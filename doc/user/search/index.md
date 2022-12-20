---
stage: Data Stores
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Searching in GitLab **(FREE)**

GitLab has two types of searches available: _basic_ and _advanced_.

Both types of search are the same, except when you are searching through code.

- When you use basic search to search code, your search includes one project at a time.
- When you use [advanced search](advanced_search.md) to search code, your search includes all projects at once.

## Global search scopes **(FREE SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68640) in GitLab 14.3.

To improve the performance of your instance's global search, a GitLab administrator
can limit the search scope by disabling the following [`ops` feature flags](../../development/feature_flags/index.md#ops-type).

| Scope | Feature flag | Description |
|--|--|--|
| Code | `global_search_code_tab` | When enabled, global search includes code. |
| Commits | `global_search_commits_tab` | When enabled, global search includes commits. |
| Issues | `global_search_issues_tab` | When enabled, global search includes issues. |
| Merge requests | `global_search_merge_requests_tab` | When enabled, global search includes merge requests. |
| Users | `global_search_users_tab` | When enabled, global search includes users. |
| Wiki | `global_search_wiki_tab` | When enabled, global search includes project wikis (not [group wikis](../project/wiki/group.md)). |

All global search scopes are enabled by default on GitLab.com
and self-managed instances.

## Global search validation

Global search ignores and logs as abusive any search with:

- Fewer than 2 characters
- A term longer than 100 characters (URL search terms must not exceed 200 characters)
- A stop word only (for example, `the`, `and`, or `if`)
- An unknown `scope`
- `group_id` or `project_id` that is not completely numeric
- `repository_ref` or `project_ref` with special characters not allowed by [Git refname](https://git-scm.com/docs/git-check-ref-format)

Global search only flags with an error any search that includes more than:

- 4096 characters
- 64 terms

## Perform a search

To start a search, type your search query in the search bar on the top-right of the screen.
You must type at least two characters.

![search navbar](img/search_navbar_v15_7.png)

After the results are displayed, you can modify the search, select a different type of data to
search, or choose a specific group or project.

![search scope](img/search_scope_v15_7.png)

## Search in code

To search through code or other documents in a project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the top bar, in the search field, type the string you want to search for.
1. Press **Enter**.

Code search shows only the first result in the file.

To search across all of GitLab, ask your administrator to enable [advanced search](advanced_search.md).

### View Git blame from code search

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327052) in GitLab 14.7.

After you find search results, you can view who made the last change to the line
where the results were found.

1. From the code search result, hover over the line number.
1. On the left, select **View blame**.

   ![code search results](img/code_search_git_blame_v15_1.png)

## Search for a SHA

You can search for a commit SHA.

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the top bar, in the search field, type the SHA.

If a single result is returned, GitLab redirects to the commit result
and gives you the option to return to the search results page.

![project SHA search redirect](img/project_search_sha_redirect.png)

## Searching for specific terms

> - [Removed support for partial matches in issue searches](https://gitlab.com/gitlab-org/gitlab/-/issues/273784) in GitLab 14.9 [with a flag](../../administration/feature_flags.md) named `issues_full_text_search`. Disabled by default.
> - Feature flag [`issues_full_text_search` enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/273784) in GitLab 14.10.
> - Feature flag [`issues_full_text_search` enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/273784) in GitLab 15.2.

You can filter issues and merge requests by specific terms included in titles or descriptions.

- Syntax
  - Searches look for all the words in a query, in any order. For example: searching
    issues for `display bug` returns all issues matching both those words, in any order.
  - To find the exact term, use double quotes: `"display bug"`
- Limitation
  - For performance reasons, terms shorter than 3 chars are ignored. For example: searching
    issues for `included in titles` is same as `included titles`
  - Search is limited to 4096 characters and 64 terms per query.
  - When searching issues, partial matches are not allowed. For example: searching for `play` will
    not return issues that have the word `display`. But variations of words will still match, so searching
    for `displays` also returns issues that have the word `display`.

## Retrieve search results as feed

> Feeds for merge requests were [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66336) in GitLab 14.3.

GitLab provides RSS feeds of search results for your project. To subscribe to the
RSS feed of search results:

1. Go to your project's page.
1. On the left sidebar, select **Issues** or **Merge requests**.
1. Perform a search.
1. Select the feed symbol **{rss}** to display the results as an RSS feed in Atom format.

The URL of the result contains both a feed token, and your search query.
You can add this URL to your feed reader.

## Search history

Search history is available for issues and merge requests, and is stored locally
in your browser. To run a search from history:

1. In the top menu, select **Issues** or **Merge requests**.
1. To the left of the search bar, select **Recent searches**, and select a search from the list.

## Removing search filters

Individual filters can be removed by selecting the filter's (x) button or backspacing. The entire search filter can be cleared by selecting the search box's (x) button or via <kbd>⌘</kbd> (Mac) + <kbd>⌫</kbd>.

To delete filter tokens one at a time, the <kbd>⌥</kbd> (Mac) / <kbd>Control</kbd> + <kbd>⌫</kbd> keyboard combination can be used.

## Autocomplete suggestions

In the search bar, you can view autocomplete suggestions for:

- Projects and groups
- Users
- Various help pages (try and type **API help**)
- Project feature pages (try and type **milestones**)
- Various settings pages (try and type **user settings**)
- Recently viewed issues (try and type some word from the title of a recently viewed issue)
- Recently viewed merge requests (try and type some word from the title of a recently viewed merge request)
- Recently viewed epics (try and type some word from the title of a recently viewed epic)
- [GitLab Flavored Markdown](../markdown.md#gitlab-specific-references) (GLFM) for issues in a project (try and type a GLFM reference for an issue)

## Search settings

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292941) in GitLab 13.8 [with a flag](../../administration/feature_flags.md) named `search_settings_in_page`. Disabled by default.
> - [Added](https://gitlab.com/groups/gitlab-org/-/epics/4842) to Group, Administrator, and User settings in GitLab 13.9.
> - [Feature flag `search_settings_in_page` removed](https://gitlab.com/gitlab-org/gitlab/-/issues/294025) in GitLab 13.11.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/294025) in GitLab 13.11.

You can search inside a Project, Group, Administrator, or User's settings by entering
a search term in the search box located at the top of the page. The search results
appear highlighted in the sections that match the search term.

![Search project settings](img/project_search_general_settings_v13_8.png)
