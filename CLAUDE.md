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

- **Minimal fix** — apply the smallest change that solves the problem; do not expand scope across layers unless each layer is genuinely load-bearing

## Project Notes

- Default branch: `master`
- GitLab has extensive CI/CD pipelines; be patient with pipeline results
- Danger bot will comment on MRs with warnings; these are often non-blocking
- This repository is very large; use targeted searches and glob patterns

## Fix Pipeline merge requests

When opening a merge request as part of the Fix Pipeline flow (the title contains `[FixPipeline]`), apply labels based on the source of the run. The `<fix_pipeline_source>` block in your instructions contains exactly one of `merge_request`, `default_branch`, or `branch` — use it to determine which case applies.

- **`merge_request`**: apply `pipeline::tier-1`. This runs the cheaper tier-1 pipeline instead of the full default pipeline.
- **`default_branch`**: apply both `pipeline::expedited` and `master:broken`. The expedited label fast-tracks the fix through CI by skipping non-essential jobs; the master:broken label marks the MR as a broken-master fix. Do not apply `pipeline::tier-1` in this case.
- **`branch`**: apply `pipeline::tier-1`. Same treatment as the `merge_request` case — a fix MR for a non-default branch pipeline failure with no originating MR.
