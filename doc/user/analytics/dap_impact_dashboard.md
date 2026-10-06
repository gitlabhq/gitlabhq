---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: View the impact of your usage of GitLab Duo Agent Platform across your organization.
title: GitLab Duo Agent Platform Impact dashboard
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/632113) in GitLab 19.5.

{{< /history >}}

This feature is in private [beta](../../policy/development_stages_support.md).
To test this feature, you must [request access](https://gitlab.com/gitlab-org/gitlab/-/work_items/632123).
Share your feedback in [issue 632127](https://gitlab.com/gitlab-org/gitlab/-/work_items/632127).

The GitLab Duo Agent Platform Impact dashboard shows how your organization uses Agent Platform and what that usage costs.
The dashboard displays aggregated data from your groups and projects into metrics for user adoption and engagement,
work activity, and credit consumption.

Use this dashboard to:

- Measure the volume of Agent Platform workflows across your organization.
- Track credit consumption by model, flow type, and group or project.
- Monitor user adoption trends, including retention, churn, and activity tiers.
- Identify which projects and groups are most actively using Agent Platform.

## Overview

The **Overview** tab displays a high-level summary of Agent Platform usage for the selected scope and time period.

- **Active projects**: Number of projects with at least one Agent Platform session.
- **Active users**: Number of users with at least one Agent Platform session.
- **Completed sessions**: Number of created Agent Platform sessions that completed.
- **Credits consumed**: Number of credits consumed by Agent Platform sessions.
- **Where credits went**: Number of credits consumed by each Agent Platform flow type.

## Adoption

The **Adoption** tab displays metrics on how users are adopting Agent Platform features for the selected scope and time period.

The **Users** section displays the following metrics:

- **Total users**: Number of users with at least one Agent Platform session.
- **New vs returning**: Number and percentage of new and returning users with at least one Agent Platform session. Returning users are users who had an Agent Platform session in the previous period of the same length.
- **Users by activity**: Number of users by Agent Platform flow type. A user of multiple flow types counts in each category.

The **Engagement** section displays the following metrics:

- **Multi-activity users**: Number of users with sessions for multiple Agent Platform flow types.
- **Abandonment**: Number of users who used Agent Platform only once.
- **Sessions by tier and top capabilities**: Number of sessions by user tier for the five most used Agent Platform capabilities.

The **Adoption tiers** section displays the following metrics:

- **Users across tiers**: Number of users with at least one Agent Platform session.
- **Total sessions**: Number of Agent Platform sessions across flow types and agents.
- **Share of users vs share of sessions**: Number of users and sessions by user tier.
- **Session intensity by tier**: Number of users and sessions by user tier.
- **Group and project comparison**: Number of users and used credits by group and project.

## Work

The **Work** tab displays metrics on how Agent Platform features are being used for the selected scope and time period.

The **Activity summary** section displays the following metrics:

- **Sessions**: Total number of Agent Platform sessions.
- **Sessions by activity**: Number of Agent Platform sessions by activity.
- **Sessions over time**: Number of Agent Platform sessions created, stacked by flow type.

The **MR cycle time** section displays the following metrics:

- **Created by Duo**: Number of merged merge requests created by GitLab Duo. Median and 75th percentile time in days from open to merged for merge requests.
- **Not created by Duo**: Number of merged merge requests not created by GitLab Duo, but by users. Median and 75th percentile time in days from open to merged for merge requests.
- **Merge requests created by Duo**: Number of merge requests created by GitLab Duo.
- **Duo created merge requests by status**: Number of merge requests created by GitLab Duo with current status over the selected period.

The **Capability outcomes** section displays the following metrics:

- **Agentic Code Review sessions**: Number of sessions of the Code Review flow.
- **Reviews requested**: Number of reviews requested to Code Review.
- **Reviews published**: Number of reviews published by Code Review.
- **With comments**: Number of reviews published by Code Review with at least one comment.
- **Without comments**: Number of reviews published by Code Review with no comment.
- **Agentic Code Review outcomes over time**: Number of reviews requested to and published by Code Review with and without comments over the selected period.
- **Agentic Developer sessions**: Number of sessions of the Developer flow.
- **Completed**: Number of completed sessions of the Developer flow.
- **Paused**: Number of paused sessions of the Developer flow.
- **Canceled**: Number of canceled sessions of the Developer flow.
- **Failed**: Number of failed sessions of the Developer flow.
- **Agentic Developer sessions over time**: Number of completed, paused, canceled, and failed sessions of the Developer flow over the selected period.
- **Agentic Fix Pipeline sessions**: Number of sessions of the Fix Pipeline flow.
- **Suggestions posted**: Number of fix suggestions posted by GitLab Duo on failed pipelines.
- **Suggestions applied**: Number of applied fix suggestions posted by GitLab Duo on failed pipelines.
- **Agentic Fix Pipeline suggestions over time**: Number of fix suggestions posted by GitLab Duo and applied on failed pipelines over the selected period.
- **Agentic SAST sessions**: Number of sessions of the Agentic SAST flow.
- **MRs created after finding vulnerability**: Number of merge requests created by Resolve SAST Vulnerability sessions.
- **Agentic SAST sessions over time**: Number of SAST flow sessions created and merge requests created in the sessions.

## Spend

The **Spend** tab displays metrics on how much Agent Platform features are being used for the selected scope and time period.

- **Credits by model, by capability**: Number of credits used by different models, stacked by Agent Platform capability.
- **Credits**: Total number of credits consumed.
- **Chat**: Number of credits consumed by Chat sessions.
- **Credits over time**: Number of credits used over time, stacked by capability.

## View the dashboard

Prerequisites:

- The Owner role for the group to view credit usage data.

1. In the top bar, select **Search or go to** > **Explore**.
1. In the left sidebar, select **Analytics dashboards**.
1. Select **DAP Impact**.
1. Select the tabs to view the different metrics.
1. Optional. By default the dashboard displays metrics for the top-level group in the last 30 days.
   You can filter the results:

   - To view metrics for specific groups or projects, in the respective tab, from the **Scope** dropdown list, select the groups or projects you want to view.
   - To view metrics for a different time period, in the respective tab, from the **Period** dropdown list, select the period you want to view.
   - To reset the selected scope and period, select **Reset**.

1. To analyze the displayed metrics with GitLab Duo, select **Analyze with Duo**.
