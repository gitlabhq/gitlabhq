---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in JetBrains IDEs."
title: Install and set up the GitLab plugin for JetBrains IDEs
---

Download the plugin from the [JetBrains Plugin Marketplace](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)
and install it.

Prerequisites:

- JetBrains IDEs: **2023.2.X** and later.
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

### Create a personal access token

If you are on GitLab Self-Managed, create a personal access token.

1. In GitLab, on the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Access tokens**.
1. Select **Add new token**.
1. Enter a name, description, and expiration date.
1. Select the `api` scope.
1. Select **Create personal access token**.

### Authenticate with GitLab

After you configure the plugin in your IDE, connect it to your GitLab account:

1. In your IDE, on the top bar, select your IDE's name, then select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Select an authentication method:
   - For GitLab.com, use `OAuth`.
   - For GitLab Self-Managed and GitLab Dedicated, use `Personal access token`.
1. Provide the **URL to GitLab instance**. For GitLab.com, use `https://gitlab.com`.
1. For **GitLab Personal Access Token**, paste in the personal access token you created.
   The token is not displayed, nor is it accessible to others.
1. Select **Verify setup**.
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

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video tutorial of this process, see
[Install alpha releases of the GitLab Duo plugin for JetBrains](https://www.youtube.com/watch?v=Z9AuKybmeRU).
<!-- Video published on 2024-04-04 -->
