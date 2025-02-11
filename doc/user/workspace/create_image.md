---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Create a custom workspace image to support any workspace you create in GitLab."
title: 'Tutorial: Create a custom workspace image that supports arbitrary user IDs'
---

In this tutorial, you'll learn how to create a custom workspace image that supports arbitrary user IDs.
You can then use this custom image with any [workspace](_index.md) you create in GitLab.

To create a custom workspace image that supports arbitrary user IDs, you'll:

1. [Create a base Dockerfile](#create-a-base-dockerfile).
1. [Add support for arbitrary user IDs](#add-support-for-arbitrary-user-ids).
1. [Build the custom workspace image](#build-the-custom-workspace-image).
1. [Push the custom workspace image to the GitLab container registry](#push-the-custom-workspace-image-to-the-gitlab-container-registry).
1. [Use the custom workspace image in GitLab](#use-the-custom-workspace-image-in-gitlab).

## Prerequisites

- A GitLab account with permission to create and push container images to the GitLab container registry
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

You should now have permission to run commands as the `gitlab-workspaces` user.

## Push the custom workspace image to the GitLab container registry

To push the custom workspace image to the GitLab container registry:

1. Sign in to your GitLab account:

   ```shell
   docker login registry.gitlab.com
   ```

1. Tag the image with the GitLab container registry URL:

   ```shell
   docker tag my-gitlab-workspace registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
   ```

1. Push the image to the GitLab container registry:

   ```shell
   docker push registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
   ```

Now that you've pushed the custom workspace image to the GitLab container registry, you can use the image in GitLab.

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

You're all set! You can now use this custom image with any [workspace](_index.md) you create in GitLab.

## Related topics

- [Troubleshooting Workspaces](workspaces_troubleshooting.md)
