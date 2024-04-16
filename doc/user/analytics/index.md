---
stage: Plan
group: Optimize
description: Instance, group, and project analytics.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Analyze GitLab usage

> - Group-level analytics moved to GitLab Premium in 13.9.

GitLab provides different types of analytics insights at the instance, group, and project level.
These insights appear on the left sidebar, under [**Analyze**](../project/settings/index.md#disable-project-analytics).

## Analytics features

| Feature | Description | Category | Project-level | Group-level | Instance-level |
| ------- | ----------- | -------- | ------------- | ----------- | -------------- |
| [Analytics dashboards](analytics_dashboards.md) | Built-in and customizable dashboards to visualize collected data. | End-to-end insight & visibility | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| [CI/CD analytics and DORA metrics](ci_cd_analytics.md) | Pipeline duration and successes/failures, and DORA metrics over time. | CI/CD | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| [Code review analytics](code_review_analytics.md) | Open merge requests with information about merge request activity. | Productivity | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| [Contribution analytics](../group/contribution_analytics/index.md) | Overview of [contribution events](../../user/profile/contributions_calendar.md) made by group members, with bar chart of push events, merge requests, and issues. | Developer | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No |
| [Contributor analytics](../../user/analytics/contributor_analytics.md) | Overview of commits made by project members, with line chart of number of commits. | Developer | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| [DevOps adoption](../group/devops_adoption/index.md) | Organization's maturity in DevOps adoption, with group-level feature adoption over time and adoption by subgroup. | End-to-end insight & visibility | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No |
| [Insights](../project/insights/index.md) | Customizable reports to explore issues, merged merge requests, and triage hygiene. | End-to-end insight & visibility | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| [Instance-level analytics](../../administration/analytics/index.md) | Aggregated analytics across GitLab about multiple projects and groups in one place. | End-to-end insight & visibility | **{dotted-circle}** No | **{dotted-circle}** No | **{check-circle}** Yes |
| [Issue analytics](../group/issues_analytics/index.md) | Visualization of issues created each month. | Productivity | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| [Merge request analytics](merge_request_analytics.md) | Overview of merge requests, with mean time to merge, throughput, and activity details. | Productivity | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| [Product analytics](../product_analytics/index.md) | Understanding how users behave and interact with your product.| Product Analytics | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No |
| [Productivity analytics](productivity_analytics.md) | Merge request lifecycle, filterable down to author level. | Productivity | **{dotted-circle}** No | **{check-circle}** Yes | **{dotted-circle}** No |
| [Repository analytics](../group/repositories_analytics/index.md) | Programming languages used in the repository and code coverage statistics. | Developer | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| [Security Dashboards](../application_security/security_dashboard/index.md) | Collection of metrics, ratings, and charts for vulnerabilities detected by security scanners. | Security | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |
| [Value Streams Dashboard](value_streams_dashboard.md) | Insights into DevSecOps trends, patterns, and opportunities for digital transformation improvements. | End-to-end insight & visibility | **{check-circle}** Yes | **{dotted-circle}** No | **{dotted-circle}** No |
| [Value Stream Management Analytics](../group/value_stream_analytics/index.md) | Insights into time-to-value through customizable stages. | End-to-end insight & visibility | **{check-circle}** Yes | **{check-circle}** Yes | **{dotted-circle}** No |

## Glossary

| Metric | Definition | Measurement in GitLab |
| ------ | ---------- | --------------------- |
| Mean Time to Change (MTTC) | The average duration between idea and delivery. | From issue creation to the issue's latest related merge request's deployment to production. |
| Mean Time to Detect (MTTD) | The average duration that a bug goes undetected in production. | From deployment of bug to issue creation. |
| Mean Time To Merge (MTTM) | The average lifespan of a merge request. | From merge request creation to merge request merge (excluding closed and unmerged merge requests). For more information, see [Merge Request Analytics](merge_request_analytics.md). |
| Mean Time to Recover/Repair/Resolution/Resolve/Restore (MTTR) | The average duration that a bug is not fixed in production. | From deployment of bug to deployment of fix. |
| Velocity | The total issue burden completed in some period of time. The burden is usually measured in points or weight, often per sprint. | Total points or weight of issues closed in a given period of time. Expressed as, for example, "30 points per sprint". |
