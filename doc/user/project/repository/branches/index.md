---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: concepts, howto
---

# Branches **(FREE)**

A branch is a version of a project's working tree. You create a branch for each
set of related changes you make. This keeps each set of changes separate from
each other, allowing changes to be made in parallel, without affecting each
other.

After pushing your changes to a new branch, you can:

- Create a [merge request](../../merge_requests/index.md)
- Perform inline code review
- [Discuss](../../../discussions/index.md) your implementation with your team
- Preview changes submitted to a new branch with [Review Apps](../../../../ci/review_apps/index.md).

You can also request [approval](../../merge_requests/approvals/index.md)
from your managers.

For more information on managing branches using the GitLab UI, see:

- [Default branches](default.md): When you create a new [project](../../index.md), GitLab creates a
  default branch for the repository. You can change this setting at the project,
  subgroup, group, or instance level.
- [Create a branch](../web_editor.md#create-a-new-branch)
- [Protected branches](../../protected_branches.md#protected-branches)
- [Delete merged branches](#delete-merged-branches)
- [Branch filter search box](#branch-filter-search-box)

You can also manage branches using the
[command line](../../../../gitlab-basics/start-using-git.md#create-a-branch).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>Watch the video [GitLab Flow](https://www.youtube.com/watch?v=InKNIvky2KE).

See also:

- [Branches API](../../../../api/branches.md), for information on operating on repository branches using the GitLab API.
- [GitLab Flow](../../../../topics/gitlab_flow.md) documentation.
- [Getting started with Git](../../../../topics/git/index.md) and GitLab.

## Compare

To compare branches in a repository:

1. Navigate to your project's repository.
1. Select **Repository > Compare** in the sidebar.
1. Select the target repository to compare with the [repository filter search box](#repository-filter-search-box).
1. Select branches to compare using the [branch filter search box](#branch-filter-search-box).
1. Click **Compare** to view the changes inline:

   ![compare branches](img/compare_branches_v13_12.png)

## Delete merged branches

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/6449) in GitLab 8.14.

![Delete merged branches](img/delete_merged_branches.png)

This feature allows merged branches to be deleted in bulk. Only branches that
have been merged and [are not protected](../../protected_branches.md) are deleted as part of
this operation.

It's particularly useful to clean up old branches that were not deleted
automatically when a merge request was merged.

## Repository filter search box

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/52967) in GitLab 13.10.

This feature allows you to search and select a repository quickly when [comparing branches](#compare).

![Repository filter search box](img/repository_filter_search_box_v13_12.png)

Search results appear in the following order:

- Repositories with names exactly matching the search terms.
- Other repositories with names that include search terms, sorted alphabetically.

## Branch filter search box

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22166) in GitLab 11.5.

![Branch filter search box](img/branch_filter_search_box_v13_12.png)

This feature allows you to search and select branches quickly. Search results appear in the following order:

- Branches with names that matched search terms exactly.
- Other branches with names that include search terms, sorted alphabetically.

Sometimes when you have hundreds of branches you may want a more flexible matching pattern. In such cases you can use the following:

- `^feature` matches only branch names that begin with 'feature'.
- `feature$` matches only branch names that end with 'feature'.

## Swap revisions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60491) in GitLab 13.12.

![Before swap revisions](img/swap_revisions_before_v13_12.png)

The Swap revisions feature allows you to swap the Source and Target revisions. When the Swap revisions button is clicked, the selected revisions for Source and Target will be swapped.

![After swap revisions](img/swap_revisions_after_v13_12.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
