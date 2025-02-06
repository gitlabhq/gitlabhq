---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Configure external storage for merge request diffs on your GitLab instance."
title: Merge request diffs storage
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Merge request diffs are size-limited copies of diffs associated with merge
requests. When viewing a merge request, diffs are sourced from these copies
wherever possible as a performance optimization.

By default, merge request diffs are stored in the database, in a table named
`merge_request_diff_files`. Larger installations may find this table grows too
large, in which case, switching to external storage is recommended.

Merge request diffs can be stored:

- Completely [on disk](#using-external-storage).
- Completely [on object storage](#using-object-storage).
- Current diffs in the database, and [outdated diffs in object storage](#alternative-in-database-storage).

## Using external storage

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   ```

1. The external diffs are stored in
   `/var/opt/gitlab/gitlab-rails/shared/external-diffs`. To change the path,
   for example, to `/mnt/storage/external-diffs`, edit `/etc/gitlab/gitlab.rb`
   and add the following line:

   ```ruby
   gitlab_rails['external_diffs_storage_path'] = "/mnt/storage/external-diffs"
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
   GitLab then migrates your existing merge request diffs to external storage.

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   external_diffs:
     enabled: true
   ```

1. The external diffs are stored in
   `/home/git/gitlab/shared/external-diffs`. To change the path, for example,
   to `/mnt/storage/external-diffs`, edit `/home/git/gitlab/config/gitlab.yml`
   and add or amend the following lines:

   ```yaml
   external_diffs:
     enabled: true
     storage_path: /mnt/storage/external-diffs
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations) for the changes to take effect.
   GitLab then migrates your existing merge request diffs to external storage.

::EndTabs

## Using object storage

WARNING:
Migrating to object storage is not reversible.

Instead of storing the external diffs on disk, we recommended the use of an object
store like AWS S3 instead. This configuration relies on valid AWS credentials to
be configured already.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   ```

1. Set [object storage settings](#object-storage-settings).
1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.
   GitLab then migrates your existing merge request diffs to external storage.

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   external_diffs:
     enabled: true
   ```

1. Set [object storage settings](#object-storage-settings).
1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations) for the changes to take effect.
   GitLab then migrates your existing merge request diffs to external storage.

::EndTabs

[Read more about using object storage with GitLab](object_storage.md).

### Object Storage Settings

You should use the
[consolidated object storage settings](object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

## Alternative in-database storage

Enabling external diffs may reduce the performance of merge requests, as they
must be retrieved in a separate operation to other data. A compromise may be
reached by only storing outdated diffs externally, while keeping current diffs
in the database.

To enable this feature, perform the following steps:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['external_diffs_when'] = 'outdated'
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   external_diffs:
     enabled: true
     when: outdated
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#self-compiled-installations) for the changes to take effect.

::EndTabs

With this feature enabled, diffs are initially stored in the database, rather
than externally. They are moved to external storage after any of these
conditions become true:

- A newer version of the merge request diff exists
- The merge request was merged more than seven days ago
- The merge request was closed more than seven day ago

These rules strike a balance between space and performance by only storing
frequently-accessed diffs in the database. Diffs that are less likely to be
accessed are moved to external storage instead.

## Switching from external storage to object storage

Automatic migration moves diffs stored in the database, but it does not move diffs between storage types.
To switch from external storage to object storage:

1. Move files stored on local or NFS storage to object storage manually.
1. Run this Rake task to change their location in the database.

   For Linux package installations:

   ```shell
   sudo gitlab-rake gitlab:external_diffs:force_object_storage
   ```

   For self-compiled installations:

   ```shell
   sudo -u git -H bundle exec rake gitlab:external_diffs:force_object_storage RAILS_ENV=production
   ```

   By default, `sudo` does not preserve existing environment variables. You should
   append them, rather than prefix them, like this:

   ```shell
   sudo gitlab-rake gitlab:external_diffs:force_object_storage START_ID=59946109 END_ID=59946109 UPDATE_DELAY=5
   ```

These environment variables modify the behavior of the Rake task:

| Name           | Default value | Purpose |
|----------------|---------------|---------|
| `ANSI`         | `true`        | Use ANSI escape codes to make output more understandable. |
| `BATCH_SIZE`   | `1000`        | Iterate through the table in batches of this size. |
| `START_ID`     | `nil`         | If set, begin scanning at this ID. |
| `END_ID`       | `nil`         | If set, stop scanning at this ID. |
| `UPDATE_DELAY` | `1`           | Number of seconds to sleep between updates. |

- `START_ID` and `END_ID` can be used to run the update in parallel,
  by assigning different processes to different parts of the table.
- `BATCH` and `UPDATE_DELAY` enable the speed of the migration to be traded off
  against concurrent access to the table.
- `ANSI` should be set to `false` if your terminal does not support ANSI escape codes.
