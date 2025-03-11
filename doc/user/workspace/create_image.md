---
stage: Create
group: Remote Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Create a custom workspace image to support any workspace you create in GitLab.
title: 'Tutorial: Create a custom workspace image that supports arbitrary user IDs'
---

This tutorial guides you through creating a custom workspace image that supports arbitrary user IDs.
Once complete, you can use this custom image with any [workspace](_index.md) you create in GitLab.

To create a custom workspace image that supports arbitrary user IDs:

1. [Create a base Dockerfile](#create-a-base-dockerfile).
1. [Add support for arbitrary user IDs](#add-support-for-arbitrary-user-ids).
1. [Build the custom workspace image](#build-the-custom-workspace-image).
1. [Push the custom workspace image to the GitLab container registry](#push-the-custom-workspace-image-to-the-gitlab-container-registry).
1. [Use the custom workspace image in GitLab](#use-the-custom-workspace-image-in-gitlab).

## Before you begin

You need the following:

- A GitLab account with permission to create and push container images to the GitLab container
  registry.
- Docker installed on your local machine.

## Create a base Dockerfile

Let's start by creating a base Dockerfile for our container image. Use the Python
`3.11-slim-bullseye` image from Docker Hub as our starting point:

```Dockerfile
FROM python:3.11-slim-bullseye
```

Great! You've created the foundation for your custom workspace image. Next, add the code
that enables arbitrary user ID support.

## Add support for arbitrary user IDs

Next, you will add support for arbitrary user IDs to the base image.
This ensures your workspace runs in GitLab.

To add a new `gitlab-workspaces` user with an ID of `5001`, and assign them the necessary
directory permissions, add the following code to your Dockerfile:

```dockerfile
RUN useradd -l -u 5001 -G sudo -md /home/gitlab-workspaces -s /bin/bash -p gitlab-workspaces gitlab-workspaces

ENV HOME=/home/gitlab-workspaces

WORKDIR $HOME

RUN mkdir -p /home/gitlab-workspaces && chgrp -R 0 /home && chmod -R g=u /etc/passwd /etc/group /home

USER 5001
```

## Build the custom workspace image

With your Dockerfile complete, you're ready to build your custom workspace image:

1. Run the following command in the directory where you created the Dockerfile:

   ```shell
   docker build -t my-gitlab-workspace .
   ```

   This might take a few minutes depending on your internet connection and system speed.

1. After the build process completes, test the image locally:

   ```shell
   docker run -ti my-gitlab-workspace sh
   ```

You should now have permission to run commands as the `gitlab-workspaces` user. Perfect! Your image
is working locally. Next, you will make it available in GitLab.

## Push the custom workspace image to the GitLab container registry

Push your custom workspace image to the GitLab container registry for use in your projects:

1. Sign in to your GitLab account:

   ```shell
   docker login registry.gitlab.com
   ```

1. Tag the image with the GitLab container registry URL:

   ```shell
   docker tag my-gitlab-workspace registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
   ```

   Remember to replace `your-namespace` with your actual GitLab namespace.

1. Push the image to the GitLab container registry:

   ```shell
   docker push registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
   ```

   This upload might take a while depending on your internet connection speed.

Well done! Your custom workspace image is now safely stored in the GitLab container registry
and ready to use.

## Use the custom workspace image in GitLab

For the final step, you will configure your project to use your custom workspace image:

1. Update the container image in your project's `.devfile.yaml`:

   ```yaml
   schemaVersion: 2.2.0
   components:
     - name: tooling-container
       attributes:
         gl/inject-editor: true
       container:
         image: registry.gitlab.com/your-namespace/my-gitlab-workspace:latest
   ```

   Remember to replace `your-namespace` with your actual GitLab namespace.

Congratulations! You've successfully created and configured a custom workspace image that supports
arbitrary user IDs. You can now use this custom image with any [workspace](_index.md) you create
in GitLab.

## Related topics

- [Troubleshooting Workspaces](workspaces_troubleshooting.md)
