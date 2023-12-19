---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Productivity analytics **(PREMIUM ALL)**

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

Prerequisites:

- You must have at least the Reporter role for the group.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Analyze > Productivity analytics**.
1. Optional. Filter results:
   1. From the **Projects** dropdown list, select a project.
   1. To filter results by author, milestone, or label,
   select **Filter results...** and enter a value.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.

## View time metrics for merge requests

To view time metrics for merge requests:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Analyze > Productivity analytics**.
   Time metrics are displayed on the following charts:
   - **Time to merge**: number of days it took for a merge requests to merge after they were created.
   - **Trendline**: number of merge requests that were merged in a specific time period.
1. Optional. Filter the results:
   - To filter the **Trendline** chart, in the **Time to merge** chart, select a bar.
   - To view a specific merge request, below the charts, from the **List** table select a merge request.

## View commit statistics

To view commit statistics for your group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Analyze > Productivity analytics**.
   Commit statistics are displayed under the **Trendline** scatterplot:
   - The left histogram shows the number of hours between commits, comments, and merges.
   - The right histogram shows the number of commits and changes per merge request.
1. Optional. Filter results:
   - To view different types of commit data, from the dropdown list next to each histogram, select an option.
   - To view a specific merge request, below the charts, from the **List** table select a merge request.
