---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Connect and use GitLab Duo in JetBrains IDEs.
title: GitLab Duo plugin for JetBrains IDEs
---

The [GitLab Duo plugin](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) integrates GitLab Duo
with JetBrains IDEs like IntelliJ, PyCharm, GoLand, Webstorm, and Rubymine.

To install and configure the extension, see [Install and set up](setup.md).

## Use with remote development

The GitLab Duo plugin works with JetBrains Remote Development when installed on the host machine (remote server).

For information about installing plugins in remote development environments, see the JetBrains documentation:

- [Install plugins in remote projects](https://www.jetbrains.com/help/idea/work-inside-remote-project.html#plugins).
- [Add plugins to Dev Containers](https://www.jetbrains.com/help/idea/customizing-devcontainer-json-file.html#add_plugins).

## Enable experimental or beta features

Some features in the plugin are in experiment or beta status. To use them, you must opt in:

1. Go to your IDE's top menu bar and select **Settings**, or:
   - MacOS: press <kbd>⌘</kbd>+<kbd>,</kbd>
   - Windows or Linux: press <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd>
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Select **Enable Experiment or BETA features**.
1. To apply the changes, restart your IDE.

## Update the extension

To update your extension to the latest version:

1. In your JetBrains IDE, go to **Settings** > **Plugins**.
1. From **Marketplace**, select **GitLab Duo** published by **GitLab, Inc.**.
1. Select **Update** to update to the latest plugin version.

## Enable telemetry

The GitLab Duo plugin uses the telemetry settings in your JetBrains IDE to send usage and error
information to GitLab. To enable telemetry in your JetBrains IDE:

1. Go to your IDE's top menu bar and select **Settings**. For example, in PyCharm, select **PyCharm** > **Settings**.
1. On the left sidebar, expand **Tools** and select **GitLab Duo**.
1. Under **Advanced**, select the **Enable telemetry** checkbox.
1. Select **OK** or **Apply** to save your changes.

## Integrate with 1Password CLI

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/291) in GitLab Duo 2.1 for GitLab 16.11 and later.

{{< /history >}}

You can configure the plugin to use 1Password secret references for authentication, instead of hard-coding personal access tokens.

Prerequisites:

- You have the [1Password](https://1password.com) desktop app installed.
- You have the [1Password CLI](https://developer.1password.com/docs/cli/get-started/) tool installed.

To integrate GitLab for JetBrains with the 1Password CLI:

1. Authenticate with GitLab. Either:
   - [Install the `glab`](../gitlab_cli/_index.md#install-the-cli) CLI and
     configure the [1Password shell plugin](https://developer.1password.com/docs/cli/shell-plugins/gitlab/).
   - Follow the GitLab for JetBrains
     [steps](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin#setup).
1. Open the 1Password item.
1. [Copy the secret reference](https://developer.1password.com/docs/cli/secret-references/#step-1-copy-secret-references).

   If you use the `gitlab` 1Password shell plugin, the token is stored as a password under `"op://Private/GitLab Personal Access Token/token"`.

From the IDE:

1. Go to your IDE's top menu bar and select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Under **Authentication**, select the **1Password CLI** tab.
1. Select **Integrate with 1Password CLI**.
1. Optional. For **Secret reference**, paste the secret reference you copied from 1Password.
1. Optional. To verify your credentials, select **Verify setup**.
1. Select **OK** or **Save**.

## Report issues with the plugin

You can report any issues, bugs, or feature requests in the
[`gitlab-jetbrains-plugin` issue tracker](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues).
Use the `Bug` or `Feature Proposal` template.

If you encounter an error while using GitLab Duo, you can also report it with your IDE's
built-in error reporting tool:

1. To access the tool, either:
   - When an error occurs, in the error message, select **See details and submit report**.
   - In the status bar, on the bottom right, select the exclamation mark.
1. In the **IDE Internal Errors** dialog, describe the error.
1. Select **Report and clear all**.
1. Your browser opens a GitLab issue form, pre-populated with debug information.
1. Follow the prompts in the issue template to fill out the description, providing
   as much context as you can.
1. Select **Create issue** to file the bug report.

## Related topics

- [Code Suggestions](../../user/project/repository/code_suggestions/_index.md)
- [JetBrains troubleshooting](jetbrains_troubleshooting.md)
- [GitLab Language Server documentation](../language_server/_index.md)
- [Open issues for this plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/)
- [Plugin documentation](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/main/README.md)
- [View source code](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin)
