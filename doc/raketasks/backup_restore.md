# Backing up and restoring GitLab

![backup banner](backup_hrz.png)

An application data backup creates an archive file that contains the database,
all repositories and all attachments.

You can only restore a backup to **exactly the same version and type (CE/EE)**
of GitLab on which it was created. The best way to migrate your repositories
from one server to another is through backup restore.

## Backup

GitLab provides a simple command line interface to backup your whole installation,
and is flexible enough to fit your needs.

### Requirements

If you're using GitLab with the Omnibus package, you're all set. If you
installed GitLab from source, make sure the following packages are installed:

* rsync

If you're using Ubuntu, you could run:

```
sudo apt-get install -y rsync
```

### Backup timestamp

>**Note:**
In GitLab 9.2 the timestamp format was changed from `EPOCH_YYYY_MM_DD` to
`EPOCH_YYYY_MM_DD_GitLab version`, for example `1493107454_2017_04_25`
would become `1493107454_2017_04_25_9.1.0`.

The backup archive will be saved in `backup_path`, which is specified in the
`config/gitlab.yml` file.
The filename will be `[TIMESTAMP]_gitlab_backup.tar`, where `TIMESTAMP`
identifies the time at which each backup was created, plus the GitLab version.
The timestamp is needed if you need to restore GitLab and multiple backups are
available.

For example, if the backup name is `1493107454_2017_04_25_9.1.0_gitlab_backup.tar`,
then the timestamp is `1493107454_2017_04_25_9.1.0`.

### Creating a backup of the GitLab system

Use this command if you've installed GitLab with the Omnibus package:

```
sudo gitlab-rake gitlab:backup:create
```

Use this if you've installed GitLab from source:

```
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

If you are running GitLab within a Docker container, you can run the backup from the host:

```
docker exec -t <container name> gitlab-rake gitlab:backup:create
```

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

### Backup strategy option

> **Note:** Introduced as an option in GitLab 8.17.

The default backup strategy is to essentially stream data from the respective
data locations to the backup using the Linux command `tar` and `gzip`. This works
fine in most cases, but can cause problems when data is rapidly changing.

When data changes while `tar` is reading it, the error `file changed as we read
it` may occur, and will cause the backup process to fail. To combat this, 8.17
introduces a new backup strategy called `copy`. The strategy copies data files
to a temporary location before calling `tar` and `gzip`, avoiding the error.

A side-effect is that the backup process with take up to an additional 1X disk
space. The process does its best to clean up the temporary files at each stage
so the problem doesn't compound, but it could be a considerable change for large
installations. This is why the `copy` strategy is not the default in 8.17.

To use the `copy` strategy instead of the default streaming strategy, specify
`STRATEGY=copy` in the Rake task command. For example,
`sudo gitlab-rake gitlab:backup:create STRATEGY=copy`.

### Excluding specific directories from the backup

You can choose what should be backed up by adding the environment variable `SKIP`.
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

```
# use this command if you've installed GitLab with the Omnibus package
sudo gitlab-rake gitlab:backup:create SKIP=db,uploads

# if you've installed GitLab from source
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=db,uploads RAILS_ENV=production
```

### Uploading backups to a remote (cloud) storage

Starting with GitLab 7.4 you can let the backup script upload the '.tar' file it creates.
It uses the [Fog library](http://fog.io/) to perform the upload.
In the example below we use Amazon S3 for storage, but Fog also lets you use
[other storage providers](http://fog.io/storage/). GitLab
[imports cloud drivers](https://gitlab.com/gitlab-org/gitlab-ce/blob/30f5b9a5b711b46f1065baf755e413ceced5646b/Gemfile#L88)
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

#### Other S3 Providers

Not all S3 providers are fully-compatible with the Fog library. For example,
if you see `411 Length Required` errors after attempting to upload, you may
need to downgrade the `aws_signature_version` value from the default value to
2 [due to this issue](https://github.com/fog/fog-aws/issues/428).

---

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

1. Go to the storage settings page https://console.cloud.google.com/storage/settings
1. Select "Interoperability" and create an access key
1. Make note of the "Access Key" and "Secret" and replace them in the
   configurations below
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

---

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

### Uploading to locally mounted shares

You may also send backups to a mounted share (`NFS` / `CIFS` / `SMB` / etc.) by
using the Fog [`Local`](https://github.com/fog/fog-local#usage) storage provider.
The directory pointed to by the `local_root` key **must** be owned by the `git`
user **when mounted** (mounting with the `uid=` of the `git` user for `CIFS` and
`SMB`) or the user that you are executing the backup tasks under (for omnibus
packages, this is the `git` user).

The `backup_upload_remote_directory` **must** be set in addition to the
`local_root` key. This is the sub directory inside the mounted directory that
backups will be copied to, and will be created if it does not exist. If the
directory that you want to copy the tarballs to is the root of your mounted
directory, just use `.` instead.

For omnibus packages:

```ruby
gitlab_rails['backup_upload_connection'] = {
  :provider => 'Local',
  :local_root => '/mnt/backups'
}

