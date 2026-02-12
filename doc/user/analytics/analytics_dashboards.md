---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Analytics dashboards
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduced in GitLab 15.9 as an [experiment](../../policy/development_stages_support.md#experiment) feature [with a flag](../../administration/feature_flags/_index.md) named `combined_analytics_dashboards`. Disabled by default.
- `combined_analytics_dashboards` [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/389067) by default in GitLab 16.11.
- `combined_analytics_dashboards` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/454350) in GitLab 17.1.
- `filters` configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/505317) in GitLab 17.9. Disabled by default.
- Inline visualizations configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/509111) in GitLab 17.9.
- [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195086) from GitLab Ultimate to GitLab Premium in 18.2.

{{< /history >}}

Analytics dashboards help you visualize collected data on built-in dashboards.

An enhanced dashboard experience is proposed in [epic 13801](https://gitlab.com/groups/gitlab-org/-/epics/13801) and [epic 19430](https://gitlab.com/groups/gitlab-org/-/work_items/19430).

## Data sources

{{< history >}}

- Product analytics and custom visualization data sources [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/497577) in GitLab 17.7.

{{< /history >}}

A data source is a connection to a database or collection of data which can be used by your dashboard
filters and visualizations to query and retrieve results.

## Built-in dashboards

To help you get started with analytics, GitLab provides built-in dashboards with predefined visualizations.
These dashboards are labeled **By GitLab**.

The following built-in dashboards are available:

- [**Value Streams Dashboard**](value_streams_dashboard.md) displays metrics related to DevOps performance, security exposure, and workstream optimization.
- [**GitLab Duo and SDLC trends**](duo_and_sdlc_trends.md) displays the impact of AI tools on software development lifecycle (SDLC) metrics for a project or group.
- [**DORA Metrics Dashboard**](dora_metrics_charts.md) displays the evolution of each DORA metric over time.
- [**Merge request analytics**](merge_request_analytics.md) displays metrics for merge request throughput and mean time to merge.

## View project dashboards

Prerequisites:

- You must have the Reporter, Developer, Maintainer, or Owner role for the project.

To view a list of dashboards for a project:

1. On the top bar, select **Search or go to** and find your project.
1. Select **Analyze** > **Analytics dashboards**.
1. From the list of available dashboards, select the dashboard you want to view.

## View group dashboards

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390542) in GitLab 16.2 [with a flag](../../administration/feature_flags/_index.md) named `group_analytics_dashboards`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/416970) in GitLab 16.8.
- Feature flag `group_analytics_dashboards` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/439718) in GitLab 16.11.

{{< /history >}}

Prerequisites:

- You must have the Reporter, Developer, Maintainer, or Owner role for the group.

To view a list of dashboards for a group:

1. On the top bar, select **Search or go to** and find your group.
1. Select **Analyze** > **Analytics dashboards**.
1. From the list of available dashboards, select the dashboard you want to view.
