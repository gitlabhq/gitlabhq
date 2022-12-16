---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/lfs/lfs_administration.html'
---

# GitLab Git Large File Storage (LFS) Administration **(FREE SELF)**

This page contains information about configuring Git LFS in self-managed GitLab instances.
For user documentation about Git LFS, see [Git Large File Storage](../../topics/git/lfs/index.md).

LFS is enabled in GitLab self-managed instances by default.

## Requirements

- Users need to install [Git LFS client](https://git-lfs.github.com) version 1.0.1 or later.

## Configuration

Git LFS objects can be large in size. By default, they are stored on the server
GitLab is installed on.

There are various configuration options to help GitLab server administrators:

- Enabling/disabling Git LFS support.
- Changing the location of LFS object storage.
- Setting up object storage supported by [Fog](https://fog.io/about/provider_documentation.html).

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

After you update settings in `/etc/gitlab/gitlab.rb`, run [Omnibus GitLab reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure).

### Configuration for installations from source

In `config/gitlab.yml`:

```yaml
# Change to true to enable lfs
  lfs:
    enabled: false
    storage_path: /mnt/storage/lfs-objects
```

## Storing LFS objects in remote object storage

You can store LFS objects in remote object storage. This allows you
to reduce reads and writes to the local disk, and free up disk space significantly.
GitLab is tightly integrated with `Fog`, so you can refer to its [documentation](https://fog.io/about/provider_documentation.html)
to check which storage services can be integrated with GitLab.
You can also use external object storage in a private local network. For example,
[MinIO](https://min.io/) is a standalone object storage service that works with GitLab instances.

[Read more about using object storage with GitLab](../object_storage.md).

NOTE:
In GitLab 13.2 and later, we recommend using the
[consolidated object storage settings](../object_storage.md#consolidated-object-storage-configuration).
This section describes the earlier configuration format.

1. User pushes an `lfs` file to the GitLab instance.
1. GitLab-workhorse uploads the file directly to the external object storage.
1. GitLab-workhorse notifies GitLab-rails that the upload process is complete.

The following general settings are supported.

| Setting             | Description | Default |
|---------------------|-------------|---------|
| `enabled`           | Enable/disable object storage. | `false` |
| `remote_directory`  | The bucket name where LFS objects are stored. | |
| `proxy_download`    | Set to true to enable proxying all files served. Option allows to reduce egress traffic as this allows clients to download directly from remote storage instead of proxying all data. | `false` |
| `connection`        | Various connection options described below. | |

See [the available connection settings for different providers](../object_storage.md#connection-settings).

Here is a configuration example with S3.

### S3 for Omnibus installations

On Omnibus GitLab installations, the settings are prefixed by `lfs_object_store_`:

1. Edit `/etc/gitlab/gitlab.rb` and add the following lines, replacing values based on your needs:

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

1. Save the file, and then [reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) for the changes to take effect.
1. [Migrate any existing local LFS objects to the object storage](#migrating-to-object-storage).
   New LFS objects are forwarded to object storage.

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

1. Save the file, and then [restart GitLab](../restart_gitlab.md#installations-from-source) for the changes to take effect.
1. [Migrate any existing local LFS objects to the object storage](#migrating-to-object-storage).
   New LFS objects are forwarded to object storage.

### Migrating to object storage

**Option 1: Rake task**

After [configuring the object storage](#storing-lfs-objects-in-remote-object-storage), use the following task to
migrate existing LFS objects from the local storage to the remote storage.
The processing is done in a background worker and requires **no downtime**.

For Omnibus GitLab:

```shell
sudo gitlab-rake "gitlab:lfs:migrate"
```

For installations from source:

```shell
RAILS_ENV=production sudo -u git -H bundle exec rake gitlab:lfs:migrate
```

You can optionally track progress and verify that all LFS objects migrated successfully using the
[PostgreSQL console](https://docs.gitlab.com/omnibus/settings/database.html#connecting-to-the-bundled-postgresql-database):

- `sudo gitlab-rails dbconsole` for Omnibus GitLab 14.1 and earlier.
- `sudo gitlab-rails dbconsole --database main` for Omnibus GitLab 14.2 and later.
- `sudo -u git -H psql -d gitlabhq_production` for source-installed instances.

Verify `objectstg` below (where `store=2`) has count of all LFS objects:

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM lfs_objects;
```

**Example Output**

```shell
total | filesystem | objectstg
------+------------+-----------
 2409 |          0 |      2409
```

Verify that there are no files on disk in the `objects` folder:

```shell
sudo find /var/opt/gitlab/gitlab-rails/shared/lfs-objects -type f | grep -v tmp | wc -l
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

### Migrating back to local storage

To migrate back to local storage:

1. Run `rake gitlab:lfs:migrate_to_local` on your console.
1. Disable `object_storage` for LFS objects in `gitlab.rb`. Remember to restart GitLab afterwards.

## Storage statistics

You can see the total storage used for LFS objects on groups and projects:

- In the administration area.
- In the [groups](../../api/groups.md) and [projects APIs](../../api/projects.md).

## Related topics

- Blog post: [Getting started with Git LFS](https://about.gitlab.com/blog/2017/01/30/getting-started-with-git-lfs-tutorial/)
- User documentation: [Git Large File Storage (LFS)](../../topics/git/lfs/index.md)
- [Git LFS developer information](../../development/lfs.md)

## Troubleshooting

### Missing LFS objects

An error about a missing LFS object may occur in either of these situations:

- When migrating LFS objects from disk to object storage, with error messages like:

  ```plaintext
  ERROR -- : Failed to transfer LFS object
  006622269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
  with error: No such file or directory @ rb_sysopen -
  /var/opt/gitlab/gitlab-rails/shared/lfs-objects/00/66/22269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
  ```

   (Line breaks have been added for legibility.)

- When running the
  [integrity check for LFS objects](../raketasks/check.md#uploaded-files-integrity)
  with the `VERBOSE=1` parameter.

The database can have records for LFS objects which are not on disk. The database entry may
[prevent a new copy of the object from being pushed](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/49241).
To delete these references:

1. [Start a rails console](../operations/rails_console.md).
1. Query the object that's reported as missing in the rails console, to return a file path:

   ```ruby
   lfs_object = LfsObject.find_by(oid: '006622269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7')
   lfs_object.file.path
   ```

1. Check on disk or object storage if it exists:

   ```shell
   ls -al /var/opt/gitlab/gitlab-rails/shared/lfs-objects/00/66/22269c61b41bf14a22bbe0e43be3acf86a4a446afb4250c3794ea47541a7
   ```

1. If the file is not present, remove the database record via the rails console:

   ```ruby
   lfs_object.destroy
   ```

### LFS commands fail on TLS v1.3 server

If you configure GitLab to [disable TLS v1.2](https://docs.gitlab.com/omnibus/settings/nginx.html)
and only enable TLS v1.3 connections, LFS operations require a
[Git LFS client](https://git-lfs.github.com) version 2.11.0 or later. If you use
a Git LFS client earlier than version 2.11.0, GitLab displays an error:

```plaintext
batch response: Post https://username:***@gitlab.example.com/tool/releases.git/info/lfs/objects/batch: remote error: tls: protocol version not supported
error: failed to fetch some objects from 'https://username:[MASKED]@gitlab.example.com/tool/releases.git/info/lfs'
```

When using GitLab CI over a TLS v1.3 configured GitLab server, you must
[upgrade to GitLab Runner](https://docs.gitlab.com/runner/install/index.html) 13.2.0
or later to receive an updated Git LFS client version via
the included [GitLab Runner Helper image](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#helper-image).

To check an installed Git LFS client's version, run this command:

```shell
git lfs version
```

## Error viewing a PDF file

When LFS has been configured with object storage and `proxy_download` set to
`false`, [you may see an error when previewing a PDF file from the Web browser](https://gitlab.com/gitlab-org/gitlab/-/issues/248100):

```plaintext
An error occurred while loading the file. Please try again later.
```

This occurs due to Cross-Origin Resource Sharing (CORS) restrictions:
the browser attempts to load the PDF from object storage, but the object
storage provider rejects the request because the GitLab domain differs
from the object storage domain.

To fix this issue, configure your object storage provider's CORS
settings to allow the GitLab domain. See the following documentation
for more details:

1. [AWS S3](https://aws.amazon.com/premiumsupport/knowledge-center/s3-configure-cors/)
1. [Google Cloud Storage](https://cloud.google.com/storage/docs/configuring-cors)
1. [Azure Storage](https://learn.microsoft.com/en-us/rest/api/storageservices/cross-origin-resource-sharing--cors--support-for-the-azure-storage-services).

## Known limitations

- Only compatible with the Git LFS client versions 1.1.0 and later, or 1.0.2.
- The storage statistics count each LFS object for
  every project linking to it.
