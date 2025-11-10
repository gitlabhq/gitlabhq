---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Exact code search
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Limited availability

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 15.9 [with flags](../../administration/feature_flags/_index.md) named `index_code_with_zoekt` and `search_code_with_zoekt`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) in GitLab 16.6.
- Feature flags `index_code_with_zoekt` and `search_code_with_zoekt` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) in GitLab 17.1.
- [Changed](https://gitlab.com/groups/gitlab-org/-/epics/17918) from beta to limited availability in GitLab 18.6.

{{< /history >}}

{{< alert type="warning" >}}

This feature is in [limited availability](../../policy/development_stages_support.md#limited-availability).
For more information, see [epic 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404).
Provide feedback in [issue 420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920).

{{< /alert >}}

With exact code search, you can use exact match and regular expression modes
to search for code in all GitLab or in a specific project.

Exact code search is powered by Zoekt and is used by default
in groups where the feature is enabled.

## Use exact code search

Prerequisites:

- Exact code search must be enabled:
  - For GitLab.com, exact code search is enabled by default in paid subscriptions.
  - For GitLab Self-Managed, an administrator must
    [install Zoekt](../../integration/zoekt/_index.md#install-zoekt) and
    [enable exact code search](../../integration/zoekt/_index.md#enable-exact-code-search).

To use exact code search:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. In the search box, enter your search term.
1. On the left sidebar, select **Code**.

You can also use exact code search in a project or group.

## Available scopes

Scopes describe the type of data you're searching.
The following scopes are available for exact code search:

| Scope | Global <sup>1</sup> <sup>2</sup>   | Group                                       | Project |
|-------|:----------------------------------:|:-------------------------------------------:|:-------:|
| Code  | {{< icon name="dash-circle" >}} No | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |

**Footnotes**:

1. An administrator can [disable global search scopes](_index.md#disable-global-search-scopes).
   On GitLab Self-Managed, an administrator can enable global search
   with the `zoekt_cross_namespace_search` feature flag.
1. On GitLab.com, global search is not enabled.

## Zoekt search API

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143666) in GitLab 16.9 [with a flag](../../administration/feature_flags/_index.md) named `zoekt_search_api`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17522) in GitLab 18.4. Feature flag `zoekt_search_api` removed.

{{< /history >}}

With the Zoekt search API, you can use the search API for exact code search.
To use advanced search or basic search instead, [specify a search type](_index.md#specify-a-search-type).

## Global code search

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077) in GitLab 16.11 [with a flag](../../administration/feature_flags/_index.md) named `zoekt_cross_namespace_search`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

Use this feature to search code across the entire GitLab instance.

Global code search does not perform well on large GitLab instances.
When this feature is enabled for instances with more than 20,000 projects, your search might time out.

## Search modes

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/434417) in GitLab 16.8 [with a flag](../../administration/feature_flags/_index.md) named `zoekt_exact_search`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/436457) in GitLab 17.3. Feature flag `zoekt_exact_search` removed.

{{< /history >}}

GitLab has two search modes:

- **Exact match mode**: returns results that exactly match the query.
- **Regular expression mode**: supports regular and boolean expressions.

The exact match mode is used by default.
To switch to the regular expression mode, to the right of the search box,
select **Use regular expression** ({{< icon name="regular-expression" >}}).

### Syntax

<!-- Remember to also update the table in `doc/drawers/exact_code_search_syntax.md` -->

This table shows some example queries for exact match and regular expression modes.

| Query                | Exact match mode                                        | Regular expression mode |
| -------------------- | ------------------------------------------------------- | ----------------------- |
| `"foo"`              | `"foo"`                                                 | `foo` |
| `foo file:^doc/`     | `foo` in directories that start with `/doc`             | `foo` in directories that start with `/doc` |
| `"class foo"`        | `"class foo"`                                           | `class foo` |
| `class foo`          | `class foo`                                             | `class` and `foo` |
| `foo or bar`         | `foo or bar`                                            | `foo` or `bar` |
| `class Foo`          | `class Foo` (case-sensitive)                            | `class` (case-insensitive) and `Foo` (case-sensitive) |
| `class Foo case:yes` | `class Foo` (case-sensitive)                            | `class` and `Foo` (both case-sensitive) |
| `foo -bar`           | `foo -bar`                                              | `foo` but not `bar` |
| `foo file:js`        | `foo` in files with names that contain `js`             | `foo` in files with names that contain `js` |
| `foo -file:test`     | `foo` in files with names that do not contain `test`    | `foo` in files with names that do not contain `test` |
| `foo lang:ruby`      | `foo` in Ruby source code                               | `foo` in Ruby source code |
| `foo file:\.js$`     | `foo` in files with names that end with `.js`           | `foo` in files with names that end with `.js` |
| `foo.*bar`           | `foo.*bar` (literal)                                    | `foo.*bar` (regular expression) |
| `sym:foo`            | `foo` in symbols like class, method, and variable names | `foo` in symbols like class, method, and variable names |

## Known issues

- You can search only files smaller than 1 MB with less than `20_000` trigrams.
  For more information, see [issue 455073](https://gitlab.com/gitlab-org/gitlab/-/issues/455073).
- You can use exact code search only on the default branch of a project.
  For more information, see [issue 403307](https://gitlab.com/gitlab-org/gitlab/-/issues/403307).
- Multiple matches on a single line are counted as one result.
- If you encounter results where newlines are not displayed correctly,
  update `gitlab-zoekt` to version 1.5.0 or later.
