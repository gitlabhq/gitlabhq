---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Runners API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This page describes endpoints for runners registered to an instance. To create a runner linked to the current user, see [Create a runner](users.md#create-a-runner-linked-to-a-user).

[Pagination](rest/_index.md#pagination) is available on the following API endpoints (they return 20 items by default):

```plaintext
GET /runners
GET /runners/all
GET /runners/:id/jobs
GET /projects/:id/runners
GET /groups/:id/runners
```

## Registration and authentication tokens

There are two tokens to take into account when connecting a runner with GitLab.

| Token | Description |
| ----- | ----------- |
| Registration token | Token used to [register the runner](https://docs.gitlab.com/runner/register/). It can be [obtained through GitLab](../ci/runners/_index.md). |
| Authentication token | Token used to authenticate the runner with the GitLab instance. The token is obtained automatically when you [register a runner](https://docs.gitlab.com/runner/register/) or by the Runners API when you manually [register a runner](#create-a-runner) or [reset the authentication token](#reset-runners-authentication-token-by-using-the-runner-id). You can also obtain the token by using the [`POST /user/runners`](users.md#create-a-runner-linked-to-a-user) endpoint. |

Here's an example of how the two tokens are used in runner registration:

1. You register the runner via the GitLab API using a registration token, and an
   authentication token is returned.
1. You use that authentication token and add it to the
   [runner's configuration file](https://docs.gitlab.com/runner/commands/#configuration-file):

   ```toml
   [[runners]]
     token = "<authentication_token>"
   ```

GitLab and the runner are then connected.

## List owned runners

Get a list of runners available to the user.

Prerequisites:

- You must be an administrator of or have the Owner role for the target namespace or project.
- For `instance_type`, you must be an administrator of the GitLab instance.

```plaintext
GET /runners
GET /runners?scope=active
GET /runners?type=project_type
GET /runners?status=online
GET /runners?paused=true
GET /runners?tag_list=tag1,tag2
```

| Attribute        | Type         | Required | Description                                                                                                                                                                                                          |
|------------------|--------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `scope`          | string       | no       | Deprecated: Use `type` or `status` instead. The scope of runners to return, one of: `active`, `paused`, `online` and `offline`; showing all runners if none provided                                                 |
| `type`           | string       | no       | The type of runners to return, one of: `instance_type`, `group_type`, `project_type`                                                                                                                                 |
| `status`         | string       | no       | The status of runners to return, one of: `online`, `offline`, `stale`, or `never_contacted`.<br/>Other possible values are the deprecated `active` and `paused`.<br/>Requesting `offline` runners might also return `stale` runners because `stale` is included in `offline`. |
| `paused`         | boolean      | no       | Whether to include only runners that are accepting or ignoring new jobs                                                                                                                                              |
| `tag_list`       | string array | no       | A list of runner tags                                                                                                                                                                                                |
| `version_prefix` | string       | no       | The prefix of the version of the runners to return. For example, `15.0`, `14`, `16.1.241`                                                                                                                            |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners"
```

NOTE:
The `active` and `paused` values in the `status` query parameter were deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). They are replaced by the `paused` query parameter.

NOTE:
The `active` attribute in the response was deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

NOTE:
The `ip_address` attribute in the response was deprecated
[in GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) and will be removed in
[a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).
This attribute will start returning an empty string in GitLab 17.0.
The `ipAddress` attribute can be found inside the respective runner manager, currently only available through the GraphQL
[`CiRunnerManager` type](graphql/reference/_index.md#cirunnermanager).

Example response:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "test-1-20150125",
        "id": 6,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": true,
        "status": "online"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "group_type",
        "name": null,
        "online": false,
        "status": "offline"
    }
]
```

## List all runners

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Get a list of all runners in the GitLab instance (project and shared). Access
is restricted to users with administrator access.

Prerequisites:

- You must be an administrator of or have the Owner role for the target namespace or project.
- For `instance_type`, you must be an administrator of the GitLab instance.

```plaintext
GET /runners/all
GET /runners/all?scope=online
GET /runners/all?type=project_type
GET /runners/all?status=online
GET /runners/all?paused=true
GET /runners/all?tag_list=tag1,tag2
```

| Attribute        | Type         | Required | Description                                                                                                                                                                                                             |
|------------------|--------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `scope`          | string       | no       | Deprecated: Use `type` or `status` instead. The scope of runners to return, one of: `specific`, `shared`, `active`, `paused`, `online` and `offline`; showing all runners if none provided                              |
| `type`           | string       | no       | The type of runners to return, one of: `instance_type`, `group_type`, `project_type`                                                                                                                                    |
| `status`         | string       | no       | The status of runners to return, one of: `online`, `offline`, `stale`, or `never_contacted`.<br/>Other possible values are the deprecated `active` and `paused`.<br/>Requesting `offline` runners might also return `stale` runners because `stale` is included in `offline`. |
| `paused`         | boolean      | no       | Whether to include only runners that are accepting or ignoring new jobs                                                                                                                                                 |
| `tag_list`       | string array | no       | A list of runner tags                                                                                                                                                                                                   |
| `version_prefix` | string       | no       | The prefix of the version of the runners to return. For example, `15.0`, `16.1.241`                                                                                                                               |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/all"
```

NOTE:
The `active` and `paused` values in the `status` query parameter were deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). They are replaced by the `paused` query parameter.

NOTE:
The `active` attribute in the response was deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

NOTE:
The `ip_address` attribute in the response was deprecated
[in GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) and will be removed in
[a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).
This attribute will start returning an empty string in GitLab 17.0.
The `ipAddress` attribute can be found inside the respective runner manager, currently only available through the GraphQL
[`CiRunnerManager` type](graphql/reference/_index.md#cirunnermanager).

Example response:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "shared-runner-1",
        "id": 1,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": true,
        "status": "online"
    },
    {
        "active": true,
        "paused": false,
        "description": "shared-runner-2",
        "id": 3,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": false,
        "status": "offline"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-1-20150125",
        "id": 6,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": true,
        "status": "paused"
    },
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "group_type",
        "name": null,
        "online": false,
        "status": "offline"
    }
]
```

To view more than the first 20 runners, use [pagination](rest/_index.md#pagination).

## Get runner's details

Get details of a runner.

Instance-level runner details via this endpoint are available to all authenticated users.

Prerequisites:

- You must have at least the Developer role for the target namespace or project.
- An access token with the `manage_runner` scope and the appropriate role.

```plaintext
GET /runners/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a runner  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6"
```

NOTE:
The `token` attribute in the response was deprecated [in GitLab 12.10](https://gitlab.com/gitlab-org/gitlab/-/issues/214320)
and removed in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/214322).

NOTE:
The `active` attribute in the response was deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

NOTE:
The `ip_address` attribute in the response was deprecated
[in GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) and will be removed in
[a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).
This attribute will start returning an empty string in GitLab 17.0.
The `ipAddress` attribute can be found inside the respective runner manager, currently only available through the GraphQL
[`CiRunnerManager` type](graphql/reference/_index.md#cirunnermanager).

NOTE:
The `version`, `revision`, `platform`, and `architecture` attributes in the response were deprecated
[in GitLab 17.0](https://gitlab.com/gitlab-org/gitlab/-/issues/457128) and will be removed in
[a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).
These attributes will start returning an empty string in GitLab 18.0.
The same attributes can be found inside the respective runner manager, currently only available through the GraphQL
[`CiRunnerManager` type](graphql/reference/_index.md#cirunnermanager).

Example response:

```json
{
    "active": true,
    "paused": false,
    "architecture": null,
    "description": "test-1-20150125",
    "id": 6,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "project_type",
    "contacted_at": "2016-01-25T16:39:48.066Z",
    "maintenance_note": null,
    "name": null,
    "online": true,
    "status": "online",
    "platform": null,
    "projects": [
        {
            "id": 1,
            "name": "GitLab Community Edition",
            "name_with_namespace": "GitLab.org / GitLab Community Edition",
            "path": "gitlab-foss",
            "path_with_namespace": "gitlab-org/gitlab-foss"
        }
    ],
    "revision": null,
    "tag_list": [
        "ruby",
        "mysql"
    ],
    "version": null,
    "access_level": "ref_protected",
    "maximum_timeout": 3600
}
```

## Update runner's details

Update details of a runner.

```plaintext
PUT /runners/:id
```

Prerequisites:

- For `instance_type`, you must be an administrator of the GitLab instance.
- For `group_type`, you must have the Owner role for the target namespace.
- For `project_type`, you must have at least the Maintainer role for the target project.
- An access token with the `manage_runner` scope and the appropriate role.

| Attribute          | Type    | Required | Description                                                                                     |
|--------------------|---------|----------|-------------------------------------------------------------------------------------------------|
| `id`               | integer | yes      | The ID of a runner                                                                              |
| `description`      | string  | no       | The description of the runner                                                                   |
| `active`           | boolean | no       | Deprecated: Use `paused` instead. Flag indicating whether the runner is allowed to receive jobs |
| `paused`           | boolean | no       | Specifies if the runner should ignore new jobs                                             |
| `tag_list`         | array   | no       | The list of tags for the runner                                                                 |
| `run_untagged`     | boolean | no       | Specifies if the runner can execute untagged jobs                                          |
| `locked`           | boolean | no       | Specifies if the runner is locked                                                          |
| `access_level`     | string  | no       | The access level of the runner; `not_protected` or `ref_protected`                              |
| `maximum_timeout`  | integer | no       | Maximum timeout that limits the amount of time (in seconds) that runners can run jobs           |
| `maintenance_note` | string  | no       | Free-form maintenance notes for the runner (1024 characters)                                    |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6" \
     --form "description=test-1-20150125-test" --form "tag_list=ruby,mysql,tag1,tag2"
```

NOTE:
The `token` attribute in the response was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/214320) in GitLab 12.10
and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/214322) in GitLab 13.0.

NOTE:
The `active` query parameter was deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

NOTE:
The `ip_address` attribute in the response was deprecated
[in GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) and will be removed in
[a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).
This attribute will start returning an empty string in GitLab 17.0.
The `ipAddress` attribute can be found inside the respective runner manager, currently only available through the GraphQL
[`CiRunnerManager` type](graphql/reference/_index.md#cirunnermanager).

Example response:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125-test",
    "id": 6,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "group_type",
    "contacted_at": "2016-01-25T16:39:48.066Z",
    "maintenance_note": null,
    "name": null,
    "online": true,
    "status": "online",
    "platform": null,
    "projects": [
        {
            "id": 1,
            "name": "GitLab Community Edition",
            "name_with_namespace": "GitLab.org / GitLab Community Edition",
            "path": "gitlab-foss",
            "path_with_namespace": "gitlab-org/gitlab-foss"
        }
    ],
    "revision": null,
    "tag_list": [
        "ruby",
        "mysql",
        "tag1",
        "tag2"
    ],
    "version": null,
    "access_level": "ref_protected",
    "maximum_timeout": null
}
```

### Pause a runner

Pause a runner.

Prerequisites:

- For `instance_type`, you must be an administrator of the GitLab instance.
- For `group_type`, you must have the Owner role for the target namespace.
- For `project_type`, you must have at least the Maintainer role for the target project.
- An access token with the `manage_runner` scope and the appropriate role.

```plaintext
PUT --form "paused=true" /runners/:runner_id

# --or--

# Deprecated: removal planned in 16.0
PUT --form "active=false" /runners/:runner_id
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `runner_id` | integer | yes      | The ID of a runner  |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "paused=true"  "https://gitlab.example.com/api/v4/runners/6"

# --or--

# Deprecated: removal planned in 16.0
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "active=false"  "https://gitlab.example.com/api/v4/runners/6"
```

NOTE:
The `active` form attribute was deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

## List jobs processed by a runner

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/15432) in GitLab 10.3.

List jobs that are being processed or were processed by the specified runner. The list of jobs is limited
to projects where the user has at least the Reporter role.

```plaintext
GET /runners/:id/jobs
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer | yes      | The ID of a runner  |
| `system_id` | string  | no       | System ID of the machine where the runner manager is running |
| `status`    | string  | no       | Status of the job; one of: `running`, `success`, `failed`, `canceled` |
| `order_by`  | string  | no       | Order jobs by `id` |
| `sort`      | string  | no       | Sort jobs in `asc` or `desc` order (default: `desc`). If `sort` is specified, `order_by` must be specified as well |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/1/jobs?status=running"
```

Example response:

```json
[
    {
        "id": 2,
        "status": "running",
        "stage": "test",
        "name": "test",
        "ref": "main",
        "tag": false,
        "coverage": null,
        "created_at": "2017-11-16T08:50:29.000Z",
        "started_at": "2017-11-16T08:51:29.000Z",
        "finished_at": "2017-11-16T08:53:29.000Z",
        "duration": 120,
        "queued_duration": 2,
        "user": {
            "id": 1,
            "name": "John Doe2",
            "username": "user2",
            "state": "active",
            "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
            "web_url": "http://localhost/user2",
            "created_at": "2017-11-16T18:38:46.000Z",
            "bio": null,
            "location": null,
            "public_email": "",
            "skype": "",
            "linkedin": "",
            "twitter": "",
            "website_url": "",
            "organization": null
        },
        "commit": {
            "id": "97de212e80737a608d939f648d959671fb0a0142",
            "short_id": "97de212e",
            "title": "Update configuration\r",
            "created_at": "2017-11-16T08:50:28.000Z",
            "parent_ids": [
                "1b12f15a11fc6e62177bef08f47bc7b5ce50b141",
                "498214de67004b1da3d820901307bed2a68a8ef6"
            ],
            "message": "See merge request !123",
            "author_name": "John Doe2",
            "author_email": "user2@example.org",
            "authored_date": "2017-11-16T08:50:27.000Z",
            "committer_name": "John Doe2",
            "committer_email": "user2@example.org",
            "committed_date": "2017-11-16T08:50:27.000Z"
        },
        "pipeline": {
            "id": 2,
            "sha": "97de212e80737a608d939f648d959671fb0a0142",
            "ref": "main",
            "status": "running"
        },
        "project": {
            "id": 1,
            "description": null,
            "name": "project1",
            "name_with_namespace": "John Doe2 / project1",
            "path": "project1",
            "path_with_namespace": "namespace1/project1",
            "created_at": "2017-11-16T18:38:46.620Z"
        }
    }
]
```

## List runner's managers

List all the managers of a runner.

```plaintext
GET /runners/:id/managers
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a runner  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/1/managers"
```

Example response:

```json
[
    {
      "id": 1,
      "system_id": "s_89e5e9956577",
      "version": "16.11.1",
      "revision": "535ced5f",
      "platform": "linux",
      "architecture": "amd64",
      "created_at": "2024-06-09T11:12:02.507Z",
      "contacted_at": "2024-06-09T06:30:09.355Z",
      "ip_address": "127.0.0.1",
      "status": "offline"
    },
    {
        "id": 2,
        "system_id": "runner-2",
        "version": "16.11.0",
        "revision": "91a27b2a",
        "platform": "linux",
        "architecture": "amd64",
        "created_at": "2024-06-09T09:12:02.507Z",
      "contacted_at": "2024-06-09T06:30:09.355Z",
        "ip_address": "127.0.0.1",
        "status": "offline",

    }
]
```

## List project's runners

List all runners available in the project, including from ancestor groups and [any allowed instance runners](../ci/runners/runners_scope.md#enable-instance-runners-for-a-project).

Prerequisites:

- You must be an administrator of or have at least the Maintainer role for the target project.

```plaintext
GET /projects/:id/runners
GET /projects/:id/runners?scope=active
GET /projects/:id/runners?type=project_type
GET /projects/:id/runners/all?status=online
GET /projects/:id/runners/all?paused=true
GET /projects/:id/runners?tag_list=tag1,tag2
```

| Attribute        | Type           | Required | Description                                                                                                                                                                                                          |
|------------------|----------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`             | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)                                                                                                  |
| `scope`          | string         | no       | Deprecated: Use `type` or `status` instead. The scope of runners to return, one of: `active`, `paused`, `online` and `offline`; showing all runners if none provided                                                 |
| `type`           | string         | no       | The type of runners to return, one of: `instance_type`, `group_type`, `project_type`                                                                                                                                 |
| `status`         | string         | no       | The status of runners to return, one of: `online`, `offline`, `stale`, or `never_contacted`.<br/>Other possible values are the deprecated `active` and `paused`.<br/>Requesting `offline` runners might also return `stale` runners because `stale` is included in `offline`. |
| `paused`         | boolean        | no       | Whether to include only runners that are accepting or ignoring new jobs                                                                                                                                              |
| `tag_list`       | string array   | no       | A list of runner tags                                                                                                                                                                                                |
| `version_prefix` | string         | no       | The prefix of the version of the runners to return. For example, `15.0`, `14`, `16.1.241`                                                                                                                            |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners"
```

NOTE:
The `active` and `paused` values in the `status` query parameter were deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). They are replaced by the `paused` query parameter.

NOTE:
The `active` attribute in the response was deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

NOTE:
The `ip_address` attribute in the response was deprecated
[in GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) and will be removed in
[a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).
This attribute will start returning an empty string in GitLab 17.0.
The `ipAddress` attribute can be found inside the respective runner manager, currently only available through the GraphQL
[`CiRunnerManager` type](graphql/reference/_index.md#cirunnermanager).

Example response:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "",
        "is_shared": false,
        "runner_type": "project_type",
        "name": null,
        "online": false,
        "status": "offline"
    },
    {
        "active": true,
        "paused": false,
        "description": "development_runner",
        "id": 5,
        "ip_address": "",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": true,
        "status": "online"
    }
]
```

## Assign a runner to project

Assign an available project runner to the project.

Prerequisites:

- For `instance_type`, you must be an administrator of the GitLab instance.
- For `group_type`, you must have the Owner role for the target namespace.
- For `project_type`, you must have at least the Maintainer role for the target project.

```plaintext
POST /projects/:id/runners
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `runner_id` | integer | yes      | The ID of a runner  |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners" \
     --form "runner_id=9"
```

NOTE:
The `ip_address` attribute in the response was deprecated
[in GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) and will be removed in
[a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).
This attribute will start returning an empty string in GitLab 17.0.
The `ipAddress` attribute can be found inside the respective runner manager, currently only available through the GraphQL
[`CiRunnerManager` type](graphql/reference/_index.md#cirunnermanager).

Example response:

```json
{
    "active": true,
    "description": "test-2016-02-01",
    "id": 9,
    "ip_address": "",
    "is_shared": false,
    "runner_type": "project_type",
    "name": null,
    "online": true,
    "status": "online"
}
```

## Unassign a runner from project

Unassign a project runner from the project.
You cannot unassign a runner from the owner project. If you attempt this action, an error occurs.
Use the call to [delete a runner](#delete-a-runner) instead.

Prerequisites:

- For `instance_type`, you must be an administrator of the GitLab instance.
- For `group_type`, you must have the Owner role for the target namespace.
- For `project_type`, you must have at least the Maintainer role for the target project.

```plaintext
DELETE /projects/:id/runners/:runner_id
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `runner_id` | integer | yes      | The ID of a runner  |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners/9"
```

## List group's runners

List all runners available in the group as well as its ancestor groups, including [any allowed instance runners](../ci/runners/runners_scope.md#enable-instance-runners-for-a-group).

Prerequisites:

- You must be an administrator or have the Maintainer role for the target namespace.

```plaintext
GET /groups/:id/runners
GET /groups/:id/runners?type=group_type
GET /groups/:id/runners/all?status=online
GET /groups/:id/runners/all?paused=true
GET /groups/:id/runners?tag_list=tag1,tag2
```

| Attribute        | Type           | Required | Description                                                                                                                                                                                                             |
|------------------|----------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`             | integer        | yes      | The ID of the group                                                                                                                                                                     |
| `type`           | string         | no       | The type of runners to return, one of: `instance_type`, `group_type`, `project_type`. The `project_type` value is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/351466) and will be removed in GitLab 15.0 |
| `status`         | string         | no       | The status of runners to return, one of: `online`, `offline`, `stale`, or `never_contacted`.<br/>Other possible values are the deprecated `active` and `paused`.<br/>Requesting `offline` runners might also return `stale` runners because `stale` is included in `offline`. |
| `paused`         | boolean        | no       | Whether to include only runners that are accepting or ignoring new jobs                                                                                                                                                 |
| `tag_list`       | string array   | no       | A list of runner tags                                                                                                                                                                                                   |
| `version_prefix` | string         | no       | The prefix of the version of the runners to return. For example, `15.0`, `14`, `16.1.241`                                                                                                                               |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/9/runners"
```

NOTE:
The `active` and `paused` values in the `status` query parameter were deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). They are replaced by the `paused` query parameter.

NOTE:
The `active` attribute in the response was deprecated
and will be removed in [a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

NOTE:
The `ip_address` attribute in the response was deprecated
[in GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/415159) and will be removed in
[a future version of the REST API](https://gitlab.com/gitlab-org/gitlab/-/issues/351109).
This attribute will start returning an empty string in GitLab 17.0.
The `ipAddress` attribute can be found inside the respective runner manager, currently only available through the GraphQL
[`CiRunnerManager` type](graphql/reference/_index.md#cirunnermanager).

Example response:

```json
[
  {
    "id": 3,
    "description": "Shared",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": true,
    "runner_type": "instance_type",
    "name": "gitlab-runner",
    "online": null,
    "status": "never_contacted"
  },
  {
    "id": 6,
    "description": "Test",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": true,
    "runner_type": "instance_type",
    "name": "gitlab-runner",
    "online": false,
    "status": "offline"
  },
  {
    "id": 8,
    "description": "Test 2",
    "ip_address": "",
    "active": true,
    "paused": false,
    "is_shared": false,
    "runner_type": "group_type",
    "name": "gitlab-runner",
    "online": null,
    "status": "never_contacted"
  }
]
```

## Create a runner

WARNING:
This endpoint returns an `HTTP 410 Gone` status code if registration with runner registration tokens
is disabled in the project or group settings. If registration with runner registration tokens
is disabled, use the [`POST /user/runners`](users.md#create-a-runner-linked-to-a-user) endpoint
to create and register runners instead.

Create a runner with a runner registration token.

```plaintext
POST /runners
```

| Attribute          | Type         | Required | Description                                                                                                                                                                                    |
|--------------------|--------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `token`            | string       | yes      | [Registration token](#registration-and-authentication-tokens)                                                                                                                                  |
| `description`      | string       | no       | Description of the runner                                                                                                                                                                      |
| `info`             | hash         | no       | Runner's metadata. You can include `name`, `version`, `revision`, `platform`, and `architecture`, but only `version`, `platform`, and `architecture` are displayed in the **Admin** area of the UI |
| `active`           | boolean      | no       | Deprecated: Use `paused` instead. Specifies if the runner is allowed to receive new jobs                                                                                                       |
| `paused`           | boolean      | no       | Specifies if the runner should ignore new jobs                                                                                                                                                 |
| `locked`           | boolean      | no       | Specifies if the runner should be locked for the current project                                                                                                                               |
| `run_untagged`     | boolean      | no       | Specifies if the runner should handle untagged jobs                                                                                                                                            |
| `tag_list`         | string array | no       | A list of runner tags                                                                                                                                                                          |
| `access_level`     | string       | no       | The access level of the runner; `not_protected` or `ref_protected`                                                                                                                             |
| `maximum_timeout`  | integer      | no       | Maximum timeout that limits the amount of time (in seconds) that runners can run jobs                                                                                                          |
| `maintainer_note`  | string       | no       | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/350730), see `maintenance_note`                                                                                                     |
| `maintenance_note` | string       | no       | Free-form maintenance notes for the runner (1024 characters)                                                                                                                                   |

```shell
curl --request POST "https://gitlab.example.com/api/v4/runners" \
     --form "token=<registration_token>" --form "description=test-1-20150125-test" \
     --form "tag_list=ruby,mysql,tag1,tag2"
```

Response:

| Status    | Description                       |
|-----------|-----------------------------------|
| 201       | Runner was created                |
| 403       | Invalid runner registration token |
| 410       | Runner registration disabled      |

Example response:

```json
{
    "id": 12345,
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## Delete a runner

There are two ways to delete a runner:

- By specifying the runner ID.
- By specifying the runner's authentication token.

### Delete a runner by ID

To delete the runner by ID, use your access token with the runner's ID:

Prerequisites:

- For `instance_type`, you must be an administrator of the GitLab instance.
- For `group_type`, you must have the Owner role for the target namespace.
- For `project_type`, you must have at least the Maintainer role for the target project.
- An access token with the `manage_runner` scope and the appropriate role.

```plaintext
DELETE /runners/:id
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer | yes      | The ID of a runner. The ID is visible in the UI under **Settings > CI/CD**. Expand **Runners**, and below the **Remove Runner** button is an ID preceded by the pound sign, for example, `#6`. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6"
```

### Delete a runner by authentication token

To delete the runner by using its authentication token:

Prerequisites:

- You must be an administrator of or have the Owner role for the target namespace or project.
- For `instance_type`, you must be an administrator of the GitLab instance.

```plaintext
DELETE /runners
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `token`     | string  | yes      | The runner's [authentication token](#registration-and-authentication-tokens). |

```shell
curl --request DELETE "https://gitlab.example.com/api/v4/runners" \
     --form "token=<authentication_token>"
```

Response:

| Status    | Description                     |
|-----------|---------------------------------|
| 204       | Runner was deleted              |

## Verify authentication for a registered runner

Validates authentication credentials for a registered runner.

```plaintext
POST /runners/verify
```

| Attribute   | Type    | Required | Description                                                                                    |
|-------------|---------|----------|------------------------------------------------------------------------------------------------|
| `token`     | string  | yes      | The runner's [authentication token](#registration-and-authentication-tokens).                  |
| `system_id` | string  | no       | The runner's system identifier. This attribute is required if the `token` starts with `glrt-`. |

```shell
curl --request POST "https://gitlab.example.com/api/v4/runners/verify" \
     --form "token=<authentication_token>"
```

Response:

| Status    | Description                     |
|-----------|---------------------------------|
| 200       | Credentials are valid           |
| 403       | Credentials are invalid         |

Example response:

```json
{
    "id": 12345,
    "token": "glrt-6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## Reset instance's runner registration token

WARNING:
Runner registration tokens, and support for certain configuration arguments, were [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6 and will be removed in GitLab 17.0. After GitLab 17.0, you will no longer be able to reset runner registration tokens and the `reset_registration_token` endpoint will not function.

Reset the runner registration token for the GitLab instance.

```plaintext
POST /runners/reset_registration_token
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/runners/reset_registration_token"
```

## Reset project's runner registration token

WARNING:
Runner registration tokens, and support for certain configuration arguments, were [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6 and will be removed in GitLab 17.0. After GitLab 17.0, you will no longer be able to reset runner registration tokens and the `reset_registration_token` endpoint will not function.

Reset the runner registration token for a project.

```plaintext
POST /projects/:id/runners/reset_registration_token
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/9/runners/reset_registration_token"
```

## Reset group's runner registration token

WARNING:
Runner registration tokens, and support for certain configuration arguments, were [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6 and will be removed in GitLab 17.0. After GitLab 17.0, you will no longer be able to reset runner registration tokens and the `reset_registration_token` endpoint will not function.

Reset the runner registration token for a group.

```plaintext
POST /groups/:id/runners/reset_registration_token
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/9/runners/reset_registration_token"
```

## Reset runner's authentication token by using the runner ID

Reset the runner's authentication token by using its runner ID.

Prerequisites:

- For `instance_type`, you must be an administrator of the GitLab instance.
- For `group_type`, you must have the Owner role for the target namespace.
- For `project_type`, you must have at least the Maintainer role for the target project.
- An access token with the `manage_runner` scope and the appropriate role.

```plaintext
POST /runners/:id/reset_authentication_token
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a runner  |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/runners/1/reset_authentication_token"
```

Example response:

```json
{
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```

## Reset runner's authentication token by using the current token

Reset the runner's authentication token by using the current token's value as an input.

```plaintext
POST /runners/reset_authentication_token
```

| Attribute | Type    | Required | Description                            |
|-----------|---------|----------|----------------------------------------|
| `token`   | string  | yes      | The authentication token of the runner |

```shell
curl --request POST --form "token=<current token>" \
     "https://gitlab.example.com/api/v4/runners/reset_authentication_token"
```

Example response:

```json
{
    "token": "6337ff461c94fd3fa32ba3b1ff4125",
    "token_expires_at": "2021-09-27T21:05:03.203Z"
}
```
