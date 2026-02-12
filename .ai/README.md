# GitLab AI Prompts

This directory contains modular AI agent instructions for the GitLab project.

## Quick Start

AI tools like OpenCode automatically read `AGENTS.md` from the project root, which
loads `.ai/AGENTS.md` by default. This gives you GitLab conventions out of the box.

## Customization

### Option A: Override file (simplest)

Create `AGENTS.local.md` in the project root to replace the default entirely:

```bash
# Create your local override
cat > AGENTS.local.md <<EOF
# My Custom Agent Instructions

Read .ai/git.md
Read .ai/testing.md
# Add only the modules you need
EOF
```

### Option B: Use all defaults

If you want all project defaults, your `AGENTS.local.md` can simply say:

```markdown
Read and follow all instructions in the .ai/ directory.
```

### Option C: Explicit prompting (maximum control)

Ignore all auto-loaded files and manually specify in your prompt:

```
Read .ai/database.md and .ai/testing.md. Ignore all other .ai/ files.
```

## Available Modules

| File | Description |
|------|-------------|
| `git.md` | Git workflow, commit conventions, branch naming, lefthook |
| `merge-requests.md` | MR workflows, pipelines, chained MRs, rebasing |
| `code-review.md` | Conventional comments, review best practices |
| `database.md` | Migrations, multi-database, BBMs, structure.sql |
| `testing.md` | RSpec, Jest, local testing, predictive tests |
| `code-style.md` | Ruby, JavaScript, Rails conventions, linting |

## File Loading Behavior

By default, the root `AGENTS.md` contains:

```
If AGENTS.local.md exists, read and load that.
Otherwise, read and load .ai/AGENTS.md
```

This means:
- **No customization** - You get `.ai/AGENTS.md` (sensible defaults)
- **Create `AGENTS.local.md`** - You get full control
- `AGENTS.local.md` is gitignored, so your customizations stay local

## Troubleshooting

**Agent not reading files?**

Some AI tools don't reliably auto-load AGENTS.md files. If this happens:

1. Explicitly prompt: "Read AGENTS.md from the project root"
2. Or be more specific: "Read .ai/database.md"
3. Prepend important sessions with: "First, reread AGENTS.md, then..."

**Too much context loaded?**

Create a minimal `AGENTS.local.md` with only what you need for your current task.

**Want to share a workflow?**

Create a file in `.ai/workflows/` and document it here, but don't commit
`AGENTS.local.md` itself (it's gitignored).
