const { relative } = require('node:path');
const FixtureCISequencer = require('./fixture_ci_sequencer');
const { getLocalQuarantinedFiles } = require('./jest_vue3_quarantine_utils');

function relativePath(test) {
  return relative(test.context.config.rootDir, test.path);
}

class CheckVue3QuarantineSequencer extends FixtureCISequencer {
  async shard(tests, settings) {
    const quarantinedFiles = new Set(await getLocalQuarantinedFiles());
    const testsUnderQuarantine = tests.filter((test) => quarantinedFiles.has(relativePath(test)));
    const testsNotUnderQuarantine = tests.filter(
      (test) => !quarantinedFiles.has(relativePath(test)),
    );

    console.log(
      `[check_vue3_quarantine_sequencer] Omitting ${testsNotUnderQuarantine.length} specs not under quarantine:`,
    );
    console.log(testsNotUnderQuarantine.map(relativePath).join('\n'));

    return super.shard(testsUnderQuarantine, settings);
  }
}

module.exports = CheckVue3QuarantineSequencer;
