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

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md): Yes

{{< /collapsible >}}

{{< history >}}

- VS Code [introduced on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/work_items/540917) in GitLab 18.1 as an [experiment](../../policy/development_stages_support.md) with a [flag](../../administration/feature_flags/_index.md) named `duo_agentic_chat`. Disabled by default.
- VS Code [enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196688) in GitLab 18.2.
- GitLab UI [introduced on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/546140) in GitLab 18.2 [with flags](../../administration/feature_flags/_index.md) named `duo_workflow_workhorse` and `duo_workflow_web_chat_mutation_tools`. Both flags are enabled by default.
- Feature flag `duo_agentic_chat` enabled by default in GitLab 18.2.
- JetBrains IDEs [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1077) in GitLab 18.2.
- Changed to beta in GitLab 18.2.
- Visual Studio for Windows [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/245) in GitLab 18.3.
- [Added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721) to GitLab Duo Core in GitLab 18.3.
- Feature flags `duo_workflow_workhorse` and `duo_workflow_web_chat_mutation_tools` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198487) in GitLab 18.4.
- For GitLab Duo Agent Platform on self-managed instances (both with [self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md) and cloud-connected GitLab models), [introduced](https://gitlab.com/groups/gitlab-org/-/epics/19213) in GitLab 18.4, as an [experiment](../../policy/development_stages_support.md#experiment) with a [feature flag](../../administration/feature_flags/_index.md) named `self_hosted_agent_platform`. Disabled by default.

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

- The GitLab UI.
- VS Code.
- A JetBrains IDE.
- Visual Studio for Windows.

### Use GitLab Duo Chat in the GitLab UI

{{< history >}}

- Ability for Chat to remember your most recent conversation [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203653) in GitLab 18.4.

{{< /history >}}

Prerequisites:

- Ensure you meet [the prerequisites](../duo_agent_platform/_index.md#prerequisites).

To use Chat in the GitLab UI:

1. On the left sidebar, select **Search or go to** and find your project.
1. In the upper-right corner, select **Open GitLab Duo Chat** ({{< icon name="duo-chat" >}}). A drawer opens on the right side of your screen.
1. Under the chat text box, turn on the **Agentic mode (Beta)** toggle.
1. Enter your question in the chat text box and press <kbd>Enter</kbd> or select **Send**.
   It may take a few seconds to produce an answer.
1. Optional. Ask a follow-up question.

If you reload the webpage you are on, or go to another webpage, Chat remembers your
most recent conversation, and that conversation is still active in the Chat drawer.

### Use GitLab Duo Chat in VS Code

Prerequisites:

- [Install and configure the GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/setup.md) version 6.15.1 or later.
- Ensure you meet [the other prerequisites](../duo_agent_platform/_index.md#prerequisites).

Turn on GitLab Duo Chat:
<!-- markdownlint-disable MD044 -->
1. In VS Code, go to **Settings** > **Settings**.
1. Search for `agent platform`.
1. Under **Gitlab › Duo Agent Platform: Enabled**, select the
   **Enable GitLab Duo Agent Platform** checkbox.
<!-- markdownlint-enable MD044 -->

Then, to use GitLab Duo Chat:

1. On the left sidebar, select **GitLab Duo Agent Platform (Beta)** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** tab.
1. Select **Refresh page** if prompted.
1. In the message box, enter your question and press <kbd>Enter</kbd> or select **Send**.

### Use GitLab Duo Chat in JetBrains IDEs

Prerequisites:

- [Install and configure the GitLab plugin for JetBrains](../../editor_extensions/jetbrains_ide/setup.md) version 3.11.1 or later.
- Ensure you meet [the other prerequisites](../duo_agent_platform/_index.md#prerequisites).

Turn on GitLab Duo Chat:

1. In your JetBrains IDE, go to **Settings** > **Tools** > **GitLab Duo**.
1. Under **GitLab Duo Agent Platform (Beta)**, select the **Enable GitLab Duo Agent Platform** checkbox.
1. Restart your IDE if prompted.

Then, to use GitLab Duo Chat:

1. On the left sidebar, select **GitLab Duo Agent Platform (Beta)** ({{< icon name="duo-agentic-chat" >}}).
1. Select the **Chat** tab.
1. In the message box, enter your question and press <kbd>Enter</kbd> or select **Send**.

### Use GitLab Duo Chat in Visual Studio

Prerequisites:

- [Install and configure the GitLab extension for Visual Studio](../../editor_extensions/visual_studio/setup.md) version 0.60.0 or later.
- Ensure you meet [the other prerequisites](../duo_agent_platform/_index.md#prerequisites).

Turn on GitLab Duo Chat:

1. In Visual Studio, go to **Tools** > **Options** > **GitLab**.
1. Under **GitLab**, select **General**.
1. For **Enable Agentic Duo Chat (experimental)**, select **True**, and then **OK**.

Then, to use GitLab Duo Chat:

1. Select **Extensions** > **GitLab** > **Open Agentic Chat**.
1. In the message box, enter your question and press **Enter**.

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
1. To have GitLab Duo Chat follow the new custom rules, start a new conversation.

   You must do this every time you change the custom rules.

For more information, see the [Custom rules in GitLab Duo Agentic Chat blog](https://about.gitlab.com/blog/custom-rules-duo-agentic-chat-deep-dive/).

### Select a model

{{< details >}}

- Offering: GitLab.com
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/19251) in GitLab 18.4 as a [beta](../../policy/development_stages_support.md#beta) feature with a [flag](../../administration/feature_flags/_index.md) called `ai_user_model_switching`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

When you use Chat in the GitLab UI, you can select the model to use for conversations. If you open a previous chat from the chat history and continue the conversation,
Chat uses the currently selected model.

Model selection in the IDE is not supported.

Prerequisites:

- No model has been selected for the GitLab Duo Agent Platform feature by the Owner of the top-level group.
If a model has been selected for the group, you cannot change the model for Chat.

To select a model:

1. Under the chat text box, turn on the **Agentic mode (Beta)** toggle.
1. Select a model from the dropdown list.

### Select an agent

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/562708) in GitLab 18.4 for the GitLab UI as an [experiment](../../policy/development_stages_support.md#experiment).

{{< /history >}}

When you use Chat in a project in the GitLab UI, you can select a specific agent for Chat to use.

Prerequisites:

- You must [enable an agent in your project](../duo_agent_platform/agents/_index.md#enable-an-agent)
  from the AI Catalog.

To select an agent:

1. In the GitLab UI, open GitLab Duo Chat.
1. In the upper-right corner of the drawer, select **New chat**.
1. In the dropdown list, select a custom agent. If you have not set up any custom
   agents, there is no dropdown list, and Chat uses the default GitLab Duo agent.
1. Enter your question and press <kbd>Enter</kbd> or select **Send**.

After you create a conversation with a custom agent:

- The conversation remembers the custom agent you selected.
- If you use the chat history to go back to the same conversation, it uses the same agent.

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
| Restart a conversation |                                  Yes. Use `/new` or `/reset`. |                             Yes. Use `/new` or, if in the UI, `/reset`.                                                                                       |
| Delete a conversation |                                   Yes, in the chat history.|                                             Yes, in the chat history                                                                                                            |
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

### Security

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Dedicated

{{< /details >}}

You can use GitLab Duo Chat (Agentic) to triage, manage, and remediate vulnerabilities through natural language commands.

You can use the following security tools in GitLab Duo Chat (Agentic):

Vulnerability information and analysis:

- List all vulnerabilities in a project with filtering by severity and report types.
- Get detailed vulnerability information including CVE data, EPSS scores, and reachability analysis.

Vulnerability management actions:

- Confirm vulnerabilities when verified as genuine security issues.
- Dismiss false positives or acceptable risks with proper reasoning.
- Update vulnerability severity levels based on security review.
- Revert vulnerability status back to detected for re-assessment.

Issue management integration:

- Create GitLab issues automatically linked to vulnerabilities.
- Link existing issues to vulnerabilities for tracking.

#### Security example prompts

- `Show me all critical vulnerabilities in my project`
- `List vulnerabilities with EPSS scores above 0.7 that are reachable`
- `Dismiss all dependency scanning vulnerabilities marked as false positives with unreachable code`
- `Create issues for all confirmed high-severity SAST vulnerabilities and assign them to recent committers`
- `Update severity to HIGH for all vulnerabilities that cross trust boundaries`
- `Show me vulnerabilities dismissed in the past week with their reasoning`
- `Confirm all container scanning vulnerabilities with known exploits`
- `Link vulnerability 123 to issue 456 for tracking remediation`

For more information about these security capabilities, see [epic 19639](https://gitlab.com/groups/gitlab-org/-/epics/19639).

## Troubleshooting

When working with GitLab Duo Chat, you might encounter the following issues.

### Trouble connecting or viewing

To ensure you are connected properly and can view Chat, see [Troubleshooting](../duo_agent_platform/troubleshooting.md).

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
