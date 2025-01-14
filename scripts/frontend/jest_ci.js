#!/usr/bin/env node

const { spawnSync } = require('node:child_process');
const { readFileSync } = require('node:fs');
const defaultChalk = require('chalk');
const program = require('commander');

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
    .usage('[options]')
    .description(`Runs Jest under CI.`)
    .option('--vue3', 'Run tests under Vue 3 (via @vue/compat). The default is to run under Vue 2.')
    .option(
      '--predictive',
      'Only run specs affected by the changes in the merge request. The default is to run all specs.',
    )
    .option(
      '--fixtures',
      'Only run specs which rely on generated fixtures. The default is to only run specs which do not rely on generated fixtures.',
    )
    .option('--coverage', 'Tell Jest to generate coverage. The default is not to.')
    .parse(process.argv);

  if (!IS_CI) {
    console.warn('This script is intended to run in CI only.');
    if (program.vue3) showVue3Help();
    process.exit(1);
  }

  const changedFiles = [];
  if (program.predictive) {
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

  return {
    vue3: program.vue3,
    predictive: program.predictive,
    fixtures: program.fixtures,
    coverage: program.coverage,
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

function runJest({ vue3, predictive, fixtures, coverage, nodeIndex, nodeTotal, changedFiles }) {
  const commonArguments = [
    '--config',
    'jest.config.js',
    '--ci',
    `--shard=${nodeIndex}/${nodeTotal}`,
    '--logHeapUsage',
  ];

  const sequencerArguments = [
    '--testSequencer',
    vue3
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
        ...(vue3 ? { VUE_VERSION: '3' } : {}),
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
