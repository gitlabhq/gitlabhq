---
stage: Data Stores
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Searching in GitLab **(FREE)**

GitLab has two types of searches available: _basic_ and _advanced_.

Both types of search are the same, except when you are searching through code.

- When you use basic search to search code, your search includes one project at a time.
- When you use [advanced search](advanced_search.md) to search code, your search includes all projects at once.

## Basic search

Use basic search to find:

- Projects
- Issues
- Merge requests
- Milestones
- Users
- Epics (when searching in a group only)
- Code
- Comments
- Commits
- Wiki

## Perform a search

To start a search, type your search query in the search bar on the top-right of the screen.

![basic search](img/basic_search_v15_1.png)

After the results are displayed, you can modify the search, select a different type of data to
search, or choose a specific group or project.

![basic_search_results](img/basic_search_results_v15_1.png)

## Search in code

To search through code or other documents in a project:

1. On the top bar, select **Menu > Projects** and find your project.
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

1. On the top bar, select **Menu > Projects** and find your project.
1. On the top bar, in the search field, type the SHA.

If a single result is returned, GitLab redirects to the commit result
and gives you the option to return to the search results page.

![project SHA search redirect](img/project_search_sha_redirect.png)

## Filter issue and merge request lists

> - Filtering by epics was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/195704) in GitLab 12.9.
> - Filtering by child epics was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9029) in GitLab 13.0.
> - Filtering by iterations was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118742) in GitLab 13.6.
> - Filtering by iterations was moved from GitLab Ultimate to GitLab Premium in 13.9.
> - Filtering by type was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/322755) in GitLab 13.10 [with a flag](../../administration/feature_flags.md) named `vue_issues_list`. Disabled by default.
> - Filtering by type was [enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/322755) in GitLab 14.10.
> - Filtering by type is generally available in GitLab 15.1. [Feature flag `vue_issues_list`](https://gitlab.com/gitlab-org/gitlab/-/issues/359966) removed.
> - Filtering by attention request was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343528) in GitLab 14.10 [with a flag](../../administration/feature_flags.md) named `mr_attention_requests`. Disabled by default.

Follow these steps to filter the **Issues** and **Merge requests** list pages in projects and
groups:

1. Select **Search or filter results...**.
1. In the dropdown list that appears, select the attribute you wish to filter by:
   - Assignee
   - [Attention requests](../project/merge_requests/index.md#request-attention-to-a-merge-request)
   - Author
   - Confidential
   - [Epic and child Epic](../group/epics/index.md) (available only for the group the Epic was created, not for [higher group levels](https://gitlab.com/gitlab-org/gitlab/-/issues/233729)).
   - [Iteration](../group/iterations/index.md)
   - [Label](../project/labels.md)
   - [Milestone](../project/milestones/index.md)
   - My-reaction
   - Release
   - Type
   - Weight
   - Search for this text
1. Select or type the operator to use for filtering the attribute. The following operators are
   available:
   - `=`: Is
   - `!=`: Is not ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18059) in GitLab 12.7)
1. Enter the text to [filter the attribute by](#filters-autocomplete).
   You can filter some attributes by **None** or **Any**.
1. Repeat this process to filter by multiple attributes. Multiple attributes are joined by a logical
   `AND`.

GitLab displays the results on-screen, but you can also
[retrieve them as an RSS feed](#retrieve-search-results-as-feed).

## Searching for specific terms

You can filter issues and merge requests by specific terms included in titles or descriptions.

- Syntax
  - Searches look for all the words in a query, in any order. For example: searching
    issues for `display bug` returns all issues matching both those words, in any order.
  - To find the exact term, use double quotes: `"display bug"`
- Limitation
  - For performance reasons, terms shorter than 3 chars are ignored. For example: searching
    issues for `included in titles` is same as `included titles`
  - Search is limited to 4096 characters and 64 terms per query.

## Retrieve search results as feed

> Feeds for merge requests were [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66336) in GitLab 14.3.

GitLab provides RSS feeds of search results for your project. To subscribe to the
RSS feed of search results:

1. Go to your project's page.
1. On the left sidebar, select **Issues** or **Merge requests**.
1. Build your search query as described in [Filter issue and merge request lists](#filter-issue-and-merge-request-lists).
1. Select the feed symbol **{rss}** to display the results as an RSS feed in Atom format.

The URL of the result contains both a feed token, and your search query.
You can add this URL to your feed reader.

## Filters autocomplete

GitLab provides many filters across many pages (issues, merge requests, epics,
and pipelines among others) which you can use to narrow down your search. When
using the filter functionality, you can start typing characters to bring up
relevant users or other attributes.

For performance optimization, there is a requirement of a minimum of three
characters to begin your search. To search for issues with the assignee `Simone Presley`,
you must type at least `Sim` before autocomplete displays results.

## Search history

Search history is available for issues and merge requests, and is stored locally
in your browser. To run a search from history:

1. In the top menu, select **Issues** or **Merge requests**.
1. To the left of the search bar, select **Recent searches**, and select a search from the list.

## Removing search filters

Individual filters can be removed by clicking on the filter's (x) button or backspacing. The entire search filter can be cleared by clicking on the search box's (x) button or via <kbd>⌘</kbd> (Mac) + <kbd>⌫</kbd>.

To delete filter tokens one at a time, the <kbd>⌥</kbd> (Mac) / <kbd>Control</kbd> + <kbd>⌫</kbd> keyboard combination can be used.

## Filtering with multiple filters of the same type

Some filters can be added multiple times. These include but are not limited to assignees and labels. When you filter with these multiple filters of the same type, the `AND` logic is applied. For example, if you were filtering `assignee:@sam assignee:@sarah`, your results include only entries whereby the assignees are assigned to both Sam and Sarah are returned.

![multiple assignees filtering](img/multiple_assignees.png)

## Groups

You can search through your groups from
the left menu, by clicking the menu bar, then **Groups**.

On the field **Filter by name**, type the group name you want to find, and GitLab
filters them for you as you type.

You can also **Explore** all public and internal groups available in GitLab.com,
and sort them by **Name**, **Last created**, **Oldest created**, or **Updated date**.

## Issue boards

From an [issue board](../../user/project/issue_board.md), you can filter issues by **Author**, **Assignee**, **Milestone**, and **Labels**.
You can also filter them by name (issue title), from the field **Filter by name**, which is loaded as you type.

To search for issues to add to lists present in your issue board, select
the button **Add issues** on the top-right of your screen, opening a modal window from which
you can, besides filtering them by **Name**, **Author**, **Assignee**, **Milestone**,
and **Labels**, select multiple issues to add to a list of your choice:

![search and select issues to add to board](img/search_issues_board.png)

## Autocomplete suggestions

In the search bar, you can view autocomplete suggestions for:

- Projects and groups
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
