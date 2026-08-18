#!/usr/bin/env node
// Posts (or updates) a "MSW Test Result Summary" comment on the current MR
// after a jest-msw-integration / jest-msw-integration vue3 job finishes.
//
// Called from the CI after_script — no external dependencies, uses only
// Node built-ins and the fetch API available in Node 18+.
//
// Required env vars (standard CI variables):
//   PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE
//   CI_API_V4_URL
//   CI_PROJECT_ID
//   CI_MERGE_REQUEST_IID  (only set for merge-request pipelines)
//   CI_JOB_NAME, CI_JOB_URL, CI_JOB_DURATION
//   CI_PROJECT_DIR        (used to normalise absolute report paths)
//
// Actionability model (see docs/superpowers/specs/2026-07-09-msw-actionable-runtime-signal-design.md):
//   - Detects the spec files this MR adds/changes (via the MR diffs API).
//   - For each changed file that ran in this job, diffs its runtime and test
//     count against the same file in the latest successful master run.
//   - Reduces the whole MR to one actionable number: seconds per NEW test.
//   - Flags OK (<15s/test), Warning (15–60s/test), Action required (>60s/test).
//   - Exits with code 1 when in the "action-required" range (after posting).

import { readFileSync, existsSync } from 'node:fs';
import { parseArgs } from 'node:util';

const MARKER = '<!-- msw-test-result-summary -->';

// ---------------------------------------------------------------------------
// Per-new-test time budget (seconds). MSW integration tests are heavier than
// unit tests, so the budget is generous compared to a plain unit test.
// ---------------------------------------------------------------------------
const BUDGET_OK_S = 15; // < 15 s/test  → OK
const BUDGET_ACTION_S = 60; // > 60 s/test  → action required (also exits 1)

// Frontend spec files follow the `_spec.js` naming convention.
const SPEC_FILE_RE = /_spec\.js$/;

// How far we page through the MR diffs API. 100 diffs/page × 5 pages = 500
// files — a generous safety cap. Past this the per-file breakdown is truncated,
// which we surface as a warning so the numbers stay trustworthy.
const DIFFS_PER_PAGE = 100;
const MAX_DIFF_PAGES = 5;

// Transient GitLab API failures are retried with exponential backoff.
const MAX_API_ATTEMPTS = 3;
const MAX_BACKOFF_S = 60;

function parseOptions() {
  const { values } = parseArgs({
    options: {
      'job-name': { type: 'string', default: process.env.CI_JOB_NAME ?? 'jest-msw-integration' },
      'report-path': { type: 'string', default: '' },
      // Path of the artifact *within the artifact archive* used to fetch the
      // master baseline report (e.g. "tmp/jest-msw-report.json").
      'artifact-path': { type: 'string', default: '' },
      'job-url': { type: 'string', default: process.env.CI_JOB_URL ?? '' },
      duration: { type: 'string', default: process.env.CI_JOB_DURATION ?? '0' },
      // Print the comment to stdout instead of posting it, and never exit 1.
      // Useful for verifying against a real MR locally without side effects.
      'dry-run': { type: 'boolean', default: false },
    },
    strict: false,
  });
  return {
    jobName: values['job-name'],
    reportPath: values['report-path'],
    artifactPath: values['artifact-path'],
    jobUrl: values['job-url'],
    duration: parseInt(values.duration, 10) || 0,
    dryRun: Boolean(values['dry-run']),
  };
}

function formatDuration(seconds) {
  if (seconds == null || seconds < 0) return '—';
  const rounded = Math.round(seconds);
  const m = Math.floor(rounded / 60);
  const s = rounded % 60;
  return m > 0 ? `${m}m ${s}s` : `${s}s`;
}

/**
 * Format a signed duration for a table cell, e.g. "+2m 10s" or "−5s".
 * Returns an em dash when the value is null.
 */
function formatSignedDuration(seconds) {
  if (seconds == null) return '—';
  const sign = seconds >= 0 ? '+' : '−';
  return `${sign}${formatDuration(Math.abs(seconds))}`;
}

