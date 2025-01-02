---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# AI impact analytics

DETAILS:
**Tier:** Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab.com, Self-managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443696) in GitLab 16.11 [with a flag](../../administration/feature_flags.md) named `ai_impact_analytics_dashboard`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/451873) in GitLab 17.2. Feature flag `ai_impact_analytics_dashboard` removed.
> - Changed to require GitLab Duo add-on in GitLab 17.6.

AI impact analytics displays software development lifecycle (SDLC) metrics for a project or group in the month-to-date and the past six months.

Use AI impact analytics to:

- Measure the effectiveness and impact of AI on SDLC metrics.
- Visualize which metrics improved as a result of investments in AI.
- Track the progress of AI adoption.
- Compare the performance of teams that are using AI against teams that are not using AI.

For a click-through demo, see the [AI impact analytics product tour](https://gitlab.navattic.com/ai-impact).

## AI impact metrics

AI impact analytics displays key metrics and metric trends for a project or group.

### Key metrics

- **Code Suggestions: Unique users**: Percentage of users that engage with Code Suggestions every month. It is calculated as the number of monthly unique Code Suggestions users divided by total monthly [unique contributors](../../user/profile/contributions_calendar.md#user-contribution-events). Only unique code contributors, meaning users with `pushed` events, are included in the calculation.
- **Code Suggestions: Acceptance rate**: Percentage of code suggestions provided by GitLab Duo that have been accepted by code contributors in the last 30 days.
- **Duo Chat: Unique users**: Percentage of users that engage with GitLab Duo Chat every month. It is calculated as the number of monthly unique GitLab Duo Chat users divided by the total GitLab Duo assigned users.

### Metric trends

The **Metric trends** table displays metrics for the last six months, with monthly values, percentage changes in the past six months, and trend sparklines.

#### Lifecycle metrics

- [**Cycle time**](../group/value_stream_analytics/index.md#lifecycle-metrics)
- [**Lead time**](../group/value_stream_analytics/index.md#lifecycle-metrics)
- [**Deployment frequency**](dora_metrics.md#deployment-frequency)
- [**Change failure rate**](dora_metrics.md#change-failure-rate)
- [**Critical vulnerabilities over time**](../application_security/vulnerability_report/index.md)

#### AI usage metrics

**Code Suggestions usage**: Monthly user engagement with AI Code Suggestions.

- The month-over-month comparison of the AI Usage unique users rate gives a more accurate indication of this metric, as it eliminates factors such as developer experience level and project type or complexity.
- The baseline for the AI Usage trend is the total number of code contributors, not just users with GitLab Duo seats. This baseline gives a more accurate representation of AI usage by team members. To learn more about AI impact analytics, see the blog post [Developing GitLab Duo: AI impact analytics dashboard measures the ROI of AI](https://about.gitlab.com/blog/2024/05/15/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/).
- To analyze the performance of teams that use AI versus teams that don't, you can create a custom [Value Streams Dashboard Scheduled Report](https://gitlab.com/explore/catalog/components/vsd-reports-generator) based on the AI impact view of projects and groups with and without GitLab Duo.

NOTE:
Usage rate for Code Suggestions is calculated with data starting from GitLab 16.11.
For more information, see [epic 12978](https://gitlab.com/groups/gitlab-org/-/epics/12978).

## View AI impact analytics

Prerequisites:

- [Code Suggestions](../../user/project/repository/code_suggestions/index.md) must be enabled.
- [ClickHouse for contribution analytics](../../user/group/contribution_analytics/index.md#contribution-analytics-with-clickhouse) must be configured.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Analytics Dashboards**.
1. Select **AI impact analytics**.

To retrieve AI impact metrics, you can also use the following GraphQL APIs:

- [`AiUserMetrics`](../../api/graphql/reference/index.md#aiusermetrics) - Requires ClickHouse
- [`AiUsageData`](../../api/graphql/reference/index.md#aiusagedata) - Does not require ClickHouse
