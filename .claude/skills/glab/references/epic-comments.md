# Epic Comments (Notes)

**⚠️ The REST `/groups/<id>/epics/<iid>/notes` endpoint returns 404 — it does not exist.**

Both **GET and POST** on this endpoint 404. Verified on gitlab.com and on a GitLab
19.1 instance (GDK) — GraphQL is still the only way to read or write epic comments,
and there is no native `glab epic` subcommand. Epics are internally implemented as
work items; use the wrapper scripts below (or the GraphQL templates they consume).

## Quick start — use the scripts

```bash
# Read comments (handles pagination automatically)
epic-notes.sh <group-path> <epic-iid>
# Example:
epic-notes.sh gitlab-org 16428

# Post a comment
create-epic-note.sh <group-id> <epic-iid> "comment body"
# Example:
create-epic-note.sh 9970 16428 "This is my comment"
```

The scripts live in `scripts/` alongside the skill and consume the GraphQL documents
in `assets/graphql/` (the single source for the query and mutation — see [Template
files](#template-files)). Use the scripts; the notes below explain *why* they are
shaped the way they are, so you can read or extend them.

## Why the scripts use these shapes

**Reading** (`epic-notes.sh` → `assets/graphql/epic-notes.graphql`):
- Pass the group path and iid as GraphQL **variables** (`-f`, raw string — `-F`
  coerces a numeric-looking iid to `Int`, failing `String!`).
- `widgets[].type == "NOTES"` holds the `discussions`; each `discussion` is a thread
  and `notes.nodes` are its replies.
- Pagination is driven by `pageInfo.hasNextPage` + `pageInfo.endCursor`; the script
  re-runs with `cursor` set to the previous `endCursor`. `pageSize: 100` covers most
  epics in one request; only very high-traffic epics need multiple pages.

**Posting** (`create-epic-note.sh` → `assets/graphql/create-note.graphql`):
- The REST notes endpoint (POST) also 404s, so the script uses the `createNote`
  mutation. It first resolves the epic's internal `id` (not `iid`) and builds
  `noteableId` as `gid://gitlab/Epic/<internal_id>`.
- `noteableId` and `body` are passed as **variables** (`-f`), never string-interpolated:
  bodies with newlines, backticks, `$`, or non-ASCII characters (e.g. an em dash)
  break an interpolated query — and on GitLab 19.1+ a stray non-ASCII byte outside a
  `#` comment raises `UNKNOWN_CHAR`. Variables sidestep all of it.

## Template files

The `.graphql` files in `assets/graphql/` are the source of truth for the queries
above, parameterised with GraphQL **variables** (passed via `glab api graphql -f`/`-F`,
no string substitution):

- `assets/graphql/epic-notes.graphql` — read query (`groupPath`, `epicIid`, `pageSize`, `cursor`)
- `assets/graphql/create-note.graphql` — `createNote` mutation (`noteableId`, `body`)

To run a query ad hoc without the scripts, pass the matching template as
`-f query="$(cat assets/graphql/epic-notes.graphql)"` along with its variables.

## Why REST doesn't work

GitLab migrated epics to the work items data model. The legacy REST endpoints for epic notes (`/notes`, `/discussions`) were removed. The epic response still includes a `work_item_id` field that exposes this relationship. GraphQL via `group.workItem(iid: "...")` is the stable path.
