const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

/**
 * Jest reporter that writes per-test, per-source-file, per-line coverage
 * data in the format consumed by the `gitlab_quality-test_tooling` gem's
 * `--per-test-coverage` flag.
 *
 * Activation requires both Jest's `--coverage` flag (so `testResult.coverage`
 * is populated) and `GLCI_PER_TEST_COVERAGE=true` in the environment. Wire-up
 * is in jest.config.base.js. With either off, the reporter is a no-op.
 *
 * Unlike the RSpec sibling this reporter doesn't snapshot/diff
 * `globalThis.__coverage__` between tests. Jest already resets and reports
 * per-test-file coverage when `--coverage` is on, so the reporter just
 * translates the Istanbul format into the line-hit-array shape the exporter
 * expects.
 */

const OUTPUT_DIR = 'tmp';

function projectDir() {
  return process.env.CI_PROJECT_DIR || '/builds/gitlab-org/gitlab';
}

function relativePath(absPath) {
  if (typeof absPath !== 'string') return absPath;
  const prefix = `${projectDir()}/`;
  if (absPath.startsWith(prefix)) {
    return absPath.slice(prefix.length);
  }
  return absPath;
}

// Project Istanbul statement counters onto line numbers. Statements span one
// or more lines (start.line..end.line); the line's hit count is the max
// across all statements that touch it.
function statementMapToLineHits(coverage) {
  if (!coverage || !coverage.statementMap || !coverage.s) return null;

  const lineHits = new Map();
  let maxLine = 0;

  for (const [id, info] of Object.entries(coverage.statementMap)) {
    const startLine = info.start && info.start.line;
    if (startLine) {
      const endLine = (info.end && info.end.line) || startLine;
      const hits = Number(coverage.s[id] || 0);
      for (let line = startLine; line <= endLine; line += 1) {
        const prev = lineHits.get(line);
        if (prev === undefined || hits > prev) lineHits.set(line, hits);
        if (line > maxLine) maxLine = line;
      }
    }
  }

  if (maxLine === 0) return null;

  const result = new Array(maxLine).fill(null);
  for (const [line, hits] of lineHits) {
    result[line - 1] = hits;
  }
  return result;
}

class PerTestCoverageReporter {
  constructor(globalConfig, reporterOptions) {
    this.globalConfig = globalConfig;
    this.options = reporterOptions || {};
    this.coverageEnabled = Boolean(globalConfig.collectCoverage);
    this.perTest = {};
  }

  onTestResult(test, testResult) {
    if (!this.coverageEnabled || !testResult.coverage) return;

    const testFile = relativePath(testResult.testFilePath);
    const filesForThisTest = {};

    for (const [absSourcePath, fileCoverage] of Object.entries(testResult.coverage)) {
      const lineHits = statementMapToLineHits(fileCoverage);
      if (lineHits) {
        filesForThisTest[relativePath(absSourcePath)] = lineHits;
      }
    }

    if (Object.keys(filesForThisTest).length > 0) {
      this.perTest[testFile] = filesForThisTest;
    }
  }

  onRunComplete() {
    if (Object.keys(this.perTest).length === 0) return;

    const slug = process.env.CI_JOB_NAME_SLUG || 'local';
    const hex = crypto.randomBytes(6).toString('hex');
    const file = path.join(OUTPUT_DIR, `per-test-coverage-jest-${slug}-${hex}.json`);

    // Wrap so a transient fs failure (permissions, disk space) doesn't fail
    // the jest run after every test has already passed. Log loudly so the
    // missing artifact is investigable from CI logs.
    try {
      fs.mkdirSync(OUTPUT_DIR, { recursive: true });
      fs.writeFileSync(file, JSON.stringify(this.perTest));
    } catch (error) {
      console.error(`PerTestCoverageReporter: failed to write ${file}: ${error.message}`);
    }
    this.perTest = {};
  }
}

module.exports = PerTestCoverageReporter;
