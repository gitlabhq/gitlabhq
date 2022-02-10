---
description: "Merge request analytics help you understand the efficiency of your code review process, and the productivity of your team." # Up to ~200 chars long. They will be displayed in Google Search snippets. It may help to write the page intro first, and then reuse it here.
stage: Manage
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Merge request analytics **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/229045) in GitLab 13.3.
> - Moved to GitLab Premium in 13.9.

Use merge request analytics to view:

- The number of merge requests your organization merged per month.
- The average time between merge request creation and merge.
- Information about each merged merge request.

You can use merge request analytics to identify:

- Low or high productivity months.
- Efficiency and productivity of your merge request process.
- Efficiency of your code review process.

## View merge request analytics

You must have at least the Reporter role to view merge request analytics.

To view merge request analytics:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > Merge request**.

## View merge requests merged per month

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/232651) in GitLab 13.3.
> - Filtering [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/229266) in GitLab 13.4

To view the number of merge requests merged per month:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > Merge request**.
1. Optional. Filter results:   
   1. Select the filter bar.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
       - In the **From** field, select a start date.
       - In the **To** field, select an end date.

The **Throughput** chart shows the number of merge requests merged per month.

The table shows up to 20 merge requests per page, and includes
information about each merge request.

## View average time between merge request creation and merge

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/229389) in GitLab 13.9.

Use the number in **Mean time to merge** to view the average time between when a merge request is
created and when it's merged.

To view **Mean time to merge**:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > Merge request**.
