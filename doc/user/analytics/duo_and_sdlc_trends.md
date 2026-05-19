---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo and SDLC trends
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta for GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443696) in GitLab 16.11 [with a flag](../../administration/feature_flags/_index.md) named `ai_impact_analytics_dashboard`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/451873) in GitLab 17.2. Feature flag `ai_impact_analytics_dashboard` removed.
- Changed to require GitLab Duo add-on in GitLab 17.6.
- Moved from GitLab Ultimate to GitLab Premium in 18.2.
- Changed to support Amazon Q in GitLab 18.2.1.
- Pipeline metrics table [added](https://gitlab.com/gitlab-org/gitlab/-/issues/550356) in GitLab 18.4.
- Renamed from `AI impact analytics` to `GitLab Duo and SDLC trends` in GitLab 18.4.
- Changed to not require add-ons in GitLab 18.7.

{{< /history >}}

This feature is in beta for GitLab Self-Managed.
For more information, see [epic 51](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/epics/51).

GitLab Duo and SDLC trends measure the impact of GitLab Duo on software development lifecycle (SDLC) performance.
This dashboard provides visibility into key SDLC metrics in the context of AI adoption for projects or groups.
You can use the dashboard to measure which metrics have improved from your AI investments.

The metrics display a trend indicator showing the percentage change compared to the previous time period.
If no data is available for the previous time period, the percentage change displays **n/a**.

Values in green indicate positive changes, and values in red indicate negative changes.
The icons next to the values indicate upward trends {{< icon name="trend-up" >}} or downward trends {{< icon name="trend-down" >}}.

Upward trends are positive (green) for some metrics (like [deployment frequency](dora_metrics.md#deployment-frequency)), but negative (red) for others (like [mean time to merge](merge_request_analytics.md)).

Use GitLab Duo and SDLC trends to:

- Track SDLC trends in relation to your GitLab Duo journey: Examine how trends in GitLab Duo usage in a project or group influence other crucial productivity metrics such as mean time to merge and CI/CD statistics. GitLab Duo usage metrics are displayed for the last six months, including the current one.
- Monitor GitLab Duo feature adoption: Track the use of seats and features in a project or group over the last 30 days.

To learn how you can optimize your license utilization,
see [GitLab Duo add-ons](../../subscriptions/subscription-add-ons.md).

To learn more about GitLab Duo and SDLC trends, see the blog post
[Developing GitLab Duo: AI impact analytics dashboard measures the ROI of AI](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/).

<i class="fa-youtube-play" aria-hidden="true"></i>
For an overview, see [GitLab Duo AI Impact Dashboard](https://youtu.be/FxSWX64aUOE?si=7Yfc6xHm63c3BRwn).
<!-- Video published on 2025-03-06 -->

## Key metrics

{{< history >}}

- GitLab Duo Chat usage metric [replaced](https://gitlab.com/gitlab-org/gitlab/-/issues/587301) with GitLab Duo Agentic Chat sessions in GitLab 18.10.
- Assigned GitLab Duo seat engagement metric [replaced](https://gitlab.com/gitlab-org/gitlab/-/work_items/587298) with GitLab Duo users in GitLab 18.10.
- GitLab Duo Code Suggestions usage metric [changed](https://gitlab.com/gitlab-org/gitlab/-/work_items/592813) from percentage rate to absolute user count in GitLab 18.10.
- Code Suggestions acceptance rate metric [replaced](https://gitlab.com/gitlab-org/gitlab/-/work_items/587300) with GitLab Duo agent/flow users in GitLab 18.11.
- Trend indicators [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/590535) in GitLab 19.0.
- Code Suggestions users metric [replaced](https://gitlab.com/gitlab-org/gitlab/-/work_items/587299) with GitLab Duo power users in GitLab 19.0.

{{< /history >}}

- **GitLab Duo users**: Number of users who used at least one GitLab Duo or GitLab Duo Agent Platform feature in the last 30 days.
- **GitLab Duo power users**: Number of users who used at least three GitLab Duo features in the last 30 days.
- **GitLab Duo agent/flow users**: Number of users who used at least one GitLab Duo agent or flow in the last 30 days.
- **GitLab Duo Agent chat sessions**: Number of chat sessions initiated in GitLab Duo Agent Platform in the last 30 days.

## Metric trends

The **Metric trends** table displays metrics for the last six months, with monthly values, percentage changes in the past six months, and trend sparklines.

### GitLab Duo usage metrics

{{< history >}}

- GitLab Duo Root Cause Analysis usage [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/513252) in GitLab 18.1 [with a flag](../../administration/feature_flags/_index.md) named `duo_rca_usage_rate`. Disabled by default.
- GitLab Duo Root Cause Analysis usage [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/543987) in GitLab 18.3.
- GitLab Duo Root Cause Analysis usage [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/556726) in GitLab 18.4. Feature flag `duo_rca_usage_rate` removed.
- GitLab Duo features usage [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207562) in GitLab 18.6.
- GitLab Duo Code Review requests and comments [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/573979) in GitLab 18.7.
- GitLab Duo Agent Platform chats and flows [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/583375) in GitLab 18.7.
- GitLab Duo Code Suggestions, Non-Agentic Chat, and Root Cause Analysis metrics [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/589605) from percentage rates to absolute user counts in GitLab 18.10.

{{< /history >}}

- **Feature usage**: Number of users who used at least one GitLab Duo or GitLab Duo Agent Platform feature.
- **Agent Platform chats**: Number of chat sessions initiated through GitLab Duo Agent Platform.
- **Agent Platform flows**: Number of agent flows (excluding chats) executed through GitLab Duo Agent Platform.
- **Non-Agentic Chat usage**: Number of users who used Non-Agentic Chat.
- **Root Cause Analysis usage**: Number of users who used Root Cause Analysis.
- **Code Review requests**: Number of Code Review requests made on merge requests.
  This includes requests initiated by both merge request authors and non-authors.
- **Code Review comments**: Number of Code Review comments posted on merge request diffs.
- **Code Suggestions usage**: Number of users who used Code Suggestions.
  On GitLab.com, data updates every five minutes.
  GitLab counts Code Suggestions usage only if the user has pushed code to the project in the current month.
- **Code Suggestions acceptance rate**: Percentage of code suggestions provided by GitLab Duo that have been accepted by code contributors.

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

## Pipelines using GitLab Duo Agent Platform

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/587303) in GitLab 19.0.

{{< /history >}}

The **Pipelines using GitLab Duo Agent Platform** chart displays the number of pipelines run over the last 180 days, aggregated by month. The chart shows:

- **With Agent Platform**: Number of pipelines triggered by GitLab Duo Agent Platform.
- **All pipelines**: Total number of pipelines run in the namespace.

## GitLab Duo Code Suggestions acceptance by language

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/454809) in GitLab 18.5.

{{< /history >}}

The **GitLab Duo Code Suggestions acceptance by language** chart displays the number of Code Suggestions accepted by programming language for the last 30 days.

Hover over a bar to view for each language:

- **Suggestions accepted**: Number of suggestions accepted by users.
- **Suggestions shown**: Number of suggestions shown to users.
- **Acceptance rate**: Percentage of suggestions accepted.
  Calculated as the number of accepted code suggestions divided by the total number of code suggestions shown.

## GitLab Duo Code Suggestions acceptance by IDE

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/550064) in GitLab 18.7.

{{< /history >}}

The **GitLab Duo Code Suggestions acceptance by IDE** chart displays the number of Code Suggestions accepted by IDE for the last 30 days.

Hover over a bar to view for each IDE:

- **Suggestions accepted**: Number of suggestions accepted by users.
- **Suggestions shown**: Number of suggestions shown to users.
- **Acceptance rate**: Percentage of suggestions accepted.
  Calculated as the number of accepted code suggestions divided by the total number of code suggestions shown.

## Code generation volume trends

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/573972) in GitLab 18.5.

{{< /history >}}

The **Code generation volume trends** chart displays the volume of code generated through Code Suggestions over the last 180 days, aggregated by month. The chart shows:

- **Lines of code accepted**: Lines of code from Code Suggestions that were accepted.
- **Lines of code shown**: Lines of code displayed in Code Suggestions.

## GitLab Duo Code Review requests by role

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/574003) in GitLab 18.7.

{{< /history >}}

The **GitLab Duo Code Review requests by role** chart displays the number of Code Review requests over the last 180 days, aggregated by month. The chart shows:

- **Review requests by authors**: Number of Code Review requests made by the merge request author. This includes code reviews requested automatically through the project setting and manually in the merge request by the author.
- **Review requests by non-authors**: Number of Code Review requests made by users other than the merge request author. For example, reviewers who ask GitLab Duo to review the merge request changes.

Higher author adoption indicates teams embracing automated review workflows.

## GitLab Duo Code Review comments sentiment

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/574005) in GitLab 18.8.

{{< /history >}}

The **GitLab Duo Code Review comments sentiment** chart displays the sentiment of Code Review comments over the last 180 days, measured by positive (👍) and negative (👎) reaction rates. The chart shows:

- **Approval rate**: The percentage of Code Review comments that received positive (👍) reactions.
- **Disapproval rate**: The percentage of Code Review comments that received negative (👎) reactions.

When interpreting your analytics, keep in mind that:

- Negativity bias is expected. Users tend to flag problems, but rarely acknowledge good suggestions, even when applying them.
- Low reaction rates are common. Focus on whether code improves and reviews complete faster.
- Rising disapproval (👎) rates signal issues. Stable or declining disapproval rates indicate healthy adoption of GitLab Duo Code Review.

## GitLab Duo metrics by user

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/574420) in GitLab 18.7.

{{< /history >}}

The user metrics tables display usage of different GitLab Duo features by individual users over the last 30 days.

- **GitLab Duo Code Suggestions usage by user**: Number of code suggestions accepted, and the code suggestions acceptance rate.
- **GitLab Duo Code Review usage by user**: Number of code reviews requested as the merge request author from GitLab Duo, and number of reactions (:thumbsup: and :thumbsdown:) to code review comments.
- **GitLab Duo Root Cause Analysis usage by user**: Number of troubleshooting requests from GitLab Duo.
- **GitLab Duo usage by user**: Number of GitLab Duo events made by the user.
- **Flows usage by user**: Number of times a user triggers a specific flow.

## View GitLab Duo and SDLC trends

Prerequisites:

- You must have at least the Reporter role for the group.
- The group must be a top-level group.
- GitLab Duo Code Suggestions must be enabled.
- For GitLab Self-Managed, [ClickHouse for contribution analytics](../group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse) must be configured.

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Analyze** > **Analytics dashboards**.
1. Select **GitLab Duo and SDLC trends**.

To retrieve GitLab Duo and SDLC metrics, you can also use the `AiMetrics`, `AiUserMetrics`, and `AiUsageData` [GraphQL APIs](../../api/graphql/duo_and_sdlc_trends.md).

## Metric data availability

The following table displays the GitLab versions when usage data calculation started for GitLab Duo metrics:

| GitLab Duo metric | Data calculation start |
|--------|------------------------------|
| Code Suggestions usage | GitLab 16.11 |
| Root Cause Analysis usage | GitLab 18.0 |
| Code Review requests and comments | GitLab 18.3 |
| Agent Platform chats and flows | GitLab 18.7 |
