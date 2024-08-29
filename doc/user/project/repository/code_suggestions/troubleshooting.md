---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Troubleshooting tips for common problems in Code Suggestions."
---

# Troubleshooting Code Suggestions

DETAILS:
**Tier:** Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../../../subscriptions/subscription-add-ons.md)
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

When working with GitLab Duo Code Suggestions, you might encounter the following issues.

## Verify Code Suggestions status in Admin area

Prerequisites:

- You must be an administrator of the instance.

You can verify that Code Suggestions is set up correctly on the server. Because you are checking this on the server side and not for a specific user, it does not guarantee that Code Suggestions will work for a specific user on client side.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Duo Pro**.

A flash message with Code Suggestions check status is displayed at the top of the page.

## Suggestions are not displayed

If suggestions are not displayed, follow these steps:

1. Ensure you have [installed a supported IDE extension](supported_extensions.md#supported-editor-extensions)
1. Ensure your administrator has [assigned you a seat](../../../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).

If suggestions are still not displayed, try the following troubleshooting steps.

### Suggestions not displayed in VS Code or GitLab Web IDE

If you are a self-managed user, ensure that Code Suggestions for the [GitLab Web IDE](../../../project/web_ide/index.md) is enabled. The same settings apply to VS Code as local IDE.

1. On the left sidebar, select **Extensions > GitLab Workflow**.
1. Select **Settings** (**{settings}**), and then select **Extension Settings**.
1. In **GitLab > Duo Code Suggestions**, select the **GitLab Duo Code Suggestions**
   checkbox.

### View Code Suggestions logs

If the settings are enabled, but suggestions are still not displayed, try the following steps:

1. In the GitLab Workflow **Extension Settings**, enable **GitLab: Debug**.
1. Open the extension log in **View > Output** and change the dropdown list to **GitLab Workflow** as the log filter. The command palette command is `GitLab: Show Extension Logs`.
1. Disable and re-enable the **Enable code completion** checkbox.
1. Verify that the debug log contains similar output:

```shell
2023-07-14T17:29:00:763 [debug]: Disabling code completion
2023-07-14T17:29:01:802 [debug]: Enabling code completion
2023-07-14T17:29:01:802 [debug]: AI Assist: Using server: https://cloud.gitlab.com/ai/v2/code/completions
```

To enable debug logging for the Language Server (LS), enable **GitLab › Ls: Debug**.

### Suggestions not displayed in JetBrains IDEs

1. Ensure you have properly [set up the extension](https://gitlab.com/gitlab-org/editor-extensions/gitlab-intellij-plugin#setup).
1. From the **Tools > GitLab Duo** menu, select **Verify setup**. Make sure the health check passes.
1. Verify that your JetBrains IDE natively supports the language of the file you are
   working on. Go to **Settings** > **Languages & Frameworks** to see the full list of
   languages and frameworks supported by your JetBrains IDE.

### Suggestions not displayed in Microsoft Visual Studio

1. Ensure you have properly [set up the extension](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension#setup).
1. From the **Tools > Options** menu, find the **GitLab** option. Ensure **Log Level** is set to **Debug**.
1. Open the extension log in **View > Output** and change the dropdown list to **GitLab Extension** as the log filter.
1. Verify that the debug log contains similar output:

```shell
14:48:21:344 GitlabProposalSource.GetCodeSuggestionAsync
14:48:21:344 LsClient.SendTextDocumentCompletionAsync("GitLab.Extension.Test\TestData.cs", 34, 0)
14:48:21:346 LS(55096): time="2023-07-17T14:48:21-05:00" level=info msg="update context"
```

## Code Suggestions returns a 401 error

Code Suggestions [depends on a license token](../../../ai_features.md) that
[synchronizes your subscription](../../../../administration/license.md) with GitLab.

If the token expires, GitLab Duo Code Suggestions returns the following error
with status `401` when the token has expired:

```plaintext
Token validation failed in Language Server:
(Failed to check token: Error: Fetching Information about personal access token
```

If GitLab has access to the [cloud server](../../../ai_features.md), try
[manually synchronizing your license](../../../../subscriptions/self_managed/index.md#manually-synchronize-subscription-data).

## Authentication troubleshooting

If the above steps do not solve your issue, the problem may be related to the recent changes in authentication,
specifically the token system. To resolve the issue:

1. Remove the existing personal access token from your GitLab account settings.
1. Reauthorize your GitLab account in VS Code using OAuth.
1. Test the Code Suggestions feature with different file extensions to verify if the issue is resolved.
