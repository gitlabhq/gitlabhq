---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Contribute code with Gitpod
---

Now for the fun part. Let's edit some code.

In this example, I found some UI text I'd like to change.
In the upper-right corner in GitLab, I selected my avatar and then **Preferences**.
I want to change `Customize the color of GitLab` to `Customize the color theme of the GitLab UI`:

![The UI text in GitLab before making the change.](../img/ui_color_theme_before_v16_9.png)

1. Create a new branch for your changes:

   Select `master` in the status bar, then from the **Select a branch or tag to checkout** box,
   select **Create new branch** and enter a name for the new branch.

   If your code change addresses an issue, [start the branch name with the issue number](../../../user/project/repository/branches/_index.md#prefix-branch-names-with-issue-numbers).

   The examples in this doc use a new branch called `ui-updates`.

1. Search the repository for the string `Customize the color of GitLab`:

   - In VS Code, select the search icon <i class="fa fa-search fa-flip-horizontal" aria-hidden="true"></i> from the side toolbar.

1. Select the `app/views/profiles/preferences/show.html.haml` file.
1. Update the string to `Customize the color theme of the GitLab UI`.
1. Save your changes.
1. Use the IDE **Terminal** tab to commit the changes:

   ```shell
   git commit -m "Update UI text

   Standardizing the text on this page so
   that each area uses consistent language."
   ```

   Follow the GitLab
   [commit message guidelines](../merge_request_workflow.md#commit-messages-guidelines).

1. Push the changes to the new branch:

   ```shell
   git push --set-upstream origin ui-updates
   ```

1. You can [create a merge request](mr-review.md) with the code change,
   or continue to update the translation files.

## Update the translation files

English UI strings are localized into many languages.
These strings are saved in a `.pot` file, which must be regenerated
any time you update UI text.

To automatically regenerate the localization file:

1. Ensure you are in the `gitlab-development-kit/gitlab` directory.
1. Run the following command:

   ```shell
   tooling/bin/gettext_extractor locale/gitlab.pot
   ```

   The `.pot` file will be generated in the `/locale` directory.

   Now, in the `gitlab-development-kit/gitlab` directory, if you type `git status`
   you should have both files listed:

   ```shell
           modified:   app/views/profiles/preferences/show.html.haml
           modified:   locale/gitlab.pot
   ```

1. Commit and push the changes.
1. [Create a merge request](mr-review.md) or continue to update the documentation.

For more information about localization, see [internationalization](../../i18n/externalization.md).

## Update the documentation

Documentation for GitLab is published on <https://docs.gitlab.com>.
When you add or update a feature, you must update the documentation as well.

1. To find the documentation for a feature, the easiest thing is to search the
   documentation site. In this case, the setting is described on this documentation page:

   ```plaintext
   https://docs.gitlab.com/ee/user/profile/preferences.html
   ```

1. The URL shows you the location of the file in the `/doc` directory.
   In this case, the location is:

   ```plaintext
   doc/user/profile/preferences.md
   ```

1. Go to this location in your local `gitlab` repository and update the `.md` file
   and any related images.

   Now when you run `git status`, you should have something like:

   ```plaintext
           modified:   app/views/profiles/preferences/show.html.haml
           modified:   doc/user/profile/img/profile-preferences-syntax-themes.png
           modified:   doc/user/profile/preferences.md
           modified:   locale/gitlab.pot
   ```

1. Commit and push the changes.
1. [Create a merge request](mr-review.md) or continue to update the documentation.
