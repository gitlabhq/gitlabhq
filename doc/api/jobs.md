# Jobs API

## List project jobs

Get a list of jobs in a project. Jobs are sorted in descending order of their IDs.

```
GET /projects/:id/jobs
```

| Attribute | Type                           | Required | Description                                                                                                                                                                                                    |
|-----------|--------------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string                 | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user.                                                                                               |
| `scope`   | string **or** array of strings | no       | Scope of jobs to show. Either one of or an array of the following: `created`, `pending`, `running`, `failed`, `success`, `canceled`, `skipped`, or `manual`. All jobs are returned if `scope` is not provided. |

```sh
curl --globoff --header "PRIVATE-TOKEN: <your_access_token>" 'https://gitlab.example.com/api/v4/projects/1/jobs?scope[]=pending&scope[]=running'
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
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:54:27.895Z",
    "duration": 0.173,
    "artifacts_file": {
      "filename": "artifacts.zip",
      "size": 1000
    },
    "artifacts": [
      {"file_type": "archive", "size": 1000, "filename": "artifacts.zip", "file_format": "zip"},
      {"file_type": "metadata", "size": 186, "filename": "metadata.gz", "file_format": "gzip"},
      {"file_type": "trace", "size": 1500, "filename": "job.log", "file_format": "raw"},
      {"file_type": "junit", "size": 750, "filename": "junit.xml.gz", "file_format": "gzip"}
    ],
    "artifacts_expire_at": "2016-01-23T17:54:27.895Z",
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "ref": "master",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "master",
    "artifacts": [],
    "runner": null,
    "stage": "test",
    "status": "failed",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
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
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.727Z",
    "started_at": "2015-12-24T17:54:24.729Z",
    "finished_at": "2015-12-24T17:54:24.921Z",
    "duration": 0.192,
    "artifacts_expire_at": "2016-01-23T17:54:24.921Z",
    "id": 6,
    "name": "rspec:other",
    "pipeline": {
      "id": 6,
      "ref": "master",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "master",
    "artifacts": [],
    "runner": null,
    "stage": "test",
    "status": "failed",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/6",
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
    }
  }
]
```

## List pipeline jobs

Get a list of jobs for a pipeline.

```
GET /projects/:id/pipelines/:pipeline_id/jobs
```

| Attribute     | Type                           | Required | Description                                                                                                                                                                                                    |
|---------------|--------------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | integer/string                 | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user.                                                                                               |
| `pipeline_id` | integer                        | yes      | ID of a pipeline.                                                                                                                                                                                          |
| `scope`       | string **or** array of strings | no       | Scope of jobs to show. Either one of or an array of the following: `created`, `pending`, `running`, `failed`, `success`, `canceled`, `skipped`, or `manual`. All jobs are returned if `scope` is not provided. |

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" 'https://gitlab.example.com/api/v4/projects/1/pipelines/6/jobs?scope[]=pending&scope[]=running'
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
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.727Z",
    "started_at": "2015-12-24T17:54:24.729Z",
    "finished_at": "2015-12-24T17:54:24.921Z",
    "duration": 0.192,
    "artifacts_expire_at": "2016-01-23T17:54:24.921Z",
    "id": 6,
    "name": "rspec:other",
    "pipeline": {
      "id": 6,
      "ref": "master",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "master",
    "artifacts": [],
    "runner": null,
    "stage": "test",
    "status": "failed",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/6",
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
    "allow_failure": false,
    "created_at": "2015-12-24T15:51:21.802Z",
    "started_at": "2015-12-24T17:54:27.722Z",
    "finished_at": "2015-12-24T17:54:27.895Z",
    "duration": 0.173,
    "artifacts_file": {
      "filename": "artifacts.zip",
      "size": 1000
    },
    "artifacts": [
      {"file_type": "archive", "size": 1000, "filename": "artifacts.zip", "file_format": "zip"},
      {"file_type": "metadata", "size": 186, "filename": "metadata.gz", "file_format": "gzip"},
      {"file_type": "trace", "size": 1500, "filename": "job.log", "file_format": "raw"},
      {"file_type": "junit", "size": 750, "filename": "junit.xml.gz", "file_format": "gzip"}
    ],
    "artifacts_expire_at": "2016-01-23T17:54:27.895Z",
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "ref": "master",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "master",
    "artifacts": [],
    "runner": null,
    "stage": "test",
    "status": "failed",
    "tag": false,
    "web_url": "https://example.com/foo/bar/-/jobs/7",
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
    }
  }
]
```

## Get a single job

Get a single job of a project

```
GET /projects/:id/jobs/:job_id
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/8"
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
  "allow_failure": false,
  "created_at": "2015-12-24T15:51:21.880Z",
  "started_at": "2015-12-24T17:54:30.733Z",
  "finished_at": "2015-12-24T17:54:31.198Z",
  "duration": 0.465,
  "artifacts_expire_at": "2016-01-23T17:54:31.198Z",
  "id": 8,
  "name": "rubocop",
  "pipeline": {
    "id": 6,
    "ref": "master",
    "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "status": "pending"
  },
  "ref": "master",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "status": "failed",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/8",
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
  }
}
```

## Get job artifacts

> **Notes**:
>
> - [Introduced][ce-2893] in GitLab 8.5.
> - The use of `CI_JOB_TOKEN` in the artifacts download API was [introduced][ee-2346]
>   in [GitLab Premium][ee] 9.5.

Get the job's artifacts zipped archive of a project.

```
GET /projects/:id/jobs/:job_id/artifacts
```

| Attribute   | Type           | Required | Description                                                                                                                                     |
|-------------|----------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user.                                |
| `job_id`    | integer        | yes      | ID of a job.                                                                                                                                |
| `job_token` **(PREMIUM)** | string         | no       | To be used with [triggers] for multi-project pipelines. It should be invoked only inside `.gitlab-ci.yml`. Its value is always `$CI_JOB_TOKEN`. |

Example request using the `PRIVATE-TOKEN` header:

```sh
curl --output artifacts.zip --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts"
```

To use this in a [`script` definition](../ci/yaml/README.md#script) inside
`.gitlab-ci.yml` **(PREMIUM)**, you can use either:

- The `JOB-TOKEN` header with the GitLab-provided `CI_JOB_TOKEN` variable.
  For example, the following job will download the artifacts of the job with ID
  `42`. Note that the command is wrapped into single quotes since it contains a
  colon (`:`):

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip --header "JOB-TOKEN: $CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts"'
  ```

