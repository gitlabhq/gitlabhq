---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Runners API **(FREE)**

[Pagination](rest/index.md#pagination) is available on the following API endpoints (they return 20 items by default):

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
| Registration token | Token used to [register the runner](https://docs.gitlab.com/runner/register/). It can be [obtained through GitLab](../ci/runners/index.md). |
| Authentication token | Token used to authenticate the runner with the GitLab instance. It is obtained automatically when you [register a runner](https://docs.gitlab.com/runner/register/) or by the Runner API when you manually [register a runner](#register-a-new-runner) or [reset the authentication token](#reset-runners-authentication-token-by-using-the-runner-id). |

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

```plaintext
GET /runners
GET /runners?scope=active
GET /runners?type=project_type
GET /runners?status=online
GET /runners?paused=true
GET /runners?tag_list=tag1,tag2
```

| Attribute  | Type         | Required | Description                                                                                                                                                                                              |
|------------|--------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `scope`    | string       | no       | Deprecated: Use `type` or `status` instead. The scope of runners to return, one of: `active`, `paused`, `online` and `offline`; showing all runners if none provided                              |
| `type`     | string       | no       | The type of runners to return, one of: `instance_type`, `group_type`, `project_type`                                                                                                                       |
| `status`   | string       | no       | The status of runners to return, one of: `online`, `offline`, `stale`, and `never_contacted`. `active` and `paused` are also possible values which were deprecated in GitLab 14.8 and will be removed in GitLab 16.0 |
| `paused`   | boolean      | no       | Whether to include only runners that are accepting or ignoring new jobs                                                                                                                                  |
| `tag_list` | string array | no       | A list of runner tags                                                                                                                                                                                    |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners"
```

NOTE:
The `active` and `paused` values in the `status` query parameter were deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). They are replaced by the `paused` query parameter.

NOTE:
The `active` attribute in the response was deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

Example response:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "test-1-20150125",
        "id": 6,
        "ip_address": "127.0.0.1",
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
        "ip_address": "127.0.0.1",
        "is_shared": false,
        "runner_type": "group_type",
        "name": null,
        "online": false,
        "status": "offline"
    }
]
```

## List all runners **(FREE SELF)**

Get a list of all runners in the GitLab instance (project and shared). Access
is restricted to users with administrator access.

```plaintext
GET /runners/all
GET /runners/all?scope=online
GET /runners/all?type=project_type
GET /runners/all?status=online
GET /runners/all?paused=true
GET /runners/all?tag_list=tag1,tag2
```

| Attribute  | Type         | Required | Description                                                                                                                                                                              |
|------------|--------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `scope`    | string       | no       | Deprecated: Use `type` or `status` instead. The scope of runners to return, one of: `specific`, `shared`, `active`, `paused`, `online` and `offline`; showing all runners if none provided |
| `type`     | string       | no       | The type of runners to return, one of: `instance_type`, `group_type`, `project_type`                                                                                                       |
| `status`   | string       | no       | The status of runners to return, one of: `online`, `offline`, `stale`, and `never_contacted`. `active` and `paused` are also possible values which were deprecated in GitLab 14.8 and will be removed in GitLab 16.0    |
| `paused`   | boolean      | no       | Whether to include only runners that are accepting or ignoring new jobs                                                                                                                  |
| `tag_list` | string array | no       | A list of runner tags                                                                                                                                                                    |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/all"
```

NOTE:
The `active` and `paused` values in the `status` query parameter were deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). They are replaced by the `paused` query parameter.

NOTE:
The `active` attribute in the response was deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

Example response:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "shared-runner-1",
        "id": 1,
        "ip_address": "127.0.0.1",
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
        "ip_address": "127.0.0.1",
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
        "ip_address": "127.0.0.1",
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
        "ip_address": "127.0.0.1",
        "is_shared": false,
        "runner_type": "group_type",
        "name": null,
        "online": false,
        "status": "offline"
    }
]
```

To view more than the first 20 runners, use [pagination](rest/index.md#pagination).

## Get runner's details

Get details of a runner.

At least the Maintainer role is required to get runner details at the
project and group level.

Instance-level runner details via this endpoint are available to all authenticated users.

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
The `token` attribute in the response was deprecated [in GitLab 12.10](https://gitlab.com/gitlab-org/gitlab/-/issues/214320).
and removed in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/214322).

NOTE:
The `active` attribute in the response was deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

Example response:

```json
{
    "active": true,
    "paused": false,
    "architecture": null,
    "description": "test-1-20150125",
    "id": 6,
    "ip_address": "127.0.0.1",
    "is_shared": false,
    "runner_type": "project_type",
    "contacted_at": "2016-01-25T16:39:48.066Z",
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

| Attribute         | Type    | Required | Description                                                                                     |
|-------------------|---------|----------|-------------------------------------------------------------------------------------------------|
| `id`              | integer | yes      | The ID of a runner                                                                              |
| `description`     | string  | no       | The description of the runner                                                                   |
| `active`          | boolean | no       | Deprecated: Use `paused` instead. Flag indicating whether the runner is allowed to receive jobs |
| `paused`          | boolean | no       | Specifies if the runner should ignore new jobs                                             |
| `tag_list`        | array   | no       | The list of tags for the runner                                                                 |
| `run_untagged`    | boolean | no       | Specifies if the runner can execute untagged jobs                                          |
| `locked`          | boolean | no       | Specifies if the runner is locked                                                          |
| `access_level`    | string  | no       | The access level of the runner; `not_protected` or `ref_protected`                              |
| `maximum_timeout` | integer | no       | Maximum timeout that limits the amount of time (in seconds) that runners can run jobs           |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6" \
     --form "description=test-1-20150125-test" --form "tag_list=ruby,mysql,tag1,tag2"
```

NOTE:
The `token` attribute in the response was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/214320) in GitLab 12.10.
and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/214322) in GitLab 13.0.

NOTE:
The `active` query parameter was deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

Example response:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125-test",
    "id": 6,
    "ip_address": "127.0.0.1",
    "is_shared": false,
    "runner_type": "group_type",
    "contacted_at": "2016-01-25T16:39:48.066Z",
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
The `active` form attribute was deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

## List runner's jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/15432) in GitLab 10.3.

List jobs that are being processed or were processed by the specified runner. The list of jobs is limited
to projects where the user has at least the Reporter role.

```plaintext
GET /runners/:id/jobs
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a runner  |
| `status`  | string  | no       | Status of the job; one of: `running`, `success`, `failed`, `canceled` |
| `order_by`| string  | no       | Order jobs by `id` |
| `sort`    | string  | no       | Sort jobs in `asc` or `desc` order (default: `desc`). Specify `order_by` as well, including for `id`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/1/jobs?status=running"
```

Example response:

```json
[
    {
        "id": 2,
        "ip_address": "127.0.0.1",
        "status": "running",
        "stage": "test",
        "name": "test",
        "ref": "master",
        "tag": false,
        "coverage": null,
        "created_at": "2017-11-16T08:50:29.000Z",
        "started_at": "2017-11-16T08:51:29.000Z",
        "finished_at": "2017-11-16T08:53:29.000Z",
        "duration": 120,
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
            "ref": "master",
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

## List project's runners

List all runners available in the project, including from ancestor groups and [any allowed shared runners](../ci/runners/runners_scope.md#enable-shared-runners-for-a-project).

```plaintext
GET /projects/:id/runners
GET /projects/:id/runners?scope=active
GET /projects/:id/runners?type=project_type
GET /projects/:id/runners/all?status=online
GET /projects/:id/runners/all?paused=true
GET /projects/:id/runners?tag_list=tag1,tag2
```

| Attribute  | Type           | Required | Description                                                                                                                                                                           |
|------------|----------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user                                                                        |
| `scope`    | string         | no       | Deprecated: Use `type` or `status` instead. The scope of runners to return, one of: `active`, `paused`, `online` and `offline`; showing all runners if none provided           |
| `type`     | string         | no       | The type of runners to return, one of: `instance_type`, `group_type`, `project_type`                                                                                                    |
| `status`   | string         | no       | The status of runners to return, one of: `online`, `offline`, `stale`, and `never_contacted`. `active` and `paused` are also possible values which were deprecated in GitLab 14.8 and will be removed in GitLab 16.0 |
| `paused`   | boolean        | no       | Whether to include only runners that are accepting or ignoring new jobs                                                                                                               |
| `tag_list` | string array   | no       | A list of runner tags                                                                                                                                                                 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners"
```

NOTE:
The `active` and `paused` values in the `status` query parameter were deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). They are replaced by the `paused` query parameter.

NOTE:
The `active` attribute in the response was deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

Example response:

```json
[
    {
        "active": true,
        "paused": false,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "127.0.0.1",
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
        "ip_address": "127.0.0.1",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": true,
        "status": "online"
    }
]
```

## Enable a runner in project

Enable an available project runner in the project.

```plaintext
POST /projects/:id/runners
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `runner_id` | integer | yes      | The ID of a runner  |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners" \
     --form "runner_id=9"
```

Example response:

```json
{
    "active": true,
    "description": "test-2016-02-01",
    "id": 9,
    "ip_address": "127.0.0.1",
    "is_shared": false,
    "runner_type": "project_type",
    "name": null,
    "online": true,
    "status": "online"
}
```

## Disable a runner from project

Disable a project runner from the project. It works only if the project isn't
the only project associated with the specified runner. If so, an error is
returned. Use the call to [delete a runner](#delete-a-runner) instead.

```plaintext
DELETE /projects/:id/runners/:runner_id
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `runner_id` | integer | yes      | The ID of a runner  |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners/9"
```

## List group's runners

List all runners available in the group as well as its ancestor groups, including [any allowed shared runners](../ci/runners/runners_scope.md#enable-shared-runners-for-a-group).

```plaintext
GET /groups/:id/runners
GET /groups/:id/runners?type=group_type
GET /groups/:id/runners/all?status=online
GET /groups/:id/runners/all?paused=true
GET /groups/:id/runners?tag_list=tag1,tag2
```

| Attribute  | Type           | Required | Description                                                                                                                                                                                                           |
|------------|----------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`       | integer        | yes      | The ID of the group owned by the authenticated user                                                                                                                                                                   |
| `type`     | string         | no       | The type of runners to return, one of: `instance_type`, `group_type`, `project_type`. The `project_type` value is [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/351466) and will be removed in GitLab 15.0 |
| `status`   | string         | no       | The status of runners to return, one of: `online`, `offline`, `stale`, and `never_contacted`. `active` and `paused` are also possible values which were deprecated in GitLab 14.8 and will be removed in GitLab 16.0    |
| `paused`   | boolean        | no       | Whether to include only runners that are accepting or ignoring new jobs                                                                                                                                               |
| `tag_list` | string array   | no       | A list of runner tags                                                                                                                                                                                                 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/9/runners"
```

NOTE:
The `active` and `paused` values in the `status` query parameter were deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). They are replaced by the `paused` query parameter.

NOTE:
The `active` attribute in the response was deprecated [in GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/347211).
and will be removed in [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/351109). It is replaced by the `paused` attribute.

Example response:

```json
[
  {
    "id": 3,
    "description": "Shared",
    "ip_address": "127.0.0.1",
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
    "ip_address": "127.0.0.1",
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
    "ip_address": "127.0.0.1",
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

## Register a new runner

Register a new runner for the instance.

```plaintext
POST /runners
```

| Attribute          | Type         | Required | Description                                                                                                                                                                                    |
|--------------------|--------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `token`            | string       | yes      | [Registration token](#registration-and-authentication-tokens)                                                                                                                                  |
| `description`      | string       | no       | Description of the runner                                                                                                                                                                      |
| `info`             | hash         | no       | Runner's metadata. You can include `name`, `version`, `revision`, `platform`, and `architecture`, but only `version`, `platform`, and `architecture` are displayed in the Admin Area of the UI |
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

## Reset instance's runner registration token (deprecated)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30942) in GitLab 14.3.
> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104691) in GitLab 15.7.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/383341) in GitLab 15.7 and is planned for removal in 17.0. This change is a breaking change.

Reset the runner registration token for the GitLab instance.

```plaintext
POST /runners/reset_registration_token
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/runners/reset_registration_token"
```

## Reset project's runner registration token (deprecated)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30942) in GitLab 14.3.
> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104691) in GitLab 15.7.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/383341) in GitLab 15.7 and is planned for removal in 17.0. This change is a breaking change.

Reset the runner registration token for a project.

```plaintext
POST /projects/:id/runners/reset_registration_token
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/9/runners/reset_registration_token"
```

## Reset group's runner registration token (deprecated)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30942) in GitLab 14.3.
> - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104691) in GitLab 15.7.

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/383341) in GitLab 15.7 and is planned for removal in 17.0. This change is a breaking change.

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
