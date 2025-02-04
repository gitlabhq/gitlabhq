---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in JetBrains IDEs."
title: JetBrains troubleshooting
---

If the steps on this page don't solve your problem, check the
[list of open issues](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/?sort=created_date&state=opened&first_page_size=100)
in the JetBrains plugin's project. If an issue matches your problem, update the issue.
If no issues match your problem, [create a new issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/new).

For troubleshooting JetBrains IDEs for GitLab Duo Code Suggestions,
see [Troubleshooting Code Suggestions](../../user/project/repository/code_suggestions/troubleshooting.md#jetbrains-ides-troubleshooting).

## Enable debug mode

To enable debug logs in JetBrains:

1. On the top bar, go to **Help > Diagnostic Tools > Debug Log Settings**, or
   search for the action by going to **Help > Find Action > Debug log settings**.
1. Add this line: `com.gitlab.plugin`
1. Select **OK** or **Save**.

## Use an HTTP proxy

If you experience [certificate errors](#certificate-errors) or other connection errors, and
use a HTTP proxy to connect to your GitLab instance, you must
[configure the Language Server to use a proxy](../language_server/_index.md#configure-the-language-server-to-use-a-proxy)
for the GitLab Language Server.

You can also [enable proxy authentication](../language_server/_index.md#enable-proxy-authentication).

## Enable GitLab Language Server debug logs

To enable GitLab Language Server debug logs:

1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, select **Tools > GitLab Duo**.
1. Select **GitLab Language Server** to expand the section.
1. In **Logging > Log Level**, enter `debug`.
1. Select **Apply**.
1. Below **Enable GitLab Language Server**, select **Restart Language Server**.

The debug logs are available in the `idea.log` log file. To view this file, either:

<!-- vale gitlab_base.SubstitutionWarning = NO -->

- In your IDE, go to **Help > Show Log in Finder**.
- Go to the directory `/Users/<user>/Library/Logs/JetBrains/IntelliJIdea<build_version>`, replacing
  `<user>` and `<build_version>` with the appropriate values.

<!-- vale gitlab_base.SubstitutionWarning = YES -->

## Certificate errors

If your machine connects to your GitLab instance through a proxy, you might encounter
SSL certificate errors in JetBrains. GitLab Duo attempts to detect certificates in your system store;
however, Language Server cannot do this. If you see errors from the Language Server
about certificates, try enabling the option to pass a Certificate Authority (CA) certificate:

To do this:

1. On the bottom right corner of your IDE, select the GitLab icon.
1. On the dialog, select **Show Settings**. This opens the **Settings** dialog to **Tools > GitLab Duo**.
1. Select **GitLab Language Server** to expand the section.
1. Select **HTTP Agent Options** to expand it.
1. Either:
   - Select an option **Pass CA certificate from Duo to the Language Server**.
   - In **Certificate authority (CA)**, specify the path to your `.pem` file with CA certificates.
1. Restart your IDE.

### Ignore certificate errors

If GitLab Duo still fails to connect, you might need to
ignore certificate errors. You might see errors in the GitLab Language Server logs after enabling [debug mode](jetbrains_troubleshooting.md#enable-debug-mode):

```plaintext
2024-10-31T10:32:54:165 [error]: fetch: request to https://gitlab.com/api/v4/personal_access_tokens/self failed with:
request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
FetchError: request to https://gitlab.com/api/v4/personal_access_tokens/self failed, reason: unable to get local issuer certificate
```

By design, this setting represents a security risk:
these errors alert you to potential security breaches. You should enable this
setting only if you are absolutely certain the proxy causes the problem.

Prerequisites:

- You have verified the certificate chain is valid, using your system browser,
  or you have confirmed with your machine's administrator that this error is safe to ignore.

To do this:

1. Refer to JetBrains documentation on [SSL certificates](https://www.jetbrains.com/help/idea/ssl-certificates.html).
1. Go to your IDE's top menu bar and select **Settings**.
1. On the left sidebar, select **Tools > GitLab Duo**.
1. Confirm your default browser trusts the **URL to GitLab instance** you're using.
1. Enable the **Ignore certificate errors** option.
1. Select **Verify setup**.
1. Select **OK** or **Save**.

### Authentication fails in PyCharm

If you encounter problems during the **Verify setup** phase of GitLab authentication, confirm you
are running a supported version of PyCharm:

1. Go to the [plugin compatibility](https://plugins.jetbrains.com/plugin/22325-gitlab-duo/versions) page.
1. For **Compatibility**, select `PyCharm Community` or `PyCharm Professional`.
1. For **Channels**, select your desired stability level for the GitLab plugin.
1. For your version of PyCharm, select **Download** to download the correct GitLab plugin version, and install it.
