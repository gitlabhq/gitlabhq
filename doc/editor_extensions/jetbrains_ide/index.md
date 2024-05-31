---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in JetBrains IDEs."
---

# GitLab plugin for JetBrains IDEs

The [GitLab Duo plugin](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) integrates GitLab Duo Pro with JetBrains IDEs. The marketplace listing provides a full list of [supported IDEs](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/versions).

## Supported features

The GitLab Duo plugin for JetBrains IDEs supports:

- [GitLab Duo Code Suggestions](../../user/project/repository/code_suggestions/index.md).
- [GitLab Duo Chat](../../user/gitlab_duo_chat.md).

## Download the extension

Download the extension from the [JetBrains Plugin Marketplace](https://plugins.jetbrains.com/plugin/22325-gitlab-duo).

## Configure the extension

Instructions for getting started can be found in the project README under [setup](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin#setup).

### Integrate with 1Password CLI

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/291) in GitLab Duo 2.1 for GitLab 16.11 and later.

You can configure the editor extension to use 1Password secret references for authentication, instead of hard-coding personal access tokens.

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

1. On the top bar, select **Settings**.
1. On the left sidebar, select **Tools > GitLab Duo**.
1. Under **Advanced**:
   1. Select **Integrate with 1Password CLI**.
   1. Optional. For **Secret reference**, paste the secret reference you copied from 1Password.
1. Optional. To verify your credentials, select **Verify setup**.
1. Select **OK**.

## Report issues with the extension

Report any issues, bugs, or feature requests in the
[`gitlab-jetbrains-plugin` issue queue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues).

## Related topics

- [Download the plugin](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)
- [Plugin documentation](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/main/README.md)
- [View source code](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin)
