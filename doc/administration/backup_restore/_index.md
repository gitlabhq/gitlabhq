---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Back up and restore overview
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Your GitLab instance contains critical data for your software development or organization.
It is important to have a disaster recovery plan that includes regular backups for:

- **Data protection**: Safeguard against data loss due to hardware failures, software bugs, or accidental deletions.
- **Disaster recovery**: Restore GitLab instances and data in case of adverse events.
- **Version control**: Provide historical snapshots that enable rollbacks to previous states.
- **Compliance**: Meet the regulatory requirements of specific industries.
- **Migration**: Facilitate moving GitLab to new servers or environments.
- **Testing and development**: Create copies for testing upgrades or new features without risk to production data.

NOTE:
This documentation applies to GitLab Community and Enterprise Edition.
While data security is ensured for GitLab.com, you can't use these methods to export or back up your data from GitLab.com.

## Back up GitLab

The procedures to back up your GitLab instance vary based on your
deployment's specific configuration and usage patterns.
Factors such as data types, storage locations, and volume influence the backup method,
storage options, and restoration process. For more information, see [Back up GitLab](backup_gitlab.md).

## Restore GitLab

The procedures to back up your GitLab instance vary based on your
deployment's specific configuration and usage patterns.
Factors such as data types, storage locations, and volume influence the restoration process.

For more information, see [Restore GitLab](restore_gitlab.md).

## Migrate to a new server

Use the GitLab backup and restore features to migrate your instance to a new server. For GitLab Geo deployments,
consider [Geo disaster recovery for planned failover](../geo/disaster_recovery/planned_failover.md).
For more information, see [Migrate to a new server](migrate_to_new_server.md).

## Back up and restore large reference architectures

It is important to back up and restore large reference architectures regularly.
For information on how to configure and restore backups for object storage data,
PostgreSQL data, and Git repositories, see [Back up and restore large reference architectures](backup_large_reference_architectures.md).

## Backup archive process

For data preservation and system integrity, GitLab creates a backup archive. For detailed information
on how GitLab creates this archive, see [Backup archive process](backup_archive_process.md).

## Related topics

- [Geo](../geo/_index.md)
- [Disaster Recovery (Geo)](../geo/disaster_recovery/_index.md)
- [Migrating GitLab groups](../../user/group/import/_index.md)
- [Import and migrate projects](../../user/project/import/_index.md)
- [GitLab Linux package (Omnibus) - Backup and Restore](https://docs.gitlab.com/omnibus/settings/backups.html)
- [GitLab Helm chart - Backup and Restore](https://docs.gitlab.com/charts/backup-restore/)
- [GitLab Operator - Backup and Restore](https://docs.gitlab.com/operator/backup_and_restore.html)