# The directory inside the mounted folder to copy backups to
# Use '.' to store them in the root directory
gitlab_rails['backup_upload_remote_directory'] = 'gitlab_backups'
```

For installations from source:

```yaml
  backup:
    # snip
    upload:
      # Fog storage connection settings, see http://fog.io/storage/ .
      connection:
        provider: Local
        local_root: '/mnt/backups'
      # The directory inside the mounted folder to copy backups to
      # Use '.' to store them in the root directory
      remote_directory: 'gitlab_backups'
```

### Specifying a custom directory for backups

If you want to group your backups you can pass a `DIRECTORY` environment variable:

```
sudo gitlab-rake gitlab:backup:create DIRECTORY=daily
sudo gitlab-rake gitlab:backup:create DIRECTORY=weekly
```

### Backup archive permissions

The backup archives created by GitLab (`1393513186_2014_02_27_gitlab_backup.tar`)
will have owner/group git:git and 0600 permissions by default.
This is meant to avoid other system users reading GitLab's data.
If you need the backup archives to have different permissions you can use the 'archive_permissions' setting.

```
# In /etc/gitlab/gitlab.rb, for omnibus packages
gitlab_rails['backup_archive_permissions'] = 0644 # Makes the backup archives world-readable
```

```
# In gitlab.yml, for installations from source:
  backup:
    archive_permissions: 0644 # Makes the backup archives world-readable
```

### Storing configuration files

Please be informed that a backup does not store your configuration
files. One reason for this is that your database contains encrypted
information for two-factor authentication. Storing encrypted
information along with its key in the same place defeats the purpose
of using encryption in the first place!

If you use an Omnibus package please see the [instructions in the readme to backup your configuration](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#backup-and-restore-omnibus-gitlab-configuration).
If you have a cookbook installation there should be a copy of your configuration in Chef.
If you installed from source, please consider backing up your `config/secrets.yml` file, `gitlab.yml` file, any SSL keys and certificates, and your [SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079).

At the very **minimum** you should backup `/etc/gitlab/gitlab.rb` and
`/etc/gitlab/gitlab-secrets.json` (Omnibus), or
`/home/git/gitlab/config/secrets.yml` (source) to preserve your database
encryption key.

### Configuring cron to make daily backups

>**Note:**
The following cron jobs do not [backup your GitLab configuration files](#storing-configuration-files)
or [SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079).

**For Omnibus installations**

To schedule a cron job that backs up your repositories and GitLab metadata, use the root user:

```
sudo su -
crontab -e
```

There, add the following line to schedule the backup for everyday at 2 AM:

```
0 2 * * * /opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1
```

You may also want to set a limited lifetime for backups to prevent regular
backups using all your disk space.  To do this add the following lines to
`/etc/gitlab/gitlab.rb` and reconfigure:

```
# limit backup lifetime to 7 days - 604800 seconds
gitlab_rails['backup_keep_time'] = 604800
```

Note that the `backup_keep_time` configuration option only manages local
files. GitLab does not automatically prune old files stored in a third-party
object storage (e.g., AWS S3) because the user may not have permission to list
and delete files. We recommend that you configure the appropriate retention
policy for your object storage. For example, you can configure [the S3 backup
policy as described here](http://stackoverflow.com/questions/37553070/gitlab-omnibus-delete-backup-from-amazon-s3).

**For installation from source**

```
cd /home/git/gitlab
sudo -u git -H editor config/gitlab.yml # Enable keep_time in the backup section to automatically delete old backups
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
restore actions ('git') is usually not allowed to create or delete
the SQL database it needs to import data into ('gitlabhq_production').
All existing data will be either erased (SQL) or moved to a separate
directory (repositories, uploads).

