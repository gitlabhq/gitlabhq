---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure tool-level approval policies for AI agents to gate sensitive actions with human approval at execution time.
title: Agent tool governance
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/20466) in GitLab 19.1 as a [beta](../../policy/development_stages_support.md) with a [feature flag](../../administration/feature_flags/_index.md) named `gitlab_duo_governance_settings`. Enabled by default.
- Enforcement for background flows, such as the Duo Developer foundational flow, added in GitLab 19.3 behind a [feature flag](../../administration/feature_flags/_index.md) named `duo_workflow_background_tool_governance`. Disabled by default.
- Feature flag `gitlab_duo_governance_settings` removed in GitLab 19.4.
- Default for local file reads [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256385) from Always Ask to Always Allow in GitLab 19.5.

{{< /history >}}

> [!warning]
> This feature is in [beta](../../policy/development_stages_support.md).
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

## Access types

Each tool has a separate mode for each access type. The access type depends on
who the agent acts as and where it runs:

Cloud access
: Runs on GitLab as the user.
  For example, GitLab Duo Agentic Chat in the GitLab UI.

Local access
: Runs on the user's machine as the user.
  For example, the IDE extensions and the GitLab Duo CLI.

Background access
: Runs on GitLab as a service account, without waiting for anyone.
  For example, flows started by a trigger or a mention, and code review.

## Default governance matrix

| Classification | Mode |
|------|------|
| Read (GitLab resources) | Always Allow |
| Read (local files) | Always Allow |
| Read (agent session) | Always Allow |
| Write | Always Ask |
| Delete | Always Ask |

