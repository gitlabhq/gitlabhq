---
stage: Application Security Testing
group: Composition Analysis
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'Tutorial: Scan a Docker container for vulnerabilities'
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use [container scanning](../../user/application_security/container_scanning/_index.md) to check for vulnerabilities
in container images stored in the [container registry](../../user/packages/container_registry/_index.md).

Container scanning configuration is added to the pipeline configuration of a project. In this tutorial, you:

1. Create a [new project](#create-a-new-project).
1. [Add a `Dockerfile`](#add-a-dockerfile-to-new-project) file to the project. This `Dockerfile` contains minimal
   configuration required to create a Docker image.
1. Create [pipeline configuration](#create-pipeline-configuration) for the new project to create a Docker
   image from the `Dockerfile`, build and push a Docker image to the container registry, and then scan the Docker image
   for vulnerabilities.
1. Check for [reported vulnerabilities](#check-for-reported-vulnerabilities).
1. [Update the Docker image](#update-the-docker-image) and scan the updated image.

## Create a new project

To create the new project

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create blank project**.
1. In **Project name**, enter `Tutorial container scanning project`.
1. In **Project URL**, select a namespace for the project.
1. Select **Create project**.

## Add a `Dockerfile` to new project

To provide something for container scanning to work on, create a `Dockerfile` with very minimal configuration:

1. In your `Tutorial container scanning project` project, select **{plus}** > **New file**.
1. Enter the filename `Dockerfile`, and provide the following contents for the file:

   ```Dockerfile
   FROM hello-world:latest
   ```

Docker images created from this `Dockerfile` are based on [`hello-world`](https://hub.docker.com/_/hello-world) Docker
image.

1. Select **Commit changes**.

## Create pipeline configuration

Now you're ready to create pipeline configuration. The pipeline configuration:

1. Builds a Docker image from the `Dockerfile` file, and pushes the Docker image to the container registry. The
   `build-image` job uses [Docker-in-Docker](../../ci/docker/using_docker_build.md) as a
   [CI/CD service](../../ci/services/_index.md) to build the Docker image. You can also
   [use kaniko](../../ci/docker/using_kaniko.md) to build Docker images in a pipeline.
1. Includes the `Container-Scanning.gitlab-ci.yml` template, to scan the Docker image stored in the container registry.

To create the pipeline configuration:

1. In the root directory of your project, select **{plus}** > **New file**.
1. Enter the filename `.gitlab-ci.yml`, and provide the following contents for the file:

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml

   container_scanning:
     variables:
       CS_IMAGE: $CI_REGISTRY_IMAGE/tutorial-image

   build-image:
     image: docker:24.0.2
     stage: build
     services:
       - docker:24.0.2-dind
     script:
       - docker build --tag $CI_REGISTRY_IMAGE/tutorial-image --file Dockerfile .
       - docker login --username gitlab-ci-token --password $CI_JOB_TOKEN $CI_REGISTRY
       - docker push $CI_REGISTRY_IMAGE/tutorial-image
   ```

1. Select **Commit changes**.

You're almost done. After you commit the file, a new pipeline starts with this configuration.
When it's finished, you can check the results of the scan.

## Check for reported vulnerabilities

Vulnerabilities for a scan are located on the pipeline that ran the scan. To check for reported vulnerabilities:

1. Select **CI/CD** > **Pipelines** and select the most recent pipeline. This pipeline should consist of a job called
   `container_scanning` in the `test` stage.
1. If the `container_scanning` job was successful, select the **Security** tab. If any vulnerabilities were found, they
   are listed on that page.

## Update the Docker image

A Docker image based on `hello-world:latest` is unlikely to show any vulnerabilities. For an example of a scan that
reports vulnerabilities:

1. In the root directory of your project, select the existing `Dockerfile` file.
1. Select **Edit**.
1. Replace `FROM hello-world:latest` with a different Docker image for the
   [`FROM`](https://docs.docker.com/reference/dockerfile/#from) instruction. The best Docker images to demonstrate
   container scanning have:
   - Operating system packages. For example, from Debian, Ubuntu, Alpine, or Red Hat.
   - Programming language packages. For example, NPM packages or Python packages.
1. Select **Commit changes**.

After you commit changes to the file, a new pipeline starts with this updated `Dockerfile`. When it's finished, you can
check the results of the new scan.