To restore a backup, you will also need to restore `/etc/gitlab/gitlab-secrets.json`
(for Omnibus packages) or `/home/git/gitlab/.secret` (for installations
from source). This file contains the database encryption key,
[CI secret variables](../ci/variables/README.md#secret-variables), and
secret variables used for [two-factor authentication](../user/profile/account/two_factor_authentication.md).
If you fail to restore this encryption key file along with the application data
backup, users with two-factor authentication enabled and GitLab Runners will
lose access to your GitLab server.

Depending on your case, you might want to run the restore command with one or
more of the following options:

- `BACKUP=timestamp_of_backup` - Required if more than one backup exists.
  Read what the [backup timestamp is about](#backup-timestamp).
- `force=yes` - Does not ask if the authorized_keys file should get regenerated and assumes 'yes' for warning that database tables will be removed.

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
Deleting tmp directories...[DONE]
```

Next, restore `/home/git/gitlab/.secret` if necessary as mentioned above.

Restart GitLab:

```shell
sudo service gitlab restart
```

### Restore for Omnibus installations

This procedure assumes that:

- You have installed the **exact same version and type (CE/EE)** of GitLab
  Omnibus with which the backup was created.
- You have run `sudo gitlab-ctl reconfigure` at least once.
- GitLab is running.  If not, start it using `sudo gitlab-ctl start`.

First make sure your backup tar file is in the backup directory described in the
`gitlab.rb` configuration `gitlab_rails['backup_path']`. The default is
`/var/opt/gitlab/backups`.

```shell
sudo cp 1493107454_2017_04_25_9.1.0_gitlab_backup.tar /var/opt/gitlab/backups/
```

Stop the processes that are connected to the database.  Leave the rest of GitLab
running:

```shell
sudo gitlab-ctl stop unicorn
sudo gitlab-ctl stop sidekiq
# Verify
sudo gitlab-ctl status
```

Next, restore the backup, specifying the timestamp of the backup you wish to
restore:

```shell
# This command will overwrite the contents of your GitLab database!
sudo gitlab-rake gitlab:backup:restore BACKUP=1493107454_2017_04_25_9.1.0
```

Next, restore `/etc/gitlab/gitlab-secrets.json` if necessary as mentioned above.

Restart and check GitLab:

```shell
sudo gitlab-ctl restart
sudo gitlab-rake gitlab:check SANITIZE=true
```

If there is a GitLab version mismatch between your backup tar file and the installed
version of GitLab, the restore command will abort with an error. Install the
[correct GitLab version](https://packages.gitlab.com/gitlab/) and try again.

## Alternative backup strategies

If your GitLab server contains a lot of Git repository data you may find the GitLab backup script to be too slow.
In this case you can consider using filesystem snapshots as part of your backup strategy.

Example: Amazon EBS

> A GitLab server using omnibus-gitlab hosted on Amazon AWS.
> An EBS drive containing an ext4 filesystem is mounted at `/var/opt/gitlab`.
> In this case you could make an application backup by taking an EBS snapshot.
> The backup includes all repositories, uploads and Postgres data.

Example: LVM snapshots + rsync

> A GitLab server using omnibus-gitlab, with an LVM logical volume mounted at `/var/opt/gitlab`.
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

### Restoring database backup using omnibus packages outputs warnings
If you are using backup restore procedures you might encounter the following warnings:

```
psql:/var/opt/gitlab/backups/db/database.sql:22: ERROR:  must be owner of extension plpgsql
psql:/var/opt/gitlab/backups/db/database.sql:2931: WARNING:  no privileges could be revoked for "public" (two occurrences)
psql:/var/opt/gitlab/backups/db/database.sql:2933: WARNING:  no privileges were granted for "public" (two occurrences)
```

Be advised that, backup is successfully restored in spite of these warnings.

The rake task runs this as the `gitlab` user which does not have the superuser access to the database. When restore is initiated it will also run as `gitlab` user but it will also try to alter the objects it does not have access to.
Those objects have no influence on the database backup/restore but they give this annoying warning.

For more information see similar questions on postgresql issue tracker[here](http://www.postgresql.org/message-id/201110220712.30886.adrian.klaver@gmail.com) and [here](http://www.postgresql.org/message-id/2039.1177339749@sss.pgh.pa.us) as well as [stack overflow](http://stackoverflow.com/questions/4368789/error-must-be-owner-of-language-plpgsql).

[reconfigure GitLab]: ../administration/restart_gitlab.md#omnibus-gitlab-reconfigure
[restart GitLab]: ../administration/restart_gitlab.md#installations-from-source
