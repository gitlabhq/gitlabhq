---
stage: Create
group: IDE
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tutorial: Create a custom workspace image that supports arbitrary user IDs **(PREMIUM ALL BETA)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112397) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/391543) in GitLab 16.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, an administrator can [disable the feature flag](../../administration/feature_flags.md) named `remote_development_feature_flag`. On GitLab.com, this feature is available. The feature is not ready for production use.

WARNING:
This feature is in [Beta](../../policy/experiment-beta-support.md#beta) and subject to change without notice. To leave feedback, see the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/410031).

In this tutorial, you'll learn how to create a custom workspace image that supports arbitrary user IDs.
You can then use this custom image with any [workspace](index.md) you create in GitLab.

To create a custom workspace image that supports arbitrary user IDs, you'll:

1. [Create a base Dockerfile](#create-a-base-dockerfile).
1. [Add support for arbitrary user IDs](#add-support-for-arbitrary-user-ids).
1. [Build the custom workspace image](#build-the-custom-workspace-image).
1. [Push the custom workspace image to the GitLab Container Registry](#push-the-custom-workspace-image-to-the-gitlab-container-registry).
1. [Use the custom workspace image in GitLab](#use-the-custom-workspace-image-in-gitlab).

## Prerequisites

- A GitLab account with permission to create and push container images to the GitLab Container Registry
- Docker installation

## Create a base Dockerfile

To create a base Dockerfile for the container image, let's use the Python `3.11-slim-bullseye` image from Docker Hub:

```Dockerfile
FROM python:3.11-slim-bullseye
```

Next, you'll modify this base image.

## Add support for arbitrary user IDs

To add support for arbitrary user IDs to the base image, let's:

1. Add a new `gitlab-workspaces` user with a `5001` user ID.
1. Set the necessary directory permissions.

```Dockerfile
RUN useradd -l -u 5001 -G sudo -md /home/gitlab-workspaces -s /bin/bash -p gitlab-workspaces gitlab-workspaces

ENV HOME=/home/gitlab-workspaces

WORKDIR $HOME

RUN mkdir -p /home/gitlab-workspaces && chgrp -R 0 /home && chmod -R g=u /etc/passwd /etc/group /home

USER 5001
```

Now that the image supports arbitrary user IDs, it's time to build the custom workspace image.

## Build the custom workspace image

To build the custom workspace image, run this command:

```shell
docker build -t my-gitlab-workspace .
```

When the build is complete, you can test the image locally:

```shell
docker run -ti my-gitlab-workspace sh
```

You should now be able to run commands as the `gitlab-workspaces` user.

## Push the custom workspace image to the GitLab Container Registry

To push the custom workspace image to the GitLab Container Registry:

1. Sign in to your GitLab account:

   ```shell
   docker login registry.gitlab.com
   ```

1. Tag the image with the GitLab Container Registry URL:

   ```shell
   docker tag my-gitlab-workspace registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
   ```

1. Push the image to the GitLab Container Registry:

   ```shell
   docker push registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
   ```

Now that you've pushed the custom workspace image to the GitLab Container Registry, you can use the image in GitLab.

## Use the custom workspace image in GitLab

To use the custom workspace image in GitLab, in your project's `.devfile.yaml`, update the container image:

```yaml
schemaVersion: 2.2.0
components:
  - name: tooling-container
    attributes:
      gl/inject-editor: true
    container:
      image: registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
```

You're all set! You can now use this custom image with any [workspace](index.md) you create in GitLab.
