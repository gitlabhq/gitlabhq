---
stage: Plan
group: Optimize
description: Instance, group, and project analytics.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Analyze GitLab usage
---

> - Group-level analytics moved to GitLab Premium in 13.9.

GitLab provides different types of analytics insights at the instance, group, and project level.
These insights appear on the left sidebar, under [**Analyze**](../project/settings/_index.md#turn-off-project-analytics).

## Analytics features

### End-to-end insight & visibility analytics

Use these features to gain insights into your overall software development lifecycle.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Value Streams Dashboard](value_streams_dashboard.md) | Insights into DevSecOps trends, patterns, and opportunities for digital transformation improvements. | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| [Value Stream Management Analytics](../group/value_stream_analytics/_index.md) | Insights into time-to-value through customizable stages. | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| DevOps adoption [by group](../group/devops_adoption/_index.md) and [by instance](../../administration/analytics/dev_ops_reports.md) | Organization's maturity in DevOps adoption, with feature adoption over time and feature distribution by group. | **{dotted-circle}** No | **{check-circle}** Yes | **{check-circle}** Yes |
| [Usage trends](../../administration/analytics/usage_trends.md) | Overview of instance data and changes in data volume over time. | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes |
| [Insights](../project/insights/_index.md) | Customizable reports to explore issues, merged merge requests, and triage hygiene. | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| [Product analytics](../../development/internal_analytics/product_analytics.md) | Understanding how users behave and interact with your product.| **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No |
| [Analytics dashboards](analytics_dashboards.md) | Built-in and customizable dashboards to visualize collected data. | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |

### Productivity analytics

Use these features to gain insights into the productivity of your team on issues and merge requests.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Issue analytics](../group/issues_analytics/_index.md) | Visualization of issues created each month. | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| [Merge request analytics](merge_request_analytics.md) | Overview of merge requests, with mean time to merge, throughput, and activity details. | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| [Productivity analytics](productivity_analytics.md) | Merge request lifecycle, filterable down to author level. | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No |
| [Code review analytics](code_review_analytics.md) | Open merge requests with information about merge request activity. | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |

### Developer analytics

Use these features to gain insights into developer productivity and code coverage.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Contribution analytics](../group/contribution_analytics/_index.md) | Overview of [contribution events](../profile/contributions_calendar.md) made by group members, with bar chart of push events, merge requests, and issues. | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No |
| [Contributor analytics](../analytics/contributor_analytics.md) | Overview of commits made by project members, with line chart of number of commits. | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| [Repository analytics](../group/repositories_analytics/_index.md) | Programming languages used in the repository and code coverage statistics. | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |

### CI/CD analytics

Use these features to gain insights into CI/CD performance.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [CI/CD analytics](ci_cd_analytics.md) | Pipeline duration and successes/failures. | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| [DORA metrics](dora_metrics.md) | DORA metrics over time. | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |

### Security analytics

Use these features to gain insights into security vulnerabilities and metrics.

| Feature | Description | Project-level | Group-level | Instance-level |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Security Dashboards](../application_security/security_dashboard/_index.md) | Collection of metrics, ratings, and charts for vulnerabilities detected by security scanners. | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |

## Glossary

| Metric | Definition | Measurement in GitLab |
| ------ | ---------- | --------------------- |
| Mean Time to Change (MTTC) | The average duration between idea and delivery. | From issue creation to the issue's latest related merge request's deployment to production. |
| Mean Time to Detect (MTTD) | The average duration that a bug goes undetected in production. | From deployment of bug to issue creation. |
| Mean Time To Merge (MTTM) | The average lifespan of a merge request. | From merge request creation to merge request merge (excluding closed and unmerged merge requests). For more information, see [Merge Request Analytics](merge_request_analytics.md). |
| Mean Time to Recover/Repair/Resolution/Resolve/Restore (MTTR) | The average duration that a bug is not fixed in production. | From deployment of bug to deployment of fix. |
| Velocity | The total issue burden completed in some period of time. The burden is usually measured in points or weight, often per sprint. | Total points or weight of issues closed in a given period of time. Expressed as, for example, "30 points per sprint". |
