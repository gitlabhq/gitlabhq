---
stage: Verify
group: Testing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Job Artifacts API

## Get job artifacts

> The use of `CI_JOB_TOKEN` in the artifacts download API was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/2346) in [GitLab Premium](https://about.gitlab.com/pricing/) 9.5.

Get the job's artifacts zipped archive of a project.

```plaintext
GET /projects/:id/jobs/:job_id/artifacts
```

| Attribute   | Type           | Required | Description                                                                                                  |
|-------------|----------------|----------|--------------------------------------------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`    | integer        | yes      | ID of a job.                                                                                                 |
| `job_token` **(PREMIUM)** | string | no | To be used with [triggers](../ci/triggers/index.md#when-a-pipeline-depends-on-the-artifacts-of-another-pipeline) for multi-project pipelines. It should be invoked only inside `.gitlab-ci.yml`. Its value is always `$CI_JOB_TOKEN`. |

Example request using the `PRIVATE-TOKEN` header:

```shell
curl --output artifacts.zip --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts"
```

To use this in a [`script` definition](../ci/yaml/index.md#script) inside
`.gitlab-ci.yml` **(PREMIUM)**, you can use either:

- The `JOB-TOKEN` header with the GitLab-provided `CI_JOB_TOKEN` variable.
  For example, the following job downloads the artifacts of the job with ID
  `42`. Note that the command is wrapped into single quotes because it contains a
  colon (`:`):

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip --header "JOB-TOKEN: $CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts"'
  ```

- Or the `job_token` attribute with the GitLab-provided `CI_JOB_TOKEN` variable.
  For example, the following job downloads the artifacts of the job with ID `42`:

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

## Download the artifacts archive

> The use of `CI_JOB_TOKEN` in the artifacts download API was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/2346) in [GitLab Premium](https://about.gitlab.com/pricing/) 9.5.

Download the artifacts zipped archive from the latest successful pipeline for
the given reference name and job, provided the job finished successfully. This
is the same as [getting the job's artifacts](#get-job-artifacts), but by
defining the job's name instead of its ID.

NOTE:
If a pipeline is [parent of other child pipelines](../ci/pipelines/parent_child_pipelines.md), artifacts
are searched in hierarchical order from parent to child. For example, if both parent and
child pipelines have a job with the same name, the artifact from the parent pipeline is returned.

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/download?job=name
```

Parameters

| Attribute   | Type           | Required | Description                                                                                                  |
|-------------|----------------|----------|--------------------------------------------------------------------------------------------------------------|
| `id`        | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `ref_name`  | string         | yes      | Branch or tag name in repository. HEAD or SHA references are not supported.                                  |
| `job`       | string         | yes      | The name of the job.                                                                                         |
| `job_token` **(PREMIUM)** | string | no | To be used with [triggers](../ci/triggers/index.md#when-a-pipeline-depends-on-the-artifacts-of-another-pipeline) for multi-project pipelines. It should be invoked only inside `.gitlab-ci.yml`. Its value is always `$CI_JOB_TOKEN`. |

Example request using the `PRIVATE-TOKEN` header:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test"
```

To use this in a [`script` definition](../ci/yaml/index.md#script) inside
`.gitlab-ci.yml` **(PREMIUM)**, you can use either:

- The `JOB-TOKEN` header with the GitLab-provided `CI_JOB_TOKEN` variable.
  For example, the following job downloads the artifacts of the `test` job
  of the `main` branch. Note that the command is wrapped into single quotes
  because it contains a colon (`:`):

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip --header "JOB-TOKEN: $CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/main/download?job=test"'
  ```

- Or the `job_token` attribute with the GitLab-provided `CI_JOB_TOKEN` variable.
  For example, the following job downloads the artifacts of the `test` job
  of the `main` branch:

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN"'
  ```

Possible response status codes:

| Status    | Description                     |
|-----------|---------------------------------|
| 200       | Serves the artifacts file.      |
| 404       | Build not found or no artifacts.|

## Download a single artifact file by job ID

> - Introduced in GitLab 10.0.
> - The use of `CI_JOB_TOKEN` in the artifacts download API was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55042) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.10.

Download a single artifact file from a job with a specified ID from inside
the job's artifacts zipped archive. The file is extracted from the archive and
streamed to the client.

```plaintext
GET /projects/:id/jobs/:job_id/artifacts/*artifact_path
```

Parameters

| Attribute       | Type           | Required | Description                                                                                                      |
|-----------------|----------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`            | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`        | integer        | yes      | The unique job identifier.                                                                                       |
| `artifact_path` | string         | yes      | Path to a file inside the artifacts archive.                                                                     |
| `job_token` **(PREMIUM)** | string | no     | To be used with [triggers](../ci/triggers/index.md#when-a-pipeline-depends-on-the-artifacts-of-another-pipeline) for multi-project pipelines. It should be invoked only inside `.gitlab-ci.yml`. Its value is always `$CI_JOB_TOKEN`. |

Example request:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/5/artifacts/some/release/file.pdf"
```

Possible response status codes:

| Status    | Description                          |
|-----------|--------------------------------------|
| 200       | Sends a single artifact file         |
| 400       | Invalid path provided                |
| 404       | Build not found or no file/artifacts |

## Download a single artifact file from specific tag or branch

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/23538) in GitLab 11.5.
> - The use of `CI_JOB_TOKEN` in the artifacts download API was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55042) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.10.

Download a single artifact file for a specific job of the latest successful
pipeline for the given reference name from inside the job's artifacts archive.
The file is extracted from the archive and streamed to the client.

In [GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/201784) and later, artifacts
for [parent and child pipelines](../ci/pipelines/parent_child_pipelines.md) are searched in hierarchical
order from parent to child. For example, if both parent and child pipelines have a
job with the same name, the artifact from the parent pipeline is returned.

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name
```

Parameters:

| Attribute       | Type           | Required | Description                                                                                                  |
|-----------------|----------------|----------|--------------------------------------------------------------------------------------------------------------|
| `id`            | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `ref_name`      | string         | yes      | Branch or tag name in repository. `HEAD` or `SHA` references are not supported.                              |
| `artifact_path` | string         | yes      | Path to a file inside the artifacts archive.                                                                 |
| `job`           | string         | yes      | The name of the job.                                                                                         |
| `job_token` **(PREMIUM)** | string | no     | To be used with [triggers](../ci/triggers/index.md#when-a-pipeline-depends-on-the-artifacts-of-another-pipeline) for multi-project pipelines. It should be invoked only inside `.gitlab-ci.yml`. Its value is always `$CI_JOB_TOKEN`. |

Example request:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/raw/some/release/file.pdf?job=pdf"
```

Possible response status codes:

| Status    | Description                          |
|-----------|--------------------------------------|
| 200       | Sends a single artifact file         |
| 400       | Invalid path provided                |
| 404       | Build not found or no file/artifacts |

## Keep artifacts

Prevents artifacts from being deleted when expiration is set.

```plaintext
POST /projects/:id/jobs/:job_id/artifacts/keep
```

Parameters

| Attribute | Type           | Required | Description                                                                                                  |
|-----------|----------------|----------|--------------------------------------------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `job_id`  | integer        | yes      | ID of a job.                                                                                                 |

Example request:

```shell
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
  "ref": "main",
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/25522) in GitLab 11.9.

Delete artifacts of a job.

```plaintext
DELETE /projects/:id/jobs/:job_id/artifacts
```

| Attribute | Type           | Required | Description                                                                 |
|-----------|----------------|----------|-----------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `job_id`  | integer        | yes      | ID of a job.                                                                |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts"
```

NOTE:
At least Maintainer role is required to delete artifacts.

If the artifacts were deleted successfully, a response with status `204 No Content` is returned.
