---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Data Analyst Agent
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/578342) in GitLab 18.6 [with a flag](../../../../administration/feature_flags/_index.md) named `foundational_analytics_agent`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

The Data Analyst Agent is a specialized AI assistant that helps you query, visualize, and surface
data across the GitLab platform. It uses [GitLab Query Language (GLQL)](../../../glql/_index.md)
to retrieve and analyze data, then provides clear, actionable insights about your projects and teams.

Use the Data Analyst Agent when you need help with:

- Volume analysis: Counting merge requests, issues, or other work items over time periods.
- Team performance: Understanding what team members have worked on and their output.
- Trend analysis: Identifying patterns in your development workflow.
- Status monitoring: Checking the state of work items across your project or group.
- Work item discovery: Finding issues, merge requests, or epics by author, label, milestone, or other criteria.
- GLQL query generation: Creating queries to embed anywhere that supports GitLab Flavored Markdown,
  including issues, merge requests, epics, comments, wikis, snippets, and releases.

You can leave feedback in [issue 574028](https://gitlab.com/gitlab-org/gitlab/-/issues/574028).

## Known issues

- The agent can perform light aggregation on queried data, but results may be
  incomplete for datasets exceeding 100 items.
- GLQL supports querying [specific areas](../../../glql/_index.md#supported-areas)
  but not all GitLab data sources.
- The agent cannot output directly to work items or dashboards. However, you can copy the generated GLQL
  queries and embed them on any page that supports GitLab Flavored Markdown.

## Access the Data Analyst Agent

Prerequisites:

- Foundational agents must be [turned on](_index.md#turn-foundational-agents-on-or-off).

1. Open GitLab Duo Chat:

   On the GitLab Duo sidebar, select either **New GitLab Duo Chat** ({{< icon name="pencil-square" >}}) or **Current GitLab Duo Chat** ({{< icon name="duo-chat" >}}).

   A Chat conversation opens in the GitLab Duo sidebar on the right side of your screen.

1. From the **New chat** ({{< icon name="duo-chat-new" >}}) dropdown list, select **Data Analyst**.
1. Enter your analytics question or request. To get the best results from your request:

   - Specify the scope (project or group) when asking about data.
   - Include time ranges for time-based analysis.
   - Be specific about the type of work items you're interested in.

## Example prompts

- Volume and counting:
  - "How many merge requests were merged this month?"
  - "Count the issues created last week."
  - "How many bugs are currently open?"
- Team performance:
  - "What has @username worked on this month?"
  - "Show me merge requests merged by team X in the last two weeks."
  - "Show me a table of issues with titles and labels assigned to me."
  - "List open merge requests by author."
- Status and monitoring:
  - "Show me open issues with ~priority::1 and ~bug labels."
  - "Show me overdue issues."
  - "What merge requests are waiting for review?"
  - "List issues in the current milestone."
- Trend analysis:
  - "Show me the merge request activity over the last month."
  - "What's the trend of bug creation this quarter?"
  - "Compare issue closure rates between this month and last month."
- GLQL query generation:
  - "Write a GLQL query for open issues assigned to me."
  - "Create a table showing all merge requests merged this week."
  - "Generate a GLQL embedded view for team X's open work."
  - "What's the GLQL syntax for filtering by multiple labels?"
- Work item discovery:
  - "List merge requests targeting the main branch."
  - "Find issues updated in the last 24 hours."
  - "Show me open bugs assigned to team X."
