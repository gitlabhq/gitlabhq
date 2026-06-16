---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrate a Linux package GitLab instance to Docker
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Migrate your existing Linux package GitLab instance to Docker using one of two approaches:

- **Reuse existing data directories**: move the existing data directories into the Docker volume
  paths. Use this approach to keep your data in place without a full backup and restore cycle.
- **Back up and restore**: create a GitLab backup on the Linux package instance, set up a
  fresh Docker instance, and restore into it. Use this approach for a clean migration that
  supports rollback if needed.

## Prerequisites

- The versions of GitLab on the Linux package instance and the Docker image must match. If required,
  upgrade your Linux package instance before migrating to Docker.
- [Docker installed](installation.md) on the target server.

## Reuse existing data directories

Migrate a Linux package GitLab instance to Docker by reusing existing data directories.

### Stop the Linux package instance

Stop all GitLab services:

```shell
sudo gitlab-ctl stop
```

### Prepare the volume directories

How you prepare the volume directories depends on where Docker runs:

- If Docker runs on the same server as the Linux package instance, you can mount
  the existing directories directly without copying them. Set the volume paths in your
  Docker Compose file to the Linux package locations:

  ```yaml
  volumes:
    - '/etc/gitlab:/etc/gitlab'
    - '/var/log/gitlab:/var/log/gitlab'
    - '/var/opt/gitlab:/var/opt/gitlab'
  ```

- If you are moving to a different server, or want to keep the Docker volumes separate
  from the Linux package paths, copy the directories to a new location first.

  1. Set `$GITLAB_HOME` to the target directory:

     ```shell
     export GITLAB_HOME=/srv/gitlab
     sudo mkdir -p $GITLAB_HOME
     ```

  1. Copy (or move) the data, logs, and configuration directories:

     ```shell
     sudo cp -a /var/opt/gitlab $GITLAB_HOME/data
     sudo cp -a /var/log/gitlab $GITLAB_HOME/logs
     sudo cp -a /etc/gitlab     $GITLAB_HOME/config
     ```

     To move instead of copy, use `mv` instead of `cp -a`.

> [!warning]
> Do not change the ownership of the host directories to `root:root` before starting
> the container. Doing so prevents the container from starting, and prevents the
> `update-permissions` script from correcting ownership afterwards.

Verify that the repository directory exists and is a real directory, not a broken symlink:

```shell
ls -la $GITLAB_HOME/data/git-data/repositories
```

If the directory is missing or a broken symlink, create it:

```shell
sudo mkdir -p $GITLAB_HOME/data/git-data/repositories
```

### Align user and group identifiers

The GitLab Docker image includes a built-in script called `update-permissions` that sets
correct ownership on all GitLab directories. If the Linux package instance used different
UIDs than the Docker image expects (either OS defaults that vary by distribution, or
[explicitly configured values](https://docs.gitlab.com/omnibus/settings/configuration/#specify-numeric-user-and-group-identifiers)),
run `update-permissions` from a temporary container with your volumes mounted before
starting the container. This corrects ownership before the first start:

```shell
docker run --rm \
  -v <config_path>:/etc/gitlab \
  -v <logs_path>:/var/log/gitlab \
  -v <data_path>:/var/opt/gitlab \
  --entrypoint /bin/bash \
  gitlab/gitlab-ee:<version> \
  -c "update-permissions"
```

Replace `<config_path>`, `<logs_path>`, and `<data_path>` with the host paths you
identified in [Prepare the volume directories](#prepare-the-volume-directories).

### Start GitLab in Docker

Follow the [installation instructions](installation.md) to create a Docker Compose file or
Docker Engine command that mounts the directories you prepared:

```yaml
volumes:
  - '$GITLAB_HOME/config:/etc/gitlab'
  - '$GITLAB_HOME/logs:/var/log/gitlab'
  - '$GITLAB_HOME/data:/var/opt/gitlab'
```

After the container starts, run reconfigure:

```shell
docker exec -it <container_name> gitlab-ctl reconfigure
```

Verify the installation:

```shell
docker exec -it <container_name> gitlab-rake gitlab:check
```

## Back up the Linux package instance and restore to the Docker instance

### Create a backup on the Linux package instance

Before you stop your Linux package instance, create a backup:

```shell
sudo gitlab-backup create
```

Copy your secrets file to a safe location:

```shell
sudo cp /etc/gitlab/gitlab-secrets.json /your/backup/location/
```

For more information, see [Back up GitLab](../../administration/backup_restore/backup_gitlab.md).

### Stop the Linux package instance

Stop all GitLab services:

```shell
sudo gitlab-ctl stop
```

### Set up the Docker instance

Follow the [installation instructions](installation.md) to set up a new Docker instance.
Set `$GITLAB_HOME` to the directory you create for the volumes, for example:

```shell
export GITLAB_HOME=/srv/gitlab
```

Start the container once to initialize the volume directories, then stop it before restoring:

```shell
docker compose up -d
docker compose stop
```

### Restore the backup

1. Copy the backup archive into the Docker data volume:

   ```shell
   sudo cp <timestamp>_gitlab_backup.tar $GITLAB_HOME/data/backups/
   ```

1. Copy the secrets file into the Docker config volume:

   ```shell
   sudo cp gitlab-secrets.json $GITLAB_HOME/config/gitlab-secrets.json
   ```

1. Start the container and run the restore:

   ```shell
   docker compose start
   docker exec -it <container_name> gitlab-backup restore BACKUP=<timestamp>
   ```

1. Reconfigure and restart after the restore completes:

   ```shell
   docker exec -it <container_name> gitlab-ctl reconfigure
   docker exec -it <container_name> gitlab-ctl restart
   ```

1. Verify the installation:

   ```shell
   docker exec -it <container_name> gitlab-rake gitlab:check
   ```

## Troubleshooting

When migrating a Linux package GitLab instance to Docker, you might encounter the following issues.

### Permission errors after starting

If the container starts but reports permission errors, run:

```shell
sudo docker exec <container_name> update-permissions
sudo docker restart <container_name>
```

This occurs when the Linux package instance used different UIDs for system accounts than the
Docker image expects. To prevent this, run `update-permissions` before starting as described in
[Align user and group identifiers](#align-user-and-group-identifiers).

### Errors when reusing data from another instance

When reusing data from another instance, you might encounter the following issues.

#### `stat: missing operand` error on startup

This error occurs when the container cannot find the `git-data/repositories` directory:

```plaintext
stat: missing operand
Expected process to exit with [0], but received '1'
Ran stat --printf='%U' $(readlink -f /var/opt/gitlab/git-data/repositories) returned 1
```

On the host, create the missing directory, then restart the container:

```shell
sudo mkdir -p $GITLAB_HOME/data/git-data/repositories
sudo docker restart <container_name>
```

#### Container exits immediately and restart loop blocks `docker exec`

If the container exits immediately after starting, you cannot use `docker exec` to
investigate or run `update-permissions`. Instead, run `update-permissions` directly
using the same command from
[Align user and group identifiers](#align-user-and-group-identifiers), which starts a
temporary container with your volumes mounted and corrects ownership without needing the
main container to be running.
