---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Roll back to earlier GitLab versions
description: Roll back Linux package or Docker instances to earlier versions.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can roll back to earlier versions of GitLab instances that were installed by using the Linux package or Docker.

When rolling back, you must take into account [version-specific changes](../versions/_index.md) that occurred when you previously upgraded.

## Prerequisites

Because you must revert the database schema changes (migrations) that were made when the instance was upgraded, you
must have:

- At least a database backup created under the exact same version and edition you are rolling back to.
- Ideally, a [full backup archive](../../administration/backup_restore/_index.md) of that exact same version and edition
  you are rolling back to.

## Roll back a Linux package instance

To roll back a Linux package instance to an earlier GitLab version:

1. Stop GitLab and remove the current package:

   ```shell
   # If running Puma
   sudo gitlab-ctl stop puma

   # Stop sidekiq
   sudo gitlab-ctl stop sidekiq

   # If on Ubuntu: remove the current package
   sudo dpkg -r gitlab-ee

   # If on Centos: remove the current package
   sudo yum remove gitlab-ee
   ```

1. Identify the GitLab version you want to roll back to:

   ```shell
   # (Replace with gitlab-ce if you have GitLab FOSS installed)

   # Ubuntu
   sudo apt-cache madison gitlab-ee

   # CentOS:
   sudo yum --showduplicates list gitlab-ee
   ```

1. Roll back GitLab to the desired version (for example, to GitLab 15.0.5):

   ```shell
   # (Replace with gitlab-ce if you have GitLab FOSS installed)

   # Ubuntu
   sudo apt install gitlab-ee=15.0.5-ee.0

   # CentOS:
   sudo yum install gitlab-ee-15.0.5-ee.0.el8
   ```

1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. [Restore GitLab](../../administration/backup_restore/restore_gitlab.md#restore-for-linux-package-installations)
   to complete the roll back.

## Roll back a Docker instance

The restore overwrites all newer GitLab database content with the older state.
A rollback is only recommended where necessary. For example, if post-upgrade tests reveal problems that cannot be resolved quickly.

{{< alert type="warning" >}}

You must have at least a database backup created with the exact same version and edition you are downgrading to.
The backup is required to revert the schema changes (migrations) made during the upgrade.

{{< /alert >}}

To roll back GitLab shortly after an upgrade:

1. Follow the upgrade procedure, by [specifying an earlier version](../../install/docker/installation.md#find-the-gitlab-version-and-edition-to-use)
   than you have installed.

1. Restore the [database backup you made](../../install/docker/backup.md#create-a-database-backup) before the upgrade.

   - [Follow the restore steps for Docker images](../../administration/backup_restore/restore_gitlab.md#restore-for-docker-image-and-gitlab-helm-chart-installations), including
     stopping Puma and Sidekiq. Only the database must be restored, so add
     `SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state`
     to the `gitlab-backup restore` command line arguments.
