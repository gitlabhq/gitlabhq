---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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

GitLab provides analytics features that give you insights into your software development lifecycle.
Use these features to track productivity, code quality, deployment performance, and security.
Analytics features are available for instances, groups, and [projects](../project/settings/_index.md#turn-off-project-analytics),
and require different [roles and permissions](../permissions.md#project-analytics).
This way, you can analyze data at the scale that matters to your team.

## End-to-end insight & visibility analytics

Use these features to gain insights into your overall software development lifecycle.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Value Streams Dashboard](value_streams_dashboard.md) | Insights into DevSecOps trends, patterns, and opportunities for digital transformation improvements. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Value Stream Management Analytics](../group/value_stream_analytics/_index.md) | Insights into time-to-value through customizable stages. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| DevOps adoption [by group](../group/devops_adoption/_index.md) and [by instance](../../administration/analytics/devops_adoption.md) | Organization's maturity in DevOps adoption, with feature adoption over time and feature distribution by group. | {{< no >}} | {{< yes >}} | {{< yes >}} |
| [Usage trends](../../administration/analytics/usage_trends.md) | Overview of instance data and changes in data volume over time. | {{< no >}} | {{< no >}} | {{< yes >}} |
| [Insights](../project/insights/_index.md) | Customizable reports to explore issues, merged merge requests, and triage hygiene. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Analytics dashboards](analytics_dashboards.md) | Built-in and customizable dashboards to visualize collected data. | {{< yes >}} | {{< yes >}} | {{< no >}} |

## Productivity analytics

Use these features to gain insights into the productivity of your team on issues and merge requests.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Issue analytics](../group/issues_analytics/_index.md) | Visualization of issues created each month. | {{< yes >}} | {{< yes >}} | {{< no >}} |
| [Merge request analytics](merge_request_analytics.md) | Overview of merge requests, with mean time to merge, throughput, and activity details. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [Productivity analytics](productivity_analytics.md) | Merge request lifecycle, filterable down to author level. | {{< no >}} | {{< yes >}} | {{< no >}} |
| [Code review analytics](code_review_analytics.md) | Open merge requests with information about merge request activity. | {{< yes >}} | {{< no >}} | {{< no >}} |

## Developer analytics

Use these features to gain insights into developer productivity and code coverage.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Contribution analytics](../group/contribution_analytics/_index.md) | Overview of [contribution events](../profile/contributions_calendar.md) made by group members, with bar chart of push events, merge requests, and issues. | {{< no >}} | {{< yes >}} | {{< no >}} |
| [Contributor analytics](contributor_analytics.md) | Overview of commits made by project members, with line chart of number of commits. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [Repository analytics](../group/repositories_analytics/_index.md) | Programming languages used in the repository and code coverage statistics. | {{< yes >}} | {{< yes >}} | {{< no >}} |

## CI/CD analytics

Use these features to gain insights into CI/CD performance.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [CI/CD analytics](ci_cd_analytics.md) | Pipeline duration and successes or failures. | {{< yes >}} | {{< no >}} | {{< no >}} |
| [DORA metrics](dora_metrics.md) | DORA metrics over time. | {{< yes >}} | {{< yes >}} | {{< no >}} |

## Security analytics

Use these features to gain insights into security vulnerabilities and metrics.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Security Dashboards](../application_security/security_dashboard/_index.md) | Collection of metrics, ratings, and charts for vulnerabilities detected by security scanners. | {{< yes >}} | {{< yes >}} | {{< no >}} |
