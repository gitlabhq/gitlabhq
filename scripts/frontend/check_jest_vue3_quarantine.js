#!/usr/bin/env node

const { spawnSync } = require('node:child_process');
const { readFile, open, stat, mkdir } = require('node:fs/promises');
const { join, relative, dirname } = require('node:path');
const defaultChalk = require('chalk');
const { program } = require('commander');
const IS_EE = require('../../config/helpers/is_ee_env');
const { getLocalQuarantinedFiles } = require('./jest_vue3_quarantine_utils');

const ROOT = join(__dirname, '..', '..');
const IS_CI = Boolean(process.env.CI);
const FIXTURES_HELP_URL =
  // eslint-disable-next-line no-restricted-syntax
  'https://docs.gitlab.com/ee/development/testing_guide/frontend_testing.html#download-fixtures';

const DIR = join(ROOT, 'tmp/tests/frontend');

const JEST_JSON_OUTPUT = join(DIR, 'jest_results.json');
const JEST_STDERR = join(DIR, 'jest_stderr');

// Force basic color output in CI
const chalk = new defaultChalk.constructor({ level: IS_CI ? 1 : undefined });

let quarantinedFiles;
let filesThatChanged;

function parseArguments() {
  program
    .description(
      `
Checks whether Jest specs quarantined under Vue 3 should be unquarantined.

Usage examples
--------------

In CI:

    # Check quarantined files which were affected by changes in the merge request.
    $ scripts/frontend/check_jest_vue3_quarantine.js

    # Check all quarantined files, still subject to sharding/fixture separation.
    # Useful for tier 3 pipelines, or when dependencies change.
    $ scripts/frontend/check_jest_vue3_quarantine.js --all

Locally:

    # Run all quarantined files, including those which need fixtures.
    # See ${FIXTURES_HELP_URL}
    $ scripts/frontend/check_jest_vue3_quarantine.js --all

    # Run a particular spec
    $ scripts/frontend/check_jest_vue3_quarantine.js spec/frontend/foo_spec.js

    # Run specs in this branch that were modified since master
    $ scripts/frontend/check_jest_vue3_quarantine.js $(git diff master... --name-only)

    # Write to stdio normally instead of to temporary files
    $ scripts/frontend/check_jest_vue3_quarantine.js --stdio spec/frontend/foo_spec.js
    `.trim(),
    )
    .option(
      '--all',
      'Run all quarantined specs. Good for local testing, or in CI when configuration files have changed.',
    )
    .option(
      '--stdio',
      `Let Jest write to stderr as normal. By default, it writes to ${JEST_STDERR}. Should not be used in CI, as it can exceed maximum job log size.`,
    )
    .argument('[spec...]', 'List of spec files to run (incompatible with --all)')
    .parse(process.argv);
  const options = program.opts();

  let invalidArgumentsMessage;

  if (!IS_CI) {
    if (!options.all && program.args.length === 0) {
      invalidArgumentsMessage =
        'No spec files to check!\n\nWhen run locally, either add the --all option, or a list of spec files to check.';
    }

    if (options.all && program.args.length > 0) {
      invalidArgumentsMessage = `Do not pass arguments in addition to the --all option.`;
    }
  }

  if (invalidArgumentsMessage) {
    console.warn(`${chalk.red(invalidArgumentsMessage)}\n`);
    program.help();
  }
}

async function parseResults() {
  let results;
  try {
    results = JSON.parse(await readFile(JEST_JSON_OUTPUT, 'UTF-8'));
  } catch (e) {
    console.warn(e);
    // No JUnit report exists, or there was a parsing error. Either way, we
    // should not block the MR.
    return [];
  }

  return results.testResults.reduce((acc, { name, status }) => {
    if (status === 'passed') {
      acc.push(relative(ROOT, name));
    }

    return acc;
  }, []);
}

function reportSpecsShouldBeUnquarantined(files) {
  const docsLink =
    // eslint-disable-next-line no-restricted-syntax
    'https://docs.gitlab.com/ee/development/testing_guide/testing_vue3.html#quarantine-list';
  console.warn(' ');
  console.warn(
    `The following ${files.length} spec files either now pass under Vue 3, or no longer exist, and so must be removed from quarantine:`,
  );
  console.warn(' ');
  console.warn(files.join('\n'));
  console.warn(' ');
  console.warn(
    chalk.red(
      `To fix this job, remove the files listed above from the file ${chalk.underline('scripts/frontend/quarantined_vue3_specs.txt')}.`,
    ),
  );
  console.warn(`For more information, please see ${docsLink}.`);
}

async function changedFiles() {
  if (!IS_CI) {
    // We're not in CI, so `detect-tests` artifacts won't be available.
    return [];
  }

  const { RSPEC_CHANGED_FILES_PATH, RSPEC_MATCHING_JS_FILES_PATH } = process.env;

  const files = await Promise.all(
    [RSPEC_CHANGED_FILES_PATH, RSPEC_MATCHING_JS_FILES_PATH].map((path) =>
      readFile(path, 'UTF-8').then((content) => content.split(/\s+/).filter(Boolean)),
    ),
  );

  return files.flat();
}

