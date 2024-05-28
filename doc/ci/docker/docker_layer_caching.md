---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Make Docker-in-Docker builds faster with Docker layer caching

When using Docker-in-Docker, Docker downloads all layers of your image every
time you create a build. Recent versions of Docker (Docker 1.13 and later) can
use a pre-existing image as a cache during the `docker build` step. This significantly
accelerates the build process.

## How Docker caching works

When running `docker build`, each command in `Dockerfile` creates a layer.
These layers are retained as a cache and can be reused if there have been no changes. Change in one layer causes the recreation of all subsequent layers.

To specify a tagged image to be used as a cache source for the `docker build`
command, use the `--cache-from` argument. Multiple images can be specified
as a cache source by using multiple `--cache-from` arguments. Any image that's used
with the `--cache-from` argument must be pulled
(using `docker pull`) before it can be used as a cache source.

## Docker caching example

This example `.gitlab-ci.yml` file shows how to use Docker caching with
the `inline` cache backend with the default `docker build` command. For
more advanced caching options, see the [`docker buildx build` command and its cache options](https://docs.docker.com/build/cache/backends/).

```yaml
default:
  image: docker:24.0.5
  services:
    - docker:24.0.5-dind
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
1. The second command builds a Docker image by using the pulled image as a
   cache (see the `--cache-from $CI_REGISTRY_IMAGE:latest` argument) if
   available, and tags it. The `--build-arg BUILDKIT_INLINE_CACHE=1` tells
   Docker to use [inline caching](https://docs.docker.com/build/cache/backends/inline/),
   which embeds the build cache into the image itself.
1. The last two commands push the tagged Docker images to the container registry
   so that they can also be used as cache for subsequent builds.
