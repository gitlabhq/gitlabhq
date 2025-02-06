---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Reduce container registry data transfers
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Depending on the frequency with which images or tags are downloaded from the container registry,
data transfer can be quite high. This page offers several recommendations and tips for
reducing the amount of data you transfer with the container registry.

## Check data transfer use

Transfer usage is not available within the GitLab UI. [GitLab-#350905](https://gitlab.com/gitlab-org/gitlab/-/issues/350905)
is the epic tracking the work to surface this information.

## Determine image size

Use these tools and techniques to determine your image's size:

- [Skopeo](https://github.com/containers/skopeo):
  use the Skopeo `inspect` command to examine layer count and sizes through API calls. You can
  therefore inspect this data prior to running `docker pull IMAGE`.

- Docker in CI: examine and record the image size when using GitLab CI prior to pushing an image
  with Docker. For example:

  ```shell
  docker inspect "$CI_REGISTRY_IMAGE:$IMAGE_TAG" \
        | awk '/"Size": ([0-9]+)[,]?/{ printf "Final Image Size: %d\n", $2 }'
  ```

- [Dive](https://github.com/wagoodman/dive)
  is a tool for exploring a Docker image, layer contents, and discovering ways to reduce its size.

## Reduce image size

### Use a smaller base image

Consider using a smaller base image, such as [Alpine Linux](https://alpinelinux.org/).
An Alpine image is around 5 MB, which is several times smaller than popular base images such as
[Debian](https://hub.docker.com/_/debian).
If your application is distributed as a self-contained static binary, such as for Go applications,
you can also consider using the Docker [scratch](https://hub.docker.com/_/scratch/)
base image.

If you need to use a specific base image OS, look for `-slim` or `-minimal` variants, as this helps
to reduce the image size.

Also be mindful about the operating system packages you install on top of your base image. These can
add up to hundreds of megabytes. Try keeping the number of installed packages to the bare minimum.

[Multi-stage builds](#use-multi-stage-builds) can be a powerful ally in cleaning up transient build
dependencies.

You may also consider using tools such as these:

- [DockerSlim](https://github.com/docker-slim/docker-slim)
  provides a set of commands to reduce the size of your container images.
- [Distroless](https://github.com/GoogleContainerTools/distroless) images contain only your
  application and its runtime dependencies. They don't contain package managers, shells, or any
  other programs you would expect to find in a standard Linux distribution.

### Minimize layers

Every instruction in your Dockerfile leads to a new layer, which records the file system changes
applied during such an instruction. In general, more or larger layers lead to larger images. Try to
minimize the number of layers to install the packages in the Dockerfile. Otherwise, this may cause
each step in the build process to increase the image size.

There are multiple strategies to reduce the number and size of layers. For example, instead of using
a `RUN` command per operating system package that you want to install (which would lead to a layer
per package), you can install all the packages on a single `RUN` command to reduce the number of
steps in the build process and reduce the size of the image.

Another useful strategy is to ensure that you remove all transient build dependencies and disable or
empty the operating system package manager cache before and after installing a package.

When building your images, make sure you only copy the relevant files. For Docker, using a
[`.dockerignore`](https://docs.docker.com/reference/dockerfile/#dockerignore-file)
helps ensure that the build process ignores irrelevant files.

You can use other third-party tools to minify your images, such as [DockerSlim](https://github.com/docker-slim/docker-slim).
Be aware that if used improperly, such tools may remove dependencies that your application needs to
operate under certain conditions. Therefore, it's preferable to strive for smaller images during the
build process instead of trying to minify images afterward.

### Use multi-stage builds

With [multi-stage builds](https://docs.docker.com/build/building/multi-stage/),
you use multiple `FROM` statements in your Dockerfile. Each `FROM` instruction can use a different
base, and each begins a new build stage. You can selectively copy artifacts from one stage to
another, leaving behind everything you don't want in the final image. This is especially useful when
you need to install build dependencies, but you don't need them to be present in your final image.

## Use an image pull policy

When using the `docker` or `docker+machine` executors, you can set a [`pull_policy`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)
parameter in your runner `config.toml` that defines how the runner works when pulling Docker images.
To avoid transferring data when using large and rarely updated images, consider using the
`if-not-present` pull policy when pulling images from remote registries.

## Use Docker layer caching

When running `docker build`, each command in `Dockerfile` results in a layer. These layers are kept
as a cache and can be reused if there haven't been any changes. You can specify a tagged image to be
used as a cache source for the `docker build` command by using the `--cache-from` argument. Multiple
images can be specified as a cache source by using multiple `--cache-from` arguments. This can speed
up your builds and reduce the amount of data transferred. For more information, see the
[documentation on Docker layer caching](../../../ci/docker/using_docker_build.md#make-docker-in-docker-builds-faster-with-docker-layer-caching).

## Check automation frequency

We often create automation scripts bundled into container images to perform regular tasks on specific intervals.
You can reduce the frequency of those intervals in cases where the automation is pulling container images from
the GitLab Registry to a service outside of GitLab.com.

## Related issues

- You may want to rebuild your image when the base Docker image is updated. However, the
  [pipeline subscription limit is too low](https://gitlab.com/gitlab-org/gitlab/-/issues/225278)
  to leverage this feature. As a workaround, you can rebuild daily or multiple times per day.
  [GitLab-#225278](https://gitlab.com/gitlab-org/gitlab/-/issues/225278)
  proposes raising the limit to help with this workflow.
