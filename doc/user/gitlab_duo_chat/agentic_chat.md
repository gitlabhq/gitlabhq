---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chat (Agentic)
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta
- LLM: Anthropic [Claude Sonnet 4](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Available on GitLab Duo with self-hosted models: Not supported

{{< /details >}}

{{< history >}}

- VS Code [introduced on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/work_items/540917) in GitLab 18.1 as an [experiment](../../policy/development_stages_support.md) with a [flag](../../administration/feature_flags/_index.md) named `duo_agentic_chat`. Disabled by default.
- VS Code [enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196688) in GitLab 18.2.
- GitLab UI [introduced on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/546140) in GitLab 18.2 [with flags](../../administration/feature_flags/_index.md) named `duo_workflow_workhorse` and `duo_workflow_web_chat_mutation_tools`. Both flags are enabled by default.
- Feature flag `duo_agentic_chat` enabled by default in GitLab 18.2.
- JetBrains IDEs [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1077) in GitLab 18.2.
- GitLab Duo Chat (Agentic) changed to beta in GitLab 18.2.
- Visual Studio for Windows [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/245) in GitLab 18.3.
- Feature flags `duo_workflow_workhorse` and `duo_workflow_web_chat_mutation_tools` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198487) in GitLab 18.4.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by feature flags.
For more information, see the history.

{{< /alert >}}

GitLab Duo Chat (Agentic) is an enhanced version of GitLab Duo Chat (Classic). This new Chat can autonomously
perform actions on your behalf, to help you answer complex questions more comprehensively.

While the classic Chat answers questions based on a single context, the agentic Chat searches,
retrieves, and combines information from multiple sources across your GitLab projects
to provide more thorough and relevant answers. The agentic Chat can also create and edit
files for you.

"Agentic" means that Chat:

- Autonomously uses a large language model to determine what information is needed.
- Executes a sequence of operations to gather that information.
- Formulates a response to your questions.
- Can create and change local files.

