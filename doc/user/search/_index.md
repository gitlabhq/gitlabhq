---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Searching in GitLab
description: Basic, advanced, exact, search scope, and commit SHA search.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Find what you need in a growing codebase or expanding organization.
Save time by looking up specific code, issues, merge requests, and other content across your projects.
Choose from three types of search to match your needs: **basic search**,
[**advanced search**](advanced_search.md), and [**exact code search**](exact_code_search.md).

For code search, GitLab uses these types in this order:

- **Exact code search**: where you can use exact match and regular expression modes.
- **Advanced search**: when exact code search is not available.
- **Basic search**: when exact code search and advanced search are not available
  or when you search against a non-default branch.
  This type does not support group or global search.

## Available scopes

Scopes describe the type of data you're searching.
The following scopes are available for basic search:

| Scope          | Global <sup>1</sup>                         | Group                                       | Project |
|----------------|:-------------------------------------------:|:-------------------------------------------:|:-------:|
| Code           | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes |
| Comments       | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes |
| Commits        | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes |
| Epics          | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No |
| Issues         | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Merge requests | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Milestones     | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Projects       | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="dash-circle" >}} No |
| Users          | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes | {{< icon name="check-circle-filled" >}} Yes |
| Wikis          | {{< icon name="dash-circle" >}} No          | {{< icon name="dash-circle" >}} No          | {{< icon name="check-circle-filled" >}} Yes |

**Footnotes**:

1. An administrator can [disable global search scopes](#disable-global-search-scopes).

## Specify a search type

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161999) in GitLab 17.4.

{{< /history >}}

To specify a search type, set the `search_type` URL parameter as follows:

- `search_type=zoekt` for [exact code search](exact_code_search.md)
- `search_type=advanced` for [advanced search](advanced_search.md)
- `search_type=basic` for basic search

`search_type` replaces the deprecated `basic_search` parameter.
For more information, see [issue 477333](https://gitlab.com/gitlab-org/gitlab/-/issues/477333).

## Restrict search access

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Restricting global search to authenticated users [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41041) in GitLab 13.4 [with a flag](../../administration/feature_flags/_index.md) named `block_anonymous_global_searches`. Disabled by default.
- Allowing search for unauthenticated users [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138975) in GitLab 16.7 [with a flag](../../administration/feature_flags/_index.md) named `allow_anonymous_searches`. Enabled by default.
- Restricting global search to authenticated users [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186727) in GitLab 17.11. Feature flag `block_anonymous_global_searches` removed.
- Allowing search for unauthenticated users [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190090) in GitLab 18.0. Feature flag `allow_anonymous_searches` removed.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

By default, requests to `/search` and global search are available for unauthenticated users.

To restrict `/search` to authenticated users only, do one of the following:

- [Restrict visibility levels](../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)
  for the project or group.
- Restrict access in the **Admin** area:

  1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
  1. Select **Settings** > **Search**.
  1. Expand **Advanced search**.
  1. Clear the **Allow unauthenticated users to use search** checkbox.
  1. Select **Save changes**.

To restrict global search to authenticated users only:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Visibility and access controls**
1. Select the **Restrict global search to authenticated users only** checkbox.
1. Select **Save changes**.

## Disable global search scopes

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179688) in GitLab 17.9.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

To improve the performance of your instance's global search,
you can disable one or more search scopes.
All global search scopes are enabled by default on GitLab Self-Managed instances.

To disable one or more global search scopes:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **Search**.
1. Expand **Visibility and access controls**.
1. Clear the checkboxes for the scopes you want to disable.
1. Select **Save changes**.

## Global search validation

{{< history >}}

- Support for partial matches in issue search [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71913) in GitLab 14.9 [with a flag](../../administration/feature_flags/_index.md) named `issues_full_text_search`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124703) in GitLab 16.2. Feature flag `issues_full_text_search` removed.

{{< /history >}}

Global search ignores and logs as abusive any search that includes:

