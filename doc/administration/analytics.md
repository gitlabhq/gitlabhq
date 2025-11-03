---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: Enable and configure ClickHouse for data analytics in GitLab.
title: Use ClickHouse for analytics reports
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- ClickHouse data collector [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414610) in GitLab 16.3 [with a flag](feature_flags/_index.md) named `clickhouse_data_collection`. Disabled by default.
- Feature flag `clickhouse_data_collection` removed in GitLab 17.0 and replaced with an application setting.

{{< /history >}}

The [contribution analytics](../user/group/contribution_analytics/_index.md) report, [CI/CD analytics dashboard](../user/analytics/ci_cd_analytics.md), and [Value Streams Dashboard](../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) contributors count metric can use ClickHouse as a data source.

Prerequisites:

- You must have [ClickHouse configured](../integration/clickhouse.md) on your instance.

To enable ClickHouse:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select your avatar and then select **Admin**.
1. Select **Settings** > **General**.
1. In the **Analytics** section, select the **Enable ClickHouse** checkbox.