### GitLab MCP server tools

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/606073) in GitLab 19.4 with a [feature flag](../../administration/feature_flags/_index.md) named `duo_mcp_tool_governance`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/work_items/607499) in GitLab 19.4.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Tools exposed by the GitLab MCP server appear on the **Tool management** tab
with a source of `mcp`, alongside the GitLab Duo Agent Platform tools. You set
a mode for them the same way, as described in
[Configure tool governance for a group](#configure-tool-governance-for-a-group).

> [!note]
> Tool governance applies when GitLab Duo agents call GitLab MCP server tools.
> These rules do not govern third-party MCP clients that connect directly to the
> GitLab MCP server, such as Claude Desktop, Claude Code, or Cursor.
> To limit the tools these clients receive, see
> [select tool groups (toolsets)](../model_context_protocol/mcp_server.md#select-tool-groups-toolsets).

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
example, setting a mode for `create_merge_request` also applies to the MCP
server tool `save_merge_request`. Set the mode on the GitLab Duo Agent Platform
tool. You don't need to find and set the MCP server tool separately.

If you don't set a mode, behavior is unchanged. Read-only MCP tools remain
pre-approved. Write and delete MCP tools still prompt for approval.

#### Always Deny enforcement

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/258209) in GitLab 19.6 with [feature flags](../../administration/feature_flags/_index.md) named `duo_mcp_server_governance_rule_enforcement` and `duo_workflow_local_tool_governance`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by feature flags.
> For more information, see the history.

**Always Deny** is enforced by the GitLab MCP server, not by the client
that connects to it. A third-party client such as Claude Code or Cursor might
call a denied tool. The server rejects the request before the tool runs, and
returns a JSON-RPC error with code `-32002`. The server uses the mode set for
[local access](#access-types), the same mode that applies to the IDE extensions.

The check happens on the server, so client configuration can't bypass the mode,
and calling a denied tool directly still fails.

Rules are enforced against the group or project the call names in its
arguments, so the tool must identify one. A tool that does not act on a project or
group, such as `get_mcp_server_version`, cannot be governed this way and always
runs. If the call names a project or group that does not exist or that you
cannot access, its rules are not checked, and the tool returns its own error.

Tools that act on multiple projects or groups are checked against the rules of each one,
and a deny in any of them blocks the call.
For example, `save_merge_request` checks both the project in `project_id` and
the one in `target_project_id`, so a deny rule on either project blocks the
call. The most restrictive rule wins, so naming several containers cannot be
used to route around a deny rule. You must treat deny rules as one layer alongside
standard GitLab permissions, not as an absolute block.

A call that names a group is also checked against the rules of the projects in that group.
A deny rule on one of those projects blocks the call, even if you cannot access that project.

Denied tools are also not included in the tool list the server advertises, so a
client does not offer them. A list request does not name any project
or group. Those rules therefore resolve against your default GitLab Duo
namespace, and if you don't have a default namespace, the list is unfiltered. Only rules set
on that namespace apply. A rule set on one of its projects does not hide a tool from the list. Enforcement is
unaffected either way: a denied tool is refused when it is called, even if it
was listed.

#### Always Ask

**Always Ask** is not enforced by the GitLab MCP server. Tools set to **Always Ask**
are listed with an annotation that asks the client to confirm with you first.
The client's implementation determines if the rule is applied.
Only tools you set to **Always Ask** get the annotation. Tools left on **Default**
are not annotated, even when the UI shows "Default (uses Always Ask)".

This applies only to clients connecting to the GitLab MCP server. In GitLab Duo
Agent Platform, Always Ask pauses the agent and asks you to approve. For more
information, see [Approval prompt (Always Ask)](#approval-prompt-always-ask).

| Client | Always Deny | Always Ask |
|---|---|---|
| Claude Code 2.1.199 and later | Enforced | Prompts for confirmation |
| Claude Code earlier than 2.1.199 | Enforced | Runs without prompting |
| Cursor, Windsurf, other MCP clients | Enforced | Runs without prompting |

Always Deny is enforced for every client because the server refuses the call.
Use Always Deny rather than Always Ask when you need stronger enforcement
across all clients.

### Approval prompt (Always Ask)

When a GitLab Duo Agent Platform agent calls a tool configured as
`Always Ask`, execution pauses and an inline approval card is displayed.
The card shows:

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
1. In the left sidebar, select **AI** > **Governance**.
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
1. In the left sidebar, select **AI** > **Governance**.
1. For each tool, select a mode from the dropdown: **Always Allow**, **Always Ask**, or **Always Deny**.
1. Select **Save changes**.

## Block Model Context Protocol (MCP) servers

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/601159) in GitLab 19.3 as a [beta](../../policy/development_stages_support.md) with a [feature flag](../../administration/feature_flags/_index.md) named `mcp_server_block_enforcement`. Disabled by default.
- Enforcement [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251329) for GitLab Self-Managed and GitLab Dedicated in GitLab 19.4, applied when the session's tool configuration is built. Enabled by default.
- Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in GitLab 19.4.

{{< /history >}}

> [!warning]
> This feature is in [beta](../../policy/development_stages_support.md).
> It is subject to change without notice.
> For more information, see [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

In addition to [per-tool governance](#default-governance-matrix), group Owners can block all tools from a specific
external MCP server. When an MCP server is blocked, no tools from that server can be
invoked, regardless of individual tool governance settings or user approvals.

> [!flag]
> Enforcement of MCP server blocks is controlled by a feature flag.
> For more information, see the history.

If enforcement is not enabled on your instance, the MCP Registry still shows the server as blocked.
The block itself does not take effect, so the server's tools remain available to GitLab Duo Agentic Chat.

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
1. In the left sidebar, select **AI** > **Governance**.
1. Select the **MCP Registry** tab.
1. Find the MCP server you want to block and select **Block**.

The block applies from each user's next message or new chat session. Tools from the
blocked server are removed for all users in the group and its subgroups and projects.

#### Block an MCP server for a project

Prerequisites:

- You have the Owner role for the project.

To block an MCP server for a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **AI** > **Governance**.
1. Select the **MCP Registry** tab.
1. Find the MCP server you want to block and select **Block**.

The block applies from each user's next message or new chat session. Tools from the
blocked server are removed for all users in the project. If the same server is also
blocked on an ancestor group, allowing it in the project has no effect until the
group block is removed. The MCP Registry shows these servers as blocked by an
ancestor.

## Known issues

- [Background access](#access-types) supports only **Always Allow** and **Always Deny**.
  **Always Ask** does not apply, because no user is present to respond to an approval prompt
  in a background flow. A tool with no configured background access rule defaults to **Always Allow**.
- The `search` tool served by the GitLab MCP server aggregates what the GitLab Duo Agent Platform
  exposes as separate, narrower search tools, and replaces those tools in the toolset.
  Rules configured on the narrower tools have no effect while `search` is available, including
  **Always Allow**, which the **Tool management** tab still shows as allowed.
  Setting `search` to **Always Deny** removes the aggregated tool and returns the narrower ones,
  which are allowed by default, so search remains available.
  To remove the search tools that `search` replaces, also set `gitlab_issue_search`,
  `gitlab_blob_search`, and `gitlab_merge_request_search` to **Always Deny**. Other search tools,
  such as `gitlab_commit_search` and `gitlab_documentation_search`, have their own rules and stay
  allowed by default. Denying `gitlab_merge_request_search` also denies the `list_merge_requests` tool,
  because governance treats the two names as one tool.
- In GitLab 19.4, setting `search` to **Always Deny** removed `search` without restoring the narrower
  tools, which left the agent with no issue search and no code search.
  This issue is resolved in GitLab 19.5, where denying `search` restores `gitlab_issue_search`,
  `gitlab_blob_search`, and `gitlab_merge_request_search`.

## Related topics

- [AI Governance](_index.md)
- [AI Governance Dashboard](governance-dashboard.md)
- [Control GitLab Duo Agent Platform availability](../duo_agent_platform/turn_on_off.md)
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
- [Audit events](../../administration/compliance/audit_event_reports.md)
