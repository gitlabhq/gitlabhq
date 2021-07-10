---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Runners API

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/2640) in GitLab 8.5.

## Registration and authentication tokens

There are two tokens to take into account when connecting a runner with GitLab.

| Token | Description |
| ----- | ----------- |
| Registration token   | Token used to [register the runner](https://docs.gitlab.com/runner/register/). It can be [obtained through GitLab](../ci/runners/index.md). |
| Authentication token | Token used to authenticate the runner with the GitLab instance. It is obtained either automatically when [registering a runner](https://docs.gitlab.com/runner/register/), or manually when [registering the runner via the Runner API](#register-a-new-runner). |

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

Get a list of specific runners available to the user.

```plaintext
GET /runners
GET /runners?scope=active
GET /runners?type=project_type
GET /runners?status=active
GET /runners?tag_list=tag1,tag2
GET /runners?search=gitlab
```

| Attribute   | Type           | Required | Description         |
|-------------|----------------|----------|---------------------|
| `scope`     | string         | no       | Deprecated: Use `type` or `status` instead. The scope of specific runners to show, one of: `active`, `paused`, `online`, `offline`; showing all runners if none provided |
| `type`      | string         | no       | The type of runners to show, one of: `instance_type`, `group_type`, `project_type` |
| `status`    | string         | no       | The status of runners to show, one of: `active`, `paused`, `online`, `offline` |
| `tag_list`  | string array   | no       | List of the runner's tags |
| `search`    | string         | no       | The full token or partial description text to match |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners"
```

Example response:

```json
[
    {
        "active": true,
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

## List all runners

Get a list of all runners in the GitLab instance (specific and shared). Access
is restricted to users with `admin` privileges.

```plaintext
GET /runners/all
GET /runners/all?scope=online
GET /runners/all?type=project_type
GET /runners/all?status=active
GET /runners/all?tag_list=tag1,tag2
```

| Attribute   | Type           | Required | Description         |
|-------------|----------------|----------|---------------------|
| `scope`     | string         | no       | Deprecated: Use `type` or `status` instead. The scope of runners to show, one of: `specific`, `shared`, `active`, `paused`, `online`, `offline`; showing all runners if none provided |
| `type`      | string         | no       | The type of runners to show, one of: `instance_type`, `group_type`, `project_type` |
| `status`    | string         | no       | The status of runners to show, one of: `active`, `paused`, `online`, `offline` |
| `tag_list`  | string array   | no       | List of the runner's tags |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/all"
```

Example response:

```json
[
    {
        "active": true,
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

## Get runner's details

Get details of a runner.

At least the [Maintainer role](../user/permissions.md) is required to get runner details at the
project and group level.

Instance-level runner details via this endpoint are available to all signed in users.

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

Example response:

```json
{
    "active": true,
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

| Attribute     | Type    | Required | Description         |
|---------------|---------|----------|---------------------|
| `id`          | integer | yes      | The ID of a runner  |
| `description` | string  | no       | The description of a runner |
| `active`      | boolean | no       | The state of a runner; can be set to `true` or `false` |
| `tag_list`    | array   | no       | The list of tags for a runner; put array of tags, that should be finally assigned to a runner |
| `run_untagged`| boolean | no       | Flag indicating the runner can execute untagged jobs |
| `locked`      | boolean | no       | Flag indicating the runner is locked |
| `access_level` | string | no       | The access_level of the runner; `not_protected` or `ref_protected` |
| `maximum_timeout` | integer | no   | Maximum timeout set when this runner handles the job |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6" \
     --form "description=test-1-20150125-test" --form "tag_list=ruby,mysql,tag1,tag2"
```

NOTE:
The `token` attribute in the response was deprecated [in GitLab 12.10](https://gitlab.com/gitlab-org/gitlab/-/issues/214320).
and removed in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/214322).

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

Pause a specific runner.

```plaintext
PUT --form "active=false"  /runners/:runner_id
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `runner_id` | integer | yes      | The ID of a runner  |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "active=false"  "https://gitlab.example.com/api/v4/runners/6"
```

## List runner's jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/15432) in GitLab 10.3.

List jobs that are being processed or were processed by specified runner.

```plaintext
GET /runners/:id/jobs
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a runner  |
| `status`  | string  | no       | Status of the job; one of: `running`, `success`, `failed`, `canceled` |
| `order_by`| string  | no       | Order jobs by `id`. |
| `sort`    | string  | no       | Sort jobs in `asc` or `desc` order (default: `desc`) |

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

List all runners (specific and shared) available in the project. Shared runners
are listed if at least one shared runner is defined.

```plaintext
GET /projects/:id/runners
GET /projects/:id/runners?scope=active
GET /projects/:id/runners?type=project_type
GET /projects/:id/runners?status=active
GET /projects/:id/runners?tag_list=tag1,tag2
```

| Attribute  | Type           | Required | Description         |
|------------|----------------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `scope`    | string         | no       | Deprecated: Use `type` or `status` instead. The scope of specific runners to show, one of: `active`, `paused`, `online`, `offline`; showing all runners if none provided |
| `type`     | string         | no       | The type of runners to show, one of: `instance_type`, `group_type`, `project_type` |
| `status`   | string         | no       | The status of runners to show, one of: `active`, `paused`, `online`, `offline` |
| `tag_list` | string array   | no       | List of the runner's tags |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners"
```

Example response:

```json
[
    {
        "active": true,
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
        "description": "development_runner",
        "id": 5,
        "ip_address": "127.0.0.1",
        "is_shared": true,
        "runner_type": "instance_type",
        "name": null,
        "online": true,
        "status": "paused"
    }
]
```

## Enable a runner in project

Enable an available specific runner in the project.

```plaintext
POST /projects/:id/runners
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
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

Disable a specific runner from the project. It works only if the project isn't
the only project associated with the specified runner. If so, an error is
returned. Use the call to [delete a runner](#delete-a-runner) instead.

```plaintext
DELETE /projects/:id/runners/:runner_id
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `runner_id` | integer | yes      | The ID of a runner  |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners/9"
```

## List group's runners

List all runners (specific and shared) available in the group as well it's ancestor groups.
Shared runners are listed if at least one shared runner is defined.

```plaintext
GET /groups/:id/runners
GET /groups/:id/runners?type=group_type
GET /groups/:id/runners?status=active
GET /groups/:id/runners?tag_list=tag1,tag2
```

| Attribute  | Type           | Required | Description         |
|------------|----------------|----------|---------------------|
| `id`       | integer        | yes      | The ID of the group owned by the authenticated user |
| `type`     | string         | no       | The type of runners to show, one of: `instance_type`, `group_type`, `project_type` |
| `status`   | string         | no       | The status of runners to show, one of: `active`, `paused`, `online`, `offline` |
| `tag_list` | string array   | no       | List of the runner's tags |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/9/runners"
```

Example response:

```json
[
  {
    "id": 3,
    "description": "Shared",
    "ip_address": "127.0.0.1",
    "active": true,
    "is_shared": true,
    "runner_type": "instance_type",
    "name": "gitlab-runner",
    "online": null,
    "status": "not_connected"
  },
  {
    "id": 6,
    "description": "Test",
    "ip_address": "127.0.0.1",
    "active": true,
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
    "is_shared": false,
    "runner_type": "group_type",
    "name": "gitlab-runner",
    "online": null,
    "status": "not_connected"
  }
]
```

## Register a new runner

Register a new runner for the instance.

```plaintext
POST /runners
```

| Attribute    | Type    | Required | Description         |
|--------------|---------|----------|---------------------|
| `token`      | string  | yes      | [Registration token](#registration-and-authentication-tokens).  |
| `description`| string  | no       | Runner's description|
| `info`       | hash    | no       | Runner's metadata. You can include `name`, `version`, `revision`, `platform`, and `architecture`, but only `version` is displayed in the Admin area of the UI. |
| `active`     | boolean | no       | Whether the runner is active   |
| `locked`     | boolean | no       | Whether the runner should be locked for current project |
| `run_untagged` | boolean | no     | Whether the runner should handle untagged jobs |
| `tag_list`   | string array | no  | List of runner's tags |
| `access_level`    | string | no   | The access_level of the runner; `not_protected` or `ref_protected` |
| `maximum_timeout` | integer | no  | Maximum timeout set when this runner handles the job |

```shell
curl --request POST "https://gitlab.example.com/api/v4/runners" \
     --form "token=<registration_token>" --form "description=test-1-20150125-test" \
     --form "tag_list=ruby,mysql,tag1,tag2"
```

Response:

| Status    | Description                     |
|-----------|---------------------------------|
| 201       | Runner was created              |

Example response:

```json
{
    "id": 12345,
    "token": "6337ff461c94fd3fa32ba3b1ff4125"
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

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `token`     | string  | yes      | Runner's [authentication token](#registration-and-authentication-tokens).  |

```shell
curl --request POST "https://gitlab.example.com/api/v4/runners/verify" \
     --form "token=<authentication_token>"
```

Response:

| Status    | Description                     |
|-----------|---------------------------------|
| 200       | Credentials are valid           |
| 403       | Credentials are invalid         |
