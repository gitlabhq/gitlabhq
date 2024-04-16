---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Use the Web IDE to edit multiple files in the GitLab UI, stage commits, and create merge requests."
---

# Web IDE

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95169) in GitLab 15.7 [with a flag](../../../administration/feature_flags.md) named `vscode_web_ide`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/371084) in GitLab 15.7.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115741) in GitLab 15.11.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named `vscode_web_ide`. On GitLab.com and GitLab Dedicated, this feature is available.

The Web IDE is an advanced editor with commit staging.
You can use the Web IDE to make changes to multiple files directly from the GitLab UI.
For a more basic implementation, see [Web Editor](../repository/web_editor.md).

To pair the Web IDE with a remote development environment, see [Remote development](../remote_development/index.md).

## Open the Web IDE

To open the Web IDE:

1. On the left sidebar, select **Search or go to** and find your project.
1. Use the <kbd>.</kbd> keyboard shortcut.

### From a file or directory

To open the Web IDE from a file or directory:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to your file or directory.
1. Select **Edit > Open in Web IDE**.

### From a merge request

To open the Web IDE from a merge request:

1. On the left sidebar, select **Search or go to** and find your project.
1. Go to your merge request.
1. In the upper right, select **Code > Open in Web IDE**.

The Web IDE opens new and modified files in separate tabs and displays changes side by side.
To reduce load time, only 10 files with the most lines changed are opened automatically.

On the left **Explorer** sidebar, any new or modified file is indicated
by the merge request icon (**{merge-request}**) next to the filename.
To view changes to a file, right-click the file and select **Compare with merge request base**.

## Open a file

To open a file by name in the Web IDE:

1. Press <kbd>Command</kbd>+<kbd>P</kbd>.
1. In the search box, enter the filename.

## Search open files

To search across open files in the Web IDE:

1. Press <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>F</kbd>.
1. In the search box, enter your search term.

## View a list of modified files

To view a list of files you modified in the Web IDE:

- On the left activity bar, select **Source Control**, or
  press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>.

