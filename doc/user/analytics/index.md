---
stage: Manage
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Analytics

## Definitions

When we describe GitLab analytics, we use the following terms:

- Cycle time: The duration of your value stream, from start to finish. Often displayed in combination with "lead time." GitLab measures cycle time from issue creation to issue close. GitLab displays cycle time in [Value Stream Analytics](value_stream_analytics.md).
- DORA (DevOps Research and Assessment) ["Four Keys"](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance):
  - Speed
    - Deployment Frequency: How often an organization successfully releases to production.
    - Lead Time for Changes: The time it takes for a commit to get into production. This differs from ordinary "lead time" as it "focuses on measuring only the time to deliver a feature once it has been developed",
as described in ([Measuring DevOps Performance](https://devops.com/measuring-devops-performance/)).
  - Stability
    - Change Failure Rate: The percentage of deployments causing a failure in production.
    - Time to Restore Service: How long it takes an organization to recover from a failure in production.
- MTTC (Mean Time to Change): The average duration between idea and delivery. GitLab measures MTTC from issue creation to the issue's latest related merge request's deployment to production.
- MTTD (Mean Time to Detect): The average duration that a bug goes undetected in production. GitLab measures MTTD from deployment of bug to issue creation.
- MTTM (Mean Time To Merge): The average lifespan of a merge request. GitLab measures MTTM from merge request creation to merge request merge (and closed/un-merged merge requests are excluded). For more information, see [Merge Request Analytics](merge_request_analytics.md).
- MTTR (Mean Time to Recover/Repair/Resolution/Resolve/Restore): The average duration that a bug is not fixed in production. GitLab measures MTTR from deployment of bug to deployment of fix.
- Lead time: The duration of the work itself. Often displayed in combination with "cycle time." GitLab measures from issue first merge request creation to issue close. Note: Obviously work started before the creation of the first merge request. We plan to start measuring from "issue first commit" as a better proxy, although still imperfect. GitLab displays lead time in [Value Stream Analytics](value_stream_analytics.md).
- Throughput: The number of issues closed or merge requests merged (not closed) in some period of time. Often measured per sprint. GitLab displays merge request throughput in [Merge Request Analytics](merge_request_analytics.md).
- Value Stream: The entire work process that is followed to deliver value to customers. For example, the [DevOps lifecycle](https://about.gitlab.com/stages-devops-lifecycle/) is a value stream that starts with "plan" and ends with "monitor". GitLab helps you track your value stream using [Value Stream Analytics](value_stream_analytics.md).
- Velocity: The total issue burden completed in some period of time. The burden is usually measured in points or weight, often per sprint. For example, your velocity may be "30 points per sprint". GitLab measures velocity as the total points/weight of issues closed in a given period of time.

## Instance-level analytics

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12077) in GitLab 12.2.

Instance-level analytics make it possible to aggregate analytics across
GitLab, so that users can view information across multiple projects and groups
in one place.

[Learn more about instance-level analytics](../admin_area/analytics/index.md).

## Group-level analytics

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/195979) in GitLab 12.8.

The following analytics features are available at the group level:

- [Contribution](../group/contribution_analytics/index.md). **(STARTER)**
- [Insights](../group/insights/index.md). **(ULTIMATE)**
- [Issue](../group/issues_analytics/index.md). **(PREMIUM)**
- [Productivity](productivity_analytics.md) **(PREMIUM)**
- [Repositories](../group/repositories_analytics/index.md) **(PREMIUM)**
- [Value Stream](value_stream_analytics.md). **(PREMIUM)**

## Project-level analytics

The following analytics features are available at the project level:

- [CI/CD](ci_cd_analytics.md). **(FREE)**
- [Code Review](code_review_analytics.md). **(STARTER)**
- [Insights](../project/insights/index.md). **(ULTIMATE)**
- [Issue](../group/issues_analytics/index.md). **(PREMIUM)**
- [Merge Request](merge_request_analytics.md), enabled with the `project_merge_request_analytics`
  [feature flag](../../development/feature_flags/development.md#enabling-a-feature-flag-locally-in-development). **(STARTER)**
- [Repository](repository_analytics.md). **(FREE)**
- [Value Stream](value_stream_analytics.md). **(FREE)**
