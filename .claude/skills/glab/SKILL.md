---
name: glab
description: GitLab workflow automation using glab CLI
version: 1.10.0
category: Development Workflow
license: MIT
metadata:
  audience: developers
  author: dgruzd
  workflow: gitlab
---

# GitLab Workflow Skill

GitLab workflow management using `glab` CLI for merge requests, issues, and Git best practices.

## Multiple GitLab Instances

glab auto-detects the GitLab host from your git remote. No `GITLAB_HOST` is needed when
working inside a repository. For non-`origin` remotes (e.g. a local GDK instance added
as a secondary remote), use `glab config set remote_alias <remote>`. Set `GITLAB_HOST`
only when running outside a git repository or for a one-off command targeting a specific
instance. See [references/multi-host.md](references/multi-host.md) for non-origin remote
setup and hostname derivation from remote URLs.

## ⚠️ Message Escaping — Common Trap

**If your message contains backticks (`` ` ``), `$`, or other shell special characters, NEVER inline them directly in `-m "..."`.** The shell interprets backticks as command substitution, silently mangling your message and producing errors like `/bin/bash: line 1: client_name: command not found`.

This has caused real production failures: agents posting malformed comments to GitLab MRs/issues, followed by apologetic correction notes.

### ❌ DON'T — inline backticks in double-quoted -m

```bash
# BROKEN: shell tries to execute `client_name` as a command
glab mr note 100 -m "Use `client_name` and `wor/` here." -R org/repo
# Error: /bin/bash: line 1: client_name: command not found
# The comment is posted as: "Use  and  here." (identifiers silently stripped)

# Also BROKEN: backslash-escaped backticks break in nested/scripted contexts
glab mr note 100 -m "Use \`client_name\`" -R org/repo
# Works in simple cases but fails when the command is double-quoted by a caller:
# bash -c "glab mr note 100 -m \"Use \`client_name\`\""  → still executes client_name
```

### ✅ DO — write to a file first, then pass via $(cat ...)

Pick a path appropriate for your environment (a `mktemp` result, a scoped workspace tmp file, whatever fits — the skill doesn't prescribe a specific path; agents choose one that's unique to their invocation to avoid clobbering parallel runs):

```bash
# MSG = path you choose (e.g. mktemp, ~/workspace/tmp/note-$$.md, etc.)
MSG=<agent picks>

cat > "$MSG" << 'EOF'
Use `client_name` and `wor/` here. The `glab` tool handles this.
EOF
glab mr note 100 -m "$(cat "$MSG")" -R org/repo
```

The single-quoted `'EOF'` heredoc delimiter prevents ALL variable/backtick expansion when writing the file. The `$(cat "$MSG")` substitution is safe because the file content is already written literally. **Triple-backtick code blocks (` ``` `) are also safe inside `<<'EOF'` heredocs** — no escaping needed; only single-backticks and `$` trigger command substitution.

### ✅ Also safe — glab api with -f flag

```bash
glab api --method POST "projects/org%2Frepo/merge_requests/100/notes" \
  -f "body=$(cat "$MSG")"
```

### ⚠️ Unquoted heredoc still interprets backticks

```bash
# BROKEN: unquoted EOF delimiter — backticks in body are still interpreted
cat > "$MSG" << EOF
Use `client_name` here.    # ← shell executes client_name when writing the file
EOF
```

### ⚠️ Heredoc-inside-heredoc breaks shell parsing

If your content itself contains a heredoc example **with an unindented `EOF` terminator**, the inner `EOF` at column 0 closes the outer heredoc early:

```bash
# BROKEN: the inner EOF is at column 0 — it closes the OUTER heredoc early
cat > "$OUTER" << 'EOF'
Here is the safe pattern:
cat > "$MSG" << 'EOF'
Use `client_name` here.
EOF
# ↑ This EOF terminates the OUTER heredoc — the lines below run as shell commands!
echo "more content..."
EOF
# ↑ This stray EOF becomes a command: "EOF: command not found"
```

**Fix — use a different delimiter for the outer heredoc:**

```bash
cat > "$OUTER" << 'OUTEREOF'
Here is the safe pattern:
  cat > "$MSG" << 'EOF'
  Use `client_name` here.
  EOF
OUTEREOF
```

Or write the file in chunks — first chunk uses `>`, subsequent chunks use `>>`, each with its own delimiter.

