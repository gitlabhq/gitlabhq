---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Back up GitLab running in a Docker container
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can create a GitLab backup with:

```shell
docker exec -t <container name> gitlab-backup create
```

For more information, see [Back up and restore GitLab](../../administration/backup_restore/_index.md).

NOTE:
If your GitLab configuration is provided entirely using the `GITLAB_OMNIBUS_CONFIG` environment variable
(by using the ["Pre-configure Docker Container"](configuration.md#pre-configure-docker-container) steps),
the configuration settings are not stored in the `gitlab.rb` file so you do not need
to back up the `gitlab.rb` file.

WARNING:
To avoid [complicated steps](../../administration/backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost) when recovering
GitLab from a backup, you should also follow the instructions in
[Backing up the GitLab secrets file](../../administration/backup_restore/backup_gitlab.md#storing-configuration-files).
The secrets file is stored either in the `/etc/gitlab/gitlab-secrets.json` file inside the container or in the
`$GITLAB_HOME/config/gitlab-secrets.json` file [on the container host](installation.md#create-a-directory-for-the-volumes).

## Create a database backup

Before you upgrade GitLab, create a database-only backup. If you encounter issues during the GitLab upgrade, you can restore the database backup to roll back the upgrade. To create a database backup, run this command:

```shell
docker exec -t <container name> gitlab-backup create SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state
```

The backup is written to `/var/opt/gitlab/backups` which should be on a
[volume mounted by Docker](installation.md#create-a-directory-for-the-volumes).

For more information on using the backup to roll back an upgrade, see [Downgrade GitLab](upgrade.md#downgrade-gitlab).
