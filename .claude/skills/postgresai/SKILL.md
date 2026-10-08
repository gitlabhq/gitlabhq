---
name: postgresai
description: "Run EXPLAIN / EXPLAIN ANALYZE, test indexes, and measure query cost on PostgresAI Database Lab thin clones with the PostgresAI CLI (postgresai, pgai, Joe). Use when asked to explain or optimize a query, check a plan at production scale, try an index on realistic data, or prepare a GitLab database review."
version: 1.0.3
license: MIT
category: Database
---

# PostgresAI CLI (Database Lab / Joe)

Run `EXPLAIN` and DDL experiments on ephemeral thin clones of production-sized data
from the terminal, not the Joe chat bot.

## When to Use

- Checking query plans at production scale, or testing an index or migration on a thin clone.
- Collecting queries and plans as evidence for a database review.

Not for local development databases (GitLab: use `gitlab-psql`).

## Install

Prefer npm: `npm i -g postgresai` (or `npx postgresai ...`); binaries `postgresai`, `pgai`.
Don't rely on a Homebrew tap; it may no longer exist.

## Authenticate

`postgresai auth show-key` shows whether a key is stored; if not, run `postgresai login` (browser
OAuth, callback on `127.0.0.1`, `--port` selectable). Headless: `login --set-key <key>` or
`PGAI_API_KEY`. Never commit or print the key.

## Pick the target

```shell
postgresai projects        # JOE column shows which projects are ready
```

Pass `--project <id|alias>` (or `--instance-id <id>`) to `joe`, or store a default with
`postgresai set-default-project <alias>`; `joe --help` wrongly says `--project` is always required.
Prefer JOE `ready` entries (skips stale `-deprecated`/`-new` duplicates); ask the user if ambiguous.

## Core loop

Run `joe` through [scripts/joe.sh](scripts/joe.sh) (path relative to this skill): same arguments as
`postgresai joe`, but it waits out the CLI's poll budget and prints only the result.

```shell
J=scripts/joe.sh; P="--project <alias>"
$J plan     $P "SELECT ..."            # estimates only, never executes: default
$J explain  $P "SELECT ..."            # EXPLAIN + ANALYZE + buffers, executes on clone
$J describe $P <table>                 # \d-style metadata
$J exec     $P "CREATE INDEX ..."      # real DDL on the clone; prints only the duration
$J exec     $P "ANALYZE <table>"       # refresh stats, then `explain` again to re-measure
$J reset    $P                         # discard experiments
```

Plans and iterating: [references/plan-analysis.md](references/plan-analysis.md).

## Gotchas

- **Budget:** plain `postgresai joe` returns exit 0 after `--budget` (default 25 s) with
  `started <id> · pending … resume: pgai joe result <id>`; the command keeps running (`result`
  exits 1 while pending). `joe.sh` polls (`JOE_WAIT_SECONDS`, default 600; raise it for big tables).
- **Don't `reset` to stop a slow command** (kills pending work, `conn closed`): use
  `joe activity` and `joe terminate <pid>`.
- **`hypo` (HypoPG) didn't persist between CLI calls**: test indexes with `exec CREATE INDEX` +
  `exec ANALYZE` + `explain` (see plan-analysis).
- `explain` and `exec` really execute: bound queries (`LIMIT`, tenant/project id). `exec` returns no rows.
- **Clone creation can fail** (`failed to create a Database Lab clone`). Stop using that target
  for the session (`explain`/`reset` fail the same way), report it, don't retry in a loop. Switch
  target only if another database can answer the question.
- JSON output and explicit clones: [references/advanced.md](references/advanced.md).

## Safety rules

- Experiment only through the clone commands; never run writes or DDL against production or
  replicas by any other route. Always `joe reset` when finished.
- Clone data is real production data. **Never paste row values, emails, tokens or
  result sets** into public MRs, issues, or repos. Share SQL, plans with literals
  replaced by placeholders, and timings/buffer counts only.
- Clones may enforce statement timeouts; don't retry them in a loop.

## GitLab-specific

GitLab monolith: target aliases in [references/gitlab.md](references/gitlab.md); review flow in
[references/db-review-flow.md](references/db-review-flow.md).

## CLI reference (live)

Flags change between releases; check the installed CLI:

!`postgresai joe --help 2>&1 | head -30`

## Contributing Improvements

This skill is maintained in [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) at
`.claude/skills/postgresai/`.
If you discover that any guidance here is **inaccurate or outdated** (e.g. a command that no
longer works, a wrong flag, CLI output drift that breaks `scripts/joe.sh`), confirm with the
user and open an MR against `gitlab-org/gitlab` with the fix. Keep changes focused — one fix per MR.
