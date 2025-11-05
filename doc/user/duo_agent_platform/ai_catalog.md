---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AI Catalog
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/549914) in GitLab 18.5 [with a flag](../../administration/feature_flags/_index.md) named `global_ai_catalog`. Enabled on GitLab.com. This feature is an [experiment](../../policy/development_stages_support.md).
- Support for third-party agents [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207610) in GitLab 18.6 with a flag named `ai_catalog_third_party_flows`. Enabled on GitLab.com.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The AI Catalog is a central list of agents and flows.
Add these agents and flows to your project to get started orchestrating agentic AI tasks.
Agents perform tasks for you, like creating merge requests, and can answer complex questions.

Use the AI Catalog to:

- Discover agents and flows created by the GitLab team and community members.
- Create agents and flows, and share them with other users.
- Enable agents and flows in your projects to use them across the GitLab Duo Agent Platform.

## View the AI Catalog

Prerequisites:

- You must meet the [prerequisites](_index.md#prerequisites).
- To use agents and flows from the AI Catalog, you must have at least the Maintainer role for a project.

To view the AI Catalog:

1. On the left sidebar, select **Search or go to** > **Explore**. If you've [turned on the new navigation](../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **AI Catalog**.

A list of agents is displayed. To view available flows, select the **Flows** tab.

## Related topics

- [Agents](agents/_index.md)
- [Third-party agents](agents/third_party.md)
