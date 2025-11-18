---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Instance, group, and project analytics.
title: Analyze GitLab usage
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Group-level analytics moved to GitLab Premium in 13.9.

{{< /history >}}

GitLab provides different types of analytics insights for instances, groups, and [projects](../project/settings/_index.md#turn-off-project-analytics).
Analytics features require different [roles and permissions](../permissions.md#analytics) for projects and groups.

## Analytics features

### End-to-end insight & visibility analytics

Use these features to gain insights into your overall software development lifecycle.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Value Streams Dashboard](value_streams_dashboard.md) | Insights into DevSecOps trends, patterns, and opportunities for digital transformation improvements. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Value Stream Management Analytics](../group/value_stream_analytics/_index.md) | Insights into time-to-value through customizable stages. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| DevOps adoption [by group](../group/devops_adoption/_index.md) and [by instance](../../administration/analytics/devops_adoption.md) | Organization's maturity in DevOps adoption, with feature adoption over time and feature distribution by group. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Usage trends](../../administration/analytics/usage_trends.md) | Overview of instance data and changes in data volume over time. | {{< no >}} | {{< no >}} | {{< yes >}} |
| [Insights](../project/insights/_index.md) | Customizable reports to explore issues, merged merge requests, and triage hygiene. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Analytics dashboards](analytics_dashboards.md) | Built-in and customizable dashboards to visualize collected data. | {{< yes >}} | {{< yes >}} | {{< no >}} |

### Productivity analytics

Use these features to gain insights into the productivity of your team on issues and merge requests.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Issue analytics](../group/issues_analytics/_index.md) | Visualization of issues created each month. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Merge request analytics](merge_request_analytics.md) | Overview of merge requests, with mean time to merge, throughput, and activity details. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [Productivity analytics](productivity_analytics.md) | Merge request lifecycle, filterable down to author level. | {{< no >}} | {{< yes >}} | {{< no >}} |
| [Code review analytics](code_review_analytics.md) | Open merge requests with information about merge request activity. | {{< yes >}} | {{< no >}} | {{< no >}} |

### Developer analytics

Use these features to gain insights into developer productivity and code coverage.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Contribution analytics](../group/contribution_analytics/_index.md) | Overview of [contribution events](../profile/contributions_calendar.md) made by group members, with bar chart of push events, merge requests, and issues. | {{< no >}} | {{< yes >}} | {{< no >}} |
| [Contributor analytics](contributor_analytics.md) | Overview of commits made by project members, with line chart of number of commits. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [Repository analytics](../group/repositories_analytics/_index.md) | Programming languages used in the repository and code coverage statistics. | {{< yes >}} | {{< yes >}} | {{< no >}} |

### CI/CD analytics

Use these features to gain insights into CI/CD performance.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [CI/CD analytics](ci_cd_analytics.md) | Pipeline duration and successes or failures. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [DORA metrics](dora_metrics.md) | DORA metrics over time. | {{< yes >}} | {{< yes >}} | {{< no >}} |

### Security analytics

Use these features to gain insights into security vulnerabilities and metrics.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Security Dashboards](../application_security/security_dashboard/_index.md) | Collection of metrics, ratings, and charts for vulnerabilities detected by security scanners. | {{< yes >}} | {{< yes >}} | {{< no >}} |

## Metric glossary

The following glossary provides definitions for common development metrics used in analytics features,
and explains how they are measured in GitLab.

| Metric | Definition | Measurement in GitLab |
| ------ | ---------- | --------------------- |
| Mean Time to Change (MTTC) | The average duration between idea and delivery. | From when an issue is created until its related merge request is deployed to production. |
| Mean Time to Detect (MTTD) | The average duration that a bug goes undetected in production. | From when a bug is deployed to production until an issue is created to report it. |
| Mean Time to Merge (MTTM) | The average lifespan of a merge request. | From when a merge request is created until it is merged. Excludes merge requests that are closed or unmerged. For more information, see [merge request analytics](merge_request_analytics.md). |
| Mean Time to Recover / Repair / Resolution / Resolve / Restore (MTTR) | The average duration that a bug is not fixed in production. | From when a bug is deployed to production until the bug fix is deployed. |
| Velocity | The total issue burden completed in a specific period of time. The burden is usually measured in points or weight, often per sprint. | Total points or weight of issues closed in a specific period of time. For example, "30 points per sprint". |

For more definitions, see also the [Value Streams Dashboard metrics and drill-down reports](value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports).
