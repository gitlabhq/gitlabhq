---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Connect and use GitLab Duo in Eclipse.
title: Troubleshooting Eclipse
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163) from experiment to beta in GitLab 17.11.

{{< /history >}}

{{< alert type="disclaimer" />}}

If the steps on this page don't solve your problem, check the
[list of open issues](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/?sort=created_date&state=opened&first_page_size=100)
in the Eclipse plugin's project. If an issue matches your problem, update the issue.
If no issues match your problem, [create a new issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/new) with the [required information for support](#required-information-for-support).

## Review the Error Log

1. In the menu bar of your IDE, select **Window**.
1. Expand **Show View**, then select **Error Log**.
1. Search for errors referencing the `gitlab-eclipse-plugin` plugins.

## Locate the Workspace Log file

The Workspace log file, named `.log` is located in the directory `<your-eclipse-workspace>/.metadata`.

## Enable GitLab Language Server debug logs

To enable GitLab Language Server debug logs:

1. In your IDE, select **Eclipse** > **Settings**.
1. On the left sidebar, select **GitLab**.
1. In **Language Server Log Level**, enter `debug`.
1. Select **Apply and Close**.

The debug logs are available in the `language_server.log` file. To view this file, either:

- Go to the directory `/Users/<user>/eclipse/<eclipse-version>/Eclipse.app/Contents/MacOS/.gitlab_plugin`, replacing `<user>` and `<eclipse-version>` with the appropriate values.
- Open the [Error logs](#review-the-error-log). Search for the log `Language server logs saved to: <file>.` where `<file>` is the absolute path to the `language_server.log` file.

## Required information for support

When creating a support request, provide the following information:

1. Your current GitLab for Eclipse plugin version.
   1. Open the `About Eclipse IDE` dialog.
      - On Windows, in your IDE, select **Help** > **About Eclipse IDE**.
      - On MacOS, in your IDE, select **Eclipse** > **About Eclipse IDE**.

   1. On the dialog, select **Installation details**.
   1. Locate **GitLab for Eclipse** and copy the **Version** value.

1. Your Eclipse version.
   1. Open the `About Eclipse IDE` dialog.
      - On Windows, in your IDE, select **Help** > **About Eclipse IDE**.
      - On MacOS, in your IDE, select **Eclipse** > **About Eclipse IDE**.

1. Your operating system.
1. Are you using a GitLab.com, GitLab Self-Managed, or GitLab Dedicated instance?
1. Are you using a proxy?
1. Are you using a self-signed certificate?
1. The [workspace logs](#locate-the-workspace-log-file).
1. The [Language Server debug logs](#enable-gitlab-language-server-debug-logs).
1. If applicable, a video or a screenshot of the issue.
1. If applicable, the steps to reproduce the issue.
1. If applicable, the attempted steps to resolve the issue.

## Certificate errors

If your machine connects to your GitLab instance through a proxy, you might encounter
SSL certificate errors in Eclipse. GitLab Duo attempts to detect certificates in your system store;
however, Language Server cannot do this. If you see errors from the Language Server
about certificates, try enabling the option to pass a Certificate Authority (CA) certificate:

To do this:

1. On the bottom right corner of your IDE, select the GitLab icon.
1. On the dialog, select **Show Settings**. This opens the **Settings** dialog to **Tools** > **GitLab Duo**.
1. Select **GitLab Language Server** to expand the section.
1. Select **HTTP Agent Options** to expand it.
1. Either:
   - Select an option **Pass CA certificate from Duo to the Language Server**.
   - In **Certificate authority (CA)**, specify the path to your `.pem` file with CA certificates.
1. Restart your IDE.

### Ignore certificate errors

If GitLab Duo still fails to connect, you might need to
ignore certificate errors. You might see errors in the GitLab Language Server logs after enabling
debug mode:

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

1. Refer to Eclipse documentation on SSL certificates.
1. Go to your IDE's top menu bar and select **Settings**.
1. On the left sidebar, select **Tools** > **GitLab Duo**.
1. Confirm your default browser trusts the **URL to GitLab instance** you're using.
1. Enable the **Ignore certificate errors** option.
1. Select **Verify setup**.
1. Select **OK** or **Save**.
