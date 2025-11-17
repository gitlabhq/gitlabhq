---
stage: Developer Experience
group: API
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Authenticate with the GitLab REST API by using OAuth 2.0, access, and job tokens."
title: REST API authentication
---

Most API requests require authentication, or return only public data when authentication isn't
provided. When authentication is not required, the documentation for each endpoint specifies this.
For example, the [`/projects/:id` endpoint](../projects.md#get-a-single-project) does not require
authentication.

You can authenticate with the GitLab REST API in several ways:

- [OAuth 2.0 tokens](#oauth-20-tokens)
- [Personal access tokens](../../user/profile/personal_access_tokens.md)
- [Project access tokens](../../user/project/settings/project_access_tokens.md)
- [Group access tokens](../../user/group/settings/group_access_tokens.md)
- [Session cookie](#session-cookie)
- [CI/CD job tokens](#job-tokens) (specific endpoints only)

Project access tokens are supported by:

- GitLab Self-Managed: Free, Premium, and Ultimate.
- GitLab.com: Premium and Ultimate.

If you are an administrator, you or your application can authenticate as a specific user, using
either:

- [Impersonation tokens](#impersonation-tokens)
- [Sudo](#sudo)

If authentication information is not valid or is missing, GitLab returns an error message with a
status code of `401`:

```json
{
  "message": "401 Unauthorized"
}
```

{{< alert type="note" >}}

Deploy tokens can't be used with the GitLab public API. For details, see
[Deploy Tokens](../../user/project/deploy_tokens/_index.md).

{{< /alert >}}

## OAuth 2.0 tokens

You can use an [OAuth 2.0 token](../oauth2.md) to authenticate with the API by passing it in either
the `access_token` parameter or the `Authorization` header.

Example of using the OAuth 2.0 token in a parameter:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects?access_token=OAUTH-TOKEN"
```

Example of using the OAuth 2.0 token in a header:

```shell
curl --request GET \
  --header "Authorization: Bearer OAUTH-TOKEN" \
  --url "https://gitlab.example.com/api/v4/projects"
```

Read more about [GitLab as an OAuth 2.0 provider](../oauth2.md).

{{< alert type="note" >}}

All OAuth access tokens are valid for two hours after they are created. You can use the
`refresh_token` parameter to refresh tokens. See [OAuth 2.0 token](../oauth2.md) documentation for
how to request a new access token using a refresh token.

{{< /alert >}}

## Personal, project, and group access tokens

You can use access tokens to authenticate with the API.
Pass the token using the `PRIVATE-TOKEN` header (recommended) or other methods.

For example, using the recommended header method:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects"
```

You can also use personal, project, or group access tokens with OAuth-compliant headers.
For example:

```shell
curl --request GET \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects"
```

## Job tokens

You can use job tokens to authenticate with [specific API endpoints](../../ci/jobs/ci_job_token.md#job-token-access).
In GitLab CI/CD jobs, the token is available as the `CI_JOB_TOKEN` variable.

Pass the token using the `JOB-TOKEN` header (recommended) or other methods.
For all authentication methods, see [CI/CD job token authentication](../../ci/jobs/ci_job_token.md#rest-api-authentication).

For example, using the header method:

```shell
curl --request GET \
  --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --url "https://gitlab.example.com/api/v4/projects/1/releases"
```

## Session cookie

Signing in to the main GitLab application sets a `_gitlab_session` cookie. The API uses this cookie
for authentication if it's present. Using the API to generate a new session cookie isn't supported.

The primary user of this authentication method is the web frontend of GitLab itself. The web
frontend can use the API as the authenticated user to get a list of projects without explicitly
passing an access token.

## Impersonation tokens

Impersonation tokens are a type of
[personal access token](../../user/profile/personal_access_tokens.md).
They can be created only by an administrator, and are used to authenticate with the API as a
specific user.

Use impersonation tokens as an alternative to:

- The user's password or one of their personal access tokens.
- The [Sudo](#sudo) feature. The user's or administrator's password or token
  may not be known, or may change over time.

For more details, see the
[User tokens API](../user_tokens.md#create-an-impersonation-token) documentation.

Impersonation tokens are used exactly like regular personal access tokens, and can be passed in
either the `private_token` parameter or the `PRIVATE-TOKEN` header.

### Disable impersonation

By default, impersonation is enabled. To disable impersonation:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit the `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_rails['impersonation_enabled'] = false
   ```

1. Save the file, and then [reconfigure](../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)
   GitLab for the changes to take effect.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit the `config/gitlab.yml` file:

   ```yaml
   gitlab:
     impersonation_enabled: false
   ```

1. Save the file, and then [restart](../../administration/restart_gitlab.md#self-compiled-installations)
   GitLab for the changes to take effect.

{{< /tab >}}

{{< /tabs >}}

To re-enable impersonation, remove this configuration and reconfigure GitLab (Linux package
installations) or restart GitLab (self-compiled installations).

## Sudo

All API requests support performing an API request as if you were another user, provided you're
authenticated as an administrator with an OAuth or personal access token that has the `sudo` scope.
The API requests are executed with the permissions of the impersonated user.

As an [administrator](../../user/permissions.md), pass the `sudo` parameter either by using query
string or a header with an ID or username (case-insensitive) of the user you want to perform the
operation as. If passed as a header, the header name must be `Sudo`.

If a non administrative access token is provided, GitLab returns an error message with a status code
of `403`:

```json
{
  "message": "403 Forbidden - Must be admin to use sudo"
}
```

If an access token without the `sudo` scope is provided, an error message is returned with a status
code of `403`:

```json
{
  "error": "insufficient_scope",
  "error_description": "The request requires higher privileges than provided by the access token.",
  "scope": "sudo"
}
```

If the sudo user ID or username cannot be found, an error message is returned with a status code of
`404`:

```json
{
  "message": "404 User with ID or username '123' Not Found"
}
```

Example of a valid API request and a request using cURL with sudo request,
providing a username:

```plaintext
GET /projects?private_token=<your_access_token>&sudo=username
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Sudo: username" \
  --url "https://gitlab.example.com/api/v4/projects"
```

Example of a valid API request and a request using cURL with sudo request, providing an ID:

```plaintext
GET /projects?private_token=<your_access_token>&sudo=23
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Sudo: 23" \
  --url "https://gitlab.example.com/api/v4/projects"
```
