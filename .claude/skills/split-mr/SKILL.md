---
name: split-mr
description: Analyze the changes on the current branch — both uncommitted work and commits already made (e.g. a PoC or existing MR) — and reason about whether they should be split into smaller, more focused MRs. Identifies natural boundaries (backend/frontend, model/spec, feature/refactor) and proposes a split plan or confirms the changes are cohesive enough to keep as one.
argument-hint: ""
disable-model-invocation: false
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git show:*), Bash(git checkout:*), Bash(git branch:*), Bash(git push:*), Bash(glab mr create:*), Bash(glab mr view:*), Read, Grep, Glob
---

# MR Split Analysis

Establish the base the branch diverges from (usually `master`) with `git merge-base HEAD master`, then run `git diff <base>...HEAD --stat` and `--name-only` to get the full file list. This covers **all** changes on the branch — both uncommitted work and commits already made — so the analysis works the same whether the user has staged nothing yet or is pointing the skill at a branch that already has commits (a PoC or an open MR). Reason about whether to split from that complete picture.

When the changes are already committed and the user wants to act on a split, the existing commits can be unwound with `git reset <base>` (or `git reset HEAD~N` for the last N commits) before re-distributing files across the proposed MRs in the Execution step.

## Split heuristics

1. **Backend/frontend split** — Ruby and Vue/JS changes that depend on a new field or endpoint: split, with the frontend MR targeting the backend branch.

2. **Migration-first** — Migrations that add columns/tables should land alone ahead of the code that uses them.

3. **Specs travel with code** — Don't split specs out unless you're refactoring shared test infrastructure.

4. **Independent refactors** — Unrelated cleanups or renames alongside a feature: separate them so reviewers can focus.

5. **Cohesion check** — If every file works toward one clearly stated goal and no file is a prerequisite for another MR, keep it as one.

6. **Topology-first** — Find the structural cut that lets every other MR be independent:
   - *Removals:* delete the entry point (route, webpack page, GraphQL mount) first; downstream files become unreachable and can be deleted in parallel MRs. Default to maximally fine-grained.
   - *Additions:* land the substrate first (feature flag off, base type, scaffolded route, empty service). Everything else becomes parallel leaf additions instead of a nested chain.
   - *Refactors:* MR 1 introduces the new shape alongside the old; downstream MRs convert callers in parallel; final MR removes the old shape.

7. **Frontend import graph** — Before splitting frontend changes, trace what's imported by webpack entry points. A file may look standalone but still be imported elsewhere — deleting it alone breaks `bin/rake gitlab:assets:compile`.

**When NOT to split:** change is already small (< ~10 files, single concern); backend and frontend changes are trivial and tightly coupled (e.g. renaming a constant end-to-end); splitting would leave a branch in a broken/non-functional state with no guard.

## Stacked vs. parallel (default: parallel)

Classify each pair:
- **True dependency (stack):** MR B references symbols defined in MR A and won't compile against `master` alone.
- **Convenience bundling (parallelize):** files are related but neither references the other.
- **Soft dependency (parallelize, accept transient CI red):** MR B's CI is red until MR A lands, but runtime is fine — merge order handles it.

Prefer the shallowest stack possible (depth 2–3 max). Linear stacks force sequential review; if any MR stalls, the whole chain stalls.

"Shallowest stack" caps stack *depth* — it is **not** a reason to minimize MR *count*. Sibling leaves that each depend only on a shared substrate but not on each other (e.g. a write path, a read path, an operationally independent cron worker, a cross-component capability handshake) are **parallel, not stacked**: giving each its own MR does not deepen the stack — it keeps every MR small. Never fold independent leaves into one MR to "stay shallow"; that just rebuilds the oversized MR you set out to split. Only bundle leaves when each is trivially small **and** shares a single reviewer domain. After proposing a split, re-check every MR: if one still mixes two concerns that don't reference each other, split it again.

## Output format

```
## Split Analysis

**Verdict:** [Split into N MRs | Keep as one MR]

### Proposed MRs
1. **MR 1 — [title]** (targets: master)
   Files: ...
   Why first: ...

2. **MR 2 — [title]** (targets: MR 1 branch | master)
   Files: ...

### Reasoning
[2–3 sentences]
```

## Generated files

`locale/gitlab.pot`, `doc/api/graphql/reference/_index.md`, and `public/-/graphql/introspection_result.json` are derived from source. Each MR that changes their inputs must regenerate them in the same commit — run `lefthook run autofix` after edits and before each commit.

## Execution (only if user confirms)

For each proposed MR, starting closest to master:
1. `git checkout <base> && git checkout -b <branch>`
2. `git checkout <original-branch> -- <files>`
3. `lefthook run autofix` — regenerates derived files, applies linters. Never skip with `--no-verify`.
4. Commit, push, `glab mr create` targeting the correct branch.
