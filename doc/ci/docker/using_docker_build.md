---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Docker to build Docker images
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use GitLab CI/CD with Docker to create Docker images.
For example, you can create a Docker image of your application,
test it, and push it to a container registry.

To run Docker commands in your CI/CD jobs, you must configure
GitLab Runner to support `docker` commands. This method requires `privileged` mode.

If you want to build Docker images without enabling `privileged` mode on the runner,
you can use a [Docker alternative](#docker-alternatives).

## Enable Docker commands in your CI/CD jobs

To enable Docker commands for your CI/CD jobs, you can use:

- [The shell executor](#use-the-shell-executor)
- [Docker-in-Docker](#use-docker-in-docker)
- [Docker socket binding](#use-the-docker-executor-with-docker-socket-binding)

### Use the shell executor

To include Docker commands in your CI/CD jobs, you can configure your runner to
use the `shell` executor. In this configuration, the `gitlab-runner` user runs
the Docker commands, but needs permission to do so.

1. [Install](https://gitlab.com/gitlab-org/gitlab-runner/#installation) GitLab Runner.
1. [Register](https://docs.gitlab.com/runner/register/) a runner.
   Select the `shell` executor. For example:

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor shell \
     --description "My Runner"
   ```

1. On the server where GitLab Runner is installed, install Docker Engine.
   View a list of [supported platforms](https://docs.docker.com/engine/install/).

1. Add the `gitlab-runner` user to the `docker` group:

   ```shell
   sudo usermod -aG docker gitlab-runner
   ```

1. Verify that `gitlab-runner` has access to Docker:

   ```shell
   sudo -u gitlab-runner -H docker info
   ```

1. In GitLab, add `docker info` to `.gitlab-ci.yml` to verify that Docker is working:

   ```yaml
   default:
     before_script:
       - docker info

   build_image:
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

You can now use `docker` commands (and install Docker Compose if needed).

When you add `gitlab-runner` to the `docker` group, you effectively grant `gitlab-runner` full root permissions.
For more information, see [security of the `docker` group](https://blog.zopyx.com/on-docker-security-docker-group-considered-harmful/).

### Use Docker-in-Docker

"Docker-in-Docker" (`dind`) means:

- Your registered runner uses the [Docker executor](https://docs.gitlab.com/runner/executors/docker.html) or
  the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/index.html).
- The executor uses a [container image of Docker](https://hub.docker.com/_/docker/), provided
  by Docker, to run your CI/CD jobs.

The Docker image includes all of the `docker` tools and can run
the job script in context of the image in privileged mode.

You should use Docker-in-Docker with TLS enabled,
which is supported by [GitLab.com instance runners](../runners/_index.md).

You should always pin a specific version of the image, like `docker:24.0.5`.
If you use a tag like `docker:latest`, you have no control over which version is used.
This can cause incompatibility problems when new versions are released.

#### Use the Docker executor with Docker-in-Docker

You can use the Docker executor to run jobs in a Docker container.

##### Docker-in-Docker with TLS enabled in the Docker executor

The Docker daemon supports connections over TLS. TLS is the default in Docker 19.03.12 and later.

WARNING:
This task enables `--docker-privileged`, which effectively disables the container's security mechanisms and exposes your host to privilege
escalation. This action can cause container breakout. For more information, see
[runtime privilege and Linux capabilities](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities).

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
     --docker-image "docker:24.0.5" \
     --docker-privileged \
     --docker-volumes "/certs/client"
   ```

   - This command registers a new runner to use the `docker:24.0.5` image (if none is specified at the job level).
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
       image = "docker:24.0.5"
       privileged = true
       disable_cache = false
       volumes = ["/certs/client", "/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. You can now use `docker` in the job script. You should include the
   `docker:24.0.5-dind` service:

   ```yaml
   default:
     image: docker:24.0.5
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
     # https://docs.gitlab.com/ee/ci/services/#accessing-the-services.
     #
     # Specify to Docker where to create the certificates. Docker
     # creates them automatically on boot, and creates
     # `/certs/client` to share between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"

   build:
     stage: build
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

##### Use a Unix socket on a shared volume between Docker-in-Docker and build container

Directories defined in `volumes = ["/certs/client", "/cache"]` in the
[Docker-in-Docker with TLS enabled in the Docker executor](#docker-in-docker-with-tls-enabled-in-the-docker-executor)
approach are [persistent between builds](https://docs.gitlab.com/runner/executors/docker.html#persistent-storage).
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
    image = "docker:24.0.5"
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
  image: docker:24.0.5
  script:
    - docker version
```

##### Docker-in-Docker with TLS disabled in the Docker executor

Sometimes there are legitimate reasons to disable TLS.
For example, you have no control over the GitLab Runner configuration
that you are using.

Assuming that the runner's `config.toml` is similar to:

```toml
[[runners]]
  url = "https://gitlab.com/"
  token = TOKEN
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "docker:24.0.5"
    privileged = true
    disable_cache = false
    volumes = ["/cache"]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

You can now use `docker` in the job script. You should include the
`docker:24.0.5-dind` service:

```yaml
default:
  image: docker:24.0.5
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
  # https://docs.gitlab.com/ee/ci/docker/using_docker_images.html#accessing-the-services
  #
  # If you're using GitLab Runner 12.7 or earlier with the Kubernetes executor and Kubernetes 1.6 or earlier,
  # the variable must be set to tcp://localhost:2375 because of how the
  # Kubernetes executor connects services to the job container
  # DOCKER_HOST: tcp://localhost:2375
  #
  DOCKER_HOST: tcp://docker:2375
  #
  # This instructs Docker not to start over TLS.
  DOCKER_TLS_CERTDIR: ""

build:
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

##### Docker-in-Docker with proxy enabled in the Docker executor

You might need to configure proxy settings to use the `docker push` command.

For more information, see [Proxy settings when using dind service](https://docs.gitlab.com/runner/configuration/proxy.html#proxy-settings-when-using-dind-service).

#### Use the Kubernetes executor with Docker-in-Docker

You can use the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/index.html) to run jobs in a Docker container.

##### Docker-in-Docker with TLS enabled in Kubernetes

To use Docker-in-Docker with TLS enabled in Kubernetes:

1. Using the
   [Helm chart](https://docs.gitlab.com/runner/install/kubernetes.html), update the
   [`values.yml` file](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)
   to specify a volume mount.

   ```yaml
   runners:
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

1. You can now use `docker` in the job script. You should include the
   `docker:24.0.5-dind` service:

   ```yaml
   default:
     image: docker:24.0.5
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
     # https://docs.gitlab.com/ee/ci/services/#accessing-the-services.
     # If you're using GitLab Runner 12.7 or earlier with the Kubernetes executor and Kubernetes 1.6 or earlier,
     # the variable must be set to tcp://localhost:2376 because of how the
     # Kubernetes executor connects services to the job container
     # DOCKER_HOST: tcp://localhost:2376
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
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

##### Docker-in-Docker with TLS disabled in Kubernetes

To use Docker-in-Docker with TLS disabled in Kubernetes, you must adapt the example above to:

- Remove the `[[runners.kubernetes.volumes.empty_dir]]` section from the `values.yml` file.
- Change the port from `2376` to `2375` with `DOCKER_HOST: tcp://docker:2375`.
- Instruct Docker to start with TLS disabled with `DOCKER_TLS_CERTDIR: ""`.

For example:

1. Using the
   [Helm chart](https://docs.gitlab.com/runner/install/kubernetes.html), update the
   [`values.yml` file](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137):

   ```yaml
   runners:
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = true
   ```

1. You can now use `docker` in the job script. You should include the
   `docker:24.0.5-dind` service:

   ```yaml
   default:
     image: docker:24.0.5
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
     # https://docs.gitlab.com/ee/ci/services/#accessing-the-services.
     # If you're using GitLab Runner 12.7 or earlier with the Kubernetes executor and Kubernetes 1.6 or earlier,
     # the variable must be set to tcp://localhost:2376 because of how the
     # Kubernetes executor connects services to the job container
     # DOCKER_HOST: tcp://localhost:2376
     #
     # This instructs Docker not to start over TLS.
     DOCKER_TLS_CERTDIR: ""
   build:
     stage: build
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Known issues with Docker-in-Docker

Docker-in-Docker is the recommended configuration, but you should be aware of the following issues:

- **The `docker-compose` command**: This command is not available in this configuration by default.
  To use `docker-compose` in your job scripts, follow the Docker Compose
  [installation instructions](https://docs.docker.com/compose/install/).
- **Cache**: Each job runs in a new environment. Because every build gets its own instance of the Docker engine, concurrent jobs do not cause conflicts.
  However, jobs can be slower because there's no caching of layers. See [Docker layer caching](#make-docker-in-docker-builds-faster-with-docker-layer-caching).
- **Storage drivers**: By default, earlier versions of Docker use the `vfs` storage driver,
  which copies the file system for each job. Docker 17.09 and later use `--storage-driver overlay2`, which is
  the recommended storage driver. See [Using the OverlayFS driver](#use-the-overlayfs-driver) for details.
- **Root file system**: Because the `docker:24.0.5-dind` container and the runner container do not share their
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

### Use the Docker executor with Docker socket binding

To use Docker commands in your CI/CD jobs, you can bind-mount `/var/run/docker.sock` into the
container. Docker is then available in the context of the image.

If you bind the Docker socket you can't use `docker:24.0.5-dind` as a service. Volume bindings also affect services,
making them incompatible.

To make Docker available in the context of the image, you need to mount
`/var/run/docker.sock` into the launched containers. To do this with the Docker
executor, add `"/var/run/docker.sock:/var/run/docker.sock"` to the
[Volumes in the `[runners.docker]` section](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#volumes-in-the-runnersdocker-section).

Your configuration should look similar to this example:

```toml
[[runners]]
  url = "https://gitlab.com/"
  token = RUNNER_TOKEN
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "docker:24.0.5"
    privileged = false
    disable_cache = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
  [runners.cache]
    Insecure = false
```

To mount `/var/run/docker.sock` while registering your runner, include the following options:

```shell
sudo gitlab-runner register -n \
  --url "https://gitlab.com/" \
  --registration-token REGISTRATION_TOKEN \
  --executor docker \
  --description "My Docker Runner" \
  --docker-image "docker:24.0.5" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock
```

For complex Docker-in-Docker setups like [Code Quality scanning using CodeClimate](../testing/code_quality_codeclimate_scanning.md), you must match host and container paths for proper execution. For more details, see
[Use private runners for CodeClimate-based scanning](../testing/code_quality_codeclimate_scanning.md#use-private-runners).

#### Enable registry mirror for `docker:dind` service

When the Docker daemon starts inside the service container, it uses
the default configuration. You might want to configure a
[registry mirror](https://docs.docker.com/docker-hub/mirror/) for
performance improvements and to ensure you do not exceed Docker Hub rate limits.

##### The service in the `.gitlab-ci.yml` file

You can append extra CLI flags to the `dind` service to set the registry
mirror:

```yaml
services:
  - name: docker:24.0.5-dind
    command: ["--registry-mirror", "https://registry-mirror.example.com"]  # Specify the registry mirror to use
```

##### The service in the GitLab Runner configuration file

If you are a GitLab Runner administrator, you can specify the `command` to configure the registry mirror
for the Docker daemon. The `dind` service must be defined for the
[Docker](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersdockerservices-section)
or [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/index.html#define-a-list-of-services).

Docker:

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    [[runners.docker.services]]
      name = "docker:24.0.5-dind"
      command = ["--registry-mirror", "https://registry-mirror.example.com"]
```

Kubernetes:

```toml
[[runners]]
  ...
  name = "kubernetes"
  [runners.kubernetes]
    ...
    privileged = true
    [[runners.kubernetes.services]]
      name = "docker:24.0.5-dind"
      command = ["--registry-mirror", "https://registry-mirror.example.com"]
```

##### The Docker executor in the GitLab Runner configuration file

If you are a GitLab Runner administrator, you can use
the mirror for every `dind` service. Update the
[configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)
to specify a [volume mount](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#volumes-in-the-runnersdocker-section).

For example, if you have a `/opt/docker/daemon.json` file with the following
content:

```json
{
  "registry-mirrors": [
    "https://registry-mirror.example.com"
  ]
}
```

Update the `config.toml` file to mount the file to
`/etc/docker/daemon.json`. This mounts the file for **every**
container created by GitLab Runner. The configuration is
detected by the `dind` service.

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    image = "alpine:3.12"
    privileged = true
    volumes = ["/opt/docker/daemon.json:/etc/docker/daemon.json:ro"]
```

##### The Kubernetes executor in the GitLab Runner configuration file

If you are a GitLab Runner administrator, you can use
the mirror for every `dind` service. Update the
[configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)
to specify a [ConfigMap volume mount](https://docs.gitlab.com/runner/executors/kubernetes/index.html#configmap-volume).

For example, if you have a `/tmp/daemon.json` file with the following
content:

```json
{
  "registry-mirrors": [
    "https://registry-mirror.example.com"
  ]
}
```

Create a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) with the content
of this file. You can do this with a command like:

```shell
kubectl create configmap docker-daemon --namespace gitlab-runner --from-file /tmp/daemon.json
```

NOTE:
You must use the namespace that the Kubernetes executor for GitLab Runner uses to create job pods.

After the ConfigMap is created, you can update the `config.toml`
file to mount the file to `/etc/docker/daemon.json`. This update
mounts the file for **every** container created by GitLab Runner.
The `dind` service detects this configuration.

```toml
[[runners]]
  ...
  executor = "kubernetes"
  [runners.kubernetes]
    image = "alpine:3.12"
    privileged = true
    [[runners.kubernetes.volumes.config_map]]
      name = "docker-daemon"
      mount_path = "/etc/docker/daemon.json"
      sub_path = "daemon.json"
```

#### Known issues with Docker socket binding

When you use Docker socket binding, you avoid running Docker in privileged mode. However,
the implications of this method are:

- By sharing the Docker daemon, you effectively disable all
  the container's security mechanisms and expose your host to privilege
  escalation. This can cause container breakout. For example, if a project
  ran `docker rm -f $(docker ps -a -q)`, it would remove the GitLab Runner
  containers.
- Concurrent jobs might not work. If your tests
  create containers with specific names, they might conflict with each other.
- Any containers created by Docker commands are siblings of the runner, rather
  than children of the runner. This might cause complications for your workflow.
- Sharing files and directories from the source repository into containers might not
  work as expected. Volume mounting is done in the context of the host
  machine, not the build container. For example:

   ```shell
   docker run --rm -t -i -v $(pwd)/src:/home/app/src test-image:latest run_app_tests
   ```

You do not need to include the `docker:24.0.5-dind` service, like you do when
you use the Docker-in-Docker executor:

```yaml
default:
  image: docker:24.0.5
  before_script:
    - docker info

build:
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

## Authenticate with registry in Docker-in-Docker

When you use Docker-in-Docker, the [standard authentication methods](using_docker_images.md#access-an-image-from-a-private-container-registry) do not work, because a fresh Docker daemon is started with the service. You should [authenticate with registry](authenticate_registry.md).

## Make Docker-in-Docker builds faster with Docker layer caching

When using Docker-in-Docker, Docker downloads all layers of your image every time you create a build. You can [make your builds faster with Docker layer caching](docker_layer_caching.md).

## Use the OverlayFS driver

NOTE:
The instance runners on GitLab.com use the `overlay2` driver by default.

By default, when using `docker:dind`, Docker uses the `vfs` storage driver, which
copies the file system on every run. You can avoid this disk-intensive operation by using a different driver, for example `overlay2`.

### Requirements

1. Ensure a recent kernel is used, preferably `>= 4.2`.
1. Check whether the `overlay` module is loaded:

   ```shell
   sudo lsmod | grep overlay
   ```

   If you see no result, then the module is not loaded. To load the module, use:

   ```shell
   sudo modprobe overlay
   ```

   If the module loaded, you must make sure the module loads on reboot.
   On Ubuntu systems, do this by adding the following line to `/etc/modules`:

   ```plaintext
   overlay
   ```

### Use the OverlayFS driver per project

You can enable the driver for each project individually by using the `DOCKER_DRIVER`
[CI/CD variable](../yaml/_index.md#variables) in `.gitlab-ci.yml`:

```yaml
variables:
  DOCKER_DRIVER: overlay2
```

### Use the OverlayFS driver for every project

If you use your own [runners](https://docs.gitlab.com/runner/), you
can enable the driver for every project by setting the `DOCKER_DRIVER`
environment variable in the
[`[[runners]]` section of the `config.toml` file](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section):

```toml
environment = ["DOCKER_DRIVER=overlay2"]
```

If you're running multiple runners, you must modify all configuration files.

Read more about the [runner configuration](https://docs.gitlab.com/runner/configuration/)
and [using the OverlayFS storage driver](https://docs.docker.com/storage/storagedriver/overlayfs-driver/).

## Docker alternatives

To build Docker images without enabling privileged mode on the runner, you can
use one of these alternatives:

- [`kaniko`](using_kaniko.md).
- [`buildah`](#buildah-example).

### Buildah example

To use Buildah with GitLab CI/CD, you need [a runner](https://docs.gitlab.com/runner/) with one
of the following executors:

- [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/index.html).
- [Docker](https://docs.gitlab.com/runner/executors/docker.html).
- [Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine.html).

In this example, you use Buildah to:

1. Build a Docker image.
1. Push it to [GitLab container registry](../../user/packages/container_registry/_index.md).

In the last step, Buildah uses the `Dockerfile` under the
root directory of the project to build the Docker image. Finally, it pushes the image to the
project's container registry:

```yaml
build:
  stage: build
  image: quay.io/buildah/stable
  variables:
    # Use vfs with buildah. Docker offers overlayfs as a default, but Buildah
    # cannot stack overlayfs on top of another overlayfs filesystem.
    STORAGE_DRIVER: vfs
    # Write all image metadata in the docker format, not the standard OCI format.
    # Newer versions of docker can handle the OCI format, but older versions, like
    # the one shipped with Fedora 30, cannot handle the format.
    BUILDAH_FORMAT: docker
    FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE/test"
  before_script:
    # GitLab container registry credentials taken from the
    # [predefined CI/CD variables](../variables/_index.md#predefined-cicd-variables)
    # to authenticate to the registry.
    - echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY
  script:
    - buildah images
    - buildah build -t $FQ_IMAGE_NAME
    - buildah images
    - buildah push $FQ_IMAGE_NAME
```

If you are using GitLab Runner Operator deployed to an OpenShift cluster, try the
[tutorial for using Buildah to build images in rootless container](buildah_rootless_tutorial.md).

## Use the GitLab container registry

After you've built a Docker image, you can push it to the
[GitLab container registry](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd).

## Troubleshooting

### Error: `docker: Cannot connect to the Docker daemon at tcp://docker:2375`

This error is common when you are using [Docker-in-Docker](#use-docker-in-docker)
v19.03 or later:

```plaintext
docker: Cannot connect to the Docker daemon at tcp://docker:2375. Is the docker daemon running?
```

This error occurs because Docker starts on TLS automatically.

- If this is your first time setting it up, see
  [use the Docker executor with the Docker image](#use-docker-in-docker).
- If you are upgrading from v18.09 or earlier, see the
  [upgrade guide](https://about.gitlab.com/blog/2019/07/31/docker-in-docker-with-docker-19-dot-03/).

This error can also occur with the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/index.html#using-dockerdind) when attempts are made to access the Docker-in-Docker service before it has fully started up. For a more detailed explanation, see [issue 27215](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27215).

### Docker `no such host` error

You might get an error that says
`docker: error during connect: Post https://docker:2376/v1.40/containers/create: dial tcp: lookup docker on x.x.x.x:53: no such host`.

This issue can occur when the service's image name
[includes a registry hostname](../services/_index.md#available-settings-for-services). For example:

```yaml
default:
  image: docker:24.0.5
  services:
    - registry.hub.docker.com/library/docker:24.0.5-dind
```

A service's hostname is [derived from the full image name](../services/_index.md#accessing-the-services).
However, the shorter service hostname `docker` is expected.
To allow service resolution and access, add an explicit alias for the service name `docker`:

```yaml
default:
  image: docker:24.0.5
  services:
    - name: registry.hub.docker.com/library/docker:24.0.5-dind
      alias: docker
```

### Error: `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`

You might get the following error when trying to run a `docker` command
to access a `dind` service:

```shell
$ docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

Make sure your job has defined these environment variables:

- `DOCKER_HOST`
- `DOCKER_TLS_CERTDIR` (optional)
- `DOCKER_TLS_VERIFY` (optional)

You may also want to update the image that provides the Docker
client. For example, the [`docker/compose` images are obsolete](https://hub.docker.com/r/docker/compose) and should be
replaced with [`docker`](https://hub.docker.com/_/docker).

As described in [runner issue 30944](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30944#note_1514250909),
this error can happen if your job previously relied on environment variables derived from the deprecated
[Docker `--link` parameter](https://docs.docker.com/network/links/#environment-variables),
such as `DOCKER_PORT_2375_TCP`. Your job fails with this error if:

- Your CI/CD image relies on a legacy variable, such as `DOCKER_PORT_2375_TCP`.
- The [runner feature flag `FF_NETWORK_PER_BUILD`](https://docs.gitlab.com/runner/configuration/feature-flags.html) is set to `true`.
- `DOCKER_HOST` is not explicitly set.

### Error: `unauthorized: incorrect username or password`

This error appears when you use the deprecated variable, `CI_BUILD_TOKEN`:

```plaintext
Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized: incorrect username or password
```

To prevent users from receiving this error, you should:

- Use [CI_JOB_TOKEN](../jobs/ci_job_token.md) instead.
- Change from `gitlab-ci-token/CI_BUILD_TOKEN` to `$CI_REGISTRY_USER/$CI_REGISTRY_PASSWORD`.

### Error during connect: `no such host`

This error appears when the `dind` service has failed to start:

```plaintext
error during connect: Post "https://docker:2376/v1.24/auth": dial tcp: lookup docker on 127.0.0.11:53: no such host
```

Check the job log to see if `mount: permission denied (are you root?)`
appears. For example:

```plaintext
Service container logs:
2023-08-01T16:04:09.541703572Z Certificate request self-signature ok
2023-08-01T16:04:09.541770852Z subject=CN = docker:dind server
2023-08-01T16:04:09.556183222Z /certs/server/cert.pem: OK
2023-08-01T16:04:10.641128729Z Certificate request self-signature ok
2023-08-01T16:04:10.641173149Z subject=CN = docker:dind client
2023-08-01T16:04:10.656089908Z /certs/client/cert.pem: OK
2023-08-01T16:04:10.659571093Z ip: can't find device 'ip_tables'
2023-08-01T16:04:10.660872131Z modprobe: can't change directory to '/lib/modules': No such file or directory
2023-08-01T16:04:10.664620455Z mount: permission denied (are you root?)
2023-08-01T16:04:10.664692175Z Could not mount /sys/kernel/security.
2023-08-01T16:04:10.664703615Z AppArmor detection and --privileged mode might break.
2023-08-01T16:04:10.665952353Z mount: permission denied (are you root?)
```

This indicates the GitLab Runner does not have permission to start the
`dind` service:

1. Check that `privileged = true` is set in the `config.toml`.
1. Make sure the CI job has the right Runner tags to use these
   privileged runners.

### Error: `cgroups: cgroup mountpoint does not exist: unknown`

There is a known incompatibility introduced by Docker Engine 20.10.

When the host uses Docker Engine 20.10 or newer, then the `docker:dind` service in a version older than 20.10 does
not work as expected.

While the service itself will start without problems, trying to build the container image results in the error:

```plaintext
cgroups: cgroup mountpoint does not exist: unknown
```

To resolve this issue, update the `docker:dind` container to version at least 20.10.x,
for example `docker:24.0.5-dind`.

The opposite configuration (`docker:24.0.5-dind` service and Docker Engine on the host in version
19.06.x or older) works without problems. For the best strategy, you should to frequently test and update
job environment versions to the newest. This brings new features, improved security and - for this specific
case - makes the upgrade on the underlying Docker Engine on the runner's host transparent for the job.
