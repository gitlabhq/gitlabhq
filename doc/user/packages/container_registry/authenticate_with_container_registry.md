---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Authenticate with the container registry
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To authenticate with the container registry, you can use a:

- [Personal access token](../../profile/personal_access_tokens.md).
- [Deploy token](../../project/deploy_tokens/_index.md).
- [Project access token](../../project/settings/project_access_tokens.md).
- [Group access token](../../group/settings/group_access_tokens.md).

All of these authentication methods require the minimum scope:

- For read (pull) access, to be `read_registry`.
- For write (push) access, to be `write_registry` and `read_registry`.

NOTE:
[Admin Mode](../../../administration/settings/sign_in_restrictions.md#admin-mode)
does not apply during authentication with the container registry. If you are an administrator
with Admin Mode enabled, and you create a personal access token without the `admin_mode` scope,
that token works even though Admin Mode is enabled.

To authenticate, run the `docker login` command. For example:

```shell
TOKEN=<token>
echo "$TOKEN" | docker login registry.example.com -u <username> --password-stdin
```

After authentication, the client caches the credentials. Later operations make authorization
requests that return JWT tokens, authorized to do only the specified operation.
Tokens remain valid for [5 minutes by default](../../../administration/packages/container_registry.md#increase-token-duration),
and [15 minutes on GitLab.com](../../gitlab_com/_index.md#gitlab-container-registry).

## Use GitLab CI/CD to authenticate

To use CI/CD to authenticate with the container registry, you can use:

- The `CI_REGISTRY_USER` CI/CD variable.

  This variable holds a per-job user with read-write access to the container registry.
  Its password is also automatically created and available in `CI_REGISTRY_PASSWORD`.

  ```shell
  echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin
  ```

- A [CI job token](../../../ci/jobs/ci_job_token.md).

  ```shell
  echo "$CI_JOB_TOKEN" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin
  ```

- A [deploy token](../../project/deploy_tokens/_index.md#gitlab-deploy-token) with the minimum scope of:
  - For read (pull) access, `read_registry`.
  - For write (push) access, `read_registry` and `write_registry`.

  ```shell
  echo "$CI_DEPLOY_PASSWORD" | docker login $CI_REGISTRY -u $CI_DEPLOY_USER --password-stdin
  ```

- A [personal access token](../../profile/personal_access_tokens.md) with the minimum scope of:
  - For read (pull) access, `read_registry`.
  - For write (push) access, `read_registry` and `write_registry`.

  ```shell
  echo "<access_token>" | docker login $CI_REGISTRY -u <username> --password-stdin
  ```

## Troubleshooting

### `docker login` command fails with `access forbidden`

The container registry [returns the GitLab API URL to the Docker client](../../../administration/packages/container_registry.md#architecture-of-gitlab-container-registry)
to validate credentials. The Docker client uses basic auth, so the request contains
the `Authorization` header. If the `Authorization` header is missing in the request to the
`/jwt/auth` endpoint configured in the `token_realm` for the registry configuration,
you receive an `access forbidden` error message.

For example:

```plaintext
> docker login gitlab.example.com:4567

Username: user
Password:
Error response from daemon: Get "https://gitlab.company.com:4567/v2/": denied: access forbidden
```

To avoid this error, ensure the `Authorization` header is not stripped from the request.
For example, a proxy in front of GitLab might be redirecting to the `/jwt/auth` endpoint.

### `unauthorized: authentication required` when pushing large images

When pushing large images, you may see an authentication error like the following:

```shell
docker push gitlab.example.com/myproject/docs:latest
The push refers to a repository [gitlab.example.com/myproject/docs]
630816f32edb: Preparing
530d5553aec8: Preparing
...
4b0bab9ff599: Waiting
d1c800db26c7: Waiting
42755cf4ee95: Waiting
unauthorized: authentication required
```

This error happens when your authentication token expires before the image push is complete.
By default, tokens for the container registry on GitLab Self-Managed instances expire after five minutes.
On GitLab.com, the token expiration time is 15 minutes.
