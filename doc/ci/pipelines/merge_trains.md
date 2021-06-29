---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
last_update: 2019-07-03
---

# Merge Trains **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9186) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.0.
> - [Squash and merge](../../user/project/merge_requests/squash_and_merge.md) support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13001) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.6.

For more information about why you might want to use Merge Trains, read [How merge trains keep your master green](https://about.gitlab.com/blog/2020/01/30/all-aboard-merge-trains/).

When [pipelines for merged results](pipelines_for_merged_results.md) are
enabled, the pipeline jobs run as if the changes from your source branch have already
been merged into the target branch.

However, the target branch may be changing rapidly. When you're ready to merge,
if you haven't run the pipeline in a while, the target branch may have already changed.
Merging now could introduce breaking changes.

*Merge trains* can prevent this from happening. A merge train is a queued list of merge
requests, each waiting to be merged into the target branch.

Many merge requests can be added to the train. Each merge request runs its own merged results pipeline,
which includes the changes from all of the other merge requests in *front* of it on the train.
All the pipelines run in parallel, to save time.

If the pipeline for a merge request fails, the breaking changes are not merged, and the target
branch is unaffected. The merge request is removed from the train, and all pipelines behind it restart.

If the pipeline for the merge request at the front of the train completes successfully,
the changes are merged into the target branch, and the other pipelines continue to
run.

To add a merge request to a merge train, you need [permissions](../../user/permissions.md) to push to the target branch.

Each merge train can run a maximum of **twenty** pipelines in parallel.
If more than twenty merge requests are added to the merge train, the merge requests
are queued until a slot in the merge train is free. There is no limit to the
number of merge requests that can be queued.

## Merge train example

Three merge requests (`A`, `B` and `C`) are added to a merge train in order, which
creates three merged results pipelines that run in parallel:

1. The first pipeline runs on the changes from `A` combined with the target branch.
1. The second pipeline runs on the changes from `A` and `B` combined with the target branch.
1. The third pipeline runs on the changes from `A`, `B`, and `C` combined with the target branch.

If the pipeline for `B` fails, it is removed from the train. The pipeline for
`C` restarts with the `A` and `C` changes, but without the `B` changes.

If `A` then completes successfully, it merges into the target branch, and `C` continues
to run. If more merge requests are added to the train, they now include the `A`
changes that are included in the target branch, and the `C` changes that are from
the merge request already in the train.

Read more about [how merge trains keep your master green](https://about.gitlab.com/blog/2020/01/30/all-aboard-merge-trains/).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch this video for a demonstration on [how parallel execution
of Merge Trains can prevent commits from breaking the default
branch](https://www.youtube.com/watch?v=D4qCqXgZkHQ).

## Prerequisites

To enable merge trains:

- You must have the [Maintainer role](../../user/permissions.md).
- You must be using [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner) 11.9 or later.
- In GitLab 13.0 and later, you need [Redis](https://redis.io/) 5.0 or later.
- Your repository must be a GitLab repository, not an
  [external repository](../ci_cd_for_external_repos/index.md).

## Enable merge trains

To enable merge trains for your project:

1. If you are on a self-managed GitLab instance, ensure the [feature flag](#merge-trains-feature-flag) is set correctly.
1. [Configure your CI/CD configuration file](merge_request_pipelines.md#configure-pipelines-for-merge-requests)
   so that the pipeline or individual jobs run for merge requests.
1. Visit your project's **Settings > General** and expand **Merge requests**.
1. In the **Merge method** section, verify that **Merge commit** is selected.
   You cannot use **Merge commit with semi-linear history** or **Fast-forward merge** with merge trains.
1. In the **Merge options** section, select **Enable merged results pipelines.** (if not already selected) and **Enable merge trains.**
1. Click **Save changes**

In GitLab 13.5 and earlier, there is only one checkbox, named
**Enable merge trains and pipelines for merged results**.

WARNING:
If you select the check box but don't configure your CI/CD to use
pipelines for merge requests, your merge requests may become stuck in an
unresolved state or your pipelines may be dropped.

## Start a merge train

To start a merge train:

1. Visit a merge request.
1. Click the **Start merge train** button.

![Start merge train](img/merge_train_start_v12_0.png)

Other merge requests can now be added to the train.

## Add a merge request to a merge train

To add a merge request to a merge train:

1. Visit a merge request.
1. Click the **Add to merge train** button.

If pipelines are already running for the merge request, you cannot add the merge request
to the train. Instead, you can schedule to add the merge request to a merge train **when the latest
pipeline succeeds**.

![Add to merge train when pipeline succeeds](img/merge_train_start_when_pipeline_succeeds_v12_0.png)

## Remove a merge request from a merge train

1. Visit a merge request.
1. Click the **Remove from merge train** button.

![Cancel merge train](img/merge_train_cancel_v12_0.png)

If you want to add the merge request to a merge train again later, you can.

## View a merge request's current position on the merge train

After a merge request has been added to the merge train, the merge request's
current position is displayed under the pipeline widget:

![Merge train position indicator](img/merge_train_position_v12_0.png)

## Immediately merge a merge request with a merge train

If you have a high-priority merge request (for example, a critical patch) that must
be merged urgently, you can bypass the merge train by using the **Merge Immediately** option.
This is the fastest option to get the change merged into the target branch.

![Merge Immediately](img/merge_train_immediate_merge_v12_6.png)

WARNING:
Each time you merge a merge request immediately, the current merge train
is recreated and all pipelines restart.

## Troubleshooting

### Merge request dropped from the merge train immediately

If a merge request is not mergeable (for example, it's a draft merge request, there is a merge
conflict, etc.), your merge request is dropped from the merge train automatically.

In these cases, the reason for dropping the merge request is in the **system notes**.

To check the reason:

1. Open the merge request that was dropped from the merge train.
1. Open the **Discussion** tab.
1. Find a system note that includes either:
   - The text **... removed this merge request from the merge train because ...**
   - **... aborted this merge request from the merge train because ...**
   The reason is given in the text after the **because ...** phrase.

![Merge Train Failure](img/merge_train_failure.png)

### Merge When Pipeline Succeeds cannot be chosen

[Merge When Pipeline Succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md)
is currently unavailable when Merge Trains are enabled.

See [the related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/12267)
for more information.

### Merge Train Pipeline cannot be retried

When a pipeline for merge trains fails the merge request is dropped from the train and the pipeline can't be retried.
Pipelines for merge trains run on the merged result of the changes in the merge request and
the changes from other merge requests already on the train. If the merge request is dropped from the train,
the merged result is out of date and the pipeline can't be retried.

Instead, you should [add the merge request to the train](#add-a-merge-request-to-a-merge-train)
again, which triggers a new pipeline.

### Unable to add to merge train with message "The pipeline for this merge request failed."

Sometimes the **Start/Add to Merge Train** button is not available and the merge request says,
"The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure."

This issue occurs when [**Pipelines must succeed**](../../user/project/merge_requests/merge_when_pipeline_succeeds.md#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds)
is enabled in **Settings > General > Merge requests**. This option requires that you
run a new successful pipeline before you can re-add a merge request to a merge train.

Merge trains ensure that each pipeline has succeeded before a merge happens, so
you can clear the **Pipelines must succeed** check box and keep
**Enable merge trains and pipelines for merged results** (merge trains) enabled.

If you want to keep the **Pipelines must succeed** option enabled along with Merge
Trains, create a new pipeline for merged results when this error occurs:

1. Go to the **Pipelines** tab and click **Run pipeline**.
1. Click **Start/Add to merge train when pipeline succeeds**.

See [the related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/35135)
for more information.

### Merge Trains feature flag **(PREMIUM SELF)**

In [GitLab 13.6 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/244831),
you can [enable or disable merge trains in the project settings](#enable-merge-trains).

In GitLab 13.5 and earlier, merge trains are automatically enabled when
[pipelines for merged results](pipelines_for_merged_results.md) are enabled.
To use pipelines for merged results without using merge trains, you can enable a
[feature flag](../../user/feature_flags.md) that blocks the merge trains feature.

[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can enable the feature flag to disable merge trains:

```ruby
Feature.enable(:disable_merge_trains)
```

After you enable this feature flag, all existing merge trains are cancelled and
the **Start/Add to Merge Train** button no longer appears in merge requests.

To disable the feature flag, and enable merge trains again:

```ruby
Feature.disable(:disable_merge_trains)
```
