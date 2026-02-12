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

- Have [GitLab Duo turned on](../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off).
- If you do not have GitLab Duo Enterprise or Pro, have [GitLab Duo Core turned on](../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off).
- Depending on your GitLab version:
  - In GitLab 18.8 and later, have the [Agent Platform turned on](../gitlab_duo/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off).
  - In GitLab 18.7 and earlier, have [beta and experimental features turned on](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
- For GitLab Self-Managed, [configure your instance](../../administration/gitlab_duo/configure/gitlab_self_managed.md).
- For GitLab Duo Self-Hosted, [install the AI Gateway](../../install/install_ai_gateway.md) with the Agent Platform service.

To use the Agent Platform in your IDE:

- Install an editor extension and authenticate with GitLab.
- Have a project in a [group namespace](../namespace/_index.md).
- Have the Developer, Maintainer, or Owner role.

## Use cases

Solve these use cases by using the GitLab Duo Agent Platform.

| Use case | Feature |
|-------------|---------|
| Answer complex questions by searching multiple sources and autonomously creating and editing files. | [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md) |
| Automate repetitive tasks: Triage issues, fix bugs, generate tests, add documentation, analyze vulnerabilities. | [Agents](agents/_index.md) - Includes foundational agents (pre-built), custom agents (team-specific), and external agents (third-party integrations).|
| Solve complex problems and automate development tasks by making one or more agents work together: Fix CI/CD pipelines, review and modernize code, fix vulnerabilities. | [Flows](flows/_index.md) |
| Discover, create, and enable agents and flows from this central list. | [AI Catalog](ai_catalog.md) |
| Customize the Agent Platform with custom rules for Agentic Chat, AGENTS.md files for project-specific context, and code review instructions to enforce coding standards. | [Customization](customize/_index.md) |
| Securely connect GitLab Duo features to external data sources and tools. | [MCP clients](../gitlab_duo/model_context_protocol/mcp_clients.md) |
| Securely connect AI tools and applications to your GitLab instance. | [MCP server](../gitlab_duo/model_context_protocol/mcp_server.md) |
| Create structured, queryable representations of code repositories and use them to power AI features. | [Knowledge Graph](../project/repository/knowledge_graph/_index.md) |
