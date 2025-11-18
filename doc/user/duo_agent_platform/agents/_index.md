---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Agents
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a flag](../../../administration/feature_flags/_index.md) named `global_ai_catalog`. Enabled on GitLab.com.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Agents are AI-powered assistants that help you accomplish specific
tasks and answer complex questions.

GitLab provides three types of agents:

- [Foundational agents](foundational_agents/_index.md) are pre-built,
  production-ready agents created by GitLab for common
  workflows. These agents come with specialized expertise and tools
  for specific domains. Foundational agents are turned on by default,
  so you can start using them with GitLab Duo Chat.
- [Custom agents](custom.md) are agents you create and configure for
  your team's specific needs. You define their behavior through system
  prompts, and choose what tools they can access. Custom agents are
  ideal when you need specialized workflows that aren't covered by
  foundational agents, such as automating your team's code review
  process or managing project-specific tasks. To interact with a
  custom agent, enable it in a group or project to use it with Chat.
- [External agents](external.md) integrate with AI model providers
  outside GitLab. Use external agents to allow model providers like
  Claude to operate directly in GitLab. You can trigger an
  external agent directly from a discussion, issue, or merge request.

To use agents, you must meet the [prerequisites](../_index.md#prerequisites).
