---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Use the Web Editor to create, upload, and edit text files directly in the GitLab UI."
---

# Web Editor

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can use the Web Editor to make changes to a single file directly from the GitLab UI.
To make changes to multiple files, see [Web IDE](../web_ide/index.md).

Your [primary email address](../../profile/index.md#change-the-email-displayed-on-your-commits)
is used by default for any change you commit with the Web Editor.

## Create a file

To create a text file in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the directory where you want to create the new file.
1. Next to the directory name, select the plus icon (**{plus}**) > **New file**.
1. Complete the fields.
   To create a merge request with your changes, enter a branch name
   that's not your repository's [default branch](branches/default.md).
1. Select **Commit changes**.

### From a template

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
1. Complete the fields.
   To create a merge request with your changes, enter a branch name
   that's not your repository's [default branch](branches/default.md).
1. Select **Commit changes**.

## Edit a file

To edit a text file in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the file you want to edit.
1. Select **Edit > Edit single file**.
1. Complete the fields.
   To create a merge request with your changes, enter a branch name
   that's not your repository's [default branch](branches/default.md).
1. Select **Commit changes**.

### Preview Markdown

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378966) in GitLab 15.6.

To preview a Markdown file in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the file you want to preview.
1. Select **Edit > Edit single file**.
1. Select the **Preview** tab.

You can see a live Markdown preview alongside your content.

To close the preview panel, select the **Write** tab.

### Link to specific lines

To link to single or multiple lines in the Web Editor, add hash
information to the filename segment of the URL. For example:

- `MY_FILE.js#L3` highlights line 3 in `MY_FILE.js`.
- `MY_FILE.js#L3-10` highlights lines 3 to 10 in `MY_FILE.js`.

When you edit a file, you can also link to a single line by selecting a line number.

## Upload a file

To upload a file in the Web Editor:

<!-- This list is duplicated at doc/user/project/repository/index.md#add-a-file-from-the-ui -->
<!-- For why we duplicated the info, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111072#note_1267429478 -->

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the directory where you want to upload the file.
1. Next to the directory name, select the plus icon (**{plus}**) > **Upload file**.
1. Complete the fields.
   To create a merge request with your changes, enter a branch name
   that's not your repository's [default branch](branches/default.md).
1. Select **Upload file**.

## Create a directory

To create a directory in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to the directory where you want to create the new directory.
1. Next to the directory name, select the plus icon (**{plus}**) > **New directory**.
1. Complete the fields.
   To create a merge request with your changes, enter a branch name
   that's not your repository's [default branch](branches/default.md).
1. Select **Create directory**.

## Create a branch

To create a [branch](branches/index.md) in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Next to the repository name, select the plus icon (**{plus}**) > **New branch**.
1. Complete the fields.
1. Select **Create branch**.

## Create a tag

You can create [tags](tags/index.md) to mark milestones such as
production releases and release candidates. To create a tag in the Web Editor:

1. On the left sidebar, select **Search or go to** and find your project.
1. Next to the repository name, select the plus icon (**{plus}**) > **New tag**.
1. Complete the fields.
1. Select **Create tag**.
