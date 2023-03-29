---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Value stream analytics for projects **(FREE)**

> - Introduced as cycle analytics prior to GitLab 12.3 at the project level.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12077) in GitLab Premium 12.3 at the group level.
> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/23427) from cycle analytics to value stream analytics in GitLab 12.8.

Value stream analytics provides metrics about each stage of your software development process.
For more information, see [How value stream analytics measures stages](../group/value_stream_analytics/index.md#how-value-stream-analytics-measures-stages).

A **value stream** is the entire work process that delivers value to customers. For example,
the [DevOps lifecycle](https://about.gitlab.com/stages-devops-lifecycle/) is a value stream that starts
with the Plan stage and ends with the Govern stage.

Use value stream analytics to identify:

- The amount of time it takes to go from an idea to production.
- The velocity of a given project.
- Bottlenecks in the development process.
- Factors that cause your software development lifecycle to slow down.

Value stream analytics is also available for [groups](../group/value_stream_analytics).

## View value stream analytics

> - Filtering [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/326701) in GitLab 14.3
> - Sorting [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/335974) in GitLab 14.4.

To view value stream analytics for your project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > Value stream**.
1. To view metrics for a particular stage, select a stage below the **Filter results** text box.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.
1. Optional. Sort results by ascending or descending:
      - To sort by most recent or oldest workflow item, select the **Last event** header.
      - To sort by most or least amount of time spent in each stage, select the **Duration** header.

The table shows a list of related workflow items for the selected stage. Based on the stage you choose, this can be:

- CI/CD jobs
- Issues
- Merge requests
- Pipelines

A badge next to the workflow items table header shows the number of workflow items that completed the selected stage.

## View time spent in each development stage

Value stream analytics shows the median time spent by issues or merge requests in each development stage.

To view the median time spent in each stage:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > Value stream**.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.
1. To view the median time for each stage, above the **Filter results** text box, point to a stage.

## View the lead time and cycle time for issues

Value stream analytics shows the lead time and cycle time for issues in your project:

- Lead time: Median time from when the issue was created to when it was closed.
- Cycle time: Median time from first commit to issue closed. GitLab measures cycle time from the earliest commit of a [linked issue's merge request](../project/issues/crosslinking_issues.md) to when that issue is closed. The cycle time approach underestimates the lead time because merge request creation is always later than commit time.

To view the lead time and cycle time for issues:

1. On the top bar, select **Main menu > Projects** and find your project.
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

To view the lead time for changes for merge requests in your project:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Analytics > Value stream**.
1. Optional. Filter the results:
   1. Select the **Filter results** text box.
   1. Select a parameter.
   1. Select a value or enter text to refine the results.
   1. To adjust the date range:
      - In the **From** field, select a start date.
      - In the **To** field, select an end date.

The **Lead Time for Changes** metrics display below the **Filter results** text box.

## View number of successful deployments

Prerequisites:

- To view deployment metrics, you must have a
[production environment configured](../../ci/environments/index.md#deployment-tier-of-environments).

Value stream analytics shows the following deployment metrics for your project within the specified date range:

- Deploys: The number of successful deployments in the date range.
- Deployment Frequency: The average number of successful deployments per day in the date range.

If you have a GitLab Premium or Ultimate subscription:

- The number of successful deployments is calculated with DORA data.
- The data is filtered based on environment and environment tier.

To view deployment metrics for your project:

1. On the top bar, select **Main menu > Projects** and find your project.
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
[DORA API](../../api/dora/metrics.md#devops-research-and-assessment-dora-key-metrics-api).

NOTE:
In GitLab 13.9 and later, metrics are calculated based on when the deployment was finished.
In GitLab 13.8 and earlier, metrics are calculated based on when the deployment was created.

## Access permissions for value stream analytics

Access permissions for value stream analytics depend on the project type.

| Project type | Permissions                            |
|--------------|----------------------------------------|
| Public       | Anyone can access.                     |
| Internal     | Any authenticated user can access.     |
| Private      | Any member Guest and above can access. |

## Troubleshooting

### 100% CPU utilization by Sidekiq `cronjob:analytics_cycle_analytics`

It is possible that Value stream analytics background jobs
strongly impact performance by monopolizing CPU resources.

To recover from this situation:

1. Disable the feature for all projects in [the Rails console](../../administration/operations/rails_console.md),
   and remove existing jobs:

   ```ruby
   Project.find_each do |p|
     p.analytics_access_level='disabled';
     p.save!
   end

   Analytics::CycleAnalytics::GroupStage.delete_all
   Analytics::CycleAnalytics::Aggregation.delete_all
   ```

1. Configure a [Sidekiq routing](../../administration/sidekiq/processing_specific_job_classes.md)
   with for example a single `feature_category=value_stream_management`
   and multiple `feature_category!=value_stream_management` entries.
   Find other relevant queue metadata in the
   [Enterprise Edition list](../../administration/sidekiq/processing_specific_job_classes.md#list-of-available-job-classes).
1. Enable value stream analytics for one project after another.
   You might need to tweak the Sidekiq routing further according to your performance requirements.
