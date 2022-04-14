---
stage: Enablement
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# GitLab Advanced Search **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

NOTE:
This is the user documentation. To configure the Advanced Search,
visit the [administrator documentation](../../integration/elasticsearch.md).
Advanced Search is enabled in GitLab.com.

GitLab Advanced Search expands on the Basic Search with an additional set of
features for faster, more advanced searches across the entire GitLab instance
when searching in:

- Projects
- Issues
- Merge requests
- Milestones
- Epics
- Comments
- Code
- Commits
- Users
- Wiki (except [group wikis](../project/wiki/group.md))

The Advanced Search can be useful in various scenarios:

- **Faster searches:**
  Advanced Search is based on Elasticsearch, which is a purpose-built full
  text search engine that can be horizontally scaled so that it can provide
  search results in 1-2 seconds in most cases.
- **Code Maintenance:**
  Finding all the code that needs to be updated at once across an entire
  instance can save time spent maintaining code.
  This is especially helpful for organizations with more than 10 active projects.
  This can also help build confidence is code refactoring to identify unknown impacts.
- **Promote innersourcing:**
  Your company may consist of many different developer teams each of which has
  their own group where the various projects are hosted. Some of your applications
  may be connected to each other, so your developers need to instantly search
  throughout the GitLab instance and find the code they search for.

## Advanced Search syntax

See the documentation on [Advanced Search syntax](global_search/advanced_search_syntax.md).

## Search by issue or merge request ID

You can search a specific issue or merge request by its ID with a special prefix.

- To search by issue ID, use prefix `#` followed by issue ID. For example, [#23456](https://gitlab.com/search?snippets=&scope=issues&repository_ref=&search=%2323456&group_id=9970&project_id=278964)
- To search by merge request ID, use prefix `!` followed by merge request ID. For example [!23456](https://gitlab.com/search?snippets=&scope=merge_requests&repository_ref=&search=%2123456&group_id=9970&project_id=278964)

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/346263) in GitLab 14.6 [with a flag](../../administration/feature_flags.md) named `prevent_abusive_searches`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `prevent_abusive_searches`.
The feature is not ready for production use.

To prevent abusive searches, such as searches that may result in a Distributed Denial of Service (DDoS), Global Search ignores, logs, and
doesn't return any results for searches considered abusive according to the following criteria, if `prevent_abusive_searches` feature flag is enabled:

- Searches with less than 2 characters.
- Searches with any term greater than 100 characters. URL search terms have a maximum of 200 characters.
- Searches with a stop word as the only term (ie: "the", "and", "if", etc.).
- Searches with a `group_id` or `project_id` parameter that is not completely numeric.
- Searches with a `repository_ref` or `project_ref` parameter that has special characters not allowed by [Git refname](https://git-scm.com/docs/git-check-ref-format).
- Searches with a `scope` that is unknown.

Regardless of the status of the `prevent_abusive_searches` feature flag, searches that don't
comply with the criteria described below aren't logged as abusive but are flagged with an error:

- Searches with more than 4096 characters.
- Searches with more than 64 terms.
