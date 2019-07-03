---
type: reference
last_update: 2019-07-03
---

# Pipelines for Merged Results **[PREMIUM]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/7380) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.10.
> This feature is disabled by default until we resolve issues with [contention handling](https://gitlab.com/gitlab-org/gitlab-ee/issues/11222), but [can be enabled manually](#enabling-pipelines-for-merged-results).

It's possible for your source and target branches to diverge, which can result
in the scenario that source branch's pipeline was green, the target's pipeline was green,
but the combined output fails.

By having your merge request pipeline automatically
create a new ref that contains the merge result of the source and target branch
(then running a pipeline on that ref), we can better test that the combined result
is also valid.

GitLab can run pipelines for merge requests
on this merged result. That is, where the source and target branches are combined into a
new ref and a pipeline for this ref validates the result prior to merging.

![Merge request pipeline as the head pipeline](img/merge_request_pipeline.png)

There are some cases where creating a combined ref is not possible or not wanted.
For example, a source branch that has conflicts with the target branch
or a merge request that is still in WIP status. In this case, the merge request pipeline falls back to a "detached" state
and runs on the source branch ref as if it was a regular pipeline.

The detached state serves to warn you that you are working in a situation
subjected to merge problems, and helps to highlight that you should
get out of WIP status or resolve merge conflicts as soon as possible.

## Requirements and limitations

Pipelines for merged results require:

- [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner) 11.9 or newer.
- [Gitaly](https://gitlab.com/gitlab-org/gitaly) 1.21.0 or newer.

In addition, pipelines for merged results have the following limitations:

- Forking/cross-repo workflows are not currently supported. To follow progress,
  see [#9713](https://gitlab.com/gitlab-org/gitlab-ee/issues/9713).
- This feature is not available for
  [fast forward merges](../../../user/project/merge_requests/fast_forward_merge.md) yet.
  To follow progress, see [#58226](https://gitlab.com/gitlab-org/gitlab-ce/issues/58226).

## Enabling Pipelines for Merged Results

To enable pipelines on merged results at the project level:

1. Visit your project's **Settings > General** and expand **Merge requests**.
1. Check **Merge pipelines will try to validate the post-merge result prior to merging**.
1. Click **Save changes** button.

![Merge request pipeline config](img/merge_request_pipeline_config.png)

CAUTION: **Warning:**
Make sure your `gitlab-ci.yml` file is [configured properly for pipelines for merge requests](../index.md#configuring-pipelines-for-merge-requests),
otherwise pipelines for merged results won't run and your merge requests will be stuck in an unresolved state.

## Merge Trains **[PREMIUM]**

Read the [documentation on Merge Trains](merge_trains/index.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