function filterSet(set, predicate) {
  const result = new Set();

  for (const element of set) {
    if (predicate(element)) result.add(element);
  }

  return result;
}

function intersection(a, b) {
  return filterSet(a, (element) => b.has(element));
}

async function getRemovedQuarantinedSpecs() {
  const removedQuarantinedSpecs = [];

  const filesToCheckIfTheyExist = IS_CI
    ? // In CI, only check quarantined files the author has touched.
      // If we're in a FOSS pipeline, ignore EE specs which do not exist.
      filterSet(intersection(filesThatChanged, quarantinedFiles), (path) => {
        if (IS_EE) return true;

        if (path.startsWith('ee/')) {
          console.warn(`Ignoring non-existent EE spec ${path} as we are in FOSS mode.`);
          return false;
        }

        return true;
      })
    : // Locally, check all quarantined files
      quarantinedFiles;

  for (const file of filesToCheckIfTheyExist) {
    try {
      // eslint-disable-next-line no-await-in-loop
      await stat(file);
    } catch (e) {
      if (e.code === 'ENOENT') removedQuarantinedSpecs.push(file);
    }
  }

  return removedQuarantinedSpecs;
}

function getTestArguments() {
  if (IS_CI) {
    const nodeIndex = process.env.CI_NODE_INDEX ?? '1';
    const nodeTotal = process.env.CI_NODE_TOTAL ?? '1';

    const ciArguments = (touchedFiles) => [
      '--findRelatedTests',
      ...touchedFiles,
      '--passWithNoTests',
      `--shard=${nodeIndex}/${nodeTotal}`,
      '--testSequencer',
      './scripts/frontend/check_jest_vue3_quarantine_sequencer.js',
    ];

    if (program.opts().all) {
      console.warn(
        'Running in CI with --all. Checking all quarantined specs, subject to FixtureCISequencer sharding behavior.',
      );

      return ciArguments(quarantinedFiles);
    }

    console.warn(
      'Running in CI. Only specs affected by changes in the merge request will be checked.',
    );
    return ciArguments(filesThatChanged);
  }

  if (program.opts().all) {
    console.warn('Running locally with --all. Checking all quarantined specs.');
    return ['--runTestsByPath', ...quarantinedFiles];
  }

  if (program.args.length > 0) {
    const specs = program.args.filter((spec) => {
      const isQuarantined = quarantinedFiles.has(relative(ROOT, spec));
      if (!isQuarantined) console.warn(`Omitting file as it is not in quarantine list: ${spec}`);
      return isQuarantined;
    });

    if (specs.length === 0) {
      console.warn(`No quarantined specs to run!`);
      process.exit(1);
    }

    console.warn('Running locally. Checking given specs.');
    return ['--runTestsByPath', ...specs];
  }

  // ESLint's consistent-return rule requires something like this.
  return ['--this-should-never-happen-and-jest-should-fail'];
}

async function getStdio() {
  if (program.opts().stdio) {
    return 'inherit';
  }

  await mkdir(dirname(JEST_STDERR), { recursive: true });
  const jestStderr = (await open(JEST_STDERR, 'w')).createWriteStream();

  return ['inherit', 'inherit', jestStderr];
}

async function main() {
  parseArguments();

  filesThatChanged = await changedFiles();
  quarantinedFiles = new Set(await getLocalQuarantinedFiles());

  // Note: we don't care what Jest's exit code is.
  //
  // If it's zero, then either:
  //   - all specs passed, or
  //   - no specs were run.
  //
  // Both situations are handled later.
  //
  // If it's non-zero, then either:
  //   - one or more specs failed (which is expected!), or
  //   - there was some unknown error. We shouldn't block MRs in this case.
  spawnSync(
    'node_modules/.bin/jest',
    [
      '--config',
      'jest.config.js',
      '--ci',
      '--logHeapUsage',
      '--json',
      `--outputFile=${JEST_JSON_OUTPUT}`,
      ...getTestArguments(),
    ],
    {
      stdio: await getStdio(),
      env: {
        ...process.env,
        VUE_VERSION: '3',
      },
    },
  );

  const passed = await parseResults();
  const removedQuarantinedSpecs = await getRemovedQuarantinedSpecs();
  const filesToReport = [...passed, ...removedQuarantinedSpecs];

  if (filesToReport.length === 0) {
    // No tests ran, or there was some unexpected error. Either way, exit
    // successfully.
    console.warn('No spec files need to be removed from quarantine.');
    return;
  }

  process.exitCode = 1;
  reportSpecsShouldBeUnquarantined(filesToReport);
}

main().catch((e) => {
  // Don't block on unexpected errors.
  console.warn(e);
});
