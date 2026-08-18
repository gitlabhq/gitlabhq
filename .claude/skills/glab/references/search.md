# Search via `glab api`

Use `glab api` to call the GitLab Search REST API directly — no extra CLI flags needed.

## Instance-level search

```bash
# Search issues across the entire instance
glab api --method GET "search?scope=issues&search=login+bug" | jq '.[] | {iid, title, web_url}'

# Search merge requests instance-wide
glab api --method GET "search?scope=merge_requests&search=refactor" | jq '.[] | {iid, title, state}'

# Paginate: 50 results per page, page 2
glab api --method GET "search?scope=issues&search=bug&per_page=50&page=2" | jq '.[] | {iid, title}'

# Filter by state
glab api --method GET "search?scope=merge_requests&search=auth&state=merged" | jq '.[] | {iid, title}'
```

## Group-level search

```bash
# Search issues within a group
glab api --method GET "groups/gitlab-org/search?scope=issues&search=performance" | jq '.[] | {iid, title, web_url}'

# Search merge requests in a group
glab api --method GET "groups/gitlab-org/search?scope=merge_requests&search=refactor" | jq '.[] | {iid, title, state}'

# Nested group — encode the slash as %2F
glab api --method GET "groups/gitlab-org%2Ffoundations/search?scope=issues&search=bug" | jq '.[] | {iid, title}'
```

## Project-level search

```bash
# Search issues in a project (URL-encode the project path: / → %2F)
glab api --method GET "projects/gitlab-org%2Fcli/search?scope=issues&search=crash" | jq '.[] | {iid, title}'

# Code search (blobs) — requires Advanced Search or Exact Code Search
glab api --method GET "projects/gitlab-org%2Fcli/search?scope=blobs&search=handleAuth" | jq '.[] | {path, startline, data}'

# Commits — requires Advanced Search
glab api --method GET "projects/gitlab-org%2Fcli/search?scope=commits&search=fix+nil" | jq '.[] | {id, title, authored_date}'

# Wiki pages — requires Advanced Search
glab api --method GET "projects/gitlab-org%2Fcli/search?scope=wiki_blobs&search=setup" | jq '.[] | {path, data}'

# Notes (comments) — requires Advanced Search
glab api --method GET "projects/gitlab-org%2Fcli/search?scope=notes&search=LGTM" | jq '.[] | {id, body}'
```

## Scope availability

| Scope | Instance | Group | Project | Requires |
|-------|----------|-------|---------|----------|
| `projects` | ✅ | ✅ | — | Free |
| `issues` | ✅ | ✅ | ✅ | Free |
| `merge_requests` | ✅ | ✅ | ✅ | Free |
| `milestones` | ✅ | ✅ | ✅ | Free |
| `users` | ✅ | ✅ | ✅ | Free |
| `work_items` | ✅ | ✅ | ✅ | Free |
| `snippet_titles` | ✅ | — | — | Free |
| `blobs` (code) | — | — | ✅ | Advanced Search or Exact Code Search |
| `commits` | — | — | ✅ | Advanced Search |
| `wiki_blobs` | — | — | ✅ | Advanced Search |
| `notes` | — | — | ✅ | Advanced Search |

## Common gotchas

- **`glab api` has no `--jq`** — pipe its output through `| jq '...'` (the search endpoints are all `glab api`). The global `--jq` flag added to `glab issue list`/`glab mr list`/`glab ci list` does not apply to `glab api`.
- **URL-encode project paths** — use `%2F` for `/`: `projects/gitlab-org%2Fcli/search?...`
- **Nested groups need `%2F`** — `groups/gitlab-org%2Fsubgroup/search?...`; unencoded slashes → 404
- **Pagination** — add `per_page=<n>&page=<n>`; default page size is 20, max is 100
- **Tier restrictions** — `blobs` requires Advanced Search or Exact Code Search; `commits`, `wiki_blobs`, and `notes` require Advanced Search
