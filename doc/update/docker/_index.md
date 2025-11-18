---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrade Docker instances
description: Upgrade a single-node Docker-based instance.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Upgrade a Docker-based instance to a later version of GitLab.

## Prerequisites

Before you upgrade a Docker instance, you must first
[read required information and perform required steps](../plan_your_upgrade.md).

## Upgrade a Docker-based instance

To upgrade a Docker-based instance:

1. Consider [turning on maintenance mode](../../administration/maintenance_mode/_index.md) during the upgrade.
1. Pause [running CI/CD pipelines and jobs](../plan_your_upgrade.md#pause-cicd-pipelines-and-jobs).
1. [Upgrade GitLab Runner](https://docs.gitlab.com/runner/install/) to the same version as your target GitLab version.
1. Upgrade GitLab itself by either:
   - [Using Docker Engine](#upgrade-with-docker-engine).
   - [Using Docker Compose](#upgrade-with-docker-compose).

After you upgrade:

1. Unpause [running CI/CD pipelines and jobs](../plan_your_upgrade.md#pause-cicd-pipelines-and-jobs).
1. If enabled, [turn off maintenance mode](../../administration/maintenance_mode/_index.md#disable-maintenance-mode).
1. Run [upgrade health checks](../plan_your_upgrade.md#run-upgrade-health-checks).

### Upgrade with Docker Engine

To upgrade a GitLab instance that was
[installed with Docker Engine](../../install/docker/installation.md#install-gitlab-by-using-docker-engine):

1. Create a [backup](../../install/docker/backup.md). As a minimum, back up
   [the database](../../install/docker/backup.md#create-a-database-backup) and the GitLab secrets file.

1. Stop the running container:

   ```shell
   sudo docker stop gitlab
   ```

1. Remove the existing container:

   ```shell
   sudo docker rm gitlab
   ```

1. Pull the new image:

   {{< tabs >}}

   {{< tab title="GitLab Enterprise Edition" >}}

   ```shell
   sudo docker pull gitlab/gitlab-ee:<version>-ee.0
   ```

   {{< /tab >}}

   {{< tab title="GitLab Community Edition" >}}

   ```shell
   sudo docker pull gitlab/gitlab-ce:<version>-ce.0
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Ensure that the `GITLAB_HOME` environment variable is [defined](../../install/docker/installation.md#create-a-directory-for-the-volumes):

   ```shell
   echo $GITLAB_HOME
   ```

1. Create the container again with the
   [previously specified](../../install/docker/installation.md#install-gitlab-by-using-docker-engine) options:

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

### Upgrade with Docker Compose

To upgrade a GitLab instance that was
[installed with Docker Compose](../../install/docker/installation.md#install-gitlab-by-using-docker-compose):

1. Create a [backup](../../install/docker/backup.md). As a minimum, back up
   [the database](../../install/docker/backup.md#create-a-database-backup) and the GitLab secrets file.
1. Edit `docker-compose.yml` and change the version to pull.
1. Download the newest release and upgrade your GitLab instance:

   ```shell
   docker compose pull
   docker compose up -d
   ```
