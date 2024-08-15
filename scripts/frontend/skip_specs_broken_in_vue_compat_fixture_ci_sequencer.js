const { relative } = require('node:path');
const { setTimeout: setTimeoutPromise } = require('node:timers/promises');
const axios = require('axios');
const FixtureCISequencer = require('./fixture_ci_sequencer');

const url = 'https://gitlab-org.gitlab.io/frontend/playground/jest-speed-reporter/vue3.json';

// These fail due to template compilation errors, so aren't recorded in the
// JUnit report that the Jest Speed Reporter project consumes. We must explicitly
// exclude them until this is solved.
// See https://gitlab.com/gitlab-org/gitlab/-/issues/478773.
const SPECS_THAT_FAIL_TO_COMPILE = [
  'spec/frontend/boards/components/board_app_spec.js',
  'ee/spec/frontend/boards/components/board_app_spec.js',
  'spec/frontend/boards/components/board_content_spec.js',
  'ee/spec/frontend/boards/components/board_content_spec.js',
];

async function getFailedFilesAsAbsolutePaths(n = 0, maxRetries = 3) {
  try {
    const { data } = await axios.get(url, { timeout: 10_000 });
    return new Set([...data.failedFiles, ...SPECS_THAT_FAIL_TO_COMPILE]);
  } catch (error) {
    console.error('\nFailed to fetch list of specs failing with @vue/compat: %s', error.message);

    if (n < maxRetries) {
      const waitMs = 5_000 * 2 ** n;
      console.error(`Waiting ${waitMs}ms to retry (${maxRetries - n} remaining)`);
      await setTimeoutPromise(waitMs);
      return getFailedFilesAsAbsolutePaths(n + 1);
    }

    throw error;
  }
}

class SkipSpecsBrokenInVueCompatFixtureCISequencer extends FixtureCISequencer {
  #failedSpecFilesPromise = getFailedFilesAsAbsolutePaths();

  async shard(tests, options) {
    const failedSpecFiles = await this.#failedSpecFilesPromise;

    const testsExcludingOnesThatFailInVueCompat = tests.filter(
      (test) => !failedSpecFiles.has(relative(test.context.config.rootDir, test.path)),
    );

    return super.shard(testsExcludingOnesThatFailInVueCompat, options);
  }
}

module.exports = SkipSpecsBrokenInVueCompatFixtureCISequencer;
