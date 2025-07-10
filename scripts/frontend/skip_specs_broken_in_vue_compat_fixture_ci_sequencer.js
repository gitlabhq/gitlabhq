const { relative } = require('node:path');
const {
  getFastQuarantinedFiles,
  getLocalQuarantinedFiles,
} = require('./jest_vue3_quarantine_utils');
const FixtureCISequencer = require('./fixture_ci_sequencer');

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
