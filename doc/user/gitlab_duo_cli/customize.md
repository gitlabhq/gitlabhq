---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure hooks, custom slash commands, plugins, and network settings for the GitLab Duo CLI.
title: Customize the GitLab Duo CLI
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Environment variable and option to enable user-level Agent Skills [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.83.0) in GitLab Duo CLI 8.83.0 as an [experiment](../../policy/development_stages_support.md#experiment), during the GitLab 19.0 release.

{{< /history >}}

The GitLab Duo CLI supports the following customizations:

- Use hooks to run custom commands at specific points in the GitLab Duo CLI lifecycle.
- Use custom slash commands to better align the CLI with your workflow or use case.
- Use plugins to install Agent Skills, custom slash commands, and Model Context Protocol (MCP)
  servers from a marketplace.
- Use [custom instructions](../duo_agent_platform/customize/_index.md) set for
  the GitLab Duo Agent Platform to match your workflow, coding standards, or
  project requirements.

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

Use additional text to customize what the custom slash command does.

For example, `/daily prioritize my milestone deliverables`.

## Plugins

{{< details >}}

- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.10.0) as an [experiment](../../policy/development_stages_support.md#experiment) in GitLab Duo CLI 9.10.0, during the GitLab 19.3 release.

{{< /history >}}

Use plugins to extend the GitLab Duo CLI with additional capabilities.

A plugin is a directory that bundles extensions for the GitLab Duo CLI. A plugin can bundle
[Agent Skills](../duo_agent_platform/customize/agent_skills.md),
[custom slash commands](#custom-slash-commands), and
[MCP servers](../gitlab_duo/model_context_protocol/mcp_clients.md).

A marketplace is a catalog of available plugins in a Git repository or a local
directory. The `marketplace.json` file lists the available plugins and where to
find them.

To use a plugin, you register the marketplace that contains it, then install the plugin from that
marketplace. Plugins are identified as `<plugin>@<marketplace>`.

For compatibility with the existing community plugin ecosystem, the GitLab Duo CLI also reads
`.claude-plugin/marketplace.json` files. Existing plugin marketplaces work with the GitLab Duo CLI
without modification.

Prerequisites:

- [Set up the GitLab Duo CLI](set_up.md).
- Git, if you want to add a marketplace from a Git repository.

### Register a marketplace

Before you can install a plugin, you must register the marketplace that contains it.

The first time you use plugins, the GitLab Duo CLI automatically registers the official GitLab
marketplace, [`gitlab-duo-plugins`](https://gitlab.com/gitlab-org/ai/gitlab-duo-plugins).
If you remove this marketplace, the GitLab Duo CLI does not register it again.

To register a marketplace:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add <source>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add <source>
```

{{< /tab >}}

{{< /tabs >}}

`<source>` is one of the following:

| Source type      | Format                                                                                     | Example                                          |
|-------------------|---------------------------------------------------------------------------------------------|---------------------------------------------------|
| Git repository    | A URL that `git clone` accepts. Optionally append `#<ref>` to pin a branch or tag.          | `https://gitlab.com/group/marketplace.git#stable` |
| Local directory   | An absolute or relative path. `~` is expanded to your home directory.                       | `~/marketplaces/internal`                        |

For example:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add https://gitlab.com/example-group/example-marketplace.git
```

```shell
glab duo plugin marketplace add ~/marketplaces/internal
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add https://gitlab.com/example-group/example-marketplace.git
```

```shell
duo plugin marketplace add ~/marketplaces/internal
```

{{< /tab >}}

{{< /tabs >}}

The GitLab Duo CLI identifies the marketplace by the `name` field in its `marketplace.json` file.

#### Automatically update plugins from a marketplace

To automatically update the plugins you install from a marketplace, register the marketplace with
the `--auto-update` option:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace add <source> --auto-update
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace add <source> --auto-update
```

{{< /tab >}}

{{< /tabs >}}

When the GitLab Duo CLI starts, it updates the plugins you installed from this marketplace in the
background, without confirmation. When a plugin is updated, the GitLab Duo CLI prompts you to
restart to load the new version.

#### List registered marketplaces

To list the marketplaces you've registered:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace list
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace list
```

{{< /tab >}}

{{< /tabs >}}

For each marketplace, the GitLab Duo CLI displays:

- The marketplace source.
- When the marketplace was last updated.
- The number of plugins the marketplace has.
- Whether automatic updates are enabled for the marketplace.

#### List available marketplace plugins

To list the plugins a marketplace offers:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace show <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace show <name>
```

{{< /tab >}}

{{< /tabs >}}

For each plugin, the GitLab Duo CLI displays the version, description, and where the plugin is
installed, if anywhere.

#### Update a marketplace

To refresh a marketplace's catalog from its source:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace update <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace update <name>
```

{{< /tab >}}

{{< /tabs >}}

#### Remove a marketplace

To remove a registered marketplace:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin marketplace remove <name>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin marketplace remove <name>
```

{{< /tab >}}

{{< /tabs >}}

> [!warning]
> Removing a marketplace also uninstalls all plugins that you installed from it.

### Install and manage plugins

When you install a plugin, you choose a scope. The scope determines which configuration file the
GitLab Duo CLI updates, and who the installation applies to.

| Scope               | Configuration file                          | Use for                                                            |
|----------------------|----------------------------------------------|------------------------------------------------------------------------|
| `user` (default)     | `<config dir>/plugins.json`                 | Plugins for all your projects.                                       |
| `project`            | `.gitlab/duo/plugins.json` in the project   | Team-shared plugins. Commit this file to your repository.           |
| `local`              | `.gitlab/duo/plugins.local.json` in the project | Personal, per-project plugins. Add this file to your `.gitignore`. |

`<config dir>` is `~/.gitlab/duo` on Linux and macOS, or `%APPDATA%\GitLab\duo` on Windows.

To install a plugin from a registered marketplace:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin install <plugin>@<marketplace> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin install <plugin>@<marketplace> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

If you don't specify `--scope`, the GitLab Duo CLI uses the `user` scope.

For example:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin install my-plugin@my-marketplace
```

```shell
glab duo plugin install my-plugin@my-marketplace --scope project
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin install my-plugin@my-marketplace
```

```shell
duo plugin install my-plugin@my-marketplace --scope project
```

{{< /tab >}}

{{< /tabs >}}

#### Enabled state after installation

When you install a plugin, the GitLab Duo CLI records whether the plugin is enabled in the scope's
configuration file. To determine the initial state, the GitLab Duo CLI uses, in order of precedence:

1. Any enabled or disabled setting you previously recorded for the plugin in the target scope or a
   broader scope. For example, if you disabled a plugin, uninstalled it, and then reinstalled it, the plugin stays disabled.
1. The `defaultEnabled` value in the plugin's marketplace catalog entry.
1. The `defaultEnabled` value in the plugin's `plugin.json` manifest.

If none of these are set, the plugin is enabled.

#### List installed plugins

To list your installed plugins:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin list
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin list
```

{{< /tab >}}

{{< /tabs >}}

Installed plugins are grouped by scope, and the list shows whether each plugin is enabled.

#### Enable or disable a plugin

When you enable, disable, or uninstall a plugin, you can identify it by its name alone. If the
same plugin name is installed from more than one marketplace, use the full `<plugin>@<marketplace>`
identifier.

To enable or disable an installed plugin:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin enable <plugin> [--scope user|project|local]
glab duo plugin disable <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin enable <plugin> [--scope user|project|local]
duo plugin disable <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

If you enable or disable a plugin at multiple scopes, the most specific scope takes precedence:
`local`, then `project`, then `user`.

#### Update a plugin

To update a plugin to the latest version available from its marketplace:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin update <plugin>@<marketplace>
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin update <plugin>@<marketplace>
```

{{< /tab >}}

{{< /tabs >}}

The update applies to all scopes where the plugin is installed.

#### Uninstall a plugin

To uninstall a plugin:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo plugin uninstall <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
duo plugin uninstall <plugin> [--scope user|project|local]
```

{{< /tab >}}

{{< /tabs >}}

Uninstalling removes the plugin from your configuration.

### Use an installed plugin

After you install and enable a plugin, the GitLab Duo CLI discovers everything the plugin
bundles the next time it starts:

- Skills become available the same way as other Agent Skills.
- Custom slash commands appear in the slash command menu. Built-in slash commands, Agent Skills
  slash commands, and your own custom slash commands take precedence over a plugin command with
  the same name.
- MCP servers are loaded alongside the MCP servers you have configured, and require
  [tool approval](../gitlab_duo/model_context_protocol/mcp_clients.md#configure-tool-approval) in
  the same way. To identify where a server comes from, the GitLab Duo CLI prefixes the server name
  with the plugin name.

### Create a marketplace

To create a marketplace, add a `marketplace.json` file at the root of a Git repository or a
local directory. For example:

```json
{
  "name": "my-marketplace",
  "owner": {
    "name": "Your Name"
  },
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "description": "A short description of the plugin."
    }
  ]
}
```

Each entry in `plugins` must set `source` to a path relative to the marketplace root, starting with
`./`.

### Create a plugin

A plugin is a directory that contains an optional `plugin.json` manifest and the extensions the
plugin bundles: skills, custom slash commands, and MCP servers.

The `plugin.json` manifest supports the following fields:

| Field             | Required | Description                                              |
|--------------------|----------|--------------------------------------------------------------|
| `name`             | Yes      | The plugin's name.                                            |
| `version`          | No       | The plugin's version.                                         |
| `description`      | No       | A short description of the plugin.                            |
| `defaultEnabled`   | No       | Whether the plugin is enabled by default when installed.      |

For example:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "A short description of the plugin.",
  "defaultEnabled": true
}
```

For compatibility with existing community plugins, the GitLab Duo CLI also reads the manifest from
`.claude-plugin/plugin.json`.

To bundle extensions with your plugin:

- Skills: Add a `SKILL.md` file to a `skills/<skill-name>/` directory in the plugin. For the
  `SKILL.md` file format, see [create skills](../duo_agent_platform/customize/agent_skills.md#create-skills).
- Custom slash commands: Add a Markdown file to a `commands/` directory in the plugin. The filename
  is the command name, and the file format is the same as a
  [custom slash command](#create-a-custom-slash-command).
- MCP servers: Add a `.mcp.json` file to the root of the plugin. The file format is the same as the
  [MCP configuration format](../gitlab_duo/model_context_protocol/mcp_clients.md#configuration-format).
  To reference files inside the plugin, use the `${DUO_PLUGIN_ROOT}` variable, which resolves to
  the directory the plugin is installed in.

For example, a marketplace repository with one plugin that bundles a skill, a custom slash command,
and an MCP server:

```plaintext
my-marketplace/
├── marketplace.json
└── plugins/
    └── my-plugin/
        ├── plugin.json
        ├── .mcp.json
        ├── commands/
        │   └── my-command.md
        └── skills/
            └── my-skill/
                └── SKILL.md
```

The GitLab Duo CLI determines a plugin's version from, in order of precedence:

1. The `version` field in the plugin's `plugin.json`.
1. The `version` field on the plugin's entry in the marketplace `marketplace.json`.

If neither field is set, the plugin's version is `unknown`.

## Related topics

- [GitLab Duo CLI complete reference](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [Customize GitLab Duo Agent Platform](../duo_agent_platform/customize/_index.md)
- [Agent Skills](../duo_agent_platform/customize/agent_skills.md)
