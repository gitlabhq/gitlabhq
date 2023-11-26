---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Analyze GitLab usage **(FREE ALL)**

GitLab provides different types of analytics insights at the instance, group, and project level.
These insights appear on the left sidebar, under [**Analyze**](../project/settings/index.md#disable-project-analytics).

## Instance-level analytics

Use [instance-level analytics](../../administration/analytics/index.md) to aggregate analytics across GitLab,
so that you can view information across multiple projects and groups in one place.

## Group-level analytics

> Moved to GitLab Premium in 13.9.

Use group-level analytics to get insights into your groups':

- [Security Dashboards](../application_security/security_dashboard/index.md)
- [Contribution analytics](../group/contribution_analytics/index.md)
- [DevOps adoption](../group/devops_adoption/index.md)
- [Insights](../group/insights/index.md)
- [Issue analytics](../group/issues_analytics/index.md)
- [Productivity analytics](productivity_analytics.md)
- [Repositories analytics](../group/repositories_analytics/index.md)
- [Value Stream Management Analytics](../group/value_stream_analytics/index.md) and [Value Stream Management Dashboard](value_streams_dashboard.md)

## Project-level analytics

Use project-level analytics to get insights into your projects':

- [Analytics dashboards](analytics_dashboards.md)
- [Security Dashboards](../application_security/security_dashboard/index.md)
- [CI/CD analytics and DORA metrics](ci_cd_analytics.md)
- [Code review analytics](code_review_analytics.md)
- [Contributor statistics](../../user/analytics/contributor_statistics.md)
- [Insights](../project/insights/index.md)
- [Issue analytics](../../user/analytics/issue_analytics.md)
- [Merge request analytics](merge_request_analytics.md), enabled with the `project_merge_request_analytics`
  [feature flag](../../development/feature_flags/index.md#enabling-a-feature-flag-locally-in-development)
- [Repository analytics](repository_analytics.md)
- [Value Stream Management Analytics](../group/value_stream_analytics/index.md) and [Value Stream Management Dashboard](value_streams_dashboard.md)

## User-configurable analytics

View vulnerabilities of your selected projects in the [Security Center](../application_security/security_dashboard/index.md#security-center).

## Value streams management

Analyze and visualize the performance of your projects and groups with:

- [Value stream analytics for projects and groups](../group/value_stream_analytics/index.md)
- [Value streams dashboard](value_streams_dashboard.md)

## Glossary

| Metric | Definition | Measurement in GitLab |
| ------ | ---------- | --------------------- |
| Mean Time to Change (MTTC) | The average duration between idea and delivery. | From issue creation to the issue's latest related merge request's deployment to production. |
| Mean Time to Detect (MTTD) | The average duration that a bug goes undetected in production. | From deployment of bug to issue creation. |
| Mean Time To Merge (MTTM) | The average lifespan of a merge request. | From merge request creation to merge request merge (excluding closed and unmerged merge requests). For more information, see [Merge Request Analytics](merge_request_analytics.md). |
| Mean Time to Recover/Repair/Resolution/Resolve/Restore (MTTR) | The average duration that a bug is not fixed in production. | From deployment of bug to deployment of fix. |
| Velocity | The total issue burden completed in some period of time. The burden is usually measured in points or weight, often per sprint. | Total points or weight of issues closed in a given period of time. Expressed as, for example, "30 points per sprint". |
