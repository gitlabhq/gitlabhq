---
stage: AI Clients
group: Duo Client SDK
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Run GitLab Duo agent actions and local MCP servers in a process sandbox on your computer.
title: Local sandbox
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.80.0) as an [experiment](../policy/development_stages_support.md#experiment) in GitLab for VS Code 6.80.0, during the GitLab 19.0 release.
- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.94.0) as an [experiment](../policy/development_stages_support.md#experiment) in GitLab Duo CLI 8.94.0, during the GitLab 19.1 release.
- Sandbox configuration file [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.4.0) in GitLab Language Server 9.4.0 and GitLab Duo CLI 9.4.0, during the GitLab 19.3 release.

{{< /history >}}

The local sandbox restricts what GitLab Duo agents can read, write, and reach on the
network when they run on your computer. It applies to agents in your editor and in the
GitLab Duo CLI.

The sandbox is off by default. Until you turn it on, the risks described in
[security considerations for editor extensions and CLI tools](security_considerations.md) apply.

For flows that run on GitLab Runner, see
[remote execution environment sandbox](../user/duo_agent_platform/environment_sandbox.md).

## How the sandbox works

When the sandbox is on, GitLab Duo runs agent actions in a separate worker process that the
operating system restricts. Agent actions include shell commands, file reads and writes,
file searches, and directory listings.

Local MCP servers that use the `stdio` transport run in the same kind of sandbox.

The sandbox removes known credential environment variables, such as `GITLAB_TOKEN`,
`GITHUB_TOKEN`, `AWS_SECRET_ACCESS_KEY`, and `SSH_AUTH_SOCK`, from the environment of
processes in the sandbox. Other environment variables are not removed.

By default, the sandbox also blocks:

- Reads from common credential and personal directories.
- Writes outside the workspace and the temporary directory.
- Network access to every host except your GitLab instance.

For the full list, see [default sandbox rules](#default-sandbox-rules).

The sandbox is a process sandbox, not a container or a virtual machine.
The following run outside the sandbox:

- Your editor and GitLab Duo itself.
- Connections to MCP servers that use the `http` or `sse` transport.
- MCP servers with `"sandboxEnabled": false`.
- [GitLab Duo CLI hooks](../user/gitlab_duo_cli/customize.md#hooks).

The sandbox reduces the risks of running agents locally, but does not remove them.
Agents can still read and change files in your workspace, and send data to the hosts
the sandbox allows.

If the sandbox is on but cannot start, for example because a dependency is missing,
agent actions and local MCP servers fail with an error. They do not run without the sandbox.
This behavior is different from the remote execution environment sandbox, which runs flows
without the sandbox and shows a warning.

## Supported platforms

| Operating system | Supported |
|------------------|-----------|
| macOS            | Yes       |
| Linux            | Yes, with [prerequisites](#prerequisites) |
| Windows          | No        |

## Prerequisites

On Linux, install `bubblewrap` and `socat`. For example:

- On Debian or Ubuntu:

  ```shell
  sudo apt-get install bubblewrap socat
  ```

- On Fedora:

  ```shell
  sudo dnf install bubblewrap socat
  ```

On macOS, no additional software is required.

## Turn on the sandbox

To turn on the sandbox:

{{< tabs >}}

{{< tab title="VS Code" >}}

1. In VS Code, open the settings:
   - For macOS, press <kbd>Command</kbd>+<kbd>,</kbd>.
   - For Windows or Linux, press <kbd>Control</kbd>+<kbd>,</kbd>.
1. Search for `gitlab.duoAgentPlatform.sandbox.enabled`.
1. Select the **Enable Sandboxing** checkbox.

Alternatively, on the bottom status bar, select **Duo** ({{< icon name="tanuki-ai" >}}), then select **Enable Agent Sandboxing**.

{{< /tab >}}

{{< tab title="JetBrains IDEs" >}}

The sandbox setting is available only in alpha builds of the GitLab Duo plugin for JetBrains IDEs.

1. In your IDE, in the top bar, select your IDE's name, then select **Settings**.
1. In the left sidebar, select **Tools** > **GitLab Duo**.
1. Under **GitLab Duo Agent Platform**, select the **Enable Sandboxing** checkbox.
1. Select **OK** or **Save**.

{{< /tab >}}

{{< tab title="GitLab Duo CLI" >}}

Start the GitLab Duo CLI with the `--sandbox` option set to `true`:

```shell
duo --sandbox true
```

Alternatively, set the `DUO_SANDBOX_ENABLED` environment variable:

```shell
export DUO_SANDBOX_ENABLED=true
```

{{< /tab >}}

{{< /tabs >}}

## Check sandbox status

To check whether the sandbox is on and available:

{{< tabs >}}

{{< tab title="VS Code" >}}

- On the bottom status bar, select **Duo** ({{< icon name="tanuki-ai" >}}). The menu shows the
  sandbox status, for example **Agent Sandboxing: Enabled** or **Agent Sandboxing: Missing Dependencies**.

For details, open the Command Palette, run **GitLab: Diagnostics**, and go to the
**GitLab Duo Agent Sandboxing** section.

{{< /tab >}}

{{< tab title="JetBrains IDEs" >}}

- In the status bar, select **Duo** ({{< icon name="tanuki-ai" >}}). The menu shows the
  sandbox status, for example **Agent Sandboxing: Enabled** or **Agent Sandboxing: Missing Dependencies**.

{{< /tab >}}

{{< tab title="GitLab Duo CLI" >}}

1. Start the GitLab Duo CLI with the sandbox turned on:

   ```shell
   duo --sandbox true
   ```

1. Run the `/doctor` command.
1. Go to the **Sandbox** section.

The **Sandbox** section reports on the current session only. If you start the CLI without
`--sandbox true` or `DUO_SANDBOX_ENABLED=true`, the section shows the sandbox as turned off.

{{< /tab >}}

{{< /tabs >}}

Each status check reports whether:

- Process sandboxing is enabled in settings.
- Process sandboxing is supported on this platform.
- System dependencies required for process sandboxing are installed.

## Default sandbox rules

These rules apply to agent actions and to local MCP servers when the sandbox is on.

### Network

Processes in the sandbox can connect only to the host and port of your GitLab instance URL.
If your instance URL does not include a port, the sandbox uses `443` for `https` and `80` for `http`.

All other hosts are blocked, including package registries. To allow more hosts,
[customize the sandbox rules](#customize-sandbox-rules).

The sandbox checks only the host and port of each connection. It does not inspect the requests.
Agents can send data to any project or account on a host the sandbox allows.

### File system read

Processes in the sandbox cannot read:

- Credential files and directories, such as `~/.ssh/`, `~/.gnupg/`, `~/.aws/`, `~/.azure/`,
  `~/.kube/config`, `~/.docker/config.json`, `~/.netrc`, `~/.git-credentials`, `~/.npmrc`,
  and `~/.pypirc`.
- `~/.config/`, except `~/.config/git/`.
- Personal directories: `~/Documents/`, `~/Downloads/`, `~/Desktop/`, `~/Pictures/`,
  `~/Movies/`, and `~/Music/`.
- Shell history: `~/.bash_history` and `~/.zsh_history`.
- On macOS, `~/Library/Application Support/`, `~/Library/Containers/`,
  `~/Library/Group Containers/`, and `~/Library/Keychains/`.

On Linux, and on macOS in VS Code, processes in the sandbox can read only an allowed set of paths.
The allowed paths include the workspace, system directories such as `/usr/`, `/bin/`, and
`/etc/`, the temporary directory, the GitLab Duo configuration directory, your Git configuration,
and common Node.js version manager directories.

On macOS in JetBrains IDEs and the GitLab Duo CLI, processes in the sandbox can read any path
that is not in the blocked list.

An allowed path takes precedence over a blocked path that contains it. For example, if your
workspace is in `~/Documents/`, processes in the sandbox can read the workspace.

### File system write

Processes in the sandbox can write only to the workspace, the temporary directory, and a few
log directories that the sandbox runtime uses.

In the workspace, processes in the sandbox cannot write to:

- `.git/hooks/` and `.git/config`
- `.gitlab-ci.yml` and `.gitlab/`
- `.gitconfig` and `.gitmodules`
- Shell startup files, such as `.bashrc`, `.zshrc`, and `.profile`
- Editor configuration directories: `.vscode` and `.idea`

In the GitLab Duo CLI, if you use the `--cwd` option to open a workspace from another
directory, the rules for `.git/config`, `.gitmodules`, shell startup files, and editor
configuration directories apply to the directory where you started the CLI, not to the workspace.
To keep these rules on the workspace, start the CLI from the workspace directory.

## Customize sandbox rules

You can add rules to the defaults in a sandbox configuration file.
Your rules apply to every workspace.

To customize sandbox rules:

1. Create a `sandbox.json` file in the [file location](#file-location).
1. Add the rules you need. For example, to let agents install packages from the npm registry
   and read a directory in your home directory:

   ```json
   {
     "network": {
       "allowedDomains": ["registry.npmjs.org"]
     },
     "filesystem": {
       "allowRead": ["~/reference-docs/"],
       "allowWrite": ["~/.npm/"]
     }
   }
   ```

   npm stores downloaded packages in `~/.npm/`, so the example also allows writes there.

1. Save the file.
1. Restart your IDE or the GitLab Duo CLI.

In the GitLab Duo CLI, you can use a different file with the `--sandbox-config` option
or the `DUO_SANDBOX_CONFIG` environment variable. Use an absolute path or a path that starts
with `~/`. The sandbox must also be turned on:

```shell
duo --sandbox true --sandbox-config ~/sandbox-strict.json
```

### File location

The file is at `~/.gitlab/duo/sandbox.json`.

If you set the `XDG_CONFIG_HOME` environment variable, the file is at
`$XDG_CONFIG_HOME/gitlab/duo/sandbox.json`.

### Configuration file reference

The file supports the following keys. Unless stated otherwise, each key takes a list of strings.

| Key | Description |
|-----|-------------|
| `filesystem.allowRead` | Paths processes in the sandbox can read. |
| `filesystem.denyRead` | Paths processes in the sandbox cannot read. |
| `filesystem.allowWrite` | Paths processes in the sandbox can write to. |
| `filesystem.denyWrite` | Paths processes in the sandbox cannot write to. |
| `network.allowedDomains` | Hosts processes in the sandbox can connect to. To allow a specific port, use `host:port`. |
| `network.deniedDomains` | Hosts processes in the sandbox cannot connect to. |
| `srt.enableWeakerNestedSandbox` | Boolean. On Linux, set to `true` to run in a container that does not support the full sandbox. This setting weakens the sandbox. |
| `srt.ignoreViolations` | Object that maps command patterns to lists of paths. Blocked access to these paths is not reported. |

Your rules add to the default rules. You cannot remove:

- Write access to the workspace and the temporary directory.
- Network access to your GitLab instance.
- The blocked write paths in the workspace.

If the file is not valid JSON or contains a key that is not in this table, GitLab Duo ignores
the whole file and uses the default rules. The error is written to the GitLab Duo log.

## Configure the sandbox for an MCP server

Some local MCP servers need access that the default rules block. For example, an MCP server
that reads its own configuration from `~/.config/` cannot start.

To change the sandbox rules for one MCP server:

1. Open your [user MCP configuration file](../user/gitlab_duo/model_context_protocol/mcp_clients.md#create-user-configuration).
1. In the server configuration, add a `sandbox` object. For example:

   ```json
   {
     "mcpServers": {
       "gitlab": {
         "type": "stdio",
         "command": "glab",
         "args": ["mcp", "serve"],
         "sandbox": {
           "allowRead": ["~/.config/glab-cli/"]
         }
       }
     }
   }
   ```

   This example uses the `glab` configuration directory on Linux. On macOS, use
   `~/Library/Application Support/glab-cli/`.

1. Save the file.
1. Restart your IDE or the GitLab Duo CLI.

The sandbox removes credential environment variables from an MCP server, even when you set
them in the server's `env` object.

### MCP server sandbox settings

The `sandbox` object applies only to MCP servers that use the `stdio` transport.
It supports the following keys:

| Key | Type | Description |
|-----|------|-------------|
| `sandboxEnabled` | Boolean | Set to `false` to run this server without the sandbox. Setting it to `true` has no effect when the sandbox is turned off. |
| `allowRead` | List of strings | Paths this server can read, in addition to the defaults. |
| `allowWrite` | List of strings | Paths this server can write to, in addition to the defaults. |
| `denyRead` | List of strings | Paths this server cannot read, in addition to the defaults. |

Where you set the `sandbox` object affects which keys apply:

- User configuration: All keys apply.
- Workspace configuration (`.gitlab/duo/mcp.json`): Only `denyRead` applies. A project can
  restrict a server, but cannot give it more access. GitLab Duo ignores the other keys and logs
  a warning.
- Plugins: The `sandbox` object is ignored.

> [!warning]
> When you set `"sandboxEnabled": false`, the MCP server runs with the same access as your
> user account. Use this setting only for servers you trust.

## Troubleshooting

When working with the local sandbox, you might encounter the following issues.

### Error: `Sandbox is enabled but sandbox provider is not available (missing_dependencies)`

You might get this error when the sandbox is on and required software is not installed.
In VS Code, a warning also lists the missing dependencies.

To resolve this issue, install the [prerequisites](#prerequisites), then restart your IDE or
the GitLab Duo CLI.

### Error: `Sandbox is enabled but sandbox provider is not available (unsupported_platform)`

You might get this error when the sandbox is on and your operating system is not
[supported](#supported-platforms).

To resolve this issue, turn off the sandbox:

- In VS Code, in the settings, search for `gitlab.duoAgentPlatform.sandbox.enabled`, then clear
  the **Enable Sandboxing** checkbox.
- In the GitLab Duo CLI, unset the `DUO_SANDBOX_ENABLED` and `DUO_SANDBOX_CONFIG` environment
  variables, then start the CLI without the `--sandbox` and `--sandbox-config` options.

### Error: `Operation is blocked by sandbox.`

You might get this error when an agent action tries to read, write, or connect to something
that the sandbox rules block.

To resolve this issue, if the agent needs the access, add a rule to your
[sandbox configuration file](#customize-sandbox-rules).

### MCP server fails to start

When the sandbox is on, a local MCP server might fail to start because:

- The sandbox cannot start. The error includes `Sandbox is enabled but sandbox provider is not available`.
  To resolve this issue, install the [prerequisites](#prerequisites).
- The server reads files or connects to hosts that the sandbox blocks.
  To resolve this issue, [configure the sandbox for the MCP server](#configure-the-sandbox-for-an-mcp-server).
- The server needs a credential environment variable that the sandbox removes, such as `GITHUB_TOKEN`.
  To resolve this issue, if you trust the server, set `"sandboxEnabled": false` in its `sandbox` object.

### Project MCP sandbox settings are ignored

You might get a warning that includes `sandbox settings from this project's committed config can only narrow, not widen`.

This warning occurs when the workspace `.gitlab/duo/mcp.json` file sets `sandbox` keys
other than `denyRead`.

To resolve this issue, move the keys to your
[user MCP configuration file](../user/gitlab_duo/model_context_protocol/mcp_clients.md#create-user-configuration).

### Requests to the GitLab instance are blocked

Processes in the sandbox can connect to your GitLab instance only on the host and port in your
instance URL. Requests to a different port are blocked. For example, if your instance URL is
`https://gitlab.example.com`, the allowed port is `443`, so a request to `http://gitlab.example.com`
on port `80` is blocked.

To resolve this issue, use the same port as your instance URL, or add the host and port to
`network.allowedDomains` in your [sandbox configuration file](#customize-sandbox-rules).
For example, `gitlab.example.com:8080`.
