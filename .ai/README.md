# GitLab AI Prompts

This directory contains modular AI agent instructions for the GitLab project.

## Quick Start

To use these AI instructions with OpenCode, copy `opencode.example.json` to `opencode.json`:

```shell
cp opencode.example.json opencode.json
```

This configuration loads both `AGENTS.local.md` (if it exists) and `.ai/AGENTS.md`,
giving you GitLab conventions with optional personal customizations.

## Customization

### Option A: Override file (simplest)

Create `AGENTS.local.md` in the project root to replace the default entirely:

```shell
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

```plaintext
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

The `opencode.example.json` configuration explicitly loads:

```json
"instructions": ["AGENTS.local.md", ".ai/AGENTS.md"]
```

This means:

- **`AGENTS.local.md`** loads first (if it exists) - for your personal customizations
- **`.ai/AGENTS.md`** loads second - providing project defaults
- `AGENTS.local.md` is gitignored, so your customizations stay local
- If `AGENTS.local.md` doesn't exist, you still get `.ai/AGENTS.md` defaults

## Troubleshooting

**Agent not reading files?**

Make sure you have `opencode.json` configured (copy from `opencode.example.json`).

If instructions still aren't loading:

1. Check your `opencode.json` has the correct `instructions` array.
1. Explicitly prompt: "Read .ai/database.md" to load specific modules.
1. Verify the file paths are correct relative to the project root.

**Too much context loaded?**

Create a minimal `AGENTS.local.md` with only what you need for your current task.

**Want to share a workflow?**

Create a file in `.ai/workflows/` and document it here, but don't commit
`AGENTS.local.md` itself (it's gitignored).
