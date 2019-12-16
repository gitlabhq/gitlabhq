# Cycle Analytics

> - Introduced prior to GitLab 12.3 at the project level.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/12077) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.3 at the group level.

Cycle Analytics measures the time spent to go from an
[idea to production](https://about.gitlab.com/blog/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/#from-idea-to-production-with-gitlab)
(also known as cycle time) for each of your projects. Cycle Analytics displays the median time
spent in each stage defined in the process.

NOTE: **Note:**
Use the `cycle_analytics` feature flag to enable at the group level.

Cycle Analytics is useful in order to quickly determine the velocity of a given
project. It points to bottlenecks in the development process, enabling management
to uncover, triage, and identify the root cause of slowdowns in the software development life cycle.

Cycle Analytics is tightly coupled with the [GitLab flow](../../topics/gitlab_flow.md) and
calculates a separate median for each stage.

## Overview

Cycle Analytics is available:

- From GitLab 12.3, at the group level in the analytics workspace (top navigation bar) at
  **Analytics > Cycle Analytics**. **(PREMIUM)**

  In the future, multiple groups will be selectable which will effectively make this an
  instance-level feature.

- At the project level via **Project > Cycle Analytics**.

There are seven stages that are tracked as part of the Cycle Analytics calculations.

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
- **Production** (Total)
  - Total lifecycle time; i.e. the velocity of the project or team

## Date ranges

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/13216) in GitLab 12.4.

GitLab provides the ability to filter analytics based on a date range. To filter results:

1. Select a group.
1. Optionally select a project.
1. Select a date range using the available date pickers.

## How the data is measured

Cycle Analytics records cycle time and data based on the project issues with the
exception of the staging and production stages, where only data deployed to
production are measured.

