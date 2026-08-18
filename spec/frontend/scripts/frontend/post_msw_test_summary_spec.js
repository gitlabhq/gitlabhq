/* eslint-disable import/extensions */
import {
  perFileFromReport,
  computeActionable,
  thresholdInfo,
  buildComment,
  formatSignedDuration,
  apiRequest,
} from '../../../../scripts/frontend/post_msw_test_summary.mjs';

// Helper: build a Jest --json-shaped testResults entry with the given
// assertion durations (ms). Jest records absolute file paths.
const reportEntry = (relPath, durationsMs) => ({
  name: `/builds/gitlab-org/gitlab/${relPath}`,
  assertionResults: durationsMs.map((duration, i) => ({ title: `test ${i}`, duration })),
});

describe('perFileFromReport', () => {
  it('normalises absolute paths and aggregates runtime + test count per file', () => {
    const data = {
      testResults: [
        reportEntry('spec/frontend/msw_integration/a_spec.js', [1000, 2000]),
        reportEntry('ee/spec/frontend/msw_integration/b_spec.js', [500]),
      ],
    };

    expect(perFileFromReport(data)).toEqual({
      'spec/frontend/msw_integration/a_spec.js': { runtimeS: 3, testCount: 2 },
      'ee/spec/frontend/msw_integration/b_spec.js': { runtimeS: 0.5, testCount: 1 },
    });
  });

  it('returns an empty map when there are no test results', () => {
    expect(perFileFromReport({})).toEqual({});
  });
});

describe('thresholdInfo', () => {
  it.each`
    perTestS | level
    ${null}  | ${'none'}
    ${0}     | ${'ok'}
    ${14}    | ${'ok'}
    ${15}    | ${'warning'}
    ${60}    | ${'warning'}
    ${61}    | ${'action'}
    ${130}   | ${'action'}
  `('maps $perTestS s/test to level "$level"', ({ perTestS, level }) => {
    expect(thresholdInfo(perTestS).level).toBe(level);
  });
});

describe('formatSignedDuration', () => {
  it.each`
    seconds | expected
    ${null} | ${'—'}
    ${12}   | ${'+12s'}
    ${130}  | ${'+2m 10s'}
    ${-5}   | ${'−5s'}
  `('formats $seconds as "$expected"', ({ seconds, expected }) => {
    expect(formatSignedDuration(seconds)).toBe(expected);
  });
});

describe('computeActionable', () => {
  const report = {
    perFile: {
      'spec/frontend/msw_integration/slow_spec.js': { runtimeS: 170, testCount: 9 },
      'spec/frontend/msw_integration/new_spec.js': { runtimeS: 12, testCount: 4 },
      'spec/frontend/msw_integration/renamed_spec.js': { runtimeS: 20, testCount: 5 },
      'spec/frontend/msw_integration/untouched_spec.js': { runtimeS: 99, testCount: 3 },
    },
  };
  const baseline = {
    perFile: {
      'spec/frontend/msw_integration/slow_spec.js': { runtimeS: 40, testCount: 8 },
      'spec/frontend/msw_integration/old_name_spec.js': { runtimeS: 18, testCount: 5 },
    },
  };

  it('diffs a modified file against its master baseline', () => {
    const changedFiles = [
      {
        path: 'spec/frontend/msw_integration/slow_spec.js',
        isNew: false,
        oldPath: 'spec/frontend/msw_integration/slow_spec.js',
      },
    ];

    const result = computeActionable({ changedFiles, report, baseline });

    expect(result.addedTests).toBe(1);
    expect(result.addedRuntimeS).toBe(130);
    expect(result.perTestS).toBe(130);
    expect(result.files[0]).toMatchObject({ masterTests: 8, currentTests: 9, deltaRuntimeS: 130 });
  });

  it('treats a brand-new file as fully added cost', () => {
    const changedFiles = [
      {
        path: 'spec/frontend/msw_integration/new_spec.js',
        isNew: true,
        oldPath: 'spec/frontend/msw_integration/new_spec.js',
      },
    ];

    const result = computeActionable({ changedFiles, report, baseline });

    expect(result.addedTests).toBe(4);
    expect(result.addedRuntimeS).toBe(12);
    expect(result.perTestS).toBe(3);
    expect(result.files[0]).toMatchObject({ isNew: true, masterTests: null, masterRuntimeS: null });
  });

  it('looks up a renamed file under its old path', () => {
    const changedFiles = [
      {
        path: 'spec/frontend/msw_integration/renamed_spec.js',
        isNew: false,
        oldPath: 'spec/frontend/msw_integration/old_name_spec.js',
      },
    ];

    const result = computeActionable({ changedFiles, report, baseline });

    // 20s / 5 tests now vs 18s / 5 tests on master → +2s, 0 net-new tests.
    expect(result.addedRuntimeS).toBe(2);
    expect(result.addedTests).toBe(0);
    expect(result.perTestS).toBeNull();
  });

  it('ignores changed files that did not run in this job', () => {
    const changedFiles = [
      {
        path: 'spec/frontend/msw_integration/deleted_from_run_spec.js',
        isNew: false,
        oldPath: 'spec/frontend/msw_integration/deleted_from_run_spec.js',
      },
    ];

    const result = computeActionable({ changedFiles, report, baseline });

    expect(result.files).toHaveLength(0);
    expect(result.perTestS).toBeNull();
  });

  it('aggregates across multiple files into a single per-test number', () => {
    const changedFiles = [
      {
        path: 'spec/frontend/msw_integration/slow_spec.js',
        isNew: false,
        oldPath: 'spec/frontend/msw_integration/slow_spec.js',
      },
      {
        path: 'spec/frontend/msw_integration/new_spec.js',
        isNew: true,
        oldPath: 'spec/frontend/msw_integration/new_spec.js',
      },
    ];

    const result = computeActionable({ changedFiles, report, baseline });

    // (130 + 12)s added over (1 + 4) new tests = 28.4s/test.
    expect(result.addedRuntimeS).toBe(142);
    expect(result.addedTests).toBe(5);
    expect(result.perTestS).toBeCloseTo(28.4);
  });
});

