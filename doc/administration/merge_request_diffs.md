---
stage: Create
group: Editor
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Merge request diffs storage **(CORE ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/52568) in GitLab 11.8.

Merge request diffs are size-limited copies of diffs associated with merge
requests. When viewing a merge request, diffs are sourced from these copies
wherever possible as a performance optimization.

By default, merge request diffs are stored in the database, in a table named
`merge_request_diff_files`. Larger installations may find this table grows too
large, in which case, switching to external storage is recommended.

Merge request diffs can be stored on disk, or in object storage. In general, it
is better to store the diffs in the database than on disk. A compromise is available
that only [stores outdated diffs](#alternative-in-database-storage) outside of database.

## Using external storage

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   ```

1. _The external diffs will be stored in
   `/var/opt/gitlab/gitlab-rails/shared/external-diffs`._ To change the path,
   for example, to `/mnt/storage/external-diffs`, edit `/etc/gitlab/gitlab.rb`
   and add the following line:

   ```ruby
   gitlab_rails['external_diffs_storage_path'] = "/mnt/storage/external-diffs"
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   external_diffs:
     enabled: true
   ```

1. _The external diffs will be stored in
   `/home/git/gitlab/shared/external-diffs`._ To change the path, for example,
   to `/mnt/storage/external-diffs`, edit `/home/git/gitlab/config/gitlab.yml`
   and add or amend the following lines:

   ```yaml
   external_diffs:
     enabled: true
     storage_path: /mnt/storage/external-diffs
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

## Using object storage

CAUTION: **Warning:**
Currently migrating to object storage is **non-reversible**

Instead of storing the external diffs on disk, we recommended the use of an object
store like AWS S3 instead. This configuration relies on valid AWS credentials to
be configured already.

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   ```

1. Set [object storage settings](#object-storage-settings).
1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   external_diffs:
     enabled: true
   ```

1. Set [object storage settings](#object-storage-settings).
1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

[Read more about using object storage with GitLab](object_storage.md).

### Object Storage Settings

NOTE: **Note:**
In GitLab 13.2 and later, we recommend using the
[consolidated object storage settings](object_storage.md#consolidated-object-storage-configuration).
This section describes the earlier configuration format.

For source installations, these settings are nested under `external_diffs:` and
then `object_store:`. On Omnibus installations, they are prefixed by
`external_diffs_object_store_`.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where external diffs will be stored| |
| `direct_upload` | Set to `true` to enable direct upload of external diffs without the need of local shared storage. Option may be removed once we decide to support only single storage for all files. | `false` |
| `background_upload` | Set to `false` to disable automatic upload. Option may be removed once upload is direct to S3 | `true` |
| `proxy_download` | Set to `true` to enable proxying all files served. Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data | `false` |
| `connection` | Various connection options described below | |

#### S3 compatible connection settings

See [the available connection settings for different providers](object_storage.md#connection-settings).

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
   the values you want:

   ```ruby
   gitlab_rails['external_diffs_enabled'] = true
   gitlab_rails['external_diffs_object_store_enabled'] = true
   gitlab_rails['external_diffs_object_store_remote_directory'] = "external-diffs"
   gitlab_rails['external_diffs_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => 'AWS_ACCESS_KEY_ID',
     'aws_secret_access_key' => 'AWS_SECRET_ACCESS_KEY'
   }
   ```

   Note that, if you are using AWS IAM profiles, be sure to omit the
   AWS access key and secret access key/value pairs. For example:

   ```ruby
   gitlab_rails['external_diffs_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'use_iam_profile' => true
   }
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   external_diffs:
     enabled: true
     object_store:
       enabled: true
       remote_directory: "external-diffs" # The bucket name
       connection:
         provider: AWS # Only AWS supported at the moment
         aws_access_key_id: AWS_ACCESS_KEY_ID
         aws_secret_access_key: AWS_SECRET_ACCESS_KEY
         region: eu-central-1
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

## Alternative in-database storage

Enabling external diffs may reduce the performance of merge requests, as they
must be retrieved in a separate operation to other data. A compromise may be
reached by only storing outdated diffs externally, while keeping current diffs
in the database.

To enable this feature, perform the following steps:

**In Omnibus installations:**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['external_diffs_when'] = 'outdated'
   ```

1. Save the file and [reconfigure GitLab](restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.

**In installations from source:**

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   external_diffs:
     enabled: true
     when: outdated
   ```

1. Save the file and [restart GitLab](restart_gitlab.md#installations-from-source) for the changes to take effect.

With this feature enabled, diffs will initially stored in the database, rather
than externally. They will be moved to external storage once any of these
conditions become true:

- A newer version of the merge request diff exists
- The merge request was merged more than seven days ago
- The merge request was closed more than seven day ago

These rules strike a balance between space and performance by only storing
frequently-accessed diffs in the database. Diffs that are less likely to be
accessed are moved to external storage instead.

## Correcting incorrectly-migrated diffs

Versions of GitLab earlier than `v13.0.0` would incorrectly record the location
of some merge request diffs when [external diffs in object storage](#object-storage-settings)
were enabled. This mainly affected imported merge requests, and was resolved
with [this merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/31005).

If you are using object storage, have never used on-disk storage for external
diffs, the "changes" tab for some merge requests fails to load with a 500 error,
and the exception for that error is of this form:

```plain
Errno::ENOENT (No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/shared/external-diffs/merge_request_diffs/mr-6167082/diff-8199789)
```

Then you are affected by this issue. Since it's not possible to safely determine
all these conditions automatically, we've provided a Rake task in GitLab v13.2.0
that you can run manually to correct the data:

**In Omnibus installations:**

```shell
sudo gitlab-rake gitlab:external_diffs:force_object_storage
```

**In installations from source:**

```shell
sudo -u git -H bundle exec rake gitlab:external_diffs:force_object_storage RAILS_ENV=production
```

Environment variables can be provided to modify the behavior of the task. The
available variables are:

| Name | Default value | Purpose |
| ---- | ------------- | ------- |
| `ANSI`         | `true`  | Use ANSI escape codes to make output more understandable |
| `BATCH_SIZE`   | `1000`  | Iterate through the table in batches of this size |
| `START_ID`     | `nil`   | If set, begin scanning at this ID |
| `END_ID`       | `nil`   | If set, stop scanning at this ID |
| `UPDATE_DELAY` | `1`     | Number of seconds to sleep between updates |

The `START_ID` and `END_ID` variables may be used to run the update in parallel,
by assigning different processes to different parts of the table. The `BATCH`
and `UPDATE_DELAY` parameters allow the speed of the migration to be traded off
against concurrent access to the table. The `ANSI` parameter should be set to
false if your terminal does not support ANSI escape codes.
