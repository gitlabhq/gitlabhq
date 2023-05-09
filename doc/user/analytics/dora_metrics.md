---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# DevOps Research and Assessment (DORA) metrics **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/275991) in GitLab 13.7.
> - [Added support](https://gitlab.com/gitlab-org/gitlab/-/issues/291746) for lead time for changes in GitLab 13.10.

The [DevOps Research and Assessment (DORA)](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)
team has identified four metrics that measure DevOps performance.
Using these metrics helps improve DevOps efficiency and communicate performance to business stakeholders, which can accelerate business results.

DORA includes four key metrics, divided into two core areas of DevOps:

- [Deployment frequency](#deployment-frequency) and [Lead time for changes](#lead-time-for-changes) measure team velocity.
- [Change failure rate](#change-failure-rate) and [Time to restore service](#time-to-restore-service) measure stability.

For software leaders, tracking velocity alongside quality metrics ensures they're not sacrificing quality for speed.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video explanation, see [DORA metrics: User analytics](https://www.youtube.com/watch?v=lM_FbVYuN8s) and [GitLab speed run: DORA metrics](https://www.youtube.com/watch?v=1BrcMV6rCDw).

## DORA metrics in Value Stream Analytics

The four DORA metrics are available out-of-the-box in the [Value Streams Dashboard](value_streams_dashboard.md).
This helps you visualize the engineering work in the context of end-to-end value delivery.

The One DevOps Platform [Value Stream Management](https://gitlab.com/gitlab-org/gitlab/-/value_stream_analytics) provides end-to-end visibility to the entire software delivery lifecycle.
This enables teams and managers to understand all aspects of productivity, quality, and delivery, without the ["toolchain tax"](https://about.gitlab.com/solutions/value-stream-management/).

## Deployment frequency

> [Fixed](https://gitlab.com/gitlab-org/gitlab/-/issues/394712) the frequency calculation formula for the `all` and `monthly` intervals in GitLab 16.0.

Deployment frequency is the frequency of successful deployments to production over the given date range (hourly, daily, weekly, monthly, or yearly).

Software leaders can use the deployment frequency metric to understand how often the team successfully deploys software to production, and how quickly the teams can respond to customers' requests or new market opportunities.
High deployment frequency means you can get feedback sooner and iterate faster to deliver improvements and features.

### How deployment frequency is calculated

In GitLab, Deployment frequency is measured by the average number of deployments per day to a given environment, based on the deployment's end time (its `finished_at` property).
GitLab calculates the deployment frequency from the number of finished deployments on the given day.

The calculation takes into account the production `environment tier` or the environments named `production/prod`. The environment must be part of the production deployment tier for its deployment information to appear on the graphs.

### How to improve deployment frequency

The first step is to benchmark the cadence of code releases between groups and projects. Next, you should consider:

- Add more automated testing.
- Add more automated code validation.
- Break the changes down into smaller iterations.

## Lead time for changes

Lead time for changes is the amount of time it takes a code change to get into production.

"Lead time for changes" is not the same as "Lead time". In the value stream, "Lead time" measures the time it takes for work on an issue to move from the moment it's requested (Issue created) to the moment it's fulfilled and delivered (Issue closed).

For software leaders, Lead time for changes reflects the efficiency of CI/CD pipelines and visualizes how quickly work is delivered to customers.
Over time, the lead time for changes should decrease, while your team's performance should increase. Low lead time for changes means more efficient CI/CD pipelines.
In GitLab, Lead time for changes is measure by the `Median time it takes for a merge request to get merged into production (from master)`.

### How lead time for changes is calculated

GitLab calculates Lead time for changes base on the number of seconds to successfully deliver a commit into production - **from** code committed **to** code successfully running in production, without adding the `coding_time` to the calculation.

### How to improve lead time for changes

The first step is to benchmark the CI/CD pipelines' efficiency between groups and projects. Next, you should consider:

- Using Value Stream Analytics to identify bottlenecks in the processes.
- Breaking the changes down into smaller iterations.
- Adding more automation.

## Time to restore service

Time to restore service is the amount of time it takes an organization to recover from a failure in production.

For software leaders, Time to restore service reflects how long it takes an organization to recover from a failure in production.
Low Time to restore service means the organization can take risks with new innovative features to drive competitive advantages and increase business results.

### How time to restore service is calculated

In GitLab, Time to restore service is measured as the median time an incident was open for on a production environment.
GitLab calculates the number of seconds an incident was open on a production environment in the given time period. This assumes:

- [GitLab incidents](../../operations/incident_management/incidents.md) are tracked.
- All incidents are related to a production environment.
- Incidents and deployments have a strictly one-to-one relationship. An incident is related to only one production deployment, and any production deployment is related to no more than one incident.

### How to improve time to restore service

The first step is to benchmark the team response and recover from service interruptions and outages, between groups and projects. Next, you should consider:

- Improving the observability into the production environment.
- Improving response workflows.

## Change failure rate

Change failure rate is how often a change cause failure in production.

Software leaders can use the change failure rate metric to gain insights into the quality of the code being shipped.
High change failure rate may indicate an inefficient deployment process or insufficient automated testing coverage.

### How change failure rate is calculated

In GitLab, Change failure rate is measured as the percentage of deployments that cause an incident in production in the given time period.
GitLab calculates this by the number of incidents divided by the number of deployments to a production environment. This assumes:

- [GitLab incidents](../../operations/incident_management/incidents.md) are tracked.
- All incidents are related to a production environment.
- Incidents and deployments have a strictly one-to-one relationship. An incident is related to only one production deployment, and any production deployment is related to no
more than one incident.

### How to improve change failure rate

The first step is to benchmark the quality and stability, between groups and projects.

To improve this metric, you should consider:

- Finding the right balance between stability and throughput (Deployment frequency and Lead time for changes), and not sacrificing quality for speed.
- Improving the efficacy of code review processes.
- Adding more automated testing.

## DORA metrics in GitLab

The DORA metrics are displayed on the following charts:

- [Value Streams Dashboard](value_streams_dashboard.md), which helps you identify trends, patterns, and opportunities for improvement.
- [CI/CD analytics charts](ci_cd_analytics.md), which show pipeline success rates and duration, and the history of DORA metrics over time.
- Insights reports for [groups](../group/insights/index.md) and [projects](value_stream_analytics.md), where you can also use [DORA query parameters](../../user/project/insights/index.md#dora-query-parameters) to create custom charts.

The table below provides an overview of the DORA metrics' data aggregation in different charts.

| Metric name | Measured values | Data aggregation in the [Value Streams Dashboard](value_streams_dashboard.md) | Data aggregation in [CI/CD analytics charts](ci_cd_analytics.md) | Data aggregation in [Custom insights reporting](../../user/project/insights/index.md#dora-query-parameters) |
|---------------------------|-------------------|-----------------------------------------------------|------------------------|----------|
| Deployment frequency | Number of successful deployments | daily average per month | daily average | `day` (default) or `month` |
| Lead time for changes | Number of seconds to successfully deliver a commit into production | daily median per month | median time |  `day` (default) or `month` |
| Time to restore service | Number of seconds an incident was open for           | daily median per month | daily median | `day` (default) or `month` |
| Change failure rate | percentage of deployments that cause an incident in production | daily median per month | percentage of failed deployments | `day` (default) or `month` |

## Retrieve DORA metrics data

To retrieve DORA data, use the [GraphQL](../../api/graphql/reference/index.md) or the [REST](../../api/dora/metrics.md) APIs.

### Measure DORA metrics without using GitLab CI/CD pipelines

Deployment frequency is calculated based on the deployments record, which is created for typical push-based deployments.
These deployment records are not created for pull-based deployments, for example when Container Images are connected to GitLab with an agent.

To track DORA metrics in these cases, you can [create a deployment record](../../api/deployments.md#create-a-deployment) using the Deployments API. See also the documentation page for [Track deployments of an external deployment tool](../../ci/environments/external_deployment_tools.md).

### Measure DORA metrics with Jira

- Deployment frequency and Lead time for changes are calculated based on GitLab CI/CD and Merge Requests (MRs), and do not require Jira data.
- Time to restore service and Change failure rate require GitLab incidents for the calculation. For more information, see [Measure DORA Time to restore service and Change failure rate with external incidents](#measure-dora-time-to-restore-service-and-change-failure-rate-with-external-incidents).

### Measure DORA Time to restore service and Change failure rate with external incidents

[Time to restore service](#time-to-restore-service) and [Change failure rate](#change-failure-rate)
require [GitLab incidents](../../operations/incident_management/manage_incidents.md) to calculate the metrics.

For PagerDuty, you can set up a [webhook to automatically create a GitLab incident for each PagerDuty incident](../../operations/incident_management/manage_incidents.md#using-the-pagerduty-webhook).
This configuration requires you to make changes in both PagerDuty and GitLab.

For others incident management tools, you can set up the
[HTTP integration](../../operations/incident_management/integrations.md#http-endpoints),
and use it to automatically:

1. [Create an incident when an alert is triggered](../../operations/incident_management/manage_incidents.md#automatically-when-an-alert-is-triggered).
1. [Close incidents via recovery alerts](../../operations/incident_management/manage_incidents.md#automatically-close-incidents-via-recovery-alerts).

### Supported DORA metrics in GitLab

| Metric                    | Level             | API                                                 | UI chart               | Comments |
|---------------------------|-------------------|-----------------------------------------------------|------------------------|----------|
| `deployment_frequency`    | Project           | [GitLab 13.7 and later](../../api/dora/metrics.md)  | GitLab 14.8 and later  | The previous API endpoint was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/323713) in 13.10. |
| `deployment_frequency`    | Group             | [GitLab 13.10 and later](../../api/dora/metrics.md) | GitLab 13.12 and later |          |
| `lead_time_for_changes`   | Project           | [GitLab 13.10 and later](../../api/dora/metrics.md) | GitLab 13.11 and later | Unit in seconds. Aggregation method is median. |
| `lead_time_for_changes`   | Group             | [GitLab 13.10 and later](../../api/dora/metrics.md) | GitLab 14.0 and later  | Unit in seconds. Aggregation method is median. |
| `time_to_restore_service` | Project and group | [GitLab 14.9 and later](../../api/dora/metrics.md)  | GitLab 15.1 and later  | Unit in days. Aggregation method is median. |
| `change_failure_rate`     | Project and group | [GitLab 14.10 and later](../../api/dora/metrics.md) | GitLab 15.2 and later  | Percentage of deployments. |
