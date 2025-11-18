---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Contribute code with the Web IDE
---

The [GitLab Web IDE](../../../user/project/web_ide/_index.md) is a built-in advanced editor with commit staging.

{{< alert type="warning" >}}

This tutorial is designed to be a general introduction to contributing to the GitLab project
and is not an example of a change that should be submitted for review.

{{< /alert >}}

The example in this section shows how to modify a line of code as part of a community contribution
to GitLab code using the Web IDE.

1. Go to the [GitLab community fork](https://gitlab.com/gitlab-community/gitlab-org/gitlab).

1. Search the GitLab code for the string `Syntax highlighting`.
   From the [GitLab Community Fork](https://gitlab.com/gitlab-community/gitlab-org/gitlab):

   1. On the left sidebar, select **Search or go to**. If you've [turned on the new navigation](../../../user/interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
   1. Enter the search string `"Syntax highlighting"`.

1. Select the filename
   [from the results](https://gitlab.com/search?search=Syntax+highlighting&nav_source=navbar&project_id=41372369&group_id=60717473&search_code=true).
   In this case, `app/views/profiles/preferences/show.html.haml`.

1. Open the file in Web IDE. Select **Edit** > **Open in Web IDE**.

   - Keyboard shortcut: <kbd>.</kbd>

1. Update the string from `Syntax highlighting` to `Code highlighting`.

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

   If your code change addresses an issue, [start the branch name with the issue number](../../../user/project/repository/branches/_index.md#prefix-branch-names-with-a-number).

1. In the notification that appears in the lower right, select **Create MR**.

1. Continue to [Create a merge request](mr-review.md)
