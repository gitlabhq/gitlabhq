---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/forking_workflow.html'
---

# Project forking workflow **(FREE)**

Whenever possible, it's recommended to work in a common Git repository and use
[branching strategies](../../../topics/gitlab_flow.md) to manage your work. However,
if you do not have write access for the repository you want to contribute to, you
can create a fork.

A fork is a personal copy of the repository and all its branches, which you create
in a namespace of your choice. This way you can make changes in your own fork and
submit them through a merge request to the repository you don't have access to.

## Creating a fork

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15013) a new form in GitLab 13.11 [with a flag](../../../user/feature_flags.md) named `fork_project_form`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77181) in GitLab 14.8. Feature flag `fork_project_form` removed.

To fork an existing project in GitLab:

1. On the project's home page, in the top right, select **{fork}** **Fork**:
   ![Fork this project](img/forking_workflow_fork_button_v13_10.png)
1. Optional. Edit the **Project name**.
1. For **Project URL**, select the [namespace](../../namespace/index.md)
   your fork should belong to.
1. Add a **Project slug**. This value becomes part of the URL to your fork.
   It must be unique in the namespace.
1. Optional. Add a **Project description**.
1. Select the **Visibility level** for your fork. For more information about
   visibility levels, read [Project and group visibility](../../public_access.md).
1. Select **Fork project**.

GitLab creates your fork, and redirects you to the new fork's page.

## Update your fork

To copy the latest changes from the upstream repository into your fork, update it
from the command line. GitLab Premium and higher tiers can also
[configure forks as pull mirrors](mirror/pull.md#configure-pull-mirroring)
of the upstream repository.

### From the command line

To update your fork from the command line, first ensure that you have configured
an `upstream` remote repository for your fork:

1. Clone your fork locally, if you have not already done so. For more information, see
   [Clone a repository](../../../gitlab-basics/start-using-git.md#clone-a-repository).
1. View the remotes configured for your fork with `git remote -v`.
1. If your fork does not have an `upstream` remote pointing to the original repository,
   use one of these examples to configure an `upstream` remote:

   ```shell
   # Use this line to set any repository as your upstream after editing <upstream_url>
   git remote add upstream <upstream_url>

   # Use this line to set the main GitLab repository as your upstream
   git remote add upstream https://gitlab.com/gitlab-org/gitlab.git
   ```

   After ensuring your fork has an `upstream` remote configured, you are ready to update your fork.

1. In your local copy, ensure you have checked out the [default branch](branches/default.md),
   replacing `main` with the name of your default branch:

   ```shell
   git checkout main
   ```

   If Git identifies unstaged changes, commit or stash them before continuing.
1. Fetch the changes to the upstream repository with `git fetch upstream`.
1. Pull the changes into your fork, replacing `main` with the name of the branch
   you are updating:

   ```shell
   git pull upstream main
   ```

1. Push the changes to your fork repository on the server (GitLab.com or self-managed).

   ```shell
   git push origin main
   ```

### With repository mirroring **(PREMIUM)**

A fork can be configured as a mirror of the upstream if all these conditions are met:

1. Your subscription is **(PREMIUM)** or a higher tier.
1. You create all changes in branches (not `main`).
1. You do not work on [merge requests for confidential issues](../merge_requests/confidential.md),
   which requires changes to `main`.

[Repository mirroring](mirror/index.md) keeps your fork synced with the original repository.
This method updates your fork once per hour, with no manual `git pull` required.
For instructions, read [Configure pull mirroring](mirror/pull.md#configure-pull-mirroring).

WARNING:
With mirroring, before approving a merge request, you are asked to sync. You should automate it.

## Merging upstream

When you are ready to send your code back to the upstream project,
[create a merge request](../merge_requests/creating_merge_requests.md). For **Source branch**,
choose your forked project's branch. For **Target branch**, choose the original project's branch.

NOTE:
When creating a merge request, if the forked project's visibility is more restrictive than the parent project (for example the fork is private, the parent is public), the target branch defaults to the forked project's default branch. This prevents potentially exposing the private code of the forked project.

![Selecting branches](img/forking_workflow_branch_select.png)

Then you can add labels, a milestone, and assign the merge request to someone who can review
your changes. Then select **Submit merge request** to conclude the process. When successfully merged, your
changes are added to the repository and branch you're merging into.

## Removing a fork relationship

You can unlink your fork from its upstream project in the [advanced settings](../settings/index.md#remove-a-fork-relationship).

## Related topics

- GitLab blog post: [How to keep your fork up to date with its origin](https://about.gitlab.com/blog/2016/12/01/how-to-keep-your-fork-up-to-date-with-its-origin/).
- GitLab community forum: [Refreshing a fork](https://forum.gitlab.com/t/refreshing-a-fork/).
