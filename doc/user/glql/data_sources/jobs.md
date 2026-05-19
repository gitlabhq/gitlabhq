---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jobs
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228521) in GitLab 18.11.
- Fields `browseArtifactsPath`, `canPlayJob`, `commitPath`, `createdByTag`, `exitCode`, `pipeline`,
  `playPath`, `queuedDuration`, `refPath`, `retryPath`, and `scheduledAt`
  [added](https://gitlab.com/gitlab-org/glql/-/merge_requests/361) in GitLab 18.11.

{{< /history >}}

> [!note]
> Jobs do not support sorting.

## Allowed scopes

| Scope     | Description                           |
| --------- | ------------------------------------- |
| `project` | Query jobs in a specific project.     |

For more information, see [scopes](_index.md#scopes).

## Query fields

| Field                                          | Name                | Operators  |
| ---------------------------------------------- | ------------------- | ---------- |
| [Kind](#job-kind)                              | `kind`              | `=`        |
| [Pipeline](#job-pipeline)                      | `pipeline`          | `=`        |
| [Status](#job-status)                          | `status`            | `=`        |
| [With artifacts](#job-with-artifacts)          | `withArtifacts`     | `=`, `!=`  |

### Kind {#job-kind}

**Description**: Filter jobs by their kind.

**Allowed value types**:

- `Enum`, one of `bridge` or `build`

**Notes**:

- `bridge` jobs are trigger jobs that start downstream pipelines.
- `build` jobs are regular CI/CD jobs.

### Pipeline {#job-pipeline}

**Description**: Filter jobs by the pipeline they belong to, using the pipeline IID.

**Allowed value types**: `Number` (pipeline IID)

### Status {#job-status}

**Description**: Filter jobs by their CI/CD status.

**Allowed value types**:

- `Enum`, one of `canceled`, `canceling`, `created`, `failed`, `manual`, `pending`,
  `preparing`, `running`, `scheduled`, `skipped`, `success`, `waiting_for_callback`,
  or `waiting_for_resource`

### With artifacts {#job-with-artifacts}

**Description**: Filter jobs by whether they have artifacts.

**Allowed value types**: `Boolean` (either `true` or `false`)

## Display fields

| Field                  | Name (and alias)                   | Description |
| ---------------------- | ---------------------------------- | ----------- |
| Active                 | `active`                           | Display whether the job is active |
| Allow failure          | `allowFailure`                     | Display whether the job is allowed to fail |
| Browse artifacts path  | `browseArtifactsPath`              | Display the URL for browsing the job's artifact archive |
| Can play job           | `canPlayJob`                       | Display whether the current user can play the job |
| Cancelable             | `cancelable`                       | Display whether the job can be canceled |
| Commit path            | `commitPath`                       | Display the path to the commit that triggered the job |
| Coverage               | `coverage`                         | Display code coverage percentage |
| Created at             | `created`, `createdAt`             | Display when the job was created |
| Created by tag         | `createdByTag`                     | Display whether the job was created by a tag |
| Duration               | `duration`                         | Display the job duration |
| Erased at              | `erased`, `erasedAt`               | Display when job artifacts were erased |
| Exit code              | `exitCode`                         | Display the exit code of the job |
| Failure message        | `failureMessage`                   | Display the failure message |
| Finished at            | `finished`, `finishedAt`           | Display when the job finished |
| ID                     | `id`                               | Display the job ID |
| Kind                   | `kind`                             | Display the job kind (`bridge` or `build`) |
| Manual job             | `manualJob`                        | Display whether this is a manual job |
| Name                   | `name`                             | Display the job name |
| Pipeline               | `pipeline`                         | Display the pipeline the job belongs to |
| Play path              | `playPath`                         | Display the path to play the job |
| Playable               | `playable`                         | Display whether the job can be played |
| Queued at              | `queued`, `queuedAt`               | Display when the job was queued |
| Queued duration        | `queuedDuration`                   | Display how long the job was queued before starting |
| Ref name               | `refName`                          | Display the Git ref name |
| Ref path               | `refPath`                          | Display the path to the ref that triggered the job |
| Retried                | `retried`                          | Display whether the job was retried |
| Retry path             | `retryPath`                        | Display the path to retry the job |
| Retryable              | `retryable`                        | Display whether the job can be retried |
| Scheduled              | `scheduled`                        | Display whether the job is scheduled |
| Scheduled at           | `scheduledAt`                      | Display when the job was scheduled to run |
| Scheduling type        | `schedulingType`                   | Display the scheduling type |
| Short SHA              | `shortSha`                         | Display the short commit SHA |
| Source                 | `source`                           | Display the job source |
| Stage                  | `stage`                            | Display the pipeline stage the job belongs to |
| Started at             | `started`, `startedAt`             | Display when the job started |
| Status                 | `status`                           | Display the job status |
| Stuck                  | `stuck`                            | Display whether the job is stuck |
| Tags                   | `tags`                             | Display the runner tags |
| Triggered              | `triggered`                        | Display whether the job was triggered |
| Web path               | `webPath`                          | Display the web path to the job |

## Examples

- List all failed jobs in the `gitlab-org/gitlab` project:

  ````yaml
  ```glql
  display: table
  fields: name, status, stage, startedAt
  query: type = Job and project = "gitlab-org/gitlab" and status = failed
  ```
  ````

- List all jobs with artifacts in the `gitlab-org/gitlab` project:

  ````yaml
  ```glql
  display: table
  fields: name, status, stage
  query: type = Job and project = "gitlab-org/gitlab" and withArtifacts = true
  ```
  ````
