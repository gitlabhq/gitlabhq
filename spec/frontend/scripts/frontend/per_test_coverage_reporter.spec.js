import fs from 'fs';
import PerTestCoverageReporter from '../../../../scripts/frontend/per_test_coverage_reporter';

jest.mock('fs');

describe('PerTestCoverageReporter', () => {
  const PROJECT_DIR = '/builds/gitlab-org/gitlab';
  const ABS_TEST = `${PROJECT_DIR}/spec/frontend/foo_spec.js`;
  const ABS_SRC = `${PROJECT_DIR}/app/assets/javascripts/foo.js`;
  let reporter;
  let originalEnv;

  beforeEach(() => {
    originalEnv = process.env;
    process.env = { ...originalEnv, CI_PROJECT_DIR: PROJECT_DIR, CI_JOB_NAME_SLUG: 'jest-shard-1' };
    reporter = new PerTestCoverageReporter({ collectCoverage: true });
  });

  afterEach(() => {
    process.env = originalEnv;
    jest.restoreAllMocks();
    jest.clearAllMocks();
  });

  // Helper that builds an Istanbul-shaped per-file coverage entry from a
  // simple {lineNumber: hits, ...} description.
  function istanbulCoverage(lineHits) {
    const statementMap = {};
    const s = {};
    Object.entries(lineHits).forEach(([line, hits], index) => {
      const lineNum = Number(line);
      statementMap[index] = {
        start: { line: lineNum, column: 0 },
        end: { line: lineNum, column: 1 },
      };
      s[index] = hits;
    });
    return { statementMap, s };
  }

  describe('constructor', () => {
    it('reads collectCoverage from globalConfig', () => {
      expect(reporter.coverageEnabled).toBe(true);
    });

    it('sets coverageEnabled false when collectCoverage is false', () => {
      const r = new PerTestCoverageReporter({ collectCoverage: false });
      expect(r.coverageEnabled).toBe(false);
    });

    it('starts with an empty per-test map', () => {
      expect(reporter.perTest).toEqual({});
    });
  });

  describe('onTestResult', () => {
    it('records line hits per test, projecting Istanbul statements onto line numbers', () => {
      reporter.onTestResult(
        { path: ABS_TEST },
        {
          testFilePath: ABS_TEST,
          coverage: {
            [ABS_SRC]: istanbulCoverage({ 1: 1, 3: 0, 5: 7 }),
          },
        },
      );

      expect(reporter.perTest).toEqual({
        'spec/frontend/foo_spec.js': {
          'app/assets/javascripts/foo.js': [1, null, 0, null, 7],
        },
      });
    });

    it('skips generated route helpers under lib/utils/path_helpers', () => {
      const generatedSrc = `${PROJECT_DIR}/app/assets/javascripts/lib/utils/path_helpers/project.js`;
      reporter.onTestResult(
        { path: ABS_TEST },
        {
          testFilePath: ABS_TEST,
          coverage: {
            [ABS_SRC]: istanbulCoverage({ 1: 1 }),
            [generatedSrc]: istanbulCoverage({ 1: 1, 2: 1 }),
          },
        },
      );

      expect(reporter.perTest).toEqual({
        'spec/frontend/foo_spec.js': {
          'app/assets/javascripts/foo.js': [1],
        },
      });
    });

    it('skips when coverageEnabled is false', () => {
      const r = new PerTestCoverageReporter({ collectCoverage: false });
      r.onTestResult(
        { path: ABS_TEST },
        { testFilePath: ABS_TEST, coverage: { [ABS_SRC]: istanbulCoverage({ 1: 1 }) } },
      );
      expect(r.perTest).toEqual({});
    });

    it('skips when testResult.coverage is missing', () => {
      reporter.onTestResult({ path: ABS_TEST }, { testFilePath: ABS_TEST });
      expect(reporter.perTest).toEqual({});
    });

    it('skips files with no statementMap entries', () => {
      reporter.onTestResult(
        { path: ABS_TEST },
        {
          testFilePath: ABS_TEST,
          coverage: {
            [ABS_SRC]: { statementMap: {}, s: {} },
          },
        },
      );
      expect(reporter.perTest).toEqual({});
    });

    it('uses max hit count when multiple statements touch the same line', () => {
      const cov = {
        statementMap: {
          0: { start: { line: 5, column: 0 }, end: { line: 5, column: 10 } },
          1: { start: { line: 5, column: 11 }, end: { line: 5, column: 20 } },
        },
        s: { 0: 2, 1: 9 },
      };
      reporter.onTestResult(
        { path: ABS_TEST },
        { testFilePath: ABS_TEST, coverage: { [ABS_SRC]: cov } },
      );
      expect(
        reporter.perTest['spec/frontend/foo_spec.js']['app/assets/javascripts/foo.js'][4],
      ).toBe(9);
    });

    it('handles multi-line statements (start.line through end.line)', () => {
      const cov = {
        statementMap: {
          0: { start: { line: 1, column: 0 }, end: { line: 3, column: 5 } },
        },
        s: { 0: 4 },
      };
      reporter.onTestResult(
        { path: ABS_TEST },
        { testFilePath: ABS_TEST, coverage: { [ABS_SRC]: cov } },
      );
      const lineHits =
        reporter.perTest['spec/frontend/foo_spec.js']['app/assets/javascripts/foo.js'];
      expect(lineHits).toEqual([4, 4, 4]);
    });

    it('leaves absolute paths unchanged when they do not start with CI_PROJECT_DIR', () => {
      const externalPath = '/somewhere/else/spec.js';
      const externalSrc = '/somewhere/else/src.js';
      reporter.onTestResult(
        { path: externalPath },
        {
          testFilePath: externalPath,
          coverage: { [externalSrc]: istanbulCoverage({ 1: 1 }) },
        },
      );
      expect(Object.keys(reporter.perTest)).toEqual([externalPath]);
    });
  });

  describe('onRunComplete', () => {
    beforeEach(() => {
      reporter.perTest = {
        'spec/frontend/foo_spec.js': { 'app/foo.js': [1, null] },
      };
    });

    it('writes a JSON file under tmp/ named with job slug + random hex', () => {
      reporter.onRunComplete();

      expect(fs.mkdirSync).toHaveBeenCalledWith('tmp', { recursive: true });
      expect(fs.writeFileSync).toHaveBeenCalledTimes(1);
      const [filePath, content] = fs.writeFileSync.mock.calls[0];
      expect(filePath).toMatch(/^tmp\/per-test-coverage-jest-jest-shard-1-[0-9a-f]{12}\.json$/);
      expect(JSON.parse(content)).toEqual({
        'spec/frontend/foo_spec.js': { 'app/foo.js': [1, null] },
      });
    });

    it('falls back to "local" job slug when CI_JOB_NAME_SLUG is unset', () => {
      delete process.env.CI_JOB_NAME_SLUG;
      reporter.onRunComplete();
      const filePath = fs.writeFileSync.mock.calls[0][0];
      expect(filePath).toMatch(/^tmp\/per-test-coverage-jest-local-[0-9a-f]{12}\.json$/);
    });

    it('does nothing when no per-test data was collected', () => {
      reporter.perTest = {};
      reporter.onRunComplete();

      expect(fs.mkdirSync).not.toHaveBeenCalled();
      expect(fs.writeFileSync).not.toHaveBeenCalled();
    });

    it('clears perTest after writing so a re-invocation does not double-write', () => {
      reporter.onRunComplete();
      expect(reporter.perTest).toEqual({});
    });

    it('logs to stderr and continues when fs throws (does not fail the jest run)', () => {
      jest.spyOn(console, 'error').mockImplementation();
      fs.writeFileSync.mockImplementation(() => {
        throw new Error('disk full');
      });

      expect(() => reporter.onRunComplete()).not.toThrow();
      // eslint-disable-next-line no-console
      expect(console.error).toHaveBeenCalledWith(
        expect.stringMatching(/PerTestCoverageReporter: failed to write .* disk full/),
      );
      expect(reporter.perTest).toEqual({});
    });
  });
});
