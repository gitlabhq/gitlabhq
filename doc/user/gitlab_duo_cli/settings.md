---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Change GitLab Duo CLI settings in the settings panel or the settings file, and enforce settings with a managed settings file.
title: GitLab Duo CLI settings
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can change how the GitLab Duo CLI behaves in the following ways:

- In the [settings panel](#settings-panel), from interactive mode.
- In the [settings file](#settings-file), which stores your settings panel choices. You can also edit the file directly.
- With a [managed settings file](#managed-settings-file), which system administrators deploy to enforce settings.

## Settings panel

{{< history >}}

- Settings panel [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.90.0) in GitLab Duo CLI 8.90.0, during the GitLab 19.0 release.
- Setting to display work items in new sessions [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.11.0) in GitLab Duo CLI 9.11.0, during
the GitLab 19.4 release.
- Setting to adjust theme [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.11.0) in GitLab Duo CLI 9.11.0, during the GitLab 19.4 release.
- Setting to run suggested prompts as `/goal` sessions [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.24.0) in GitLab Duo CLI 9.24.0, during the GitLab 19.5 release.

{{< /history >}}

To change a setting:

1. In interactive mode, type `/settings` and press <kbd>Enter</kbd>.
1. Use the arrow keys to navigate the list of settings.
1. To change the selected setting, press <kbd>Enter</kbd> or <kbd>Space</kbd>.
1. To close the panel, press <kbd>Escape</kbd>.

Changes persist across sessions in the settings file.
If your organization enforces a setting, the panel shows **Set by your organization** and you can't
change it.

The following settings are available:

| Setting                  | Description                                                                                       |
|--------------------------|---------------------------------------------------------------------------------------------------|
| **Telemetry**            | Send anonymous usage data to improve GitLab Duo.                                                  |
| **Notifications**        | Control [system notifications](use.md#system-notifications) (`auto` or `disabled`).                     |
| **Show work items on session start** | Display your open work items when you start a new session. |
| **Run suggested prompts as /goal sessions** | Run suggested prompts as `/goal` sessions instead of plain chat messages. A restart is required for changes to take effect. |
| **Theme**        | Change the theme setting. Options include `auto`, `dark`, `light`, `dark high contrast`, and `light high contrast`. |

## Settings file

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.26.0) in GitLab Duo CLI 9.26.0, during the GitLab 19.5 release.

{{< /history >}}

The GitLab Duo CLI stores the settings you change in the `/settings` panel in a settings file.
You can also edit the file directly, or create it in advance, for example in a container image.

The GitLab Duo CLI reads the file when it starts.
Changes you make to the file apply the next time you start the GitLab Duo CLI.

### File location

The file location depends on your operating system:

| Operating system | Path                                 |
|------------------|--------------------------------------|
| Linux and macOS  | `~/.gitlab/duo/settings.json`        |
| Windows          | `%APPDATA%\GitLab\duo\settings.json` |

If you have set `XDG_CONFIG_HOME`, the file is `$XDG_CONFIG_HOME/gitlab/duo/settings.json`.

The GitLab Duo CLI creates the file the first time you change a setting in the `/settings` panel.

### File format

The file must contain a JSON object, and can include comments (`//` and `/* */`) and trailing commas.
When you change a setting in the `/settings` panel, the GitLab Duo CLI keeps your comments, formatting,
and any keys it does not recognize.

The following example sets every setting to its default value:

```json
{
  "telemetry": {
    "enabled": true
  },
  "showWorkItemsInNewSessions": true,
  "goalFlowInWelcomePrompts": true,
  "notifications": {
    "channel": "auto" // or "disabled"
  },
  "theme": "auto" // or "dark", "light", "dark-high-contrast", "light-high-contrast"
}
```

### Invalid files and values

The GitLab Duo CLI never deletes or rewrites the file to fix it:

- If the file is not valid JSON, the GitLab Duo CLI ignores the whole file and logs a warning.
- If a setting has an invalid value, the GitLab Duo CLI ignores that setting and logs a warning.
- If the GitLab Duo CLI does not recognize a setting, for example one from a newer version, it ignores that setting.

If the file is read-only, changes you make in the `/settings` panel apply to the current session only.

## Managed settings file

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v9.27.0) in GitLab Duo CLI 9.27.0, during the GitLab 19.5 release.

{{< /history >}}

To enforce settings, system administrators deploy a managed settings file to each machine.
For example, they can use a mobile device management tool or group policy.

Settings in the managed settings file take precedence over command-line options, environment variables,
and the settings file, including changes users make in the settings panel.

Enforced settings cannot be changed by users. Settings not in the file remain under user control.

### File location

The GitLab Duo CLI reads the file from a fixed location that can't be changed:

| Operating system                  | Path                                                            |
|-----------------------------------|-----------------------------------------------------------------|
| Linux and other operating systems | `/etc/gitlab/duo/settings.managed.json`                         |
| macOS                             | `/Library/Application Support/GitLab/duo/settings.managed.json` |
| Windows                           | `C:\Program Files\GitLab\duo\settings.managed.json`             |

Restrict write access to system administrators and grant read-only access
to all other users.

The GitLab Duo CLI reads the file when it starts.
Changes to the file apply the next time users start the GitLab Duo CLI.

In Windows Subsystem for Linux (WSL), the GitLab Duo CLI reads the Linux path inside the
distribution, and Windows group policy does not apply.

### File format

The file must contain a JSON object, and can include comments (`//` and `/* */`) and trailing commas.

The following example sets every setting you can enforce:

```json
{
  "telemetry": {
    "enabled": false
  },
  "showWorkItemsInNewSessions": true,
  "goalFlowInWelcomePrompts": true,
  "notifications": {
    "channel": "auto" // or "disabled"
  },
}
```

## Settings precedence

For each setting, the GitLab Duo CLI uses the first value it finds, in this order:

1. The managed settings file, if your organization enforces the setting.
1. Command-line options and environment variables, which apply to the current session only.
1. The settings file.
1. The default value.
