---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Back up GitLab **(FREE SELF)**

GitLab provides a command line interface to back up your entire instance,
including:

- Database
- Attachments
- Git repositories data
- CI/CD job output logs
- CI/CD job artifacts
- LFS objects
- Terraform states ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/331806) in GitLab 14.7)
- Container Registry images
- GitLab Pages content
- Packages ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332006) in GitLab 14.7)
- Snippets
- [Group wikis](../user/project/wiki/group.md)

Backups do not include:

- [Mattermost data](https://docs.mattermost.com/administration/config-settings.html#file-storage)
- Redis (and thus Sidekiq jobs)

WARNING:
GitLab does not back up any configuration files (`/etc/gitlab`), TLS keys and certificates, or system
files. You are highly advised to read about [storing configuration files](#storing-configuration-files).

WARNING:
The backup command requires [additional parameters](backup_restore.md#back-up-and-restore-for-installations-using-pgbouncer) when
your installation is using PgBouncer, for either performance reasons or when using it with a Patroni cluster.

WARNING:
Before GitLab 15.5.0, the backup command doesn't verify if another backup is already running, as described in
[issue 362593](https://gitlab.com/gitlab-org/gitlab/-/issues/362593). We strongly recommend
you make sure that all backups are complete before starting a new one.

Depending on your version of GitLab, use the following command if you installed
GitLab using the Omnibus package:

- GitLab 12.2 or later:

  ```shell
  sudo gitlab-backup create
  ```

- GitLab 12.1 and earlier:

  ```shell
  gitlab-rake gitlab:backup:create
  ```

If you installed GitLab from source, use the following command:

```shell
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

If you're running GitLab from within a Docker container, run the backup from
the host, based on your installed version of GitLab:

- GitLab 12.2 or later:

  ```shell
  docker exec -t <container name> gitlab-backup create
  ```

- GitLab 12.1 and earlier:

  ```shell
  docker exec -t <container name> gitlab-rake gitlab:backup:create
  ```

If you're using the [GitLab Helm chart](https://gitlab.com/gitlab-org/charts/gitlab)
on a Kubernetes cluster, you can run the backup task by using `kubectl` to run the `backup-utility`
script on the GitLab toolbox pod. For more details, see the
[charts backup documentation](https://docs.gitlab.com/charts/backup-restore/backup.html).

Similar to the Kubernetes case, if you have scaled out your GitLab cluster to
use multiple application servers, you should pick a designated node (that isn't
auto-scaled away) for running the backup Rake task. Because the backup Rake
task is tightly coupled to the main Rails application, this is typically a node
on which you're also running Puma or Sidekiq.

Example output:

```plaintext
Dumping database tables:
- Dumping table events... [DONE]
- Dumping table issues... [DONE]
- Dumping table keys... [DONE]
- Dumping table merge_requests... [DONE]
- Dumping table milestones... [DONE]
- Dumping table namespaces... [DONE]
- Dumping table notes... [DONE]
- Dumping table projects... [DONE]
- Dumping table protected_branches... [DONE]
- Dumping table schema_migrations... [DONE]
- Dumping table services... [DONE]
- Dumping table snippets... [DONE]
- Dumping table taggings... [DONE]
- Dumping table tags... [DONE]
- Dumping table users... [DONE]
- Dumping table users_projects... [DONE]
- Dumping table web_hooks... [DONE]
- Dumping table wikis... [DONE]
Dumping repositories:
- Dumping repository abcd... [DONE]
Creating backup archive: $TIMESTAMP_gitlab_backup.tar [DONE]
Deleting tmp directories...[DONE]
Deleting old backups... [SKIPPING]
```

## Storing configuration files

The [backup Rake task](#back-up-gitlab) GitLab provides does _not_ store your
configuration files. The primary reason for this is that your database contains
items including encrypted information for two-factor authentication and the
CI/CD _secure variables_. Storing encrypted information in the same location
as its key defeats the purpose of using encryption in the first place.

WARNING:
The secrets file is essential to preserve your database encryption key.

At the very **minimum**, you must back up:

For Omnibus:

- `/etc/gitlab/gitlab-secrets.json`
- `/etc/gitlab/gitlab.rb`

For installation from source:

- `/home/git/gitlab/config/secrets.yml`
- `/home/git/gitlab/config/gitlab.yml`

For [Docker installations](../install/docker.md), you must
back up the volume where the configuration files are stored. If you created
the GitLab container according to the documentation, it should be in the
`/srv/gitlab/config` directory.

For [GitLab Helm chart installations](https://gitlab.com/gitlab-org/charts/gitlab)
on a Kubernetes cluster, you must follow the
[Back up the secrets](https://docs.gitlab.com/charts/backup-restore/backup.html#backup-the-secrets)
instructions.

You may also want to back up any TLS keys and certificates (`/etc/gitlab/ssl`, `/etc/gitlab/trusted-certs`), and your
[SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)
to avoid man-in-the-middle attack warnings if you have to perform a full machine restore.

If you use Omnibus GitLab, review additional information to
[backup your configuration](https://docs.gitlab.com/omnibus/settings/backups.html).

In the unlikely event that the secrets file is lost, see the
[troubleshooting section](backup_restore.md#when-the-secrets-file-is-lost).

## Backup options

The command line tool GitLab provides to backup your instance can accept more
options.

### Backup strategy option

The default backup strategy is to essentially stream data from the respective
data locations to the backup using the Linux command `tar` and `gzip`. This works
fine in most cases, but can cause problems when data is rapidly changing.

When data changes while `tar` is reading it, the error `file changed as we read
it` may occur, and causes the backup process to fail. To combat this, 8.17
introduces a new backup strategy called `copy`. The strategy copies data files
to a temporary location before calling `tar` and `gzip`, avoiding the error.

A side-effect is that the backup process takes up to an additional 1X disk
space. The process does its best to clean up the temporary files at each stage
so the problem doesn't compound, but it could be a considerable change for large
installations. This is why the `copy` strategy is not the default in 8.17.

To use the `copy` strategy instead of the default streaming strategy, specify
`STRATEGY=copy` in the Rake task command. For example:

```shell
sudo gitlab-backup create STRATEGY=copy
```

Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:create` instead.

### Backup filename

WARNING:
If you use a custom backup filename, you can't
[limit the lifetime of the backups](#limit-backup-lifetime-for-local-files-prune-old-backups).

By default, a backup file is created according to the specification in the
previous [Backup timestamp](backup_restore.md#backup-timestamp) section. You can, however,
override the `[TIMESTAMP]` portion of the filename by setting the `BACKUP`
environment variable. For example:

```shell
sudo gitlab-backup create BACKUP=dump
```

Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:create` instead.

The resulting file is named `dump_gitlab_backup.tar`. This is useful for
systems that make use of rsync and incremental backups, and results in
considerably faster transfer speeds.

### Confirm archive can be transferred

To ensure the generated archive is transferable by rsync, you can set the `GZIP_RSYNCABLE=yes`
option. This sets the `--rsyncable` option to `gzip`, which is useful only in
combination with setting [the Backup filename option](#backup-filename).

The `--rsyncable` option in `gzip` isn't guaranteed to be available
on all distributions. To verify that it's available in your distribution, run
`gzip --help` or consult the man pages.

```shell
sudo gitlab-backup create BACKUP=dump GZIP_RSYNCABLE=yes
```

Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:create` instead.

### Excluding specific directories from the backup

You can exclude specific directories from the backup by adding the environment variable `SKIP`, whose values are a comma-separated list of the following options:

- `db` (database)
- `uploads` (attachments)
- `builds` (CI job output logs)
- `artifacts` (CI job artifacts)
- `lfs` (LFS objects)
- `terraform_state` (Terraform states)
- `registry` (Container Registry images)
- `pages` (Pages content)
- `repositories` (Git repositories data)
- `packages` (Packages)

NOTE:
When [backing up and restoring Helm Charts](https://docs.gitlab.com/charts/architecture/backup-restore.html), there is an additional option `packages`, which refers to any packages managed by the GitLab [package registry](../user/packages/package_registry/index.md).
For more information see [command line arguments](https://docs.gitlab.com/charts/architecture/backup-restore.html#command-line-arguments).

All wikis are backed up as part of the `repositories` group. Non-existent
wikis are skipped during a backup.

For Omnibus GitLab packages:

```shell
sudo gitlab-backup create SKIP=db,uploads
```

Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:create` instead.

For installations from source:

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=db,uploads RAILS_ENV=production
```

`SKIP=` is also used to:

- [Skip creation of the tar file](#skipping-tar-creation) (`SKIP=tar`).
- [Skip uploading the backup to remote storage](#skip-uploading-backups-to-remote-storage) (`SKIP=remote`).

### Skipping tar creation

NOTE:
It is not possible to skip the tar creation when using [object storage](#upload-backups-to-a-remote-cloud-storage) for backups.

The last part of creating a backup is generation of a `.tar` file containing
all the parts. In some cases (for example, if the backup is picked up by other
backup software) creating a `.tar` file might be wasted effort or even directly
harmful, so you can skip this step by adding `tar` to the `SKIP` environment
variable.

Adding `tar` to the `SKIP` variable leaves the files and directories containing the
backup in the directory used for the intermediate files. These files are
overwritten when a new backup is created, so you should make sure they are copied
elsewhere, because you can only have one backup on the system.

For Omnibus GitLab packages:

```shell
sudo gitlab-backup create SKIP=tar
```

For installations from source:

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=tar RAILS_ENV=production
```

### Back up Git repositories concurrently

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37158) in GitLab 13.3.
> - [Concurrent restore introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/69330) in GitLab 14.3

When using [multiple repository storages](../administration/repository_storage_paths.md),
repositories can be backed up or restored concurrently to help fully use CPU time. The
following variables are available to modify the default behavior of the Rake
task:

- `GITLAB_BACKUP_MAX_CONCURRENCY`: The maximum number of projects to back up at
  the same time. Defaults to the number of logical CPUs (in GitLab 14.1 and
  earlier, defaults to `1`).
- `GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY`: The maximum number of projects to
  back up at the same time on each storage. This allows the repository backups
  to be spread across storages. Defaults to `2` (in GitLab 14.1 and earlier,
  defaults to `1`).

For example, for Omnibus GitLab installations with 4 repository storages:

```shell
sudo gitlab-backup create GITLAB_BACKUP_MAX_CONCURRENCY=4 GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=1
```

For example, for installations from source:

```shell
sudo -u git -H bundle exec rake gitlab:backup:create GITLAB_BACKUP_MAX_CONCURRENCY=4 GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=1
```

### Incremental repository backups

> - Introduced in GitLab 14.9 [with a flag](../administration/feature_flags.md) named `incremental_repository_backup`. Disabled by default.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/355945) in GitLab 14.10.
> - `PREVIOUS_BACKUP` option [introduced](https://gitlab.com/gitlab-org/gitaly/-/issues/4184) in GitLab 15.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, ask an administrator to [disable the feature flag](../administration/feature_flags.md) named `incremental_repository_backup`.
On GitLab.com, this feature is not available.

NOTE:
Only repositories support incremental backups. Therefore, if you use `INCREMENTAL=yes`, the task
creates a self-contained backup tar archive. This is because all subtasks except repositories are
still creating full backups (they overwrite the existing full backup).
See [issue 19256](https://gitlab.com/gitlab-org/gitlab/-/issues/19256) for a feature request to
support incremental backups for all subtasks.

Incremental repository backups can be faster than full repository backups because they only pack changes since the last backup into the backup bundle for each repository.
The incremental backup archives are not linked to each other: each archive is a self-contained backup of the instance. There must be an existing backup
to create an incremental backup from:

- In GitLab 14.9 and 14.10, use the `BACKUP=<timestamp_of_backup>` option to choose the backup to use. The chosen previous backup is overwritten.
- In GitLab 15.0 and later, use the `PREVIOUS_BACKUP=<timestamp_of_backup>` option to choose the backup to use. By default, a backup file is created
  as documented in the [Backup timestamp](backup_restore.md#backup-timestamp) section. You can override the `[TIMESTAMP]` portion of the filename by setting the
  [`BACKUP` environment variable](#backup-filename).

To create an incremental backup, run:

- In GitLab 15.0 or later:

  ```shell
  sudo gitlab-backup create INCREMENTAL=yes PREVIOUS_BACKUP=<timestamp_of_backup>
  ```

- In GitLab 14.9 and 14.10:

  ```shell
  sudo gitlab-backup create INCREMENTAL=yes BACKUP=<timestamp_of_backup>
  ```

To create an [untarred](#skipping-tar-creation) incremental backup from a tarred backup, use `SKIP=tar`:

```shell
sudo gitlab-backup create INCREMENTAL=yes SKIP=tar
```

### Back up specific repository storages

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86896) in GitLab 15.0.

When using [multiple repository storages](../administration/repository_storage_paths.md),
repositories from specific repository storages can be backed up separately
using the `REPOSITORIES_STORAGES` option. The option accepts a comma-separated list of
storage names.

For example, for Omnibus GitLab installations:

```shell
sudo gitlab-backup create REPOSITORIES_STORAGES=storage1,storage2
```

For example, for installations from source:

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_STORAGES=storage1,storage2
```

### Back up specific repositories

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88094) in GitLab 15.1.

You can back up a specific repositories using the `REPOSITORIES_PATHS` option.
The option accepts a comma-separated list of project and group paths. If you
specify a group path, all repositories in all projects in the group and
descendent groups are included.

For example, to back up all repositories for all projects in **Group A** (`group-a`), and the repository for **Project C** in **Group B** (`group-b/project-c`):

- Omnibus GitLab installations:

  ```shell
  sudo gitlab-backup create REPOSITORIES_PATHS=group-a,group-b/project-c
  ```

- Installations from source:

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_PATHS=group-a,group-b/project-c
  ```

### Upload backups to a remote (cloud) storage

NOTE:
It is not possible to [skip the tar creation](#skipping-tar-creation) when using object storage for backups.

You can let the backup script upload (using the [Fog library](https://fog.io/))
the `.tar` file it creates. In the following example, we use Amazon S3 for
storage, but Fog also lets you use [other storage providers](https://fog.io/storage/).
GitLab also [imports cloud drivers](https://gitlab.com/gitlab-org/gitlab/-/blob/da46c9655962df7d49caef0e2b9f6bbe88462a02/Gemfile#L113)
for AWS, Google, and Aliyun. A local driver is
[also available](#upload-to-locally-mounted-shares).

[Read more about using object storage with GitLab](../administration/object_storage.md).

#### Using Amazon S3

For Omnibus GitLab packages:

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-west-1',
     'aws_access_key_id' => 'AKIAKIAKI',
     'aws_secret_access_key' => 'secret123'
     # If using an IAM Profile, don't configure aws_access_key_id & aws_secret_access_key
     # 'use_iam_profile' => true
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
   # Consider using multipart uploads when file size reaches 100MB. Enter a number in bytes.
   # gitlab_rails['backup_multipart_chunk_size'] = 104857600
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect

#### S3 Encrypted Buckets

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64765) in GitLab 14.3.

AWS supports these [modes for server side encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html):

- Amazon S3-Managed Keys (SSE-S3)
- Customer Master Keys (CMKs) Stored in AWS Key Management Service (SSE-KMS)
- Customer-Provided Keys (SSE-C)

Use your mode of choice with GitLab. Each mode has similar, but slightly
different, configuration methods.

##### SSE-S3

To enable SSE-S3, in the backup storage options set the `server_side_encryption`
field to `AES256`. For example, in Omnibus GitLab:

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'AES256'
}
```

##### SSE-KMS

To enable SSE-KMS, you need the
[KMS key via its Amazon Resource Name (ARN) in the `arn:aws:kms:region:acct-id:key/key-id` format](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html).
Under the `backup_upload_storage_options` configuration setting, set:

- `server_side_encryption` to `aws:kms`.
- `server_side_encryption_kms_key_id` to the ARN of the key.

For example, in Omnibus GitLab:

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'aws:kms',
  'server_side_encryption_kms_key_id' => 'arn:aws:<YOUR KMS KEY ID>:'
}
```

##### SSE-C

SSE-C requires you to set these encryption options:

- `backup_encryption`: AES256.
- `backup_encryption_key`: Unencoded, 32-byte (256 bits) key. The upload fails if this isn't exactly 32 bytes.

For example, in Omnibus GitLab:

```ruby
gitlab_rails['backup_encryption'] = 'AES256'
gitlab_rails['backup_encryption_key'] = '<YOUR 32-BYTE KEY HERE>'
```

If the key contains binary characters and cannot be encoded in UTF-8,
instead, specify the key with the `GITLAB_BACKUP_ENCRYPTION_KEY` environment variable.
For example:

```ruby
gitlab_rails['env'] = { 'GITLAB_BACKUP_ENCRYPTION_KEY' => "\xDE\xAD\xBE\xEF" * 8 }
```

#### Digital Ocean Spaces

This example can be used for a bucket in Amsterdam (AMS3):

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'ams3',
     'aws_access_key_id' => 'AKIAKIAKI',
     'aws_secret_access_key' => 'secret123',
     'endpoint'              => 'https://ams3.digitaloceanspaces.com'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect

If you see a `400 Bad Request` error message when using Digital Ocean Spaces,
the cause may be the use of backup encryption. Because Digital Ocean Spaces
doesn't support encryption, remove or comment the line that contains
`gitlab_rails['backup_encryption']`.

#### Other S3 Providers

Not all S3 providers are fully compatible with the Fog library. For example,
if you see a `411 Length Required` error message after attempting to upload,
you may need to downgrade the `aws_signature_version` value from the default
value to `2`, [due to this issue](https://github.com/fog/fog-aws/issues/428).

For installations from source:

1. Edit `home/git/gitlab/config/gitlab.yml`:

   ```yaml
     backup:
       # snip
       upload:
         # Fog storage connection settings, see https://fog.io/storage/ .
         connection:
           provider: AWS
           region: eu-west-1
           aws_access_key_id: AKIAKIAKI
           aws_secret_access_key: 'secret123'
           # If using an IAM Profile, leave aws_access_key_id & aws_secret_access_key empty
           # ie. aws_access_key_id: ''
           # use_iam_profile: 'true'
         # The remote 'directory' to store your backups. For S3, this would be the bucket name.
         remote_directory: 'my.s3.bucket'
         # Specifies Amazon S3 storage class to use for backups, this is optional
         # storage_class: 'STANDARD'
         #
         # Turns on AWS Server-Side Encryption with Amazon Customer-Provided Encryption Keys for backups, this is optional
         #   'encryption' must be set in order for this to have any effect.
         #   'encryption_key' should be set to the 256-bit encryption key for Amazon S3 to use to encrypt or decrypt.
         #   To avoid storing the key on disk, the key can also be specified via the `GITLAB_BACKUP_ENCRYPTION_KEY`  your data.
         # encryption: 'AES256'
         # encryption_key: '<key>'
         #
         #
         # Turns on AWS Server-Side Encryption with Amazon S3-Managed keys (optional)
         # https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html
         # For SSE-S3, set 'server_side_encryption' to 'AES256'.
         # For SS3-KMS, set 'server_side_encryption' to 'aws:kms'. Set
         # 'server_side_encryption_kms_key_id' to the ARN of customer master key.
         # storage_options:
         #   server_side_encryption: 'aws:kms'
         #   server_side_encryption_kms_key_id: 'arn:aws:kms:YOUR-KEY-ID-HERE'
   ```

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   for the changes to take effect

If you're uploading your backups to S3, you should create a new
IAM user with restricted access rights. To give the upload user access only for
uploading backups create the following IAM profile, replacing `my.s3.bucket`
with the name of your bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1412062044000",
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
        "arn:aws:s3:::my.s3.bucket/*"
      ]
    },
    {
      "Sid": "Stmt1412062097000",
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Sid": "Stmt1412062128000",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my.s3.bucket"
      ]
    }
  ]
}
```

#### Using Google Cloud Storage

To use Google Cloud Storage to save backups, you must first create an
access key from the Google console:

1. Go to the [Google storage settings page](https://console.cloud.google.com/storage/settings).
1. Select **Interoperability**, and then create an access key.
1. Make note of the **Access Key** and **Secret** and replace them in the
   following configurations.
1. In the buckets advanced settings ensure the Access Control option
   **Set object-level and bucket-level permissions** is selected.
1. Ensure you have already created a bucket.

For Omnibus GitLab packages:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'Google',
     'google_storage_access_key_id' => 'Access Key',
     'google_storage_secret_access_key' => 'Secret',

     ## If you have CNAME buckets (foo.example.com), you might run into SSL issues
     ## when uploading backups ("hostname foo.example.com.storage.googleapis.com
     ## does not match the server certificate"). In that case, uncomnent the following
     ## setting. See: https://github.com/fog/fog/issues/2834
     #'path_style' => true
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.google.bucket'
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect

For installations from source:

1. Edit `home/git/gitlab/config/gitlab.yml`:

   ```yaml
     backup:
       upload:
         connection:
           provider: 'Google'
           google_storage_access_key_id: 'Access Key'
           google_storage_secret_access_key: 'Secret'
         remote_directory: 'my.google.bucket'
   ```

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   for the changes to take effect

#### Using Azure Blob storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25877) in GitLab 13.4.

For Omnibus GitLab packages:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
    'provider' => 'AzureRM',
    'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
    'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
    'azure_storage_domain' => 'blob.core.windows.net', # Optional
   }
   gitlab_rails['backup_upload_remote_directory'] = '<AZURE BLOB CONTAINER>'
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect

For installations from source:

1. Edit `home/git/gitlab/config/gitlab.yml`:

   ```yaml
     backup:
       upload:
         connection:
           provider: 'AzureRM'
           azure_storage_account_name: '<AZURE STORAGE ACCOUNT NAME>'
           azure_storage_access_key: '<AZURE STORAGE ACCESS KEY>'
         remote_directory: '<AZURE BLOB CONTAINER>'
   ```

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   for the changes to take effect

For more details, see the [table of Azure parameters](../administration/object_storage.md#azure-blob-storage).

#### Specifying a custom directory for backups

This option works only for remote storage. If you want to group your backups,
you can pass a `DIRECTORY` environment variable:

```shell
sudo gitlab-backup create DIRECTORY=daily
sudo gitlab-backup create DIRECTORY=weekly
```

Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:create` instead.

### Skip uploading backups to remote storage

If you have configured GitLab to [upload backups in a remote storage](#upload-backups-to-a-remote-cloud-storage),
you can use the `SKIP=remote` option to skip uploading your backups to the remote storage.

For Omnibus GitLab packages:

```shell
sudo gitlab-backup create SKIP=remote
```

For installations from source:

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=remote RAILS_ENV=production
```

### Upload to locally-mounted shares

You can send backups to a locally-mounted share (for example, `NFS`,`CIFS`, or `SMB`) using the Fog
[`Local`](https://github.com/fog/fog-local#usage) storage provider.

To do this, you must set the following configuration keys:

- `backup_upload_connection.local_root`: mounted directory that backups are copied to.
- `backup_upload_remote_directory`: subdirectory of the `backup_upload_connection.local_root` directory. It is created if it doesn't exist.
  If you want to copy the tarballs to the root of your mounted directory, use `.`.

When mounted, the directory set in the `local_root` key must be owned by either:

- The `git` user. So, mounting with the `uid=` of the `git` user for `CIFS` and `SMB`.
- The user that you are executing the backup tasks as. For Omnibus GitLab, this is the `git` user.

Because file system performance may affect overall GitLab performance,
[we don't recommend using cloud-based file systems for storage](../administration/nfs.md#avoid-using-cloud-based-file-systems).

#### Avoid conflicting configuration

Don't set the following configuration keys to the same path:

- `gitlab_rails['backup_path']` (`backup.path` for source installations).
- `gitlab_rails['backup_upload_connection'].local_root` (`backup.upload.connection.local_root` for source installations).

The `backup_path` configuration key sets the local location of the backup file. The `upload` configuration key is
intended for use when the backup file is uploaded to a separate server, perhaps for archival purposes.

If these configuration keys are set to the same location, the upload feature fails because a backup already exists at
the upload location. This failure causes the upload feature to delete the backup because it assumes it's a residual file
remaining after the failed upload attempt.

#### Configure uploads to locally-mounted shares

For Omnibus GitLab packages:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     :provider => 'Local',
     :local_root => '/mnt/backups'
   }

   # The directory inside the mounted folder to copy backups to
   # Use '.' to store them in the root directory
   gitlab_rails['backup_upload_remote_directory'] = 'gitlab_backups'
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

For installations from source:

1. Edit `home/git/gitlab/config/gitlab.yml`:

   ```yaml
   backup:
     upload:
       # Fog storage connection settings, see https://fog.io/storage/ .
       connection:
         provider: Local
         local_root: '/mnt/backups'
       # The directory inside the mounted folder to copy backups to
       # Use '.' to store them in the root directory
       remote_directory: 'gitlab_backups'
   ```

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   for the changes to take effect.

### Backup archive permissions

The backup archives created by GitLab (`1393513186_2014_02_27_gitlab_backup.tar`)
have the owner/group `git`/`git` and 0600 permissions by default. This is
meant to avoid other system users reading GitLab data. If you need the backup
archives to have different permissions, you can use the `archive_permissions`
setting.

For Omnibus GitLab packages:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_archive_permissions'] = 0644 # Makes the backup archives world-readable
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

For installations from source:

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   backup:
     archive_permissions: 0644 # Makes the backup archives world-readable
   ```

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   for the changes to take effect.

### Configuring cron to make daily backups

WARNING:
The following cron jobs do not [back up your GitLab configuration files](#storing-configuration-files)
or [SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079).

You can schedule a cron job that backs up your repositories and GitLab metadata.

For Omnibus GitLab packages:

1. Edit the crontab for the `root` user:

   ```shell
   sudo su -
   crontab -e
   ```

1. There, add the following line to schedule the backup for everyday at 2 AM:

   ```plaintext
   0 2 * * * /opt/gitlab/bin/gitlab-backup create CRON=1
   ```

   Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:create` instead.

For installations from source:

1. Edit the crontab for the `git` user:

   ```shell
   sudo -u git crontab -e
   ```

1. Add the following lines at the bottom:

   ```plaintext
   # Create a full backup of the GitLab repositories and SQL database every day at 2am
   0 2 * * * cd /home/git/gitlab && PATH=/usr/local/bin:/usr/bin:/bin bundle exec rake gitlab:backup:create RAILS_ENV=production CRON=1
   ```

The `CRON=1` environment setting directs the backup script to hide all progress
output if there aren't any errors. This is recommended to reduce cron spam.
When troubleshooting backup problems, however, replace `CRON=1` with `--trace` to log verbosely.

## Limit backup lifetime for local files (prune old backups)

WARNING:
The process described in this section doesn't work if you used a [custom filename](#backup-filename)
for your backups.

To prevent regular backups from using all your disk space, you may want to set a limited lifetime
for backups. The next time the backup task runs, backups older than the `backup_keep_time` are
pruned.

This configuration option manages only local files. GitLab doesn't prune old
files stored in a third-party [object storage](#upload-backups-to-a-remote-cloud-storage)
because the user may not have permission to list and delete files. It's
recommended that you configure the appropriate retention policy for your object
storage (for example, [AWS S3](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/create-lifecycle.html)).

For Omnibus GitLab packages:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect.

For installations from source:

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   backup:
     ## Limit backup lifetime to 7 days - 604800 seconds
     keep_time: 604800
   ```

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   for the changes to take effect.
