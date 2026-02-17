---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom rules
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Custom rules [added](https://gitlab.com/gitlab-org/gitlab/-/issues/550743) in GitLab 18.2.
- User-level custom rules [added](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2452) in GitLab 18.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.

{{< /history >}}

You can use custom rules in the GitLab Duo Agent Platform
to ensure that generated output (for example, code or documentation)
aligns with your specific instructions, or any other
requirements such as development style guides.

The following Agent Platform features support custom rules:

- [GitLab Duo Chat (Agentic)](../../gitlab_duo_chat/agentic_chat.md)
- [Foundational and custom agents](../agents/_index.md)
- [Foundational and custom flows](../flows/_index.md)

## Create custom rules

You can create custom rules at two levels:

- User-level rules: Apply to all of your projects and workspaces.
- Workspace-level rules: Apply only to a specific project or workspace.

If both user-level and workspace-level rules exist, GitLab Duo Chat applies both to conversations.

Prerequisites:

- Meet the [Agent Platform prerequisites](../_index.md#prerequisites).
- For VS Code, [install and configure the GitLab Workflow extension for VS Code](../../../editor_extensions/visual_studio_code/setup.md) version 6.32.2 or later.
- For a JetBrains IDE, [install and configure the GitLab plugin for JetBrains](../../../editor_extensions/jetbrains_ide/setup.md) version 3.12.2 or later.
- For Visual Studio, [install and configure the GitLab extension for Visual Studio](../../../editor_extensions/visual_studio/setup.md) version 0.60.0 or later.

> [!note]
> Conversations that existed before you created any custom rules do not follow those rules.

### Create user-level custom rules

User-level custom rules apply to all of your projects and workspaces in your local environment (IDE).

1. Create a custom rules file in your home directory:
   - On Linux or macOS, create the file at `~/.gitlab/duo/chat-rules.md`.
   - On Windows, create the file at `%APPDATA%\GitLab\duo\chat-rules.md`.
1. Add custom rules to the file. For example:

   ```markdown
   - Don't put comments in the generated code
   - Be brief in your explanations
   - Always use single quotes for JavaScript strings
   ```

1. Save the file.

1. To apply the new custom rules, do any of the following as appropriate:
   - Start a new GitLab Duo Chat conversation.
   - Use an agent in a Chat conversation, discussion, issue, or merge request.
   - Trigger a flow.

If you have set a specific environment variable, then you create the
custom rules file in a different location:

- If you have set the `GLAB_CONFIG_DIR` environment variable,
  create the file at `$GLAB_CONFIG_DIR/chat-rules.md`.
- If you have set the `XDG_CONFIG_HOME` environment variable,
  create the file at `$XDG_CONFIG_HOME/gitlab/duo/chat-rules.md`.

### Create workspace-level custom rules

Workspace-level custom rules apply only to a specific project or workspace.
You can use this method to apply a set of custom rules to the project for your team.
For example, you can apply a set of development style guides that your team uses.

1. In your IDE workspace, create a custom rules file: `.gitlab/duo/chat-rules.md`.
1. Add custom rules to the file. For example:

   ```markdown
   - Don't put comments in the generated code
   - Be brief in your explanations
   - Always use single quotes for JavaScript strings
   ```

1. Save the file.
1. For a project: Add the `.gitlab/duo/chat-rules.md` file to the Git repository.
   Agentic Chat, agents, and flows then automatically read the custom rules from
   the repository into context.
1. To apply the new custom rules, start a new GitLab Duo conversation.

   You must do this every time you change the custom rules.

For more information, see the [Custom rules in GitLab Duo Agentic Chat tutorial blog](https://about.gitlab.com/blog/custom-rules-duo-agentic-chat-deep-dive/).

## Update custom rules

To update your custom rules, edit and save the custom rules file. Then, start a new GitLab Duo
conversation to apply the updated rules.

You cannot use Chat to edit your custom rules file directly.

To manage who must approve any changes to custom rules, use [Code Owners](../../project/codeowners/_index.md).

## Related topics

- [AGENTS.md customization files](agents_md.md)
