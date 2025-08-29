---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrade Docker instances
description: Upgrade a Docker-based instance.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Upgrade a Docker-based instance to a later version of GitLab.

Before you upgrade, consult [information you need before you upgrade](../plan_your_upgrade.md).

## Upgrade GitLab by using Docker Engine

To upgrade a GitLab instance that was
[installed by using Docker Engine](../../install/docker/installation.md#install-gitlab-by-using-docker-engine):

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

## Upgrade GitLab by using Docker Compose

To upgrade a GitLab instance that was
[installed by using Docker Compose](../../install/docker/installation.md#install-gitlab-by-using-docker-compose):

1. Create a [backup](../../install/docker/backup.md). As a minimum, back up
   [the database](../../install/docker/backup.md#create-a-database-backup) and the GitLab secrets file.
1. Edit `docker-compose.yml` and change the version to pull.
1. Download the newest release and upgrade your GitLab instance:

   ```shell
   docker compose pull
   docker compose up -d
   ```
