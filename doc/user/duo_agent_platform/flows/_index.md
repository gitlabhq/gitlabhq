---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Flows
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

{{< history >}}

- Introduced as an [experiment](../../../policy/development_stages_support.md) in GitLab 18.4 [with a flag](../../../administration/feature_flags/_index.md) named `ai_catalog_flows`. Disabled by default.
- Changed to [beta](../../../policy/development_stages_support.md) in GitLab 18.7.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/569060) in GitLab 18.7.
- [Enabled on GitLab Self-Managed and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/569060) in GitLab 18.8.
- Additional flags are required for foundational flows.
- Foundational flows [generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.
- Custom flows [changed](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) to beta in GitLab 18.8.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

A flow is a combination of one or more agents working together to solve a complex problem.

GitLab provides two types of flows:

- [Foundational flows](foundational_flows/_index.md) are pre-built,
  production-ready workflows created by GitLab for common development
  tasks.
- [Custom flows](custom.md) are workflows you create to automate your
  team's specific processes. You define the workflow steps and agents, and define triggers to control when the
  flow runs.

Flows are available in IDEs and the GitLab UI.

- In the UI, they run directly in GitLab CI/CD, helping you automate common development tasks without the need to leave your browser.
- In IDEs, the software development flow is available in VS Code, Visual Studio, and JetBrains. Support for other flows is being proposed.

For more information about how flows execute in CI/CD, see [the flow execution documentation](execution.md).
For information about the security of flows, see [the composite identity documentation](../security.md).

## Prerequisites

To use flows:

- You must meet the [prerequisites](../_index.md#prerequisites).

To execute flows in the GitLab UI:

- You must turn on flows with [the GitLab Duo settings](../../gitlab_duo/turn_on_off.md).
- Before you add or execute a flow for the first time, you must
  [allow members to be added to the group your project is in](../troubleshooting.md#allow-members-to-be-added-to-projects).
- To use flows that create code, you must
  [configure push rules to allow a service account](../troubleshooting.md#configure-push-rules-to-allow-a-service-account).

## Monitor running flows in the GitLab UI

To view flows that are running for your project:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Automate** > **Sessions**.

## View flow history in the IDEs

To view a history of flows you've run in your project:

- On the **Flows** tab, scroll down and view **Recent agent sessions**.

## Customize flows with `AGENTS.md`

Use `AGENTS.md` files to provide context and instructions for GitLab Duo to follow while executing
foundational and custom flows.

For more information, see [`AGENTS.md` customization files](../../gitlab_duo/customize_duo/agents_md.md).

## Give feedback

Flows are part of GitLab AI-powered development platform. Your feedback helps us improve these workflows.
To report issues or suggest improvements for flows,
[complete this survey](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu).

## Related topics

- [Configure where flows run](execution.md)
- [Foundational flows](foundational_flows/_index.md)
