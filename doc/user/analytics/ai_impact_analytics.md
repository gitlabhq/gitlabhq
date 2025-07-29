---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AI impact analytics
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443696) in GitLab 16.11 [with a flag](../../administration/feature_flags/_index.md) named `ai_impact_analytics_dashboard`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/451873) in GitLab 17.2. Feature flag `ai_impact_analytics_dashboard` removed.
- Changed to require GitLab Duo add-on in GitLab 17.6.

{{< /history >}}

AI impact analytics measure the impact of GitLab Duo on software development lifecycle (SDLC) performance.
This dashboard provides visibility into key SDLC metrics in the context of AI adoption for projects or groups.
You can use the dashboard to measure which metrics have improved from your AI investments.

Use AI impact analytics for:

- Correlation observations: Examine how trends in AI usage in a project or group influence other crucial productivity metrics. AI usage metrics are displayed for the last six months, including the current one.
- Snapshot of GitLab Duo usage: Track the use of seats and features in a project or group over the last 30 days.

To learn how you can optimize your license utilization,
see [GitLab Duo add-ons](../../subscriptions/subscription-add-ons.md).

To learn more about AI impact analytics, see the blog post
[Developing GitLab Duo: AI impact analytics dashboard measures the ROI of AI](https://about.gitlab.com/blog/2024/05/15/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/).

For a click-through demo, see the [AI impact analytics product tour](https://gitlab.navattic.com/ai-impact).

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [GitLab Duo AI Impact Dashboard](https://youtu.be/FxSWX64aUOE?si=7Yfc6xHm63c3BRwn).
<!-- Video published on 2025-03-06 -->

## Key metrics

- **Assigned Duo seat engagement**: Percentage of users that are assigned a Duo seat and used at least one AI feature in the last 30 days.
It is calculated as the number of users with Duo seats that use AI features divided by the total number of assigned Duo seats.
- **Code Suggestions: Usage**: Percentage of users that engage with Code Suggestions every month.
It is calculated as the number of monthly unique Code Suggestions users divided by total monthly [unique contributors](../profile/contributions_calendar.md#user-contribution-events).
Only unique code contributors (users with `pushed` events) are included in the calculation.
- **Code Suggestions: Acceptance rate**: Percentage of code suggestions provided by GitLab Duo that have been accepted by code contributors in the last 30 days.
It is calculated as the number of accepted code suggestions divided by the total number of generated code suggestions.
- **Duo Chat: Usage**: Percentage of users that engage with GitLab Duo Chat every month.
It is calculated as the number of monthly unique GitLab Duo Chat users divided by the total GitLab Duo assigned users.

{{< alert type="note" >}}

For tracking Code Suggestions events, GitLab collects data only from code editor extensions.
[Epic 14203](https://gitlab.com/groups/gitlab-org/-/epics/14203) proposes support for the Web IDE as well.

{{< /alert >}}

## Metric trends

The **Metric trends** table displays metrics for the last six months, with monthly values, percentage changes in the past six months, and trend sparklines.

### Lifecycle metrics

- [**Lead time**](../group/value_stream_analytics/_index.md#lifecycle-metrics)
- [**Median time to merge**](merge_request_analytics.md)
- [**Deployment frequency**](dora_metrics.md#deployment-frequency)
- [**Merge request throughput**](merge_request_analytics.md#view-the-number-of-merge-requests-in-a-date-range)
- [**Critical vulnerabilities over time**](../application_security/vulnerability_report/_index.md)
- [**Contributor count**](../profile/contributions_calendar.md#user-contribution-events)

### AI usage metrics

**Code Suggestions: Usage**: Monthly user engagement with AI Code Suggestions.

On GitLab.com, data updates every fives minutes.
GitLab counts Code Suggestions usage only if the user has pushed code to the project in the current month.

The month-over-month comparison of the AI Usage unique users rate gives a more accurate indication Code Suggestion usage,
because it eliminates factors such as developer experience level and project type or complexity.

The baseline for the AI Usage trend is the total number of code contributors, not only users with GitLab Duo seats.
This baseline gives a more accurate representation of AI usage by team members.

To analyze the performance of teams that use AI versus teams that don't, you can create a custom
[Value Streams Dashboard Scheduled Report](https://gitlab.com/explore/catalog/components/vsd-reports-generator)
based on the AI impact view of projects and groups with and without GitLab Duo.

{{< alert type="note" >}}

Usage rate for Code Suggestions is calculated with data starting from GitLab 16.11.
For more information, see [epic 12978](https://gitlab.com/groups/gitlab-org/-/epics/12978).

{{< /alert >}}

**Duo RCA: Usage**: Monthly user engagement with Duo Root Cause Analysis.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/513252) in GitLab 18.1 [with a flag](../../administration/feature_flags/_index.md) named `duo_rca_usage_rate`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/543987) in GitLab 18.3.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

This metric tracks the percentage of Duo users who select [**Troubleshoot** to analyze failed CI/CD jobs](../gitlab_duo_chat/examples.md#from-a-merge-request).

{{< alert type="note" >}}

Usage rate for Duo RCA is calculated with data starting from GitLab 18.0.
For more information, see [epic 15025](https://gitlab.com/groups/gitlab-org/-/epics/15025).

{{< /alert >}}

## View AI impact analytics

Prerequisites:

- [Code Suggestions](../project/repository/code_suggestions/_index.md) must be enabled.
- For GitLab Self-Managed, [ClickHouse for contribution analytics](../group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse) must be configured.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Analytics Dashboards**.
1. Select **AI impact analytics**.

To retrieve AI impact metrics, you can also use the `AiMetrics`, `AiUserMetrics`, and `AiUsageData` [GraphQL APIs](../../api/graphql/reference/_index.md).
For an overview and sample queries, see [issue 512931](https://gitlab.com/gitlab-org/gitlab/-/issues/512931).
