---
type: reference
stage: Manage
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Value Stream Analytics **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/196455) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.9 at the group level.

Value Stream Analytics measures the time spent to go from an
[idea to production](https://about.gitlab.com/blog/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/#from-idea-to-production-with-gitlab)
(also known as cycle time) for each of your projects or groups. Value Stream Analytics displays the median time
spent in each stage defined in the process.

Value Stream Analytics can help you quickly dtermine the velocity of a given
group. It points to bottlenecks in the development process, enabling management
to uncover, triage, and identify the root cause of slowdowns in the software development life cycle.

For information on how to contribute to the development of Value Stream Analytics, see our [contributor documentation](../../../development/value_stream_analytics.md).

Group-level Value Stream Analytics is available via **Group > Analytics > Value Stream**.

Note: [Project-level Value Stream Analytics](../../analytics/value_stream_analytics.md) is also available.

## Default stages

The stages tracked by Value Stream Analytics by default represent the [GitLab flow](../../../topics/gitlab_flow.md). These stages can be customized in Group Level Value Stream Analytics.

- **Issue** (Tracker)
  - Time to schedule an issue (by milestone or by adding it to an issue board)
- **Plan** (Board)
  - Time to first commit
- **Code** (IDE)
  - Time to create a merge request
- **Test** (CI)
  - Time it takes GitLab CI/CD to test your code
- **Review** (Merge Request/MR)
  - Time spent on code review
- **Staging** (Continuous Deployment)
  - Time between merging and deploying to production

## Filter the analytics data

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13216) in GitLab 13.3

GitLab provides the ability to filter analytics based on the following parameters:

- Milestones (Group level)
- Labels (Group level)
- Author
- Assignees

To filter results:

1. Select a group.
1. Click on the filter bar.
1. Select a parameter to filter by.
1. Select a value from the autocompleted results, or type to refine the results.

![Value stream analytics filter bar](img/vsa_filter_bar_v13.3.png "Active filter bar for value stream analytics")

### Date ranges

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13216) in GitLab 12.4.

GitLab provides the ability to filter analytics based on a date range. To filter results:

1. Select a group.
1. Optionally select a project.
1. Select a date range using the available date pickers.

## How Time metrics are measured

The "Time" metrics near the top of the page are measured as follows:

- **Lead time**: median time from issue created to issue closed.
- **Cycle time**: median time from first commit to issue closed.

A commit is associated with an issue by [crosslinking](../../project/issues/crosslinking_issues.md) in the commit message or by manually linking the merge request containing the commit.

![Value stream analytics time metrics](img/vsa_time_metrics_v13_0.png "Time metrics for value stream analytics")

## How the stages are measured

Value Stream Analytics records stage time and data based on the project issues with the
exception of the staging stage, where only data deployed to
production are measured.

