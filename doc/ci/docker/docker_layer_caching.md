---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Make Docker-in-Docker builds faster with Docker layer caching
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When using Docker-in-Docker, Docker downloads all layers of your image every
time you create a build. Recent versions of Docker (Docker 1.13 and later) can
use a pre-existing image as a cache during the `docker build` step. This significantly
accelerates the build process.

In Docker 27.0.1 and later, the default `docker` build driver only supports cache backends when the `containerd` image store is enabled.

To use Docker caching with Docker 27.0.1 and later, do one of the following:

- Enable the `containerd` image store in your Docker daemon configuration.
- Select a different build driver.

For more information, see [Cache storage backends](https://docs.docker.com/build/cache/backends/).

## How Docker caching works

When running `docker build`, each command in `Dockerfile` creates a layer.
These layers are retained as a cache and can be reused if there have been no changes. Change in one layer causes the recreation of all subsequent layers.

To specify a tagged image to be used as a cache source for the `docker build`
command, use the `--cache-from` argument. Multiple images can be specified
as a cache source by using multiple `--cache-from` arguments.

## Docker inline caching example

This example `.gitlab-ci.yml` file shows how to use Docker caching with
the `inline` cache backend with the default `docker build` command.

```yaml
default:
  image: docker:27.4.1
  services:
    - docker:27.4.1-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

variables:
  # Use TLS https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#tls-enabled
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  script:
    - docker pull $CI_REGISTRY_IMAGE:latest || true
    - docker build --build-arg BUILDKIT_INLINE_CACHE=1 --cache-from $CI_REGISTRY_IMAGE:latest --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
```

In the `script` section for the `build` job:

1. The first command tries to pull the image from the registry so that it can be
   used as a cache for the `docker build` command.
   Any image that's used with the `--cache-from` argument must be
   pulled (using `docker pull`) before it can be used as a cache
   source.
1. The second command builds a Docker image by using the pulled image as a
   cache (see the `--cache-from $CI_REGISTRY_IMAGE:latest` argument) if
   available, and tags it. The `--build-arg BUILDKIT_INLINE_CACHE=1` tells
   Docker to use [inline caching](https://docs.docker.com/build/cache/backends/inline/),
   which embeds the build cache into the image itself.
1. The last two commands push the tagged Docker images to the container registry
   so that they can also be used as cache for subsequent builds.

## Docker registry caching example

You can cache your Docker builds directly to a dedicated cache
image in the registry.

This example `.gitlab-ci.yml` file shows how to use Docker caching
with the `docker buildx build` command and the `registry` cache backend.
For more advanced caching options, see [Cache storage backends](https://docs.docker.com/build/cache/backends/).

```yaml
default:
  image: docker:27.4.1
  services:
    - docker:27.4.1-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

variables:
  # Use TLS https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#tls-enabled
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  script:
    - docker context create my-builder
    - docker buildx create my-builder --driver docker-container --use
    - docker buildx build --push -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      --cache-to type=registry,ref=$CI_REGISTRY_IMAGE/cache-image,mode=max
      --cache-from type=registry,ref=$CI_REGISTRY_IMAGE/cache-image .
```

The `build` job's `script`:

1. Creates and configures the `docker-container` BuildKit driver, which supports the `registry` cache backend.
1. Builds and pushes a Docker image using:

   - A dedicated cache image with `--cache-from type=registry,ref=$CI_REGISTRY_IMAGE/cache-image`.
   - Cache updates with `--cache-to type=registry,ref=$CI_REGISTRY_IMAGE/cache-image,mode=max`, where `max` mode caches intermediate layers.
