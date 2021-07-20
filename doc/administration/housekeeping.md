---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Housekeeping **(FREE SELF)**

GitLab supports and automates housekeeping tasks within your current repository such as:

- Compressing Git objects.
- Removing unreachable objects.

## Configure housekeeping

GitLab automatically runs `git gc` and `git repack` on repositories after Git pushes:

- [`git gc`](https://git-scm.com/docs/git-gc) runs a number of housekeeping tasks such as:
  - Compressing Git objects to reduce disk space and increase performance.
  - Removing unreachable objects that may have been created from changes to the repository, like force-overwriting branches.
- [`git repack`](https://git-scm.com/docs/git-repack) either:
  - Runs an incremental repack, according to a [configured period](#housekeeping-options). This
    packs all loose objects into a new packfile and prunes the now-redundant loose objects.
  - Runs a full repack, according to a [configured period](#housekeeping-options). This repacks all
    packfiles and loose objects into a single new packfile, and deletes the old now-redundant loose
    objects and packfiles. It also optionally creates bitmaps for the new packfile.

You can change how often this happens or turn it off:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Repository**.
1. Expand **Repository maintenance**.
1. In the **Housekeeping** section, configure the [housekeeping options](#housekeeping-options).
1. Select **Save changes**.

### Housekeeping options

The following housekeeping options are available:

- **Enable automatic repository housekeeping**: Regularly run `git repack` and `git gc`. If you
  keep this setting disabled for a long time, Git repository access on your GitLab server becomes
  slower and your repositories use more disk space.
- **Enable Git pack file bitmap creation**: Create pack file bitmaps which accelerates `git clone`
  performance. Makes housekeeping take a little longer.
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

## How housekeeping handles pool repositories

Housekeeping for pool repositories is handled differently from standard repositories. It is
ultimately performed by the Gitaly RPC `FetchIntoObjectPool`.

This is the current call stack by which it is invoked:

1. `Repositories::HousekeepingService#execute_gitlab_shell_gc`
1. `Projects::GitGarbageCollectWorker#perform`
1. `Projects::GitDeduplicationService#fetch_from_source`
1. `ObjectPool#fetch`
1. `ObjectPoolService#fetch`
1. `Gitaly::FetchIntoObjectPoolRequest`

To manually invoke it from a Rails console if needed, you can call
`project.pool_repository.object_pool.fetch`. This is a potentially long-running task, though Gitaly
times out in about 8 hours.

WARNING:
Do not run `git prune` or `git gc` in pool repositories! This can cause data loss in "real"
repositories that depend on the pool in question.
