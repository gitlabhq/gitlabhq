---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
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

{{< /history >}}

The GitLab Duo CLI is a command-line interface tool that brings [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md)
to your terminal. Available for use with any operating system and editor, use `duo` to ask complex
questions about your codebase and to autonomously perform actions on your behalf.

The GitLab Duo CLI can help you:

- Understand your codebase structure, cross-file functionality, and individual code snippets.
- Build, modify, refactor, and modernize code.
- Troubleshoot errors and fix code issues.
- Automate CI/CD configuration, troubleshoot pipeline errors, and optimize pipelines.
- Perform multi-step development tasks autonomously.

{{< alert type="note" >}}

The GitLab Duo CLI (`duo`) is a separate tool from the [GitLab CLI](https://docs.gitlab.com/cli/)
(`glab`). While `glab` provides command-line access to GitLab features like issues and merge
requests, `duo` provides autonomous AI capabilities to complete tasks and assist you while you work.

A unified experience is proposed in [epic 20826](https://gitlab.com/groups/gitlab-org/-/work_items/20826).

{{< /alert >}}

The GitLab Duo CLI offers two modes:

- Interactive mode: Provides a chat experience similar to GitLab Duo Chat in the GitLab UI or in
  editor extensions.
- Headless mode: Enables non-interactive use in runners, scripts, and other automated workflows.

## Install the GitLab Duo CLI

Prerequisites:

- Node.js 22 or later.

To install the GitLab Duo CLI, run:

```shell
npm install --global @gitlab/duo-cli
```

To start the GitLab Duo CLI, run:

```shell
duo
```

## Authenticate with GitLab

The first time you run the GitLab Duo CLI, a configuration screen appears with a prompt to set a
**GitLab Instance URL** and **GitLab Token** for authentication.

Prerequisites:

- A [personal access token](../profile/personal_access_tokens.md) with `api` permissions.

To authenticate:

1. Enter a **GitLab Instance URL** and then press <kbd>Enter</kbd>. For example,
   `https://gitlab.com`.
1. For **GitLab Token**, enter your personal access token.
1. To save and exit the CLI, press <kbd>Control</kbd>+<kbd>S</kbd>.
1. To restart the CLI, run `duo` in your terminal.

To modify the configuration after initial setup, use `duo config edit`.

## Use the GitLab Duo CLI

Prerequisites:

- You must be working with a GitLab project that has a remote repository configured, or set a
  [default GitLab Duo namespace](../profile/preferences.md#set-a-default-gitlab-duo-namespace).

### Use the GitLab Duo CLI in interactive mode

To use the GitLab Duo CLI in interactive mode, use the command `duo`:

1. Start the interactive UI in your terminal:

   ```shell
   duo
   ```

1. `Duo` appears in your terminal window. After the prompt, enter your question or request and press
  <kbd>Enter</kbd>.

    For example:

    ```plaintext
    What is this repository about?

    Which issues need my attention?

    Help me implement issue 15.

    The pipelines in MR 23 are failing. Please help me fix them.
    ```

### Use the GitLab Duo CLI in headless mode

> [!caution]
> Use headless mode with caution and in a controlled sandbox environment.

To run a workflow in non-interactive mode, use the command `duo run`:

```shell
duo run --goal "Your goal or prompt here"
```

For example, you can run an ESLint command and pipe errors to the GitLab Duo CLI to resolve:

 ```shell
duo run --goal "Fix these errors: $eslint_output"
```

When you use headless mode, the GitLab Duo CLI:

- Bypasses manual tool approvals and automatically approves all tools for use.
- Does not maintain context from previous conversations.
  A new workflow starts every time you execute `duo run`.

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

Additional options for headless mode:

- `--ai-context-items <contextItems>`: JSON-encoded array of additional context items for reference.
- `--existing-session-id <sessionId>`: ID of an existing session to resume.
- `--gitlab-auth-token <token>`: Authentication token for a GitLab instance.
- `--gitlab-base-url <url>`: Base URL of a GitLab instance (default: `https://gitlab.com`).

## Commands

- `duo`: Start interactive mode.
- `duo config`: Manage the configuration and authentication settings.
- `duo log`: View and manage logs.
  - `duo log last`: Open the last log file.
  - `duo log list`: List all log files.
  - `duo log tail <args...>`: Display the tail of the last log file.
    Supports standard tail arguments.
  - `duo log clear`: Remove all existing log files.
- `duo run`: Start headless mode.

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
  If your CA certificate is installed in your operating system's certificate store,
  configure Node.js to use it. Requires Node.js 22.15.0, 23.9.0, or 24.0.0 and later.

  ```shell
  export NODE_OPTIONS="--use-system-ca"
  ```

- Specify a CA certificate file:
  For older Node.js versions, or when the CA certificate is not in the system store,
  point Node.js to the certificate file directly. The file must be in PEM format.

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

To update the GitLab Duo CLI to the latest version, run:

```shell
npm install --global @gitlab/duo-cli@latest
```

## Contribute to the GitLab Duo CLI

For information on contributing to the GitLab Duo CLI, see the
[development guide](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/development.md).

## Related topics

- [Security considerations for editor extensions](../../editor_extensions/security_considerations.md)
