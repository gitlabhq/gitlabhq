# Jobs API

## List project jobs

Get a list of jobs in a project.

```
GET /projects/:id/jobs
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `scope`   | string **or** array of strings | no | The scope of jobs to show, one or array of: `created`, `pending`, `running`, `failed`, `success`, `canceled`, `skipped`, `manual`; showing all jobs if none provided |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/1/jobs?scope[]=pending&scope[]=running'
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
    },
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
      "linkedin": "",
      "name": "Administrator",
      "skype": "",
      "state": "active",
      "twitter": "",
      "username": "root",
      "web_url": "http://gitlab.dev/root",
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
    },
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
      "linkedin": "",
      "name": "Administrator",
      "skype": "",
      "state": "active",
      "twitter": "",
      "username": "root",
      "web_url": "http://gitlab.dev/root",
      "website_url": ""
    }
  }
]
```

## List pipeline jobs

Get a list of jobs for a pipeline.

```
GET /projects/:id/pipelines/:pipeline_id/jobs
```

| Attribute     | Type                           | Required | Description          |
|---------------|--------------------------------|----------|----------------------|
| `id`          | integer/string                        | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user  |
| `pipeline_id` | integer                        | yes      | The ID of a pipeline |
| `scope`       | string **or** array of strings | no       | The scope of jobs to show, one or array of: `created`, `pending`, `running`, `failed`, `success`, `canceled`, `skipped`, `manual`; showing all jobs if none provided |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" 'https://gitlab.example.com/api/v4/projects/1/pipelines/6/jobs?scope[]=pending&scope[]=running'
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
    },
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
      "linkedin": "",
      "name": "Administrator",
      "skype": "",
      "state": "active",
      "twitter": "",
      "username": "root",
      "web_url": "http://gitlab.dev/root",
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
    },
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
      "linkedin": "",
      "name": "Administrator",
      "skype": "",
      "state": "active",
      "twitter": "",
      "username": "root",
      "web_url": "http://gitlab.dev/root",
      "website_url": ""
    }
  }
]
```

## Get a single job

Get a single job of a project

```
GET /projects/:id/jobs/:job_id
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `job_id` | integer | yes      | The ID of a job   |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/8"
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
  },
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
    "linkedin": "",
    "name": "Administrator",
    "skype": "",
    "state": "active",
    "twitter": "",
    "username": "root",
    "web_url": "http://gitlab.dev/root",
    "website_url": ""
  }
}
```

## Get job artifacts

> **Notes**:
- [Introduced][ce-2893] in GitLab 8.5.
<<<<<<< HEAD
- The use of `CI_JOB_TOKEN` in the artifacts download API was [introduced][ee-2346]
  in [GitLab Premium][ee] 9.5.
=======
>>>>>>> upstream/master

Get job artifacts of a project.

```
GET /projects/:id/jobs/:job_id/artifacts
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `job_id` | integer | yes      | The ID of a job   |
| `job_token` | string  | no       | To be used with [triggers] for multi-project pipelines. Is should be invoked only inside `.gitlab-ci.yml`. Its value is always `$CI_JOB_TOKEN`. |

Example requests:

<<<<<<< HEAD
- Using the `PRIVATE-TOKEN` header:

    ```
    curl --location --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/8/artifacts"
    ```

- Using the `JOB-TOKEN` header (only inside `.gitlab-ci.yml`):

    ```
    curl --location --header "JOB-TOKEN: $CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/1/jobs/8/artifacts"
    ```

- Using the `job_token` parameter (only inside `.gitlab-ci.yml`):

    ```
    curl --location --header --form "job-token=$CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/1/jobs/8/artifacts"
    ```
=======
```
curl --location --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/8/artifacts"
```
>>>>>>> upstream/master

Response:

| Status    | Description                     |
|-----------|---------------------------------|
| 200       | Serves the artifacts file       |
| 404       | Build not found or no artifacts |

[ce-2893]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2893

## Download the artifacts archive

