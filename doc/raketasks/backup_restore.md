# Backing up and restoring GitLab

![backup banner](backup_hrz.png)

An application data backup creates an archive file that contains the database,
all repositories and all attachments.

You can only restore a backup to **exactly the same version and type (CE/EE)**
of GitLab on which it was created. The best way to migrate your repositories
from one server to another is through backup restore.

## Requirements

In order to be able to backup and restore, you need two essential tools
installed on your system.

### Rsync

If you installed GitLab:

- Using the Omnibus package, you're all set.
- From source, make sure `rsync` is installed:

  ```sh
  # Debian/Ubuntu
  sudo apt-get install rsync

  # RHEL/CentOS
  sudo yum install rsync
  ```

### Tar

Backup and restore tasks use `tar` under the hood to create and extract
archives. Ensure you have version 1.30 or above of `tar` available in your
system. To check the version, run:

```sh
tar --version
```

## Backup timestamp

NOTE: **Note:**
In GitLab 9.2 the timestamp format was changed from `EPOCH_YYYY_MM_DD` to
`EPOCH_YYYY_MM_DD_GitLab_version`, for example `1493107454_2018_04_25`
would become `1493107454_2018_04_25_10.6.4-ce`.

The backup archive will be saved in `backup_path`, which is specified in the
`config/gitlab.yml` file.
The filename will be `[TIMESTAMP]_gitlab_backup.tar`, where `TIMESTAMP`
identifies the time at which each backup was created, plus the GitLab version.
The timestamp is needed if you need to restore GitLab and multiple backups are
available.

For example, if the backup name is `1493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar`,
then the timestamp is `1493107454_2018_04_25_10.6.4-ce`.

## Creating a backup of the GitLab system

GitLab provides a simple command line interface to backup your whole instance.
It backs up your:

- Database
- Attachments
- Git repositories data
- CI/CD job output logs
- CI/CD job artifacts
- LFS objects
- Container Registry images
- GitLab Pages content

