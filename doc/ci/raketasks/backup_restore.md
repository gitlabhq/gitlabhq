# Backup restore

## Create a backup of the GitLab CI

A backup creates an archive file that contains the database and builds files.
This archive will be saved in backup_path (see `config/application.yml`).
The filename will be `[TIMESTAMP]_gitlab_ci_backup.tar.gz`. This timestamp can be used to restore an specific backup.
You can only restore a backup to exactly the same version of GitLab CI that you created it on, for example 7.10.1.

*If you are interested in the GitLab backup please follow to the [GitLab backup documentation](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/raketasks/backup_restore.md)*

```
# use this command if you've installed GitLab CI with the Omnibus package
sudo gitlab-ci-rake backup:create

# if you've installed GitLab from source
sudo -u gitlab_ci -H bundle exec rake backup:create RAILS_ENV=production
```


Example output:

```
Dumping database ...
Dumping PostgreSQL database gitlab_ci_development ... [DONE]
done
Dumping builds ...
done
Creating backup archive: 1430930060_gitlab_ci_backup.tar.gz ... done
Uploading backup archive to remote storage  ... skipped
Deleting tmp directories ... done
done
Deleting old backups ... skipping
```

## Upload backups to remote (cloud) storage

You can let the backup script upload the '.tar.gz' file it creates.
It uses the [Fog library](http://fog.io/) to perform the upload.
In the example below we use Amazon S3 for storage.
But Fog also lets you use [other storage providers](http://fog.io/storage/).

For omnibus packages:

```ruby
gitlab_ci['backup_upload_connection'] = {
  'provider' => 'AWS',
  'region' => 'eu-west-1',
  'aws_access_key_id' => 'AKIAKIAKI',
  'aws_secret_access_key' => 'secret123'
}
gitlab_ci['backup_upload_remote_directory'] = 'my.s3.bucket'
gitlab_ci['backup_multipart_chunk_size'] = 104857600
```

For installations from source:

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
      # The remote 'directory' to store your backups. For S3, this would be the bucket name.
      remote_directory: 'my.s3.bucket'
      multipart_chunk_size: 104857600
```

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

## Storing configuration files

Please be informed that a backup does not store your configuration and secret files.
If you use an Omnibus package please see the [instructions in the readme to backup your configuration](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#backup-and-restore-omnibus-gitlab-configuration).
If you have a cookbook installation there should be a copy of your configuration in Chef.
If you have an installation from source:
1. please backup `config/secrets.yml` file that contains key to encrypt variables in database,
but don't store it in the same place as your database backups.
Otherwise your secrets are exposed in case one of your backups is compromised.
1. please consider backing up your `application.yml` file,
1. any SSL keys and certificates, 
1. and your [SSH host keys](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079).

## Restore a previously created backup

You can only restore a backup to exactly the same version of GitLab CI that you created it on, for example 7.10.1.

### Installation from source

```
sudo -u gitlab_ci -H bundle exec rake backup:restore RAILS_ENV=production
```

Options

```
BACKUP=timestamp_of_backup (required if more than one backup exists)
```

### Omnibus package installation

We will assume that you have installed GitLab CI from an omnibus package and run
`sudo gitlab-ctl reconfigure` at least once.

First make sure your backup tar file is in `/var/opt/gitlab/backups`.

```shell
sudo cp 1393513186_gitlab_ci_backup.tar.gz /var/opt/gitlab/backups/
```

Next, restore the backup by running the restore command. You need to specify the
timestamp of the backup you are restoring.

```shell
# Stop processes that are connected to the database
sudo gitlab-ctl stop ci-unicorn
sudo gitlab-ctl stop ci-sidekiq

# This command will overwrite the contents of your GitLab CI database!
sudo gitlab-ci-rake backup:restore BACKUP=1393513186

# Start GitLab
sudo gitlab-ctl start
```

If there is a GitLab version mismatch between your backup tar file and the installed
version of GitLab, the restore command will abort with an error. Install a package for
the [required version](https://www.gitlab.com/downloads/archives/) and try again.



## Configure cron to make daily backups

### For installation from source:
```
cd /home/git/gitlab
sudo -u gitlab_ci -H editor config/application.yml # Enable keep_time in the backup section to automatically delete old backups
sudo -u gitlab_ci crontab -e # Edit the crontab for the git user
```

Add the following lines at the bottom:

```
# Create a backup of the GitLab CI every day at 4am
0 4 * * * cd /home/gitlab_ci/gitlab_ci && PATH=/usr/local/bin:/usr/bin:/bin bundle exec rake backup:create RAILS_ENV=production CRON=1
```

The `CRON=1` environment setting tells the backup script to suppress all progress output if there are no errors.
This is recommended to reduce cron spam.

### Omnibus package installation

To schedule a cron job that backs up your GitLab CI, use the root user:

```
sudo su -
crontab -e
```

There, add the following line to schedule the backup for everyday at 2 AM:

```
0 2 * * * /opt/gitlab/bin/gitlab-ci-rake backup:create CRON=1
```

You may also want to set a limited lifetime for backups to prevent regular
backups using all your disk space.  To do this add the following lines to
`/etc/gitlab/gitlab.rb` and reconfigure:

```
# limit backup lifetime to 7 days - 604800 seconds
gitlab_ci['backup_keep_time'] = 604800
```

NOTE: This cron job does not [backup your omnibus-gitlab configuration](#backup-and-restore-omnibus-gitlab-configuration).

## Known issues

If you’ve been using GitLab CI since 7.11 or before using MySQL and the official installation guide, you will probably get the following error while making a backup: `Dumping MySQL database gitlab_ci_production ... mysqldump: Got error: 1044: Access denied for user 'gitlab_ci'@'localhost' to database 'gitlab_ci_production' when using LOCK TABLES` .This can be resolved by adding a LOCK TABLES permission to the gitlab_ci MySQL user. Add this permission with:
```
$ mysql -u root -p
mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, LOCK TABLES ON `gitlab_ci_production`.* TO 'gitlab_ci'@'localhost';
```

