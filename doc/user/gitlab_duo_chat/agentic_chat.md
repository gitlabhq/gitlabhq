---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agentic Chat
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta
- LLMs: Anthropic [Claude Sonnet 4](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /details >}}

{{< history >}}

- VS Code [introduced on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/work_items/540917) in GitLab 18.1 as an [experiment](../../policy/development_stages_support.md) with a [flag](../../administration/feature_flags/_index.md) named `duo_agentic_chat`. Disabled by default.
- VS Code [enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196688) in GitLab 18.2.
- GitLab UI [introduced on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/546140) in GitLab 18.2 [with flags](../../administration/feature_flags/_index.md) named `duo_workflow_workhorse` and `duo_workflow_web_chat_mutation_tools`. Both flags are enabled by default.
- Feature flag `duo_agentic_chat` enabled by default in GitLab 18.2.
- JetBrains IDEs [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1077) in GitLab 18.2.
- GitLab Duo Agentic Chat changed to beta in GitLab 18.2.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by feature flags.
For more information, see the history.

{{< /alert >}}

GitLab Duo Agentic Chat is an enhanced version of GitLab Duo Chat that can autonomously
perform actions on your behalf to answer complex questions more comprehensively.

While Chat answers questions based on a single context, Agentic Chat searches,
retrieves, and combines information from multiple sources across your GitLab projects
to provide more thorough and relevant answers. Agentic Chat can also create and edit
files for you.

"Agentic" means that Agentic Chat:

- Autonomously uses a large language model to determine what information is needed.
- Executes a sequence of operations to gather that information.
- Formulates a response to your questions.
- Can create and change local files.

