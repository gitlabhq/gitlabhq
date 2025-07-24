#!/usr/bin/env node

/**
 * Unlike rspec tests, we don't have a crystalball mapping file to calculate predicted tests, instead we need to find them using the dependency graph generated at runtime.
 *
 * So, we use helper functions in this module to list the frontend predictive tests (Jest) that are ran in tier-1, based on these criteria
 * 1. Changed files (changed_files.txt)
 * 2. Vue version predictive tests -- this doesn't affect test discovery, only test execution, so, we'lll get the list using Vue2
 *  2b. Vue 2 (includes all tests)
 *  2a. Vue 3 (some vue3 tests are quarantined)
 * 3. Backend changes (`js_matching_files.txt`)
 *  3a. Fixtures
 *  3b. Views
 * 4. Jest integration tests (uses --config `jest.config.integration.js`)
 *
 * CI rule match these file patterns
 * .frontend-predictive-patterns:
 * '{,ee/,jh/}{app/assets/javascripts,spec/frontend}/**'
 *
 * Command usage:
 * Run
 * ```sh
 * # set env variables and then run the following
 * ./scripts/frontend/find_jest_predictive_tests.js
 * ```
 */
const { spawnSync } = require('node:child_process');
const { readFileSync, writeFileSync, mkdirSync } = require('node:fs');
const { relative, dirname } = require('node:path');

const requiredEnv = [
  'JEST_MATCHING_TEST_FILES_PATH',
  'GLCI_PREDICTIVE_MATCHING_JS_FILES_PATH',
  'GLCI_PREDICTIVE_CHANGED_FILES_PATH',
];

function hasRequiredEnvironmentVariables() {
  const missing = requiredEnv.filter((envVar) => !process.env[envVar]);

  if (missing.length > 0) {
    console.warn(`Warning: Missing required environment variables: ${missing.join(', ')}`);
    console.warn('Some functionality may not work as expected.');
    process.exitCode = 1;
  }
}

function getChangedFiles() {
  const files = [];
  const { GLCI_PREDICTIVE_MATCHING_JS_FILES_PATH, GLCI_PREDICTIVE_CHANGED_FILES_PATH } =
    process.env;

  for (const [name, filePath] of Object.entries({
    GLCI_PREDICTIVE_CHANGED_FILES_PATH,
    GLCI_PREDICTIVE_MATCHING_JS_FILES_PATH,
  })) {
    try {
      const contents = readFileSync(filePath, { encoding: 'UTF-8' });
      files.push(...contents.split(/\s+/).filter(Boolean));
    } catch (error) {
      console.warn(
        `Failed to read from path ${filePath} given by environment variable ${name}`,
        error,
      );
    }
  }

  return Array.from(new Set(files));
}

function findJestTests(config, changedFiles) {
  const args = ['--ci', '--config', config, '--listTests'];

  if (changedFiles) {
    if (!changedFiles.length) return [];

    args.push('--findRelatedTests');
    args.push(...changedFiles);
  }
  try {
    const childProcess = spawnSync('node_modules/.bin/jest', args, {
      encoding: 'utf8',
      stdio: 'pipe',
      env: process.env,
    });

    if (childProcess.error) {
      throw new Error(`Failed to spawn Jest: ${childProcess.error.message}`);
    }

    if (childProcess.status !== 0) {
      const errorOutput = childProcess.stderr || 'No error output captured';
      throw new Error(`Jest exited with code ${childProcess.status}: ${errorOutput}`);
    }

    if (!childProcess.stdout) {
      console.warn('No output from Jest.');
      return [];
    }
    return childProcess.stdout
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.endsWith('.js'))
      .map((test) => relative(process.cwd(), test));
  } catch (error) {
    throw new Error(`Failed to run Jest with config ${config}: ${error.message}`);
  }
}

function collectTests(changedFiles) {
  if (changedFiles && !changedFiles.length) {
    console.log('No changed files found - no tests to run');
    return [];
  }
  console.log(`Analyzing ${changedFiles.length} changed files...`);

  const configs = [
    { name: 'unit', configPath: 'jest.config.js' },
    { name: 'integration', configPath: 'jest.config.integration.js' },
  ];

  const allTests = [];

  for (const { name, configPath } of configs) {
    try {
      console.log(`Checking ${name} tests...`);
      const tests = findJestTests(configPath, changedFiles);
      allTests.push(...tests);
    } catch (error) {
      console.error(`Error with ${name} tests config:\n`, error);
    }
  }

  return Array.from(new Set(allTests)).sort();
}

function saveMatchingTestFiles(testFiles) {
  const { JEST_MATCHING_TEST_FILES_PATH } = process.env;
  if (JEST_MATCHING_TEST_FILES_PATH) {
    mkdirSync(dirname(JEST_MATCHING_TEST_FILES_PATH), { recursive: true });
    writeFileSync(JEST_MATCHING_TEST_FILES_PATH, testFiles.join(' '));
    console.log(`Saved to: ${JEST_MATCHING_TEST_FILES_PATH}`);
  }
}

function logAndSaveMatchingTestFiles(changedFiles) {
  const matchingTestFiles = collectTests(changedFiles);
  console.log(`\nFound ${matchingTestFiles.length} predictive test files`);

  console.log('\n=== TEST FILES ===');
  console.log(matchingTestFiles.join('\n'));

  saveMatchingTestFiles(matchingTestFiles);
}

function listPredictiveTests() {
  try {
    hasRequiredEnvironmentVariables();

    logAndSaveMatchingTestFiles(getChangedFiles());
  } catch (error) {
    console.error('Error finding predictive jest tests:', error);
    process.exitCode = 1;
  }
}

if (require.main === module) {
  listPredictiveTests();
} else {
  module.exports = {
    hasRequiredEnvironmentVariables,
    getChangedFiles,
    findJestTests,
    collectTests,
    logAndSaveMatchingTestFiles,
  };
}
