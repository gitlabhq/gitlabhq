# Shared Claude Code skills

This directory is the canonical home for shared Claude Code skills committed
to the repo. Skills are auto-discovered by Claude Code at session start —
**no install step is required**. After cloning, every skill listed here is
immediately available to new agent sessions.

## Layout

Each skill lives in its own subdirectory with a `SKILL.md` carrying YAML
frontmatter:

```
.claude/skills/<name>/SKILL.md
```

The frontmatter must include at least `name` and `description`; both fields
are surfaced to Claude Code when it decides whether to load the skill.

## Before adding a new skill

Skills here are task recipes (how to use a CLI, how to scaffold a component,
how to analyze a diff) or thin routers into other content — not a place to
hand-write distilled development-guideline content. If what you're encoding
is durable domain knowledge sourced from published `doc/development/*.md`
guides (for example, "how sharding keys work" or "when a feature needs
organization-level scope"), it belongs in
[`.ai/principles/`](../../.ai/principles/README.md) instead. That README
covers the manifest schema, how to regenerate the generated artifacts
(`gitlab-coding-principles/SKILL.md`, `AGENTS.md`, `.gitlab/CODEOWNERS` are
all manifest-generated — don't hand-edit them), and gotchas like `team_slug`
collisions. A hand-written skill duplicating SSOT content will drift the
moment the source docs change, since nothing keeps it in sync.

## Tracking and gitignore

`.claude/` is gitignored at the project root, so shared skills are committed
with `git add --force` — the same pattern used by the `.ai/` knowledge base.
Personal-level files placed under `.claude/` (outside `.claude/skills/`)
stay private to your checkout.

## Mirror for non-Claude AGENTS.md consumers

`.agents/skills` is a symlink pointing at this directory, so tools that
read from the `AGENTS.md` convention (OpenCode, etc.) see the same content
without a separate copy. Keep the symlink intact — a pre-commit parity
check fails the commit if `.agents/skills` and `.claude/skills` diverge.

## Personal overrides

To customise a shared skill for yourself, create a same-named skill at the
personal level:

```
~/.claude/skills/<name>/SKILL.md
```

Claude Code resolves same-named skills by precedence:

> enterprise > personal > project

so a personal-level skill takes precedence over the one committed in this
repo. See the Claude Code docs on
[where skills live](https://code.claude.com/docs/en/skills#where-skills-live)
for the full table.
