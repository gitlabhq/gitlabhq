---
stage: Data Stores
group: Global Search
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Exact code search

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) in GitLab 15.9 [with flags](../../administration/feature_flags.md) named `index_code_with_zoekt` and `search_code_with_zoekt`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available.
To make it available, an administrator can [enable the feature flags](../../administration/feature_flags.md) named `index_code_with_zoekt` and `search_code_with_zoekt`.
On GitLab.com, this feature is available. On GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

WARNING:
This feature is in [Beta](../../policy/experiment-beta-support.md#beta) and subject to change without notice.
For more information, see [epic 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404).

With exact code search, you can use regular expressions and exact strings to search for code in a project.
You can use backslashes to escape special characters and double quotes to search for exact strings.

Exact code search is powered by [Zoekt](https://github.com/sourcegraph/zoekt)
and is used by default in groups where the feature is enabled.

## Zoekt search API

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143666) in GitLab 16.9 [with a flag](../../administration/feature_flags.md) named `zoekt_search_api`. Enabled by default.

FLAG:
On self-managed GitLab, by default this feature is available.
To hide the feature, an administrator can [disable the feature flag](../../administration/feature_flags.md) named `zoekt_search_api`.
On GitLab.com and GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

With the Zoekt search API, you can use the [search API](../../api/search.md) for exact code search.
When this feature is disabled, basic or advanced search is used instead.

By default, the Zoekt search API is disabled on GitLab.com to avoid breaking changes.
To request access to this feature, contact GitLab.

## Global code search

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077) in GitLab 16.11 [with a flag](../../administration/feature_flags.md) named `zoekt_cross_namespace_search`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available.
To make it available, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `zoekt_cross_namespace_search`.
On GitLab.com and GitLab Dedicated, this feature is not available.
This feature is not ready for production use.

Use this feature to search code across the entire GitLab instance.

Global code search does not perform well on large GitLab instances.
If you enable this feature for instances with more than 20,000 projects, your search might time out.

## Syntax

This table shows some example queries for exact code search.

| Query                | Description                                                                       |
|----------------------|-----------------------------------------------------------------------------------|
| `foo`                | Returns files that contain `foo`.                                                 |
| `foo file:^doc/`     | Returns files that contain `foo` in directories that start with `doc/`.           |
| `"class foo"`        | Returns files that contain the exact string `class foo`.                          |
| `class foo`          | Returns files that contain both `class` and `foo`.                                |
| `foo or bar`         | Returns files that contain either `foo` or `bar`.                                 |
| `class Foo`          | Returns files that contain `class` (case insensitive) and `Foo` (case sensitive). |
| `class Foo case:yes` | Returns files that contain `class` and `Foo` (both case sensitive).               |
| `foo -bar`           | Returns files that contain `foo` but not `bar`.                                   |
| `foo file:js`        | Searches for `foo` in files with names that contain `js`.                         |
| `foo -file:test`     | Searches for `foo` in files with names that do not contain `test`.                |
| `foo lang:ruby`      | Searches for `foo` in Ruby source code.                                           |
| `foo file:\.js$`     | Searches for `foo` in files with names that end with `.js`.                       |
| `foo.*bar`           | Searches for strings that match the regular expression `foo.*bar`.                |
