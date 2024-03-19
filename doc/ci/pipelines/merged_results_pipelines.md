---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Merged results pipelines

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/351192) from `pipelines for merged results` to `merged results pipelines` in GitLab 14.8.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91849) in GitLab 15.1, merged results pipelines also run on [Draft merge requests](../../user/project/merge_requests/drafts.md).

A merged results pipeline runs on the result of the source and target branches merged together.
It is a type of [merge request pipeline](merge_request_pipelines.md).

GitLab creates an internal commit with the merged results, so the pipeline can run
against it. This commit does not exist in either branch,
but you can view it in the pipeline details. The author of the internal commit is
always the user that created the merge request.

The pipeline runs against the target branch as it exists at the moment you run the pipeline.
Over time, while you're working in the source branch, the target branch might change.
Any time you want to be sure the merged results are accurate, you should re-run the pipeline.

Merged results pipelines can't run when the target branch has changes that conflict with the changes in the source branch.
In these cases, the pipeline runs as a [merge request pipeline](merge_request_pipelines.md)
and is labeled as `merge request`.

## Prerequisites

To use merged results pipelines:

- Your project's [`.gitlab-ci.yml` file](../index.md#the-gitlab-ciyml-file) must be configured to
  [run jobs in merge request pipelines](merge_request_pipelines.md#prerequisites).
- Your repository must be a GitLab repository, not an
  [external repository](../ci_cd_for_external_repos/index.md).

## Enable merged results pipelines

To enable merged results pipelines in a project, you must have at least the
Maintainer role:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **Merge options** section, select **Enable merged results pipelines**.
1. Select **Save changes**.

WARNING:
If you select the checkbox but don't configure your pipeline to use
merge request pipelines, your merge requests may become stuck in an
unresolved state or your pipelines may be dropped.

## Troubleshooting

### Merged results pipelines are not created

In GitLab 13.7 and earlier, merged results pipelines might not be created due
to a disabled [feature flag](../../user/feature_flags.md). This feature flag
[was removed](https://gitlab.com/gitlab-org/gitlab/-/issues/299115) in GitLab 13.8.
Upgrade to 13.8 or later, or make sure the `:merge_ref_auto_sync`
[feature flag is enabled](../../administration/feature_flags.md#check-if-a-feature-flag-is-enabled)
on your GitLab instance.

### Successful merged results pipeline overrides a failed branch pipeline

A failed branch pipeline is sometimes ignored when the
[**Pipelines must succeed** setting](../../user/project/merge_requests/merge_when_pipeline_succeeds.md#require-a-successful-pipeline-for-merge)
is activated.
[Issue 385841](https://gitlab.com/gitlab-org/gitlab/-/issues/385841) is open to track this.