Specifically, if your CI is not set up and you have not defined a [production environment](#how-the-production-environment-is-identified), then you will not have any
data for this stage.

Each stage of Value Stream Analytics is further described in the table below.

| **Stage** | **Description** |
| --------- | --------------- |
| Issue     | Measures the median time between creating an issue and taking action to solve it, by either labeling it or adding it to a milestone, whatever comes first. The label will be tracked only if it already has an [Issue Board list](../../project/issue_board.md) created for it. |
| Plan      | Measures the median time between the action you took for the previous stage, and pushing the first commit to the branch. The very first commit of the branch is the one that triggers the separation between **Plan** and **Code**, and at least one of the commits in the branch needs to contain the related issue number (e.g., `#42`). If none of the commits in the branch mention the related issue number, it is not considered to the measurement time of the stage. |
| Code      | Measures the median time between pushing a first commit (previous stage) and creating a merge request (MR) related to that commit. The key to keep the process tracked is to include the [issue closing pattern](../../project/issues/managing_issues.md#closing-issues-automatically) to the description of the merge request (for example, `Closes #xxx`, where `xxx` is the number of the issue related to this merge request). If the closing pattern is not present, then the calculation takes the creation time of the first commit in the merge request as the start time. |
| Test      | Measures the median time to run the entire pipeline for that project. It's related to the time GitLab CI/CD takes to run every job for the commits pushed to that merge request defined in the previous stage. It is basically the start->finish time for all pipelines. |
| Review    | Measures the median time taken to review the merge request that has a closing issue pattern, between its creation and until it's merged. |
| Staging   | Measures the median time between merging the merge request with a closing issue pattern until the very first deployment to a [production environment](#how-the-production-environment-is-identified). If there isn't a production environment, this is not tracked. |

How this works, behind the scenes:

1. Issues and merge requests are grouped together in pairs, such that for each
   `<issue, merge request>` pair, the merge request has the [issue closing pattern](../../project/issues/managing_issues.md#closing-issues-automatically)
   for the corresponding issue. All other issues and merge requests are **not**
   considered.
1. Then the `<issue, merge request>` pairs are filtered out by last XX days (specified
   by the UI - default is 90 days). So it prohibits these pairs from being considered.
1. For the remaining `<issue, merge request>` pairs, we check the information that
   we need for the stages, like issue creation date, merge request merge time,
   etc.

To sum up, anything that doesn't follow [GitLab flow](../../../topics/gitlab_flow.md) will not be tracked and the
Value Stream Analytics dashboard will not present any data for:

- Merge requests that do not close an issue.
- Issues not labeled with a label present in the Issue Board or for issues not assigned a milestone.
- Staging stage, if the project has no [production environment](#how-the-production-environment-is-identified).

## How the production environment is identified

Value Stream Analytics identifies production environments by looking for project [environments](../../../ci/yaml/README.md#environment) with a name matching any of these patterns:

- `prod` or `prod/*`
- `production` or `production/*`

These patterns are not case-sensitive.

You can change the name of a project environment in your GitLab CI/CD configuration.

## Example workflow

Below is a simple fictional workflow of a single cycle that happens in a
single day through all noted stages. Note that if a stage does not include a start
and a stop time, its data is not included in the median time. It is assumed that
milestones are created and a CI for testing and setting environments is configured.
a start and a stop mark, it is not measured and hence not calculated in the median
time. It is assumed that milestones are created and CI for testing and setting
environments is configured.

1. Issue is created at 09:00 (start of **Issue** stage).
1. Issue is added to a milestone at 11:00 (stop of **Issue** stage / start of
   **Plan** stage).
1. Start working on the issue, create a branch locally and make one commit at
   12:00.
1. Make a second commit to the branch which mentions the issue number at 12.30
   (stop of **Plan** stage / start of **Code** stage).
1. Push branch and create a merge request that contains the [issue closing pattern](../../project/issues/managing_issues.md#closing-issues-automatically)
   in its description at 14:00 (stop of **Code** stage / start of **Test** and
   **Review** stages).
1. The CI starts running your scripts defined in [`.gitlab-ci.yml`](../../../ci/yaml/README.md) and
   takes 5min (stop of **Test** stage).
1. Review merge request, ensure that everything is OK and merge the merge
   request at 19:00. (stop of **Review** stage / start of **Staging** stage).
1. Now that the merge request is merged, a deployment to the `production`
   environment starts and finishes at 19:30 (stop of **Staging** stage).

From the above example you can conclude the time it took each stage to complete
as long as their total time:

- **Issue**: 2h (11:00 - 09:00)
- **Plan**: 1h (12:00 - 11:00)
- **Code**: 2h (14:00 - 12:00)
- **Test**: 5min
- **Review**: 5h (19:00 - 14:00)
- **Staging**: 30min (19:30 - 19:00)

A few notes:

- In the above example we demonstrated that it doesn't matter if your first
  commit doesn't mention the issue number, you can do this later in any commit
  of the branch you are working on.
- You can see that the **Test** stage is not calculated to the overall time of
  the cycle since it is included in the **Review** process (every MR should be
  tested).
- The example above was just **one cycle** of the seven stages. Add multiple
  cycles, calculate their median time and the result is what the dashboard of
  Value Stream Analytics is showing.

## Customizable Stages

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12196) in GitLab 12.9.

The default stages are designed to work straight out of the box, but they might not be suitable for
all teams. Different teams use different approaches to building software, so some teams might want
to customize their Value Stream Analytics.

GitLab allows users to create multiple value streams, hide default stages and create custom stages that align better to their development workflow.

### Stage path

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/210315) in GitLab 13.0.

Stages are visually depicted as a horizontal process flow. Selecting a stage will update the
the content below the value stream.

This is disabled by default. If you have a self-managed instance, an
administrator can [open a Rails console](../../../administration/troubleshooting/navigating_gitlab_via_rails_console.md)
and enable it with the following command:

```ruby
Feature.enable(:value_stream_analytics_path_navigation)
```

### Adding a stage

In the following example we're creating a new stage that measures and tracks issues from creation
time until they are closed.

1. Navigate to your group's **Analytics > Value Stream**.
1. Click the **Add a stage** button.
1. Fill in the new stage form:
   - Name: Issue start to finish.
   - Start event: Issue created.
   - End event: Issue closed.
1. Click the **Add stage** button.

![New Value Stream Analytics Stage](img/new_vsm_stage_v12_9.png "Form for creating a new stage")

The new stage is persisted and it will always show up on the Value Stream Analytics page for your
group.

If you want to alter or delete the stage, you can easily do that for customized stages by:

1. Hovering over the stage.
1. Clicking the vertical ellipsis (**{ellipsis_v}**) button that appears.

![Value Stream Analytics Stages](img/vsm_stage_list_v12_9.png)

Creating a custom stage requires specifying two events:

- A start.
- An end.

Be careful to choose a start event that occurs *before* your end event. For example, consider a
stage that:

- Started when an issue is added to a board.
- Ended when the issue is created.

This stage would not work because the end event has already happened when the start event occurs.
To prevent such invalid stages, the UI prohibits incompatible start and end events. After you select
the start event, the stop event dropdown will only list the compatible events.

### Re-ordering stages

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/196698) in GitLab 12.10.

Once a custom stage has been added, you can "drag and drop" stages to rearrange their order. These changes are automatically saved to the system.

### Label based stages

The pre-defined start and end events can cover many use cases involving both issues and merge requests.

For supporting more complex workflows, use stages based on group labels. These events are based on
labels being added or removed. In particular, [scoped labels](../../project/labels.md#scoped-labels)
are useful for complex workflows.

In this example, we'd like to measure more accurate code review times. The workflow is the following:

- When the code review starts, the reviewer adds `workflow::code_review_start` label to the merge request.
- When the code review is finished, the reviewer adds `workflow::code_review_complete` label to the merge request.

Creating a new stage called "Code Review":

![New Label Based Value Stream Analytics Stage](img/label_based_stage_vsm_v12_9.png "Creating a label based Value Stream Analytics Stage")

### Hiding unused stages

Sometimes certain default stages are not relevant to a team. In this case, you can easily hide stages
so they no longer appear in the list. To hide stages:

1. Add a custom stage to activate customizability.
1. Hover over the default stage you want to hide.
1. Click the vertical ellipsis (**{ellipsis_v}**) button that appears and select **Hide stage**.

To recover a default stage that was previously hidden:

1. Click **Add a stage** button.
1. In the top right corner open the **Recover hidden stage** dropdown.
1. Select a stage.

### Creating a value stream

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/221202) in GitLab 13.3

A default value stream is readily available for each group. You can create additional value streams based on the different areas of work that you would like to measure.

Once created, a new value stream includes the [seven stages](#default-stages) that follow
[GitLab workflow](../../../topics/gitlab_flow.md)
best practices. You can customize this flow by adding, hiding or re-ordering stages.

To create a value stream:

1. Navigate to your group's **Analytics > Value Stream**.
1. Click the Value stream dropdown and select **Create new Value Stream**
1. Fill in a name for the new Value Stream
1. Click the **Create Value Stream** button.

![New value stream](img/new_value_stream_v13_3.png "Creating a new value stream")

### Deleting a value stream

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/221205) in GitLab 13.4.

To delete a custom value stream:

1. Navigate to your group's **Analytics > Value Stream**.
1. Click the Value stream dropdown and select the value stream you would like to delete.
1. Click the **Delete (name of value stream)**.
1. Click the **Delete** button to confirm.

![Delete value stream](img/delete_value_stream_v13.4.png "Deleting a custom value stream")

### Disabling custom value streams

Custom value streams are enabled by default. If you have a self-managed instance, an
administrator can open a Rails console and disable them with the following command:

```ruby
Feature.disable(:value_stream_analytics_create_multiple_value_streams)
```

## Days to completion chart

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/21631) in GitLab 12.6.
> - [Chart median line removed](https://gitlab.com/gitlab-org/gitlab/-/issues/235455) in GitLab 13.4.

This chart visually depicts the total number of days it takes for cycles to be completed. (Totals are being replaced with averages in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/262070).)

This chart uses the global page filters for displaying data based on the selected
group, projects, and timeframe. In addition, specific stages can be selected
from within the chart itself.

The chart data is limited to the last 500 items.

### Disabling chart

This chart is enabled by default. If you have a self-managed instance, an
administrator can open a Rails console and disable it with the following command:

```ruby
Feature.disable(:cycle_analytics_scatterplot_enabled)
```

## Type of work - Tasks by type chart

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32421) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.10.

This chart shows a cumulative count of issues and merge requests per day.

This chart uses the global page filters for displaying data based on the selected
group, projects, and timeframe. The chart defaults to showing counts for issues but can be
toggled to show data for merge requests and further refined for specific group-level labels.

By default the top group-level labels (max. 10) are pre-selected, with the ability to
select up to a total of 15 labels.

## Permissions

To access Group-level Value Stream Analytics, users must have Reporter access or above.

You can [read more about permissions](../../permissions.md) in general.

## More resources

Learn more about Value Stream Analytics in the following resources:

- [Value Stream Analytics feature page](https://about.gitlab.com/stages-devops-lifecycle/value-stream-analytics/).
- [Value Stream Analytics feature preview](https://about.gitlab.com/blog/2016/09/16/feature-preview-introducing-cycle-analytics/).
- [Value Stream Analytics feature highlight](https://about.gitlab.com/blog/2016/09/21/cycle-analytics-feature-highlight/).
