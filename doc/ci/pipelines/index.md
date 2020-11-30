---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
disqus_identifier: 'https://docs.gitlab.com/ee/ci/pipelines.html'
type: reference
---

# CI/CD pipelines

> Introduced in GitLab 8.8.

TIP: **Tip:**
Watch the
["Mastering continuous software development"](https://about.gitlab.com/webcast/mastering-ci-cd/)
webcast to see a comprehensive demo of a GitLab CI/CD pipeline.

Pipelines are the top-level component of continuous integration, delivery, and deployment.

Pipelines comprise:

- Jobs, which define *what* to do. For example, jobs that compile or test code.
- Stages, which define *when* to run the jobs. For example, stages that run tests after stages that compile the code.

Jobs are executed by [runners](../runners/README.md). Multiple jobs in the same stage are executed in parallel,
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
If you have a [mirrored repository that GitLab pulls from](../../user/project/repository/repository_mirroring.md#pulling-from-a-remote-repository),
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

- [Jobs](../jobs/index.md) are the basic configuration component.
- Stages are defined by using the [`stages`](../yaml/README.md#stages) keyword.

For a list of configuration options in the CI pipeline file, see the [GitLab CI/CD Pipeline Configuration Reference](../yaml/README.md).

You can also configure specific aspects of your pipelines through the GitLab UI. For example:

- [Pipeline settings](settings.md) for each project.
- [Pipeline schedules](schedules.md).
- [Custom CI/CD variables](../variables/README.md#custom-environment-variables).

### Ref Specs for Runners

When a runner picks a pipeline job, GitLab provides that job's metadata. This includes the [Git refspecs](https://git-scm.com/book/en/v2/Git-Internals-The-Refspec),
which indicate which ref (branch, tag, and so on) and commit (SHA1) are checked out from your
project repository.

This table lists the refspecs injected for each pipeline type:

| Pipeline type                                                      | Refspecs                                                                                       |
|---------------                                                     |----------------------------------------                                                        |
| Pipeline for Branches                                              | `+refs/pipelines/<id>:refs/pipelines/<id>` and `+refs/heads/<name>:refs/remotes/origin/<name>` |
| pipeline for Tags                                                  | `+refs/pipelines/<id>:refs/pipelines/<id>` and `+refs/tags/<name>:refs/tags/<name>`            |
| [Pipeline for Merge Requests](../merge_request_pipelines/index.md) | `+refs/pipelines/<id>:refs/pipelines/<id>`                                                     |

The refs `refs/heads/<name>` and `refs/tags/<name>` exist in your
project repository. GitLab generates the special ref `refs/pipelines/<id>` during a
running pipeline job. This ref can be created even after the associated branch or tag has been
deleted. It's therefore useful in some features such as [automatically stopping an environment](../environments/index.md#automatically-stopping-an-environment),
and [merge trains](../merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md)
that might run pipelines after branch deletion.

### View pipelines

You can find the current and historical pipeline runs under your project's
**CI/CD > Pipelines** page. You can also access pipelines for a merge request by navigating
to its **Pipelines** tab.

![Pipelines index page](img/pipelines_index_v13_0.png)

Click a pipeline to open the **Pipeline Details** page and show
the jobs that were run for that pipeline. From here you can cancel a running pipeline,
retry jobs on a failed pipeline, or [delete a pipeline](#delete-a-pipeline).

[Starting in GitLab 12.3](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/50499), a link to the
latest pipeline for the last commit of a given branch is available at `/project/pipelines/[branch]/latest`.
Also, `/project/pipelines/latest` redirects you to the latest pipeline for the last commit
on the project's default branch.

[Starting in GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/215367),
you can filter the pipeline list by:

- Trigger author
- Branch name
- Status ([GitLab 13.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/217617))
- Tag ([GitLab 13.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/217617))

### Run a pipeline manually

Pipelines can be manually executed, with predefined or manually-specified [variables](../variables/README.md).

You might do this if the results of a pipeline (for example, a code build) are required outside the normal
operation of the pipeline.

To execute a pipeline manually:

1. Navigate to your project's **CI/CD > Pipelines**.
1. Select the **Run Pipeline** button.
1. On the **Run Pipeline** page:
    1. Select the branch to run the pipeline for in the **Create for** field.
    1. Enter any [environment variables](../variables/README.md) required for the pipeline run.
    1. Click the **Create pipeline** button.

The pipeline now executes the jobs as configured.

### Run a pipeline by using a URL query string

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24146) in GitLab 12.5.

You can use a query string to pre-populate the **Run Pipeline** page. For example, the query string
`.../pipelines/new?ref=my_branch&var[foo]=bar&file_var[file_foo]=file_bar` pre-populates the
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

Manual actions, configured using the [`when:manual`](../yaml/README.md#whenmanual) keyword,
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
After you click this button, each individual manual action is triggered and refreshed
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
Deleting a pipeline expires all pipeline caches, and deletes all related objects,
such as builds, logs, artifacts, and triggers. **This action cannot be undone.**

### Pipeline quotas

Each user has a personal pipeline quota that tracks the usage of shared runners in all personal projects.
Each group has a [usage quota](../../subscriptions/gitlab_com/index.md#ci-pipeline-minutes) that tracks the usage of shared runners for all projects created within the group.

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
- Run on-demand DAST scan.
- Trigger manual actions on existing pipelines.
- Retry or cancel existing jobs (using the Web UI or pipelines API).

**Variables** marked as **protected** are accessible only to jobs that
run on protected branches, preventing untrusted users getting unintended access to
sensitive information like deployment credentials and tokens.

**Runners** marked as **protected** can run jobs only on protected
branches, preventing untrusted code from executing on the protected runner and
preserving deployment keys and other credentials from being unintentionally
accessed. In order to ensure that jobs intended to be executed on protected
runners do not use regular runners, they must be tagged accordingly.

## Visualize pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/5742) in GitLab 8.11.

Pipelines can be complex structures with many sequential and parallel jobs.

To make it easier to understand the flow of a pipeline, GitLab has pipeline graphs for viewing pipelines
and their statuses.

Pipeline graphs can be displayed in two different ways, depending on the page you
access the graph from.

GitLab capitalizes the stages' names in the pipeline graphs.

### Regular pipeline graphs

Regular pipeline graphs show the names of the jobs in each stage. Regular pipeline graphs can
be found when you are on a [single pipeline page](#view-pipelines). For example:

![Pipelines example](img/pipelines.png)

[Multi-project pipeline graphs](../multi_project_pipelines.md#multi-project-pipeline-visualization) help
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
