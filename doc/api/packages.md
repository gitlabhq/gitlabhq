---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Packages API

This is the API documentation of [GitLab Packages](../administration/packages/index.md).

## List packages

### Within a project

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/9259) in GitLab 11.8.

Get a list of project packages. All package types are included in results. When
accessed without authentication, only packages of public projects are returned.

```plaintext
GET /projects/:id/packages
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `order_by`| string | no | The field to use as order. One of `created_at` (default), `name`, `version`, or `type`. |
| `sort`    | string | no | The direction of the order, either `asc` (default) for ascending order or `desc` for descending order. |
| `package_type` | string | no | Filter the returned packages by type. One of `conan`, `maven`, `npm`, `pypi`, `composer`, `nuget`, `helm`, or `golang`. (_Introduced in GitLab 12.9_)
| `package_name` | string | no | Filter the project packages with a fuzzy search by name. (_Introduced in GitLab 12.9_)
| `include_versionless` | boolean | no | When set to true, versionless packages are included in the response. (_Introduced in GitLab 13.8_)
| `status` | string | no | Filter the returned packages by status. One of `default` (default), `hidden`, or `processing`. (_Introduced in GitLab 13.9_)

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven",
    "created_at": "2019-11-27T03:37:38.711Z"
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm",
    "created_at": "2019-11-27T03:37:38.711Z"
  },
  {
    "id": 3,
    "name": "Hello/0.1@mycompany/stable",
    "conan_package_name": "Hello",
    "version": "0.1",
    "package_type": "conan",
    "_links": {
      "web_path": "/foo/bar/-/packages/3",
      "delete_api_path": "https://gitlab.example.com/api/v4/projects/1/packages/3"
    },
    "created_at": "2029-12-16T20:33:34.316Z",
    "tags": []
  }
]
```

By default, the `GET` request returns 20 results, because the API is [paginated](index.md#pagination).

Although you can filter packages by status, working with packages that have a `processing` status
can result in malformed data or broken packages.

### Within a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18871) in GitLab 12.5.

Get a list of project packages at the group level.
When accessed without authentication, only packages of public projects are returned.

```plaintext
GET /groups/:id/packages
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the group](index.md#namespaced-path-encoding). |
| `exclude_subgroups` | boolean | false | If the parameter is included as true, packages from projects from subgroups are not listed. Default is `false`. |
| `order_by`| string | no | The field to use as order. One of `created_at` (default), `name`, `version`, `type`, or `project_path`. |
| `sort`    | string | no | The direction of the order, either `asc` (default) for ascending order or `desc` for descending order. |
| `package_type` | string | no | Filter the returned packages by type. One of `conan`, `maven`, `npm`, `pypi`, `composer`, `nuget`, `helm`, or `golang`. (_Introduced in GitLab 12.9_) |
| `package_name` | string | no | Filter the project packages with a fuzzy search by name. (_[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/30980) in GitLab 13.0_)
| `include_versionless` | boolean | no | When set to true, versionless packages are included in the response. (_Introduced in GitLab 13.8_)
| `status` | string | no | Filter the returned packages by status. One of `default` (default), `hidden`, or `processing`. (_Introduced in GitLab 13.9_)

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/packages?exclude_subgroups=false"
```

> **Deprecation:**
>
> The `pipeline` attribute in the response is deprecated in favor of `pipelines`, which was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44348) in GitLab 13.6. Both are available until 13.7.
> The `build_info` attribute in the response is deprecated in favor of `pipeline`, which was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28040) in GitLab 12.10.

Example response:

```json
[
  {
    "id": 1,
    "name": "com/mycompany/my-app",
    "version": "1.0-SNAPSHOT",
    "package_type": "maven",
    "_links": {
      "web_path": "/namespace1/project1/-/packages/1",
      "delete_api_path": "/namespace1/project1/-/packages/1"
    },
    "created_at": "2019-11-27T03:37:38.711Z",
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  },
  {
    "id": 2,
    "name": "@foo/bar",
    "version": "1.0.3",
    "package_type": "npm",
    "_links": {
      "web_path": "/namespace1/project1/-/packages/1",
      "delete_api_path": "/namespace1/project1/-/packages/1"
    },
    "created_at": "2019-11-27T03:37:38.711Z",
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  }
]
```

By default, the `GET` request returns 20 results, because the API is [paginated](index.md#pagination).

The `_links` object contains the following properties:

- `web_path`: The path which you can visit in GitLab and see the details of the package.
- `delete_api_path`: The API path to delete the package. Only available if the request user has permission to do so.

Although you can filter packages by status, working with packages that have a `processing` status
can result in malformed data or broken packages.

## Get a project package

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/9667) in GitLab 11.9.

Get a single project package.

```plaintext
GET /projects/:id/packages/:package_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `package_id`      | integer | yes | ID of a package. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id"
```

