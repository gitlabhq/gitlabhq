# Builds API

## List project builds

Get a list of builds in a project.

```
GET /projects/:id/builds
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a project |
| `scope`   | string **or** array of strings | no | The scope of builds to show, one or array of: `pending`, `running`, `failed`, `success`, `canceled`; showing all builds if none provided |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/builds"
```

Example of response

```json
[
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "created_at": "2015-12-24T15:51:21.802Z",
    "artifacts_file": {
      "filename": "artifacts.zip",
      "size": 1000
    },
    "finished_at": "2015-12-24T17:54:27.895Z",
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "ref": "master",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    }
    "ref": "master",
    "runner": null,
    "stage": "test",
    "started_at": "2015-12-24T17:54:27.722Z",
    "status": "failed",
    "tag": false,
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "bio": null,
      "created_at": "2015-12-21T13:14:24.077Z",
      "id": 1,
      "is_admin": true,
      "linkedin": "",
      "name": "Administrator",
      "skype": "",
      "state": "active",
      "twitter": "",
      "username": "root",
      "web_url": "http://gitlab.dev/u/root",
      "website_url": ""
    }
  },
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "created_at": "2015-12-24T15:51:21.727Z",
    "artifacts_file": null,
    "finished_at": "2015-12-24T17:54:24.921Z",
    "id": 6,
    "name": "spinach:other",
    "pipeline": {
      "id": 6,
      "ref": "master",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    }
    "ref": "master",
    "runner": null,
    "stage": "test",
    "started_at": "2015-12-24T17:54:24.729Z",
    "status": "failed",
    "tag": false,
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "bio": null,
      "created_at": "2015-12-21T13:14:24.077Z",
      "id": 1,
      "is_admin": true,
      "linkedin": "",
      "name": "Administrator",
      "skype": "",
      "state": "active",
      "twitter": "",
      "username": "root",
      "web_url": "http://gitlab.dev/u/root",
      "website_url": ""
    }
  }
]
```

## List commit builds

Get a list of builds for specific commit in a project.

This endpoint will return all builds, from all pipelines for a given commit.
If the commit SHA is not found, it will respond with 404, otherwise it will
return an array of builds (an empty array if there are no builds for this
particular commit).

```
GET /projects/:id/repository/commits/:sha/builds
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a project |
| `sha`     | string  | yes      | The SHA id of a commit |
| `scope`   | string **or** array of strings | no | The scope of builds to show, one or array of: `pending`, `running`, `failed`, `success`, `canceled`; showing all builds if none provided |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/repository/commits/0ff3ae198f8601a285adcf5c0fff204ee6fba5fd/builds"
```

Example of response

```json
[
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "created_at": "2016-01-11T10:13:33.506Z",
    "artifacts_file": null,
    "finished_at": "2016-01-11T10:14:09.526Z",
    "id": 69,
    "name": "rubocop",
    "pipeline": {
      "id": 6,
      "ref": "master",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    }
    "ref": "master",
    "runner": null,
    "stage": "test",
    "started_at": null,
    "status": "canceled",
    "tag": false,
    "user": null
  },
  {
    "commit": {
      "author_email": "admin@example.com",
      "author_name": "Administrator",
      "created_at": "2015-12-24T16:51:14.000+01:00",
      "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "message": "Test the CI integration.",
      "short_id": "0ff3ae19",
      "title": "Test the CI integration."
    },
    "coverage": null,
    "created_at": "2015-12-24T15:51:21.957Z",
    "artifacts_file": null,
    "finished_at": "2015-12-24T17:54:33.913Z",
    "id": 9,
    "name": "brakeman",
    "pipeline": {
      "id": 6,
      "ref": "master",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    }
    "ref": "master",
    "runner": null,
    "stage": "test",
    "started_at": "2015-12-24T17:54:33.727Z",
    "status": "failed",
    "tag": false,
    "user": {
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "bio": null,
      "created_at": "2015-12-21T13:14:24.077Z",
      "id": 1,
      "is_admin": true,
      "linkedin": "",
      "name": "Administrator",
      "skype": "",
      "state": "active",
      "twitter": "",
      "username": "root",
      "web_url": "http://gitlab.dev/u/root",
      "website_url": ""
    }
  }
]
```

## Get a single build

Get a single build of a project

```
GET /projects/:id/builds/:build_id
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer | yes      | The ID of a project |
| `build_id` | integer | yes      | The ID of a build   |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/builds/8"
```

