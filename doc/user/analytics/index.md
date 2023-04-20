---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Analyze GitLab usage **(FREE)**

## Instance-level analytics

Instance-level analytics make it possible to aggregate analytics across
GitLab, so that users can view information across multiple projects and groups
in one place.

For more information, see [instance-level analytics](../admin_area/analytics/index.md).

## Group-level analytics

> Moved to GitLab Premium in 13.9.

GitLab provides several analytics features at the group level. Some of these features require you to use a higher tier than GitLab Free.

- [Application Security](../application_security/security_dashboard/index.md)
- [Contribution](../group/contribution_analytics/index.md)
- [DevOps Adoption](../group/devops_adoption/index.md)
- [Insights](../group/insights/index.md)
- [Issue](../group/issues_analytics/index.md)
- [Productivity](productivity_analytics.md)
- [Repositories](../group/repositories_analytics/index.md)
- [Value Stream](../group/value_stream_analytics/index.md)

## Project-level analytics

You can use GitLab to review analytics at the project level. Some of these features require you to use a higher tier than GitLab Free.

- [Application Security](../application_security/security_dashboard/index.md)
- [CI/CD & DORA](ci_cd_analytics.md)
- [Code Review](code_review_analytics.md)
- [Insights](../project/insights/index.md)
- [Issue](../group/issues_analytics/index.md)
- [Merge Request](merge_request_analytics.md), enabled with the `project_merge_request_analytics`
  [feature flag](../../development/feature_flags/index.md#enabling-a-feature-flag-locally-in-development)
- [Repository](repository_analytics.md)
- [Value Stream](value_stream_analytics.md)

## User-configurable analytics

The following analytics features are available for users to create personalized views:

- [Application Security](../application_security/security_dashboard/index.md#security-center)

Be sure to review the documentation page for this feature for GitLab tier requirements.

## Value streams management

You can use the following analytics features to analyze and visualize the performance of your projects and groups:

- [Value stream analytics for projects](value_stream_analytics.md)
- [Value stream analytics for groups](../group/value_stream_analytics/index.md)
- [Value streams dashboard](value_streams_dashboard.md)

## Glossary

We use the following terms to describe GitLab analytics:

- **Mean Time to Change (MTTC):** The average duration between idea and delivery. GitLab measures
MTTC from issue creation to the issue's latest related merge request's deployment to production.
- **Mean Time to Detect (MTTD):** The average duration that a bug goes undetected in production.
GitLab measures MTTD from deployment of bug to issue creation.
- **Mean Time To Merge (MTTM):** The average lifespan of a merge request. GitLab measures MTTM from
merge request creation to merge request merge (and closed/un-merged merge requests are excluded).
For more information, see [Merge Request Analytics](merge_request_analytics.md).
- **Mean Time to Recover/Repair/Resolution/Resolve/Restore (MTTR):** The average duration that a bug
is not fixed in production. GitLab measures MTTR from deployment of bug to deployment of fix.
- **Velocity:** The total issue burden completed in some period of time. The burden is usually measured
in points or weight, often per sprint. For example, your velocity may be "30 points per sprint". GitLab
measures velocity as the total points or weight of issues closed in a given period of time.
