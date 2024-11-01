---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
ignore_in_report: true
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

### Backing up object storage

Only Google cloud is supported. See [epic 11577](https://gitlab.com/groups/gitlab-org/-/epics/11577) for the plan to add more vendors.

#### GCP

`gitlab-backup-cli` creates and runs jobs with [Google Transfer Service](https://cloud.google.com/storage-transfer-service/) to copy GitLab data to a separate backup bucket.

Prerequisites:

- Follow [Google's documentation](https://cloud.google.com/docs/authentication) for authentication.
- This document assumes you are setting up and using a dedicated Google Cloud service account for managing backups.
- If no other credentials are provided, and you are running inside Google Cloud, then the tool attempts to use the access of the infrastructure it is running on. It is recommended to run with separate credentials, and restrict access to the created backups from the application.

To create a backup:

1. [Create a role](https://cloud.google.com/iam/docs/creating-custom-roles):
   1. Create a file `role.yaml` with the following definition:

   ```yaml
   ---
   description: Role for backing up GitLab object storage
   includedPermissions:
      - storagetransfer.jobs.create
      - storagetransfer.jobs.get
      - storagetransfer.jobs.run
      - storagetransfer.jobs.update
      - storagetransfer.operations.get
      - storagetransfer.projects.getServiceAccount
   stage: GA
   title: GitLab Backup Role
   ```

   1. Apply the role:

      ```shell
      gcloud iam roles create --project=<YOUR_PROJECT_ID> <ROLE_NAME> --file=role.yaml
      ```

1. Create a service account for backups, and add it to the role:

   ```shell
   gcloud iam service-accounts create "gitlab-backup-cli" --display-name="GitLab Backup Service Account"
   # Get the service account email from the output of the following
   gcloud iam service-accounts list
   # Add the account to the role created previously
   gcloud projects add-iam-policy-binding <YOUR_PROJECT_ID> --member="serviceAccount:<SERVICE_ACCOUNT_EMAIL>" --role="roles/<ROLE_NAME>"
   ```

1. Follow [Google's documentation](https://cloud.google.com/docs/authentication) for authentication with the service account. In general, the credentials can be saved to a file, or stored in a predefined environment variable.
1. Create a destination bucket to backup to in [Google Cloud Storage](https://cloud.google.com/storage/). The options here are highly dependent on your requirements.
1. Run the backup:

   ```shell
   sudo gitlab-backup-cli backup all --backup-bucket=<BUCKET_NAME>
   ```

   If you want to backup the container registry bucket, add the option `--registry-bucket=<REGISTRY_BUCKET_NAME>`.
1. The backup creates a backup under `backups/<BACKUP_ID>/<BUCKET>` for each of the object storage types in the bucket.

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

## Restore a backup

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/469247) in GitLab 17.6.

Prerequisites:

- You have the backup ID of a backup created using `gitlab-backup-cli`.

To restore a backup of the current GitLab installation:

- Run the following command:

  ```shell
  sudo gitlab-backup-cli restore all <backup_id>
  ```

### Restore object storage data

You can restore data from Google Cloud Storage. [Epic 11577](https://gitlab.com/groups/gitlab-org/-/epics/11577) proposes to add support for other vendors.

Prerequisites:

- You have the backup ID of a backup created using `gitlab-backup-cli`.
- You configured the required permissions for the restore location.
- You set up the object storage configuration `gitlab.rb` or `gitlab.yml` file, and matches the backup environment.
- You tested the restore process in a staging environment.

To restore object storage data:

- Run the following command:

  ```shell
  sudo gitlab-backup restore <backup_id>
  ```

The restore process:

- Does not clear the destination bucket first.
- Overwrites existing files with the same filenames in the destination bucket.
- Might take a significant amount of time, depending on how much data is restored.

Always monitor your system resources during a restore. Keep your original files
until you verify the restoration was successful.

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

## What data is backed up?

1. Git Repository Data
1. Databases
1. Blobs

## What data is NOT backed up?

1. Secrets and Configurations

   - Follow the documentation on how to [backup secrets and configuration](backup_gitlab.md#storing-configuration-files).

1. Transient and Cache Data

   - Redis: Cache
   - Redis: Sidekiq Data
   - Logs
   - Elasticsearch
   - Observability Data / Prometheus Metrics
