---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting the GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

If you are working with the GitLab Duo Agent Platform in your Integrated Development Environment (IDE), you might encounter the following issues.

## General guidance

Start by ensuring that GitLab Duo is on and that you are properly connected.

- Ensure you meet [the prerequisites](_index.md#prerequisites).
- Ensure the branch you want to work in is checked out.
- Ensure you have turned on the necessary settings in the IDE.
- Ensure that [Admin mode is disabled](../../administration/settings/sign_in_restrictions.md#turn-off-admin-mode-for-your-session).

## Network issues

Your network might block the connection to the Agent Platform,
for example, by using a firewall. By default the Agent Platform uses a gRPC
(Google Remote Procedure Call) connection. The network must let HTTP/2 traffic through to
the service for gRPC to work.

gRPC can be [changed to a WebSocket connection](#use-websocket-connection-instead-of-grpc) in the IDE.

To confirm that you can connect to the Agent Platform service using gRPC:

1. In Google Chrome or Firefox, open Developer Tools and select the **Network** tab.
1. Right-click the column headers to show the **Protocol** column.
1. In the address bar, enter `https://duo-workflow-svc.runway.gitlab.net/DuoWorkflow/ExecuteWorkflow`.
1. Ensure the request was successful and the **Protocol** column includes `h2` in Chrome or `HTTP/2` in Firefox.

If the request fails or does not show the HTTP/2 protocol:

- A security system like Netskope or Zscaler might be configured to block or inspect traffic.
- The HTTP/2 protocol downgrades to HTTP/1.1, which prevents the Agent Platform from working correctly.

To correct this issue, ask your network administrator to put `https://duo-workflow-svc.runway.gitlab.net/DuoWorkflow/ExecuteWorkflow`
on the correct allowlist, or to exempt it from traffic inspection.

### Use WebSocket connection instead of gRPC

If your network conditions do not allow a gRPC connection, WebSocket is an alternative in
VS Code and JetBrains IDEs:

- In VS Code:
  1. Select **File** > **Preferences** > **Settings**
  1. Search for the setting **GitLab: Duo Agent Platform: Connection Type**, then select `WebSocket`.

- In JetBrains:
  1. On the top bar, select the main menu, then select **Settings**.
  1. On the left sidebar, select **Tools** > **GitLab Duo**.
  1. In the **GitLab Duo Agent Platform** > **Connection Type** section, select `WebSocket`.

## View debugging logs in VS Code

In VS Code, you can troubleshoot some issues by viewing debugging logs.

1. Open local debugging logs:
   - On macOS: <kbd>Command</kbd>+<kbd>,</kbd>
   - On Windows and Linux: <kbd>Control</kbd>+<kbd>,</kbd>
1. Search for the setting **GitLab: Debug** and enable it.
1. Open the language server logs:
   1. In VS Code, select **View** > **Output**.
   1. In the output panel at the bottom, in the upper-right corner,
      select **GitLab Workflow** or **GitLab Language Server** from the list.
1. Review for errors, warnings, connection issues, or authentication problems.

## VS Code configuration

You can try several things to ensure your repository is properly configured and connected in VS Code.

### View the project in the GitLab Workflow extension

Start by ensuring the correct project is selected in the GitLab Workflow extension for VS Code.

1. In VS Code, on the left sidebar, select **GitLab Workflow** ({{< icon name="tanuki" >}}).
1. Ensure the project is listed and selected.

If an error message appears next to the project name, select it to reveal what needs to be updated.

For example, you might have multiple repositories and need to select one, or there might be no repositories at all.

#### No Git repository

If your workspace doesn't have a Git repository initialized, you must create a new one:

1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
1. Select **Initialize Repository**.

When the repository is initialized, you should see the name in the **Source Control** view.

#### Git repository with no GitLab remote

You might have a Git repository but it's not properly connected to GitLab.

1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
1. On the **Source Control** label, right-click and select **Repositories**.
1. Next to your repository, select the ellipsis ({{< icon name=ellipsis_h >}}), then **Remote** > **Add Remote**.
1. Enter your GitLab project URL.
1. Select the newly added remote as your upstream.

#### Multiple GitLab remotes

Your repository might have multiple GitLab remotes configured.
To select the correct one:

1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
1. On the status bar, select the current remote name.
1. From the list, select the appropriate GitLab remote.
1. Ensure the selected remote belongs to a group namespace in GitLab.

#### Multiple GitLab projects

If your VS Code workspace contains multiple GitLab projects, you might want
to close all the projects you're not using.

To close projects:

1. On the left sidebar, select **Source Control** ({{< icon name="branch" >}}).
1. Ensure repositories are shown: on the **Source Control** label, right-click and select **Repositories**.
1. Right-click the repository you want to close and select **Close Repository**.

### Project not in a group namespace

GitLab Duo Agent Platform requires that projects belong to a group namespace.

To determine the namespace your project is in, [look at the URL](../namespace/_index.md#determine-which-type-of-namespace-youre-in).

If necessary, you can
[transfer your project to a group namespace](../../tutorials/move_personal_project_to_group/_index.md#move-your-project-to-a-group).

## Flows not visible in the UI

If you are trying to run a flow but it's not visible in the GitLab UI:

1. Ensure you have at least Developer role in the project.
1. Ensure GitLab Duo is [turned on and flows are allowed to execute](../gitlab_duo/turn_on_off.md).
1. Ensure the required feature flags, [`duo_workflow` and `duo_workflow_in_ci`](../../administration/feature_flags/_index.md), are enabled.

## IDE commands fail or run indefinitely

When using GitLab Duo Chat (Agentic) or the Software Development flow in your IDE,
GitLab Duo can get stuck in a loop or have difficulty running commands.

This issue can occur when you are using shell themes or integrations, like `Oh My ZSH!` or `powerlevel10k`.
When a GitLab Duo agent spawns a terminal, a theme or integration can prevent commands from running properly.

As a workaround, use a simpler theme for commands sent by agents.
[Issue 2070](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/2070) tracks improvements to this behavior so this workaround is no longer needed.

### Edit your `.zshrc` file

In VS Code and JetBrains IDEs, configure `Oh My ZSH!` or `powerlevel10k` to use a simpler
theme when it runs commands sent by an agent. You can use the environment variables exposed
by the IDEs to set these values.

Edit your `~/.zshrc` file to include this code:

```shell
# ~/.zshrc

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# ...

# Decide whether to load a full terminal environment,
# or keep it minimal for agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" || "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]]; then
  echo "IDE agentic environment detected, not loading full shell integrations"
else
  # Oh My ZSH
  source $ZSH/oh-my-zsh.sh
  # Theme: Powerlevel10k
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
  # Other integrations like syntax highlighting
fi

# Other setup, like PATH variables
```

### Edit your Bash shell

In VS Code or JetBrains IDEs, you can turn off advanced prompts in Bash, so that agents don't initiate them.
Edit your `~/.bashrc` or `~/.bash_profile` file to include this code:

```shell
# ~/.bashrc or ~/.bash_profile

# Decide whether to load a full terminal environment,
# or keep it minimal for Agentic AI in IDEs
if [[ "$TERM_PROGRAM" == "vscode" || "$TERMINAL_EMULATOR" == "JetBrains-JediTerm" ]]; then
  echo "IDE agentic environment detected, not loading full shell integrations"

  # Keep only essential settings for agents
  export PS1='\$ '  # Minimal prompt

else
  # Load full Bash environment

  # Custom prompt (e.g., Starship, custom PS1)
  if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
  else
    # ... Add your own PS1 variable
  fi

  # Load additional integrations
fi

# Always load essential environment variables and aliases

```

## Still having issues?

Contact your GitLab administrator for assistance.
