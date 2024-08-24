---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in JetBrains IDEs."
---

# GitLab plugin for JetBrains IDEs

The [GitLab Duo plugin](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) integrates GitLab Duo with JetBrains IDEs
like IntelliJ, PyCharm, GoLand, Webstorm, and Rubymine. The plugin supports these GitLab features:

- [GitLab Duo Code Suggestions](../../user/project/repository/code_suggestions/index.md).
- [GitLab Duo Chat](../../user/gitlab_duo_chat.md).

While coding, accept Code Suggestions by pressing <kbd>Tab</kbd>. To dismiss Code Suggestions,
press <kbd>Escape</kbd>.

This JetBrains plugin adds an icon to your IDE's status bar:

| Icon | Status | Meaning |
| :--- | :----- | :------ |
| **{tanuki-ai}** | **Ready** | You've configured and enabled GitLab Duo, and you're using a language that supports Code Suggestions. |
| **{tanuki-ai-off}** | **Not configured** | You haven't entered a personal access token, or you're using a language that Code Suggestions doesn't support. |
| ![The status icon for fetching Code Suggestions.](../img/code_suggestions_loading_v17_4.svg) | **Loading suggestion** | GitLab Duo is fetching Code Suggestions for you. |
| ![The status icon for a Code Suggestions error.](../img/code_suggestions_error_v17_4.svg) | **Error** | GitLab Duo has encountered an error. |

## Download the extension

Download the plugin from the [JetBrains Plugin Marketplace](https://plugins.jetbrains.com/plugin/22325-gitlab-duo).

Prerequisites:

- JetBrains IDEs: **2023.2.X** and later.
- GitLab version 16.8 or later.

If you use an older version of a JetBrains IDE, check the version compatibility list on the marketplace listing.
It contains a table of plugin versions and their
[supported IDE versions](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/versions).

## Configure the extension

Prerequisites:

- GitLab Duo [is available and configured](../../user/gitlab_duo/turn_on_off.md) for your project.
- You have created a [GitLab personal access token](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)
  with the `api` and `read_user` scope.
- You have created a project in JetBrains.

To enable the plugin:

1. In your IDE, on the top bar, select your IDE's name, then select **Settings**.
1. On the left sidebar, select **Plugins**.
1. Select the **GitLab Duo** plugin, and select **Install**.
1. Select **OK**.

To configure the plugin in your IDE after you enable it:

1. Go to your IDE's top menu bar and select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Provide the **URL to GitLab instance**. For GitLab.com, use `https://gitlab.com`.
1. For **GitLab Personal Access Token**, paste in the personal access token you created. The token is not displayed,
   nor is it accessible to others.
1. Select **Verify setup**.
1. Select **OK**.

### Enable experimental or beta features

Some features in the plugin are in experiment or beta status. To use them, you must opt in:

1. Go to your IDE's top menu bar and select **Settings**, or:
   - MacOS: press <kbd>⌘</kbd>+<kbd>,</kbd>
   - Windows or Linux: press <kbd>Control</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd>
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Select **Enable Experiment or BETA features**.
1. To apply the changes, restart your IDE.

### Install alpha versions of the plugin

GitLab publishes pre-release (alpha) builds of the plugin to the
[`Alpha` release channel](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/edit/versions/alpha)
in the JetBrains Marketplace.

To install a pre-release build, either:

- Download the build from JetBrains Marketplace and
  [install it from disk](https://www.jetbrains.com/help/idea/managing-plugins.html#install_plugin_from_disk).
- [Add the `alpha` plugin repository](https://www.jetbrains.com/help/idea/managing-plugins.html#add_plugin_repos)
  to your IDE. For the repository URL, use `https://plugins.jetbrains.com/plugins/alpha/list`.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video tutorial of this process, see
[Install alpha releases of the GitLab Duo plugin for JetBrains](https://www.youtube.com/watch?v=Z9AuKybmeRU).
<!-- Video published on 2024-04-04 -->

## Add a custom certificate for Code Suggestions

> - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/561) in GitLab Duo 2.10.0.

GitLab Duo attempts to detect [trusted root certificates](https://www.jetbrains.com/help/idea/ssl-certificates.html)
without configuration on your part. If needed, configure your JetBrains IDE to allow the GitLab Duo plugin
to use a custom SSL certificate when connecting to your GitLab instance.

To use a custom SSL certificate with GitLab Duo:

1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Under **Connection**, enter the **URL to GitLab instance**.
1. To verify your connection, select **Verify setup**.
1. Select **OK**.

If your IDE detects a non-trusted SSL certificate:

1. The GitLab Duo plugin displays a confirmation dialog.
1. Review the SSL certificate details shown.
   - Confirm the certificate details match the certificate shown when you connect to GitLab in your browser.
1. If the certificate matches your expectations, select **Accept**.

To review certificates you've already accepted:

1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, select **Tools > Server Certificates**.
1. Select [**Server Certificates**](https://www.jetbrains.com/help/idea/settings-tools-server-certificates.html).
1. Select a certificate to view it.

## Integrate with 1Password CLI

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/291) in GitLab Duo 2.1 for GitLab 16.11 and later.

You can configure the plugin to use 1Password secret references for authentication, instead of hard-coding personal access tokens.

Prerequisites:

- You have the [1Password](https://1password.com) desktop app installed.
- You have the [1Password CLI](https://developer.1password.com/docs/cli/get-started/) tool installed.

To integrate GitLab for JetBrains with the 1Password CLI:

1. Authenticate with GitLab. Either:
   - [Install the `glab`](../gitlab_cli/index.md#install-the-cli) CLI and
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
1. Select **OK**.

## Toggle sending open tabs as context

By default, the Code Suggestions use the files open in your IDE for context.
To enable or disable this feature in your IDE:

1. Go to your IDE's top menu bar and select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Expand **GitLab Language Server**.
1. Under **Code Completion**, select or clear **Send open tabs as context**.
1. Select **OK**.

## Report issues with the plugin

You can report any issues, bugs, or feature requests in the
[`gitlab-jetbrains-plugin` issue queue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues).
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

- [About the Create:Editor Extensions Group](https://handbook.gitlab.com/handbook/engineering/development/dev/create/editor-extensions/)
- [Open issues for this plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/)
- [Plugin documentation](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/main/README.md)
- [View source code](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin)
