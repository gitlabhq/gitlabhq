---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Command-line interface tool that brings the GitLab Duo Agent Platform to your terminal.
title: GitLab Duo CLI (`duo`)
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- [Default LLM](../duo_agent_platform/model_selection.md#default-models)
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as [experiment](../../policy/development_stages_support.md#experiment) in GitLab 18.9.
- [Added](https://gitlab.com/gitlab-org/cli/-/merge_requests/2838) to the GitLab CLI as an experiment in `glab` 1.87.0, during the GitLab 18.9 release.
- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.68.0) model selection option and environment variable in GitLab Duo CLI 8.68.0, during the GitLab 18.10 release.
- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.76.0) model selection slash command in GitLab Duo CLI 8.76.0, during the GitLab 18.10 release.
- [Changed](https://gitlab.com/groups/gitlab-org/-/work_items/19716) from experiment to beta in GitLab 18.11.
- Environment variable and option to enable user-level Agent Skills [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0) in GitLab Duo CLI 8.83.0 as an [experiment](../../policy/development_stages_support.md#experiment), during the GitLab 19.0 release.
- Approve tool for session option [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2129) in GitLab 19.0.
  - Introduced in [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.80.0) 8.80.0.
- `/exit` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.88.0) in GitLab Duo CLI 8.88.0, during the GitLab 19.0 release.
- `/doctor` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.94.0) in GitLab Duo CLI 8.94.0, during the GitLab 19.0 release.
- `/skills` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.81.0) in GitLab Duo CLI 8.81.0, during the GitLab 19.0 release.
- `/mcp` slash command [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0) in GitLab Duo CLI 8.95.0, during the GitLab 19.0 release.
- Settings panel [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.90.0) in GitLab Duo CLI 8.90.0, during the GitLab 19.0 release.
- `AI_AGENT` environment variable [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0) in GitLab Duo CLI 8.95.0, during the GitLab 19.0 release.
- Pattern-based tool approval [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21850) in GitLab 19.1.
  - Introduced in [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.101.0) 8.101.0.
- System notifications [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.105.0) in GitLab Duo CLI 8.105.0, during the GitLab 19.1 release.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/work_items/19717) as GitLab Duo CLI 9.0.0 in GitLab 19.2.
- Pattern-based tool approval [removed](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3699) on July 10, 2026.
  - Removed in [GitLab Duo CLI](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.3.0) 9.3.0.

{{< /history >}}

The GitLab Duo CLI is a command-line interface tool that brings [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md)
to your terminal. Available for use with any operating system and editor, use the CLI to ask complex
questions about your codebase and to autonomously perform actions on your behalf.

The GitLab Duo CLI can help you:

- Understand your codebase structure, cross-file functionality, and individual code snippets.
- Build, modify, refactor, and modernize code.
- Troubleshoot errors and fix code issues.
- Automate CI/CD configuration, troubleshoot pipeline errors, and optimize pipelines.
- Perform multi-step development tasks autonomously.

> [!note]
> The GitLab Duo CLI is now generally available. Update to
> GitLab Duo CLI 9.0.0 or later for the full generally available experience.

The GitLab Duo CLI offers two modes:

- Interactive mode: Provides a chat experience similar to GitLab Duo Chat in the GitLab UI or in
  editor extensions. Supports build and plan modes.
- Headless mode: Enables non-interactive use in runners, scripts, and other automated workflows.

It also supports [custom instructions](../duo_agent_platform/customize/_index.md) set for
the GitLab Duo Agent Platform, including `chat-rules.md`, `AGENTS.md`, and `SKILL.md` files.

## Prerequisites

- GitLab 19.2 or later.
- The [prerequisites for GitLab Duo Agent Platform](../duo_agent_platform/_index.md#prerequisites).

> [!note]
> If you are on GitLab 18.11 to 19.1, you can use the latest version of the GitLab Duo CLI by turning on [beta and experimental features](../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features).

## Turn GitLab Duo CLI access on or off

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242250) in GitLab 19.2.

{{< /history >}}

By default, GitLab Duo CLI access is turned on.

On GitLab Self-Managed and GitLab Dedicated, you can turn GitLab Duo CLI access on or off for an instance.

Prerequisites:

