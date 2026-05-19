---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Use the GitLab for VS Code extension to handle common GitLab tasks directly in VS Code.
title: Install and set up the GitLab for VS Code extension
---

To use the GitLab for VS Code extension, install the extension, connect to GitLab, and then
configure it as needed.

## Install the extension

Choose the installation method that meets your needs:

- For standard VS Code, install from the [Visual Studio Marketplace](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).
- For unofficial VS Code versions, install from [Open VSX Registry](https://open-vsx.org/extension/GitLab/gitlab-workflow).
- For secure local development, install in a Visual Studio Code Dev Container.

### Install in a Visual Studio Code Dev Container

For added security, set up the extension and use GitLab Duo in a containerized development
environment using [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers).

Prerequisites:

- [Docker](https://www.docker.com/products/docker-desktop/) is installed and running.
- The Visual Studio Code [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
  extension is installed in VS Code.

To install the extension in a VS Code Dev Container:

1. Run the **Dev Containers: Add Dev Container Configuration Files** command from the Command
   Palette.
1. Add the GitLab extension to the configuration file:

   ```json
   // .devcontainer/devcontainer.json
   {
   "name": "My Project",
   "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
   "customizations": {
      "vscode": {
         "extensions": [
         "GitLab.gitlab-workflow"
         ]
      }
   }
   }
   ```

1. Run the **Dev Containers: Open Folder in Container** command to open your project in a VS Code
   Dev Container. VS Code automatically installs the extension inside the container.

## Connect to GitLab

After you install the extension, authenticate and then connect your project to a repository on
GitLab.

### Authenticate with GitLab

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CHANGELOG.md#release--6470-2025-09-26) OAuth authentication for GitLab Self-Managed and GitLab Dedicated in GitLab for VS Code 6.47.0 during the GitLab 18.3 release.

{{< /history >}}

{{< tabs >}}

{{< tab title="GitLab.com" >}}

Prerequisites:

- For authentication using PAT, a [personal access token](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) with the `api` scope.

To authenticate with GitLab:

1. Open the Command Palette:
   - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type `GitLab: Authenticate` and press <kbd>Enter</kbd>.
1. Select your GitLab instance URL from the options or enter one manually.
   - If you enter one manually, in **URL to GitLab instance**, paste the full URL,
     including the `http://` or `https://`. Press <kbd>Enter</kbd> to confirm.
1. Select an authentication method, **OAuth** or **PAT**.
   - For OAuth, follow the prompts to sign in and authenticate.
   - For PAT, follow the prompts to create a token or enter an existing one to authenticate.

{{< /tab >}}

{{< tab title="GitLab Self-Managed and GitLab Dedicated" >}}

Prerequisites:

- For authentication using OAuth, the application ID for an [OAuth application for VS Code](../../administration/settings/editor_extensions.md#vs-code).
- For authentication using PAT, a [personal access token](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) with the `api` scope.

To use OAuth, first configure the OAuth application login:

1. Open the Command Palette:
   - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type `Preferences: Open User Settings` and press <kbd>Enter</kbd>.
1. Select **Settings** > **Extensions** > **GitLab** > **Authentication**.
1. Under **OAuth Client IDs**, select **Add Item**.
1. Select **Key** and enter the GitLab instance URL.
1. Select **Value** and enter the ID of the OAuth application.

To authenticate with GitLab:

1. Open the Command Palette:
   - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Type `GitLab: Authenticate` and press <kbd>Enter</kbd>.
1. Select your GitLab instance URL from the options or enter one manually.
   - If you enter one manually, in **URL to GitLab instance**, paste the full URL,
     including the `http://` or `https://`. Press <kbd>Enter</kbd> to confirm.
1. Select an authentication method, **OAuth** or **PAT**.
   - For OAuth, follow the prompts to sign in and authenticate.
   - For PAT, follow the prompts to create a token or enter an existing one to authenticate.
{{< /tab >}}

{{< /tabs >}}

The extension matches your Git repository remote URL with the GitLab instance URL you specified
for your token. If you have multiple accounts or projects, you can choose the one you want to use.

> [!note]
> If your GitLab instance or network uses a custom SSL setup,
> you can configure the extension to support self-signed certificates. For more information, see
> [using the extension with self-signed certificates](ssl.md).

### Connect to your repository

To connect to your GitLab repository from VS Code:

1. In VS Code, on the top menu, select **Terminal** > **New Terminal**.
1. Clone your repository: `git clone <repository>`.
1. Change to the directory where your repository was cloned and check out your branch:
   `git checkout <branch_name>`.
1. Ensure your project is selected:
   1. In the left sidebar, select **GitLab** ({{< icon name="tanuki" >}}).
   1. Select the project name. If you have multiple projects, select the one you want to work with.
1. In the terminal, ensure your repository is configured with a remote: `git remote -v`. The results
   should look similar to:

   ```plaintext
   origin  git@gitlab.com:gitlab-org/gitlab.git (fetch)
   origin  git@gitlab.com:gitlab-org/gitlab.git (push)
   ```

   If no remote is defined, or you have multiple remotes:

   1. In the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
   1. On the **Source Control** label, right-click and select **Repositories**.
   1. Next to your repository, select the ellipsis ({{< icon name=ellipsis_h >}}), then
      **Remote** > **Add Remote**.
   1. Select **Add remote from GitLab**.
   1. Choose a remote.

The extension shows information in the VS Code status bar if both:

- Your project has a pipeline for the last commit.
- Your current branch is associated with a merge request.

## Configure the extension

To configure settings, go to **Settings** > **Extensions** > **GitLab**.

### Configure accounts and projects

After you authenticate and connect to your repository, the extension automatically associates your
GitLab account and project based on your Git repository configuration.

In some environments, you might need additional configuration to persist your credentials.

#### Store tokens in environment variables

If you often delete your VS Code storage, such as in Gitpod containers, store your authentication
tokens in [VS Code environment variables](https://code.visualstudio.com/docs/editor/variables-reference#_environment-variables).
Environment variables persist when you delete your VS Code storage.

Set these variables before you start VS Code:

- `GITLAB_WORKFLOW_INSTANCE_URL`: Your GitLab instance URL. For example, `https://gitlab.com`.
- `GITLAB_WORKFLOW_TOKEN`: Your personal access token.

If you configure a token for the same GitLab instance in the extension, the extension token
overrides the environment variable.

#### Switch accounts

The extension uses one account for each [VS Code workspace](https://code.visualstudio.com/docs/editor/workspaces)
(window). It automatically selects the account when:

- You authenticate with only one GitLab account in the extension.
- All workspaces in your VS Code window use the same GitLab account, based on the `git remote`
  configuration.

If multiple GitLab accounts exist and the extension cannot determine which account to use, it adds
**Multiple GitLab Accounts** ({{< icon name="question-o" >}}) to the status bar. To select a GitLab
account, select the status bar item and follow the prompts.

Alternatively, you can use the Command Palette:

1. Open the Command Palette:
   - For macOS, press <kbd>Command</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.
1. Run the command `GitLab: Select Account for this Workspace`.
1. Select an account from the list.

#### Select a project

The extension uses your Git repository remote to determine which GitLab project to associate with
your VS Code workspace.

When your Git repository has multiple remotes that point to different GitLab projects, the extension
cannot determine which one to use. For example:

- `origin`: `git@gitlab.com:gitlab-org/gitlab-vscode-extension.git`
- `personal-fork`: `git@gitlab.com:myusername/gitlab-vscode-extension.git`

In these cases, the extension adds a **(multiple projects)** label to the status bar.

To select a project:

1. In the left sidebar, select **GitLab** ({{< icon name="tanuki" >}}).
1. Expand **Issues and merge requests**.
1. Select the line containing **(multiple projects, click to select)**.
1. Select a project from the list.

The **Issues and merge requests** list updates with your selected project's information.

#### Change the project

To change your project selection:

1. In the left sidebar, select **GitLab** ({{< icon name="tanuki" >}}).
1. Expand **Issues and merge requests**.
1. Select the project.
1. Next to the project name, select **Clear Selected Project**
   ({{< icon name="close-xs" >}}).

### Configure GitLab Duo

GitLab Duo features are enabled by default in VS Code when you meet the prerequisites:

- For agentic features, you meet the prerequisites for [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md#prerequisites).
- You have GitLab Duo [turned on](../../user/gitlab_duo/turn_on_off.md).
- For flows, you have [foundational flows turned on](../../user/duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off).
- For agents, you have [foundational agents turned on](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off)
  and [custom agents enabled](../../user/duo_agent_platform/agents/custom.md#enable-an-agent), as
  needed.
- Your project is in a [group namespace](../../user/namespace/_index.md).
- You have a [default GitLab Duo namespace](../../user/profile/preferences.md#namespace-resolution-in-your-local-environment)
  set or have a project open that has GitLab Duo access.
- For GitLab Duo Code Suggestions, you [meet the additional prerequisites](../../user/project/repository/code_suggestions/set_up.md#prerequisites).

To approve Agentic Chat tools once per session instead of individually,
see [tool approvals](../../user/gitlab_duo_chat/agentic_chat.md#tool-approvals).

#### Turn off GitLab Duo

To turn off GitLab Duo features in VS Code:

1. In VS Code, open the Settings editor:
   - For macOS, press <kbd>Command</kbd>+<kbd>,</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>,</kbd>.
1. Select **Extensions** > **GitLab** > **GitLab Duo**.
1. Find the feature you want to turn off and clear the checkbox.

### Configure telemetry

GitLab for VS Code uses the telemetry settings in Visual Studio Code to send usage and error
information to GitLab. To turn on or customize telemetry in Visual Studio Code:

1. In VS Code, open the Settings editor:
   - For macOS, press <kbd>Command</kbd>+<kbd>,</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>,</kbd>.
1. Select **Application** > **Telemetry**.
1. For **Telemetry Level**, select the data you want to share:
   - `all`: Sends usage data, general error telemetry, and crash reports.
   - `error`: Sends general error telemetry, and crash reports.
   - `crash`: Sends OS-level crash reports.
   - `off`: Disables all telemetry data in Visual Studio Code.
1. Save your changes.
