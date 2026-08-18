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

Prerequisites:

- A [default GitLab Duo namespace](../profile/preferences.md#namespace-resolution-in-your-local-environment)
  set, or an open project that has GitLab Duo access.

You can use the GitLab Duo CLI in two modes:

- Interactive mode: Provides a chat experience similar to GitLab Duo Chat in the GitLab UI or in
  editor extensions. Supports build and plan modes.
- Headless mode: Enables non-interactive use in runners, scripts, and other automated workflows.

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

### Switch between build and plan modes

In interactive mode, you can switch the GitLab Duo CLI between two modes as you work:

| Mode                 | Permissions | How it works                                                                  |
|----------------------|-------------|-------------------------------------------------------------------------------|
| Build mode (default) | Read-write  | GitLab Duo can execute tasks and make changes to your project.               |
| Plan mode            | Read-only   | GitLab Duo can analyze your project and create plans without making changes. |

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

{{< /history >}}

In interactive mode, use slash commands to configure the GitLab Duo CLI and perform
actions. Enter a slash command at the prompt and press <kbd>Enter</kbd>.

The following slash commands are available:

| Command     | Description                                          |
|-------------|------------------------------------------------------|
| `/copy`     | Copy the last GitLab Duo response to the clipboard.  |
| `/doctor`   | Show diagnostics for the GitLab Duo CLI environment. |
| `/exit`     | Exit the GitLab Duo CLI.                             |
| `/feedback` | Submit a bug report or feature request.              |
| `/help`     | Display a list of available slash commands.          |
| `/mcp`      | View configured MCP servers and their status.        |
| `/model`    | Switch the AI model for the current session.         |
| `/new`      | Start a new chat session.                            |
| `/sessions` | Browse, search, and switch sessions.                 |
| `/settings` | Open the settings panel.                             |
| `/skills`   | List available Agent Skills in the current project.  |

You can also create your own slash commands.
For more information, see [custom slash commands](customize.md#custom-slash-commands).

### Settings

{{< history >}}

- Settings panel [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.90.0) in GitLab Duo CLI 8.90.0, during the GitLab 19.0 release.

{{< /history >}}

To change a setting:

1. In interactive mode, type `/settings` and press <kbd>Enter</kbd>.
1. Use the arrow keys to navigate the list of settings.
1. To change the selected setting, press <kbd>Enter</kbd> or <kbd>Space</kbd>.
1. To close the panel, press <kbd>Escape</kbd>.

Changes persist across sessions.

The following settings are available:

| Setting                  | Description                                                                                       |
|--------------------------|---------------------------------------------------------------------------------------------------|
| **Telemetry**            | Send anonymous usage data to improve GitLab Duo.                                                  |
| **Enable global skills** | (Experimental) Discover [user-level Agent Skills](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills) from `~/.agents/skills/` and `~/.gitlab/duo/skills/`. A restart is required for changes to take effect. |
| **Notifications**        | Control [system notifications](#system-notifications) (`auto` or `disabled`).                     |

### System notifications

{{< history >}}

- System notifications [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.105.0) in GitLab Duo CLI 8.105.0, during the GitLab 19.1 release.

{{< /history >}}

The GitLab Duo CLI can send a system notification when a session needs your attention
(for example, when it finishes a task or requires a tool approval) while the terminal window
is not focused.

Notifications are controlled by the **Notifications** setting in the [settings panel](#settings):

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

- [GitLab Duo CLI complete reference](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
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
