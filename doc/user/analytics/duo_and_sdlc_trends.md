---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo and SDLC trends
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo Enterprise, GitLab Duo with Amazon Q
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443696) in GitLab 16.11 [with a flag](../../administration/feature_flags/_index.md) named `ai_impact_analytics_dashboard`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/451873) in GitLab 17.2. Feature flag `ai_impact_analytics_dashboard` removed.
- Changed to require GitLab Duo add-on in GitLab 17.6.
- Changed to support Amazon Q in GitLab 18.2.1.
- Pipeline metrics table [added](https://gitlab.com/gitlab-org/gitlab/-/issues/550356) in GitLab 18.4.
- Renamed from `AI impact analytics` to `GitLab Duo and SDLC trends` in GitLab 18.4.

{{< /history >}}

GitLab Duo and SDLC trends measure the impact of GitLab Duo on software development lifecycle (SDLC) performance.
This dashboard provides visibility into key SDLC metrics in the context of AI adoption for projects or groups.
You can use the dashboard to measure which metrics have improved from your AI investments.

Use GitLab Duo and SDLC trends for:

- Correlation observations: Examine how trends in AI usage in a project or group influence other crucial productivity metrics. AI usage metrics are displayed for the last six months, including the current one.
- Snapshot of GitLab Duo usage: Track the use of seats and features in a project or group over the last 30 days.

To learn how you can optimize your license utilization,
see [GitLab Duo add-ons](../../subscriptions/subscription-add-ons.md).

To learn more about GitLab Duo and SDLC trends, see the blog post
[Developing GitLab Duo: AI impact analytics dashboard measures the ROI of AI](https://about.gitlab.com/blog/2024/05/15/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/).

For a click-through demo, see the [GitLab Duo and SDLC trends product tour](https://gitlab.navattic.com/ai-impact).

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [GitLab Duo AI Impact Dashboard](https://youtu.be/FxSWX64aUOE?si=7Yfc6xHm63c3BRwn).
<!-- Video published on 2025-03-06 -->

## Key metrics

- **Assigned Duo seat engagement**: Percentage of users that are assigned a Duo seat and used at least one AI feature in the last 30 days.
It is calculated as the number of users with Duo seats that use AI features divided by the total number of assigned Duo seats.
- **Code Suggestions: Usage**: Percentage of users that engage with Code Suggestions every month.
It is calculated as the number of monthly unique Code Suggestions users divided by total monthly unique code contributors (users with `pushed` events).
For calculating Code Suggestions metrics, GitLab collects data only from code editor extensions.
- **Code Suggestions: Acceptance rate**: Percentage of code suggestions provided by GitLab Duo that have been accepted by code contributors in the last 30 days.
It is calculated as the number of accepted code suggestions divided by the total number of generated code suggestions.
- **Duo Chat: Usage**: Percentage of users that engage with GitLab Duo Chat every month.
It is calculated as the number of monthly unique GitLab Duo Chat users divided by the total GitLab Duo assigned users.

## Metric trends

The **Metric trends** table displays metrics for the last six months, with monthly values, percentage changes in the past six months, and trend sparklines.

### Duo usage metrics

{{< history >}}

- Duo RCA usage [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/513252) in GitLab 18.1 [with a flag](../../administration/feature_flags/_index.md) named `duo_rca_usage_rate`. Disabled by default.
- Duo RCA usage [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/543987) in GitLab 18.3.
- Duo RCA usage [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/556726) in GitLab 18.4. Feature flag `duo_rca_usage_rate` removed.

{{< /history >}}

- **Code Suggestions: Usage**: Monthly user engagement with AI Code Suggestions.

  On GitLab.com, data updates every fives minutes.
  GitLab counts Code Suggestions usage only if the user has pushed code to the project in the current month.

  The month-over-month comparison of the AI Usage unique users rate gives a more accurate indication Code Suggestion usage,
  because it eliminates factors such as developer experience level and project type or complexity.

  The baseline for the AI Usage trend is the total number of code contributors, not only users with GitLab Duo seats.
  This baseline gives a more accurate representation of AI usage by team members.

  {{< alert type="note" >}}

  Usage rate for Code Suggestions is calculated with data starting from GitLab 16.11.

  {{< /alert >}}

- **Duo RCA: Usage**: Monthly user engagement with Duo Root Cause Analysis.
  Tracks the percentage of Duo users who use GitLab Duo Chat to troubleshoot a failed CI/CD job from a merge request.

  {{< alert type="note" >}}

  Usage rate for Duo RCA is calculated with data starting from GitLab 18.0.

  {{< /alert >}}

### Development metrics

- [**Lead time**](../group/value_stream_analytics/_index.md#lifecycle-metrics)
- [**Median time to merge**](merge_request_analytics.md)
- [**Deployment frequency**](dora_metrics.md#deployment-frequency)
- [**Merge request throughput**](merge_request_analytics.md#view-the-number-of-merge-requests-in-a-date-range)
- [**Critical vulnerabilities over time**](../application_security/vulnerability_report/_index.md)
- [**Contributor count**](../profile/contributions_calendar.md#user-contribution-events)

### Pipeline metrics

The Pipeline metrics table displays metrics for the pipelines run in the selected project.

- **Total pipeline runs**: Number of pipeline runs in the project.
- **Median duration**: Median duration (in minutes) of a pipeline run.
- **Success rate**: Percentage of pipeline runs that completed successfully.
- **Failure rate**: Percentage of pipeline runs that completed with failures.

## View GitLab Duo and SDLC trends

Prerequisites:

- [Code Suggestions](../project/repository/code_suggestions/_index.md) must be enabled.
- For GitLab Self-Managed, [ClickHouse for contribution analytics](../group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse) must be configured.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Analytics Dashboards**.
1. Select **GitLab Duo and SDLC trends**.

To retrieve GitLab Duo and SDLC metrics, you can also use the `AiMetrics`, `AiUserMetrics`, and `AiUsageData` [GraphQL APIs](../../api/graphql/duo_and_sdlc_trends.md).
