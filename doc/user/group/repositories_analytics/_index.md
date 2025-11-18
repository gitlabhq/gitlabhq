---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Repository analytics for groups
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Repository analytics for groups provides test coverage data for all projects in a group.

You can use group repository analytics to:

- Monitor code coverage trends across all projects in a group.
- Track the total number of projects and jobs that generate coverage reports.
- Download historical coverage data for analysis.

Support for subgroups is proposed in [issue 273527](https://gitlab.com/gitlab-org/gitlab/-/issues/273527).

## View group repository analytics

Prerequisites:

- Projects within the group must be configured to collect test coverage data.

To view repository analytics for a group:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Analyze** > **Repository analytics**.

## Coverage metrics

The group **Repository analytics** page displays:

- **Current group code coverage**:
  - Number of projects with coverage reports.
  - Average coverage percentage across all projects.
  - Total number of pipeline jobs that produce coverage reports.

- **Average test coverage**: A graph that shows the average test coverage across all projects in your group for the last 30 days.

- **Latest test coverage results**: A list of the most recent coverage data for each project in your group. Select projects from the dropdown list to filter the results.

## Download coverage data

You can download a CSV file containing historical coverage data for projects in your group.

The CSV report:

- Contains up to 1000 records.
- Includes data from the default branch of each project.
- Shows one row per day when coverage was reported.
- Uses the last value of the day if multiple coverage reports were generated.
- Contains the following information for each coverage report:
  - Date the coverage job ran
  - Name of the job that generated the report
  - Project name
  - Coverage percentage

To download the coverage data:

1. On the group **Repository analytics** page, select **Download historic test coverage data (.csv)**.
1. Select the projects to include:
   - From the **Projects** dropdown list, choose specific projects. The projects dropdown list shows up to 100 projects.
   - Optional. Select **Select all** to include all projects in your group.
1. From the **Date range** dropdown list, select the time period to include.
1. Select **Download test coverage data (.csv)**.

## Related topics

- [Repository analytics for projects](../../analytics/repository_analytics.md)
- [Code coverage](../../../ci/testing/code_coverage/_index.md)
