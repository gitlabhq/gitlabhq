# GitLab Project Guidelines

This file provides default AI agent instructions for the GitLab project.
For customization options, see .ai/README.md.

## Local Overrides

Read @CLAUDE.local.md

## Context Loading

Load the following instruction files based on your current task:

- When working with **git, commits, or branches**: Read .ai/git.md
- When working with **merge requests**: Read .ai/merge-requests.md
- When **reviewing code or giving feedback**: Read .ai/code-review.md
- When working with **CI/CD pipelines or `.gitlab-ci.yml`**: Read .ai/ci-cd.md
- Before planning, implementing, OR reviewing code changes (including MR reviews), load the `gitlab-coding-principles` skill. This applies even when `.ai/code-review.md` is also loaded.

## Always-on rules

These apply to every task without needing a trigger:

- **Minimal fix** — apply the smallest change that fixes the root cause rather than the symptom; no refactors, cleanups, or unrelated improvements, and no edits outside the repo you were pointed at — if the real fix requires either, say so and explain why instead of doing it silently.
- **Security fixes** — treat an issue as requiring a special security fix when the issue is confidential, has the `~security` label, and does NOT have the `~security-fix-in-public` label. When all three hold, DO NOT push to `gitlab-org/gitlab` (or any canonical repo); follow .ai/security-fixes.md
- **Comment discipline** — cap comments at 1-3 lines and only add one when the why is non-obvious, like an invariant, a gotcha, or a tradeoff; delete comments that just restate the code, by default, not only when asked to trim
- **Prose via subagent** — on a high-capability model, write human-facing prose (comments, MR/issue text, docs) via a mid-tier model subagent instead of typing it inline, since high-capability models tend to produce dense, jargon-heavy prose; brief it with the facts and constraints, then check its output for accuracy; on a mid-tier model, just write it directly

## AI-authored GitLab comments

Wrap the full body of any comment, note, or reply you post to GitLab (issues,
merge requests, epics — via `glab`/`glab api`) in `<:robot:>` / `</:robot:>`
tags (GitLab emoji shortcode, renders as 🤖), so readers can tell at a glance
that it's AI-generated:

```
<:robot:>

...full comment body...

</:robot:>
```

This applies to newly posted comments. It does not apply to code, commit
messages, or MR/issue descriptions unless asked.

## Project Notes

- Default branch: `master`
- GitLab has extensive CI/CD pipelines; be patient with pipeline results
- Danger bot will comment on MRs with warnings; these are often non-blocking
- This repository is very large; use targeted searches and glob patterns

## Fix Pipeline

### Job-name stop rules

Skip the failing job whose name equals `danger-review`. Do not fetch its logs or attempt to fix it. Continue investigating and fixing all other blocking failing jobs. Take no action only when every blocking failing job matches the filters specified.

### Merge requests

When opening a merge request as part of the Fix Pipeline flow (the title contains `[FixPipeline]`), apply labels based on the source of the run. The `<fix_pipeline_source>` block in your instructions contains exactly one of `merge_request`, `default_branch`, or `branch` — use it to determine which case applies.

- **`merge_request`**: apply `pipeline::tier-1`. This runs the cheaper tier-1 pipeline instead of the full default pipeline.
- **`default_branch`**: apply both `pipeline::expedited` and `master:broken`. The expedited label fast-tracks the fix through CI by skipping non-essential jobs; the master:broken label marks the MR as a broken-master fix. Do not apply `pipeline::tier-1` in this case.
- **`branch`**: apply `pipeline::tier-1`. Same treatment as the `merge_request` case — a fix MR for a non-default branch pipeline failure with no originating MR.

### Known failures and CI health context

Before diagnosing a failure, check whether it matches a known active incident. Three sources:

- [ci-health-incidents](https://gitlab.com/gitlab-org/quality/analytics/ci-health-incidents/-/issues?state=opened&label_name[]=ci-health%3A%3Aactive) — test file failures, failure categories, uncategorized job failures
- [ci-health-systemic](https://gitlab.com/gitlab-org/quality/analytics/ci-health-systemic/-/issues?state=opened&label_name[]=ci-health%3A%3Aactive) — recurring systemic failures affecting many pipelines
- [top flaky test files](https://gitlab.com/gitlab-org/quality/test-failure-issues/-/issues?state=opened&label_name[]=automation%3Atop-flaky-test-file&label_name[]=automation%3Abot-authored) — known flaky test files

Each ci-health incident title names the affected test file, failure category, or job. The flaky test issues title the affected spec file.

If the failing job or test matches an open issue in any of these:

1. Link to the issue in your response or fix MR description.
1. Use it to guide your approach:
   - **Infra failure** (`failed_to_pull_image`, `runner_system_failure`, etc.): no code fix is possible. Post a comment with the incident link. Do not open a fix MR.
   - **Known flaky test**: the failure may be unrelated to the MR. Note this and link the issue, but still check whether the MR changes could have contributed.
   - **Known failure category** (`docs_outdated`, `rake_outdated_translated_strings`, etc.): likely unrelated to the MR. Post a comment with the incident link rather than attempting a code fix.
