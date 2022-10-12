---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Productivity analytics **(PREMIUM)**

You can use productivity analytics to identify:

- Your development velocity based on how long it takes for a merge request to merge.
- The most time consuming merge requests and potential causes.
- Authors, labels, or milestones with the longest time to merge, or most changes.

Use productivity analytics to view the following merge request statistics for your groups:

- Amount of time between merge request creation and merge.
- Amount of time between commits, comments, and merge.
- Complexity of changes, like number of lines of code per commit and number of files.

To view merge request data for projects, use [Merge request analytics](../analytics/merge_request_analytics.md).

## View productivity analytics

Prerequisite:

- You must have at least the Reporter role for the group.

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Productivity**.
1. Optional. Filter results:
   1. Select a project from the dropdown list.
   1. To filter results by author, milestone, or label,
   select **Filter results...** and enter a value.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.

## View time metrics for merge requests

Use the following charts in productivity analytics to view the velocity of your merge requests:

- **Time to merge**: number of days it took for a
merge requests to merge after they were created.
- **Trendline**: number of merge requests that were merged in a specific time period.

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Productivity**.

To filter time metrics:

1. To filter the **Trendline** chart, in the **Time to merge** chart, select a column.
1. To view a specific merge request, below the charts, select a merge request from the **List**.

## View commit statistics

To view commit statistics for your group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Productivity**.
1. Under the **Trendline** scatterplot, view the commit statistics:
   - The left histogram shows the number of hours between commits, comments, and merges.
   - The right histogram shows the number of commits and changes per merge request.

To filter commit statistics:

1. To view different types of commit data, select the dropdown list next to each histogram.
1. To view a specific merge request, below the charts, select a merge request from the **List**.
