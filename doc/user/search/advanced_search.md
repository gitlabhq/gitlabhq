---
stage: Data Stores
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference
---

# Advanced Search **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

You can use Advanced Search for faster, more efficient search across the entire GitLab
instance. Advanced Search is based on Elasticsearch, a purpose-built full-text search
engine you can horizontally scale to get results in up to a second in most cases.

You can find code you want to update in all projects at once to save
maintenance time and promote innersourcing.

You can use Advanced Search in:

- Projects
- Issues
- Merge requests
- Milestones
- Users
- Epics (in groups only)
- Code
- Comments
- Commits
- Project wikis (not [group wikis](../project/wiki/group.md))

## Configure Advanced Search

- On GitLab.com, Advanced Search is enabled for groups with paid subscriptions.
- For self-managed GitLab instances, an administrator must
  [configure Advanced Search](../../integration/advanced_search/elasticsearch.md).

## Syntax

See [Advanced Search syntax](global_search/advanced_search_syntax.md) for more information.

## Search by ID

- To search by issue ID, use the `#` prefix followed by the issue ID (for example, [`#23456`](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=%2323456&group_id=9970&project_id=278964)).
- To search by merge request ID, use the `!` prefix followed by the merge request ID (for example, [`!23456`](https://gitlab.com/search?snippets=&scope=merge_requests&repository_ref=&search=%2123456&group_id=9970&project_id=278964)).
