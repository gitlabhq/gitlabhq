---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as [a beta](../../policy/development_stages_support.md) in GitLab 18.2.
- For GitLab Duo Agent Platform on self-managed instances (both with [self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md) and cloud-connected GitLab models), [introduced](https://gitlab.com/groups/gitlab-org/-/epics/19213) in GitLab 18.4, as an [experiment](../../policy/development_stages_support.md#experiment) with a [feature flag](../../administration/feature_flags/_index.md) named `self_hosted_agent_platform`. Disabled by default.
- Feature flag `self_hosted_agent_platform` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951) in GitLab 18.7.

{{< /history >}}

With the GitLab Duo Agent Platform, multiple AI agents can work in parallel, helping you create code,
research results, and perform tasks simultaneously.
The agents have full context across your entire software development lifecycle.

The Agent Platform is made up of [several features](../gitlab_duo/feature_summary.md),
which are available in the GitLab UI and IDEs.

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [Developer Onboarding with GitLab Duo Agent Platform](https://youtu.be/UD8vAAglkY0?si=7AWWDfd-mLGdkBwT).
<!-- Video published on 2025-11-20 -->

## Prerequisites

To use the Agent Platform:

- Use GitLab 18.2 or later. For the best experience, use the latest version of GitLab.
- [GitLab Duo, including GitLab Duo Core and flow execution, must be turned on](../gitlab_duo/turn_on_off.md).
- [Beta and experimental features must be turned on](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).
- For GitLab Self-Managed, you must [ensure your instance is configured](../../administration/gitlab_duo/setup.md)
  and the composite identity turned on.
- For [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md),
  you must [install and run the AI gateway with GitLab Duo Agent Platform service](../../install/install_ai_gateway.md).

In addition, to use the Agent Platform in your IDE:

- You must install an editor extension, like the GitLab Workflow extension for VS Code, and authenticate with GitLab.
- You must have a project in a [group namespace](../namespace/_index.md) and have at least the Developer role.

## Related topics

- [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md)
- [Flows](flows/_index.md)
