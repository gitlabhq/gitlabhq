---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure GitLab running in a Docker container

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

This container uses the official Linux package, so all configuration
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

## Pre-configure Docker container

You can pre-configure the GitLab Docker image by adding the environment variable
`GITLAB_OMNIBUS_CONFIG` to Docker run command. This variable can contain any
`gitlab.rb` setting and is evaluated before the loading of the container's
`gitlab.rb` file. This behavior allows you to configure the external GitLab URL,
and make database configuration or any other option from the
[Linux package template](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template).
The settings contained in `GITLAB_OMNIBUS_CONFIG` aren't written to the
`gitlab.rb` configuration file, and are evaluated on load. To provide multiple
settings, separate them with a colon (`;`).

Here's an example that sets the external URL, enables LFS, and starts
the container with a [minimal shm size required for Prometheus](../docker/troubleshooting.md#devshm-mount-not-having-enough-space-in-docker-container):

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'; gitlab_rails['lfs_enabled'] = true;" \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:<version>-ee.0
```

Every time you execute a `docker run` command, you need to provide
the `GITLAB_OMNIBUS_CONFIG` option. The content of `GITLAB_OMNIBUS_CONFIG` is
_not_ preserved between subsequent runs.

### Run GitLab on a public IP address

You can make Docker to use your IP address and forward all traffic to the
GitLab container by modifying the `--publish` flag.

To expose GitLab on IP `198.51.100.1`:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
  --publish 198.51.100.1:443:443 \
  --publish 198.51.100.1:80:80 \
  --publish 198.51.100.1:22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:<version>-ee.0
```

You can then access your GitLab instance at `http://198.51.100.1/` and `https://198.51.100.1/`.

## Expose GitLab on different ports

GitLab will occupy [some ports](../../administration/package_information/defaults.md)
inside the container.

If you want to use a different host port than `80` (HTTP), `443` (HTTPS), or `22` (SSH),
you need to add a separate `--publish` directive to the `docker run` command.

For example, to expose the web interface on the host's port `8929`, and the SSH service on
port `2424`:

1. Use the following `docker run` command:

   ```shell
   sudo docker run --detach \
     --hostname gitlab.example.com \
     --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com:8929'; gitlab_rails['gitlab_shell_ssh_port'] = 2424" \
     --publish 8929:8929 --publish 2424:22 \
     --name gitlab \
     --restart always \
     --volume $GITLAB_HOME/config:/etc/gitlab \
     --volume $GITLAB_HOME/logs:/var/log/gitlab \
     --volume $GITLAB_HOME/data:/var/opt/gitlab \
     --shm-size 256m \
     gitlab/gitlab-ee:<version>-ee.0
   ```

   NOTE:
   The format for publishing ports is `hostPort:containerPort`. Read more in the
   Docker documentation about
   [exposing incoming ports](https://docs.docker.com/network/#published-ports).

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

1. Set the SSH port:

   ```ruby
   gitlab_rails['gitlab_shell_ssh_port'] = 2424
   ```

1. Finally, reconfigure GitLab:

   ```shell
   gitlab-ctl reconfigure
   ```

Following the above example, you will be able to reach GitLab from your
web browser under `<hostIP>:8929` and push using SSH under the port `2424`.

A `docker-compose.yml` example that uses different ports can be found in the
[Docker compose](installation.md#install-gitlab-using-docker-compose) section.

## Configure multiple database connections

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

## Recommended next steps

After completing your installation, consider taking the
[recommended next steps](../next_steps.md), including authentication options
and sign-up restrictions.
