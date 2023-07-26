---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Back up and restore large reference architectures **(FREE SELF)**

This document describes how to:

- [Configure daily backups](#configure-daily-backups)
- Take a backup now (planned)
- Restore a backup (planned)

This document is intended for environments using:

- [Linux package (Omnibus) and cloud-native hybrid reference architectures 3,000 users and up](../reference_architectures/index.md)
- Highly-automated deployment tooling such as [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit)
- [Amazon RDS](https://aws.amazon.com/rds/) for PostgreSQL data
- [Amazon S3](https://aws.amazon.com/s3/) for object storage
- [Object storage](../object_storage.md) to store everything possible, including [blobs](backup_gitlab.md#blobs) and [Container Registry](backup_gitlab.md#container-registry)

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
  1. Configure the node as another **GitLab Rails** node as defined in your [reference architecture](../reference_architectures/index.md). Use the [GitLab Environment Toolkit `gitlab_rails.yml` playbook](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/2.8.5/ansible/playbooks/gitlab_rails.yml). As with other GitLab Rails nodes, this node must have access to your main Postgres database as well as to Gitaly Cluster.

The backup node will copy all of the environment's Git data, so ensure that it has enough attached storage. For example, you need at least as much storage as one node in a Gitaly Cluster. Without Gitaly Cluster, you need at least as much storage as all Gitaly nodes. Keep in mind that Git repository backups can be significantly larger than Gitaly storage usage because forks are deduplicated in Gitaly but not in backups.

To back up the Git repositories:

1. SSH into the GitLab Rails node.
1. [Configure uploading backups to remote cloud storage](backup_gitlab.md#upload-backups-to-a-remote-cloud-storage).
1. [Configure AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/creating-a-backup-plan.html) for this bucket, or use a bucket in the same account and region as your production data object storage buckets, and ensure this bucket is included in your [preexisting AWS Backup](#configure-backup-of-postgresql-and-object-storage-data).
1. Run the [backup command](backup_gitlab.md#backup-command), skipping PostgreSQL data:

   ```shell
   sudo gitlab-backup create SKIP=db
   ```

   The resulting tar file will include only the Git repositories and some metadata. Blobs such as uploads, artifacts, and LFS do not need to be explicitly skipped, because the command does not back up object storage by default. The tar file will be created in the [`/var/opt/gitlab/backups` directory](https://docs.gitlab.com/omnibus/settings/backups.html#creating-an-application-backup) and [the filename will end in `_gitlab_backup.tar`](backup_gitlab.md#backup-timestamp).

   Since we configured uploading backups to remote cloud storage, the tar file will be uploaded to the remote region and deleted from disk.

1. Note the [timestamp](backup_gitlab.md#backup-timestamp) of the backup file for the next step. For example, if the backup name is `1493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar`, the timestamp is `1493107454_2018_04_25_10.6.4-ce`.
1. Run the [backup command](backup_gitlab.md#backup-command) again, this time specifying [incremental backup of Git repositories](backup_gitlab.md#incremental-repository-backups), and the timestamp of the source backup file. Using the example timestamp from the previous step, the command is:

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

We strongly recommend using rigorous automation tools such as [Terraform](https://www.terraform.io/) and [Ansible](https://www.ansible.com/) to administer large GitLab environments. [GitLab Environment Toolkit](https://gitlab.com/gitlab-org/gitlab-environment-toolkit) is a good example. You may choose to build up your own deployment tool and use it as a reference.

Following this approach, your configuration files and secrets should already exist in secure, canonical locations outside of the production VMs or pods. This document does not cover backing up that data.

As an example, you can store secrets in [AWS Secret Manager](https://aws.amazon.com/secrets-manager/) and pull them into your [Terraform configuration files](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_provision.md#terraform-data-sources). [AWS Secret Manager can be configured to replicate to multiple regions](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create-manage-multi-region-secrets.html).
