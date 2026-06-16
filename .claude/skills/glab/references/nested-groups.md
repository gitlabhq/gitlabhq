# Nested Groups

GitLab group paths can be multiple levels deep (e.g. `gitlab-org/foundations/design-system`). The encoding rules differ between REST and GraphQL.

## REST API — encode every `/` as `%2F`

```bash
# Two-level group
glab api "groups/gitlab-org%2Ffoundations/epics"

# Three-level group
glab api "groups/gitlab-org%2Ffoundations%2Fdesign-system/epics"

# ❌ Unencoded slashes return 404 — this is a common mistake
glab api "groups/gitlab-org/foundations/epics"   # FAILS
```

This applies everywhere you embed a group path in a REST URL segment:

```bash
# Group ID lookup
glab api "groups/gitlab-org%2Ffoundations" | jq '.id'   # → 12627982

# List epics
glab api "groups/gitlab-org%2Ffoundations%2Fdesign-system/epics"

# Create epic in nested group
glab api --method POST "groups/gitlab-org%2Ffoundations/epics" -f title="My Epic"
```

## GraphQL — use plain `/` in `fullPath`

No encoding needed. Pass the path exactly as written:

```bash
glab api graphql -f query='
{
  group(fullPath: "gitlab-org/foundations/design-system") {
    id
    name
    workItem(iid: "1") {
      title
    }
  }
}'
```

## Quick reference

| Context | Format | Example |
|---------|--------|---------|
| REST URL segment | `%2F` encoded | `groups/org%2Fsubgroup/epics` |
| GraphQL `fullPath` | plain `/` | `fullPath: "org/subgroup"` |
| `-R` flag | `OWNER/REPO` only | not usable for group paths |

## Group ID lookup

```bash
# Works the same for any depth
glab api "groups/gitlab-org%2Ffoundations" | jq '.id'               # → 12627982
glab api "groups/gitlab-org%2Ffoundations%2Fdesign-system" | jq '.id'  # → 90514461
```

Once you have the numeric ID you can use it directly in REST calls without any encoding:

```bash
GROUP_ID=$(glab api "groups/gitlab-org%2Ffoundations" | jq '.id')
glab api "groups/${GROUP_ID}/epics"
```
