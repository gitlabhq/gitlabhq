---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Web Editor **(FREE)**

You can use the Web Editor to make changes to a single file directly from the
GitLab UI. To make changes to multiple files, see [Web IDE](../web_ide/index.md).

In the Web Editor, you can:

- [Create a file](#create-a-file).
- [Edit a file](#edit-a-file).
- [Upload a file](#upload-a-file).
- [Create a directory](#create-a-directory).
- [Create a branch](#create-a-branch).
- [Create a tag](#create-a-tag).

Your [primary email address is used by default](../../../user/profile/index.md#change-the-email-displayed-on-your-commits)
for any change you commit through the Web Editor.

## Create a file

To create a text file in the Web Editor:

1. On the top bar, select **Main menu > Projects** and find your project.
1. From the project dashboard or repository, next to the branch name,
   select the plus icon (**{plus}**).
1. From the dropdown list, select **New file**.
1. Complete the fields.
1. To create a merge request with the new file, ensure the **Start a new merge request with these changes** checkbox is selected, if you had chosen a **Target branch** other than the [default branch (such as `main`)](../../../user/project/repository/branches/default.md).
1. Select **Commit changes**.

### Create a file from a template

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Repository > Files**.
1. Next to the project name, select the plus icon (**{plus}**) to display a
   dropdown list, then select **New file** from the list.
1. For **Filename**, provide one of the filenames that GitLab provides a template for:
   - `.gitignore`
   - `.gitlab-ci.yml`
   - `LICENSE`
   - `Dockerfile`
1. Select **Apply a template**, then select the template you want to apply.
1. Make your changes to the file.
1. Provide a **Commit message**.
1. Enter a **Target branch** to merge into. To create a new merge request with
   your changes, enter a branch name that is not your repository's
   [default branch](../../../user/project/repository/branches/default.md),
1. Select **Commit changes** to add the commit to your branch.

## Edit a file

To edit a text file in the Web Editor:

1. On the top bar, select **Main menu > Projects** and find your project.
1. Go to your file.
1. In the upper-right corner of the file, select **Edit**.

   If **Edit** is not visible:

   1. Next to **Open in Web IDE** or **Open in Gitpod**, select the down arrow (**{chevron-lg-down}**).
   1. From the dropdown list, select **Edit** as your default setting.
   1. Select **Edit**.

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

<!-- This list is duplicated at doc/gitlab-basics/add-file.md#from-the-ui -->
<!-- For why we duplicated the info, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111072#note_1267429478 -->

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

You can create [tags](tags/index.md) to mark milestones such as
production releases and release candidates. To create a tag in the Web Editor:

1. On the top bar, select **Main menu > Projects** and find your project.
1. From the project dashboard or repository, next to the branch name, select the plus icon (**{plus}**).
1. From the dropdown list, select **New tag**.
1. Complete the fields.
1. Select **Create tag**.
