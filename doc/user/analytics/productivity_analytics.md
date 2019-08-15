# Productivity Analytics **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/12079) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.2 (enabled by feature flags `analytics` and `productivity_analytics`).

Track development velocity with Productivity Analytics.

For many companies, the development cycle is a blackbox and getting an estimate of how
long, on average, it takes to deliver features is an enormous endeavor.

While [Cycle Analytics](../project/cycle_analytics.md) focuses on the entire
SDLC process, Productivity Analytics provides a way for Engineering Management to
drill down in a systematic way to uncover patterns and causes for success or failure at
an individual, project or group level.

Productivity can slow down for many reasons ranging from degrading code base to quickly
growing teams. In order to investigate, department or team leaders can start by visualizing the time
it takes for merge requests to be merged.

## Supported features

Productivity Analytics allows GitLab users to:

- Visualize typical Merge Request lifetime and statistics. Use a histogram
  that shows the distribution of the time elapsed between creating and merging
  Merge Requests.
- Drill down into the most time consuming Merge Requests, select a number of outliers,
  and filter down all subsequent charts to investigate potential causes.
- Filter by group, project, author, label, milestone, or a specific date range.
  Filter down, for example, to the Merge Requests of a specific author in a group
  or project during a milestone or specific date range.

## Accessing metrics and visualizations

To access the **Productivity Analytics** page, go to **Analytics > Productivity Analytics**.

The following metrics and visualizations are available on a project or group level:

- Histogram showing the number of Merge Request that took a specified number of days to
  merge after creation. Select a specific column to filter down subsequent charts.
- Histogram showing a breakdown of the time taken (in hours) to merge a Merge Request.
  The following intervals are available:
  - Time from first commit to first comment.
  - Time from first comment until last commit.
  - Time from last commit to merge.
- Histogram showing the size or complexity of a Merge Request, using the following:
  - Number of commits per Merge Request.
  - Number of lines of code per commit.
  - Number of files touched.
- Table showing list of Merge Requests with their respective times and size metrics.
  Can be sorted by the above metrics.
  - Users can sort by any of the above metrics

## Retrieving data

Users can retrieve three months of data when they deploy Productivity Analytics for the first time.

To retrieve data for a different time span, run the following in the GitLab directory:

```sh
MERGED_AT_AFTER = <your_date> rake gitlab:productivity_analytics:recalc
```

## Permissions

The **Productivity Analytics** dashboard can be accessed only:

- On GitLab instances and namespaces on
  [Premium or Silver tier](https://about.gitlab.com/pricing/) and above.
- By users with [Reporter access](../permissions.md) and above.
