---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Merge trains
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [In GitLab 16.0 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/359057), the **Start merge train** and **Start merge train when pipeline succeeds** buttons became **Set to auto-merge**. **Remove from merge train** became **Cancel auto-merge**.
> - Support for [fast-forward](../../user/project/merge_requests/methods/_index.md#fast-forward-merge) and [semi-linear](../../user/project/merge_requests/methods/_index.md#merge-commit-with-semi-linear-history) merge methods [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/282442) in GitLab 16.5 [with a flag](../../administration/feature_flags.md) named `fast_forward_merge_trains_support`. Enabled by default.
> - [Feature flag `fast_forward_merge_trains_support` removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148964#note_1855981445) in GitLab 16.11.

In projects with frequent merges to the default branch, changes in different merge requests
might conflict with each other. Use merge trains to put merge requests in a queue.
Each merge request is compared to the other, earlier merge requests, to ensure they all work together.

For more information about:

- How merge trains work, review the [merge train workflow](#merge-train-workflow).
- Why you might want to use merge trains, read [How starting merge trains improve efficiency for DevOps](https://about.gitlab.com/blog/2020/01/30/all-aboard-merge-trains/).

## Merge train workflow

A merge train starts when there are no merge requests waiting to merge and you
select [**Merge** or **Set to auto-merge**](#start-a-merge-train). GitLab starts a merge
train pipeline that verifies that the changes can merge into the default branch.
This first pipeline is the same as a [merged results pipeline](merged_results_pipelines.md),
which runs on the changes of the source and target branches combined together.
The author of the internal merged result commit is the user that initiated the
merge.

To queue a second merge request to merge immediately after the first pipeline
completes, select [**Merge** or **Set to auto-merge**](#add-a-merge-request-to-a-merge-train)
to add it to the train. This second merge train pipeline runs on the changes of
_both_ merge requests combined with the target branch. Similarly, if you add a
third merge request, that pipeline runs on the changes of all three merge
requests merged with the target branch. The pipelines all run in parallel.

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
- The pipeline for `C` [is canceled](#automatic-pipeline-cancellation), and a new pipeline
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
are canceled.

## Enable merge trains

> - `disable_merge_trains` feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/282477) in GitLab 16.5.

Prerequisites:

- You must have the Maintainer role.
- Your repository must be a GitLab repository, not an [external repository](../ci_cd_for_external_repos/_index.md).
- Your pipeline must be [configured to use merge request pipelines](merge_request_pipelines.md#prerequisites).
  Otherwise your merge requests may become stuck in an unresolved state or your pipelines
  might be dropped.
- You must have [merged results pipelines enabled](merged_results_pipelines.md#enable-merged-results-pipelines).

To enable merge trains:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In GitLab 16.4 and earlier, in the **Merge method** section, verify that **Merge commit** is selected.
   In GitLab 16.5 and later, you can use any merge method.
1. In the **Merge options** section, ensure **Enable merged results pipelines** is enabled
   and select **Enable merge trains**.
1. Select **Save changes**.

## Start a merge train

Prerequisites:

- You must have [permissions](../../user/permissions.md) to merge or push to the target branch.

To start a merge train:

1. Go to a merge request.
1. Select:
   - When no pipeline is running, **Merge**.
   - When a pipeline is running, [**Set to auto-merge**](../../user/project/merge_requests/auto_merge.md).

The merge request's merge train status displays under the pipeline widget with a
message similar to `A new merge train has started and this merge request is the first of the queue. View merge train details.`
You can select the link to view the merge train.

Other merge requests can now be added to the train.

## View a merge train

> - Merge train visualization [introduced](https://gitlab.com/groups/gitlab-org/-/epics/13705) in GitLab 17.3.

You can view the merge train to gain better insight into the order and status of merge requests in the queue.
The merge train details page shows active merge requests in the queue and merged merge requests that were part of the train.

To access the merge train details from the list of merge requests:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. Above the list of merge requests, select **Merge trains**.
1. Optional. Filter the merge trains by target branch.

You also access this view by selecting **View merge train details** from:

- The pipeline widget and system notes on a merge request added to a merge train.
- The pipeline details page for a merge train pipeline.

You can also remove (**{close}**) a merge request from the merge train details view.

## Add a merge request to a merge train

> - Auto-merge for merge trains [introduced](https://gitlab.com/groups/gitlab-org/-/epics/10874) in GitLab 17.2 [with a flag](../../administration/feature_flags.md) named `merge_when_checks_pass_merge_train`. Disabled by default.
> - Auto-merge for merge trains [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/470667) on GitLab.com in GitLab 17.2.
> - Auto-merge for merge trains [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/470667) by default in GitLab 17.4.
> - Auto-merge for merge trains [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174357) in GitLab 17.7. Feature flag `merge_when_checks_pass_merge_train` removed.

Prerequisites:

- You must have [permissions](../../user/permissions.md) to merge or push to the target branch.

To add a merge request to a merge train:

1. Visit a merge request.
1. Select:
   - When no pipeline is running, **Merge**.
   - When a pipeline is running, [**Set to auto-merge**](../../user/project/merge_requests/auto_merge.md).

The merge request's merge train status displays under the pipeline widget with a
message similar to `This merge request is 2 of 3 in queue.`

Each merge train can run a maximum of twenty pipelines in parallel. If you add more than
twenty merge requests to the merge train, the extra merge requests are queued, waiting
for pipelines to complete. There is no limit to the number of queued merge requests
waiting to join the merge train.

## Remove a merge request from a merge train

When you remove a merge request from a merge train:

- All pipelines for merge requests queued after the removed merge request restart.
- Redundant pipelines [are canceled](#automatic-pipeline-cancellation).

You can add the merge request to a merge train again later.

To remove a merge request from a merge train:

- From a merge request, select **Cancel auto-merge**.
- From the [merge train details](#view-a-merge-train), next to the merge request, select **{close}**.

## Skip the merge train and merge immediately

If you have a high-priority merge request, like a critical patch that must
be merged urgently, you can select **Merge immediately**.

When you merge a merge request immediately:

- The commits from the merge request are merged, ignoring the status of the merge train.
- The merge train pipelines for all other merge requests on the train [are canceled](#automatic-pipeline-cancellation).
- A new merge train starts and all the merge requests from the original merge train are added to this new merge train,
  with a new merge train pipeline for each. These new merge train pipelines now contain
  the commits added by the merge request that was merged immediately.

WARNING:
Merging immediately can use a lot of CI/CD resources. Use this option
only in critical situations.

NOTE:
The **merge immediately** option may not be available if your project uses the [fast-forward](../../user/project/merge_requests/methods/_index.md#fast-forward-merge)
merge method and the source branch is behind the target branch. See [issue 434070](https://gitlab.com/gitlab-org/gitlab/-/issues/434070) for more details.

### Allow merge trains to be skipped to merge immediately without restarting merge train pipelines

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414505) in GitLab 16.5 [with a flag](../../administration/feature_flags.md) named `merge_trains_skip_train`. Disabled by default.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/422111) as an [experiment feature](../../policy/development_stages_support.md) in GitLab 16.10.

FLAG:
On GitLab Self-Managed, by default this feature is available. To hide the feature,
an administrator can [disable the feature flag](../../administration/feature_flags.md)
named `merge_trains_skip_train`. On GitLab.com and GitLab Dedicated, this feature is available.

You can allow merge requests to be merged without completely restarting a running merge train.
Use this feature to quickly merge changes that can safely skip the pipeline, for example
minor documentation updates.

You cannot skip merge trains for fast-forward or semi-linear merge methods. For more information, see [issue 429009](https://gitlab.com/gitlab-org/gitlab/-/issues/429009).

Skipping merge trains is an experimental feature. It may change or be removed completely in future releases.

WARNING:
You can use this feature to quickly merge security or bug fixes, but the changes
in the merge request that skipped the train are not verified against
any of the other merge requests in the train. If these other merge train pipelines
complete successfully and merge, there is a risk that the combined changes are incompatible.
The target branch could then require additional work to resolve the new failures.

Prerequisites:

- You must have the Maintainer role.
- You must have [Merge trains enabled](#enable-merge-trains).

To enable skipping the train without pipeline restarts:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **Merge options** section, ensure the **Enable merged results pipelines**
   and **Enable merge trains** options are enabled.
1. Select **Allow skipping the merge train**.
1. Select **Save changes**.

To merge a merge request by skipping the merge train, use the [merge requests merge API endpoint](../../api/merge_requests.md#merge-a-merge-request)
to merge with the attribute `skip_merge_train` set to `true`.

The merge request merges, and the existing merge train pipelines are not canceled
or restarted.

## Troubleshooting

### Merge request dropped from the merge train

If a merge request becomes unmergeable while a merge train pipeline is running,
the merge train drops your merge request automatically. For example, this could be caused by:

- Changing the merge request to a [draft](../../user/project/merge_requests/drafts.md).
- A merge conflict.
- A new conversation thread that is unresolved, when [all threads must be resolved](../../user/project/merge_requests/_index.md#prevent-merge-unless-all-threads-are-resolved)
  is enabled.

You can find reason the merge request was dropped from the merge train in the system
notes. Check the **Activity** section in the **Overview** tab for a message similar to:
`User removed this merge request from the merge train because ...`

### Cannot use auto-merge

You cannot use [auto-merge](../../user/project/merge_requests/auto_merge.md)
(formerly **Merge when pipeline succeeds**) to skip the merge train, when merge trains are enabled.
See [issue 12267](https://gitlab.com/gitlab-org/gitlab/-/issues/12267) for more information.

### Cannot retry merge train pipeline

When a merge train pipeline fails, the merge request is dropped from the train and the pipeline can't be retried after it fails.
Merge train pipelines run on the merged result of the changes in the merge request and
changes from other merge requests already on the train. If the merge request is dropped from the train,
the merged result is out of date and the pipeline can't be retried.

You can:

- [Add the merge request to the train](#add-a-merge-request-to-a-merge-train) again,
  which triggers a new pipeline.
- Add the [`retry`](../yaml/_index.md#retry) keyword to the job if it fails intermittently.
  If it succeeds after a retry, the merge request is not removed from the merge train.

### Cannot add a merge request to the merge train

When [**Pipelines must succeed**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)
is enabled, but the latest pipeline failed:

- The **Set to auto-merge** or **Merge** options are not available.
- The merge request displays `The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure.`

Before you can re-add a merge request to a merge train, you can try to:

- Retry the failed job. If it passes, and no other jobs failed, the pipeline is marked as successful.
- Rerun the whole pipeline. On the **Pipelines** tab, select **Run pipeline**.
- Push a new commit that fixes the issue, which also triggers a new pipeline.

See [the related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/35135)
for more information.
