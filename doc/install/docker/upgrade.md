---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrade
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

In most cases, upgrading GitLab is as easy as downloading the newest Docker
image tag.

## Upgrade GitLab using Docker Engine

To upgrade a GitLab instance that was [installed using Docker Engine](installation.md#install-gitlab-by-using-docker-engine):

1. Create a [backup](backup.md). As a minimum, back up [the database](backup.md#create-a-database-backup) and
   the GitLab secrets file.

1. Stop the running container:

   ```shell
   sudo docker stop gitlab
   ```

1. Remove the existing container:

   ```shell
   sudo docker rm gitlab
   ```

1. Pull the new image:

   ```shell
   sudo docker pull gitlab/gitlab-ee:<version>-ee.0
   ```

1. Ensure that the `GITLAB_HOME` environment variable is [defined](installation.md#create-a-directory-for-the-volumes):

   ```shell
   echo $GITLAB_HOME
   ```

1. Create the container again with the
   [previously specified](installation.md#install-gitlab-by-using-docker-engine) options:

   ```shell
   sudo docker run --detach \
   --hostname gitlab.example.com \
   --publish 443:443 --publish 80:80 --publish 22:22 \
   --name gitlab \
   --restart always \
   --volume $GITLAB_HOME/config:/etc/gitlab \
   --volume $GITLAB_HOME/logs:/var/log/gitlab \
   --volume $GITLAB_HOME/data:/var/opt/gitlab \
   --shm-size 256m \
   gitlab/gitlab-ee:<version>-ee.0
   ```

On the first run, GitLab reconfigures and upgrades itself.

Refer to the GitLab [Upgrade recommendations](../../policy/maintenance.md#upgrade-recommendations)
when upgrading to different versions.

## Upgrade GitLab using Docker compose

To upgrade a GitLab instance that was [installed using Docker Compose](installation.md#install-gitlab-by-using-docker-compose):

1. Take a [backup](backup.md). As a minimum, back up [the database](backup.md#create-a-database-backup) and
   the GitLab secrets file.
1. Edit `docker-compose.yml` and change the version to pull.
1. Download the newest release and upgrade your GitLab instance:

   ```shell
   docker compose pull
   docker compose up -d
   ```

## Convert Community Edition to Enterprise Edition

You can convert an existing GitLab Community Edition (CE) container for Docker
to a GitLab [Enterprise Edition](https://about.gitlab.com/pricing/) (EE) container
using the same approach as [upgrading the version](upgrade.md).

We recommend you convert from the same version of CE to EE (for example, CE 14.1 to EE 14.1).
However, this is not required. Any standard upgrade (for example, CE 14.0 to EE 14.1) should work.
The following steps assume that you are converting to the same version.

1. Take a [backup](backup.md). At minimum, back up [the database](backup.md#create-a-database-backup) and
   the GitLab secrets file.

1. Stop the current CE container, and remove or rename it.

1. To create a new container with GitLab EE,
   replace `ce` with `ee` in your `docker run` command or `docker-compose.yml` file.
   Reuse the CE container name, port mappings, file mappings, and version.

## Downgrade GitLab

The restore overwrites all newer GitLab database content with the older state.
A downgrade is only recommended where necessary. For example, if post-upgrade tests reveal problems that cannot be resolved quickly.

WARNING:
You must have at least a database backup created with the exact same version and edition you are downgrading to.
The backup is required to revert the schema changes (migrations) made during the upgrade.

To downgrade GitLab shortly after an upgrade:

1. Follow the upgrade procedure, by [specifying an earlier version](installation.md#find-the-gitlab-version-and-edition-to-use)
   than you have installed.

1. Restore the [database backup you made](backup.md#create-a-database-backup) before the upgrade.

   - [Follow the restore steps for Docker images](../../administration/backup_restore/restore_gitlab.md#restore-for-docker-image-and-gitlab-helm-chart-installations), including
     stopping Puma and Sidekiq. Only the database must be restored, so add
     `SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state`
     to the `gitlab-backup restore` command line arguments.
