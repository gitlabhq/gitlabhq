---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Deployments API

## List project deployments

Get a list of deployments in a project.

```plaintext
GET /projects/:id/deployments
```

| Attribute        | Type           | Required | Description                                                                                                     |
|------------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`             | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `order_by`       | string         | no       | Return deployments ordered by either one of `id`, `iid`, `created_at`, `updated_at` or `ref` fields. Default is `id`.    |
| `sort`           | string         | no       | Return deployments sorted in `asc` or `desc` order. Default is `asc`.                                            |
| `updated_after`  | datetime       | no       | Return deployments updated after the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `updated_before` | datetime       | no       | Return deployments updated before the specified date. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). |
| `environment`    | string         | no       | The [name of the environment](../ci/environments/index.md) to filter deployments by.       |
| `status`         | string         | no       | The status to filter deployments by. One of `created`, `running`, `success`, `failed`, `canceled`.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/deployments"
```

Example response:

```json
[
  {
    "created_at": "2016-08-11T07:36:40.222Z",
    "updated_at": "2016-08-11T07:38:12.414Z",
    "status": "created",
    "deployable": {
      "commit": {
        "author_email": "admin@example.com",
        "author_name": "Administrator",
        "created_at": "2016-08-11T09:36:01.000+02:00",
        "id": "99d03678b90d914dbb1b109132516d71a4a03ea8",
        "message": "Merge branch 'new-title' into 'main'\r\n\r\nUpdate README\r\n\r\n\r\n\r\nSee merge request !1",
        "short_id": "99d03678",
        "title": "Merge branch 'new-title' into 'main'\r"
      },
      "coverage": null,
      "created_at": "2016-08-11T07:36:27.357Z",
      "finished_at": "2016-08-11T07:36:39.851Z",
      "id": 657,
      "name": "deploy",
      "ref": "main",
      "runner": null,
      "stage": "deploy",
      "started_at": null,
      "status": "success",
      "tag": false,
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://gitlab.dev/root",
        "created_at": "2015-12-21T13:14:24.077Z",
        "bio": null,
        "location": null,
        "public_email": "",
        "skype": "",
        "linkedin": "",
        "twitter": "",
        "website_url": "",
        "organization": ""
      },
      "pipeline": {
        "created_at": "2016-08-11T02:12:10.222Z",
        "id": 36,
        "ref": "main",
        "sha": "99d03678b90d914dbb1b109132516d71a4a03ea8",
        "status": "success",
        "updated_at": "2016-08-11T02:12:10.222Z",
        "web_url": "http://gitlab.dev/root/project/pipelines/12"
      }
    },
    "environment": {
      "external_url": "https://about.gitlab.com",
      "id": 9,
      "name": "production"
    },
    "id": 41,
    "iid": 1,
    "ref": "main",
    "sha": "99d03678b90d914dbb1b109132516d71a4a03ea8",
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "web_url": "http://localhost:3000/root"
    }
  },
  {
    "created_at": "2016-08-11T11:32:35.444Z",
    "updated_at": "2016-08-11T11:34:01.123Z",
    "status": "created",
    "deployable": {
      "commit": {
        "author_email": "admin@example.com",
        "author_name": "Administrator",
        "created_at": "2016-08-11T13:28:26.000+02:00",
        "id": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "message": "Merge branch 'rename-readme' into 'main'\r\n\r\nRename README\r\n\r\n\r\n\r\nSee merge request !2",
        "short_id": "a91957a8",
        "title": "Merge branch 'rename-readme' into 'main'\r"
      },
      "coverage": null,
      "created_at": "2016-08-11T11:32:24.456Z",
      "finished_at": "2016-08-11T11:32:35.145Z",
      "id": 664,
      "name": "deploy",
      "ref": "main",
      "runner": null,
      "stage": "deploy",
      "started_at": null,
      "status": "success",
      "tag": false,
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "state": "active",
        "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
        "web_url": "http://gitlab.dev/root",
        "created_at": "2015-12-21T13:14:24.077Z",
        "bio": null,
        "location": null,
        "public_email": "",
        "skype": "",
        "linkedin": "",
        "twitter": "",
        "website_url": "",
        "organization": ""
      },
      "pipeline": {
        "created_at": "2016-08-11T07:43:52.143Z",
        "id": 37,
        "ref": "main",
        "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
        "status": "success",
        "updated_at": "2016-08-11T07:43:52.143Z",
        "web_url": "http://gitlab.dev/root/project/pipelines/13"
      }
    },
    "environment": {
      "external_url": "https://about.gitlab.com",
      "id": 9,
      "name": "production"
    },
    "id": 42,
    "iid": 2,
    "ref": "main",
    "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "id": 1,
      "name": "Administrator",
      "state": "active",
      "username": "root",
      "web_url": "http://localhost:3000/root"
    }
  }
]
```

