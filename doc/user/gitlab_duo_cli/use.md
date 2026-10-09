---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Use the GitLab Duo CLI in interactive and headless modes.
title: Use the GitLab Duo CLI
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can use the GitLab Duo CLI in two modes:

- Interactive mode: Provides a chat experience similar to GitLab Duo Chat in the GitLab UI or in
  editor extensions. Supports build, plan, and auto modes.
- Headless mode: Enables non-interactive use in runners, scripts, and other automated workflows.

## Prerequisites

- The GitLab Duo CLI installed and [set up](set_up.md).
- A [default GitLab Duo namespace](../profile/preferences.md#namespace-resolution-in-your-local-environment)
  set, or an open project that has access to GitLab Duo.

## Interactive mode

To use the GitLab Duo CLI in interactive mode:

1. Based on your setup, enter the command to start interactive mode:

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. The prompt `>` appears in your terminal window. After the prompt, enter your question or
   request and press <kbd>Enter</kbd>.

   For example:

   ```plaintext
   What is this repository about?

   Which issues need my attention?

   Help me implement issue 15.

   The pipelines in MR 23 are failing. Please help me fix them.
   ```

To cancel a response while the GitLab Duo CLI is working, press <kbd>Escape</kbd>.
The GitLab Duo CLI stops the current operation and returns to the prompt.

Use the <kbd>↑</kbd> key to view your prompt history, or <kbd>Control</kbd>+<kbd>R</kbd> to search it.

When you start a new session, the prompt placeholder might show a tip about a GitLab Duo CLI feature.

### Startup cards

{{< history >}}

- Welcome card [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.11.0) in GitLab Duo CLI 9.11.0, during the GitLab 19.4 release.
- `--startup-cards` option and `STARTUP_CARDS` environment variable [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.17.0) in GitLab Duo CLI 9.17.0, during the GitLab 19.4 release.
- Onboarding card [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.28.0) in GitLab Duo CLI 9.28.0, during the GitLab 19.5 release.

{{< /history >}}

Startup cards appear in your terminal when you start a new session in interactive mode:
an onboarding card on your first run, and a welcome card on later runs.
The cards do not appear when you resume an existing session.

Startup cards are enabled by default, but you can turn them off.

#### Onboarding card

The first time you run the GitLab Duo CLI on a machine, an onboarding card helps you
[connect MCP servers](#model-context-protocol-mcp-connections) and install
[plugins](customize.md#plugins) from the GitLab marketplace.

The card displays navigation hints to select and run the steps. Completed steps show a checkmark
with the number of connected MCP servers or installed plugins.

The card stays until you send your first prompt, even after you complete both steps.
It does not appear again on later runs.

#### Welcome card

Every time you start a new session, a welcome card appears by default.
You can turn off the card with the [**Show work items on session start**](#settings) setting.

The card suggests prompts to kick off common tasks and displays navigation hints for browsing
and running prompts. For example, when you work in a GitLab project, the suggested prompts are
built from your open merge requests and issues. Otherwise, the card shows generic examples.

When you select a prompt for one of your merge requests and its source branch exists, the
prompt tells GitLab Duo to check out that branch first.

If the [**Run suggested prompts as /goal sessions**](#settings) setting is enabled and your
instance is GitLab 19.3 or later, the prompt to address review feedback runs as a `/goal` session.

#### Hide the startup cards

Startup cards are enabled by default. To turn them off, set `--startup-cards` to `false`:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo cli --startup-cards false
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo --startup-cards false
```

{{< /tab >}}

{{< /tabs >}}

Alternatively, set the `STARTUP_CARDS` environment variable to `false`.
If you set both, the `--startup-cards` option takes precedence over the environment variable.

### Status bar

The bottom of the screen shows a status bar with:

- The current working directory and Git branch.
- The detected GitLab project and, if one exists, the open merge request for the current branch
  and its pipeline status.
- The progress of a running `/goal` session.
- The status of configured MCP servers.

### Switch modes

In interactive mode, you can switch the GitLab Duo CLI between modes as you work:

| Mode                 | Permissions | How it works                                                                  |
|----------------------|-------------|-------------------------------------------------------------------------------|
| Build mode (default) | Read-write  | GitLab Duo can execute tasks and make changes to your project.               |
| Plan mode            | Read-only   | GitLab Duo can analyze your project and create plans without making changes. |
| Auto mode (beta)     | Read-write  | GitLab Duo can use tools without asking for approval first. For more information, see [auto mode](#auto-mode). |

For example, start by discussing a problem with GitLab Duo in plan mode. When you're ready, switch
to build mode and instruct GitLab Duo to implement the plan.

The GitLab Duo CLI displays the current mode under the `>` prompt. To switch between modes, press
<kbd>Tab</kbd>.

### Slash commands

{{< history >}}

- `/exit` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.88.0) in GitLab Duo CLI 8.88.0, during the GitLab 19.0 release.
- `/doctor` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.94.0) in GitLab Duo CLI 8.94.0, during the GitLab 19.0 release.
- `/skills` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.81.0) in GitLab Duo CLI 8.81.0, during the GitLab 19.0 release.
- `/mcp` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0) in GitLab Duo CLI 8.95.0, during the GitLab 19.0 release.
- `/goal` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.17.0) in GitLab Duo CLI 9.17.0, during the GitLab 19.4 release, as a [beta](../../policy/development_stages_support.md#beta).
- `/goal` slash command [generally available](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.27.0) in GitLab Duo CLI 9.27.0, during the GitLab 19.5 release.
- `/compact` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.109.0) in GitLab Duo CLI 8.109.0, during the GitLab 19.2 release.
- `/export` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.11.0) in GitLab Duo CLI 9.11.0, during the GitLab 19.4 release.
- `/review` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.14.0) in GitLab Duo CLI 9.14.0, during the GitLab 19.4 release.
- `/whatsnew` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.20.0) in GitLab Duo CLI 9.20.0, during the GitLab 19.4 release.

{{< /history >}}

In interactive mode, use slash commands to configure the GitLab Duo CLI and perform
actions. Enter a slash command at the prompt and press <kbd>Enter</kbd>.

The following slash commands are available:

| Command     | Description                                          |
|-------------|------------------------------------------------------|
| `/compact`  | Compress the conversation history to save context space. |
| `/copy`     | Copy the last GitLab Duo response to the clipboard.  |
| `/doctor`   | Show diagnostics for the GitLab Duo CLI environment. |
| `/exit`     | Exit the GitLab Duo CLI.                             |
| `/export`   | Export the session as a portable JSON bundle.        |
| `/feedback` | Submit a bug report or feature request.              |
| `/goal`     | Start a session that works toward a goal. Requires GitLab 19.3 or later. |
| `/help`     | Display available shortcuts, modes, and slash commands. |
| `/mcp`      | View configured MCP servers and their status.        |
| `/model`    | Switch the AI model for the current session.         |
| `/new`      | Start a new chat session.                            |
| `/review`   | Review your changes with the code review subagent.   |
| `/sessions` | Browse, search, and switch sessions.                 |
| `/settings` | Open the settings panel.                             |
| `/skills`   | List available Agent Skills in the current project.  |
| `/whatsnew` | Show recent changes to the GitLab Duo CLI.           |

To close a panel or dialog that a slash command opens, press <kbd>Escape</kbd>.

You can also create your own slash commands.
For more information, see [custom slash commands](customize.md#custom-slash-commands).

### Settings

To view and change settings, type `/settings` in interactive mode.
For more information, see [GitLab Duo CLI settings](settings.md).

### System notifications

{{< history >}}

- System notifications [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.105.0) in GitLab Duo CLI 8.105.0, during the GitLab 19.1 release.

{{< /history >}}

The GitLab Duo CLI can send a system notification when a session needs your attention
(for example, when it finishes a task or requires a tool approval) while the terminal window
is not focused.

Notifications are controlled by the **Notifications** setting in the [settings panel](settings.md#settings-panel):

- `auto` (default): Send a system notification when the terminal is unfocused.
- `disabled`: Never send system notifications.

### Tool approvals

{{< history >}}

- Approve tool for session option [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2129) in GitLab 19.0.
  - Introduced in [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.80.0) 8.80.0.
- Pattern-based tool approval [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21850) in GitLab 19.1.
  - Introduced in [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.101.0) 8.101.0.
- Pattern-based tool approval [removed](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3699) on July 10, 2026.
  - Removed in [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.3.0) 9.3.0.

{{< /history >}}

When GitLab Duo needs to use a tool, it prompts you to approve before it begins. For example, when
it needs to read a file or run a command.

Your options are:

- **Approve**: GitLab Duo can use the tool once.
- **Approve for session**: GitLab Duo can use the tool with these arguments for the remainder of the
  session. Different arguments require additional approval.
- **Deny**: GitLab Duo cannot use the tool.

> [!note]
> To use the **Approve for session** option,
> your administrator must turn it on for your group or instance.
> For more information, see [tool approvals](../gitlab_duo_chat/agentic_chat.md#tool-approvals).

### Auto mode

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/618088) in GitLab 19.5 as a [beta](../../policy/development_stages_support.md#beta) with a [feature flag](../../administration/feature_flags/_index.md) named `duo_auto_mode`. Disabled by default.
  - Introduced in [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.22.0) 9.22.0.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/work_items/629172) in GitLab 19.5.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

In auto mode, GitLab Duo uses tools without asking for approval.
Where your settings allow it, GitLab Duo can perform the following actions:

- Run any shell command, including commands that delete files or change your system.
- Run `git` commands, including commits and pushes.
- Create or update issues, merge requests, and other GitLab resources.
- Run MCP tools and start flows.

Auto mode does not override [agent tool governance](../ai-governance/tool-governance.md).
Tools set to **Always Deny** stay blocked.

> [!warning]
> GitLab Duo can make mistakes.
> Any content that GitLab Duo reads, such as files, issues, merge requests, or web pages,
> might contain malicious instructions used for prompt injection.
> To limit the risk:
>
> - Use auto mode only in repositories you trust and on branches you can discard.
> - Do not use auto mode on devices or in shells that contain sensitive credentials.
> - Stay in the session and review all changes before merging.
> - Switch back to build mode when you do not need auto mode.
>
> For more information, see [security considerations for editor extensions](../../editor_extensions/security_considerations.md).

#### Turn on auto mode

The **Auto mode** setting is off by default.
Auto mode must be turned on for your group or project before you can use it.
Subgroups and projects inherit the setting from their parent group.

{{< tabs >}}

{{< tab title="Group" >}}

Prerequisites:

- The Owner role for the group.

To turn on auto mode for a group:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. From the **Auto mode** dropdown list, select one of the following options:
   - **On by default**: Auto mode is available. Subgroups and projects can turn it off.
   - **Off by default**: Auto mode is not available. Subgroups and projects can turn it on.
   - **Always off**: Auto mode is not available. Subgroups and projects cannot turn it on.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="Project" >}}

If a parent group has set auto mode to **Always off**, the project setting is locked and cannot be turned on.

Prerequisites:

- The Maintainer or Owner role for the project.

To turn on auto mode for a project:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn on the **Auto mode** toggle.
1. Select **Save changes**.

{{< /tab >}}

{{< /tabs >}}

#### Use auto mode

Prerequisites:

- GitLab Duo CLI 9.22.0 or later.
- Auto mode turned on for your project.

To use auto mode:

1. Start or restart the GitLab Duo CLI in your project to pick up the setting.
1. Press <kbd>Tab</kbd> until the mode under the `>` prompt shows `auto`.
1. Enter your prompt. Auto mode applies from that prompt onward.

To stop using auto mode, press <kbd>Tab</kbd> to switch to another mode.
The change applies to your next prompt.

Auto mode does not persist between sessions.
Each new or resumed session, including a session you start with `/new`, starts in build mode.

#### Troubleshooting auto mode

If `auto` does not appear when you press <kbd>Tab</kbd>:

1. Confirm that the **Auto mode** setting is turned on for your project.
1. Confirm that no parent group is set to **Always off**.
1. Restart the GitLab Duo CLI.

## Headless mode

> [!caution]
> Use headless mode with caution and in a controlled [sandbox environment](../../editor_extensions/security_considerations.md#use-development-containers-for-isolation).

To run a workflow in non-interactive mode, use the command for your setup:

{{< tabs >}}

{{< tab title="glab" >}}

Use `glab duo cli run`:

```shell
glab duo cli run --goal "Your goal or prompt here"
```

For example, you can run an ESLint command and pipe errors to the GitLab Duo CLI to resolve:

```shell
glab duo cli run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< tab title="duo" >}}

Use `duo run`:

```shell
duo run --goal "Your goal or prompt here"
```

For example, you can run an ESLint command and pipe errors to the GitLab Duo CLI to resolve:

```shell
duo run --goal "Fix these errors: $eslint_output"
```

{{< /tab >}}

{{< /tabs >}}

When you use headless mode, the GitLab Duo CLI:

- Bypasses manual tool approvals and automatically approves all tools for use.
- Does not maintain context from previous conversations.
  A new workflow starts every time you execute the `run` command.

## Provide images as context

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.27.0) in GitLab Duo CLI 9.27.0, during the GitLab 19.5 release.

{{< /history >}}

In interactive and headless mode, GitLab Duo can read images and use them as context.
You cannot attach an image to your prompt.
Instead, in your prompt, name an image file in the repository or an image attached to an issue or
merge request in the same project.

For more information about how to reference images and the image requirements, see
[provide images as context](../project/merge_requests/developer.md#provide-images-as-context).
For example prompts, see [use images as context](../project/merge_requests/developer.md#use-images-as-context).

## Select a model

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.68.0) model selection option and environment variable in GitLab Duo CLI 8.68.0, during the GitLab 18.10 release.
- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.76.0) model selection slash command in GitLab Duo CLI 8.76.0, during the GitLab 18.10 release.

{{< /history >}}

You can select a model for interactive mode or headless mode.

### For interactive mode

The model you select persists across sessions, and you can switch models
mid-conversation without losing context.

Prerequisites:

- GitLab Duo CLI 8.76.0 or later.

To select a model for interactive mode:

1. In interactive mode, type `/model` and press <kbd>Enter</kbd>.
1. Use the arrow keys to scroll through the list of available models, or enter a model name to
   filter the list.
1. Select a model and press <kbd>Enter</kbd> to switch to it.

### For headless mode

The model you select does not persist across sessions.

Prerequisites:

- GitLab Duo CLI 8.68.0 or later.

To select a model for headless mode:

1. Find the [`gitlab_identifier` for the model](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml).
1. When you run the GitLab Duo CLI, set the `--model` option or the `GITLAB_DUO_MODEL` environment
   variable to the `gitlab_identifier` value.

   {{< tabs >}}

   {{< tab title="glab" >}}

   Use the `--model` option:

   ```shell
   glab duo cli --model <gitlab_identifier_for_the_model>
   ```

   Use the `GITLAB_DUO_MODEL` environment variable:

   ```shell
   GITLAB_DUO_MODEL=<gitlab_identifier_for_the_model> glab duo cli
   ```

   For example, to use [`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448):

   ```shell
   glab duo cli --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex glab duo cli
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   Use the `--model` option:

   ```shell
   duo --model <gitlab_identifier_for_the_model>
   ```

   Use the `GITLAB_DUO_MODEL` environment variable:

   ```shell
   GITLAB_DUO_MODEL=<gitlab_identifier_for_the_model> duo
   ```

   For example, to use [`GPT-5-Codex - OpenAI`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/HEAD/ai_gateway/model_selection/models.yml#L448):

   ```shell
   duo --model gpt_5_codex
   ```

   ```shell
   GITLAB_DUO_MODEL=gpt_5_codex duo
   ```

   {{< /tab >}}

   {{< /tabs >}}

## Switch sessions

GitLab Duo Chat sessions store your conversation history and workflow data, and are shared across
the GitLab Duo CLI, the GitLab UI, and editor extensions.

For example, you can start a conversation in your browser and continue it in your terminal.

To browse and switch to a session:

1. In interactive mode, type `/sessions` and press <kbd>Enter</kbd>.
1. Use the arrow keys to scroll through the list of available sessions, or enter text to filter the
   list.
1. Select a session and press <kbd>Enter</kbd>.

To switch to a session in headless mode, use the `--existing-session-id` option.

## Model Context Protocol (MCP) connections

To connect the GitLab Duo CLI to local or remote MCP servers, use the same MCP configuration
as the GitLab IDE extensions. For instructions, see [configure MCP servers](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-mcp-servers).

## Related topics

- [GitLab Duo CLI complete reference](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/app/docs/cli-reference.md)
- [Security considerations for editor extensions](../../editor_extensions/security_considerations.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
- [Customize GitLab Duo Agent Platform](../duo_agent_platform/customize/_index.md)
- [GitLab Duo Agent Platform sessions](../duo_agent_platform/sessions/_index.md)

## Troubleshooting

When working with the GitLab Duo CLI, you might encounter the following issues.

### Certificate errors

You might encounter certificate errors:

```plaintext
Error: unable to verify the first certificate
Error: self-signed certificate in certificate chain
```

These errors occur if your organization uses a custom Certificate Authority (CA)
for an HTTPS-intercepting proxy or similar.

To resolve certificate errors, use one of the following methods:

- Use the system certificate store (recommended):
  1. If your CA certificate is installed in your operating system's certificate store, configure
     Node.js to use it. Requires Node.js 22.15.0, 23.9.0, or 24.0.0 and later.
  1. If you run the GitLab Duo CLI in a container, install the CA certificate in the container's
     system store, not the host system store.

     ```shell
     export NODE_OPTIONS="--use-system-ca"
     ```

- Specify a CA certificate file:
  1. For older Node.js versions, or when the CA certificate is not in the system store, point Node.js
     to the certificate file directly. The file must be in PEM format.
  1. If you run the GitLab Duo CLI in a container, set the path to a location in the container.
     Use a volume mount to provide the certificate file.

     ```shell
     export NODE_EXTRA_CA_CERTS=/path/to/custom-ca.pem
     ```

### Ignore certificate errors

If you still encounter certificate errors, you can disable certificate verification.

> [!warning]
> Disabling certificate verification is a security risk.
> You should not disable verification in production environments.

Certificate errors alert you to potential security breaches, so you should disable
certificate verification only when you are confident that disabling verification is safe.

Prerequisites:

- You verified the certificate chain in your browser, or your administrator
  confirmed that this error is safe to ignore.

To disable certificate verification:

```shell
export NODE_TLS_REJECT_UNAUTHORIZED=0
```
