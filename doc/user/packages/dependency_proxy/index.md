---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Dependency Proxy **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/7934) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.11.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/273655) to GitLab Free in GitLab 13.6.
> - [Support for private groups](https://gitlab.com/gitlab-org/gitlab/-/issues/11582) in GitLab Free 13.7.
> - Anonymous access to images in public groups is no longer available starting in GitLab Free 13.7.
> - [Support for pull-by-digest and Docker version 20.x](https://gitlab.com/gitlab-org/gitlab/-/issues/290944) in GitLab Free 13.10.

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
[direction page](https://about.gitlab.com/direction/package/#dependency-proxy).

## Enable the Dependency Proxy

The Dependency Proxy is disabled by default.
[Learn how an administrator can enable it](../../../administration/packages/dependency_proxy.md).

## View the Dependency Proxy

To view the Dependency Proxy:

- Go to your group's **Packages & Registries > Dependency Proxy**.

The Dependency Proxy is not available for projects.

## Use the Dependency Proxy for Docker images

You can use GitLab as a source for your Docker images.

Prerequisites:

- Your images must be stored on [Docker Hub](https://hub.docker.com/).

### Authenticate with the Dependency Proxy

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11582) in GitLab Free 13.7.
> - It's [deployed behind a feature flag](../../feature_flags.md), enabled by default.
> - It's enabled on GitLab.com.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](../../../administration/packages/dependency_proxy.md#disabling-authentication). **(FREE SELF)**

WARNING:
This feature might not be available to you. Check the **version history** note above for details.
The requirement to authenticate is a breaking change added in 13.7. An [administrator can temporarily
disable it](../../../administration/packages/dependency_proxy.md#disabling-authentication) if it
has disrupted your existing Dependency Proxy usage.

WARNING:
If [SSO enforcement](../../group/saml_sso/index.md#sso-enforcement)
is enabled for your Group, requests to the dependency proxy will fail. This bug is being tracked in
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/294018).

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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/280582) in GitLab 13.7.
> - Automatic runner authentication [added](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27302) in GitLab 13.9.
> - The prefix for group names containing uppercase letters was [fixed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54559) in GitLab 13.10.

Runners log in to the Dependency Proxy automatically. To pull through
the Dependency Proxy, use the `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`
[predefined CI/CD variable](../../../ci/variables/predefined_variables.md):

Example pulling the latest alpine image:

```yaml
# .gitlab-ci.yml
image: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/alpine:latest
```

There are other additional predefined CI/CD variables you can also use:

- `CI_DEPENDENCY_PROXY_USER`: A CI/CD user for logging in to the Dependency Proxy.
- `CI_DEPENDENCY_PROXY_PASSWORD`: A CI/CD password for logging in to the Dependency Proxy.
- `CI_DEPENDENCY_PROXY_SERVER`: The server for logging in to the Dependency Proxy.
- `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`: The image prefix for pulling images through the Dependency Proxy.

`CI_DEPENDENCY_PROXY_SERVER` and `CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX`
include the server port. If you explicitly include the Dependency Proxy
path, the port must be included, unless you have logged into the Dependency
Proxy manually without including the port:

```shell
docker pull gitlab.example.com:443/my-group/dependency_proxy/containers/alpine:latest
```

You can also use [custom CI/CD variables](../../../ci/variables/index.md#custom-cicd-variables) to store and access your personal access token or other valid credentials.

### Store a Docker image in Dependency Proxy cache

To store a Docker image in Dependency Proxy storage:

1. Go to your group's **Packages & Registries > Dependency Proxy**.
1. Copy the **Dependency Proxy URL**.
1. Use one of these commands. In these examples, the image is `alpine:latest`.
1. You can also pull images by digest to specify exactly which version of an image to pull.

   - Pull an image by tag by adding the image to your [`.gitlab-ci.yml`](../../../ci/yaml/index.md#image) file:

     ```shell
     image: gitlab.example.com/groupname/dependency_proxy/containers/alpine:latest
     ```

   - Pull an image by digest by adding the image to your [`.gitlab-ci.yml`](../../../ci/yaml/index.md#image) file:

     ```shell
     image: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/alpine@sha256:c9375e662992791e3f39e919b26f510e5254b42792519c180aad254e6b38f4dc
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

## Docker Hub rate limits and the Dependency Proxy

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/241639) in GitLab Free 13.7.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
Watch how to [use the Dependency Proxy to help avoid Docker Hub rate limits](https://youtu.be/Nc4nUo7Pq08).

In November 2020, Docker introduced
[rate limits on pull requests from Docker Hub](https://docs.docker.com/docker-hub/download-rate-limit/).
If your GitLab [CI/CD configuration](../../../ci/index.md) uses
an image from Docker Hub, each time a job runs, it may count as a pull request.
To help get around this limit, you can pull your image from the Dependency Proxy cache instead.

When you pull an image (by using a command like `docker pull` or, in a `.gitlab-ci.yml`
file, `image: foo:latest`), the Docker client makes a collection of requests:

1. The image manifest is requested. The manifest contains information about
   how to build the image.
1. Using the manifest, the Docker client requests a collection of layers, also
   known as blobs, one at a time.

The Docker Hub rate limit is based on the number of GET requests for the manifest. The Dependency Proxy
caches both the manifest and blobs for a given image, so when you request it again,
Docker Hub does not have to be contacted.

### How does GitLab know if a cached tagged image is stale?

If you are using an image tag like `alpine:latest`, the image changes
over time. Each time it changes, the manifest contains different information about which
blobs to request. The Dependency Proxy does not pull a new image each time the
manifest changes; it checks only when the manifest becomes stale.

Docker does not count HEAD requests for the image manifest towards the rate limit.
You can make a HEAD request for `alpine:latest`, view the digest (checksum)
value returned in the header, and determine if a manifest has changed.

The Dependency Proxy starts all requests with a HEAD request. If the manifest
has become stale, only then is a new image pulled.

For example, if your pipeline pulls `node:latest` every five
minutes, the Dependency Proxy caches the entire image and only updates it if
`node:latest` changes. So instead of having 360 requests for the image in six hours
(which exceeds the Docker Hub rate limit), you only have one pull request, unless
the manifest changed during that time.

### Check your Docker Hub rate limit

If you are curious about how many requests to Docker Hub you have made and how
many remain, you can run these commands from your runner, or even in a CI/CD
script:

```shell
# Note, you must have jq installed to run this command
TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq --raw-output .token) && curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1 | grep RateLimit
...
```

The output is something like:

```shell
RateLimit-Limit: 100;w=21600
RateLimit-Remaining: 98;w=21600
```

This example shows the total limit of 100 pulls in six hours, with 98 pulls remaining.

#### Check the rate limit in a CI/CD job

This example shows a GitLab CI/CD job that uses an image with `jq` and `curl` installed:

```yaml
hub_docker_quota_check:
    stage: build
    image: alpine:latest
    tags:
        - <optional_runner_tag>
    before_script: apk add curl jq
    script:
      - |
        TOKEN=$(curl "https://auth.docker.io/token?service=registry.docker.io&scope=repository:ratelimitpreview/test:pull" | jq --raw-output .token) && curl --head --header "Authorization: Bearer $TOKEN" "https://registry-1.docker.io/v2/ratelimitpreview/test/manifests/latest" 2>&1
```

## Troubleshooting

### Dependency Proxy Connection Failure

If a service alias is not set the `docker:19.03.12` image is unable to find the
`dind` service, and an error like the following is thrown:

```plaintext
error during connect: Get http://docker:2376/v1.39/info: dial tcp: lookup docker on 192.168.0.1:53: no such host
```

This can be resolved by setting a service alias for the Docker service:

```yaml
services:
    - name: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/docker:18.09.7-dind
      alias: docker
```
