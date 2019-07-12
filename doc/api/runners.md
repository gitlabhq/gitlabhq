# Runners API

> [Introduced][ce-2640] in GitLab 8.5

[ce-2640]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2640

## Registration and authentication tokens

There are two tokens to take into account when connecting a Runner with GitLab.

| Token | Description |
| ----- | ----------- |
| Registration token   | Token used to [register the Runner](https://docs.gitlab.com/runner/register/). It can be [obtained through GitLab](../ci/runners/README.md). |
| Authentication token | Token used to authenticate the Runner with the GitLab instance. It is obtained either automatically when [registering a Runner](https://docs.gitlab.com/runner/register/), or manually when [registering the Runner via the Runners API](#register-a-new-runner). |

Here's an example of how the two tokens are used in Runner registration:

1. You register the Runner via the GitLab API using a registration token, and an
   authentication token is returned.
1. You use that authentication token and add it to the
   [Runner's configuration file](https://docs.gitlab.com/runner/commands/#configuration-file):

   ```toml
   [[runners]]
     token = "<authentication_token>"
   ```

GitLab and Runner are then connected.

## List owned runners

Get a list of specific runners available to the user.

```
GET /runners
GET /runners?scope=active
GET /runners?type=project_type
GET /runners?status=active
GET /runners?tag_list=tag1,tag2
```

| Attribute   | Type           | Required | Description         |
|-------------|----------------|----------|---------------------|
| `scope`     | string         | no       | Deprecated: Use `type` or `status` instead. The scope of specific runners to show, one of: `active`, `paused`, `online`, `offline`; showing all runners if none provided |
| `type`      | string         | no       | The type of runners to show, one of: `instance_type`, `group_type`, `project_type` |
| `status`    | string         | no       | The status of runners to show, one of: `active`, `paused`, `online`, `offline` |
| `tag_list`  | string array   | no       | List of of the runner's tags |

```
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners"
```

Example response:

```json
[
    {
        "active": true,
        "description": "test-1-20150125",
        "id": 6,
        "is_shared": false,
        "ip_address": "127.0.0.1",
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
        "name": null,
        "online": false,
        "status": "offline"
    }
]
```

## List all runners

Get a list of all runners in the GitLab instance (specific and shared). Access
is restricted to users with `admin` privileges.

```
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
| `tag_list`  | string array   | no       | List of of the runner's tags |

```
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
        "name": null,
        "online": false
        "status": "offline"
    },
    {
        "active": true,
        "description": "test-1-20150125",
        "id": 6,
        "ip_address": "127.0.0.1",
        "is_shared": false,
        "name": null,
        "online": true
        "status": "paused"
    },
    {
        "active": true,
        "description": "test-2-20150125",
        "id": 8,
        "ip_address": "127.0.0.1",
        "is_shared": false,
        "name": null,
        "online": false,
        "status": "offline"
    }
]
```

## Get runner's details

Get details of a runner.

```
GET /runners/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a runner  |

```
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6"
```

Example response:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125",
    "id": 6,
    "ip_address": "127.0.0.1",
    "is_shared": false,
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
            "path": "gitlab-ce",
            "path_with_namespace": "gitlab-org/gitlab-ce"
        }
    ],
    "token": "205086a8e3b9a2b818ffac9b89d102",
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

```
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
| `maximum_timeout` | integer | no   | Maximum timeout set when this Runner will handle the job |

```
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6" --form "description=test-1-20150125-test" --form "tag_list=ruby,mysql,tag1,tag2"
```

Example response:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125-test",
    "id": 6,
    "ip_address": "127.0.0.1",
    "is_shared": false,
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
            "path": "gitlab-ce",
            "path_with_namespace": "gitlab-org/gitlab-ce"
        }
    ],
    "token": "205086a8e3b9a2b818ffac9b89d102",
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

## Remove a runner

Remove a runner.

```
DELETE /runners/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a runner  |

```
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/runners/6"
```

## List runner's jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/15432) in GitLab 10.3.

List jobs that are being processed or were processed by specified Runner.

