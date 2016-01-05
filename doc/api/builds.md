# Builds API

## List project builds

Get a list of builds in a project.

```
GET /projects/:id/builds
```

Parameters:

- `id` (required) - The ID of a project
- `scope` (optional) - The scope of builds to show (one of: `all`, `finished`, `running`; default: `all`)

```json
[
    {
        "commit": {
            "committed_at": "2015-12-28T14:34:03.814Z",
            "id": 2,
            "ref": null,
            "sha": "6b053ad388c531c21907f022933e5e81598db388"
        },
        "created_at": "2016-01-04T15:41:23.147Z",
        "finished_at": null,
        "id": 65,
        "name": "brakeman",
        "ref": "master",
        "runner": null,
        "stage": "test",
        "started_at": null,
        "status": "pending"
    },
    {
        "commit": {
            "committed_at": "2015-12-28T14:34:03.814Z",
            "id": 2,
            "ref": null,
            "sha": "6b053ad388c531c21907f022933e5e81598db388"
        },
        "created_at": "2016-01-04T15:41:23.046Z",
        "finished_at": null,
        "id": 64,
        "name": "rubocop",
        "ref": "master",
        "runner": null,
        "stage": "test",
        "started_at": null,
        "status": "pending"
    }
]
```

## List commit builds

Get a list of builds for specific commit in a project.

```
GET /projects/:id/builds/commit/:sha
```

Parameters:

- `id` (required) - The ID of a project
- `sha` (required) - The SHA id of a commit
- `scope` (optional) - The scope of builds to show (one of: `all`, `finished`, `running`; default: `all`)


```json
[
    {
        "commit": {
            "committed_at": "2015-12-28T14:34:03.814Z",
            "id": 2,
            "ref": null,
            "sha": "6b053ad388c531c21907f022933e5e81598db388"
        },
        "created_at": "2016-01-04T15:41:23.147Z",
        "finished_at": null,
        "id": 65,
        "name": "brakeman",
        "ref": "master",
        "runner": null,
        "stage": "test",
        "started_at": null,
        "status": "pending"
    },
    {
        "commit": {
            "committed_at": "2015-12-28T14:34:03.814Z",
            "id": 2,
            "ref": null,
            "sha": "6b053ad388c531c21907f022933e5e81598db388"
        },
        "created_at": "2016-01-04T15:41:23.046Z",
        "finished_at": null,
        "id": 64,
        "name": "rubocop",
        "ref": "master",
        "runner": null,
        "stage": "test",
        "started_at": null,
        "status": "pending"
    }
]
```

## Get a single build

Get a single build of a project

```
GET /projects/:id/builds/:build_id
```

Parameters:

- `id` (required) - The ID of a project
- `build_id` (required) - The ID of a build

```json
{
    "commit": {
        "committed_at": "2015-12-28T14:34:03.814Z",
        "id": 2,
        "ref": null,
        "sha": "6b053ad388c531c21907f022933e5e81598db388"
    },
    "created_at": "2016-01-04T15:41:23.046Z",
    "finished_at": null,
    "id": 64,
    "name": "rubocop",
    "ref": "master",
    "runner": null,
    "stage": "test",
    "started_at": null,
    "status": "pending"
}
```

## Cancel a build

Cancel a single build of a project

```
POST /projects/:id/builds/:build_id/cancel
```

Parameters:

- `id` (required) - The ID of a project
- `build_id` (required) - The ID of a build

```json
{
    "commit": {
        "committed_at": "2015-12-28T14:34:03.814Z",
        "id": 2,
        "ref": null,
        "sha": "6b053ad388c531c21907f022933e5e81598db388"
    },
    "created_at": "2016-01-05T15:33:25.936Z",
    "finished_at": "2016-01-05T15:33:47.553Z",
    "id": 66,
    "name": "rubocop",
    "ref": "master",
    "runner": null,
    "stage": "test",
    "started_at": null,
    "status": "canceled"
}
```

## Retry a build

Retry a single build of a project

```
POST /projects/:id/builds/:build_id/retry
```

Parameters:

- `id` (required) - The ID of a project
- `build_id` (required) - The ID of a build

```json
{
    "commit": {
        "committed_at": "2015-12-28T14:34:03.814Z",
        "id": 2,
        "ref": null,
        "sha": "6b053ad388c531c21907f022933e5e81598db388"
    },
    "created_at": "2016-01-05T15:33:25.936Z",
    "finished_at": null,
    "id": 66,
    "name": "rubocop",
    "ref": "master",
    "runner": null,
    "stage": "test",
    "started_at": null,
    "status": "pending"
}
```
