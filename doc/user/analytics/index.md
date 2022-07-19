---
stage: Manage
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Analyze GitLab usage **(FREE)**

## Instance-level analytics

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12077) in GitLab 12.2.

Instance-level analytics make it possible to aggregate analytics across
GitLab, so that users can view information across multiple projects and groups
in one place.

[Learn more about instance-level analytics](../admin_area/analytics/index.md).

## Group-level analytics

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/195979) in GitLab 12.8.
> - Moved to GitLab Premium in 13.9.

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
- [CI/CD](ci_cd_analytics.md)
- [Code Review](code_review_analytics.md)
- [Insights](../project/insights/index.md)
- [Issue](../group/issues_analytics/index.md)
- [Merge Request](merge_request_analytics.md), enabled with the `project_merge_request_analytics`
  [feature flag](../../development/feature_flags/index.md#enabling-a-feature-flag-locally-in-development)
- [Repository](repository_analytics.md)
- [Value Stream](value_stream_analytics.md)

## User-configurable analytics

The following analytics features are available for users to create personalized views:

- [Application Security](../application_security/security_dashboard/#security-center)

Be sure to review the documentation page for this feature for GitLab tier requirements.

## DevOps Research and Assessment (DORA) key metrics **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/275991) in GitLab 13.7.
> - [Added support](https://gitlab.com/gitlab-org/gitlab/-/issues/291746) for lead time for changes in GitLab 13.10.

The [DevOps Research and Assessment (DORA)](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)
team developed several key metrics that you can use as performance indicators for software development
teams.

### Deployment frequency

Deployment frequency is the frequency of successful deployments to production (hourly, daily, weekly, monthly, or yearly).
This measures how often you deliver value to end users. A higher deployment frequency means you can
get feedback sooner and iterate faster to deliver improvements and features. GitLab measures this as the number of
deployments to a production environment in the given time period.

Deployment frequency displays in several charts:

- [Group-level value stream analytics](../group/value_stream_analytics/index.md)
- [Project-level value stream analytics](value_stream_analytics.md)
- [CI/CD analytics](ci_cd_analytics.md)

To retrieve metrics for deployment frequency, use the [GraphQL](../../api/graphql/reference/index.md) or the [REST](../../api/dora/metrics.md) APIs.

### Lead time for changes

Lead time for changes measures the time to deliver a feature once it has been developed,
as described in [Measuring DevOps Performance](https://devops.com/measuring-devops-performance/).

Lead time for changes displays in several charts:

- [Group-level value stream analytics](../group/value_stream_analytics/index.md)
- [Project-level value stream analytics](value_stream_analytics.md)
- [CI/CD analytics](ci_cd_analytics.md)

To retrieve metrics for lead time for changes, use the [GraphQL](../../api/graphql/reference/index.md) or the [REST](../../api/dora/metrics.md) APIs.

### Time to restore service

Time to restore service measures how long it takes an organization to recover from a failure in production.
GitLab measures this as the average time required to close the incidents
in the given time period. This assumes:

- All incidents are related to a production environment.
- Incidents and deployments have a strictly one-to-one relationship. An incident is related to only
one production deployment, and any production deployment is related to no more than one incident).

Time to restore service displays in several charts:

- [Group-level value stream analytics](../group/value_stream_analytics/index.md)
- [Project-level value stream analytics](value_stream_analytics.md)
- [CI/CD analytics](ci_cd_analytics.md)

To retrieve metrics for time to restore service, use the [GraphQL](../../api/graphql/reference/index.md) or the [REST](../../api/dora/metrics.md) APIs.

### Change failure rate

Change failure rate measures the percentage of deployments that cause a failure in production. GitLab measures this as the number
of incidents divided by the number of deployments to a
production environment in the given time period. This assumes:

- All incidents are related to a production environment.
- Incidents and deployments have a strictly one-to-one relationship. An incident is related to only
one production deployment, and any production deployment is related to no
more than one incident.

To retrieve metrics for change failure rate, use the [GraphQL](../../api/graphql/reference/index.md) or the [REST](../../api/dora/metrics.md) APIs.

### Supported DORA metrics in GitLab

| Metric                    | Level                   | API                                 | UI chart                              | Comments                      |
|---------------------------|-------------------------|-------------------------------------|---------------------------------------|-------------------------------|
| `deployment_frequency`    | Project           | [GitLab 13.7 and later](../../api/dora/metrics.md)  | GitLab 14.8 and later                                 | The previous API endpoint was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/323713) in 13.10.                                                                                                                                               |
| `deployment_frequency`    | Group             | [GitLab 13.10 and later](../../api/dora/metrics.md) | GitLab 13.12 and later                                |                                                |
| `lead_time_for_changes`   | Project           | [GitLab 13.10 and later](../../api/dora/metrics.md) | GitLab 13.11 and later                                | Unit in seconds. Aggregation method is median. |
| `lead_time_for_changes`   | Group             | [GitLab 13.10 and later](../../api/dora/metrics.md) | GitLab 14.0 and later                                 | Unit in seconds. Aggregation method is median. |
| `time_to_restore_service` | Project and group | [GitLab 14.9 and later](../../api/dora/metrics.md)  | GitLab 15.1 and later                                 | Unit in days. Aggregation method is median.    |
| `change_failure_rate`     | Project and group | [GitLab 14.10 and later](../../api/dora/metrics.md) | GitLab 15.2 and later                                 | Percentage of deployments.                     |                 |

## Definitions

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
