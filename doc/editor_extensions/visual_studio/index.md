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

## Install the extension

Download the extension from the
[Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio)
and install it.

The extension requires:

- Visual Studio 2022, either AMD64 or Arm64.
- The [IntelliCode](https://visualstudio.microsoft.com/services/intellicode/) component for Visual Studio.
- GitLab version 16.1 and later.
  - GitLab Duo Code Suggestions requires GitLab version 16.8 or later.
- You are not using Visual Studio for Mac, as it is unsupported.

No new additional data is collected to enable this feature. Private non-public GitLab customer data is not used as training data.
Learn more about [Google Vertex AI Codey APIs Data Governance](https://cloud.google.com/vertex-ai/generative-ai/docs/data-governance).

### Authenticate with GitLab

After you download and install the extension, connect it to your GitLab account.

Prerequisites:

- GitLab Duo [is available and configured](../../user/gitlab_duo/turn_on_off.md) for your project.
- You have created a [GitLab personal access token](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) with the `api` and `read_user` scope, and copied that token.
- Your project must use one of the
  [supported languages](../../user/project/repository/code_suggestions/supported_extensions.md#supported-languages).

To do this:

1. In Visual Studio, on the top bar, go to **Tools > Options > GitLab**.
1. In the **Access Token** field, paste in your token. The token is not displayed, nor is it accessible to others.
1. In the **GitLab URL** text box, enter the URL of your GitLab instance. For GitLab SaaS, use `https://gitlab.com`.

### Configure the extension

This extension provides these custom commands, which you can configure:

| Command name                   | Default keyboard shortcut | Feature |
|--------------------------------|---------------------------|---------|
| `GitLab.ToggleCodeSuggestions` | not applicable            | Enable or disable automated Code Suggestions. |

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
- [GitLab Language Server documentation](../language_server/index.md)

## Troubleshooting

For troubleshooting information, see the
[extension's troubleshooting page](visual_studio_troubleshooting.md).
