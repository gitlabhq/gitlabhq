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
  and (with `--push`) opens an MR via the REST API.
- `gitlab-ai-principles-distiller-provision-flow` — idempotent provisioner for
  the AI Catalog Flow that the orchestrator drives. Runs before `sync` so prompt
  edits in git automatically propagate to the catalog.

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
