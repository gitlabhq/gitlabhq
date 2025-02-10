---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Repository analytics for projects
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Repository analytics is part of [GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss)
and is available to users with permission to clone the repository.

Use repository analytics to view information about a project's Git repository, such as:

- Programming languages used in the repository's default branch.
- Code coverage statistics for the last three months.
- Commit statistics for the last month.
- Number of commits per day of month, per weekday, and per hour.

## Chart data processing

Data in the charts is queued.
Background workers update the charts 10 minutes after each commit to the default branch.
Depending on the size of GitLab installation and background job queues, it might take longer for data to refresh.

## View repository analytics

Prerequisites:

- You must have an initialized Git repository.
- There must be at least one commit in the default branch (`main` by default), excluding commits in a project's [wiki](../project/wiki/_index.md#track-wiki-events), which are not included in the analysis.

To view repository analytics for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Repository analytics**.
1. To view details about a category, hover over a bar in the chart.
1. To view statistics of code coverage and commits in a specific branch, from the dropdown list next to **Commit statistics**, select a branch.
