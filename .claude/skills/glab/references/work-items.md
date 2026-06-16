# Work Items

GitLab is migrating from "issues" to "work items". The UI shows `/work_items/<iid>` URLs, but the underlying data is the same.

## Project-level work items — use the issues REST API

Work item IIDs and issue IIDs share the same space within a project. The `/work_items/` REST endpoint does not exist — use `/issues/` instead:

```bash
# ✅ Correct — issues API works for work items
glab api "projects/org%2Fproject/issues/<iid>"
glab api "projects/<project_id>/issues/<iid>/notes"
glab api --method POST "projects/<project_id>/issues/<iid>/notes" -f "body=comment"

# ❌ Wrong — this endpoint doesn't exist
glab api "projects/org%2Fproject/work_items/<iid>"   # → 404
```

URL parsing:
```
https://gitlab.com/org/project/-/work_items/539076
→ project: org/project  →  glab api "projects/org%2Fproject/issues/539076"
```

## Group-level work_items — REST endpoint doesn't exist

```bash
glab api "groups/<id>/work_items"   # → 404 always
```

Use these instead:

```bash
# List epics (REST)
glab api "groups/<group_id>/epics" | jq '.[] | {iid, title, state}'

# Single epic as work item (GraphQL)
glab api graphql -f query='
{
  group(fullPath: "<group-path>") {
    workItem(iid: "<iid>") { id title workItemType { name } }
  }
}'

# List work items in a group (GraphQL)
glab api graphql -f query='
{
  group(fullPath: "<group-path>") {
    workItems(first: 20) {
      nodes { iid title workItemType { name } }
    }
  }
}'
```

## Project-level work items via GraphQL

Prefer REST for project work items — it's simpler. Use GraphQL when you need the full widget interface (e.g. `NOTES` widget, `HIERARCHY` widget):

```bash
# ⚠️ project.workItem (singular) does NOT exist → use workItems (plural)
# ⚠️ workItems does NOT accept a filter: {} argument → pass iid: directly
# ⚠️ WorkItem has no type field → use workItemType { name }
glab api graphql -f query='
{
  project(fullPath: "org/project") {
    workItems(first: 1, iid: "539076") {
      nodes {
        id
        iid
        title
        workItemType { name }
        widgets {
          type
          ... on WorkItemWidgetNotes {
            discussions(first: 50) {
              pageInfo { hasNextPage endCursor }
              nodes {
                notes {
                  nodes { id body author { username } createdAt }
                }
              }
            }
          }
        }
      }
    }
  }
}'
```

## Gotchas

- **`/work_items/` in URLs is cosmetic** — the REST API uses `/issues/<iid>` with the same number
- **`groups/<id>/work_items` is 404** — no REST equivalent; use epics endpoint or GraphQL
- **`project.workItem` (singular) doesn't exist** — GraphQL error will say "Did you mean workItems?"
- **`filter:` argument not accepted** — `workItems(filter: {iid: "1"})` fails; use `workItems(iid: "1")` directly
