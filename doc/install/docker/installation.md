---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Install GitLab in a Docker container
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

To install GitLab in a Docker container, use Docker Compose, Docker Engine, or Docker Swarm mode.

Prerequisites:

- You must have a working [Docker installation](https://docs.docker.com/engine/install/#server) that is not Docker for Windows.
Docker for Windows is not officially supported as the images have known compatibility issues with volume
permissions and potentially other unknown issues. If you are trying to run on Docker
for Windows, see the [getting help page](https://about.gitlab.com/get-help/). This page
contains links to community resources (like IRC or forums) where you can seek help
from other users.
- You must have a mail transport agent (MTA), such as Postfix or Sendmail. The GitLab images don't include an MTA. You can
install an MTA in a separate container. While you can install an MTA in the same container as GitLab, you might need to
reinstall the MTA after every upgrade or restart.
- You should not plan to deploy the GitLab Docker image in Kubernetes as it creates a
single point of failure. If you want to deploy GitLab in Kubernetes, use the
[GitLab Helm Chart](https://docs.gitlab.com/charts/) or [GitLab Operator](https://docs.gitlab.com/operator/)
instead.
- You must have a valid, externally accessible hostname for your Docker installation. Do not use `localhost`.

## Configure the SSH port

By default, GitLab uses port `22` to interact with Git over SSH.
To use port `22`, skip this section.

To use a different port, you can either:

- Change the server's SSH port now (recommended). Then the SSH clone URLs don't need the new port number:

  ```plaintext
  ssh://git@gitlab.example.com/user/project.git
  ```

- [Change the GitLab Shell SSH port](configuration.md#expose-gitlab-on-different-ports) after installation. Then the SSH clone URLs include the configured port number:

  ```plaintext
  ssh://git@gitlab.example.com:<portNumber>/user/project.git
  ```

To change the server's SSH port:

1. Open `/etc/ssh/sshd_config` with your editor, and change the SSH port:

   ```conf
   Port = 2424
   ```

1. Save the file and restart the SSH service:

   ```shell
   sudo systemctl restart ssh
   ```

1. Verify that you can connect over SSH. Open a new terminal session and SSH to the server using
   the new port.

## Create a directory for the volumes

Create a directory for the configuration files, logs,
and data files. The directory can be in your user's home directory (for example
`~/gitlab-docker`), or in a directory like `/srv/gitlab`.

1. Create the directory:

   ```shell
   sudo mkdir -p /srv/gitlab
   ```

1. If you're running Docker with a user other than `root`, grant the appropriate
   permissions to the user for the new directory.

1. Configure a new environment variable `$GITLAB_HOME` that sets the path to the
   directory you created:

   ```shell
   export GITLAB_HOME=/srv/gitlab
   ```

1. Optionally, you can append the `GITLAB_HOME` environment variable to your shell's
   profile so it is applied on all future terminal sessions:

   - Bash: `~/.bash_profile`
   - ZSH: `~/.zshrc`

The GitLab container uses host-mounted volumes to store persistent data:

| Local location       | Container location | Usage                                       |
|----------------------|--------------------|---------------------------------------------|
| `$GITLAB_HOME/data`  | `/var/opt/gitlab`  | Stores application data.                    |
| `$GITLAB_HOME/logs`  | `/var/log/gitlab`  | Stores logs.                                |
| `$GITLAB_HOME/config`| `/etc/gitlab`      | Stores the GitLab configuration files.      |

## Find the GitLab version and edition to use

In a production environment, you should pin your deployment to a specific
GitLab version. Review the available versions and choose the version you want to use in the
Docker tags page:

- [GitLab Enterprise Edition tags](https://hub.docker.com/r/gitlab/gitlab-ee/tags/)
- [GitLab Community Edition tags](https://hub.docker.com/r/gitlab/gitlab-ce/tags/)

The tag name consists of the following:

```plaintext
gitlab/gitlab-ee:<version>-ee.0
```

Where `<version>` is the GitLab version, for example `16.5.3`. The version always includes
`<major>.<minor>.<patch>` in its name.

For testing purposes, you can use the `latest` tag, such as `gitlab/gitlab-ee:latest`,
which points to the latest stable release.

The following examples use a stable Enterprise Edition version.
If you want to use the Release Candidate (RC) or nightly image, use
`gitlab/gitlab-ee:rc` or `gitlab/gitlab-ee:nightly` instead.

To install the Community Edition, replace `ee` with `ce`.

## Installation

You can run the GitLab Docker images by using:

- [Docker Compose](#install-gitlab-by-using-docker-compose) (recommended)
- [Docker Engine](#install-gitlab-by-using-docker-engine)
- [Docker Swarm mode](#install-gitlab-by-using-docker-swarm-mode)

### Install GitLab by using Docker Compose

With [Docker Compose](https://docs.docker.com/compose/) you can configure,
install, and upgrade your Docker-based GitLab installation:

1. [Install Docker Compose](https://docs.docker.com/compose/install/linux/).
1. Create a `docker-compose.yml` file. For example:

   ```yaml
   version: '3.6'
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           # Add any other gitlab.rb configuration here, each on its own line
           external_url 'https://gitlab.example.com'
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

   NOTE:
   Read the [Pre-configure Docker container](configuration.md#pre-configure-docker-container) section
   to see how the `GITLAB_OMNIBUS_CONFIG` variable works.

   Here is another `docker-compose.yml` example with GitLab running on a custom
   HTTP and SSH port. Notice that the `GITLAB_OMNIBUS_CONFIG` variables match the
   `ports` section:

   ```yaml
   version: '3.6'
   services:
     gitlab:
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           external_url 'http://gitlab.example.com:8929'
           gitlab_rails['gitlab_shell_ssh_port'] = 2424
       ports:
         - '8929:8929'
         - '443:443'
         - '2424:22'
       volumes:
         - '$GITLAB_HOME/config:/etc/gitlab'
         - '$GITLAB_HOME/logs:/var/log/gitlab'
         - '$GITLAB_HOME/data:/var/opt/gitlab'
       shm_size: '256m'
   ```

   This configuration is the same as using `--publish 8929:8929 --publish 2424:22`.

1. In the same directory as `docker-compose.yml`, start GitLab:

   ```shell
   docker compose up -d
   ```

### Install GitLab by using Docker Engine

Alternatively, you can install GitLab using Docker Engine.

1. If you've set up the `GITLAB_HOME` variable, adjust the directories to meet your requirements
and run the image:

   - If you are not on SELinux, run this command:

      ```shell
      sudo docker run --detach \
        --hostname gitlab.example.com \
        --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
        --publish 443:443 --publish 80:80 --publish 22:22 \
        --name gitlab \
        --restart always \
        --volume $GITLAB_HOME/config:/etc/gitlab \
        --volume $GITLAB_HOME/logs:/var/log/gitlab \
        --volume $GITLAB_HOME/data:/var/opt/gitlab \
        --shm-size 256m \
        gitlab/gitlab-ee:<version>-ee.0
      ```

      This command downloads and starts a GitLab container, and
      [publishes ports](https://docs.docker.com/network/#published-ports) needed to
      access SSH, HTTP and HTTPS. All GitLab data are stored as subdirectories of
      `$GITLAB_HOME`. The container automatically restarts after a system reboot.

   - If you are on SELinux, then run this instead:

     ```shell
      sudo docker run --detach \
        --hostname gitlab.example.com \
        --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
        --publish 443:443 --publish 80:80 --publish 22:22 \
        --name gitlab \
        --restart always \
        --volume $GITLAB_HOME/config:/etc/gitlab:Z \
        --volume $GITLAB_HOME/logs:/var/log/gitlab:Z \
        --volume $GITLAB_HOME/data:/var/opt/gitlab:Z \
        --shm-size 256m \
        gitlab/gitlab-ee:<version>-ee.0
      ```

      This command ensures that the Docker process has enough permissions to create the configuration
      files in the mounted volumes.

1. If you're using the [Kerberos integration](../../integration/kerberos.md),
you must also publish your Kerberos port (for example, `--publish 8443:8443`).
Failing to do so prevents Git operations with Kerberos.
The initialization process may take a long time. You can track this
process with:

   ```shell
   sudo docker logs -f gitlab
   ```

   After starting the container, you can visit `gitlab.example.com`. It might take
   a while before the Docker container starts to respond to queries.

1. Visit the GitLab URL, and sign in with the username `root`
and the password from the following command:

   ```shell
   sudo docker exec -it gitlab grep 'Password:' 
   /etc/gitlab/initial_root_password
   ```

NOTE:
The password file is automatically deleted in the first container restart after 24 hours.

### Install GitLab by using Docker Swarm mode

With [Docker Swarm mode](https://docs.docker.com/engine/swarm/), you can
configure and deploy your GitLab installation with Docker in a swarm cluster.

In swarm mode, you can leverage [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
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
       image: gitlab/gitlab-ee:<version>-ee.0
       container_name: gitlab
       restart: always
       hostname: 'gitlab.example.com'
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

   To reduce complexity, the example above excludes the `network` configuration.
   You can find more information in the official [Compose file reference](https://docs.docker.com/compose/compose-file/).

1. Create a `gitlab.rb` file:

   ```ruby
   external_url 'https://my.domain.com/'
   gitlab_rails['initial_root_password'] = File.read('/run/secrets/gitlab_root_password').gsub("\n", "")
   ```

1. Create a file called `root_password.txt` containing the password:

   ```plaintext
   MySuperSecretAndSecurePassw0rd!
   ```

1. Make sure you are in the same directory as `docker-compose.yml` and run:

   ```shell
   docker stack deploy --compose-file docker-compose.yml mystack
   ```

After you've installed Docker, you need to [configure your GitLab instance](configuration.md).
