---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Back up and restore large reference architectures
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This document describes how to:

- [Configure daily backups](#configure-daily-backups)
- Take a backup now (planned)
- [Restore a backup](#restore-a-backup)

This document is intended for environments using:

- [Linux package (Omnibus) and cloud-native hybrid reference architectures 60 RPS / 3,000 users and up](../reference_architectures/_index.md)
- [Amazon RDS](https://aws.amazon.com/rds/) for PostgreSQL data
- [Amazon S3](https://aws.amazon.com/s3/) for object storage
- [Object storage](../object_storage.md) to store everything possible, including [blobs](backup_gitlab.md#blobs) and [container registry](backup_gitlab.md#container-registry)

## Configure daily backups

### Configure backup of PostgreSQL data

The [backup command](backup_gitlab.md) uses `pg_dump`, which is [not appropriate for databases over 100 GB](backup_gitlab.md#postgresql-databases). You must choose a PostgreSQL solution which has native, robust backup capabilities.

::Tabs

:::TabTitle AWS

1. [Configure AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/creating-a-backup-plan.html) to back up RDS (and S3) data. For maximum protection, [configure continuous backups as well as snapshot backups](https://docs.aws.amazon.com/aws-backup/latest/devguide/point-in-time-recovery.html).
1. Configure AWS Backup to copy backups to a separate region. When AWS takes a backup, the backup can only be restored in the region the backup is stored.
1. After AWS Backup has run at least one scheduled backup, then you can [create an on-demand backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/recov-point-create-on-demand-backup.html) as needed.

:::TabTitle Google

Schedule [automated daily backups of Google Cloud SQL data](https://cloud.google.com/sql/docs/postgres/backup-recovery/backing-up#schedulebackups).
Daily backups [can be retained](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups#retention) for up to one year, and transaction logs can be retained for 7 days by default for point-in-time recovery.

::EndTabs

### Configure backup of object storage data

[Object storage](../object_storage.md), ([not NFS](../nfs.md)) is recommended for storing GitLab data, including [blobs](backup_gitlab.md#blobs) and [Container registry](backup_gitlab.md#container-registry).

::Tabs

:::TabTitle AWS

Configure AWS Backup to back up S3 data. This can be done at the same time when [configuring the backup of PostgreSQL data](#configure-backup-of-postgresql-data).

:::TabTitle Google

1. [Create a backup bucket in GCS](https://cloud.google.com/storage/docs/creating-buckets).
1. [Create Storage Transfer Service jobs](https://cloud.google.com/storage-transfer/docs/create-transfers) which copy each GitLab object storage bucket to a backup bucket. You can create these jobs once, and [schedule them to run daily](https://cloud.google.com/storage-transfer/docs/schedule-transfer-jobs). However this mixes new and old object storage data, so files that were deleted in GitLab will still exist in the backup. This wastes storage after restore, but it is otherwise not a problem. These files would be inaccessible to GitLab users since they do not exist in the GitLab database. You can delete [some of these orphaned files](../../raketasks/cleanup.md#clean-up-project-upload-files-from-object-storage) after restore, but this clean up Rake task only operates on a subset of files.
   1. For `When to overwrite`, choose `Never`. GitLab object stored files are intended to be immutable. This selection could be helpful if a malicious actor succeeded at mutating GitLab files.
   1. For `When to delete`, choose `Never`. If you sync the backup bucket to source, then you cannot recover if files are accidentally or maliciously deleted from source.
1. Alternatively, it is possible to backup object storage into buckets or subdirectories segregated by day. This avoids the problem of orphaned files after restore, and supports backup of file versions if needed. But it greatly increases backup storage costs. This can be done with [a Cloud Function triggered by Cloud Scheduler](https://cloud.google.com/scheduler/docs/tut-gcf-pub-sub), or with a script run by a cronjob. A partial example:

   ```shell
   # Set GCP project so you don't have to specify it in every command
   gcloud config set project example-gcp-project-name

   # Grant the Storage Transfer Service's hidden service account permission to write to the backup bucket. The integer 123456789012 is the GCP project's ID.
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.objectAdmin gs://backup-bucket

   # Grant the Storage Transfer Service's hidden service account permission to list and read objects in the source buckets. The integer 123456789012 is the GCP project's ID.
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-artifacts
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-ci-secure-files
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-dependency-proxy
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-lfs
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-mr-diffs
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-packages
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-pages
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-registry
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-terraform-state
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-uploads

   # Create transfer jobs for each bucket, targeting a subdirectory in the backup bucket.
   today=$(date +%F)
   gcloud transfer jobs create gs://gitlab-bucket-artifacts/ gs://backup-bucket/$today/artifacts/ --name "$today-backup-artifacts"
   gcloud transfer jobs create gs://gitlab-bucket-ci-secure-files/ gs://backup-bucket/$today/ci-secure-files/ --name "$today-backup-ci-secure-files"
   gcloud transfer jobs create gs://gitlab-bucket-dependency-proxy/ gs://backup-bucket/$today/dependency-proxy/ --name "$today-backup-dependency-proxy"
   gcloud transfer jobs create gs://gitlab-bucket-lfs/ gs://backup-bucket/$today/lfs/ --name "$today-backup-lfs"
   gcloud transfer jobs create gs://gitlab-bucket-mr-diffs/ gs://backup-bucket/$today/mr-diffs/ --name "$today-backup-mr-diffs"
   gcloud transfer jobs create gs://gitlab-bucket-packages/ gs://backup-bucket/$today/packages/ --name "$today-backup-packages"
   gcloud transfer jobs create gs://gitlab-bucket-pages/ gs://backup-bucket/$today/pages/ --name "$today-backup-pages"
   gcloud transfer jobs create gs://gitlab-bucket-registry/ gs://backup-bucket/$today/registry/ --name "$today-backup-registry"
   gcloud transfer jobs create gs://gitlab-bucket-terraform-state/ gs://backup-bucket/$today/terraform-state/ --name "$today-backup-terraform-state"
   gcloud transfer jobs create gs://gitlab-bucket-uploads/ gs://backup-bucket/$today/uploads/ --name "$today-backup-uploads"
   ```

   1. These Transfer Jobs are not automatically deleted after running. You could implement clean up of old jobs in the script.
   1. The example script does not delete old backups. You could implement clean up of old backups according to your desired retention policy.
1. Ensure that backups are performed at the same time or later than Cloud SQL backups, to reduce data inconsistencies.

::EndTabs

### Configure backup of Git repositories

Set up cronjobs to perform Gitaly server-side backups:

::Tabs

:::TabTitle Linux package (Omnibus)

1. [Configure a server-side backup destination in all Gitaly nodes](../gitaly/configure_gitaly.md#configure-server-side-backups).
1. Configure [Upload backups to a remote (cloud) storage](backup_gitlab.md#upload-backups-to-a-remote-cloud-storage). Even though Gitaly backs up all Git data to its own object storage bucket, the `gitlab-backup` command also creates a `tar` file containing backup metadata. This `tar` file is required by the restore command.
1. Make sure to add both buckets to [backups of object storage data](#configure-backup-of-object-storage-data).
1. SSH into a GitLab Rails node, which is a node that runs Puma or Sidekiq.
1. Take a full backup of your Git data. Use the `REPOSITORIES_SERVER_SIDE` variable, and skip PostgreSQL data:

   ```shell
   sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db
   ```

   This causes Gitaly nodes to upload the Git data and some metadata to remote storage. Blobs such as uploads, artifacts, and LFS do not need to be explicitly skipped, because the `gitlab-backup` command does not back up object storage by default.

1. Note the [backup ID](backup_archive_process.md#backup-id) of the backup, which is needed for the next step. For example, if the backup command outputs
   `2024-02-22 02:17:47 UTC -- Backup 1708568263_2024_02_22_16.9.0-ce is done.`, then the backup ID is `1708568263_2024_02_22_16.9.0-ce`.
1. Check that the full backup created data in both the Gitaly backup bucket as well as the regular backup bucket.
1. Run the [backup command](backup_gitlab.md#backup-command) again, this time specifying [incremental backup of Git repositories](backup_gitlab.md#incremental-repository-backups), and a backup ID. Using the example ID from the previous step, the command is:

   ```shell
   sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db INCREMENTAL=yes PREVIOUS_BACKUP=1708568263_2024_02_22_16.9.0-ce
   ```

   The value of `PREVIOUS_BACKUP` is not used by this command, but it is required by the command. There is an issue for removing this unnecessary requirement, see [issue 429141](https://gitlab.com/gitlab-org/gitlab/-/issues/429141).

1. Check that the incremental backup succeeded, and added data to object storage.
1. [Configure cron to make daily backups](backup_gitlab.md#configuring-cron-to-make-daily-backups). Edit the crontab for the `root` user:

   ```shell
   sudo su -
   crontab -e
   ```

1. There, add the following lines to schedule the backup for everyday of every month at 2 AM. To limit the number of increments needed to restore a backup, a full backup of Git repositories will be taken on the first of each month, and the rest of the days will take an incremental backup.:

   ```plaintext
   0 2 1 * * /opt/gitlab/bin/gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db CRON=1
   0 2 2-31 * * /opt/gitlab/bin/gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db INCREMENTAL=yes PREVIOUS_BACKUP=1708568263_2024_02_22_16.9.0-ce CRON=1
   ```

:::TabTitle Helm chart (Kubernetes)

1. [Configure a server-side backup destination in all Gitaly nodes](../gitaly/configure_gitaly.md#configure-server-side-backups).
1. [Configure Object storage buckets for backup-utility](https://docs.gitlab.com/charts/backup-restore/#object-storage). Even though Gitaly backs up all Git data to its own object storage bucket, the `backup-utility` command also creates a `tar` file containing backup metadata. This `tar` file is required by the restore command.
1. Make sure to add both buckets to [backups of object storage data](#configure-backup-of-object-storage-data).
1. Take a full backup of your Git data. Use the `--repositories-server-side` option, and skip all other data:

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --repositories-server-side --skip db,builds,pages,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,pages,ci_secure_files
   ```

   This causes Gitaly nodes to upload the Git data and some metadata to remote storage. See [Toolbox included tools](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#toolbox-included-tools).

1. Check that the full backup created data in both the Gitaly backup bucket as well as the regular backup bucket. Incremental repository backup is not supported by `backup-utility` with server-side repository backup, see [charts issue 3421](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3421).
1. [Configure cron to make daily backups](https://docs.gitlab.com/charts/backup-restore/backup.html#cron-based-backup). Specifically, set `gitlab.toolbox.backups.cron.extraArgs` to include:

   ```shell
   --repositories-server-side --skip db --skip repositories --skip uploads --skip builds --skip artifacts --skip pages --skip lfs --skip terraform_state --skip registry --skip packages --skip ci_secure_files
   ```

::EndTabs

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
1. Ensure that [object storage is configured](restore_gitlab.md#certain-gitlab-configuration-must-match-the-original-backed-up-environment).
1. To use new secrets or configuration, and to avoid dealing with any unexpected configuration changes during restore:

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

::Tabs

:::TabTitle AWS

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

:::TabTitle Google

1. [Create Storage Transfer Service jobs](https://cloud.google.com/storage-transfer/docs/create-transfers) to transfer backed up data to the GitLab buckets.
1. You can move on to [Restore PostgreSQL data](#restore-postgresql-data) while the transfer jobs are
   running.

::EndTabs

### Restore PostgreSQL data

::Tabs

:::TabTitle AWS

1. [Restore the AWS RDS database using built-in tooling](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-rds.html),
   which creates a new RDS instance.
1. Because the new RDS instance has a different endpoint, you must reconfigure the destination GitLab instance
   to point to the new database:

   - For Linux package installations, follow
     [Using a non-packaged PostgreSQL database management server](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server).

   - For Helm chart (Kubernetes) installations, follow
     [Configure the GitLab chart with an external database](https://docs.gitlab.com/charts/advanced/external-db/index.html).

1. Before moving on, wait until the new RDS instance is created and ready to use.

:::TabTitle Google

1. [Restore the Google Cloud SQL database using built-in tooling](https://cloud.google.com/sql/docs/postgres/backup-recovery/restoring).
1. If you restore to a new database instance, then reconfigure GitLab to point to the new database:

   - For Linux package installations, follow
     [Using a non-packaged PostgreSQL database management server](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server).

   - For Helm chart (Kubernetes) installations, follow
     [Configure the GitLab chart with an external database](https://docs.gitlab.com/charts/advanced/external-db/index.html).

1. Before moving on, wait until the Cloud SQL instance is ready to use.

::EndTabs

### Restore Git repositories

First, as part of [Restore object storage data](#restore-object-storage-data), you should have already:

- Restored a bucket containing the Gitaly server-side backups of Git repositories.
- Restored a bucket containing the `*_gitlab_backup.tar` files.

::Tabs

:::TabTitle Linux package (Omnibus)

1. SSH into a GitLab Rails node, which is a node that runs Puma or Sidekiq.
1. In your backup bucket, choose a `*_gitlab_backup.tar` file based on its timestamp, aligned with the PostgreSQL and object storage data that you restored.
1. Download the `tar` file in `/var/opt/gitlab/backups/`.
1. Restore the backup, specifying the ID of the backup you wish to restore, omitting `_gitlab_backup.tar` from the name:

   ```shell
   # This command will overwrite the contents of your GitLab database!
   sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce SKIP=db
   ```

   If there's a GitLab version mismatch between your backup tar file and the installed version of
   GitLab, the restore command aborts with an error message.
   Install the [correct GitLab version](https://packages.gitlab.com/gitlab/), and then try again.

1. Restart and [check](../raketasks/maintenance.md#check-gitlab-configuration) GitLab:

   1. In all Puma or Sidekiq nodes, run:

      ```shell
      sudo gitlab-ctl restart
      ```

   1. In one Puma or Sidekiq node, run:

      ```shell
      sudo gitlab-rake gitlab:check SANITIZE=true
      ```

1. Check that
   [database values can be decrypted](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)
   especially if `/etc/gitlab/gitlab-secrets.json` was restored, or if a different server is the
   target for the restore:

   In a Puma or Sidekiq node, run:

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. For added assurance, you can perform
   [an integrity check on the uploaded files](../raketasks/check.md#uploaded-files-integrity):

   In a Puma or Sidekiq node, run:

   ```shell
   sudo gitlab-rake gitlab:artifacts:check
   sudo gitlab-rake gitlab:lfs:check
   sudo gitlab-rake gitlab:uploads:check
   ```

   If missing or corrupted files are found, it does not always mean the backup and restore process failed.
   For example, the files might be missing or corrupted on the source GitLab instance. You might need to cross-reference prior backups.
   If you are migrating GitLab to a new environment, you can run the same checks on the source GitLab instance to determine whether
   the integrity check result is preexisting or related to the backup and restore process.

:::TabTitle Helm chart (Kubernetes)

1. SSH into a toolbox pod.
1. In your backup bucket, choose a `*_gitlab_backup.tar` file based on its timestamp, aligned with the PostgreSQL and object storage data that you restored.
1. Download the `tar` file in `/var/opt/gitlab/backups/`.
1. Restore the backup, specifying the ID of the backup you wish to restore, omitting `_gitlab_backup.tar` from the name:

   ```shell
   # This command will overwrite the contents of Gitaly!
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t 11493107454_2018_04_25_10.6.4-ce --skip db,builds,pages,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,pages,ci_secure_files
   ```

   If there's a GitLab version mismatch between your backup tar file and the installed version of
   GitLab, the restore command aborts with an error message.
   Install the [correct GitLab version](https://packages.gitlab.com/gitlab/), and then try again.

1. Restart and [check](../raketasks/maintenance.md#check-gitlab-configuration) GitLab:

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

   In the Toolbox pod, run:

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. For added assurance, you can perform
   [an integrity check on the uploaded files](../raketasks/check.md#uploaded-files-integrity):

   Since these commands can take a long time because they iterate over all rows, run the following commands the GitLab Rails node,
   rather than a Toolbox pod:

   ```shell
   sudo gitlab-rake gitlab:artifacts:check
   sudo gitlab-rake gitlab:lfs:check
   sudo gitlab-rake gitlab:uploads:check
   ```

   If missing or corrupted files are found, it does not always mean the backup and restore process failed.
   For example, the files might be missing or corrupted on the source GitLab instance. You might need to cross-reference prior backups.
   If you are migrating GitLab to a new environment, you can run the same checks on the source GitLab instance to determine whether
   the integrity check result is preexisting or related to the backup and restore process.

::EndTabs

The restoration should be complete.
