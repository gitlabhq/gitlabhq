---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "How to create merge requests in GitLab."
---

# Creating merge requests **(FREE)**

There are many different ways to create a merge request.

NOTE:
Use [branch naming patterns](../repository/branches/index.md#prefix-branch-names-with-issue-numbers) to streamline merge request creation.

## From the merge request list

You can create a merge request from the list of merge requests.

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left menu, select **Merge requests**.
1. In the upper-right corner, select **New merge request**.
1. Select a source and target branch and then **Compare branches and continue**.
1. Fill out the fields and select **Create merge request**.

NOTE:
Merge requests are designed around a one-to-one (1:1) branch relationship. Only one open merge request may
be associated with a given target branch at a time.

## From an issue

> The **Create merge request** button [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/349566) to open the merge request creation form in GitLab 14.8.

If your development workflow requires an issue for every merge
request, you can create a branch directly from the issue to speed the process up.
The new branch, and later its merge request, are marked as related to this issue.
After merging the merge request, the issue is closed automatically, unless
[automatic issue closing is disabled](../issues/managing_issues.md#disable-automatic-issue-closing).
You can see a **Create merge request** dropdown list below the issue description.

NOTE:
In GitLab 14.8 and later, selecting **Create merge request**
[redirects to the merge request creation form](https://gitlab.com/gitlab-org/gitlab/-/issues/349566)
instead of immediately creating the merge request.

**Create merge request** doesn't display if:

- A branch with the same name already exists.
- A merge request already exists for this branch.
- Your project has an active fork relationship.
- Your project is private and the issue is confidential.

To make this button appear, one possible workaround is to
[remove your project's fork relationship](../repository/forking_workflow.md#unlink-a-fork).
After removal, the fork relationship cannot be restored. This project can no longer
be able to receive or send merge requests to the source project, or other forks.

The dropdown list contains the options **Create merge request and branch** and **Create branch**.

After selecting one of these options, a new branch or branch and merge request
is created based on your project's [default branch](../repository/branches/default.md).
The branch name is based on your project's [branch name template](../repository/branches/index.md),
but this value can be changed.

When you select **Create branch** in an empty
repository project, GitLab performs these actions:

- Creates a default branch.
- Commits a blank `README.md` file to it.
- Creates and redirects you to a new branch based on the issue title.
- _If your project is [configured with a deployment service](../integrations/index.md) like Kubernetes,_
  GitLab prompts you to set up [auto deploy](../../../topics/autodevops/stages.md#auto-deploy)
  by helping you create a `.gitlab-ci.yml` file.

After the branch is created, you can edit files in the repository to fix
the issue. When a merge request is created based on the newly-created branch,
the description field displays the [issue closing pattern](../issues/managing_issues.md#closing-issues-automatically)
`Closes #ID`, where `ID` is the ID of the issue. This closes the issue when the
merge request is merged.

## When you add, edit, or upload a file

You can create a merge request when you add, edit, or upload a file to a repository.

1. [Add, edit, or upload](../repository/web_editor.md) a file to the repository.
1. In the **Commit message**, enter a reason for the commit.
1. Select the **Target branch** or create a new branch by typing the name (without spaces).
1. Select the **Start a new merge request with these changes** checkbox or toggle. This checkbox or toggle is visible only
   if the target is not the same as the source branch, or if the source branch is protected.
1. Select **Commit changes**.

## When you create a branch

You can create a merge request when you create a branch.

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left menu, select **Repository > Branches**.
1. Type a branch name and select **New branch**.
1. Above the file list, on the right side, select **Create merge request**.
   A merge request is created. The default branch is the target.
1. Fill out the fields and select **Create merge request**.

## When you use Git commands locally

You can create a merge request by running Git commands on your local machine.

1. Create a branch:

   ```shell
   git checkout -b my-new-branch
   ```

1. Create, edit, or delete files. The stage and commit them:

   ```shell
   git add .
   git commit -m "My commit message"
   ```

1. [Push your branch to GitLab](../../../gitlab-basics/start-using-git.md#send-changes-to-gitlabcom):

   ```shell
   git push origin my-new-branch
   ```

   GitLab prompts you with a direct link for creating a merge request:

   ```plaintext
   ...
   remote: To create a merge request for my-new-branch, visit:
   remote:   https://gitlab.example.com/my-group/my-project/merge_requests/new?merge_request%5Bsource_branch%5D=my-new-branch
   ```

1. Copy the link and paste it in your browser.

You can add other [flags to commands when pushing through the command line](../push_options.md)
to reduce the need for editing merge requests manually through the UI.

## When you work in a fork

You can create a merge request from your fork to contribute back to the main project.

1. On the top bar, select **Main menu > Projects** and find your project.
1. Select your fork of the repository.
1. On the left menu, go to **Merge requests**, and select **New merge request**.
1. In the **Source branch** dropdown list box, select the branch in your forked repository as the source branch.
1. In the **Target branch** dropdown list box, select the branch from the upstream repository as the target branch.
   You can set a [default target project](#set-the-default-target-project) to
   change the default target branch (which can be useful if you are working in a
   forked project).
1. Select **Compare branches and continue**.
1. Select **Create merge request**.

After your work is merged, if you don't intend to
make any other contributions to the upstream project, you can
[unlink your fork](../repository/forking_workflow.md#unlink-a-fork) from its upstream project.

For more information, [see the forking workflow documentation](../repository/forking_workflow.md).

## By sending an email

You can create a merge request by sending an email message to GitLab.
The merge request target branch is the project's default branch.

Prerequisites:

- A GitLab administrator must configure [incoming email](../../../administration/incoming_email.md).
- A GitLab administrator must configure [Reply by email](../../../administration/reply_by_email.md).

To create a merge request by sending an email:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left menu, select **Merge requests**.
1. In the upper-right corner, select **Email a new merge request to this project**.
   An email address is displayed. Copy this address.
   Ensure you keep this address private.
1. Open an email and compose a message with the following information:

   - The **To** line is the email address you copied.
   - The subject line is the source branch name.
   - The message body is the merge request description.

1. Send the email message.

A merge request is created.

### Add attachments when creating a merge request by email

You can add commits to a merge request by adding
patches as attachments to the email. All attachments with a filename
ending in `.patch` are considered patches and are processed
ordered by name.

The combined size of the patches can be 2 MB.

If the source branch from the subject does not exist, it is
created from the repository's HEAD or the specified target branch.
You can specify the target branch by using the
[`/target_branch` quick action](../quick_actions.md). If the source
branch already exists, the patches are applied on top of it.

## Set the default target project

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58093) in GitLab 13.11.

Merge requests have a source and a target project that are the same, unless
forking is involved. Creating a fork of the project can cause either of these
scenarios when you create a new merge request:

- You target an upstream project (the project you forked, and the default
  option).
- You target your own fork.

To have merge requests from a fork by default target your own fork
(instead of the upstream project), you can change the default.

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left menu, select **Settings > General > Merge requests**.
1. In the **Target project** section, select the option you want to use for
   your default target project.
1. Select **Save changes**.