/**
 * Normalise a Jest report's absolute `name` to a repo-relative path so it can
 * be matched against the MR diffs API and the master baseline report.
 * Jest records absolute paths like `/builds/gitlab-org/gitlab/spec/...`.
 */
function normalizeReportPath(absPath) {
  if (!absPath) return '';
  // Prefer extracting the well-known repo-relative spec segment; this is stable
  // regardless of the runner's build directory.
  const specMatch = absPath.match(/(?:^|\/)((?:ee\/)?spec\/.*)$/);
  if (specMatch) return specMatch[1];

  const root = process.env.CI_PROJECT_DIR || process.cwd();
  return absPath.startsWith(root) ? absPath.slice(root.length).replace(/^\/+/, '') : absPath;
}

/**
 * Build a per-file map of runtime and test count from a Jest --json report.
 *
 * Uses the sum of per-assertion `duration` (ms) rather than `perfStats` /
 * suite start-end timestamps: Jest's --json output has no `perfStats`, and the
 * MSW tests mock the system clock (every suite reports the same fake timestamp),
 * so only assertion durations remain a reliable measure.
 *
 * @returns {Object<string, { runtimeS: number, testCount: number }>}
 */
function perFileFromReport(data) {
  const perFile = {};
  for (const result of data.testResults ?? []) {
    const path = normalizeReportPath(result.name ?? '');
    if (!path) continue;
    const asserts = result.assertionResults ?? [];
    const runtimeMs = asserts.reduce((sum, a) => sum + (a.duration ?? 0), 0);
    perFile[path] = { runtimeS: runtimeMs / 1000, testCount: asserts.length };
  }
  return perFile;
}

function parseReport(reportPath) {
  if (!reportPath || !existsSync(reportPath)) return null;
  const data = JSON.parse(readFileSync(reportPath, 'utf8'));
  const perFile = perFileFromReport(data);
  const testDurationS = Object.values(perFile).reduce((sum, f) => sum + f.runtimeS, 0);

  return {
    total: data.numTotalTests ?? 0,
    passed: data.numPassedTests ?? 0,
    failed: data.numFailedTests ?? 0,
    skipped: (data.numPendingTests ?? 0) + (data.numTodoTests ?? 0),
    suites: data.numTotalTestSuites ?? 0,
    testDurationS: Math.round(testDurationS),
    perFile,
  };
}

function statusEmoji(stats, { jobFailed = false } = {}) {
  if (!stats) return '⚠️';
  return stats.failed > 0 || jobFailed ? '❌' : '✅';
}

/**
 * Returns threshold info for a given per-new-test duration in seconds.
 * @param {number|null} perTestS  added runtime divided by number of new tests
 * @returns {{ level: 'none'|'ok'|'warning'|'action', emoji: string, label: string }}
 */
function thresholdInfo(perTestS) {
  if (perTestS == null) return { level: 'none', emoji: '', label: '' };
  if (perTestS < BUDGET_OK_S) return { level: 'ok', emoji: '✅', label: 'OK' };
  if (perTestS <= BUDGET_ACTION_S) {
    return { level: 'warning', emoji: '⚠️', label: 'Warning' };
  }
  return { level: 'action', emoji: '🔴', label: 'Action required' };
}

/**
 * Diff each changed spec file that ran in this job against the master baseline
 * and reduce it to a single actionable number: seconds per new test.
 *
 * @returns {{
 *   files: Array<Object>,
 *   addedRuntimeS: number,
 *   addedTests: number,
 *   perTestS: number|null,
 * }}
 */
