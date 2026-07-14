---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Reviewing GitLab AI instruction files
---

For broader advice and best practices for code review, see the
[code review guide](code_review.md).

## General process

Every change to a file under `.ai/` requires a dedicated review.
These files configure how AI coding agents (GitLab Duo, Claude Code,
OpenCode, and other `AGENTS.md`-aware tools) behave when working in this
repository, so a mistake affects every contributor's agent sessions
rather than a single runtime code path.

The distilled principles have an additional consumer:
[`.gitlab/duo/mr-review-instructions.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/duo/mr-review-instructions.yaml)
carries generated fences imported from the distilled principles, so a change
to a distilled principle also changes the automated review feedback Duo posts
on every merge request that matches the principle's file filters.

Fence regeneration is decoupled from distillation. A distilled principle's
merge request updates only the `.ai/principles/distilled/*.md` file. A separate
daily scheduled job reconciles the fences from the merged `master` distilled
files by pure projection (it copies each file's `distilled_at_sha` and
`source_checksum` front matter and never re-runs distillation) and opens its
own merge request. This keeps a team's distilled merge request and the fence
update independently mergeable, so neither waits on the other to pass CI.

Changes to `.ai/` files require approval from an AI harness directly
responsible individual (DRI). This convention is encoded in
[`.gitlab/CODEOWNERS`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/CODEOWNERS)
under the "Monolith AI harness files" block: these files do not need the
broad `*` rule approval, but each requires approval from a named DRI. The
review convention is tracked in
[work item 20880](https://gitlab.com/groups/gitlab-org/-/work_items/20880).

Distilled principle files carry an additional layer of routing: each is
also owned by the team that owns its single source of truth (SSOT)
documentation, so distillation changes are approved by the relevant
domain team. See [Reviewing auto-generated sync merge requests](#reviewing-auto-generated-sync-merge-requests).

## What the `.ai/` files are

The `.ai/` directory holds four categories of file, each reviewed
differently:

- Hand-authored modules: `.ai/README.md`, `.ai/ci-cd.md`,
  `.ai/git.md`, `.ai/merge-requests.md`, and `.ai/code-review.md`.
  Human-written instruction prose, referenced from the repository-root
  `AGENTS.md` and `CLAUDE.md`.
- Distilled principles: `.ai/principles/distilled/*.md`.
  Auto-generated from SSOT documentation on `docs.gitlab.com` by the
  [AI principles distiller](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-ai-principles-distiller/README.md).
  These files must not be edited by hand.
- Baselines: `.ai/principles/baselines/*.md`. Hand-curated review
  rules that are not yet covered by `docs.gitlab.com` and are merged into
  the distilled output during a sync.
- Distillation configuration: `.ai/principles/manifest.yml` and
  `.ai/principles/distillation_prompt.md`. The routing and prompt SSOT
  that drive the distiller.

## General review principles

Apply these to every `.ai/` change, regardless of file category:

- Treat instructions as prompts, not code. They are consumed by language
  models, not executed. Prefer clear, imperative, unambiguous rules. Flag
  wording that an agent could misread or that contradicts another module.
- Remember that every agent session is affected. There is no gradual
  rollout and no feature flag. A regression in an instruction file degrades
  every contributor's agent output immediately.
- Keep instructions actionable. Favor concrete `Do X` / `Don't do Y`
  rules over background prose. Vague guidance produces vague agent
  behavior.
- Mind the token budget. Instruction files are loaded into the agent's
  context window. Redundant or verbose content displaces useful context
  and increases cost. Prefer concise rules and cross-references over
  duplication.
- Keep `AGENTS.md` and `CLAUDE.md` identical. The repository-root
  entry points must not diverge. `AGENTS.md` is the source of truth. When
  a change references a new module, both entry points must be updated
  together.
- Avoid dual sources of truth. Prefer distilling a rule from SSOT
  documentation over hand-authoring it in `.ai/`. Every hand-authored rule
  is a rule that can drift from the docs it duplicates.

## Checklist by file category

### Hand-authored modules

For `.ai/README.md`, `.ai/ci-cd.md`, `.ai/git.md`,
`.ai/merge-requests.md`, and `.ai/code-review.md`:

- Verify the guidance is correct and current against the practice it
  describes.
- Check for contradictions with other modules and with the distilled
  principles.
- Confirm any new module is referenced from both `AGENTS.md` and
  `CLAUDE.md`, and that the two entry points remain identical.
- Confirm a new shared module was force-added (`git add --force`), because
  the `.ai/*` pattern is gitignored.
- Prefer moving durable, broadly applicable guidance into SSOT
  documentation so it can be distilled, rather than growing hand-authored
  modules.

### Distilled principles

For `.ai/principles/distilled/*.md`:

- Never edit these files by hand. They are regenerated from SSOT
  documentation and carry a
  `<!-- Auto-generated ... do not edit manually -->` marker. A deliberate
  hand-fix is acceptable only on a distiller service-account branch as a
  stopgap, and must be called out explicitly in the merge request.
- To change a distilled principle's content, change its SSOT
  documentation (or the matching `baselines/<name>.md`) and re-run the
  sync, rather than editing the distilled file.
- Verify the distilled changes faithfully reflect the source-doc updates
  and do not introduce, drop, or contradict rules that the source does not
  support.
- Confirm the distilled output contains no references to repository
  internals that make no sense to an agent reading the principle, such as
  paths under `.ai/principles/baselines/` or links to other principle
  files. Baseline content survives distillation verbatim, so such
  references leak into the distilled file. Fix them in the source baseline,
  not the distilled file.
- Leave the front matter (`source_checksum`, `distilled_at_sha`) untouched.
  These drive drift detection. Hand-editing them masks or forces
  re-distillation incorrectly.
- Confirm the change is routed to the correct SSOT-owning team through the
  generated CODEOWNERS block.

### Baselines

For `.ai/principles/baselines/*.md`:

- Require a justification for why the rule has no SSOT home yet. Baselines
  are an escape hatch, not the primary way to add agent instructions.
- Treat every baseline as temporary. Prefer opening a follow-up to move
  the rule into `docs.gitlab.com`, after which it should be removed from the
  baseline.
- Watch for baseline rules that duplicate or contradict existing SSOT
  content, which creates a dual source of truth.
- Check that the baseline does not reference the `baselines/` folder or
  other principle files. Baseline content is merged into the distilled
  output verbatim, so any such cross-reference leaks into an agent-facing
  principle where it is meaningless. Point readers to the distilled source
  instead, or drop the cross-reference.

### Distillation configuration

For `.ai/principles/manifest.yml` and
`.ai/principles/distillation_prompt.md`:

- For `manifest.yml`, validate the entry against the
  [manifest schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ai/principles/README.md#manifest-schema):
  required `description`, `sources`, and `owner_team`; correct
  `file_filters`; and a `team_slug` that does not collide with another
  entry.
- Confirm `owner_team` routes approval to the team that actually owns the
  SSOT documentation.
- Do not hand-edit content inside a generated block. The sync delimits
  these blocks with `# BEGIN GENERATED` and `# END GENERATED` comments in
  `.gitlab/CODEOWNERS`, and with `# >>> generated: <name>` and
  `# <<< end generated: <name>` comments in
  `.gitlab/duo/mr-review-instructions.yaml`. Regenerate them by running
  the sync instead.
- Treat changes to `distillation_prompt.md` as the highest-risk change in
  this directory. The prompt governs how every principle is distilled,
  so a regression silently degrades all distilled files on the next sync
  rather than one. Scrutinize prompt changes accordingly: reason through
  the effect on the full set of principles, not just the one that
  motivated the change, and prefer distilling a sample of principles with
  `--force` on a branch to inspect the output before merging.
- Remember that `distillation_prompt.md` changes only take effect after
  the catalog flow is re-provisioned
  (`gitlab-ai-principles-distiller-provision-flow`). Merging the file
  alone does not roll the new prompt out.

## Reviewing auto-generated sync merge requests

The weekly distillation sync opens merge requests automatically, labeled
`ai-agent` and `documentation`. They are never auto-merged: a human
must verify that the distilled changes faithfully reflect the source-doc
updates before merging.

Each per-team merge request's approval is routed to the SSOT-owning team
through generated per-file CODEOWNERS rules. When reviewing one:

- Compare the distilled diff against the referenced SSOT documentation
  changes.
- Confirm no still-valid, SSOT-supported rule was dropped, and no
  unsupported rule was added.
- Confirm the front matter checksums were updated by the tool, not by hand.

The daily fence-reconcile job opens a separate merge request that changes only
`.gitlab/duo/mr-review-instructions.yaml`. When reviewing one, confirm the
fence directives match the front matter of the distilled files on `master`. The
job runs no distillation, so the fence body should never diverge from the
committed distilled content.

The `ai-duo-review-instructions` guard that enforces this always fails on
malformed or orphaned fences, because those are broken on their own ref
regardless of the reconcile. Fence _staleness_ is treated by severity:

- Blocking on the reconcile merge request and on merge requests that touch the
  fences' owned files (the Duo instructions file, the distiller gem, or the
  guard script), where a stale fence is real drift the author can fix.
- A non-blocking warning on `master` and on other merge requests caught by the
  broad manifest trigger (including a team's distilled merge request), where
  staleness is expected transient state until the daily reconcile job catches
  the fences up. So neither a team's distilled merge request nor an unrelated
  `doc/**/*.md` edit inherits a fence-stale failure it cannot fix on its own
  ref.

For the full mechanics of the distillation pipeline (the provisioner, the
sync binary, the schedule, and the manifest schema), see
[`.ai/principles/README.md`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ai/principles/README.md),
which is the source of truth for how the sync works.

## Related topics

- [Code review guidelines](code_review.md)
- [AI agent instruction files for documentation](documentation/ai-instruction-files-documentation.md)
- [`.ai/README.md`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ai/README.md): how instruction files are organized and loaded
- [`.ai/principles/README.md`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.ai/principles/README.md): how the SSOT distillation sync works
- [AI principles distiller gem](https://gitlab.com/gitlab-org/gitlab/-/blob/master/gems/gitlab-ai-principles-distiller/README.md)