For larger problems, like understanding a codebase or generating an implementation
plan, use the [software development flow of the GitLab Duo Agent Platform](../duo_agent_platform/_index.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [GitLab Duo Chat (Agentic)](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ).
<!-- Video published on 2025-06-02 -->

## Use GitLab Duo Chat

You can use GitLab Duo Chat in:

- If you have GitLab Duo Pro or Enterprise, the GitLab UI.
- VS Code.
- A JetBrains IDE.
- Visual Studio for Windows.

Prerequisites:

- A GitLab Duo Core, Pro, or Enterprise add-on.
- A Premium or Ultimate subscription.
- You have an assigned seat for or access to GitLab Duo Chat.
- You have [turned on beta and experimental features](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) for your GitLab instance or group.

### Use GitLab Duo Chat in the GitLab UI

{{< details >}}

- Add-on: GitLab Duo Pro or Enterprise

{{< /details >}}

To use Agentic Chat in the GitLab UI:

1. Go to a project in a group that meets the prerequisites.
1. In the upper-right corner, select **GitLab Duo Chat**. A drawer opens on the right side of your screen.
1. Under the chat text box, turn on the **Agentic mode (Beta)** toggle.
1. Enter your question in the chat text box and press <kbd>Enter</kbd> or select **Send**. It may take a few seconds for the interactive AI chat to produce an answer.
1. Optional. Ask a follow-up question.

### Use GitLab Duo Chat in VS Code

Prerequisites:

- You have [installed and configured the GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/setup.md) version 6.15.1 or later.

You can only use GitLab Duo Chat in a project:

- Hosted on a GitLab instance.
- That is part of a group that meets the prerequisites.

To use GitLab Duo Chat:
<!-- markdownlint-disable MD044 -->
1. In VS Code, go to **Settings > Settings**.
1. Search for `agent platform`.
1. Under **Gitlab › Duo Agent Platform: Enabled**, select the
   **Enable GitLab Duo Agent Platform** checkbox.
1. On the left sidebar, select **GitLab Duo Agent Platform (Beta)** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** tab.
1. Select **Refresh page** if prompted.
1. In the message box, enter your question and press <kbd>Enter</kbd> or select **Send**.
<!-- markdownlint-enable MD044 -->

### Use GitLab Duo Chat in JetBrains IDEs

Prerequisites:

- You have [installed and configured the GitLab plugin for JetBrains](../../editor_extensions/jetbrains_ide/setup.md) version 3.11.1 or later.

To use GitLab Duo Chat in a project, it must be:

- Hosted on a GitLab instance.
- Part of a group that meets the prerequisites.

To use GitLab Duo Chat:
<!-- markdownlint-disable MD044 -->
1. In your JetBrains IDE, go to **Settings > Tools > GitLab Duo**.
1. Under **GitLab Duo Agent Platform (Beta)**, select the **Enable GitLab Duo Agent Platform** checkbox.
1. Restart your IDE if prompted.
1. On the left sidebar, select **GitLab Duo Agent Platform (Beta)** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** tab.
1. In the message box, enter your question and press <kbd>Enter</kbd> or select **Send**.
<!-- markdownlint-enable MD044 -->

### Use GitLab Duo Chat in Visual Studio

Prerequisites:

- You have [installed and configured the GitLab extension for Visual Studio](../../editor_extensions/visual_studio/setup.md) version 0.60.0 or later.

To use GitLab Duo Chat in a project, it must be:

- Hosted on a GitLab instance.
- Part of a group that meets the prerequisites.

To use GitLab Duo Chat:
<!-- markdownlint-disable MD044 -->
1. In Visual Studio, go to **Tools > Options > GitLab**.
1. Under **GitLab**, select **General**.
1. For **Enable Agentic Duo Chat (experimental)**, select **True**, and then **OK**.
1. Select **Extensions > GitLab > Open Agentic Chat**.
1. In the message box, enter your question and press **Enter**.
<!-- markdownlint-enable MD044 -->

### View the chat history

{{< history >}}

- Chat history [introduced](https://gitlab.com/groups/gitlab-org/-/epics/17922) on IDEs in GitLab 18.2.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/issues/556875) for GitLab UI in GitLab 18.3.

{{< /history >}}

To view your chat history:

- In the GitLab UI: In the upper-right corner of the Chat drawer, select
  **Chat history** ({{< icon name="history" >}}).
- In your IDE: In the upper-right corner of the message box, select
  **Chat history** ({{< icon name="history" >}}).

In the GitLab UI, all of the conversations in your chat history are visible.

In your IDE, the last 20 conversations are visible. [Issue 1308](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1308) proposes to change this.

### Have multiple conversations

{{< history >}}

- Multiple conversations [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/556875) in GitLab 18.3.

{{< /history >}}

You can have an unlimited number of simultaneous conversations with GitLab Duo Chat.

Your conversations synchronize across GitLab Duo Chat in the GitLab UI and your IDE.

1. Open GitLab Duo Chat in the GitLab UI or your IDE.
1. Enter your question and press <kbd>Enter</kbd> or select **Send**.
1. Create a new conversation:

   - In the GitLab UI: In the upper-right corner of the drawer, select **New chat**
     ({{< icon name="duo-chat-new" >}}).
   - In your IDE: In the upper-right corner of the message box, select **New chat**
     ({{< icon name="plus" >}}).

1. Enter your question and press <kbd>Enter</kbd> or select **Send**.
1. To view all of your conversations, look at your [chat history](#view-the-chat-history).
1. To switch between conversations, in your chat history, select the
   appropriate conversation.
1. IDE only: To search for a specific conversation in the chat history, in the
   **Search chats** text box, enter your search term.

Because of LLM context window limits, conversations are truncated to 200,000 tokens
(roughly 800,000 characters) each.

### Delete a conversation

{{< history >}}

- Ability to delete a conversation [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/545289) in GitLab 18.2.

{{< /history >}}

1. In the GitLab UI or your IDE, select the [chat history](#view-the-chat-history).
1. In the history, select **Delete this chat** ({{< icon name="remove" >}}).

Individual conversations expire and are automatically deleted after 30 days of inactivity.

### Create custom rules

{{< history >}}

- Custom rules [added](https://gitlab.com/gitlab-org/gitlab/-/issues/550743) in GitLab 18.2.

{{< /history >}}

In your IDE, if you have specific instructions that you want
GitLab Duo Chat to follow in every conversation, you can create custom rules.

Prerequisites:

- For VS Code, [install and configure the GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/setup.md) version 6.32.2 or later.
- For a JetBrains IDE, [install and configure the GitLab plugin for JetBrains](../../editor_extensions/jetbrains_ide/setup.md) version 3.12.2 or later.
- For Visual Studio, [install and configure the GitLab extension for Visual Studio](../../editor_extensions/visual_studio/setup.md) version 0.60.0 or later.

{{< alert type="note" >}}

Conversations that existed before you created any custom rules do not follow those rules.

{{< /alert >}}

1. In your IDE workspace, create a custom rules file: `.gitlab/duo/chat-rules.md`.
1. Enter the custom rules into the file. For example:

   ```markdown
   - don't put comments in the generated code
   - be brief in your explanations
   - always use single quotes for JavaScript strings
   ```

1. Save the file.
1. To have GitLab Duo Chat follow the new custom rules, start a new conversation, or `/clear` the existing conversation.

   You must do this every time you change the custom rules.

For more information, see the [Custom rules in GitLab Duo Agentic Chat blog](https://about.gitlab.com/blog/custom-rules-duo-agentic-chat-deep-dive/).

## GitLab Duo Chat capabilities

GitLab Duo Chat (Agentic) extends GitLab Duo Chat (Classic) capabilities with the following features:

- **Project search**: Can search through your projects to find relevant
  issues, merge requests, and other artifacts using keyword-based search. Agentic
  Chat does not have semantic search capability.
- **File access**: Can read and list files in your local project without you
  needing to manually specify file paths.
- **Create and edit files**: Can create files and edit multiple files in multiple locations.
  This affects the local files.
- **Resource retrieval**: Can automatically retrieve detailed information about
  issues, merge requests, and pipeline logs of your current project.
- **Multi-source analysis**: Can combine information from multiple sources to
  provide more complete answers to complex questions. You can use [Model Context Protocol](../gitlab_duo/model_context_protocol/_index.md) to connect GitLab Duo Chat (Agentic) to
  external data sources and tools.
- **Custom rules**: Conversations can follow any customised rules that you specify.
- GitLab Duo Chat (Agentic) in the GitLab UI only - **Commit creation**: Can create and push commits.

### Chat feature comparison

| Capability                                              | GitLab Duo Chat (Classic) |                                                         GitLab Duo Chat (Agentic)                                                                                                          |
| ------------                                            |------|                                                         -------------                                                                                                          |
| Ask general programming questions |                       Yes  |                                                          Yes                                                                                                                   |
| Get answers about an open file in the editor |     Yes  |                                                          Yes. Provide the path of the file in your question.                                                                   |
| Provide context about specified files |                   Yes. Use `/include` to add a file to the conversation. |        Yes. Provide the path of the file in your question.                                                                   |
| Autonomously search project contents |                    No |                                                            Yes                                                                                                                   |
| Autonomously create files and change files |              No |                                                            Yes. Ask it to change files. Note, it may overwrite changes that you have made manually and have not committed, yet.  |
| Retrieve issues and MRs without specifying IDs |          No |                                                            Yes. Search by other criteria. For example, an MR or issue's title or assignee.                                       |
| Combine information from multiple sources |               No |                                                            Yes                                                                                                                   |
| Analyze pipeline logs |                                   Yes. Requires Duo Enterprise add-on. |                          Yes                                                                                                                   |
| Restart a conversation |                                  Yes. Use `/reset`. |                                            Yes. Use `/reset`.                                                                                                    |
| Delete a conversation |                                   Yes. Use `/clear`.|                                             Yes, in the chat history                                                                                                            |
| Create issues and MRs |                                   No |                                                            Yes                                                                                                                   |
| Use Git read-only commands |                                                 No |                                                            Yes                                                  |
| Use Git write commands |                                                 No |                                                            Yes, UI only                                                  |
| Run Shell commands |                                      No |                                                            Yes, IDEs only                                                                                                        |
| Run MCP tools |                                      No |                                                            Yes, IDEs only                                                                                                          |

## Use cases

You might find GitLab Duo Chat particularly helpful when you:

- Need answers that require information from multiple files or GitLab resources.
- Want to ask questions about your codebase without having to specify exact file paths.
- Are trying to understand the status of issues or merge requests across a project.
- Want to have files created or edited for you.

### Example prompts

GitLab Duo Chat works best with natural language questions. Here are some examples:

- `Read the project structure and explain it to me`, or `Explain the project`.
- `Find the API endpoints that handle user authentication in this codebase`.
- `Please explain the authorization flow for <application name>`.
- `How do I add a GraphQL mutation in this repository?`
- `Show me how error handling is implemented across our application`.
- `Component <component name> has methods for <x> and <y>. Could you split it up into two components?`
- `Could you add in-line documentation for all Java files in <directory>?`
- `Do merge request <MR URL> and merge request <MR URL> fully address this issue <issue URL>?`

## Troubleshooting

When working with GitLab Duo Chat, you might encounter the following issues.

### Network connectivity problems

Because GitLab Duo Chat (Agentic) requires network access to retrieve resources, network restrictions
might impact its functionality.

To help resolve GitLab Duo Chat networking issues, see the
[GitLab Duo Agent Platform network issue troubleshooting documentation](../duo_agent_platform/troubleshooting.md#network-issues).

### GitLab Duo Chat does not show up in the IDE

You might find that GitLab Duo Chat (Agentic) is not visible in your IDE. To resolve this, make sure that:

1. You have enabled GitLab Duo Chat (Agentic) in the [VS Code](#use-gitlab-duo-chat-in-vs-code) or [JetBrains IDE](#use-gitlab-duo-chat-in-jetbrains-ides) settings.
1. You have one project open in your IDE workspace, and that [project is connected to a GitLab project](../duo_agent_platform/troubleshooting.md#view-the-project-in-the-gitlab-workflow-extension).
1. The [GitLab project is in a group namespace](../duo_agent_platform/troubleshooting.md#project-not-in-a-group-namespace).
1. You have a Premium or Ultimate subscription.
1. [GitLab Duo is turned on](../gitlab_duo/turn_on_off.md).
1. [GitLab Duo experimental and beta features are turned on](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) for your top-level group on GitLab.com, or your instance on GitLab Self-Managed. Contact your administrator if necessary.

### Slow response times

Chat has significant latency when processing requests.

This issue occurs because Chat makes multiple API calls to gather information,
so responses often take much longer compared to Chat.

### Limited permissions

Chat can access the same resources that your GitLab user has permission to
access.

### Search limitations

Chat uses keyword-based search instead of semantic search. This means that
Chat might miss relevant content that does not contain the exact keywords
used in the search.

## Feedback

Because this is a beta feature, your feedback is valuable in helping us improve it.
Share your experiences, suggestions, or issues in [issue 542198](https://gitlab.com/gitlab-org/gitlab/-/issues/542198).

## Related topics

- [Blog: GitLab Duo Chat gets agentic AI makeover](https://about.gitlab.com/blog/2025/05/29/gitlab-duo-chat-gets-agentic-ai-makeover/)
