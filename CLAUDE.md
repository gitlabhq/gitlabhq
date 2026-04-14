# GitLab Project Guidelines

This file provides default AI agent instructions for the GitLab project.
For customization options, see .ai/README.md.

## Local Overrides

Read @AGENTS.local.md

## Context Loading

Load the following instruction files based on your current task:

- When working with **git, commits, or branches**: Read .ai/git.md
- When working with **merge requests**: Read .ai/merge-requests.md
- When **reviewing code or giving feedback**: Read .ai/code-review.md
- When working with **database migrations or schema**: Read .ai/database.md
- When working with **tests (RSpec or Jest)**: Read .ai/testing.md
- When working with **code style or linting**: Read .ai/code-style.md
- When working with **CI/CD pipelines or `.gitlab-ci.yml`**: Read .ai/ci-cd.md

## Project Notes

- Default branch: `master`
- GitLab CI/CD pipelines can take 1-2 hours for a full run; do not assume failure if results are not immediately available
- Danger bot will comment on MRs with warnings; these are often non-blocking
- This repository is very large; use targeted searches and glob patterns
