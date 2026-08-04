# gitlab-ai-principles-distiller

Tooling that keeps `.ai/principles/distilled/*.md` in sync with the SSOT
documentation under `doc/development/`. It powers the scheduled weekly job in
`.gitlab/ci/sync-principles.gitlab-ci.yml`; see
[`.ai/principles/README.md`](../../.ai/principles/README.md) in the consuming
repository for the full operator-facing flow.

## Binaries

- `gitlab-ai-principles-distiller-sync` — the orchestrator. Detects per-principle
  drift via the existing checksum frontmatter, triggers one Duo Workflow per
  affected principle, polls each until terminal state, writes the result back,
  and (with `--push`) opens an MR via the REST API. Each per-team MR pings the
  people who changed the SSOT docs since the last distillation (resolved via a
  GraphQL `commits` query, so private and secondary emails match too), assigns
  up to three of them as reviewers, and falls back to one available `owner_team`
  member when no author resolves. Approval still routes to `owner_team` via
  CODEOWNERS.
- `gitlab-ai-principles-distiller-provision-flow` — idempotent provisioner for
  the AI Catalog Flow that the orchestrator drives. Runs before `sync` so prompt
  edits in git automatically propagate to the catalog.

## Run modes

Run with no mode flag, `sync` does everything in one process: scan, distill
every affected principle (four at a time), and publish. This is the local and
dry-run path.

Scheduled CI instead splits those stages across jobs, so each principle gets its
own CI job with its own timeout:

| Flag | Stage | Does |
|------|-------|------|
| `--generate-child-pipeline` | generate | Scans for drift and writes the child-pipeline YAML. Distills nothing. |
| `--distill-one NAME` | distill (one job per principle) | Distills exactly that principle and records the outcome as an artifact. Publishes nothing. |
| `--collect NAMES` | collect | Fans the artifacts back in and publishes. Distills nothing. |

The split exists because all principles previously shared a single 2 h job
budget. A principle that fails with invalid content burns roughly 20 minutes of
retry backoff, and that time was charged to every other principle: on
2026-07-30 the job timed out and discarded 19 successfully distilled principles
because the publish step was never reached.

Publishing stays a single job. It groups principles by owning team and builds
each team's branch against one shared working tree, so it cannot be split the
way distillation can.

### Artifact contract

Each `--distill-one` job writes two files under `tmp/ai-principles-distilled/`:
`<name>.status` (always) and `<name>.md` (only when the status is `updated`).
`--collect` reads them against the expected principle list and sorts each
principle into one of four states:

| Artifact | State |
|----------|-------|
| status `updated` + content | Publish it. |
| status `unchanged` | Ran cleanly, no meaningful diff. Nothing to publish. |
| status `failed` | Failed after retries. Reported, and the run exits non-zero. |
| no status file | The job never completed. Reported separately, and the run exits zero. |

The last two states are deliberately distinct. A principle whose job never ran
has not been shown to be undistillable, so reporting it as a distillation
failure would send an operator chasing a defect that does not exist. Either way
the principle keeps its committed checksum, so the next scheduled run
re-attempts it.

## Workspace

Both binaries operate on the consumer repository's working tree. The path is
discovered, in order:

1. `--workspace PATH` CLI flag.
2. `CI_PROJECT_DIR` environment variable.
3. Otherwise the script aborts with an explicit error.

## Required environment variables

| Variable | Purpose |
|----------|---------|
| `GITLAB_TOKEN` | Duo Workflow API + GraphQL polling. |
| `GITLAB_API_TOKEN` | Auto-MR creation via REST API. |
| `AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID` | Numeric ID of the catalog `ItemConsumer` that binds the distillation flow to the project. |

The CI job in `.gitlab/ci/sync-principles.gitlab-ci.yml` documents how these are
sourced from project CI/CD variables.