function computeActionable({ changedFiles, report, baseline }) {
  const reportPerFile = report?.perFile ?? {};
  const masterPerFile = baseline?.perFile ?? {};

  const files = [];
  let addedRuntimeS = 0;
  let addedTests = 0;

  for (const cf of changedFiles) {
    const current = reportPerFile[cf.path];
    // Only attribute cost to files that actually ran in this job's report.
    if (!current) continue;

    // Renamed files exist on master under their old path.
    const master = masterPerFile[cf.oldPath] ?? null;
    const masterRuntimeS = master?.runtimeS ?? 0;
    const masterTests = master?.testCount ?? 0;

    const deltaRuntimeS = current.runtimeS - masterRuntimeS;
    const deltaTests = current.testCount - masterTests;

    addedRuntimeS += deltaRuntimeS;
    addedTests += deltaTests;

    files.push({
      path: cf.path,
      isNew: cf.isNew || master == null,
      currentRuntimeS: current.runtimeS,
      masterRuntimeS: master == null ? null : masterRuntimeS,
      deltaRuntimeS,
      currentTests: current.testCount,
      masterTests: master == null ? null : masterTests,
      deltaTests,
    });
  }

  const perTestS = addedTests > 0 ? addedRuntimeS / addedTests : null;
  return { files, addedRuntimeS, addedTests, perTestS };
}

function buildFileRow(f) {
  const tag = f.isNew ? ' (new)' : '';
  const masterTestsStr = f.masterTests == null ? '—' : String(f.masterTests);
  const masterRtStr = f.masterRuntimeS == null ? '—' : formatDuration(f.masterRuntimeS);
  const deltaTestsStr = `${f.deltaTests >= 0 ? '+' : ''}${f.deltaTests}`;
  const perTest = f.deltaTests > 0 ? f.deltaRuntimeS / f.deltaTests : null;
  const perTestCell =
    perTest == null ? '—' : `${Math.round(perTest)}s ${thresholdInfo(perTest).emoji}`.trim();

  return `| \`${f.path}\`${tag} | ${masterTestsStr} → ${f.currentTests} (${deltaTestsStr}) | ${masterRtStr} → ${formatDuration(f.currentRuntimeS)} | ${formatSignedDuration(f.deltaRuntimeS)} | ${perTestCell} |`;
}

function buildComment({ jobName, jobUrl, ciDuration, stats, baseline, actionable, truncated = false }) {
  const threshold = thresholdInfo(actionable?.perTestS);
  // The budget gate exits 1 (failing the job) in the action-required range, so
  // the status reflects job outcome — ❌ even when every test itself passed.
  const emoji = statusEmoji(stats, { jobFailed: threshold.level === 'action' });
  const lines = [MARKER, '', '## MSW Test Result Summary', ''];

  if (!stats) {
    lines.push(`**${jobName}**: ${emoji} [job log](${jobUrl}) — no JSON report found`);
    lines.push('');
    return lines.join('\n');
  }

  const hasBaseline = baseline != null && Object.keys(baseline.perFile ?? {}).length > 0;

  // Header line with status + threshold badge.
  const badge = threshold.level !== 'none' ? ` — ${threshold.emoji} **${threshold.label}**` : '';
  lines.push(`**${jobName}**: ${emoji} [job log](${jobUrl})${badge}`);
  lines.push('');

  // The diffs API is paged up to a safety cap; past it some changed spec files
  // are missing, so the breakdown and aggregate numbers are understated.
  if (truncated) {
    lines.push(
      `> ⚠️ **Warning**: This MR changes ${DIFFS_PER_PAGE * MAX_DIFF_PAGES}+ files, so the per-file breakdown is truncated.`,
    );
    lines.push('');
  }

  // Single actionable headline.
  if (!hasBaseline) {
    lines.push('> ℹ️ No master baseline available yet — runtime delta omitted.');
  } else if (actionable.addedTests > 0) {
    const fileCount = actionable.files.length;
    lines.push(
      `**+${actionable.addedTests} new test${actionable.addedTests === 1 ? '' : 's'}** across ${fileCount} file${fileCount === 1 ? '' : 's'} · **${formatSignedDuration(actionable.addedRuntimeS)} vs master** · **${Math.round(actionable.perTestS)}s/test** (budget ${BUDGET_OK_S}s/test)`,
    );
  } else if (actionable.files.length > 0) {
    lines.push(
      `Changed ${actionable.files.length} spec file${actionable.files.length === 1 ? '' : 's'} with no net-new tests · **${formatSignedDuration(actionable.addedRuntimeS)} vs master**`,
    );
  } else {
    lines.push('No changed MSW spec files detected in this MR.');
  }
  lines.push('');

  // Per-file breakdown, collapsed to keep the comment quiet.
  if (actionable.files.length > 0) {
    lines.push('<details><summary>Per-file breakdown</summary>');
    lines.push('');
    lines.push('| File | Tests (master → now) | Runtime (master → now) | Δ Runtime | Per new test |');
    lines.push('| --- | --- | --- | --- | --- |');
    for (const f of actionable.files) lines.push(buildFileRow(f));
    lines.push('');
    lines.push('</details>');
    lines.push('');
  }

  // Callout only when it needs attention.
  if (threshold.level === 'action') {
    lines.push(
      `> 🔴 **Action required**: the tests this MR adds cost ~${Math.round(actionable.perTestS)}s each (budget ${BUDGET_OK_S}s/test). Please investigate slow tests before merging.`,
    );
    lines.push('');
  } else if (threshold.level === 'warning') {
    lines.push(
      `> ⚠️ **Warning**: the tests this MR adds cost ~${Math.round(actionable.perTestS)}s each (budget ${BUDGET_OK_S}s/test). Consider reviewing test performance.`,
    );
    lines.push('');
  }

  // Full suite stats as secondary context (collapsed, no longer drives the badge).
  lines.push('<details><summary>Full suite stats</summary>');
  lines.push('');
  const headers = ['', 'Tests', 'Passed', 'Failed', 'Skipped', 'Suites', 'Test duration', 'CI job duration'];
  lines.push(`| ${headers.join(' | ')} |`);
  lines.push(`| ${headers.map(() => '---').join(' | ')} |`);
  lines.push(
    `| ${emoji} | ${stats.total} | ${stats.passed} | ${stats.failed} | ${stats.skipped} | ${stats.suites} | ${formatDuration(stats.testDurationS)} | ${formatDuration(ciDuration)} |`,
  );
  lines.push('');
  lines.push('</details>');
  lines.push('');

  return lines.join('\n');
}

