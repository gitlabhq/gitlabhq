---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Use the Web Editor to create, upload, and edit text files directly in the GitLab UI."
title: Web Editor
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use the Web Editor directly in the GitLab UI without
cloning repositories locally or using the command line.

Use the Web Editor to:

- Edit single files without a local development environment.
- Create or upload new files.
- Replace a file with another file.
- Create new directories.
- Create a branch or tag.
- [Lock a file or a directory](../file_lock.md#lock-a-file-or-a-directory).
- Contribute to projects without setting up Git locally.

GitLab uses your [primary email address](../../profile/_index.md#change-the-email-displayed-on-your-commits)
for Web Editor commits.

For changes to multiple files, use the [Web IDE](../web_ide/_index.md).

NOTE:
To manage files in a [protected branch](branches/protected.md),
you must have the appropriate [permissions](../../permissions.md).

## Manage files

You can create, edit, upload, and delete files with the Web Editor, directly from the GitLab UI.

### Create a file

To create a text file in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the directory where you want to create the new file.
1. Next to the directory name, select the plus icon (**{plus}**) > **New file**.
1. Next to the branch name, enter a filename and extension. For example, `my_file.md`.
1. Add content to your file.
1. Select **Commit changes**.
1. In the **Commit message** field, enter a reason for the commit.
1. Choose one of the following options:

   - To create a file in the prefilled target branch, select **Commit changes**.
   - To create a file in a new branch and commit changes:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is cleared.
     1. Select **Commit changes**.

   - To create a file in a new branch, commit changes, and create a merge request:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is selected.
     1. Select **Commit changes**.

#### From a template

To create a text file from a template in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the directory where you want to create the new file.
1. Next to the directory name, select the plus icon (**{plus}**) > **New file**.
1. In **Filename**, enter a name that GitLab provides a template for:
   - `.gitignore`
   - `.gitlab-ci.yml`
   - `LICENSE`
   - `Dockerfile`
1. From the **Apply a template** dropdown list, select a template.
1. Optional. Update the template as desired.
1. Continue from the step 6 in the [create a file](#create-a-file) process.

### Edit a file

To edit a text file in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the file you want to edit.
1. Select **Edit > Edit single file**.
1. Make your changes.
1. Select **Commit changes**.
1. In the **Commit message** field, enter a reason for the commit.
1. Choose one of the following options:

   - To edit a file from the prefilled target branch, select **Commit changes**.
   - To edit a file from a new branch and commit changes:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is cleared.
     1. Select **Commit changes**.

   - To edit a file from a new branch, commit changes, and create a merge request:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is selected.
     1. Select **Commit changes**.
     1. Fill out the fields and select **Create merge request**.

NOTE:
If someone edits and commits changes to the same file while your are editing,
you can't commit your changes. The following error message is displayed:
`Someone edited the file the same time you did. Please check out the file and
make sure your change will not unintentionally remove theirs.`

#### Markdown preview

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378966) in GitLab 15.6.

To preview a Markdown file in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the file you want to preview.
1. Select **Edit > Edit single file**.
1. Select the **Preview** tab.

You can see a live Markdown preview alongside your content.

To close the preview panel, select the **Write** tab.

#### Link to specific lines

To link to single or multiple lines in the Web Editor, add hash
information to the filename segment of the URL. For example:

- `MY_FILE.js#L3` highlights line 3 in `MY_FILE.js`.
- `MY_FILE.js#L3-10` highlights lines 3 to 10 in `MY_FILE.js`.

When you edit a file, you can also link to a single line by selecting a line number.

#### Edit files in a forked merge request

Prerequisites:

- You must work on a merge request from a fork.
- [Allow commits from upstream members](../merge_requests/allow_collaboration.md#allow-commits-from-upstream-members) must be enabled.

If you're working on a merge request from a forked project,
you can edit a file and commit changes. To do this:

1. Go to the merge request.
1. Go to the file you want to edit.
1. Select **Edit > Edit single file**.
1. Select **Commit changes**.
1. In **Commit message**, enter a reason for the commit.
   The following information is provided: `Your changes can be committed to <branch-name> because a merge request is open.`
1. Select **Commit changes**.

### Upload a file

To upload a file in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the directory where you want to upload the file.
1. Next to the directory name, select the plus icon (**{plus}**) > **Upload file**.
1. Drop or upload the file your want to add.
1. In the **Commit message** field, enter a reason for the commit.
1. Choose one of the following options:

   - To upload a file from the prefilled target branch, select **Commit changes**.
   - To upload a file from a new branch and commit changes:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is cleared.
     1. Select **Commit changes**.

   - To upload a file from a new branch, commit changes, and create a merge request:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is selected.
     1. Select **Commit changes**.
     1. Fill out the fields and select **Create merge request**.

### Delete a file

To delete a file in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the file you want to delete.
1. Select **Delete**.
1. In **Commit message**, enter a reason for the commit.
1. Choose between the following options:

   - To delete a file from the prefilled target branch, select **Commit changes**.
   - To delete a file from a new branch and commit changes:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is cleared.
     1. Select **Commit changes**.

   - To delete a file from a new branch, commit changes, and create a merge request:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is selected.
     1. Select **Commit changes**.

NOTE:
If someone edits and commits changes to the same file while your are editing,
you can't commit your changes. The following error message is displayed:
`Someone edited the file the same time you did. Please check out the file and
make sure your change will not unintentionally remove theirs.`

### Replace a file

To replace a file in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the file you want to replace.
1. Select **Replace**.
1. Drop or upload the file you want to upload and replace the existing one.
1. In **Commit message**, enter a reason for the commit.
1. Choose between the following options:

   - To replace a file from the prefilled target branch, select **Commit changes**.
   - To replace a file from a new branch and commit changes:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is cleared.
     1. Select **Commit changes**.

   - To replace a file from a new branch, commit changes, and create a merge request:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is selected.
     1. Select **Commit changes**.

### Cancel file changes

To cancel changes, edit, upload, or delete a file, from the Web Editor:

1. Select **Cancel**.
1. Select one of the following:

   - Confirm you want to cancel changes: Select **OK**.
   - Don't cancel changes: Select **Cancel**.

## Create a directory

To create a directory in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the directory where you want to create the new directory.
1. Next to the directory name, select the plus icon (**{plus}**) > **New directory**.
1. In the **Directory name** field, enter your directory name.
1. In **Commit message**, enter a reason for the commit.
1. Choose between the following options:

   - To create a directory from the prefilled target branch, select **Commit changes**.
   - To create a directory from a new branch and commit changes:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is cleared.
     1. Select **Commit changes**.

   - To create a directory from a new branch, commit changes, and create a merge request:

     1. Select **Commit to a new branch**.
     1. Enter a branch name.
     1. Ensure the **Create a merge request for this change** checkbox is selected.
     1. Select **Commit changes**.

## Create a branch

To create a [branch](branches/_index.md) in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Next to the repository name, select the plus icon (**{plus}**) > **New branch**.
1. Complete the fields.
1. Select **Create branch**.

## Create a tag

You can create [tags](tags/_index.md) to mark milestones such as
production releases and release candidates. To create a tag in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Next to the repository name, select the plus icon (**{plus}**) > **New tag**.
1. Complete the fields.
1. Select **Create tag**.

## Related topics

- [Create merge requests](../merge_requests/creating_merge_requests.md)
- [Branches](branches/_index.md)
  - [Default branch](branches/default.md)
  - [Protected branches](branches/protected.md)
- [Web IDE](../web_ide/_index.md)
