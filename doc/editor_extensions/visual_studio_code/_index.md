---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Use the GitLab for VS Code extension to handle common GitLab tasks directly in VS Code.
title: GitLab for VS Code extension
---

The [GitLab for VS Code extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
integrates GitLab Duo and other GitLab features directly into your IDE.

To get started, [install and configure the extension](setup.md). For added security, you can set up
the extension in a Visual Studio Code Dev Container.

When configured, this extension brings the GitLab features you use every day directly into your
VS Code environment:

- [Work with projects](projects.md): Plan and track work with issues, review and discuss changes
  with merge requests, and share code snippets. Use GitLab Duo for AI-native planning and coding.
- [Monitor and test CI/CD pipelines](cicd.md): Test your pipeline configuration. View pipeline
  status and job outputs.
- [Secure your application](security_scanning.md): Review security findings and perform SAST
  scanning for your project.
- [Browse repositories](remote_urls.md#browse-a-repository-in-read-only-mode): Access a GitLab
  repository in read-only mode without cloning it.

When you view a GitLab project in VS Code, the extension shows you information about your current branch:

- The status of the branch's most recent CI/CD pipeline.
- A link to the merge request for this branch.
- If the merge request includes an [issue closing pattern](../../user/project/issues/managing_issues.md#closing-issues-automatically),
  a link to the issue.

## GitLab extension panels

After you install and set up the extension, you can access the following features:

- In the left sidebar, **GitLab** ({{< icon name="tanuki" >}}): Manage issues and merge
  requests, run CI/CD commands, view pipeline status, and perform security scanning.
  You can also extend your view with [custom queries](custom_queries.md).
- In the left sidebar, **GitLab Duo Agent Platform** ({{< icon name="duo-agentic-chat" >}}):
  - The chat tab: Interact with GitLab Duo Agentic Chat, or use the **New chat** ({{< icon name="duo-chat-new" >}})
    dropdown list to select a foundational or custom agent to work with.
  - The flows tab: Use the Software Development Flow. Learn more about the
    [difference between Chat and the flow](../../user/duo_agent_platform/flows/foundational_flows/software_development.md#flow-and-chat-comparison).
- In the status bar, **Duo** ({{< icon name="tanuki-ai" >}}): Check the feature status of
  GitLab Duo Code Suggestions and review suggestions in
  your file as you author code.
- In the left sidebar, **GitLab Duo Chat** ({{< icon name="duo-chat" >}}): Interact with
  GitLab Duo Non-Agentic Chat.

If these features do not appear, see [troubleshooting](troubleshooting.md#gitlab-duo-features-are-unavailable) for guidance.

## Customize keyboard shortcuts

You can assign different keyboard shortcuts for **Accept Inline Suggestion**, **Accept Next Word Of Inline Suggestion**,
or **Accept Next Line Of Inline Suggestion**:

1. In VS Code, run the `Preferences: Open Keyboard Shortcuts` command.
1. Find the shortcut you want to edit, and select **Change keybinding** ({{< icon name="pencil" >}}).
1. Assign your preferred shortcuts to **Accept Inline Suggestion**, **Accept Next Word Of Inline Suggestion**,
   or **Accept Next Line Of Inline Suggestion**.
1. Press <kbd>Enter</kbd> to save your changes.

## Update the extension

To update your extension to the latest version:

1. In Visual Studio Code, go to **Settings** > **Extensions**.
1. Search for **GitLab** published by **GitLab (`gitlab.com`)**.
1. From **Extension: GitLab**, select **Update to {later version}**.
1. Optional. To enable automatic updates in the future, select **Auto-Update**.

## Install the pre-release version

GitLab publishes pre-release builds of the extension to the VS Code Extension Marketplace.

To install the pre-release build:

1. Open VS Code.
1. Under **Extensions** > **GitLab**, select **Switch to Pre-release Version**.
1. Select **Restart Extensions**.

## Check GitLab Duo status

1. In Visual Studio Code, on the bottom status bar, select the GitLab icon ({{< icon name="tanuki" >}}).
1. A menu opens under the VS Code search box, and the GitLab for VS Code extension shows the status.
   Any errors are displayed next to **Status:**.

For GitLab Duo Non-Agentic Chat, you can also check the [status of Chat](../../user/gitlab_duo_chat/_index.md#check-the-status-of-chat).

## Related topics

- [GitLab for VS Code releases](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases)
- [Security considerations for editor extensions](../security_considerations.md)
- [Command Palette commands](settings.md#command-palette-commands)
- [Troubleshooting the GitLab for VS Code extension](troubleshooting.md)
- [Download the GitLab for VS Code extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
- Extension [source code](https://gitlab.com/gitlab-org/gitlab-vscode-extension/)
- [GitLab Language Server documentation](../language_server/_index.md)
