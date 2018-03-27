# GitLab API

Automate GitLab via a simple and powerful API. All definitions can be found
under [`/lib/api`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/lib/api).

## Resources

Documentation for various API resources can be found separately in the
following locations:

- [Award Emoji](award_emoji.md)
- [Branches](branches.md)
- [Broadcast Messages](broadcast_messages.md)
- [Project-level Variables](project_level_variables.md)
- [Group-level Variables](group_level_variables.md)
- [Commits](commits.md)
- [Custom Attributes](custom_attributes.md)
- [Deployments](deployments.md)
- [Deploy Keys](deploy_keys.md)
- [Environments](environments.md)
- [Events](events.md)
- [Feature flags](features.md)
- [Gitignores templates](templates/gitignores.md)
- [GitLab CI Config templates](templates/gitlab_ci_ymls.md)
- [Groups](groups.md)
- [Group Access Requests](access_requests.md)
- [Group Badges](group_badges.md)
- [Group Members](members.md)
- [Issues](issues.md)
- [Issue Boards](boards.md)
- [Group Issue Boards](group_boards.md)
- [Jobs](jobs.md)
- [Keys](keys.md)
- [Labels](labels.md)
- [Merge Requests](merge_requests.md)
- [Project milestones](milestones.md)
- [Group milestones](group_milestones.md)
- [Namespaces](namespaces.md)
- [Notes](notes.md) (comments)
- [Discussions](discussions.md) (threaded comments)
- [Notification settings](notification_settings.md)
- [Open source license templates](templates/licenses.md)
- [Pages Domains](pages_domains.md)
- [Pipelines](pipelines.md)
- [Pipeline Triggers](pipeline_triggers.md)
- [Pipeline Schedules](pipeline_schedules.md)
- [Projects](projects.md) including setting Webhooks
- [Project Access Requests](access_requests.md)
- [Project Badges](project_badges.md)
- [Project import/export](project_import_export.md)
- [Project Members](members.md)
- [Project Snippets](project_snippets.md)
- [Protected Branches](protected_branches.md)
- [Repositories](repositories.md)
- [Repository Files](repository_files.md)
- [Runners](runners.md)
- [Search](search.md)
- [Services](services.md)
- [Settings](settings.md)
- [Sidekiq metrics](sidekiq_metrics.md)
- [System Hooks](system_hooks.md)
- [Tags](tags.md)
- [Todos](todos.md)
- [Users](users.md)
- [Validate CI configuration](lint.md)
- [V3 to V4](v3_to_v4.md)
- [Version](version.md)
- [Wikis](wikis.md)

## Road to GraphQL

