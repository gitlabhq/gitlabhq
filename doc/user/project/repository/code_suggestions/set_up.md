---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Set up Code Suggestions."
---

# Configure Code Suggestions

Before you can use Code Suggestions, you must set it up.

## Set up Code Suggestions

Prerequisites:

- You should have the latest version of GitLab.

To set up Code Suggestions:

1. Configure GitLab Duo.
1. Check that your preferred language is supported.
1. Configure your editor extension.

### Configure GitLab Duo

1. [Create a personal access token](../../../profile/personal_access_tokens.md#create-a-personal-access-token)
   with at least the [`ai_features` scope](../../../profile/personal_access_tokens.md#personal-access-token-scopes).
1. [Turn on GitLab Duo](../../../gitlab_duo/turn_on_off.md).
1. Purchase the [GitLab Duo Pro add-on subscription](../../../../subscriptions/subscription-add-ons.md).
1. [Get a Duo Pro seat assigned to you](../../../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats),
   either individually or [in bulk](../../../../subscriptions/subscription-add-ons.md#assign-and-remove-gitlab-duo-seats-in-bulk).
1. For GitLab self-managed, you must:

   - Fulfill the [prerequisites](../../../gitlab_duo/turn_on_off.md#prerequisites).
   - Have GitLab 16.8 or later.
   - [Configure proxy settings](../../../../subscriptions/subscription-add-ons.md#configure-network-and-proxy-settings).

For more information, see how to [Get started with GitLab Duo](../../../get_started/getting_started_gitlab_duo.md).

### Check language support

Code Suggestions supports a range of programming languages and development concepts.

Check that Code Suggestions [supports your preferred language](supported_extensions.md#supported-languages).

Different IDEs support different languages.

### Configure editor extension

NOTE:
You might have already completed this as part of [getting started with GitLab Duo](../../../get_started/getting_started_gitlab_duo.md).

To use Code Suggestions, if you are not using the [GitLab Web IDE](../../web_ide/index.md), you must
configure one of the following [editor extensions](supported_extensions.md#supported-editor-extensions)
to then use an equivalent IDE:

- GitLab Workflow for VS Code.
- Visual Studio GitLab Extension.
- GitLab Duo Plugin for JetBrains.
- `gitlab.vim` plugin for Neovim.

Regardless of the extension you use, you must:

1. Install the extension in your IDE.
1. Authenticate with GitLab from the IDE. You can use either OAuth or the [personal access token](../../../profile/personal_access_tokens.md#create-a-personal-access-token) you created when configuring GitLab Duo.
1. Configure the extension.

#### GitLab Workflow for VS Code

1. [Install the extension](../../../../editor_extensions/visual_studio_code/index.md#install-the-extension).
1. [Authenticate with GitLab](../../../../editor_extensions/visual_studio_code/index.md#authenticate-with-gitlab).
1. [Configure the extension](../../../../editor_extensions/visual_studio_code/index.md#configure-the-extension).

#### Visual Studio GitLab extension

1. [Install the extension](../../../../editor_extensions/visual_studio/index.md#install-the-extension).
1. [Authenticate with GitLab](../../../../editor_extensions/visual_studio/index.md#authenticate-with-gitlab).
1. [Configure the extension](../../../../editor_extensions/visual_studio/index.md#configure-the-extension).

#### GitLab Duo plugin for JetBrains IDEs

1. [Install the extension](../../../../editor_extensions/jetbrains_ide/index.md#install-the-extension).
1. [Configure the extension](../../../../editor_extensions/jetbrains_ide/index.md#configure-the-extension).
1. [Authenticate with GitLab](../../../../editor_extensions/jetbrains_ide/index.md#authenticate-with-gitlab).

#### `gitlab.vim` plugin for Neovim

1. [Install the extension](../../../../editor_extensions/neovim/index.md#install-the-extension).
1. [Authenticate with GitLab](../../../../editor_extensions/neovim/index.md#authenticate-with-gitlab).
1. [Configure the extension](../../../../editor_extensions/neovim/index.md#configure-the-extension).
1. [Enable Omni Completion](../../../../editor_extensions/neovim/index.md#configure-omni-completion).

## Turn off Code Suggestions

How you turn off Code Suggestions differs depending on which editor extension and IDE you use.

NOTE:
When turning off Code Suggestions, you cannot turn off code generation and code completion separately.

### VS Code

To turn off Code Suggestions in the UI:

1. In VS Code, go to **Code > Settings > Extensions**.
1. Select **Manage** (**{settings}**) **> Settings**.
1. Clear the **GitLab Duo Code Suggestions** checkbox.

You can also [set `gitlab.duoCodeSuggestions.enabled` to `false` in the VS Code `settings.json` file](../../../../editor_extensions/visual_studio_code/settings.md#extension-settings).

### Visual Studio

To turn Code Suggestions on or off without uninstalling the extension,
[assign a keyboard shortcut to the `GitLab.ToggleCodeSuggestions` custom command](../../../../editor_extensions/visual_studio/index.md#configure-the-extension).

To disable or uninstall the extension, see the [Microsoft Visual Studio documentation on uninstalling or disabling the extension](https://learn.microsoft.com/en-us/visualstudio/ide/finding-and-using-visual-studio-extensions?view=vs-2022#uninstall-or-disable-an-extension).

### JetBrains IDEs

The process to disable GitLab Duo, including Code Suggestions, is the same
regardless of which JetBrains IDE you use.

1. In your JetBrains IDE, go to settings and select the plugins menu.
1. Under the installed plugins, find the GitLab Duo plugin.
1. Disable the plugin.

For more information, see the [JetBrains product documentation](https://www.jetbrains.com/help/).

### Neovim

1. Go to the [Neovim `defaults.lua` settings file](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/lua/gitlab/config/defaults.lua).
1. Under `code_suggestions`, change the `enabled =` flag to `false`:

   ```lua
   code_suggestions = {
   ...
    enabled = false,
   ```

### Turn off GitLab Duo

Alternatively, you can [turn off GitLab Duo](../../../../user/gitlab_duo/turn_on_off.md#turn-off-gitlab-duo-features) (which includes Code Suggestions) completely for a group, project, or instance.
