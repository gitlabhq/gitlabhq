# MR Review — Notes, Code Suggestions, Discussions

**Default to `glab mr note` for every MR-comment operation** — read, write, reply, resolve.
The raw `glab api .../discussions` and `glab api .../draft_notes` paths exist only for two
specific cases:

1. **Batched draft reviews** (Section 3) — multiple inline comments published together via
   `bulk_publish`. `glab mr note` has no draft mode yet, so this is the one workflow where
   the raw API is still required.
2. **Raw discussion JSON / position metadata** (Section 4) — when you need fields that
   `glab mr note list -F json` doesn't surface (e.g. full position diff refs).

If your task is "list / post / reply / resolve a single MR comment", use Section 1. **Do not
reach for `glab api` for these operations** — it produces brittle, gotcha-laden code (see
Section 3 caveats) when a one-liner suffices.

Always check existing discussions before posting — earlier threads may already be resolved or
outdated.

## 1. `glab mr note` (preferred)

### List discussions

```bash
# Auto-detects MR from current branch
glab mr note list

# Filter by resolution state, type, or file
glab mr note list --state unresolved          # state: all | resolved | unresolved
glab mr note list --type diff                 # type:  all | general | diff | system
glab mr note list --file src/main.go          # only diff notes on this path

# JSON output for scripting
glab mr note list -F json | jq '.[] | {id, resolved, position}'

# Specific MR
glab mr note list 123
```

`-F json` returns discussion objects with nested `notes[]` — same shape as
`glab api .../discussions` but already filtered.

**`-F json` returns `null` (not `[]`) when there are no discussions.** This breaks naive `jq`
pipelines like `jq '.[]'` or `jq 'length'`. Guard with one of:

```bash
glab mr note list -F json | jq '. // [] | length'                     # default to []
glab mr note list -F json | jq 'if . == null then [] else . end | .[]' # iterate safely
```

### General comments

```bash
glab mr note create -m "Looks good!"
glab mr note create -m "$(cat "$MSG")"        # multi-line / backtick-safe (see SKILL.md)
echo "LGTM" | glab mr note create             # body from stdin

# Idempotent — skip if a note with the same body already exists
glab mr note create -m "LGTM" --unique
```

### Reply to an existing discussion thread

```bash
# Discussion ID prefix (8+ chars) or full 40-char ID
glab mr note create --reply abc12345 -m "Fixed in the next commit."
```

### Comments on diff lines

```bash
# Diff comment on a specific line (new side / added or unchanged line)
glab mr note create --file src/main.go --line 42 -m "Rename this variable."

# Multi-line range (anchor + N lines)
glab mr note create --file src/main.go --line 10:15 -m "Extract this block."

# Comment on a removed line (old side)
glab mr note create --file src/main.go --old-line 7 -m "Why was this removed?"

# File-level diff comment (no line specified)
glab mr note create --file src/main.go -m "General comment on this file."
```

`glab mr note create --file --line` resolves line types, paths, and version SHAs internally —
no `position` object to hand-build.

### Resolve / reopen threads

```bash
# Accepts discussion ID prefix (8+ chars), full discussion ID, or a note ID
glab mr note resolve abc12345
glab mr note reopen  abc12345

# Targeting a specific MR
glab mr note resolve 123 abc12345          # MR IID first, THEN discussion ID
glab mr note reopen  123 abc12345 -R owner/repo
```

**⚠️ Argument order is `<mr-iid> <discussion-id>`, NOT the reverse.** The CLI `--help` USAGE
line shows `resolve <discussion-id> [<id> | <branch>]` which is confusing — the `<id>` slot
is the MR IID (or branch), and when you pass both, **MR IID comes first**. The EXAMPLES
section of `--help` confirms this (`glab mr note resolve 123 abc12345`).

If a prefix matches multiple discussions, `glab` errors out with the ambiguous matches.

### Flag rules

- `--line` and `--old-line` **require `--file`**, and **cannot be used together**.
- `--file`, `--reply`, and `--unique` are **mutually exclusive**.
- All `create` subcommands accept the MR IID as a positional argument; omit it to auto-detect
  from the current branch.

### Targeting a specific MR or repo

The MR IID is always a **positional argument** (there is no `--mr` flag). Omit it to
auto-detect from the current branch.

```bash
glab mr note create 123 -m "Comment on MR 123"
glab mr note create 123 -R owner/repo -m "..."
glab mr note list -R owner/repo
glab mr note resolve 123 abc12345          # MR IID first, then discussion ID
glab mr note resolve abc12345              # auto-detect MR
```

