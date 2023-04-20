---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Merge trains **(PREMIUM)**

FLAG:
In GitLab 15.11 and later, the **Start merge train** button is **Set to auto-merge** and the **Add to merge train** button is **Merge**. On self-managed GitLab, by default these changes are not available. To make them available,
ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `auto_merge_labels_mr_widget`. On GitLab.com, this feature is not available.

Use merge trains to queue merge requests and verify their changes work together before
they are merged to the target branch.

In projects with frequent merges to the default branch, changes in different merge requests
might conflict with each other. [Merged results pipelines](merged_results_pipelines.md)
ensure the changes work with the content in the default branch, but not content
that others are merging at the same time.

Merge trains do not work with [Semi-linear history merge requests](../../user/project/merge_requests/methods/index.md#merge-commit-with-semi-linear-history)
or [fast-forward merge requests](../../user/project/merge_requests/methods/index.md#fast-forward-merge).

For more information about:

- How merge trains work, review the [merge train workflow](#merge-train-workflow).
- Why you might want to use merge trains, read [How starting merge trains improve efficiency for DevOps](https://about.gitlab.com/blog/2020/01/30/all-aboard-merge-trains/).

## Merge train workflow

A merge train starts when there are no merge requests waiting to merge and you
select [**Start merge train**](#start-a-merge-train). GitLab starts a merge train pipeline
that verifies that the changes can merge into the default branch. This first pipeline
is the same as a [merged results pipeline](merged_results_pipelines.md), which runs on
the changes of the source and target branches combined together. The author of the
internal merged result commit is the user that initiated the merge.

To queue a second merge request to merge immediately after the first pipeline completes, select
[**Add to merge train**](#add-a-merge-request-to-a-merge-train) and add it to the train.
This second merge train pipeline runs on the changes of _both_ merge requests combined with the
target branch. Similarly, if you add a third merge request, that pipeline runs on the changes
of all three merge requests merged with the target branch. The pipelines all run in parallel.

Each merge request merges into the target branch only after:

- The merge request's pipeline completes successfully.
- All other merge requests queued before it are merged.

If a merge train pipeline fails, the merge request is not merged. GitLab
removes that merge request from the merge train, and starts new pipelines for all
the merge requests that were queued after it.

For example:

Three merge requests (`A`, `B`, and `C`) are added to a merge train in order, which
creates three merged results pipelines that run in parallel:

1. The first pipeline runs on the changes from `A` combined with the target branch.
1. The second pipeline runs on the changes from `A` and `B` combined with the target branch.
1. The third pipeline runs on the changes from `A`, `B`, and `C` combined with the target branch.

If the pipeline for `B` fails:

- The first pipeline (`A`) continues to run.
- `B` is removed from the train.
- The pipeline for `C` [is cancelled](#automatic-pipeline-cancellation), and a new pipeline
  starts for the changes from `A` and `C` combined with the target branch (without the `B` changes).

If `A` then completes successfully, it merges into the target branch, and `C` continues
to run. Any new merge requests added to the train include the `A` changes now in
the target branch, and the `C` changes from the merge train.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch this video for a demonstration on [how parallel execution of merge trains can prevent commits from breaking the default branch](https://www.youtube.com/watch?v=D4qCqXgZkHQ).

### Automatic pipeline cancellation

GitLab CI/CD detects redundant pipelines, and cancels them to conserve resources.

Redundant merge train pipelines happen when:

- The pipeline fails for one of the merge requests in the merge train.
- You [skip the merge train and merge immediately](#skip-the-merge-train-and-merge-immediately).
- You [remove a merge request from a merge train](#remove-a-merge-request-from-a-merge-train).

In these cases, GitLab must create new merge train pipelines for some or all of the
merge requests on the train. The old pipelines were comparing against the previous
combined changes in the merge train, which are no longer valid, so these old pipelines
are cancelled.

## Enable merge trains

Prerequisites:

- You must have the Maintainer role.
- Your repository must be a GitLab repository, not an [external repository](../ci_cd_for_external_repos/index.md).
- Your pipeline must be [configured to use merge request pipelines](merge_request_pipelines.md#prerequisites).
  Otherwise your merge requests may become stuck in an unresolved state or your pipelines
  might be dropped.

To enable merge trains:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Merge requests**.
1. In the **Merge method** section, verify that **Merge commit** is selected.
1. In the **Merge options** section:
   - In GitLab 13.6 and later, select **Enable merged results pipelines** and **Enable merge trains**.
   - In GitLab 13.5 and earlier, select **Enable merge trains and pipelines for merged results**.
     Additionally, [a feature flag](#disable-merge-trains-in-gitlab-135-and-earlier)
     must be set correctly.
1. Select **Save changes**.

## Start a merge train

Prerequisites:

- You must have [permissions](../../user/permissions.md) to merge or push to the target branch.

To start a merge train:

1. Visit a merge request.
1. Select:
   - When no pipeline is running, **Start merge train**.
   - When a pipeline is running, **Start merge train when pipeline succeeds**.

The merge request's merge train status displays under the pipeline widget with a
message similar to `A new merge train has started and this merge request is the first of the queue.`

Other merge requests can now be added to the train.

## Add a merge request to a merge train

Prerequisites:

- You must have [permissions](../../user/permissions.md) to merge or push to the target branch.

To add a merge request to a merge train:

1. Visit a merge request.
1. Select:
   - When no pipeline is running, **Add to merge train**.
   - When a pipeline is running, **Add to merge train when pipeline succeeds**.

The merge request's merge train status displays under the pipeline widget with a
message similar to `Added to the merge train. There are 2 merge requests waiting to be merged.`

Each merge train can run a maximum of twenty pipelines in parallel. If you add more than
twenty merge requests to the merge train, the extra merge requests are queued, waiting
for pipelines to complete. There is no limit to the number of queued merge requests
waiting to join the merge train.

## Remove a merge request from a merge train

To remove a merge request from a merge train, select **Remove from merge train**.
You can add the merge request to a merge train again later.

When you remove a merge request from a merge train:

- All pipelines for merge requests queued after the removed merge request restart.
- Redundant pipelines [are cancelled](#automatic-pipeline-cancellation).

## Skip the merge train and merge immediately

If you have a high-priority merge request, like a critical patch that must
be merged urgently, select **Merge Immediately**.

When you merge a merge request immediately:

- The current merge train is recreated.
- All pipelines restart.
- Redundant pipelines [are cancelled](#automatic-pipeline-cancellation).

WARNING:
Merging immediately can use a lot of CI/CD resources. Use this option
only in critical situations.

## Disable merge trains in GitLab 13.5 and earlier **(PREMIUM SELF)**

In [GitLab 13.6 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/244831),
you can [enable or disable merge trains in the project settings](#enable-merge-trains).

In GitLab 13.5 and earlier, merge trains are automatically enabled when
[merged results pipelines](merged_results_pipelines.md) are enabled.
To use merged results pipelines but not merge trains, enable the `disable_merge_trains`
[feature flag](../../user/feature_flags.md).

[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can enable the feature flag to disable merge trains:

```ruby
Feature.enable(:disable_merge_trains)
```

After you enable this feature flag, GitLab cancels existing merge trains and removes
the **Start/Add to merge train** option from merge requests.

To disable the feature flag, which enables merge trains again:

```ruby
Feature.disable(:disable_merge_trains)
```

## Troubleshooting

### Merge request dropped from the merge train

If a merge request becomes unmergeable while a merge train pipeline is running,
the merge train drops your merge request automatically. For example, this could be caused by:

- Changing the merge request to a [draft](../../user/project/merge_requests/drafts.md).
- A merge conflict.
- A new conversation thread that is unresolved, when [all threads must be resolved](../../user/discussions/index.md#prevent-merge-unless-all-threads-are-resolved)
  is enabled.

You can find reason the merge request was dropped from the merge train in the system
notes. Check the **Activity** section in the **Overview** tab for a message similar to:
`User removed this merge request from the merge train because ...`

### Cannot use merge when pipeline succeeds

You cannot use [merge when pipeline succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md)
when merge trains are enabled. See [the related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/12267)
for more information.

### Cannot retry merge train pipeline cannot

When a merge train pipeline fails, the merge request is dropped from the train and the pipeline can't be retried.
Merge train pipelines run on the merged result of the changes in the merge request and
changes from other merge requests already on the train. If the merge request is dropped from the train,
the merged result is out of date and the pipeline can't be retried.

You can:

- [Add the merge request to the train](#add-a-merge-request-to-a-merge-train) again,
  which triggers a new pipeline.
- Add the [`retry`](../yaml/index.md#retry) keyword to the job if it fails intermittently.
  If it succeeds after a retry, the merge request is not removed from the merge train.

### Unable to add to the merge train

When [**Pipelines must succeed**](../../user/project/merge_requests/merge_when_pipeline_succeeds.md#require-a-successful-pipeline-for-merge)
is enabled, but the latest pipeline failed:

- The **Start/Add to merge train** option is not available.
- The merge request displays `The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure.`

Before you can re-add a merge request to a merge train, you can try to:

- Retry the failed job. If it passes, and no other jobs failed, the pipeline is marked as successful.
- Rerun the whole pipeline. On the **Pipelines** tab, select **Run pipeline**.
- Push a new commit that fixes the issue, which also triggers a new pipeline.

See [the related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/35135)
for more information.
