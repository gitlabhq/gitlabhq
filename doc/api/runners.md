# Runners API

## List owned runners

Get a list of specific runners available for user.

```
GET /runners
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `scope`   | string  | no       | The scope of runners to show, one of: `specific`, `shared`, `active`, `paused`, `online`; showing all runners if none provided |

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/runners"
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

Get a list of all runners (specific and shared). Access restricted to users with `admin` privileges.

```
GET /runners/all
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `scope`   | string  | no       | The scope of runners to show, one of: `specific`, `shared`, `active`, `paused`, `online`; showing all runners if none provided |

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/runners/all"
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
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/runners/6"
```

Example response:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125",
    "id": 6,
    "is_shared": false,
    "last_contact": "2016-01-25T16:39:48.066Z",
    "name": null,
    "platform": null,
    "projects": [
        {
            "id": 1,
            "name": "GitLab.org / GitLab Community Edition",
            "path": "gitlab-org/gitlab-ce"
        }
    ],
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
curl -X PUT -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/runners/6" -F "description=test-1-20150125-test" -F "tag_list=ruby,mysql,tag1,tag2"
```

Example response:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125-test",
    "id": 6,
    "is_shared": false,
    "last_contact": "2016-01-25T16:39:48.066Z",
    "name": null,
    "platform": null,
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
curl -X DELETE -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/runners/6"
```

Example response:

```json
{
    "active": true,
    "architecture": null,
    "description": "test-1-20150125-test",
    "id": 6,
    "is_shared": false,
    "last_contact": "2016-01-25T16:39:48.066Z",
    "name": null,
    "platform": null,
    "revision": null,
    "tag_list": [],
    "version": null
}
```

## List project's runners

List all runners (*shared* and *specific*) available in project. Shared runners are listed if at least one shared runner
is defined **and** shared runners usage is enabled in project's settings.

```
GET /projects/:id/runners
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a project |

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/project/9/runners"
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

Enable available specific runner in project.

```
POST /projects/:id/runners/:runner_id
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer | yes      | The ID of a project |
| `runner_id` | integer | yes      | The ID of a runner  |

```
curl -X POST -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/project/9/runners/9"
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

Disable a specific runner from project. It works only, if the project isn't an only project associated with the
specified runner. If so, then an error is returned and user should use the [remove a runner](#remove-a-runner) feature.

```
DELETE /projects/:id/runners/:runner_id
```

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer | yes      | The ID of a project |
| `runner_id` | integer | yes      | The ID of a runner  |

```
curl -X DELETE -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/project/9/runners/9"
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
