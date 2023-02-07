---
type: reference
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
# Contribution Analytics **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3090) in GitLab 12.2 for subgroups.

With Contribution Analytics, you can get an overview of the [contribution events](../../profile/contributions_calendar.md#user-contribution-events) in your
group.

- Analyze your team's contributions over a period of time.
- Identify opportunities for improvement with group members who may benefit from additional
  support.

## View Contribution Analytics

To view Contribution Analytics:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Contribution**.

Three bar graphs illustrate the number of contributions made by each group member:

- Push events
- Merge requests
- Closed issues

### View a member's contributions

Hover over each bar to display the number of events for a specific group member.

![Contribution analytics bar graphs](img/group_stats_graph.png)

### Zoom in on a chart

You can zoom in on a bar chart to display only a subset of group members.

To do this, select the sliders (**{status-paused}**) below the chart and slide them along the axis.

### Sort contributions

Contributions per group member are also presented in tabular format. Select a column header to sort the table by that column:

- Member name
- Number of pushed events
- Number of opened issues
- Number of closed issues
- Number of opened MRs
- Number of merged MRs
- Number of closed MRs
- Number of total contributions

![Contribution analytics contributions table](img/group_stats_table.png)

## Change the time period

You can choose from the following three periods:

- Last week (default)
- Last month
- Last three months

Select the desired period from the calendar dropdown list.

![Contribution analytics choose period](img/group_stats_cal.png)

## Contribution analytics GraphQL API

To retrieve metrics for user contributions, use the [GraphQL](../../../api/graphql/reference/index.md#groupcontributions) API.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
