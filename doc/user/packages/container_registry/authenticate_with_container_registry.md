---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Learn how to authenticate with the container registry using your GitLab login credentials, a token, or CI/CD variables such as a CI job token.
title: Authenticate with the container registry
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To authenticate with the container registry, you can use:

- GitLab username and password (not available if 2FA is enabled)
- [Personal access token](../../profile/personal_access_tokens.md)
- [Deploy token](../../project/deploy_tokens/_index.md)
- [Project access token](../../project/settings/project_access_tokens.md)
- [Group access token](../../group/settings/group_access_tokens.md)
- The [GitLab CLI](https://docs.gitlab.com/cli/)

For token-based authentication methods, the minimum required scope:

- For read (pull) access, must be `read_registry`
- For write (push) access, must be `write_registry` and `read_registry`

> [!note]
> Admin Mode does not apply during authentication with the container registry. If you are an administrator
> with Admin Mode enabled, and you create a personal access token without the `admin_mode` scope,
> that token works even though Admin Mode is enabled. For more information, see
> [Admin Mode](../../../administration/settings/sign_in_restrictions.md#admin-mode).

## Authenticate with username and password

> [!note]
> If you have enabled [two-factor authentication (2FA)](../../profile/account/two_factor_authentication.md)
> (including email OTP) on your account, you must [authenticate with a token](#authenticate-with-a-token).

To authenticate with your username and password, run the `docker login` command:

```shell
docker login registry.example.com -u <username> -p <password>
```

For security reasons, it's recommended to use the `--password-stdin` flag instead of `-p`:

```shell
echo "<password>" | docker login registry.example.com -u <username> --password-stdin
```

## Authenticate with a token

To authenticate with a token, run the `docker login` command:

```shell
TOKEN=<token>
echo "$TOKEN" | docker login registry.example.com -u <username> --password-stdin
```

After authentication, the client caches the credentials. Later operations make authorization
requests that return JWT tokens, authorized to do only the specified operation.
Tokens remain valid:

- For [5 minutes by default](../../../administration/packages/container_registry.md#increase-token-duration) on GitLab Self-Managed
- For [15 minutes](../../gitlab_com/_index.md#container-registry) on GitLab.com

## Use GitLab CI/CD to authenticate

To use CI/CD to authenticate with the container registry, you can use:

- The `CI_REGISTRY_USER` and `CI_REGISTRY_PASSWORD` CI/CD variables.

  `CI_REGISTRY_USER` holds a per-job user with read-write access to the container registry,
  and `CI_REGISTRY_PASSWORD` holds its automatically created password.

  ```shell
  echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin
  ```

- A [CI job token](../../../ci/jobs/ci_job_token.md).

  This token has read (pull) and write (push) access to the container registry of the project that runs the job.
  The [CI/CD job token allowlist](../../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project) controls access to other projects' registries.

  ```shell
  echo "$CI_JOB_TOKEN" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin
  ```

  You can also use the `gitlab-ci-token` scheme:

  ```shell
  echo "$CI_JOB_TOKEN" | docker login $CI_REGISTRY -u gitlab-ci-token --password-stdin
  ```

- A [GitLab deploy token](../../project/deploy_tokens/_index.md#gitlab-deploy-token) with the minimum scope of:
  - For read (pull) access, `read_registry`.
  - For write (push) access, `read_registry` and `write_registry`.

  ```shell
  echo "$CI_DEPLOY_PASSWORD" | docker login $CI_REGISTRY -u $CI_DEPLOY_USER --password-stdin
  ```

- A personal access token with the minimum scope of:
  - For read (pull) access, `read_registry`.
  - For write (push) access, `read_registry` and `write_registry`.

  ```shell
  echo "<access_token>" | docker login $CI_REGISTRY -u <username> --password-stdin
  ```

## Troubleshooting

### Error: `docker login` command fails with `access forbidden`

The container registry returns the GitLab API URL to the Docker client
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

For more information about credential validation with Docker clients, see [Container registry architecture](../../../administration/packages/container_registry.md#container-registry-architecture).

### Error: `docker login` fails with an authentication error

When GitLab rejects a `docker login` request, the Docker client displays a JSON error envelope containing an error code and message.

To resolve the error, identify the error code and follow the instructions:

- `UNAUTHORIZED` (`401`): GitLab could not verify the credentials. To resolve:
  - Confirm the password or token is correct and not expired.
  - Confirm a personal access token or deploy token has the `read_registry` scope for pull
    access, or the `read_registry` and `write_registry` scopes for push access.
  - If the account uses two-factor authentication, authenticate with a token instead of a
    password. For more information, see [authenticate with a token](#authenticate-with-a-token).
- `DENIED` (`403`): GitLab denied access. Check the message:
  - `access forbidden`: the credentials are valid but do not grant registry access. Confirm
    the token has the `read_registry` scope (and `write_registry` for push access), and that
    your role allows access to the project's registry.
  - `Pushing to protected repository path forbidden`: the target path is protected by
    container registry protection rules.
  - `Access denied: too many failed authentication attempts from this network`: abuse
    protection blocked your network. Wait for the block to expire, or retry from a
    different network.
  - `Access denied: too many distinct sources for this account`: the account was used from
    too many IP addresses. Review where the account is used, then consolidate or stagger
    the requests.
- `UNSUPPORTED` (`404`): GitLab does not recognize the requested authentication service. To resolve:
  - Verify the registry token service is configured correctly.

If the Docker client instead reports `unexpected end of JSON input`, the response body was empty
or contained invalid JSON:

### Error: `unexpected end of JSON input`

When a proxy or load balancer in front of GitLab strips the response body, you might receive
the following error:

```plaintext
Error response from daemon: error parsing HTTP <status> response body: unexpected end of JSON input: ""
```

To resolve this issue, check the request path between the Docker client and GitLab.

### Error: `unauthorized: authentication required` when pushing large images

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
