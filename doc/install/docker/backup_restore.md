---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Back up GitLab running in a Docker container

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

You can create a GitLab backup with:

```shell
docker exec -t <container name> gitlab-backup create
```

Read more on how to [back up and restore GitLab](../../administration/backup_restore/index.md).

NOTE:
If configuration is provided entirely via the `GITLAB_OMNIBUS_CONFIG` environment variable
(per the ["Pre-configure Docker Container"](configuration.md#pre-configure-docker-container) steps),
meaning no configuration is set directly in the `gitlab.rb` file, then there is no need
to back up the `gitlab.rb` file.

WARNING:
[Backing up the GitLab secrets file](../../administration/backup_restore/backup_gitlab.md#storing-configuration-files) is required
to avoid [complicated steps](../../administration/backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost) when recovering
GitLab from backup. The secrets file is stored at `/etc/gitlab/gitlab-secrets.json` inside the container, or
`$GITLAB_HOME/config/gitlab-secrets.json` [on the container host](installation.md#set-up-the-volumes-location).

## Create a database backup

A database backup is required to roll back a GitLab upgrade if you encounter issues.

```shell
docker exec -t <container name> gitlab-backup create SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state
```

The backup is written to `/var/opt/gitlab/backups` which should be on a
[volume mounted by Docker](installation.md#set-up-the-volumes-location).
