---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Packages API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/349418) support for [GitLab CI/CD job token](../ci/jobs/ci_job_token.md) authentication for the project-level API in GitLab 15.3.

The API documentation of [GitLab Packages](../administration/packages/_index.md).

## List packages

### For a project

Get a list of project packages. All package types are included in results. When
accessed without authentication, only packages of public projects are returned.
By default, packages with `default`, `deprecated`, and `error` status are returned. Use the `status` parameter to view other
packages.

```plaintext
GET /projects/:id/packages
```

| Attribute             | Type           | Required | Description |
|:----------------------|:---------------|:---------|:------------|
| `id`                  | integer/string | yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `order_by`            | string         | no       | The field to use as order. One of `created_at` (default), `name`, `version`, or `type`. |
| `sort`                | string         | no       | The direction of the order, either `asc` (default) for ascending order or `desc` for descending order. |
| `package_type`        | string         | no       | Filter the returned packages by type. One of `conan`, `maven`, `npm`, `pypi`, `composer`, `nuget`, `helm`, `terraform_module`, or `golang`. |
| `package_name`        | string         | no       | Filter the project packages with a fuzzy search by name. |
| `package_version`     | string         | no       | Filter the project packages by version. If used in combination with `include_versionless`, then no versionless packages are returned. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/349065) in GitLab 16.6. |
| `include_versionless` | boolean        | no       | When set to true, versionless packages are included in the response. |
| `status`              | string         | no       | Filter the returned packages by status. One of `default`, `hidden`, `processing`, `error`, or `pending_destruction`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages"
```

> **Deprecation:**
>
> The `pipelines` attribute in the response is deprecated in favor of the [list package pipelines endpoint](#list-package-pipelines), which was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/341950) in GitLab 16.0. If the package does not have any pipelines, the `pipelines` attribute is not included in the response. Otherwise, the `pipelines` attribute returns an empty array.

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

By default, the `GET` request returns 20 results, because the API is [paginated](rest/_index.md#pagination).

Although you can filter packages by status, working with packages that have a `processing` status
can result in malformed data or broken packages.

### For a group

Get a list of project packages at the group level.
When accessed without authentication, only packages of public projects are returned.
By default, packages with `default`, `deprecated`, and `error` status are returned. Use the `status` parameter to view other
packages.

```plaintext
GET /groups/:id/packages
```

| Attribute             | Type           | Required | Description |
|:----------------------|:---------------|:---------|:------------|
| `id`                  | integer/string | yes      | ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `exclude_subgroups`   | boolean        | no       | If the parameter is included as true, packages from projects from subgroups are not listed. Default is `false`. |
| `order_by`            | string         | no       | The field to use as order. One of `created_at` (default), `name`, `version`, `type`, or `project_path`. |
| `sort`                | string         | no       | The direction of the order, either `asc` (default) for ascending order or `desc` for descending order. |
| `package_type`        | string         | no       | Filter the returned packages by type. One of `conan`, `maven`, `npm`, `pypi`, `composer`, `nuget`, `helm`, or `golang`. |
| `package_name`        | string         | no       | Filter the project packages with a fuzzy search by name. |
| `package_version`     | string         | no       | Filter the returned packages by version. If used in combination with `include_versionless`, then no versionless packages are returned. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/349065) in GitLab 16.6. |
| `include_versionless` | boolean        | no       | When set to true, versionless packages are included in the response. |
| `status`              | string         | no       | Filter the returned packages by status. One of `default`, `hidden`, `processing`, `error`, or `pending_destruction`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/packages?exclude_subgroups=false"
```

