# GitLab AI Instructions

This directory contains modular AI agent instruction files for the GitLab
project. These files are referenced from `AGENTS.md` (and its identical copy
`CLAUDE.md`) at the repository root via `.ai/...` paths.

## How It Works

- **`AGENTS.md`** and **`CLAUDE.md`** at the repo root (and optionally at
  subdirectory levels) are the entry points. They are identical in content —
  `AGENTS.md` is the source of truth.
- Each entry point references module files in `.ai/` via `.ai/<module>.md`.
- The `.ai/*` pattern is gitignored, so you can add personal instruction files
  here without them being committed. Committed modules were added with
  `git add --force`. Files already tracked by git (force-added) will continue
  to be tracked despite the gitignore pattern — only new untracked files you
  create in `.ai/` are automatically ignored.

## Structure

```
.ai/
  ci-cd.md                 # CI/CD pipeline guidelines
  git.md                   # Git workflow guidelines
  merge-requests.md        # Merge request workflow guidelines
  code-review.md           # Code review methodology and standards
  principles/              # SSOT-derived development principles
    manifest.yml           # Manifest: doc paths, file filters, baselines
    distilled/             # Auto-generated principle files (23 domains)
    baselines/             # Hand-curated rules not yet in docs.gitlab.com
.claude/
  skills/<name>/SKILL.md   # Shared Claude Code skills (auto-discovered)
.agents/
  skills -> ../.claude/skills   # symlink, so other agents such as Duo and OpenCode
                                # pickup skills on session startup.
```

## How instructions are loaded

- **Root `AGENTS.md` / `CLAUDE.md`**: The Context Loading section routes
  task types to the hand-authored topical modules (`.ai/git.md`,
  `.ai/merge-requests.md`, `.ai/ci-cd.md`) and points domain-specific work
  at the `gitlab-coding-principles` skill.
- **Directory-scoped `AGENTS.md`**: Files in target directories
  (e.g., `doc/AGENTS.md`, `workhorse/AGENTS.md`) provide directory-specific
  guidance. Works with any AI tool that respects directory-scoped
  `AGENTS.md` files.
- **Claude Code**: Uses the project-scope skill at
  `.claude/skills/gitlab-coding-principles/SKILL.md`, auto-discovered from
  `.claude/skills/`.
- **OpenCode and other AGENTS.md-aware tools**: Use the same file via the
  `.agents/skills` symlink, which points at `.claude/skills`. No second
  copy to keep in sync.

## Shared Claude Code skills

Skills are auto-discovered by Claude Code from the project-root
`.claude/skills/` directory — **no install step is required**. After
cloning, every committed skill is immediately available. The same
directory is exposed to other tools via the `.agents/skills` symlink.

`.claude/` is gitignored at the project root, so shared skills are
committed with `git add --force` — the same pattern used for everything
in `.ai/`. See [`.claude/skills/README.md`](../.claude/skills/README.md)
for the directory layout and conventions.

### Personal overrides

To customise a shared skill for yourself without touching the team's
version, create a **personal-level** copy at the same skill name under
your home directory:

```
~/.claude/skills/<name>/SKILL.md
```

Claude Code resolves same-named skills across levels by precedence:

> enterprise > personal > project

A personal-level skill takes precedence over the project-level one
committed in this repo. See the Claude Code docs on
[where skills live and how precedence works][skills-docs] for the full
table.

[skills-docs]: https://code.claude.com/docs/en/skills#where-skills-live

> **Why not "override" at the project level by editing the file in
> place?** The project-level files under `.claude/skills/` are tracked
> by git via `git add --force`. Once a path is tracked, `.gitignore`
> no longer shields it: editing the working-tree copy is an ordinary
> uncommitted change, and any later `git pull` that advances the same
> path is refused with `error: Your local changes ... would be
> overwritten by merge` until you commit, stash, or discard. Use the
> personal-level path instead — it's a different file, so git never
> sees a conflict and Claude Code's precedence rule picks your version.

## Adding Personal Instruction Files

Create any `.md` file in `.ai/` — it will be gitignored automatically:

```shell
# Example: add personal testing preferences
echo "# My Testing Notes" > .ai/my-testing.md
```

If you wish, you can create these files in a separate source-controlled project,
and symlink them into this repo.

## Committing New Shared Modules

To add a new shared module that all contributors benefit from:

1. Create the file in `.ai/` (e.g., `.ai/new-module.md`)
2. Force-add it: `git add --force .ai/new-module.md`
3. Reference it from `AGENTS.md` and `CLAUDE.md` (keep them identical)
4. Commit

## Local Overrides

Create `AGENTS.local.md` at any directory level for personal customizations.
This file is explicitly referenced via `@AGENTS.local.md` in both `CLAUDE.md`
and `AGENTS.md`. `CLAUDE.local.md` is also supported — Claude Code loads it
natively by convention, not via an explicit reference in the instruction files.
Both files can reference any additional gitignored files you have in `.ai/` or
elsewhere.

The `AGENTS.local.md` is gitignored and will not be committed.
It may also be symlinked from a local source-controlled repo.

## See also

- [`principles/README.md`](principles/README.md) — How the SSOT sync works
- [`AGENTS.md`](../AGENTS.md) — Project-level entry point for all AI tools
- <https://gitlab.com/gitlab-org/gitlab/-/work_items/594821>
