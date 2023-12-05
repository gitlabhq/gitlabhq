---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Auto-merge **(FREE ALL)**

> **Merge when pipeline succeeds** and **Add to merge train when pipeline succeeds** [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/409530) to **Auto-merge** in GitLab 16.0 [with a flag](../../../administration/feature_flags.md) named `auto_merge_labels_mr_widget`. Enabled by default.

If you review a merge request and it's ready to merge, but the pipeline hasn't
completed yet, you can set it to auto-merge. You don't
have to remember later to merge the work manually:

![Auto-merge is ready](img/auto_merge_ready_v16_0.png)

NOTE:
[In GitLab 16.0 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/359057), **Merge when pipeline succeeds** and **Add to merge train when pipeline succeeds** are renamed **Set to auto-merge**.

If the pipeline succeeds, the merge request is merged. If the pipeline fails, the
author can either retry any failed jobs, or push new commits to fix the failure:

- If a retried job succeeds on the second try, the merge request is merged.
- If new commits are added to the merge request, GitLab cancels the request
  to ensure the new changes are reviewed before merge.

## Auto-merge a merge request

Prerequisites:

- You must have at least the Developer role in the project.
- If the project is configured to require it, all threads in the
  merge request [must be resolved](index.md#resolve-a-thread).
- The merge request must have received all required approvals.

To do this when pushing from the command line, use the `merge_request.merge_when_pipeline_succeeds`
[push option](../push_options.md).

To do this from the GitLab user interface:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. Select the merge request to edit.
1. Scroll to the merge request reports section.
1. Optional. Select your desired merge options, such as **Delete source branch**,
   **Squash commits**, or **Edit commit message**.
1. Select **Auto-merge**.

If a new comment is added to the merge request after you select **Auto-merge**,
but before the pipeline completes, GitLab blocks the merge until you
resolve all existing threads.

## Cancel an auto-merge

If a merge request is set to auto-merge, you can cancel it.

Prerequisites:

- You must either be the author of the merge request, or a project member with
  at least the Developer role.
- The merge request's pipeline must still be in progress.

To do this:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. Select the merge request to edit.
1. Scroll to the merge request reports section.
1. Select **Cancel auto-merge**.

![Status](img/cancel-mwps_v15_4.png)

## Require a successful pipeline for merge

You can configure your project to require a complete and successful pipeline before
merge. This configuration works for both:

- GitLab CI/CD pipelines.
- Pipelines run from an [external CI integration](../integrations/index.md#available-integrations).

As a result, [disabling GitLab CI/CD pipelines](../../../ci/pipelines/settings.md#disable-gitlab-cicd-pipelines)
does not disable this feature, but you can use pipelines from external
CI providers with it.

Prerequisites:

- Ensure CI/CD is configured to run a pipeline for every merge request.
- You must have at least the Maintainer role in the project.

To enable this setting:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. Scroll to **Merge checks**, and select **Pipelines must succeed**.
   This setting also prevents merge requests from being merged if there is no pipeline,
   which can [conflict with some rules](#merge-request-cannot-be-merged-despite-no-failed-pipeline).
1. Select **Save**.

If [multiple pipeline types run for the same merge request](#merge-request-can-still-be-merged-despite-a-failed-pipeline),
merge request pipelines take precedence over other pipeline types. For example,
an older but successful merge request pipeline allows a merge request to be merged,
despite a newer but failed branch pipeline.

### Allow merge after skipped pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211482) in GitLab 13.1.

When the **Pipelines must succeed** checkbox is checked,
[skipped pipelines](../../../ci/pipelines/index.md#skip-a-pipeline) prevent
merge requests from being merged.

Prerequisites:

- You must have at least the Maintainer role in the project.

To change this behavior:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. Under **Merge checks**:
   - Select **Pipelines must succeed**.
   - Select **Skipped pipelines are considered successful**.
1. Select **Save**.

## Troubleshooting

### Merge request cannot be merged despite no failed pipeline

In some cases, you can [require a successful pipeline for merge](#require-a-successful-pipeline-for-merge),
but be unable to merge a merge request with no failed pipelines. The setting requires
the existence of a successful pipeline, not the absence of failed pipelines. If the merge request
has no pipelines at all, it is not considered to have a successful pipeline and cannot be merged.

When the setting is enabled, use [`rules`](../../../ci/yaml/index.md#rules) or [`workflow:rules`](../../../ci/yaml/index.md#workflowrules)
to ensure pipelines run for every merge request.

### Merge request can still be merged despite a failed pipeline

In some cases, you can [require a successful pipeline for merge](#require-a-successful-pipeline-for-merge),
but still merge a merge request with a failed pipeline.

Merge request pipelines have the highest priority for the **Pipelines must succeed** setting.
If multiple pipeline types run for the same merge request, only the merge request pipelines
are checked for success.

Multiple pipeline types in the same merge request can be caused by:

- A [`rules`](../../../ci/yaml/index.md#rules) configuration that causes [duplicate pipelines](../../../ci/jobs/job_control.md#avoid-duplicate-pipelines):
  one merge request pipeline and one branch pipeline. In this case, the status of the
  latest merge request pipeline determines if a merge request can be merged, not the branch pipeline.
- Pipelines triggered by external tools that target the same branch as the merge request.

In all cases, update your CI/CD configuration to prevent multiple pipeline types for the same merge request.
