---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Monitor AI agent sessions, audit logs, and developer exposure across your organization from a central dashboard.
title: AI Governance Dashboard
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com
- Status: Limited availability

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/603776) in GitLab 19.4 in [beta](../../policy/development_stages_support.md) with a [feature flag](../../administration/feature_flags/_index.md) named `ai_governance_dashboard`. Enabled by default.
- The **Show** control's **All agents** and **Connected** options [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/618950) in GitLab 19.4 [with a feature flag](../../administration/feature_flags/_index.md) named `ai_governance_connected_agents_filter`. Disabled by default.
- Date range filter with 7-day and 30-day windows [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/610984) in GitLab 19.5.
- **Total number of tool calls** tile and **Top tools used by agents** card [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/618956) in GitLab 19.5 [with a feature flag](../../administration/feature_flags/_index.md) named `ai_governance_tool_calls`. Enabled by default.
- **Tool calls by risk** card [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/259004) in GitLab 19.5 [with a feature flag](../../administration/feature_flags/_index.md) named `ai_governance_tool_calls`. Enabled by default.
- **Which AI agents developers are using** card [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/629071) in GitLab 19.5 [with a feature flag](../../administration/feature_flags/_index.md) named `ai_governance_dashboard_charts`. Enabled by default.
- Sessions from connected agents and the audit event count on the **Most recent sessions** card [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/630095) in GitLab 19.5 [with a feature flag](../../administration/feature_flags/_index.md) named `ai_governance_sessions_api`. Enabled by default.
- The **Show** control's **All agents** and **Connected** options [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/260271) in GitLab 19.5.

{{< /history >}}

> [!flag]
> The availability of some tiles and cards on this page is controlled by feature flags.
> For more information, see the history.

Security and compliance teams can use AI Governance Dashboard to monitor AI agent activity across a
group.

> [!warning]
> This feature is in [beta](../../policy/development_stages_support.md).
> It is subject to change without notice.
> For more information, see [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

AI Governance Dashboard surfaces key performance indicators and data cards that give you
visibility on:

- How AI agents are being used.
- Which developers are most active.
- Which projects have the most exposure.

The dashboard shows data for GitLab Duo Agent Platform (DAP) agents and, when the **Show** control
offers it, for connected agents. Connected agents are external coding agents such as Claude Code,
Cursor, and OpenCode that report their sessions to GitLab. By default, the dashboard covers the last
7 days. You can change the date range to the last 30 days.

Prerequisites:

- You have the Owner role for the top-level group, or a custom role with the
  `read_agent_artifacts` ability.

## View the dashboard

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **AI** > **Governance**.
1. Select the **Dashboard** tab.

## Filter the dashboard

Two controls at the top of the dashboard filter the tiles and most cards:

- **Show**: The agents to include:
  - **All agents** (default): GitLab Duo Agent Platform agents and connected agents.
  - **DAP**: GitLab Duo Agent Platform agents.
  - **Connected**: Connected agents.

- **Date range**: **Last 7 days** (default) or **Last 30 days**.

Each card that ignores the date range says so below its list.

## Key performance indicator (KPI) tiles

The dashboard header shows up to three KPI tiles. Each tile displays a count for the
selected date range and a sparkline showing the daily trend. The tile also shows
the change compared to the previous period of the same length.

### Total number of agents

The **Total number of agents** tile shows the number of distinct active agent
instances in the selected date range. An agent instance is unique per user,
project, namespace, agent type, and environment. A connected agent instance is
unique per user, project, agent type, and agent identity. GitLab Duo Agentic Chat
conversations are excluded from this count.

### Total number of agent sessions

The **Total number of agent sessions** tile shows the total number of agent
workflow sessions in the selected date range. This includes all DAP workflow
types: IDE, web, chat, and ambient sessions. Agentic Chat is included. With **All agents**
or **Connected**, the tile also counts sessions of connected agents.

### Total number of tool calls

The **Total number of tool calls** tile shows the number of times agents invoked
a tool in the selected date range. Every invocation counts, so a tool called 10
times adds 10. The tile counts tool calls from GitLab Duo agents and from connected agents
that report them, such as Claude Code.

## Data cards

Below the KPI tiles, data cards provide breakdowns of agent activity.

### Which AI agents developers are using

The **Which AI agents developers are using** card shows a ring chart of the
distinct developers who used AI agents in the selected date range. The total is
in the center of the chart. The slices depend on the **Show** control:

- With **All agents**, one slice per agent product, such as **GitLab Duo**, **Claude Code**,
  **Cursor**, or **OpenCode**.
- With **DAP**, one slice per GitLab Duo Agent Platform flow type, such as chat, code review, or
  software development.
- With **Connected**, one slice per connected agent type.

Hover over a slice to see its developer count and its share of all developers. A
developer who used two agents is counted in both slices, so the shares can add up
to more than 100%.

Select **View all agents** to open the group's **Agents** page.

### Top tools used by agents

The **Top tools used by agents** card lists the 10 tools that agents invoked most
often in the selected date range, with the number of calls for each. The card
follows the **Show** control and the date range.

Select **View tool management** to open the **Tool management** tab, where you set
what each tool is allowed to do.

### Tool calls by risk

The **Tool calls by risk** card shows a ring chart of the tool calls in the
selected date range, grouped by the risk level of the tool, as set in
**Tool management**:

- **Read**
- **Write**
- **Destructive**
- **Unclassified**, for tools that the tool registry does not know.

The total number of calls is in the center of the chart. The legend shows each
level's share.

Select **View tool registry** to open the **Tool management** tab.

### Most recent sessions

The **Most recent sessions** card lists the latest agent sessions, newest first.
It ignores the date range. It follows the **Show** control.

The card lists sessions from GitLab Duo and from connected agents. Each row
shows the agent that ran the session, such as **GitLab Duo**, **Claude Code (glab)**,
**Cursor (glab)**, or **Claude Code (Compliance API)**, and the number of audit
events the session produced.

Select a GitLab Duo session to open it in the
[AI audit event report](ai-audit-events.md). Select a connected agent session to
open the report without opening a session. Select **View all audit logs** to open
the full report.

### Most used agents

The **Most used agents** card lists the agents used most in your group over the
last 30 days, with the project each agent belongs to. The ranking always covers
30 days, whatever date range you select.

### Most active developers using agents

The **Most active developers using agents** card shows the top users by agent session count
over the selected date range. Use this to understand which developers are most
actively using AI agents.

### Projects with the most active agent sessions

The **Projects with the most active agent sessions** card shows the top projects
by agent session count over the selected date range. Use this to identify which
projects have the highest volume of AI agent activity.

### MCP servers

The **MCP servers** card lists the Model Context Protocol (MCP) servers
registered for your group, with their status. Use this to see which external
MCP servers your agents can reach.

To read a server's full description, hover over or focus the truncated
description text.

The card lists registered servers only. It does not show how often each server
is used.

## Related topics

- [AI Governance](_index.md)
- [Tool governance](tool-governance.md)
- [GitLab Duo Agent Platform](../duo_agent_platform/_index.md)
