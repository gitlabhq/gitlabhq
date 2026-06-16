# Epics — CRUD Reference

Epics are group-level. `glab issue` commands don't work — use `glab api` with the REST API.

For **comments/notes** → [epic-comments.md](epic-comments.md)  
For **nested group paths** → [nested-groups.md](nested-groups.md)

## Finding IDs

```bash
# Group ID from path
glab api "groups/my-group" | jq '.id'

# Epic: response includes id (internal global), iid (display number), work_item_id
glab api "groups/<group_id>/epics/<iid>" | jq '{id, iid, title, work_item_id}'
```

## List and view

```bash
# List epics in a group
glab api "groups/<group_id>/epics" | jq '.[] | {iid, title, state}'

# View a single epic
glab api "groups/<group_id>/epics/<iid>"

# List issues linked to an epic
glab api "groups/<group_id>/epics/<epic_iid>/issues" | jq '.[] | {iid, title, state}'
```

## Create

```bash
# Simple epic
glab api --method POST "groups/<group_id>/epics" \
  -f title="My Epic" \
  -f "description=$(cat /tmp/epic-description.md)"

# With parent epic — parent_id is the INTERNAL id (not iid)
PARENT_ID=$(glab api "groups/<group_id>/epics/<parent_iid>" | jq '.id')
glab api --method POST "groups/<group_id>/epics" \
  -f title="Child Epic" \
  -f "description=$(cat /tmp/description.md)" \
  -f parent_id=$PARENT_ID
```

## Update

```bash
glab api --method PUT "groups/<group_id>/epics/<iid>" \
  -f title="New Title" \
  -f "description=$(cat /tmp/epic-description.md)"
```

## Close and reopen

Epic state transitions work via REST — no GraphQL needed:

```bash
glab api --method PUT "groups/<group_id>/epics/<iid>" -f state_event=close
glab api --method PUT "groups/<group_id>/epics/<iid>" -f state_event=reopen
```

## Add / remove issues

```bash
# Add — preferred: update the issue's epic_id directly
EPIC_ID=$(glab api "groups/<group_id>/epics/<epic_iid>" | jq '.id')
glab api --method PUT "projects/<project_id>/issues/<iid>" -f epic_id=$EPIC_ID

# Add — alternative (may 404 depending on plan)
ISSUE_ID=$(glab api "projects/<project_id>/issues/<iid>" | jq '.id')
glab api --method POST "groups/<group_id>/epics/<epic_iid>/issues/$ISSUE_ID"

# Remove — preferred: set epic_id to 0
glab api --method PUT "projects/<project_id>/issues/<iid>" -f epic_id=0

# Remove — alternative (needs epic_issue_id from list response, not the issue iid)
glab api --method DELETE "groups/<group_id>/epics/<epic_iid>/issues/<epic_issue_id>"
```

## URL parsing

```
https://gitlab.com/groups/<group-path>/-/epics/<iid>
```

Example: `https://gitlab.com/groups/gitlab-org/-/epics/16428`
- Group path: `gitlab-org` → `glab api "groups/gitlab-org" | jq '.id'` → `9970`
- Epic IID: `16428`

For nested group paths like `gitlab-org/foundations`, see [nested-groups.md](nested-groups.md).

## Gotchas

- **`parent_id` is the internal id, not iid** — use `jq '.id'`, not `jq '.iid'`
- **`glab issue` doesn't work** — always use `glab api` for epics
- **No `-R` flag** — `-R` expects `OWNER/REPO`. Group endpoints don't use it
- **jq and multiline content** — descriptions with newlines break jq pipelines. Extract specific fields: `jq '{id, iid, title}'`. Never pipe raw epic JSON through jq selection on full output
