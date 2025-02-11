---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DevOps Research and Assessment (DORA) metrics
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The [DevOps Research and Assessment (DORA)](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)
team has identified four metrics that measure DevOps performance.
Using these metrics helps improve DevOps efficiency and communicate performance to business stakeholders, which can accelerate business results.

DORA includes four key metrics, divided into two core areas of DevOps:

- [Deployment frequency](#deployment-frequency) and [Lead time for changes](#lead-time-for-changes) measure team *velocity*.
- [Change failure rate](#change-failure-rate) and [Time to restore service](#time-to-restore-service) measure *stability*.

For software leaders, tracking velocity alongside quality metrics ensures they're not sacrificing quality for speed.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video explanation, see [DORA metrics: User analytics](https://www.youtube.com/watch?v=jYQSH4EY6_U) and [GitLab speed run: DORA metrics](https://www.youtube.com/watch?v=1BrcMV6rCDw).

## Deployment frequency

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/394712) fix for the frequency calculation formula for `all` and `monthly` intervals in GitLab 16.0.

Deployment frequency is the frequency of successful deployments to production over the given date range (hourly, daily, weekly, monthly, or yearly).

Software leaders can use the deployment frequency metric to understand how often the team successfully deploys software to production, and how quickly the teams can respond to customers' requests or new market opportunities.
High deployment frequency means you can get feedback sooner and iterate faster to deliver improvements and features.

### Deployment frequency forecasting

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Experiment

Deployment frequency forecasting (formerly named Value stream forecasting) uses a statistical forecasting model to predict productivity metrics and identify anomalies across the software development lifecycle.
This information can help you improve planning and decision-making for your product and teams.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch an overview of [Value stream forecasting](https://www.youtube.com/watch?v=6u8_8QQ5pEQ&list=PLFGfElNsQthYDx0A_FaNNfUm9NHsK6zED).

### How deployment frequency is calculated

In GitLab, deployment frequency is measured by the average number of deployments per day to a given environment, based on the deployment's end time (its `finished_at` property).
GitLab calculates the deployment frequency from the number of finished deployments on the given day. Only successful deployments (`Deployment.statuses = success`) are counted.

The calculation takes into account the production `environment tier` or the environments named `production/prod`. The environment must be part of the production deployment tier for its deployment information to appear on the graphs.

You can configure DORA metrics for different environments by specifying `other` under the `environment_tiers` parameter in the [`.gitlab/insights.yml` file](../project/insights/_index.md#insights-configuration-file).

NOTE:
Deployment frequency is calculated as the **average (mean)**, unlike the other DORA metrics that use the median, which is preferred because it provides a more accurate and reliable view of performance.
This difference is because deployment frequency was added to GitLab prior to adopting the DORA framework, and the calculation of this metric remained unchanged when it was incorporated into other reports.
[Issue 499591](https://gitlab.com/gitlab-org/gitlab/-/issues/499591) proposes offering the option to customize the calculation method for each metric, choosing between mean and median.

### How to improve deployment frequency

The first step is to benchmark the cadence of code releases between groups and projects. Next, you should consider:

- Adding automated testing.
- Adding automated code validation.
- Breaking the changes down into smaller iterations.

## Lead time for changes

Lead time for changes is the amount of time it takes a code change to get into production.

**Lead time for changes** is not the same as **Lead time**. In value stream analytics, lead time measures the time it takes for work on an issue to move from the moment it's requested (Issue created) to the moment it's fulfilled and delivered (Issue closed).

For software leaders, lead time for changes reflects the efficiency of CI/CD pipelines and visualizes how quickly work is delivered to customers.
Over time, the lead time for changes should decrease, while your team's performance should increase. Low lead time for changes means more efficient CI/CD pipelines.

### How lead time for changes is calculated

GitLab calculates lead time for changes based on the number of seconds to successfully deliver a merge request into production: from merge request merge time (when the merge button is clicked) to code successfully running in production, without adding the `coding_time` to the calculation. Data is aggregated right after the deployment is finished, with a slight delay.

By default, lead time for changes supports measuring only one branch operation with multiple deployment jobs (for example, from development to staging to production on the default branch). When a merge request gets merged on staging, and then on production, GitLab interprets them as two deployed merge requests, not one.

### How to improve lead time for changes

The first step is to benchmark the CI/CD pipelines' efficiency between groups and projects. Next, you should consider:

- Using Value Stream Analytics to identify bottlenecks in the processes.
- Breaking the changes down into smaller iterations.
- Adding automation.
- Improving the performance of your pipelines.

## Time to restore service

Time to restore service is the amount of time it takes an organization to recover from a failure in production.

For software leaders, time to restore service reflects how long it takes an organization to recover from a failure in production.
Low time to restore service means the organization can take risks with new innovative features to drive competitive advantages and increase business results.

### How time to restore service is calculated

In GitLab, time to restore service is measured as the median time an incident was open on a production environment.
GitLab calculates the number of seconds an incident was open on a production environment in the given time period. This assumes:

- [GitLab incidents](../../operations/incident_management/incidents.md) are tracked.
- All incidents are related to a production environment.
- Incidents and deployments have a strictly one-to-one relationship. An incident is related to only one production deployment, and any production deployment is related to no more than one incident.

### How to improve time to restore service

The first step is to benchmark the team response and recover from service interruptions and outages, between groups and projects. Next, you should consider:

- Improving the observability into the production environment.
- Improving response workflows.
- Improving deployment frequency and lead time for changes so fixes can get into production more efficiently.

## Change failure rate

Change failure rate is how often a change causes a failure in production.

Software leaders can use the change failure rate metric to gain insights into the quality of the code being shipped.
High change failure rate may indicate an inefficient deployment process or insufficient automated testing coverage.

### How change failure rate is calculated

In GitLab, change failure rate is measured as the percentage of deployments that cause an incident in production in a given time period.
GitLab calculates change failure rate as the number of incidents divided by the number of deployments to a production environment. This calculation assumes:

- [GitLab incidents](../../operations/incident_management/incidents.md) are tracked.
- All incidents are production incidents, regardless of the environment.
- Change failure rate is used primarily as high-level stability tracking, which is why in a given day, all incidents and deployments are aggregated into a joined daily rate. Adding specific relations between deployments and incidents is proposed in [issue 444295](https://gitlab.com/gitlab-org/gitlab/-/issues/444295).
- Change failure rate calculates duplicate incidents as separate entries, which results in double counting. [Issue 480920](https://gitlab.com/gitlab-org/gitlab/-/issues/480920) proposes a solution for a more accurate calculation.

For example, if you have 10 deployments (considering one deployment per day) with two incidents on the first day and one incident on the last day, then your change failure rate is 0.3.

### How to improve change failure rate

The first step is to benchmark the quality and stability, between groups and projects. Next, you should consider:

- Finding the right balance between stability and throughput (Deployment frequency and Lead time for changes), and not sacrificing quality for speed.
- Improving the efficacy of code review processes.
- Adding automated testing.

## DORA custom calculation rules

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96561) in GitLab 15.4 [with a flag](../../administration/feature_flags.md) named `dora_configuration`. Disabled by default. This feature is an [experiment](../../policy/development_stages_support.md).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

This feature is an [experiment](../../policy/development_stages_support.md).
To join the list of users testing this feature, [here is a suggested test flow](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96561#steps-to-check-on-localhost).
If you find a bug, [open an issue here](https://gitlab.com/groups/gitlab-org/-/epics/11490).
To share your use cases and feedback, comment in [epic 11490](https://gitlab.com/groups/gitlab-org/-/epics/11490).

### Multi-branch rule for lead time for changes

Unlike the default [calculation of lead time for changes](#how-lead-time-for-changes-is-calculated), this calculation rule allows measuring multi-branch operations with a single deployment job for each operation.
For example, from development job on development branch, to staging job on staging branch, to production job on production branch.

This calculation rule has been implemented by updating the `dora_configurations` table with the target branches that are part of the development flow.
This way, GitLab can recognize the branches as one, and filter out other merge requests.

This configuration changes how daily DORA metrics are calculated for the selected project, but doesn't affect other projects, groups, or users.

This feature supports only project-level propagation.

To do this, in the Rails console run the following command:

```ruby
my_project = Project.find_by_full_path('group/subgroup/project')
Dora::Configuration.create!(project: my_project, branches_for_lead_time_for_changes: ['master', 'main'])
```

To update an existing configuration, run the following command:

```ruby
my_project = Project.find_by_full_path('group/subgroup/project')
record = Dora::Configuration.where(project: my_project).first
record.branches_for_lead_time_for_changes = ['development', 'staging', 'master', 'main']
record.save!
```

## Measure DORA metrics

### Without using GitLab CI/CD pipelines

Deployment frequency is calculated based on the deployments record, which is created for typical push-based deployments.
These deployment records are not created for pull-based deployments, for example when Container Images are connected to GitLab with an agent.

To track DORA metrics in these cases, you can [create a deployment record](../../api/deployments.md#create-a-deployment) using the Deployments API.
You must set the environment name where the deployment tier is configured, because the tier variable is specified for the given environment, not for the deployments.
For more information, see how to [track deployments of an external deployment tool](../../ci/environments/external_deployment_tools.md).

### With Jira

- Deployment frequency and lead time for changes are calculated based on GitLab CI/CD and Merge Requests (MRs), and do not require Jira data.
- Time to restore service and change failure rate require [GitLab incidents](../../operations/incident_management/manage_incidents.md) for the calculation. For more information, see how to measure these metrics [with external incidents](#with-external-incidents) and the [Jira incident replicator guide](https://gitlab.com/smathur/jira-incident-replicator).

### With external incidents

You can measure the time to restore service and change failure rate for incident management.

For PagerDuty, you can [set up a webhook](../../operations/incident_management/manage_incidents.md#using-the-pagerduty-webhook)
to automatically create a GitLab incident for each PagerDuty incident.
This configuration requires you to make changes in both PagerDuty and GitLab.

For other incident management tools, you can set up the
[HTTP integration](../../operations/incident_management/integrations.md#http-endpoints),
and use it to automatically:

1. [Create an incident when an alert is triggered](../../operations/incident_management/manage_incidents.md#automatically-when-an-alert-is-triggered).
1. [Close incidents via recovery alerts](../../operations/incident_management/manage_incidents.md#automatically-close-incidents-via-recovery-alerts).

## Analytics features

DORA metrics are displayed in the following analytics features:

- [Value Streams Dashboard](value_streams_dashboard.md) includes the [DORA metrics comparison panel](value_streams_dashboard.md#devsecops-metrics-comparison-panels) and [DORA Performers score panel](value_streams_dashboard.md#dora-performers-score-panel).
- [CI/CD analytics charts](ci_cd_analytics.md) show the history of DORA metrics over time.
- [Insights reports](../project/insights/_index.md) provide the option to create custom charts with [DORA query parameters](../project/insights/_index.md#dora-query-parameters).
- [GraphQL API](../../api/graphql/reference/_index.md) (with the interactive [GraphQL explorer](../../api/graphql/_index.md#interactive-graphql-explorer)) and [REST API](../../api/dora/metrics.md) support the retrieval of metrics data.

## Project and group availability

The following table provides an overview of the DORA metrics' availability in projects and groups.

| Metric                    | Level             | Comments |
|---------------------------|-------------------|----------|
| `deployment_frequency`    | Project           | Unit in deployment count. |
| `deployment_frequency`    | Group             | Unit in deployment count. Aggregation method is average.  |
| `lead_time_for_changes`   | Project           | Unit in seconds. Aggregation method is median. |
| `lead_time_for_changes`   | Group             | Unit in seconds. Aggregation method is median. |
| `time_to_restore_service` | Project and group | Unit in days. Aggregation method is median. (Available in UI chart in GitLab 15.1 and later) |
| `change_failure_rate`     | Project and group | Percentage of deployments. (Available in UI chart in GitLab 15.2 and later) |

## Data aggregation

The following table provides an overview of the DORA metrics' data aggregation in different charts.

| Metric name | Measured values | Data aggregation in the [Value Streams Dashboard](value_streams_dashboard.md) | Data aggregation in [CI/CD analytics charts](ci_cd_analytics.md) | Data aggregation in [Custom insights reporting](../project/insights/_index.md#dora-query-parameters) |
|---------------------------|-------------------|-----------------------------------------------------|------------------------|----------|
| Deployment frequency | Number of successful deployments | daily average per month | daily average | `day` (default) or `month` |
| Lead time for changes | Number of seconds to successfully deliver a commit into production | daily median per month | median time |  `day` (default) or `month` |
| Time to restore service | Number of seconds an incident was open for           | daily median per month | daily median | `day` (default) or `month` |
| Change failure rate | percentage of deployments that cause an incident in production | daily median per month | percentage of failed deployments | `day` (default) or `month` |
