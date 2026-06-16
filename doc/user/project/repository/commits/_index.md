---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: View information about a repository's commit history.
title: Commits
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Commit list [redesigned](https://gitlab.com/groups/gitlab-org/-/epics/17482) with grouped commits, token-based search, and new actions menu in GitLab 19.1.

{{< /history >}}

The **Commits** list displays the commit history for your repository. Use it to browse
code changes, view commit details, and verify commit signatures. Commits are grouped by
day, and you can filter the list by author, commit message, date, or Git revision.

The list shows:

- Commit hash: Unique identifier (SHA) for each commit.
- Commit message: Title and description of the commit.
- Author: Name and avatar of the user who made the commit.
- Timestamp: When the commit was created.
- Pipeline status: CI/CD pipeline results, if configured.
- Signature verification: GPG, SSH, or X.509 signature status.
- Tags: Any tags pointing to this commit.

![An example of a repository's commits list](img/repository_commits_list_v19_1.png)

## View commits

To view your repository's commit history:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.

To view a commit's full description, select the expand ({{< icon name="chevron-down" >}}) icon
on the right side of the commit. To collapse the description, select the expand ({{< icon name="chevron-down" >}}) icon again.

## View commit details

Examine the specific changes made in any commit, including file modifications, additions, and deletions.

To view a commit's details:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. Select the commit to open the commit's details page.

The commit's details page shows:

- Commit information: Commit hash, author, committer, parent commits, and timestamp.
- Commit message: Title and description of the commit.
- File changes: All modified files with diff view.
- Statistics: Number of lines changed, added, and removed.
- Pipeline details: Associated CI/CD pipeline status and details.
- References: Branches and tags containing this commit.
- Related merge requests: Links to merge requests associated with the commit.

## Browse repository files by Git revision

To view all repository files and folders at a specific Git revision, such as a commit SHA,
branch name, or tag:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. Choose one of the following options:
   - Filter by Git revision:
      1. At the top, select to open the **Select Git revision** dropdown list.
      1. Select or search for a Git revision.
   - Select a specific commit from the commits list.
1. In the upper right, select **Browse files**.

You are directed to the [repository](../_index.md) page at that specific revision.

## Filter and search commits

Use the search bar to filter the commit history by author, commit message, or date. You can
combine multiple filters at the same time.

### Filter by date

To filter commits by date:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. In the search bar, select **Committed after** or **Committed before** from the filter dropdown list.
1. Enter a date.

To view commits for a specific date range, use both filters together.

### Filter by author

To filter commits by one or more authors:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. In the search bar, select **Author** from the filter dropdown list.
1. Select or search for one or more authors.

The list updates to show only commits from the selected authors.

If author filtering doesn't work for names with special characters, use the URL parameter format.
For example, append `?author=Elliot%20Stevens` to the URL.

### Filter by Git revision

To filter commits by Git revision, such as branch, tag, or commit SHA:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. In the dropdown list at the top, select or search for a Git revision.
   For example, branch name, tag, or commit SHA.
1. Select the Git revision to view the list of filtered commits.

### Search by commit message

To search for commits by message content:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. In the search bar, select **Message** from the filter dropdown list.
1. Enter your search terms.

You can also search by commit SHA, full or partial, to find a specific commit directly.

### Share and bookmark filtered views

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/599000) in GitLab 19.1.

{{< /history >}}

When you filter the commits list or change the page size, the URL updates to reflect your current
view. You can:

- Copy the URL to share a filtered view.
- Bookmark the URL to save a filter combination.
- Use the browser's Back and Forward buttons to move between filter states.

The URL uses these parameters:

| Parameter          | Description |
|--------------------|-------------|
| `author`           | Username of the commit author. |
| `message`          | Text to match in commit messages. |
| `committed_after`  | Earliest commit date, in `YYYY-MM-DD` format. |
| `committed_before` | Latest commit date, in `YYYY-MM-DD` format. |
| `page_size`        | Number of commits per page. Default is `20`. |

## Navigate between pages of commits

The commit list uses cursor-based pagination. To move between pages:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. At the bottom of the list, select **Previous** or **Next** to navigate between pages.

## Access commit list actions

The commits page includes an actions menu with quick links for the current Git revision.

To access the actions menu:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. In the upper-right corner, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) to open the actions menu.

The actions menu includes:

- **Browse files**: View all repository files at the selected Git revision.
- **Subscribe to commits RSS feed**: Subscribe to an RSS feed of commits for the current revision.

## Cherry-pick a commit

Apply changes from a specific commit to another.

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the project.
- The target branch must exist.

To cherry-pick a commit:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. Select the commit you want to cherry-pick.
1. In the upper-right corner, select **Options** and then **Cherry-pick**.
1. In the dialog:
   - From the dropdown lists, select the target project and branch.
   - Optional. Select **Start a new merge request** to create a merge request with the changes.
   - Select **Cherry-pick**.

GitLab creates a new commit on the target branch with the cherry-picked changes.
If the branch is [protected](../branches/protected.md) or you don't have the correct permissions,
GitLab prompts you to [create a new merge request](../../merge_requests/_index.md#create-a-merge-request).

## Revert a commit

Create a new commit that undoes changes from a previous commit.

Prerequisites:

- You must have the Developer, Maintainer, or Owner role for the project.

To revert a commit:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. Select the commit you want to revert.
1. In the upper-right corner, select **Options** and then **Revert**.
1. In the dialog:
   - Select the target branch for the revert commit.
   - Optional. Select **Start a new merge request** to create a merge request.
   - Select **Revert**.

GitLab creates a new commit that reverses the changes from the selected commit.
If the branch is [protected](../branches/protected.md) or you don't have the correct permissions,
GitLab prompts you to [create a new merge request](../../merge_requests/_index.md#create-a-merge-request).

## Download commit contents

To download a commit's diff contents:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. Select the commit you want to download.
1. In the upper-right corner, select **Options**.
1. Under **Downloads**, select **Plain Diff**.

## Verify commit signatures

GitLab verifies GPG, SSH, and X.509 signatures to ensure commit authenticity.
Verified commits show a **Verified** badge.

For more information, see [signed commits](../signed_commits/_index.md).

### View signature details

To view signature information:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. Find a commit with a **Verified** or **Unverified** badge.
1. Select the badge to view signature details including:
   - Signature type (GPG, SSH, or X.509)
   - Key fingerprint
   - Verification status
   - Signer identity

## View pipeline status and details

The commit list includes a CI/CD pipeline status icon next to each commit. To view the pipeline details:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Commits**.
1. Select the pipeline status icon next to any commit.

## Related topics

- [Signed commits](../signed_commits/_index.md)
- [Compare revisions](../compare_revisions.md)
- [File management](../files/_index.md)
- [Git file history](../files/git_history.md)
- [Tags](../tags/_index.md)
