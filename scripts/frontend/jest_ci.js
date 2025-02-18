#!/usr/bin/env node

const { spawnSync } = require('node:child_process');
const { readFileSync } = require('node:fs');
const defaultChalk = require('chalk');
const { program } = require('commander');

const IS_CI = Boolean(process.env.CI);

const VUE_3_TESTING_DOCS_URL =
  // eslint-disable-next-line no-restricted-syntax
  'https://docs.gitlab.com/ee/development/testing_guide/testing_vue3.html';
const VUE_3_TESTING_EPIC = 'https://gitlab.com/groups/gitlab-org/-/epics/11740';

// Force basic color output in CI
const chalk = new defaultChalk.constructor({ level: IS_CI ? 1 : undefined });

function showVue3Help() {
  console.warn(' ');
  console.warn(
    chalk.green.bold('Having trouble getting tests to pass under Vue 3? These resources may help:'),
  );
  console.warn(' ');
  console.warn(` - ${chalk.green('Vue 3 testing documentation:')} ${VUE_3_TESTING_DOCS_URL}`);
  console.warn(` - ${chalk.green('Epic for fixing tests under Vue 3:')} w${VUE_3_TESTING_EPIC}`);
}

function parseArgumentsAndEnvironment() {
  program
    .description(`Runs Jest under CI.`)
    .option(
      '--vue3',
      'Run tests under Vue 3 (via @vue/compat). The default is to run under Vue 2. The VUE_VERSION environment variable must agree with this option.',
    )
    .option(
      '--include-vue3-quarantined',
      'Include tests normally quarantined under Vue 3. This is currently used for nightly pipelines. Has no effect without --vue3. The default (given --vue3) is to exclude quarantined tests.',
    )
    .option(
      '--predictive',
      'Only run specs affected by the changes in the merge request. The default is to run all specs.',
    )
    .option(
      '--fixtures',
      'Only run specs which rely on generated fixtures. The default is to only run specs which do not rely on generated fixtures.',
    )
    .option(
      '--coverage',
      "Tell Jest to generate coverage. If not specified, it's enabled only on non-FOSS branch or tag pipelines under Vue 2, non-predictive runs.",
    )
    .parse(process.argv);
  const options = program.opts();

  if (!IS_CI) {
    console.warn('This script is intended to run in CI only.');
    if (options.vue3) showVue3Help();
    process.exit(1);
  }

  if (options.vue3 && process.env.VUE_VERSION !== '3') {
    console.warn(
      `Expected environment variable VUE_VERSION=3 given option '--vue3', got VUE_VERSION="${process.env.VUE_VERSION}".`,
    );
    process.exit(1);
  }

  if (!options.vue3 && ![undefined, '2'].includes(process.env.VUE_VERSION)) {
    console.warn(
      `Expected unset environment variable VUE_VERSION, or VUE_VERSION=2, got VUE_VERSION="${process.env.VUE_VERSION}".`,
    );
    process.exit(1);
  }

  const changedFiles = [];
  if (options.predictive) {
    const { RSPEC_MATCHING_JS_FILES_PATH, RSPEC_CHANGED_FILES_PATH } = process.env;

    for (const [name, path] of Object.entries({
      RSPEC_CHANGED_FILES_PATH,
      RSPEC_MATCHING_JS_FILES_PATH,
    })) {
      try {
        const contents = readFileSync(path, { encoding: 'UTF-8' });
        changedFiles.push(...contents.split(/\s+/).filter(Boolean));
      } catch (error) {
        console.warn(
          `Failed to read from path ${path} given by environment variable ${name}`,
          error,
        );
      }
    }

    if (!changedFiles) {
      console.warn('No changed files detected; will not run Jest.');
      process.exit(0);
    }
  }

  const coverage =
    options.coverage ||
    (!process.env.CI_MERGE_REQUEST_IID &&
      !/^as-if-foss\//.test(process.env.CI_COMMIT_BRANCH) &&
      !options.vue3 &&
      !options.predictive);

  return {
    vue3: options.vue3,
    includeVue3Quarantined: options.includeVue3Quarantined,
    predictive: options.predictive,
    fixtures: options.fixtures,
    coverage,
    nodeIndex: process.env.CI_NODE_INDEX ?? '1',
    nodeTotal: process.env.CI_NODE_TOTAL ?? '1',
    changedFiles,
  };
}

function loggedSpawnSync(command, args, options) {
  const env = ['JEST_FIXTURE_JOBS_ONLY', 'VUE_VERSION']
    .map((name) => `${name}=${options.env[name] ?? ''}`)
    .join(' ');
  const fullCommand = `${env} ${command} ${args.join(' ')}`;
  console.warn(`Running command:\n${fullCommand}`);
  const childProcess = spawnSync(command, args, options);
  console.warn(`Command ${fullCommand} exited with status ${childProcess.status}`);
  return childProcess;
}

function runJest({
  vue3,
  includeVue3Quarantined,
  predictive,
  fixtures,
  coverage,
  nodeIndex,
  nodeTotal,
  changedFiles,
}) {
  const commonArguments = [
    '--config',
    'jest.config.js',
    '--ci',
    `--shard=${nodeIndex}/${nodeTotal}`,
    '--logHeapUsage',
  ];

  const sequencerArguments = [
    '--testSequencer',
    vue3 && !includeVue3Quarantined
      ? './scripts/frontend/skip_specs_broken_in_vue_compat_fixture_ci_sequencer.js'
      : './scripts/frontend/fixture_ci_sequencer.js',
  ];

  const predictiveArguments = predictive
    ? ['--passWithNoTests', '--findRelatedTests', ...changedFiles]
    : [];

  const coverageArguments = coverage ? ['--coverage'] : [];

  const childProcess = loggedSpawnSync(
    'node_modules/.bin/jest',
    [...commonArguments, ...sequencerArguments, ...predictiveArguments, ...coverageArguments],
    {
      stdio: 'inherit',
      env: {
        ...process.env,
        ...(fixtures ? { JEST_FIXTURE_JOBS_ONLY: '1' } : {}),
      },
    },
  );

  return childProcess;
}

function main() {
  const config = parseArgumentsAndEnvironment();
  const childProcess = runJest(config);

  if (childProcess.status !== 0 && config.vue3) {
    showVue3Help();
  }

  return childProcess.status;
}

try {
  process.exitCode = main();
} catch (error) {
  process.exitCode = 1;
  console.error(error);
}
