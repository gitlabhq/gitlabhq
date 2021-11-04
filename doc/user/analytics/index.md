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

- [Application Security](../application_security/security_dashboard/#group-security-dashboard)
- [Contribution](../group/contribution_analytics/index.md)
- [DevOps Adoption](../group/devops_adoption/index.md)
- [Insights](../group/insights/index.md)
- [Issue](../group/issues_analytics/index.md)
- [Productivity](productivity_analytics.md)
- [Repositories](../group/repositories_analytics/index.md)
- [Value Stream](../group/value_stream_analytics/index.md)

## Project-level analytics

You can use GitLab to review analytics at the project level. Some of these features require you to use a higher tier than GitLab Free.

- [Application Security](../application_security/security_dashboard/#project-security-dashboard)
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

## Definitions

We use the following terms to describe GitLab analytics:

- **Cycle time:** The duration of only the execution work. Cycle time is often displayed in combination with the lead time, which is longer than the cycle time. GitLab measures cycle time from the earliest commit of a [linked issue's merge request](../project/issues/crosslinking_issues.md) to when that issue is closed. The cycle time approach underestimates the lead time because merge request creation is always later than commit time. GitLab displays cycle time in [group-level Value Stream Analytics](../group/value_stream_analytics/index.md) and [project-level Value Stream Analytics](../analytics/value_stream_analytics.md).
- **Deploys:** The total number of successful deployments to production in the given time frame (across all applicable projects). GitLab displays deploys in [group-level Value Stream Analytics](../group/value_stream_analytics/index.md) and [project-level Value Stream Analytics](value_stream_analytics.md).
- **DORA (DevOps Research and Assessment)** ["Four Keys"](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance):
  - **Speed/Velocity**

    - **Deployment frequency:** The relative frequency of successful deployments to production
      (hourly, daily, weekly, monthly, or yearly).
      This measures how often you are delivering value to end users. A higher deployment
      frequency means you are able to get feedback and iterate faster to deliver
      improvements and features. GitLab measures this as the number of deployments to a
      [production environment](../../ci/environments/index.md#deployment-tier-of-environments) in
      the given time period.
      GitLab displays deployment frequency in [group-level Value Stream Analytics](../group/value_stream_analytics/index.md) and [project-level Value Stream Analytics](value_stream_analytics.md).
    - **Lead Time for Changes:** The time it takes for a commit to get into production. GitLab
      measures this as the median duration between merge request merge and deployment to a
      [production environment](../../ci/environments/index.md#deployment-tier-of-environments) for
      all MRs deployed in the given time period. This measure under estimates lead time because
      merge time is always later than commit time. The
      [standard definition](https://github.com/GoogleCloudPlatform/fourkeys/blob/main/METRICS.md#lead-time-for-changes) uses median commit time.
      [An issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/328459) to start
      measuring from "issue first commit" as a better proxy, although still imperfect.

  - **Stability**
    - **Change Failure Rate:** The percentage of deployments causing a failure in production.
      GitLab measures this as the number of [incidents](../../operations/incident_management/incidents.md)
      divided by the number of deployments to a
      [production environment](../../ci/environments/index.md#deployment-tier-of-environments) in
      the given time period. This assumes:

      - All incidents are related to a production environment.
      - Incidents and deployments have a strictly one-to-one relationship (meaning any incident is
        related to only one production deployment, and any production deployment is related to no
        more than one incident).

    - **Time to Restore Service:** How long it takes an organization to recover from a failure in
      production. GitLab measures this as the average time required to close the
      [incidents](../../operations/incident_management/incidents.md) in the given time period.
      This assumes:

      - All incidents are related to a [production environment](../../ci/environments/index.md#deployment-tier-of-environments).
      - Incidents and deployments have a strictly one-to-one relationship (meaning any incident is related to only one production deployment, and any production deployment is related to no more than one incident).

- **Lead time:** The duration of your value stream, from start to finish. Different to 
[Lead time for changes](#lead-time-for-changes). Often displayed in combination with "cycle time," 
which is shorter. GitLab measures lead time from issue creation to issue close. GitLab displays lead 
time in [group-level Value Stream Analytics](../group/value_stream_analytics/index.md).
- **Mean Time to Change (MTTC):** The average duration between idea and delivery. GitLab measures 
MTTC from issue creation to the issue's latest related merge request's deployment to production.
- **Mean Time to Detect (MTTD):** The average duration that a bug goes undetected in production. 
GitLab measures MTTD from deployment of bug to issue creation.
- **Mean Time To Merge (MTTM):** The average lifespan of a merge request. GitLab measures MTTM from 
merge request creation to merge request merge (and closed/un-merged merge requests are excluded). 
For more information, see [Merge Request Analytics](merge_request_analytics.md).
- **Mean Time to Recover/Repair/Resolution/Resolve/Restore (MTTR):** The average duration that a bug 
is not fixed in production. GitLab measures MTTR from deployment of bug to deployment of fix.
- **Throughput:** The number of issues closed or merge requests merged (not closed) in a period of 
time. Often measured per sprint. GitLab displays merge request throughput in [Merge Request Analytics](merge_request_analytics.md).
- **Value Stream:** The entire work process that is followed to deliver value to customers. For example, 
the [DevOps lifecycle](https://about.gitlab.com/stages-devops-lifecycle/) is a value stream that starts 
with "plan" and ends with "monitor". GitLab helps you track your value stream using [Value Stream Analytics](value_stream_analytics.md).
- **Velocity:** The total issue burden completed in some period of time. The burden is usually measured 
in points or weight, often per sprint. For example, your velocity may be "30 points per sprint". GitLab 
measures velocity as the total points or weight of issues closed in a given period of time.

## Lead time for changes

"Lead Time for Changes" differs from "Lead Time" because it "focuses on measuring only the time to 
deliver a feature once it has been developed", as described in ([Measuring DevOps Performance](https://devops.com/measuring-devops-performance/)).
