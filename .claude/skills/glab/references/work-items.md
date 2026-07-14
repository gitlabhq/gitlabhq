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

## Agent plan (Workplan) widget

The **agent_plan** widget (the "Workplan" in the UI) holds a coding agent's plan for a work item. Read and write it through the same `project.workItems(iid:)` query above, selecting the `WorkItemWidgetAgentPlan` widget. EE, experiment-gated (GitLab 19.0+, `:workplan` feature flag); CE and older instances won't expose it.

**Read** -- capture the work item `id`; you need it to write back. Only one work item's `content` resolves per request (a server-side field-call cap), so fetch one at a time:

```bash
glab api graphql -f query='
{
  project(fullPath: "org/project") {
    workItems(first: 1, iid: "33") {
      nodes {
        id
        widgets { type ... on WorkItemWidgetAgentPlan { content } }
      }
    }
  }
}' | jq -r '.data.project.workItems.nodes[0].widgets[]
            | select(.type == "AGENT_PLAN") | .content'
```

`content` is `null` when no plan exists yet.

**Write** -- `workItemUpdate` with `agentPlanWidget` **replaces** the whole plan (no append/patch; fetch current content first if you want to extend it). Plans are large markdown full of backticks and `$`, so write the plan to a file and pass it via a variable -- see the **Message Escaping** section in `SKILL.md`. Never string-interpolate content into the query:

```bash
glab api graphql -f query='
mutation($id: WorkItemID!, $content: String!) {
  workItemUpdate(input: { id: $id, agentPlanWidget: { content: $content } }) {
    errors
    workItem { widgets { type ... on WorkItemWidgetAgentPlan { content } } }
  }
}' -f id="gid://gitlab/WorkItem/<n>" -f content="$(cat "$PLAN")"
```

Confirm `data.workItemUpdate.errors` is `[]`. The same `agentPlanWidget` input works on `workItemCreate` to seed a plan on a new work item. Reads work under `api` / `read_api` / `ai_workflows`; writes need `update_work_item`. Content limit ~128 KB.

## Gotchas

- **`/work_items/` in URLs is cosmetic** — the REST API uses `/issues/<iid>` with the same number
- **`groups/<id>/work_items` is 404** — no REST equivalent; use epics endpoint or GraphQL
- **`project.workItem` (singular) doesn't exist** — GraphQL error will say "Did you mean workItems?"
- **`filter:` argument not accepted** — `workItems(filter: {iid: "1"})` fails; use `workItems(iid: "1")` directly
