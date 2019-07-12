# GitLab API

Automate GitLab via a simple and powerful API.

The main GitLab API is a [REST](https://en.wikipedia.org/wiki/Representational_state_transfer) API. Therefore, documentation in this section assumes knowledge of REST concepts.

## API resources

Available API resources can be grouped in the following contexts:

- [Projects](#project-resources).
- [Groups](#group-resources).
- [Standalone](#standalone-resources).

See also:

- [V3 to V4](v3_to_v4.md).
- Adding [deploy keys for multiple projects](deploy_key_multiple_projects.md).

### Project resources

The following API resources are available in the project context:

| Resource                                                            | Available endpoints                                                                                                                                                                                   |
|:--------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Access requests](access_requests.md)                               | `/projects/:id/access_requests` (also available for groups)                                                                                                                                           |
| [Award emoji](award_emoji.md)                                       | `/projects/:id/issues/.../award_emoji`, `/projects/:id/merge_requests/.../award_emoji`, `/projects/:id/snippets/.../award_emoji`                                                                      |
| [Branches](branches.md)                                             | `/projects/:id/repository/branches/`, `/projects/:id/repository/merged_branches`                                                                                                                      |
| [Commits](commits.md)                                               | `/projects/:id/repository/commits`, `/projects/:id/statuses`                                                                                                                                          |
| [Container Registry](container_registry.md)                         | `/projects/:id/registry/repositories`                                                                                                                                                                 |
| [Custom attributes](custom_attributes.md)                           | `/projects/:id/custom_attributes` (also available for groups and users)                                                                                                                               |
| [Deploy keys](deploy_keys.md)                                       | `/projects/:id/deploy_keys` (also available standalone)                                                                                                                                               |
| [Deployments](deployments.md)                                       | `/projects/:id/deployments`                                                                                                                                                                           |
| [Discussions](discussions.md) (threaded comments)                   | `/projects/:id/issues/.../discussions`, `/projects/:id/snippets/.../discussions`, `/projects/:id/merge_requests/.../discussions`, `/projects/:id/commits/.../discussions` (also available for groups) |
| [Environments](environments.md)                                     | `/projects/:id/environments`                                                                                                                                                                          |
| [Events](events.md)                                                 | `/projects/:id/events` (also available for users and standalone)                                                                                                                                      |
| [Issues](issues.md)                                                 | `/projects/:id/issues` (also available for groups and standalone)                                                                                                                                     |
| [Issues Statistics](issues_statistics.md)                           | `/projects/:id/issues_statistics` (also available for groups and standalone)                                                                                                                          |
| [Issue boards](boards.md)                                           | `/projects/:id/boards`                                                                                                                                                                                |
| [Issue links](issue_links.md) **(STARTER)**                         | `/projects/:id/issues/.../links`                                                                                                                                                                      |
| [Jobs](jobs.md)                                                     | `/projects/:id/jobs`, `/projects/:id/pipelines/.../jobs`                                                                                                                                              |
| [Labels](labels.md)                                                 | `/projects/:id/labels`                                                                                                                                                                                |
| [Managed licenses](managed_licenses.md) **(ULTIMATE)**              | `/projects/:id/managed_licenses`                                                                                                                                                                      |
| [Members](members.md)                                               | `/projects/:id/members` (also available for groups)                                                                                                                                                   |
| [Merge request approvals](merge_request_approvals.md) **(STARTER)** | `/projects/:id/approvals`, `/projects/:id/merge_requests/.../approvals`                                                                                                                               |
| [Merge requests](merge_requests.md)                                 | `/projects/:id/merge_requests` (also available for groups and standalone)                                                                                                                             |
| [Notes](notes.md) (comments)                                        | `/projects/:id/issues/.../notes`, `/projects/:id/snippets/.../notes`, `/projects/:id/merge_requests/.../notes` (also available for groups)                                                            |
| [Notification settings](notification_settings.md)                   | `/projects/:id/notification_settings` (also available for groups and standalone)                                                                                                                      |
| [Packages](packages.md) **(PREMIUM)**                               | `/projects/:id/packages`                                                                                                                                                                              |
| [Pages domains](pages_domains.md)                                   | `/projects/:id/pages` (also available standalone)                                                                                                                                                     |
| [Pipelines](pipelines.md)                                           | `/projects/:id/pipelines`                                                                                                                                                                             |
| [Pipeline schedules](pipeline_schedules.md)                         | `/projects/:id/pipeline_schedules`                                                                                                                                                                    |
| [Pipeline triggers](pipeline_triggers.md)                           | `/projects/:id/triggers`                                                                                                                                                                              |
| [Projects](projects.md) including setting Webhooks                  | `/projects`, `/projects/:id/hooks` (also available for users)                                                                                                                                         |
| [Project badges](project_badges.md)                                 | `/projects/:id/badges`                                                                                                                                                                                |
| [Project clusters](project_clusters.md)                             | `/projects/:id/clusters`                                                                                                                                                                              |
| [Project-level variables](project_level_variables.md)               | `/projects/:id/variables`                                                                                                                                                                             |
| [Project import/export](project_import_export.md)                   | `/projects/:id/export`, `/projects/import`, `/projects/:id/import`                                                                                                                                    |
| [Project milestones](milestones.md)                                 | `/projects/:id/milestones`                                                                                                                                                                            |
| [Project snippets](project_snippets.md)                             | `/projects/:id/snippets`                                                                                                                                                                              |
| [Project templates](project_templates.md)                           | `/projects/:id/templates`                                                                                                                                                                             |
| [Protected branches](protected_branches.md)                         | `/projects/:id/protected_branches`                                                                                                                                                                    |
| [Protected tags](protected_tags.md)                                 | `/projects/:id/protected_tags`                                                                                                                                                                        |
| [Releases](releases/index.md)                                       | `/projects/:id/releases`                                                                                                                                                                              |
| [Release links](releases/links.md)                                  | `/projects/:id/releases/.../assets/links`                                                                                                                                                             |
| [Repositories](repositories.md)                                     | `/projects/:id/repository`                                                                                                                                                                            |
| [Repository files](repository_files.md)                             | `/projects/:id/repository/files`                                                                                                                                                                      |
| [Repository submodules](repository_submodules.md)                   | `/projects/:id/repository/submodules`                                                                                                                                                                 |
| [Resource label events](resource_label_events.md)                   | `/projects/:id/issues/.../resource_label_events`, `/projects/:id/merge_requests/.../resource_label_events` (also available for groups)                                                                |
| [Runners](runners.md)                                               | `/projects/:id/runners` (also available standalone)                                                                                                                                                   |
| [Search](search.md)                                                 | `/projects/:id/search` (also available for groups and standalone)                                                                                                                                     |
| [Services](services.md)                                             | `/projects/:id/services`                                                                                                                                                                              |
| [Tags](tags.md)                                                     | `/projects/:id/repository/tags`                                                                                                                                                                       |
| [Vulnerabilities](vulnerabilities.md) **(ULTIMATE)**                | `/projects/:id/vulnerabilities` (also available for groups)                                                                                                                                           |
| [Wikis](wikis.md)                                                   | `/projects/:id/wikis`                                                                                                                                                                                 |

### Group resources

The following API resources are available in the group context:

| Resource                                                         | Available endpoints                                                              |
|:-----------------------------------------------------------------|:---------------------------------------------------------------------------------|
| [Access requests](access_requests.md)                            | `/groups/:id/access_requests/` (also available for projects)                     |
| [Custom attributes](custom_attributes.md)                        | `/groups/:id/custom_attributes` (also available for projects and users)          |
| [Discussions](discussions.md) (threaded comments) **(ULTIMATE)** | `/groups/:id/epics/.../discussions` (also available for projects)                |
| [Epic issues](epic_issues.md) **(ULTIMATE)**                     | `/groups/:id/epics/.../issues`                                                   |
| [Epic links](epic_links.md) **(ULTIMATE)**                       | `/groups/:id/epics/.../epics`                                                    |
| [Epics](epics.md) **(ULTIMATE)**                                 | `/groups/:id/epics`                                                              |
| [Groups](groups.md)                                              | `/groups`, `/groups/.../subgroups`                                               |
| [Group badges](group_badges.md)                                  | `/groups/:id/badges`                                                             |
| [Group issue boards](group_boards.md)                            | `/groups/:id/boards`                                                             |
| [Group labels](group_labels.md)                                  | `/groups/:id/labels`                                                             |
| [Group-level variables](group_level_variables.md)                | `/groups/:id/variables`                                                          |
| [Group milestones](group_milestones.md)                          | `/groups/:id/milestones`                                                         |
| [Issues](issues.md)                                              | `/groups/:id/issues` (also available for projects and standalone)                |
| [Issues Statistics](issues_statistics.md)                        | `/groups/:id/issues_statistics` (also available for projects and standalone)     |
| [Members](members.md)                                            | `/groups/:id/members` (also available for projects)                              |
| [Merge requests](merge_requests.md)                              | `/groups/:id/merge_requests` (also available for projects and standalone)        |
| [Notes](notes.md) (comments)                                     | `/groups/:id/epics/.../notes` (also available for projects)                      |
| [Notification settings](notification_settings.md)                | `/groups/:id/notification_settings` (also available for projects and standalone) |
| [Resource label events](resource_label_events.md)                | `/groups/:id/epics/.../resource_label_events` (also available for projects)      |
| [Search](search.md)                                              | `/groups/:id/search` (also available for projects and standalone)                |

### Standalone resources

The following API resources are available outside of project and group contexts (including `/users`):

| Resource                                          | Available endpoints                                                     |
|:--------------------------------------------------|:------------------------------------------------------------------------|
| [Applications](applications.md)                   | `/applications`                                                         |
| [Avatar](avatar.md)                               | `/avatar`                                                               |
| [Broadcast messages](broadcast_messages.md)       | `/broadcast_messages`                                                   |
| [Code snippets](snippets.md)                      | `/snippets`                                                             |
| [Custom attributes](custom_attributes.md)         | `/users/:id/custom_attributes` (also available for groups and projects) |
| [Deploy keys](deploy_keys.md)                     | `/deploy_keys` (also available for projects)                            |
| [Events](events.md)                               | `/events`, `/users/:id/events` (also available for projects)            |
| [Feature flags](features.md)                      | `/features`                                                             |
| [Geo Nodes](geo_nodes.md) **(PREMIUM ONLY)**      | `/geo_nodes`                                                            |
| [Import repository from GitHub](import.md)        | `/import/github`                                                        |
| [Issues](issues.md)                               | `/issues` (also available for groups and projects)                      |
| [Issues Statistics](issues_statistics.md)         | `/issues_statistics` (also available for groups and projects)           |
| [Keys](keys.md)                                   | `/keys`                                                                 |
| [License](license.md) **(CORE ONLY)**             | `/license`                                                              |
| [Markdown](markdown.md)                           | `/markdown`                                                             |
| [Merge requests](merge_requests.md)               | `/merge_requests` (also available for groups and projects)              |
| [Namespaces](namespaces.md)                       | `/namespaces`                                                           |
| [Notification settings](notification_settings.md) | `/notification_settings` (also available for groups and projects)       |
| [Pages domains](pages_domains.md)                 | `/pages/domains` (also available for projects)                          |
| [Projects](projects.md)                           | `/users/:id/projects` (also available for projects)                     |
| [Runners](runners.md)                             | `/runners` (also available for projects)                                |
| [Search](search.md)                               | `/search` (also available for groups and projects)                      |
| [Settings](settings.md)                           | `/application/settings`                                                 |
| [Sidekiq metrics](sidekiq_metrics.md)             | `/sidekiq`                                                              |
| [Suggestions](suggestions.md)                     | `/suggestions`                                                          |
| [System hooks](system_hooks.md)                   | `/hooks`                                                                |
| [Todos](todos.md)                                 | `/todos`                                                                |
| [Users](users.md)                                 | `/users`                                                                |
| [Validate `.gitlab-ci.yml` file](lint.md)         | `/lint`                                                                 |
| [Version](version.md)                             | `/version`                                                              |

### Templates API resources

Endpoints are available for:

- [Dockerfile templates](templates/dockerfiles.md).
- [`.gitignore` templates](templates/gitignores.md).
- [GitLab CI YAML templates](templates/gitlab_ci_ymls.md).
- [Open source license templates](templates/licenses.md).

## SCIM **(SILVER ONLY)**

[GitLab.com Silver and above](https://about.gitlab.com/pricing/) provides an [SCIM API](scim.md) that implements [the RFC7644 protocol](https://tools.ietf.org/html/rfc7644) and provides
the `/Users` endpoint. The base URL is: `/api/scim/v2/groups/:group_path/Users/`.

## Road to GraphQL

[GraphQL](graphql/index.md) is available in GitLab, which will
allow deprecation of controller-specific endpoints.

GraphQL has a number of benefits:

1. We avoid having to maintain two different APIs.
1. Callers of the API can request only what they need.
1. It is versioned by default.

It will co-exist with the current v4 REST API. If we have a v5 API, this should
be a compatibility layer on top of GraphQL.

Although there were some patenting and licensing concerns with GraphQL, these
have been resolved to our satisfaction by the relicensing of the reference
implementations under MIT, and the use of the OWF license for the GraphQL
specification.

## Compatibility guidelines

The HTTP API is versioned using a single number, the current one being 4. This
number symbolizes the same as the major version number as described by
[SemVer](https://semver.org/). This mean that backward incompatible changes
will require this version number to change. However, the minor version is
not explicit. This allows for a stable API endpoint, but also means new
features can be added to the API in the same version number.

New features and bug fixes are released in tandem with a new GitLab, and apart
from incidental patch and security releases, are released on the 22nd of each
month. Backward incompatible changes (e.g. endpoints removal, parameters
removal etc.), as well as removal of entire API versions are done in tandem
with a major point release of GitLab itself. All deprecations and changes
between two versions should be listed in the documentation. For the changes
between v3 and v4; please read the [v3 to v4 documentation](v3_to_v4.md)

### Current status

Currently only API version v4 is available. Version v3 was removed in
[GitLab 11.0](https://gitlab.com/gitlab-org/gitlab-ce/issues/36819).

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
1. [Sudo](#sudo)

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
curl https://gitlab.example.com/api/v4/projects?private_token=<your_access_token>
```

Example of using the personal access token in a header:

```shell
curl --header "Private-Token: <your_access_token>" https://gitlab.example.com/api/v4/projects
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
[users API](users.md#create-an-impersonation-token) docs.

Impersonation tokens are used exactly like regular personal access tokens, and can be passed in either the
`private_token` parameter or the `Private-Token` header.

#### Disable impersonation

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/40385) in GitLab
11.6.

By default, impersonation is enabled. To disable impersonation:

**For Omnibus installations**

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['impersonation_enabled'] = false
   ```

1. Save the file and [reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure)
   GitLab for the changes to take effect.

To re-enable impersonation, remove this configuration and reconfigure GitLab.

---

**For installations from source**

1. Edit `config/gitlab.yml`:

   ```yaml
   gitlab:
     impersonation_enabled: false
   ```

1. Save the file and [restart](../administration/restart_gitlab.md#installations-from-source)
   GitLab for the changes to take effect.

To re-enable impersonation, remove this configuration and restart GitLab.

### Sudo

NOTE: **Note:**
Only available to [administrators](../user/permissions.md).

All API requests support performing an API call as if you were another user,
provided you are authenticated as an administrator with an OAuth or Personal Access Token that has the `sudo` scope.

You need to pass the `sudo` parameter either via query string or a header with an ID/username of
the user you want to perform the operation as. If passed as a header, the
header name must be `Sudo`.

NOTE: **Note:**
Usernames are case insensitive.

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
GET /projects?private_token=<your_access_token>&sudo=username
```

```shell
curl --header "Private-Token: <your_access_token>" --header "Sudo: username" "https://gitlab.example.com/api/v4/projects"
```

Example of a valid API call and a request using cURL with sudo request,
providing an ID:

```
GET /projects?private_token=<your_access_token>&sudo=23
```

```shell
curl --header "Private-Token: <your_access_token>" --header "Sudo: 23" "https://gitlab.example.com/api/v4/projects"
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
| `DELETE` | Returns `204 No Content` if the resource was deleted successfully. |

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
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces?per_page=50
```

### Pagination Link header

[Link headers](http://www.w3.org/wiki/LinkHeader) are sent back with each
response. They have `rel` set to prev/next/first/last and contain the relevant
URL. Please use these links instead of generating your own URLs.

In the cURL example below, we limit the output to 3 items per page (`per_page=3`)
and we request the second page (`page=2`) of [comments](notes.md) of the issue
with ID `8` which belongs to the project with ID `8`:

```bash
curl --head --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/8/issues/8/notes?per_page=3&page=2
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

CAUTION: **Caution:**
For performance reasons since
[GitLab 11.8](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/23931)
and **behind the `api_kaminari_count_with_limit`
[feature flag](../development/feature_flags.md)**, if the number of resources is
more than 10,000, the `X-Total` and `X-Total-Pages` headers as well as the
`rel="last"` `Link` are not present in the response headers.

## Namespaced path encoding

If using namespaced API calls, make sure that the `NAMESPACE/PROJECT_NAME` is
URL-encoded.

For example, `/` is represented by `%2F`:

```
GET /api/v4/projects/diaspora%2Fdiaspora
```

## Branches and tags name encoding

If your branch or tag contains a `/`, make sure the branch/tag name is
URL-encoded.

For example, `/` is represented by `%2F`:

```
GET /api/v4/projects/1/branches/my%2Fbranch/commits
```

## Encoding API parameters of `array` and `hash` types

We can call the API with `array` and `hash` types parameters as shown below:

### `array`

`import_sources` is a parameter of type `array`:

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
-d "import_sources[]=github" \
-d "import_sources[]=bitbucket" \
"https://gitlab.example.com/api/v4/some_endpoint
```

### `hash`

`override_params` is a parameter of type `hash`:

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--form "namespace=email" \
--form "path=impapi" \
--form "file=@/path/to/somefile.txt"
--form "override_params[visibility]=private" \
--form "override_params[some_other_param]=some_value" \
https://gitlab.example.com/api/v4/projects/import
```

### Array of hashes

`variables` is a parameter of type `array` containing hash key/value pairs `[{ 'key' => 'UPLOAD_TO_S3', 'value' => 'true' }]`:

```bash
curl --globoff --request POST --header "PRIVATE-TOKEN: ********************" \
"https://gitlab.example.com/api/v4/projects/169/pipeline?ref=master&variables[][key]=VAR1&variables[][value]=hello&variables[][key]=VAR2&variables[][value]=world"

curl --request POST --header "PRIVATE-TOKEN: ********************" \
--header "Content-Type: application/json" \
--data '{ "ref": "master", "variables": [ {"key": "VAR1", "value": "hello"}, {"key": "VAR2", "value": "world"} ] }' \
"https://gitlab.example.com/api/v4/projects/169/pipeline"
```

## `id` vs `iid`

 Some resources have two similarly-named fields. For example, [issues](issues.md), [merge requests](merge_requests.md), and [project milestones](merge_requests.md). The fields are:

- `id`: ID that is unique across all projects.
- `iid`: additional, internal ID that is unique in the scope of a single project.

NOTE: **Note:**
The `iid` is displayed in the web UI.

If a resource has the `iid` field and the `id` field, the `iid` field is usually used instead of `id` to fetch the resource.

For example, suppose a project with `id: 42` has an issue with `id: 46` and `iid: 5`. In this case:

- A valid API call to retrieve the issue is  `GET /projects/42/issues/5`
- An invalid API call to retrieve the issue is `GET /projects/42/issues/46`.

NOTE: **Note:**
Not all resources with the `iid` field are fetched by `iid`. For guidance on which field to use, see the documentation for the specific resource.

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
to a [W3 recommendation](http://www.w3.org/Addressing/URL/4_URI_Recommentations.html) that
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
