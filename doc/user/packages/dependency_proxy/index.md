---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Dependency Proxy

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7934) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.11.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/273655) to [GitLab Core](https://about.gitlab.com/pricing/) in GitLab 13.6.
> - [Support for private groups](https://gitlab.com/gitlab-org/gitlab/-/issues/11582) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.7.
> - Anonymous access to images in public groups is no longer available starting in [GitLab Premium](https://about.gitlab.com/pricing/) 13.7.

The GitLab Dependency Proxy is a local proxy you can use for your frequently-accessed
upstream images.

In the case of CI/CD, the Dependency Proxy receives a request and returns the
upstream image from a registry, acting as a pull-through cache.

## Prerequisites

The Dependency Proxy must be [enabled by an administrator](../../../administration/packages/dependency_proxy.md).

### Supported images and packages

The following images and packages are supported.

| Image/Package    | GitLab version |
| ---------------- | -------------- |
| Docker           | 11.11+         |

For a list of planned additions, view the
[direction page](https://about.gitlab.com/direction/package/dependency_proxy/#top-vision-items).

## Enable the Dependency Proxy

The Dependency Proxy is disabled by default.
[Learn how an administrator can enable it](../../../administration/packages/dependency_proxy.md).

## View the Dependency Proxy

To view the Dependency Proxy:

- Go to your group's **Packages & Registries > Dependency Proxy**.

The Dependency Proxy is not available for projects.

## Use the Dependency Proxy for Docker images

CAUTION: **Important:**
In some specific storage configurations, an issue occurs and container images are not pulled correctly from the cache. The problem occurs when an image is located in object storage. The proxy looks for it locally and fails to find it. View [issue #208080](https://gitlab.com/gitlab-org/gitlab/-/issues/208080) for details.

You can use GitLab as a source for your Docker images.

Prerequisites:

- Your images must be stored on [Docker Hub](https://hub.docker.com/).
- Docker Hub must be available. Follow [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/241639)
  for progress on accessing images when Docker Hub is down.

### Authenticate with the Dependency Proxy

Because the Dependency Proxy is storing Docker images in a space associated with your group,
you must authenticate against the Dependency Proxy.

Follow the [instructions for using images from a private registry](../../../ci/docker/using_docker_images.md#define-an-image-from-a-private-container-registry),
but instead of using `registry.example.com:5000`, use your GitLab domain with no port `gitlab.example.com`.

For example, to manually log in:

```shell
docker login gitlab.example.com --username my_username --password my_password
```

You can authenticate using:

- Your GitLab username and password.
- A [personal access token](../../../user/profile/personal_access_tokens.md) with the scope set to `read_registry` and `write_registry`.

#### Authenticate within CI/CD

To work with the Dependency Proxy in [GitLab CI/CD](../../../ci/README.md), you can use
`CI_REGISTRY_USER` and `CI_REGISTRY_PASSWORD`.

```shell
docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" gitlab.example.com
```

You can use other [predefined variables](../../../ci/variables/predefined_variables.md)
to further generalize your CI script. For example:

```yaml
# .gitlab-ci.yml

dependency-proxy-pull-master:
  # Official docker image.
  image: docker:latest
  stage: build
  services:
    - docker:dind
  before_script:
    - docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_SERVER_HOST":"$CI_SERVER_PORT"
  script:
    - docker pull "$CI_SERVER_HOST":"$CI_SERVER_PORT"/groupname/dependency_proxy/containers/alpine:latest
```

You can also use [custom environment variables](../../../ci/variables/README.md#custom-environment-variables) to store and access your personal access token or other valid credentials.

### Store a Docker image in Dependency Proxy cache

To store a Docker image in Dependency Proxy storage:

1. Go to your group's **Packages & Registries > Dependency Proxy**.
1. Copy the **Dependency Proxy URL**.
1. Use one of these commands. In these examples, the image is `alpine:latest`.

   - Add the URL to your [`.gitlab-ci.yml`](../../../ci/yaml/README.md#image) file:

     ```shell
     image: gitlab.example.com/groupname/dependency_proxy/containers/alpine:latest
     ```

   - Manually pull the Docker image:

     ```shell
     docker pull gitlab.example.com/groupname/dependency_proxy/containers/alpine:latest
     ```

   - Add the URL to a `Dockerfile`:

     ```shell
     FROM gitlab.example.com/groupname/dependency_proxy/containers/alpine:latest
     ```

GitLab pulls the Docker image from Docker Hub and caches the blobs
on the GitLab server. The next time you pull the same image, GitLab gets the latest
information about the image from Docker Hub, but serves the existing blobs
from the GitLab server.

## Clear the Dependency Proxy cache

Blobs are kept forever on the GitLab server, and there is no hard limit on how much data can be
stored.

To reclaim disk space used by image blobs that are no longer needed, use
the [Dependency Proxy API](../../../api/dependency_proxy.md).
