---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Learn about foundational, custom, and external agents available in the GitLab Duo Agent Platform.
title: Agents
---

{{< details >}}

- Tier: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- [Default LLM](../model_selection.md#default-models)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a flag](../../../administration/feature_flags/_index.md) named `global_ai_catalog`. Enabled on GitLab.com.
- Foundational and custom agents [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/568176) to beta in GitLab 18.7.
- Foundational, external, and custom agents [generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.
- Feature flag `global_ai_catalog` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223135) in 18.10.
- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.

{{< /history >}}

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
  foundational agents. To interact with a custom agent, enable it in a
  group or project to use it with Chat.
- [External agents](external.md) integrate with AI model providers
  outside GitLab. Use external agents to allow model providers like
  Claude to operate in GitLab. You can trigger an external agent
  directly from a discussion, issue, or merge request.
