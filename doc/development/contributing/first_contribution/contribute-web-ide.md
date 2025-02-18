---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Contribute code with the Web IDE
---

The [GitLab Web IDE](../../../user/project/web_ide/_index.md) is a built-in advanced editor with commit staging.

The example in this section shows how to modify a line of code as part of a community contribution
to GitLab code using the Web IDE.

1. Go to the [GitLab community fork](https://gitlab.com/gitlab-community/gitlab).

1. Search the GitLab code for the string `Customize the color of GitLab`.
   From the [GitLab Community Fork](https://gitlab.com/gitlab-community/gitlab):

   1. On the left sidebar, select **Search or go to**.
   1. Enter the search string `"Customize the color of GitLab"`.

1. Select the filename
   [from the results](https://gitlab.com/search?search=%22Customize+the+color+of+GitLab%22&nav_source=navbar&project_id=41372369&group_id=60717473&search_code=true).
   In this case, `app/views/profiles/preferences/show.html.haml`.

1. Open the file in Web IDE. Select **Edit > Open in Web IDE**.

   - Keyboard shortcut: <kbd>.</kbd>

1. Update the string from `Customize the color of GitLab` to `Customize the color theme of the GitLab UI`.

1. Save your changes.

1. On the left activity bar, select **Source Control**.

   Keyboard shortcut: <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>.

1. Enter your commit message:

   ```plaintext
   Update UI text

   Standardizing the text on this page so
   that each area uses consistent language.
   ```

   Follow the GitLab
   [commit message guidelines](../merge_request_workflow.md#commit-messages-guidelines).

1. Select **Commit to new branch** from the **Commit to** dropdown list, and enter `1st-contrib-example`.

   If your code change addresses an issue, [start the branch name with the issue number](../../../user/project/repository/branches/_index.md#prefix-branch-names-with-issue-numbers).

1. In the notification that appears in the lower right, select **Create MR**.

1. Continue to [Create a merge request](mr-review.md)
