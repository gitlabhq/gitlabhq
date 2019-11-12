---
type: concepts, howto
---

# Building Docker images with GitLab CI/CD

GitLab CI/CD allows you to use Docker Engine to build and test docker-based projects.

One of the new trends in Continuous Integration/Deployment is to:

1. Create an application image.
1. Run tests against the created image.
1. Push image to a remote registry.
1. Deploy to a server from the pushed image.

It's also useful when your application already has the `Dockerfile` that can be
used to create and test an image:

```bash
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

   ```bash
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

   ```bash
   sudo usermod -aG docker gitlab-runner
   ```

1. Verify that `gitlab-runner` has access to Docker:

   ```bash
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

### Use docker-in-docker workflow with Docker executor

The second approach is to use the special docker-in-docker (dind)
[Docker image](https://hub.docker.com/_/docker/) with all tools installed
(`docker`) and run the job script in context of that
image in privileged mode.

NOTE: **Note:**
`docker-compose` is not part of docker-in-docker (dind). To use `docker-compose` in your
CI builds, follow the `docker-compose`
[installation instructions](https://docs.docker.com/compose/install/).

DANGER: **Danger:**
By enabling `--docker-privileged`, you are effectively disabling all of
the security mechanisms of containers and exposing your host to privilege
escalation which can lead to container breakout. For more information, check
out the official Docker documentation on
[Runtime privilege and Linux capabilities][docker-cap].

Docker-in-Docker works well, and is the recommended configuration, but it is
not without its own challenges:

- When using docker-in-docker, each job is in a clean environment without the past
  history. Concurrent jobs work fine because every build gets it's own
  instance of Docker engine so they won't conflict with each other. But this
  also means jobs can be slower because there's no caching of layers.
- By default, Docker 17.09 and higher uses `--storage-driver overlay2` which is
  the recommended storage driver. See [Using the overlayfs driver](#using-the-overlayfs-driver)
  for details.
- Since the `docker:19.03.1-dind` container and the Runner container don't share their
  root filesystem, the job's working directory can be used as a mount point for
  child containers. For example, if you have files you want to share with a
  child container, you may create a subdirectory under `/builds/$CI_PROJECT_PATH`
  and use it as your mount point (for a more thorough explanation, check [issue
  #41227](https://gitlab.com/gitlab-org/gitlab-foss/issues/41227)):

    ```yaml
    variables:
      MOUNT_POINT: /builds/$CI_PROJECT_PATH/mnt

    script:
      - mkdir -p "$MOUNT_POINT"
      - docker run -v "$MOUNT_POINT:/mnt" my-docker-image
    ```

An example project using this approach can be found here: <https://gitlab.com/gitlab-examples/docker>.

In the examples below, we are using Docker images tags to specify a
specific version, such as `docker:19.03.1`. If tags like `docker:stable`
are used, you have no control over what version is going to be used and this
can lead to unpredictable behavior, especially when new versions are
released.

#### TLS enabled

NOTE: **Note**
This requires GitLab Runner 11.11 or higher.

The Docker daemon supports connection over TLS and it's done by default
for Docker 19.03.1 or higher. This is the **suggested** way to use the
docker-in-docker service and
[GitLab.com Shared Runners](../../user/gitlab_com/index.html#shared-runners)
support this.

1. Install [GitLab Runner](https://docs.gitlab.com/runner/install/).

1. Register GitLab Runner from the command line to use `docker` and `privileged`
   mode:

   ```bash
   sudo gitlab-runner register -n \
     --url https://gitlab.com/ \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --docker-image "docker:19.03.1" \
     --docker-privileged \
     --docker-volumes "/certs/client"
   ```

   The above command will register a new Runner to use the special
   `docker:19.03.1` image, which is provided by Docker. **Notice that it's
   using the `privileged` mode to start the build and service
   containers.** If you want to use [docker-in-docker](https://www.docker.com/blog/docker-can-now-run-within-docker/) mode, you always
   have to use `privileged = true` in your Docker containers.

   This will also mount `/certs/client` for the service and build
   container, which is needed for the docker client to use the
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
       image = "docker:19.03.1"
       privileged = true
       disable_cache = false
       volumes = ["/certs/client", "/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
    ```

