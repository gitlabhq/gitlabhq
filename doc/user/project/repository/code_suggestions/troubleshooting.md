---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Code Suggestions **(FREE ALL BETA)**

When working with GitLab Duo Code Suggestions, you might encounter the following issues.

## Code Suggestions aren't displayed

If Code Suggestions are not displayed, and you have [installed a supported IDE extension](index.md#supported-editor-extensions), try the following troubleshooting steps.

In GitLab, ensure Code Suggestions is enabled:

- [For your user account](../../../profile/preferences.md#enable-code-suggestions).
- [For **all** top-level groups your account belongs to](../../../group/manage.md#enable-code-suggestions-for-a-group). If you don't have a role that lets you view the top-level group's settings, contact a group owner.

### Code Suggestions not displayed in VS Code or GitLab WebIDE

Check all the steps in [Code Suggestions aren't displayed](#code-suggestions-arent-displayed) first.

If you are a self-managed user, ensure that Code Suggestions for the [GitLab WebIDE](../../../project/web_ide/index.md) are enabled. The same settings apply to VS Code as local IDE.

1. On the left sidebar, select **Extensions > GitLab Workflow**.
1. Select **Settings** (**{settings}**), and then select **Extension Settings**.
1. In **GitLab > AI Assisted Code Suggestions**, select the **Enable code completion (Beta)**
   checkbox.

If the settings are enabled, but Code Suggestions are still not displayed, try the following steps:

1. Enable the `Debug` checkbox in the GitLab Workflow **Extension Settings**.
1. Open the extension log in **View > Output** and change the dropdown list to **GitLab Workflow** as the log filter. The command palette command is `GitLab: Show Extension Logs`.
1. Disable and re-enable the **Enable code completion (Beta)** checkbox.
1. Verify that the debug log contains similar output:

```shell
2023-07-14T17:29:00:763 [debug]: Disabling code completion
2023-07-14T17:29:01:802 [debug]: Enabling code completion
2023-07-14T17:29:01:802 [debug]: AI Assist: Using server: https://codesuggestions.gitlab.com/v2/completions
```

### Code Suggestions not displayed in Microsoft Visual Studio

Check all the steps in [Code Suggestions aren't displayed](#code-suggestions-arent-displayed) first.

1. Ensure you have properly [set up the extension](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension#setup).
1. From the **Tools > Options** menu, find the **GitLab** option. Ensure **Log Level** is set to **Debug**.
1. Open the extension log in **View > Output** and change the dropdown list to **GitLab Extension** as the log filter.
1. Verify that the debug log contains similar output:

```shell
14:48:21:344 GitlabProposalSource.GetCodeSuggestionAsync
14:48:21:344 LsClient.SendTextDocumentCompletionAsync("GitLab.Extension.Test\TestData.cs", 34, 0)
14:48:21:346 LS(55096): time="2023-07-17T14:48:21-05:00" level=info msg="update context"
```

## Authentication troubleshooting

If the above steps do not solve your issue, the problem may be related to the recent changes in authentication,
specifically the token system. To resolve the issue:

1. Remove the existing personal access token from your GitLab account settings.
1. Reauthorize your GitLab account in VS Code using OAuth.
1. Test the Code Suggestions feature with different file extensions to verify if the issue is resolved.
