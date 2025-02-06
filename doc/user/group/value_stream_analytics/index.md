---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Value stream analytics
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Value stream analytics measures the time it takes to go from an idea to production.

A **value stream** is the entire work process that delivers value to customers. For example,
the [DevOps lifecycle](https://about.gitlab.com/stages-devops-lifecycle/) is a value stream that starts
with the "manage" stage and ends with the "protect" stage.

Use value stream analytics to identify:

- The amount of time it takes to go from an idea to production.
- The velocity of a given project.
- Bottlenecks in the development process.
- Long-running issues or merge requests.
- Factors that cause your software development lifecycle to slow down.

Value stream analytics helps businesses:

- Visualize their end-to-end DevSecOps workstreams.
- Identify and solve inefficiencies.
- Optimize their workstreams to deliver more value, faster.

Value stream analytics is available for projects and groups.

For a click-through demo, see [the Value Stream Management product tour](https://gitlab.navattic.com/vsm).

## Feature availability

Value stream analytics offers different features at the project and group level for FOSS and licensed versions.

- On GitLab Free, value stream analytics does not aggregate data. It queries the database directly where the date range filter is applied to the creation date of issues and merge request. You can view value stream analytics with pre-defined default stages.
- On GitLab Premium, value stream analytics aggregates data and applies the date range filter on the end event. You can also create, edit, and delete value streams.

|Feature|Group level (licensed)|Project level (licensed)|Project level (FOSS)|
|-|-|-|-|
|Create custom value streams|Yes|Yes|no, only one value stream (default) is present with the default stages|
|Create custom stages|Yes|Yes|No|
|Filtering (for example, by author, label, milestone)|Yes|Yes|Yes|
|Stage time chart|Yes|Yes|No|
|Total time chart|Yes|Yes|No|
|Task by type chart|Yes|No|No|
|DORA Metrics|Yes|Yes|No|
|Cycle time and lead time summary (Lifecycle metrics)|Yes|Yes|No|
|New issues, commits, and deploys (Lifecycle metrics)|Yes, excluding commits|Yes|Yes|
|Uses aggregated backend|Yes|Yes|No|
|Date filter behavior|Filters items [finished within the date range](https://gitlab.com/groups/gitlab-org/-/epics/6046)|Filters items by creation date.|Filters items by creation date.|
|Authorization|At least reporter|At least reporter|Can be public|

NOTE:
Feature parity of project-level with group-level value stream analytics is achieved by using the new record `ProjectNamespace`. For details about this consolidation initiative, see the [Organization documentation](../../../development/organization/_index.md).

## How value stream analytics works

Value stream analytics calculates the duration of every stage of your software development process.

Value stream analytics is made of three core objects:

- A **value stream** contains a value stream stage list.
- Each value stream stage list contains one or more **stages**.
- Each stage has two **events**: start and stop.

### Value stream stages

A stage represents an event pair (start and end events) with additional metadata, such as the name of the stage. You can configure the stages in the pairing rules defined in the backend.

### Value streams

Value streams are container objects for the stages. You can have multiple value streams per group, to focus on different aspects of the DevOps lifecycle.

### Value stream stage events

> - Merge request first reviewer assigned event [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/466383) in GitLab 17.2. Reviewer assignment events in merge requests created or updated prior to GitLab 17.2 are not available for reporting.

Events are the smallest building blocks of the value stream analytics feature. A stage consists of a start event and an end event.

The following stage events are available:

- Issue closed
- Issue created
- Issue first added to board
- Issue first added to iteration
- Issue first assigned
- Issue first associated with milestone
- Issue first mentioned
- Issue label added
- Issue label removed
- MR closed
- MR merged
- MR created
- MR first commit time
- MR first assigned
- MR first reviewer assigned
- MR first deployed
- MR label added
- MR label removed
- MR last pipeline duration

These events play a key role in the duration calculation, which is calculated by the formula: duration = end event time - start event time.

To learn what start and end events can be paired, see [Validating start and end events](../../../development/value_stream_analytics.md#validating-start-and-end-events).

### How value stream analytics aggregates data

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Enable filtering by stop date [added](https://gitlab.com/gitlab-org/gitlab/-/issues/355000) in GitLab 15.0

Value stream analytics uses a backend process to collect and aggregate stage-level data, which
ensures it can scale for large groups with a high number of issues and merge requests. Due to this process,
there may be a slight delay between when an action is taken (for example, closing an issue) and when the data
displays on the value stream analytics page.

It may take up to 10 minutes to process the data and display results. Data collection may take
longer than 10 minutes in the following cases:

- If this is the first time you are viewing value stream analytics and have not yet [created a value stream](#create-a-value-stream-with-gitlab-default-stages).
- If the group hierarchy has been re-arranged.
- If there have been bulk updates on issues and merge requests.

To view when the data was most recently updated, in the right corner next to **Edit**, hover over the **Last updated** badge.

### How value stream analytics measures stages

Value stream analytics measures each stage from its start event to its end event.
Only items that have reached their end event are included in the stage time calculation.

By default, blocked issues are not included in the lifecycle overview.
However, you can use custom labels (for example `workflow::blocked`) to track them.

You can customize stages in value stream analytics based on pre-defined events.
To help you with the configuration, GitLab provides a pre-defined list of stages that you can use as a template.
For example, you can define a stage that starts when you add a label to an issue,
and ends when you add another label.

The following table gives an overview of the pre-defined stages in value stream analytics.

| Stage   | Measurement method   |
| ------- | -------------------- |
| Issue     | The median time between creating an issue and taking action to solve it, by either labeling it or adding it to a milestone, whichever comes first. The label is tracked only if it already has an [issue board list](../../project/issue_board.md) created for it. |
| Plan      | The median time between the action you took for the previous stage, and pushing the first commit to the branch. The first commit on the branch triggers the separation between **Plan** and **Code**. At least one of the commits in the branch must contain the related issue number (for example, `#42`). If none of the commits in the branch mention the related issue number, it is not considered in the measurement time of the stage. |
| Code      | The median time between pushing a first commit (previous stage) and creating a merge request (MR) related to that commit. The key to keep the process tracked is to include the [issue closing pattern](../../project/issues/managing_issues.md#default-closing-pattern) in the description of the merge request. For example, `Closes #xxx`, where `xxx` is the number of the issue related to this merge request. If the closing pattern is not present, then the calculation uses the creation time of the first commit in the merge request as the start time. |
| Test      | The median time to run the entire pipeline for that project. It's related to the time GitLab CI/CD takes to run every job for the commits pushed to that merge request. It is basically the start->finish time for all pipelines. |
| Review    | The median time taken to review a merge request that has a closing issue pattern, between its creation and until it's merged. |
| Staging   | The median time between merging a merge request that has a closing issue pattern until the very first deployment to a [production environment](#how-value-stream-analytics-identifies-the-production-environment). If there isn't a production environment, this is not tracked. |

NOTE:
Value stream analytics works on timestamp data and aggregates only the final start and stop events of the stage. For items that move back and forth between stages multiple times, the stage time is calculated solely from the final events' timestamps.

For information about how value stream analytics calculates each stage, see the [Value stream analytics development guide](../../../development/value_stream_analytics.md).

#### Example workflow

This example shows a workflow through all seven stages in one day.

If a stage does not include a start and a stop time, its data is not included in the median time.
In this example, milestones have been created and CI/CD for testing and setting environments is configured.

- 09:00: Create issue. **Issue** stage starts.
- 11:00: Add issue to a milestone (or backlog), start work on the issue, and create a branch locally.
  **Issue** stage stops and **Plan** stage starts.
- 12:00: Make the first commit.
- 12:30: Make the second commit to the branch that mentions the issue number.
  **Plan** stage stops and **Code** stage starts.
- 14:00: Push branch and create a merge request that contains the
  [issue closing pattern](../../project/issues/managing_issues.md#closing-issues-automatically).
  **Code** stage stops and **Test** and **Review** stages start.
- GitLab CI/CD takes 5 minutes to run scripts defined in the [`.gitlab-ci.yml` file](../../../ci/yaml/_index.md).
- 19:00: Merge the merge request. **Review** stage stops and **Staging** stage starts.
- 19:30: Deployment to the `production` environment finishes. **Staging** stops.

Value stream analytics records the following times for each stage:

- **Issue**: 09:00 to 11:00: 2 hrs
- **Plan**: 11:00 to 12:00: 1 hr
- **Code**: 12:00 to 14:00: 2 hrs
- **Test**: 5 minutes
- **Review**: 14:00 to 19:00: 5 hrs
- **Staging**: 19:00 to 19:30: 30 minutes

Keep in mind the following observations related to this example:

- This example demonstrates that it doesn't matter if your first
  commit doesn't mention the issue number, you can do this later in any commit
  on the branch you are working on.
- The **Test** stage is used in the calculation for the overall time of
  the cycle. It is included in the **Review** process, as every MR should be
  tested.
- This example illustrates only **one cycle** of the seven stages. The value stream analytics dashboard
  shows the median time for multiple cycles.

#### Cumulative label event duration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/432576) in GitLab 16.9 [with flags](../../../administration/feature_flags.md) named `enable_vsa_cumulative_label_duration_calculation` and `vsa_duration_from_db`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17476) in GitLab 16.10. Feature flag `vsa_duration_from_db` removed.
> - Feature flag `enable_vsa_cumulative_label_duration_calculation` [removed](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17478) in GitLab 17.0.

With this feature, value stream analytics measures the duration of repetitive events for label-based stages. You should configure label removal or addition events for both start and end events.

For example, a stage tracks when the `in progress` label is added and removed, with the following times:

- 9:00: label added.
- 10:00: label removed.
- 12:00: label added.
- 14:00 label removed.

With the original calculation method, the duration is five hours (from 9:00 to 14:00).
With cumulative label event duration calculation enabled, the duration is three hours (9:00 to 10:00 and 12:00 to 14:00).

NOTE:
When you upgrade your GitLab version to 16.10 (or to a higher version), existing label-based value stream analytics stages are automatically reaggregated using the background aggregation process.

##### Reaggregate data after upgrade

DETAILS:
**Offering:** GitLab Self-Managed

On large instances, when you upgrade the GitLab version and especially if several minor versions are skipped, the background aggregation processes might last longer. This delay can result in outdated data on the Value Stream Analytics page.
To speed up the aggregation process and avoid outdated data, in the [rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session) you can invoke the synchronous aggregation snippet for a given group:

```ruby
group = Group.find(-1) # put your group id here
group_to_aggregate = group.root_ancestor

loop do
  cursor = {}
  context = Analytics::CycleAnalytics::AggregationContext.new(cursor: cursor)
  service_response = Analytics::CycleAnalytics::DataLoaderService.new(group: group_to_aggregate, model: Issue, context: context).execute

  if service_response.success? && service_response.payload[:reason] == :limit_reached
    cursor = service_response.payload[:context].cursor
  elsif service_response.success?
    puts "finished"
    break
  else
    puts "failed"
    break
  end
end

loop do
  cursor = {}
  context = Analytics::CycleAnalytics::AggregationContext.new(cursor: cursor)
  service_response = Analytics::CycleAnalytics::DataLoaderService.new(group: group_to_aggregate, model: MergeRequest, context: context).execute

  if service_response.success? && service_response.payload[:reason] == :limit_reached
    cursor = service_response.payload[:context].cursor
  elsif service_response.success?
    puts "finished"
    break
  else
    puts "failed"
    break
  end
end
```

### How value stream analytics identifies the production environment

Value stream analytics identifies [production environments](../../../ci/environments/_index.md#deployment-tier-of-environments) by looking for project
[environments](../../../ci/yaml/_index.md#environment) with a name matching any of these patterns:

- `prod` or `prod/*`
- `production` or `production/*`

These patterns are not case-sensitive.

You can change the name of a project environment in your GitLab CI/CD configuration.

## View value stream analytics

> - Predefined date ranges dropdown list [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/408656/) in GitLab 16.5 [with a flag](../../../administration/feature_flags.md) named `vsa_predefined_date_ranges`. Disabled by default.
> - Predefined date ranges dropdown list [enabled on GitLab Self-Managed and GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/433149) in GitLab 16.7.
> - Predefined date ranges dropdown list [generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/438051) in GitLab 16.9. Feature flag `vsa_predefined_date_ranges` removed.

Prerequisites:

- You must have at least the Reporter role.
- You must create a [custom value stream](#create-a-value-stream). Value stream analytics only shows custom value streams created for your group or project.

To view value stream analytics for your group or project:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Value stream analytics**.
1. To view metrics for a particular stage, select a stage below the **Filter results** text box.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To view metrics in a particular date range, from the dropdown list select a predefined date range or the **Custom** option. With the **Custom** option selected:

      - In the **From** field, select a start date.
      - In the **To** field, select an end date.

      The charts and list display workflow items created during the date range.
1. Optional. Sort results by ascending or descending:
      - To sort by most recent or oldest workflow item, select the **Last event** header.
      - To sort by most or least amount of time spent in each stage, select the **Duration** header.

A badge next to the workflow items table header shows the number of workflow items that
completed during the selected stage.

The table shows a list of related workflow items for the selected stage. Based on the stage you select, this can be:

- Issues
- Merge requests

NOTE:
The end date for each predefined date range is the current day, and is included in the number of days selected. For example, the start date for `Last 30 days` is 29 days prior to the current day for a total of 30 days.

### Data filters

You can filter value stream analytics to view data that matches specific criteria. The following filters are supported:

- Date range
- Project
- Assignee
- Author
- Milestone
- Label

NOTE:
For the "Tasks by type" chart, only the Date range and Project selector filters are available. Labels and other filters are not applied, and you need to select labels separately from the dropdown list next to the chart.

## Value stream analytics metrics

The **Overview** page in value stream analytics displays key metrics of the DevSecOps lifecycle performance for projects and groups.

### Lifecycle metrics

Value stream analytics includes the following lifecycle metrics:

- **Lead time**: Median time from when the issue was created to when it was closed.
- **Cycle time**: Median time from first commit to issue closed. GitLab measures cycle time from the earliest commit of a
  [linked issue's merge request](../../project/issues/crosslinking_issues.md#from-commit-messages) to when that issue is closed.
  The cycle time approach underestimates the lead time because merge request creation is always later than commit time.
- **New issues**: Number of new issues created.
- **Deploys**: Total number of deployments to production.

### DORA metrics

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/355304) time to restore service tile in GitLab 15.0.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/357071) change failure rate tile in GitLab 15.0.

Value stream analytics includes the following [DORA](../../analytics/dora_metrics.md) metrics:

- Deployment frequency
- Lead time for changes
- Time to restore service
- Change failure rate

DORA metrics are calculated based on data from the
[DORA API](../../../api/dora/metrics.md).

If you have a GitLab Premium or Ultimate subscription:

- The number of successful deployments is calculated with DORA data.
- The data is filtered based on environment and environment tier.

## View lifecycle and DORA metrics

Prerequisites:

- To view deployment metrics, you must have a
  [production environment configured](#how-value-stream-analytics-identifies-the-production-environment).

To view lifecycle metrics:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Value stream analytics**.
   Lifecycle metrics display below the **Filter results** text box.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
      Based on the filter you select, the dashboard automatically aggregates lifecycle metrics and displays the status of the value stream.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.

To view the [Value Streams Dashboard](../../analytics/value_streams_dashboard.md) and [DORA metrics](../../analytics/dora_metrics.md):

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Value stream analytics**.
1. Below the **Filter results** text box, in the **Lifecycle metrics** row, select **Value Streams Dashboard / DORA**.
1. Optional. To open the new page, append this path `/analytics/dashboards/value_streams_dashboard` to the group URL
   (for example, `https://gitlab.com/groups/gitlab-org/-/analytics/dashboards/value_streams_dashboard`).

## View metrics for each development stage

Value stream analytics shows the median time spent by issues or merge requests in each development stage.

To view the median time spent in each stage by a group:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Value stream analytics**.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.
1. To view the metrics for each stage, above the **Filter results** text box, hover over a stage.

NOTE:
The date range selector filters items by the event time. The event time is when the
selected stage finished for the given item.

## View tasks by type

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The **Tasks by type** chart displays the cumulative number of issues and merge requests per day for your group.

The chart uses the global page filters to display data based on the selected
group and time frame.

To view tasks by type:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Analyze > Value stream analytics**.
1. Below the **Filter results** text box, select **Overview**. The **Tasks by type** chart displays below the **Total time** chart.
1. To switch between the task type, select the **Settings** (**{settings}**) dropdown list
   and select **Issues** or **Merge Requests**.
1. To add or remove labels, select the **Settings** (**{settings}**) dropdown list
   and select or search for a label. By default the top group-level labels (maximum 10) are selected. You can select a maximum of 15 labels.

## Create a value stream

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - **New value stream** [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/381002) from a dialog to a page in GitLab 16.10 [with a flag](../../../administration/feature_flags.md) named `vsa_standalone_settings_page`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171856) in GitLab 17.7. Feature flag `vsa_standalone_settings_page` removed.

### Create a value stream with GitLab default stages

When you create a value stream, you can use GitLab default stages and hide or re-order them. You can also
create custom stages in addition to those provided in the default template.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Value Stream analytics**.
1. Select **New Value Stream**.
1. Enter a name for the value stream.
1. Select **Create from default template**.
1. Customize the default stages:
   - To re-order stages, select the up or down arrows.
   - To hide a stage, select **Hide** (**{eye-slash}**).
1. To add a custom stage, select **Add a stage**.
   - Enter a name for the stage.
   - Select a **Start event** and a **Stop event**.
1. Select **New value stream**.

NOTE:
If you have recently upgraded to GitLab Premium, it can take up to 30 minutes for data to collect and display.

### Create a value stream with custom stages

When you create a value stream, you can create and add custom stages that align with your own development workflows.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Value Stream analytics**.
1. Select **New value stream**.
1. For each stage:
   - Enter a name for the stage.
   - Select a **Start event** and a **Stop event**.
1. To add another stage, select **Add a stage**.
1. To re-order the stages, select the up or down arrows.
1. Select **New value stream**.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a video explanation, see [Optimizing merge request review process with Value Stream Analytics](https://www.youtube.com/watch?v=kblpge6xeL8).
<!-- Video published on 2024-07-29 -->

#### Label-based stages for custom value streams

To measure complex workflows, you can use [scoped labels](../../project/labels.md#scoped-labels). For example, to measure deployment
time from a staging environment to production, you could use the following labels:

- When the code is deployed to staging, the `workflow::staging` label is added to the merge request.
- When the code is deployed to production, the `workflow::production` label is added to the merge request.

![Label-based value stream analytics stage](img/vsa_label_based_stage_v14_0.png "Creating a label-based value stream analytics stage")

##### Automatic data labeling with webhooks

You can automatically add labels by using [GitLab webhook events](../../project/integrations/webhook_events.md),
so that a label is applied to merge requests or issues when a specific event occurs.
Then, you can add label-based stages to track your workflow.
To learn more about the implementation, see the blog post [Applying GitLab Labels Automatically](https://about.gitlab.com/blog/2016/08/19/applying-gitlab-labels-automatically/).

#### Example for custom value stream configuration

![Example configuration](img/object_hierarchy_v14_10.png "Example custom value stream configuration")

In the example above, two independent value streams are set up for two teams that are using different development workflows in the **Test Group** (top-level namespace).

The first value stream uses standard timestamp-based events for defining the stages. The second value stream uses label events.

## Edit a value stream

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - **Edit value stream** [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/381002) from a dialog to a page in GitLab 16.10 [with a flag](../../../administration/feature_flags.md) named `vsa_standalone_settings_page`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171856) in GitLab 17.7. Feature flag `vsa_standalone_settings_page` removed.

After you create a value stream, you can customize it to suit your purposes. To edit a value stream:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Value stream analytics**.
1. From the value stream dropdown list, select the value stream you want to edit.
1. Next to the value stream dropdown list, select **Edit**.
1. Optional:
   - Rename the value stream.
   - Hide or re-order default stages.
   - Remove existing custom stages.
   - To add new stages, select **Add a stage**.
   - Select the start and end events for the stage.
1. Optional. To undo any modifications, select **Restore value stream defaults**.
1. Select **Save Value Stream**.

## Delete a value stream

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To delete a custom value stream:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Value stream analytics**.
1. From the value stream dropdown list, select the value stream you want to delete, then **Delete (name of value stream)**.
1. To confirm, select **Delete**.

## View number of days for a cycle to complete

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The **Total time chart** shows the average number of days it takes for development cycles to complete.
The chart shows data for the last 500 workflow items.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Analyze > Value stream analytics**.
1. Above the **Filter results** box, select a stage:
   - To view a summary of the cycle time for all stages, select **Overview**.
   - To view the cycle time for specific stage, select a stage.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.

## Access permissions for value stream analytics

Access permissions for value stream analytics depend on the project type.

| Project type | Permissions                                       |
|--------------|---------------------------------------------------|
| Public       | Anyone can access.                                |
| Internal     | Any authenticated user can access.                |
| Private      | Any user with at least the Guest role can access. |

## Value Stream Analytics GraphQL API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Loading stage metrics through GraphQL [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/410327) in GitLab 17.0.

With the VSA GraphQL API, you can request metrics from your configured value streams and value stream stages. This can be useful if you want to export VSA data to an external system or for a report.

The following metrics are available:

- Number of completed items in the stage. The count is limited to a maximum of 10,000 items.
- Median duration for the completed items in the stage.
- Average duration for the completed items in the stage.

### Request the metrics

Prerequisites:

- You must have at least the Reporter role.

First, you must determine which value stream you want to use in the reporting.

To request the configured value streams for a group, run:

```graphql
group(fullPath: "your-group-path") {
  valueStreams {
    nodes {
      id
      name
    }
  }
}
```

Similarly, to request metrics for a project, run:

```graphl
project(fullPath: "your-group-path") {
  valueStreams {
    nodes {
      id
      name
    }
  }
}
```

To request metrics for stages of a value stream, run:

```graphql
group(fullPath: "your-group-path") {
  valueStreams(id: "your-value-stream-id") {
    nodes {
      stages {
        id
        name
      }
    }
  }
}
```

Depending how you want to consume the data, you can request metrics for one specific stage or all stages in your value stream.

NOTE:
Requesting metrics for all stages might be too slow for some installations.
The recommended approach is to request metrics stage by stage.

Requesting metrics for the stage:

```graphql
group(fullPath: "your-group-path") {
  valueStreams(id: "your-value-stream-id") {
    nodes {
      stages(id: "your-stage-id") {
        id
        name
        metrics(timeframe: { start: "2024-03-01", end: "2024-03-31" }) {
          average {
            value
            unit
          }
          median {
            value
            unit
          }
          count {
            value
            unit
          }
        }
      }
    }
  }
}
```

NOTE:
You should always request metrics with a given time frame.
The longest supported time frame is 180 days.

The `metrics` node supports additional filtering options:

- Assignee usernames
- Author username
- Label names
- Milestone title

Example request with filters:

```graphql
group(fullPath: "your-group-path") {
  valueStreams(id: "your-value-stream-id") {
    nodes {
      stages(id: "your-stage-id") {
        id
        name
        metrics(
          labelNames: ["backend"],
          milestoneTitle: "17.0",
          timeframe: { start: "2024-03-01", end: "2024-03-31" }
        ) {
          average {
            value
            unit
          }
          median {
            value
            unit
          }
          count {
            value
            unit
          }
        }
      }
    }
  }
}
```

### Best practices

- To get an accurate view of the current status, request metrics as close to the end of the time frame as possible.
- For periodic reporting, you can create a script and use the [scheduled pipelines](../../../ci/pipelines/schedules.md) feature to export the data in a timely manner.
- When invoking the API, you get the current data from the database. Over time, the same metrics might change due to changes in the underlying data in the database. For example, moving or removing a project from the group might affect group-level metrics.
- Re-requesting the metrics for previous periods and comparing them to the previously collected metrics can show skews in the data, which can help in discovering and explaining changing trends.

## Forecast deployment frequency with Value Stream Forecasting

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10228) in GitLab 16.2 as an [experiment](../../../policy/development_stages_support.md#experiment).

Improve your planning and decision-making by predicting productivity metrics and
identifying anomalies across your software development lifecycle.

Prerequisites:

- You must belong to at least one group with the [experiment and beta features setting](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features) enabled.
- You must have permission to view the CI/CD analytics.

To view a forecast of deployment frequency in CI/CD Analytics:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > CI/CD analytics**.
1. Select the **Deployment frequency** tab.
1. Turn on the **Show forecast** toggle.
1. On the confirmation dialog, select **Accept testing terms**.

The forecast is displayed as a dotted line on the chart. Data is forecasted for
a duration that is half of the selected date range.

For example, if you select a 30-day range, a forecast for the following 15 days
is displayed.

![Forecast deployment frequency](img/forecast_deployment_frequency_v16_5.png)

Provide feedback on this experimental feature in [issue 416833](https://gitlab.com/gitlab-org/gitlab/-/issues/416833).

## Troubleshooting

### 100% CPU utilization by Sidekiq `cronjob:analytics_cycle_analytics`

It is possible that value stream analytics background jobs
strongly impact performance by monopolizing CPU resources.

To recover from this situation:

1. Disable the feature for all projects in [the Rails console](../../../administration/operations/rails_console.md),
   and remove existing jobs:

   ```ruby
   Project.find_each do |p|
     p.analytics_access_level='disabled';
     p.save!
   end

   Analytics::CycleAnalytics::GroupStage.delete_all
   Analytics::CycleAnalytics::Aggregation.delete_all
   ```

1. Configure a [Sidekiq routing](../../../administration/sidekiq/processing_specific_job_classes.md)
   with for example a single `feature_category=value_stream_management`
   and multiple `feature_category!=value_stream_management` entries.
   Find other relevant queue metadata in the
   [Enterprise Edition list](../../../administration/sidekiq/processing_specific_job_classes.md#list-of-available-job-classes).
1. Enable value stream analytics for one project after another.
   You might need to tweak the Sidekiq routing further according to your performance requirements.
