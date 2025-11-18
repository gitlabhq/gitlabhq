---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Buildah to build multi-platform images
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use Buildah to build images for multiple CPU architectures. Multi-platform builds
create images that work across different hardware platforms, and Docker automatically
selects the appropriate image for each deployment target.

## Prerequisites

- A Dockerfile to build the image from
- (Optional) GitLab runners running on different CPU architectures

## Build multi-platform images

To build multi-platform images with Buildah:

1. Configure separate build jobs for each target architecture.
1. Create a manifest job that combines the architecture-specific images.
1. Configure the manifest job to push the combined manifest to your registry.

Running jobs on their respective architectures avoids performance issues from CPU instruction translation.
However, you can run both builds on a single architecture if needed. Building for non-native architecture may result in slower build times.

The following example uses two [GitLab-hosted runners on Linux](../../ci/runners/hosted_runners/linux.md):

- `saas-linux-small-arm64`
- `saas-linux-small-amd64`

```yaml
stages:
  - build

variables:
  STORAGE_DRIVER: vfs
  BUILDAH_FORMAT: docker
  FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE:latest"

default:
  image: quay.io/buildah/stable
  before_script:
    - echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY

build-amd64:
  stage: build
  tags:
    - saas-linux-small-amd64
  script:
    - buildah build --platform=linux/amd64 -t $CI_REGISTRY_IMAGE:amd64 .
    - buildah push $CI_REGISTRY_IMAGE:amd64

build-arm64:
  stage: build
  tags:
    - saas-linux-small-arm64
  script:
    - buildah build --platform=linux/arm64/v8 -t $CI_REGISTRY_IMAGE:arm64 .
    - buildah push $CI_REGISTRY_IMAGE:arm64

create_manifest:
  stage: build
  needs: ["build-arm64", "build-amd64"]
  tags:
    - saas-linux-small-amd64
  script:
    - buildah manifest create $FQ_IMAGE_NAME
    - buildah manifest add $FQ_IMAGE_NAME docker://$CI_REGISTRY_IMAGE:amd64
    - buildah manifest add $FQ_IMAGE_NAME docker://$CI_REGISTRY_IMAGE:arm64
    - buildah manifest push --all $FQ_IMAGE_NAME
```

This pipeline creates architecture-specific images tagged with `amd64` and `arm64`,
then combines them into a single manifest available under the `latest` tag.

## Troubleshooting

### Build fails with authentication errors

If you encounter registry authentication failures:

- Verify that `CI_REGISTRY_USER` and `CI_REGISTRY_PASSWORD` variables are available.
- Check that you have push permissions to the target registry.
- For external registries, ensure authentication credentials are correctly configured
  in your project's CI/CD variables.

### Multi-platform builds fail

For multi-platform build issues:

- Verify that base images in your `Dockerfile` support the target architectures.
- Check that architecture-specific dependencies are available for all target platforms.
- Consider using conditional statements in your `Dockerfile` for architecture-specific logic.

### Error: `Error during unshare(CLONE_NEWUSER): Operation not permitted`

When you use Buildah or [Docker BuildKit](using_buildkit.md) in rootless mode to build Docker images in CI/CD jobs,
you might encounter an `Error during unshare(CLONE_NEWUSER): Operation not permitted`.

This error occurs when the required security options are not set for rootless container builds.

To resolve this issue, configure the `[runners.docker]` section in the runner's `config.toml` file:

```toml
[runners.docker]
  security_opt = ["seccomp:unconfined", "apparmor:unconfined"]
```

For more information, see [BuildKit rootless Docker builds and security requirements](https://github.com/moby/buildkit/blob/master/docs/rootless.md#docker).
