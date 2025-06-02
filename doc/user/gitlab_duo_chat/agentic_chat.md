---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agentic Chat in VS Code
---

{{< details >}}

- Tier: Premium with GitLab Duo Pro, Ultimate with GitLab Duo Pro or Enterprise
- Offering: GitLab.com
- Status: Experiment
- LLMs: Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/540917) in GitLab 18.1. This feature is an [experiment](../../policy/development_stages_support.md).

{{< /history >}}

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

Agentic Chat is only available in the
[GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/_index.md) version 6.15.1 or later.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [GitLab Duo Agentic Chat](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ).
<!-- Video published on 2025-06-02 -->

## Use Agentic Chat in VS Code

Prerequisites:

- A GitLab Duo Core, Pro, or Enterprise add-on.
- A Premium or Ultimate subscription.
- You have an assigned seat for or access to GitLab Duo Chat.
- You have [installed and configured the GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/setup.md) version 6.15.1 or later.
- You have [turned on beta and experimental features](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) for your GitLab instance or group.

You can only use Agentic Chat in a project:

- Open in VS Code.
- Hosted on a GitLab instance.
- That is part of a group that meets the prerequisites.

To use Agentic Chat:

1. In VS Code, go to **Settings > Extensions > GitLab Workflow**.
1. Select **GitLab Duo Pro**.
1. Under **GitLab > Duo Chat > Agentic: Enabled**, select the
   **Enable Access to Agentic Duo Chat (Experimental)** checkbox.
1. On the left sidebar, select **GitLab Duo Agentic Chat** ({{< icon name="duo-agentic-chat" >}}).
1. Optional. Select **Refresh page**, if prompted.
1. In the message box, enter your question and press **Enter** or select **Send**.

Conversations in Agentic Chat do not expire and are stored permanently. You cannot delete these conversations.

## Agentic Chat capabilities

Agentic Chat extends Chat capabilities with the following features:

- **Project Search**: Can search through your projects to find relevant
  issues, merge requests, and other artifacts using keyword-based search. Agentic
  Chat does not have semantic search capability.
- **File Access**: Can read and list files in your local project without you
  needing to manually specify file paths.
- **Create and Edit Files**: Can create files and edit multiple files in multiple locations.
  This affects the local files.
- **Resource Retrieval**: Can automatically retrieve detailed information about
  issues, merge requests, and pipeline logs of your current project.
- **Multi-source Analysis**: Can combine information from multiple sources to
  provide more complete answers to complex questions.

### Chat feature comparison

| Capability | Chat | Agentic Chat |
|------------|------| -------------|
| Ask general programming questions | Yes | Yes |
| Get answers about currently open file in the editor | Yes | Yes. Provide the path of the file in your question. |
| Provide context about specified files | Yes. Use `/include` to add a file to the conversation. | Yes. Provide the path of the file in your question. |
| Autonomously search project contents | No | Yes |
| Autonomously create files and change files | No | Yes. Ask it to change files. Note, it may overwrite changes that you have made manually and have not committed, yet. |
| Retrieve issues and MRs without specifying IDs | No | Yes. Search by other criteria. For example, an MR or issue's title or assignee. |
| Combine information from multiple sources | No | Yes |
| Analyze pipeline logs | Yes. Requires Duo Enterprise add-on. | Yes |
| Restart a conversation | Yes. Use `/reset`. | Yes. Use `/reset`. |
| Delete a conversation | Yes. Use `/clear`.| No. |

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
[GitLab Duo Workflow network issue troubleshooting documentation](../duo_workflow/troubleshooting.md#network-issues).

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