> **Deprecation:**
>
> The `pipeline` attribute in the response is deprecated in favor of `pipelines`, which was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44348) in GitLab 13.6. Both are available until 13.7.
> The `build_info` attribute in the response is deprecated in favor of `pipeline`, which was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28040) in GitLab 12.10.

Example response:

```json
{
  "id": 1,
  "name": "com/mycompany/my-app",
  "version": "1.0-SNAPSHOT",
  "package_type": "maven",
  "_links": {
    "web_path": "/namespace1/project1/-/packages/1",
    "delete_api_path": "/namespace1/project1/-/packages/1"
  },
  "created_at": "2019-11-27T03:37:38.711Z",
  "pipelines": [
    {
      "id": 123,
      "status": "pending",
      "ref": "new-pipeline",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "web_url": "https://example.com/foo/bar/pipelines/47",
      "created_at": "2016-08-11T11:28:34.085Z",
      "updated_at": "2016-08-11T11:32:35.169Z",
      "user": {
        "name": "Administrator",
        "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
      }
    }
  ],
  "versions": [
    {
      "id":2,
      "version":"2.0-SNAPSHOT",
      "created_at":"2020-04-28T04:42:11.573Z",
      "pipelines": [
        {
          "id": 234,
          "status": "pending",
          "ref": "new-pipeline",
          "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
          "web_url": "https://example.com/foo/bar/pipelines/58",
          "created_at": "2016-08-11T11:28:34.085Z",
          "updated_at": "2016-08-11T11:32:35.169Z",
          "user": {
            "name": "Administrator",
            "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
          }
        }
      ]
    }
  ]
}
```

The `_links` object contains the following properties:

- `web_path`: The path which you can visit in GitLab and see the details of the package.
- `delete_api_path`: The API path to delete the package. Only available if the request user has permission to do so.

## List package files

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/9305) in GitLab 11.8.

Get a list of package files of a single package.

```plaintext
GET /projects/:id/packages/:package_id/package_files
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `package_id`      | integer | yes | ID of a package. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages/4/package_files"
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
    "file_sha1": "ebd193463d3915d7e22219f52740056dfd26cbfe",
    "file_sha256": "a903393463d3915d7e22219f52740056dfd26cbfeff321b",
    "pipelines": [
      {
        "id": 123,
        "status": "pending",
        "ref": "new-pipeline",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "web_url": "https://example.com/foo/bar/pipelines/47",
        "created_at": "2016-08-11T11:28:34.085Z",
        "updated_at": "2016-08-11T11:32:35.169Z",
        "user": {
          "name": "Administrator",
          "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
        }
      }
    ]
  },
  {
    "id": 26,
    "package_id": 4,
    "created_at": "2018-11-07T15:25:56.776Z",
    "file_name": "my-app-1.5-20181107.152550-1.pom",
    "size": 1122,
    "file_md5": "d90f11d851e17c5513586b4a7e98f1b2",
    "file_sha1": "9608d068fe88aff85781811a42f32d97feb440b5",
    "file_sha256": "2987d068fe88aff85781811a42f32d97feb4f092a399"
  },
  {
    "id": 27,
    "package_id": 4,
    "created_at": "2018-11-07T15:26:00.556Z",
    "file_name": "maven-metadata.xml",
    "size": 767,
    "file_md5": "6dfd0cce1203145a927fef5e3a1c650c",
    "file_sha1": "d25932de56052d320a8ac156f745ece73f6a8cd2",
    "file_sha256": "ac849d002e56052d320a8ac156f745ece73f6a8cd2f3e82"
  }
]
```

By default, the `GET` request returns 20 results, because the API is [paginated](index.md#pagination).

## Delete a project package

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/9623) in GitLab 11.9.

Deletes a project package.

```plaintext
DELETE /projects/:id/packages/:package_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `package_id`      | integer | yes | ID of a package. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id"
```

Can return the following status codes:

- `204 No Content`, if the package was deleted successfully.
- `404 Not Found`, if the package was not found.

## Delete a package file

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32107) in GitLab 13.12.

WARNING:
Deleting a package file may corrupt your package making it unusable or unpullable from your package
manager client. When deleting a package file, be sure that you understand what you're doing.

Delete a package file:

```plaintext
DELETE /projects/:id/packages/:package_id/package_files/:package_file_id
```

| Attribute         | Type           | Required | Description |
| ----------------- | -------------- | -------- | ----------- |
| `id`              | integer/string | yes | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `package_id`      | integer        | yes | ID of a package. |
| `package_file_id` | integer        | yes | ID of a package file. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/package_files/:package_file_id"
```

Can return the following status codes:

- `204 No Content`: The package was deleted successfully.
- `403 Forbidden`: The user does not have permission to delete the file.
- `404 Not Found`: The package or package file was not found.
