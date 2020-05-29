---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: concepts, howto
---

# Building Docker images with GitLab CI/CD

GitLab CI/CD allows you to use Docker Engine to build and test Docker-based projects.

One of the new trends in Continuous Integration/Deployment is to:

1. Create an application image.
1. Run tests against the created image.
1. Push image to a remote registry.
1. Deploy to a server from the pushed image.

It's also useful when your application already has the `Dockerfile` that can be
used to create and test an image:

```shell
docker build -t my-image dockerfiles/
docker run my-image /script/to/run/tests
docker tag my-image my-registry:5000/my-image
docker push my-registry:5000/my-image
```

This requires special configuration of GitLab Runner to enable `docker` support
during jobs.

## Runner Configuration

There are three methods to enable the use of `docker build` and `docker run`
during jobs; each with their own tradeoffs.

An alternative to using `docker build` is to [use kaniko](using_kaniko.md).
This avoids having to execute Runner in privileged mode.

TIP: **Tip:**
To see how Docker and Runner are configured for shared Runners on
GitLab.com, see [GitLab.com Shared
Runners](../../user/gitlab_com/index.md#shared-runners).

### Use shell executor

The simplest approach is to install GitLab Runner in `shell` execution mode.
GitLab Runner then executes job scripts as the `gitlab-runner` user.

1. Install [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/#installation).

1. During GitLab Runner installation select `shell` as method of executing job scripts or use command:

   ```shell
   sudo gitlab-runner register -n \
     --url https://gitlab.com/ \
     --registration-token REGISTRATION_TOKEN \
     --executor shell \
     --description "My Runner"
   ```

1. Install Docker Engine on server.

   For more information how to install Docker Engine on different systems
   checkout the [Supported installations](https://docs.docker.com/engine/installation/).

1. Add `gitlab-runner` user to `docker` group:

   ```shell
   sudo usermod -aG docker gitlab-runner
   ```

1. Verify that `gitlab-runner` has access to Docker:

   ```shell
   sudo -u gitlab-runner -H docker info
   ```

   You can now verify that everything works by adding `docker info` to `.gitlab-ci.yml`:

   ```yaml
   before_script:
     - docker info

   build_image:
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

1. You can now use `docker` command (and **install** `docker-compose` if needed).

NOTE: **Note:**
By adding `gitlab-runner` to the `docker` group you are effectively granting `gitlab-runner` full root permissions.
For more information please read [On Docker security: `docker` group considered harmful](https://www.andreas-jung.com/contents/on-docker-security-docker-group-considered-harmful).

### Use Docker-in-Docker workflow with Docker executor

The second approach is to use the special Docker-in-Docker (dind)
[Docker image](https://hub.docker.com/_/docker/) with all tools installed
(`docker`) and run the job script in context of that
image in privileged mode.

NOTE: **Note:**
`docker-compose` is not part of Docker-in-Docker (dind). To use `docker-compose` in your
CI builds, follow the `docker-compose`
[installation instructions](https://docs.docker.com/compose/install/).

DANGER: **Danger:**
By enabling `--docker-privileged`, you are effectively disabling all of
the security mechanisms of containers and exposing your host to privilege
escalation which can lead to container breakout. For more information, check
out the official Docker documentation on
[Runtime privilege and Linux capabilities](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities).

Docker-in-Docker works well, and is the recommended configuration, but it is
not without its own challenges:

- When using Docker-in-Docker, each job is in a clean environment without the past
  history. Concurrent jobs work fine because every build gets its own
  instance of Docker engine so they won't conflict with each other. But this
  also means that jobs can be slower because there's no caching of layers.
- By default, Docker 17.09 and higher uses `--storage-driver overlay2` which is
  the recommended storage driver. See [Using the overlayfs driver](#use-the-overlayfs-driver)
  for details.
- Since the `docker:19.03.8-dind` container and the Runner container don't share their
  root filesystem, the job's working directory can be used as a mount point for
  child containers. For example, if you have files you want to share with a
  child container, you may create a subdirectory under `/builds/$CI_PROJECT_PATH`
  and use it as your mount point (for a more thorough explanation, check [issue
  #41227](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41227)):

  ```yaml
  variables:
    MOUNT_POINT: /builds/$CI_PROJECT_PATH/mnt

  script:
    - mkdir -p "$MOUNT_POINT"
    - docker run -v "$MOUNT_POINT:/mnt" my-docker-image
  ```

An example project using this approach can be found here: <https://gitlab.com/gitlab-examples/docker>.

In the examples below, we are using Docker images tags to specify a
specific version, such as `docker:19.03.8`. If tags like `docker:stable`
are used, you have no control over what version is going to be used and this
can lead to unpredictable behavior, especially when new versions are
released.

#### TLS enabled

NOTE: **Note**
Requires GitLab Runner 11.11 or later, but is not supported if GitLab
Runner is installed using the [Helm
chart](https://docs.gitlab.com/runner/install/kubernetes.html). See the
[related
issue](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/83) for
details.

The Docker daemon supports connection over TLS and it's done by default
for Docker 19.03.8 or higher. This is the **suggested** way to use the
Docker-in-Docker service and
[GitLab.com Shared Runners](../../user/gitlab_com/index.md#shared-runners)
support this.

1. Install [GitLab Runner](https://docs.gitlab.com/runner/install/).

1. Register GitLab Runner from the command line to use `docker` and `privileged`
   mode:

   ```shell
   sudo gitlab-runner register -n \
     --url https://gitlab.com/ \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --docker-image "docker:19.03.8" \
     --docker-privileged \
     --docker-volumes "/certs/client"
   ```

   The above command will register a new Runner to use the special
   `docker:19.03.8` image, which is provided by Docker. **Notice that it's
   using the `privileged` mode to start the build and service
   containers.** If you want to use [Docker-in-Docker](https://www.docker.com/blog/docker-can-now-run-within-docker/) mode, you always
   have to use `privileged = true` in your Docker containers.

   This will also mount `/certs/client` for the service and build
   container, which is needed for the Docker client to use the
   certificates inside of that directory. For more information how
   Docker with TLS works check <https://hub.docker.com/_/docker/#tls>.

   The above command will create a `config.toml` entry similar to this:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:19.03.8"
       privileged = true
       disable_cache = false
       volumes = ["/certs/client", "/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. You can now use `docker` in the build script (note the inclusion of the
   `docker:19.03.8-dind` service):

   ```yaml
   image: docker:19.03.8

   variables:
     # When using dind service, we need to instruct docker, to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket. Docker 19.03 does this automatically
     # by setting the DOCKER_HOST in
     # https://github.com/docker-library/docker/blob/d45051476babc297257df490d22cbd806f1b11e4/19.03/docker-entrypoint.sh#L23-L29
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ee/ci/docker/using_docker_images.html#accessing-the-services.
     #
     # Note that if you're using GitLab Runner 12.7 or earlier with the Kubernetes executor and Kubernetes 1.6 or earlier,
     # the variable must be set to tcp://localhost:2376 because of how the
     # Kubernetes executor connects services to the job container
     # DOCKER_HOST: tcp://localhost:2376
     #
     # Specify to Docker where to create the certificates, Docker will
     # create them automatically on boot, and will create
     # `/certs/client` that will be shared between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"

   services:
     - docker:19.03.8-dind

   before_script:
     - docker info

   build:
     stage: build
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

#### TLS disabled

Sometimes there are legitimate reasons why you might want to disable TLS.
For example, you have no control over the GitLab Runner configuration
that you are using.

Assuming that the Runner `config.toml` is similar to:

```toml
[[runners]]
  url = "https://gitlab.com/"
  token = TOKEN
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "docker:19.03.8"
    privileged = true
    disable_cache = false
    volumes = ["/cache"]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

You can now use `docker` in the build script (note the inclusion of the
`docker:19.03.8-dind` service):

```yaml
image: docker:19.03.8

variables:
  # When using dind service we need to instruct docker, to talk with the
  # daemon started inside of the service. The daemon is available with
  # a network connection instead of the default /var/run/docker.sock socket.
  #
  # The 'docker' hostname is the alias of the service container as described at
  # https://docs.gitlab.com/ee/ci/docker/using_docker_images.html#accessing-the-services
  #
  # Note that if you're using GitLab Runner 12.7 or earlier with the Kubernetes executor and Kubernetes 1.6 or earlier,
  # the variable must be set to tcp://localhost:2375 because of how the
  # Kubernetes executor connects services to the job container
  # DOCKER_HOST: tcp://localhost:2375
  #
  DOCKER_HOST: tcp://docker:2375
  #
  # This will instruct Docker not to start over TLS.
  DOCKER_TLS_CERTDIR: ""

services:
  - docker:19.03.8-dind

before_script:
  - docker info

build:
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

### Use Docker socket binding

The third approach is to bind-mount `/var/run/docker.sock` into the
container so that Docker is available in the context of that image.

NOTE: **Note:**
If you bind the Docker socket [when using GitLab Runner 11.11 or
newer](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1261),
you can no longer use `docker:19.03.8-dind` as a service because volume bindings
are done to the services as well, making these incompatible.

In order to do that, follow the steps:

1. Install [GitLab Runner](https://docs.gitlab.com/runner/install/).

1. Register GitLab Runner from the command line to use `docker` and share `/var/run/docker.sock`:

   ```shell
   sudo gitlab-runner register -n \
     --url https://gitlab.com/ \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --docker-image "docker:19.03.8" \
     --docker-volumes /var/run/docker.sock:/var/run/docker.sock
   ```

   The above command will register a new Runner to use the special
   `docker:19.03.8` image which is provided by Docker. **Notice that it's using
   the Docker daemon of the Runner itself, and any containers spawned by Docker
   commands will be siblings of the Runner rather than children of the Runner.**
   This may have complications and limitations that are unsuitable for your workflow.

   The above command will create a `config.toml` entry similar to this:

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = REGISTRATION_TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:19.03.8"
       privileged = false
       disable_cache = false
       volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
     [runners.cache]
       Insecure = false
   ```

1. You can now use `docker` in the build script (note that you don't need to
   include the `docker:19.03.8-dind` service as when using the Docker in Docker
   executor):

   ```yaml
   image: docker:19.03.8

   before_script:
     - docker info

   build:
     stage: build
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

While the above method avoids using Docker in privileged mode, you should be
aware of the following implications:

- By sharing the Docker daemon, you are effectively disabling all
  the security mechanisms of containers and exposing your host to privilege
  escalation which can lead to container breakout. For example, if a project
  ran `docker rm -f $(docker ps -a -q)` it would remove the GitLab Runner
  containers.
- Concurrent jobs may not work; if your tests
  create containers with specific names, they may conflict with each other.
- Sharing files and directories from the source repo into containers may not
  work as expected since volume mounting is done in the context of the host
  machine, not the build container. For example:

   ```shell
   docker run --rm -t -i -v $(pwd)/src:/home/app/src test-image:latest run_app_tests
   ```

## Making Docker-in-Docker builds faster with Docker layer caching

When using Docker-in-Docker, Docker will download all layers of your image every
time you create a build. Recent versions of Docker (Docker 1.13 and above) can
use a pre-existing image as a cache during the `docker build` step, considerably
speeding up the build process.

### How Docker caching works

When running `docker build`, each command in `Dockerfile` results in a layer.
These layers are kept around as a cache and can be reused if there haven't been
any changes. Change in one layer causes all subsequent layers to be recreated.

You can specify a tagged image to be used as a cache source for the `docker build`
command by using the `--cache-from` argument. Multiple images can be specified
as a cache source by using multiple `--cache-from` arguments. Keep in mind that
any image that's used with the `--cache-from` argument must first be pulled
(using `docker pull`) before it can be used as a cache source.

### Using Docker caching

Here's a `.gitlab-ci.yml` file showing how Docker caching can be used:

```yaml
image: docker:19.03.8

services:
  - docker:19.03.8-dind

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

The steps in the `script` section for the `build` stage can be summed up to:

1. The first command tries to pull the image from the registry so that it can be
   used as a cache for the `docker build` command.
1. The second command builds a Docker image using the pulled image as a
   cache (notice the `--cache-from $CI_REGISTRY_IMAGE:latest` argument) if
   available, and tags it.
1. The last two commands push the tagged Docker images to the container registry
   so that they may also be used as cache for subsequent builds.

## Use the OverlayFS driver

NOTE: **Note:**
The shared Runners on GitLab.com use the `overlay2` driver by default.

By default, when using `docker:dind`, Docker uses the `vfs` storage driver which
copies the filesystem on every run. This is a disk-intensive operation
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
environment [variable](../yaml/README.md#variables) in `.gitlab-ci.yml`:

```yaml
variables:
  DOCKER_DRIVER: overlay2
```

### Use the OverlayFS driver for every project

If you use your own [GitLab Runners](https://docs.gitlab.com/runner/), you
can enable the driver for every project by setting the `DOCKER_DRIVER`
environment variable in the
[`[[runners]]` section of `config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section):

```toml
environment = ["DOCKER_DRIVER=overlay2"]
```

If you're running multiple Runners you will have to modify all configuration files.

NOTE: **Note:**
Read more about the [Runner configuration](https://docs.gitlab.com/runner/configuration/)
and [using the OverlayFS storage driver](https://docs.docker.com/engine/userguide/storagedriver/overlayfs-driver/).

## Using the GitLab Container Registry

Once you've built a Docker image, you can push it up to the built-in
[GitLab Container Registry](../../user/packages/container_registry/index.md#build-and-push-images-using-gitlab-cicd).

## Troubleshooting

### `docker: Cannot connect to the Docker daemon at tcp://docker:2375. Is the docker daemon running?`

This is a common error when you are using
[Docker in Docker](#use-docker-in-docker-workflow-with-docker-executor)
v19.03 or higher.

This occurs because Docker starts on TLS automatically, so you need to do some set up.
If:

- This is the first time setting it up, carefully read
  [using Docker in Docker workflow](#use-docker-in-docker-workflow-with-docker-executor).
- You are upgrading from v18.09 or earlier, read our
  [upgrade guide](https://about.gitlab.com/releases/2019/07/31/docker-in-docker-with-docker-19-dot-03/).
