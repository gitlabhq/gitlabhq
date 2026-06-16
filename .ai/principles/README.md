# SSOT-driven Agent Principles

This directory holds the GitLab development principles distilled from
docs.gitlab.com. They are loaded automatically by code-authoring agents
(Claude Code, OpenCode, Duo Agent Platform) when working on relevant
areas of the codebase.

## Structure

```
principles/
  manifest.yml            # Manifest: SSOT doc paths, file filters, baselines per principle
  distillation_prompt.md # Source of truth for the catalog agent's system prompt
  distilled/             # Auto-generated principle files (one per domain) — DO NOT EDIT
  baselines/             # Hand-curated supplements that survive distillation verbatim
```

## How the sync works

The distillation pipeline has two cooperating parts:

1. **`gitlab-ai-principles-distiller-provision-flow`** (in `gems/gitlab-ai-principles-distiller/bin/`) mirrors
   `distillation_prompt.md` and a fixed read-only tool allowlist into the
   AI Catalog Flow named **"Agent Principles Distiller"**. It is
   idempotent: it creates the flow on first run, releases a new version
   only when the YAML definition has drifted, and ensures an
   `ItemConsumer` exists that binds the flow to the configured project.

   A *Flow* is required (rather than a bare *Agent*) because the Workflow
   API's `ai_catalog_item_consumer_id` parameter only accepts items of
   type `flow` — see
   [`ee/app/services/ai/catalog/flows/execute_service.rb`][execute_service].
   The flow's YAML definition has a single `AgentComponent` whose system
   prompt carries our distillation rules.

2. **`gitlab-ai-principles-distiller-sync`** (in `gems/gitlab-ai-principles-distiller/bin/`) triggers a Duo Workflow per
   affected principle through the [Workflow API][workflow-api]. Each
   workflow runs the catalog flow in a child CI pipeline that reads the
   current distilled file, the SSOT sources, and the optional baseline
   file directly from the source branch via gitaly — no file content is
   inlined into the API request. Once the workflow finishes, the script
   extracts the assistant's response from the workflow's GraphQL
   representation and writes it to disk. When run with `--push`, the
   script then opens an MR with the diff.

[execute_service]: https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/services/ai/catalog/flows/execute_service.rb

[workflow-api]: https://docs.gitlab.com/api/duo_workflows/

The script runs in two contexts:

1. **Locally**, ad-hoc, by maintainers when source docs change.
2. **Automatically in CI** — a periodic scheduled pipeline runs the script
   and opens an MR if any principle has drifted (see
   [`.gitlab/ci/sync-principles.gitlab-ci.yml`](../../.gitlab/ci/sync-principles.gitlab-ci.yml)).

### Pipeline schedule

The CI job is gated on:

- `$CI_PROJECT_PATH == "gitlab-org/gitlab"`
- `$CI_PIPELINE_SOURCE == "schedule"`
- `$SCHEDULE_TYPE == "weekly"` (the cadence is configurable via the
  pipeline schedule's `SCHEDULE_TYPE` variable; weekly is the current
  cadence but the gating rule reuses GitLab's existing
  `&if-default-branch-schedule-weekly` anchor)
- `$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH`

Configured at <https://gitlab.com/gitlab-org/gitlab/-/pipeline_schedules>
with a cron expression matching the chosen cadence (e.g. `0 6 * * 1`
for Monday 06:00 UTC) and the corresponding `SCHEDULE_TYPE` variable.

### Required CI variables

