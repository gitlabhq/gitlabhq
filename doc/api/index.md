---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# API Docs **(FREE)**

Use the GitLab APIs to automate GitLab.

You can also use a partial [OpenAPI definition](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/api/openapi/openapi.yaml),
to test the API directly from the GitLab user interface.
Contributions are welcome.

## REST API

A REST API is available in GitLab.
Usage instructions are below.
For a list of the available resources and their endpoints, see
[REST API resources](api_resources.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an introduction and basic steps, see
[How to make GitLab API calls](https://www.youtube.com/watch?v=0LsMC3ZiXkA).

## SCIM API **(PREMIUM SAAS)**

GitLab provides an [SCIM API](scim.md) that both implements
[the RFC7644 protocol](https://tools.ietf.org/html/rfc7644) and provides the
`/Users` endpoint. The base URL is `/api/scim/v2/groups/:group_path/Users/`.

## GraphQL API

A [GraphQL API](graphql/index.md) is available in GitLab.

With GraphQL, you can make an API request for only what you need,
and it's versioned by default.

GraphQL co-exists with the current v4 REST API. If we have a v5 API, this should
be a compatibility layer on top of GraphQL.

There were some patenting and licensing concerns with GraphQL. However, these
have been resolved to our satisfaction. The reference implementations
were re-licensed under MIT, and the OWF license used for the GraphQL specification.

When GraphQL is fully implemented, GitLab:

- Can delete controller-specific endpoints.
- Will no longer maintain two different APIs.

## Compatibility guidelines

The HTTP API is versioned with a single number, which is currently `4`. This number
symbolizes the major version number, as described by [SemVer](https://semver.org/).
Because of this, backward-incompatible changes require this version number to
change.

The minor version isn't explicit, which allows for a stable API
endpoint. New features can be added to the API in the same
version number.

New features and bug fixes are released in tandem with GitLab. Apart
from incidental patch and security releases, GitLab is released on the 22nd of each
month. Major API version changes, and removal of entire API versions, are done in tandem
with major GitLab releases.

All deprecations and changes between versions are in the documentation.
For the changes between v3 and v4, see the [v3 to v4 documentation](v3_to_v4.md).

### Current status

Only API version v4 is available. Version v3 was removed in
[GitLab 11.0](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/36819).

## How to use the API

API requests must include both `api` and the API version. The API
version is defined in [`lib/api.rb`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/api/api.rb).
For example, the root of the v4 API is at `/api/v4`.

### Valid API request

If you have a GitLab instance at `gitlab.example.com`:

```shell
curl "https://gitlab.example.com/api/v4/projects"
```

The API uses JSON to serialize data. You don't need to specify `.json` at the
end of the API URL.

### API request to expose HTTP response headers

If you want to expose HTTP response headers, use the `--include` option:

```shell
curl --include "https://gitlab.example.com/api/v4/projects"
HTTP/2 200
...
```

This request can help you investigate an unexpected response.

### API request that includes the exit code

If you want to expose the HTTP exit code, include the `--fail` option:

```shell
curl --fail "https://gitlab.example.com/api/v4/does-not-exist"
curl: (22) The requested URL returned error: 404
```

The HTTP exit code can help you diagnose the success or failure of your REST request.

## Authentication

Most API requests require authentication, or only return public data when
authentication isn't provided. When authentication is not required, the documentation
for each endpoint specifies this. For example, the
[`/projects/:id` endpoint](projects.md#get-single-project) does not require authentication.

There are several ways you can authenticate with the GitLab API:

- [OAuth2 tokens](#oauth2-tokens)
- [Personal access tokens](../user/profile/personal_access_tokens.md)
- [Project access tokens](../user/project/settings/project_access_tokens.md)
- [Session cookie](#session-cookie)
- [GitLab CI/CD job token](#gitlab-cicd-job-token) **(Specific endpoints only)**

Project access tokens are supported by:

- Self-managed GitLab Free and higher.
- GitLab SaaS Premium and higher.

If you are an administrator, you or your application can authenticate as a specific user.
To do so, use:

- [Impersonation tokens](#impersonation-tokens)
- [Sudo](#sudo)

If authentication information is not valid or is missing, GitLab returns an error
message with a status code of `401`:

```json
{
  "message": "401 Unauthorized"
}
```

### OAuth2 tokens

You can use an [OAuth2 token](oauth2.md) to authenticate with the API by passing
it in either the `access_token` parameter or the `Authorization` header.

Example of using the OAuth2 token in a parameter:

```shell
curl "https://gitlab.example.com/api/v4/projects?access_token=OAUTH-TOKEN"
```

Example of using the OAuth2 token in a header:

```shell
curl --header "Authorization: Bearer OAUTH-TOKEN" "https://gitlab.example.com/api/v4/projects"
```

Read more about [GitLab as an OAuth2 provider](oauth2.md).

### Personal/project access tokens

You can use access tokens to authenticate with the API by passing it in either
the `private_token` parameter or the `PRIVATE-TOKEN` header.

Example of using the personal or project access token in a parameter:

```shell
curl "https://gitlab.example.com/api/v4/projects?private_token=<your_access_token>"
```

Example of using the personal or project access token in a header:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects"
```

You can also use personal or project access tokens with OAuth-compliant headers:

```shell
curl --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/projects"
```

### Session cookie

Signing in to the main GitLab application sets a `_gitlab_session` cookie. The
API uses this cookie for authentication if it's present. Using the API to
generate a new session cookie isn't supported.

The primary user of this authentication method is the web frontend of GitLab
itself. The web frontend can use the API as the authenticated user to get a
list of projects without explicitly passing an access token.

### GitLab CI/CD job token

When a pipeline job is about to run, GitLab generates a unique token and injects it as the
[`CI_JOB_TOKEN` predefined variable](../ci/variables/predefined_variables.md).

You can use a GitLab CI/CD job token to authenticate with specific API endpoints:

- Packages:
  - [Package Registry](../user/packages/package_registry/index.md). To push to the
    Package Registry, you can use [deploy tokens](../user/project/deploy_tokens/index.md).
  - [Container Registry](../user/packages/container_registry/index.md)
    (the `$CI_REGISTRY_PASSWORD` is `$CI_JOB_TOKEN`).
  - [Container Registry API](container_registry.md) (scoped to the job's project, when the `ci_job_token_scope` feature flag is enabled)
- [Get job artifacts](job_artifacts.md#get-job-artifacts).
- [Get job token's job](jobs.md#get-job-tokens-job).
- [Pipeline triggers](pipeline_triggers.md), using the `token=` parameter.
- [Release creation](releases/index.md#create-a-release).
- [Terraform plan](../user/infrastructure/index.md).

The token has the same permissions to access the API as the user that triggers the
pipeline. Therefore, this user must be assigned to [a role that has the required privileges](../user/permissions.md).

The token is valid only while the pipeline job runs. After the job finishes, you can't
use the token anymore.

A job token can access a project's resources without any configuration, but it might
give extra permissions that aren't necessary. There is [a proposal](https://gitlab.com/groups/gitlab-org/-/epics/3559)
to redesign the feature for more strategic control of the access permissions.

#### GitLab CI/CD job token security

To make sure that this token doesn't leak, GitLab:

- Masks the job token in job logs.
- Grants permissions to the job token only when the job is running.

To make sure that this token doesn't leak, you should also configure
your [runners](../ci/runners/README.md) to be secure. Avoid:

- Using Docker's `privileged` mode if the machines are re-used.
- Using the [`shell` executor](https://docs.gitlab.com/runner/executors/shell.html) when jobs
  run on the same machine.

If you have an insecure GitLab Runner configuration, you increase the risk that someone
tries to steal tokens from other jobs.

#### Limit GitLab CI/CD job token access

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328553) in GitLab 14.1.
> - [Deployed behind a feature flag](../user/feature_flags.md), disabled by default.
> - Disabled on GitLab.com.
> - Not recommended for production use.
> - To use in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-ci-job-token-scope-limit). **(FREE SELF)**

This in-development feature might not be available for your use. There can be
[risks when enabling features still in development](../user/feature_flags.md#risks-when-enabling-features-still-in-development).
Refer to this feature's version history for more details.

You can limit the access scope of a project's CI/CD job token to increase the
job token's security. A job token might give extra permissions that aren't necessary
to access specific resources. Limiting the job token access scope reduces the risk of a leaked
token being used to access private data that the user associated to the job can access.

Control the job token access scope with an allowlist of other projects authorized
to be accessed by authenticating with the current project's job token. By default
the token scope only allows access to the same project where the token comes from.
Other projects can be added and removed by maintainers with access to both projects.

This setting is enabled by default for all new projects, and disabled by default in projects
created before GitLab 14.1. It is strongly recommended that project maintainers enable this
setting at all times, and configure the allowlist for cross-project access if needed.

For example, when the setting is enabled, jobs in a pipeline in project `A` have
a `CI_JOB_TOKEN` scope limited to project `A`. If the job needs to use the token
to make an API request to project `B`, then `B` must be added to the allowlist for `A`.

To enable and configure the job token scope limit:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > CI/CD**.
1. Expand **Token Access**.
1. Toggle **Limit CI_JOB_TOKEN access** to enabled.
1. (Optional) Add existing projects to the token's access scope. The user adding a
   project must have the [maintainer role](../user/permissions.md) in both projects.

If the job token scope limit is disabled, the token can potentially be used to authenticate
API requests to all projects accessible to the user that triggered the job.

There is [a proposal](https://gitlab.com/groups/gitlab-org/-/epics/3559) to improve
the feature with more strategic control of the access permissions.

##### Enable or disable CI job token scope limit **(FREE SELF)**

The GitLab CI/CD job token access scope limit is under development and not ready for production
use. It is deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can enable it.

To enable it:

```ruby
Feature.enable(:ci_scoped_job_token)
```

To disable it:

```ruby
Feature.disable(:ci_scoped_job_token)
```

### Impersonation tokens

Impersonation tokens are a type of [personal access token](../user/profile/personal_access_tokens.md).
They can be created only by an administrator, and are used to authenticate with the
API as a specific user.

Use impersonation tokens an alternative to:

- The user's password or one of their personal access tokens.
- The [Sudo](#sudo) feature. The user's or administrator's password or token
  may not be known, or may change over time.

For more information, see the [users API](users.md#create-an-impersonation-token)
documentation.

Impersonation tokens are used exactly like regular personal access tokens, and
can be passed in either the `private_token` parameter or the `PRIVATE-TOKEN`
header.

#### Disable impersonation

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/40385) in GitLab 11.6.

By default, impersonation is enabled. To disable impersonation:

**For Omnibus installations**

1. Edit the `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_rails['impersonation_enabled'] = false
   ```

1. Save the file, and then [reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   GitLab for the changes to take effect.

To re-enable impersonation, remove this configuration, and then reconfigure
GitLab.

**For installations from source**

1. Edit the `config/gitlab.yml` file:

   ```yaml
   gitlab:
     impersonation_enabled: false
   ```

1. Save the file, and then [restart](../administration/restart_gitlab.md#installations-from-source)
   GitLab for the changes to take effect.

To re-enable impersonation, remove this configuration, and then restart GitLab.

### Sudo

All API requests support performing an API request as if you were another user,
provided you're authenticated as an administrator with an OAuth or personal
access token that has the `sudo` scope. The API requests are executed with the
permissions of the impersonated user.

As an [administrator](../user/permissions.md), pass the `sudo` parameter either
by using query string or a header with an ID or username (case insensitive) of
the user you want to perform the operation as. If passed as a header, the header
name must be `Sudo`.

If a non administrative access token is provided, GitLab returns an error
message with a status code of `403`:

```json
{
  "message": "403 Forbidden - Must be admin to use sudo"
}
```

If an access token without the `sudo` scope is provided, an error message is
be returned with a status code of `403`:

```json
{
  "error": "insufficient_scope",
  "error_description": "The request requires higher privileges than provided by the access token.",
  "scope": "sudo"
}
```

If the sudo user ID or username cannot be found, an error message is
returned with a status code of `404`:

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
curl --header "PRIVATE-TOKEN: <your_access_token>" --header "Sudo: username" "https://gitlab.example.com/api/v4/projects"
```

Example of a valid API request and a request using cURL with sudo request,
providing an ID:

```plaintext
GET /projects?private_token=<your_access_token>&sudo=23
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" --header "Sudo: 23" "https://gitlab.example.com/api/v4/projects"
```

## Status codes

The API is designed to return different status codes according to context and
action. This way, if a request results in an error, you can get
insight into what went wrong.

The following table gives an overview of how the API functions generally behave.

| Request type  | Description |
|---------------|-------------|
| `GET`         | Access one or more resources and return the result as JSON. |
| `POST`        | Return `201 Created` if the resource is successfully created and return the newly created resource as JSON. |
| `GET` / `PUT` | Return `200 OK` if the resource is accessed or modified successfully. The (modified) result is returned as JSON. |
| `DELETE`      | Returns `204 No Content` if the resource was deleted successfully. |

The following table shows the possible return codes for API requests.

| Return values            | Description |
|--------------------------|-------------|
| `200 OK`                 | The `GET`, `PUT` or `DELETE` request was successful, and the resource(s) itself is returned as JSON. |
| `204 No Content`         | The server has successfully fulfilled the request, and there is no additional content to send in the response payload body. |
| `201 Created`            | The `POST` request was successful, and the resource is returned as JSON. |
| `304 Not Modified`       | The resource hasn't been modified since the last request. |
| `400 Bad Request`        | A required attribute of the API request is missing. For example, the title of an issue is not given. |
| `401 Unauthorized`       | The user isn't authenticated. A valid [user token](#authentication) is necessary. |
| `403 Forbidden`          | The request isn't allowed. For example, the user isn't allowed to delete a project. |
| `404 Not Found`          | A resource couldn't be accessed. For example, an ID for a resource couldn't be found. |
| `405 Method Not Allowed` | The request isn't supported. |
| `409 Conflict`           | A conflicting resource already exists. For example, creating a project with a name that already exists. |
| `412`                    | The request was denied. This can happen if the `If-Unmodified-Since` header is provided when trying to delete a resource, which was modified in between. |
| `422 Unprocessable`      | The entity couldn't be processed. |
| `429 Too Many Requests`  | The user exceeded the [application rate limits](../administration/instance_limits.md#rate-limits). |
| `500 Server Error`       | While handling the request, something went wrong on the server. |

## Pagination

GitLab supports the following pagination methods:

- Offset-based pagination. This is the default method and is available on all endpoints.
- Keyset-based pagination. Added to selected endpoints but being
  [progressively rolled out](https://gitlab.com/groups/gitlab-org/-/epics/2039).

For large collections, for performance reasons we recommend keyset pagination
(when available) instead of offset pagination.

### Offset-based pagination

Sometimes, the returned result spans many pages. When listing resources, you can
pass the following parameters:

| Parameter  | Description |
|------------|-------------|
| `page`     | Page number (default: `1`). |
| `per_page` | Number of items to list per page (default: `20`, max: `100`). |

In the following example, we list 50 [namespaces](namespaces.md) per page:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces?per_page=50"
```

#### Pagination `Link` header

[`Link` headers](https://www.w3.org/wiki/LinkHeader) are returned with each
response. They have `rel` set to `prev`, `next`, `first`, or `last` and contain
the relevant URL. Be sure to use these links instead of generating your own URLs.

For GitLab SaaS users, [some pagination headers may not be returned](../user/gitlab_com/index.md#pagination-response-headers).

In the following cURL example, we limit the output to three items per page
(`per_page=3`) and we request the second page (`page=2`) of [comments](notes.md)
of the issue with ID `8` which belongs to the project with ID `9`:

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/issues/8/notes?per_page=3&page=2"
```

The response is:

```http
HTTP/2 200 OK
cache-control: no-cache
content-length: 1103
content-type: application/json
date: Mon, 18 Jan 2016 09:43:18 GMT
link: <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=1&per_page=3>; rel="prev", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=3&per_page=3>; rel="next", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=1&per_page=3>; rel="first", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=3&per_page=3>; rel="last"
status: 200 OK
vary: Origin
x-next-page: 3
x-page: 2
x-per-page: 3
x-prev-page: 1
x-request-id: 732ad4ee-9870-4866-a199-a9db0cde3c86
x-runtime: 0.108688
x-total: 8
x-total-pages: 3
```

#### Other pagination headers

GitLab also returns the following additional pagination headers:

| Header          | Description |
|-----------------|-------------|
| `x-next-page`   | The index of the next page. |
| `x-page`        | The index of the current page (starting at 1). |
| `x-per-page`    | The number of items per page. |
| `X-prev-page`   | The index of the previous page. |
| `x-total`       | The total number of items. |
| `x-total-pages` | The total number of pages. |

For GitLab.com users, [some pagination headers may not be returned](../user/gitlab_com/index.md#pagination-response-headers).

### Keyset-based pagination

Keyset-pagination allows for more efficient retrieval of pages and - in contrast
to offset-based pagination - runtime is independent of the size of the
collection.

This method is controlled by the following parameters:

| Parameter    | Description |
|--------------| ------------|
| `pagination` | `keyset` (to enable keyset pagination). |
| `per_page`   | Number of items to list per page (default: `20`, max: `100`). |

In the following example, we list 50 [projects](projects.md) per page, ordered
by `id` ascending.

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc"
```

The response header includes a link to the next page. For example:

```http
HTTP/1.1 200 OK
...
Links: <https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc&id_after=42>; rel="next"
Link: <https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc&id_after=42>; rel="next"
Status: 200 OK
...
```

WARNING:
The `Links` header is scheduled to be removed in GitLab 14.0 to be aligned with the
[W3C `Link` specification](https://www.w3.org/wiki/LinkHeader). The `Link`
header was [added in GitLab 13.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33714)
and should be used instead.

The link to the next page contains an additional filter `id_after=42` that
excludes already-retrieved records. The type of filter depends on the
`order_by` option used, and we may have more than one additional filter.

When the end of the collection is reached and there are no additional
records to retrieve, the `Link` header is absent and the resulting array is
empty.

We recommend using only the given link to retrieve the next page instead of
building your own URL. Apart from the headers shown, we don't expose additional
pagination headers.

Keyset-based pagination is supported only for selected resources and ordering
options:

| Resource                | Order |
|-------------------------|-------|
| [Projects](projects.md) | `order_by=id` only. |

## Path parameters

If an endpoint has path parameters, the documentation displays them with a
preceding colon.

For example:

```plaintext
DELETE /projects/:id/share/:group_id
```

The `:id` path parameter needs to be replaced with the project ID, and the
`:group_id` needs to be replaced with the ID of the group. The colons `:`
shouldn't be included.

The resulting cURL request for a project with ID `5` and a group ID of `17` is then:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/share/17"
```

Path parameters that are required to be URL-encoded must be followed. If not,
it doesn't match an API endpoint and responds with a 404. If there's
something in front of the API (for example, Apache), ensure that it doesn't decode
the URL-encoded path parameters.

## Namespaced path encoding

If using namespaced API requests, make sure that the `NAMESPACE/PROJECT_PATH` is
URL-encoded.

For example, `/` is represented by `%2F`:

```plaintext
GET /api/v4/projects/diaspora%2Fdiaspora
```

A project's _path_ isn't necessarily the same as its _name_. A project's path is
found in the project's URL or in the project's settings, under
**General > Advanced > Change path**.

## File path, branches, and tags name encoding

If a file path, branch or tag contains a `/`, make sure it is URL-encoded.

For example, `/` is represented by `%2F`:

```plaintext
GET /api/v4/projects/1/repository/files/src%2FREADME.md?ref=master
GET /api/v4/projects/1/branches/my%2Fbranch/commits
GET /api/v4/projects/1/repository/tags/my%2Ftag
```

## Request Payload

API Requests can use parameters sent as [query strings](https://en.wikipedia.org/wiki/Query_string)
or as a [payload body](https://tools.ietf.org/html/draft-ietf-httpbis-p3-payload-14#section-3.2).
GET requests usually send a query string, while PUT or POST requests usually
send the payload body:

- Query string:

  ```shell
  curl --request POST "https://gitlab/api/v4/projects?name=<example-name>&description=<example-description>"
  ```

- Request payload (JSON):

  ```shell
  curl --request POST --header "Content-Type: application/json" \
       --data '{"name":"<example-name>", "description":"<example-description"}' "https://gitlab/api/v4/projects"
  ```

URL encoded query strings have a length limitation. Requests that are too large
result in a `414 Request-URI Too Large` error message. This can be resolved by
using a payload body instead.

## Encoding API parameters of `array` and `hash` types

You can request the API with `array` and `hash` types parameters:

### `array`

`import_sources` is a parameter of type `array`:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
-d "import_sources[]=github" \
-d "import_sources[]=bitbucket" \
"https://gitlab.example.com/api/v4/some_endpoint"
```

### `hash`

`override_params` is a parameter of type `hash`:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--form "namespace=email" \
--form "path=impapi" \
--form "file=@/path/to/somefile.txt"
--form "override_params[visibility]=private" \
--form "override_params[some_other_param]=some_value" \
"https://gitlab.example.com/api/v4/projects/import"
```

### Array of hashes

`variables` is a parameter of type `array` containing hash key/value pairs
`[{ 'key': 'UPLOAD_TO_S3', 'value': 'true' }]`:

```shell
curl --globoff --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
"https://gitlab.example.com/api/v4/projects/169/pipeline?ref=master&variables[][key]=VAR1&variables[][value]=hello&variables[][key]=VAR2&variables[][value]=world"

curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--header "Content-Type: application/json" \
--data '{ "ref": "master", "variables": [ {"key": "VAR1", "value": "hello"}, {"key": "VAR2", "value": "world"} ] }' \
"https://gitlab.example.com/api/v4/projects/169/pipeline"
```

## `id` vs `iid`

Some resources have two similarly-named fields. For example, [issues](issues.md),
[merge requests](merge_requests.md), and [project milestones](merge_requests.md).
The fields are:

- `id`: ID that is unique across all projects.
- `iid`: Additional, internal ID (displayed in the web UI) that's unique in the
  scope of a single project.

If a resource has both the `iid` field and the `id` field, the `iid` field is
usually used instead of `id` to fetch the resource.

For example, suppose a project with `id: 42` has an issue with `id: 46` and
`iid: 5`. In this case:

- A valid API request to retrieve the issue is `GET /projects/42/issues/5`.
- An invalid API request to retrieve the issue is `GET /projects/42/issues/46`.

Not all resources with the `iid` field are fetched by `iid`. For guidance
regarding which field to use, see the documentation for the specific resource.

## Data validation and error reporting

When working with the API you may encounter validation errors, in which case
the API returns an HTTP `400` error.

Such errors appear in the following cases:

- A required attribute of the API request is missing (for example, the title of
  an issue isn't given).
- An attribute did not pass the validation (for example, the user bio is too
  long).

When an attribute is missing, you receive something like:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
    "message":"400 (Bad request) \"title\" not given"
}
```

When a validation error occurs, error messages are different. They hold
all details of validation errors:

```http
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
    "message": {
        "bio": [
            "is too long (maximum is 255 characters)"
        ]
    }
}
```

This makes error messages more machine-readable. The format can be described as
follows:

```json
{
    "message": {
        "<property-name>": [
            "<error-message>",
            "<error-message>",
            ...
        ],
        "<embed-entity>": {
            "<property-name>": [
                "<error-message>",
                "<error-message>",
                ...
            ],
        }
    }
}
```

## Unknown route

When you attempt to access an API URL that doesn't exist, you receive a
404 Not Found message.

```http
HTTP/1.1 404 Not Found
Content-Type: application/json
{
    "error": "404 Not Found"
}
```

## Encoding `+` in ISO 8601 dates

If you need to include a `+` in a query parameter, you may need to use `%2B`
instead, due to a [W3 recommendation](http://www.w3.org/Addressing/URL/4_URI_Recommentations.html)
that causes a `+` to be interpreted as a space. For example, in an ISO 8601 date,
you may want to include a specific time in ISO 8601 format, such as:

```plaintext
2017-10-17T23:11:13.000+05:30
```

The correct encoding for the query parameter would be:

```plaintext
2017-10-17T23:11:13.000%2B05:30
```

## Clients

There are many unofficial GitLab API Clients for most of the popular programming
languages. For a complete list, visit the [GitLab website](https://about.gitlab.com/partners/technology-partners/#api-clients).

## Rate limits

For administrator documentation on rate limit settings, see
[Rate limits](../security/rate_limits.md). To find the settings that are
specifically used by GitLab.com, see
[GitLab SaaS-specific rate limits](../user/gitlab_com/index.md#gitlab-saas-specific-rate-limits).

## Content type

The GitLab API supports the `application/json` content type by default, though
some API endpoints also support `text/plain`.

In [GitLab 13.10 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/250342),
API endpoints do not support `text/plain` by default, unless it's explicitly documented.
