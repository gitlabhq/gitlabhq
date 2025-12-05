---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Container virtual registry
description: Use the container virtual registry to cache container images from upstream registries.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/548794) in GitLab 18.5 [with a flag](../../../../administration/feature_flags/_index.md) named `container_virtual_registries`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The GitLab container virtual registry is a local proxy you can use to cache container images from
upstream registries. It acts as a pull-through cache, storing frequently-accessed images locally
to reduce bandwidth usage and improve build performance.

## Prerequisites

Before you can use the container virtual registry:

- Review the [prerequisites](../_index.md#prerequisites) to use the virtual registry.

When using the container virtual registry, remember the following restrictions:

- You can create up to `5` container virtual registries per top-level group.
- You can set only `5` upstreams to a given container virtual registry.
- For technical reasons, the `proxy_download` setting is force enabled, no matter what the value in the [object storage configuration](../../../../administration/object_storage.md#proxy-download) is configured to.
- Geo support is not implemented.

## Manage virtual registries

To create, edit, or delete a container virtual registry, see the
[Container virtual registry API](../../../../api/container_virtual_registries.md).

## Authenticate with the container virtual registry

The container virtual registry stores and
associates container images in a registry associated
with your top-level group.
To access container images, you must authenticate
with your group's container virtual registry.

To authenticate manually, run the following command:

```shell
echo "$CONTAINER_REGISTRY_PASSWORD" | docker login gitlab.example.com/virtual_registries/container/1 --username <your_username> --password-stdin
```

Or, access the virtual registry with one of the following tokens:

- A [personal access token](../../../profile/personal_access_tokens.md).
- A [group deploy token](../../../project/deploy_tokens/_index.md) for the top-level group hosting the considered virtual registry.
- A [group access token](../../../group/settings/group_access_tokens.md) for the top-level group hosting the considered virtual registry.
- A [CI/CD job token](../../../../ci/jobs/ci_job_token.md).

Tokens need one of the following scopes:

- `api`
- `read_virtual_registry`

Access tokens and the CI/CD job token are resolved to users. The resolved user must be either:

- A direct member of the top-level group with at least the Guest role.
- A GitLab instance administrator.
- A direct member of one of the projects included in the top-level group.

The container virtual registry follows the [Docker v2 token authentication flow](https://distribution.github.io/distribution/spec/auth/token/):

1. After client authentication, a JWT token issued to the client authorizes the client to pull container images.
1. The token expires according to its expiration time.
1. When the token expires, most Docker clients store user credentials and automatically request a new token without further action.

## Pull container images from the virtual registry

To pull a container image through the virtual registry:

1. Authenticate with the virtual registry.
1. Use the virtual registry URL format to pull images:

   ```plaintext
   gitlab.example.com/virtual_registries/container/<registry_id>/<image_path>:<tag>
   ```

For example:

- Pull an image by its tag:

  ```shell
  docker pull gitlab.example.com/virtual_registries/container/1/library/alpine:latest
  ```

- Pull an image by digest:

  ```shell
  docker pull gitlab.example.com/virtual_registries/container/1/library/alpine@sha256:c9375e662992791e3f39e919b26f510e5254b42792519c180aad254e6b38f4dc
  ```

- Pull an image in a `Dockerfile`:

  ```dockerfile
  FROM gitlab.example.com/virtual_registries/container/1/library/alpine:latest
  ```

- Pull an image in a `.gitlab-ci.yml` file:

  ```yaml
  image: gitlab.example.com/virtual_registries/container/1/library/alpine:latest
  ```

When you pull an image, the virtual registry:

1. Checks if the image is already cached.
   1. If the image is cached and still valid based on the upstream's `cache_validity_hours` setting, the image is served from the cache.
   1. If the image is not cached or the cache is invalid, the image is fetched from the configured upstream registry and cached.
1. Serves the image to your Docker client.

### How the virtual registry validates the cache period for images

An image tag like `alpine:latest` always pulls the most recent version of the image. The new version contains an updated image manifest. The container virtual registry does not pull a new image when the manifest changes.

Instead, the container virtual registry:

1. Checks the `cache_validity_hours` setting in the upstream to determine when an image manifest is invalid.
1. Sends a HEAD request to the upstream. If the manifest is invalid, a new image is pulled.

For example, if your pipeline pulls `node:latest` and you've set the `cache_validity_period` to 24 hours, the virtual registry caches the image and updates it either when the cache expires or `node:latest` changes in the upstream.

## Troubleshooting

### Authentication error: `HTTP Basic: Access Denied`

If you receive an `HTTP Basic: Access denied` error when authenticating against the virtual registry,
refer to [two-factor authentication troubleshooting](../../../profile/account/two_factor_authentication_troubleshooting.md#error-http-basic-access-denied-if-a-password-was-provided-for-git-authentication-).

### Virtual registry connection failure

If a service alias is not set, the `docker:20.10.16` image is unable to find the
`dind` service, and an error like the following is thrown:

```plaintext
error during connect: Get http://docker:2376/v1.39/info: dial tcp: lookup docker on 192.168.0.1:53: no such host
```

To resolve this error, set a service alias for the Docker service:

```yaml
services:
  - name: docker:20.10.16-dind
    alias: docker
```

### Virtual registry authentication issues from CI/CD jobs

GitLab Runner authenticates automatically using the CI/CD job token. However, the underlying Docker engine
is still subject to its [authorization resolving process](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#precedence-of-docker-authorization-resolving).

Misconfigurations in the authentication mechanism may cause `HTTP Basic: Access denied` and `403: Access forbidden` errors.

You can use the job logs to view the authentication mechanism used to authenticate against the virtual registry:

```plaintext
Authenticating with credentials from $DOCKER_AUTH_CONFIG
```

```plaintext
Authenticating with credentials from /root/.docker/config.json
```

```plaintext
Authenticating with credentials from job payload (GitLab Registry)
```

Make sure you are using the expected authentication mechanism.

### `Not Found` or `404` error when pulling image

Errors like these might indicate that:

- The user running the job does not have at least the Guest role for the group that owns the virtual registry.
- The virtual registry ID in the URL is incorrect.
- The upstream registry does not contain the requested image.
- The virtual registry has no upstreams configured.

Example error messages:

```plaintext
ERROR: gitlab.example.com/virtual_registries/container/1/library/alpine:latest: not found
```

```plaintext
ERROR: Job failed: failed to pull image "gitlab.example.com/virtual_registries/container/1/library/alpine:latest" with specified policies [always]:
Error response from daemon: error parsing HTTP 404 response body: unexpected end of JSON input: "" (manager.go:237:1s)
```

To resolve these errors:

1. Verify you have at least the Guest role for the group.
1. Confirm the virtual registry ID is correct.
1. Check that the virtual registry has at least one upstream configured.
1. Verify the image exists in the upstream registry.