- Or the `job_token` attribute with the GitLab-provided `CI_JOB_TOKEN` variable.
  For example, the following job will download the artifacts of the job with ID `42`:

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts?job_token=$CI_JOB_TOKEN"'
  ```

Possible response status codes:

| Status    | Description                     |
|-----------|---------------------------------|
| 200       | Serves the artifacts file.      |
| 404       | Build not found or no artifacts.|

[ce-2893]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/2893

## Download the artifacts archive

> **Notes**:
>
> - [Introduced][ce-5347] in GitLab 8.10.
> - The use of `CI_JOB_TOKEN` in the artifacts download API was [introduced][ee-2346]
>   in [GitLab Premium][ee] 9.5.

Download the artifacts zipped archive from the latest successful pipeline for
the given reference name and job, provided the job finished successfully. This
is the same as [getting the job's artifacts](#get-job-artifacts), but by
defining the job's name instead of its ID.

```
GET /projects/:id/jobs/artifacts/:ref_name/download?job=name
```

Parameters

| Attribute   | Type           | Required | Description                                                                                                                                     |
|-------------|----------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user.                                |
| `ref_name`  | string         | yes      | Branch or tag name in repository. HEAD or SHA references are not supported.                                                                     |
| `job`       | string         | yes      | The name of the job.                                                                                                                            |
| `job_token` **(PREMIUM)** | string         | no       | To be used with [triggers] for multi-project pipelines. It should be invoked only inside `.gitlab-ci.yml`. Its value is always `$CI_JOB_TOKEN`. |

Example request using the `PRIVATE-TOKEN` header:

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/master/download?job=test"
```

To use this in a [`script` definition](../ci/yaml/README.md#script) inside
`.gitlab-ci.yml` **(PREMIUM)**, you can use either:

- The `JOB-TOKEN` header with the GitLab-provided `CI_JOB_TOKEN` variable.
  For example, the following job will download the artifacts of the `test` job
  of the `master` branch. Note that the command is wrapped into single quotes
  since it contains a colon (`:`):

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip --header "JOB-TOKEN: $CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/master/download?job=test"'
  ```

- Or the `job_token` attribute with the GitLab-provided `CI_JOB_TOKEN` variable.
  For example, the following job will download the artifacts of the `test` job
  of the `master` branch:

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/master/download?job=test&job_token=$CI_JOB_TOKEN"'
  ```

Possible response status codes:

| Status    | Description                     |
|-----------|---------------------------------|
| 200       | Serves the artifacts file.      |
| 404       | Build not found or no artifacts.|

[ce-5347]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/5347

## Download a single artifact file by job ID

> Introduced in GitLab 10.0

Download a single artifact file from a job with a specified ID from within
the job's artifacts zipped archive. The file is extracted from the archive and
streamed to the client.

```
GET /projects/:id/jobs/:job_id/artifacts/*artifact_path
```

Parameters

| Attribute       | Type           | Required | Description                                                                                                      |
|-----------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`            | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`        | integer        | yes      | The unique job identifier.                                                                                       |
| `artifact_path` | string         | yes      | Path to a file inside the artifacts archive.                                                                     |

Example request:

```sh
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/5/artifacts/some/release/file.pdf"
```

Possible response status codes:

| Status    | Description                          |
|-----------|--------------------------------------|
| 200       | Sends a single artifact file         |
| 400       | Invalid path provided                |
| 404       | Build not found or no file/artifacts |

## Download a single artifact file from specific tag or branch

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/23538) in GitLab 11.5.

