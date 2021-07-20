---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Jobs API **(FREE)**

## List project jobs

Get a list of jobs in a project. Jobs are sorted in descending order of their IDs.

```plaintext
GET /projects/:id/jobs
```

| Attribute | Type                           | Required | Description                                                                                                                                                                                                    |
|-----------|--------------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string                 | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                                                                                               |
| `scope`   | string **or** array of strings | no       | Scope of jobs to show. Either one of or an array of the following: `created`, `pending`, `running`, `failed`, `success`, `canceled`, `skipped`, or `manual`. All jobs are returned if `scope` is not provided. |

```shell
curl --globoff --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs?scope[]=pending&scope[]=running"
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
    "queued_duration": 0.010,
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
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
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
    "queued_duration": 0.023,
    "artifacts_expire_at": "2016-01-23T17:54:24.921Z",
    "tag_list": [
      "docker runner", "win10-2004"
    ],
    "id": 6,
    "name": "rspec:other",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
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

```plaintext
GET /projects/:id/pipelines/:pipeline_id/jobs
```

| Attribute         | Type                           | Required | Description                                                                                                                                                                                                    |
|-------------------|--------------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`              | integer/string                 | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                                                                                                   |
| `pipeline_id`     | integer                        | yes      | ID of a pipeline. Can also be obtained in CI jobs via the [predefined CI variable](../ci/variables/predefined_variables.md) `CI_PIPELINE_ID`.                                                                                                                                                            |
| `scope`           | string **or** array of strings | no       | Scope of jobs to show. Either one of or an array of the following: `created`, `pending`, `running`, `failed`, `success`, `canceled`, `skipped`, or `manual`. All jobs are returned if `scope` is not provided. |
| `include_retried` | boolean                        | no       | Include retried jobs in the response. Defaults to `false`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/272627) in GitLab 13.9.                                                                  |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/6/jobs?scope[]=pending&scope[]=running"
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
    "queued_duration": 0.023,
    "artifacts_expire_at": "2016-01-23T17:54:24.921Z",
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 6,
    "name": "rspec:other",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
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
    "queued_duration": 0.023,
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
    "tag_list": [
      "docker runner", "ubuntu18"
    ],
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending"
    },
    "ref": "main",
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

In GitLab 13.3 and later, this endpoint [returns data for any pipeline](pipelines.md#single-pipeline-requests)
including [child pipelines](../ci/pipelines/parent_child_pipelines.md).

In GitLab 13.5 and later, this endpoint does not return retried jobs in the response
by default. Additionally, jobs are sorted by ID in descending order (newest first).
In earlier GitLab versions, jobs are sorted by ID in ascending order (oldest first).

In GitLab 13.9 and later, this endpoint can include retried jobs in the response
with `include_retried` set to `true`.

## List pipeline bridges

Get a list of bridge jobs for a pipeline.

```plaintext
GET /projects/:id/pipelines/:pipeline_id/bridges
```

| Attribute     | Type                           | Required | Description                                                                                                                                                                                                    |
|---------------|--------------------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | integer/string                 | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user.                                                                                               |
| `pipeline_id` | integer                        | yes      | ID of a pipeline.                                                                                                                                                                                          |
| `scope`       | string **or** array of strings | no       | Scope of jobs to show. Either one of or an array of the following: `created`, `pending`, `running`, `failed`, `success`, `canceled`, `skipped`, or `manual`. All jobs are returned if `scope` is not provided. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/pipelines/6/bridges?scope[]=pending&scope[]=running"
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
    "finished_at": "2015-12-24T17:58:27.895Z",
    "duration": 240,
    "queued_duration": 0.123,
    "id": 7,
    "name": "teaspoon",
    "pipeline": {
      "id": 6,
      "project_id": 1,
      "ref": "main",
      "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
      "status": "pending",
      "created_at": "2015-12-24T15:50:16.123Z",
      "updated_at": "2015-12-24T18:00:44.432Z",
      "web_url": "https://example.com/foo/bar/pipelines/6"
    },
    "ref": "main",
    "stage": "test",
    "status": "pending",
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
    },
    "downstream_pipeline": {
      "id": 5,
      "sha": "f62a4b2fb89754372a346f24659212eb8da13601",
      "ref": "main",
      "status": "pending",
      "created_at": "2015-12-24T17:54:27.722Z",
      "updated_at": "2015-12-24T17:58:27.896Z",
      "web_url": "https://example.com/diaspora/diaspora-client/pipelines/5"
    }
  }
]
```

## Get job token's job

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/51727) in GitLab 13.10.

Retrieve the job that generated a job token.

```plaintext
GET /job
```

Examples

```shell
curl --header "JOB-TOKEN: <your_job_token>" "https://gitlab.example.com/api/v4/job"
curl "https://gitlab.example.com/api/v4/job?job_token=<your_job_token>"
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
  "queued_duration": 0.123,
  "artifacts_expire_at": "2016-01-23T17:54:31.198Z",
  "id": 8,
  "name": "rubocop",
  "pipeline": {
    "id": 6,
    "project_id": 1,
    "ref": "main",
    "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "status": "pending"
  },
  "ref": "main",
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

