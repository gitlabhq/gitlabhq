---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Searching in GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

GitLab has three types of search: **basic search**, [**advanced search**](advanced_search.md),
and [**exact code search**](exact_code_search.md).

For code search, GitLab uses these types in this order:

- **Exact code search:** where you can use exact match and regular expression modes.
- **Advanced search:** when exact code search is not available.
- **Basic search:** when exact code search and advanced search are not available
  or when you search against a non-default branch.
  This type does not support group or global search.

## Specify a search type

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161999) in GitLab 17.4.

To specify a search type, set the `search_type` URL parameter as follows:

- `search_type=zoekt` for [exact code search](exact_code_search.md)
- `search_type=advanced` for [advanced search](advanced_search.md)
- `search_type=basic` for basic search

`search_type` replaces the deprecated `basic_search` parameter.
For more information, see [issue 477333](https://gitlab.com/gitlab-org/gitlab/-/issues/477333).

## Restrict search access

DETAILS:
**Offering:** GitLab Self-Managed

Prerequisites:

- You must have administrator access to the instance.

By default, requests to `/search` and global search are available for unauthenticated users.

To restrict `/search` to authenticated users only, do one of the following:

- [Restrict public visibility](../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)
  ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171368) in GitLab 17.6).
- Disable the `ops` feature flag `allow_anonymous_searches`
  ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138975) in GitLab 16.7).

To restrict global search to authenticated users only,
enable the `ops` feature flag `block_anonymous_global_searches`.

## Disable global search scopes

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179688) in GitLab 17.9.

Prerequisites:

- You must have administrator access to the instance.

To improve the performance of your instance's global search,
you can disable one or more search scopes.
All global search scopes are enabled by default on GitLab Self-Managed instances.

To disable one or more global search scopes:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Global search**.
1. Clear the checkboxes for the scopes you want to disable.
1. Select **Save changes**.

## Global search validation

> - Support for partial matches in issue search [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71913) in GitLab 14.9 [with a flag](../../administration/feature_flags.md) named `issues_full_text_search`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124703) in GitLab 16.2. Feature flag `issues_full_text_search` removed.

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

As you type in the search box, autocomplete suggestions are displayed for:

- [Projects](#search-for-a-project-by-full-path) and groups
- Users
- Help pages
- Project features (for example, milestones)
- Settings (for example, user settings)
- Recently viewed merge requests
- Recently viewed issues and epics
- [GitLab Flavored Markdown references](../markdown.md#gitlab-specific-references) for issues in a project

## Search in all GitLab

To search in all GitLab:

1. On the left sidebar, at the top, select **Search or go to**.
1. Type your search query. You must type at least two characters.
1. Press <kbd>Enter</kbd> to search, or select from the list.

The results are displayed. To filter the results, on the left sidebar, select a filter.

## Search in a project

To search in a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Search or go to** again and type the string you want to search for.
1. Press <kbd>Enter</kbd> to search, or select from the list.

The results are displayed. To filter the results, on the left sidebar, select a filter.

## Search for a project by full path

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108906) in GitLab 15.9 [with a flag](../../administration/feature_flags.md) named `full_path_project_search`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114932) in GitLab 15.11. Feature flag `full_path_project_search` removed.

You can search for a project by entering its full path (including the namespace it belongs to) in the search box.
As you type the project path, [autocomplete suggestions](#autocomplete-suggestions) are displayed.

For example:

- `gitlab-org/gitlab` searches for the `gitlab` project in the `gitlab-org` namespace.
- `gitlab-org/` displays autocomplete suggestions for projects that belong to the `gitlab-org` namespace.

## Include archived projects in search results

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121981) in GitLab 16.1 [with a flag](../../administration/feature_flags.md) named `search_projects_hide_archived` for project search. Disabled by default.
> - [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/10957) in GitLab 16.6 for all search scopes.

By default, archived projects are excluded from search results.
To include archived projects in search results:

1. On the search page, on the left sidebar, select the **Include archived** checkbox.
1. On the left sidebar, select **Apply**.

## Search for code

To search for code in a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Search or go to** again and type the code you want to search for.
1. Press <kbd>Enter</kbd> to search, or select from the list.

Code search shows only the first result in the file.
To search for code in all GitLab, ask your administrator to enable [advanced search](advanced_search.md).

### View Git blame from code search

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327052) in GitLab 14.7.

After you find search results, you can view who made the last change to the line
where the results were found.

1. From the code search result, hover over the line number.
1. On the left, select **View blame**.

### Filter code search results by language

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342651) in GitLab 15.10.

To filter code search results by one or more languages:

1. On the code search page, on the left sidebar, select one or more languages.
1. On the left sidebar, select **Apply**.

## Search for a commit SHA

To search for a commit SHA:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Search or go to** again and type the commit SHA you want to search for.
1. Press <kbd>Enter</kbd> to search, or select from the list.

If a single result is returned, GitLab redirects to the commit result
and gives you the option to return to the search results page.
