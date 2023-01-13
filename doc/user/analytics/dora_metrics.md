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

- [Deployment Frequency](#deployment-frequency) and [Lead Time for Change](#lead-time-for-changes) measure team velocity.
- [Change Failure Rate](#change-failure-rate) and [Time to Restore Service](#time-to-restore-service) measure stability.

For software leaders, tracking velocity alongside quality metrics ensures they're not sacrificing quality for speed.

<div class="video-fallback">
  For an overview, see <a href="https://www.youtube.com/watch?v=1BrcMV6rCDw">GitLab Speed Run: DORA metrics in GitLab One DevOps Platform</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/1BrcMV6rCDw" frameborder="0" allowfullscreen> </iframe>
</figure>

## DORA Metrics dashboard in Value Stream Analytics

The four DORA metrics are available out-of-the-box in the [Value Stream Analytics (VSA) overview dashboard](../group/value_stream_analytics/index.md#view-dora-metrics-and-key-metrics-for-a-group).
This helps you visualize the engineering work in the context of end-to-end value delivery.

The One DevOps Platform [Value Stream Management](https://gitlab.com/gitlab-org/gitlab/-/value_stream_analytics) provides end-to-end visibility to the entire software delivery lifecycle.
This enables teams and managers to understand all aspects of productivity, quality, and delivery, without the ["toolchain tax"](https://about.gitlab.com/solutions/value-stream-management/).

## Deployment frequency

Deployment frequency is the frequency of successful deployments to production (hourly, daily, weekly, monthly, or yearly).
This measures how often you deliver value to end users. A higher deployment frequency means you can
get feedback sooner and iterate faster to deliver improvements and features. GitLab measures this as the number of
deployments to a production environment in the given time period.

Deployment frequency displays in several charts:

- [Group-level value stream analytics](../group/value_stream_analytics/index.md)
- [Project-level value stream analytics](value_stream_analytics.md)
- [CI/CD analytics](ci_cd_analytics.md)

To retrieve metrics for deployment frequency, use the [GraphQL](../../api/graphql/reference/index.md) or the [REST](../../api/dora/metrics.md) APIs.

## Lead time for changes

DORA Lead time for changes measures the time to successfully deliver a commit into production.
This metric reflects the efficiency of CI/CD pipelines.

In GitLab, Lead time for changes calculates the median time it takes for a merge request to get merged into production.
We measure **from** code committed **to** code successfully running in production, without adding the `coding_time` to the calculation.

Over time, the lead time for changes should decrease, while your team's performance should increase.

Lead time for changes displays in several charts:

- [Group-level value stream analytics](../group/value_stream_analytics/index.md)
- [Project-level value stream analytics](value_stream_analytics.md)
- [CI/CD analytics](ci_cd_analytics.md)

To retrieve metrics for lead time for changes, use the [GraphQL](../../api/graphql/reference/index.md) or the [REST](../../api/dora/metrics.md) APIs.

- The definition of lead time for change can vary widely, which often creates confusion within the industry.
- "Lead time for changes" is not the same as "Lead time". In the value stream, "Lead time" measures the time it takes for work on an issue to move from the moment it's requested (Issue created) to the moment it's fulfilled and delivered (Issue closed).

## Time to restore service

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

## Change failure rate

Change failure rate measures the percentage of deployments that cause a failure in production. GitLab measures this as the number
of incidents divided by the number of deployments to a
production environment in the given time period. This assumes:

- All incidents are related to a production environment.
- Incidents and deployments have a strictly one-to-one relationship. An incident is related to only
one production deployment, and any production deployment is related to no
more than one incident.

To retrieve metrics for change failure rate, use the [GraphQL](../../api/graphql/reference/index.md) or the [REST](../../api/dora/metrics.md) APIs.

### Insights: Custom DORA reporting

Custom charts to visualize DORA data with [Insights YAML-based reports](../../user/project/insights/index.md#dora-query-parameters).

With this new visualization, software leaders can track metrics improvements, understand patterns in their metrics trends, and compare performance between groups and projects.

### Measure DORA metrics without using GitLab CI/CD pipelines

Deployment frequency is calculated based on the deployments record, which is created for typical push-based deployments.
These deployment records are not created for pull-based deployments, for example when Container Images are connected to GitLab with an agent.

To track DORA metrics in these cases, you can [create a deployment record](../../api/deployments.md#create-a-deployment) using the Deployments API. See also the documentation page for [Track deployments of an external deployment tool](../../ci/environments/external_deployment_tools.md).

### Supported DORA metrics in GitLab

| Metric                    | Level             | API                                                 | UI chart               | Comments |
|---------------------------|-------------------|-----------------------------------------------------|------------------------|----------|
| `deployment_frequency`    | Project           | [GitLab 13.7 and later](../../api/dora/metrics.md)  | GitLab 14.8 and later  | The previous API endpoint was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/323713) in 13.10. |
| `deployment_frequency`    | Group             | [GitLab 13.10 and later](../../api/dora/metrics.md) | GitLab 13.12 and later |          |
| `lead_time_for_changes`   | Project           | [GitLab 13.10 and later](../../api/dora/metrics.md) | GitLab 13.11 and later | Unit in seconds. Aggregation method is median. |
| `lead_time_for_changes`   | Group             | [GitLab 13.10 and later](../../api/dora/metrics.md) | GitLab 14.0 and later  | Unit in seconds. Aggregation method is median. |
| `time_to_restore_service` | Project and group | [GitLab 14.9 and later](../../api/dora/metrics.md)  | GitLab 15.1 and later  | Unit in days. Aggregation method is median. |
| `change_failure_rate`     | Project and group | [GitLab 14.10 and later](../../api/dora/metrics.md) | GitLab 15.2 and later  | Percentage of deployments. |