- You must be an administrator.

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo CLI**, select or clear the **Turn on GitLab Duo CLI access** checkbox.
1. Select **Save changes**.

## Set up the GitLab Duo CLI

You can use the GitLab Duo CLI through the [GitLab CLI](https://docs.gitlab.com/cli/) (`glab`). With the GitLab CLI, you get access to other GitLab features and you only need to authenticate once, using OAuth and or a personal access token.

Alternatively, you can install and use the GitLab Duo CLI (`duo`) as a standalone AI tool, authenticating
separately with a personal access token.

Both setups support interactive and headless modes, along with all GitLab Duo CLI options, commands
and functionality.

### With the GitLab CLI

Prerequisites:

- [GitLab CLI](https://docs.gitlab.com/cli/) 1.107.0 or later.
- GitLab CLI is [authenticated](https://docs.gitlab.com/cli/#authenticate-with-gitlab).

To set up the GitLab Duo CLI for use through the GitLab CLI:

1. Run the `glab` command for the GitLab Duo CLI:

   ```shell
   glab duo cli
   ```

1. Follow the prompts to install the GitLab Duo CLI binary.

The GitLab CLI automatically handles authentication, so you can start using the GitLab Duo CLI
immediately.

### Without the GitLab CLI

To use the GitLab Duo CLI as a standalone tool, install it and then authenticate.

#### Install

To install the GitLab Duo CLI as a compiled binary, download and run the install script.

On macOS and Linux:

```shell
bash <(curl --fail --silent --show-error --location "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.sh")
```

On Windows:

```shell
irm "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.ps1" | iex
```

#### Authenticate

> [!note]
> If `glab` is already installed and authenticated on your system when you first run `duo`, `duo`
> automatically uses `glab` as a credential helper. You do not need to authenticate separately. This
> requires `glab` 1.85.2 or later and `duo` 8.68.0 or later.
>
> If you authenticated `duo` before this feature was available and want to use `glab` as a
> credential helper instead, delete your authentication settings from `~/.gitlab/storage.json`.

Prerequisites:

- A [personal access token](../profile/personal_access_tokens.md) with `api` permissions.

To authenticate:

1. Run `duo` in your terminal. The first time you run the GitLab Duo CLI, a configuration screen
   appears.
1. Enter a **GitLab Instance URL** and then press <kbd>Enter</kbd>:
   - For GitLab.com, enter `https://gitlab.com`.
   - For GitLab Self-Managed or GitLab Dedicated, enter your instance URL.
1. For **GitLab Token**, enter your personal access token.
1. To save and exit the CLI, press <kbd>Enter</kbd>.
1. To restart the CLI, run `duo` in your terminal.

To modify the configuration after initial setup, use `duo config edit`.

#### Authenticate with environment variables

Prerequisites:

- A [personal access token](../profile/personal_access_tokens.md) with `api` permissions.

To authenticate with environment variables:

1. Set `GITLAB_TOKEN` or `GITLAB_OAUTH_TOKEN` to your personal access token.

   ```shell
   export GITLAB_TOKEN="<your-personal-access-token>"
   ```

1. Optional. Set `GITLAB_BASE_URL` or `GITLAB_URL` to your custom GitLab instance URL, for example `https://gitlab.example.com`. The default is `https://gitlab.com`.

   ```shell
   export GITLAB_BASE_URL="<your-instance-url>"
   ```

This method is useful for headless mode, CI/CD pipelines, and scripted workflows
where interactive authentication is not possible.

## Use the GitLab Duo CLI

Prerequisites:

- A [default GitLab Duo namespace](../profile/preferences.md#namespace-resolution-in-your-local-environment)
  set, or an open project that has GitLab Duo access.

### Interactive mode

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

#### Switch between build and plan modes

In interactive mode, you can switch the GitLab Duo CLI between two modes as you work:

| Mode                 | Permissions | How it works                                                                  |
|----------------------|-------------|-------------------------------------------------------------------------------|
| Build mode (default) | Read-write  | GitLab Duo can execute tasks and make changes to your project.               |
| Plan mode            | Read-only   | GitLab Duo can analyze your project and create plans without making changes. |

For example, start by discussing a problem with GitLab Duo in plan mode. When you're ready, switch
to build mode and instruct GitLab Duo to implement the plan.

The GitLab Duo CLI displays the current mode under the `>` prompt. To switch between modes, press
<kbd>Tab</kbd>.

#### Slash commands

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
For more information, see [custom slash commands](#custom-slash-commands).

#### Settings

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

#### System notifications

The GitLab Duo CLI can send a system notification when a session needs your attention
(for example, when it finishes a task or requires a tool approval) while the terminal window
is not focused.

Notifications are controlled by the **Notifications** setting in the [settings panel](#settings):

- `auto` (default): Send a system notification when the terminal is unfocused.
- `disabled`: Never send system notifications.

#### Tool approvals

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

### Headless mode

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

## Hooks

{{< details >}}

- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2209) as an [experiment](../../policy/development_stages_support.md#experiment) in GitLab Duo CLI 8.95.0, during the GitLab 19.1 release.

{{< /history >}}

Use hooks to run custom commands at specific points in the GitLab Duo CLI lifecycle.

For example, you can inject additional context into every new chat session by running
a script that gathers information about your environment.

The GitLab Duo CLI supports hooks at two levels:

- User-level (global): Apply to all of your projects.
- Project-level: Apply only to a specific project. Project-level hooks are disabled by default to
  prevent running arbitrary code from checked-out repositories.

When both user-level and project-level `hooks.json` files exist, the CLI merges the hooks and runs
the user-level ones first.

> [!note]
> For security reasons, sensitive environment variables (`GITLAB_TOKEN`, `GITLAB_OAUTH_TOKEN`, `CI_JOB_TOKEN`) are excluded from hook processes.

### Hook execution

When a hook runs, the GitLab Duo CLI:

1. Sends a JSON object to the command's standard input with session metadata:

   ```json
   {
     "session_id": "abc-123",
     "cwd": "/path/to/project",
     "transcript_path": "",
     "hook_event_name": "SessionStart",
     "source": "startup"
   }
   ```

1. Sets environment variables `DUO_SESSION_ID` and `DUO_PROJECT_DIR` for the
   hook process.
1. Collects the command's standard output as additional context for the session.

The hook can return plain text on standard output, or a JSON object:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Your context string here"
  }
}
```

If the hook exits with a non-zero status or times out, it is logged as a warning
but does not block the session from starting.

### Create hooks

The GitLab Duo CLI supports the `SessionStart` event, which runs when a new session starts or an existing
session resumes.

To create a hook:

1. Create a `hooks.json` file:
   - For a user-level hook:
     - On Linux or macOS, create the file at `~/.gitlab/duo/hooks.json`.
     - On Windows, create the file at `%APPDATA%\GitLab\duo\hooks.json`.
   - For a project-level hook, create the file in the root of your project: `<project>/.gitlab/duo/hooks.json`.
1. Define your hooks in the file.
   - Create a matcher group for each `SessionStart` event source that should trigger the hook (`startup`
     or `resume`).
   - Each matcher group has an optional regex `matcher` value and an array of command hooks:

     | Field | Description |
     |-------|-------------|
     | `matcher` | Optional. Regex tested against the event source (`startup` or `resume` for `SessionStart`). Omit to match all. |
     | `hooks[].type` | Must be `"command"`. |
     | `hooks[].command` | A shell command to execute. |
     | `hooks[].timeout` | Optional. Timeout in seconds. Default: 30. |

   - For example:

     ```json
     {
       "hooks": {
         "SessionStart": [
           {
             "matcher": "startup",
             "hooks": [
               {
                 "type": "command",
                 "command": "cat ~/.my-coding-preferences.md",
                 "timeout": 10
               }
             ]
          }
         ]
       }
     }
     ```

1. If you have project-level hooks, enable them when you start the GitLab Duo CLI:

   {{< tabs >}}

   {{< tab title="glab" >}}

   ```shell
   glab duo cli --enable-project-hooks
   ```

   {{< /tab >}}

   {{< tab title="duo" >}}

   ```shell
   duo --enable-project-hooks
   ```

   {{< /tab >}}

   {{< /tabs >}}

   Alternatively, set the environment variable:

   ```shell
   export GITLAB_ENABLE_PROJECT_HOOKS=true
   ```

## Custom slash commands

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/3617) in GitLab Duo CLI 9.2.0, during the GitLab 19.2 release.

{{< /history >}}

Create custom slash commands for prompts you use frequently.

The GitLab Duo CLI supports custom slash commands at two levels:

- User-level: Apply to all of your projects.
- Project-level: Apply only to a specific project.

If a user-level command and a project-level command share the same name, the project-level command
takes precedence. Custom slash commands cannot override built-in slash commands or
[Agent Skills slash commands](../duo_agent_platform/customize/agent_skills.md#expose-skills-as-slash-commands).

### Create a custom slash command

To create a custom slash command, you create a Markdown file.

The filename is the command name, and the file content is the prompt.

For example, a file named `daily.md` creates the `/daily` command:

1. Create a `commands` directory:
   - For a project-level command, create the directory in the root of your project:
     `<project>/.agents/commands/`.
   - For a user-level command, use one of the following locations:
     - To keep your commands with your other GitLab Duo customization files:
       - On Linux or macOS, create the directory at `~/.gitlab/duo/commands/`.
       - On Windows, create the directory at `%APPDATA%\GitLab\duo\commands\`.
       - If you have set `GLAB_CONFIG_DIR` or `XDG_CONFIG_HOME`, use `$GLAB_CONFIG_DIR/commands/`
         or `$XDG_CONFIG_HOME/gitlab/duo/commands/`. If both are set, `GLAB_CONFIG_DIR` takes
         priority.
     - To share commands with other AI tools:
       - On Linux or macOS, create the directory at `~/.agents/commands/`.
       - On Windows, create the directory at `%USERPROFILE%\.agents\commands\`.
1. In the directory, create a Markdown file.
   Use the command name as the filename.
   Command names must start with a letter or number, and can contain only letters, numbers,
   hyphens, and underscores.
1. Add the prompt to the file.
1. Optional. Add a `description` field in YAML front matter at the top of the file.
   The description appears next to the command in the slash command menu.

   For example, a `/daily` command defined in `daily.md`:

   ```markdown
   ---
   description: Prepare a daily report
   ---

   Use `glab todo list` to fetch my open TODO items. Give me a concise morning report ranked by priority.
   ```

1. Restart the GitLab Duo CLI. The CLI discovers custom slash commands when it starts.

### Use a custom slash command

In interactive mode, enter the slash command at the prompt and press <kbd>Enter</kbd>.
The GitLab Duo CLI sends the file content as the prompt.

Any text you enter after the command name is added to the end of the prompt.

Use this to customize what the custom slash command does.

For example, `/daily prioritize my milestone deliverables`.

## Reference

Use these options, commands, and environment variables when you start or run the GitLab Duo CLI.

For more details and the most up-to-date list, see the
[GitLab Duo CLI reference](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md).

### Options

The GitLab Duo CLI supports these options:

- `-C, --cwd <path>`: Change the working directory.
- `-h, --help` : Display help for the GitLab Duo CLI or a specific command. For example, `duo --help` or
  `duo run --help`.
- `--log-level <level>`: Set the logging level (`debug`, `info`, `warn`, `error`).
- `-v`, `--version`: Display version information.
- `--enable-global-skills`: (Experimental) Enable [user-level Agent Skills](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills).
- `--enable-project-hooks`: (Experimental) Enable loading project-level [hooks](#hooks).
- `--model <model>`: Select the AI model to use for the session.

Additional options for headless mode:

- `--ai-context-items <contextItems>`: JSON-encoded array of additional context items for reference.
- `--existing-session-id <sessionId>`: ID of an existing session to resume.
- `--gitlab-auth-token <token>`: Authentication token for a GitLab instance.
- `--gitlab-base-url <url>`: Base URL of a GitLab instance (default: `https://gitlab.com`).

### Commands

The following commands are available for each setup:

{{< tabs >}}

{{< tab title="glab" >}}

- `glab duo cli`: Start interactive mode.
- `glab duo cli log`: View and manage logs.
  - `glab duo cli log last`: Open the last log file.
  - `glab duo cli log list`: List all log files.
  - `glab duo cli log tail <args...>`: Display the tail of the last log file.
    Supports standard tail arguments.
  - `glab duo cli log clear`: Remove all existing log files.
- `glab duo cli run`: Start headless mode.

{{< /tab >}}

{{< tab title="duo" >}}

- `duo`: Start interactive mode.
- `duo config`: Manage the configuration and authentication settings.
- `duo log`: View and manage logs.
  - `duo log last`: Open the last log file.
  - `duo log list`: List all log files.
  - `duo log tail <args...>`: Display the tail of the last log file.
    Supports standard tail arguments.
  - `duo log clear`: Remove all existing log files.
- `duo run`: Start headless mode.

{{< /tab >}}

{{< /tabs >}}

### Environment variables

You can configure the GitLab Duo CLI using environment variables:

- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTP authentication password.
- `DUO_WORKFLOW_GIT_HTTP_USER`: Git HTTP authentication username.
- `GITLAB_BASE_URL` or `GITLAB_URL`: GitLab instance URL.
- `GITLAB_DUO_MODEL`: AI model to use for the session.
- `GITLAB_ENABLE_GLOBAL_SKILLS`: (Experimental) Enable [user-level Agent Skills](../duo_agent_platform/customize/agent_skills.md#create-user-level-skills).
- `GITLAB_ENABLE_PROJECT_HOOKS`: (Experimental) Enable loading project-level [hooks](#hooks).
- `GITLAB_OAUTH_TOKEN` or `GITLAB_TOKEN`: Authentication token.
- `LOG_LEVEL`: Logging level.

When the GitLab Duo CLI runs a command on your behalf, it sets the `AI_AGENT` environment variable
in that process. Scripts and tools can read `AI_AGENT` to detect that they are running in an
AI-driven execution.

## Proxy and custom certificate configuration

If your network uses an HTTPS-intercepting proxy or requires custom SSL certificates,
you might need additional configuration.

### Proxy configuration

The GitLab Duo CLI respects standard proxy environment variables:

- `HTTP_PROXY` or `http_proxy`: Proxy URL for HTTP requests.
- `HTTPS_PROXY` or `https_proxy`: Proxy URL for HTTPS requests.
- `NO_PROXY` or `no_proxy`: Comma-separated list of hosts to exclude from proxying.

### Custom SSL certificates

If your organization uses a custom Certificate Authority (CA), for an HTTPS-intercepting proxy or similar, you might encounter certificate errors.

```plaintext
Error: unable to verify the first certificate
Error: self-signed certificate in certificate chain
```

To resolve certificate errors, use one of the following methods:

- Use the system certificate store (recommended):
  - If your CA certificate is installed in your operating system's certificate store, configure
    Node.js to use it. Requires Node.js 22.15.0, 23.9.0, or 24.0.0 and later.
  - If you run the GitLab Duo CLI in a container, install the CA certificate in the container's
    system store, not the host system store.

  ```shell
  export NODE_OPTIONS="--use-system-ca"
  ```

- Specify a CA certificate file:
  - For older Node.js versions, or when the CA certificate is not in the system store, point Node.js
    to the certificate file directly. The file must be in PEM format.
  - If you run the GitLab Duo CLI in a container, set the path to a location in the container.
    Use a volume mount to provide the certificate file.

  ```shell
  export NODE_EXTRA_CA_CERTS=/path/to/custom-ca.pem
  ```

### Ignore certificate errors

If you still encounter certificate errors, you can disable certificate verification.

> [!warning]
> Disabling certificate verification is a security risk.
> You should not disable verification in production environments.

Certificate errors alert you to potential security breaches, so you should disable certificate verification only when you are confident that it is safe to do so.

Prerequisites:

- You verified the certificate chain in your browser, or your administrator
  confirmed that this error is safe to ignore.

To disable certificate verification:

```shell
export NODE_TLS_REJECT_UNAUTHORIZED=0
```

## Update the GitLab Duo CLI

To manually update the GitLab Duo CLI to the latest version, run the command for your setup:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo cli --update
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
npm install --global @gitlab/duo-cli@latest
```

{{< /tab >}}

{{< /tabs >}}

## Contribute to the GitLab Duo CLI

For information on contributing to the GitLab Duo CLI, see the
[development guide](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/development.md).

## Related topics

- [Security considerations for editor extensions](../../editor_extensions/security_considerations.md)
- [GitLab Duo CLI reference](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
- [Customize GitLab Duo Agent Platform](../duo_agent_platform/customize/_index.md)
- [GitLab Duo Agent Platform sessions](../duo_agent_platform/sessions/_index.md)