| Variable                                    | Purpose                                                                                                                                                                  |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `AGENT_PRINCIPLES_SERVICE_ACCOUNT_TOKEN`    | Classic PAT with `api` scope (and `ai_features` per the [External Agents recipe](https://docs.gitlab.com/user/duo_agent_platform/agents/external/#create-a-service-account)) used as both `GITLAB_TOKEN` (Workflow API + GraphQL) and `GITLAB_API_TOKEN` (auto-MR REST). Currently a maintainer's personal token; see [Service account auth](#service-account-auth-why-a-pat-today). Fine-grained PATs cannot drive this job: they do not cover GraphQL, AI Catalog mutations, or the Duo Workflow create/start endpoint. |
| `AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID` | Numeric ID returned by `aiCatalogItemConsumerCreate` when binding the catalog flow to `gitlab-org/gitlab`. Printed by `gitlab-ai-principles-distiller-provision-flow`.          |

### Service account auth: why a PAT today

The Duo Agent Platform Workflow API requires the calling identity to
have a Duo Agent Platform seat. Project access tokens (such as
`PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE`) are bound to bot users that
do not hold seats, so they cannot drive this job.

The supported sustainable pattern is a service account auto-provisioned
when an AI Catalog flow's `ItemConsumer` is created at the **group**
level. That service account is added to all the group's projects as a
Developer, has `composite_identity_enforced` set, and authenticates the
Workflow API in tandem with the human user who triggered the workflow
(e.g. via a `mention` or `pipeline_hooks` flow trigger).

Provisioning a group-level consumer for `gitlab-org` requires Owner
access on that group, which the maintainer of this MR does not have.
For now, `AGENT_PRINCIPLES_SERVICE_ACCOUNT_TOKEN` holds a maintainer's
personal access token. The maintainer who owns this CI variable is
responsible for token rotation and is the user attributed to the
auto-generated MRs. Migration to a dedicated service account is tracked
in access request
[!43931](https://gitlab.com/gitlab-com/team-member-epics/access-requests/-/issues/43931).

### Service account auth: composite identity with a service account as the invoker

The canonical pattern for invoking the Workflow API is
[composite identity](https://docs.gitlab.com/user/duo_agent_platform/composite_identity/):
an OAuth token where a service account owns the token but the invoking
human's `user_id` is embedded in a dynamic scope, with authorization
enforced as the intersection of the SA's and the human's permissions
(see [epic gitlab-org&19478](https://gitlab.com/groups/gitlab-org/-/epics/19478)).

Because we always pass `ai_catalog_item_consumer_id`, the Workflow API
**does** mint a composite-identity OAuth token server-side. The flow's
own service account (provisioned when the AI Catalog item is created)
has `composite_identity_enforced: true`, and the endpoint binds the
caller's `user_id` to that SA before issuing a token scoped to
`ai_workflows` + `mcp` (see [`workflows.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/api/ai/duo_workflows/workflows.rb#L599)
and
[`WorkflowContextGenerationService`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/services/ai/duo_workflows/workflow_context_generation_service.rb)).

The deviation from the canonical pattern is on the *caller* side, not
on the SA side: the "user" in composite identity is itself a service
account (the AR-provisioned `AGENT_PRINCIPLES_SERVICE_ACCOUNT_TOKEN`
holder), not a human. The weekly scheduled CI job has no human invoker
at trigger time; the schedule runs autonomously against `master`. GitLab
acknowledges autonomous workloads as a known extension area and is
considering support for linking composite identities with non-human
principals (see
[the AI security blog post](https://about.gitlab.com/blog/improve-ai-security-in-gitlab-with-composite-identities/)).

In summary: the canonical composite-identity machinery is engaged; the
only unusual part is that the OAuth token's `user_id` scope binds to a
service account rather than a human. `composite_identity_enforced`
on the AR-provisioned SA is therefore not required — only the flow's
SA needs that flag set.

Compensating controls for the SA-as-invoker shape:

- PAT scope `api`, expiry ≤1 year, rotation reminder at month 11 (see
  the runbook below).
- CI variable `AGENT_PRINCIPLES_SERVICE_ACCOUNT_TOKEN` is **Masked**
  during pre-merge testing (so the temporary `merge_request_event`
  rule can use it), and becomes **Protected** as the final pre-merge
  step in
  [MR !235014](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235014).
  Post-merge, the only consumer is the scheduled pipeline on the
  protected `master` ref.
- The SA holds Developer role on `gitlab-org/gitlab` — it cannot push
  to `master` directly.
- Auto-MRs target `master`. The weekly sync fans out into one MR per
  SSOT-owning team (plus a separate tooling MR for the global routing
  tables); per-file CODEOWNERS rules route each MR's approval to the
  team that owns the corresponding SSOT doc. See [Reviewing
  auto-generated MRs](#reviewing-auto-generated-mrs).

Revisit this design when DAP supports non-human-bound principals.

### Schedule ownership & recovery

The pipeline schedule that drives this job is **owned by the service
account**, not by any individual. The bus-factor risk is mitigated by:

- Three named **admin users** on access request !43931 (Pedro Pombeiro,
  Cheryl Li, Fabio Pitino) who can sign in as the SA to rotate
  credentials or take ownership of the schedule.
- A documented **PAT rotation procedure** (calendar reminder at month
  11; new PAT scoped to `api`, ≤1 year expiry; update CI variable
  `AGENT_PRINCIPLES_SERVICE_ACCOUNT_TOKEN` on `gitlab-org/gitlab`;
  revoke old). The PAT credential is stored in a 1Password vault named
  on the access request.
- GitLab's
  [`pipelineScheduleTakeOwnership`](https://docs.gitlab.com/api/graphql/reference/#mutationpipelinescheduletakeownership)
  mutation lets any project Maintainer or Owner reassign schedule
  ownership if the SA becomes unavailable.

Precedent for non-individual-owned schedules on `gitlab-org/gitlab`
exists (e.g. nightly maintenance, ruby-next, rails-next, weekly
Elasticsearch), historically owned by
[`gitlab-bot`](https://gitlab.com/gitlab-bot). Current guidance has
moved away from a single shared bot account toward **dedicated SAs per
need**, which is exactly the model this access request provisions — the
SA created here is the recommended end state.

## Reviewing auto-generated MRs

Sync MRs are labelled `ai-agent` and `documentation`. They are not
auto-merged — a human must verify that the distilled changes faithfully
reflect the source-doc updates before merging.

Each per-team MR's approval is routed to the SSOT-owning team via the
generated per-file rules in
[`.gitlab/CODEOWNERS`](../../.gitlab/CODEOWNERS) (see [Manifest
schema](#manifest-schema)). The separate tooling MR, which carries only
the global routing tables (AGENTS.md, CLAUDE.md, SKILL.md), falls back
to the broad `/.ai/` and `/.claude/` AI-harness owners.

## Running the sync locally

Both binaries operate on the consuming repository's working tree, which they
discover from `--workspace PATH`, then `CI_PROJECT_DIR`, then abort. Run them
from the gem directory so Bundler resolves dependencies:

```shell
cd gems/gitlab-ai-principles-distiller
bundle install

# These env vars are normally set by the CI pipeline. For local runs,
# export them explicitly (they are repeated in every example below):
#   - AGENT_PRINCIPLES_CATALOG_PROJECT: project that owns the AI Catalog
#     flow; required by both binaries.
#   - CI_DEFAULT_BRANCH: the repo default branch; required by the sync
#     binary to resolve the workflow source branch.
#   - CI_PROJECT_ID: numeric project ID; required by the sync binary only
#     when --push is given (used to create the MR). 278964 = gitlab-org/gitlab.

# Step 1 (one-time, or whenever distillation_prompt.md changes):
GITLAB_TOKEN=<personal-access-token> \
AGENT_PRINCIPLES_CATALOG_PROJECT=gitlab-org/gitlab \
  bundle exec bin/gitlab-ai-principles-distiller-provision-flow \
    --workspace "$(git rev-parse --show-toplevel)"
# Note the printed AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID value.

# Step 2: dry run (show what would change without writing or pushing)
AGENT_PRINCIPLES_CATALOG_PROJECT=gitlab-org/gitlab \
  bundle exec bin/gitlab-ai-principles-distiller-sync \
    --workspace "$(git rev-parse --show-toplevel)" --dry-run

# Step 3: distill only specific principles
GITLAB_TOKEN=<token> \
CI_DEFAULT_BRANCH=master \
AGENT_PRINCIPLES_CATALOG_PROJECT=gitlab-org/gitlab \
AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID=<id> \
  bundle exec bin/gitlab-ai-principles-distiller-sync \
    --workspace "$(git rev-parse --show-toplevel)" \
    --only feature-flags,workers

# Force re-distillation (ignore checksum cache)
GITLAB_TOKEN=<token> \
CI_DEFAULT_BRANCH=master \
AGENT_PRINCIPLES_CATALOG_PROJECT=gitlab-org/gitlab \
AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID=<id> \
  bundle exec bin/gitlab-ai-principles-distiller-sync \
    --workspace "$(git rev-parse --show-toplevel)" --force

# End-to-end: distill, branch, commit, push, open MR
GITLAB_TOKEN=<token> \
GITLAB_API_TOKEN=<token> \
CI_DEFAULT_BRANCH=master \
CI_PROJECT_ID=278964 \
AGENT_PRINCIPLES_CATALOG_PROJECT=gitlab-org/gitlab \
AGENT_PRINCIPLES_CATALOG_ITEM_CONSUMER_ID=<id> \
  bundle exec bin/gitlab-ai-principles-distiller-sync \
    --workspace "$(git rev-parse --show-toplevel)" --push
```

The Workflow API runs the agent server-side from the **pushed** state of
the configured `source_branch`. If you have local edits that haven't been
pushed, the catalog agent will not see them. Push your branch (or commit
to it) before triggering a distillation.

## Manifest schema

Each entry under `principles:` in
[`manifest.yml`](manifest.yml) supports these fields:

- `description` (required) — one-line summary used in the AGENTS.md /
  SKILL.md routing tables.
- `sources` (required) — list of SSOT doc paths (`path`, `url`) the
  principle is distilled from.
- `owner_team` (required) — the CODEOWNERS handle of the team that owns
  the SSOT doc(s). This is the axis the weekly sync fans out by: each
  per-team MR touches only that team's distilled files, and a generated
  per-file CODEOWNERS rule routes the approval to this team. May be a
  group handle (`@gitlab-org/maintainers/database`) or one or more
  individuals (`@abdwdd @alexpooley`) when no group handle exists.
- `secondary_teams` (optional) — additional CODEOWNERS handles to
  mention in a "Request a review from" section of the MR description,
  for SSOT docs whose changes also concern another team. The primary
  `owner_team` still owns the approval; secondary teams are notified,
  not required.
- `team_slug` (optional) — branch/title suffix for the per-team MR.
  Defaults to the last path segment of `owner_team` (e.g.
  `@gitlab-org/maintainers/database` → `database`). Set it explicitly
  when that segment is generic and would **collide** across teams — for
  example `.../authentication/approvers` and `.../authorization/approvers`
  both end in `approvers`, so they declare `authentication` and
  `authorization` respectively. Also set it for individual-handle owners
  (e.g. `qa`).
- `group` (optional) — display grouping in the routing tables only; it
  does **not** affect approval routing (that is `owner_team`).
- `prerequisite`, `file_filters`, `baseline` — see existing entries.

The per-file CODEOWNERS rules are **generated** from `owner_team` /
`secondary_teams` into a managed block in
[`.gitlab/CODEOWNERS`](../../.gitlab/CODEOWNERS) (delimited by
`# BEGIN/END GENERATED: gitlab-ai-principles-distiller`), inserted right
after the broad `/.ai/` rule so CODEOWNERS last-match-wins routes each
file to its owning team. Do not edit that block by hand; re-run the sync
(or the static-artifact regeneration) to refresh it.

## Modifying principles

To change a distilled principle's content:

- Update its source doc on docs.gitlab.com.
- Or update the matching `baselines/<name>.md` file for procedural
  knowledge that has no SSOT home.

Then re-run the sync (`--only <name>`) to regenerate `distilled/<name>.md`.

To change the **distillation rules themselves**, edit
`distillation_prompt.md` and re-run
`gitlab-ai-principles-distiller-provision-flow` to roll the new prompt out to
the catalog flow.

## Known limitations

### Transient Gitaly load failures

The Duo Workflow runtime fetches files from the repository via Git's
promisor protocol (partial clone). On large repositories like
`gitlab-org/gitlab`, Gitaly nodes occasionally return transient load
errors during these fetches:

```
fatal: remote error: GitLab is currently unable to handle this request due to load
fatal: could not fetch <sha> from promisor remote
```

When this happens, the Duo Workflow ends in `FAILED` state with no
checkpoints, and the affected principles are not updated. The script
retries each principle up to 3 times with exponential backoff (5min,
15min, 30min between attempts) to ride out short-lived load spikes. If
all retries are exhausted, the run exits non-zero with a clear error
listing the affected principles.

Since the weekly schedule fires again the following week, no manual
intervention is required — the system is self-healing over time. Failed
runs leave the repository in a consistent state: no partial commits, no
orphan branches, and the existing distilled files untouched.
