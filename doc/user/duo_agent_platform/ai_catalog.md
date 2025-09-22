---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AI Catalog
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta
- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a flag](../../administration/feature_flags/_index.md) named `global_ai_catalog`. Disabled by default. This feature is in [beta](../../policy/development_stages_support.md).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The AI Catalog is a list of agents you can use to add agentic AI to your projects.
Agents perform tasks for you, like creating merge requests, and can answer complex questions.

Use the AI Catalog to:

- Discover agents created by the GitLab team and community members.
- Create agents and share them across projects.
- Add agents to your projects and use them with GitLab Duo Agentic Chat.

## View the AI Catalog

Prerequisites:

- You must meet the [prerequisites](_index.md#prerequisites).
- To use agents from the AI Catalog, you must have a project that belongs to a group namespace with a Premium or Ultimate subscription.

To view the AI Catalog:

1. On the left sidebar, select **Search or go to** > **Explore**.
1. Select **AI Catalog**.
