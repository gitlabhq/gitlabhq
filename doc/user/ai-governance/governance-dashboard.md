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
- Date range filter with 7-day and 30-day windows [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/610984) in GitLab 19.5.

{{< /history >}}

> [!warning]
> This feature is in [beta](../../policy/development_stages_support.md).
> It is subject to change without notice.
> For more information, see [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

Security and compliance teams can use AI Governance Dashboard to monitor AI agent activity across a
group. AI Governance Dashboard surfaces key performance indicators and data cards that give you
visibility on:

- How AI agents are being used.
- Which developers are most active.
- Which projects have the most exposure.

The dashboard shows data for GitLab Duo Agent Platform (DAP) agents. By default, it covers the last
7 days. You can change the date range to the last 30 days.

## Prerequisites

- You have the Owner role for the top-level group, or a custom role with the
  `read_agent_artifacts` ability.
- The `ai_governance_dashboard` feature flag is enabled for your group.

## View the dashboard

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **AI** > **Governance**.
1. Select the **Dashboard** tab.

## Filter the dashboard

Two controls at the top of the dashboard filter the tiles and most cards:

- **Show**: The agent class. **DAP** shows GitLab Duo Agent Platform agents.
- **Date range**: **Last 7 days** (default) or **Last 30 days**.

Each card that ignores the date range says so below its list.

## Key performance indicator (KPI) tiles

The dashboard header shows two KPI tiles. Each tile displays a count for the
selected date range and a sparkline showing the daily trend. The tile also shows
the change compared to the previous period of the same length.

### Total number of agents

The **Total number of agents** tile shows the number of distinct active agent
instances in the selected date range. An agent instance is unique per user,
project, namespace, agent type, and environment. Duo Chat conversations are
excluded from this count.

### Total number of agent sessions

The **Total number of agent sessions** tile shows the total number of agent
workflow sessions in the selected date range. This includes all DAP workflow
types: IDE, web, chat, and ambient sessions. Duo Chat is included.

## Data cards

Below the KPI tiles, data cards provide breakdowns of agent activity.

### Most recent sessions

The **Most recent sessions** card lists the latest agent sessions, newest first.
It ignores the date range. Select a session to open it in the
[AI audit event report](ai-audit-events.md), or select **View all audit logs**
to see the full report.

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
