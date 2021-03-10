const Sequencer = require('@jest/test-sequencer').default;

const sortByPath = (test1, test2) => {
  if (test1.path < test2.path) {
    return -1;
  }
  if (test1.path > test2.path) {
    return 1;
  }
  return 0;
};

class ParallelCISequencer extends Sequencer {
  constructor() {
    super();
    this.ciNodeIndex = Number(process.env.CI_NODE_INDEX || '1');
    this.ciNodeTotal = Number(process.env.CI_NODE_TOTAL || '1');
  }

  sort(tests) {
    const sortedTests = [...tests].sort(sortByPath);
    const testsForThisRunner = this.distributeAcrossCINodes(sortedTests);

    console.log(`CI_NODE_INDEX: ${this.ciNodeIndex}`);
    console.log(`CI_NODE_TOTAL: ${this.ciNodeTotal}`);
    console.log(`Total number of tests: ${tests.length}`);
    console.log(`Total number of tests for this runner: ${testsForThisRunner.length}`);

    return testsForThisRunner;
  }

  distributeAcrossCINodes(tests) {
    return tests.filter((test, index) => {
      return index % this.ciNodeTotal === this.ciNodeIndex - 1;
    });
  }
}

module.exports = ParallelCISequencer;
