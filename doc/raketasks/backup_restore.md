---
stage: Enablement
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Back up and restore GitLab **(FREE SELF)**

GitLab provides Rake tasks for backing up and restoring GitLab instances.

An application data backup creates an archive file that contains the database,
all repositories and all attachments.

You can only restore a backup to **exactly the same version and type (CE/EE)**
of GitLab on which it was created. The best way to [migrate your projects
from one server to another](#migrate-to-a-new-server) is through a backup and restore.

WARNING:
GitLab doesn't back up items that aren't stored on the file system. If you're
using [object storage](../administration/object_storage.md), be sure to enable
backups with your object storage provider, if desired.

## Requirements

To be able to back up and restore, ensure that Rsync is installed on your
system. If you installed GitLab:

- _Using the Omnibus package_, you're all set.
- _From source_, you need to determine if `rsync` is installed. For example:

  ```shell
  # Debian/Ubuntu
  sudo apt-get install rsync

  # RHEL/CentOS
  sudo yum install rsync
  ```

## Backup timestamp

The backup archive is saved in `backup_path`, which is specified in the
`config/gitlab.yml` file. The filename is `[TIMESTAMP]_gitlab_backup.tar`,
where `TIMESTAMP` identifies the time at which each backup was created, plus
the GitLab version. The timestamp is needed if you need to restore GitLab and
multiple backups are available.

For example, if the backup name is `1493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar`,
the timestamp is `1493107454_2018_04_25_10.6.4-ce`.

## Back up GitLab

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
The backup command requires [additional parameters](#back-up-and-restore-for-installations-using-pgbouncer) when
your installation is using PgBouncer, for either performance reasons or when using it with a Patroni cluster.

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

### Storing configuration files

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

For [Docker installations](https://docs.gitlab.com/omnibus/docker/), you must
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
[troubleshooting section](#when-the-secrets-file-is-lost).

### Backup options

The command line tool GitLab provides to backup your instance can accept more
options.

#### Backup strategy option

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

#### Backup filename

WARNING:
If you use a custom backup filename, you can't
[limit the lifetime of the backups](#limit-backup-lifetime-for-local-files-prune-old-backups).

By default, a backup file is created according to the specification in the
previous [Backup timestamp](#backup-timestamp) section. You can, however,
override the `[TIMESTAMP]` portion of the filename by setting the `BACKUP`
environment variable. For example:

```shell
sudo gitlab-backup create BACKUP=dump
```

Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:create` instead.

The resulting file is named `dump_gitlab_backup.tar`. This is useful for
systems that make use of rsync and incremental backups, and results in
considerably faster transfer speeds.

#### Confirm archive can be transferred

To ensure the generated archive is transferable by rsync, you can set the `GZIP_RSYNCABLE=yes`
option. This sets the `--rsyncable` option to `gzip`, which is useful only in
combination with setting [the Backup filename option](#backup-filename).

Note that the `--rsyncable` option in `gzip` isn't guaranteed to be available
on all distributions. To verify that it's available in your distribution, run
`gzip --help` or consult the man pages.

```shell
sudo gitlab-backup create BACKUP=dump GZIP_RSYNCABLE=yes
```

Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:create` instead.

#### Excluding specific directories from the backup

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

All wikis are backed up as part of the `repositories` group. Non-existent wikis are skipped during a backup.

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

#### Skipping tar creation

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

#### Disabling prompts during restore

During a restore from backup, the restore script may ask for confirmation before
proceeding. If you wish to disable these prompts, you can set the `GITLAB_ASSUME_YES`
environment variable to `1`.

For Omnibus GitLab packages:

```shell
sudo GITLAB_ASSUME_YES=1 gitlab-backup restore
```

For installations from source:

```shell
sudo -u git -H GITLAB_ASSUME_YES=1 bundle exec rake gitlab:backup:restore RAILS_ENV=production
```

#### Back up Git repositories concurrently

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

#### Uploading backups to a remote (cloud) storage

You can let the backup script upload (using the [Fog library](http://fog.io/))
the `.tar` file it creates. In the following example, we use Amazon S3 for
storage, but Fog also lets you use [other storage providers](http://fog.io/storage/).
GitLab also [imports cloud drivers](https://gitlab.com/gitlab-org/gitlab/-/blob/da46c9655962df7d49caef0e2b9f6bbe88462a02/Gemfile#L113)
for AWS, Google, OpenStack Swift, Rackspace, and Aliyun. A local driver is
[also available](#uploading-to-locally-mounted-shares).

[Read more about using object storage with GitLab](../administration/object_storage.md).

##### Using Amazon S3

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
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect

##### S3 Encrypted Buckets

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64765) in GitLab 14.3.

AWS supports these [modes for server side encryption](https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html):

- Amazon S3-Managed Keys (SSE-S3)
- Customer Master Keys (CMKs) Stored in AWS Key Management Service (SSE-KMS)
- Customer-Provided Keys (SSE-C)

Use your mode of choice with GitLab. Each mode has similar, but slightly
different, configuration methods.

###### SSE-S3

To enable SSE-S3, in the backup storage options set the `server_side_encryption`
field to `AES256`. For example, in Omnibus GitLab:

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'AES256'
}
```

###### SSE-KMS

To enable SSE-KMS, you'll need the [KMS key via its Amazon Resource Name (ARN)
in the `arn:aws:kms:region:acct-id:key/key-id` format](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html). Under the `backup_upload_storage_options` config setting, set:

- `server_side_encryption` to `aws:kms`.
- `server_side_encryption_kms_key_id` to the ARN of the key.

For example, in Omnibus GitLab:

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'aws:kms',
  'server_side_encryption_kms_key_id' => 'arn:aws:<YOUR KMS KEY ID>:'
}
```

###### SSE-C

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

##### Digital Ocean Spaces

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

##### Other S3 Providers

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
         # Fog storage connection settings, see http://fog.io/storage/ .
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

##### Using Google Cloud Storage

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

##### Using Azure Blob storage

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

##### Specifying a custom directory for backups

This option works only for remote storage. If you want to group your backups,
you can pass a `DIRECTORY` environment variable:

```shell
sudo gitlab-backup create DIRECTORY=daily
sudo gitlab-backup create DIRECTORY=weekly
```

Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:create` instead.

#### Uploading to locally mounted shares

You may also send backups to a mounted share (for example, `NFS`,`CIFS`, or
`SMB`) by using the Fog [`Local`](https://github.com/fog/fog-local#usage)
storage provider. The directory pointed to by the `local_root` key _must_ be
owned by the `git` user _when mounted_ (mounting with the `uid=` of the `git`
user for `CIFS` and `SMB`) or the user that you are executing the backup tasks
as (for Omnibus packages, this is the `git` user).

The `backup_upload_remote_directory` _must_ be set in addition to the
`local_root` key. This is the sub directory inside the mounted directory that
backups are copied to, and is created if it does not exist. If the
directory that you want to copy the tarballs to is the root of your mounted
directory, use `.` instead.

Because file system performance may affect overall GitLab performance,
[GitLab doesn't recommend using cloud-based file systems for storage](../administration/nfs.md#avoid-using-cloud-based-file-systems).

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
       # Fog storage connection settings, see http://fog.io/storage/ .
       connection:
         provider: Local
         local_root: '/mnt/backups'
       # The directory inside the mounted folder to copy backups to
       # Use '.' to store them in the root directory
       remote_directory: 'gitlab_backups'
   ```

1. [Restart GitLab](../administration/restart_gitlab.md#installations-from-source)
   for the changes to take effect.

#### Backup archive permissions

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

#### Configuring cron to make daily backups

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

### Limit backup lifetime for local files (prune old backups)

WARNING:
The process described in this section don't work if you used a [custom filename](#backup-filename)
for your backups.

To prevent regular backups from using all your disk space, you may want to set a limited lifetime
for backups. The next time the backup task runs, backups older than the `backup_keep_time` are
pruned.

This configuration option manages only local files. GitLab doesn't prune old
files stored in a third-party [object storage](#uploading-backups-to-a-remote-cloud-storage)
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

## Restore GitLab

GitLab provides a command line interface to restore your entire installation,
and is flexible enough to fit your needs.

The [restore prerequisites section](#restore-prerequisites) includes crucial
information. Be sure to read and test the complete restore process at least
once before attempting to perform it in a production environment.

You can restore a backup only to _the exact same version and type (CE/EE)_ of
GitLab that you created it on (for example CE 9.1.0).

If your backup is a different version than the current installation, you must
[downgrade your GitLab installation](../update/package/downgrade.md)
before restoring the backup.

### Restore prerequisites

You need to have a working GitLab installation before you can perform a
restore. This is because the system user performing the restore actions (`git`)
is usually not allowed to create or delete the SQL database needed to import
data into (`gitlabhq_production`). All existing data is either erased
(SQL) or moved to a separate directory (such as repositories and uploads).

To restore a backup, you must restore `/etc/gitlab/gitlab-secrets.json`
(for Omnibus packages) or `/home/git/gitlab/.secret` (for installations from
source). This file contains the database encryption key,
[CI/CD variables](../ci/variables/index.md), and
variables used for [two-factor authentication](../user/profile/account/two_factor_authentication.md).
If you fail to restore this encryption key file along with the application data
backup, users with two-factor authentication enabled and GitLab Runner
loses access to your GitLab server.

You may also want to restore your previous `/etc/gitlab/gitlab.rb` (for Omnibus packages)
or `/home/git/gitlab/config/gitlab.yml` (for installations from source) and
any TLS keys, certificates (`/etc/gitlab/ssl`, `/etc/gitlab/trusted-certs`), or
[SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079).

Starting with GitLab 12.9, if an untarred backup (like the ones made with
`SKIP=tar`) is found, and no backup is chosen with `BACKUP=<timestamp>`, the
untarred backup is used.

Depending on your case, you might want to run the restore command with one or
more of the following options:

- `BACKUP=timestamp_of_backup`: Required if more than one backup exists.
  Read what the [backup timestamp is about](#backup-timestamp).
- `force=yes`: Doesn't ask if the authorized_keys file should get regenerated,
  and assumes 'yes' for warning about database tables being removed,
  enabling the "Write to authorized_keys file" setting, and updating LDAP
  providers.

If you're restoring into directories that are mount points, you must ensure these directories are
empty before attempting a restore. Otherwise, GitLab attempts to move these directories before
restoring the new data, which causes an error.

Read more about [configuring NFS mounts](../administration/nfs.md)

### Restore for Omnibus GitLab installations

This procedure assumes that:

- You have installed the **exact same version and type (CE/EE)** of GitLab
  Omnibus with which the backup was created.
- You have run `sudo gitlab-ctl reconfigure` at least once.
- GitLab is running. If not, start it using `sudo gitlab-ctl start`.

First ensure your backup tar file is in the backup directory described in the
`gitlab.rb` configuration `gitlab_rails['backup_path']`. The default is
`/var/opt/gitlab/backups`. It needs to be owned by the `git` user.

```shell
sudo cp 11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar /var/opt/gitlab/backups/
sudo chown git.git /var/opt/gitlab/backups/11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar
```

Stop the processes that are connected to the database. Leave the rest of GitLab
running:

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
# Verify
sudo gitlab-ctl status
```

Next, restore the backup, specifying the timestamp of the backup you wish to
restore:

```shell
# This command will overwrite the contents of your GitLab database!
sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:restore` instead.

WARNING:
`gitlab-rake gitlab:backup:restore` doesn't set the correct file system
permissions on your Registry directory. This is a [known issue](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62759).
In GitLab 12.2 or later, you can use `gitlab-backup restore` to avoid this
issue.

If there's a GitLab version mismatch between your backup tar file and the
installed version of GitLab, the restore command aborts with an error
message. Install the [correct GitLab version](https://packages.gitlab.com/gitlab/),
and then try again.

WARNING:
The restore command requires [additional parameters](#back-up-and-restore-for-installations-using-pgbouncer) when
your installation is using PgBouncer, for either performance reasons or when using it with a Patroni cluster.

Next, restore `/etc/gitlab/gitlab-secrets.json` if necessary,
[as previously mentioned](#restore-prerequisites).

Reconfigure, restart and [check](../administration/raketasks/maintenance.md#check-gitlab-configuration) GitLab:

```shell
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
sudo gitlab-rake gitlab:check SANITIZE=true
```

In GitLab 13.1 and later, check [database values can be decrypted](../administration/raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)
especially if `/etc/gitlab/gitlab-secrets.json` was restored, or if a different server is
the target for the restore.

```shell
sudo gitlab-rake gitlab:doctor:secrets
```

For added assurance, you can perform [an integrity check on the uploaded files](../administration/raketasks/check.md#uploaded-files-integrity):

```shell
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

### Restore for Docker image and GitLab Helm chart installations

For GitLab installations using the Docker image or the GitLab Helm chart on a
Kubernetes cluster, the restore task expects the restore directories to be
empty. However, with Docker and Kubernetes volume mounts, some system level
directories may be created at the volume roots, such as the `lost+found`
directory found in Linux operating systems. These directories are usually owned
by `root`, which can cause access permission errors since the restore Rake task
runs as the `git` user. To restore a GitLab installation, users have to confirm
the restore target directories are empty.

For both these installation types, the backup tarball has to be available in
the backup location (default location is `/var/opt/gitlab/backups`).

For Docker installations, the restore task can be run from host:

```shell
# Stop the processes that are connected to the database
docker exec -it <name of container> gitlab-ctl stop puma
docker exec -it <name of container> gitlab-ctl stop sidekiq

# Verify that the processes are all down before continuing
docker exec -it <name of container> gitlab-ctl status

# Run the restore. NOTE: "_gitlab_backup.tar" is omitted from the name
docker exec -it <name of container> gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce

# Restart the GitLab container
docker restart <name of container>

# Check GitLab
docker exec -it <name of container> gitlab-rake gitlab:check SANITIZE=true
```

Users of GitLab 12.1 and earlier should use the command `gitlab-rake gitlab:backup:create` instead.

WARNING:
`gitlab-rake gitlab:backup:restore` doesn't set the correct file system
permissions on your Registry directory. This is a [known issue](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62759).
In GitLab 12.2 or later, you can use `gitlab-backup restore` to avoid this
issue.

The GitLab Helm chart uses a different process, documented in
[restoring a GitLab Helm chart installation](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/backup-restore/restore.md).

### Restore for installation from source

First, ensure your backup tar file is in the backup directory described in the
`gitlab.yml` configuration:

```yaml
## Backup settings
backup:
  path: "tmp/backups"   # Relative paths are relative to Rails.root (default: tmp/backups/)
```

The default is `/home/git/gitlab/tmp/backups`, and it needs to be owned by the `git` user. Now, you can begin the backup procedure:

```shell
# Stop processes that are connected to the database
sudo service gitlab stop

sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
```

Example output:

```plaintext
Unpacking backup... [DONE]
Restoring database tables:
-- create_table("events", {:force=>true})
   -> 0.2231s
[...]
- Loading fixture events...[DONE]
- Loading fixture issues...[DONE]
- Loading fixture keys...[SKIPPING]
- Loading fixture merge_requests...[DONE]
- Loading fixture milestones...[DONE]
- Loading fixture namespaces...[DONE]
- Loading fixture notes...[DONE]
- Loading fixture projects...[DONE]
- Loading fixture protected_branches...[SKIPPING]
- Loading fixture schema_migrations...[DONE]
- Loading fixture services...[SKIPPING]
- Loading fixture snippets...[SKIPPING]
- Loading fixture taggings...[SKIPPING]
- Loading fixture tags...[SKIPPING]
- Loading fixture users...[DONE]
- Loading fixture users_projects...[DONE]
- Loading fixture web_hooks...[SKIPPING]
- Loading fixture wikis...[SKIPPING]
Restoring repositories:
- Restoring repository abcd... [DONE]
- Object pool 1 ...
Deleting tmp directories...[DONE]
```

Next, restore `/home/git/gitlab/.secret` if necessary, [as previously mentioned](#restore-prerequisites).

Restart GitLab:

```shell
sudo service gitlab restart
```

### Restoring only one or a few projects or groups from a backup

Although the Rake task used to restore a GitLab instance doesn't support
restoring a single project or group, you can use a workaround by restoring
your backup to a separate, temporary GitLab instance, and then export your
project or group from there:

1. [Install a new GitLab](../install/index.md) instance at the same version as
   the backed-up instance from which you want to restore.
1. [Restore the backup](#restore-gitlab) into this new instance, then
   export your [project](../user/project/settings/import_export.md)
   or [group](../user/group/settings/import_export.md). Be sure to read the
   **Important Notes** on either export feature's documentation to understand
   what is and isn't exported.
1. After the export is complete, go to the old instance and then import it.
1. After importing the projects or groups that you wanted is complete, you may
   delete the new, temporary GitLab instance.

A feature request to provide direct restore of individual projects or groups
is being discussed in [issue #17517](https://gitlab.com/gitlab-org/gitlab/-/issues/17517).

## Alternative backup strategies

If your GitLab instance contains a lot of Git repository data, you may find the
GitLab backup script to be too slow. If your GitLab instance has a lot of forked
projects, the regular backup task also duplicates the Git data for all of them.
In these cases, consider using file system snapshots as part of your backup strategy.

Example: Amazon Elastic Block Store (EBS)

> A GitLab server using Omnibus GitLab hosted on Amazon AWS.
> An EBS drive containing an ext4 file system is mounted at `/var/opt/gitlab`.
> In this case you could make an application backup by taking an EBS snapshot.
> The backup includes all repositories, uploads and PostgreSQL data.

Example: Logical Volume Manager (LVM) snapshots + rsync

> A GitLab server using Omnibus GitLab, with an LVM logical volume mounted at `/var/opt/gitlab`.
> Replicating the `/var/opt/gitlab` directory using rsync would not be reliable because too many files would change while rsync is running.
> Instead of rsync-ing `/var/opt/gitlab`, we create a temporary LVM snapshot, which we mount as a read-only file system at `/mnt/gitlab_backup`.
> Now we can have a longer running rsync job which creates a consistent replica on the remote server.
> The replica includes all repositories, uploads and PostgreSQL data.

If you're running GitLab on a virtualized server, you can possibly also create
VM snapshots of the entire GitLab server. It's not uncommon however for a VM
snapshot to require you to power down the server, which limits this solution's
practical use.

### Back up repository data separately

First, ensure you back up existing GitLab data while [skipping repositories](#excluding-specific-directories-from-the-backup):

```shell
# for Omnibus GitLab package installations
sudo gitlab-backup create SKIP=repositories

# for installations from source:
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=repositories RAILS_ENV=production
```

For manually backing up the Git repository data on disk, there are multiple possible strategies:

- Use snapshots, such as the previous examples of Amazon EBS drive snapshots, or LVM snapshots + rsync.
- Use [GitLab Geo](../administration/geo/index.md) and rely on the repository data on a Geo secondary site.
- [Prevent writes and copy the Git repository data](#prevent-writes-and-copy-the-git-repository-data).
- [Create an online backup by marking repositories as read-only (experimental)](#online-backup-through-marking-repositories-as-read-only-experimental).

#### Prevent writes and copy the Git repository data

Git repositories must be copied in a consistent way. They should not be copied during concurrent write
operations, as this can lead to inconsistencies or corruption issues. For more details,
[issue #270422](https://gitlab.com/gitlab-org/gitlab/-/issues/270422 "Provide documentation on preferred method of migrating Gitaly servers")
has a longer discussion explaining the potential problems.

To prevent writes to the Git repository data, there are two possible approaches:

- Use [maintenance mode](../administration/maintenance_mode/index.md) **(PREMIUM SELF)** to place GitLab in a read-only state.
- Create explicit downtime by stopping all Gitaly services before backing up the repositories:

  ```shell
  sudo gitlab-ctl stop gitaly
  # execute git data copy step
  sudo gitlab-ctl start gitaly
  ```

You can copy Git repository data using any method, as long as writes are prevented on the data being copied
(to prevent inconsistencies and corruption issues). In order of preference and safety, the recommended methods are:

1. Use `rsync` with archive-mode, delete, and checksum options, for example:

   ```shell
   rsync -aR --delete --checksum source destination # be extra safe with the order as it will delete existing data if inverted
   ```

1. Use a [`tar` pipe to copy the entire repository's directory to another server or location](../administration/operations/moving_repositories.md#tar-pipe-to-another-server).

1. Use `sftp`, `scp`, `cp`, or any other copying method.

#### Online backup through marking repositories as read-only (experimental)

One way of backing up repositories without requiring instance-wide downtime
is to programmatically mark projects as read-only while copying the underlying data.

There are a few possible downsides to this:

- Repositories are read-only for a period of time that scales with the size of the repository.
- Backups take a longer time to complete due to marking each project as read-only, potentially leading to inconsistencies. For example,
  a possible date discrepancy between the last data available for the first project that gets backed up compared to
  the last project that gets backed up.
- Fork networks should be entirely read-only while the projects inside get backed up to prevent potential changes to the pool repository.

There is an **experimental** script that attempts to automate this process in
[the Geo team Runbooks project](https://gitlab.com/gitlab-org/geo-team/runbooks/-/tree/main/experimental-online-backup-through-rsync).

## Back up and restore for installations using PgBouncer

Do NOT back up or restore GitLab through a PgBouncer connection. These
tasks must [bypass PgBouncer and connect directly to the PostgreSQL primary database node](#bypassing-pgbouncer),
or they cause a GitLab outage.

When the GitLab backup or restore task is used with PgBouncer, the
following error message is shown:

```ruby
ActiveRecord::StatementInvalid: PG::UndefinedTable
```

Each time the GitLab backup runs, GitLab will start generating 500 errors and errors about missing
tables will [be logged by PostgreSQL](../administration/logs.md#postgresql-logs):

```plaintext
ERROR: relation "tablename" does not exist at character 123
```

This happens because the task uses `pg_dump`, which [sets a null search
path and explicitly includes the schema in every SQL query](https://gitlab.com/gitlab-org/gitlab/-/issues/23211)
to address [CVE-2018-1058](https://www.postgresql.org/about/news/postgresql-103-968-9512-9417-and-9322-released-1834/).

Since connections are reused with PgBouncer in transaction pooling mode,
PostgreSQL fails to search the default `public` schema. As a result,
this clearing of the search path causes tables and columns to appear
missing.

### Bypassing PgBouncer

There are two ways to fix this:

1. [Use environment variables to override the database settings](#environment-variable-overrides) for the backup task.
1. Reconfigure a node to [connect directly to the PostgreSQL primary database node](../administration/postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer).

#### Environment variable overrides

By default, GitLab uses the database configuration stored in a
configuration file (`database.yml`). However, you can override the database settings
for the backup and restore task by setting environment
variables that are prefixed with `GITLAB_BACKUP_`:

- `GITLAB_BACKUP_PGHOST`
- `GITLAB_BACKUP_PGUSER`
- `GITLAB_BACKUP_PGPORT`
- `GITLAB_BACKUP_PGPASSWORD`
- `GITLAB_BACKUP_PGSSLMODE`
- `GITLAB_BACKUP_PGSSLKEY`
- `GITLAB_BACKUP_PGSSLCERT`
- `GITLAB_BACKUP_PGSSLROOTCERT`
- `GITLAB_BACKUP_PGSSLCRL`
- `GITLAB_BACKUP_PGSSLCOMPRESSION`

For example, to override the database host and port to use 192.168.1.10
and port 5432 with the Omnibus package:

```shell
sudo GITLAB_BACKUP_PGHOST=192.168.1.10 GITLAB_BACKUP_PGPORT=5432 /opt/gitlab/bin/gitlab-backup create
```

See the [PostgreSQL documentation](https://www.postgresql.org/docs/12/libpq-envars.html)
for more details on what these parameters do.

## Migrate to a new server

<!-- some details borrowed from GitLab.com move from Azure to GCP detailed at https://gitlab.com/gitlab-com/migration/-/blob/master/.gitlab/issue_templates/failover.md -->

You can use GitLab backup and restore to migrate your instance to a new server. This section outlines a typical procedure for a GitLab deployment running on a single server.
If you're running GitLab Geo, an alternative option is [Geo disaster recovery for planned failover](../administration/geo/disaster_recovery/planned_failover.md).

WARNING:
Avoid uncoordinated data processing by both the new and old servers, where multiple
servers could connect concurrently and process the same data. For example, when using
[incoming email](../administration/incoming_email.md), if both GitLab instances are
processing email at the same time, then both instances will end up missing some data.
This type of problem can occur with other services as well, such as a
[non-packaged database](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server),
a non-packaged Redis instance, or non-packaged Sidekiq.

Prerequisites:

- Some time before your migration, consider notifying your users of upcoming
  scheduled maintenance with a [broadcast message banner](../user/admin_area/broadcast_messages.md).
- Ensure your backups are complete and current. Create a complete system-level backup, or
  take a snapshot of all servers involved in the migration, in case destructive commands
  (like `rm`) are run incorrectly.

### Prepare the new server

To prepare the new server:

1. Copy the
   [SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)
   from the old server to avoid man-in-the-middle attack warnings.
1. [Install and configure GitLab](https://about.gitlab.com/install) except
   [incoming email](../administration/incoming_email.md):
   1. Install GitLab.
   1. Configure by copying `/etc/gitlab` files from the old server to the new server, and update as necessary.
      Read the
      [Omnibus configuration backup and restore instructions](https://docs.gitlab.com/omnibus/settings/backups.html) for more detail.
   1. If applicable, disable [incoming email](../administration/incoming_email.md).
   1. Block new CI/CD jobs from starting upon initial startup after the backup and restore.
      Edit `/etc/gitlab/gitlab.rb` and set the following:

      ```ruby
      nginx['custom_gitlab_server_config'] = "location /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
      ```

   1. Reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. Stop GitLab to avoid any potential unnecessary and unintentional data processing:

   ```shell
   sudo gitlab-ctl stop
   ```

1. Configure the new server to allow receiving the Redis database and GitLab backup files:

   ```shell
   sudo rm -f /var/opt/gitlab/redis/dump.rdb
   sudo chown <your-linux-username> /var/opt/gitlab/redis
   sudo mkdir /var/opt/gitlab/backups
   sudo chown <your-linux-username> /var/opt/gitlab/backups
   ```

### Prepare and transfer content from the old server

1. Ensure you have an up-to-date system-level backup or snapshot of the old server.
1. Enable [maintenance mode](../administration/maintenance_mode/index.md) **(PREMIUM SELF)**,
   if supported by your GitLab edition.
1. Block new CI/CD jobs from starting:
   1. Edit `/etc/gitlab/gitlab.rb`, and set the following:

      ```ruby
      nginx['custom_gitlab_server_config'] = "location /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
      ```

   1. Reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. Disable periodic background jobs:
   1. On the top bar, select **Menu > Admin**.
   1. On the left sidebar, select **Monitoring > Background Jobs**.
   1. Under the Sidekiq dashboard, select **Cron** tab and then
      **Disable All**.
1. Wait for the currently running CI/CD jobs to finish, or accept that jobs that have not completed may be lost.
   To view jobs currently running, on the left sidebar, select **Overviews > Jobs**,
   and then select **Running**.
1. Wait for Sidekiq jobs to finish:
   1. On the left sidebar, select **Monitoring > Background Jobs**.
   1. Under the Sidekiq dashboard, select **Queues** and then **Live Poll**.
      Wait for **Busy** and **Enqueued** to drop to 0.
      These queues contain work that has been submitted by your users;
      shutting down before these jobs complete may cause the work to be lost.
      Make note of the numbers shown in the Sidekiq dashboard for post-migration verification.
1. Flush the Redis database to disk, and stop GitLab other than the services needed for migration:

   ```shell
   sudo /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket save && sudo gitlab-ctl stop && sudo gitlab-ctl start postgresql
   ```

1. Create a GitLab backup:

   ```shell
   sudo gitlab-backup create
   ```

1. Disable the following GitLab services and prevent unintentional restarts by adding the following to the bottom of `/etc/gitlab/gitlab.rb`:

   ```ruby
   alertmanager['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_pages['enable'] = false
   gitlab_workhorse['enable'] = false
   grafana['enable'] = false
   logrotate['enable'] = false
   gitlab_rails['incoming_email_enabled'] = false
   nginx['enable'] = false
   node_exporter['enable'] = false
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   prometheus['enable'] = false
   puma['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   registry['enable'] = false
   sidekiq['enable'] = false
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Verify everything is stopped, and confirm no services are running:

   ```shell
   sudo gitlab-ctl status
   ```

1. Transfer the Redis database and GitLab backups to the new server:

   ```shell
   sudo scp /var/opt/gitlab/redis/dump.rdb <your-linux-username>@new-server:/var/opt/gitlab/redis
   sudo scp /var/opt/gitlab/backups/your-backup.tar <your-linux-username>@new-server:/var/opt/gitlab/backups
   ```

### Restore data on the new server

1. Restore appropriate file system permissions:

   ```shell
   sudo chown gitlab-redis /var/opt/gitlab/redis
   sudo chown gitlab-redis:gitlab-redis /var/opt/gitlab/redis/dump.rdb
   sudo chown git:root /var/opt/gitlab/backups
   sudo chown git:git /var/opt/gitlab/backups/your-backup.tar
   ```

1. [Restore the GitLab backup](#restore-gitlab).
1. Verify that the Redis database restored correctly:
   1. On the top bar, select **Menu > Admin**.
   1. On the left sidebar, select **Monitoring > Background Jobs**.
   1. Under the Sidekiq dashboard, verify that the numbers
      match with what was shown on the old server.   
   1. While still under the Sidekiq dashboard, select **Cron** and then **Enable All**
      to re-enable periodic background jobs.
1. Test that read-only operations on the GitLab instance work as expected. For example, browse through project repository files, merge requests, and issues.
1. Disable [Maintenance Mode](../administration/maintenance_mode/index.md) **(PREMIUM SELF)**, if previously enabled.
1. Test that the GitLab instance is working as expected.
1. If applicable, re-enable [incoming email](../administration/incoming_email.md) and test it is working as expected.
1. Update your DNS or load balancer to point at the new server.
1. Unblock new CI/CD jobs from starting by removing the custom NGINX config
   you added previously:

   ```ruby
   # The following line must be removed
   nginx['custom_gitlab_server_config'] = "location /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Remove the scheduled maintenance [broadcast message banner](../user/admin_area/broadcast_messages.md).

## Additional notes

This documentation is for GitLab Community and Enterprise Edition. We back up
GitLab.com and ensure your data is secure. You can't, however, use these
methods to export or back up your data yourself from GitLab.com.

Issues are stored in the database, and can't be stored in Git itself.

To migrate your repositories from one server to another with an up-to-date
version of GitLab, use the [import Rake task](import.md) to do a mass import of
the repository. If you do an import Rake task rather than a backup restore,
you get all of your repositories, but no other data.

## Troubleshooting

The following are possible problems you might encounter, along with potential
solutions.

### Restoring database backup using Omnibus packages outputs warnings

If you're using backup restore procedures, you may encounter the following
warning messages:

```plaintext
ERROR: must be owner of extension pg_trgm
ERROR: must be owner of extension btree_gist
ERROR: must be owner of extension plpgsql
WARNING:  no privileges could be revoked for "public" (two occurrences)
WARNING:  no privileges were granted for "public" (two occurrences)
```

Be advised that the backup is successfully restored in spite of these warning
messages.

The Rake task runs this as the `gitlab` user, which doesn't have superuser
access to the database. When restore is initiated, it also runs as the `gitlab`
user, but it also tries to alter the objects it doesn't have access to.
Those objects have no influence on the database backup or restore, but display
a warning message.

For more information, see:

- PostgreSQL issue tracker:
  - [Not being a superuser](https://www.postgresql.org/message-id/201110220712.30886.adrian.klaver@gmail.com).
  - [Having different owners](https://www.postgresql.org/message-id/2039.1177339749@sss.pgh.pa.us).

- Stack Overflow: [Resulting errors](https://stackoverflow.com/questions/4368789/error-must-be-owner-of-language-plpgsql).

### When the secrets file is lost

If you didn't [back up the secrets file](#storing-configuration-files), you
must complete several steps to get GitLab working properly again.

The secrets file is responsible for storing the encryption key for the columns
that contain required, sensitive information. If the key is lost, GitLab can't
decrypt those columns, preventing access to the following items:

- [CI/CD variables](../ci/variables/index.md)
- [Kubernetes / GCP integration](../user/infrastructure/clusters/index.md)
- [Custom Pages domains](../user/project/pages/custom_domains_ssl_tls_certification/index.md)
- [Project error tracking](../operations/error_tracking.md)
- [Runner authentication](../ci/runners/index.md)
- [Project mirroring](../user/project/repository/mirror/index.md)
- [Web hooks](../user/project/integrations/webhooks.md)

In cases like CI/CD variables and runner authentication, you can experience
unexpected behaviors, such as:

- Stuck jobs.
- 500 errors.

In this case, you must reset all the tokens for CI/CD variables and
runner authentication, which is described in more detail in the following
sections. After resetting the tokens, you should be able to visit your project
and the jobs begin running again.

Use the information in the following sections at your own risk.

#### Verify that all values can be decrypted

You can determine if your database contains values that can't be decrypted by using a
[Rake task](../administration/raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

#### Take a backup

You must directly modify GitLab data to work around your lost secrets file.

WARNING:
Be sure to create a full database backup before attempting any changes.

#### Disable user two-factor authentication (2FA)

Users with 2FA enabled can't sign in to GitLab. In that case, you must
[disable 2FA for everyone](../security/two_factor_authentication.md#disable-2fa-for-everyone),
after which users must reactivate 2FA.

#### Reset CI/CD variables

1. Enter the database console:

   For Omnibus GitLab 14.1 and earlier:

   ```shell
   sudo gitlab-rails dbconsole
   ```

   For Omnibus GitLab 14.2 and later:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For installations from source, GitLab 14.1 and earlier:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production
   ```

   For installations from source, GitLab 14.2 and later:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Examine the `ci_group_variables` and `ci_variables` tables:

   ```sql
   SELECT * FROM public."ci_group_variables";
   SELECT * FROM public."ci_variables";
   ```

   These are the variables that you need to delete.

1. Drop the table:

   ```sql
   DELETE FROM ci_group_variables;
   DELETE FROM ci_variables;
   ```

1. If you know the specific group or project from which you wish to delete variables, you can include a `WHERE` statement to specify that in your `DELETE`:

   ```sql
   DELETE FROM ci_group_variables WHERE group_id = <GROUPID>;
   DELETE FROM ci_variables WHERE project_id = <PROJECTID>;
   ```

You may need to reconfigure or restart GitLab for the changes to take effect.

#### Reset runner registration tokens

1. Enter the database console:

   For Omnibus GitLab 14.1 and earlier:

   ```shell
   sudo gitlab-rails dbconsole
   ```

   For Omnibus GitLab 14.2 and later:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For installations from source, GitLab 14.1 and earlier:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production
   ```

   For installations from source, GitLab 14.2 and later:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Clear all tokens for projects, groups, and the entire instance:

   WARNING:
   The final `UPDATE` operation stops the runners from being able to pick
   up new jobs. You must register new runners.

   ```sql
   -- Clear project tokens
   UPDATE projects SET runners_token = null, runners_token_encrypted = null;
   -- Clear group tokens
   UPDATE namespaces SET runners_token = null, runners_token_encrypted = null;
   -- Clear instance tokens
   UPDATE application_settings SET runners_registration_token_encrypted = null;
   -- Clear key used for JWT authentication
   -- This may break the $CI_JWT_TOKEN job variable:
   -- https://gitlab.com/gitlab-org/gitlab/-/issues/325965
   UPDATE application_settings SET encrypted_ci_jwt_signing_key = null;
   -- Clear runner tokens
   UPDATE ci_runners SET token = null, token_encrypted = null;
   ```

#### Reset pending pipeline jobs

1. Enter the database console:

   For Omnibus GitLab 14.1 and earlier:

   ```shell
   sudo gitlab-rails dbconsole
   ```

   For Omnibus GitLab 14.2 and later:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For installations from source, GitLab 14.1 and earlier:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production
   ```

   For installations from source, GitLab 14.2 and later:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Clear all the tokens for pending jobs:

   ```sql
   -- Clear build tokens
   UPDATE ci_builds SET token = null, token_encrypted = null;
   ```

A similar strategy can be employed for the remaining features. By removing the
data that can't be decrypted, GitLab can be returned to operation, and the
lost data can be manually replaced.

#### Fix project integrations

If you've lost your secrets, the [projects' integrations settings pages](../user/project/integrations/index.md)
are probably displaying `500` error messages.

The fix is to truncate the `web_hooks` table:

1. Enter the database console:

   For Omnibus GitLab 14.1 and earlier:

   ```shell
   sudo gitlab-rails dbconsole
   ```

   For Omnibus GitLab 14.2 and later:

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   For installations from source, GitLab 14.1 and earlier:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production
   ```

   For installations from source, GitLab 14.2 and later:

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Truncate the table:

   ```sql
   -- truncate web_hooks table
   TRUNCATE web_hooks CASCADE;
   ```

### Container Registry push failures after restoring from a backup

If you use the [Container Registry](../user/packages/container_registry/index.md),
pushes to the registry may fail after restoring your backup on an Omnibus GitLab
instance after restoring the registry data.

These failures mention permission issues in the registry logs, similar to:

```plaintext
level=error
msg="response completed with error"
err.code=unknown
err.detail="filesystem: mkdir /var/opt/gitlab/gitlab-rails/shared/registry/docker/registry/v2/repositories/...: permission denied"
err.message="unknown error"
```

This issue is caused by the restore running as the unprivileged user `git`,
which is unable to assign the correct ownership to the registry files during
the restore process ([issue #62759](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62759 "Incorrect permissions on registry filesystem after restore")).

To get your registry working again:

```shell
sudo chown -R registry:registry /var/opt/gitlab/gitlab-rails/shared/registry/docker
```

If you changed the default file system location for the registry, run `chown`
against your custom location, instead of `/var/opt/gitlab/gitlab-rails/shared/registry/docker`.

### Backup fails to complete with Gzip error

When running the backup, you may receive a Gzip error message:

```shell
sudo /opt/gitlab/bin/gitlab-backup create
...
Dumping ...
...
gzip: stdout: Input/output error

Backup failed
```

If this happens, examine the following:

- Confirm there is sufficient disk space for the Gzip operation.
- If NFS is being used, check if the mount option `timeout` is set. The
  default is `600`, and changing this to smaller values results in this error.

### `gitaly-backup` for repository backup and restore

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/333034) in GitLab 14.2.
> - [Deployed behind a feature flag](../user/feature_flags.md), enabled by default.
> - Recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#disable-or-enable-gitaly-backup).

There can be
[risks when disabling released features](../administration/feature_flags.md#risks-when-disabling-released-features).
Refer to this feature's version history for more details.

The `gitaly-backup` binary is used by the backup Rake task to create and restore repository backups from Gitaly.
`gitaly-backup` replaces the previous backup method that directly calls RPCs on Gitaly from GitLab.

The backup Rake task must be able to find this executable. In most cases, you don't need to change
the path to the binary as it should work fine with the default path `/opt/gitlab/embedded/bin/gitaly-backup`.
If you have a specific reason to change the path, it can be configured in Omnibus GitLab packages:

1. Add the following to `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_gitaly_backup_path'] = '/path/to/gitaly-backup'
   ```

1. [Reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   for the changes to take effect

#### Disable or enable `gitaly-backup`

`gitaly-backup` is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can opt to disable it.

To disable it:

```ruby
Feature.disable(:gitaly_backup)
```

To enable it:

```ruby
Feature.enable(:gitaly_backup)
```
