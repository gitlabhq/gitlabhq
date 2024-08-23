---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in Visual Studio."
---

# GitLab extension for Visual Studio

The [GitLab extension](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio)
integrates GitLab with Visual Studio for Windows. GitLab for Visual Studio supports
[GitLab Duo Code Suggestions](../../user/project/repository/code_suggestions/index.md).

This project shows a status icon in the status bar:

![The status bar in Visual Studio.](../img/visual_studio_status_bar_v17_4.png)

| Icon | Status | Meaning |
| :--- | :----- | :------ |
| **{tanuki-ai}** | **Ready** | You've configured and enabled GitLab Duo, and using a language that supports Code Suggestions. |
| **{tanuki-ai-off}** | **Not configured** | You haven't entered a personal access token, or using a language that Code Suggestions doesn't support. |
| ![The status icon for fetching Code Suggestions.](../img/code_suggestions_loading_v17_4.svg) | **Loading suggestion** | GitLab Duo is fetching Code Suggestions for you. |
| ![The status icon for a Code Suggestions error.](../img/code_suggestions_error_v17_4.svg) | **Error** | GitLab Duo has encountered an error. |

## Download the extension

Download the extension from the
[Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio).

The extension requires:

- Visual Studio 2022, either AMD64 or Arm64.
- GitLab version 16.1 and later.
  - GitLab Duo Code Suggestions requires GitLab version 16.8 or later.
- You are not using Visual Studio for Mac, as it is unsupported.

## Configure the extension

After you download and install the extension, you must configure it.

Prerequisites:

- GitLab Duo [is available and configured](../../user/gitlab_duo/turn_on_off.md) for your project.
- Your project must use one of the
  [supported languages](../../user/project/repository/code_suggestions/supported_extensions.md#supported-languages).

To do this:

1. Install the extension from the Visual Studio Marketplace, and enable it.
1. In GitLab, create a [GitLab personal access token](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)
   with the `api` and `read_user` scopes.
   1. Copy the token. _For security reasons, this value is never displayed again, so you must copy this value now._
1. Open Visual Studio.
   1. On the top bar, go to **Tools > Options > GitLab**.
   1. For **Access Token**, paste in your token. The token is not displayed, nor is it accessible to others.
   1. For **GitLab URL** field, provide the URL of your GitLab instance. For GitLab SaaS, use `https://gitlab.com`.

No new additional data is collected to enable this feature. Private non-public GitLab customer data is not used as training data.
Learn more about [Google Vertex AI Codey APIs Data Governance](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance).

### Customize keyboard shortcuts

This extension provides these custom commands:

| Command name                   | Default keyboard shortcut | Feature |
|--------------------------------|---------------------------|---------|
| `GitLab.ToggleCodeSuggestions` | not applicable            | Enable or disable automated code suggestions. |

You can access the extension's custom commands with keyboard shortcuts, which you can customize:

1. On the top bar, go to **Tools > Options**.
1. Go to **Environment > Keyboard**. Commands exposed by this extension are prefixed with `GitLab.`.
1. Select a command, and assign it a keyboard shortcut.

## Report issues with the extension

Report any issues, bugs, or feature requests in the
[`gitlab-visual-studio-extension` issue queue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues).

## Related topics

- [About the Create:Editor Extensions Group](https://handbook.gitlab.com/handbook/engineering/development/dev/create/editor-extensions/)
- [Open issues for this plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/)
- [View source code](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension)

## Troubleshooting

For troubleshooting information, see the
[extension's troubleshooting page](visual_studio_troubleshooting.md).
