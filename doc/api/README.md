# GitLab API

Automate GitLab via a simple and powerful API. All definitions can be found
under [`/lib/api`](https://gitlab.com/gitlab-org/gitlab-ce/tree/master/lib/api).

## Resources

Documentation for various API resources can be found separately in the
following locations:

- [Award Emoji](award_emoji.md)
- [Branches](branches.md)
- [Broadcast Messages](broadcast_messages.md)
- [Builds](builds.md)
- [Build Triggers](build_triggers.md)
- [Build Variables](build_variables.md)
- [Commits](commits.md)
- [Deployments](deployments.md)
- [Deploy Keys](deploy_keys.md)
- [Groups](groups.md)
- [Group Access Requests](access_requests.md)
- [Group Members](members.md)
- [Issues](issues.md)
- [Keys](keys.md)
- [Labels](labels.md)
- [Merge Requests](merge_requests.md)
- [Milestones](milestones.md)
- [Open source license templates](licenses.md)
- [Namespaces](namespaces.md)
- [Notes](notes.md) (comments)
- [Notification settings](notification_settings.md)
- [Pipelines](pipelines.md)
- [Projects](projects.md) including setting Webhooks
- [Project Access Requests](access_requests.md)
- [Project Members](members.md)
- [Project Snippets](project_snippets.md)
- [Repositories](repositories.md)
- [Repository Files](repository_files.md)
- [Runners](runners.md)
- [Services](services.md)
- [Session](session.md)
- [Settings](settings.md)
- [Sidekiq metrics](sidekiq_metrics.md)
- [System Hooks](system_hooks.md)
- [Tags](tags.md)
- [Todos](todos.md)
- [Users](users.md)
- [Validate CI configuration](ci/lint.md)

### Internal CI API

The following documentation is for the [internal CI API](ci/README.md):

- [Builds](ci/builds.md)
- [Runners](ci/runners.md)

## Authentication

All API requests require authentication via a session cookie or token. There are
three types of tokens available: private tokens, OAuth 2 tokens, and personal
access tokens.

If authentication information is invalid or omitted, an error message will be
returned with status code `401`:

```json
{
  "message": "401 Unauthorized"
}
```

### Private Tokens

You need to pass a `private_token` parameter via query string or header. If passed as a
header, the header name must be `PRIVATE-TOKEN` (uppercase and with a dash instead of
an underscore). You can find or reset your private token in your account page
(`/profile/account`).

### OAuth 2 Tokens

You can use an OAuth 2 token to authenticate with the API by passing it either in the
`access_token` parameter or in the `Authorization` header.

Example of using the OAuth2 token in the header:

```shell
curl --header "Authorization: Bearer OAUTH-TOKEN" https://gitlab.example.com/api/v3/projects
```

Read more about [GitLab as an OAuth2 client](oauth2.md).

### Personal Access Tokens

> [Introduced][ce-3749] in GitLab 8.8.

You can create as many personal access tokens as you like from your GitLab
profile (`/profile/personal_access_tokens`); perhaps one for each application
that needs access to the GitLab API.

Once you have your token, pass it to the API using either the `private_token`
parameter or the `PRIVATE-TOKEN` header.


### Session Cookie

When signing in to GitLab as an ordinary user, a `_gitlab_session` cookie is
set. The API will use this cookie for authentication if it is present, but using
the API to generate a new session cookie is currently not supported.

## Basic Usage

API requests should be prefixed with `api` and the API version. The API version
is defined in [`lib/api.rb`][lib-api-url].

Example of a valid API request:

```shell
GET https://gitlab.example.com/api/v3/projects?private_token=9koXpg98eAheJpvBs5tK
```

Example of a valid API request using cURL and authentication via header:

```shell
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects"
```

The API uses JSON to serialize data. You don't need to specify `.json` at the
end of an API URL.

## Status codes

The API is designed to return different status codes according to context and
action. This way, if a request results in an error, the caller is able to get
insight into what went wrong.

The following table gives an overview of how the API functions generally behave.

| Request type | Description |
| ------------ | ----------- |
| `GET`   | Access one or more resources and return the result as JSON. |
| `POST`  | Return `201 Created` if the resource is successfully created and return the newly created resource as JSON. |
| `GET` / `PUT` / `DELETE` | Return `200 OK` if the resource is accessed, modified or deleted successfully. The (modified) result is returned as JSON. |
| `DELETE` | Designed to be idempotent, meaning a request to a resource still returns `200 OK` even it was deleted before or is not available. The reasoning behind this, is that the user is not really interested if the resource existed before or not. |

The following table shows the possible return codes for API requests.

| Return values | Description |
| ------------- | ----------- |
| `200 OK` | The `GET`, `PUT` or `DELETE` request was successful, the resource(s) itself is returned as JSON. |
| `201 Created` | The `POST` request was successful and the resource is returned as JSON. |
| `304 Not Modified` | Indicates that the resource has not been modified since the last request. |
| `400 Bad Request` | A required attribute of the API request is missing, e.g., the title of an issue is not given. |
| `401 Unauthorized` | The user is not authenticated, a valid [user token](#authentication) is necessary. |
| `403 Forbidden` | The request is not allowed, e.g., the user is not allowed to delete a project. |
| `404 Not Found` | A resource could not be accessed, e.g., an ID for a resource could not be found. |
| `405 Method Not Allowed` | The request is not supported. |
| `409 Conflict` | A conflicting resource already exists, e.g., creating a project with a name that already exists. |
| `422 Unprocessable` | The entity could not be processed. |
| `500 Server Error` | While handling the request something went wrong server-side. |

## Sudo

All API requests support performing an API call as if you were another user,
provided your private token is from an administrator account. You need to pass
the `sudo` parameter either via query string or a header with an ID/username of
the user you want to perform the operation as. If passed as a header, the
header name must be `SUDO` (uppercase).

If a non administrative `private_token` is provided, then an error message will
be returned with status code `403`:

```json
{
  "message": "403 Forbidden - Must be admin to use sudo"
}
```

If the sudo user ID or username cannot be found, an error message will be
returned with status code `404`:

```json
{
  "message": "404 Not Found: No user id or username for: <id/username>"
}
```

---

Example of a valid API call and a request using cURL with sudo request,
providing a username:

```shell
GET /projects?private_token=9koXpg98eAheJpvBs5tK&sudo=username
```

```shell
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --header "SUDO: username" "https://gitlab.example.com/api/v3/projects"
```

Example of a valid API call and a request using cURL with sudo request,
providing an ID:

```shell
GET /projects?private_token=9koXpg98eAheJpvBs5tK&sudo=23
```

```shell
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --header "SUDO: 23" "https://gitlab.example.com/api/v3/projects"
```

## Pagination

Sometimes the returned result will span across many pages. When listing
resources you can pass the following parameters:

| Parameter | Description |
| --------- | ----------- |
| `page`    | Page number (default: `1`) |
| `per_page`| Number of items to list per page (default: `20`, max: `100`) |

In the example below, we list 50 [namespaces](namespaces.md) per page.

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/namespaces?per_page=50
```

### Pagination Link header

[Link headers](http://www.w3.org/wiki/LinkHeader) are sent back with each
response. They have `rel` set to prev/next/first/last and contain the relevant
URL. Please use these links instead of generating your own URLs.

In the cURL example below, we limit the output to 3 items per page (`per_page=3`)
and we request the second page (`page=2`) of [comments](notes.md) of the issue
with ID `8` which belongs to the project with ID `8`:

```bash
curl --head --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/8/issues/8/notes?per_page=3&page=2
```

The response will then be:

```
HTTP/1.1 200 OK
Cache-Control: no-cache
Content-Length: 1103
Content-Type: application/json
Date: Mon, 18 Jan 2016 09:43:18 GMT
Link: <https://gitlab.example.com/api/v3/projects/8/issues/8/notes?page=1&per_page=3>; rel="prev", <https://gitlab.example.com/api/v3/projects/8/issues/8/notes?page=3&per_page=3>; rel="next", <https://gitlab.example.com/api/v3/projects/8/issues/8/notes?page=1&per_page=3>; rel="first", <https://gitlab.example.com/api/v3/projects/8/issues/8/notes?page=3&per_page=3>; rel="last"
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

## `id` vs `iid`

When you work with the API, you may notice two similar fields in API entities:
`id` and `iid`. The main difference between them is scope.

For example, an issue might have `id: 46` and `iid: 5`.

| Parameter | Description |
| --------- | ----------- |
| `id`  | Is unique across all issues and is used for any API call |
| `iid` | Is unique only in scope of a single project. When you browse issues or merge requests with the Web UI, you see the `iid` |

That means that if you want to get an issue via the API you should use the `id`:

```bash
GET /projects/42/issues/:id
```

On the other hand, if you want to create a link to a web page you should use
the `iid`:

```bash
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

## Clients

There are many unofficial GitLab API Clients for most of the popular
programming languages. Visit the [GitLab website] for a complete list.

[GitLab website]: https://about.gitlab.com/applications/#api-clients "Clients using the GitLab API"
[lib-api-url]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/lib/api/api.rb
[ce-3749]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3749
