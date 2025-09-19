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

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a flag](../administration/feature_flags/_index.md) named `global_ai_catalog`. Disabled by default. This feature is in [beta](../policy/development_stages_support.md).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The AI Catalog is a list of agents and flows you can use to add AI to your projects.

## Prerequisites

To view the AI Catalog:

- [GitLab Duo, including GitLab Duo Core and flow execution, must be turned on](gitlab_duo/turn_on_off.md).

In addition, to use agents and flows from the AI Catalog in your projects:

- [Beta and experimental features must be turned on for the project](gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
- Your project must belong to a group namespace with a Premium or Ultimate subscription.

## Related topics

- [GitLab Duo Agentic Chat](gitlab_duo_chat/agentic_chat.md)
- [Flows](duo_agent_platform/flows/_index.md)
