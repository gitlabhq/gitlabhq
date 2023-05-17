---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Docker images **(FREE SELF)**

The GitLab Docker images are monolithic images of GitLab running all the
necessary services in a single container.

Find the GitLab official Docker image at:

- [GitLab Docker image in Docker Hub](https://hub.docker.com/r/gitlab/gitlab-ee/)

The Docker images don't include a mail transport agent (MTA). The recommended
solution is to add an MTA (such as Postfix or Sendmail) running in a separate
container. As another option, you can install an MTA directly in the GitLab
container, but this adds maintenance overhead as you'll likely need to reinstall
the MTA after every upgrade or restart.

In the following examples, if you want to use the latest RC image, use
`gitlab/gitlab-ee:rc` instead.

You should not deploy the GitLab Docker image in Kubernetes as it creates a
single point of failure. If you want to deploy GitLab in Kubernetes, the
[GitLab Helm Chart](https://docs.gitlab.com/charts/) or [GitLab Operator](https://docs.gitlab.com/operator/)
should be used instead.

WARNING:
Docker for Windows is not officially supported. There are known issues with volume
permissions, and potentially other unknown issues. If you are trying to run on Docker
for Windows, see the [getting help page](https://about.gitlab.com/get-help/) for links
to community resources (such as IRC or forums) to seek help from other users.

## Prerequisites

Docker is required. See the [official installation documentation](https://docs.docker.com/get-docker/).

## Set up the volumes location

Before setting everything else, configure a new environment variable `$GITLAB_HOME`
pointing to the directory where the configuration, logs, and data files will reside.
Ensure that the directory exists and appropriate permission have been granted.

For Linux users, set the path to `/srv/gitlab`:

```shell
export GITLAB_HOME=/srv/gitlab
```

For macOS users, use the user's `$HOME/gitlab` directory:

```shell
export GITLAB_HOME=$HOME/gitlab
```

The `GITLAB_HOME` environment variable should be appended to your shell's profile so it is
applied on all future terminal sessions:

- Bash: `~/.bash_profile`
- ZSH: `~/.zshrc`

The GitLab container uses host mounted volumes to store persistent data:

| Local location       | Container location | Usage                                       |
|----------------------|--------------------|---------------------------------------------|
| `$GITLAB_HOME/data`  | `/var/opt/gitlab`  | For storing application data.               |
| `$GITLAB_HOME/logs`  | `/var/log/gitlab`  | For storing logs.                           |
| `$GITLAB_HOME/config`| `/etc/gitlab`      | For storing the GitLab configuration files. |

## Installation

The GitLab Docker images can be run in multiple ways:

- [Using Docker Engine](#install-gitlab-using-docker-engine)
- [Using Docker Compose](#install-gitlab-using-docker-compose)
- [Using Docker swarm mode](#install-gitlab-using-docker-swarm-mode)

### Install GitLab using Docker Engine

You can fine tune these directories to meet your requirements.
Once you've set up the `GITLAB_HOME` variable, you can run the image:

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
  gitlab/gitlab-ee:latest
```

This will download and start a GitLab container and publish ports needed to
access SSH, HTTP and HTTPS. All GitLab data will be stored as subdirectories of
`$GITLAB_HOME`. The container will automatically `restart` after a system reboot.

If you are on SELinux, then run this instead:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab:Z \
  --volume $GITLAB_HOME/logs:/var/log/gitlab:Z \
  --volume $GITLAB_HOME/data:/var/opt/gitlab:Z \
  --shm-size 256m \
  gitlab/gitlab-ee:latest
```

This will ensure that the Docker process has enough permissions to create the
configuration files in the mounted volumes.

If you're using the [Kerberos integration](../integration/kerberos.md) **(PREMIUM ONLY)**,
you must also publish your Kerberos port (for example, `--publish 8443:8443`).
Failing to do so prevents Git operations with Kerberos.

The initialization process may take a long time. You can track this
process with:

```shell
sudo docker logs -f gitlab
```

After starting a container you can visit `gitlab.example.com` (or
`http://192.168.59.103` if you used boot2docker on macOS). It might take a while
before the Docker container starts to respond to queries.

Visit the GitLab URL, and sign in with the username `root`
and the password from the following command:

```shell
sudo docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

NOTE:
The password file will be automatically deleted in the first reconfigure run after 24 hours.

### Install GitLab using Docker Compose

With [Docker Compose](https://docs.docker.com/compose/) you can easily configure,
install, and upgrade your Docker-based GitLab installation:

1. [Install Docker Compose](https://docs.docker.com/compose/install/).
1. Create a `docker-compose.yml` file:

   ```yaml
   version: '3.6'
   services:
     web:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           external_url 'https://gitlab.example.com'
           # Add any other gitlab.rb configuration here, each on its own line
       ports:
         - '80:80'
         - '443:443'
         - '22:22'
       volumes:
         - '$GITLAB_HOME/config:/etc/gitlab'
         - '$GITLAB_HOME/logs:/var/log/gitlab'
         - '$GITLAB_HOME/data:/var/opt/gitlab'
       shm_size: '256m'
   ```

1. Make sure you are in the same directory as `docker-compose.yml` and start
   GitLab:

   ```shell
   docker compose up -d
   ```

NOTE:
Read the ["Pre-configure Docker container"](#pre-configure-docker-container) section
to see how the `GITLAB_OMNIBUS_CONFIG` variable works.

Below is another `docker-compose.yml` example with GitLab running on a custom
HTTP and SSH port. Notice how the `GITLAB_OMNIBUS_CONFIG` variables match the
`ports` section:

```yaml
version: '3.6'
services:
  web:
    image: 'gitlab/gitlab-ee:latest'
    restart: always
    hostname: 'gitlab.example.com'
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.example.com:8929'
        gitlab_rails['gitlab_shell_ssh_port'] = 2224
    ports:
      - '8929:8929'
      - '2224:22'
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data:/var/opt/gitlab'
    shm_size: '256m'
```

This is the same as using `--publish 8929:8929 --publish 2224:22`.

### Install GitLab using Docker swarm mode

With [Docker swarm mode](https://docs.docker.com/engine/swarm/), you can easily
configure and deploy your
Docker-based GitLab installation in a swarm cluster.

In swarm mode you can leverage [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
and [Docker configurations](https://docs.docker.com/engine/swarm/configs/) to efficiently and securely deploy your GitLab instance.
Secrets can be used to securely pass your initial root password without exposing it as an environment variable.
Configurations can help you to keep your GitLab image as generic as possible.

Here's an example that deploys GitLab with four runners as a [stack](https://docs.docker.com/get-started/swarm-deploy/#describe-apps-using-stack-files), using secrets and configurations:

1. [Set up a Docker swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/).
1. Create a `docker-compose.yml` file:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: gitlab/gitlab-ee:latest
       ports:
         - "22:22"
         - "80:80"
         - "443:443"
       volumes:
         - $GITLAB_HOME/data:/var/opt/gitlab
         - $GITLAB_HOME/logs:/var/log/gitlab
         - $GITLAB_HOME/config:/etc/gitlab
       shm_size: '256m'
       environment:
         GITLAB_OMNIBUS_CONFIG: "from_file('/omnibus_config.rb')"
       configs:
         - source: gitlab
           target: /omnibus_config.rb
       secrets:
         - gitlab_root_password
     gitlab-runner:
       image: gitlab/gitlab-runner:alpine
       deploy:
         mode: replicated
         replicas: 4
   configs:
     gitlab:
       file: ./gitlab.rb
   secrets:
     gitlab_root_password:
       file: ./root_password.txt
   ```

   For simplicity reasons, the `network` configuration was omitted.
   More information can be found in the official [Compose file reference](https://docs.docker.com/compose/compose-file/).

1. Create a `gitlab.rb` file:

   ```ruby
   external_url 'https://my.domain.com/'
   gitlab_rails['initial_root_password'] = File.read('/run/secrets/gitlab_root_password').gsub("\n", "")
   ```

1. Create a `root_password.txt` file:

   ```plaintext
   MySuperSecretAndSecurePassw0rd!
   ```

1. Make sure you are in the same directory as `docker-compose.yml` and run:

   ```shell
   docker stack deploy --compose-file docker-compose.yml mystack
   ```

### Install the product documentation

This is an optional step. See how to [self-host the product documentation](../administration/docs_self_host.md#self-host-the-product-documentation-with-docker).

## Configuration

This container uses the official Omnibus GitLab package, so all configuration
is done in the unique configuration file `/etc/gitlab/gitlab.rb`.

To access the GitLab configuration file, you can start a shell session in the
context of a running container. This will allow you to browse all directories
and use your favorite text editor:

```shell
sudo docker exec -it gitlab /bin/bash
```

You can also just edit `/etc/gitlab/gitlab.rb`:

```shell
sudo docker exec -it gitlab editor /etc/gitlab/gitlab.rb
```

Once you open `/etc/gitlab/gitlab.rb` make sure to set the `external_url` to
point to a valid URL.

To receive emails from GitLab you have to configure the
[SMTP settings](https://docs.gitlab.com/omnibus/settings/smtp.html) because the GitLab Docker image doesn't
have an SMTP server installed. You may also be interested in
[enabling HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/index.html).

After you make all the changes you want, you will need to restart the container to reconfigure GitLab:

```shell
sudo docker restart gitlab
```

GitLab will reconfigure itself whenever the container starts.
For more options about configuring GitLab, check the
[configuration documentation](https://docs.gitlab.com/omnibus/settings/configuration.html).

### Pre-configure Docker container

You can pre-configure the GitLab Docker image by adding the environment variable
`GITLAB_OMNIBUS_CONFIG` to Docker run command. This variable can contain any
`gitlab.rb` setting and is evaluated before the loading of the container's
`gitlab.rb` file. This behavior allows you to configure the external GitLab URL,
and make database configuration or any other option from the
[Omnibus GitLab template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).
The settings contained in `GITLAB_OMNIBUS_CONFIG` aren't written to the
`gitlab.rb` configuration file, and are evaluated on load.

Here's an example that sets the external URL and enables LFS while starting
the container:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://my.domain.com/'; gitlab_rails['lfs_enabled'] = true;" \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:latest
```

Every time you execute a `docker run` command, you need to provide
the `GITLAB_OMNIBUS_CONFIG` option. The content of `GITLAB_OMNIBUS_CONFIG` is
_not_ preserved between subsequent runs.

### Use tagged versions of GitLab

Tagged versions of the GitLab Docker images are also provided.
To see all available tags see:

- [GitLab CE tags](https://hub.docker.com/r/gitlab/gitlab-ce/tags/)
- [GitLab EE tags](https://hub.docker.com/r/gitlab/gitlab-ee/tags/)

To use a specific tagged version, replace `gitlab/gitlab-ee:latest` with
the GitLab version you want to run, for example `gitlab/gitlab-ee:12.1.3-ce.0`.

### Run GitLab on a public IP address

You can make Docker to use your IP address and forward all traffic to the
GitLab container by modifying the `--publish` flag.

To expose GitLab on IP `198.51.100.1`:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --publish 198.51.100.1:443:443 \
  --publish 198.51.100.1:80:80 \
  --publish 198.51.100.1:22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:latest
```

You can then access your GitLab instance at `http://198.51.100.1/` and `https://198.51.100.1/`.

### Expose GitLab on different ports

GitLab will occupy [some ports](../administration/package_information/defaults.md)
inside the container.

If you want to use a different host port than `80` (HTTP) or `443` (HTTPS),
you need to add a separate `--publish` directive to the `docker run` command.

For example, to expose the web interface on the host's port `8929`, and the SSH service on
port `2289`:

1. Use the following `docker run` command:

   ```shell
   sudo docker run --detach \
     --hostname gitlab.example.com \
     --publish 8929:8929 --publish 2289:22 \
     --name gitlab \
     --restart always \
     --volume $GITLAB_HOME/config:/etc/gitlab \
     --volume $GITLAB_HOME/logs:/var/log/gitlab \
     --volume $GITLAB_HOME/data:/var/opt/gitlab \
     --shm-size 256m \
     gitlab/gitlab-ee:latest
   ```

   NOTE:
   The format for publishing ports is `hostPort:containerPort`. Read more in the
   Docker documentation about
   [exposing incoming ports](https://docs.docker.com/engine/reference/run/#/expose-incoming-ports).

1. Enter the running container:

   ```shell
   sudo docker exec -it gitlab /bin/bash
   ```

1. Open `/etc/gitlab/gitlab.rb` with your editor and set `external_url`:

   ```ruby
   # For HTTP
   external_url "http://gitlab.example.com:8929"

   or

   # For HTTPS (notice the https)
   external_url "https://gitlab.example.com:8929"
   ```

   The port specified in this URL must match the port published to the host by Docker.
   Additionally, if the NGINX listen port is not explicitly set in
   `nginx['listen_port']`, it will be pulled from the `external_url`.
   For more information see the [NGINX documentation](https://docs.gitlab.com/omnibus/settings/nginx.html).

1. Set `gitlab_shell_ssh_port`:

   ```ruby
   gitlab_rails['gitlab_shell_ssh_port'] = 2289
   ```

1. Finally, reconfigure GitLab:

   ```shell
   gitlab-ctl reconfigure
   ```

Following the above example, you will be able to reach GitLab from your
web browser under `<hostIP>:8929` and push using SSH under the port `2289`.

A `docker-compose.yml` example that uses different ports can be found in the
[Docker compose](#install-gitlab-using-docker-compose) section.

### Configure multiple database connections

In [GitLab 16.0](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6850),
GitLab defaults to using two database connections that point to the same PostgreSQL database.

If, for any reason, you wish to switch back to single database connection:

1. Edit `/etc/gitlab/gitlab.rb` inside the container:

   ```shell
   sudo docker exec -it gitlab editor /etc/gitlab/gitlab.rb
   ```

1. Add the following line:

   ```ruby
   gitlab_rails['databases']['ci']['enable'] = false
   ```

1. Restart the container:

```shell
sudo docker restart gitlab
```

## Upgrade

In most cases, upgrading GitLab is as easy as downloading the newest Docker
[image tag](#use-tagged-versions-of-gitlab).

### Upgrade GitLab using Docker Engine

To upgrade GitLab that was [installed using Docker Engine](#install-gitlab-using-docker-engine):

1. Take a [backup](#back-up-gitlab). As a minimum, back up [the database](#create-a-database-backup) and
   the GitLab secrets file.

1. Stop the running container:

   ```shell
   sudo docker stop gitlab
   ```

1. Remove the existing container:

   ```shell
   sudo docker rm gitlab
   ```

1. Pull the new image. For example, the latest GitLab image:

   ```shell
   sudo docker pull gitlab/gitlab-ee:latest
   ```

1. Ensure that the `GITLAB_HOME` environment variable is [defined](#set-up-the-volumes-location):

   ```shell
   echo $GITLAB_HOME
   ```

1. Create the container once again with the
[previously specified](#install-gitlab-using-docker-engine) options:

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
   gitlab/gitlab-ee:latest
   ```

On the first run, GitLab will reconfigure and upgrade itself.

Refer to the GitLab [Upgrade recommendations](../policy/maintenance.md#upgrade-recommendations)
when upgrading between major versions.

### Upgrade GitLab using Docker compose

To upgrade GitLab that was [installed using Docker Compose](#install-gitlab-using-docker-compose):

1. Take a [backup](#back-up-gitlab). As a minimum, back up [the database](#create-a-database-backup) and
   the GitLab secrets file.

1. Download the newest release and upgrade your GitLab instance:

   ```shell
   docker compose pull
   docker compose up -d
   ```

   If you have used [tags](#use-tagged-versions-of-gitlab) instead, you'll need
   to first edit `docker-compose.yml`.

### Convert Community Edition to Enterprise Edition

You can convert an existing Docker-based GitLab Community Edition (CE) container
to a GitLab [Enterprise Edition](https://about.gitlab.com/pricing/) (EE) container
using the same approach as [upgrading the version](#upgrade).

We recommend you convert from the same version of CE to EE (for example, CE 14.1 to EE 14.1).
This is not explicitly necessary, and any standard upgrade (for example, CE 14.0 to EE 14.1) should work.
The following steps assume that you are upgrading the same version.

1. Take a [backup](#back-up-gitlab). As a minimum, back up [the database](#create-a-database-backup) and
   the GitLab secrets file.

1. Stop the current CE container, and remove or rename it.

1. To create a new container with GitLab EE,
   replace `ce` with `ee` in your `docker run` command or `docker-compose.yml` file.
   However, reuse the CE container name, port and file mappings, and version.

### Upgrade the product documentation

This is an optional step. If you [installed the documentation site](#install-the-product-documentation),
see how to [upgrade to another version](../administration/docs_self_host.md#upgrade-using-docker).

### Downgrade GitLab

To downgrade GitLab after an upgrade:

1. Follow the upgrade procedure, but [specify the tag for the original version of GitLab](#use-tagged-versions-of-gitlab)
   instead of `latest`.

1. Restore the [database backup you made](#create-a-database-backup) as part of the upgrade.

   - Restoring is required to back out database data and schema changes (migrations) made as part of the upgrade.
   - GitLab backups must be restored to the exact same version and edition.
   - [Follow the restore steps for Docker images](../raketasks/restore_gitlab.md#restore-for-docker-image-and-gitlab-helm-chart-installations), including
     stopping Puma and Sidekiq. Only the database must be restored, so add
     `SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state`
     to the `gitlab-backup restore` command line arguments.

## Back up GitLab

You can create a GitLab backup with:

```shell
docker exec -t <container name> gitlab-backup create
```

Read more on how to [back up and restore GitLab](../raketasks/backup_restore.md).

NOTE:
If configuration is provided entirely via the `GITLAB_OMNIBUS_CONFIG` environment variable
(per the ["Pre-configure Docker Container"](#pre-configure-docker-container) steps),
meaning no configuration is set directly in the `gitlab.rb` file, then there is no need
to back up the `gitlab.rb` file.

WARNING:
[Backing up the GitLab secrets file](../raketasks/backup_gitlab.md#storing-configuration-files) is required
to avoid [complicated steps](../raketasks/backup_restore.md#when-the-secrets-file-is-lost) when recovering
GitLab from backup. The secrets file is stored at `/etc/gitlab/gitlab-secrets.json` inside the container, or
`$GITLAB_HOME/config/gitlab-secrets.json` [on the container host](#set-up-the-volumes-location).

### Create a database backup

A database backup is required to roll back GitLab upgrade if you encounter issues.

```shell
docker exec -t <container name> gitlab-backup create SKIP=artifacts,repositories,registry,uploads,builds,pages,lfs,packages,terraform_state
```

The backup is written to `/var/opt/gitlab/backups` which should be on a
[volume mounted by Docker](#set-up-the-volumes-location).

## Installing GitLab Community Edition

[GitLab CE Docker image](https://hub.docker.com/r/gitlab/gitlab-ce/)

To install the Community Edition, replace `ee` with `ce` in the commands on this
page.

## Troubleshooting

The following information will help if you encounter problems using Omnibus GitLab and Docker.

### Diagnose potential problems

Read container logs:

```shell
sudo docker logs gitlab
```

Enter running container:

```shell
sudo docker exec -it gitlab /bin/bash
```

From within the container you can administer the GitLab container as you would
usually administer an
[Omnibus installation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md)

### 500 Internal Error

When updating the Docker image you may encounter an issue where all paths
display a `500` page. If this occurs, restart the container to try to rectify the
issue:

```shell
sudo docker restart gitlab
```

### Permission problems

When updating from older GitLab Docker images you might encounter permission
problems. This happens when users in previous images were not
preserved correctly. There's script that fixes permissions for all files.

To fix your container, execute `update-permissions` and restart the
container afterwards:

```shell
sudo docker exec gitlab update-permissions
sudo docker restart gitlab
```

### Windows/Mac: `Error executing action run on resource ruby_block[directory resource: /data/GitLab]`

This error occurs when using Docker Toolbox with VirtualBox on Windows or Mac,
and making use of Docker volumes. The `/c/Users` volume is mounted as a
VirtualBox Shared Folder, and does not support the all POSIX file system features.
The directory ownership and permissions cannot be changed without remounting, and
GitLab fails.

Our recommendation is to switch to using the native Docker install for your
platform, instead of using Docker Toolbox.

If you cannot use the native Docker install (Windows 10 Home Edition, or Windows 7/8),
then an alternative solution is to setup NFS mounts instead of VirtualBox shares for
Docker Toolbox's boot2docker.

### Linux ACL issues

If you are using file ACLs on the Docker host, the `docker` group requires full access to the volumes in order for GitLab to work:

```shell
getfacl $GITLAB_HOME

# file: $GITLAB_HOME
# owner: XXXX
# group: XXXX
user::rwx
group::rwx
group:docker:rwx
mask::rwx
default:user::rwx
default:group::rwx
default:group:docker:rwx
default:mask::rwx
default:other::r-x
```

If these are not correct, set them with:

```shell
sudo setfacl -mR default:group:docker:rwx $GITLAB_HOME
```

The default group is `docker`. If you changed the group, be sure to update your
commands.

### `/dev/shm` mount not having enough space in Docker container

GitLab comes with a Prometheus metrics endpoint at `/-/metrics` to expose a
variety of statistics on the health and performance of GitLab. The files
required for this gets written to a temporary file system (like `/run` or
`/dev/shm`).

By default, Docker allocates 64 MB to the shared memory directory (mounted at
`/dev/shm`). This is insufficient to hold all the Prometheus metrics related
files generated, and will generate error logs like the following:

```plaintext
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
```

Other than disabling the Prometheus Metrics from the Admin Area, the recommended
solution to fix this problem is to increase the size of shared memory to at least 256 MB.
If using `docker run`, this can be done by passing the flag `--shm-size 256m`.
If using a `docker-compose.yml` file, the `shm_size` key can be used for this
purpose.

### Docker containers exhausts space due to the `json-file`

Docker uses the [`json-file` default logging driver](https://docs.docker.com/config/containers/logging/configure/#configure-the-default-logging-driver), which performs no log rotation by default. As a result of this lack of rotation, log files stored by the `json-file` driver can consume a significant amount of disk space for containers that generate a lot of output. This can lead to disk space exhaustion. To address this, use [`journald`](https://docs.docker.com/config/containers/logging/journald/) as the logging driver when available, or [another supported driver](https://docs.docker.com/config/containers/logging/configure/#supported-logging-drivers) with native rotation support.

### Buffer overflow error when starting Docker

If you receive this buffer overflow error, you should purge old log files in
`/var/log/gitlab`:

```plaintext
buffer overflow detected : terminated
xargs: tail: terminated by signal 6
```

Removing old log files helps fix the error, and ensures a clean startup of the instance.
