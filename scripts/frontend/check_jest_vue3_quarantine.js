const { spawnSync } = require('node:child_process');
const { readFile } = require('node:fs/promises');
const parser = require('fast-xml-parser');
const defaultChalk = require('chalk');
const { getLocalQuarantinedFiles } = require('./jest_vue3_quarantine_utils');

// Always use basic color output
const chalk = new defaultChalk.constructor({ level: 1 });

async function parseJUnitReport() {
  let junit;
  try {
    const xml = await readFile('./junit_jest.xml', 'UTF-8');
    junit = parser.parse(xml, {
      arrayMode: true,
      attributeNamePrefix: '',
      parseNodeValue: false,
      ignoreAttributes: false,
    });
  } catch (e) {
    console.warn(e);
    // No JUnit report exists, or there was a parsing error. Either way, we
    // should not block the MR.
    return { passed: [], total: 0 };
  }

  const failuresByFile = new Map();

  for (const testsuites of junit.testsuites) {
    for (const testsuite of testsuites.testsuite || []) {
      for (const testcase of testsuite.testcase) {
        const { file } = testcase;
        if (!failuresByFile.has(file)) {
          failuresByFile.set(file, 0);
        }

        const failuresSoFar = failuresByFile.get(file);
        const testcaseFailed = testcase.failure ? 1 : 0;
        failuresByFile.set(file, failuresSoFar + testcaseFailed);
      }
    }
  }

  const quarantinedFiles = new Set(await getLocalQuarantinedFiles());
  const passed = [];
  for (const [file, failures] of failuresByFile.entries()) {
    if (failures === 0 && quarantinedFiles.has(file)) passed.push(file);
  }

  return {
    passed,
    total: failuresByFile.size,
  };
}

/**
 * Wraps the output of `callback` in a collapsible section (for GitLab CI).
 *
 * Assumes `callback` is synchronous.
 *
 * See https://docs.gitlab.com/ee/ci/jobs/job_logs.html#custom-collapsible-sections
 */
function section(header, callback, { showCollapsed = true } = {}) {
  const ANSI_CLEAR_LINE = '\x1b[0K';
  const timestamp = () => Math.floor(Date.now() / 1000);
  const collapsed = showCollapsed ? '[collapsed=true]' : '';
  const name = header.toLowerCase().replace(/\W+/g, '_');

  console.log(
    `${ANSI_CLEAR_LINE}section_start:${timestamp()}:${name}${collapsed}\r${ANSI_CLEAR_LINE}${chalk.cyan.bold(header)}`,
  );

  callback();

  console.log(`${ANSI_CLEAR_LINE}section_end:${timestamp()}:${name}\r${ANSI_CLEAR_LINE}`);
}

function reportPassingSpecsShouldBeUnquarantined(passed) {
  console.warn(' ');
  console.warn(
    `The following ${passed.length} spec file(s) now pass(es) under Vue 3, and so must be removed from quarantine:`,
  );
  console.warn(' ');
  console.warn(passed.join('\n'));
  console.warn(' ');
  console.warn(
    chalk.red(
      `To fix this job, remove the file(s) listed above from the file ${chalk.underline('scripts/frontend/quarantined_vue3_specs.txt')}.`,
    ),
  );
}

async function changedFiles() {
  const { RSPEC_CHANGED_FILES_PATH, RSPEC_MATCHING_JS_FILES_PATH } = process.env;

  const files = await Promise.all(
    [RSPEC_CHANGED_FILES_PATH, RSPEC_MATCHING_JS_FILES_PATH].map((path) =>
      readFile(path, 'UTF-8').then((content) => content.split(/\s+/).filter(Boolean)),
    ),
  );

  return files.flat();
}

async function main() {
  const filesThatChanged = await changedFiles();

  // Note: we don't care what Jest's exit code is.
  //
  // If it's zero, then either:
  //   - all specs passed, or
  //   - no specs were run.
  //
  // Both situations are handled later.
  //
  // If it's non-zero, then either:
  //   - one or more specs failed (which is expected!), or
  //   - there was some unknown error. We shouldn't block MRs in this case.
  section('Jest output (only useful for debugging the CI job itself, not the tests)', () =>
    spawnSync(
      'node_modules/.bin/jest',
      [
        '--config',
        'jest.config.js',
        '--ci',
        '--findRelatedTests',
        ...filesThatChanged,
        '--passWithNoTests',
        // Explicitly have one shard, so that the `shard` method of the sequencer is called.
        '--shard=1/1',
        '--testSequencer',
        './scripts/frontend/check_jest_vue3_quarantine_sequencer.js',
        '--logHeapUsage',
      ],
      {
        stdio: 'inherit',
        env: {
          ...process.env,
          VUE_VERSION: '3',
        },
      },
    ),
  );

  const { passed, total } = await parseJUnitReport();

  if (total.length === 0) {
    // No tests ran, or there was some unexpected error. Either way, exit
    // successfully.
    return;
  }

  if (passed.length > 0) {
    process.exitCode = 1;
    reportPassingSpecsShouldBeUnquarantined(passed);
  }
}

main().catch((e) => {
  // Don't block on unexpected errors.
  console.warn(e);
});
