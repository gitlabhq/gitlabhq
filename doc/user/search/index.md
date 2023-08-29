---
stage: Data Stores
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Searching in GitLab **(FREE ALL)**

GitLab has two types of searches available: **basic** and **advanced**.

Both types of search are the same, except when you are searching through code.

- When you use basic search to search code, your search includes one project at a time.
- When you use [advanced search](advanced_search.md) to search code, your search includes all projects at once.

## Global search scopes **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68640) in GitLab 14.3.

To improve the performance of your instance's global search, an administrator can limit the search scope
by disabling one or more [`ops` feature flags](../../development/feature_flags/index.md#ops-type).

| Scope          | Feature flag                       | Description                                                                               |
|----------------|------------------------------------|-------------------------------------------------------------------------------------------|
| Code           | `global_search_code_tab`           | When enabled, global search includes code.                                                |
| Commits        | `global_search_commits_tab`        | When enabled, global search includes commits.                                             |
| Issues         | `global_search_issues_tab`         | When enabled, global search includes issues.                                              |
| Merge requests | `global_search_merge_requests_tab` | When enabled, global search includes merge requests.                                      |
| Users          | `global_search_users_tab`          | When enabled, global search includes users.                                               |
| Wiki           | `global_search_wiki_tab`           | When enabled, global search includes project and [group wikis](../project/wiki/group.md). |

All global search scopes are enabled by default on self-managed instances.

## Global search validation

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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121981) in GitLab 16.1 [with a flag](../../administration/feature_flags.md) named `search_projects_hide_archived`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/413821) in GitLab 16.3. Feature flag `search_projects_hide_archived` removed.

By default, archived projects are excluded from search results.
To include archived projects:

1. On the project search page, on the left sidebar, select the **Include archived** checkbox.
1. On the left sidebar, select **Apply**.

## Exclude issues in archived projects from search results

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124846) in GitLab 16.2 [with a flag](../../administration/feature_flags.md) named `search_issues_hide_archived_projects`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
an administrator can [enable the feature flag](../../administration/feature_flags.md) named `search_issues_hide_archived_projects`. On GitLab.com, this feature is not available.

By default, issues in archived projects are included in search results.
To exclude issues in archived projects, ensure the `search_issues_hide_archived_projects` flag is enabled.

To include issues in archived projects with `search_issues_hide_archived_projects` enabled,
you must add the parameter `include_archived=true` to the URL.

## Search for code

To search for code in a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Search or go to** again and type the code you want to search for.
1. Press <kbd>Enter</kbd> to search, or select from the list.

Code search shows only the first result in the file.
To search for code in all GitLab, ask your administrator to enable [advanced search](advanced_search.md).

### View Git blame from code search

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327052) in GitLab 14.7.

After you find search results, you can view who made the last change to the line
where the results were found.

1. From the code search result, hover over the line number.
1. On the left, select **View blame**.

### Filter code search results by language

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342651) in GitLab 15.10.

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

## Search for specific terms

> - [Support for partial matches in issue search](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71913) removed in GitLab 14.9 [with a flag](../../administration/feature_flags.md) named `issues_full_text_search`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124703) in GitLab 16.2. Feature flag `issues_full_text_search` removed.

You can filter issues and merge requests by specific terms included in titles or descriptions.

- Syntax
  - Searches look for all the words in a query, in any order. For example: searching
    issues for `display bug` returns all issues matching both those words, in any order.
  - To find the exact term, use double quotes: `"display bug"`.
- Limitation
  - For performance reasons, terms shorter than three characters are ignored. For example: searching
    issues for `included in titles` is same as `included titles`
  - Search is limited to 4096 characters and 64 terms per query.
  - When searching issues, partial matches are not allowed. For example: searching for `play` will
    not return issues that have the word `display`. But variations of words match, so searching
    for `displays` also returns issues that have the word `display`.

## Run a search from history

You can run a search from history for issues and merge requests. Search history is stored locally
in your browser. To run a search from history:

1. On the left sidebar, select **Search or go to** and find your project.
1. To view recent searches:

   - For issues, on the left sidebar, select **Plan > Issues**. Above the list, to the left of the search box, select (**{history}**).
   - For merge requests, on the left sidebar, select **Code > Merge requests**. Above the list, to the left of the search box, select **Recent searches**.

1. From the dropdown list, select a search.
