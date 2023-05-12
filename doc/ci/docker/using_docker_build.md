---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: concepts, howto
---

# Use Docker to build Docker images **(FREE)**

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
     --url https://gitlab.com/ \
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

- Your registered runner uses the [Docker executor](https://docs.gitlab.com/runner/executors/docker.html) or the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes.html).
- The executor uses a [container image of Docker](https://hub.docker.com/_/docker/), provided
  by Docker, to run your CI/CD jobs.

The Docker image includes all of the `docker` tools and can run
the job script in context of the image in privileged mode.

You should use Docker-in-Docker with TLS enabled,
which is supported by [GitLab.com shared runners](../runners/index.md).

You should always pin a specific version of the image, like `docker:20.10.16`.
If you use a tag like `docker:stable`, you have no control over which version is used.
This can cause incompatibility problems when new versions are released.

#### Use the Docker executor with Docker-in-Docker

You can use the Docker executor to run jobs in a Docker container.

##### Docker-in-Docker with TLS enabled in the Docker executor

> Introduced in GitLab Runner 11.11.

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
     --url https://gitlab.com/ \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --docker-image "docker:20.10.16" \
     --docker-privileged \
     --docker-volumes "/certs/client"
   ```

   - This command registers a new runner to use the `docker:20.10.16` image.
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
       image = "docker:20.10.16"
       privileged = true
       disable_cache = false
       volumes = ["/certs/client", "/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. You can now use `docker` in the job script. You should include the
   `docker:20.10.16-dind` service:

   ```yaml
   image: docker:20.10.16

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

   services:
     - docker:20.10.16-dind

   before_script:
     - docker info

   build:
     stage: build
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
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
    image = "docker:20.10.16"
    privileged = true
    disable_cache = false
    volumes = ["/cache"]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

You can now use `docker` in the job script. You should include the
`docker:20.10.16-dind` service:

```yaml
image: docker:20.10.16

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

services:
  - docker:20.10.16-dind

before_script:
  - docker info

build:
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

#### Use the Kubernetes executor with Docker-in-Docker

You can use the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes.html) to run jobs in a Docker container.

##### Docker-in-Docker with TLS enabled in Kubernetes

> [Introduced](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/106) in GitLab Runner Helm Chart 0.23.0.

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
   `docker:20.10.16-dind` service:

   ```yaml
   image: docker:20.10.16

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

   services:
     - docker:20.10.16-dind

   before_script:
     - docker info

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
- **Root file system**: Because the `docker:20.10.16-dind` container and the runner container do not share their
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

NOTE:
If you bind the Docker socket and you are
[using GitLab Runner 11.11 or later](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1261),
you can no longer use `docker:20.10.16-dind` as a service. Volume bindings
also affect services, making them incompatible.

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
    image = "docker:20.10.16"
    privileged = false
    disable_cache = false
    volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
  [runners.cache]
    Insecure = false
```

To mount `/var/run/docker.sock` while registering your runner, include the following options:

```shell
sudo gitlab-runner register -n \
  --url https://gitlab.com/ \
  --registration-token REGISTRATION_TOKEN \
  --executor docker \
  --description "My Docker Runner" \
  --docker-image "docker:20.10.16" \
  --docker-volumes /var/run/docker.sock:/var/run/docker.sock
```

#### Enable registry mirror for `docker:dind` service

When the Docker daemon starts inside the service container, it uses
the default configuration. You might want to configure a
[registry mirror](https://docs.docker.com/registry/recipes/mirror/) for
performance improvements and to ensure you do not exceed Docker Hub rate limits.

##### The service in the `.gitlab-ci.yml` file

You can append extra CLI flags to the `dind` service to set the registry
mirror:

```yaml
services:
  - name: docker:20.10.16-dind
    command: ["--registry-mirror", "https://registry-mirror.example.com"]  # Specify the registry mirror to use
```

##### The service in the GitLab Runner configuration file

> [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27173) in GitLab Runner 13.6.

If you are a GitLab Runner administrator, you can specify the `command` to configure the registry mirror
for the Docker daemon. The `dind` service must be defined for the
[Docker](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnersdockerservices-section)
or [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes.html#using-services).

Docker:

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    [[runners.docker.services]]
      name = "docker:20.10.16-dind"
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
      name = "docker:20.10.16-dind"
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3223) in GitLab Runner 13.6.

If you are a GitLab Runner administrator, you can use
the mirror for every `dind` service. Update the
[configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)
to specify a [ConfigMap volume mount](https://docs.gitlab.com/runner/executors/kubernetes.html#using-volumes).

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

You do not need to include the `docker:20.10.16-dind` service, like you do when
you use the Docker-in-Docker executor:

```yaml
image: docker:20.10.16

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
The shared runners on GitLab.com use the `overlay2` driver by default.

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
[CI/CD variable](../yaml/index.md#variables) in `.gitlab-ci.yml`:

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

- [`kaniko`](using_kaniko.md)
- [`buildah`](https://github.com/containers/buildah)

For example, with `buildah`:

```yaml
# Some details from https://major.io/2019/05/24/build-containers-in-gitlab-ci-with-buildah/

build:
  stage: build
  image: quay.io/buildah/stable
  variables:
    # Use vfs with buildah. Docker offers overlayfs as a default, but buildah
    # cannot stack overlayfs on top of another overlayfs filesystem.
    STORAGE_DRIVER: vfs
    # Write all image metadata in the docker format, not the standard OCI format.
    # Newer versions of docker can handle the OCI format, but older versions, like
    # the one shipped with Fedora 30, cannot handle the format.
    BUILDAH_FORMAT: docker
    # You may need this workaround for some errors: https://stackoverflow.com/a/70438141/1233435
    BUILDAH_ISOLATION: chroot
    FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE/test"
  before_script:
    # Log in to the GitLab container registry
    - export REGISTRY_AUTH_FILE=$HOME/auth.json
    - echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY
  script:
    - buildah images
    - buildah build -t $FQ_IMAGE_NAME
    - buildah images
    - buildah push $FQ_IMAGE_NAME
```

## Use the GitLab Container Registry

After you've built a Docker image, you can push it to the
[GitLab Container Registry](../../user/packages/container_registry/build_and_push_images.md#use-gitlab-cicd).

## Troubleshooting

### `docker: Cannot connect to the Docker daemon at tcp://docker:2375. Is the docker daemon running?`

This is a common error when you are using
[Docker-in-Docker](#use-docker-in-docker)
v19.03 or later.

This error occurs because Docker starts on TLS automatically.

- If this is your first time setting it up, see
  [use the Docker executor with the Docker image](#use-docker-in-docker).
- If you are upgrading from v18.09 or earlier, see the
  [upgrade guide](https://about.gitlab.com/blog/2019/07/31/docker-in-docker-with-docker-19-dot-03/).

This error can also occur with the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes.html#using-dockerdind) when attempts are made to access the Docker-in-Docker service before it has fully started up. For a more detailed explanation, see [issue 27215](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27215).

### Docker `no such host` error

You might get an error that says
`docker: error during connect: Post https://docker:2376/v1.40/containers/create: dial tcp: lookup docker on x.x.x.x:53: no such host`.

This issue can occur when the service's image name
[includes a registry hostname](../../ci/services/index.md#available-settings-for-services). For example:

```yaml
image: docker:20.10.16

services:
  - registry.hub.docker.com/library/docker:20.10.16-dind
```

A service's hostname is [derived from the full image name](../../ci/services/index.md#accessing-the-services).
However, the shorter service hostname `docker` is expected.
To allow service resolution and access, add an explicit alias for the service name `docker`:

```yaml
image: docker:20.10.16

services:
  - name: registry.hub.docker.com/library/docker:20.10.16-dind
    alias: docker
```

### Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized: incorrect username or password

This error appears when you use the deprecated variable, `CI_BUILD_TOKEN`. To prevent users from receiving this error, you should:

- Use [CI_JOB_TOKEN](../jobs/ci_job_token.md) instead.
- Change from `gitlab-ci-token/CI_BUILD_TOKEN` to `$CI_REGISTRY_USER/$CI_REGISTRY_PASSWORD`.
