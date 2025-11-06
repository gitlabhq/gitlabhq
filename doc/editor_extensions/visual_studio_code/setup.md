---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use the GitLab Workflow extension for VS Code to handle common GitLab tasks directly in VS Code.
title: Install and set up the GitLab Workflow extension for VS Code
---

To install the GitLab Workflow extension for VS Code:

- [Go to the Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
  and install and enable the extension.
- If you use an unofficial version of VS Code, install the
  extension from the [Open VSX Registry](https://open-vsx.org/extension/GitLab/gitlab-workflow).

## Connect to GitLab

After you download and install the extension, connect it to your GitLab account.

### Authenticate with GitLab

1. Open the Command Palette:
   - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type `GitLab: Authenticate` and press <kbd>Enter</kbd>.
1. Select your GitLab instance URL from the options, or enter one manually.
   - If you enter one manually, in **URL to GitLab instance**, paste the full URL,
     including the `http://` or `https://`. Press <kbd>Enter</kbd> to confirm.
1. Authenticate with GitLab using:
   - OAuth login after [configuring authentication](#authentication).
   - A new [personal access token](#create-a-personal-access-token).

The extension matches your Git repository remote URL with the GitLab instance URL you specified
for your token. If you have multiple accounts or projects, you can choose the one you want to use.
For more details, see [Switch GitLab accounts in VS Code](_index.md#switch-gitlab-accounts-in-vs-code).

### Connect to your repository

To connect to your GitLab repository from VS Code:

1. In VS Code, on the top menu, select **Terminal** > **New Terminal**.
1. Clone your repository: `git clone <repository>`.
1. Change to the directory where your repository was cloned and check out your branch: `git checkout <branch_name>`.
1. Ensure your project is selected:
   1. On the left sidebar, select **GitLab Workflow** ({{< icon name="tanuki" >}}).
   1. Select the project name. If you have multiple projects, select the one you want to work with.
1. In the terminal, ensure your repository is configured with a remote: `git remote -v`. The results should look similar to:

   ```plaintext
   origin  git@gitlab.com:gitlab-org/gitlab.git (fetch)
   origin  git@gitlab.com:gitlab-org/gitlab.git (push)
   ```

   If no remote is defined, or you have multiple remotes:

   1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
   1. On the **Source Control** label, right-click and select **Repositories**.
   1. Next to your repository, select the ellipsis ({{< icon name=ellipsis_h >}}), then **Remote** > **Add Remote**.
   1. Select **Add remote from GitLab**.
   1. Choose a remote.

The extension shows information in the VS Code status bar if both:

- Your project has a pipeline for the last commit.
- Your current branch is associated with a merge request.

## Configure the extension

To configure settings, go to **Settings** > **Extensions** > **GitLab Workflow**.
Settings can be configured at the user or workspace level.

By default, Code Suggestions and GitLab Duo Chat are enabled, so if you have
the GitLab Duo add-on and a seat assigned, you should have access.

### Authentication

Authenticate using a personal access token or logging in through an OAuth application.

#### Create a personal access token

If you are on GitLab Self-Managed or GitLab Dedicated, create a personal access token.

1. On the left sidebar, select your avatar. If you've [turned on the new navigation](../../user/interface_redesign.md#turn-new-navigation-on-or-off), this button is in the upper-right corner.
1. Select **Edit profile**.
1. On the left sidebar, select **Personal access tokens**.
1. Select **Add new token**.
1. Enter a name, description, and expiration date.
1. Select the `api` scope.
1. Select **Create personal access token**.

#### Use an OAuth application

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2738) in GitLab Workflow 6.47.0.

{{< /history >}}

To use OAuth authentication you must know the client ID of either:

- An instance-wide OAuth application managed by your instance administrator.
- A group-wide OAuth application managed by a group owner.
- A user OAuth application managed by yourself.

To configure OAuth application login:

1. Open the Command Palette:
   - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type `Preferences: Open User Settings` and press <kbd>Enter</kbd>.
1. Select **Settings** > **Extensions** > **GitLab Workflow** > **Authentication**.
1. Under **OAuth Client IDs**, select **Add Item**.
1. Select **Key** and enter the GitLab instance URL.
1. Select **Value** and enter the client ID of the OAuth application.

### Code security

To configure the code security settings, go to **Settings** > **Extensions** > **GitLab Workflow** > **Code Security**.

- To enable SAST scanning of the active file, select the **Enable Real-time SAST scan** checkbox.
- Optional. To enable SAST scanning of the active file when you save it, select the
  **Enable scanning on file save** checkbox.

### Install pre-release versions of the extension

GitLab publishes pre-release builds of the extension to the VS Code Extension Marketplace.

To install a pre-release build:

1. Open VS Code.
1. Under **Extensions** > **GitLab Workflow**, select **Switch to Pre-release Version**.
1. Select **Restart Extensions**.
   1. Alternatively **Reload Window** to refresh any outdated webviews after updating.