const sleep = (seconds) =>
  new Promise((resolve) => {
    setTimeout(resolve, seconds * 1000);
  });

// A 429 (rate limit) or 5xx is transient, and CI is flaky enough that a single
// blip should not stop us posting the summary. Other 4xx (401, 403, 404) are
// deterministic, so they fail fast and the "post a fresh comment" fallback
// still triggers immediately.
function isRetryableStatus(status) {
  return status === 429 || status >= 500;
}

/**
 * Perform a GitLab API request, retrying transient failures with exponential
 * backoff (2**attempt seconds, capped at MAX_BACKOFF_S). Network errors and
 * retryable statuses are retried up to MAX_API_ATTEMPTS times; other failures
 * throw immediately.
 */
async function apiRequest(method, path, body) {
  const token = process.env.PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE;
  const base = process.env.CI_API_V4_URL ?? 'https://gitlab.com/api/v4';

  // `attempt` recurses on the retry path; kept as an inner helper so the public
  // signature stays at three positional parameters.
  const attempt = async (n) => {
    const retry = async (reason) => {
      const backoffS = Math.min(2 ** n, MAX_BACKOFF_S);
      console.warn(
        `[MSW] ${reason} — retrying in ${backoffS}s (attempt ${n + 1}/${MAX_API_ATTEMPTS}).`,
      );
      await sleep(backoffS);
      return attempt(n + 1);
    };

    let res;
    try {
      res = await fetch(`${base}${path}`, {
        method,
        headers: { 'PRIVATE-TOKEN': token, 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined,
      });
    } catch (err) {
      // Network error (DNS failure, connection reset, timeout) — always retryable.
      if (n < MAX_API_ATTEMPTS) return retry(`Network error on ${method} ${path} (${err.message})`);
      throw err;
    }

    if (!res.ok) {
      if (isRetryableStatus(res.status) && n < MAX_API_ATTEMPTS) {
        return retry(`GitLab API ${res.status} on ${method} ${path}`);
      }
      const text = await res.text();
      throw new Error(`GitLab API ${res.status} on ${method} ${path}: ${text}`);
    }
    return res.json();
  };

  return attempt(1);
}

/**
 * Fetch the list of added/modified spec files in this MR from the diffs API.
 * Deleted files are ignored. Renamed files are treated as modified, keeping
 * the old path so their master baseline can be looked up.
 *
 * When the MR has more diffs than the page cap can cover, `truncated` is true:
 * some changed spec files may be missing from the breakdown, so the aggregate
 * numbers are understated and the comment surfaces a warning.
 *
 * @returns {Promise<{ files: Array<{ path: string, isNew: boolean, oldPath: string }>, truncated: boolean }>}
 */
async function fetchChangedSpecFiles(projectId, mrIid) {
  const files = [];
  let truncated = false;
  try {
    for (let page = 1; page <= MAX_DIFF_PAGES; page += 1) {
      // Pages fetched sequentially so we can stop once a short (last) page is hit.
      // eslint-disable-next-line no-await-in-loop
      const diffs = await apiRequest(
        'GET',
        `/projects/${projectId}/merge_requests/${mrIid}/diffs?per_page=${DIFFS_PER_PAGE}&page=${page}`,
      );
      if (!Array.isArray(diffs) || diffs.length === 0) break;
      for (const d of diffs) {
        if (d.deleted_file) continue;
        const newPath = d.new_path;
        if (!newPath || !SPEC_FILE_RE.test(newPath)) continue;
        files.push({
          path: newPath,
          isNew: Boolean(d.new_file),
          oldPath: d.renamed_file ? d.old_path : newPath,
        });
      }
      // A short page is the last page. A full page on the final iteration means
      // there may be more diffs we did not fetch — the breakdown is truncated.
      if (diffs.length < DIFFS_PER_PAGE) break;
      if (page === MAX_DIFF_PAGES) truncated = true;
    }
  } catch (err) {
    console.warn(`[MSW] Could not fetch MR changed files: ${err.message}`);
  }
  return { files, truncated };
}

/**
 * Fetch the master baseline for the given job name.
 *
 * Uses the "download a single artifact file by reference name" API, which
 * resolves to the artifact from the latest successful pipeline on `master`
 * for the given job — a single request instead of scanning pipelines and
 * their jobs (which in the worst case was dozens of API calls).
 *
 * Returns { perFile } or null when unavailable (e.g. no successful master run
 * has produced the artifact yet, which returns 404).
 */
async function fetchMasterBaseline(projectId, jobName, reportArtifactPath) {
  if (!reportArtifactPath) return null;

  try {
    const data = await apiRequest(
      'GET',
      `/projects/${projectId}/jobs/artifacts/master/raw/${reportArtifactPath}?job=${encodeURIComponent(jobName)}`,
    );
    console.log(`[MSW] Master baseline: latest successful "${jobName}" on master.`);
    return { perFile: perFileFromReport(data) };
  } catch (err) {
    console.log(`[MSW] No master baseline available (${err.message}) — skipping delta.`);
    return null;
  }
}

async function findExistingNote(projectId, mrIid) {
  // The summary is posted by the CI token's user, so match on author as well as
  // the marker: a stray marker string in a note from someone else must not be
  // mistaken for our comment. If we can't resolve the current user, fall back
  // to matching on the marker alone.
  let authorUsername = null;
  try {
    const me = await apiRequest('GET', '/user');
    authorUsername = me?.username ?? null;
  } catch (err) {
    console.warn(`[MSW] Could not resolve current user (${err.message}) — matching on marker only.`);
  }

  // Fetch up to 3 pages of notes (100 per page) to find an existing summary.
  for (let page = 1; page <= 3; page += 1) {
    // Pages must be fetched sequentially so we can stop early once a match or a
    // short (last) page is found, so awaiting inside the loop is intentional.
    // eslint-disable-next-line no-await-in-loop
    const notes = await apiRequest(
      'GET',
      `/projects/${projectId}/merge_requests/${mrIid}/notes?per_page=100&page=${page}&order_by=created_at&sort=desc`,
    );
    const hit = notes.find(
      (n) =>
        n.body?.includes(MARKER) &&
        (authorUsername == null || n.author?.username === authorUsername),
    );
    if (hit) return hit;
    if (notes.length < 100) break;
  }
  return null;
}

async function run() {
  const mrIid = process.env.CI_MERGE_REQUEST_IID;
  if (!mrIid) {
    console.log('Not a merge-request pipeline — skipping MSW summary comment.');
    return;
  }

  const token = process.env.PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE;
  if (!token) {
    console.warn('PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE not set — cannot post comment.');
    return;
  }

  const opts = parseOptions();
  const projectId = encodeURIComponent(process.env.CI_PROJECT_ID);
  const stats = parseReport(opts.reportPath);

  // Fetch the master baseline and the MR's changed files in parallel
  // (both best-effort — neither blocks the comment from posting).
  const [baseline, { files: changedFiles, truncated }] = await Promise.all([
    fetchMasterBaseline(projectId, opts.jobName, opts.artifactPath),
    fetchChangedSpecFiles(projectId, mrIid),
  ]);

  const actionable = computeActionable({ changedFiles, report: stats, baseline });

  const comment = buildComment({
    jobName: opts.jobName,
    jobUrl: opts.jobUrl,
    ciDuration: opts.duration,
    stats,
    baseline,
    actionable,
    truncated,
  });

  const threshold = thresholdInfo(actionable.perTestS);
  const perTestStr = actionable.perTestS != null ? `${Math.round(actionable.perTestS)}s` : '—';
  console.log(
    `[MSW] New tests: +${actionable.addedTests} | Added runtime: ${formatSignedDuration(Math.round(actionable.addedRuntimeS))} | Per new test: ${perTestStr} | ${threshold.label || 'no baseline'}`,
  );

  if (opts.dryRun) {
    console.log('\n[MSW] --dry-run: comment NOT posted. Rendered comment below:\n');
    console.log(comment);
    if (threshold.level === 'action') {
      console.log(`\n[MSW] --dry-run: would exit 1 (action required).`);
    }
    return;
  }

  const existing = await findExistingNote(projectId, mrIid);
  if (existing) {
    try {
      await apiRequest(
        'PUT',
        `/projects/${projectId}/merge_requests/${mrIid}/notes/${existing.id}`,
        { body: comment },
      );
      console.log(`Updated existing MSW summary comment (note ${existing.id}).`);
    } catch (err) {
      // The CI token can only edit notes it authored, so updating a note that
      // was created by a different user/token fails (typically 403). Fall back
      // to posting a fresh note; subsequent runs will find and update that one.
      console.warn(
        `Could not update note ${existing.id} (${err.message}) — posting a new comment instead.`,
      );
      await apiRequest('POST', `/projects/${projectId}/merge_requests/${mrIid}/notes`, {
        body: comment,
      });
      console.log('Posted new MSW summary comment.');
    }
  } else {
    await apiRequest('POST', `/projects/${projectId}/merge_requests/${mrIid}/notes`, {
      body: comment,
    });
    console.log('Posted new MSW summary comment.');
  }

  // Fail the pipeline when the per-new-test cost is in the "action-required"
  // range. The comment has already been posted, so reviewers see the details.
  if (threshold.level === 'action') {
    console.error(
      `🔴 [MSW] Action required: ${Math.round(actionable.perTestS)}s per new test (budget ${BUDGET_OK_S}s/test). Exiting with code 1.`,
    );
    process.exit(1);
  }
}

// Only run when invoked directly (node scripts/frontend/post_msw_test_summary.mjs).
// When imported by the unit test, the pure functions are exercised instead.
if (process.argv[1]?.endsWith('post_msw_test_summary.mjs')) {
  run().catch((err) => {
    // Posting the summary is best-effort: never fail the (already-finished)
    // job's after_script just because the comment could not be posted.
    console.warn(`Skipping MSW summary comment: ${err.message}`);
  });
}

export {
  BUDGET_OK_S,
  BUDGET_ACTION_S,
  formatDuration,
  formatSignedDuration,
  normalizeReportPath,
  perFileFromReport,
  parseReport,
  computeActionable,
  thresholdInfo,
  buildComment,
  apiRequest,
};
