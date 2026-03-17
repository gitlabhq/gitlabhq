---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo CLI (`duo`)
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< collapsible title="Model information" >}}

- [Default LLM](../duo_agent_platform/model_selection.md#default-models)
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as [experiment](../../policy/development_stages_support.md#experiment) in GitLab 18.9.
- [Added](https://gitlab.com/gitlab-org/cli/-/merge_requests/2838) to the GitLab CLI as an experiment in `glab` 1.87.0.

{{< /history >}}

The GitLab Duo CLI is a command-line interface tool that brings [GitLab Duo Chat (agentic)](../gitlab_duo_chat/agentic_chat.md)
to your terminal. Available for use with any operating system and editor, use `duo` to ask complex
questions about your codebase and to autonomously perform actions on your behalf.

The GitLab Duo CLI can help you:

- Understand your codebase structure, cross-file functionality, and individual code snippets.
- Build, modify, refactor, and modernize code.
- Troubleshoot errors and fix code issues.
- Automate CI/CD configuration, troubleshoot pipeline errors, and optimize pipelines.
- Perform multi-step development tasks autonomously.

The GitLab Duo CLI offers two modes:

- Interactive mode: Provides a chat experience similar to GitLab Duo Chat in the GitLab UI or in
  editor extensions.
- Headless mode: Enables non-interactive use in runners, scripts, and other automated workflows.

## Prerequisites

- Meet the [prerequisites for GitLab Duo Agent Platform](../duo_agent_platform/_index.md#prerequisites).

## Set up the GitLab Duo CLI

You can use the GitLab Duo CLI through the [GitLab CLI](https://docs.gitlab.com/cli/) (`glab`). With the GitLab CLI, you get access to other GitLab features and you only need to authenticate once, using OAuth and or a personal access token.

Alternatively, you can install and use the GitLab Duo CLI (`duo`) as a standalone AI tool, authenticating
separately with a personal access token.

Both setups support interactive and headless modes, along with all GitLab Duo CLI options, commands
and functionality.

### With the GitLab CLI

Prerequisites:

- [GitLab CLI](https://docs.gitlab.com/cli/) 1.87.0 or later
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

Install the GitLab Duo CLI as an npm package or compiled binary.

{{< tabs >}}

{{< tab title="npm package" >}}

Prerequisites:

- Node.js 22 or later.
- For GitLab Self-Managed with a self-signed certificate, either:
  - Node.js LTS 22.20.0 or later
  - Node.js 23.8.0 or later

To install the GitLab Duo CLI as an npm package, run:

```shell
npm install --global @gitlab/duo-cli
```

{{< /tab >}}

{{< tab title="Compiled binary" >}}

To install the GitLab Duo CLI as a compiled binary, download and run the install script.

On macOS and Linux:

```shell
bash <(curl --fail --silent --show-error --location "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.sh")
```

On Windows:

```shell
irm "https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/raw/main/packages/cli/scripts/install_duo_cli.ps1" | iex
```

{{< /tab >}}

{{< /tabs >}}

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

1. The prompt `Duo` appears in your terminal window. After the prompt, enter your question or
   request and press <kbd>Enter</kbd>.

   For example:

   ```plaintext
   What is this repository about?

   Which issues need my attention?

   Help me implement issue 15.

   The pipelines in MR 23 are failing. Please help me fix them.
   ```

### Headless mode

> [!caution]
> Use headless mode with caution and in a controlled sandbox environment.

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

## Model Context Protocol (MCP) connections

To connect the GitLab Duo CLI to local or remote MCP servers, use the same MCP configuration
as the GitLab IDE extensions. For instructions, see [configure MCP servers](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-mcp-servers).

## Options

The GitLab Duo CLI supports these options:

- `-C, --cwd <path>`: Change the working directory.
- `-h, --help` : Display help for the GitLab Duo CLI or a specific command. For example, `duo --help` or
  `duo run --help`.
- `--log-level <level>`: Set the logging level (`debug`, `info`, `warn`, `error`).
- `-v`, `--version`: Display version information.
- `--model <model>`: Select the AI model to use for your session.

Additional options for headless mode:

- `--ai-context-items <contextItems>`: JSON-encoded array of additional context items for reference.
- `--existing-session-id <sessionId>`: ID of an existing session to resume.
- `--gitlab-auth-token <token>`: Authentication token for a GitLab instance.
- `--gitlab-base-url <url>`: Base URL of a GitLab instance (default: `https://gitlab.com`).

## Commands

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

## Environment variables

You can configure the GitLab Duo CLI using environment variables:

- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTP authentication password.
- `DUO_WORKFLOW_GIT_HTTP_USER`: Git HTTP authentication username.
- `GITLAB_BASE_URL` or `GITLAB_URL`: GitLab instance URL.
- `GITLAB_OAUTH_TOKEN` or `GITLAB_TOKEN`: Authentication token.
- `LOG_LEVEL`: Logging level.

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
- [GitLab CLI](https://docs.gitlab.com/cli/)
