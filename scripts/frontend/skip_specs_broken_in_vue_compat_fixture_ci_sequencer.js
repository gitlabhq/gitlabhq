const { relative } = require('node:path');
const { setTimeout: setTimeoutPromise } = require('node:timers/promises');
const axios = require('axios');
const { parse, getLocalQuarantinedFiles } = require('./jest_vue3_quarantine_utils');
const FixtureCISequencer = require('./fixture_ci_sequencer');

const url =
  'https://gitlab-org.gitlab.io/frontend/playground/fast-jest-vue-3-quarantine/gitlab.txt';

// See https://gitlab.com/gitlab-org/frontend/playground/fast-jest-vue-3-quarantine for details
// about how to fast quarantine files.
async function getFastQuarantinedFiles(n = 0, maxRetries = 3) {
  try {
    const { data } = await axios.get(url, { timeout: 10_000 });
    return parse(data);
  } catch (error) {
    console.error('\nFailed to fetch list of specs failing with @vue/compat: %s', error.message);

    if (n < maxRetries) {
      const waitMs = 5_000 * 2 ** n;
      console.error(`Waiting ${waitMs}ms to retry (${maxRetries - n} remaining)`);
      await setTimeoutPromise(waitMs);
      return getFastQuarantinedFiles(n + 1);
    }

    throw error;
  }
}

async function getQuarantinedFiles() {
  const results = await Promise.all([getFastQuarantinedFiles(), getLocalQuarantinedFiles()]);
  return new Set(results.flat());
}

class SkipSpecsBrokenInVueCompatFixtureCISequencer extends FixtureCISequencer {
  #quarantinedFiles = getQuarantinedFiles();

  async shard(tests, options) {
    const quarantinedFiles = await this.#quarantinedFiles;
    console.warn(
      `Skipping ${quarantinedFiles.size} quarantined specs:\n${[...quarantinedFiles].join('\n')}`,
    );

    const testsExcludingQuarantined = tests.filter(
      (test) => !quarantinedFiles.has(relative(test.context.config.rootDir, test.path)),
    );

    return super.shard(testsExcludingQuarantined, options);
  }
}

module.exports = SkipSpecsBrokenInVueCompatFixtureCISequencer;
