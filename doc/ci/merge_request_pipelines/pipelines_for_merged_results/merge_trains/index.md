---
type: reference
last_update: 2019-07-03
---

# Merge Trains **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/9186) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.0.
> [Squash and merge](../../../../user/project/merge_requests/squash_and_merge.md) support [introduced](https://gitlab.com/gitlab-org/gitlab/issues/13001) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.6.

[Pipelines for merged results](../index.md#pipelines-for-merged-results-premium) introduces
running a build on the result of the merged code prior to merging, as a way to keep master green.

There's a scenario, however, for teams with a high number of changes in the target branch (typically master) where in many or even all cases,
by the time the merged code is validated another commit has made it to master, invalidating the merged result.
You'd need some kind of queuing, cancellation or retry mechanism for these scenarios
in order to ensure an orderly flow of changes into the target branch.

Each MR that joins a merge train joins as the last item in the train,
just as it works in the current state. However, instead of queuing and waiting,
each item takes the completed state of the previous (pending) merge ref, adds its own changes,
and starts the pipeline immediately in parallel under the assumption that everything is going to pass.

In this way, if all the pipelines in the train merge successfully, no pipeline time is wasted either queuing or retrying.
If the button is subsequently pressed in a different MR, instead of creating a new pipeline for the target branch,
it creates a new pipeline targeting the merge result of the previous MR plus the target branch.
Pipelines invalidated through failures are immediately canceled and requeued.

## Requirements and limitations

Merge trains have the following requirements and limitations:

- This feature requires that
  [pipelines for merged results](../index.md#pipelines-for-merged-results-premium) are
  **configured properly**.
- Each merge train can run a maximum of **twenty** pipelines in parallel.
  If more than twenty merge requests are added to the merge train, the merge requests
  will be queued until a slot in the merge train is free. There is no limit to the
  number of merge requests that can be queued.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch this video for a demonstration on [how parallel execution
of Merge Trains can prevent commits from breaking the default
branch](https://www.youtube.com/watch?v=D4qCqXgZkHQ).

## How to add a merge request to a merge train

To add a merge request to a merge train:

1. Visit a merge request.
1. Click the **Start/Add to merge train** button.

![Start merge train](img/merge_train_start_v12_0.png)

## How to remove a merge request from a merge train

1. Visit a merge request.
1. Click the **Remove from merge train** button.

![Cancel merge train](img/merge_train_cancel_v12_0.png)

## How to view a merge request's current position on the merge train

After a merge request has been added to the merge train, the merge request's
current position will be displayed under the pipeline widget:

![Merge train position indicator](img/merge_train_position_v12_0.png)

## Start/Add to merge train when pipeline succeeds

You can add a merge request to a merge train only when the latest pipeline in the
merge request finished. While the pipeline is running or pending, you cannot add
the merge request to a train because the current change of the merge request may
be broken thus it could affect the following merge requests.

In this case, you can schedule to add the merge request to a merge train **when the latest
pipeline succeeds** (This pipeline is [Pipelines for merged results](../index.md), not Pipelines for merge train).
You can see the following button instead of the regular **Start/Add to merge train**
button while the latest pipeline is running.

![Add to merge train when pipeline succeeds](img/merge_train_start_when_pipeline_succeeds_v12_0.png)

## Immediately merge a merge request with a merge train

In case, you have a high-priority merge request (e.g. critical patch) to be merged urgently,
you can use **Merge Immediately** option for bypassing the merge train.
This is the fastest option to get the change merged into the target branch.

![Merge Immediately](img/merge_train_immediate_merge_v12_6.png)

However, every time you merge a merge request immediately, it could affect the
existing merge train to be reconstructed, specifically, it regenerates expected
merge commits and pipelines. This means, merging immediately essentially wastes
CI resources. Because of these downsides, you will be asked to confirm before
the merge is initiated:

![Merge immediately confirmation dialog](img/merge_train_immediate_merge_confirmation_dialog_v12_6.png)

## Troubleshooting

### Merge request dropped from the merge train immediately

If a merge request is not mergeable (for example, it's WIP, there is a merge
conflict, etc), your merge request will be dropped from the merge train automatically.

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

[Merge When Pipeline Succeeds](../../../../user/project/merge_requests/merge_when_pipeline_succeeds.md)
is unavailable when
[Pipelines for Merged Results is enabled](../index.md#enabling-pipelines-for-merged-results).

Follow [this issue](https://gitlab.com/gitlab-org/gitlab/issues/12267) to
track progress on this issue.

### Merge Train Pipeline cannot be retried

A Merge Train pipeline cannot be retried because the merge request is dropped from the merge train upon failure. For this reason, the retry button does not appear next to the pipeline icon.

In the case of pipeline failure, you should [re-enqueue](#how-to-add-a-merge-request-to-a-merge-train) the merge request to the merge train, which will then initiate a new pipeline.

### Merge Train disturbs your workflow

First of all, please check if [merge immediately](#immediately-merge-a-merge-request-with-a-merge-train)
is available as a workaround in your workflow. This is the most recommended
workaround you'd be able to take immediately. If it's not available or acceptable,
please read through this section.

Merge train is enabled by default when you enable [Pipelines for merged results](../index.md),
however, you can forcibly disable this feature by disabling the feature flag `:merge_trains_enabled`.
After you disabled this feature, all the existing merge trains will be aborted and
you will no longer see the **Start/Add Merge Train** button in merge requests.

To check if the feature flag is enabled on your GitLab instance,
please ask administrator to execute the following commands:

```shell
> sudo gitlab-rails console                         # Login to Rails console of GitLab instance.
> Feature.enabled?(:merge_trains_enabled)           # Check if it's enabled or not.
> Feature.disable(:merge_trains_enabled)            # Disable the feature flag.
```
