---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Use Docker-in-Docker
description: Configure Docker-in-Docker for GitLab CI/CD jobs using the Docker or Kubernetes executor.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Docker-in-Docker (`dind`) means your registered runner uses the [Docker executor](https://docs.gitlab.com/runner/executors/docker/) or
the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/).
The executor uses a [container image of Docker](https://hub.docker.com/_/docker/), provided by Docker, to run your CI/CD jobs.

The Docker image includes all of the `docker` tools and can run
the job script in context of the image in privileged mode.

Always pin a specific version of the image, like `docker:24.0.5`.
If you use a tag like `docker:latest`, you have no control over which version is used.
This action can cause incompatibility problems when new versions are released.

## Use with Docker executor

You can use the Docker executor to run jobs in a Docker container.

### Docker-in-Docker with TLS enabled in the Docker executor (recommended)

The Docker daemon supports connections over TLS. Use TLS when possible.
TLS is the default in Docker 19.03.12 and later and is supported by
[GitLab.com instance runners](../runners/_index.md).

> [!warning]
> This task enables `--docker-privileged`, which effectively disables the container's security mechanisms and exposes your host to privilege
> escalation. This action can cause container breakout. For more information, see
> [runtime privilege and Linux capabilities](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities).

To use Docker-in-Docker with TLS enabled:

1. Install [GitLab Runner](https://docs.gitlab.com/runner/install/).
1. Register GitLab Runner from the command line. Use `docker` and `privileged`
   mode:

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --tag-list "tls-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-privileged \
     --docker-volumes "/certs/client"
   ```

   - This command registers a new runner to use the `docker:24.0.5-cli` image (if none is specified at the job level).
     To start the build and service containers, it uses the `privileged` mode.
     If you want to use Docker-in-Docker,
     you must always use `privileged = true` in your Docker containers.
   - This command mounts `/certs/client` for the service and build
     container, which is needed for the Docker client to use the
     certificates in that directory. For more information, see [the Docker image documentation](https://hub.docker.com/_/docker/).

   The previous command creates a `config.toml` entry similar to the following example:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = true
       disable_cache = false
       volumes = ["/certs/client", "/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. You can now use `docker` in the job script. Include the `docker:24.0.5-dind` service:

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - docker:24.0.5-dind
     before_script:
       - docker info

   variables:
     # When you use the dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket. Docker 19.03 does this automatically
     # by setting the DOCKER_HOST in
     # https://github.com/docker-library/docker/blob/d45051476babc297257df490d22cbd806f1b11e4/19.03/docker-entrypoint.sh#L23-L29
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # Specify to Docker where to create the certificates. Docker
     # creates them automatically on boot, and creates
     # `/certs/client` to share between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"

   build:
     stage: build
     tags:
       - tls-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Docker-in-Docker with TLS disabled in the Docker executor

Sometimes there are legitimate reasons to disable TLS.
For example, you have no control over the GitLab Runner configuration
that you are using.

1. Register GitLab Runner from command line. Use `docker` and `privileged` mode:

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --tag-list "no-tls-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-privileged
   ```

   The previous command creates a `config.toml` entry similar to the following example:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = true
       disable_cache = false
       volumes = ["/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. Include the `docker:24.0.5-dind` service in the job script:

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - docker:24.0.5-dind
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct docker to talk with the
     # daemon started inside of the service. The daemon is available with
     # a network connection instead of the default /var/run/docker.sock socket.
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services
     #
     DOCKER_HOST: tcp://docker:2375
     #
     # This instructs Docker not to start over TLS.
     DOCKER_TLS_CERTDIR: ""

   build:
     stage: build
     tags:
       - no-tls-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Use a Unix socket on a shared volume between Docker-in-Docker and build container

Directories defined in `volumes = ["/certs/client", "/cache"]` in the
[Docker-in-Docker with TLS enabled in the Docker executor](#docker-in-docker-with-tls-enabled-in-the-docker-executor-recommended)
approach are [persistent between builds](https://docs.gitlab.com/runner/executors/docker/#persistent-storage).
If multiple CI/CD jobs using a Docker executor runner have Docker-in-Docker services enabled, then each job
writes to the directory path. This approach might result in a conflict.

To address this conflict, use a Unix socket on a volume shared between the Docker-in-Docker service and the build container.
This approach improves performance and establishes a secure connection between the service and client.

The following is a sample `config.toml` with temporary volume shared between build and service containers:

```toml
[[runners]]
  url = "https://gitlab.com/"
  token = TOKEN
  executor = "docker"
  [runners.docker]
    image = "docker:24.0.5-cli"
    privileged = true
    volumes = ["/runner/services/docker"] # Temporary volume shared between build and service containers.
```

The Docker-in-Docker service creates a `docker.sock`. The Docker client connects to `docker.sock` through a Docker Unix socket volume.

```yaml
job:
  variables:
    # This variable is shared by both the DinD service and Docker client.
    # For the service, it will instruct DinD to create `docker.sock` here.
    # For the client, it tells the Docker client which Docker Unix socket to connect to.
    DOCKER_HOST: "unix:///runner/services/docker/docker.sock"
  services:
    - docker:24.0.5-dind
  image: docker:24.0.5-cli
  script:
    - docker version
```

### Docker-in-Docker with proxy enabled in the Docker executor

You might need to configure proxy settings to use the `docker push` command.

For more information, see [Proxy settings when using dind service](https://docs.gitlab.com/runner/configuration/proxy/#proxy-settings-when-using-dind-service).

## Use with Kubernetes executor

You can use the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/) to run jobs in a Docker container.

### Docker-in-Docker with TLS enabled in Kubernetes (recommended)

To use Docker-in-Docker with TLS enabled in Kubernetes:

1. Using the
   [Helm chart](https://docs.gitlab.com/runner/install/kubernetes/), update the
   [`values.yml` file](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)
   to specify a volume mount.

   ```yaml
   runners:
     tags: "tls-dind-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = true
         [[runners.kubernetes.volumes.empty_dir]]
           name = "docker-certs"
           mount_path = "/certs/client"
           medium = "Memory"
   ```

1. Include the `docker:24.0.5-dind` service in the job:

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - name: docker:24.0.5-dind
         variables:
           HEALTHCHECK_TCP_PORT: "2376"
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket.
     DOCKER_HOST: tcp://docker:2376
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # Specify to Docker where to create the certificates. Docker
     # creates them automatically on boot, and creates
     # `/certs/client` to share between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"
     # These are usually specified by the entrypoint, however the
     # Kubernetes executor doesn't run entrypoints
     # https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4125
     DOCKER_TLS_VERIFY: 1
     DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"

   build:
     stage: build
     tags:
       - tls-dind-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Docker-in-Docker with TLS disabled in Kubernetes

To use Docker-in-Docker with TLS disabled in Kubernetes, you must adapt the previous example to:

- Remove the `[[runners.kubernetes.volumes.empty_dir]]` section from the `values.yml` file.
- Change the port from `2376` to `2375` with `DOCKER_HOST: tcp://docker:2375`.
- Instruct Docker to start with TLS disabled with `DOCKER_TLS_CERTDIR: ""`.

For example:

1. Using the
   [Helm chart](https://docs.gitlab.com/runner/install/kubernetes/), update the
   [`values.yml` file](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137):

   ```yaml
   runners:
     tags: "no-tls-dind-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = true
   ```

1. You can now use `docker` in the job script. Include the
   `docker:24.0.5-dind` service:

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - name: docker:24.0.5-dind
         variables:
           HEALTHCHECK_TCP_PORT: "2375"
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket.
     DOCKER_HOST: tcp://docker:2375
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # This instructs Docker not to start over TLS.
     DOCKER_TLS_CERTDIR: ""
   build:
     stage: build
     tags:
       - no-tls-dind-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

## Known issues with Docker-in-Docker

Docker-in-Docker is the recommended configuration, but you should be aware of the following issues:

- `docker-compose` command: This command is not available in this configuration by default.
  To use `docker-compose` in your job scripts, follow the Docker Compose
  [installation instructions](https://docs.docker.com/compose/install/).
- Cache: Each job runs in a new environment. Because every build gets its own instance of the Docker engine, concurrent jobs do not cause conflicts.
  However, jobs can be slower because there's no caching of layers. See [Docker layer caching](using_docker_build.md#docker-layer-caching).
- Storage drivers: By default, earlier versions of Docker use the `vfs` storage driver,
  which copies the file system for each job. Docker 17.09 and later use `--storage-driver overlay2`, which is
  the recommended storage driver. See [Using the OverlayFS driver](using_docker_build.md#use-the-overlayfs-driver) for details.
- Root file system: Because the `docker:24.0.5-dind` container and the runner container do not share their
  root file system, you can use the job's working directory as a mount point for
  child containers. For example, if you have files you want to share with a
  child container, you could create a subdirectory under `/builds/$CI_PROJECT_PATH`
  and use it as your mount point. For a more detailed explanation, see
  [issue #41227](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41227).

  ```yaml
  variables:
    MOUNT_POINT: /builds/$CI_PROJECT_PATH/mnt
  script:
    - mkdir -p "$MOUNT_POINT"
    - docker run -v "$MOUNT_POINT:/mnt" my-docker-image
  ```