> **Notes**:
- [Introduced][ce-5347] in GitLab 8.10.
<<<<<<< HEAD
- The use of `CI_JOB_TOKEN` in the artifacts download API was [introduced][ee-2346]
  in [GitLab Premium][ee] 9.5.
=======
>>>>>>> upstream/master

Download the artifacts archive from the given reference name and job provided the
job finished successfully.

```
GET /projects/:id/jobs/artifacts/:ref_name/download?job=name
```

Parameters

| Attribute   | Type    | Required | Description               |
|-------------|---------|----------|-------------------------- |
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user       |
| `ref_name`  | string  | yes      | The ref from a repository (can only be branch or tag name, not HEAD or SHA) |
| `job`       | string  | yes      | The name of the job       |
| `job_token` | string  | no       | To be used with [triggers] for multi-project pipelines. Is should be invoked only inside `.gitlab-ci.yml`. Its value is always `$CI_JOB_TOKEN`. |

Example requests:

- Using the `PRIVATE-TOKEN` header:

    ```
    curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/master/download?job=test"
    ```

- Using the `JOB-TOKEN` header (only inside `.gitlab-ci.yml`):

    ```
    curl --header "JOB-TOKEN: $CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/master/download?job=test"
    ```

- Using the `job_token` parameter (only inside `.gitlab-ci.yml`):

    ```
    curl --header --form "job-token=$CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/master/download?job=test"
    ```

Example response:

| Status    | Description                     |
|-----------|---------------------------------|
| 200       | Serves the artifacts file       |
| 404       | Build not found or no artifacts |

[ce-5347]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5347

## Download a single artifact file

> Introduced in GitLab 10.0

Download a single artifact file from within the job's artifacts archive.

Only a single file is going to be extracted from the archive and streamed to a client.

```
GET /projects/:id/jobs/:job_id/artifacts/*artifact_path
```

Parameters

| Attribute       | Type    | Required | Description               |
|-----------------|---------|----------|-------------------------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user       |
| `job_id  `      | integer | yes      | The unique job identifier |
| `artifact_path` | string  | yes      | Path to a file inside the artifacts archive |

Example request:

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/5/artifacts/some/release/file.pdf"
```

Example response:

| Status    | Description                          |
|-----------|--------------------------------------|
| 200       | Sends a single artifact file         |
| 400       | Invalid path provided                |
| 404       | Build not found or no file/artifacts |

## Get a trace file

Get a trace of a specific job of a project

```
GET /projects/:id/jobs/:job_id/trace
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| id         | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| job_id     | integer | yes      | The ID of a job     |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/8/trace"
```

Response:

| Status    | Description                       |
|-----------|-----------------------------------|
| 200       | Serves the trace file             |
| 404       | Build not found or no trace file  |

## Cancel a job

Cancel a single job of a project

```
POST /projects/:id/jobs/:job_id/cancel
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `job_id`   | integer | yes      | The ID of a job     |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/1/cancel"
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

## Retry a job

Retry a single job of a project

```
POST /projects/:id/jobs/:job_id/retry
```

| Attribute  | Type    | Required | Description         |
|------------|---------|----------|---------------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `job_id`   | integer | yes      | The ID of a job     |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/1/retry"
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

## Erase a job

Erase a single job of a project (remove job artifacts and a job trace)

```
POST /projects/:id/jobs/:job_id/erase
```

Parameters

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `job_id`    | integer | yes      | The ID of a job     |

Example of request

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/1/erase"
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
POST /projects/:id/jobs/:job_id/artifacts/keep
```

Parameters

| Attribute   | Type    | Required | Description         |
|-------------|---------|----------|---------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `job_id`    | integer | yes      | The ID of a job     |

Example request:

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts/keep"
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

## Play a job

Triggers a manual action to start a job.

```
POST /projects/:id/jobs/:job_id/play
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `job_id`  | integer | yes      | The ID of a job     |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/jobs/1/play"
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

[ee]: https://about.gitlab.com/products/
[ee-2346]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/2346
[triggers]: ../ci/triggers/README.md#when-a-pipeline-depends-on-the-artifacts-of-another-pipeline