Going forward, we will start on moving to
[GraphQL](http://graphql.org/learn/best-practices/) and deprecate the use of
controller-specific endpoints. GraphQL has a number of benefits:

1. We avoid having to maintain two different APIs.
2. Callers of the API can request only what they need.
3. It is versioned by default.

It will co-exist with the current v4 REST API. If we have a v5 API, this should
be a compatibility layer on top of GraphQL.

Although there were some patenting and licensing concerns with GraphQL, these
have been resolved to our satisfaction by the relicensing of the reference
implementations under MIT, and the use of the OWF license for the GraphQL
specification.

## Basic usage

API requests should be prefixed with `api` and the API version. The API version
is defined in [`lib/api.rb`][lib-api-url]. For example, the root of the v4 API
is at `/api/v4`.

Example of a valid API request using cURL:

```shell
curl "https://gitlab.example.com/api/v4/projects"
```

The API uses JSON to serialize data. You don't need to specify `.json` at the
end of an API URL.

## Authentication

Most API requests require authentication, or will only return public data when
authentication is not provided. For
those cases where it is not required, this will be mentioned in the documentation
for each individual endpoint. For example, the [`/projects/:id` endpoint](projects.md).

There are three ways to authenticate with the GitLab API:

1. [OAuth2 tokens](#oauth2-tokens)
1. [Personal access tokens](#personal-access-tokens)
1. [Session cookie](#session-cookie)

For admins who want to authenticate with the API as a specific user, or who want to build applications or scripts that do so, two options are available:
1. [Impersonation tokens](#impersonation-tokens)
2. [Sudo](#sudo)

If authentication information is invalid or omitted, an error message will be
returned with status code `401`:

```json
{
  "message": "401 Unauthorized"
}
```

### OAuth2 tokens

You can use an [OAuth2 token](oauth2.md) to authenticate with the API by passing it in either the
`access_token` parameter or the `Authorization` header.

Example of using the OAuth2 token in a parameter:

```shell
curl https://gitlab.example.com/api/v4/projects?access_token=OAUTH-TOKEN
```

Example of using the OAuth2 token in a header:

```shell
curl --header "Authorization: Bearer OAUTH-TOKEN" https://gitlab.example.com/api/v4/projects
```

Read more about [GitLab as an OAuth2 provider](oauth2.md).

### Personal access tokens

You can use a [personal access token][pat] to authenticate with the API by passing it in either the
`private_token` parameter or the `Private-Token` header.

Example of using the personal access token in a parameter:

```shell
curl https://gitlab.example.com/api/v4/projects?private_token=9koXpg98eAheJpvBs5tK
```

Example of using the personal access token in a header:

```shell
curl --header "Private-Token: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects
```

Read more about [personal access tokens][pat].

### Session cookie

When signing in to the main GitLab application, a `_gitlab_session` cookie is
set. The API will use this cookie for authentication if it is present, but using
the API to generate a new session cookie is currently not supported.

The primary user of this authentication method is the web frontend of GitLab itself,
which can use the API as the authenticated user to get a list of their projects,
for example, without needing to explicitly pass an access token.

### Impersonation tokens

> [Introduced][ce-9099] in GitLab 9.0. Needs admin permissions.

Impersonation tokens are a type of [personal access token][pat]
that can only be created by an admin for a specific user. They are a great fit
if you want to build applications or scripts that authenticate with the API as a specific user.

They are an alternative to directly using the user's password or one of their
personal access tokens, and to using the [Sudo](#sudo) feature, since the user's (or admin's, in the case of Sudo)
password/token may not be known or may change over time.

For more information, refer to the
[users API](users.md#retrieve-user-impersonation-tokens) docs.

Impersonation tokens are used exactly like regular personal access tokens, and can be passed in either the
`private_token` parameter or the `Private-Token` header.

### Sudo

> Needs admin permissions.

All API requests support performing an API call as if you were another user,
provided you are authenticated as an administrator with an OAuth or Personal Access Token that has the `sudo` scope.

You need to pass the `sudo` parameter either via query string or a header with an ID/username of
the user you want to perform the operation as. If passed as a header, the
header name must be `Sudo`.

If a non administrative access token is provided, an error message will
be returned with status code `403`:

```json
{
  "message": "403 Forbidden - Must be admin to use sudo"
}
```

If an access token without the `sudo` scope is provided, an error message will
be returned with status code `403`:

```json
{
  "error": "insufficient_scope",
  "error_description": "The request requires higher privileges than provided by the access token.",
  "scope": "sudo"
}
```

If the sudo user ID or username cannot be found, an error message will be
returned with status code `404`:

```json
{
  "message": "404 User with ID or username '123' Not Found"
}
```

---

Example of a valid API call and a request using cURL with sudo request,
providing a username:

```
GET /projects?private_token=9koXpg98eAheJpvBs5tK&sudo=username
```

```shell
curl --header "Private-Token: 9koXpg98eAheJpvBs5tK" --header "Sudo: username" "https://gitlab.example.com/api/v4/projects"
```

Example of a valid API call and a request using cURL with sudo request,
providing an ID:

```
GET /projects?private_token=9koXpg98eAheJpvBs5tK&sudo=23
```

```shell
curl --header "Private-Token: 9koXpg98eAheJpvBs5tK" --header "Sudo: 23" "https://gitlab.example.com/api/v4/projects"
```

## Status codes

The API is designed to return different status codes according to context and
action. This way, if a request results in an error, the caller is able to get
insight into what went wrong.

The following table gives an overview of how the API functions generally behave.

| Request type | Description |
| ------------ | ----------- |
| `GET`   | Access one or more resources and return the result as JSON. |
| `POST`  | Return `201 Created` if the resource is successfully created and return the newly created resource as JSON. |
| `GET` / `PUT` | Return `200 OK` if the resource is accessed or modified successfully. The (modified) result is returned as JSON. |
| `DELETE` | Returns `204 No Content` if the resuource was deleted successfully. |

The following table shows the possible return codes for API requests.

| Return values | Description |
| ------------- | ----------- |
| `200 OK` | The `GET`, `PUT` or `DELETE` request was successful, the resource(s) itself is returned as JSON. |
| `204 No Content` | The server has successfully fulfilled the request and that there is no additional content to send in the response payload body. |
| `201 Created` | The `POST` request was successful and the resource is returned as JSON. |
| `304 Not Modified` | Indicates that the resource has not been modified since the last request. |
| `400 Bad Request` | A required attribute of the API request is missing, e.g., the title of an issue is not given. |
| `401 Unauthorized` | The user is not authenticated, a valid [user token](#authentication) is necessary. |
| `403 Forbidden` | The request is not allowed, e.g., the user is not allowed to delete a project. |
| `404 Not Found` | A resource could not be accessed, e.g., an ID for a resource could not be found. |
| `405 Method Not Allowed` | The request is not supported. |
| `409 Conflict` | A conflicting resource already exists, e.g., creating a project with a name that already exists. |
| `412` | Indicates the request was denied. May happen if the `If-Unmodified-Since` header is provided when trying to delete a resource, which was modified in between. |
| `422 Unprocessable` | The entity could not be processed. |
| `500 Server Error` | While handling the request something went wrong server-side. |

## Pagination

Sometimes the returned result will span across many pages. When listing
resources you can pass the following parameters:

| Parameter | Description |
| --------- | ----------- |
| `page`    | Page number (default: `1`) |
| `per_page`| Number of items to list per page (default: `20`, max: `100`) |

In the example below, we list 50 [namespaces](namespaces.md) per page.

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/namespaces?per_page=50
```

### Pagination Link header

[Link headers](http://www.w3.org/wiki/LinkHeader) are sent back with each
response. They have `rel` set to prev/next/first/last and contain the relevant
URL. Please use these links instead of generating your own URLs.

In the cURL example below, we limit the output to 3 items per page (`per_page=3`)
and we request the second page (`page=2`) of [comments](notes.md) of the issue
with ID `8` which belongs to the project with ID `8`:

```bash
curl --head --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/8/issues/8/notes?per_page=3&page=2
```

The response will then be:

```
HTTP/1.1 200 OK
Cache-Control: no-cache
Content-Length: 1103
Content-Type: application/json
Date: Mon, 18 Jan 2016 09:43:18 GMT
Link: <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=1&per_page=3>; rel="prev", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=3&per_page=3>; rel="next", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=1&per_page=3>; rel="first", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=3&per_page=3>; rel="last"
Status: 200 OK
Vary: Origin
X-Next-Page: 3
X-Page: 2
X-Per-Page: 3
X-Prev-Page: 1
X-Request-Id: 732ad4ee-9870-4866-a199-a9db0cde3c86
X-Runtime: 0.108688
X-Total: 8
X-Total-Pages: 3
```

### Other pagination headers

Additional pagination headers are also sent back.

| Header | Description |
| ------ | ----------- |
| `X-Total`       | The total number of items |
| `X-Total-Pages` | The total number of pages |
| `X-Per-Page`    | The number of items per page |
| `X-Page`        | The index of the current page (starting at 1) |
| `X-Next-Page`   | The index of the next page |
| `X-Prev-Page`   | The index of the previous page |

## Namespaced path encoding

If using namespaced API calls, make sure that the `NAMESPACE/PROJECT_NAME` is
URL-encoded.

For example, `/` is represented by `%2F`:

```
GET /api/v4/projects/diaspora%2Fdiaspora
```

## Branches & tags name encoding

If your branch or tag contains a `/`, make sure the branch/tag name is
URL-encoded.

For example, `/` is represented by `%2F`:

```
GET /api/v4/projects/1/branches/my%2Fbranch/commits
```

## `id` vs `iid`

When you work with the API, you may notice two similar fields in API entities:
`id` and `iid`. The main difference between them is scope.

For example, an issue might have `id: 46` and `iid: 5`.

| Parameter | Description |
| --------- | ----------- |
| `id`  | Is unique across all issues and is used for any API call |
| `iid` | Is unique only in scope of a single project. When you browse issues or merge requests with the Web UI, you see the `iid` |

That means that if you want to get an issue via the API you should use the `id`:

```
GET /projects/42/issues/:id
```

On the other hand, if you want to create a link to a web page you should use
the `iid`:

```
GET /projects/42/issues/:iid
```

## Data validation and error reporting

When working with the API you may encounter validation errors, in which case
the API will answer with an HTTP `400` status.

Such errors appear in two cases:

- A required attribute of the API request is missing, e.g., the title of an
  issue is not given
- An attribute did not pass the validation, e.g., user bio is too long

When an attribute is missing, you will get something like:

```
HTTP/1.1 400 Bad Request
Content-Type: application/json
{
    "message":"400 (Bad request) \"title\" not given"
}
```

When a validation error occurs, error messages will be different. They will
hold all details of validation errors:

```
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

When you try to access an API URL that does not exist you will receive 404 Not Found.

```
HTTP/1.1 404 Not Found
Content-Type: application/json
{
    "error": "404 Not Found"
}
```

## Encoding `+` in ISO 8601 dates

If you need to include a `+` in a query parameter, you may need to use `%2B` instead due
a [W3 recommendation](http://www.w3.org/Addressing/URL/4_URI_Recommentations.html) that
causes a `+` to be interpreted as a space. For example, in an ISO 8601 date, you may want to pass
a time in Mountain Standard Time, such as:

```
2017-10-17T23:11:13.000+05:30
```

The correct encoding for the query parameter would be:

```
2017-10-17T23:11:13.000%2B05:30
```

## Clients

There are many unofficial GitLab API Clients for most of the popular
programming languages. Visit the [GitLab website] for a complete list.

[GitLab website]: https://about.gitlab.com/applications/#api-clients "Clients using the GitLab API"
[lib-api-url]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/lib/api/api.rb
[ce-3749]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3749
[ce-5951]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5951
[ce-9099]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/9099
[pat]: ../user/profile/personal_access_tokens.md
