---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Back up and restore GitLab **(FREE SELF)**

Your software or organization depends on the data in your GitLab instance. You need to ensure this data is protected from adverse events such as:

- Corrupted data
- Accidental deletion of data
- Ransomware attacks
- Unexpected cloud provider downtime

You can mitigate all of these risks with a disaster recovery plan that includes backups.

## Back up GitLab

For detailed information on backing up GitLab, see [Backup GitLab](backup_gitlab.md).

## Restore GitLab

For detailed information on restoring GitLab, see [Restore GitLab](restore_gitlab.md).

## Migrate to a new server

For detailed information on using back up and restore to migrate to a new server, see
[Migrate to a new server](migrate_to_new_server.md).

## Additional notes

This documentation is for GitLab Community and Enterprise Edition. We back up
GitLab.com and ensure your data is secure. You can't, however, use these
methods to export or back up your data yourself from GitLab.com.

Issues are stored in the database, and can't be stored in Git itself.

## Related features

- [Geo](../geo/index.md)
- [Disaster Recovery (Geo)](../geo/disaster_recovery/index.md)
- [Migrating GitLab groups](../../user/group/import/index.md)
- [Import and migrate projects](../../user/project/import/index.md)
- [GitLab Linux package (Omnibus) - Backup and Restore](https://docs.gitlab.com/omnibus/settings/backups.html)
- [GitLab Helm chart - Backup and Restore](https://docs.gitlab.com/charts/backup-restore/)
- [GitLab Operator - Backup and Restore](https://docs.gitlab.com/operator/backup_and_restore.html)