```
GET /runners/:id/jobs
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a runner  |
| `status`  | string  | no       | Status of the job; one of: `running`, `success`, `failed`, `canceled` |
| `order_by`| string  | no       | Order jobs by `id`. |
| `sort`    | string  | no       | Sort jobs in `asc` or `desc` order (default: `desc`) |

```
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

```
GET /projects/:id/runners
GET /projects/:id/runners?scope=active
GET /projects/:id/runners?type=project_type
GET /projects/:id/runners?status=active
GET /projects/:id/runners?tag_list=tag1,tag2
```

| Attribute  | Type           | Required | Description         |
|------------|----------------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `scope`    | string         | no       | Deprecated: Use `type` or `status` instead. The scope of specific runners to show, one of: `active`, `paused`, `online`, `offline`; showing all runners if none provided |
| `type`     | string         | no       | The type of runners to show, one of: `instance_type`, `group_type`, `project_type` |
| `status`   | string         | no       | The status of runners to show, one of: `active`, `paused`, `online`, `offline` |
| `tag_list` | string array   | no       | List of of the runner's tags |

```
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
        "name": null,
        "online": true
        "status": "paused"
    }
]
```

## Enable a runner in project

Enable an available specific runner in the project.

```
POST /projects/:id/runners
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `runner_id` | integer | yes      | The ID of a runner  |

```
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners" --form "runner_id=9"
```

Example response:

```json
{
    "active": true,
    "description": "test-2016-02-01",
    "id": 9,
    "ip_address": "127.0.0.1",
    "is_shared": false,
    "name": null,
    "online": true,
    "status": "online"
}
```

## Disable a runner from project

Disable a specific runner from the project. It works only if the project isn't
the only project associated with the specified runner. If so, an error is
returned. Use the [Remove a runner](#remove-a-runner) call instead.

```
DELETE /projects/:id/runners/:runner_id
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `runner_id` | integer | yes      | The ID of a runner  |

```
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/9/runners/9"
```

## Register a new Runner

Register a new Runner for the instance.

```
POST /runners
```

| Attribute    | Type    | Required | Description         |
|--------------|---------|----------|---------------------|
| `token`      | string  | yes      | [Registration token](#registration-and-authentication-tokens).  |
| `description`| string  | no       | Runner's description|
| `info`       | hash    | no       | Runner's metadata   |
| `active`     | boolean | no       | Whether the Runner is active   |
| `locked`     | boolean | no       | Whether the Runner should be locked for current project |
| `run_untagged` | boolean | no     | Whether the Runner should handle untagged jobs |
| `tag_list`   | string array | no  | List of Runner's tags |
| `access_level`    | string | no   | The access_level of the runner; `not_protected` or `ref_protected` |
| `maximum_timeout` | integer | no  | Maximum timeout set when this Runner will handle the job |

```
curl --request POST "https://gitlab.example.com/api/v4/runners" --form "token=<registration_token>" --form "description=test-1-20150125-test" --form "tag_list=ruby,mysql,tag1,tag2"
```

Response:

| Status    | Description                     |
|-----------|---------------------------------|
| 201       | Runner was created              |

Example response:

```json
{
    "id": "12345",
    "token": "6337ff461c94fd3fa32ba3b1ff4125"
}
```

## Delete a registered Runner

Deletes a registered Runner.

```
DELETE /runners
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `token`     | string  | yes      | Runner's [authentication token](#registration-and-authentication-tokens).  |

```
curl --request DELETE "https://gitlab.example.com/api/v4/runners" --form "token=<authentication_token>"
```

Response:

| Status    | Description                     |
|-----------|---------------------------------|
| 204       | Runner was deleted              |

## Verify authentication for a registered Runner

Validates authentication credentials for a registered Runner.

```
POST /runners/verify
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `token`     | string  | yes      | Runner's [authentication token](#registration-and-authentication-tokens).  |

```
curl --request POST "https://gitlab.example.com/api/v4/runners/verify" --form "token=<authentication_token>"
```

Response:

| Status    | Description                     |
|-----------|---------------------------------|
| 200       | Credentials are valid           |
| 403       | Credentials are invalid         |
