---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---


# Merge request pipelines **(FREE)**

> [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/351192) from `pipelines for merge requests` to `merge request pipelines` in GitLab 14.8.

You can configure your [pipeline](index.md) to run every time you commit changes to a branch.
This type of pipeline is called a *branch pipeline*.

Alternatively, you can configure your pipeline to run every time you make changes to the
source branch for a merge request. This type of pipeline is called a *merge request pipeline*.

Branch pipelines:

- Run when you push a new commit to a branch.
- Are the default type of pipeline.
- Have access to [some predefined variables](../variables/predefined_variables.md).
- Have access to [protected variables](../variables/index.md#protect-a-cicd-variable) and [protected runners](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information).

Merge request pipelines:

- **Do not run by default**. The jobs in the CI/CD configuration file [must be configured](#prerequisites)
  to run in merge request pipelines.
- If configured, merge request pipelines run when you:
  - Create a new merge request from a source branch with one or more commits.
  - Push a new commit to the source branch for a merge request.
  - Select **Run pipeline** from the **Pipelines** tab in a merge request. This option
    is only available when merge request pipelines are configured for the pipeline
    and the source branch has at least one commit.
- Have access to [more predefined variables](#available-predefined-variables).
- Do not have access to [protected variables](../variables/index.md#protect-a-cicd-variable) or [protected runners](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information).

Both of these types of pipelines can appear on the **Pipelines** tab of a merge request.

## Types of merge request pipelines

The three types of merge request pipelines are:

- Merge request pipelines, which run on the changes in the merge request's
  source branch. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352939)
  in GitLab 14.9, these pipelines display a `merge request` label to indicate that the
  pipeline ran only on the contents of the source branch, ignoring the target branch.
  In GitLab 14.8 and earlier, the label is `detached`.
- [Merged results pipelines](merged_results_pipelines.md), which run on
  the result of combining the source branch's changes with the target branch.
- [Merge trains](merge_trains.md), which run when merging multiple merge requests
  at the same time. The changes from each merge request are combined into the
  target branch with the changes in the earlier enqueued merge requests, to ensure
  they all work together.

## Prerequisites

To use merge request pipelines:

- Your project's [CI/CD configuration file](../yaml/index.md) must be configured with
  jobs that run in merge request pipelines. To do this, you can use:
  - [`rules`](#use-rules-to-add-jobs).
  - [`only/except`](#use-only-to-add-jobs).
- You must have at least the Developer role in the
  source project to run a merge request pipeline.
- Your repository must be a GitLab repository, not an [external repository](../ci_cd_for_external_repos/index.md).

## Use `rules` to add jobs

You can use the [`rules`](../yaml/index.md#rules) keyword to configure jobs to run in
merge request pipelines. For example:

```yaml
job1:
  script:
    - echo "This job runs in merge request pipelines"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

You can also use the [`workflow: rules`](../yaml/index.md#workflowrules) keyword
to configure the entire pipeline to run in merge request pipelines. For example:

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'

job1:
  script:
    - echo "This job runs in merge request pipelines"

job2:
  script:
    - echo "This job also runs in merge request pipelines"
```

## Use `only` to add jobs

You can use the [`only`](../yaml/index.md#onlyrefs--exceptrefs) keyword with `merge_requests`
to configure jobs to run in merge request pipelines.

```yaml
job1:
  script:
    - echo "This job runs in merge request pipelines"
  only:
    - merge_requests
```

## Use with forked projects

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217451) in GitLab 13.3.
> - [Moved](https://about.gitlab.com/blog/2021/01/26/new-gitlab-product-subscription-model/) to GitLab Premium in 13.9.

External contributors who work in forks can't create pipelines in the parent project.

A merge request from a fork that is submitted to the parent project triggers a
pipeline that:

- Is created and runs in the fork (source) project, not the parent (target) project.
- Uses the fork project's CI/CD configuration, resources, and project CI/CD variables.

Pipelines for forks display with the **fork** badge in the parent project:

![Pipeline ran in fork](img/pipeline_fork_v13_7.png)

### Run pipelines in the parent project **(PREMIUM)**

Project members in the parent project can trigger a merge request pipeline
for a merge request submitted from a fork project. This pipeline:

- Is created and runs in the parent (target) project, not the fork (source) project.
- Uses the CI/CD configuration present in the fork project's branch.
- Uses the parent project's CI/CD settings, resources, and project CI/CD variables.
- Uses the permissions of the parent project member that triggers the pipeline.

Run pipelines in fork project MRs to ensure that the post-merge pipeline passes in
the parent project. Additionally, if you do not trust the fork project's runner,
running the pipeline in the parent project uses the parent project's trusted runners.

WARNING:
Fork merge requests can contain malicious code that tries to steal secrets in the parent project when the pipeline runs, even before merge. As a reviewer, carefully check the changes in the merge request before triggering the pipeline. Unless you trigger the pipeline through the API or the [`/rebase` quick action](../../user/project/quick_actions.md#issues-merge-requests-and-epics), GitLab shows a warning that you must accept before the pipeline runs. Otherwise, **no warning displays**.

Prerequisites:

- The parent project's [CI/CD configuration file](../yaml/index.md) must be configured to
  [run jobs in merge request pipelines](#prerequisites).
- You must be a member of the parent project with [permissions to run CI/CD pipelines](../../user/permissions.md#gitlab-cicd-permissions).
  You might need additional permissions if the branch is protected.
- The fork project must be [visible](../../user/public_access.md) to the
  user running the pipeline. Otherwise, the **Pipelines** tab does not display
  in the merge request.

To use the UI to run a pipeline in the parent project for a merge request from a fork project:

1. In the merge request, go to the **Pipelines** tab.
1. Select **Run pipeline**. You must read and accept the warning, or the pipeline does not run.

You can disable this feature by using [the projects API](../../api/projects.md#edit-project)
to disable the `ci_allow_fork_pipelines_to_run_in_parent_project` setting.
The setting is `enabled` by default.

## Available predefined variables

When you use merge request pipelines, you can use:

- All the same [predefined variables](../variables/predefined_variables.md) that are
  available in branch pipelines.
- [Additional predefined variables](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines)
  available only to jobs in merge request pipelines. These variables contain
  information from the associated merge request, which can be when calling the
  [GitLab Merge Request API endpoint](../../api/merge_requests.md) from a job.

## Troubleshooting

### Two pipelines when pushing to a branch

If you get duplicate pipelines in merge requests, your pipeline might be configured
to run for both branches and merge requests at the same time. Adjust your pipeline
configuration to [avoid duplicate pipelines](../jobs/job_control.md#avoid-duplicate-pipelines).

In [GitLab 13.7 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/201845),
you can add `workflow:rules` to [switch from branch pipelines to merge request pipelines](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines).
After a merge request is open on the branch, the pipeline switches to a merge request pipeline.

### Two pipelines when pushing an invalid CI/CD configuration file

If you push an invalid CI/CD configuration to a merge request's branch, two failed
pipelines appear in the pipelines tab. One pipeline is a failed branch pipeline,
the other is a failed merge request pipeline.

When the configuration syntax is fixed, no further failed pipelines should appear.
To find and fix the configuration problem, you can use:

- The [pipeline editor](../pipeline_editor/index.md).
- The [CI lint tool](../lint.md).

### The merge request's pipeline is marked as failed but the latest pipeline succeeded

It's possible to have both branch pipelines and merge request pipelines in the
**Pipelines** tab of a single merge request. This might be [by configuration](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines),
or [by accident](#two-pipelines-when-pushing-to-a-branch).

When using the [merge when pipeline succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md)
feature and both pipelines types are present, the merge request pipelines are checked,
not the branch pipelines.

Therefore, the MR pipeline result is marked as unsuccessful if the
**merge request pipeline** fails, independently of the **branch pipeline** result.

However:

- These conditions are not enforced.
- A race condition determines which pipeline's result is used to either block or pass merge requests.

This bug is tracked on [issue 384927](https://gitlab.com/gitlab-org/gitlab/-/issues/384927).

### `An error occurred while trying to run a new pipeline for this merge request.`

This error can happen when you select **Run pipeline** in a merge request, but the
project does not have merge request pipelines enabled anymore.

Some possible reasons for this error message:

- The project does not have merge request pipelines enabled, has no pipelines listed
  in the **Pipelines** tab, and you select **Run pipelines**.
- The project used to have merge request pipelines enabled, but the configuration
  was removed. For example:

  1. The project has merge request pipelines enabled in the `.gitlab-ci.yml` configuration
     file when the merge request is created.
  1. The **Run pipeline** options is available in the merge request's **Pipelines** tab,
     and selecting **Run pipeline** at this point likely does not cause any errors.
  1. The project's `.gitlab-ci.yml` file is changed to remove the merge request pipelines configuration.
  1. The branch is rebased to bring the updated configuration into the merge request.
  1. Now the pipeline configuration no longer supports merge request pipelines,
     but you select **Run pipeline** to run a merge request pipeline.

If **Run pipeline** is available, but the project does not have merge request pipelines
enabled, do not use this option. You can push a commit or rebase the branch to trigger
new branch pipelines.