1. You can now use `docker` in the build script (note the inclusion of the
   `docker:19.03.1-dind` service):

   ```yaml
   image: docker:19.03.1

   variables:
     # When using dind service, we need to instruct docker, to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket. docker:19.03.1 does this automatically
     # by setting the DOCKER_HOST in
     # https://github.com/docker-library/docker/blob/d45051476babc297257df490d22cbd806f1b11e4/19.03.1/docker-entrypoint.sh#L23-L29
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ee/ci/docker/using_docker_images.html#accessing-the-services.
     #
     # Note that if you're using the Kubernetes executor, the variable
     # should be set to tcp://localhost:2376 because of how the
     # Kubernetes executor connects services to the job container
     # DOCKER_HOST: tcp://localhost:2376
     #
     # Specify to Docker where to create the certificates, Docker will
     # create them automatically on boot, and will create
     # `/certs/client` that will be shared between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"

   services:
     - docker:19.03.1-dind

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
    image = "docker:19.03.1"
    privileged = true
    disable_cache = false
    volumes = ["/cache"]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
```

You can now use `docker` in the build script (note the inclusion of the
`docker:19.03.1-dind` service):

```yaml
image: docker:19.03.1

variables:
  # When using dind service we need to instruct docker, to talk with the
  # daemon started inside of the service. The daemon is available with
  # a network connection instead of the default /var/run/docker.sock socket.
  #
  # The 'docker' hostname is the alias of the service container as described at
  # https://docs.gitlab.com/ee/ci/docker/using_docker_images.html#accessing-the-services
  #
  # Note that if you're using the Kubernetes executor, the variable should be set to
  # tcp://localhost:2375 because of how the Kubernetes executor connects services
  # to the job container
  # DOCKER_HOST: tcp://localhost:2375
  #
  # For non-Kubernetes executors, we use tcp://docker:2375
  DOCKER_HOST: tcp://docker:2375
  #
  # This will instruct Docker not to start over TLS.
  DOCKER_TLS_CERTDIR: ""

services:
  - docker:19.03.1-dind

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
newer](https://gitlab.com/gitlab-org/gitlab-runner/merge_requests/1261),
you can no longer use `docker:19.03.1-dind` as a service because volume bindings
are done to the services as well, making these incompatible.

In order to do that, follow the steps:

1. Install [GitLab Runner](https://docs.gitlab.com/runner/install/).

1. Register GitLab Runner from the command line to use `docker` and share `/var/run/docker.sock`:

   ```bash
   sudo gitlab-runner register -n \
     --url https://gitlab.com/ \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --docker-image "docker:19.03.1" \
     --docker-volumes /var/run/docker.sock:/var/run/docker.sock
   ```

   The above command will register a new Runner to use the special
   `docker:19.03.1` image which is provided by Docker. **Notice that it's using
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
       image = "docker:19.03.1"
       privileged = false
       disable_cache = false
       volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache"]
     [runners.cache]
       Insecure = false
   ```

1. You can now use `docker` in the build script (note that you don't need to
   include the `docker:19.03.1-dind` service as when using the Docker in Docker
   executor):

   ```yaml
   image: docker:19.03.1

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

- By sharing the docker daemon, you are effectively disabling all
  the security mechanisms of containers and exposing your host to privilege
  escalation which can lead to container breakout. For example, if a project
  ran `docker rm -f $(docker ps -a -q)` it would remove the GitLab Runner
  containers.
- Concurrent jobs may not work; if your tests
  create containers with specific names, they may conflict with each other.
- Sharing files and directories from the source repo into containers may not
  work as expected since volume mounting is done in the context of the host
  machine, not the build container. For example:

   ```sh
   docker run --rm -t -i -v $(pwd)/src:/home/app/src test-image:latest run_app_tests
   ```

## Making docker-in-docker builds faster with Docker layer caching

When using docker-in-docker, Docker will download all layers of your image every
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

Here's a simple `.gitlab-ci.yml` file showing how Docker caching can be utilized:

```yaml
image: docker:19.03.1

services:
  - docker:19.03.1-dind

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

## Using the OverlayFS driver

NOTE: **Note:**
The shared Runners on GitLab.com use the `overlay2` driver by default.

By default, when using `docker:dind`, Docker uses the `vfs` storage driver which
copies the filesystem on every run. This is a disk-intensive operation
which can be avoided if a different driver is used, for example `overlay2`.

### Requirements

