---
stage: Create
group: Code Review
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Keep-around ref usage guidelines
---

## What are keep-around refs

Keep-around refs protect specific commits from the Git garbage collection process. While Git GC
normally removes unreferenced commits (those not reachable through branches or tags), there are cases
where preserving these orphaned commits is essential - such as maintaining commit comments and CI build
history. By creating a keep-around ref, we ensure these commits remain in the repository even when
they're no longer part of the active branch history.

For more information about developing with Git references on Gitaly, see
[Git references used by Gitaly](../gitaly.md#git-references-used-by-gitaly).

## Downsides of keep-around refs

Keeping the orphaned commits using keep-around refs comes with its own set of challenges.

- Its growth is untenable (`gitlab-org/gitlab` has about 1.2 GB of refs)
- The actual usage of these keep-around refs is spread across so it's hard to know exactly where
  these keep-around refs are expected to exist
- It's time consuming to check the needs of keep-around refs as we need to consider all possible places
  they could be referenced
- We could be keeping more commits than necessary because the ancestors of already preserved commits
  don't have to be kept around, but it's hard to verify that and clean up efficiently

{{< alert type="warning" >}}

Due to the downsides mentioned above, we should not be adding more places where we create keep-around
refs. Instead consider alternative options such as scoped refs
(like `refs/merge-requests/<merge-request-iid>/head`) or avoid creating these refs altogether if at all possible.

{{< /alert >}}

## Usage

Following is a typical way to create a keep-around ref for the given commit SHA.

```ruby
project.repository.keep_around(sha, source: self.class.name)
```

This command creates a ref called `refs/keep-around/<SHA>` where <SHA> is the commit SHA that is being
kept around. This prevents the commit SHA and all parent commits from being garbage collected as
we now have a ref that points to the commit directly. `source` is used as a way for us to attribute
the keep-around ref creations to specific classes.

## Where keep-around refs are currently created

Here are the places where we currently create keep-around refs.

- `MergeRequest#keep_around_commit(merge_commit_sha)` with the `after_save` callback
- `MergeRequestDiff#keep_around_commits(start_commit_sha, head_commit_sha)` for both target and
  source projects with the `after_create` callback
- `Note#keep_around_commit(commit_id)` with the `after_save` callback
- `DraftNotes::PublishService#keep_around_commits(shas)` as it publishes draft notes in bulk and `shas`
  are from both `original_potion` and `position`
- `DiffNote#Keep_around_commits(sha)` similar to above, but just for a single `DiffNote` with the `after_save`
  callback if it was not skipped for bulk insert
- `Ci::Pipeline#keep_around_commits(sha, before_sha)` with the `after_create` callback

## Future work

Due to the uncontrolled growth of keep-around refs and lack of visibility,
[Keep Around Refs Working Group](https://handbook.gitlab.com/handbook/company/working-groups/keep-around-refs/)
is currently working to:

- Reduce the number of existing keep-around refs
- Improve visibility into how and where keep-around refs are used
- Develop alternative solutions with better scalability

We should avoid creating more keep-around refs whenever possible and look for alternative solutions.

`gitlab::keep_around::orphaned` Rake task has been created to help us to identify orphaned keep-around refs.