describe('buildComment', () => {
  const stats = { total: 100, passed: 99, failed: 0, skipped: 1, suites: 10, testDurationS: 300 };
  const baseline = {
    perFile: { 'spec/frontend/msw_integration/slow_spec.js': { runtimeS: 40, testCount: 8 } },
  };
  const baseArgs = {
    jobName: 'jest-msw-integration',
    jobUrl: 'https://example.com/job',
    ciDuration: 320,
    stats,
  };

  it('renders an Action-required callout when a new test blows the budget', () => {
    const actionable = {
      files: [
        {
          path: 'spec/frontend/msw_integration/slow_spec.js',
          isNew: false,
          currentRuntimeS: 170,
          masterRuntimeS: 40,
          deltaRuntimeS: 130,
          currentTests: 9,
          masterTests: 8,
          deltaTests: 1,
        },
      ],
      addedRuntimeS: 130,
      addedTests: 1,
      perTestS: 130,
    };

    const comment = buildComment({ ...baseArgs, baseline, actionable });

    expect(comment).toContain('<!-- msw-test-result-summary -->');
    expect(comment).toContain('🔴 **Action required**');
    expect(comment).toContain('+1 new test');
    expect(comment).toContain('130s/test');
    expect(comment).toContain('40s → 2m 50s');
    expect(comment).toContain('**jest-msw-integration**: ❌ [job log]');
    expect(comment).toContain('| ❌ | 100 | 99 | 0 |');
  });

  it('omits the delta and badge when no master baseline is available', () => {
    const actionable = { files: [], addedRuntimeS: 0, addedTests: 0, perTestS: null };

    const comment = buildComment({ ...baseArgs, baseline: null, actionable });

    expect(comment).toContain('No master baseline available yet');
    expect(comment).not.toContain('Action required');
    expect(comment).not.toContain('Warning');
    expect(comment).toContain('**jest-msw-integration**: ✅ [job log]');
  });

  it('reports missing report gracefully', () => {
    const comment = buildComment({ ...baseArgs, stats: null, baseline, actionable: null });

    expect(comment).toContain('no JSON report found');
  });

  it('renders a truncation warning when the diffs page cap is hit', () => {
    const actionable = { files: [], addedRuntimeS: 0, addedTests: 0, perTestS: null };

    const comment = buildComment({ ...baseArgs, baseline, actionable, truncated: true });

    expect(comment).toContain('⚠️ **Warning**: This MR changes 500+ files');
    expect(comment).toContain('the per-file breakdown is truncated');
  });

  it('omits the truncation warning when the breakdown is complete', () => {
    const actionable = { files: [], addedRuntimeS: 0, addedTests: 0, perTestS: null };

    const comment = buildComment({ ...baseArgs, baseline, actionable, truncated: false });

    expect(comment).not.toContain('per-file breakdown is truncated');
  });
});

describe('apiRequest', () => {
  const okResponse = (payload) => ({ ok: true, json: () => Promise.resolve(payload) });
  const errorResponse = (status) => ({
    ok: false,
    status,
    text: () => Promise.resolve(`status ${status}`),
  });

  beforeEach(() => {
    // Modern fake timers so `runAllTimersAsync` can flush the backoff sleeps
    // (the shared setup defaults to legacy timers, which lack the async API).
    jest.useFakeTimers({ legacyFakeTimers: false });
    // Retries log a warning before backing off; silence it so the shared
    // console guard does not fail the test.
    jest.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.useRealTimers();
    delete global.fetch;
  });

  it('returns the parsed JSON body on a successful response', async () => {
    global.fetch = jest.fn().mockResolvedValue(okResponse({ id: 7 }));

    await expect(apiRequest('GET', '/x')).resolves.toEqual({ id: 7 });
    expect(global.fetch).toHaveBeenCalledTimes(1);
  });

  it.each([429, 500, 503])('retries a transient %i and eventually succeeds', async (status) => {
    global.fetch = jest
      .fn()
      .mockResolvedValueOnce(errorResponse(status))
      .mockResolvedValueOnce(okResponse({ ok: true }));

    const promise = apiRequest('GET', '/x');
    await jest.runAllTimersAsync();

    await expect(promise).resolves.toEqual({ ok: true });
    expect(global.fetch).toHaveBeenCalledTimes(2);
  });

  it.each([401, 403, 404])('fails fast on non-retryable %i without retrying', async (status) => {
    global.fetch = jest.fn().mockResolvedValue(errorResponse(status));

    await expect(apiRequest('GET', '/x')).rejects.toThrow(`GitLab API ${status} on GET /x`);
    expect(global.fetch).toHaveBeenCalledTimes(1);
  });

  it('retries network errors and throws after exhausting attempts', async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error('ECONNRESET'));

    const promise = apiRequest('GET', '/x').catch((err) => err);
    await jest.runAllTimersAsync();

    await expect(promise).resolves.toThrow('ECONNRESET');
    // 1 initial call + 2 retries (MAX_API_ATTEMPTS = 3).
    expect(global.fetch).toHaveBeenCalledTimes(3);
  });
});
