---
source_checksum: c73cbb508b1f684b
distilled_at_sha: 3941b843c30927ec6cea3e9caa43c88e5f930cb6
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# AI Instruction Files Principles

## Checklist

### General Review

- Treat instruction files as prompts consumed by language models, not as executable code; prefer clear, imperative, unambiguous rules and flag wording that an agent could misread or that contradicts another module.
- Ensure every agent session is affected immediately by any change — there is no gradual rollout and no feature flag, so a regression degrades every contributor's agent output at once.
- Keep instructions actionable: favor concrete `Do X` / `Don't do Y` rules over background prose.
- DO NOT add redundant or verbose content to instruction files; prefer concise rules and cross-references to avoid displacing useful context and increasing token cost.
- Keep `AGENTS.md` and `CLAUDE.md` identical; when a change references a new module, update both entry points together (`AGENTS.md` is the source of truth).
- DO NOT hand-author a rule that can instead be distilled from SSOT documentation; every hand-authored rule risks drifting from the docs it duplicates.
- Ensure changes to `.ai/` files are approved by the AI harness DRI named in the `Monolith AI harness files` block of `.gitlab/CODEOWNERS`.

### Hand-Authored Modules

- Verify guidance in `.ai/README.md`, `.ai/ci-cd.md`, `.ai/git.md`, `.ai/merge-requests.md`, and `.ai/code-review.md` is correct and current against the practice it describes.
- Check for contradictions with other modules and with the distilled principles.
- Confirm any new module is referenced from both `AGENTS.md` and `CLAUDE.md`, and that the two entry points remain identical.
- Confirm a new shared module was force-added (`git add --force`), because the `.ai/*` pattern is gitignored.
- Prefer moving durable, broadly applicable guidance into SSOT documentation so it can be distilled, rather than growing hand-authored modules.

### Distilled Principles

- DO NOT edit `.ai/principles/distilled/*.md` files by hand; they are regenerated from SSOT documentation and carry a generated marker. A deliberate hand-fix is acceptable only on a distiller service-account branch as a stopgap and must be called out explicitly in the merge request.
- To change a distilled principle's content, change its SSOT documentation (or the matching `baselines/<name>.md`) and re-run the sync instead of editing the distilled file directly.
- Verify the distilled changes faithfully reflect the source-doc updates and do not introduce, drop, or contradict rules that the source does not support.
- Confirm the distilled output contains no references to repository internals that make no sense to an agent (such as paths under `.ai/principles/baselines/` or links to other principle files); fix such leaks in the source baseline, not the distilled file.
- DO NOT hand-edit the front matter (`source_checksum`, `distilled_at_sha`); these drive drift detection and hand-editing them masks or forces re-distillation incorrectly.
- Confirm the change is routed to the correct SSOT-owning team through the generated CODEOWNERS block.

### Baselines

- Require a justification for why a baseline rule has no SSOT home yet; baselines are an escape hatch, not the primary way to add agent instructions.
- Treat every baseline rule as temporary; prefer opening a follow-up to move the rule into `docs.gitlab.com`, after which it should be removed from the baseline.
- Watch for baseline rules that duplicate or contradict existing SSOT content, which creates a dual source of truth.
- Ensure baseline files do not reference the `baselines/` folder or other principle files; baseline content is merged into the distilled output verbatim, so such cross-references leak into agent-facing principles where they are meaningless.

### Distillation Configuration

- For `manifest.yml`, validate the entry against the manifest schema: required `description`, `sources`, and `owner_team`; correct `file_filters`; and a `team_slug` that does not collide with another entry.
- Confirm `owner_team` routes approval to the team that actually owns the SSOT documentation.
- DO NOT hand-edit content inside a generated block; the sync delimits these blocks with `# BEGIN GENERATED` and `# END GENERATED` comments in `.gitlab/CODEOWNERS`, and with `# >>> generated: <name>` and `# <<< end generated: <name>` comments in `.gitlab/duo/mr-review-instructions.yaml` — regenerate them by running the sync instead.
- Treat changes to `distillation_prompt.md` as the highest-risk change in this directory; reason through the effect on the full set of principles (not just the one that motivated the change), and prefer distilling a sample of principles with `--force` on a branch to inspect the output before merging.
- Ensure `distillation_prompt.md` changes are followed by re-provisioning the catalog flow (`gitlab-ai-principles-distiller-provision-flow`); merging the file alone does not roll the new prompt out.

### Reviewing Auto-Generated Sync Merge Requests

- Compare the distilled diff against the referenced SSOT documentation changes.
- Confirm no still-valid, SSOT-supported rule was dropped and no unsupported rule was added.
- Confirm the front matter checksums were updated by the tool, not by hand.
- Classify each Duo finding into exactly one of four outcomes before acting: Content defect (distilled text misstates the source — fix on the sync branch), Content gap (distillation dropped a supported rule — restore on the sync branch), Distiller defect (root cause is the tooling — fix the output and open an issue against the distiller), or Judgment call (output is correct but could be closer — record it, no required action).
- When fixing a finding, restore a baseline-derived rule verbatim (the sync tooling mechanically rejects any alteration); make a source-derived fix faithful and traceable but DO NOT copy source prose verbatim (distilled files hold concrete checkable rules, and a verbatim copy is rephrased on the next run).
- Batch all fixes on a sync branch into a single push; pushing a file revokes that file's code owner approval (selective code owner removals are enabled), so an unbatched sequence of pushes can repeatedly invalidate an in-progress review.
- When a finding's root cause is the tooling, open an issue against the distiller describing the mechanism (which component, for what input), and record each instance of dropped content on [issue 604659](https://gitlab.com/gitlab-org/gitlab/-/issues/604659).
- Prefer a targeted fix on the sync branch for localized findings; re-run distillation only when the output is broadly wrong (re-running is slow and non-deterministic and can regress unrelated rules).
- When reviewing a fence-reconcile MR (which changes only `.gitlab/duo/mr-review-instructions.yaml`), confirm the fence directives match the front matter of the distilled files on `master`; the reconcile job runs no distillation, so the fence body must never diverge from the committed distilled content.
- Treat a malformed or orphaned fence as always-blocking; the `ai-duo-review-instructions` guard fails on its own ref regardless of the reconcile state.
- Treat fence staleness as blocking only on the reconcile MR and on MRs that touch the fences' owned files. DO NOT treat staleness as blocking on a team's distilled MR or on unrelated `doc/**/*.md` edits — it is expected transient state until the daily reconcile catches up.

## Authoritative sources

For the full picture, see:

- doc/development/ai_instruction_files_review.md