**Rule of thumb:** If the message contains `` ` ``, `$`, `!`, or `\` — write to a file with `<< 'EOF'` first, always. If the content itself contains heredoc syntax, use a unique outer delimiter (e.g. `OUTEREOF`, `MSGEOF`) that won't appear in the body.

## Creating Merge Requests

Always pass `--push` and `-H <owner/repo>`. Without `--push`, the branch may not exist on
any remote yet. Without `-H`, glab may pick the wrong remote (e.g. a security mirror) as
the source project, creating the MR from the wrong fork.

```bash
# Simple MR
glab mr create --push -H <owner/repo> --title "Add feature" --description "Brief description" --assignee <username>

# Complex MR - write description to file first (pick your own path)
glab mr create --push -H <owner/repo> --title "Add feature" --description "$(cat "$DESC")" --assignee <username>
```

**Templates:** Check `.gitlab/merge_request_templates/` for project-specific templates.

Full flag list (Claude Code injects this automatically; other agents should run it):

!`glab mr create --help`

## Updating Merge Requests

```bash
glab mr update <number> --description "$(cat "$DESC")"
glab mr view <number> -R <owner>/<repo>
```

## Issue Management

The full, always-current flag list (Claude Code injects this automatically; other agents
should run it):

!`glab issue --help`

`view`, `note`, `list`, `create`, `update` work as you'd expect. The non-obvious traps that
`--help` won't warn you about:

```bash
# List is open by default and has NO --state flag — use --closed / --all instead
glab issue list --closed -R <owner>/<repo>
glab issue list --all    -R <owner>/<repo>

# Labels — use --label / --unlabel, NEVER +label or -label syntax
glab issue update 123 --label "new-label"
glab issue update 123 --unlabel "old-label"
# Scoped labels auto-replace within their scope — no --unlabel needed:
glab issue update 123 --label "status::doing"   # removes any existing status:: label

# Messages with backticks/$ — write to a file first (see Message Escaping above)
glab issue note <number> -m "$(cat "$MSG")" -R <owner>/<repo>
```

For issue state transitions (close/reopen via API) and posting notes via `glab api`: **[references/issue-api.md](references/issue-api.md)**

## Work Items

GitLab is migrating issues to work items. The URL shows `/work_items/<iid>` but the REST API is the same.

```bash
# ✅ Use the issues API — same IID, same endpoints
glab api "projects/org%2Fproject/issues/<iid>"

# ❌ /work_items/ REST endpoint does not exist
glab api "projects/org%2Fproject/work_items/<iid>"   # → 404
```

URL parsing: `https://gitlab.com/org/project/-/work_items/539076`
→ `glab api "projects/org%2Fproject/issues/539076"`

Full details, GraphQL alternative, and group-level work items: **[references/work-items.md](references/work-items.md)**

## MR Review

Since `glab` v1.94.0, `glab mr note` handles every common MR-comment shape (list, general, diff-line, reply, resolve/reopen) without raw `glab api` calls or hand-built `position` objects. Prefer it for any single-comment workflow. The MR IID is a **positional** argument (not `--mr`); omit it to auto-detect from the current branch.

```bash
# ✅ Use glab mr note for read/write/reply/resolve — single command per operation
glab mr note list 123 -F json                                       # read discussions
glab mr note create 123 -m "comment"                                # general
glab mr note create 123 --file main.go --line 42 -m "..."           # diff comment
glab mr note create 123 --reply abc12345 -m "..."                   # reply
glab mr note resolve 123 abc12345                                   # resolve thread

# ❌ Do NOT use glab api .../discussions for these operations
glab api "projects/<id>/merge_requests/123/discussions"             # use mr note list
glab api --method PUT ".../discussions/<id>" -f resolved=true       # use mr note resolve
```

Full flag list for the subcommands above (Claude Code injects this automatically; other
agents should run it):

!`glab mr note --help`

Fall back to raw `glab api .../draft_notes` only for **batched draft reviews** (multiple inline comments published together via `bulk_publish`) — `glab mr note` has no draft mode.

Full reference (all flags, code suggestions, drafts/batch fallback, position objects): **[references/mr-review.md](references/mr-review.md)**

## Issue Links, Epics, and Nested Groups

- **Issue links** (`blocked_by`, `relates_to`): [references/issue-links.md](references/issue-links.md)
- **Epics CRUD** (create, list, update, close): [references/epics.md](references/epics.md)
- **Epic comments** (GraphQL read/write, pagination — REST returns 404): [references/epic-comments.md](references/epic-comments.md)
- **Nested groups** (`%2F` encoding): [references/nested-groups.md](references/nested-groups.md)

## MR Listing and Filtering

Full flag list (Claude Code injects this automatically; other agents should run it):

!`glab mr list --help`

