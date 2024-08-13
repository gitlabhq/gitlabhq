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

### Add a custom certificate for Code Suggestions

> - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/561) in GitLab Duo 2.10.0.

GitLab Duo attempts to detect [trusted root certificates](https://www.jetbrains.com/help/idea/ssl-certificates.html)
without configuration on your part. If needed, you can configure your JetBrains IDE to allow the GitLab Duo plugin
to connect to your GitLab instance using a custom certificate.

To use a custom certificate:

1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, select **Tools > GitLab Duo**.
1. Under **Connection**, enter the **URL to GitLab instance**.
1. To verify your connection, select **Verify setup**.
1. Select **OK**.

If your IDE detects a non-trusted certificate:

1. The GitLab Duo plugin displays a confirmation dialog.
1. Review the certificate details shown.
   - Confirm that when you connect to GitLab in your browser, you see the same certificate details.
1. If the certificate matches your expectations, select **Accept**.

To review certificates you've already accepted:

1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, select **Tools > Server Certificates**.
1. Select [**Server Certificates**](https://www.jetbrains.com/help/idea/settings-tools-server-certificates.html).
1. Select a certificate to view it.

### Allow a custom certificate for Code Suggestions

GitLab Duo attempts to pass custom certificate details to the GitLab Language Server process without configuration on your part.

To enforce a specific custom certificate:

1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, select **Tools > GitLab Duo**.
1. Under **Advanced**, select **GitLab Language Server**.
1. Under **GitLab Language Server**, select **HTTP Agent Options**.
1. Under **HTTP Agent Options**:
   1. For **Certificate authority (CA)**, enter the full path to your server's certificate authority.
   1. Optional. In **Certificate**, enter the full file path to your client certificate.
   1. Optional. In **Certificate key**, enter the full file path to your private key.
1. Insert the full path to the PEM-encoded certificate authority.
1. Select **OK**.

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

## Troubleshooting

### Error: `unable to find valid certification path to requested target`

The GitLab Duo plugin verifies TLS certificate information before connecting to your GitLab instance.
If necessary you can [allow a custom certificate](#allow-a-custom-certificate-for-code-suggestions).

### Error: `Failed to check token`

This error occurs when the provided connection instance URL and authentication token passed through to the
GitLab Language Server process are invalid. To re-enable code suggestions:

1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, select **Tools > GitLab Duo**.
1. Under **Connection**, select **Verify setup**.
1. Update your **Connection** details as needed.
1. Select **Verify setup**, and confirm that authentication succeeds.
1. Select **OK**.

## Report issues with the extension

Report any issues, bugs, or feature requests in the
[`gitlab-jetbrains-plugin` issue queue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues).

## Related topics

- [Download the plugin](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)
- [Plugin documentation](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/blob/main/README.md)
- [View source code](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin)
