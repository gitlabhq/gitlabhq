---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Job Artifacts API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to interact with [job artifacts](../ci/jobs/job_artifacts.md).

Authentication with a [CI/CD job token](../ci/jobs/job_artifacts.md#with-a-cicd-job-token)
is available in the Premium and Ultimate tier.

## Download job artifacts by job ID

Download a job's artifacts archive using the job ID.

If you use cURL to download artifacts from GitLab.com, use the `--location` parameter
as the request might redirect through a CDN.

```plaintext
GET /projects/:id/jobs/:job_id/artifacts
```

Supported attributes:

| Attribute   | Type           | Required | Description |
| ----------- | -------------- | -------- | ----------- |
| `id`        | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `job_id`    | integer        | Yes      | ID of a job. |
| `job_token` | string         | No       | To be used with [triggers](../ci/jobs/job_artifacts.md#with-a-cicd-job-token) for multi-project pipelines. It should be invoked only in a CI/CD job defined in the `.gitlab-ci.yml` file. The value is always `$CI_JOB_TOKEN`. The job associated with the `$CI_JOB_TOKEN` must be running when this token is used. Premium and Ultimate only. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and serves the artifacts file.

Example request using the `PRIVATE-TOKEN` header:

```shell
curl --location --output artifacts.zip --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts"
```

In the Premium and Ultimate tier you can authenticate with this endpoint
in a CI/CD job by using a [CI/CD job token](../ci/jobs/ci_job_token.md).

Use either:

- The `job_token` attribute with the GitLab-provided `CI_JOB_TOKEN` predefined variable.
  For example, the following job downloads the artifacts of the job with ID `42`:

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts?job_token=$CI_JOB_TOKEN"'
  ```

- The `JOB-TOKEN` header with the GitLab-provided `CI_JOB_TOKEN` predefined variable.
  For example, the following job downloads the artifacts of the job with ID
  `42`. The command is wrapped in single quotes because it contains a
  colon (`:`):

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip --header "JOB-TOKEN: $CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/1/jobs/42/artifacts"'
  ```

## Download job artifacts by reference name

Download a job's artifacts archive in the latest successful
pipeline using the reference name.

The latest successful pipeline is determined based on creation time.
The start or end time of individual jobs does not affect which pipeline is the latest.

For [parent and child pipelines](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines),
artifacts are searched in hierarchical order from parent to child. If both parent and child pipelines
have a job with the same name, the artifact from the parent pipeline is returned.

Prerequisites:

- You must have a completed pipeline with a `success` status.
- If the pipeline includes manual jobs, they must either:
  - Complete successfully.
  - Have `allow_failure: true` set.

If you use cURL to download artifacts from GitLab.com, use the `--location` parameter
as the request might redirect through a CDN.

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/download?job=name
```

Supported attributes:

| Attribute   | Type           | Required | Description |
| ----------- | -------------- | -------- | ----------- |
| `id`        | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `job`       | string         | Yes      | The name of the job. |
| `ref_name`  | string         | Yes      | Branch or tag name in repository. HEAD or SHA references are not supported. For merge request pipelines, use `ref/merge-requests/:iid/head` instead of the branch name. |
| `job_token` | string         | No       | To be used with [triggers](../ci/jobs/job_artifacts.md#with-a-cicd-job-token) for multi-project pipelines. It should be invoked only in a CI/CD job defined in the `.gitlab-ci.yml` file. The value is always `$CI_JOB_TOKEN`. The job associated with the `$CI_JOB_TOKEN` must be running when this token is used. Premium and Ultimate only. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and serves the artifacts file.

Example request using the `PRIVATE-TOKEN` header:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/download?job=test"
```

In the Premium and Ultimate tier you can authenticate with this endpoint
in a CI/CD job by using a [CI/CD job token](../ci/jobs/ci_job_token.md).

Use either:

- The `job_token` attribute with the GitLab-provided `CI_JOB_TOKEN` predefined variable.
  For example, the following job downloads the artifacts of the `test` job
  of the `main` branch:

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/main/download?job=test&job_token=$CI_JOB_TOKEN"'
  ```

- The `JOB-TOKEN` header with the GitLab-provided `CI_JOB_TOKEN` predefined variable.
  For example, the following job downloads the artifacts of the `test` job
  of the `main` branch. The command is wrapped in single quotes
  because it contains a colon (`:`):

  ```yaml
  artifact_download:
    stage: test
    script:
      - 'curl --location --output artifacts.zip --header "JOB-TOKEN: $CI_JOB_TOKEN" "https://gitlab.example.com/api/v4/projects/$CI_PROJECT_ID/jobs/artifacts/main/download?job=test"'
  ```

## Download a single artifact file by job ID

Download a single file from a job's artifacts using the job ID.
The file is extracted from the archive and streamed to the client.

If you use cURL to download artifacts from GitLab.com, use the `--location` parameter
as the request might redirect through a CDN.

```plaintext
GET /projects/:id/jobs/:job_id/artifacts/*artifact_path
```

Supported attributes:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `artifact_path` | string         | Yes      | Path to a file inside the artifacts archive. |
| `id`            | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `job_id`        | integer        | Yes      | The unique job identifier. |
| `job_token`     | string         | No       | To be used with [triggers](../ci/jobs/job_artifacts.md#with-a-cicd-job-token) for multi-project pipelines. It should be invoked only in a CI/CD job defined in the `.gitlab-ci.yml` file. The value is always `$CI_JOB_TOKEN`. The job associated with the `$CI_JOB_TOKEN` must be running when this token is used. Premium and Ultimate only. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and sends a single artifact file.

Example request:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/5/artifacts/some/release/file.pdf"
```

In the Premium and Ultimate tier you can authenticate with this endpoint
in a CI/CD job by using a [CI/CD job token](../ci/jobs/ci_job_token.md).

## Download a single artifact file by reference name

Download a single file from a job's artifacts in the latest successful pipeline
using the reference name. The file is extracted from the archive and streamed to the client with the `plain/text` content type.

For [parent and child pipelines](../ci/pipelines/downstream_pipelines.md#parent-child-pipelines),
artifacts are searched in hierarchical order from parent to child. If both parent and child pipelines
have a job with the same name, the artifact from the parent pipeline is returned.

The artifact file provides more detail than what is available in the
[CSV export](../user/application_security/vulnerability_report/_index.md#exporting).

Prerequisites:

- You must have a completed pipeline with a `success` status.
- If the pipeline includes manual jobs, they must either:
  - Complete successfully.
  - Have `allow_failure: true` set.

If you use cURL to download artifacts from GitLab.com, use the `--location` parameter
as the request might redirect through a CDN.

```plaintext
GET /projects/:id/jobs/artifacts/:ref_name/raw/*artifact_path?job=name
```

Supported attributes:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `artifact_path` | string         | Yes      | Path to a file inside the artifacts archive. |
| `id`            | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `job`           | string         | Yes      | The name of the job. |
| `ref_name`      | string         | Yes      | Branch or tag name in repository. `HEAD` or `SHA` references are not supported. For merge request pipelines, use `ref/merge-requests/:iid/head` instead of the branch name. |
| `job_token`     | string         | No       | To be used with [triggers](../ci/jobs/job_artifacts.md#with-a-cicd-job-token) for multi-project pipelines. It should be invoked only in a CI/CD job defined in the `.gitlab-ci.yml` file. The value is always `$CI_JOB_TOKEN`. The job associated with the `$CI_JOB_TOKEN` must be running when this token is used. Premium and Ultimate only. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and sends a single artifact file.

Example request:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/main/raw/some/release/file.pdf?job=pdf"
```

In the Premium and Ultimate tier you can authenticate with this endpoint
in a CI/CD job by using a [CI/CD job token](../ci/jobs/ci_job_token.md).

## Keep job artifacts

Prevent a job's artifacts from being automatically deleted when they reach their expiration date.

```plaintext
POST /projects/:id/jobs/:job_id/artifacts/keep
```

Supported attributes:

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `job_id`  | integer        | Yes      | ID of a job. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the job details.

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
  "failure_reason": "script_failure",
  "tag": false,
  "web_url": "https://example.com/foo/bar/-/jobs/42",
  "user": null
}
```

## Delete job artifacts

Delete all artifacts associated with a specific job. Artifacts cannot be recovered after they are deleted.

Prerequisites:

- You must have at least the Maintainer role for the project.

```plaintext
DELETE /projects/:id/jobs/:job_id/artifacts
```

Supported attributes:

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `job_id`  | integer        | Yes      | ID of a job. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/jobs/1/artifacts"
```

## Delete all job artifacts in a project

Delete all job artifacts eligible for deletion in a project. Artifacts cannot be recovered after they are deleted.

By default, artifacts from [the most recent successful pipeline of each ref](../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)
are not deleted.

Requests to this endpoint set the expiry of all job artifacts that
can be deleted to the current time. The files are then deleted from the system as part
of the regular cleanup of expired job artifacts. Job logs are never deleted.

The regular cleanup occurs asynchronously on a schedule, so there might be a short delay
before artifacts are deleted.

Prerequisites:

- You must have at least the Maintainer role for the project.

```plaintext
DELETE /projects/:id/artifacts
```

Supported attributes:

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`202 Accepted`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/artifacts"
```

## Troubleshooting

### Using branch names with merge request pipelines

You might get a `404 Not Found` error when trying to download job artifacts using a branch name as the `ref_name`.

This issue occurs because merge request pipelines use a different reference format than branch pipelines.
Merge request pipelines run on `refs/merge-requests/:iid/head`, not directly on the source branch.

To download job artifacts for a merge request pipeline, use `ref/merge-requests/:iid/head`
as the `ref_name` instead of the branch name, where `:iid` is the merge request ID.

For example, for merge request `!123`:

```shell
curl --location --header "PRIVATE-TOKEN: <your_access_token>" \
  "https://gitlab.example.com/api/v4/projects/1/jobs/artifacts/ref/merge-requests/123/head/raw/file.txt?job=test"
```

### Downloading `artifacts:reports` files

You might get a `404 Not Found` error when trying to download reports using the job artifacts API.

This issue occurs because [reports](../ci/yaml/_index.md#artifactsreports) are not downloadable by default.

To make reports downloadable, add their filenames or `gl-*-report.json` to [`artifacts:paths`](../ci/yaml/_index.md#artifactspaths).