**Note:** `glab mr list` lists open MRs by default and has no `--state` or `--status` flag —
use `--all`, `--merged`, or `--closed` to change the state filter.

## Search

For full search examples (instance / group / project, scope table, pagination): **[references/search.md](references/search.md)**

Quick reference:

```bash
glab api "search?scope=issues&search=<query>" | jq '.[] | {iid, title}'
glab api "groups/<group>/search?scope=merge_requests&search=<query>" | jq '.[]'
glab api "projects/<org>%2F<repo>/search?scope=issues&search=<query>" | jq '.[]'
```

## Git and Commit Conventions

Follow the repo's own git conventions when present (a project may document them and
enforce them with a commit linter). GitLab defaults:

```bash
git checkout -b feature/description   # feature branches
git checkout -b fix/description       # bug fixes
```

- Capitalized, imperative commit subjects ("Add feature", not "Added feature" or
  "feat: add feature"); GitLab does not use conventional-commit subjects.
- Reference issues/MRs with full URLs: `Closes https://gitlab.com/org/project/-/issues/123`.
- Single-quote commit messages containing special characters:
  `git commit -m 'Add note from https://gitlab.com/org/project/-/merge_requests/123'`.

## Agent Guidelines

The sections above cover the common workflows. These are the non-obvious traps and
API quirks that are easy to get wrong and not discoverable from `glab <cmd> --help`:

1. **Read context first** — `glab issue view` / `glab mr view` before implementing; check `.gitlab/issue_templates/` and `.gitlab/merge_request_templates/` for templates
2. **`--jq` works on subcommands, not on `glab api`** — `glab issue list`/`glab mr list`/`glab ci list` accept a global `--jq` flag (filters JSON output); `glab api` does **not** — pipe its output through `| jq '...'` instead
3. **No `--body` flag** — glab uses `--description`, not `--body` (which is a `gh` flag); they are not interchangeable
4. **Work items use the issues API** — `/work_items/<iid>` URLs → `projects/.../issues/<iid>`; the `/work_items/` REST endpoint is a 404
5. **Epic comments need GraphQL** — REST `/notes` GET+POST both → 404 (still true on GitLab 19.1); pass `body`/`noteableId` as GraphQL variables, never string-interpolate. See [references/epic-comments.md](references/epic-comments.md)
6. **No `-R` for group-level API** — `-R` expects `OWNER/REPO`; group endpoints use `glab api "groups/..."` directly
7. **Nested groups REST: `%2F`** — `groups/org%2Fsubgroup/epics`; unencoded slashes → 404
8. **GraphQL iid is a String** — `workItem(iid: "16428")` not `workItem(iid: 16428)`
9. **`groups/<id>/work_items` is 404** — use `groups/<id>/epics` (REST) or GraphQL
10. **`project` exposes `workItems` (plural), not `workItem`** — under `project` use `workItems(first: 1, iid: "IID")` with no `filter:` argument; the singular `workItem(iid:)` field exists only under `group`/`namespace`
11. **Epic close/reopen via REST** — `state_event=close`/`reopen` on `PUT groups/<id>/epics/<iid>` works; no GraphQL needed
12. **Scoped labels auto-replace** — `--label "status::doing"` removes any existing `status::*` label; no `--unlabel` needed (this is a platform fact, true via the API generally, not just glab)
13. **Idempotent comments → `--unique`** — `glab mr note create -m "..." --unique` skips posting if an identical body already exists; matches on body only, so identical bodies on different diff lines still post
14. **Non-origin remotes → `remote_alias`** — if `origin` points at one instance but you want glab to target another remote (e.g. a local GDK added as `gdk`), run `glab config set remote_alias gdk` rather than setting `GITLAB_HOST` per command. See [references/multi-host.md](references/multi-host.md)
15. **Backticks in messages → write to a file first** — never inline `` ` ``/`$` in `-m "..."` or `--description "..."`; write to a file you name (unique per invocation) using `<< 'EOF'` (single-quoted delimiter, critical), then pass via `$(cat "$FILE")`. See the Message Escaping section above.

## Contributing Improvements

This skill is maintained in the GitLab monolith
([`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab), under
`.claude/skills/glab/`) and synced out to
[`gitlab-org/ai/skills`](https://gitlab.com/gitlab-org/ai/skills) — the monolith copy
is the source of truth. If you discover that any guidance here is **inaccurate or
outdated** (e.g. a command that no longer works, a wrong flag, an incorrect API
behavior), confirm with the user and open an MR against the monolith with the fix.
Keep changes focused — one fix per MR.
