---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Contribution analytics
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Contribution analytics provide an overview of the
[contribution events](../../profile/contributions_calendar.md#user-contribution-events)
your group's members made in the last week, month, or three months.
Interactive bar charts and a detailed table show contribution events
(push events, issues, and merge requests) by group member.

![Contribution analytics bar graphs](img/contribution_analytics_push_v17_7.png)

Use contribution analytics to get insights into team activity and individual performance, and use this information for:

- Workload balancing: Analyze your group's contributions over a period of time, and identify group members who are high performers or may benefit from additional support.
- Team collaboration: Evaluate the balance of contributions, such as code pushes versus reviews or approvals, to ensure collaborative development practices.
- Training opportunities: Identify areas where team members may benefit from mentorship or training, such as low merge request approval or issue resolution rates.
- Retrospective evaluation: Incorporate contribution analytics into retrospectives to assess how effectively the team met objectives and where adjustments may be needed.

### Tracking

Contribution analytics are based on push events, because they provide a more reliable view of contributions than unique commits.
Counting unique commits may lead to duplication when commits are pushed across multiple branches.
By tracking push events instead, GitLab ensures that every contribution is counted accurately.

For example, a user pushes three commits to branch A in one push.
Later, the user pushes two of those commits from branch A to branch B.
GitLab records five commits, though the user made three unique commits.

## View contribution analytics

To view contribution analytics:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Analyze > Contribution analytics**.
1. Optional. Filter the results:

   - To view contribution analytics for last week, month, or three months, select one of the three tabs.
   The selected time period applies to all charts and the table.
   - To zoom in on a bar chart to display only a subset of group members,
   select the sliders ({{< icon name="status-paused" >}}) below the chart and slide them along the axis.
   - To sort the contributions table by a column, select the column header or the chevron
   ({{< icon name="chevron-lg-down" >}} for descending order, {{< icon name="chevron-lg-up" >}} for ascending order).

1. Optional. To view a group member's contributions, either:

   - On the **Contribution analytics** bar charts, hover over the bar with the member's name.
   - In the **Contributions per group member** table, select the member's name.
   The member's GitLab profile is displayed, and you can explore their [contributions calendar](../../profile/contributions_calendar.md).

To retrieve metrics for user contributions, you can also use the [GraphQL API](../../../api/graphql/reference/_index.md#groupcontributions).

## Contribution analytics with ClickHouse

On GitLab.com, contribution analytics run through the ClickHouse Cloud cluster.
On GitLab Self-Managed, when you configure the ClickHouse integration, the ClickHouse `events` table is automatically populated from the PostgreSQL `events` table. This process might take some time for large installations. After the table is fully synchronized, new events become available in ClickHouse with a delay of about three minutes.

For more information, see:

- [ClickHouse integration guidelines](../../../integration/clickhouse.md)
- [ClickHouse usage at GitLab](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/clickhouse_usage/)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
