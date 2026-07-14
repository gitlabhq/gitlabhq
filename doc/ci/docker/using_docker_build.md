---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Use Docker to build Docker images
description: Build and push container images in GitLab CI/CD using the shell executor, Docker-in-Docker, socket binding, or pipe binding.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can use GitLab CI/CD with Docker to build, test, and push container images.
To run Docker commands in CI/CD jobs, you must configure GitLab Runner to
support `docker` commands.

The approach you choose depends on your infrastructure, executor type, and
security requirements. Some approaches require `privileged` mode on the runner.
If you cannot enable `privileged` mode, use a
[Docker alternative](#docker-alternatives).

| Approach                                            | Executor           | Privileged mode | OS      |
|-----------------------------------------------------|--------------------|-----------------|---------|
| [Shell executor](#use-the-shell-executor)           | Shell              | No              | Linux   |
| [Docker-in-Docker](docker_in_docker.md)             | Docker, Kubernetes | Yes             | Linux   |
| [Docker socket binding](#use-docker-socket-binding) | Docker, Kubernetes | No              | Linux   |
| [Docker pipe binding](#use-docker-pipe-binding)     | Docker, Kubernetes | No              | Windows |

## Use the shell executor

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

## Use Docker-in-Docker

Docker-in-Docker (`dind`) means your registered runner uses the
[Docker executor](https://docs.gitlab.com/runner/executors/docker/) or the
[Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/), and the
executor uses a [container image of Docker](https://hub.docker.com/_/docker/) to run
your CI/CD jobs.

Each job gets its own isolated Docker daemon, so concurrent jobs do not conflict.
This is the recommended approach when your runner supports `privileged` mode.

For setup instructions, see [Use Docker-in-Docker](docker_in_docker.md).

## Use Docker socket binding

To use Docker commands in your CI/CD jobs, you can bind-mount `/var/run/docker.sock` into the
build container. Docker is then available in the context of the image.

If you bind the Docker socket you can't use `docker:24.0.5-dind` as a service. Volume bindings also affect services,
making them incompatible.

### Use the Docker executor with Docker socket binding

To mount the Docker socket with the Docker executor, add `"/var/run/docker.sock:/var/run/docker.sock"` to the
[Volumes in the `[runners.docker]` section](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section).

1. To mount `/var/run/docker.sock` while registering your runner, include the following options:

   ```shell
   sudo gitlab-runner register \
     --non-interactive \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor "docker" \
     --description "docker-runner" \
     --tag-list "socket-binding-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
   ```

   The previous command creates a `config.toml` entry similar to the following example:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = RUNNER_TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = false
       disable_cache = false
       volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
     [runners.cache]
       Insecure = false
   ```

1. Use Docker in the job script:

   ```yaml
   default:
     image: docker:24.0.5-cli
     before_script:
       - docker info

   build:
     stage: build
     tags:
       - socket-binding-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Use the Kubernetes executor with Docker socket binding

To mount the Docker socket with the Kubernetes executor, add `"/var/run/docker.sock"` to the
[Volumes in the `[[runners.kubernetes.volumes.host_path]]` section](https://docs.gitlab.com/runner/executors/kubernetes/index/#hostpath-volume).

1. To specify a volume mount, update the
   [`values.yml` file](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)
   by using [Helm chart](https://docs.gitlab.com/runner/install/kubernetes/).

   ```yaml
   runners:
     tags: "socket-binding-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = false
         [runners.kubernetes]
           [[runners.kubernetes.volumes.host_path]]
             host_path = '/var/run/docker.sock'
             mount_path = '/var/run/docker.sock'
             name = 'docker-sock'
             read_only = true
   ```

1. Use Docker in the job script:

   ```yaml
   default:
     image: docker:24.0.5-cli
     before_script:
       - docker info
   build:
     stage: build
     tags:
       - socket-binding-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Known issues with Docker socket binding

When you use Docker socket binding, you avoid running Docker in privileged mode. However,
the implications of this method are:

- When you share the Docker daemon, you effectively disable
  the container's security mechanisms and expose your host to privilege
  escalation. This can cause container breakout. For example, if you run
  `docker rm -f $(docker ps -a -q)` in a project, it removes the GitLab Runner
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
  image: docker:24.0.5-cli
  before_script:
    - docker info

build:
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

For complex Docker-in-Docker setups like [Code Quality scanning using CodeClimate](../testing/code_quality_codeclimate_scanning.md), you must match host and container paths for proper execution. For more details, see
[Use private runners for CodeClimate-based scanning](../testing/code_quality_codeclimate_scanning.md#use-private-runners).

## Use Docker pipe binding

Windows Containers run Windows executables compiled for the Windows Server kernel and userland
(either windowsservercore or nanoserver). To build and run Windows containers, a Windows system
with container support is required.
For more information, see [Windows Containers](https://learn.microsoft.com/en-us/virtualization/windowscontainers/).

Because Windows containers do [not support the Docker-in-Docker](https://github.com/docker-library/docker/issues/49)
approach, you cannot run a nested Docker Engine inside a container.
To build or manage Docker images from within a Windows container, use
Docker pipe binding (also known as Docker-outside-of-Docker or DooD).

> [!warning]
> Docker pipe binding has security implications. When you bind-mount `\\\\.\\pipe\\docker_engine`,
> the container has full administrative access to the host's Docker daemon. Processes inside the
> container can start or stop other containers, manage images, and potentially gain elevated
> privileges on the host system.

To use Docker pipe binding, you must install and run a Docker Engine on the host Windows Server operating system.
For more information, see [Install Docker Community Edition (CE) on Windows Server](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-1).

To use Docker commands in your Windows-based container CI/CD jobs, you can bind-mount `\\\\.\\pipe\\docker_engine`
into the launched executor container. Docker is then available in the context of the image.

The [Docker pipe binding in Windows](#use-docker-pipe-binding) is similar to
[Docker socket binding in Linux](#use-docker-socket-binding) and have similar
[Known issues](#known-issues-with-docker-pipe-binding) as
[Known issues with Docker socket binding](#known-issues-with-docker-socket-binding).

A mandatory prerequisite for usage of Docker pipe binding is a Docker Engine installed and
running on the host Windows Server operating system.
See: [Install Docker Community Edition (CE) on Windows Server](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-2)

### Use the Docker executor with Docker pipe binding

You can use the [Docker executor](https://docs.gitlab.com/runner/executors/docker/) to run jobs in a Windows-based container.

To mount the Docker pipe with the Docker executor, add `"\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"` to the
[Volumes in the `[runners.docker]` section](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section).

1. To mount `\\\\.\\pipe\\docker_engine` while registering your runner, include the following options:

   ```powershell
   .\gitlab-runner.exe register \
     --non-interactive \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor "docker-windows" \
     --description "docker-windows-runner"
     --tag-list "docker-windows-runner" \
     --docker-image "docker:25-windowsservercore-ltsc2022" \
     --docker-volumes "\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"
   ```

   The previous command creates a `config.toml` entry similar to the following example:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = RUNNER_TOKEN
     executor = "docker-windows"
     [runners.docker]
       tls_verify = false
       image = "docker:25-windowsservercore-ltsc2022"
       privileged = false
       disable_cache = false
       volumes = ["\\\\.\\pipe\\docker_engine:\\\\.\\pipe\\docker_engine"]
   ```

1. Use Docker in the job script:

   ```yaml
   default:
     image: docker:25-windowsservercore-ltsc2022
     before_script:
       - docker version
       - docker info

   build:
     stage: build
     tags:
       - docker-windows-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Use the Kubernetes executor with Docker pipe binding

You can use the [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/) to run jobs in a Windows-based container.

To use Kubernetes executor for Windows-based containers, you must include Windows nodes in your Kubernetes cluster.
For more information, see [Windows containers in Kubernetes](https://kubernetes.io/docs/concepts/windows/intro/).

You can use [Runner operating in a Linux environment but targeting Windows nodes](https://docs.gitlab.com/runner/executors/kubernetes/#example-for-windowsamd64)

To mount the Docker pipe with the Kubernetes executor, add `"\\.\pipe\docker_engine"` to the
[Volumes in the `[[runners.kubernetes.volumes.host_path]]` section](https://docs.gitlab.com/runner/executors/kubernetes/index/#hostpath-volume).

1. To specify a volume mount, update the
   [`values.yml` file](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)
   by using [Helm chart](https://docs.gitlab.com/runner/install/kubernetes/).

   ```yaml
   runners:
     tags: "kubernetes-windows-runner"
     config: |
       [[runners]]
         executor = "kubernetes"

         # The FF_USE_POWERSHELL_PATH_RESOLVER feature flag has to be enabled for PowerShell
         # to resolve paths for Windows correctly when Runner is operating in a Linux environment
         # but targeting Windows nodes.
         [runners.feature_flags]
           FF_USE_POWERSHELL_PATH_RESOLVER = true

         [runners.kubernetes]
           [[runners.kubernetes.volumes.host_path]]
             host_path = '\\\\.\\pipe\\docker_engine'
             mount_path = '\\\\.\\pipe\\docker_engine'
             name = 'docker-pipe'
             read_only = true

           [runners.kubernetes.node_selector]
             "kubernetes.io/arch" = "amd64"
             "kubernetes.io/os" = "windows"
             "node.kubernetes.io/windows-build" = "10.0.20348"
   ```

1. Use Docker in the job script:

   ```yaml
   default:
     image: docker:25-windowsservercore-ltsc2022
     before_script:
       - docker version
       - docker info

   build:
     stage: build
     tags:
       - kubernetes-windows-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### Known issues with AWS EKS Kubernetes cluster

When you migrate from `dockerd` to `containerd`, the AWS EKS bootstrapping script `Start-EKSBootstrap.ps1`
stops and disables the Docker Service. To work around this issue, rename the Docker Service after you
[Install Docker Community Edition (CE) on Windows Server](https://learn.microsoft.com/en-us/virtualization/windowscontainers/quick-start/set-up-environment?tabs=dockerce#windows-server-1) with this script:

```powershell
Write-Output "Rename the just installed Docker Engine Service from docker to dockerd"
Write-Output "because the Start-EKSBootstrap.ps1 stops and disables the docker Service as part of migration from dockerd to containerd"
Stop-Service -Name docker
dockerd --register-service --service-name dockerd
Start-Service -Name dockerd
Write-Output "Ready to do Docker pipe binding on Windows EKS Node! :-)"
```

### Known issues with Docker pipe binding

Docker pipe binding has the same set of security and isolation issues as the [Known issues with Docker socket binding](#known-issues-with-docker-socket-binding).

## Enable registry mirror for `docker:dind` service

When the Docker daemon starts inside the service container, it uses
the default configuration. You might want to configure a
[registry mirror](https://docs.docker.com/docker-hub/mirror/) for
performance improvements and to ensure you do not exceed Docker Hub rate limits.

### The service in the `.gitlab-ci.yml` file

You can append extra CLI flags to the `dind` service to set the registry
mirror:

```yaml
services:
  - name: docker:24.0.5-dind
    command: ["--registry-mirror", "https://registry-mirror.example.com"]  # Specify the registry mirror to use
```

### The service in the GitLab Runner configuration file

If you are a GitLab Runner administrator, you can specify the `command` to configure the registry mirror
for the Docker daemon. The `dind` service must be defined for the
[Docker](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runnersdockerservices-section)
or [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/#define-a-list-of-services).

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

### The Docker executor in the GitLab Runner configuration file

If you are a GitLab Runner administrator, you can use
the mirror for every `dind` service. Update the
[configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/)
to specify a [volume mount](https://docs.gitlab.com/runner/configuration/advanced-configuration/#volumes-in-the-runnersdocker-section).

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

### The Kubernetes executor in the GitLab Runner configuration file

If you are a GitLab Runner administrator, you can use
the mirror for every `dind` service. Update the
[configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/)
to specify a [ConfigMap volume mount](https://docs.gitlab.com/runner/executors/kubernetes/#configmap-volume).

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

> [!note]
> You must use the namespace that the Kubernetes executor for GitLab Runner uses to create job pods.

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

## Authenticate with registry in Docker-in-Docker

When you use Docker-in-Docker, the [standard authentication methods](using_docker_images.md#access-an-image-from-a-private-container-registry) do not work, because a fresh Docker daemon is started with the service. You should [authenticate with registry](authenticate_registry.md).

## Docker layer caching

You can cache Docker layers to speed up your builds.
For more information, see [Cache Docker layers in Docker-in-Docker builds](docker_layer_caching.md).

## Use the OverlayFS driver

> [!note]
> The instance runners on GitLab.com use the `overlay2` driver by default.

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
[`[[runners]]` section of the `config.toml` file](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section):

```toml
environment = ["DOCKER_DRIVER=overlay2"]
```

If you're running multiple runners, you must modify all configuration files.

Read more about the [runner configuration](https://docs.gitlab.com/runner/configuration/)
and [using the OverlayFS storage driver](https://docs.docker.com/engine/storage/drivers/overlayfs-driver/).

## Docker alternatives

You can build container images without enabling privileged mode on your runner:

- [BuildKit](using_buildkit.md): Includes rootless BuildKit options that eliminate Docker daemon dependency.
- [Buildah](#buildah-example): Build OCI-compliant images without requiring a Docker daemon.

### Buildah example

To use Buildah with GitLab CI/CD, you need [a runner](https://docs.gitlab.com/runner/) with one
of the following executors:

- [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/).
- [Docker](https://docs.gitlab.com/runner/executors/docker/).
- [Docker Machine](https://docs.gitlab.com/runner/executors/docker_machine/).

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

### `open //./pipe/docker_engine: The system cannot find the file specified`

The following error might appear when you run a `docker` command in the PowerShell script to access the mounted Docker pipe:

```powershell
PS C:\> docker version
Client:
 Version:           25.0.5
 API version:       1.44
 Go version:        go1.21.8
 Git commit:        5dc9bcc
 Built:             Tue Mar 19 15:06:12 2024
 OS/Arch:           windows/amd64
 Context:           default
error during connect: this error may indicate that the docker daemon is not running: Get "http://%2F%2F.%2Fpipe%2Fdocker_engine/v1.44/version": open //./pipe/docker_engine: The system cannot find the file specified.
```

The error indicates that the Docker Engine is not running on the Windows EKS Node and the Docker pipe binding could not be used in the Windows-based Executor container.

To solve the problem, use the workaround described in [Use the Kubernetes executor with Docker pipe binding](#use-the-kubernetes-executor-with-docker-pipe-binding).
