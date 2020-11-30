---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, howto
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/lfs/lfs_administration.html'
---

# GitLab Git Large File Storage (LFS) Administration **(CORE ONLY)**

> - Git LFS is supported in GitLab starting with version 8.2.
> - Support for object storage, such as AWS S3, was introduced in 10.0.
> - LFS is enabled in GitLab self-managed instances by default.

Documentation on how to use Git LFS are under [Managing large binary files with Git LFS doc](../../topics/git/lfs/index.md).

## Requirements

- Users need to install [Git LFS client](https://git-lfs.github.com) version 1.0.1 and up.

## Configuration

Git LFS objects can be large in size. By default, they are stored on the server
GitLab is installed on.

There are various configuration options to help GitLab server administrators:

- Enabling/disabling Git LFS support
- Changing the location of LFS object storage
- Setting up object storage supported by [Fog](http://fog.io/about/provider_documentation.html)

### Configuration for Omnibus installations

In `/etc/gitlab/gitlab.rb`:

```ruby
# Change to true to enable lfs - enabled by default if not defined
gitlab_rails['lfs_enabled'] = false

# Optionally, change the storage path location. Defaults to
# `#{gitlab_rails['shared_path']}/lfs-objects`. Which evaluates to
# `/var/opt/gitlab/gitlab-rails/shared/lfs-objects` by default.
gitlab_rails['lfs_storage_path'] = "/mnt/storage/lfs-objects"
```

After you update settings in `/etc/gitlab/gitlab.rb`, make sure to run [Omnibus GitLab reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Configuration for installations from source

In `config/gitlab.yml`:

```yaml
# Change to true to enable lfs
  lfs:
    enabled: false
    storage_path: /mnt/storage/lfs-objects
```

## Storing LFS objects in remote object storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/2760) in [GitLab Premium](https://about.gitlab.com/pricing/) 10.0. Brought to GitLab Core in 10.7.

It is possible to store LFS objects in remote object storage which allows you
to offload local hard disk R/W operations, and free up disk space significantly.
GitLab is tightly integrated with `Fog`, so you can refer to its [documentation](http://fog.io/about/provider_documentation.html)
to check which storage services can be integrated with GitLab.
You can also use external object storage in a private local network. For example,
[MinIO](https://min.io/) is a standalone object storage service, is easy to set up, and works well with GitLab instances.

GitLab provides two different options for the uploading mechanism: "Direct upload" and "Background upload".

[Read more about using object storage with GitLab](../object_storage.md).

NOTE: **Note:**
In GitLab 13.2 and later, we recommend using the
[consolidated object storage settings](../object_storage.md#consolidated-object-storage-configuration).
This section describes the earlier configuration format.

**Option 1. Direct upload**

1. User pushes an `lfs` file to the GitLab instance
1. GitLab-workhorse uploads the file directly to the external object storage
1. GitLab-workhorse notifies GitLab-rails that the upload process is complete

**Option 2. Background upload**

1. User pushes an `lfs` file to the GitLab instance
1. GitLab-rails stores the file in the local file storage
1. GitLab-rails then uploads the file to the external object storage asynchronously

The following general settings are supported.

| Setting | Description | Default |
|---------|-------------|---------|
| `enabled` | Enable/disable object storage | `false` |
| `remote_directory` | The bucket name where LFS objects will be stored| |
| `direct_upload` | Set to true to enable direct upload of LFS without the need of local shared storage. Option may be removed once we decide to support only single storage for all files. | `false` |
| `background_upload` | Set to false to disable automatic upload. Option may be removed once upload is direct to S3 | `true` |
| `proxy_download` | Set to true to enable proxying all files served. Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data | `false` |
| `connection` | Various connection options described below | |

See [the available connection settings for different providers](../object_storage.md#connection-settings).

Here is a configuration example with S3.

### Manual uploading to an object storage

There are two ways to manually do the same thing as automatic uploading (described above).

**Option 1: Rake task**

```shell
gitlab-rake gitlab:lfs:migrate
```

**Option 2: Rails console**

Log into the Rails console:

```shell
sudo gitlab-rails console
```

Upload LFS files manually

```ruby
LfsObject.where(file_store: [nil, 1]).find_each do |lfs_object|
  lfs_object.file.migrate!(ObjectStorage::Store::REMOTE) if lfs_object.file.file.exists?
end
```

### S3 for Omnibus installations

On Omnibus installations, the settings are prefixed by `lfs_object_store_`:

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines by replacing with
   the values you want:

   ```ruby
   gitlab_rails['lfs_object_store_enabled'] = true
   gitlab_rails['lfs_object_store_remote_directory'] = "lfs-objects"
   gitlab_rails['lfs_object_store_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-central-1',
     'aws_access_key_id' => '1ABCD2EFGHI34JKLM567N',
     'aws_secret_access_key' => 'abcdefhijklmnopQRSTUVwxyz0123456789ABCDE',
     # The below options configure an S3 compatible host instead of AWS
     'host' => 'localhost',
     'endpoint' => 'http://127.0.0.1:9000',
     'path_style' => true
   }
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. Migrate any existing local LFS objects to the object storage:

   ```shell
   gitlab-rake gitlab:lfs:migrate
   ```

   This will migrate existing LFS objects to object storage. New LFS objects
   will be forwarded to object storage unless
   `gitlab_rails['lfs_object_store_background_upload']` and `gitlab_rails['lfs_object_store_direct_upload']` is set to `false`.
1. Optional: Verify all files migrated properly.
   From [PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database)
   (`sudo gitlab-psql -d gitlabhq_production`) verify `objectstg` below (where `file_store=2`) has count of all artifacts:

   ```shell
   gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM lfs_objects;

   total | filesystem | objectstg
   ------+------------+-----------
    2409 |          0 |      2409
   ```

   Verify no files on disk in `artifacts` folder:

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp/cache | wc -l
   ```

### S3 for installations from source

For source installations the settings are nested under `lfs:` and then
`object_store:`:

1. Edit `/home/git/gitlab/config/gitlab.yml` and add or amend the following
   lines:

   ```yaml
   lfs:
   enabled: true
   object_store:
     enabled: false
     remote_directory: lfs-objects # Bucket name
     connection:
       provider: AWS
       aws_access_key_id: 1ABCD2EFGHI34JKLM567N
       aws_secret_access_key: abcdefhijklmnopQRSTUVwxyz0123456789ABCDE
       region: eu-central-1
       # Use the following options to configure an AWS compatible host such as Minio
       host: 'localhost'
       endpoint: 'http://127.0.0.1:9000'
       path_style: true
   ```

1. Save the file and [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.
1. Migrate any existing local LFS objects to the object storage:

   ```shell
   sudo -u git -H bundle exec rake gitlab:lfs:migrate RAILS_ENV=production
   ```

   This will migrate existing LFS objects to object storage. New LFS objects
   will be forwarded to object storage unless `background_upload` and `direct_upload` is set to
   `false`.
1. Optional: Verify all files migrated properly.
   From PostgreSQL console (`sudo -u git -H psql -d gitlabhq_production`) verify `objectstg` below (where `file_store=2`) has count of all artifacts:

   ```shell
   gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM lfs_objects;

   total | filesystem | objectstg
   ------+------------+-----------
    2409 |          0 |      2409
   ```

   Verify no files on disk in `artifacts` folder:

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp/cache | wc -l
   ```

### Migrating back to local storage

In order to migrate back to local storage:

1. Set both `direct_upload` and `background_upload` to `false` under the LFS object storage settings. Don't forget to restart GitLab.
1. Run `rake gitlab:lfs:migrate_to_local` on your console.
1. Disable `object_storage` for LFS objects in `gitlab.rb`. Remember to restart GitLab afterwards.

## Storage statistics

You can see the total storage used for LFS objects on groups and projects
in the administration area, as well as through the [groups](../../api/groups.md)
and [projects APIs](../../api/projects.md).

## Troubleshooting: `Google::Apis::TransmissionError: execution expired`

If LFS integration is configured with Google Cloud Storage and background uploads (`background_upload: true` and `direct_upload: false`),
Sidekiq workers may encounter this error. This is because the uploading timed out with very large files.
LFS files up to 6Gb can be uploaded without any extra steps, otherwise you need to use the following workaround.

Log into Rails console:

```shell
sudo gitlab-rails console
```

Set up timeouts:

- These settings are only in effect for the same session. For example, they are not effective for Sidekiq workers.
- 20 minutes (1200 sec) is enough to upload 30GB LFS files:

```ruby
::Google::Apis::ClientOptions.default.open_timeout_sec = 1200
::Google::Apis::ClientOptions.default.read_timeout_sec = 1200
::Google::Apis::ClientOptions.default.send_timeout_sec = 1200
```

Upload LFS files manually (this process does not use Sidekiq at all):

```ruby
LfsObject.where(file_store: [nil, 1]).find_each do |lfs_object|
  lfs_object.file.migrate!(ObjectStorage::Store::REMOTE) if lfs_object.file.file.exists?
end
```

See more information in [!19581](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/19581)

## Known limitations

- Support for removing unreferenced LFS objects was added in 8.14 onward.
- LFS authentications via SSH was added with GitLab 8.12.
- Only compatible with the Git LFS client versions 1.1.0 and up, or 1.0.2.
- The storage statistics currently count each LFS object multiple times for
  every project linking to it.
