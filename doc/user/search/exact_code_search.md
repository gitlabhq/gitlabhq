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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) as a [beta](../../policy/experiment-beta-support.md#beta) in GitLab 15.9 [with flags](../../administration/feature_flags.md) named `index_code_with_zoekt` and `search_code_with_zoekt`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) in GitLab 16.6.
> - Feature flags `index_code_with_zoekt` and `search_code_with_zoekt` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) in GitLab 17.1.

WARNING:
This feature is in [beta](../../policy/experiment-beta-support.md#beta) and subject to change without notice.
For more information, see [epic 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404).

With exact code search, you can use regular expression and exact match modes
to search for code in all GitLab or in a specific project.

Exact code search is powered by [Zoekt](https://github.com/sourcegraph/zoekt)
and is used by default in groups where the feature is enabled.

## Enable exact code search

- For [GitLab.com](../../subscriptions/gitlab_com/index.md),
  exact code search is enabled in paid subscriptions.
- For [GitLab self-managed](../../subscriptions/self_managed/index.md), an administrator must
  [install Zoekt](../../integration/exact_code_search/zoekt.md#install-zoekt) and
  [enable exact code search](../../integration/exact_code_search/zoekt.md#enable-exact-code-search).

## Zoekt search API

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143666) in GitLab 16.9 [with a flag](../../administration/feature_flags.md) named `zoekt_search_api`. Enabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

With the Zoekt search API, you can use the [search API](../../api/search.md) for exact code search.
If you want to use [advanced search](advanced_search.md) or basic search instead, see
[specify a search type](index.md#specify-a-search-type).

By default, the Zoekt search API is disabled on GitLab.com to avoid breaking changes.
To request access to this feature, contact GitLab.

## Global code search

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077) in GitLab 16.11 [with a flag](../../administration/feature_flags.md) named `zoekt_cross_namespace_search`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

Use this feature to search code across the entire GitLab instance.

Global code search does not perform well on large GitLab instances.
When this feature is enabled for instances with more than 20,000 projects, your search might time out.

## Search modes

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/434417) in GitLab 16.8 [with a flag](../../administration/feature_flags.md) named `zoekt_exact_search`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/436457) in GitLab 17.3. Feature flag `zoekt_exact_search` removed.

GitLab has two search modes:

- **Regular expression mode:** supports regular and boolean expressions.
- **Exact match mode:** returns results that exactly match the query.

The exact match mode is used by default.
To switch to the regular expression mode, to the right of the search box,
select **Use regular expression** (**{regular-expression}**).

### Syntax

This table shows some example queries for regular expression and exact match modes.

| Query                | Regular expression mode                                 | Exact match mode               |
| -------------------- | ------------------------------------------------------- | ------------------------------ |
| `"foo"`              | `foo`                                                   | `"foo"`                        |
| `foo file:^doc/`     | `foo` in directories that start with `/doc`             | `foo` in directories that start with `/doc` |
| `"class foo"`        | `class foo`                                             | `"class foo"`                  |
| `class foo`          | `class` and `foo`                                       | `class foo`                    |
| `foo or bar`         | `foo` or `bar`                                          | `foo or bar`                   |
| `class Foo`          | `class` (case insensitive) and `Foo` (case sensitive)   | `class Foo` (case insensitive) |
| `class Foo case:yes` | `class` and `Foo` (both case sensitive)                 | `class Foo` (case sensitive)   |
| `foo -bar`           | `foo` but not `bar`                                     | `foo -bar`                     |
| `foo file:js`        | `foo` in files with names that contain `js`             | `foo` in files with names that contain `js` |
| `foo -file:test`     | `foo` in files with names that do not contain `test`    | `foo` in files with names that do not contain `test` |
| `foo lang:ruby`      | `foo` in Ruby source code                               | `foo` in Ruby source code      |
| `foo file:\.js$`     | `foo` in files with names that end with `.js`           | `foo` in files with names that end with `.js` |
| `foo.*bar`           | `foo.*bar` (regular expression)                         | None                           |
| `sym:foo`            | `foo` in symbols like class, method, and variable names | `foo` in symbols like class, method, and variable names |

## Known issues

- You can only search files smaller than 1 MB with less than `20_000` trigrams.
  For more information, see [issue 455073](https://gitlab.com/gitlab-org/gitlab/-/issues/455073).
- You can use exact code search on the default branch of a project only.
  For more information, see [issue 403307](https://gitlab.com/gitlab-org/gitlab/-/issues/403307).
