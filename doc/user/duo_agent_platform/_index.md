---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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
- GitLab Duo Agent Platform and GitLab Credits supported on GitLab 18.8 and later.
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

- Have [GitLab Duo turned on](turn_on_off.md#turn-gitlab-duo-on-or-off).
- If you do not have GitLab Duo Pro or Enterprise,
  have [GitLab Duo Core turned on](turn_on_off.md#turn-gitlab-duo-core-on-or-off) for the top-level group or instance.
- Depending on your GitLab version:
  - In GitLab 18.8 and later, have the [Agent Platform turned on](turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off).
  - In GitLab 18.7 and earlier, have [beta and experimental features turned on](turn_on_off.md#turn-on-beta-and-experimental-features).
- For GitLab Self-Managed, [configure your instance](../../administration/gitlab_duo/configure/gitlab_self_managed.md).
- For GitLab Duo Self-Hosted, [install the AI Gateway](../../install/install_ai_gateway.md) with the Agent Platform service.

To use the Agent Platform in your local environment:

- Install an editor extension and authenticate with GitLab.
- Have a project in a [group namespace](../namespace/_index.md).
- Have the Developer, Maintainer, or Owner role.

## Generally available features

These features are generally available and consume [GitLab Credits](../../subscriptions/gitlab_credits.md) when used.

| Feature | Description |
|---------|-------------|
| [GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md) | Answer complex questions and autonomously create and edit files. |
| [Planner Agent](agents/foundational_agents/planner.md) | Plan, prioritize, and track work. |
| [Security Analyst Agent](agents/foundational_agents/security_analyst_agent.md) | Automate repetitive security tasks: Triage issues, analyze vulnerabilities, and generate fixes. |
| [Custom agents](agents/custom.md) | Build team-specific agents for your unique development requirements. |
| [External agents](agents/external.md) | Securely connect third-party integrations and tools to extend Agent Platform capabilities. |
| [Software Development Flow](flows/foundational_flows/software_development.md) | Create a full, multi-step plan before executing it. |
| [Developer Flow](flows/foundational_flows/developer.md) | Convert issues into merge requests. |
| [Fix CI/CD Pipeline Flow](flows/foundational_flows/fix_pipeline.md) | Diagnose and automatically fix failing CI/CD pipelines. |
| [Convert to GitLab CI/CD Flow](flows/foundational_flows/convert_to_gitlab_ci.md) | Convert legacy CI/CD pipelines to the GitLab CI/CD format. |
| [Code Review Flow](flows/foundational_flows/code_review.md) | Automate code review tasks and enforce coding standards across your team. |
| [Code Suggestions](code_suggestions/_index.md) | Get AI-powered suggestions as you write code. |

## Beta and experiment features

These features are either beta or experiment and do not consume GitLab Credits.

> [!warning]
> When a feature becomes generally available, usage of the feature starts to consume GitLab Credits on all GitLab versions and on all offerings.
> Beta features can change to generally available with usage billing at any time.

| Feature | Description |
|---------|-------------|
| [Data Analyst Agent](agents/foundational_agents/data_analyst.md) | Analyze data and generate insights from your development metrics and project data. |
| [Custom flows](flows/custom.md) | Combine multiple agents to solve your business problems. |
| [SAST False Positive Detection Flow](flows/foundational_flows/sast_false_positive_detection.md) | Automatically identify and filter out false positives in SAST security scans. |
| [SAST Vulnerability Resolution Flow](flows/foundational_flows/agentic_sast_vulnerability_resolution.md) | Automatically generate fixes and remediation steps for SAST vulnerabilities. |
| [MCP server](../gitlab_duo/model_context_protocol/mcp_server.md) | Securely connect AI tools and applications to your GitLab instance. |
| [Knowledge Graph](../project/repository/knowledge_graph/_index.md) | Create structured, queryable representations of code repositories to power AI features. |
