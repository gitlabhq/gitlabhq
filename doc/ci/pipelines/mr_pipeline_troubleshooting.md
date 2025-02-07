---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Merge request pipeline troubleshooting
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When working with merge request pipelines, you might encounter the following issues.

## Two pipelines when pushing to a branch

If you get duplicate pipelines in merge requests, your pipeline might be configured
to run for both branches and merge requests at the same time. Adjust your pipeline
configuration to [avoid duplicate pipelines](../jobs/job_rules.md#avoid-duplicate-pipelines).

You can add `workflow:rules` to [switch from branch pipelines to merge request pipelines](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines).
After a merge request is open on the branch, the pipeline switches to a merge request pipeline.

## Two pipelines when pushing an invalid CI/CD configuration file

If you push an invalid CI/CD configuration to a merge request's branch, two failed
pipelines appear in the pipelines tab. One pipeline is a failed branch pipeline,
the other is a failed merge request pipeline.

When the configuration syntax is fixed, no further failed pipelines should appear.
To find and fix the configuration problem, you can use:

- The [pipeline editor](../pipeline_editor/_index.md).
- The [CI lint tool](../yaml/lint.md).

## The merge request's pipeline is marked as failed but the latest pipeline succeeded

It's possible to have both branch pipelines and merge request pipelines in the
**Pipelines** tab of a single merge request. This might be [by configuration](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines),
or [by accident](#two-pipelines-when-pushing-to-a-branch).

When the project has [**Pipelines must succeed**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) enabled
and both pipelines types are present, the merge request pipelines are checked,
not the branch pipelines.

Therefore, the MR pipeline result is marked as unsuccessful if the
**merge request pipeline** fails, independently of the **branch pipeline** result.

However:

- These conditions are not enforced.
- A race condition determines which pipeline's result is used to either block or pass merge requests.

This bug is tracked on [issue 384927](https://gitlab.com/gitlab-org/gitlab/-/issues/384927).

## `An error occurred while trying to run a new pipeline for this merge request.`

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

## `Merge blocked: pipeline must succeed. Push a new commit that fixes the failure` message

This message is shown if the merge request pipeline, [merged results pipeline](merged_results_pipelines.md),
or [merge train pipeline](merge_trains.md) has failed or been canceled.
This does not happen when a branch pipeline fails.

If a merge request pipeline or a merged results pipeline was canceled or failed, you can:

- Re-run the entire pipeline by selecting **Run pipeline** in the pipeline tab in the merge request.
- [Retry only the jobs that failed](_index.md#view-pipelines). If you re-run the entire pipeline, this is not necessary.
- Push a new commit to fix the failure.

If the merge train pipeline has failed, you can:

- Check the failure and determine if you can use the [`/merge` quick action](../../user/project/quick_actions.md) to immediately add the merge request to the train again.
- Re-run the entire pipeline by selecting **Run pipeline** in the pipeline tab in the merge request, then add the merge request to the train again.
- Push a commit to fix the failure, then add the merge request to the train again.

If the merge train pipeline was canceled before the merge request was merged, without a failure, you can:

- Add it to the train again.
