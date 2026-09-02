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

### GitLab MCP server tools

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/606073) in GitLab 19.4 with a [feature flag](../../../administration/feature_flags/_index.md) named `duo_mcp_tool_governance`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Tools exposed by the GitLab MCP server appear on the **Tool management** tab
with a source of `mcp`, alongside the GitLab Duo Agent Platform tools. You set
a mode for them the same way, as described in
[Configure tool governance for a group](#configure-tool-governance-for-a-group).

Each tool is sorted into an action category based on the annotations it
declares. There's no maintained list to update, so a newly added MCP tool is
governed automatically:

| Tool declares | Category |
|---|---|
| `destructiveHint: true` | Delete |
| `readOnlyHint: true` | Read |
| `readOnlyHint: false` | Write |
| Neither annotation | Delete |

A tool that declares both `destructiveHint: true` and `readOnlyHint: true` is
sorted as Delete. The categories are resolved in the order shown, so the most
restrictive declaration wins. The tools on the tab also vary by GitLab edition,
license, and enabled features, because those determine which tools the MCP
server exposes.

Many capabilities exist as a GitLab Duo Agent Platform tool and an MCP server
tool. One mode governs both, even when the two tools have different names. For
example, setting a mode for `get_work_item_notes` also applies to the MCP
server tool `get_workitem_notes`. Set the mode on the GitLab Duo Agent Platform
tool. You don't need to find and set the MCP server tool separately.

If you don't set a mode, behavior is unchanged. Read-only MCP tools remain
pre-approved. Write and delete MCP tools still prompt for approval.

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
- Enforcement [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251329) in GitLab 19.4 to apply when the session's tool configuration is built.

{{< /history >}}

> [!warning]
> This feature is in [beta](../../../policy/development_stages_support.md).
> It is subject to change without notice.
> For more information, see [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

In addition to [per-tool governance](#default-governance-matrix), group Owners can block all tools from a specific
external MCP server. When an MCP server is blocked, no tools from that server can be
invoked, regardless of individual tool governance settings or user approvals.

The block is applied when the tools for a chat session are assembled, which happens
on every user message, tool approval, and new session. In practice a block takes
effect at the user's next action: a tool call that is awaiting approval when the
block lands does not run, and from the next message onward the blocked server's
tools are not offered to the agent at all. A tool call that is already running
completes.

Because the tools are silently removed rather than denied, the agent does not
receive a policy message. Agents describe the missing tools in their own words,
and after a server is allowed again, an agent in an existing conversation may
still claim the server is blocked based on the earlier conversation. Start a new
conversation, or ask the agent to retry the tool.

Blocking applies to GitLab Duo Agentic Chat in the UI. IDE and CLI clients configure
MCP servers through local configuration files, which this setting does not control.

This differs from the **Always Deny** tool governance mode:

- **Always Deny** applies to individual tools and is configured per project or group.
- Blocking an MCP server applies to all tools from that server and is configured in
  the MCP Registry. It overrides any user approval or tool governance setting.

> [!note]
> Blocking an MCP server from the MCP Registry requires GitLab 19.3 or later.
> Enforcement requires GitLab 19.4 or later with the `mcp_server_block_enforcement`
> feature flag enabled. When enforcement is unavailable, the block is not enforced
> and tools from the server are allowed by default.

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

The block applies from each user's next message or new chat session. Tools from the
blocked server are removed for all users in the group and its subgroups and projects.

#### Block an MCP server for a project

Prerequisites:

- You have the Owner role for the project.

To block an MCP server for a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **General** > **GitLab Duo**.
1. Select **Change governance**.
1. Select the **MCP Registry** tab.
1. Find the MCP server you want to block and select **Block**.

The block applies from each user's next message or new chat session. Tools from the
blocked server are removed for all users in the project. If the same server is also
blocked on an ancestor group, allowing it in the project has no effect until the
group block is removed. The MCP Registry shows these servers as blocked by an
ancestor.

## Known issues

- The governance UI has three access categories: Web (browser-based sessions),
  Local (IDE and CLI), and Runner (background flows that run in CI/CD runners).
  Runner access supports only Always Allow and Always Deny. Always Ask does not apply,
  because no user is present to respond to an approval prompt in a background flow.
  A tool with no configured runner rule defaults to Always Allow.
- The `search` tool served by the GitLab MCP server aggregates what the
  GitLab Duo Agent Platform exposes as separate, narrower search tools.
  Rules configured on those narrower tools do not extend to `search`. To
  restrict MCP search, configure a rule on `search` directly.

## Related topics

- [Control GitLab Duo Agent Platform availability](../turn_on_off.md)
- [GitLab Duo Agent Platform](../_index.md)
- [Audit events](../../../administration/compliance/audit_event_reports.md)
