---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in JetBrains IDEs."
---

# JetBrains troubleshooting

If the steps on this page don't solve your problem, check the
[list of open issues](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/?sort=created_date&state=opened&first_page_size=100)
in the JetBrains plugin's project. If an issue matches your problem, update the issue.
If no issues match your problem, [create a new issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/new).

## Enable debug mode

To enable debug logs in JetBrains:

1. On the top bar, go to **Help > Diagnostic Tools > Debug Log Settings**, or
   search for the action by going to **Help > Find Action > Debug log settings**.
1. Add this line: `com.gitlab.plugin`
1. Select **OK**.

The debug logs are available in the `idea.log` log file.

## Error: `unable to find valid certification path to requested target`

The GitLab Duo plugin verifies TLS certificate information before connecting to your GitLab instance.
You can [add a custom SSL certificate](index.md#add-a-custom-certificate-for-code-suggestions).

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
    1. Select an option **Pass CA certificate from Duo to the Language Server**.
    1. In **Certificate authority (CA)**, specify the path to your `.pem` file with CA certificates.
1. Restart your IDE.

### Ignore certificate errors

If GitLab Duo still fails to connect, you might need to
ignore certificate errors. By design, this setting represents a security risk:
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
1. Select **Apply**.
1. Select **OK**.

## Error: `Failed to check token`

This error occurs when the provided connection instance URL and authentication token passed through to the
GitLab Language Server process are invalid. To re-enable Code Suggestions:

1. In your IDE, on the top bar, select your IDE name, then select **Settings**.
1. On the left sidebar, select **Tools > GitLab Duo**.
1. Under **Connection**, select **Verify setup**.
1. Update your **Connection** details as needed.
1. Select **Verify setup**, and confirm that authentication succeeds.
1. Select **OK**.
