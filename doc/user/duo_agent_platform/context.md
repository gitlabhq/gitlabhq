---
stage: Agent Foundations
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Understand what context is available to GitLab Duo features and how to control what information they can access.
title: GitLab Duo Agent Platform contextual awareness
---

Different information is available to help GitLab Duo make decisions and offer suggestions.

Information can be available:

- Always.
- Based on your location (the context changes when you navigate).
- When referenced explicitly. For example, you mention the information by URL, ID, or file path.

## GitLab Duo Agentic Chat

{{< history >}}

- Current page title and URL [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209186) in GitLab 18.6.

{{< /history >}}

The following context is available to GitLab Duo Agentic Chat.

### Always available

- GitLab documentation.
- General programming knowledge, best practices, and language specifics.
- Your entire project and all of its files that are tracked by Git.
- The GitLab [Search API](../../api/search.md), which Chat uses to find related issues or merge requests.
- When using Chat in the GitLab UI, the current page title and URL.

Chat will automatically look up the necessary context from
SDLC data, [Knowledge Graph](../project/repository/knowledge_graph/_index.md), [MCP Clients](../gitlab_duo/model_context_protocol/mcp_clients.md) and [custom instructions](customize/_index.md).

### Based on location

- In your IDE, files you have open. You can close those files if you do not want them used for context.
- In the GitLab UI, the current page context (for example, when viewing a merge request or issue).

### When referenced explicitly

GitLab Duo Agentic Chat can autonomously retrieve and use:

- Files, including images (PNG, JPEG, WebP), by searching your project or when you provide file paths
- Images attached to issues and merge requests in the project, when you give the upload reference as it appears in the Markdown
- Epics
- Issues
- Merge requests
- CI/CD pipelines and job logs
- Commits
- Work items

Unlike non-agentic Chat, agentic Chat can search for these resources without requiring you to specify exact IDs or URLs. For example, you can ask "Find the merge request about authentication" and Chat searches for relevant merge requests.

For image requirements, see [Image requirements](../project/merge_requests/developer.md#image-requirements).

### Extended context

- To connect Chat to external data sources and tools, use the [Model Context Protocol (MCP)](../gitlab_duo/model_context_protocol/_index.md).
- To provide project-specific context, coding standards, and team practices,
  use [custom rules](customize/custom_rules.md) or [AGENTS.md](customize/agents_md.md) in Chat, agents, and flows.

## Software development flow

The following context is available to the software development flow in GitLab Duo Agent Platform.

### Always available

- General programming knowledge, best practices, and language specifics.
- Your entire project and all of its files that are tracked by Git.
- The GitLab [Search API](../../api/search.md), which is used to find related issues or merge requests.

### Based on location

- Files you have open in the IDE (close files if you do not want them used for context).

### When referenced explicitly

- Files, including images (PNG, JPEG, WebP)
- Images attached to issues and merge requests in the project
- Epics
- Issues
- Merge requests
- The merge request's pipelines

## Exclude context from GitLab Duo

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}
{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/17124) in GitLab 18.2 [with a feature flag](../../administration/feature_flags/_index.md) named `use_duo_context_exclusion`. Disabled by default.
- Changed to beta in GitLab 18.4.
- Enabled by default in GitLab 18.5.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/589801) in GitLab 18.10.

{{< /history >}}

You can control which project content is excluded as context for GitLab Duo.
Use this feature to protect sensitive information, like password and configuration files.

When you exclude content, all GitLab Duo Agent Platform features
exclude this information as context.

### Manage GitLab Duo context exclusions

To specify content that GitLab Duo excludes:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **General**.
1. Under **GitLab Duo**, in the **GitLab Duo context exclusions** section, select **Manage exclusions**.
1. Specify which project files and directories are excluded from GitLab Duo context, and select **Save exclusions**.
1. Optional. To delete an existing exclusion, select **Delete** ({{< icon name="remove" >}}) for the appropriate exclusion.
1. Select **Save changes**.

### Known issues

The following are known issues for context exclusions in the [GitLab MCP server](../model_context_protocol/mcp_server.md):

- The `get_merge_request` tool might return commit diffs that include
  content from excluded files.
  The GitLab MCP server does not check for exclusions when it fetches diffs.
- The `add_commit` tool has a `move` action that
  copies a file from one path to another. If the source file is excluded, the exclusion
  check is not applied to the source path. An agent with push access could move an
  excluded file to a non-excluded path and then read its content.

These known issues are tracked in
[issue 628141](https://gitlab.com/gitlab-org/gitlab/-/work_items/628141).
To ensure protection of sensitive information, review which tools and permissions are granted to MCP clients that access sensitive projects.
