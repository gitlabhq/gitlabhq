---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Roll back to earlier GitLab versions
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can roll back to earlier versions of GitLab instances that were installed by using the Linux package.

## Prerequisites

Because you must revert the database schema changes (migrations) that were made when the instance was upgraded, you
must have:

- At least a database backup created under the exact same version and edition you are rolling back to.
- Ideally, a [full backup archive](../../administration/backup_restore/_index.md) of that exact same version and edition
  you are rolling back to.

When rolling back to an earlier major versions, you must take into account version-specific changes that occurred when
you previously upgraded. For more information, see:

- [GitLab 17 changes](../versions/gitlab_17_changes.md)
- [GitLab 16 changes](../versions/gitlab_16_changes.md)
- [GitLab 15 changes](../versions/gitlab_15_changes.md)

## Roll back a Linux package instance to an earlier GitLab version

To roll back to an earlier GitLab version:

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
