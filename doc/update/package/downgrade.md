---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Downgrade

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This section contains general information on how to revert to an earlier version
of a package.

WARNING:
It is required to revert the schema changes (migrations) made as part of the upgrade.
You must therefore have at least a database backup created under the exact same version and edition you are
downgrading to. Ideally, you should have a
[full backup archive](../../administration/backup_restore/index.md)
on hand.
Restoring the backup is required to revert the schema changes (migrations) made as part of the upgrade.
The restore overwrites all newer GitLab database content with the older state.

The example below demonstrates the downgrade procedure when downgrading between minor
and patch versions (for example, from 15.0.6 to 15.0.5).

When downgrading between major versions, you must take into account version-specific changes that occurred when you
previously upgraded. For more information, see:

- [GitLab 17 changes](../versions/gitlab_17_changes.md)
- [GitLab 16 changes](../versions/gitlab_16_changes.md)
- [GitLab 15 changes](../versions/gitlab_15_changes.md)

These steps consist of:

- Stopping GitLab
- Removing the current package
- Installing the old package
- Reconfiguring GitLab
- Restoring the backup
- Starting GitLab

Steps:

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

1. Identify the GitLab version you want to downgrade to:

   ```shell
   # (Replace with gitlab-ce if you have GitLab FOSS installed)

   # Ubuntu
   sudo apt-cache madison gitlab-ee

   # CentOS:
   sudo yum --showduplicates list gitlab-ee
   ```

1. Downgrade GitLab to the desired version (for example, to GitLab 15.0.5):

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
   to complete the downgrade.
