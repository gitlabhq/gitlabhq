---
stage: Create
group: Editor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Web Editor **(FREE)**

You can use the Web Editor to make changes directly from the GitLab UI instead of
cloning a project and using the command line.

From the project dashboard or repository, you can:

- [Create a file](#create-a-file).
- [Edit a file](#edit-a-file).
- [Upload a file](#upload-a-file).
- [Create a directory](#create-a-directory).
- [Create a branch](#create-a-branch).
- [Create a tag](#create-a-tag).

Your [primary email address](../../../user/profile/index.md#change-the-email-displayed-on-your-commits)
is used by default for any change you commit through the Web Editor.

## Create a file

To create a text file in the Web Editor:

1. On the top bar, select **Main menu > Projects** and find your project.
1. From the project dashboard or repository, next to the branch name, select the plus icon (**{plus}**).
1. From the dropdown list, select **New file**.
1. Complete the fields.
   - From the **Select a template type** dropdown list, you can apply a template to the new file.
   - To create a merge request with the new file, ensure the **Start a new merge request with these changes** checkbox is selected.
1. Select **Commit changes**.

## Edit a file

To edit a file in the Web Editor:

1. On the top bar, select **Main menu > Projects** and find your project.
1. Go to your file.
1. Next to the display buttons, select **Edit**.

### Keyboard shortcuts

When you [edit a file](#edit-a-file) in the Web Editor, you can use the same keyboard shortcuts for the Web IDE.
See the [available shortcuts](../../shortcuts.md#web-ide).

### Preview Markdown

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378966) in GitLab 15.6.

To preview Markdown content in the Web Editor:

1. [Edit a file](#edit-a-file).
1. Do one of the following:
   - Select the **Preview** tab.
   - From the context menu, select **Preview Markdown**.

In the **Preview** tab, you can see a live Markdown preview alongside your content.

To close the preview panel, do one of the following:

- Select the **Write** tab.
- From the context menu, select **Hide Live Preview**.

### Link to specific lines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56159) in GitLab 13.11.

To link to single or multiple lines in the Web Editor, add hash
information to the filename segment of the URL. For example:

- `MY_FILE.js#L3` highlights line 3 in `MY_FILE.js`.
- `MY_FILE.js#L3-10` highlights lines 3 to 10 in `MY_FILE.js`.

To link to a single line, you can also:

1. [Edit a file](#edit-a-file).
1. Select a line number.

## Upload a file

To upload a binary file in the Web Editor:

1. On the top bar, select **Main menu > Projects** and find your project.
1. From the project dashboard or repository, next to the branch name, select the plus icon (**{plus}**).
1. From the dropdown list, select **Upload file**.
1. Complete the fields. To create a merge request with the uploaded file, ensure the **Start a new merge request with these changes** toggle is turned on.
1. Select **Upload file**.

## Create a directory

To create a directory in the Web Editor:

1. On the top bar, select **Main menu > Projects** and find your project.
1. From the project dashboard or repository, next to the branch name, select the plus icon (**{plus}**).
1. From the dropdown list, select **New directory**.
1. Complete the fields. To create a merge request with the new directory, ensure the **Start a new merge request with these changes** toggle is turned on.
1. Select **Create directory**.

## Create a branch

To create a [branch](branches/index.md) in the Web Editor:

1. On the top bar, select **Main menu > Projects** and find your project.
1. From the project dashboard or repository, next to the branch name, select the plus icon (**{plus}**).
1. From the dropdown list, select **New branch**.
1. Complete the fields.
1. Select **Create branch**.

## Create a tag

You can create [tags](../../../topics/git/tags.md) to mark milestones such as
production releases and release candidates. To create a tag in the Web Editor:

1. On the top bar, select **Main menu > Projects** and find your project.
1. From the project dashboard or repository, next to the branch name, select the plus icon (**{plus}**).
1. From the dropdown list, select **New tag**.
1. Complete the fields.
1. Select **Create tag**.