Specifically, if your CI is not set up and you have not defined a `production`
or `production/*` [environment](../../ci/yaml/README.md#environment), then you will not have any
data for those stages.

Each stage of Cycle Analytics is further described in the table below.

| **Stage** | **Description** |
| --------- | --------------- |
| Issue     | Measures the median time between creating an issue and taking action to solve it, by either labeling it or adding it to a milestone, whatever comes first. The label will be tracked only if it already has an [Issue Board list](../project/issue_board.md#creating-a-new-list) created for it. |
| Plan      | Measures the median time between the action you took for the previous stage, and pushing the first commit to the branch. The very first commit of the branch is the one that triggers the separation between **Plan** and **Code**, and at least one of the commits in the branch needs to contain the related issue number (e.g., `#42`). If none of the commits in the branch mention the related issue number, it is not considered to the measurement time of the stage. |
| Code      | Measures the median time between pushing a first commit (previous stage) and creating a merge request (MR) related to that commit. The key to keep the process tracked is to include the [issue closing pattern](../project/issues/managing_issues.md#closing-issues-automatically) to the description of the merge request (for example, `Closes #xxx`, where `xxx` is the number of the issue related to this merge request). If the issue closing pattern is not present in the merge request description, the MR is not considered to the measurement time of the stage. |
| Test      | Measures the median time to run the entire pipeline for that project. It's related to the time GitLab CI takes to run every job for the commits pushed to that merge request defined in the previous stage. It is basically the start->finish time for all pipelines. |
| Review    | Measures the median time taken to review the merge request that has closing issue pattern, between its creation and until it's merged. |
| Staging   | Measures the median time between merging the merge request with closing issue pattern until the very first deployment to production. It's tracked by the environment set to `production` or matching `production/*` (case-sensitive, `Production` won't work) in your GitLab CI configuration. If there isn't a production environment, this is not tracked. |
| Production| The sum of all time (medians) taken to run the entire process, from issue creation to deploying the code to production. |

How this works, behind the scenes:

1. Issues and merge requests are grouped together in pairs, such that for each
   `<issue, merge request>` pair, the merge request has the [issue closing pattern](../project/issues/managing_issues.md#closing-issues-automatically)
   for the corresponding issue. All other issues and merge requests are **not**
   considered.
1. Then the `<issue, merge request>` pairs are filtered out by last XX days (specified
   by the UI - default is 90 days). So it prohibits these pairs from being considered.
1. For the remaining `<issue, merge request>` pairs, we check the information that
   we need for the stages, like issue creation date, merge request merge time,
   etc.

To sum up, anything that doesn't follow [GitLab flow](../../workflow/gitlab_flow.md) will not be tracked and the
Cycle Analytics dashboard will not present any data for:

- Merge requests that do not close an issue.
- Issues not labeled with a label present in the Issue Board or for issues not assigned a milestone.
- Staging and production stages, if the project has no `production` or `production/*`
  environment.

## Example workflow

Below is a simple fictional workflow of a single cycle that happens in a
single day passing through all seven stages. Note that if a stage does not have
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
1. Push branch and create a merge request that contains the [issue closing pattern](../project/issues/managing_issues.md#closing-issues-automatically)
   in its description at 14:00 (stop of **Code** stage / start of **Test** and
   **Review** stages).
1. The CI starts running your scripts defined in [`.gitlab-ci.yml`](../../ci/yaml/README.md) and
   takes 5min (stop of **Test** stage).
1. Review merge request, ensure that everything is OK and merge the merge
   request at 19:00. (stop of **Review** stage / start of **Staging** stage).
1. Now that the merge request is merged, a deployment to the `production`
   environment starts and finishes at 19:30 (stop of **Staging** stage).
1. The cycle completes and the sum of the median times of the previous stages
   is recorded to the **Production** stage. That is the time between creating an
   issue and deploying its relevant merge request to production.

From the above example you can conclude the time it took each stage to complete
as long as their total time:

- **Issue**:  2h (11:00 - 09:00)
- **Plan**:   1h (12:00 - 11:00)
- **Code**:   2h (14:00 - 12:00)
- **Test**:   5min
- **Review**: 5h (19:00 - 14:00)
- **Staging**:  30min (19:30 - 19:00)
- **Production**: Since this stage measures the sum of median time off all
  previous stages, we cannot calculate it if we don't know the status of the
  stages before. In case this is the very first cycle that is run in the project,
  then the **Production** time is 10h 30min (19:30 - 09:00)

A few notes:

- In the above example we demonstrated that it doesn't matter if your first
  commit doesn't mention the issue number, you can do this later in any commit
  of the branch you are working on.
- You can see that the **Test** stage is not calculated to the overall time of
  the cycle since it is included in the **Review** process (every MR should be
  tested).
- The example above was just **one cycle** of the seven stages. Add multiple
  cycles, calculate their median time and the result is what the dashboard of
  Cycle Analytics is showing.

## Days to completion chart

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/21631) in GitLab 12.6.

This chart visually depicts the total number of days it takes for cycles to be completed.

This chart uses the global page filters for displaying data based on the selected
group, projects, and timeframe. In addition, specific stages can be selected
from within the chart itself.

### Enabling chart

By default, this chart is disabled for self-managed instances. To enable it, ask an
administrator with Rails console access to run the following:

```ruby
Feature.enable(:cycle_analytics_scatterplot_enabled)
```

This chart is enabled by default on GitLab.com.

## Permissions

The current permissions on the Project Cycle Analytics dashboard are:

- Public projects - anyone can access.
- Internal projects - any authenticated user can access.
- Private projects - any member Guest and above can access.

You can [read more about permissions](../../ci/yaml/README.md) in general.

NOTE: **Note:**
As of GitLab 12.3, the project-level page is deprecated. You should access
project-level Cycle Analytics from **Analytics > Cycle Analytics** in the top
navigation bar. We will ensure that the same project-level functionality is available
to CE users in the new analytics space.

For Cycle Analytics functionality introduced in GitLab 12.3 and later:

- Users must have Reporter access or above.
- Features are available only on
  [Premium or Silver tiers](https://about.gitlab.com/pricing/) and above.

## More resources

Learn more about Cycle Analytics in the following resources:

- [Cycle Analytics feature page](https://about.gitlab.com/product/cycle-analytics/).
- [Cycle Analytics feature preview](https://about.gitlab.com/blog/2016/09/16/feature-preview-introducing-cycle-analytics/).
- [Cycle Analytics feature highlight](https://about.gitlab.com/blog/2016/09/21/cycle-analytics-feature-highlight/).
