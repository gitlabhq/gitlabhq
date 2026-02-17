---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Connect and use GitLab Duo in JetBrains IDEs.
title: Install and set up the GitLab plugin for JetBrains IDEs
---

Download the plugin from the [JetBrains Plugin Marketplace](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)
and install it.

Prerequisites:

- JetBrains IDEs: 2023.2.X and later.
- GitLab version 16.8 or later.

If you use an older version of a JetBrains IDE, download a version of the plugin compatible with your IDE:

1. On the GitLab Duo [plugin page](https://plugins.jetbrains.com/plugin/22325-gitlab-duo), select **Versions**.
1. Select **Compatibility**, then select your JetBrains IDE.
1. Select a **Channel** to filter for stable releases or alpha releases.
1. In the compatibility table, find your IDE version and select **Download**.

## Enable the plugin

To enable the plugin:

1. In your IDE, on the top bar, select your IDE's name, then select **Settings**.
1. On the left sidebar, select **Plugins**.
1. Select the **GitLab Duo** plugin, and select **Install**.
1. Select **OK** or **Save**.

## Connect to GitLab

After you install the extension, connect it to your GitLab account.

### Authenticate with GitLab

Prerequisites:

- For GitLab Self-Managed and GitLab Dedicated authentication using OAuth:
  - GitLab Duo plugin for JetBrains 3.30.30 and later.
  - The application ID for an instance-wide [OAuth application for JetBrains IDEs](../../administration/settings/editor_extensions.md#jetbrains-ides).
- For authentication using PAT, a [personal access token](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)
  with the `api` scope.
- For authentication with 1Password, completion of the [steps to integrate with 1Password](_index.md#integrate-with-1password-cli)
  and the secret reference.

After you configure the plugin in your IDE, connect it to your GitLab account:

1. In your IDE, on the top bar, select your IDE's name, then select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
   If you don't see the plugin listed, restart your IDE.
1. Provide the **URL to GitLab instance**. For GitLab.com, use `https://gitlab.com`.
1. Select an authentication method, **OAuth**, **PAT**, or **1Password CLI**.
   - For OAuth, follow the prompts to sign in and authenticate.
   - For PAT, enter your personal access token.
     The token value is not displayed or accessible to others.
   - For 1Password, select **Integrate with 1Password CLI**, select your account, and, optionally,
     enter the secret reference.
1. Select **Verify setup**.
1. Select **OK** or **Save**.

## Configure GitLab Duo

Prerequisites:

- For agentic features, you meet the prerequisites for [GitLab Duo Agent Platform](../../user/duo_agent_platform/_index.md#prerequisites).
- You have GitLab Duo [turned on](../../user/gitlab_duo/turn_on_off.md).
- You open a project that is linked to a remote repository on GitLab, or you set a default GitLab Duo
  namespace in the extension.

To enable GitLab Duo features:

1. In your JetBrains IDE, go to **Settings** > **Tools** > **GitLab Duo**.
1. Find the feature you want to enable and select the checkbox.
1. Restart your IDE, if prompted.

For GitLab Duo Code Suggestions, review the additional prerequisites and setup steps:

- [GitLab Duo Code Suggestions](../../user/duo_agent_platform/code_suggestions/set_up.md#prerequisites)
- [GitLab Duo Code Suggestions (Classic)](../../user/project/repository/code_suggestions/set_up.md#prerequisites)

## Set the default namespace

The GitLab Duo Agent Platform uses the **Default Namespace** value when the plugin
can't determine the current GitLab project. To configure this value:

1. In your IDE, on the top bar, select your IDE's name, then select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Enter a value for **Default Namespace**.
1. Select **OK** or **Save**.

## Install alpha versions of the plugin

GitLab publishes pre-release (alpha) builds of the plugin to the
[`Alpha` release channel](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/edit/versions/alpha)
in the JetBrains Marketplace.

To install a pre-release build, either:

- Download the build from JetBrains Marketplace and
  [install it from disk](https://www.jetbrains.com/help/idea/managing-plugins.html#install_plugin_from_disk).
- [Add the `alpha` plugin repository](https://www.jetbrains.com/help/idea/managing-plugins.html#add_plugin_repos)
  to your IDE. For the repository URL, use `https://plugins.jetbrains.com/plugins/alpha/list`.

  > [!note]
  > To see the alpha release after adding the `alpha` plugin repository, you might need to uninstall and reinstall the GitLab Duo plugin.

<i class="fa-youtube-play" aria-hidden="true"></i>
For a video tutorial of this process, see
[Install alpha releases of the GitLab Duo plugin for JetBrains](https://www.youtube.com/watch?v=Z9AuKybmeRU).
<!-- Video published on 2024-04-04 -->