> **Deprecation:**
>
> The `pipelines` attribute in the response is deprecated in favor of the [list package pipelines endpoint](#list-package-pipelines), which was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/341950) in GitLab 16.0. If the package does not have any pipelines, the `pipelines` attribute is not included in the response. Otherwise, the `pipelines` attribute returns an empty array.

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

By default, the `GET` request returns 20 results, because the API is [paginated](rest/_index.md#pagination).

The `_links` object contains the following properties:

- `web_path`: The path which you can visit in GitLab and see the details of the package.
- `delete_api_path`: The API path to delete the package. Only available if the request user has permission to do so.

Although you can filter packages by status, working with packages that have a `processing` status
can result in malformed data or broken packages.

## Get a project package

Get a single project package. Only packages with status `default` or `deprecated` are returned.

```plaintext
GET /projects/:id/packages/:package_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `package_id`      | integer | yes | ID of a package. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id"
```

> **Deprecation:**
>
> The `pipelines` attribute in the response is deprecated in favor of the [list package pipelines endpoint](#list-package-pipelines), which was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/341950) in GitLab 16.0. If the package does not have any pipelines, the `pipelines` attribute is not included in the response. Otherwise, the `pipelines` attribute returns an empty array.

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
  "last_downloaded_at": "2022-09-07T07:51:50.504Z",
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

- `web_path`: The path which you can visit in GitLab and see the details of the package. Only available if the package has status `default` or `deprecated`.
- `delete_api_path`: The API path to delete the package. Only available if the request user has permission to do so.

## List package files

Get a list of package files of a single package.

```plaintext
GET /projects/:id/packages/:package_id/package_files
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `package_id`      | integer | yes | ID of a package. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/package_files"
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

By default, the `GET` request returns 20 results, because the API is [paginated](rest/_index.md#pagination).

## List package pipelines

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/341950) in GitLab 16.1.

Get a list of pipelines for a single package. The results are sorted by `id` in descending order.

The results are [paginated](rest/_index.md#keyset-based-pagination) and return up to 20 records per page.

```plaintext
GET /projects/:id/packages/:package_id/pipelines
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `package_id`      | integer | yes | ID of a package. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/pipelines"
```

Example response:

```json
[
  {
    "id": 1,
    "iid": 1,
    "project_id": 9,
    "sha": "2b6127f6bb6f475c4e81afcc2251e3f941e554f9",
    "ref": "mytag",
    "status": "failed",
    "source": "push",
    "created_at": "2023-02-01T12:19:21.895Z",
    "updated_at": "2023-02-01T14:00:05.922Z",
    "web_url": "http://gdk.test:3001/feature-testing/composer-repository/-/pipelines/1",
    "user": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url": "http://gdk.test:3001/root"
    }
  },
  {
    "id": 2,
    "iid": 2,
    "project_id": 9,
    "sha": "e564015ac6cb3d8617647802c875b27d392f72a6",
    "ref": "main",
    "status": "canceled",
    "source": "push",
    "created_at": "2023-02-01T12:23:23.694Z",
    "updated_at": "2023-02-01T12:26:28.635Z",
    "web_url": "http://gdk.test:3001/feature-testing/composer-repository/-/pipelines/2",
    "user": {
      "id": 1,
      "username": "root",
      "name": "Administrator",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
      "web_url": "http://gdk.test:3001/root"
    }
  }
]
```

## Delete a project package

Deletes a project package.

```plaintext
DELETE /projects/:id/packages/:package_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `package_id`      | integer | yes | ID of a package. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id"
```

Can return the following status codes:

- `204 No Content`, if the package was deleted successfully.
- `404 Not Found`, if the package was not found.

If [request forwarding](../user/packages/package_registry/supported_functionality.md#forwarding-requests) is enabled,
deleting a package can introduce a [dependency confusion risk](../user/packages/package_registry/supported_functionality.md#deleting-packages).

## Delete a package file

WARNING:
Deleting a package file may corrupt your package making it unusable or unpullable from your package
manager client. When deleting a package file, be sure that you understand what you're doing.

Delete a package file:

```plaintext
DELETE /projects/:id/packages/:package_id/package_files/:package_file_id
```

| Attribute         | Type           | Required | Description |
| ----------------- | -------------- | -------- | ----------- |
| `id`              | integer/string | yes | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `package_id`      | integer        | yes | ID of a package. |
| `package_file_id` | integer        | yes | ID of a package file. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/packages/:package_id/package_files/:package_file_id"
```

Can return the following status codes:

- `204 No Content`: The package was deleted successfully.
- `403 Forbidden`: The user does not have permission to delete the file.
- `404 Not Found`: The package or package file was not found.
