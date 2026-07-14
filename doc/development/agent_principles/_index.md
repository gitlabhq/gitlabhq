---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: AI development principles
description: How AI development principles are distilled from documentation and how to add a new principle group.
---

GitLab distills development conventions from `doc/development/` into principle
files that AI agents load when they plan or implement changes. The resulting
code follows the conventions a human reviewer would expect.

Use this page if your team maintains documentation under `doc/development/`
and wants AI principles distilled from it.

For the operational runbook (CI variables, service account auth, schedule
recovery), see
[`.ai/principles/README.md`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ai/principles/README.md)
in the repository.

## How the sync works

A scheduled CI job on `gitlab-org/gitlab` runs every week and performs the
following steps:

1. Reads `.ai/principles/manifest.yml` to determine which documentation files
   each principle is derived from.
1. Detects drift by [comparing a checksum](https://gitlab.com/gitlab-org/gitlab/-/blob/4ebf19a1419cd0737352253fa858b2af8edb8fab/gems/gitlab-ai-principles-distiller/lib/gitlab/principles_distiller/sync/manifest.rb#L110-127)
   over each principle's manifest entry, baseline, and source files against
   the checksum stored in the front matter of the existing distilled file.
1. For each principle that has drifted, calls the
   [GitLab Duo Agent Platform](../duo_agent_platform/_index.md) Workflow API to
   regenerate the distilled file from the current source documentation.
1. Writes the regenerated files to `.ai/principles/distilled/`.
1. Opens a merge request when any file changed. The merge request targets the
   default branch and requires human approval before merging.

Distillation runs server-side. The agent reads source files from the branch
the sync runs against (the default branch for the weekly schedule).

The script that drives the sync is the
[`gitlab-ai-principles-distiller`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-ai-principles-distiller)
gem.

For a diagram of the full flow, see [AI principles distillation flow](distillation_flow.md).

## Add a principle group

Use this procedure when your team owns documentation under `doc/development/`
and you want distilled principles generated from it.

A principle group (for example, Database, Frontend, Testing) typically
contains several related principles that share a `group:` label in the
manifest. Each principle in the group becomes one distilled file.

Split a group into multiple principles when:

- The source documentation is large enough that the distilled file would
  be hard to skim in one pass.
- Different principles apply to different repository paths and benefit
  from separate `file_filters:`.

For example, the Database group contains `database-fundamentals`,
`database-migrations`, `database-schema`, and `database-queries`.

1. Identify the source files for each principle. Each source file must:
   - Live under `doc/development/`.
   - Be reachable on the default branch (the sync reads from there).
   - Belong to one principle. If a source file applies to multiple
     principles, list it under each of them.
1. Choose a slug for each principle. Use kebab-case and a shared prefix
   for principles in the same group. For example, `database-migrations`,
   `database-schema`, `database-queries` all share the `database-` prefix
   and the `group: Database` label.
1. Add one entry per principle to `.ai/principles/manifest.yml` under the
   `principles:` key. For the schema, see
   [Manifest reference](manifest_reference.md). At a minimum, you need
   `description`, `group`, and `sources`.
1. Optional. Add a [baseline file](#baseline-files) for rules the source
   documentation does not yet cover.
1. Open a merge request with the manifest change. The
   [`.ai/`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/CODEOWNERS)
   CODEOWNERS rule routes the review to the AI-tooling maintainers.
1. After the merge request merges, the next scheduled sync run generates
   the first distilled file for each new principle at
   `.ai/principles/distilled/<slug>.md`. To trigger an earlier run,
   select **Run** on the "AI principles distillation" schedule at
   [pipeline schedules](https://gitlab.com/gitlab-org/gitlab/-/pipeline_schedules).
   The run fires only the sync job and opens a merge request with the
   generated files. For details, see
   [Run the distillation manually](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ai/principles/README.md#run-the-distillation-manually).
1. Review the generated files. Check that the distilled rules faithfully
   reflect your documentation and that the agent has not introduced rules
   that are not in the source.

## Write effective source documentation

The distillation prompt converts source documentation into imperative
rules when generating the distilled file. Authors of documentation under
`doc/development/` do not need to phrase content as `DO NOT` rules.

Source documentation produces better distillations when it:

- Covers one concern per heading or list item, so the distiller can
  produce one rule per concern.
- States the rule clearly enough that a reader can extract a specific
  action ("do X" or "do not do Y") without inferring intent.

For the full prompt that drives the distiller, see
[`.ai/principles/distillation_prompt.md`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ai/principles/distillation_prompt.md).

For baseline rules, which the distiller preserves verbatim, see
[Baseline files](#baseline-files).

## Baseline files

A baseline file at `.ai/principles/baselines/<slug>.md` holds rules that
your team relies on but that are not (yet) captured in the public
documentation under `doc/development/`. The distiller copies baseline
content verbatim into the generated principle file, alongside the rules
distilled from source documentation.

### When to add a baseline rule

> [!warning]
> Adding baseline rules risks creating dual sources of truth, undermining the goal of distilling
> principles from a single source of truth.
> Treat them as temporary exceptions, not as the primary way to add instructions to agents.

Add a baseline rule when:

- The rule depends on tooling state that the documentation does not
  describe. For example, "files in `db/schema_migrations/` are
  auto-generated and do not require a trailing newline" relies on a
  generator's behavior rather than a published guideline.
- The team has agreed on a convention that has not yet been promoted into
  `doc/development/`. Use the baseline as a holding area until the
  convention lands in the public documentation.
- A reviewer-facing checklist item exists in your team's internal
  documentation that the agent should also apply.

Promote baseline rules into source documentation when possible. A rule
in `doc/development/` is reviewable by a wider audience, gets indexed by
search, and benefits projects outside the principles sync.

### How baseline files fit into the distillation process

When the sync regenerates a principle, the distiller receives:

- The current distilled file, as context for what the previous version
  contained.
- The updated source documentation listed under `sources:` in the
  manifest entry.
- The baseline file content, marked as "include verbatim".

The distillation prompt instructs the distiller to:

- Convert source documentation into imperative rules.
- Include baseline content **verbatim**, without rephrasing.
- Drop any item in the current file that no longer traces back to
  either source documentation or a baseline.

The result is written to `.ai/principles/distilled/<slug>.md`.

### Style guidelines for baseline files

Because baseline content is preserved verbatim, write it in the form the
agent consumes:

- Use imperative voice. Start prohibitions with `DO NOT` and positive
  rules with an action verb (Use, Prefer, Ensure, Include, Add, Set,
  Follow, Freeze, Pass, Wrap).
- Cover one concern per list item. Split compound rules so the agent can
  apply each part independently.
- Avoid descriptive statements. The agent ignores statements like
  "feature flags are enabled by default" when they conflict with
  patterns in existing code. Write the same content as a rule: "DO NOT
  stub feature flags to `true` in specs; they are already enabled by
  default."
- Keep examples concrete. Use fenced code blocks for code, file paths,
  or command examples so the agent can match them syntactically.
- Group related rules under H3 (`### Section name`) headings to mirror
  the structure of distilled files.

### Example

A minimal baseline file for a hypothetical `database-migrations`
principle:

```markdown
### Schema migrations

- Files in `db/schema_migrations/` are auto-generated and do not require
  a trailing newline. DO NOT flag missing newlines on review.

### Batched background migration YAML

When creating `db/docs/batched_background_migrations/<name>.yml`, the
YAML must include:

- `migration_job_name: <BBM class name in CamelCase>`
- `description: <one-line description>`
- `feature_category: <category symbol>`
- `milestone: '<X.Y>'`
- `gitlab_schema: <gitlab_main | gitlab_ci | gitlab_main_user | gitlab_main_org>`
```

## Review auto-generated merge requests

The sync job opens a merge request whenever a principle's source documentation
changes. The merge request:

- Is authored by the principles sync service account.
- Targets the default branch.
- Lists the principles that changed in the description, with links to the
  source files for each one.
- Requires at least one human approval before it can merge.

When you review one of these merge requests, focus on three questions:

- Do the distilled rules match the source documentation? The agent should
  not introduce rules that are not in the source.
- Are the rules in imperative voice? The distiller is prompted to produce
  imperative rules, but it occasionally falls back to descriptive prose.
- Does any rule duplicate a baseline rule? If so, drop the duplicate from
  the baseline.

If the distillation produces noise or invents rules, the right fix is usually
in the source documentation. Tighten the wording in the source so the
distiller has less room to interpret.

## Troubleshooting

### The sync did not generate a distilled file for my new principle

The sync detects drift by comparing checksums. If your manifest entry
references documentation that has not changed after the last sync, no
distillation runs. To force the first generation, either:

- Update the source documentation. The next scheduled run picks up the change.
- Ask an AI-tooling maintainer to run the distiller with `--force` against
  your principle.

### A distillation produced wrong or noisy rules

Open a merge request that:

- Tightens the wording in the source documentation, or
- Adds a baseline file at `.ai/principles/baselines/<slug>.md` that contains
  the rule you want the agent to follow.

The next sync run picks up the change.

### I need to revert a bad distillation

Revert the auto-generated merge request through the standard GitLab revert
flow. The next sync run regenerates the file from the current source
documentation.

## Related

- [Manifest reference](manifest_reference.md) for `.ai/principles/manifest.yml`.
- [`.ai/principles/README.md`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ai/principles/README.md)
  for the operational runbook.
- [`gems/gitlab-ai-principles-distiller`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-ai-principles-distiller)
  for the gem that drives the sync.
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md) for the
  platform that runs the distillation flow.
