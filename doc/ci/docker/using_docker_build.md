---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Use Docker to build Docker images **(FREE)**

You can use GitLab CI/CD with Docker to create Docker images.
For example, you can create a Docker image of your application,
test it, and publish it to a container registry.

To run Docker commands in your CI/CD jobs, you must configure
GitLab Runner to support `docker` commands.

## Enable Docker commands in your CI/CD jobs

To enable Docker commands for your CI/CD jobs, you can use:

- [The shell executor](#use-the-shell-executor)
- [The Docker executor with the Docker image (Docker-in-Docker)](#use-the-docker-executor-with-the-docker-image-docker-in-docker)
- [Docker socket binding](#use-docker-socket-binding)

If you don't want to execute a runner in privileged mode,
but want to use `docker build`, you can also [use kaniko](using_kaniko.md).

If you are using shared runners on GitLab.com,
[learn more about how these runners are configured](../runners/index.md).

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
   View a list of [supported platforms](https://docs.docker.com/engine/installation/).

1. Add the `gitlab-runner` user to the `docker` group:

   ```shell
   sudo usermod -aG docker gitlab-runner
   ```

1. Verify that `gitlab-runner` has access to Docker:

   ```shell
   sudo -u gitlab-runner -H docker info
   ```

1. In GitLab, to verify that everything works, add `docker info` to `.gitlab-ci.yml`:

   ```yaml
   before_script:
     - docker info

   build_image:
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

You can now use `docker` commands (and install `docker-compose` if needed).

When you add `gitlab-runner` to the `docker` group, you are effectively granting `gitlab-runner` full root permissions.
Learn more about the [security of the `docker` group](https://blog.zopyx.com/on-docker-security-docker-group-considered-harmful/).

### Use the Docker executor with the Docker image (Docker-in-Docker)

"Docker-in-Docker" (`dind`) means:

- Your registered runner uses the [Docker executor](https://docs.gitlab.com/runner/executors/docker.html).
- The executor uses a [container image of Docker](https://hub.docker.com/_/docker/), provided
  by Docker, to run your CI/CD jobs.

The Docker image has all of the `docker` tools installed and can run
the job script in context of the image in privileged mode.

We recommend you use [Docker-in-Docker with TLS enabled](#docker-in-docker-with-tls-enabled),
which is supported by [GitLab.com shared runners](../runners/index.md).

You should always specify a specific version of the image, like `docker:19.03.12`.
If you use a tag like `docker:stable`, you have no control over which version is used.
Unpredictable behavior can result, especially when new versions are released.

#### Limitations of Docker-in-Docker

Docker-in-Docker is the recommended configuration, but is
not without its own challenges:

- **The `docker-compose` command**: This command is not available in this configuration by default.
  To use `docker-compose` in your job scripts, follow the `docker-compose`
  [installation instructions](https://docs.docker.com/compose/install/).
- **Cache**: Each job runs in a new environment. Concurrent jobs work fine,
  because every build gets its own instance of Docker engine and they don't conflict with each other.
  However, jobs can be slower because there's no caching of layers.
- **Storage drivers**: By default, earlier versions of Docker use the `vfs` storage driver,
  which copies the file system for each job. Docker 17.09 and later use `--storage-driver overlay2`, which is
  the recommended storage driver. See [Using the OverlayFS driver](#use-the-overlayfs-driver) for details.
- **Root file system**: Because the `docker:19.03.12-dind` container and the runner container don't share their
  root file system, you can use the job's working directory as a mount point for
  child containers. For example, if you have files you want to share with a
  child container, you might create a subdirectory under `/builds/$CI_PROJECT_PATH`
  and use it as your mount point. For a more detailed explanation, view [issue
  #41227](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41227).

  ```yaml
  variables:
    MOUNT_POINT: /builds/$CI_PROJECT_PATH/mnt
  script:
    - mkdir -p "$MOUNT_POINT"
    - docker run -v "$MOUNT_POINT:/mnt" my-docker-image
  ```

#### Docker-in-Docker with TLS enabled

> Introduced in GitLab Runner 11.11.

The Docker daemon supports connections over TLS. In Docker 19.03.12 and later,
TLS is the default.

WARNING:
This task enables `--docker-privileged`. When you do this, you are effectively disabling all of
the security mechanisms of containers and exposing your host to privilege
escalation. Doing this can lead to container breakout. For more information,
see the official Docker documentation about
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
     --docker-image "docker:19.03.12" \
     --docker-privileged \
     --docker-volumes "/certs/client"
   ```

   - This command registers a new runner to use the `docker:19.03.12` image.
     To start the build and service containers, it uses the `privileged` mode.
     If you want to use [Docker-in-Docker](https://www.docker.com/blog/docker-can-now-run-within-docker/),
     you must always use `privileged = true` in your Docker containers.
   - This command mounts `/certs/client` for the service and build
     container, which is needed for the Docker client to use the
     certificates in that directory. For more information on how
     Docker with TLS works, see <https://hub.docker.com/_/docker/#tls>.

   The previous command creates a `config.toml` entry similar to this:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:19.03.12"
       privileged = true
       disable_cache = false
       volumes = ["/certs/client", "/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. You can now use `docker` in the job script. Note the inclusion of the
   `docker:19.03.12-dind` service:

   ```yaml
   image: docker:19.03.12

   variables:
     # When you use the dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket. Docker 19.03 does this automatically
     # by setting the DOCKER_HOST in
     # https://github.com/docker-library/docker/blob/d45051476babc297257df490d22cbd806f1b11e4/19.03/docker-entrypoint.sh#L23-L29
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ee/ci/docker/using_docker_images.html#accessing-the-services.
     #
     # Specify to Docker where to create the certificates. Docker
     # creates them automatically on boot, and creates
     # `/certs/client` to share between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"

   services:
     - docker:19.03.12-dind

   before_script:
     - docker info

   build:
     stage: build
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Docker-in-Docker with TLS enabled in Kubernetes

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

1. You can now use `docker` in the job script. Note the inclusion of the
   `docker:19.03.13-dind` service:

   ```yaml
   image: docker:19.03.13

   variables:
     # When using dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket.
     DOCKER_HOST: tcp://docker:2376
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ee/ci/docker/using_docker_images.html#accessing-the-services.
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
     - docker:19.03.13-dind

   before_script:
     - docker info

   build:
     stage: build
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Docker-in-Docker with TLS disabled

Sometimes you might have legitimate reasons to disable TLS.
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
    image = "docker:19.03.12"
    privileged = true
    disable_cache = false
    volumes = ["/cache"]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

You can now use `docker` in the job script. Note the inclusion of the
`docker:19.03.12-dind` service:

```yaml
image: docker:19.03.12

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
  - docker:19.03.12-dind

before_script:
  - docker info

build:
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

### Use Docker socket binding

To use Docker commands in your CI/CD jobs, you can bind-mount `/var/run/docker.sock` into the
container. Docker is then available in the context of the image.

NOTE:
If you bind the Docker socket and you are
[using GitLab Runner 11.11 or later](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1261),
you can no longer use `docker:19.03.12-dind` as a service. Volume bindings
are done to the services as well, making these incompatible.

To make Docker available in the context of the image:

1. Install [GitLab Runner](https://docs.gitlab.com/runner/install/).
1. From the command line, register a runner with the `docker` executor and share `/var/run/docker.sock`:

   ```shell
   sudo gitlab-runner register -n \
     --url https://gitlab.com/ \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --docker-image "docker:19.03.12" \
     --docker-volumes /var/run/docker.sock:/var/run/docker.sock
   ```

   This command registers a new runner to use the
   `docker:19.03.12` image provided by Docker. The command uses
   the Docker daemon of the runner itself. Any containers spawned by Docker
   commands are siblings of the runner rather than children of the runner.
   This may have complications and limitations that are unsuitable for your workflow.

   Your `config.toml` file should now have an entry like this:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = REGISTRATION_TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:19.03.12"
       privileged = false
       disable_cache = false
       volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
     [runners.cache]
       Insecure = false
   ```

1. Use `docker` in the job script. You don't need to
   include the `docker:19.03.12-dind` service, like you do when you're using
   the Docker-in-Docker executor:

   ```yaml
   image: docker:19.03.12

   before_script:
     - docker info

   build:
     stage: build
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

This method avoids using Docker in privileged mode. However,
the implications of this method are:

- By sharing the Docker daemon, you are effectively disabling all
  the security mechanisms of containers and exposing your host to privilege
  escalation, which can lead to container breakout. For example, if a project
  ran `docker rm -f $(docker ps -a -q)` it would remove the GitLab Runner
  containers.
- Concurrent jobs may not work; if your tests
  create containers with specific names, they may conflict with each other.
- Sharing files and directories from the source repository into containers may not
  work as expected. Volume mounting is done in the context of the host
  machine, not the build container. For example:

   ```shell
   docker run --rm -t -i -v $(pwd)/src:/home/app/src test-image:latest run_app_tests
   ```

#### Enable registry mirror for `docker:dind` service

When the Docker daemon starts inside of the service container, it uses
the default configuration. You may want to configure a [registry
mirror](https://docs.docker.com/registry/recipes/mirror/) for
performance improvements and to ensure you don't reach Docker Hub rate limits.

##### The service in the `.gitlab-ci.yml` file

You can append extra CLI flags to the `dind` service to set the registry
mirror:

```yaml
services:
  - name: docker:19.03.13-dind
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
      name = "docker:19.03.13-dind"
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
      name = "docker:19.03.13-dind"
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
`/etc/docker/daemon.json`. This would mount the file for **every**
container that is created by GitLab Runner. The configuration is
picked up by the `dind` service.

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
Make sure to use the namespace that the GitLab Runner Kubernetes executor uses
to create job pods in.

After the ConfigMap is created, you can update the `config.toml`
file to mount the file to `/etc/docker/daemon.json`. This update
mounts the file for **every** container that is created by GitLab Runner.
The configuration is picked up by the `dind` service.

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

## Authenticate with registry in Docker-in-Docker

When you use Docker-in-Docker, the
[standard authentication methods](using_docker_images.md#define-an-image-from-a-private-container-registry)
don't work because a fresh Docker daemon is started with the service.

### Option 1: Run `docker login`

In [`before_script`](../yaml/index.md#before_script), run `docker
login`:

```yaml
image: docker:19.03.13

variables:
  DOCKER_TLS_CERTDIR: "/certs"

services:
  - docker:19.03.13-dind

build:
  stage: build
  before_script:
    - echo "$DOCKER_REGISTRY_PASS" | docker login $DOCKER_REGISTRY --username $DOCKER_REGISTRY_USER --password-stdin
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

To log in to Docker Hub, leave `$DOCKER_REGISTRY`
empty or remove it.

### Option 2: Mount `~/.docker/config.json` on each job

If you are an administrator for GitLab Runner, you can mount a file
with the authentication configuration to `~/.docker/config.json`.
Then every job that the runner picks up is authenticated already. If you
are using the official `docker:19.03.13` image, the home directory is
under `/root`.

If you mount the configuration file, any `docker` command
that modifies the `~/.docker/config.json` fails. For example, `docker login`
fails, because the file is mounted as read-only. Do not change it from
read-only, because problems occur.

Here is an example of `/opt/.docker/config.json` that follows the
[`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data)
documentation:

```json
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
        }
    }
}
```

#### Docker

Update the
[volume mounts](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#volumes-in-the-runnersdocker-section)
to include the file.

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    volumes = ["/opt/.docker/config.json:/root/.docker/config.json:ro"]
```

#### Kubernetes

Create a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) with the content
of this file. You can do this with a command like:

```shell
kubectl create configmap docker-client-config --namespace gitlab-runner --from-file /opt/.docker/config.json
```

Update the [volume mounts](https://docs.gitlab.com/runner/executors/kubernetes.html#using-volumes)
to include the file.

```toml
[[runners]]
  ...
  executor = "kubernetes"
  [runners.kubernetes]
    image = "alpine:3.12"
    privileged = true
    [[runners.kubernetes.volumes.config_map]]
      name = "docker-client-config"
      mount_path = "/root/.docker/config.json"
      # If you are running GitLab Runner 13.5
      # or lower you can remove this
      sub_path = "config.json"
```

### Option 3: Use `DOCKER_AUTH_CONFIG`

If you already have
[`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data)
defined, you can use the variable and save it in
`~/.docker/config.json`.

There are multiple ways to define this authentication:

- In [`pre_build_script`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)
  in the runner configuration file.
- In [`before_script`](../yaml/index.md#before_script).
- In [`script`](../yaml/index.md#script).

The following example shows [`before_script`](../yaml/index.md#before_script).
The same commands apply for any solution you implement.

```yaml
image: docker:19.03.13

variables:
  DOCKER_TLS_CERTDIR: "/certs"

services:
  - docker:19.03.13-dind

build:
  stage: build
  before_script:
    - mkdir -p $HOME/.docker
    - echo $DOCKER_AUTH_CONFIG > $HOME/.docker/config.json
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

## Make Docker-in-Docker builds faster with Docker layer caching

When using Docker-in-Docker, Docker downloads all layers of your image every
time you create a build. Recent versions of Docker (Docker 1.13 and later) can
use a pre-existing image as a cache during the `docker build` step. This considerably
speeds up the build process.

### How Docker caching works

When running `docker build`, each command in `Dockerfile` results in a layer.
These layers are kept around as a cache and can be reused if there haven't been
any changes. Change in one layer causes all subsequent layers to be recreated.

You can specify a tagged image to be used as a cache source for the `docker build`
command by using the `--cache-from` argument. Multiple images can be specified
as a cache source by using multiple `--cache-from` arguments. Any image that's used
with the `--cache-from` argument must first be pulled
(using `docker pull`) before it can be used as a cache source.

### Docker caching example

Here's a `.gitlab-ci.yml` file that shows how to use Docker caching:

```yaml
image: docker:19.03.12

services:
  - docker:19.03.12-dind

variables:
  # Use TLS https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#tls-enabled
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_CERTDIR: "/certs"

before_script:
  - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

build:
  stage: build
  script:
    - docker pull $CI_REGISTRY_IMAGE:latest || true
    - docker build --cache-from $CI_REGISTRY_IMAGE:latest --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
```

In the `script` section for the `build` stage:

1. The first command tries to pull the image from the registry so that it can be
   used as a cache for the `docker build` command.
1. The second command builds a Docker image by using the pulled image as a
   cache (see the `--cache-from $CI_REGISTRY_IMAGE:latest` argument) if
   available, and tags it.
1. The last two commands push the tagged Docker images to the container registry
   so that they may also be used as cache for subsequent builds.

## Use the OverlayFS driver

NOTE:
The shared runners on GitLab.com use the `overlay2` driver by default.

By default, when using `docker:dind`, Docker uses the `vfs` storage driver which
copies the file system on every run. This is a disk-intensive operation
which can be avoided if a different driver is used, for example `overlay2`.

### Requirements

1. Make sure a recent kernel is used, preferably `>= 4.2`.
1. Check whether the `overlay` module is loaded:

   ```shell
   sudo lsmod | grep overlay
   ```

   If you see no result, then it isn't loaded. To load it use:

   ```shell
   sudo modprobe overlay
   ```

   If everything went fine, you need to make sure module is loaded on reboot.
   On Ubuntu systems, this is done by editing `/etc/modules`. Just add the
   following line into it:

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

If you're running multiple runners, you have to modify all configuration files.

Read more about the [runner configuration](https://docs.gitlab.com/runner/configuration/)
and [using the OverlayFS storage driver](https://docs.docker.com/engine/userguide/storagedriver/overlayfs-driver/).

## Use the GitLab Container Registry

After you've built a Docker image, you can push it up to the built-in
[GitLab Container Registry](../../user/packages/container_registry/index.md#build-and-push-by-using-gitlab-cicd).

## Troubleshooting

### `docker: Cannot connect to the Docker daemon at tcp://docker:2375. Is the docker daemon running?`

This is a common error when you are using
[Docker-in-Docker](#use-the-docker-executor-with-the-docker-image-docker-in-docker)
v19.03 or later.

This issue occurs because Docker starts on TLS automatically.

- If this is your first time setting it up, read
  [use the Docker executor with the Docker image](#use-the-docker-executor-with-the-docker-image-docker-in-docker).
- If you are upgrading from v18.09 or earlier, read our
  [upgrade guide](https://about.gitlab.com/blog/2019/07/31/docker-in-docker-with-docker-19-dot-03/).

### Docker `no such host` error

You may get an error that says
`docker: error during connect: Post https://docker:2376/v1.40/containers/create: dial tcp: lookup docker on x.x.x.x:53: no such host`.

This issue can occur when the service's image name
[includes a registry hostname](../../ci/services/index.md#available-settings-for-services). For example:

```yaml
image: docker:19.03.12

services:
  - registry.hub.docker.com/library/docker:19.03.12-dind
```

A service's hostname is [derived from the full image name](../../ci/services/index.md#accessing-the-services).
However, the shorter service hostname `docker` is expected.
To allow service resolution and access, add an explicit alias for the service name `docker`:

```yaml
image: docker:19.03.12

services:
  - name: registry.hub.docker.com/library/docker:19.03.12-dind
    alias: docker
```
