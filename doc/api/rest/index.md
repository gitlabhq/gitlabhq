---
stage: Foundations
group: Import and Integrate
description: Programmatic interaction with GitLab.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# REST API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

The REST APIs have been around for a longer time compared to GraphQL APIs, which
may make them more familiar to some developers. It is often a good choice for
developers who are more comfortable with traditional API architecture.

## Compatibility guidelines

The HTTP API is versioned with a single number, which is `4`. This number
symbolizes the major version number, as described by [SemVer](https://semver.org/).
Because of this, backward-incompatible changes require this version number to
change.

The minor version isn't explicit, which allows for a stable API
endpoint. New features can be added to the API in the same
version number.

New features and bug fixes are released in tandem with GitLab. Apart
from incidental patch releases, new minor versions of GitLab are released every
month. Major API version changes, and removal of entire API versions, are done in tandem
with major GitLab releases.

All deprecations and changes between versions are in the documentation.

### Current status

Only API version v4 is available.

### Breaking change exemptions

Elements labeled as [experimental or beta](../../policy/experiment-beta-support.md) in the [REST API resources](../api_resources.md) are exempt from the deprecation process.
These parts can be removed or changed at any time without notice.

Fields behind a feature flag and disabled by default do not follow the deprecation and removal process. These fields can be removed at any time without notice.

## How to use the API

API requests must include both `api` and the API version. The API
version is defined in [`lib/api.rb`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/api/api.rb).
For example, the root of the v4 API is at `/api/v4`.

### Valid API request

The following is a basic example of a request to the fictional `gitlab.example.com` endpoint:

```shell
curl "https://gitlab.example.com/api/v4/projects"
```

The API uses JSON to serialize data. You don't need to specify `.json` at the
end of the API URL.

NOTE:
In the example above, replace `gitlab.example.com` with `gitlab.com` to query GitLab.com (GitLab SaaS).
Access can be denied due to authentication. For more information, see [Authentication](#authentication).

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
[`/projects/:id` endpoint](../projects.md#get-single-project) does not require authentication.

You can authenticate with the GitLab API in several ways:

- [OAuth 2.0 tokens](#oauth-20-tokens)
- [Personal access tokens](../../user/profile/personal_access_tokens.md)
- [Project access tokens](../../user/project/settings/project_access_tokens.md)
- [Group access tokens](../../user/group/settings/group_access_tokens.md)
- [Session cookie](#session-cookie)
- [GitLab CI/CD job token](../../ci/jobs/ci_job_token.md) **(Specific endpoints only)**

Project access tokens are supported by:

- Self-managed GitLab: Free, Premium, and Ultimate.
- GitLab SaaS: Premium and Ultimate.

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

NOTE:
Deploy tokens can't be used with the GitLab public API. For details, see
[Deploy Tokens](../../user/project/deploy_tokens/index.md).

### OAuth 2.0 tokens

You can use an [OAuth 2.0 token](../oauth2.md) to authenticate with the API by passing
it in either the `access_token` parameter or the `Authorization` header.

Example of using the OAuth 2.0 token in a parameter:

```shell
curl "https://gitlab.example.com/api/v4/projects?access_token=OAUTH-TOKEN"
```

Example of using the OAuth 2.0 token in a header:

```shell
curl --header "Authorization: Bearer OAUTH-TOKEN" "https://gitlab.example.com/api/v4/projects"
```

Read more about [GitLab as an OAuth 2.0 provider](../oauth2.md).

NOTE:
All OAuth access tokens are valid for two hours after they are created. You can
use the `refresh_token` parameter to refresh tokens. See
[OAuth 2.0 token](../oauth2.md) documentation for how to request a new access
token using a refresh token.

### Personal/project/group access tokens

You can use access tokens to authenticate with the API by passing it in either
the `private_token` parameter or the `PRIVATE-TOKEN` header.

Example of using the personal, project, or group access token in a parameter:

```shell
curl "https://gitlab.example.com/api/v4/projects?private_token=<your_access_token>"
```

Example of using the personal, project, or group access token in a header:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects"
```

You can also use personal, project, or group access tokens with OAuth-compliant headers:

```shell
curl --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/projects"
```

### Job tokens

You can use job tokens to authenticate with [specific API endpoints](../../ci/jobs/ci_job_token.md)
by passing the token in the `job_token` parameter or the `JOB-TOKEN` header.
To pass the token in GitLab CI/CD jobs, use the `CI_JOB_TOKEN` variable.

Example of using the job token in a parameter:

```shell
curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts?job_token=$CI_JOB_TOKEN"
```

Example of using the job token in a header:

```shell
curl --header "JOB-TOKEN:$CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/1/releases"
```

### Session cookie

Signing in to the main GitLab application sets a `_gitlab_session` cookie. The
API uses this cookie for authentication if it's present. Using the API to
generate a new session cookie isn't supported.

The primary user of this authentication method is the web frontend of GitLab
itself. The web frontend can use the API as the authenticated user to get a
list of projects without explicitly passing an access token.

### Impersonation tokens

Impersonation tokens are a type of [personal access token](../../user/profile/personal_access_tokens.md).
They can be created only by an administrator, and are used to authenticate with the
API as a specific user.

Use impersonation tokens as an alternative to:

- The user's password or one of their personal access tokens.
- The [Sudo](#sudo) feature. The user's or administrator's password or token
  may not be known, or may change over time.

For more information, see the [users API](../users.md#create-an-impersonation-token)
documentation.

Impersonation tokens are used exactly like regular personal access tokens, and
can be passed in either the `private_token` parameter or the `PRIVATE-TOKEN`
header.

#### Disable impersonation

By default, impersonation is enabled. To disable impersonation:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit the `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_rails['impersonation_enabled'] = false
   ```

1. Save the file, and then [reconfigure](../../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)
   GitLab for the changes to take effect.

:::TabTitle Self-compiled (source)

1. Edit the `config/gitlab.yml` file:

   ```yaml
   gitlab:
     impersonation_enabled: false
   ```

1. Save the file, and then [restart](../../administration/restart_gitlab.md#self-compiled-installations)
   GitLab for the changes to take effect.

::EndTabs

To re-enable impersonation, remove this configuration and reconfigure GitLab (Linux package installations) or restart
GitLab (self-compiled installations).

### Sudo

All API requests support performing an API request as if you were another user,
provided you're authenticated as an administrator with an OAuth or personal
access token that has the `sudo` scope. The API requests are executed with the
permissions of the impersonated user.

As an [administrator](../../user/permissions.md), pass the `sudo` parameter either
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
returned with a status code of `403`:

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

| Request type            | Description                                                                                                                     |
|:------------------------|:--------------------------------------------------------------------------------------------------------------------------------|
| `GET`                   | Access one or more resources and return the result as JSON.                                                                     |
| `POST`                  | Return `201 Created` if the resource is successfully created and return the newly created resource as JSON.                     |
| `GET` / `PUT` / `PATCH` | Return `200 OK` if the resource is accessed or modified successfully. The (modified) result is returned as JSON.                |
| `DELETE`                | Returns `204 No Content` if the resource was deleted successfully or `202 Accepted` if the resource is scheduled to be deleted. |

The following table shows the possible return codes for API requests.

| Return values             | Description                                                                                                                                              |
|:--------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------|
| `200 OK`                  | The `GET`, `PUT`, `PATCH` or `DELETE` request was successful, and the resource itself is returned as JSON.                                                        |
| `201 Created`             | The `POST` request was successful, and the resource is returned as JSON.                                                                                 |
| `202 Accepted`            | The `GET`, `PUT` or `DELETE` request was successful, and the resource is scheduled for processing.                                                       |
| `204 No Content`          | The server has successfully fulfilled the request, and there is no additional content to send in the response payload body.                              |
| `301 Moved Permanently`   | The resource has been definitively moved to the URL given by the `Location` headers.                                                                     |
| `304 Not Modified`        | The resource hasn't been modified since the last request.                                                                                                |
| `400 Bad Request`         | A required attribute of the API request is missing. For example, the title of an issue is not given.                                                     |
| `401 Unauthorized`        | The user isn't authenticated. A valid [user token](#authentication) is necessary.                                                                        |
| `403 Forbidden`           | The request isn't allowed. For example, the user isn't allowed to delete a project.                                                                      |
| `404 Not Found`           | A resource couldn't be accessed. For example, an ID for a resource couldn't be found, or the user isn't authorized to access the resource.               |
| `405 Method Not Allowed`  | The request isn't supported.                                                                                                                             |
| `409 Conflict`            | A conflicting resource already exists. For example, creating a project with a name that already exists.                                                  |
| `412 Precondition Failed` | The request was denied. This can happen if the `If-Unmodified-Since` header is provided when trying to delete a resource, which was modified in between. |
| `422 Unprocessable`       | The entity couldn't be processed.                                                                                                                        |
| `429 Too Many Requests`   | The user exceeded the [application rate limits](../../administration/instance_limits.md#rate-limits).                                                    |
| `500 Server Error`        | While handling the request, something went wrong on the server.                                                                                          |
| `503 Service Unavailable` | The server cannot handle the request because the server is temporarily overloaded.                                                                               |

## Redirects

> - Introduced in GitLab 16.4 [with a flag](../../user/feature_flags.md) named `api_redirect_moved_projects`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137578) in GitLab 16.7. Feature flag `api_redirect_moved_projects` removed.

After [path changes](../../user/project/repository/index.md#what-happens-when-a-repository-path-changes) the
REST API can respond with a redirect and users should be able to handle such responses.
The users should follow the redirect and repeat the request to the URI specified in the `Location` header.

Example of a project moved to a different path:

```shell
curl --verbose "https://gitlab.example.com/api/v4/projects/gitlab-org%2Fold-path-project"
```

The response is:

```plaintext
...
< Location: http://gitlab.example.com/api/v4/projects/81
...
This resource has been moved permanently to https://gitlab.example.com/api/v4/projects/81
```

## Pagination

GitLab supports the following pagination methods:

- Offset-based pagination. The default method and available on all endpoints except,
  in GitLab 16.5 and later, the `users` endpoint.
- Keyset-based pagination. Added to selected endpoints but being
  [progressively rolled out](https://gitlab.com/groups/gitlab-org/-/epics/2039).

For large collections, you should use keyset pagination
(when available) instead of offset pagination, for performance reasons.

### Offset-based pagination

> - The `users` endpoint was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/426547) for offset-based pagination in GitLab 16.5 and is planned for removal in 17.0. This change is a breaking change. Use keyset-based pagination for this endpoint instead.
> - The `users` endpoint enforces keyset-based pagination when the number of requested records is greater than 50,000 in GitLab 17.0.

Sometimes, the returned result spans many pages. When listing resources, you can
pass the following parameters:

| Parameter  | Description                                                   |
|:-----------|:--------------------------------------------------------------|
| `page`     | Page number (default: `1`).                                   |
| `per_page` | Number of items to list per page (default: `20`, max: `100`). |

In the following example, we list 50 [namespaces](../namespaces.md) per page:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces?per_page=50"
```

NOTE:
There is a [max offset allowed limit](../../administration/instance_limits.md#max-offset-allowed-by-the-rest-api-for-offset-based-pagination) for offset pagination. You can change the limit in self-managed instances.

#### Pagination `Link` header

[`Link` headers](https://www.w3.org/wiki/LinkHeader) are returned with each
response. They have `rel` set to `prev`, `next`, `first`, or `last` and contain
the relevant URL. Be sure to use these links instead of generating your own URLs.

For GitLab.com users, [some pagination headers may not be returned](../../user/gitlab_com/index.md#pagination-response-headers).

In the following cURL example, we limit the output to three items per page
(`per_page=3`) and we request the second page (`page=2`) of [comments](../notes.md)
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

| Header          | Description                                    |
|:----------------|:-----------------------------------------------|
| `x-next-page`   | The index of the next page.                    |
| `x-page`        | The index of the current page (starting at 1). |
| `x-per-page`    | The number of items per page.                  |
| `x-prev-page`   | The index of the previous page.                |
| `x-total`       | The total number of items.                     |
| `x-total-pages` | The total number of pages.                     |

For GitLab.com users, [some pagination headers may not be returned](../../user/gitlab_com/index.md#pagination-response-headers).

### Keyset-based pagination

Keyset-pagination allows for more efficient retrieval of pages and - in contrast
to offset-based pagination - runtime is independent of the size of the
collection.

This method is controlled by the following parameters. `order_by` and `sort` are both mandatory.

| Parameter    | Required | Description |
|--------------| ------------ | --------- |
| `pagination` | yes | `keyset` (to enable keyset pagination). |
| `per_page`   | no | Number of items to list per page (default: `20`, max: `100`). |
| `order_by`   | yes | Column by which to order by. |
| `sort`       | yes | Sort order (`asc` or `desc`) |

In the following example, we list 50 [projects](../projects.md) per page, ordered
by `id` ascending.

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc"
```

The response header includes a link to the next page. For example:

```http
HTTP/1.1 200 OK
...
Link: <https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc&id_after=42>; rel="next"
Status: 200 OK
...
```

The link to the next page contains an additional filter `id_after=42` that
excludes already-retrieved records.

As another example, the following request lists 50 [groups](../groups.md) per page ordered
by `name` ascending using keyset pagination:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups?pagination=keyset&per_page=50&order_by=name&sort=asc"
```

The response header includes a link to the next page:

```http
HTTP/1.1 200 OK
...
Link: <https://gitlab.example.com/api/v4/groups?pagination=keyset&per_page=50&order_by=name&sort=asc&cursor=eyJuYW1lIjoiRmxpZ2h0anMiLCJpZCI6IjI2IiwiX2tkIjoibiJ9>; rel="next"
Status: 200 OK
...
```

The link to the next page contains an additional filter `cursor=eyJuYW1lIjoiRmxpZ2h0anMiLCJpZCI6IjI2IiwiX2tkIjoibiJ9` that
excludes already-retrieved records.

The type of filter depends on the
`order_by` option used, and we can have more than one additional filter.

WARNING:
The `Links` header was removed to be aligned with the
[W3C `Link` specification](https://www.w3.org/wiki/LinkHeader). The `Link`
header should be used instead.

When the end of the collection is reached and there are no additional
records to retrieve, the `Link` header is absent and the resulting array is
empty.

You should use only the given link to retrieve the next page instead of
building your own URL. Apart from the headers shown, we don't expose additional
pagination headers.

#### Supported resources

Keyset-based pagination is supported only for selected resources and ordering
options:

| Resource                                                                       | Options                          | Availability                             |
|:-------------------------------------------------------------------------------|:---------------------------------|:-----------------------------------------|
| [Group audit events](../audit_events.md#retrieve-all-group-audit-events)       | `order_by=id`, `sort=desc` only  | Authenticated users only.                |
| [Groups](../groups.md#list-groups)                                             | `order_by=name`, `sort=asc` only | Unauthenticated users only.              |
| [Instance audit events](../audit_events.md#retrieve-all-instance-audit-events) | `order_by=id`, `sort=desc` only  | Authenticated users only.                |
| [Package pipelines](../packages.md#list-package-pipelines)                     | `order_by=id`, `sort=desc` only  | Authenticated users only.                |
| [Project jobs](../jobs.md#list-project-jobs)                                   | `order_by=id`, `sort=desc` only  | Authenticated users only.                |
| [Project audit events](../audit_events.md#retrieve-all-project-audit-events)   | `order_by=id`, `sort=desc` only  | Authenticated users only.                |
| [Projects](../projects.md)                                                     | `order_by=id` only               | Authenticated and unauthenticated users. |
| [Users](../users.md)                                                           | `order_by=id`, `order_by=name`, `order_by=username`               | Authenticated and unauthenticated users.  [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419556) in GitLab 16.5. |
| [Registry Repository Tags](../container_registry.md) | `order_by=name`, `sort=asc`, or `sort=desc` only. | Authenticated users only. |
| [List repository tree](../repositories.md#list-repository-tree) |   |  Authenticated and unauthenticated users. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154897) in GitLab 17.1. |

### Pagination response headers

For performance reasons, if a query returns more than 10,000 records, GitLab
doesn't return the following headers:

- `x-total`.
- `x-total-pages`.
- `rel="last"` `link`

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
or as a [payload body](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-p3-payload-14#section-3.2).
GET requests usually send a query string, while PUT or POST requests usually
send the payload body:

- Query string:

  ```shell
  curl --request POST "https://gitlab/api/v4/projects?name=<example-name>&description=<example-description>"
  ```

- Request payload (JSON):

  ```shell
  curl --request POST --header "Content-Type: application/json" \
       --data '{"name":"<example-name>", "description":"<example-description>"}' "https://gitlab/api/v4/projects"
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
--form "file=@/path/to/somefile.txt" \
--form "override_params[visibility]=private" \
--form "override_params[some_other_param]=some_value" \
"https://gitlab.example.com/api/v4/projects/import"
```

### Array of hashes

`variables` is a parameter of type `array` containing hash key/value pairs
`[{ 'key': 'UPLOAD_TO_S3', 'value': 'true' }]`:

```shell
curl --globoff --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
"https://gitlab.example.com/api/v4/projects/169/pipeline?ref=master&variables[0][key]=VAR1&variables[0][value]=hello&variables[1][key]=VAR2&variables[1][value]=world"

curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--header "Content-Type: application/json" \
--data '{ "ref": "master", "variables": [ {"key": "VAR1", "value": "hello"}, {"key": "VAR2", "value": "world"} ] }' \
"https://gitlab.example.com/api/v4/projects/169/pipeline"
```

## `id` vs `iid`

Some resources have two similarly-named fields. For example, [issues](../issues.md),
[merge requests](../merge_requests.md), and [project milestones](../merge_requests.md).
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

## `null` vs `false`

In API responses, some boolean fields can have `null` values.
A `null` boolean has no default value and is neither `true` nor `false`.
GitLab treats `null` values in boolean fields the same as `false`.

In boolean arguments, you should only set `true` or `false` values (not `null`).

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
instead, due to a [W3 recommendation](https://www.w3.org/Addressing/URL/4_URI_Recommentations.html)
that causes a `+` to be interpreted as a space. For example, in an ISO 8601 date,
you may want to include a specific time in ISO 8601 format, such as:

```plaintext
2017-10-17T23:11:13.000+05:30
```

The correct encoding for the query parameter would be:

```plaintext
2017-10-17T23:11:13.000%2B05:30
```

## Third-party clients

You can integrate third-party API client libraries with GitLab. The following libraries are maintained by community members and not officially supported by GitLab.
Report bugs and feature proposals to the respective projects.

For questions about these integrations, use the [GitLab community forum](https://forum.gitlab.com/).

Administrators can monitor usage of these API clients by
[parsing logs](../../administration/logs/log_parsing.md#print-top-api-user-agents).

### `C#`

- [`GitLabApiClient`](https://github.com/nmklotas/GitLabApiClient)
- [`NGitLab`](https://github.com/ubisoft/NGitLab)

### Go

- [`go-gitlab`](https://github.com/xanzy/go-gitlab)

### Haskell

- [`gitlab-haskell`](https://hackage.haskell.org/package/gitlab-haskell)

### Java

- [`gitlab4j-api`](https://github.com/gmessner/gitlab4j-api)
- [`java-gitlab-api`](https://github.com/timols/java-gitlab-api)

### Node.js

- [`gitlab-yaac`](https://www.npmjs.com/package/gitlab-yaac)
- [`backbone-gitlab`](https://github.com/oreillymedia/backbone-gitlab)
- [`@gitbeaker/rest`](https://www.npmjs.com/package/@gitbeaker/rest)

### Perl

- [`GitLab::API::v4`](https://metacpan.org/pod/GitLab::API::v4)

### PHP

- [`php-gitlab-api`](https://github.com/GitLabPHP/Client)

### Python

- [`python-gitlab`](https://github.com/python-gitlab/python-gitlab)
  - Blog post: [Efficient DevSecOps workflows: Hands-on `python-gitlab` API automation](https://about.gitlab.com/blog/2023/02/01/efficient-devsecops-workflows-hands-on-python-gitlab-api-automation/)
- [`libsaas_gitlab`](https://gitlab.com/bor-sh-infrastructure/libsaas_gitlab)

### Ruby

- [Ruby wrapper and CLI for the GitLab REST API](https://github.com/NARKOZ/gitlab)

### Rust

- [`gitlab` crate](https://crates.io/crates/gitlab/)

### Swift

- [`RxGitLabKit`](https://github.com/Qase/RxGitLabKit)

## Rate limits

For administrator documentation on rate limit settings, see
[Rate limits](../../security/rate_limits.md). To find the settings that are
specifically used by GitLab.com, see
[GitLab.com-specific rate limits](../../user/gitlab_com/index.md#gitlabcom-specific-rate-limits).

## Content type

The GitLab API supports the `application/json` content type by default, though
some API endpoints also support `text/plain`.

API endpoints do not support `text/plain` by default, unless it's explicitly documented.

## Resolve requests detected as spam

REST API requests can be detected as spam. If a request is detected as spam and:

- A CAPTCHA service is not configured, an error response is returned. For example:

  ```json
  {"message":{"error":"Your snippet has been recognized as spam and has been discarded."}}
  ```

- A CAPTCHA service is configured, you receive a response with:
  - `needs_captcha_response` set to `true`.
  - The `spam_log_id` and `captcha_site_key` fields set.

  For example:

  ```json
  {"needs_captcha_response":true,"spam_log_id":42,"captcha_site_key":"REDACTED","message":{"error":"Your snippet has been recognized as spam. Please, change the content or solve the reCAPTCHA to proceed."}}
  ```

- Use the `captcha_site_key` to obtain a CAPTCHA response value using the appropriate CAPTCHA API.
  Only [Google reCAPTCHA v2](https://developers.google.com/recaptcha/docs/display) is supported.
- Resubmit the request with the `X-GitLab-Captcha-Response` and `X-GitLab-Spam-Log-Id` headers set.

```shell
export CAPTCHA_RESPONSE="<CAPTCHA response obtained from CAPTCHA service>"
export SPAM_LOG_ID="<spam_log_id obtained from initial REST response>"
curl --request POST --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" --header "X-GitLab-Captcha-Response: $CAPTCHA_RESPONSE" --header "X-GitLab-Spam-Log-Id: $SPAM_LOG_ID" "https://gitlab.example.com/api/v4/snippets?title=Title&file_name=FileName&content=Content&visibility=public"
```
