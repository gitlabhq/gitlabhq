---
description: "Merge request analytics help you understand the efficiency of your code review process, and the productivity of your team." # Up to ~200 chars long. They will be displayed in Google Search snippets. It may help to write the page intro first, and then reuse it here.
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Merge request analytics

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/229045) in GitLab 13.3.
> - Moved to GitLab Premium in 13.9.

Use merge request analytics to view:

- The number of merge requests your organization merged per month.
- The average time between merge request creation and merge event.
- Information about each merged merge request (such as milestone, commits, line changes, and assignees).

You can use merge request analytics to identify:

- Low or high productivity months.
- The efficiency and productivity of your merge request and code review processes.

## View merge request analytics

Prerequisites:

- You must have at least the Reporter role.

To view merge request analytics:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Merge request analytics**.

## View the number of merge requests in a date range

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/232651) in GitLab 13.3.
> - Filtering [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/229266) in GitLab 13.4

To view the number of merge requests merged during a specific date range:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Merge request analytics**.
1. Optional. Filter results:
   1. Select the filter bar.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.

The **Throughput** chart shows issues closed or merge requests merged (not closed) over a period of
time.

The table shows up to 20 merge requests per page, and includes
the following information about each merge request:

- Merge request name
- Date merged
- Time to merge
- Milestone
- Commits
- Pipelines
- Line changes
- Assignees

## View average time between merge request creation and merge

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/229389) in GitLab 13.9.

The number in **Mean time to merge** shows the average time between when a merge request is
created and when it's merged. Closed and not yet merged merge requests are not included.

To view **Mean time to merge**:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Merge request analytics**. The **Mean time to merge** number
   is displayed on the dashboard.
