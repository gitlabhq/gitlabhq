const { join, relative } = require('node:path');
const Sequencer = require('@jest/test-sequencer').default;

const root = join(__dirname, '..', '..');

/**
 * Strips the {ee,jh,}/spec/frontend prefix from test paths, so that tests
 * which are likely to have many imports in common are run in the same shard.
 */
const stripTestPathPrefix = (path) =>
  relative(root, path).replace(/^((ee|jh)\/)?spec\/frontend\//, '');

const sortByStrippedPath = (test1, test2) => {
  const test1Path = stripTestPathPrefix(test1.path);
  const test2Path = stripTestPathPrefix(test2.path);

  if (test1Path < test2Path) {
    return -1;
  }

  if (test1Path > test2Path) {
    return 1;
  }

  return 0;
};

class ParallelCISequencer extends Sequencer {
  // eslint-disable-next-line class-methods-use-this
  shard(tests, { shardIndex, shardCount }) {
    const shardSize = Math.ceil(tests.length / shardCount);
    const shardStart = shardSize * (shardIndex - 1);
    const shardEnd = shardSize * shardIndex;

    return [...tests].sort(sortByStrippedPath).slice(shardStart, shardEnd);
  }

  // eslint-disable-next-line class-methods-use-this
  sort(tests) {
    // Use the sort order determined in the shard method, rather than Jest's
    // default of slowest/largest first.
    console.log('Will run the following specs:');
    console.log(tests.map(({ path }) => relative(root, path)).join('\n'));
    console.log(`${tests.length}  total specs`);

    return tests;
  }
}

module.exports = ParallelCISequencer;
