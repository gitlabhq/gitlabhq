---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
disqus_identifier: 'https://docs.gitlab.com/ee/ci/pipelines.html'
type: reference
---

# CI/CD pipelines

> Introduced in GitLab 8.8.

NOTE: **Tip:**
Watch the
["Mastering continuous software development"](https://about.gitlab.com/webcast/mastering-ci-cd/)
webcast to see a comprehensive demo of a GitLab CI/CD pipeline.

Pipelines are the top-level component of continuous integration, delivery, and deployment.

Pipelines comprise:

- Jobs, which define *what* to do. For example, jobs that compile or test code.
- Stages, which define *when* to run the jobs. For example, stages that run tests after stages that compile the code.

Jobs are executed by [Runners](../runners/README.md). Multiple jobs in the same stage are executed in parallel,
if there are enough concurrent runners.

If *all* jobs in a stage succeed, the pipeline moves on to the next stage.

If *any* job in a stage fails, the next stage is not (usually) executed and the pipeline ends early.

In general, pipelines are executed automatically and require no intervention once created. However, there are
also times when you can manually interact with a pipeline.

A typical pipeline might consist of four stages, executed in the following order:

- A `build` stage, with a job called `compile`.
- A `test` stage, with two jobs called `test1` and `test2`.
- A `staging` stage, with a job called `deploy-to-stage`.
- A `production` stage, with a job called `deploy-to-prod`.

NOTE: **Note:**
If you have a [mirrored repository that GitLab pulls from](../../user/project/repository/repository_mirroring.md#pulling-from-a-remote-repository-starter),
you may need to enable pipeline triggering in your project's
**Settings > Repository > Pull from a remote repository > Trigger pipelines for mirror updates**.

## Types of pipelines

Pipelines can be configured in many different ways:

- [Basic pipelines](pipeline_architectures.md#basic-pipelines) run everything in each stage concurrently,
  followed by the next stage.
- [Directed Acyclic Graph Pipeline (DAG) pipelines](../directed_acyclic_graph/index.md) are based on relationships
  between jobs and can run more quickly than basic pipelines.
- [Multi-project pipelines](../multi_project_pipelines.md) combine pipelines for different projects together.
- [Parent-Child pipelines](../parent_child_pipelines.md) break down complex pipelines
  into one parent pipeline that can trigger multiple child sub-pipelines, which all
  run in the same project and with the same SHA.
- [Pipelines for Merge Requests](../merge_request_pipelines/index.md) run for merge
  requests only (rather than for every commit).
- [Pipelines for Merged Results](../merge_request_pipelines/pipelines_for_merged_results/index.md)
  are merge request pipelines that act as though the changes from the source branch have
  already been merged into the target branch.
- [Merge Trains](../merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md)
  use pipelines for merged results to queue merges one after the other.

## Configure a pipeline

Pipelines and their component jobs and stages are defined in the CI/CD pipeline configuration file for each project.

- Jobs are the [basic configuration](../yaml/README.md#introduction) component.
- Stages are defined by using the [`stages`](../yaml/README.md#stages) keyword.

For a list of configuration options in the CI pipeline file, see the [GitLab CI/CD Pipeline Configuration Reference](../yaml/README.md).

You can also configure specific aspects of your pipelines through the GitLab UI. For example:

- [Pipeline settings](settings.md) for each project.
- [Pipeline schedules](schedules.md).
- [Custom CI/CD variables](../variables/README.md#custom-environment-variables).

### View pipelines

You can find the current and historical pipeline runs under your project's
**CI/CD > Pipelines** page. You can also access pipelines for a merge request by navigating
to its **Pipelines** tab.

![Pipelines index page](img/pipelines_index_v13_0.png)

Clicking a pipeline will bring you to the **Pipeline Details** page and show
the jobs that were run for that pipeline. From here you can cancel a running pipeline,
retry jobs on a failed pipeline, or [delete a pipeline](#delete-a-pipeline).

[Starting in GitLab 12.3](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/50499), a link to the
latest pipeline for the last commit of a given branch is available at `/project/pipelines/[branch]/latest`.
Also, `/project/pipelines/latest` will redirect you to the latest pipeline for the last commit
on the project's default branch.

[Starting in GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/215367),
you can filter the pipeline list by:

- Trigger author
- Branch name

### Run a pipeline manually

Pipelines can be manually executed, with predefined or manually-specified [variables](../variables/README.md).

You might do this if the results of a pipeline (for example, a code build) are required outside the normal
operation of the pipeline.

To execute a pipeline manually:

1. Navigate to your project's **CI/CD > Pipelines**.
1. Click on the **Run Pipeline** button.
1. On the **Run Pipeline** page:
    1. Select the branch to run the pipeline for in the **Create for** field.
    1. Enter any [environment variables](../variables/README.md) required for the pipeline run.
    1. Click the **Create pipeline** button.

The pipeline will execute the jobs as configured.

### Run a pipeline by using a URL query string

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24146) in GitLab 12.5.

You can use a query string to pre-populate the **Run Pipeline** page. For example, the query string
`.../pipelines/new?ref=my_branch&var[foo]=bar&file_var[file_foo]=file_bar` will pre-populate the
**Run Pipeline** page with:

- **Run for** field: `my_branch`.
- **Variables** section:
  - Variable:
    - Key: `foo`
    - Value: `bar`
  - File:
    - Key: `file_foo`
    - Value: `file_bar`

The format of the `pipelines/new` URL is:

```plaintext
.../pipelines/new?ref=<branch>&var[<variable_key>]=<value>&file_var[<file_key>]=<value>
```

The following parameters are supported:

- `ref`: specify the branch to populate the **Run for** field with.
- `var`: specify a `Variable` variable.
- `file_var`: specify a `File` variable.

For each `var` or `file_var`, a key and value are required.

### Add manual interaction to your pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/7931) in GitLab 8.15.

Manual actions, configured using the [`when:manual`](../yaml/README.md#whenmanual) parameter,
allow you to require manual interaction before moving forward in the pipeline.

You can do this straight from the pipeline graph. Just click the play button
to execute that particular job.

For example, your pipeline might start automatically, but it requires manual action to
[deploy to production](../environments/index.md#configuring-manual-deployments). In the example below, the `production`
stage has a job with a manual action.

![Pipelines example](img/pipelines.png)

#### Start multiple manual actions in a stage

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/27188) in GitLab 11.11.

Multiple manual actions in a single stage can be started at the same time using the "Play all manual" button.
Once the user clicks this button, each individual manual action will be triggered and refreshed
to an updated status.

This functionality is only available:

- For users with at least Developer access.
- If the stage contains [manual actions](#add-manual-interaction-to-your-pipeline).

### Delete a pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24851) in GitLab 12.7.

Users with [owner permissions](../../user/permissions.md) in a project can delete a pipeline
by clicking on the pipeline in the **CI/CD > Pipelines** to get to the **Pipeline Details**
page, then using the **Delete** button.

![Pipeline Delete Button](img/pipeline-delete.png)

CAUTION: **Warning:**
Deleting a pipeline will expire all pipeline caches, and delete all related objects,
such as builds, logs, artifacts, and triggers. **This action cannot be undone.**

### Pipeline quotas

Each user has a personal pipeline quota that tracks the usage of shared runners in all personal projects.
Each group has a [usage quota](../../subscriptions/index.md#ci-pipeline-minutes) that tracks the usage of shared runners for all projects created within the group.

When a pipeline is triggered, regardless of who triggered it, the pipeline quota for the project owner's [namespace](../../user/group/index.md#namespaces) is used. In this case, the namespace can be the user or group that owns the project.

#### How pipeline duration is calculated

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

```plaintext
0  1  2  3  4  5  6  7
   AAAAAAA
      BBBBBBB
                  CCCC
```

The union of A, B, and C is (1, 4) and (6, 7). Therefore, the total running time is:

```plaintext
(4 - 1) + (7 - 6) => 4
```

### Pipeline security on protected branches

A strict security model is enforced when pipelines are executed on
[protected branches](../../user/project/protected_branches.md).

The following actions are allowed on protected branches only if the user is
[allowed to merge or push](../../user/project/protected_branches.md#using-the-allowed-to-merge-and-allowed-to-push-settings)
on that specific branch:

- Run manual pipelines (using the [Web UI](#run-a-pipeline-manually) or [pipelines API](#pipelines-api)).
- Run scheduled pipelines.
- Run pipelines using triggers.
- Trigger manual actions on existing pipelines.
- Retry or cancel existing jobs (using the Web UI or pipelines API).

**Variables** marked as **protected** are accessible only to jobs that
run on protected branches, preventing untrusted users getting unintended access to
sensitive information like deployment credentials and tokens.

**Runners** marked as **protected** can run jobs only on protected
branches, preventing untrusted code from executing on the protected runner and
preserving deployment keys and other credentials from being unintentionally
accessed. In order to ensure that jobs intended to be executed on protected
runners will not use regular runners, they must be tagged accordingly.

## View jobs in a pipeline

When you access a pipeline, you can see the related jobs for that pipeline.

Clicking an individual job will show you its job log, and allow you to:

- Cancel the job.
- Retry the job.
- Erase the job log.

### See why a job failed

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17782) in GitLab 10.7.

When a pipeline fails or is allowed to fail, there are several places where you
can find the reason:

- In the [pipeline graph](#visualize-pipelines), on the pipeline detail view.
- In the pipeline widgets, in the merge requests and commit pages.
- In the job views, in the global and detailed views of a job.

In each place, if you hover over the failed job you can see the reason it failed.

![Pipeline detail](img/job_failure_reason.png)

In [GitLab 10.8](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/17814) and later,
you can also see the reason it failed on the Job detail page.

### The order of jobs in a pipeline

The order of jobs in a pipeline depends on the type of pipeline graph.

- For [regular pipeline graphs](#regular-pipeline-graphs), jobs are sorted by name.
- For [pipeline mini graphs](#pipeline-mini-graphs), jobs are sorted by severity and then by name.

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

### Group jobs in a pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/6242) in GitLab 8.12.

If you have many similar jobs, your [pipeline graph](#visualize-pipelines) becomes long and hard
to read.

You can automatically group similar jobs together. If the job names are formatted in a certain way,
they will be collapsed into a single group in regular pipeline graphs (not the mini graphs).

You'll know when a pipeline has grouped jobs if you don't see the retry or
cancel button inside them. Hovering over them will show the number of grouped
jobs. Click to expand them.

![Grouped pipelines](img/pipelines_grouped.png)

To create a group of jobs, in the [CI/CD pipeline configuration file](../yaml/README.md),
separate each job name with a number and one of the following:

- A slash (`/`), for example, `test 1/3`, `test 2/3`, `test 3/3`.
- A colon (`:`), for example, `test 1:3`, `test 2:3`, `test 3:3`.
- A space, for example `test 0 3`, `test 1 3`, `test 2 3`.

You can use these symbols interchangeably.

For example, these three jobs will be in a group named `build ruby`:

```yaml
build ruby 1/3:
  stage: build
  script:
  - echo "ruby1"

build ruby 2/3:
  stage: build
  script:
  - echo "ruby2"

build ruby 3/3:
  stage: build
  script:
  - echo "ruby3"
```

In the pipeline, the result is a group named `build ruby` with three jobs:

![Job group](img/job_group_v12_10.png)

The jobs will be ordered by comparing the numbers from left to right. You
usually want the first number to be the index and the second number to be the total.

[This regular expression](https://gitlab.com/gitlab-org/gitlab/blob/2f3dc314f42dbd79813e6251792853bc231e69dd/app/models/commit_status.rb#L99)
evaluates the job names: `\d+[\s:\/\\]+\d+\s*`.

### Specifying variables when running manual jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/30485) in GitLab 12.2.

When running manual jobs you can supply additional job specific variables.

You can do this from the job page of the manual job you want to run with
additional variables. To access this page, click on the **name** of the manual job in
the pipeline view, *not* the play (**{play}**) button.

This is useful when you want to alter the execution of a job that uses
[custom environment variables](../variables/README.md#custom-environment-variables).
Adding a variable name (key) and value here will override the value defined in
[the UI or `.gitlab-ci.yml`](../variables/README.md#custom-environment-variables),
for a single run of the manual job.

![Manual job variables](img/manual_job_variables.png)

### Delay a job

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/21767) in GitLab 11.4.

When you do not want to run a job immediately, you can use the [`when:delayed`](../yaml/README.md#whendelayed) parameter to
delay a job's execution for a certain period.

This is especially useful for timed incremental rollout where new code is rolled out gradually.

For example, if you start rolling out new code and:

- Users do not experience trouble, GitLab can automatically complete the deployment from 0% to 100%.
- Users experience trouble with the new code, you can stop the timed incremental rollout by canceling the pipeline
  and [rolling](../environments/index.md#retrying-and-rolling-back) back to the last stable version.

![Pipelines example](img/pipeline_incremental_rollout.png)

### Expand and collapse job log sections

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/14664) in GitLab 12.0.

Job logs are divided into sections that can be collapsed or expanded. Each section will display
the duration.

In the following example:

- Two sections are collapsed and can be expanded.
- Three sections are expanded and can be collapsed.

![Collapsible sections](img/collapsible_log_v12_6.png)

#### Custom collapsible sections

You can create collapsible sections in job logs by manually outputting special codes
that GitLab will use to determine what sections to collapse:

- Section start marker: `section_start:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K` + `TEXT_OF_SECTION_HEADER`
- Section end marker: `section_end:UNIX_TIMESTAMP:SECTION_NAME\r\e[0K`

You must add these codes to the script section of the CI configuration. For example,
using `echo`:

```yaml
job1:
  script:
    - echo -e "section_start:`date +%s`:my_first_section\r\e[0KHeader of the 1st collapsible section"
    - echo 'this line should be hidden when collapsed'
    - echo -e "section_end:`date +%s`:my_first_section\r\e[0K"
```

In the example above:

- `date +%s`: The Unix timestamp (for example `1560896352`).
- `my_first_section`: The name given to the section.
- `\r\e[0K`: Prevents the section markers from displaying in the rendered (colored)
  job log, but they are displayed in the raw job log. To see them, in the top right
  of the job log, click **{doc-text}** (**Show complete raw**).
  - `\r`: carriage return.
  - `\e[0K`: clear line ANSI escape code.

Sample raw job log:

```plaintext
section_start:1560896352:my_first_section\r\e[0KHeader of the 1st collapsible section
this line should be hidden when collapsed
section_end:1560896353:my_first_section\r\e[0K
```

## Visualize pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5742) in GitLab 8.11.

Pipelines can be complex structures with many sequential and parallel jobs.

To make it easier to understand the flow of a pipeline, GitLab has pipeline graphs for viewing pipelines
and their statuses.

Pipeline graphs can be displayed in two different ways, depending on the page you
access the graph from.

NOTE: **Note:**
GitLab capitalizes the stages' names in the pipeline graphs.

### Regular pipeline graphs

Regular pipeline graphs show the names of the jobs in each stage. Regular pipeline graphs can
be found when you are on a [single pipeline page](#view-pipelines). For example:

![Pipelines example](img/pipelines.png)

[Multi-project pipeline graphs](../multi_project_pipelines.md#multi-project-pipeline-visualization-premium) help
you visualize the entire pipeline, including all cross-project inter-dependencies. **(PREMIUM)**

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

### Pipeline success and duration charts

> - Introduced in GitLab 3.1.1 as Commit Stats, and later renamed to Pipeline Charts.
> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/38318) to CI / CD Analytics in GitLab 12.8.

GitLab tracks the history of your pipeline successes and failures, as well as how long each pipeline ran. To view this information, go to **Analytics > CI / CD Analytics**.

View successful pipelines:

![Successful pipelines](img/pipelines_success_chart.png)

View pipeline duration history:

![Pipeline duration](img/pipelines_duration_chart.png)

### Pipeline badges

Pipeline status and test coverage report badges are available and configurable for each project.
For information on adding pipeline badges to projects, see [Pipeline badges](settings.md#pipeline-badges).

## Pipelines API

GitLab provides API endpoints to:

- Perform basic functions. For more information, see [Pipelines API](../../api/pipelines.md).
- Maintain pipeline schedules. For more information, see [Pipeline schedules API](../../api/pipeline_schedules.md).
- Trigger pipeline runs. For more information, see:
  - [Triggering pipelines through the API](../triggers/README.md).
  - [Pipeline triggers API](../../api/pipeline_triggers.md).

## Troubleshooting `fatal: reference is not a tree:`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17043) in GitLab 12.4.

Previously, you'd have encountered unexpected pipeline failures when you force-pushed
a branch to its remote repository. To illustrate the problem, suppose you've had the current workflow:

1. A user creates a feature branch named `example` and pushes it to a remote repository.
1. A new pipeline starts running on the `example` branch.
1. A user rebases the `example` branch on the latest `master` branch and force-pushes it to its remote repository.
1. A new pipeline starts running on the `example` branch again, however,
   the previous pipeline (2) fails because of `fatal: reference is not a tree:` error.

This is because the previous pipeline cannot find a checkout-SHA (which associated with the pipeline record)
from the `example` branch that the commit history has already been overwritten by the force-push.
Similarly, [Pipelines for merged results](../merge_request_pipelines/pipelines_for_merged_results/index.md)
might have failed intermittently due to [the same reason](../merge_request_pipelines/pipelines_for_merged_results/index.md#intermittently-pipelines-fail-by-fatal-reference-is-not-a-tree-error).

As of GitLab 12.4, we've improved this behavior by persisting pipeline refs exclusively.
To illustrate its life cycle:

1. A pipeline is created on a feature branch named `example`.
1. A persistent pipeline ref is created at `refs/pipelines/<pipeline-id>`,
   which retains the checkout-SHA of the associated pipeline record.
   This persistent ref stays intact during the pipeline execution,
   even if the commit history of the `example` branch has been overwritten by force-push.
1. GitLab Runner fetches the persistent pipeline ref and gets source code from the checkout-SHA.
1. When the pipeline finished, its persistent ref is cleaned up in a background process.