Example of response

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "created_at": "2015-12-24T15:51:21.880Z",
  "artifacts_file": null,
  "finished_at": "2015-12-24T17:54:31.198Z",
  "id": 8,
  "name": "rubocop",
  "pipeline": {
    "id": 6,
    "ref": "master",
    "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "status": "pending"
  }
  "ref": "master",
  "runner": null,
  "stage": "test",
  "started_at": "2015-12-24T17:54:30.733Z",
  "status": "failed",
  "tag": false,
  "user": {
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "bio": null,
    "created_at": "2015-12-21T13:14:24.077Z",
    "id": 1,
    "is_admin": true,
    "linkedin": "",
    "name": "Administrator",
    "skype": "",
    "state": "active",
    "twitter": "",
    "username": "root",
    "web_url": "http://gitlab.dev/u/root",
    "website_url": ""
  }
}
```

## Get build artifacts

> [Introduced][ce-2893] in GitLab 8.5

Get build artifacts of a project

```
GET /projects/:id/builds/:build_id/artifacts
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer | yes      | The ID of a project |
| `build_id` | integer | yes      | The ID of a build   |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/builds/8/artifacts"
```

Response:

| Status    | Description                     |
|-----------|---------------------------------|
| 200       | Serves the artifacts file       |
| 404       | Build not found or no artifacts |

[ce-2893]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2893

## Download the artifacts file

> [Introduced][ce-5347] in GitLab 8.10.

Download the artifacts file from the given reference name and job provided the
build finished successfully.

```
GET /projects/:id/builds/artifacts/:ref_name/download?job=name
```

Parameters

| Attribute   | Type    | Required | Description               |
|-------------|---------|----------|-------------------------- |
| `id`        | integer | yes      | The ID of a project       |
| `ref_name`  | string  | yes      | The ref from a repository |
| `job`       | string  | yes      | The name of the job       |

Example request:

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/builds/artifacts/master/download?job=test"
```

Example response:

| Status    | Description                     |
|-----------|---------------------------------|
| 200       | Serves the artifacts file       |
| 404       | Build not found or no artifacts |

[ce-5347]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5347

## Get a trace file

Get a trace of a specific build of a project

```
GET /projects/:id/builds/:build_id/trace
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| id         | integer | yes      | The ID of a project |
| build_id   | integer | yes      | The ID of a build   |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/builds/8/trace"
```

Response:

| Status    | Description                       |
|-----------|-----------------------------------|
| 200       | Serves the trace file             |
| 404       | Build not found or no trace file  |

## Cancel a build

Cancel a single build of a project

```
POST /projects/:id/builds/:build_id/cancel
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer | yes      | The ID of a project |
| `build_id` | integer | yes      | The ID of a build   |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/builds/1/cancel"
```

Example of response

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "created_at": "2016-01-11T10:13:33.506Z",
  "artifacts_file": null,
  "finished_at": "2016-01-11T10:14:09.526Z",
  "id": 69,
  "name": "rubocop",
  "ref": "master",
  "runner": null,
  "stage": "test",
  "started_at": null,
  "status": "canceled",
  "tag": false,
  "user": null
}
```

## Retry a build

Retry a single build of a project

```
POST /projects/:id/builds/:build_id/retry
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer | yes      | The ID of a project |
| `build_id` | integer | yes      | The ID of a build   |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/builds/1/retry"
```

Example of response

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "created_at": "2016-01-11T10:13:33.506Z",
  "artifacts_file": null,
  "finished_at": null,
  "id": 69,
  "name": "rubocop",
  "ref": "master",
  "runner": null,
  "stage": "test",
  "started_at": null,
  "status": "pending",
  "tag": false,
  "user": null
}
```

## Erase a build

Erase a single build of a project (remove build artifacts and a build trace)

```
POST /projects/:id/builds/:build_id/erase
```

Parameters

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer | yes      | The ID of a project |
| `build_id`  | integer | yes      | The ID of a build   |

Example of request

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/builds/1/erase"
```

Example of response

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "download_url": null,
  "id": 69,
  "name": "rubocop",
  "ref": "master",
  "runner": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "status": "failed",
  "tag": false,
  "user": null
}
```

## Keep artifacts

Prevents artifacts from being deleted when expiration is set.

```
POST /projects/:id/builds/:build_id/artifacts/keep
```

Parameters

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer | yes      | The ID of a project |
| `build_id`  | integer | yes      | The ID of a build   |

Example request:

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/builds/1/artifacts/keep"
```

Example response:

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "download_url": null,
  "id": 69,
  "name": "rubocop",
  "ref": "master",
  "runner": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "status": "failed",
  "tag": false,
  "user": null
}
```

## Play a build

Triggers a manual action to start a build.

```
POST /projects/:id/builds/:build_id/play
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer | yes      | The ID of a project |
| `build_id` | integer | yes      | The ID of a build   |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/builds/1/play"
```

Example of response

```json
{
  "commit": {
    "author_email": "admin@example.com",
    "author_name": "Administrator",
    "created_at": "2015-12-24T16:51:14.000+01:00",
    "id": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "message": "Test the CI integration.",
    "short_id": "0ff3ae19",
    "title": "Test the CI integration."
  },
  "coverage": null,
  "created_at": "2016-01-11T10:13:33.506Z",
  "artifacts_file": null,
  "finished_at": null,
  "id": 69,
  "name": "rubocop",
  "ref": "master",
  "runner": null,
  "stage": "test",
  "started_at": null,
  "status": "started",
  "tag": false,
  "user": null
}
```
