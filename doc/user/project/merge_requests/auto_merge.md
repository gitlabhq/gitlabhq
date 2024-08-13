---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Set auto-merge on a merge request when you have reviewed its content, so it can merge without intervention when all merge checks pass."
---

# Auto-merge

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - **Merge when pipeline succeeds** and **Add to merge train when pipeline succeeds** [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/409530) to **Auto-merge** in GitLab 16.0 [with a flag](../../../administration/feature_flags.md) named `auto_merge_labels_mr_widget`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120922) in GitLab 16.0. Feature flag `auto_merge_labels_mr_widget` removed.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10874) in GitLab 16.5 [with two flags](../../../administration/feature_flags.md) named `merge_when_checks_pass` and `additional_merge_when_checks_ready`. Disabled by default.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/412995) the flags `merge_when_checks_pass` and `additional_merge_when_checks_ready` on GitLab.com in GitLab 17.0.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

When you enable the `merge_when_checks_pass` feature flag, if the content of a merge request is ready to merge,
you can select **Set to auto-merge**. The merge request auto-merges when all required checks complete successfully, and you don't need to remember to manually merge the merge request.

After you set auto-merge, these checks must all pass before the merge request merges:

- All required approvals must be given.
- No other merge requests block this merge request.
- No merge conflicts exist.
- A CI/CD pipeline must complete successfully, regardless of the [project setting](#require-a-successful-pipeline-for-merge).
- All discussions are resolved.
- The merge request is not a **Draft**.
- All external status checks have passed.
- The merge request must be open.
- No denied policies exist.
- If your project
  [requires merge requests to reference a Jira issue](../../../integration/jira/issues.md#require-associated-jira-issue-for-merge-requests-to-be-merged),
  the merge request title or description contains a Jira issue link.

For a full list of checks and their API equivalents, see
[Merge status](../../../api/merge_requests.md#merge-status).

![Auto-merge is ready](img/auto_merge_ready_v16_0.png)

## Auto-merge a merge request

Prerequisites:

- You must have at least the Developer role in the project.
- If your project configuration requires it, all threads in the
  merge request [must be resolved](index.md#resolve-a-thread).
- The merge request must have received all required approvals.
- Merge trains are not supported. For more information,
  see [issue 443395](https://gitlab.com/gitlab-org/gitlab/-/issues/443395).

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

Commenting on a merge request after you select **Auto-merge**,
but before the pipeline completes, blocks the merge until you
resolve all existing threads.

### Auto-merge when using merge trains

> - Auto-merge for merge trains [introduced](https://gitlab.com/groups/gitlab-org/-/epics/10874) in GitLab 17.2 [with a flag](../../../administration/feature_flags.md) named `merge_when_checks_pass_merge_train`. Disabled by default.
> - Auto-merge for merge trains [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/470667) on GitLab.com in GitLab 17.2.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

If your project uses [merge trains](../../../ci/pipelines/merge_trains.md), you can
use the auto-merge feature after you enable these two feature flags:

- `merge_when_checks_pass`
- `merge_when_checks_pass_merge_train`

After you enable both feature flags, selecting **Set to auto-merge** on a merge request
adds it to the merge train after all checks pass.

## Pipeline success for auto-merge

If the pipeline succeeds, the merge request merges. If the pipeline fails, the author
can either retry any failed jobs, or push new commits to fix the failure:

- If a retried job succeeds on the second try, the merge request merges.
- If you add new commits to the merge request, GitLab cancels the request
  to ensure the new changes receive a review before merge.
- If you add new commits to the _target_ branch of the merge request, and your project
  allows only fast-forward merge requests, GitLab cancels the request to prevent merge conflicts.

For stricter control on pipeline status, you can also
[require a successful pipeline](#require-a-successful-pipeline-for-merge) before merge.

## Cancel an auto-merge

You can cancel auto-merge on a merge request.

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

- Ensure your project's CI/CD configuration runs a pipeline for every merge request.
- You must have at least the Maintainer role in the project.

To enable this setting:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. Scroll to **Merge checks**, and select **Pipelines must succeed**.
   This setting also prevents merge requests from merging if there is no pipeline,
   which can [conflict with some rules](#merge-request-cant-merge-despite-no-failed-pipeline).
1. Select **Save**.

If [multiple pipeline types run for the same merge request](#merge-request-can-still-be-merged-despite-a-failed-pipeline),
merge request pipelines take precedence over other pipeline types. For example,
an older but successful merge request pipeline allows a merge request to merge,
despite a newer but failed branch pipeline.

### Allow merge after skipped pipelines

When you set **Pipelines must succeed** for a project,
[skipped pipelines](../../../ci/pipelines/index.md#skip-a-pipeline) prevent
merge requests from merging.

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

### Merge request can't merge despite no failed pipeline

In some cases, you can [require a successful pipeline for merge](#require-a-successful-pipeline-for-merge),
but be unable to merge a merge request with no failed pipelines. The setting requires
the existence of a successful pipeline, not the absence of failed pipelines. A merge request
with no pipelines at all is not considered to have a successful pipeline, and cannot merge.

When you enable this setting, use [`rules`](../../../ci/yaml/index.md#rules)
or [`workflow:rules`](../../../ci/yaml/index.md#workflowrules) to ensure pipelines
run for every merge request.

### Merge request can still be merged despite a failed pipeline

In some cases, you can [require a successful pipeline for merge](#require-a-successful-pipeline-for-merge),
but still merge a merge request with a failed pipeline.

Merge request pipelines have the highest priority for the **Pipelines must succeed** setting.
If multiple pipeline types run for the same merge request, GitLab checks only the
merge request pipelines for success.

Merge requests can have multiple pipelines if:

- A [`rules`](../../../ci/yaml/index.md#rules) configuration that causes [duplicate pipelines](../../../ci/jobs/job_rules.md#avoid-duplicate-pipelines):
  one merge request pipeline and one branch pipeline. In this case, the status of the
  latest _merge request_ pipeline determines if a merge request can merge, not the branch pipeline.
- Pipelines triggered by external tools that target the same branch as the merge request.

In all cases, update your CI/CD configuration to prevent multiple pipeline types for the same merge request.