CAUTION: **Warning:**
GitLab does not back up any configuration files, SSL certificates, or system files.
You are highly advised to [read about storing configuration files](#storing-configuration-files).

Use this command if you've installed GitLab with the Omnibus package:

```sh
sudo gitlab-backup create
```

NOTE: **Note**
For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:create`.

Use this if you've installed GitLab from source:

```sh
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

If you are running GitLab within a Docker container, you can run the backup from the host:

```sh
docker exec -t <container name> gitlab-backup create
```

NOTE: **Note**
For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:create`.

If you are using the [GitLab Helm chart](https://gitlab.com/gitlab-org/charts/gitlab) on a
Kubernetes cluster, you can run the backup task using `backup-utility` script on
the GitLab task runner pod via `kubectl`. Refer to [backing up a GitLab installation](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/backup-restore/backup.md#backing-up-a-gitlab-installation) for more details:

```sh
kubectl exec -it <gitlab task-runner pod> backup-utility
```

Similarly to the Kubernetes case, if you have scaled out your GitLab
cluster to use multiple application servers, you should pick a
designated node (that won't be auto-scaled away) for running the
backup rake task. Because the backup rake task is tightly coupled to
the main Rails application, this is typically a node on which you're
also running Unicorn/Puma and/or Sidekiq.

Example output:

```
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

A backup performed by the [raketask GitLab provides](#creating-a-backup-of-the-gitlab-system)
does **not** store your configuration files. The primary reason for this is that your
database contains encrypted information for two-factor authentication, the CI/CD
'secure variables', etc. Storing encrypted information along with its key in the
same place defeats the purpose of using encryption in the first place.

CAUTION: **Warning:**
The secrets file is essential to preserve your database encryption key.

At the very **minimum**, you must backup:

For Omnibus:

- `/etc/gitlab/gitlab-secrets.json`
- `/etc/gitlab/gitlab.rb`

For installation from source:

- `/home/git/gitlab/config/secrets.yml`
- `/home/git/gitlab/config/gitlab.yml`

For [Docker installations](https://docs.gitlab.com/omnibus/docker/), you must
back up the volume where the configuration files are stored. If you have created
the GitLab container according to the documentation, it should be under
`/srv/gitlab/config`.

You may also want to back up any TLS keys and certificates, and your
[SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079).

If you use Omnibus GitLab, see some additional information
[to backup your configuration](https://docs.gitlab.com/omnibus/settings/backups.html).

In the unlikely event that the secrets file is lost, see the
[troubleshooting section](#when-the-secrets-file-is-lost).

## Backup options

The command line tool GitLab provides to backup your instance can take more options.

### Backup strategy option

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/8728) in GitLab 8.17.

The default backup strategy is to essentially stream data from the respective
data locations to the backup using the Linux command `tar` and `gzip`. This works
fine in most cases, but can cause problems when data is rapidly changing.

When data changes while `tar` is reading it, the error `file changed as we read
it` may occur, and will cause the backup process to fail. To combat this, 8.17
introduces a new backup strategy called `copy`. The strategy copies data files
to a temporary location before calling `tar` and `gzip`, avoiding the error.

A side-effect is that the backup process will take up to an additional 1X disk
space. The process does its best to clean up the temporary files at each stage
so the problem doesn't compound, but it could be a considerable change for large
installations. This is why the `copy` strategy is not the default in 8.17.

To use the `copy` strategy instead of the default streaming strategy, specify
`STRATEGY=copy` in the Rake task command. For example:

```sh
sudo gitlab-backup create STRATEGY=copy
```

NOTE: **Note**
For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:create`.

### Backup filename

By default a backup file is created according to the specification in [the Backup timestamp](#backup-timestamp) section above. You can however override the `[TIMESTAMP]` part of the filename by setting the `BACKUP` environment variable. For example:

```sh
sudo gitlab-backup create BACKUP=dump
```

NOTE: **Note**
For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:create`.

The resulting file will then be `dump_gitlab_backup.tar`. This is useful for systems that make use of rsync and incremental backups, and will result in considerably faster transfer speeds.

### Rsyncable

To make sure the generated archive is intelligently transferable by rsync, the `GZIP_RSYNCABLE=yes` option can be set. This will set the `--rsyncable` option to `gzip`. This is only useful in combination with setting [the Backup filename option](#backup-filename).

Note that the `--rsyncable` option in `gzip` is not guaranteed to be available on all distributions. To verify that it is available in your distribution you can run `gzip --help` or consult the man pages.

```sh
sudo gitlab-backup create BACKUP=dump GZIP_RSYNCABLE=yes
```

NOTE: **Note**
For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:create`.

### Excluding specific directories from the backup

You can choose what should be exempt from the backup up by adding the environment variable `SKIP`.
The available options are:

- `db` (database)
- `uploads` (attachments)
- `repositories` (Git repositories data)
- `builds` (CI job output logs)
- `artifacts` (CI job artifacts)
- `lfs` (LFS objects)
- `registry` (Container Registry images)
- `pages` (Pages content)

Use a comma to specify several options at the same time:

All wikis will be backed up as part of the `repositories` group. Non-existent wikis
will be skipped during a backup.

For Omnibus GitLab packages:

```sh
sudo gitlab-backup create SKIP=db,uploads
```

NOTE: **Note**
For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:create`.

For installations from source:

```sh
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=db,uploads RAILS_ENV=production
```

### Uploading backups to a remote (cloud) storage

Starting with GitLab 7.4 you can let the backup script upload the '.tar' file it creates.
It uses the [Fog library](http://fog.io/) to perform the upload.
In the example below we use Amazon S3 for storage, but Fog also lets you use
[other storage providers](http://fog.io/storage/). GitLab
[imports cloud drivers](https://gitlab.com/gitlab-org/gitlab/blob/30f5b9a5b711b46f1065baf755e413ceced5646b/Gemfile#L88)
for AWS, Google, OpenStack Swift, Rackspace and Aliyun as well. A local driver is
[also available](#uploading-to-locally-mounted-shares).

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
   ```

1. [Reconfigure GitLab] for the changes to take effect

#### Digital Ocean Spaces

This example can be used for a bucket in Amsterdam (AMS3).

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

1. [Reconfigure GitLab] for the changes to take effect

NOTE: **Note:**
If you see `400 Bad Request` by using Digital Ocean Spaces, the cause may be the
usage of backup encryption. Remove or comment the line that
contains `gitlab_rails['backup_encryption']` since Digital Ocean Spaces
doesn't support encryption.

#### Other S3 Providers

Not all S3 providers are fully-compatible with the Fog library. For example,
if you see `411 Length Required` errors after attempting to upload, you may
need to downgrade the `aws_signature_version` value from the default value to
2 [due to this issue](https://github.com/fog/fog-aws/issues/428).

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
         # Turns on AWS Server-Side Encryption with Amazon S3-Managed Keys for backups, this is optional
         # encryption: 'AES256'
         # Turns on AWS Server-Side Encryption with Amazon Customer-Provided Encryption Keys for backups, this is optional
         #   This should be set to the base64-encoded encryption key for Amazon S3 to use to encrypt or decrypt your data.
         #   'encryption' must also be set in order for this to have any effect.
         #   To avoid storing the key on disk, the key can also be specified via the `GITLAB_BACKUP_ENCRYPTION_KEY` environment variable.
         # encryption_key: '<base64 key>'
         # Specifies Amazon S3 storage class to use for backups, this is optional
         # storage_class: 'STANDARD'
   ```

1. [Restart GitLab] for the changes to take effect

If you are uploading your backups to S3 you will probably want to create a new
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

If you want to use Google Cloud Storage to save backups, you'll have to create
an access key from the Google console first:

1. Go to the storage settings page <https://console.cloud.google.com/storage/settings>
1. Select "Interoperability" and create an access key
1. Make note of the "Access Key" and "Secret" and replace them in the
   configurations below
1. In the buckets advanced settings ensure the Access Control option "Set object-level
   and bucket-level permissions" is selected
1. Make sure you already have a bucket created

For Omnibus GitLab packages:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'Google',
     'google_storage_access_key_id' => 'Access Key',
     'google_storage_secret_access_key' => 'Secret'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.google.bucket'
   ```

1. [Reconfigure GitLab] for the changes to take effect

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

1. [Restart GitLab] for the changes to take effect

#### Specifying a custom directory for backups

Note: This option only works for remote storage. If you want to group your backups
you can pass a `DIRECTORY` environment variable:

```
sudo gitlab-backup create DIRECTORY=daily
sudo gitlab-backup create DIRECTORY=weekly
```

NOTE: **Note**
For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:create`.

### Uploading to locally mounted shares

You may also send backups to a mounted share (`NFS` / `CIFS` / `SMB` / etc.) by
using the Fog [`Local`](https://github.com/fog/fog-local#usage) storage provider.
The directory pointed to by the `local_root` key **must** be owned by the `git`
user **when mounted** (mounting with the `uid=` of the `git` user for `CIFS` and
`SMB`) or the user that you are executing the backup tasks under (for Omnibus
packages, this is the `git` user).

The `backup_upload_remote_directory` **must** be set in addition to the
`local_root` key. This is the sub directory inside the mounted directory that
backups will be copied to, and will be created if it does not exist. If the
directory that you want to copy the tarballs to is the root of your mounted
directory, just use `.` instead.

NOTE: **Note:** Since file system performance may affect GitLab's overall performance, we do not recommend using EFS for storage. See the [relevant documentation](../administration/high_availability/nfs.md#avoid-using-awss-elastic-file-system-efs) for more details.

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

1. [Reconfigure GitLab] for the changes to take effect.

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

1. [Restart GitLab] for the changes to take effect.

### Backup archive permissions

The backup archives created by GitLab (`1393513186_2014_02_27_gitlab_backup.tar`)
will have owner/group `git`/`git` and 0600 permissions by default.
This is meant to avoid other system users reading GitLab's data.
If you need the backup archives to have different permissions you can use the 'archive_permissions' setting.

For Omnibus GitLab packages:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['backup_archive_permissions'] = 0644 # Makes the backup archives world-readable
   ```

1. [Reconfigure GitLab] for the changes to take effect.

For installations from source:

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   backup:
     archive_permissions: 0644 # Makes the backup archives world-readable
   ```

1. [Restart GitLab] for the changes to take effect.

### Configuring cron to make daily backups

NOTE: **Note:**
The following cron jobs do not [backup your GitLab configuration files](#storing-configuration-files)
or [SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079).

For Omnibus GitLab packages:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

1. [Reconfigure GitLab] for the changes to take effect.

Note that the `backup_keep_time` configuration option only manages local
files. GitLab does not automatically prune old files stored in a third-party
object storage (e.g., AWS S3) because the user may not have permission to list
and delete files. We recommend that you configure the appropriate retention
policy for your object storage. For example, you can configure [the S3 backup
policy as described here](https://stackoverflow.com/questions/37553070/gitlab-omnibus-delete-backup-from-amazon-s3).

To schedule a cron job that backs up your repositories and GitLab metadata, use the root user:

```sh
sudo su -
crontab -e
```

There, add the following line to schedule the backup for everyday at 2 AM:

```
0 2 * * * /opt/gitlab/bin/gitlab-backup create CRON=1
```

NOTE: **Note**
For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:create`.

You may also want to set a limited lifetime for backups to prevent regular
backups using all your disk space.

For installations from source:

1. Edit `home/git/gitlab/config/gitlab.yml`:

   ```yaml
   backup:
     ## Limit backup lifetime to 7 days - 604800 seconds
     keep_time: 604800
   ```

1. [Restart GitLab] for the changes to take effect.

```sh
sudo -u git crontab -e # Edit the crontab for the git user
```

Add the following lines at the bottom:

```
# Create a full backup of the GitLab repositories and SQL database every day at 4am
0 4 * * * cd /home/git/gitlab && PATH=/usr/local/bin:/usr/bin:/bin bundle exec rake gitlab:backup:create RAILS_ENV=production CRON=1
```

The `CRON=1` environment setting tells the backup script to suppress all progress output if there are no errors.
This is recommended to reduce cron spam.

## Restore

GitLab provides a simple command line interface to restore your whole installation,
and is flexible enough to fit your needs.

The [restore prerequisites section](#restore-prerequisites) includes crucial
information. Make sure to read and test the whole restore process at least once
before attempting to perform it in a production environment.

You can only restore a backup to **exactly the same version and type (CE/EE)** of
GitLab that you created it on, for example CE 9.1.0.

### Restore prerequisites

You need to have a working GitLab installation before you can perform
a restore. This is mainly because the system user performing the
restore actions (`git`) is usually not allowed to create or delete
the SQL database it needs to import data into ('gitlabhq_production').
All existing data will be either erased (SQL) or moved to a separate
directory (repositories, uploads).

To restore a backup, you will also need to restore `/etc/gitlab/gitlab-secrets.json`
(for Omnibus packages) or `/home/git/gitlab/.secret` (for installations
from source). This file contains the database encryption key,
[CI/CD variables](../ci/variables/README.md#gitlab-cicd-environment-variables), and
variables used for [two-factor authentication](../user/profile/account/two_factor_authentication.md).
If you fail to restore this encryption key file along with the application data
backup, users with two-factor authentication enabled and GitLab Runners will
lose access to your GitLab server.

You may also want to restore any TLS keys, certificates, or [SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079).

Depending on your case, you might want to run the restore command with one or
more of the following options:

- `BACKUP=timestamp_of_backup` - Required if more than one backup exists.
  Read what the [backup timestamp is about](#backup-timestamp).
- `force=yes` - Does not ask if the authorized_keys file should get regenerated and assumes 'yes' for warning that database tables will be removed, enabling the "Write to authorized_keys file" setting, and updating LDAP providers.

If you are restoring into directories that are mountpoints you will need to make
sure these directories are empty before attempting a restore. Otherwise GitLab
will attempt to move these directories before restoring the new data and this
would cause an error.

Read more on [configuring NFS mounts](../administration/high_availability/nfs.md)

### Restore for installation from source

```
# Stop processes that are connected to the database
sudo service gitlab stop

bundle exec rake gitlab:backup:restore RAILS_ENV=production
```

Example output:

```
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

Next, restore `/home/git/gitlab/.secret` if necessary as mentioned above.

Restart GitLab:

```shell
sudo service gitlab restart
```

### Restore for Omnibus GitLab installations

This procedure assumes that:

- You have installed the **exact same version and type (CE/EE)** of GitLab
  Omnibus with which the backup was created.
- You have run `sudo gitlab-ctl reconfigure` at least once.
- GitLab is running.  If not, start it using `sudo gitlab-ctl start`.

First make sure your backup tar file is in the backup directory described in the
`gitlab.rb` configuration `gitlab_rails['backup_path']`. The default is
`/var/opt/gitlab/backups`. It needs to be owned by the `git` user.

```shell
sudo cp 11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar /var/opt/gitlab/backups/
sudo chown git.git /var/opt/gitlab/backups/11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar
```

Stop the processes that are connected to the database.  Leave the rest of GitLab
running:

```shell
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
# Verify
sudo gitlab-ctl status
```

Next, restore the backup, specifying the timestamp of the backup you wish to
restore:

```shell
# This command will overwrite the contents of your GitLab database!
sudo gitlab-backup restore BACKUP=1493107454_2018_04_25_10.6.4-ce
```

NOTE: **Note**
For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:restore`.

CAUTION: **Warning:**
`gitlab-rake gitlab:backup:restore` does not set the right file system permissions on your Registry directory.
This is a [known issue](https://gitlab.com/gitlab-org/gitlab-foss/issues/62759). On GitLab 12.2 or newer, you can
use `gitlab-backup restore` to avoid this issue.

Next, restore `/etc/gitlab/gitlab-secrets.json` if necessary as mentioned above.

Reconfigure, restart and check GitLab:

```shell
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart
sudo gitlab-rake gitlab:check SANITIZE=true
```

If there is a GitLab version mismatch between your backup tar file and the installed
version of GitLab, the restore command will abort with an error. Install the
[correct GitLab version](https://packages.gitlab.com/gitlab/) and try again.

### Restore for Docker image and GitLab Helm chart installations

For GitLab installations using the Docker image or the GitLab Helm chart on
a Kubernetes cluster, the restore task expects the restore directories to be empty.
However, with docker and Kubernetes volume mounts, some system level directories
may be created at the volume roots, like `lost+found` directory found in Linux
operating systems. These directories are usually owned by `root`, which can
cause access permission errors since the restore rake task runs as `git` user.
So, to restore a GitLab installation, users have to confirm the restore target
directories are empty.

For both these installation types, the backup tarball has to be available in the
backup location (default location is `/var/opt/gitlab/backups`).

For docker installations, the restore task can be run from host:

```sh
docker exec -it <name of container> gitlab-backup restore
```

NOTE: **Note**
For GitLab 12.1 and earlier, use `gitlab-rake gitlab:backup:restore`.

CAUTION: **Warning:**
`gitlab-rake gitlab:backup:restore` does not set the right file system permissions on your Registry directory.
This is a [known issue](https://gitlab.com/gitlab-org/gitlab-foss/issues/62759). On GitLab 12.2 or newer, you can
use `gitlab-backup restore` to avoid this issue.

The GitLab Helm chart uses a different process, documented in
[restoring a GitLab Helm chart installation](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/backup-restore/restore.md).

## Alternative backup strategies

If your GitLab server contains a lot of Git repository data you may find the GitLab backup script to be too slow.
In this case you can consider using filesystem snapshots as part of your backup strategy.

Example: Amazon EBS

> A GitLab server using Omnibus GitLab hosted on Amazon AWS.
> An EBS drive containing an ext4 filesystem is mounted at `/var/opt/gitlab`.
> In this case you could make an application backup by taking an EBS snapshot.
> The backup includes all repositories, uploads and Postgres data.

Example: LVM snapshots + rsync

> A GitLab server using Omnibus GitLab, with an LVM logical volume mounted at `/var/opt/gitlab`.
> Replicating the `/var/opt/gitlab` directory using rsync would not be reliable because too many files would change while rsync is running.
> Instead of rsync-ing `/var/opt/gitlab`, we create a temporary LVM snapshot, which we mount as a read-only filesystem at `/mnt/gitlab_backup`.
> Now we can have a longer running rsync job which will create a consistent replica on the remote server.
> The replica includes all repositories, uploads and Postgres data.

If you are running GitLab on a virtualized server you can possibly also create VM snapshots of the entire GitLab server.
It is not uncommon however for a VM snapshot to require you to power down the server, so this approach is probably of limited practical use.

## Additional notes

This documentation is for GitLab Community and Enterprise Edition. We backup
GitLab.com and make sure your data is secure, but you can't use these methods
to export / backup your data yourself from GitLab.com.

Issues are stored in the database. They can't be stored in Git itself.

To migrate your repositories from one server to another with an up-to-date version of
GitLab, you can use the [import rake task](import.md) to do a mass import of the
repository. Note that if you do an import rake task, rather than a backup restore, you
will have all your repositories, but not any other data.

## Troubleshooting

### Restoring database backup using Omnibus packages outputs warnings

If you are using backup restore procedures you might encounter the following warnings:

```
psql:/var/opt/gitlab/backups/db/database.sql:22: ERROR:  must be owner of extension plpgsql
psql:/var/opt/gitlab/backups/db/database.sql:2931: WARNING:  no privileges could be revoked for "public" (two occurrences)
psql:/var/opt/gitlab/backups/db/database.sql:2933: WARNING:  no privileges were granted for "public" (two occurrences)
```

Be advised that, backup is successfully restored in spite of these warnings.

The rake task runs this as the `gitlab` user which does not have the superuser access to the database. When restore is initiated it will also run as `gitlab` user but it will also try to alter the objects it does not have access to.
Those objects have no influence on the database backup/restore but they give this annoying warning.

For more information see similar questions on PostgreSQL issue tracker[here](https://www.postgresql.org/message-id/201110220712.30886.adrian.klaver@gmail.com) and [here](https://www.postgresql.org/message-id/2039.1177339749@sss.pgh.pa.us) as well as [stack overflow](https://stackoverflow.com/questions/4368789/error-must-be-owner-of-language-plpgsql).

### When the secrets file is lost

If you have failed to [back up the secrets file](#storing-configuration-files),
then users with 2FA enabled will not be able to log into GitLab. In that case,
you need to [disable 2FA for everyone](../security/two_factor_authentication.md#disabling-2fa-for-everyone).

The secrets file is also responsible for storing the encryption key for several
columns containing sensitive information. If the key is lost, GitLab will be
unable to decrypt those columns. This will break a wide range of functionality,
including (but not restricted to):

- [CI/CD variables](../ci/variables/README.md)
- [Kubernetes / GCP integration](../user/project/clusters/index.md)
- [Custom Pages domains](../user/project/pages/custom_domains_ssl_tls_certification/index.md)
- [Project error tracking](../user/project/operations/error_tracking.md)
- [Runner authentication](../ci/runners/README.md)
- [Project mirroring](../user/project/repository/repository_mirroring.md)
- [Web hooks](../user/project/integrations/webhooks.md)

In cases like CI/CD variables and Runner authentication, you might
experience some unexpected behavior such as:

- Stuck jobs.
- 500 errors.

In this case, you are required to reset all the tokens for CI/CD variables
and Runner Authentication, which is described in more detail below. After
resetting the tokens, you should be able to visit your project and the jobs
will have started running again.

CAUTION: **Warning:**
Use the following commands at your own risk, and make sure you've taken a
backup beforehand.

#### Reset CI/CD variables

1. Enter the DB console:

   For Omnibus GitLab packages:

   ```sh
   sudo gitlab-rails dbconsole
   ```

   For installations from source:

   ```sh
   sudo -u git -H bundle exec rails dbconsole RAILS_ENV=production
   ```

1. Check the `ci_group_variables` and `ci_variables` tables:

   ```sql
   SELECT * FROM public."ci_group_variables";
   SELECT * FROM public."ci_variables";
   ```

   Those are the variables that you need to delete.

1. Drop the table:

   ```sql
   DELETE FROM ci_group_variables;
   DELETE FROM ci_variables;
   ```

1. You may need to reconfigure or restart GitLab for the changes to take
   effect.

#### Reset Runner registration tokens

1. Enter the DB console:

   For Omnibus GitLab packages:

   ```sh
   sudo gitlab-rails dbconsole
   ```

   For installations from source:

   ```sh
   sudo -u git -H bundle exec rails dbconsole RAILS_ENV=production
   ```

1. Clear all the tokens for projects, groups, and the whole instance:

   CAUTION: **Caution:**
   The last UPDATE operation will stop the runners being able to pick up
   new jobs. You must register new runners.

   ```sql
   -- Clear project tokens
   UPDATE projects SET runners_token = null, runners_token_encrypted = null;
   -- Clear group tokens
   UPDATE namespaces SET runners_token = null, runners_token_encrypted = null;
   -- Clear instance tokens
   UPDATE application_settings SET runners_registration_token_encrypted = null;
   -- Clear runner tokens
   UPDATE ci_runners SET token = null, token_encrypted = null;
   ```

#### Reset pending pipeline jobs

1. Enter the DB console:

   For Omnibus GitLab packages:

   ```sh
   sudo gitlab-rails dbconsole
   ```

   For installations from source:

   ```sh
   sudo -u git -H bundle exec rails dbconsole RAILS_ENV=production
   ```

1. Clear all the tokens for pending jobs:

   ```sql
   -- Clear build tokens
   UPDATE ci_builds SET token = null, token_encrypted = null;
   ```

A similar strategy can be employed for the remaining features - by removing the
data that cannot be decrypted, GitLab can be brought back into working order,
and the lost data can be manually replaced.

### Container Registry push failures after restoring from a backup

If you use the [Container Registry](../user/packages/container_registry/index.md), you
may see pushes to the registry fail after restoring your backup on an Omnibus
GitLab instance after restoring the registry data.

These failures will mention permission issues in the registry logs, like:

```
level=error
msg="response completed with error"
err.code=unknown
err.detail="filesystem: mkdir /var/opt/gitlab/gitlab-rails/shared/registry/docker/registry/v2/repositories/...: permission denied"
err.message="unknown error"
```

This is caused by the restore being run as the unprivileged user `git` which was
unable to assign the correct ownership to the registry files during the restore
([issue 62759](https://gitlab.com/gitlab-org/gitlab-foss/issues/62759 "Incorrect permissions on registry filesystem after restore")).

To get your registry working again:

```bash
sudo chown -R registry:registry /var/opt/gitlab/gitlab-rails/shared/registry/docker
```

NOTE: **Note:**
If you have changed the default filesystem location for the registry, you will
want to run the `chown` against your custom location instead of
`/var/opt/gitlab/gitlab-rails/shared/registry/docker`.

[reconfigure GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart GitLab]: ../administration/restart_gitlab.md#installations-from-source

### Backup fails to complete with Gzip error

While running the backup, you may receive a gzip error:

```sh
sudo /opt/gitlab/bin/gitlab-backup create
...
Dumping ...
...
gzip: stdout: Input/output error

Backup failed
```

If this happens, check the following:

1. Confirm there is sufficient disk space for the gzip operation.
1. If NFS is being used, check if the mount option `timeout` is set. The default is `600`, and changing this to smaller values have resulted in this error.
