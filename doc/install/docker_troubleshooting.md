---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting GitLab installations that use Docker

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

When installing GitLab by using Docker, you might encounter the following issues.

## Diagnose potential problems

Read container logs:

```shell
sudo docker logs gitlab
```

Enter running container:

```shell
sudo docker exec -it gitlab /bin/bash
```

From within the container you can administer the GitLab container as you would
usually administer a [Linux package installation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md).

## 500 Internal Error

When updating the Docker image you may encounter an issue where all paths
display a `500` page. If this occurs, restart the container to try to rectify the
issue:

```shell
sudo docker restart gitlab
```

## Permission problems

When updating from older GitLab Docker images you might encounter permission
problems. This happens when users in previous images were not
preserved correctly. There's script that fixes permissions for all files.

To fix your container, execute `update-permissions` and restart the
container afterwards:

```shell
sudo docker exec gitlab update-permissions
sudo docker restart gitlab
```

## Error executing action run on resource `ruby_block`

This error occurs when using Docker Toolbox with VirtualBox on Windows or Mac,
and making use of Docker volumes:

```plaintext
Error executing action run on resource ruby_block[directory resource: /data/GitLab]
```

The `/c/Users` volume is mounted as a
VirtualBox Shared Folder, and does not support the all POSIX file system features.
The directory ownership and permissions cannot be changed without remounting, and
GitLab fails.

Our recommendation is to switch to using the native Docker install for your
platform, instead of using Docker Toolbox.

If you cannot use the native Docker install (Windows 10 Home Edition, or Windows 7/8),
then an alternative solution is to set up NFS mounts instead of VirtualBox shares for
Docker Toolbox's boot2docker.

## Linux ACL issues

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

## `/dev/shm` mount not having enough space in Docker container

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

Other than disabling the Prometheus Metrics from the Admin area, the recommended
solution to fix this problem is to [install](docker.md#pre-configure-docker-container) with shared memory set to at least 256 MB.
If using `docker run`, this can be done by passing the flag `--shm-size 256m`.
If using a `docker-compose.yml` file, the `shm_size` key can be used for this
purpose.

## Docker containers exhausts space due to the `json-file`

Docker uses the [`json-file` default logging driver](https://docs.docker.com/config/containers/logging/configure/#configure-the-default-logging-driver), which performs no log rotation by default. As a result of this lack of rotation, log files stored by the `json-file` driver can consume a significant amount of disk space for containers that generate a lot of output. This can lead to disk space exhaustion. To address this, use [`journald`](https://docs.docker.com/config/containers/logging/journald/) as the logging driver when available, or [another supported driver](https://docs.docker.com/config/containers/logging/configure/#supported-logging-drivers) with native rotation support.

## Buffer overflow error when starting Docker

If you receive this buffer overflow error, you should purge old log files in
`/var/log/gitlab`:

```plaintext
buffer overflow detected : terminated
xargs: tail: terminated by signal 6
```

Removing old log files helps fix the error, and ensures a clean startup of the instance.

## ThreadError can't create Thread Operation not permitted

```plaintext
can't create Thread: Operation not permitted
```

This error occurs when running a container built with newer `glibc` versions on a
[host that doesn't have support for the new clone3 function](https://github.com/moby/moby/issues/42680). In GitLab 16.0 and later, the container image includes
the Ubuntu 22.04 Linux package which is built with this newer `glibc`.

This problem is fixed with newer container runtime tools like [Docker 20.10.10](https://github.com/moby/moby/pull/42836).

To resolve this issue, update Docker to version 20.10.10 or later.
