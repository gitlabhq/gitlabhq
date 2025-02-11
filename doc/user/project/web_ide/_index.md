---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Use the Web IDE to edit multiple files in the GitLab UI, stage commits, and create merge requests."
title: Web IDE
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95169) in GitLab 15.7 [with a flag](../../../administration/feature_flags.md) named `vscode_web_ide`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/371084) in GitLab 15.7.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/115741) in GitLab 15.11.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

The Web IDE is an advanced editor with commit staging.
You can use the Web IDE to make changes to multiple files directly from the GitLab UI.
For a more basic implementation, see [Web Editor](../repository/web_editor.md).

Support for [GitLab Flavored Markdown](../../markdown.md) preview in the Web IDE is proposed in
[issue 645](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/645).

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
To reduce load time, only 10 files with the most lines changed open automatically.

The left **Explorer** sidebar adds a merge request icon (**{merge-request}**) next to new or modified files.
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

You do not have to manually save any file you edit in the Web IDE.
The Web IDE stages the files you modify, so you can [commit the changes](#commit-changes).
Uncommitted changes are saved in your browser's local storage, and persist
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

To create a [merge request](../merge_requests/_index.md) in the Web IDE:

1. [Commit the changes](#commit-changes).
1. In the notification that appears in the lower right, select **Create MR**.

For more information, see [View missed notifications](#view-missed-notifications).

## Use the Command Palette

You can use the Command Palette to access many commands.
To open the Command Palette and run a command in the Web IDE:

1. Press <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>P</kbd>.
1. Enter or select the command.

## Edit settings

You can use the settings editor to view and edit your user and workspace settings.
To open the settings editor in the Web IDE:

- On the top menu bar, select **File > Preferences > Settings**,
  or press <kbd>Command</kbd>+<kbd>,</kbd>.

In the settings editor, you can search for the settings you want to change.

## Edit keyboard shortcuts

You can use the keyboard shortcuts editor to view and change
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

The Web IDE stores your active color theme in your [user settings](#edit-settings).

## Configure sync settings

To configure sync settings in the Web IDE:

1. Press <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>P</kbd>.
1. In the search box, enter `Settings Sync: Configure`.
1. Select or clear the checkbox for:
   - **Settings**
   - **Keyboard shortcuts**
   - **User snippets**
   - **User tasks**
   - **UI state**
   - **Extensions**
   - **Profiles**

These settings sync automatically across multiple Web IDE instances.
You cannot sync user profiles or go back to an earlier version of synced settings.

## View missed notifications

When you perform actions in the Web IDE, notifications appear in the lower right.
To view any notification you might have missed:

1. On the bottom status bar, on the right, select the bell icon (**{notifications}**) for a list of notifications.
1. Select the notification you want to view.

## Extension marketplace

DETAILS:
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151352) as a [beta](../../../policy/development_stages_support.md#beta) in GitLab 17.0 [with flags](../../../administration/feature_flags.md) named `web_ide_oauth` and `web_ide_extensions_marketplace`. Disabled by default.
> - Feature flag `web_ide_oauth` [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163181) in GitLab 17.4.
> - Feature flag `web_ide_extensions_marketplace` [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/459028) in GitLab 17.4.
> - Feature flag `web_ide_oauth` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167464) in GitLab 17.5.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

Prerequisites:

- In user preferences, you must
  [enable the extension marketplace](../../profile/preferences.md#integrate-with-the-extension-marketplace).
- In group settings, users with the Owner role must
  [enable the extension marketplace](../../enterprise_user/_index.md#enable-the-extension-marketplace-for-the-web-ide-and-workspaces) for enterprise users.

You can use the extension marketplace to download and run VS Code extensions in the Web IDE.

The extension marketplace is preconfigured for GitLab instances,
and is hardcoded to [`https://open-vsx.org/`](https://open-vsx.org/).
[Epic 11770](https://gitlab.com/groups/gitlab-org/-/epics/11770) proposes to change this behavior.

### Install an extension

To install an extension in the Web IDE:

1. On the top menu bar, select **View > Extensions**,
   or press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>X</kbd>.
1. In the search box, enter the extension name.
1. Select the extension you want to install.
1. Select **Install**.

### Uninstall an extension

To uninstall an extension in the Web IDE:

1. On the top menu bar, select **View > Extensions**,
   or press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>X</kbd>.
1. From the list of installed extensions, select the extension you want to uninstall.
1. Select **Uninstall**.

## Related topics

- [GitLab Duo Chat in the Web IDE](../../gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-the-web-ide)

## Troubleshooting

When working with the Web IDE, you might encounter the following issues.

### Character offset when typing

When you type in the Web IDE, you might get a four-character offset.
As a workaround:

1. On the top menu bar, select **File > Preferences > Settings**,
   or press <kbd>Command</kbd>+<kbd>,</kbd>.
1. In the upper-right corner, select **Open Settings (JSON)**.
1. In the `settings.json` file, add `"editor.disableMonospaceOptimizations": true`
   or change the `"editor.fontFamily"` setting.

For more information, see [VS Code issue 80170](https://github.com/microsoft/vscode/issues/80170).

### Update the OAuth callback URL

DETAILS:
**Offering:** GitLab Self-Managed

Prerequisites:

- You must have administrator access to the instance.

The Web IDE uses an [instance-wide OAuth application](../../../integration/oauth_provider.md#create-an-instance-wide-application) for authentication.
If the OAuth callback URL is misconfigured, you might encounter a `Cannot open Web IDE` error page with the following message:

```plaintext
The URL you're using to access the Web IDE and the configured OAuth callback URL do not match. This issue often occurs when you're using a proxy.
```

To resolve this issue, you must update the OAuth callback URL to match the URL used to access the GitLab instance.

To update the OAuth callback URL:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Applications**.
1. For **GitLab Web IDE**, select **Edit**.
1. Enter the OAuth callback URL.
   You can enter multiple URLs separated by newlines.

### Workhorse dependency

DETAILS:
**Offering:** GitLab Self-Managed

On GitLab Self-Managed, [Workhorse](../../../development/workhorse/_index.md) must be installed
and running in front of the GitLab Rails server.
Otherwise, you might encounter issues when you open the Web IDE or
use certain features like Markdown preview.

For more information about this dependency,
see [features that rely on Workhorse](../../../development/workhorse/gitlab_features.md#5-web-ide).

### Report a problem

To report a problem, [create a new issue](https://gitlab.com/gitlab-org/gitlab-web-ide/-/issues/new)
with the following information:

- The error message
- The full error details
- How often the problem occurs
- Steps to reproduce the problem

If you're on a paid tier, you can also [contact Support](https://about.gitlab.com/support/#contact-support) for help.
