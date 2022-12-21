---
stage: Create
group: Editor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Web IDE Beta **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95169) in GitLab 15.7 [with a flag](../../../administration/feature_flags.md) named `vscode_web_ide`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `vscode_web_ide`. On GitLab.com, this feature is available. The feature is not ready for production use.

As announced in [this blog post](https://about.gitlab.com/blog/2022/05/23/the-future-of-the-gitlab-web-ide/),
the current implementation of the [Web IDE](../web_ide/index.md) is being replaced
with an implementation inspired by Visual Studio Code. This effort is still under
development. For updates, see [this epic](https://gitlab.com/groups/gitlab-org/-/epics/7683).

To connect a remote machine to the Web IDE Beta, see [Remote Development](../remote_development/index.md).

## Enable the Web IDE Beta

To use the Web IDE Beta on a self-managed GitLab instance,
ensure that the `vscode_web_ide` feature flag
[is enabled](../../../administration/feature_flags.md).

On GitLab.com, this feature is available by default. However, you can
[stop using it if you choose](#stop-using-the-web-ide-beta).

## Use the Web IDE Beta

To open the Web IDE Beta from anywhere in the UI:

- Use the <kbd>.</kbd> [keyboard shortcut](../../shortcuts.md).

You can also open the Web IDE Beta when viewing a file, the repository file list,
or a merge request.

### Use when viewing a file or the repository file list

To open the Web IDE Beta from a file or the repository file list:

- On the top right of the page, select **Open in Web IDE**.

If **Open in Web IDE** is not visible:

1. Next to **Edit** or **Gitpod**, select the down arrow (**{chevron-lg-down}**).
1. From the list, select **Open in Web IDE**.
1. Select **Open in Web IDE**.

### Use when viewing a merge request

To open the Web IDE Beta from a merge request:

1. Go to your merge request.
1. In the upper right corner, select **Code > Open in Web IDE**.

## Open a file in the Web IDE Beta

To open any file by its name:

1. Press <kbd>Command</kbd>+<kbd>P</kbd>.
1. Enter the name of your file.

![fuzzy_finder_v15_7](img/fuzzy_finder_v15_7.png)

## Search across files

You can use VS Code to quickly search all files in the opened folder.

To search across files:

1. Press <kbd>Shift</kbd>+<kbd>Command</kbd>+<kbd>F</kbd>.
1. Enter your search term.

In the Web IDE Beta, only partial results from opened files are displayed.
Full file search is planned for a later date.

## View a list of changed files

To view a list of files you changed in the Web IDE Beta,
in the Activity Bar on the left, select **Source Control**.
Your `CHANGES`, `STAGED CHANGES`, and `MERGE CHANGES` are displayed.

For details, see the [VS Code documentation](https://code.visualstudio.com/docs/sourcecontrol/overview#_commit).

## Stop using the Web IDE Beta

If you do not want to use the Web IDE Beta, you can change your personal preferences.

1. On the top bar, in the top right corner, select your avatar.
1. Select **Preferences**.
1. In the **Web IDE** section, select the **Opt out of the Web IDE Beta** checkbox.
1. Select **Save changes**.

## Known issues

The [Web Terminal](../web_ide/index.md#interactive-web-terminals-for-the-web-ide)
and [Live Preview](../web_ide/index.md#live-preview) are not available in the Web IDE Beta.

These features might become available at a later date.

## Related topics

- [Remote Development](../remote_development/index.md)
- [Web IDE](../web_ide/index.md)
