---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Connect and use GitLab Duo in Eclipse.
title: Eclipse troubleshooting
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

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

1. In your IDE, select **Eclipse > Settings**.
1. On the left sidebar, select **GitLab**.
1. In **Language Server Log Level**, enter `debug`.
1. Select **Apply and Close**.

The debug logs are available in the `language_server.log` file. To view this file, either:

- Go to the directory `/Users/<user>/eclipse/<eclipse-version>/Eclipse.app/Contents/MacOS/.gitlab_plugin`, replacing `<user>` and `<eclipse-version>` with the appropriate values.
- Open the [Error logs](#review-the-error-log). Search for the log `Language server logs saved to: <file>.` where `<file>` is the absolute path to the `language_server.log` file.

## Required information for support

When creating a support request, provide this information:

1. Your current GitLab for Eclipse plugin version.
   1. Open the `About Eclipse IDE` popup window.
      - On Windows, in your IDE, select **Help > About Eclipse IDE**.
      - On MacOS, in your IDE, select **Eclipse > About Eclipse IDE**.
   1. On the dialog, select **Installation details**.
   1. Locate **GitLab for Eclipse** and copy the **Version** value.

1. Your Eclipse version.
   1. Open the `About Eclipse IDE` popup window.
      - On Windows, in your IDE, select **Help > About Eclipse IDE**.
      - On MacOS, in your IDE, select **Eclipse > About Eclipse IDE**.

1. Your operating system.
1. Are you using `gitlab.com` or a self-managed instance?
1. Are you using a proxy?
1. Are you using a self-signed certificate?
1. The [workspace logs](#locate-the-workspace-log-file).
1. The [Language Server debug logs](#enable-gitlab-language-server-debug-logs).
1. If applicable, a video or a screenshot of the issue.
1. If applicable, the steps to reproduce the issue.
1. If applicable, the attempted steps to resolve the issue.

## Certificate errors

{{< alert type="warning" >}}

You may experience errors connecting to GitLab if you connect to GitLab through a proxy or using custom certificates.
[Support for HTTP proxies](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/35)
and [support for custom certificates](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/36)
are proposed for a future release.

{{< /alert >}}