### Multi-line bodies with backticks / code blocks

Follow the message-escaping rule from SKILL.md — write the body to a file with `<< 'EOF'`,
then pass `$(cat "$FILE")`:

```bash
MSG=$(mktemp)
cat > "$MSG" << 'EOF'
**Title**

Explanation with `inline code` and `$VAR`.

```go
// suggested fix
```
EOF
glab mr note create --file main.go --line 42 -m "$(cat "$MSG")"
```

---

## 2. Code suggestions

When you want to propose a specific change, embed GitLab's suggestion syntax in the note body.
GitLab renders an "Apply suggestion" button on the diff. Suggestions work in both
`glab mr note create --file --line ...` and draft notes.

Single-line replacement (comment anchored on that line):

````text
```suggestion:-0+0
replacement code here
```
````

Multi-line replacement — `-N` includes N lines above the anchor, `+M` includes M lines below:

````text
```suggestion:-2+1
all replacement lines here
```
````

Use suggestions when you have a concrete fix. Use plain text comments for questions or
broader patterns.

---

## 3. Draft notes via `glab api` (batched reviews)

Use this path **only** when you need to batch multiple inline comments and publish them
together as a single review event (one notification, all comments grouped). For any single
comment, prefer `glab mr note create` above.

### Fetching MR data

The `/diffs` endpoint returns full diff content for every file. Use `jq` to filter
client-side. Add `unidiff=true` (GitLab 16.5+) for standard unified-diff format, which is
easier to parse programmatically.

```bash
# Just the changed file paths
glab api "projects/<project_id>/merge_requests/<mr_iid>/diffs?per_page=100" \
  | jq '.[].new_path'

# Diff for a specific file (unified format)
glab api "projects/<project_id>/merge_requests/<mr_iid>/diffs?unidiff=true&per_page=100" \
  | jq '.[] | select(.new_path == "path/to/file.rb") | .diff'

# Page through large responses
glab api "projects/<project_id>/merge_requests/<mr_iid>/diffs?per_page=20&page=2"

# MR metadata
glab api "projects/<project_id>/merge_requests/<mr_iid>"
```

### MR version SHAs

Inline draft notes require three SHAs from the latest version. Always fetch fresh — cached
SHAs from a previous version may be rejected.

```bash
# ⚠️ API returns base_commit_sha / head_commit_sha / start_commit_sha
# but the position object expects base_sha / head_sha / start_sha — jq renames here
glab api "projects/<project_id>/merge_requests/<mr_iid>/versions" \
  | jq '.[0] | {base_sha: .base_commit_sha, head_sha: .head_commit_sha, start_sha: .start_commit_sha}'
```

### General draft note (not inline)

Use `-f` flags — no position object needed:

```bash
glab api --method POST \
  "projects/<project_id>/merge_requests/<mr_iid>/draft_notes" \
  -f note="Your summary comment here"
```

### Inline draft note

**⚠️ Do NOT use `-f` flags for inline draft notes** — the nested `position` object will not
serialize correctly and the comment will silently appear as a general (non-inline) note
instead of attached to the diff line.

Use JSON piped with `Content-Type: application/json`:

```bash
echo '{"note":"your comment","position":{"position_type":"text","base_sha":"BASE_SHA","head_sha":"HEAD_SHA","start_sha":"START_SHA","old_path":"path/to/file.rb","new_path":"path/to/file.rb","new_line":42}}' \
  | glab api --method POST \
    "projects/<project_id>/merge_requests/<mr_iid>/draft_notes" \
    -H "Content-Type: application/json" --input -
```

For multi-line note bodies, write the JSON to a file first:

```bash
cat > /tmp/draft.json << 'DRAFT'
{
  "note": "your comment here",
  "position": {
    "position_type": "text",
    "base_sha": "BASE_SHA",
    "head_sha": "HEAD_SHA",
    "start_sha": "START_SHA",
    "old_path": "path/to/file.rb",
    "new_path": "path/to/file.rb",
    "new_line": 42
  }
}
DRAFT
glab api --method POST \
  "projects/<project_id>/merge_requests/<mr_iid>/draft_notes" \
  -H "Content-Type: application/json" --input /tmp/draft.json
```

**Do NOT use `<(...)` process substitution** — it is not available in plain `sh`.

### Position object — line type rules

