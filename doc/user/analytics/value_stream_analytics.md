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

A **value stream** is the entire work process that delivers value to customers. For example,
the [DevOps lifecycle](https://about.gitlab.com/stages-devops-lifecycle/) is a value stream that starts
with the Manage stage and ends with the Protect stage.

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

## View number of successful deployments **(FREE)**

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

## How value stream analytics measures each stage

Value stream analytics uses start and end events to measure the time that an issue or merge request
spends in each stage.

For example, a stage might start when a user adds a label to an issue, and ends when they add another label.
Items aren't included in the stage time calculation if they have not reached the end event.

| Stage   | Measurement method   |
|---------|----------------------|
| Issue   | The median time between creating an issue and taking action to solve it, by either labeling it or adding it to a milestone. The label is tracked only if it already includes an [issue board list](../project/issue_board.md) that has been created for the label. |
| Plan    | The median time between the action you took for the previous stage, and when you push the first commit to the branch. The first branch commit triggers the transition from **Plan** to **Code**, and at least one of the commits in the branch must include the related issue number (such as `#42`). If the issue number is not included in a commit, that data is not included in the measurement time of the stage. |
| Code    | The median time between pushing a first commit (previous stage) and creating a merge request. The process is tracked with the [issue closing pattern](../project/issues/managing_issues.md#closing-issues-automatically) in the description of the merge request. For example, if the issue is closed with `Closes #xxx`, `xxx` is the issue number for the merge request. If there is no closing pattern, the start time is set to the create time of the first commit. |
| Test    | The time from start to finish for all pipelines. Measures the median time to run the entire pipeline for that project. Related to the time required by GitLab CI/CD to run every job for the commits pushed to that merge request, as defined in the previous stage. |
| Review  | The median time taken to review merge requests with a closing issue pattern, from creation to merge. |
| Staging | The median time between merging the merge request (with a closing issue pattern) to the first deployment to a [production environment](../../ci/environments/index.md#deployment-tier-of-environments). Data is not collected without a production environment. |

## Example workflow

This example shows a workflow through all seven stages in one day. In this
example, milestones have been created and CI for testing and setting environments is configured.

- 09:00: Create issue. **Issue** stage starts.
- 11:00: Add issue to a milestone, start work on the issue, and create a branch locally.
**Issue** stage stops and **Plan** stage starts.
- 12:00: Make the first commit.
- 12:30: Make the second commit to the branch that mentions the issue number. **Plan** stage stops and **Code** stage starts.
- 14:00: Push branch and create a merge request that contains the [issue closing pattern](../project/issues/managing_issues.md#closing-issues-automatically). **Code** stage stops and **Test** and **Review** stages start.
- The CI takes 5 minutes to run scripts defined in [`.gitlab-ci.yml`](../../ci/yaml/index.md).
**Test** stage stops.
- Review merge request.
- 19:00: Merge the merge request. **Review** stage stops and **Staging** stage starts.
- 19:30: Deployment to the `production` environment starts and finishes. **Staging** stops.

Value stream analytics records the following times for each stage:

- **Issue**: 09:00 to 11:00: 2 hrs
- **Plan**: 11:00 to 12:00: 1 hr
- **Code**: 12:00 to 14:00: 2 hrs
- **Test**: 5 minutes
- **Review**: 14:00 to 19:00: 5 hrs
- **Staging**: 19:00 to 19:30: 30 minutes

Keep in mind the following observations related to this example:

- Although this example specifies the issue number in a later commit, the process
still collects analytics data for the issue.
- The time required in the **Test** stage is included in the **Review** process,
as every merge request should be tested.
- This example illustrates only one cycle of multiple stages. The value
stream analytics dashboard shows the calculated median elapsed time for these issues.
- Value stream analytics identifies production environments based on the
[deployment tier of environments](../../ci/environments/index.md#deployment-tier-of-environments).