1. Make sure a recent kernel is used, preferably `>= 4.2`.
1. Check whether the `overlay` module is loaded:

   ```sh
   sudo lsmod | grep overlay
   ```

   If you see no result, then it isn't loaded. To load it use:

   ```sh
   sudo modprobe overlay
   ```

   If everything went fine, you need to make sure module is loaded on reboot.
   On Ubuntu systems, this is done by editing `/etc/modules`. Just add the
   following line into it:

   ```text
   overlay
   ```

### Use driver per project

You can enable the driver for each project individually by editing the project's `.gitlab-ci.yml`:

```yaml
variables:
  DOCKER_DRIVER: overlay2
```

### Use driver for every project

To enable the driver for every project, you can set the environment variable for every build by adding `environment` in the `[[runners]]` section of `config.toml`:

```toml
environment = ["DOCKER_DRIVER=overlay2"]
```

If you're running multiple Runners you will have to modify all configuration files.

> **Notes:**
>
> - More information about the Runner configuration is available in the [Runner documentation](https://docs.gitlab.com/runner/configuration/).
> - For more information about using OverlayFS with Docker, you can read
>   [Use the OverlayFS storage driver](https://docs.docker.com/engine/userguide/storagedriver/overlayfs-driver/).

## Using the GitLab Container Registry

> **Notes:**
>
> - This feature requires GitLab 8.8 and GitLab Runner 1.2.
> - Starting from GitLab 8.12, if you have [2FA] enabled in your account, you need
>   to pass a [personal access token][pat] instead of your password in order to
>   login to GitLab's Container Registry.

Once you've built a Docker image, you can push it up to the built-in
[GitLab Container Registry](../../user/packages/container_registry/index.md).
Some things you should be aware of:

- You must [log in to the container registry](#authenticating-to-the-container-registry)
  before running commands. You can do this in the `before_script` if multiple
  jobs depend on it.
- Using `docker build --pull` fetches any changes to base
  images before building just in case your cache is stale. It takes slightly
  longer, but means you don’t get stuck without security patches to base images.
- Doing an explicit `docker pull` before each `docker run` fetches
  the latest image that was just built. This is especially important if you are
  using multiple runners that cache images locally. Using the Git SHA in your
  image tag makes this less necessary since each job will be unique and you
  shouldn't ever have a stale image. However, it's still possible to have a
  stale image if you re-build a given commit after a dependency has changed.
- You don't want to build directly to `latest` tag in case there are multiple jobs
  happening simultaneously.

### Authenticating to the Container Registry

There are three ways to authenticate to the Container Registry via GitLab CI/CD
and depend on the visibility of your project.

For all projects, mostly suitable for public ones:

- **Using the special `$CI_REGISTRY_USER` variable**: The user specified by this variable is created for you in order to
  push to the Registry connected to your project. Its password is automatically
  set with the `$CI_REGISTRY_PASSWORD` variable. This allows you to automate building and deploying
  your Docker images and has read/write access to the Registry. This is ephemeral,
  so it's only valid for one job. You can use the following example as-is:

  ```sh
  docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  ```

For private and internal projects:

- **Using a personal access token**: You can create and use a
  [personal access token](../../user/profile/personal_access_tokens.md)
  in case your project is private:

  - For read (pull) access, the scope should be `read_registry`.
  - For read/write (pull/push) access, use `api`.

  Replace the `<username>` and `<access_token>` in the following example:

  ```sh
  docker login -u <username> -p <access_token> $CI_REGISTRY
  ```

- **Using the GitLab Deploy Token**: You can create and use a
  [special deploy token](../../user/project/deploy_tokens/index.md#gitlab-deploy-token)
  with your private projects. It provides read-only (pull) access to the Registry.
  Once created, you can use the special environment variables, and GitLab CI/CD
  will fill them in for you. You can use the following example as-is:

  ```sh
  docker login -u $CI_DEPLOY_USER -p $CI_DEPLOY_PASSWORD $CI_REGISTRY
  ```

### Using docker-in-docker image from Container Registry

If you want to use your own Docker images for docker-in-docker there are a few things you need to do in addition to the steps in the [docker-in-docker](#use-docker-in-docker-workflow-with-docker-executor) section:

1. Update the `image` and `service` to point to your registry.
1. Add a service [alias](../yaml/README.md#servicesalias).

Below is an example of what your `.gitlab-ci.yml` should look like,
assuming you have it configured with [TLS enabled](#tls-enabled):

```yaml
 build:
   image: $CI_REGISTRY/group/project/docker:19.03.1
   services:
     - name: $CI_REGISTRY/group/project/docker:19.03.1-dind
       alias: docker
   variables:
     # Specify to Docker where to create the certificates, Docker will
     # create them automatically on boot, and will create
     # `/certs/client` that will be shared between the service and
     # build container.
     DOCKER_TLS_CERTDIR: "/certs"
   stage: build
   script:
     - docker build -t my-docker-image .
     - docker run my-docker-image /script/to/run/tests
```

If you forget to set the service alias, the `docker:19.03.1` image won't find the
`dind` service, and an error like the following is thrown:

```sh
$ docker info
error during connect: Get http://docker:2376/v1.39/info: dial tcp: lookup docker on 192.168.0.1:53: no such host
```

### Container Registry examples

If you're using docker-in-docker on your Runners, this is how your `.gitlab-ci.yml`
could look like:

```yaml
build:
  image: docker:19.03.1
  stage: build
  services:
    - docker:19.03.1-dind
  variables:
    # Use TLS https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#tls-enabled
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: "/certs"
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $CI_REGISTRY/group/project/image:latest .
    - docker push $CI_REGISTRY/group/project/image:latest
```

You can also make use of [other variables](../variables/README.md) to avoid hardcoding:

```yaml
build:
  image: docker:19.03.1
  stage: build
  services:
    - docker:19.03.1-dind
  variables:
    # Use TLS https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#tls-enabled
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: "/certs"
    IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
```

Here, `$CI_REGISTRY_IMAGE` would be resolved to the address of the registry tied
to this project. Since `$CI_COMMIT_REF_NAME` resolves to the branch or tag name,
and your branch-name can contain forward slashes (e.g., feature/my-feature), it is
safer to use `$CI_COMMIT_REF_SLUG` as the image tag. This is due to that image tags
cannot contain forward slashes. We also declare our own variable, `$IMAGE_TAG`,
combining the two to save us some typing in the `script` section.

Here's a more elaborate example that splits up the tasks into 4 pipeline stages,
including two tests that run in parallel. The `build` is stored in the container
registry and used by subsequent stages, downloading the image
when needed. Changes to `master` also get tagged as `latest` and deployed using
an application-specific deploy script:

```yaml
image: docker:19.03.1
services:
  - docker:19.03.1-dind

stages:
  - build
  - test
  - release
  - deploy

variables:
  # Use TLS https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#tls-enabled
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_CERTDIR: "/certs"
  CONTAINER_TEST_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  CONTAINER_RELEASE_IMAGE: $CI_REGISTRY_IMAGE:latest

before_script:
  - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

build:
  stage: build
  script:
    - docker build --pull -t $CONTAINER_TEST_IMAGE .
    - docker push $CONTAINER_TEST_IMAGE

test1:
  stage: test
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker run $CONTAINER_TEST_IMAGE /script/to/run/tests

test2:
  stage: test
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker run $CONTAINER_TEST_IMAGE /script/to/run/another/test

release-image:
  stage: release
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker tag $CONTAINER_TEST_IMAGE $CONTAINER_RELEASE_IMAGE
    - docker push $CONTAINER_RELEASE_IMAGE
  only:
    - master

deploy:
  stage: deploy
  script:
    - ./deploy.sh
  only:
    - master
```

NOTE: **Note:**
This example explicitly calls `docker pull`. If you prefer to implicitly pull the
built image using `image:`, and use either the [Docker](https://docs.gitlab.com/runner/executors/docker.html)
or [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes.html) executor,
make sure that [`pull_policy`](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work)
is set to `always`.

[docker-cap]: https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities
[2fa]: ../../user/profile/account/two_factor_authentication.md
[pat]: ../../user/profile/personal_access_tokens.md

## Troubleshooting

### docker: Cannot connect to the Docker daemon at tcp://docker:2375. Is the docker daemon running?

This is a common error when you are using
[Docker in Docker](#use-docker-in-docker-workflow-with-docker-executor)
v19.03 or higher.

This occurs because Docker starts on TLS automatically, so you need to do some set up.
If:

- This is the first time setting it up, carefully read
  [using Docker in Docker workflow](#use-docker-in-docker-workflow-with-docker-executor).
- You are upgrading from v18.09 or earlier, read our
  [upgrade guide](https://about.gitlab.com/blog/2019/07/31/docker-in-docker-with-docker-19-dot-03/).
