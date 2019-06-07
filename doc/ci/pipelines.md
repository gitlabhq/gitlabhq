---
type: reference
---

# Creating and using CI/CD pipelines

> Introduced in GitLab 8.8.

## Introduction

Pipelines are the top-level component of continuous integration, delivery, and deployment.

Pipelines comprise:

- Jobs that define what to run. For example, code compilation or test runs.
- Stages that define when and how to run. For example, that tests run only after code compilation.

Multiple jobs in the same stage are executed by [Runners](runners/README.md) in parallel, if there are enough concurrent [Runners](runners/README.md).

If all the jobs in a stage:

- Succeed, the pipeline moves on to the next stage.
- Fail, the next stage is not (usually) executed and the pipeline ends early.

NOTE: **Note:**
If you have a [mirrored repository that GitLab pulls from](../workflow/repository_mirroring.md#pulling-from-a-remote-repository-starter),
you may need to enable pipeline triggering in your project's
**Settings > Repository > Pull from a remote repository > Trigger pipelines for mirror updates**.

### Simple pipeline example

As an example, imagine a pipeline consisting of four stages, executed in the following order:

- `build`, with a job called `compile`.
- `test`, with two jobs called `test` and `test2`.
- `staging`, with a job called `deploy-to-stage`.
- `production`, with a job called `deploy-to-prod`.

## Visualizing pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5742) in GitLab 8.11.

Pipelines can be complex structures with many sequential and parallel jobs.

To make it easier to understand the flow of a pipeline, GitLab has pipeline graphs for viewing pipelines
and their statuses.

Pipeline graphs can be displayed in two different ways, depending on the page you
access the graph from.

NOTE: **Note:**
GitLab capitalizes the stages' names when shown in the pipeline graphs (below).

### Regular pipeline graphs

Regular pipeline graphs show the names of the jobs of each stage. Regular pipeline graphs can
be found when you are on a [single pipeline page](#accessing-pipelines). For example:

![Pipelines example](img/pipelines.png)

### Pipeline mini graphs

Pipeline mini graphs take less space and can tell you at a
quick glance if all jobs passed or something failed. The pipeline mini graph can
be found when you navigate to:

- The pipelines index page.
- A single commit page.
- A merge request page.

Pipeline mini graphs allow you to see all related jobs for a single commit and the net result
of each stage of your pipeline. This allows you to quickly see what failed and
fix it.

Stages in pipeline mini graphs are collapsible. Hover your mouse over them and click to expand their jobs.

| Mini graph                                                   | Mini graph expanded                                            |
|:-------------------------------------------------------------|:---------------------------------------------------------------|
| ![Pipelines mini graph](img/pipelines_mini_graph_simple.png) | ![Pipelines mini graph extended](img/pipelines_mini_graph.png) |

### Job ordering in pipeline graphs

Job ordering depends on the type of pipeline graph. For [regular pipeline graphs](#regular-pipeline-graphs), jobs are sorted by name.

For [pipeline mini graphs](#pipeline-mini-graphs) ([introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9760)
in GitLab 9.0), jobs are sorted by severity and then by name.

The order of severity is:

- failed
- warning
- pending
- running
- manual
- scheduled
- canceled
- success
- skipped
- created

For example:

![Pipeline mini graph sorting](img/pipelines_mini_graph_sorting.png)

### How pipeline duration is calculated

Total running time for a given pipeline excludes retries and pending
(queued) time.

Each job is represented as a `Period`, which consists of:

- `Period#first` (when the job started).
- `Period#last` (when the job finished).

A simple example is:

- A (1, 3)
- B (2, 4)
- C (6, 7)

In the example:

- A begins at 1 and ends at 3.
- B begins at 2 and ends at 4.
- C begins at 6 and ends at 7.

Visually, it can be viewed as:

```text
0  1  2  3  4  5  6  7
   AAAAAAA
      BBBBBBB
                  CCCC
```

The union of A, B, and C is (1, 4) and (6, 7). Therefore, the total running time is:

```text
(4 - 1) + (7 - 6) => 4
```

## Configuring pipelines

Pipelines, and their component jobs and stages, are defined in the [`.gitlab-ci.yml`](yaml/README.md) file for each project.

In particular:

- Jobs are the [basic configuration](yaml/README.html#introduction) component.
- Stages are defined using the [`stages`](yaml/README.html#stages) keyword.

For all available configuration options, see the [GitLab CI/CD Pipeline Configuration Reference](yaml/README.md).

### Settings and schedules

In addition to configuring jobs through `.gitlab-ci.yml`, additional configuration options are available
through the GitLab UI:

- Pipeline settings for each project. For more information, see [Pipeline settings](../user/project/pipelines/settings.md).
- Schedules for pipelines. For more information, see [Pipeline schedules](../user/project/pipelines/schedules.md).

### Grouping jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/6242) in GitLab 8.12.

If you have many similar jobs, your [pipeline graph](#visualizing-pipelines) becomes long and hard
to read.

For that reason, similar jobs can automatically be grouped together.
If the job names are formatted in certain ways, they will be collapsed into
a single group in regular pipeline graphs (not the mini graphs).

You'll know when a pipeline has grouped jobs if you don't see the retry or
cancel button inside them. Hovering over them will show the number of grouped
jobs. Click to expand them.

![Grouped pipelines](img/pipelines_grouped.png)

#### Configuring grouping

In the pipeline [configuration file](yaml/README.md), job names must include two numbers separated with one of
the following (you can even use them interchangeably):

- A space.
- A slash (`/`).
- A colon (`:`).

NOTE: **Note:**
More specifically, it uses [this](https://gitlab.com/gitlab-org/gitlab-ce/blob/2f3dc314f42dbd79813e6251792853bc231e69dd/app/models/commit_status.rb#L99) regular expression: `\d+[\s:\/\\]+\d+\s*`.

#### How grouping works

The jobs will be ordered by comparing those two numbers from left to right. You
usually want the first to be the index and the second the total.

For example, the following jobs will be grouped under a job named `test`:

- `test 0 3`
- `test 1 3`
- `test 2 3`

The following jobs will be grouped under a job named `test ruby`:

- `test 1:2 ruby`
- `test 2:2 ruby`

The following jobs will be grouped under a job named `test ruby` as well:

- `1/3 test ruby`
- `2/3 test ruby`
- `3/3 test ruby`

### Pipelines for merge requests

GitLab supports configuring pipelines that run only for merge requests. For more information, see
[Pipelines for merge requests](merge_request_pipelines/index.md).

### Badges

Pipeline status and test coverage report badges are available and configurable for each project.

For information on adding pipeline badges to projects, see [Pipeline badges](../user/project/pipelines/settings.md#pipeline-badges).

## Multi-project pipelines **[PREMIUM]**

Pipelines for different projects can be combined and visualized together.

For more information, see [Multi-project pipelines](multi_project_pipelines.md).

## Working with pipelines

In general, pipelines are executed automatically and require no intervention once created.

However, there are instances where you'll need to interact with pipelines. These are documented below.

### Manually executing pipelines

Pipelines can be manually executed, with predefined or manually-specified [variables](variables/README.md).

You might do this if the results of a pipeline (for example, a code build) is required outside the normal
operation of the pipeline.

To execute a pipeline manually:

1. Navigate to your project's **CI/CD > Pipelines**.
1. Click on the **Run Pipeline** button.
1. On the **Run Pipeline** page:
    1. Select the branch to run the pipeline for in the **Create for** field.
    1. Enter any [environment variables](variables/README.md) required for the pipeline run.
    1. Click the **Create pipeline** button.

The pipeline will execute the jobs as configured.

### Accessing pipelines

You can find the current and historical pipeline runs under your project's
**CI/CD > Pipelines** page. Clicking on a pipeline will show the jobs that were run for
that pipeline.

![Pipelines index page](img/pipelines_index.png)

You can also access pipelines for a merge request by navigating to its **Pipelines** tab.

### Accessing individual jobs

When you access a pipeline, you can see the related jobs for that pipeline.

Clicking on an individual job will show you its job trace, and allow you to:

- Cancel the job.
- Retry the job.
- Erase the job trace.

### Seeing the failure reason for jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/17782) in GitLab 10.7.

When a pipeline fails or is allowed to fail, there are several places where you
can quickly check the reason it failed:

- In the pipeline graph, on the pipeline detail view.
- In the pipeline widgets, in the merge requests and commit pages.
- In the job views, in the global and detailed views of a job.

In each place, if you hover over the failed job you can see the reason it failed.

![Pipeline detail](img/job_failure_reason.png)

From [GitLab 10.8](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/17814),
you can also see the reason it failed on the Job detail page.

### Manual actions from pipeline graphs

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/7931) in GitLab 8.15.

Manual actions, configured using the [`when:manual`](yaml/README.md#whenmanual) parameter,
allow you to require manual interaction before moving forward in the pipeline.

You can do this straight from the pipeline graph. Just click on the play button
to execute that particular job.

For example, your pipeline start automatically, but require manual action to
[deploy to production](environments.md#configuring-manual-deployments). In the example below, the `production`
stage has a job with a manual action.

![Pipelines example](img/pipelines.png)

### Delay a job in a pipeline graph

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/21767) in GitLab 11.4.

When you do not want to run a job immediately, you can use the [`when:delayed`](yaml/README.md#whendelayed) parameter to
delay a job's execution for a certain period.

This is especially useful for timed incremental rollout where new code is rolled out gradually.

For example, if you start rolling out new code and:

- Users do not experience trouble, GitLab can automatically complete the deployment from 0% to 100%.
- Users experience trouble with the new code, you can stop the timed incremental rollout by canceling the pipeline
  and [rolling](environments.md#retrying-and-rolling-back) back to the last stable version.

![Pipelines example](img/pipeline_incremental_rollout.png)

### Using the API

GitLab provides API endpoints to:

- Perform basic functions. For more information, see [Pipelines API](../api/pipelines.md).
- Maintain pipeline schedules. For more information, see [Pipeline schedules API](../api/pipeline_schedules.md).
- Trigger pipeline runs. For more information, see:
  - [Triggering pipelines through the API](triggers/README.md).
  - [Pipeline triggers API](../api/pipeline_triggers.md).

### Start multiple manual actions in a stage

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/27188) in GitLab 11.11.

Multiple manual actions in a single stage can be started at the same time using the "Play all manual" button.
Once the user clicks this button, each individual manual action will be triggered and refreshed
to an updated status.

This functionality is only available:

- For users with at least Developer access.
- If the the stage contains [manual actions](#manual-actions-from-pipeline-graphs).

## Security on protected branches

A strict security model is enforced when pipelines are executed on
[protected branches](../user/project/protected_branches.md).

The following actions are allowed on protected branches only if the user is
[allowed to merge or push](../user/project/protected_branches.md#using-the-allowed-to-merge-and-allowed-to-push-settings)
on that specific branch:

- Run manual pipelines (using the [Web UI](#manually-executing-pipelines) or pipelines API).
- Run scheduled pipelines.
- Run pipelines using triggers.
- Trigger manual actions on existing pipelines.
- Retry or cancel existing jobs (using the Web UI or pipelines API).

**Variables** marked as **protected** are accessible only to jobs that
run on protected branches, preventing untrusted users getting unintended access to
sensitive information like deployment credentials and tokens.

**Runners** marked as **protected** can run jobs only on protected
branches, avoiding untrusted code to be executed on the protected runner and
preserving deployment keys and other credentials from being unintentionally
accessed. In order to ensure that jobs intended to be executed on protected
runners will not use regular runners, they must be tagged accordingly.
