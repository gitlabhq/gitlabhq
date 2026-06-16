# Issue Links (blocked_by, related)

REST API for managing relationships between issues.

## List links

```bash
glab api "projects/<project_id>/issues/<iid>/links" | jq '.[] | {iid, title, link_type}'
```

## Create links

```bash
# "blocked by" — issue 20 is blocked by issue 10
glab api --method POST "projects/<project_id>/issues/20/links" \
  -f target_project_id=<project_id> \
  -f target_issue_iid=10 \
  -f link_type=is_blocked_by

# "blocks" — issue 10 blocks issue 20 (same result, opposite direction)
glab api --method POST "projects/<project_id>/issues/10/links" \
  -f target_project_id=<project_id> \
  -f target_issue_iid=20 \
  -f link_type=blocks

# "related" — non-blocking association
glab api --method POST "projects/<project_id>/issues/20/links" \
  -f target_project_id=<project_id> \
  -f target_issue_iid=10 \
  -f link_type=relates_to
```

## Remove a link

```bash
# The issue_link_id comes from the list response (not the issue iid)
# IMPORTANT: <iid> must be the SOURCE issue (the one used in the POST that created the link).
# Using the target issue returns 404.
glab api --method DELETE "projects/<project_id>/issues/<source_iid>/links/<issue_link_id>"
```

## Link types

| Value (creation) | Meaning |
|------------------|---------|
| `relates_to` | Non-blocking association |
| `is_blocked_by` | This issue is blocked by the target |
| `blocks` | This issue blocks the target |

In list responses, `link_type` is shown from the perspective of the queried issue.

## Cross-project links

Set `target_project_id` to a different project:

```bash
glab api --method POST "projects/<source_project_id>/issues/20/links" \
  -f target_project_id=<target_project_id> \
  -f target_issue_iid=10 \
  -f link_type=is_blocked_by
```
