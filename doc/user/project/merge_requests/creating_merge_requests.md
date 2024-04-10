---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "How to create merge requests in GitLab."
---

# Creating merge requests

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

GitLab provides many different ways to create a merge request.

NOTE:
GitLab enforces [branch naming rules](../repository/branches/index.md#name-your-branch)
to prevent problems, and provides
[branch naming patterns](../repository/branches/index.md#prefix-branch-names-with-issue-numbers)
to streamline merge request creation.

## From the merge request list

You can create a merge request from the list of merge requests.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. In the upper-right corner, select **New merge request**.
1. Select a source and target branch, then select **Compare branches and continue**.
1. Complete the fields on the **New merge request** page, then select **Create merge request**.

Each branch can be associated with only one open merge request. If a merge request
already exists for this branch, a link to the existing merge request is shown.

## From an issue

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/349566) the behavior of the **Create merge request** button to open the merge request creation form in GitLab 14.8.

If your development workflow requires an issue for every merge
request, you can create a branch directly from the issue to speed the process up.
The new branch, and later its merge request, are marked as related to this issue.
After merging the merge request, the issue is closed automatically, unless
[automatic issue closing is disabled](../issues/managing_issues.md#disable-automatic-issue-closing):

::Tabs

:::TabTitle Merge request and branch

To create a branch and a merge request at the same time:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Issues** and find your issue.
1. Go to the bottom of the issue description.
1. Select **Create merge request > Create merge request and branch**.
1. In the dialog, review the suggested branch name. It's based on your project's
   [branch name template](../repository/branches/index.md) Rename it if the
   branch name is already taken, or you need a different branch name.
1. Select a source branch or tag.
1. Select **Create merge request**.

:::TabTitle Branch only

To create only a branch directly from an issue:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Plan > Issues** and find your issue.
1. Go to the bottom of the issue description.
1. Select **Create merge request > Create branch**.
1. In the dialog, review the suggested branch name. It's based on your project's
   [branch name template](../repository/branches/index.md) Rename it if the
   branch name is already taken, or you need a different branch name.
1. Select a source branch or tag.
1. Select **Create branch**.

::EndTabs

If your Git repository is empty, GitLab:

- Creates a default branch.
- Commits a blank `README.md` file to it.
- Creates and redirects you to a new branch based on the issue title.
- If your project is [configured with a deployment service](../integrations/index.md) like Kubernetes,
  GitLab prompts you to set up [auto deploy](../../../topics/autodevops/stages.md#auto-deploy)
  by helping you create a `.gitlab-ci.yml` file.

If the name of the branch you create is
[prefixed with the issue number](../repository/branches/index.md#prefix-branch-names-with-issue-numbers),
GitLab cross-links the issue and merge request, and adds the
[issue closing pattern](../issues/managing_issues.md#closing-issues-automatically)
to the description of the merge request. In most cases, this looks like `Closes #ID`,
where `ID` is the ID of the issue. If your project is configured with a
[closing pattern](../issues/managing_issues.md#default-closing-pattern), the issue closes
when the merge request merges.

## When you add, edit, or upload a file

You can create a merge request when you add, edit, or upload a file to a repository.

1. [Add, edit, or upload](../repository/web_editor.md) a file to the repository.
1. In the **Commit message**, enter a reason for the commit.
1. Select the **Target branch** or create a new branch by typing the name.
1. Select the **Start a new merge request with these changes** checkbox or toggle. This checkbox or toggle is visible only
   if the target is not the same as the source branch, or if the source branch is protected.
1. Select **Upload file**.
1. Fill out the fields and select **Create merge request**.

## When you create a branch

You can create a merge request when you create a branch.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Branches**.
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

1. Create, edit, or delete files as needed.

1. Mark the files as ready to commit (staging them) and commit them locally:

   ```shell
   # Mark the files as ready to commit
   git add .
   # Commit the changes locally
   git commit -m "My commit message"
   ```

1. Push your branch and its commits to GitLab:

   ```shell
   git push origin my-new-branch
   ```

   To reduce the number of fields to edit later in the merge request, use
   [push options](../push_options.md) to set the value of fields.

1. In the response to the `git push`, GitLab provides a direct link to create the merge request:

   ```plaintext
   ...
   remote: To create a merge request for my-new-branch, visit:
   remote:   https://gitlab.example.com/my-group/my-project/merge_requests/new?merge_request%5Bsource_branch%5D=my-new-branch
   ```

1. Copy the link and paste it in your browser.

## When you work in a fork

You can create a merge request from your fork to contribute back to the main project.

1. On the left sidebar, select **Search or go to** and find your fork.
1. Select **Code > Merge requests**, and select **New merge request**.
1. For **Source branch**, select the branch in your fork that contains your changes.
1. For **Target branch**:

   1. Select the target project. (Make sure to select the upstream project, rather than your fork.)
   1. Select a branch from the upstream repository.

   NOTE:
   If you contribute changes upstream frequently, consider setting a
   [default target project](#set-the-default-target-project) for your fork.

1. Select **Compare branches and continue**.
1. Select **Create merge request**. The merge request is created in the target project,
   not your fork.

After your work merges, [unlink your fork](../repository/forking_workflow.md#unlink-a-fork)
from its upstream project if you don't intend to make more contributions.

For more information, [see the forking workflow documentation](../repository/forking_workflow.md).

### Set the default target project

By default, merge requests originating from a fork target the upstream project, not the forked project.

You can configure your forked project to be the default target rather than the upstream project.

Prerequisites:

- You're working in a fork.
- You must have at least the Developer role, or be allowed to create merge requests in the project.
- The upstream project allows merge requests to be created.
- The [visibility settings](../../public_access.md#change-project-visibility) for
  the fork must match, or be less strict than, the upstream repository. For example:
  this setting isn't shown if your fork is private, but the upstream is public.

To do this:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **Target project** section, select the option you want to use for
   your default target project.
1. Select **Save changes**.

## By sending an email

You can create a merge request by sending an email message to GitLab.
The merge request target branch is the project's default branch.

Prerequisites:

- The merge request must target the current project, not an upstream project.
- A GitLab administrator must configure [incoming email](../../../administration/incoming_email.md).
- A GitLab administrator must configure [Reply by email](../../../administration/reply_by_email.md).
- You must have at least the Developer role, or be allowed to create merge requests in the project.

To create a merge request by sending an email:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. If the project contains any merge requests, select **Email a new merge request to this project**.
1. In the dialog, copy the email address shown. Keep this address private. Anyone who
   has it can create issues or merge requests as if they were you.
1. Open an email and compose a message with the following information:

   - The **To** line is the email address you copied.
   - The **Subject** is the source branch name.
   - The body of the email is the merge request description.

1. To add commits, attach `.patch` files to the message.
1. Send the email.

A merge request is created.

### Add attachments when creating a merge request by email

Add commits to a merge request by adding patches as attachments to the email.

- The combined size of the patches must be 2 MB or less.
- To be considered a patch, the attachment's filename must end in `.patch`.
- Patches are processed in order by name.
- If the source branch from the subject does not exist, it is
  created from the repository's `HEAD`, or the default target branch.
  To change the target branch manually, use the
  [`/target_branch` quick action](../quick_actions.md).
- If the source branch already exists, patches are applied on top of it.

## Troubleshooting

### No option to create a merge request on an issue

The option to **Create merge request** doesn't display on an issue if:

- A branch with the same name already exists.
- A merge request already exists for this branch.
- Your project has an active fork relationship.
- Your project is private and the issue is confidential.

To make this button appear, one possible workaround is to
[remove your project's fork relationship](../repository/forking_workflow.md#unlink-a-fork).
After removal, the fork relationship cannot be restored. This project can no longer
be able to receive or send merge requests to the source project, or other forks.

### Email message could not be processed

When sending an email to create a merge request, and you attempt to target an
upstream project, GitLab responds with this error:

```plaintext
Unfortunately, your email message to GitLab could not be processed.

You are not allowed to perform this action. If you believe this is in error, contact a staff member.
```