For larger problems, like understanding a codebase or generating an implementation
plan, use the [software development flow of the GitLab Duo Agent Platform](../duo_agent_platform/_index.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [GitLab Duo Agentic Chat](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ).
<!-- Video published on 2025-06-02 -->

## Use Agentic Chat

You can use Agentic Chat in the GitLab UI, VS Code, or a JetBrains IDE.

Prerequisites:

- A GitLab Duo Core, Pro, or Enterprise add-on.
- A Premium or Ultimate subscription.
- You have an assigned seat for or access to GitLab Duo Chat.
- You have [turned on beta and experimental features](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) for your GitLab instance or group.

### Use Agentic Chat in the GitLab UI

To use Agentic Chat in the GitLab UI:

1. Go to a project in a group that meets the prerequisites.
1. In the upper-right corner, select **GitLab Duo Chat**. A drawer opens on the right side of your screen.
1. Under the chat text box, turn on the **Agentic mode (Beta)** toggle.
1. Enter your question in the chat text box and press <kbd>Enter</kbd> or select **Send**. It may take a few seconds for the interactive AI chat to produce an answer.
1. Optional. Ask a follow-up question.

### Use Agentic Chat in VS Code

Prerequisites:

- You have [installed and configured the GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/setup.md) version 6.15.1 or later.

You can only use Agentic Chat in a project:

- Hosted on a GitLab instance.
- That is part of a group that meets the prerequisites.

To use Agentic Chat:
<!-- markdownlint-disable MD044 -->
1. In VS Code, go to **Settings > Settings**.
1. Search for `gitlab agentic`.
1. Under **Gitlab › Duo Agentic Chat: Enabled**, select the
   **Enable GitLab Duo Agentic Chat** checkbox.
1. On the left sidebar, select **GitLab Duo Agentic Chat** ({{< icon name="duo-agentic-chat" >}}).
1. Select **Refresh page** if prompted.
1. In the message box, enter your question and press **Enter** or select **Send**.
<!-- markdownlint-enable MD044 -->
Conversations in Agentic Chat do not expire and are stored permanently. You cannot delete these conversations.

### Use Agentic Chat in JetBrains IDEs

Prerequisites:

- You have [installed and configured the GitLab plugin for JetBrains](../../editor_extensions/jetbrains_ide/setup.md) version 3.11.1 or later.

To use Agentic Chat in a project, it must be:

- Hosted on a GitLab instance.
- Part of a group that meets the prerequisites.

To use Agentic Chat:
<!-- markdownlint-disable MD044 -->
1. In your JetBrains IDE, go to **Settings > Tools > GitLab Duo**.
1. Under **Features**, select the **Enable GitLab Duo Agentic Chat** checkbox.
1. Restart your IDE if prompted.
1. On the left sidebar, select **GitLab Duo Agentic Chat** ({{< icon name="duo-agentic-chat" >}}).
1. In the message box, enter your question and press **Enter** or select **Send**.
<!-- markdownlint-enable MD044 -->
Conversations in Agentic Chat do not expire and are stored permanently. You cannot delete these conversations.

### Create custom rules

{{< history >}}

- Custom rules [added](https://gitlab.com/gitlab-org/gitlab/-/issues/550743) in GitLab 18.2.

{{< /history >}}

In VS Code or a JetBrains IDE, if you have specific instructions that you want
Agentic Chat to follow in every conversation, you can create custom rules.

Prerequisites:

- For VS Code, [install and configure the GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/setup.md) version 6.32.2 or later.
- For a JetBrains IDE, [install and configure the GitLab plugin for JetBrains](../../editor_extensions/jetbrains_ide/setup.md) version 3.12.2 or later.

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
1. To have Agentic Chat follow the new custom rules, start a new conversation, or `/clear` the existing conversation.

   You must do this every time you change the custom rules.

## Agentic Chat capabilities

Agentic Chat extends Chat capabilities with the following features:

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
  provide more complete answers to complex questions. You can use [Model Context Protocol](../gitlab_duo/model_context_protocol/_index.md) to connect Agentic Chat to
  external data sources and tools.
- **Custom rules**: Conversations can follow any customised rules that you specify.
- Agentic Chat in the GitLab UI only - **Commit creation**: Can create and push commits.

### Chat feature comparison

| Capability                                              | Chat |                                                         Agentic Chat                                                                                                          |
| ------------                                            |------|                                                         -------------                                                                                                          |
| Ask general programming questions |                       Yes  |                                                          Yes                                                                                                                   |
| Get answers about currently open file in the editor |     Yes  |                                                          Yes. Provide the path of the file in your question.                                                                   |
| Provide context about specified files |                   Yes. Use `/include` to add a file to the conversation. |        Yes. Provide the path of the file in your question.                                                                   |
| Autonomously search project contents |                    No |                                                            Yes                                                                                                                   |
| Autonomously create files and change files |              No |                                                            Yes. Ask it to change files. Note, it may overwrite changes that you have made manually and have not committed, yet.  |
| Retrieve issues and MRs without specifying IDs |          No |                                                            Yes. Search by other criteria. For example, an MR or issue's title or assignee.                                       |
| Combine information from multiple sources |               No |                                                            Yes                                                                                                                   |
| Analyze pipeline logs |                                   Yes. Requires Duo Enterprise add-on. |                          Yes                                                                                                                   |
| Restart a conversation |                                  Yes. Use `/reset`. |                                            Yes. Use `/reset`.                                                                                                    |
| Delete a conversation |                                   Yes. Use `/clear`.|                                             No                                                                                                                    |
| Create issues and MRs |                                   No |                                                            Yes                                                                                                                   |
| Use Git |                                                 No |                                                            Yes, IDEs only                                                                                                        |
| Run Shell commands |                                      No |                                                            Yes, IDEs only                                                                                                        |
| Run MCP tools |                                      No |                                                            Yes, IDEs only                                                                                                          |

## Use cases

You might find Agentic Chat particularly helpful when you:

- Need answers that require information from multiple files or GitLab resources.
- Want to ask questions about your codebase without having to specify exact file paths.
- Are trying to understand the status of issues or merge requests across a project.
- Want to have files created or edited for you.

### Example prompts

Agentic Chat works best with natural language questions. Here are some examples:

- `Read the project structure and explain it to me`, or `Explain the project`.
- `Find the API endpoints that handle user authentication in this codebase`.
- `Please explain the authorization flow for <application name>`.
- `How do I add a GraphQL mutation in this repository?`
- `Show me how error handling is implemented across our application`.
- `Component <component name> has methods for <x> and <y>. Could you split it up into two components?`
- `Could you add in-line documentation for all Java files in <directory>?`
- `Do merge request <MR URL> and merge request <MR URL> fully address this issue <issue URL>?`

## Troubleshooting

When working with Agentic Chat, you might encounter the following issues.

### Network connectivity problems

Because Agentic Chat requires network access to retrieve resources, network restrictions
might impact its functionality.

To help resolve Agentic Chat networking issues, see the
[GitLab Duo Agent Platform network issue troubleshooting documentation](../duo_agent_platform/troubleshooting.md#network-issues).

### Slow response times

Agentic Chat has significant latency when processing requests.

This issue occurs because Agentic Chat makes multiple API calls to gather information,
so responses often take much longer compared to Chat.

### Limited permissions

Agentic Chat can only access resources that your GitLab user has permission to
access, which is the same as Chat.

### Search limitations

Agentic Chat uses keyword-based search instead of semantic search. This means that
Agentic Chat might miss relevant content that does not contain the exact keywords
used in the search.

## Feedback

Because this is an experimental feature, your feedback is valuable in helping us improve it.
Share your experiences, suggestions, or issues in [issue 542198](https://gitlab.com/gitlab-org/gitlab/-/issues/542198).

## Related topics

- [Blog: GitLab Duo Chat gets agentic AI makeover](https://about.gitlab.com/blog/2025/05/29/gitlab-duo-chat-gets-agentic-ai-makeover/)
