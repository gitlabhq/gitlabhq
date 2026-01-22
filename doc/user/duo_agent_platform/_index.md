---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as a [beta](../../policy/development_stages_support.md) in GitLab 18.2.
- For GitLab Duo Agent Platform on self-managed instances (both with [self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md) and cloud-connected GitLab models), [introduced](https://gitlab.com/groups/gitlab-org/-/epics/19213) in GitLab 18.4, as an [experiment](../../policy/development_stages_support.md#experiment) with a [feature flag](../../administration/feature_flags/_index.md) named `self_hosted_agent_platform`. Disabled by default.
- Feature flag `self_hosted_agent_platform` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951) in GitLab 18.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.
- Feature flag `self_hosted_agent_platform` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218589) in GitLab 18.9.

{{< /history >}}

The GitLab Duo Agent Platform is an AI-native solution that embeds multiple
intelligent assistants ("agents")
throughout the software development lifecycle.

- Instead of following a linear workflow, collaborate asynchronously with AI agents.
- Delegate routine tasks, from code refactoring and security scans to research,
  to specialized AI agents.

To get started, see
[Get started with the GitLab Duo Agent Platform](../get_started/get_started_agent_platform.md).

## Prerequisites

To use the Agent Platform:

- Use GitLab 18.2 or later. For the best experience, use the latest version of GitLab.
- Have purchased [GitLab Credits](../../subscriptions/gitlab_credits.md).
- [GitLab Duo, including GitLab Duo Core and flow execution, must be turned on](../gitlab_duo/turn_on_off.md).
- Depending on your GitLab version:
  - In GitLab 18.8 and later, the [Agent Platform must be turned on](../gitlab_duo/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off).
  - In GitLab 18.7 and earlier, [beta and experimental features must be turned on](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
- For GitLab Self-Managed, you must [ensure your instance is configured](../../administration/gitlab_duo/configure/gitlab_self_managed.md)
  and the composite identity turned on.
- For [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md),
  you must [install and run the AI gateway with GitLab Duo Agent Platform service](../../install/install_ai_gateway.md).

In addition, to use the Agent Platform in your IDE:

- You must install an editor extension, like the GitLab Workflow extension for VS Code, and authenticate with GitLab.
- You must have a project in a [group namespace](../namespace/_index.md) and have at least the Developer role.

## Features

The following features are part of the GitLab Duo Agent Platform.

| Feature | Description |
|---------|-------------|
| [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md) | Enhanced Chat that autonomously performs actions, searches multiple sources, and can create and edit files to answer complex questions. |
| [AI Catalog](ai_catalog.md) | Central list of agents and flows where you can discover, create, and enable them in your projects. |
| [Agents](agents/_index.md) | AI-powered assistants that help accomplish specific tasks. Includes foundational agents (pre-built), custom agents (team-specific), and external agents (third-party integrations). |
| [Flows](flows/_index.md) | One or more agents working together to solve complex problems and automate development tasks. |
| [MCP clients](../gitlab_duo/model_context_protocol/mcp_clients.md) | Standardized way for GitLab Duo features to securely connect to external data sources and tools. |
| [MCP server](../gitlab_duo/model_context_protocol/mcp_server.md) | Enables AI tools like Claude Desktop and Cursor to securely connect to your GitLab instance. |
| [Knowledge Graph](../project/repository/knowledge_graph/_index.md) | Framework that creates structured, queryable representations of code repositories to power AI features. |