| Diff prefix       | Use                              | Omit       |
|-------------------|----------------------------------|------------|
| `+` (added line)  | `new_line`                       | `old_line` |
| `-` (removed line)| `old_line`                       | `new_line` |
| ` ` (context line)| both `old_line` and `new_line`   | —          |

Line numbers come from the diff hunk headers (`@@ -old_start,count +new_start,count @@`), not
from the source file's absolute line numbers. Count down from `old_start` / `new_start` to
your target. Lines prefixed with `-` advance `old_line`, `+` advances `new_line`, context
lines advance both.

For renames (`renamed_file: true`): use the `old_path` and `new_path` from the diff object
directly — they will differ. For most files: copy `new_path` into both `old_path` and
`new_path`.

### Bulk publish

After creating all draft notes, publish them as one review event:

```bash
glab api --method POST \
  "projects/<project_id>/merge_requests/<mr_iid>/draft_notes/bulk_publish"
```

This sends a single notification to MR participants with all your comments grouped together.

---

## 4. Discussions via `glab api` (last-resort fallback)

**Use Section 1 (`glab mr note`) for any read / reply / resolve.** This section exists only
for the narrow case where you need fields that `glab mr note list -F json` does not surface
(e.g. raw `position.base_sha` / `head_sha` for cross-referencing with the diff endpoint, or
the full `notes[].resolved_by` chain). For "list discussions to find a thread ID" or
"resolve thread X", **do not use these commands** — `glab mr note list` and
`glab mr note resolve` are correct and shorter.

```bash
# Fetch all discussions (each thread has id, notes array, position info)
glab api "projects/<project_id>/merge_requests/<mr_iid>/discussions?per_page=100"

# Extract key fields
glab api "projects/<project_id>/merge_requests/<mr_iid>/discussions?per_page=100" \
  | jq '.[] | {id, resolved: .notes[0].resolved, body: .notes[0].body}'
```

### Reply via the API (draft-mode reply, no position needed)

```bash
glab api --method POST \
  "projects/<project_id>/merge_requests/<mr_iid>/draft_notes" \
  -f note="your reply" \
  -f in_reply_to_discussion_id="DISCUSSION_ID"
```

For non-batched replies, prefer `glab mr note create --reply <id>`.

### Resolve / reopen via the API

```bash
# Resolve
glab api --method PUT \
  "projects/<project_id>/merge_requests/<mr_iid>/discussions/DISCUSSION_ID" \
  -f resolved=true

# Reopen
glab api --method PUT \
  "projects/<project_id>/merge_requests/<mr_iid>/discussions/DISCUSSION_ID" \
  -f resolved=false
```

For non-batched flows, prefer `glab mr note resolve|reopen <id>`.

---

## Gotchas

### `glab mr note`

- **EXPERIMENTAL flag** — `glab mr note *` is marked experimental in v1.94.0+. Stable enough
  for our workflows; watch upstream changelogs for flag changes.
- **`resolve`/`reopen` arg order is `<mr-iid> <discussion-id>`** — the `--help` USAGE line
  reads `<discussion-id> [<id>]` which is misleading. The EXAMPLES line is correct
  (`glab mr note resolve 123 abc12345`). MR IID always first when you pass both.
- **`-F json` returns `null` on empty** — not `[]`. Guard `jq` pipelines with `. // []` or
  `if . == null then [] else . end` before iterating / counting.
- **Ambiguous prefix** — `glab mr note resolve abc12345` errors if more than one discussion
  matches the prefix. Use a longer prefix or the full ID.
- **Flag exclusivity** — `--file`, `--reply`, and `--unique` cannot be combined. To
  idempotently post a diff comment, list existing notes first and check before creating.
- **Auto-detection failure** — if the current branch has no open MR (or is detached), pass
  the MR IID as a positional argument.

### `glab api .../draft_notes` (fallback)

- **`-f` for inline notes → silently broken** — position won't serialize; use `--input -`
  with JSON and `-H "Content-Type: application/json"`.
- **No process substitution** — `<(...)` is bash-only; write JSON to `/tmp/` for multi-line
  bodies.
- **SHA field name mismatch** — API returns `base_commit_sha` etc.; the position object
  expects `base_sha` etc. — always apply the jq rename.
- **SHAs expire** — always fetch `/versions` fresh.
- **Line numbers are diff-relative** — count from hunk headers, not from the raw file.
- **Draft notes are per-user** — `bulk_publish` publishes YOUR drafts; it won't publish
  drafts belonging to other users.
