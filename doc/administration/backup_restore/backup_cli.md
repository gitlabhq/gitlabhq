---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Back up and Restore GitLab with `gitlab-backup-cli`

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11908) in GitLab 17.0. This feature is an [experiment](../../policy/experiment-beta-support.md) and subject to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

This tool is under development and is ultimately meant to replace [the Rake tasks used for backing up and restoring GitLab](backup_gitlab.md). You can follow the development of this tool in the epic: [Next Gen Scalable Backup and Restore](https://gitlab.com/groups/gitlab-org/-/epics/11577).

Feedback on the tool is welcome in [the feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/457155).

## Taking a backup

To take a backup of the current GitLab installation:

```shell
sudo gitlab-backup-cli backup all
```

## Backup directory structure

Example backup directory structure:

```plaintext
backups
└── 1714053314_2024_04_25_17.0.0-pre
    ├── artifacts.tar.gz
    ├── backup_information.json
    ├── builds.tar.gz
    ├── ci_secure_files.tar.gz
    ├── db
    │   ├── ci_database.sql.gz
    │   └── database.sql.gz
    ├── lfs.tar.gz
    ├── packages.tar.gz
    ├── pages.tar.gz
    ├── registry.tar.gz
    ├── repositories
    │   ├── default
    │   │   ├── @hashed
    │   │   └── @snippets
    │   └── manifests
    │       └── default
    ├── terraform_state.tar.gz
    └── uploads.tar.gz
```

The `db` directory is used to back up the GitLab PostgreSQL database using `pg_dump` to create [an SQL dump](https://www.postgresql.org/docs/14/backup-dump.html). The output of `pg_dump` is piped through `gzip` in order to create a compressed SQL file.

The `repositories` directory is used to back up Git repositories, as found in the GitLab database.

## Backup ID

Backup IDs identify individual backups. You need the backup ID of a backup archive if you need to restore GitLab and multiple backups are available.

Backups are saved in a directory set in `backup_path`, which is specified in the `config/gitlab.yml` file.

- By default, backups are stored in `/var/opt/gitlab/backups`.
- By default, backup directories are named after `backup_id`'s where `<backup-id>` identifies the time when the backup was created and the GitLab version.

For example, if the backup directory name is `1714053314_2024_04_25_17.0.0-pre`, the time of creation is represented by `1714053314_2024_04_25` and the GitLab version is 17.0.0-pre.

## Backup metadata file (`backup_information.json`)

> - Metadata version 2 was introduced in [GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149441).

`backup_information.json` is found in the backup directory, and it stores metadata about the backup. For example:

```json
{
  "metadata_version": 2,
  "backup_id": "1714053314_2024_04_25_17.0.0-pre",
  "created_at": "2024-04-25T13:55:14Z",
  "gitlab_version": "17.0.0-pre"
}
```

## Known issues

When working with `gitlab-backup-cli`, you might encounter the following issues.

### Architecture compatibility

If you use the `gitlab-backup-cli` tool on architectures other than the [1K architecture](../reference_architectures/1k_users.md), you might experience issues. This tool is supported only on 1K architecture and is recommended only for relevant environments.

### Backup strategy

Changes to existing files during backup might cause issues on the GitLab instance. This issue occurs because the tool's initial version does not use the [copy strategy](backup_gitlab.md#backup-strategy-option).

A workaround of this issue, is either to:

- Transition the GitLab instance into [Maintenance Mode](../maintenance_mode/index.md).
- Restrict traffic to the servers during backup to preserve instance resources.

We're investigating an alternative to the copy strategy, see [issue 428520](https://gitlab.com/gitlab-org/gitlab/-/issues/428520).
