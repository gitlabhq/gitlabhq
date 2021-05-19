---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Housekeeping **(FREE)**

GitLab supports and automates housekeeping tasks within your current repository,
such as compressing file revisions and removing unreachable objects.

## Automatic housekeeping

GitLab automatically runs `git gc` and `git repack` on repositories
after Git pushes. You can change how often this happens or turn it off in
**Admin Area > Settings > Repository** (`/admin/application_settings/repository`).

## Manual housekeeping

The housekeeping function runs `repack` or `gc` depending on the
**Housekeeping** settings configured in **Admin Area > Settings > Repository**.

For example in the following scenario a `git repack -d` will be executed:

- Project: pushes since GC counter (`pushes_since_gc`) = `10`
- Git GC period = `200`
- Full repack period = `50`

When the `pushes_since_gc` value is 50 a `repack -A -d --pack-kept-objects` runs, similarly when
the `pushes_since_gc` value is 200 a `git gc` runs.

- `git gc` ([man page](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-gc.html)) runs a number of housekeeping tasks,
  such as compressing file revisions (to reduce disk space and increase performance)
  and removing unreachable objects which may have been created from prior invocations of
  `git add`.
- `git repack` ([man page](https://mirrors.edge.kernel.org/pub/software/scm/git/docs/git-repack.html)) re-organize existing packs into a single, more efficient pack.

Housekeeping also [removes unreferenced LFS files](../raketasks/cleanup.md#remove-unreferenced-lfs-files)
from your project on the same schedule as the `git gc` operation, freeing up storage space for your project.

To manually start the housekeeping process:

1. In your project, go to **Settings > General**.
1. Expand the **Advanced** section.
1. Select **Run housekeeping**.

## How housekeeping handles pool repositories

Housekeeping for pool repositories is handled differently from standard repositories.
It is ultimately performed by the Gitaly RPC `FetchIntoObjectPool`.

This is the current call stack by which it is invoked:

1. `Repositories::HousekeepingService#execute_gitlab_shell_gc`
1. `Projects::GitGarbageCollectWorker#perform`
1. `Projects::GitDeduplicationService#fetch_from_source`
1. `ObjectPool#fetch`
1. `ObjectPoolService#fetch`
1. `Gitaly::FetchIntoObjectPoolRequest`

To manually invoke it from a Rails console, if needed, you can call `project.pool_repository.object_pool.fetch`.
This is a potentially long-running task, though Gitaly times out in about 8 hours.

WARNING:
Do not run `git prune` or `git gc` in pool repositories! This can
cause data loss in "real" repositories that depend on the pool in
question.
