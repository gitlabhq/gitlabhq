# Packages API **(PREMIUM)**

This is the API docs of [GitLab Packages](../administration/packages/index.md).

## List packages

### Within a project

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/9259) in GitLab 11.8.

Get a list of project packages. Both Maven and NPM packages are included in results.
When accessed without authentication, only packages of public projects are returned.

```
GET /projects/:id/packages
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/packages
```

Example response:

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven"
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm"
  }
]
```

By default, the `GET` request will return 20 results, since the API is [paginated](README.md#pagination).

### Within a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/18871) in GitLab 12.5.

Get a list of project packages at the group level.
When accessed without authentication, only packages of public projects are returned.

```
GET /groups/:id/packages
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the group](README.md#namespaced-path-encoding). |
| `exclude_subgroups` | boolean | false | If the param is included as true, packages from projects from subgroups are not listed. Default is `false`. |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/:id/packages?exclude_subgroups=true
```

Example response:

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven"
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm"
  }
]
```

By default, the `GET` request will return 20 results, since the API is [paginated](README.md#pagination).

## Get a project package

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/9667) in GitLab 11.9.

Get a single project package.

```
GET /projects/:id/packages/:package_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding). |
| `package_id`      | integer | yes | ID of a package. |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/packages/:package_id
```

Example response:

```json
{
  "id": 1,
  "name": "com/mycompany/my-app",
  "version": "1.0-SNAPSHOT",
  "package_type": "maven"
}
```

## List package files

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/9305) in GitLab 11.8.

Get a list of package files of a single package.

```
GET /projects/:id/packages/:package_id/package_files
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `package_id`      | integer | yes | ID of a package. |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/packages/4/package_files
```

Example response:

```json
[
  {
    "id": 25,
    "package_id": 4,
    "created_at": "2018-11-07T15:25:52.199Z",
    "file_name": "my-app-1.5-20181107.152550-1.jar",
    "size": 2421,
    "file_md5": "58e6a45a629910c6ff99145a688971ac",
    "file_sha1": "ebd193463d3915d7e22219f52740056dfd26cbfe"
  },
  {
    "id": 26,
    "package_id": 4,
    "created_at": "2018-11-07T15:25:56.776Z",
    "file_name": "my-app-1.5-20181107.152550-1.pom",
    "size": 1122,
    "file_md5": "d90f11d851e17c5513586b4a7e98f1b2",
    "file_sha1": "9608d068fe88aff85781811a42f32d97feb440b5"
  },
  {
    "id": 27,
    "package_id": 4,
    "created_at": "2018-11-07T15:26:00.556Z",
    "file_name": "maven-metadata.xml",
    "size": 767,
    "file_md5": "6dfd0cce1203145a927fef5e3a1c650c",
    "file_sha1": "d25932de56052d320a8ac156f745ece73f6a8cd2"
  }
]
```

By default, the `GET` request will return 20 results, since the API is [paginated](README.md#pagination).

## Delete a project package

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/9623) in GitLab 11.9.

Deletes a project package.

```
DELETE /projects/:id/packages/:package_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `package_id`      | integer | yes | ID of a package. |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/packages/:package_id
```

Can return the following status codes:

- `204 No Content`, if the package was deleted successfully.
- `404 Not Found`, if the package was not found.
