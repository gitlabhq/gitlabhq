---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Connect and use GitLab Duo in Visual Studio.
title: Install and set up the GitLab extension for Visual Studio
---

To get the extension, use any of these methods:

- Inside Visual Studio, select **Extensions** from the activity bar, and search for `GitLab`.
- From the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio).
- From GitLab, either from the
  [list of releases](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/releases), or by
  [downloading the latest version](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/releases/permalink/latest/downloads/GitLab.Extension.vsix)
  directly.

The extension requires:

- Visual Studio 2022 version 17.6 or later, either AMD64 or Arm64.
- The [IntelliCode](https://visualstudio.microsoft.com/services/intellicode/) component for Visual Studio.
- GitLab version 16.1 and later.
  - GitLab Duo Code Suggestions requires GitLab version 16.8 or later.
- You are not using Visual Studio for Mac, as it is unsupported.

No new additional data is collected to enable this feature. Private non-public GitLab customer data is not used as training data.
Learn more about [Google Vertex AI Codey APIs Data Governance](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance).

## Connect to GitLab

After you download and install the extension, connect it to your GitLab account.

### Create a personal access token

If you are on GitLab Self-Managed, create a personal access token.

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access tokens**.
1. Select **Add new token**.
1. Enter a name, description, and expiration date.
1. Select the `api` and `read_user` scope.
1. Select **Create personal access token**.

### Authenticate with GitLab

Then authenticate with GitLab.

1. In Visual Studio, on the top bar, go to **Tools > Options > GitLab**.
1. In the **Access Token** field, paste in your token. The token is not displayed, nor is it accessible to others.
1. In the **GitLab URL** text box, enter the URL of your GitLab instance. For GitLab.com, use `https://gitlab.com`.

## Configure the extension

This extension provides custom commands that you can use with GitLab. Most commands don't have
default keyboard shortcuts to avoid conflicts with your existing Visual Studio configuration.

| Command name                          | Default keyboard shortcut                   | Description |
|---------------------------------------|---------------------------------------------|-------------|
| `GitLab.ToggleCodeSuggestions`        | None                                        | Turn on or turn off Code Suggestions. |
| `GitLab.OpenDuoChat`                  | None                                        | Open GitLab Duo Chat.  |
| `GitLab.GitLabDuoNextSuggestions`     | <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>N</kbd> | Switch to the next code suggestion. |
| `GitLab.GitLabDuoPreviousSuggestions` | None                                        | Switch to the previous code suggestion. |
| `GitLab.GitLabExplainTerminalWithDuo` | <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>E</kbd> | Explain selected text in the terminal. |
| `GitLabDuoChat.ExplainCode`           | None                                        | Explain selected code. |
| `GitLabDuoChat.Fix`                   | None                                        | Fix issues for the selected code. |
| `GitLabDuoChat.GenerateTests`         | None                                        | Generate tests for the selected code. |
| `GitLabDuoChat.Refactor`              | None                                        | Refactor selected code. |

You can access the extension's custom commands with keyboard shortcuts, which you can customize:

1. On the top bar, go to **Tools > Options**.
1. Go to **Environment > Keyboard**. Search for `GitLab.`.
1. Select a command, and assign it a keyboard shortcut.
