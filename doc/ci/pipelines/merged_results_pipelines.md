---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use merged results pipelines to test code from source and target branches combined before merging.
title: Merged results pipelines
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Merged results pipelines test a temporary merged commit that combines code from
the source and target branches. This commit doesn't exist in either branch,
but you can view it in the pipeline details.

This approach helps verify changes work with the code in the latest target branch,
catch integration issues before merging, and ensure changes in different files work together.

Merged results pipelines can't run when the target branch has changes
that conflict with the changes in the source branch.
In these cases, GitLab runs a standard merge request pipeline instead.

## Enable merged results pipelines

Prerequisites:

- You must have the Maintainer or Owner role for the project.
- Your `.gitlab-ci.yml` file must be configured for [merge request pipelines](merge_request_pipelines.md#prerequisites).
- Your project must be hosted on GitLab (not an external repository like GitHub or Bitbucket).

To enable merged results pipelines in a project:

1. In the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **Merge requests**.
1. Under **Merge options**, select **Enable merged results pipelines**.
1. Select **Save changes**.

> [!warning]
> If you enable this setting without configuring merge request pipelines in your
> `.gitlab-ci.yml` file, your merge requests might become stuck in an unresolved state
> or your pipelines might be dropped.

## Troubleshooting

When working with merged results pipelines, you might encounter the following issues.

### Jobs or pipelines run unexpectedly with `rules:changes:compare_to`

You might have jobs or pipelines that run unexpectedly when using
`rules:changes:compare_to` with merge request pipelines.

This issue occurs because merged results pipelines use the temporary merged commit as the base
for comparison. This commit contains changes from both your merge request branch and the target branch,
which can cause rules to trigger unexpectedly.

For example, if your merge request adds `src/feature.js` and the target branch
contains `src/utils.js`, the temporary merged commit includes both files.
A rule with `rules:changes:compare_to: main` detects both changes, not just
your feature file, and may trigger jobs that should only run for your changes.

To resolve this issue:

- Remove the `compare_to` parameter to use the default comparison behavior.
- Use more specific file path patterns in your changes rules.
- Consider using `rules:changes` without `compare_to`.

### Successful merged results pipeline overrides a failed branch pipeline

You might encounter a situation where a failed branch pipeline is ignored when the
[**Pipelines must succeed** setting](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)
is activated.

This issue occurs due to the pipeline logic prioritization.
Support for improvements is proposed in [issue 385841](https://gitlab.com/gitlab-org/gitlab/-/issues/385841).
