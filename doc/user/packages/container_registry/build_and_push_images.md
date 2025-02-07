---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Build and push container images to the container registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Before you can build and push container images, you must [authenticate](authenticate_with_container_registry.md) with the container registry.

## Use Docker commands

You can use Docker commands to build and push container images to your container registry:

1. [Authenticate](authenticate_with_container_registry.md) with the container registry.
1. Run the Docker command to build or push. For example:

   - To build:

     ```shell
     docker build -t registry.example.com/group/project/image .
     ```

   - To push:

     ```shell
     docker push registry.example.com/group/project/image
     ```

## Configure your `.gitlab-ci.yml` file

You can configure your `.gitlab-ci.yml` file to build and push container images to the container registry.

- If multiple jobs require authentication, put the authentication command in the `before_script`.
- Before building, use `docker build --pull` to fetch changes to base images. It takes slightly
  longer, but it ensures your image is up-to-date.
- Before each `docker run`, do an explicit `docker pull` to fetch
  the image that was just built. This step is especially important if you are
  using multiple runners that cache images locally.

  If you use the Git SHA in your image tag, each job is unique and you
  should never have a stale image. However, it's still possible to have a
  stale image if you rebuild a given commit after a dependency has changed.
- Don't build directly to the `latest` tag because multiple jobs may be
  happening simultaneously.

## Use GitLab CI/CD

You can use [GitLab CI/CD](../../../ci/_index.md) to build and push container images to the
Container Registry. You can use CI/CD to test, build, and deploy your project from the container
image you created.

### Use a Docker-in-Docker container image from your container registry

You can use your own container images for Docker-in-Docker.

1. Set up [Docker-in-Docker](../../../ci/docker/using_docker_build.md#use-docker-in-docker).
1. Update the `image` and `service` to point to your registry.
1. Add a service [alias](../../../ci/services/_index.md#available-settings-for-services).

Your `.gitlab-ci.yml` should look similar to this:

```yaml
build:
  image: $CI_REGISTRY/group/project/docker:20.10.16
  services:
    - name: $CI_REGISTRY/group/project/docker:20.10.16-dind
      alias: docker
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

If you forget to set the service alias, the container image can't find the `dind` service,
and an error like the following is shown:

```plaintext
error during connect: Get http://docker:2376/v1.39/info: dial tcp: lookup docker on 192.168.0.1:53: no such host
```

### Use a Docker-in-Docker container image with Dependency Proxy

You can use your own container images with Dependency Proxy.

1. Set up [Docker-in-Docker](../../../ci/docker/using_docker_build.md#use-docker-in-docker).
1. Update the `image` and `service` to point to your registry.
1. Add a service [alias](../../../ci/services/_index.md#available-settings-for-services).

Your `.gitlab-ci.yml` should look similar to this:

```yaml
build:
  image: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/docker:20.10.16
  services:
    - name: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/docker:18.09.7-dind
      alias: docker
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

If you forget to set the service alias, the container image can't find the `dind` service,
and an error like the following is shown:

```plaintext
error during connect: Get http://docker:2376/v1.39/info: dial tcp: lookup docker on 192.168.0.1:53: no such host
```

## Container registry examples with GitLab CI/CD

If you're using Docker-in-Docker on your runners, your `.gitlab-ci.yml` file should look similar to this:

```yaml
build:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin
    - docker build -t $CI_REGISTRY/group/project/image:latest .
    - docker push $CI_REGISTRY/group/project/image:latest
```

You can use [CI/CD variables](../../../ci/variables/_index.md) in your `.gitlab-ci.yml` file. For example:

```yaml
build:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  variables:
    IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
```

In this example, `$CI_REGISTRY_IMAGE` resolves to the address of the registry tied
to this project. `$CI_COMMIT_REF_NAME` resolves to the branch or tag name, which
can contain forward slashes. Image tags can't contain forward slashes. Use
`$CI_COMMIT_REF_SLUG` as the image tag. You can declare the variable, `$IMAGE_TAG`,
combining `$CI_REGISTRY_IMAGE` and `$CI_COMMIT_REF_NAME` to save some typing in the
`script` section.

This example splits the tasks into 4 pipeline stages, including two tests that run in parallel. The `build` is stored in the container
registry and used by subsequent stages, downloading the container image when needed. Changes to `main` also get tagged as
`latest` and deployed using an application-specific deploy script:

```yaml
default:
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  before_script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin

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
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy:
  stage: deploy
  script:
    - ./deploy.sh
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: production
```

NOTE:
This example explicitly calls `docker pull`. If you prefer to implicitly pull the container image using `image:`,
and use either the [Docker](https://docs.gitlab.com/runner/executors/docker.html) or [Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/index.html) executor,
make sure that [`pull_policy`](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work) is set to `always`.