## Get a specific deployment

```plaintext
GET /projects/:id/deployments/:deployment_id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `deployment_id` | integer | yes      | The ID of the deployment |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/deployments/1"
```

Example response:

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "updated_at": "2016-08-11T11:34:01.123Z",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": {
    "id": 664,
    "status": "success",
    "stage": "deploy",
    "name": "deploy",
    "ref": "main",
    "tag": false,
    "coverage": null,
    "created_at": "2016-08-11T11:32:24.456Z",
    "started_at": null,
    "finished_at": "2016-08-11T11:32:35.145Z",
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.dev/root",
      "created_at": "2015-12-21T13:14:24.077Z",
      "bio": null,
      "location": null,
      "skype": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": ""
    },
    "commit": {
      "id": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "short_id": "a91957a8",
      "title": "Merge branch 'rename-readme' into 'main'\r",
      "author_name": "Administrator",
      "author_email": "admin@example.com",
      "created_at": "2016-08-11T13:28:26.000+02:00",
      "message": "Merge branch 'rename-readme' into 'main'\r\n\r\nRename README\r\n\r\n\r\n\r\nSee merge request !2"
    },
    "pipeline": {
      "created_at": "2016-08-11T07:43:52.143Z",
      "id": 42,
      "ref": "main",
      "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
      "status": "success",
      "updated_at": "2016-08-11T07:43:52.143Z",
      "web_url": "http://gitlab.dev/root/project/pipelines/5"
    },
    "runner": null
  }
}
```

## Create a deployment

```plaintext
POST /projects/:id/deployments
```

| Attribute     | Type           | Required | Description                                                                                                     |
|---------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------|
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.|
| `environment` | string         | yes      | The [name of the environment](../ci/environments/index.md) to create the deployment for.                        |
| `sha`         | string         | yes      | The SHA of the commit that is deployed.                                                                         |
| `ref`         | string         | yes      | The name of the branch or tag that is deployed.                                                                 |
| `tag`         | boolean        | yes      | A boolean that indicates if the deployed ref is a tag (`true`) or not (`false`).                                |
| `status`      | string         | no       | The status to filter deployments by. One of `created`, `running`, `success`, `failed`, or `canceled`.           |

```shell
curl --data "environment=production&sha=a91957a858320c0e17f3a0eca7cfacbff50ea29a&ref=main&tag=false&status=success" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/deployments"
```

Example response:

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": null
}
```

## Update a deployment

```plaintext
PUT /projects/:id/deployments/:deployment_id
```

| Attribute        | Type           | Required | Description         |
|------------------|----------------|----------|---------------------|
| `id`             | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `deployment_id`  | integer        | yes      | The ID of the deployment to update. |
| `status`         | string         | no       | The new status of the deployment. One of `created`, `running`, `success`, `failed`, or `canceled`.           |

```shell
curl --request PUT --data "status=success" --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/deployments/42"
```

Example response:

```json
{
  "id": 42,
  "iid": 2,
  "ref": "main",
  "sha": "a91957a858320c0e17f3a0eca7cfacbff50ea29a",
  "created_at": "2016-08-11T11:32:35.444Z",
  "status": "success",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://localhost:3000/root"
  },
  "environment": {
    "id": 9,
    "name": "production",
    "external_url": "https://about.gitlab.com"
  },
  "deployable": null
}
```

## List of merge requests associated with a deployment

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/35739) in GitLab 12.7.

This API retrieves the list of merge requests shipped with a given deployment:

```plaintext
GET /projects/:id/deployments/:deployment_id/merge_requests
```

It supports the same parameters as the [Merge Requests API](merge_requests.md#list-merge-requests) and returns a response using the same format:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/deployments/42/merge_requests"
```
