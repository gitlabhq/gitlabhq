const { relative } = require('path');
const Sequencer = require('./parallel_ci_sequencer');

const seen = {};

function isFixtureDependency(context, relPath, root) {
  if (relPath.startsWith('test_fixtures/')) {
    return true;
  }

  if (
    !relPath.startsWith('.') &&
    !relPath.startsWith('jest/') &&
    !relPath.startsWith('helpers/') &&
    !relPath.startsWith('ee_else_ce_jest/') &&
    !relPath.startsWith('ee_jest/') &&
    !relPath.startsWith('jh_jest/')
  ) {
    return false;
  }
  if (relPath in seen) {
    return seen[relPath];
  }

  const resolved = relative(context.config.rootDir, context.resolver.resolveModule(root, relPath));

  if (resolved in seen) {
    return seen[resolved];
  }

  const result = context.hasteFS
    .getDependencies(resolved)
    ?.some((depPath) => isFixtureDependency(context, depPath, resolved));

  if (!relPath.startsWith('.')) {
    seen[relPath] = result;
  }

  seen[resolved] = result;

  return result;
}

function isFixtureTest({ context, path }) {
  const relativePath = relative(context.config.rootDir, path);
  const dependencies = context.hasteFS.getDependencies(relativePath);
  if (
    dependencies?.some((dependencyPath) =>
      isFixtureDependency(context, dependencyPath, relativePath),
    )
  ) {
    return true;
  }

  return false;
}

class FixtureCISequencer extends Sequencer {
  shard(tests, settings) {
    let testList = tests;

    if (process.env.JEST_FIXTURE_JOBS_ONLY) {
      testList = testList.filter(isFixtureTest);
      console.log(`[fixture_ci_sequencer] running only ${testList.length} fixture-using specs.`);
    } else {
      const lengthBefore = testList.length;
      testList = testList.filter((t) => !isFixtureTest(t));
      console.log(
        `[fixture_ci_sequencer] filtered out ${
          lengthBefore - testList.length
        } fixture-using specs.`,
      );
    }

    return super.shard(testList, settings);
  }
}

module.exports = FixtureCISequencer;