Your `CHANGES`, `STAGED CHANGES`, and `MERGE CHANGES` are displayed.
For more information, see the [VS Code documentation](https://code.visualstudio.com/docs/sourcecontrol/overview#_commit).

## Restore uncommitted changes

You do not have to manually save any file you modify in the Web IDE.
Modified files are automatically staged and can be [committed](#commit-changes).
Uncommitted changes are saved in your browser's local storage and persist
even if you close the browser tab or refresh the Web IDE.

If your uncommitted changes are not available, you can restore the changes from local history.
To restore uncommitted changes in the Web IDE:

1. Press <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>P</kbd>.
1. In the search box, enter `Local History: Find Entry to Restore`.
1. Select the file that contains the uncommitted changes.

## Upload a file

To upload a file in the Web IDE:

1. On the left activity bar, select **Explorer**, or
   press <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>E</kbd>.
1. Go to the directory where you want to upload the file.
   To create a new directory:

   - On the left **Explorer** sidebar, in the upper right,
     select **New Folder** (**{folder-new}**).

1. Right-click the directory and select **Upload**.
1. Select the file you want to upload.

You can upload multiple files at once.
The files are uploaded and automatically added to the repository.

## Switch branches

The Web IDE uses the current branch by default.
To switch branches in the Web IDE:

1. On the bottom status bar, on the left, select the current branch name.
1. Enter or select an existing branch.

## Create a branch

To create a branch from the current branch in the Web IDE:

1. On the bottom status bar, on the left, select the current branch name.
1. From the dropdown list, select **Create new branch**.
1. Enter the new branch name.

If you do not have write access to the repository, **Create new branch** is not visible.

## Commit changes

To commit changes in the Web IDE:

1. On the left activity bar, select **Source Control**, or
   press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>G</kbd>.
1. Enter your commit message.
1. Commit to the current branch or [create a new branch](#create-a-branch).

## Create a merge request

To create a [merge request](../merge_requests/index.md) in the Web IDE:

1. [Commit the changes](#commit-changes).
1. In the notification that appears in the lower right, select **Create MR**.

For more information, see [View missed notifications](#view-missed-notifications).

## Use the command palette

You can use the command palette to access many commands.
To open the command palette and run a command in the Web IDE:

1. Press <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>P</kbd>.
1. Enter or select the command.

## Edit settings

You can use the settings editor to view and modify your user and workspace settings.
To open the settings editor in the Web IDE:

- On the top menu bar, select **File > Preferences > Settings**,
  or press <kbd>Command</kbd>+<kbd>,</kbd>.

In the settings editor, you can search for the settings you want to modify.

## Edit keyboard shortcuts

You can use the keyboard shortcuts editor to view and modify
the default keybindings for all available commands.
To open the keyboard shortcuts editor in the Web IDE:

- On the top menu bar, select **File > Preferences > Keyboard Shortcuts**,
  or press <kbd>Command</kbd>+<kbd>K</kbd> then <kbd>Command</kbd>+<kbd>S</kbd>.

In the keyboard shortcuts editor, you can search for:

- The keybindings you want to change
- The commands you want to add or remove keybindings for

Keybindings are based on your keyboard layout.
If you change your keyboard layout, existing keybindings are updated automatically.

## Change the color theme

You can choose between different color themes for the Web IDE.
The default theme is **GitLab Dark**.

To change the color theme in the Web IDE:

1. On the top menu bar, select **File > Preferences > Theme > Color Theme**,
   or press <kbd>Command</kbd>+<kbd>K</kbd> then <kbd>Command</kbd>+<kbd>T</kbd>.
1. From the dropdown list, preview the themes with the arrow keys.
1. Select a theme.

The active color theme is stored in the [user settings](#edit-settings).

## View missed notifications

When you perform actions in the Web IDE, notifications appear in the lower right.
To view any notification you might have missed:

1. On the bottom status bar, on the right, select the bell icon (**{notifications}**) for a list of notifications.
1. Select the notification you want to view.

<!-- ## Privacy and data collection for extensions

The Web IDE Extension Marketplace is based on Open VSX. Open VSX does not collect any
data about you or your activities on the platform.

However, the privacy and data collection practices of extensions available on Open VSX can vary.
Some extensions might collect data to provide personalized recommendations or to improve the functionality.
Other extensions might collect data for analytics or advertising purposes.

To protect your privacy and data:

- Carefully review the permissions requested by an extension before you install the extension.
- Keep your extensions up to date to ensure that any security or privacy vulnerabilities are addressed promptly. -->

## Interactive web terminals

DETAILS:
**Status**: Beta

WARNING:
This feature is in [Beta](../../../policy/experiment-beta-support.md#beta) and subject to change without notice.

When you set up a remote development server in the Web IDE, you can use interactive web terminals to:

- Access a remote shell on the server.
- Interact with the server's file system and execute commands remotely.

You cannot use interactive web terminals to interact with a runner.
However, you can use a terminal to install dependencies and compile and debug code.

For more information, see [Remote development](../remote_development/index.md).

## Related topics

- [GitLab Duo Chat in the Web IDE](../../gitlab_duo_chat.md#use-gitlab-duo-chat-in-the-web-ide)

## Troubleshooting

When working with the Web IDE, you might encounter the following issues.

### Character offset when typing

When you type in the Web IDE, you might get a four-character offset.
As a workaround:

1. On the top menu bar, select **File > Preferences > Settings**,
   or press <kbd>Command</kbd>+<kbd>,</kbd>.
1. In the upper-right corner, select **Open Settings (JSON)**.
1. In the `settings.json` file, add `"editor.disableMonospaceOptimizations": true`
   or modify the `"editor.fontFamily"` setting.

For more information, see [VS Code issue 80170](https://github.com/microsoft/vscode/issues/80170).
