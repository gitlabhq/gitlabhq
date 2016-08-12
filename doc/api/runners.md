# Runners API

> [Introduced][ce-2640] in GitLab 8.5

[ce-2640]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2640

## List owned runners

Get a list of specific runners available to the user.

```
GET /runners
GET /runners?scope=active
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `scope`   | string  | no       | The scope of specific runners to show, one of: `active`, `paused`, `online`; showing all runners if none provided |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/runners"
```

Example response:

```json
[
    {
        "active": true,
        "description": "test-1-20150125",
        "id": 6,
        "is_shared": false,
        "name": null
    },
    {
        "active": true,
        "description": "test-2-20150125",
        "id": 8,
        "is_shared": false,
        "name": null
    }
]
```

## List all runners

Get a list of all runners in the GitLab instance (specific and shared). Access
is restricted to users with `admin` privileges.

```
GET /runners/all
GET /runners/all?scope=online
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `scope`   | string  | no       | The scope of runners to show, one of: `specific`, `shared`, `active`, `paused`, `online`; showing all runners if none provided |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/runners/all"
```

Example response:

```json
[
    {
        "active": true,
        "description": "shared-runner-1",
        "id": 1,
        "is_shared": true,
        "name": null
    },
    {
        "active": true,
        "description": "shared-runner-2",
        "id": 3,
        "is_shared": true,
        "name": null
    },
    {
        "active": true,
        "description": "test-1-20150125",
        "id": 6,
        "is_shared": false,
        "name": null
    },
    {
        "active": true,
        "description": "test-2-20150125",
        "id": 8,
        "is_shared": false,
        "name": null
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
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/runners/6"
```

Example response:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125",
    "id": 6,
    "is_shared": false,
    "contacted_at": "2016-01-25T16:39:48.066Z",
    "name": null,
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
    "version": null
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

```
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/runners/6" --form "description=test-1-20150125-test" --form "tag_list=ruby,mysql,tag1,tag2"
```

Example response:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125-test",
    "id": 6,
    "is_shared": false,
    "contacted_at": "2016-01-25T16:39:48.066Z",
    "name": null,
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
    "version": null
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
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/runners/6"
```

Example response:

```json
{
    "active": true,
    "description": "test-1-20150125-test",
    "id": 6,
    "is_shared": false,
    "name": null,
}
```

## List project's runners

List all runners (specific and shared) available in the project. Shared runners
are listed if at least one shared runner is defined **and** shared runners
usage is enabled in the project's settings.

```
GET /projects/:id/runners
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a project |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/9/runners"
```

Example response:

```json
[
    {
        "active": true,
        "description": "test-2-20150125",
        "id": 8,
        "is_shared": false,
        "name": null
    },
    {
        "active": true,
        "description": "development_runner",
        "id": 5,
        "is_shared": true,
        "name": null
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
| `id`        | integer | yes      | The ID of a project |
| `runner_id` | integer | yes      | The ID of a runner  |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/9/runners" --form "runner_id=9"
```

Example response:

```json
{
    "active": true,
    "description": "test-2016-02-01",
    "id": 9,
    "is_shared": false,
    "name": null
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
| `id`        | integer | yes      | The ID of a project |
| `runner_id` | integer | yes      | The ID of a runner  |

```
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/9/runners/9"
```

Example response:

```json
{
    "active": true,
    "description": "test-2016-02-01",
    "id": 9,
    "is_shared": false,
    "name": null
}
```
