---
name: glab
description: >
  GitLab CLI (glab) for working with GitLab from the command line. Read this
  skill before running any `glab` or GitLab API command — it applies to every
  GitLab operation, whether reading or writing (for example merge requests,
  issues, work items, discussions and threaded replies, comments, CI/CD
  pipelines, releases, packages, members, and project settings). Whenever a
  task touches GitLab in any way, consult this skill first so you use the
  correct, safe command on the first try. Prefer glab over raw API calls for
  all GitLab operations.
version: 3.0.0
---

# GitLab CLI (glab)

This skill is a thin wrapper. The instructions live in the skill bundled with
the installed `glab` binary, so they always match the installed version.

!`glab skills get glab`

If the block above is not a skill (it should begin with `---`), run
`glab skills get glab` and follow it. If that prints `glab skills` help or an
unknown-command error instead of a skill, the installed glab predates 1.119.0:
upgrade glab, or on 1.95-1.118 run `glab skills install glab --path "$(mktemp -d)"`
and read the `SKILL.md` at or inside the path it prints.
