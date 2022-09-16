---
stage: Data Stores
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
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

## Global search scopes **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68640) in GitLab 14.3.

To improve the performance of your instance's global search, you can limit
the scope of the search. To do so, you can exclude global search scopes by disabling
[`ops` feature flags](../../development/feature_flags/index.md#ops-type).

Global search has all its scopes **enabled** by default in GitLab SaaS and
self-managed instances. A GitLab administrator can disable the following `ops`
feature flags to limit the scope of your instance's global search and optimize
its performance:

| Scope | Feature flag | Description |
|--|--|--|
| Code | `global_search_code_tab` | When enabled, the global search includes code as part of the search. |
| Commits | `global_search_commits_tab` | When enabled, the global search includes commits as part of the search. |
| Issues | `global_search_issues_tab` | When enabled, the global search includes issues as part of the search. |
| Merge Requests | `global_search_merge_requests_tab` | When enabled, the global search includes merge requests as part of the search. |
| Users | `global_search_users_tab` | When enabled, the global search includes users as part of the search. |
| Wiki | `global_search_wiki_tab` | When enabled, the global search includes wiki as part of the search. [Group wikis](../project/wiki/group.md) are not included. |

## Global Search validation

To prevent abusive searches, such as searches that may result in a Distributed Denial of Service (DDoS), Global Search ignores, logs, and
doesn't return any results for searches considered abusive according to the following criteria:

- Searches with less than 2 characters.
- Searches with any term greater than 100 characters. URL search terms have a maximum of 200 characters.
- Searches with a stop word as the only term (for example, "the", "and", "if", etc.).
- Searches with a `group_id` or `project_id` parameter that is not completely numeric.
- Searches with a `repository_ref` or `project_ref` parameter that has special characters not allowed by [Git refname](https://git-scm.com/docs/git-check-ref-format).
- Searches with a `scope` that is unknown.

Searches that don't comply with the criteria described below aren't logged as abusive but are flagged with an error:

- Searches with more than 4096 characters.
- Searches with more than 64 terms.
