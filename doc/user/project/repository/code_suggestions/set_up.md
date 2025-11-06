---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Set up Code Suggestions.
title: Set up Code Suggestions
---

{{< history >}}

- Changed to include GitLab Duo Core in GitLab 18.0.

{{< /history >}}

You can use Code Suggestions in several different IDEs.
To set up Code Suggestions, follow the instructions for your IDE.

## Prerequisites

To use Code Suggestions, you need:

- A GitLab Duo Core, Pro, or Enterprise add-on.
- A Premium or Ultimate subscription.
- If you have GitLab Duo Pro or Enterprise, an assigned seat.
- If you have GitLab Duo Core, [IDE features turned on](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off).
- To confirm that Code Suggestions [supports your preferred language](supported_extensions.md#supported-languages-by-ide).
  Different IDEs support different languages.

## Configure editor extension

Code Suggestions is part of an editor extension. To use Code Suggestions:

1. Install the extension in your IDE.
1. Authenticate with GitLab from the IDE. You can use either OAuth or a personal access token.
1. Configure the extension.

Follow these steps for your IDE:

- [Visual Studio Code](../../../../editor_extensions/visual_studio_code/setup.md)
- [Visual Studio](../../../../editor_extensions/visual_studio/setup.md)
- [GitLab Duo plugin for JetBrains IDEs](../../../../editor_extensions/jetbrains_ide/setup.md)
- [`gitlab.vim` plugin for Neovim](../../../../editor_extensions/neovim/setup.md)
- [GitLab for Eclipse](../../../../editor_extensions/eclipse/setup.md)

## Turn on Code Suggestions

Code Suggestions is turned on [if you meet the prerequisites](#prerequisites).
To confirm, open your IDE and verify if Code Suggestions works.

### VS Code

To verify that Code Suggestions is turned on in VS Code:

1. In VS Code, go to **Settings** > **Extensions** > **GitLab Workflow**.
1. Select **Manage** ({{< icon name="settings" >}}).
1. Ensure that **GitLab › Duo Code Suggestions: Enabled** is selected.
1. Optional. For **GitLab › Duo Code Suggestions: Enabled Supported Languages**,
   select the languages you want to suggest or generate code for.
1. Optional. For **GitLab › Duo Code Suggestions: Additional Languages**, add other languages you'd like to use.

### Visual Studio

To verify that Code Suggestions is turned on in Visual Studio:

1. In Visual Studio, on the bottom status bar, point to the GitLab icon.
1. When Code Suggestions is enabled, the icon tooltip shows `GitLab code suggestions are enabled.`
1. If Code Suggestions are not enabled, on the top bar select **Extensions** > **GitLab** > **Toggle Code Suggestions** to enable it.

### JetBrains IDEs

To verify that Code Suggestions is turned on in JetBrains IDEs:

1. In your IDE, on the top bar, select your IDE's name, then select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. In the **Features** section, ensure that **Enable Code Suggestions** and **Enable GitLab Duo Chat** are selected.
1. Select **OK** or **Save**.

#### Add a custom certificate for Code Suggestions

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/561) in GitLab Duo 2.10.0.

{{< /history >}}

GitLab Duo attempts to detect [trusted root certificates](https://www.jetbrains.com/help/idea/ssl-certificates.html)
without configuration on your part. If needed, configure your JetBrains IDE to allow the GitLab Duo plugin
to use a custom SSL certificate when connecting to your GitLab instance.

To use a custom SSL certificate with GitLab Duo:

1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Under **Connection**, enter the **URL to GitLab instance**.
1. To verify your connection, select **Verify setup**.
1. Select **OK** or **Save**.

If your IDE detects a non-trusted SSL certificate:

1. The GitLab Duo plugin displays a confirmation dialog.
1. Review the SSL certificate details shown.
   - Confirm the certificate details match the certificate shown when you connect to GitLab in your browser.
1. If the certificate matches your expectations, select **Accept**.

To review certificates you've already accepted:

1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, select **Tools** > **Server Certificates**.
1. Select [**Server Certificates**](https://www.jetbrains.com/help/idea/settings-tools-server-certificates.html).
1. Select a certificate to view it.

### Eclipse

{{< alert type="note" >}}

To enable GitLab Duo Code Suggestions, open an Eclipse project. If you open a single file, Code Suggestions is disabled for all file types.

{{< /alert >}}

To verify that Code Suggestions is turned on in Eclipse:

1. In Eclipse, open your GitLab project.
1. In the Eclipse bottom toolbar, select the GitLab icon.

**Code Suggestions** displays as "Enabled".

### Neovim

Code Suggestions provides a LSP (Language Server Protocol) server, to support the built-in
<kbd>Control</kbd>+<kbd>x</kbd>, <kbd>Control</kbd>+<kbd>o</kbd> Omni Completion key mapping:

| Mode     | Key mappings                          | Type      | Description |
|----------|---------------------------------------|-----------|-------------|
| `INSERT` | <kbd>Control</kbd>+<kbd>x</kbd>, <kbd>Control</kbd>+<kbd>o</kbd> | Built-in | Requests completions from GitLab Duo Code Suggestions through the language server. |
| `NORMAL` | `<Plug>(GitLabToggleCodeSuggestions)` | `<Plug>`  | Toggles Code Suggestions on or off for the current buffer. Requires [configuration](../../../../editor_extensions/neovim/setup.md#configure-plug-key-mappings). |

## Verify that Code Suggestions is on

All editor extensions from GitLab, except Neovim, add an icon to your IDE's status bar.
For example, in Visual Studio:

![The status bar in Visual Studio.](img/visual_studio_status_bar_v17_4.png)

| Icon | Status | Meaning |
| :--- | :----- | :------ |
| {{< icon name="tanuki-ai" >}} | **Ready** | You've configured and enabled GitLab Duo, and you're using a language that supports Code Suggestions. |
| {{< icon name="tanuki-ai-off" >}} | **Not configured** | You haven't entered a personal access token, or you're using a language that Code Suggestions doesn't support. |
| ![The status icon for fetching Code Suggestions.](img/code_suggestions_loading_v17_4.svg) | **Loading suggestion** | GitLab Duo is fetching Code Suggestions for you. |
| ![The status icon for a Code Suggestions error.](img/code_suggestions_error_v17_4.svg) | **Error** | GitLab Duo has encountered an error. |

## Turn off Code Suggestions

The process for turning off Code Suggestions is different for each IDE.

{{< alert type="note" >}}

You cannot turn off code generation and code completion separately.

{{< /alert >}}

### VS Code

To turn off Code Suggestions in VS Code:

1. Go to **Code** > **Settings** > **Extensions**.
1. Select **Manage** ({{< icon name="settings" >}}) > **Settings**.
1. Clear the **GitLab Duo Code Suggestions** checkbox.

Instead, you can [set `gitlab.duoCodeSuggestions.enabled` to `false` in the VS Code `settings.json` file](../../../../editor_extensions/visual_studio_code/settings.md#extension-settings).

### Visual Studio

To turn Code Suggestions on or off without uninstalling the extension,
[assign a keyboard shortcut to the `GitLab.ToggleCodeSuggestions` custom command](../../../../editor_extensions/visual_studio/setup.md#configure-the-extension).

To disable or uninstall the extension, see the
[Microsoft Visual Studio documentation on uninstalling or disabling the extension](https://learn.microsoft.com/en-us/visualstudio/ide/finding-and-using-visual-studio-extensions?view=vs-2022#uninstall-or-disable-an-extension).

### JetBrains IDEs

The process to disable GitLab Duo, including Code Suggestions, is the same
regardless of which JetBrains IDE you use.

1. In your JetBrains IDE, go to settings and select the plugins menu.
1. Under the installed plugins, find the GitLab Duo plugin.
1. Disable the plugin.

For more information, see the [JetBrains product documentation](https://www.jetbrains.com/help/).

### Eclipse

To disable Eclipse Code Suggestions for a project:

1. In the Eclipse bottom toolbar, select the GitLab icon.
1. Select **Disable Code Suggestions** to disable Code Suggestions for the current project.

To disable Eclipse Code Suggestions for a specific language:

1. In the Eclipse bottom toolbar, select the GitLab icon.
1. Select **Show Settings**.
1. Scroll down to the **Code Suggestions Enabled Languages** section and clear the checkbox for the language you wish to disable.

### Neovim

1. Go to the [Neovim `defaults.lua` settings file](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/lua/gitlab/config/defaults.lua).
1. Under `code_suggestions`, change the `enabled =` flag to `false`:

   ```lua
   code_suggestions = {
   ...
    enabled = false,
   ```

### Turn off GitLab Duo

Alternatively, you can [turn off GitLab Duo](../../../gitlab_duo/turn_on_off.md) (which includes Code Suggestions) completely for a group, project, or instance.
