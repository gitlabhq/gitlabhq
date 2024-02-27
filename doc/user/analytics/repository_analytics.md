---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Repository analytics for projects

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Use repository analytics to view information about a project's Git repository:

- Programming languages used in the repository's default branch.
- Code coverage history from last 3 months ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33743) in GitLab 13.1).
- Commit statistics (last month).
- Commits per day of month.
- Commits per weekday.
- Commits per day hour (UTC).

Repository analytics is part of [GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss). It's available to anyone who has permission to clone the repository.

Repository analytics requires:

- An initialized Git repository.
- At least one commit in the default branch (`main` by default).

NOTE:
Without a Git commit in the default branch, the menu item isn't visible.
Commits in a project's [wiki](../project/wiki/index.md#track-wiki-events) are not included in the analysis.

## View repository analytics

To review repository analytics for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Repository analytics**.

## How repository analytics chart data is updated

Data in the charts are queued. Background workers update the charts 10 minutes after each commit in the default branch.
Depending on the size of the GitLab installation, it may take longer for data to refresh due to variations in the size of background job queues.
