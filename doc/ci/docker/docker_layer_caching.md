---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page,
  see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Speed up Docker-in-Docker builds by caching image layers across pipeline runs
  with inline or registry cache backends.
title: Cache Docker layers in Docker-in-Docker builds
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When you use Docker-in-Docker, Docker downloads all layers of your image on every build.
Docker 1.13 and later can use a pre-existing image as a cache during the `docker build` step,
which significantly speeds up the build process.

When Docker runs `docker build`, each `Dockerfile` command creates a layer.
Docker retains these layers as a cache and reuses them if nothing has changed.
A change in one layer causes all subsequent layers to be rebuilt.
To use a tagged image as a cache source for `docker build`, pass the `--cache-from` argument.
To specify multiple cache sources, use `--cache-from` multiple times.

## Prerequisites

In Docker 27.0.1 and later, the default `docker` build driver only supports cache backends
when the `containerd` image store is enabled. Do one of the following:

- Enable the `containerd` image store in your Docker daemon configuration.
- Select a different build driver.

## Use inline caching

Use the `inline` cache backend with the default `docker build` command. It is the simplest way
to get started with caching. The cache is stored inside the image itself, with no separate
cache image required. For complex build flows or multi-stage builds, use
[registry caching](#use-registry-caching) instead.
For more information, see [inline caching options](https://docs.docker.com/build/cache/backends/inline/).

> [!note]
> The `--build-arg BUILDKIT_INLINE_CACHE=1` argument is required. It instructs Docker to embed
> cache metadata into the image so subsequent builds can use it as a cache source with
> `--cache-from`. Without this argument, caching silently fails.

To use inline caching in your pipeline:

1. Add the following `.gitlab-ci.yml` configuration to your project:

   ```yaml
   default:
     image: docker:27.4.1-cli
     services:
       - docker:27.4.1-dind
     before_script:
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

   variables:
     # Use TLS https://docs.gitlab.com/ci/docker/using_docker_build/#tls-enabled
     DOCKER_HOST: tcp://docker:2376
     DOCKER_TLS_CERTDIR: "/certs"

   build:
     stage: build
     script:
       - docker pull $CI_REGISTRY_IMAGE:latest || true
       - docker build --build-arg BUILDKIT_INLINE_CACHE=1 --cache-from $CI_REGISTRY_IMAGE:latest
         --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
       - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
       - docker push $CI_REGISTRY_IMAGE:latest
   ```

   In the `build` job `script`:

   - The first command tries to pull the image from the registry to use as a cache source.
     Any image used with `--cache-from` must be pulled with `docker pull` before it can be used.
   - The second command builds a Docker image using the pulled image as a cache
     (via `--cache-from $CI_REGISTRY_IMAGE:latest`), then tags it.
     The `--build-arg BUILDKIT_INLINE_CACHE=1` flag embeds the build cache into the image.
   - The last two commands push both tagged images to the container registry so they can be
     used as cache in future builds.

## Use registry caching

Use the `registry` cache backend with `docker buildx build` to store build cache in a dedicated
cache image, separate from your application image. This scales better than inline caching
for multi-stage builds and complex build flows.
For more information, see [cache backend options](https://docs.docker.com/build/cache/backends/).

To use registry caching in your pipeline:

1. Add the following `.gitlab-ci.yml` configuration to your project:

   ```yaml
   default:
     image: docker:27.4.1-cli
     services:
       - docker:27.4.1-dind
     before_script:
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

   variables:
     # Use TLS https://docs.gitlab.com/ci/docker/using_docker_build/#tls-enabled
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

   In the `build` job `script`:

   - The first two commands create and configure the `docker-container` BuildKit driver,
     which supports the `registry` cache backend.
   - The third command builds and pushes the Docker image. It reads from a dedicated cache
     image with `--cache-from`, and updates it with `--cache-to`. The `max` mode caches
     all intermediate layers.
