---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Use the GitLab Workflow extension for VS Code to handle common GitLab tasks directly in VS Code."
title: Install and set up the GitLab Workflow extension for VS Code
---

To install the GitLab Workflow extension for VS Code:

- [Go to the Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
  and install and enable the extension.
- If you use an unofficial version of VS Code, install the
  extension from the [Open VSX Registry](https://open-vsx.org/extension/GitLab/gitlab-workflow).

## Connect to GitLab

After you download and install the extension, connect it to your GitLab account.

### Create a personal access token

If you are on GitLab Self-Managed, create a personal access token.

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access tokens**.
1. Select **Add new token**.
1. Enter a name, description, and expiration date.
1. Select the `api` scope.
1. Select **Create personal access token**.

### Authenticate with GitLab

Then authenticate with GitLab.

1. Open the Command Palette:
   - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - For Windows or Linux, press <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type `GitLab: Authenticate` and press <kbd>Enter</kbd>.
1. Select your GitLab instance URL from the options, or enter one manually.
   - If you enter one manually, in **URL to GitLab instance**, paste the full URL,
     including the `http://` or `https://`. Press <kbd>Enter</kbd> to confirm.
1. Authenticate with GitLab. For `GitLab.com`, you can use the OAuth authentication method.
   If you don't use OAuth, use a personal access token.

The extension matches your Git repository remote URL with the GitLab instance URL you specified
for your token. If you have multiple accounts or projects, you can choose the one you want to use.
For more details, see [Switch GitLab accounts in VS Code](_index.md#switch-gitlab-accounts-in-vs-code).

The extension shows information in the VS Code status bar if both:

- Your project has a pipeline for the last commit.
- Your current branch is associated with a merge request.

## Configure the extension

To configure settings, go to **Settings > Extensions > GitLab Workflow**.

By default, Code Suggestions and GitLab Duo Chat are enabled, so if you have
the GitLab Duo add-on and a seat assigned, you should have access.

### Code security

To configure the code security settings, go to **Settings > Extensions > GitLab Workflow > Code
Security**.

- To enable SAST scanning of the active file, select the **Enable Real-time SAST scan** checkbox.
- Optional. To enable SAST scanning of the active file when you save it, select the
  **Enable scanning on file save** checkbox.