## Get Kubernetes Agents by `CI_JOB_TOKEN` **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/324269) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.11.

Retrieve the job that generated the `CI_JOB_TOKEN`, along with a list of allowed GitLab
Kubernetes Agents.

```plaintext
GET /job/allowed_agents
```

Supported attributes:

| Attribute      | Type     | Required | Description           |
|:------------   |:---------|:---------|:----------------------|
| `CI_JOB_TOKEN` | string   | yes      | Token value associated with the GitLab-provided `CI_JOB_TOKEN` variable. |

Example request:

```shell
curl --header "JOB-TOKEN: <CI_JOB_TOKEN>" "https://gitlab.example.com/api/v4/job/allowed_agents"
curl "https://gitlab.example.com/api/v4/job/allowed_agents?job_token=<CI_JOB_TOKEN>"
```

Example response:

```json
{
  "allowed_agents":
    [
      {
        "id": 1,
        "config_project": {
          "id": 1,
          "description": null,
          "name": "project1",
          "name_with_namespace": "John Doe2 / project1",
          "path": "project1",
          "path_with_namespace": "namespace1/project1",
          "created_at": "2021-03-26T14:51:50.579Z"
        }
      }
    ],
  "job": {
    "id": 1,
    "name": "test",
    "stage": "test",
    "project_id": 1,
    "project_name": "project1"
  },
  "pipeline": {
    "id": 1,
    "project_id": 1,
    "sha": "b83d6e391c22777fca1ed3012fce84f633d7fed0",
    "ref": "main",
    "status": "pending",
    "created_at": "2021-03-26T14:51:51.107Z",
    "updated_at": "2021-03-26T14:51:51.107Z",
    "web_url": "http://localhost/namespace1/project1/-/pipelines/1"
  },
  "project": {
    "id": 1,
    "description": null,
    "name": "project1",
    "name_with_namespace": "John Doe2 / project1",
    "path": "project1",
    "path_with_namespace": "namespace1/project1",
    "created_at": "2021-03-26T14:51:50.579Z"
  },
  "user": {
    "id": 2,
    "name": "John Doe3",
    "username": "user2",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/10fc7f102b",
    "web_url": "http://localhost/user2"
  }
}
```

## Get a single job

Get a single job of a project

```plaintext
GET /projects/:id/jobs/:job_id
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

```shell
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
  "queued_duration": 0.010,
  "artifacts_expire_at": "2016-01-23T17:54:31.198Z",
  "tag_list": [
      "docker runner", "macos-10.15"
    ],
  "id": 8,
  "name": "rubocop",
  "pipeline": {
    "id": 6,
    "project_id": 1,
    "ref": "main",
    "sha": "0ff3ae198f8601a285adcf5c0fff204ee6fba5fd",
    "status": "pending"
  },
  "ref": "main",
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

## Get a log file

Get a log (trace) of a specific job of a project:

```plaintext
GET /projects/:id/jobs/:job_id/trace
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/8/trace"
```

Possible response status codes:

| Status    | Description                   |
|-----------|-------------------------------|
| 200       | Serves the log file           |
| 404       | Job not found or no log file  |

## Cancel a job

Cancel a single job of a project

```plaintext
POST /projects/:id/jobs/:job_id/cancel
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

```shell
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
  "queued_duration": 0.010,
  "id": 42,
  "name": "rubocop",
  "ref": "main",
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

```plaintext
POST /projects/:id/jobs/:job_id/retry
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

```shell
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
  "queued_duration": 0.010,
  "id": 42,
  "name": "rubocop",
  "ref": "main",
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

```plaintext
POST /projects/:id/jobs/:job_id/erase
```

Parameters

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

Example of request

```shell
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
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "created_at": "2016-01-11T10:13:33.506Z",
  "started_at": "2016-01-11T10:13:33.506Z",
  "finished_at": "2016-01-11T10:15:10.506Z",
  "duration": 97.0,
  "queued_duration": 0.010,
  "status": "failed",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```

## Play a job

Triggers a manual action to start a job.

```plaintext
POST /projects/:id/jobs/:job_id/play
```

| Attribute | Type           | Required | Description                                                                                                      |
|-----------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

```shell
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
  "queued_duration": 0.010,
  "id": 42,
  "name": "rubocop",
  "ref": "main",
  "artifacts": [],
  "runner": null,
  "stage": "test",
  "status": "pending",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```
