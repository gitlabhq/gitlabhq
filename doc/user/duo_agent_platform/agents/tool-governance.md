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
- Enforcement for background flows, such as the Duo Developer foundational flow, added in GitLab 19.3 behind a [feature flag](../../../administration/feature_flags/_index.md) named `duo_workflow_background_tool_governance`. Disabled by default.

{{< /history >}}

> [!warning]
> This feature is in [beta](../../../policy/development_stages_support.md).
> It is subject to change without notice.
> For more information, see [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

Tool governance sits at the execution boundary. After an agent has been
admitted to a project, and before a tool is invoked, the governance layer
consults the configured rules for the user's role and the tool's action
category, then enforces the resulting mode.

> [!flag]
> Enforcement for background flows is controlled by a feature flag.
> For more information, see the history.

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

This feature applies to Agentic Chat and IDE extensions. For flows, governance
enforcement depends on where the flow runs:

- For flows that run in an IDE extension, GitLab enforces governance rules.
- For background flows, such as the Duo Developer foundational flow, GitLab enforces governance rules.

## Default governance matrix

| Classification | Mode |
|------|------|
| Read (GitLab resources) | Always Allow |
| Read (local files) | Always Ask |
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
uses the default governance matrix value.

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

## Block Model Context Protocol (MCP) servers

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/601159) in GitLab 19.3 as a [beta](../../../policy/development_stages_support.md) with a [feature flag](../../../administration/feature_flags/_index.md) named `mcp_server_block_enforcement`. Disabled by default.

{{< /history >}}

> [!warning]
> This feature is in [beta](../../../policy/development_stages_support.md).
> It is subject to change without notice.
> For more information, see [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

In addition to [per-tool governance](#default-governance-matrix), group Owners can block all tools from a specific
external MCP server. When an MCP server is blocked, no tools from that server can be
invoked, regardless of individual tool governance settings or user approvals.

This block is enforced on every tool call, including mid-session. If an administrator
blocks an MCP server while a workflow is running, subsequent calls to tools from that
server are denied immediately.

When a tool from a blocked MCP server is called, the agent receives a policy message
instead of a tool result. The agent cannot use any tools from that server.

This differs from the **Always Deny** tool governance mode:

- **Always Deny** applies to individual tools and is configured per project or group.
- Blocking an MCP server applies to all tools from that server and is configured in
  the MCP Registry. It overrides any user approval or tool governance setting.

> [!note]
> Blocking an MCP server requires GitLab 19.3 or later. On older GitLab Self-Managed
> and Dedicated instances, the block is not enforced and tools from the server are
> allowed by default. In GitLab 19.3, enforcing the block requires one additional
> request per MCP tool call.

### Block an MCP server

You can block an MCP server at the group or project level:

- **Group level**: blocks the server for all projects in the group and their subgroups.
  If a server is blocked at the group level, project-level settings cannot unblock it.
- **Project level**: blocks the server for that project only.

#### Block an MCP server for a group

Prerequisites:

- You have the Owner role for the top-level group.

To block an MCP server for a group:

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Select **Change governance**.
1. Select the **MCP Registry** tab.
1. Find the MCP server you want to block and select **Block**.

The block applies immediately. All tools from the blocked server are denied for all users
in the group and its subgroups and projects.

#### Block an MCP server for a project

Prerequisites:

- You have the Owner role for the project.

To block an MCP server for a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **General** > **GitLab Duo**.
1. Select **Change governance**.
1. Select the **MCP Registry** tab.
1. Find the MCP server you want to block and select **Block**.

The block applies immediately. All tools from the blocked server are denied for all users
in the project.

## Known issues

- The governance UI has three access categories: Web (browser-based sessions),
  Local (IDE and CLI), and Runner (background flows that run in CI/CD runners).
  Runner access supports only Always Allow and Always Deny. Always Ask does not apply,
  because no user is present to respond to an approval prompt in a background flow.
  A tool with no configured runner rule defaults to Always Allow.

## Related topics

- [Control GitLab Duo Agent Platform availability](../turn_on_off.md)
- [GitLab Duo Agent Platform](../_index.md)
- [Audit events](../../../administration/compliance/audit_event_reports.md)
