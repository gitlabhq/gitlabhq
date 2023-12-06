---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Back up and restore large reference architectures **(FREE SELF)**

This document describes how to:

- [Configure daily backups](#configure-daily-backups)
- Take a backup now (planned)
- [Restore a backup](#restore-a-backup)

This document is intended for environments using:

- [Linux package (Omnibus) and cloud-native hybrid reference architectures 3,000 users and up](../reference_architectures/index.md)
- [Amazon RDS](https://aws.amazon.com/rds/) for PostgreSQL data
- [Amazon S3](https://aws.amazon.com/s3/) for object storage
- [Object storage](../object_storage.md) to store everything possible, including [blobs](backup_gitlab.md#blobs) and [container registry](backup_gitlab.md#container-registry)

## Configure daily backups

### Configure backup of PostgreSQL and object storage data

The [backup command](backup_gitlab.md) uses `pg_dump`, which is [not appropriate for databases over 100 GB](backup_gitlab.md#postgresql-databases). You must choose a PostgreSQL solution which has native, robust backup capabilities.

[Object storage](../object_storage.md), ([not NFS](../nfs.md)) is recommended for storing GitLab data, including [blobs](backup_gitlab.md#blobs) and [Container registry](backup_gitlab.md#container-registry).

1. [Configure AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/creating-a-backup-plan.html) to back up both RDS and S3 data. For maximum protection, [configure continuous backups as well as snapshot backups](https://docs.aws.amazon.com/aws-backup/latest/devguide/point-in-time-recovery.html).
1. Configure AWS Backup to copy backups to a separate region. When AWS takes a backup, the backup can only be restored in the region the backup is stored.
1. After AWS Backup has run at least one scheduled backup, then you can [create an on-demand backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/recov-point-create-on-demand-backup.html) as needed.

### Configure backup of Git repositories

NOTE:
There is a feature proposal to add the ability to back up repositories directly from Gitaly to object storage. See [epic 10077](https://gitlab.com/groups/gitlab-org/-/epics/10077).

- Linux package (Omnibus):

  We will continue to use the [backup command](backup_gitlab.md#backup-command) to back up Git repositories.

  If utilization is low enough, you can run it from an existing GitLab Rails node. Otherwise, spin up another node.

- Cloud native hybrid:

  [The `backup-utility` command in a `toolbox` pod fails when there is a large amount of data](https://gitlab.com/gitlab-org/gitlab/-/issues/396343#note_1352989908). In this case, you must run the [backup command](backup_gitlab.md#backup-command) to back up Git repositories, and you must run it in a VM running the GitLab Linux package:

  1. Spin up a VM with 8 vCPU and 7.2 GB memory. This node will be used to back up Git repositories. Note that
     [a Praefect node cannot be used to back up Git data](https://gitlab.com/gitlab-org/gitlab/-/issues/396343#note_1385950340).
  1. Configure the node as another **GitLab Rails** node as defined in your [reference architecture](../reference_architectures/index.md).
     As with other GitLab Rails nodes, this node must have access to your main PostgreSQL database, Redis, object storage, and Gitaly Cluster.
  1. Ensure the GitLab application isn't running on this node by disabling most services:

     1. Edit `/etc/gitlab/gitlab.rb` to ensure the following services are disabled.
        `roles(['application_role'])` disables Redis, PostgreSQL, and Consul, and
        is the basis of the reference architecture Rails node definition.

        ```ruby
        roles(['application_role'])
        gitlab_workhorse['enable'] = false
        puma['enable'] = false
        sidekiq['enable'] = false
        gitlab_kas['enable'] = false
        gitaly['enable'] = false
        prometheus_monitoring['enable'] = false
        ```

     1. Reconfigure GitLab:

        ```shell
        sudo gitlab-ctl reconfigure
        ```

     1. The only service that should be left is `logrotate`, you can verify with:

        ```shell
        gitlab-ctl status
        ```

     There is [a feature request](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6823) for a role in the Linux package
     that meets these requirements.

To back up the Git repositories:

1. Ensure that the GitLab Rails node has enough attached storage to store Git repositories and an archive of the Git repositories. Additionally, the contents of forked repositories are duplicated into their forks during backup.
   For example, if you have 5 GB worth of Git repositories and two forks of a 1 GB repository, then you require at least 14 GB of attached storage to account for:
   - 7 GB of Git data.
   - A 7 GB archive file of all Git data.
1. SSH into the GitLab Rails node.
1. [Configure uploading backups to remote cloud storage](backup_gitlab.md#upload-backups-to-a-remote-cloud-storage).
1. [Configure AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/creating-a-backup-plan.html) for this bucket, or use a bucket in the same account and region as your production data object storage buckets, and ensure this bucket is included in your [preexisting AWS Backup](#configure-backup-of-postgresql-and-object-storage-data).
1. Run the [backup command](backup_gitlab.md#backup-command), skipping PostgreSQL data:

   ```shell
   sudo gitlab-backup create SKIP=db
   ```

   The resulting tar file will include only the Git repositories and some metadata. Blobs such as uploads, artifacts, and LFS do not need to be explicitly skipped, because the command does not back up object storage by default. The tar file will be created in the [`/var/opt/gitlab/backups` directory](https://docs.gitlab.com/omnibus/settings/backups.html#creating-an-application-backup) and [the file name will end in `_gitlab_backup.tar`](index.md#backup-id).

   Since we configured uploading backups to remote cloud storage, the tar file will be uploaded to the remote region and deleted from disk.

1. Note the [backup ID](index.md#backup-id) of the backup file for the next step. For example, if the backup archive name is `1493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar`, the backup ID is `1493107454_2018_04_25_10.6.4-ce`.
1. Run the [backup command](backup_gitlab.md#backup-command) again, this time specifying [incremental backup of Git repositories](backup_gitlab.md#incremental-repository-backups), and the backup ID of the source backup file. Using the example ID from the previous step, the command is:

   ```shell
   sudo gitlab-backup create SKIP=db INCREMENTAL=yes PREVIOUS_BACKUP=1493107454_2018_04_25_10.6.4-ce
   ```

1. Check that the incremental backup succeeded and uploaded to object storage.
1. [Configure cron to make daily backups](backup_gitlab.md#configuring-cron-to-make-daily-backups). Edit the crontab for the `root` user:

   ```shell
   sudo su -
   crontab -e
   ```

1. There, add the following line to schedule the backup for everyday at 2 AM:

   ```plaintext
   0 2 * * * /opt/gitlab/bin/gitlab-backup create SKIP=db INCREMENTAL=yes PREVIOUS_BACKUP=1493107454_2018_04_25_10.6.4-ce CRON=1
   ```

### Configure backup of configuration files

If your configuration and secrets are defined outside of your deployment and then deployed into it, then the implementation of the backup strategy depends on your specific setup and requirements. As an example, you can store secrets in [AWS Secret Manager](https://aws.amazon.com/secrets-manager/) with [replication to multiple regions](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create-manage-multi-region-secrets.html) and configure a script to back up secrets automatically.

If your configuration and secrets are only defined inside your deployment:

1. [Storing configuration files](backup_gitlab.md#storing-configuration-files) describes how to extract configuration and secrets files.
1. These files should be uploaded to a separate, more restrictive, object storage account.

## Restore a backup

Restore a backup of a GitLab instance.

### Prerequisites

Before restoring a backup:

1. Choose a [working destination GitLab instance](restore_gitlab.md#the-destination-gitlab-instance-must-already-be-working).
1. Ensure the destination GitLab instance is in a region where your AWS backups are stored.
1. Check that the [destination GitLab instance uses exactly the same version and type (CE or EE) of GitLab](restore_gitlab.md#the-destination-gitlab-instance-must-have-the-exact-same-version)
   on which the backup data was created. For example, CE 15.1.4.
1. [Restore backed up secrets to the destination GitLab instance](restore_gitlab.md#gitlab-secrets-must-be-restored).
1. Ensure that the [destination GitLab instance has the same repository storages configured](restore_gitlab.md#certain-gitlab-configuration-must-match-the-original-backed-up-environment).
   Additional storages are fine.
1. If the backed up GitLab instance had any blobs stored in object storage,
   [ensure that object storage is configured for those kinds of blobs](restore_gitlab.md#certain-gitlab-configuration-must-match-the-original-backed-up-environment).
1. If the backed up GitLab instance had any blobs stored on the file system, [ensure that NFS is configured](restore_gitlab.md#certain-gitlab-configuration-must-match-the-original-backed-up-environment).
1. To use new secrets or configuration, and to avoid unexpected configuration changes during restore:

   - Linux package installations on all nodes:
     1. [Reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation) the destination GitLab instance.
     1. [Restart](../restart_gitlab.md#restart-a-linux-package-installation) the destination GitLab instance.

   - Helm chart (Kubernetes) installations:

     1. On all GitLab Linux package nodes, run:

        ```shell
        sudo gitlab-ctl reconfigure
        sudo gitlab-ctl start
        ```

     1. Make sure you have a running GitLab instance by deploying the charts.
        Ensure the Toolbox pod is enabled and running by executing the following command:

        ```shell
        kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
        ```

     1. The Webservice, Sidekiq and Toolbox pods must be restarted.
        The safest way to restart those pods is to run:

        ```shell
        kubectl delete pods -lapp=sidekiq,release=<helm release name>
        kubectl delete pods -lapp=webservice,release=<helm release name>
        kubectl delete pods -lapp=toolbox,release=<helm release name>
        ```

1. Confirm the destination GitLab instance still works. For example:

   - Make requests to the [health check endpoints](../monitoring/health_check.md).
   - [Run GitLab check Rake tasks](../raketasks/maintenance.md#check-gitlab-configuration).

1. Stop GitLab services which connect to the PostgreSQL database.

   - Linux package installations on all nodes running Puma or Sidekiq, run:

     ```shell
     sudo gitlab-ctl stop
     ```

   - Helm chart (Kubernetes) installations:

     1. Note the current number of replicas for database clients for subsequent restart:

        ```shell
        kubectl get deploy -n <namespace> -lapp=sidekiq,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        kubectl get deploy -n <namespace> -lapp=webservice,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        kubectl get deploy -n <namespace> -lapp=prometheus,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        ```

     1. Stop the clients of the database to prevent locks interfering with the restore process:

        ```shell
        kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=0
        kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=0
        kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=0
        ```

### Restore object storage data

Each bucket exists as a separate backup within AWS and each backup can be restored to an existing or
new bucket.

1. To restore buckets, an IAM role with the correct permissions is required:

   - `AWSBackupServiceRolePolicyForBackup`
   - `AWSBackupServiceRolePolicyForRestores`
   - `AWSBackupServiceRolePolicyForS3Restore`
   - `AWSBackupServiceRolePolicyForS3Backup`

1. If existing buckets are being used, they must have
   [Access Control Lists enabled](https://docs.aws.amazon.com/AmazonS3/latest/userguide/managing-acls.html).
1. [Restore the S3 buckets using built-in tooling](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-s3.html).
1. You can move on to [Restore PostgreSQL data](#restore-postgresql-data) while the restore job is
   running.

### Restore PostgreSQL data

1. [Restore the AWS RDS database using built-in tooling](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-rds.html),
   which creates a new RDS instance.
1. Because the new RDS instance has a different endpoint, you must reconfigure the destination GitLab instance
   to point to the new database:

   - For Linux package installations, follow
     [Using a non-packaged PostgreSQL database management server](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server).

   - For Helm chart (Kubernetes) installations, follow
     [Configure the GitLab chart with an external database](https://docs.gitlab.com/charts/advanced/external-db/index.html).

1. Before moving on, wait until the new RDS instance is created and ready to use.

### Restore Git repositories

Select or create a node to restore:

- For Linux package installations, choose a Rails node, which is a node that normally runs Puma or Sidekiq.
- For Helm chart (Kubernetes) installations, if you don't already have [a Git repository backup node](#configure-backup-of-git-repositories),
  create one now:

  1. Spin up a VM with 8 vCPU and 7.2 GB memory.
     This node is used to back up and restore Git repositories because a Praefect node
     [cannot be used to back up Git data](https://gitlab.com/gitlab-org/gitlab/-/issues/396343#note_1385950340).
  1. Configure the node as another **GitLab Rails** node as defined in your
     [reference architecture](../reference_architectures/index.md).
     As with other GitLab Rails nodes, this node must have access to your main PostgreSQL database as
     well as to Gitaly Cluster.
  1. [Restore backed up secrets to the target GitLab](restore_gitlab.md#gitlab-secrets-must-be-restored).

To restore Git repositories:

1. Ensure the node has enough attached storage to store both the `.tar` file of Git repositories,
   and its extracted data.
1. SSH into the GitLab Rails node.
1. As part of [Restore object storage data](#restore-object-storage-data), you should have restored
   a bucket containing the GitLab backup `.tar` file of Git repositories.
1. Download the backup `.tar` file from its bucket into the backup directory described in the
   `gitlab.rb` configuration `gitlab_rails['backup_path']`.
   The default is `/var/opt/gitlab/backups`.
   The backup file must be owned by the `git` user.

   ```shell
   sudo cp 11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar /var/opt/gitlab/backups/
   sudo chown git:git /var/opt/gitlab/backups/11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar
   ```

1. Restore the backup, specifying the ID of the backup you wish to restore:

   WARNING:
   The restore command requires
   [additional parameters](backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer)
   when your installation is using PgBouncer, for either performance reasons or when using it with a
   Patroni cluster.

   ```shell
   # This command will overwrite the contents of your GitLab database!
   # NOTE: "_gitlab_backup.tar" is omitted from the name
   sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce
   ```

   If there's a GitLab version mismatch between your backup tar file and the installed version of
   GitLab, the restore command aborts with an error message.
   Install the [correct GitLab version](https://packages.gitlab.com/gitlab/), and then try again.

1. Restart and [check](../raketasks/maintenance.md#check-gitlab-configuration) GitLab:

   - Linux package installations:

     1. In all Puma or Sidekiq nodes, run:

        ```shell
        sudo gitlab-ctl restart
        ```

     1. In one Puma or Sidekiq node, run:

        ```shell
        sudo gitlab-rake gitlab:check SANITIZE=true
        ```

   - Helm chart (Kubernetes) installations:

     1. Start the stopped deployments, using the number of replicas noted in [Prerequisites](#prerequisites):

        ```shell
        kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=<original value>
        kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=<original value>
        kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=<original value>
        ```

     1. In the Toolbox pod, run:

        ```shell
        sudo gitlab-rake gitlab:check SANITIZE=true
        ```

1. Check that
   [database values can be decrypted](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)
   especially if `/etc/gitlab/gitlab-secrets.json` was restored, or if a different server is the
   target for the restore:

   - For Linux package installations, in a Puma or Sidekiq node, run:

     ```shell
     sudo gitlab-rake gitlab:doctor:secrets
     ```

   - For Helm chart (Kubernetes) installations, in the Toolbox pod, run:

     ```shell
     sudo gitlab-rake gitlab:doctor:secrets
     ```

1. For added assurance, you can perform
   [an integrity check on the uploaded files](../raketasks/check.md#uploaded-files-integrity):

   - For Linux package installations, in a Puma or Sidekiq node, run:

     ```shell
     sudo gitlab-rake gitlab:artifacts:check
     sudo gitlab-rake gitlab:lfs:check
     sudo gitlab-rake gitlab:uploads:check
     ```

   - For Helm chart (Kubernetes) installations, because these commands can take a long time because they iterate over all rows, run the following commands the GitLab Rails node,
     rather than a Toolbox pod:

     ```shell
     sudo gitlab-rake gitlab:artifacts:check
     sudo gitlab-rake gitlab:lfs:check
     sudo gitlab-rake gitlab:uploads:check
     ```

   If missing or corrupted files are found, it does not always mean the back up and restore process failed.
   For example, the files might be missing or corrupted on the source GitLab instance. You might need to cross-reference prior backups.
   If you are migrating GitLab to a new environment, you can run the same checks on the source GitLab instance to determine whether
   the integrity check result is preexisting or related to the backup and restore process.

The restoration should be complete.
