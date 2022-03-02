---
type: reference
stage: Manage
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Value stream analytics for groups **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/196455) in GitLab 12.9 for groups.

Value stream analytics provides metrics about each stage of your software development process.

Use value stream analytics to identify:

- The amount of time it takes to go from an idea to production.
- The velocity of a given project.
- Bottlenecks in the development process.
- Factors that cause your software development lifecycle to slow down.

Value stream analytics is also available for [projects](../../analytics/value_stream_analytics.md).

## View value stream analytics

> - Date range filter [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13216) in GitLab 12.4
> - Filtering [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13216) in GitLab 13.3
> - Horizontal stage path [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12196) in 13.0 and [feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/323982) in 13.12

You must have at least the Reporter role to view value stream analytics for groups.

To view value stream analytics for your group:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Value stream**.
1. To view metrics for each stage, above the **Filter results** text box, select a stage.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date. The charts and list show workflow items created
        during the date range.
1. Optional. Sort results by ascending or descending:
      - To sort by most recent or oldest workflow item, select the **Merge requests** or **Issues**
        header. The header name differs based on the stage you select.
      - To sort by most or least amount of time spent in each stage, select the **Time** header.

A badge next to the workflow items table header shows the number of workflow items that
completed during the selected stage.

The table shows a list of related workflow items for the selected stage. Based on the stage you select, this can be:

- CI/CD jobs
- Issues
- Merge requests
- Pipelines

## View metrics for each development stage

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/210315) in GitLab 13.0.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/323982) in GitLab 13.12.

Value stream analytics shows the median time spent by issues or merge requests in each development stage.

To view the median time spent in each stage by a group:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Value stream**.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.
1. To view the metrics for each stage, above the **Filter results** text box, hover over a stage.

## View the lead time and cycle time for issues

Value stream analytics shows the lead time and cycle time for issues in your groups:

