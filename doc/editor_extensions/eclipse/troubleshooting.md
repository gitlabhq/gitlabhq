---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Connect and use GitLab Duo in Eclipse.
title: Troubleshooting Eclipse
---

{{< details >}}

- Tier: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163) from experiment to beta in GitLab 17.11.
- Access to GitLab Duo Non-Agentic Chat removed for GitLab Duo Core customers on May 21, 2026 as part of GitLab 19.0, with a feature flag named `no_duo_classic_for_duo_core_users`. Enabled by default.

{{< /history >}}

> [!disclaimer]

If the steps on this page don't solve your problem, check the
[list of open issues](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/?sort=created_date&state=opened&first_page_size=100)
in the Eclipse plugin's project. If an issue matches your problem, update the issue.
If no issues match your problem, [create a new issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/new) with the [required information for support](#required-information-for-support).

## Review the Error Log

1. In the menu bar of your IDE, select **Window**.
1. Expand **Show View**, then select **Error Log**.
1. Search for errors referencing the `gitlab-eclipse-plugin` plugins.

## Locate the Eclipse workspace log file

The Eclipse workspace log file, named `.log` is located in the directory `<your-eclipse-workspace>/.metadata`.

## Enable GitLab Language Server debug logs

To enable GitLab Language Server debug logs:

1. In your IDE, open preferences:
   - For macOS, select **Eclipse** > **Settings**.
   - For Windows or Linux, select **Window** > **Preferences**.
1. In the left sidebar, select **GitLab Duo**.
1. In **Language Server Log Level**, enter `debug`.
1. Select **Apply and Close**.

The debug logs are available in the `language_server.log` file. To view this file, either:

- Go to the following directory, replacing `<user>` and `<eclipse-version>` with the appropriate
  values:
  - For macOS: `/Users/<user>/eclipse-workspace/.metadata/.plugins/com.gitlab.eclipse.gitlab-eclipse-plugin`
  - For Windows: `<drive>:\Users\<user>\eclipse-workspace\.metadata\.plugins\com.gitlab.eclipse.gitlab-eclipse-plugin`
  - For Linux: `/home/<user>/eclipse-workspace/.metadata/.plugins/com.gitlab.eclipse.gitlab-eclipse-plugin`
- Open the **Error Log**. Search for the log `Language server logs saved to: <file>.` where `<file>` is
  the absolute path to the `language_server.log` file.

## Required information for support

When creating a support request, provide the following information:

1. Your current GitLab for Eclipse plugin version.
   1. Open the `About Eclipse` dialog in your IDE.
      - For macOS, select **Eclipse** > **About Eclipse**.
      - For Windows or Linux, select **Help** > **About Eclipse IDE**.
   1. Select **Installation details**.
   1. Locate **GitLab for Eclipse** and copy the **Version** value.
1. Your Eclipse version.
   1. Open the `About Eclipse` dialog in your IDE.
      - For macOS, select **Eclipse** > **About Eclipse**.
      - For Windows or Linux, select **Help** > **About Eclipse IDE**.
1. Your operating system.
1. Are you using a GitLab.com, GitLab Self-Managed, or GitLab Dedicated instance?
1. Are you using a proxy?
1. Are you using a self-signed certificate?
1. The Eclipse workspace logs.
1. The Language Server debug logs.
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
   - Under **Language Server**, for **CA certificate**, select **Browse** and choose your `.pem` file with CA certificates.
   - Under **Connection**, select the **Ignore Certificate Errors** checkbox.
1. Select **Apply and Close**.

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

- You verified the certificate chain in your system browser or your machine's administrator
  confirmed that this error is safe to ignore.

To do this:

1. Refer to Eclipse documentation on SSL certificates.
1. In your IDE, open preferences:
   - For macOS, select **Eclipse** > **Settings**.
   - For Windows or Linux, select **Window** > **Preferences**.
1. In the left sidebar, select **GitLab Duo**.
1. Confirm your default browser trusts the **URL to GitLab instance** value.
1. Select the **Ignore certificate errors** checkbox.
1. Select **Verify Setup**.
1. Select **Apply and Close**.