- Fewer than two characters
- A term longer than 100 characters (URL search terms must not exceed 200 characters)
- A stop word only (for example, `the`, `and`, or `if`)
- An unknown `scope`
- `group_id` or `project_id` that is not completely numeric
- `repository_ref` or `project_ref` with special characters not allowed by [Git refname](https://git-scm.com/docs/git-check-ref-format)

Global search only flags with an error any search that includes more than:

- 4096 characters
- 64 terms

Partial matches are not supported in issue search.
For example, when you search issues for `play`, the query does not return issues that contain `display`.
However, the query matches all possible variations of the string (for example, `plays`).

## Autocomplete suggestions

{{< history >}}

- Showing only users from authorized projects and groups [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442091) in GitLab 17.10 [with flags](../../administration/feature_flags/_index.md) named `users_search_scoped_to_authorized_namespaces_advanced_search`, `users_search_scoped_to_authorized_namespaces_basic_search`, and `users_search_scoped_to_authorized_namespaces_basic_search_by_ids`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/185577) in GitLab 17.11. Feature flags `users_search_scoped_to_authorized_namespaces_advanced_search`, `users_search_scoped_to_authorized_namespaces_basic_search`, and `users_search_scoped_to_authorized_namespaces_basic_search_by_ids` removed.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by feature flags.
For more information, see the history.

{{< /alert >}}

As you type in the search box, autocomplete suggestions are displayed for:

- [Projects](#search-for-a-project-by-full-path) and groups
- Users from authorized projects and groups
- Help pages
- Project features (for example, milestones)
- Settings (for example, user settings)
- Recently viewed merge requests
- Recently viewed issues and epics
- [GitLab Flavored Markdown references](../markdown.md#gitlab-specific-references) for issues in a project

## Search in all GitLab

To search in all GitLab:

1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Type your search query. You must type at least two characters.
1. Press <kbd>Enter</kbd> to search, or select from the list.

The results are displayed. To filter the results, on the left sidebar, select a filter.

## Search in a project

To search in a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Search or go to** again and type the string you want to search for.
1. Press <kbd>Enter</kbd> to search, or select from the list.

The results are displayed. To filter the results, on the left sidebar, select a filter.

## Search for a project by full path

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108906) in GitLab 15.9 [with a flag](../../administration/feature_flags/_index.md) named `full_path_project_search`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114932) in GitLab 15.11. Feature flag `full_path_project_search` removed.

{{< /history >}}

You can search for a project by entering its full path (including the namespace it belongs to) in the search box.
As you type the project path, [autocomplete suggestions](#autocomplete-suggestions) are displayed.

For example:

- `gitlab-org/gitlab` searches for the `gitlab` project in the `gitlab-org` namespace.
- `gitlab-org/` displays autocomplete suggestions for projects that belong to the `gitlab-org` namespace.

## Include archived projects in search results

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121981) in GitLab 16.1 [with a flag](../../administration/feature_flags/_index.md) named `search_projects_hide_archived` for project search. Disabled by default.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/10957) in GitLab 16.6 for all search scopes.

{{< /history >}}

By default, archived projects are excluded from search results.
To include archived projects in search results:

1. On the search page, on the left sidebar, select the **Include archived** checkbox.
1. On the left sidebar, select **Apply**.

## Search for code

To search for code in a project:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Search or go to** again and type the code you want to search for.
1. Press <kbd>Enter</kbd> to search, or select from the list.

Code search shows only the first result in the file.
To search for code in all GitLab, ask your administrator to enable [advanced search](advanced_search.md).

### View Git blame from code search

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327052) in GitLab 14.7.

{{< /history >}}

After you find search results, you can view who made the last change to the line
where the results were found.

1. From the code search result, hover over the line number.
1. On the left, select **View blame**.

### Filter code search results by language

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342651) in GitLab 15.10.

{{< /history >}}

To filter code search results by one or more languages:

1. On the code search page, on the left sidebar, select one or more languages.
1. On the left sidebar, select **Apply**.

## Search for a commit SHA

To search for a commit SHA:

1. On the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Search or go to** again and type the commit SHA you want to search for.
1. Press <kbd>Enter</kbd> to search, or select from the list.

If a single result is returned, GitLab redirects to the commit result
and gives you the option to return to the search results page.

## Syntax

Basic search uses exact substring matching with the following options:

| Syntax       | Description                                     | Example |
|--------------|-------------------------------------------------|---------|
| `filename:`  | Filename                                        | `filename:*spec.rb` |
| `path:`      | Repository location (full or partial matches)   | `path:spec/workers/` |
| `extension:` | File extension without `.` (exact matches only) | `extension:js` |

### Examples

<!-- markdownlint-disable MD044 -->

| Query                                 | Description |
|---------------------------------------|-------------|
| `rails -filename:gemfile.lock`        | Returns `rails` in all files except the `gemfile.lock` file. |
| `helper -extension:yml -extension:js` | Returns `helper` in all files except files with a `.yml` or `.js` extension. |
| `helper path:lib/git`                 | Returns `helper` in all files with a `lib/git*` path (for example, `spec/lib/gitlab`). |

<!-- markdownlint-enable MD044 -->