Download a single artifact file for a specific job of the latest successful
pipeline for the given reference name from within the job's artifacts archive.
The file is extracted from the archive and streamed to the client.

```
GET /projects/:id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name
```

Parameters:

| Attribute       | Type           | Required | Description                                                                                                      |
|-----------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`            | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `ref_name`      | string         | yes      | Branch or tag name in repository. HEAD or SHA references are not supported.                                      |
| `artifact_path` | string         | yes      | Path to a file inside the artifacts archive.                                                                     |
| `job`           | string         | yes      | The name of the job.                                                                                             |

Example request:

```sh
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/master/raw/some/release/file.pdf?job=pdf"
```

Possible response status codes:

| Status    | Description                          |
|-----------|--------------------------------------|
| 200       | Sends a single artifact file         |
| 400       | Invalid path provided                |
| 404       | Build not found or no file/artifacts |

## Get a log file

Get a log (trace) of a specific job of a project:

```
GET /projects/:id/jobs/:job_id/trace
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| id        | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| job_id    | integer        | yes      | ID of a job.                                                                                                 |

```sh
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/8/trace"
```

Possible response status codes:

| Status    | Description                   |
|-----------|-------------------------------|
| 200       | Serves the log file           |
| 404       | Job not found or no log file  |

## Cancel a job

Cancel a single job of a project

```
POST /projects/:id/jobs/:job_id/cancel
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

```sh
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/1/cancel"
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
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:14:09.526Z",
  "finished_at": null,
  "duration": 8,
  "id": 42,
  "name": "rubocop",
  "ref": "master",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "status": "canceled",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```

## Retry a job

Retry a single job of a project

```
POST /projects/:id/jobs/:job_id/retry
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

```sh
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/1/retry"
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
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": null,
  "finished_at": null,
  "duration": null,
  "id": 42,
  "name": "rubocop",
  "ref": "master",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "status": "pending",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```

## Erase a job

Erase a single job of a project (remove job artifacts and a job log)

```
POST /projects/:id/jobs/:job_id/erase
```

Parameters

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

Example of request

```sh
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/1/erase"
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
  "allow_failure": false,
  "download_url": null,
  "id": 42,
  "name": "rubocop",
  "ref": "master",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "duration": 97.0,
  "status": "failed",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```

## Keep artifacts

Prevents artifacts from being deleted when expiration is set.

```
POST /projects/:id/jobs/:job_id/artifacts/keep
```

Parameters

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

Example request:

```sh
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts/keep"
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
  "allow_failure": false,
  "download_url": null,
  "id": 42,
  "name": "rubocop",
  "ref": "master",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "duration": 97.0,
  "status": "failed",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```

## Delete artifacts

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/25522) in GitLab 11.9.

Delete artifacts of a job.

```
DELETE /projects/:id/jobs/:job_id/artifacts
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `job_id`  | integer        | yes      | ID of a job.                                                                |

Example request:

```sh
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts"
```

NOTE: **Note:**
At least Maintainer role is required to delete artifacts.

If the artifacts were deleted successfully, a response with status `204 No Content` is returned.

## Play a job

Triggers a manual action to start a job.

```
POST /projects/:id/jobs/:job_id/play
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

```sh
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/1/play"
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
  "allow_failure": false,
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": null,
  "finished_at": null,
  "duration": null,
  "id": 42,
  "name": "rubocop",
  "ref": "master",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "status": "started",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```

[ee]: https://about.gitlab.com/pricing/
[ee-2346]: https://gitlab.com/gitlab-org/gitlab/merge_requests/2346
[triggers]: ../ci/triggers/README.md#when-a-pipeline-depends-on-the-artifacts-of-another-pipeline-premium
