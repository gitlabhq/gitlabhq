---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Fork a Git repository when you want to contribute changes back to an upstream repository you don't have permission to contribute to directly."
title: Update a fork
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

A fork is a personal copy of the repository and all its branches, which you create
in a namespace of your choice. You can use forks to propose changes to another project
that you don't have access to. For more information,
see [Forking workflows](../../user/project/repository/forking_workflow.md).

This page describes how to update a fork using Git commands from your command line and
how to [collaborate across forks](#collaborate-across-forks).

You can also update a fork with the [GitLab UI](../../user/project/repository/forking_workflow.md#from-the-ui).

Prerequisites:

- You must [download and install the Git client](how_to_install_git/_index.md) on your local machine.
- You must [create a fork](../../user/project/repository/forking_workflow.md#create-a-fork) of the
  repository you want to update.

To update your fork from the command line:

1. Check if an `upstream` remote repository is configured for your fork:

   1. Clone your fork locally, if you haven't already. For more information, see [Clone a repository](clone.md).
   1. View the configured remotes for your fork:

      ```shell
      git remote -v
      ```

   1. If your fork doesn't have a remote pointing to the original repository, use one of these examples
      to configure a remote called upstream:

       ```shell
       # Set any repository as your upstream after editing <upstream_url>
       git remote add upstream <upstream_url>

       # Set the main GitLab repository as your upstream
       git remote add upstream https://gitlab.com/gitlab-org/gitlab.git
       ```

1. Update your fork:

   1. In your local copy, check out the [default branch](../../user/project/repository/branches/default.md).
      Replace `main` with the name of your default branch:

      ```shell
      git checkout main
      ```

      NOTE:
      If Git identifies unstaged changes, [commit or stash](commit.md) them before continuing.

   1. Fetch the changes from the upstream repository:

      ```shell
      git fetch upstream
      ```

   1. Pull the changes into your fork. Replace `main` with the name of the branch you're updating:

      ```shell
      git pull upstream main
      ```

   1. Push the changes to your fork repository on the server:

      ```shell
      git push origin main
      ```

## Collaborate across forks

GitLab enables collaboration between the upstream project maintainers and the fork owners.
For more information, see:

- [Collaborate on merge requests across forks](../../user/project/merge_requests/allow_collaboration.md)
  - [Allow commits from upstream members](../../user/project/merge_requests/allow_collaboration.md#allow-commits-from-upstream-members)
  - [Prevent commits from upstream members](../../user/project/merge_requests/allow_collaboration.md#prevent-commits-from-upstream-members)

### Push to a fork as an upstream member

You can push directly to the branch of the forked repository if:

- The author of the merge request enabled contributions from upstream members.
- You have at least the Developer role for the upstream project.

In the following example:

- The forked repository URL is `git@gitlab.com:contributor/forked-project.git`.
- The branch of the merge request is `fork-branch`.

To change or add a commit to the contributor's merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to **Code** > **Merge requests** and find the merge request.
1. In the upper-right corner, select **Code**, then select **Check out branch**.
1. On the dialog, select **Copy** (**{copy-to-clipboard}**).
1. In your terminal, go to the cloned version of the repository, and paste the commands. For example:

   ```shell
   git fetch "git@gitlab.com:contributor/forked-project.git" 'fork-branch'
   git checkout -b 'contributor/fork-branch' FETCH_HEAD
   ```

   These commands fetch the branch from the forked project and create a local branch for you to work on.

1. Make your changes to the local copy of the branch, and then commit them.
1. Push your local changes to the forked project. The following command pushes the
   local branch `contributor/fork-branch` to the `fork-branch` branch of
   the `git@gitlab.com:contributor/forked-project.git` repository:

   ```shell
   git push git@gitlab.com:contributor/forked-project.git contributor/fork-branch:fork-branch
   ```

   If you've amended or squashed any commits, you must use `git push --force`. Proceed with caution as this command rewrites the commit history.

   ```shell
   git push --force git@gitlab.com:contributor/forked-project.git contributor/fork-branch:fork-branch
   ```

   The colon (`:`) specifies the source branch and the destination branch. The scheme is:

   ```shell
   git push <forked_repository_git_url> <local_branch>:<fork_branch>
   ```

## Related topics

- [Forking workflows](../../user/project/repository/forking_workflow.md)
  - [Create a fork](../../user/project/repository/forking_workflow.md#create-a-fork)
  - [Unlink a fork](../../user/project/repository/forking_workflow.md#unlink-a-fork)
- [Collaborate on merge requests across forks](../../user/project/merge_requests/allow_collaboration.md)
- [Merge requests](../../user/project/merge_requests/_index.md)
