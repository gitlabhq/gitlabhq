---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "How to revert commits or merge requests in a GitLab project."
---

# Revert changes

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can revert individual commits or an entire merge request in GitLab.

When you revert a commit in Git, you create a new commit that reverses all actions
taken in the original commit. The new commit:

- Removes the lines added in the original commit.
- Restores the lines removed in the original commit.
- Restores the lines modified in the original commit to their previous state.

Your **revert commit** is still subject to your project's access controls and processes.

## Revert a merge request

After a merge request merges, you can revert all changes in the merge request.

Prerequisites:

- You must have a role in the project that allows you to edit merge requests, and add
  code to the repository.
- Your project must use the [merge method](methods/index.md#fast-forward-merge) **Merge Commit**,
  set in your project's **Settings > Merge requests**.

  [In GitLab 16.9 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/22236), you can revert
  fast-forwarded commits from the GitLab UI if either:

  - The commits are squashed, or
  - The merge request contains a single commit.

To revert merge request `Example`:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. From the secondary menu, select **Merged**, and select your merge request (here, `Example`).
1. Scroll to the merge request reports area, and find the report showing the
   **Merged by** information.
1. Select **Revert**.
1. In **Revert in branch**, select the branch to revert your changes into.
1. To revert immediately, without a merge request:
   1. Clear **Start a new merge request**.
   1. Select **Revert**, and the revert of `Example` is complete.
1. To review the revert in a new merge request instead of reverting immediately,
   select **Start a new merge request**, then:
   1. Fill in the fields for your revert merge request, then select **Create merge request**.
   1. When the merge request merges, the revert of `Example` is complete.

After you revert the `Example` merge request, the option to **Revert** is no longer shown on it.

## Revert a commit

You can revert any commit in a repository into either:

- The current branch.
- A new merge request.

Prerequisites:

- Your role in the project must allow you to edit merge requests, and add
  code to the repository.
- The commit must not have already been reverted, as the **Revert** option is not
  shown in this case.

To do this:

1. On the left sidebar, select **Search or go to** and find your project.
1. If you know the merge request that contains the commit:
   1. Select **Code > Merge requests**, then select your merge request.
   1. Select **Commits**, then select the title of the commit you want to revert.
      This displays the commit in the context of your merge request.
   1. Below the secondary menu, GitLab shows the message **Viewing commit `00001111`**,
      where `00001111` is the hash of the commit. Select the commit hash to show
      the commit's page.
1. If you don't know the merge request the commit originated from:
   1. Select **Code > Commits**.
   1. Select the title of the commit to display full information about the commit.
1. In the upper-right corner, select **Options**, then select **Revert**.
1. In **Revert in branch**, select the branch to revert your changes into.
1. To revert immediately, without a merge request:
   1. Clear **Start a new merge request**.
   1. Select **Revert**.
1. To review the revert in a new merge request instead of reverting immediately,
   select **Start a new merge request**, then:
   1. Fill in the fields for your revert merge request, then select **Create merge request**.
   1. When the merge request merges, the commit revert is complete.

### Revert a merge commit to a different parent commit

When you revert a merge commit, the branch you merged to (often `main`) is always the
first parent. To revert a merge commit to a different parent,
you must revert the commit from the command line:

1. Identify the SHA of the parent commit you want to revert to.
1. Identify the parent number of the commit you want to revert to. (Defaults to `1`, for the first parent.)
1. Run this command, replacing `2` with the parent number, and `7a39eb0` with the commit SHA:

   ```shell
   git revert -m 2 7a39eb0
   ```

## Related topics

- [Official `git revert` documentation](https://git-scm.com/docs/git-revert)
- [Undo changes by using Git](../../../topics/git/undo.md)
- [Revert a commit](../../../api/commits.md#revert-a-commit) with the Commits API
- How changelogs [handle reverted commits](../changelogs.md#reverted-commit-handling)
