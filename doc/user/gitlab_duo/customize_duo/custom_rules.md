---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom rules
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- Custom rules [added](https://gitlab.com/gitlab-org/gitlab/-/issues/550743) in GitLab 18.2.
- User-level custom rules [added](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2452) in GitLab 18.7.

{{< /history >}}

Use custom rules to specify instructions for GitLab Duo Chat to follow for every conversation in
your IDE. You can only use custom rules with GitLab Duo Chat.

## Create custom rules

You can create custom rules at two levels:

- User-level rules: Apply to all of your projects and workspaces.
- Workspace-level rules: Apply only to a specific project or workspace.

If both user-level and workspace-level rules exist, GitLab Duo Chat applies both to conversations.

Prerequisites:

- For VS Code, [install and configure the GitLab Workflow extension for VS Code](../../../editor_extensions/visual_studio_code/setup.md) version 6.32.2 or later.
- For a JetBrains IDE, [install and configure the GitLab plugin for JetBrains](../../../editor_extensions/jetbrains_ide/setup.md) version 3.12.2 or later.
- For Visual Studio, [install and configure the GitLab extension for Visual Studio](../../../editor_extensions/visual_studio/setup.md) version 0.60.0 or later.

> [!note]
> Conversations that existed before you created any custom rules do not follow those rules.

### Create user-level custom rules

User-level custom rules apply to all of your projects and workspaces.

1. Create a custom rules file in your user configuration directory:
   - If you have set the `GLAB_CONFIG_DIR` environment variable, create the file at: `$GLAB_CONFIG_DIR/chat-rules.md`
   - Otherwise, create the file in your platform's default configuration directory:
     - macOS or Linux:
       - If you use the `XDG_CONFIG_HOME` environment variable, create the file at: `$XDG_CONFIG_HOME/gitlab/duo/chat-rules.md`
       - Otherwise, create the file within your home directory at: `~/.gitlab/duo/chat-rules.md`
     - Windows: `%APPDATA%\GitLab\duo\chat-rules.md`
1. Add custom rules to the file. For example:

   ```markdown
   - Don't put comments in the generated code
   - Be brief in your explanations
   - Always use single quotes for JavaScript strings
   ```

1. Save the file.
1. To apply the new custom rules, start a new GitLab Duo conversation.

   You must do this every time you change the custom rules.

### Create workspace-level custom rules

Workspace-level custom rules apply only to a specific project or workspace.

1. In your IDE workspace, create a custom rules file: `.gitlab/duo/chat-rules.md`.
1. Add custom rules to the file. For example:

   ```markdown
   - Don't put comments in the generated code
   - Be brief in your explanations
   - Always use single quotes for JavaScript strings
   ```

1. Save the file.
1. To apply the new custom rules, start a new GitLab Duo conversation.

   You must do this every time you change the custom rules.

For more information, see the [Custom rules in GitLab Duo Agentic Chat blog](https://about.gitlab.com/blog/custom-rules-duo-agentic-chat-deep-dive/).

## Update custom rules

To update your custom rules, edit and save the custom rules file. Then, start a new GitLab Duo
conversation to apply the updated rules.

You cannot use Chat to edit your custom rules file directly.

To manage who must approve any changes to custom rules, use [Code Owners](../../project/codeowners/_index.md).

## Related topics

- [AGENTS.md customization files](agents_md.md)