- Lead time: Median time from when the issue was created to when it was closed.
- Cycle time: Median time from first commit to issue closed. Commits are associated with issues when users [cross-link them in the commit message](../../project/issues/crosslinking_issues.md#from-commit-messages).

To view the lead time and cycle time for issues:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Value stream**.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.

The **Lead Time** and **Cycle Time** metrics display below the **Filter results** text box.

## View lead time for changes for merge requests **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340150) in GitLab 14.5.

Lead time for changes is the median duration between when a merge request is merged and when it's deployed to production.

To view the lead time for changes for merge requests in your group:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Value stream**.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.

The **Lead Time for Changes** metrics display below the **Filter results** text box.

## View number of successful deployments **(PREMIUM)**

> DORA API-based deployment metrics for value stream analytics for groups were [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/337256) from GitLab Ultimate to GitLab Premium in 14.3.

To view deployment metrics, you must have a
[production environment configured](../../../ci/environments/index.md#deployment-tier-of-environments).

Value stream analytics shows the following deployment metrics for your group:  
 
- Deploys: The number of successful deployments in the date range.
- Deployment Frequency: The average number of successful deployments per day in the date range.

To view deployment metrics for your group:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Value stream**.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.

The **Deploys** and **Deployment Frequency** metrics display below the **Filter results** text box.

Deployment metrics are calculated based on data from the
[DORA API](../../../api/dora/metrics.md#devops-research-and-assessment-dora-key-metrics-api).

NOTE:
In GitLab 13.9 and later, metrics are calculated based on when the deployment was finished.
In GitLab 13.8 and earlier, metrics are calculated based on when the deployment was created.

## Upcoming date filter change

In the [epics](https://gitlab.com/groups/gitlab-org/-/epics/6046), we plan to alter
the date filter behavior to filter the end event time of the currently selected stage.

The change makes it possible to get a much better picture about the completed items within the
stage and helps uncover long-running items.

For example, an issue was created a year ago and the current stage was finished in the current month.
If you were to look at the metrics for the last three months, this issue would not be included in the calculation of
the stage metrics. With the new date filter, this item would be included.

DISCLAIMER:
This section contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

## How value stream analytics measures stages

Value stream analytics measures each stage from its start event to its end event.

For example, a stage might start when a user adds a label to an issue, and ends when they add another label.
Items aren't included in the stage time calculation if they have not reached the end event.

Each stage of value stream analytics is further described in the table below.

| Stage   | Measurement method   |
| ------- | -------------------- |
| Issue     | The median time between creating an issue and taking action to solve it, by either labeling it or adding it to a milestone, whichever comes first. The label is tracked only if it already has an [issue board list](../../project/issue_board.md) created for it. |
| Plan      | The median time between the action you took for the previous stage, and pushing the first commit to the branch. The first commit on the branch triggers the separation between **Plan** and **Code**. At least one of the commits in the branch must contain the related issue number (for example, `#42`). If none of the commits in the branch mention the related issue number, it is not considered in the measurement time of the stage. |
| Code      | The median time between pushing a first commit (previous stage) and creating a merge request (MR) related to that commit. The key to keep the process tracked is to include the [issue closing pattern](../../project/issues/managing_issues.md#default-closing-pattern) in the description of the merge request. For example, `Closes #xxx`, where `xxx` is the number of the issue related to this merge request. If the closing pattern is not present, then the calculation uses the creation time of the first commit in the merge request as the start time. |
| Test      | The median time to run the entire pipeline for that project. It's related to the time GitLab CI/CD takes to run every job for the commits pushed to that merge request. It is basically the start->finish time for all pipelines. |
| Review    | The median time taken to review a merge request that has a closing issue pattern, between its creation and until it's merged. |
| Staging   | The median time between merging a merge request that has a closing issue pattern until the very first deployment to a [production environment](#how-value-stream-analytics-identifies-the-production-environment). If there isn't a production environment, this is not tracked. |

## Example workflow

This example shows a workflow through all seven stages in one day. 

If a stage does not include a start and a stop time, its data is not included in the median time. 
In this example, milestones have been created and CI/CD for testing and setting environments is configured.

- 09:00: Create issue. **Issue** stage starts.
- 11:00: Add issue to a milestone, start work on the issue, and create a branch locally. 
  **Issue** stage stops and **Plan** stage starts. 
- 12:00: Make the first commit.
- 12:30: Make the second commit to the branch that mentions the issue number.
  **Plan** stage stops and **Code** stage starts.
- 14:00: Push branch and create a merge request that contains the 
  [issue closing pattern](../../project/issues/managing_issues.md#closing-issues-automatically). 
  **Code** stage stops and **Test** and **Review** stages start.
- GitLab CI/CD takes 5 minutes to run scripts defined in [`.gitlab-ci.yml`](../../../ci/yaml/index.md).
- 19:00: Merge the merge request. **Review** stage stops and **Staging** stage starts.
- 19:30: Deployment to the `production` environment finishes. **Staging** stops.

Value stream analytics records the following times for each stage:

- **Issue**: 09:00 to 11:00: 2 hrs
- **Plan**: 11:00 to 12:00: 1 hr
- **Code**: 12:00 to 14:00: 2 hrs
- **Test**: 5 minutes
- **Review**: 14:00 to 19:00: 5 hrs 
- **Staging**: 19:00 to 19:30: 30 minutes

There are some additional considerations for this example:

- This example demonstrates that it doesn't matter if your first
  commit doesn't mention the issue number, you can do this later in any commit
  on the branch you are working on.
- The **Test** stage is used in the calculation for the overall time of
  the cycle. It is included in the **Review** process, as every MR should be
  tested.
- This example illustrates only **one cycle** of the seven stages. The value stream analytics dashboard
  shows the median time for multiple cycles.

## How value stream analytics identifies the production environment

Value stream analytics identifies production environments by looking for project
[environments](../../../ci/yaml/index.md#environment) with a name matching any of these patterns:

- `prod` or `prod/*`
- `production` or `production/*`

These patterns are not case-sensitive.

You can change the name of a project environment in your GitLab CI/CD configuration.

## Custom value streams

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12196) in GitLab 12.9.

Use custom value streams to create custom stages that align with your own development processes,
and hide default stages. The dashboard depicts stages as a horizontal process
flow.

### Create a value stream

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/221202) in GitLab 13.3

A default value stream is readily available for each group. You can create additional value streams
based on the different areas of work that you would like to measure.

Once created, a new value stream includes the stages that follow
[GitLab workflow](../../../topics/gitlab_flow.md)
best practices. You can customize this flow by adding, hiding or re-ordering stages.

To create a value stream:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Value Stream**.
1. In the top right, select the dropdown list and then **Create new Value Stream**.
1. Enter a name for the new Value Stream.
   - You can [customize the stages](#create-a-value-stream-with-stages).
1. Select **Create Value Stream**.

![New value stream](img/new_value_stream_v13_12.png "Creating a new value stream")

### Create a value stream with stages

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50229) in GitLab 13.7.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55572) in GitLab 13.10.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/294190) in GitLab 13.11.

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

You can create value streams with stages, starting with a default or a blank template. You can
add stages as desired.

To create a value stream with stages:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Value Stream**.
1. In the top right, select the dropdown list and then **Create new Value Stream**.
1. Select either **Create from default template** or **Create from no template**.
   - You can hide or re-order default stages in the value stream.

     ![Default stage actions](img/vsa_default_stage_v13_10.png "Default stage actions")

   - You can add new stages by selecting **Add another stage**.
   - You can select the name and start and end events for the stage.

     ![Custom stage actions](img/vsa_custom_stage_v13_10.png "Custom stage actions")
1. Select **Create Value Stream**.

### Label-based stages

The pre-defined start and end events can cover many use cases involving both issues and merge requests.

In more complex workflows, use stages based on group labels. These events are based on
added or removed labels. In particular, [scoped labels](../../project/labels.md#scoped-labels)
are useful for complex workflows.

In this example, we'd like to measure times for deployment from a staging environment to production. The workflow is the following:

- When the code is deployed to staging, the `workflow::staging` label is added to the merge request.
- When the code is deployed to production, the `workflow::production` label is added to the merge request.

![Label-based value stream analytics stage](img/vsa_label_based_stage_v14_0.png "Creating a label-based value stream analytics stage")

### Edit a value stream

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267537) in GitLab 13.10.

After you create a value stream, you can customize it to suit your purposes. To edit a value stream:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Value Stream**.
1. In the top right, select the dropdown list and then select the relevant value stream.
1. Next to the value stream dropdown list, select **Edit**.
   The edit form is populated with the value stream details.
1. Optional:
    - Rename the value stream.
    - Hide or re-order default stages.
    - Remove existing custom stages.
    - Add new stages by selecting the 'Add another stage' button
    - Select the start and end events for the stage.
1. Optional. To undo any modifications, select **Restore value stream defaults**.
1. Select **Save Value Stream**.

### Delete a value stream

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/221205) in GitLab 13.4.

To delete a custom value stream:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Value Stream**.
1. In the top right, select the dropdown list and then select the value stream you would like to delete.
1. Select **Delete (name of value stream)**.
1. To confirm, select **Delete**.

![Delete value stream](img/delete_value_stream_v13_12.png "Deleting a custom value stream")

## View number of days for a cycle to complete

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21631) in GitLab 12.6.
> - Chart median line [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/235455) in GitLab 13.4.
> - Totals [replaced](https://gitlab.com/gitlab-org/gitlab/-/issues/262070) with averages in GitLab 13.12.

The **Total time chart** shows the average number of days it takes for development cycles to complete.
The chart shows data for the last 500 workflow items.

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Analytics > Value stream**.
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

## Type of work - Tasks by type chart

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32421) in GitLab 12.10.

This chart shows a cumulative count of issues and merge requests per day.

This chart uses the global page filters for displaying data based on the selected
group, projects, and time frame. The chart defaults to showing counts for issues but can be
toggled to show data for merge requests and further refined for specific group-level labels.

By default the top group-level labels (max. 10) are pre-selected, with the ability to
select up to a total of 15 labels.
