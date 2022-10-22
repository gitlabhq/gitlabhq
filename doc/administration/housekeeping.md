---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Housekeeping **(FREE SELF)**

GitLab supports and automates housekeeping tasks in Git repositories to ensure
that they can be served as efficiently as possible. Housekeeping tasks include:

- Compressing Git objects and revisions.
- Removing unreachable objects.
- Removing stale data like lock files.
- Maintaining data structures that improve performance.
- Updating object pools to improve object deduplication across forks.

WARNING:
Do not manually execute Git commands to perform housekeeping in Git
repositories that are controlled by GitLab. Doing so may lead to corrupt
repositories and data loss.

## Running housekeeping tasks

There are different ways in which GitLab runs housekeeping tasks:

- A project's administrator can [manually trigger](#manual-trigger) repository
  housekeeping tasks.
- GitLab can automatically schedule housekeeping tasks [after a number of Git pushes](#push-based-trigger).
- GitLab can [schedule a job](#scheduled-housekeeping) that runs housekeeping
  tasks for all repositories in a configurable timeframe.

### Manual trigger

Administrators of repositories can manually trigger housekeeping tasks in a
repository. In general this is not required as GitLab knows to automatically run
housekeeping tasks. The manual trigger can be useful when either:

- A repository is known to require housekeeping.
- Automated push-based scheduling of housekeeping tasks has been disabled.

To trigger housekeeping tasks manually:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. Select **Run housekeeping**.

This starts an asynchronous background worker for the project's repository. The
background worker executes `git gc`, which performs a number of optimizations.

### Push-based trigger

GitLab automatically runs repository housekeeping tasks after a configured
number of pushes:

- [`git gc`](https://git-scm.com/docs/git-gc) runs a number of housekeeping tasks such as:
  - Compressing Git objects to reduce disk space and increase performance.
  - Removing unreachable objects that may have been created from changes to the repository, like force-overwriting branches.
- [`git repack`](https://git-scm.com/docs/git-repack) either:
  - Runs an incremental repack, according to a [configured period](#configure-push-based-maintenance). This
    packs all loose objects into a new packfile and prunes the now-redundant loose objects.
  - Runs a full repack, according to a [configured period](#configure-push-based-maintenance). This repacks all
    packfiles and loose objects into a single new packfile, and deletes the old now-redundant loose
    objects and packfiles. It also optionally creates bitmaps for the new packfile.
- [`git pack-refs`](https://git-scm.com/docs/git-pack-refs) compresses references
  stored as loose files into a single file.

#### Configure push-based maintenance

You can change how often these tasks run when pushes occur, or you can turn
them off entirely:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Repository**.
1. Expand **Repository maintenance**.
1. In the **Housekeeping** section, configure the housekeeping options.
1. Select **Save changes**.

The following housekeeping options are available:

- **Enable automatic repository housekeeping**: Regularly run housekeeping tasks. If you
  keep this setting disabled for a long time, Git repository access on your GitLab server becomes
  slower and your repositories use more disk space.
- **Incremental repack period**: Number of Git pushes after which an incremental `git repack` is
  run.
- **Full repack period**: Number of Git pushes after which a full `git repack` is run.
- **Git GC period**: Number of Git pushes after which `git gc` is run.

As an example, see the following scenario:

- Incremental repack period: 10.
- Full repack period: 50.
- Git GC period: 200.

When the:

- `pushes_since_gc` value is 50, a `repack -A -l -d --pack-kept-objects` runs.
- `pushes_since_gc` value is 200, a `git gc` runs.

Housekeeping also [removes unreferenced LFS files](../raketasks/cleanup.md#remove-unreferenced-lfs-files)
from your project on the same schedule as the `git gc` operation, freeing up storage space for your
project.

### Scheduled housekeeping

While GitLab automatically performs housekeeping tasks based on the number of
pushes, it does not maintain repositories that don't receive any pushes at all.
As a result, inactive repositories or repositories that are only getting read
requests may not benefit from improvements in the repository housekeeping
strategy.

Administrators can enable a background job that performs housekeeping in all
repositories at a customizable interval to remedy this situation. This
background job processes all repositories hosted by a Gitaly node in a random
order and eagerly performs housekeeping tasks on them. The Gitaly node will stop
processing repositories if it takes longer than the configured interval.

#### Configure scheduled housekeeping

Background maintenance of Git repositories is configured in Gitaly. By default,
Gitaly performs background repository maintenance every day at 12:00 noon for a
duration of 10 minutes.

You can change this default in Gitaly configuration. The following snippet
enables daily background repository maintenance starting at 23:00 for 1 hour
for the `default` storage:

```toml
[daily_maintenance]
start_hour = 23
start_minute = 00
duration = 1h
storages = ["default"]
```

Use the following snippet to completely disable background repository
maintenance:

```toml
[daily_maintenance]
disabled = true
```

## Object pool repositories

Object pool repositories are used by GitLab to deduplicate objects across forks
of a repository. When creating the first fork, we:

1. Create an object pool repository that contains all objects of the repository
   that is about to be forked.
1. Link the repository to this new object pool via Git's altenates mechanism.
1. Repack the repository so that it uses objects from the object pool. It thus
   can drop its own copy of the objects.

Any forks of this repository can now link against the object pool and thus only
have to keep objects that diverge from the primary repository.

GitLab needs to perform special housekeeping operations in object pools:

- Gitaly cannot ever delete unreachable objects from object pools because they
  might be used by any of the forks that are connected to it.
- Gitaly must keep all objects reachable due to the same reason. Object pools
  thus maintain references to unreachable "dangling" objects so that they don't
  ever get deleted.
- GitLab must update object pools regularly to pull in new objects that have
  been added in the primary repository. Otherwise, an object pool will become
  increasingly inefficient at deduplicating objects.

These housekeeping operations are performed by the specialized
`FetchIntoObjectPool` RPC that handles all of these special tasks while also
executing the regular housekeeping tasks we execute for normal Git
repositories.

Object pools are getting optimized automatically whenever the primary member is
getting garbage collected. Therefore, the cadence can be configured using the
same Git GC period in that project.

If you need to manually invoke the RPC from a [Rails console](operations/rails_console.md),
you can call `project.pool_repository.object_pool.fetch`. This is a potentially
long-running task, though Gitaly times out after about 8 hours.
