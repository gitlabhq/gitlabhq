---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
description: "How to create merge requests in GitLab."
disqus_identifier: 'https://docs.gitlab.com/ee/gitlab-basics/add-merge-request.html'
---

# Creating merge requests **(FREE)**

There are many different ways to create a merge request.

## From the merge request list

You can create a merge request from the list of merge requests.

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left menu, select **Merge requests**.
1. In the top right, select **New merge request**.
1. Select a source and target branch and then **Compare branches and continue**.
1. Fill out the fields and select **Create merge request**.

## From an issue

You can [create a merge request from an issue](../repository/web_editor.md#create-a-new-branch-from-an-issue).

## When you add, edit, or upload a file

You can create a merge request when you add, edit, or upload a file to a repository.

1. Add, edit, or upload a file to the repository.
1. In the **Commit message**, enter a reason for the commit.
1. Select the **Target branch** or create a new branch by typing the name (without spaces, capital letters, or special chars).
1. Select the **Start a new merge request with these changes** checkbox or toggle. This checkbox or toggle is visible only
   if the target is not the same as the source branch, or if the source branch is protected.
1. Select **Commit changes**.

## When you create a branch

You can create a merge request when you create a branch.

1. On the top bar, select **Menu > Projects** and find your project.
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
   remote: To create a merge request for docs-new-merge-request, visit:
   remote:   https://gitlab.example.com/my-group/my-project/merge_requests/new?merge_request%5Bsource_branch%5D=my-new-branch
   ```

1. Copy the link and paste it in your browser.

You can add other [flags to commands when pushing through the command line](../push_options.md)
to reduce the need for editing merge requests manually through the UI.

## When you work in a fork

You can create a merge request from your fork to contribute back to the main project.

1. On the top bar, select **Menu > Project**.
1. Select your fork of the repository.
1. On the left menu, go to **Merge requests**, and select **New merge request**.
1. In the **Source branch** drop-down list box, select the branch in your forked repository as the source branch.
1. In the **Target branch** drop-down list box, select the branch from the upstream repository as the target branch.
   You can set a [default target project](#set-the-default-target-project) to
   change the default target branch (which can be useful if you are working in a
   forked project).
1. Select **Compare branches and continue**.
1. Select **Submit merge request**.

After your work is merged, if you don't intend to
make any other contributions to the upstream project, you can unlink your
fork from its upstream project. Go to **Settings > Advanced Settings** and
[remove the forking relationship](../settings/index.md#removing-a-fork-relationship).

For more information, [see the forking workflow documentation](../repository/forking_workflow.md).

## By sending an email **(FREE SELF)**

> The format of the generated email address changed in GitLab 11.7.
  The earlier format is still supported so existing aliases
  or contacts still work.

You can create a merge request by sending an email message to GitLab.
The merge request target branch is the project's default branch.

Prerequisites:

- A GitLab administrator must configure [incoming email](../../../administration/incoming_email.md).
- A GitLab administrator must configure [Reply by email](../../../administration/reply_by_email.md).

To create a merge request by sending an email:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left menu, select **Merge requests**.
1. In the top right, select **Email a new merge request to this project**.
   An email address is displayed. Copy this address.
   Ensure you keep this address private.
1. Open an email and compose a message with the following information:

   - The **To** line is the email address you copied.
   - The subject line is the source branch name.
   - The message body is the merge request description.

1. Send the email message.

A merge request is created.

### Add attachments when creating a merge request by email

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22723) in GitLab 11.5.

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

Merge requests have a source and a target project that are the same, unless
forking is involved. Creating a fork of the project can cause either of these
scenarios when you create a new merge request:

- You target an upstream project (the project you forked, and the default
  option).
- You target your own fork.

To have merge requests from a fork by default target your own fork
(instead of the upstream project), you can change the default.

1. On the top bar, select **Menu > Project**.
1. On the left menu, select **Settings > General > Merge requests**.
1. In the **Target project** section, select the option you want to use for
   your default target project.
1. Select **Save changes**.
