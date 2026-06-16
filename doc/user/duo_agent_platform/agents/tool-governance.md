---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure tool-level approval policies for GitLab Duo agents to gate sensitive actions with human approval at execution time.
title: Agent tool governance
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/20466) in GitLab 19.1 as a [beta](../../../policy/development_stages_support.md) with a [feature flag](../../../administration/feature_flags/_index.md) named `gitlab_duo_governance_settings`. Enabled by default.

{{< /history >}}

> [!warning]
> This feature is in [beta](../../../policy/development_stages_support.md).
> It is subject to change without notice.
> For more information, see [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

Tool governance sits at the execution boundary. After an agent has been
admitted to a project, and before a tool is invoked, the governance layer
consults the configured rules for the user's role and the tool's action
category, then enforces the resulting mode.

Tools are classified into three action categories:

- **Read**: Tools that only retrieve or display information.
- **Write**: Tools that create or modify resources.
- **Delete**: Tools that delete or irreversibly remove resources.

Agent tool governance (human-in-the-loop guardrail) lets administrators define how each agent tool is
enforced at the moment of execution. Instead of allowing agents to invoke
any tool without review, you can configure each tool to one of three modes:

- **Always Allow**: The tool executes silently without prompting the user.
- **Always Ask**: The user is shown an inline approval card and must approve
  or reject the action before it proceeds.
- **Always Deny**: The tool is blocked entirely and is invisible to the agent.
  The agent never sees the tool and the user is never prompted.

This feature applies across Agentic Chat, IDE extensions, and flows.

## Default governance matrix

| Classification | Mode |
|------|------|
| Read | Always Allow |
| Write | Always Ask |
| Delete | Always Ask |

### Approval prompt (Always Ask)

When an agent calls a tool configured as **Always Ask**, execution pauses
and an inline approval card is displayed. The card shows:

- The name of the tool being invoked.
- A description of the action the tool will perform.
- **Approve** and **Reject** buttons.

If you approve, the tool executes and the agent continues. If you reject,
the tool is not executed. The agent receives a rejection signal and may
attempt an alternative approach or stop.

### Denial message (Always Deny)

When an agent attempts to invoke a tool that is configured as **Always Deny**
for your role, the tool is not surfaced to the agent. If the agent's plan
requires a denied tool, it receives an error indicating the tool is
unavailable due to governance policy.

## Rule resolution and cascading

Rules are resolved in the following order, from most specific to least specific:

1. Project-level rule (if configured).
1. Group-level rule (if configured).
1. Default matrix value.

Project-level rules override group-level rules for the same tool, but can
only be equal to or stricter than the group-level rule. Group-level rules
override the defaults. If no rule is configured at any level, the tool
defaults to Always Allow.

The fail-closed principle applies. If the governance service encounters
a persistent error when resolving rules, the agent receives no tools rather 
than silently allowing execution.

## Configure tool governance for a group

Group-level rules apply to all projects in the group unless overridden
at the project level.

Prerequisites:

- You have the Owner role for the top-level group.

To configure tool governance rules for a group:

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change governance**.
1. For each tool, select a mode from the **Mode** dropdown list: **Always Allow**, **Always Ask**, or **Always Deny**.
1. Select **Save changes**.

Changes apply to all subgroups and projects that do not have a project-level override.

## Configure tool governance for a project

Project-level rules override the group-level rules for the same tool
within that project.

Prerequisites:

- You have the Maintainer or Owner role for the project.

To configure tool governance rules for a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Select **Change governance**.
1. For each tool, select a mode from the dropdown: **Always Allow**, **Always Ask**, or **Always Deny**.
1. Select **Save changes**.

## Related topics

- [Control GitLab Duo Agent Platform availability](../turn_on_off.md)
- [GitLab Duo Agent Platform](../_index.md)
- [Audit events](../../../administration/compliance/audit_event_reports.md)
