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

{{< /history >}}

> [!note]
> Jobs do not support sorting.

## Query fields

The following fields are required: [Project](#job-project)

| Field                                          | Name                | Operators  |
| ---------------------------------------------- | ------------------- | ---------- |
| [Kind](#job-kind)                              | `kind`              | `=`        |
| [Pipeline](#job-pipeline)                      | `pipeline`          | `=`        |
| [Project](#job-project)                        | `project`           | `=`        |
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

### Project {#job-project}

**Description**: Specify the project to query jobs from. This field is **required**.

**Allowed value types**: `String`

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

| Field              | Name (and alias)                   | Description |
| ------------------ | ---------------------------------- | ----------- |
| Active             | `active`                           | Display whether the job is active |
| Allow failure      | `allowFailure`                     | Display whether the job is allowed to fail |
| Cancelable         | `cancelable`                       | Display whether the job can be canceled |
| Coverage           | `coverage`                         | Display code coverage percentage |
| Created at         | `created`, `createdAt`             | Display when the job was created |
| Duration           | `duration`                         | Display the job duration |
| Erased at          | `erased`, `erasedAt`               | Display when job artifacts were erased |
| Failure message    | `failureMessage`                   | Display the failure message |
| Finished at        | `finished`, `finishedAt`           | Display when the job finished |
| ID                 | `id`                               | Display the job ID |
| Kind               | `kind`                             | Display the job kind (`bridge` or `build`) |
| Manual job         | `manualJob`                        | Display whether this is a manual job |
| Name               | `name`                             | Display the job name |
| Playable           | `playable`                         | Display whether the job can be played |
| Queued at          | `queued`, `queuedAt`               | Display when the job was queued |
| Ref name           | `refName`                          | Display the Git ref name |
| Retried            | `retried`                          | Display whether the job was retried |
| Retryable          | `retryable`                        | Display whether the job can be retried |
| Scheduled          | `scheduled`                        | Display whether the job is scheduled |
| Scheduling type    | `schedulingType`                   | Display the scheduling type |
| Short SHA          | `shortSha`                         | Display the short commit SHA |
| Source             | `source`                           | Display the job source |
| Stage              | `stage`                            | Display the pipeline stage the job belongs to |
| Started at         | `started`, `startedAt`             | Display when the job started |
| Status             | `status`                           | Display the job status |
| Stuck              | `stuck`                            | Display whether the job is stuck |
| Tags               | `tags`                             | Display the runner tags |
| Triggered          | `triggered`                        | Display whether the job was triggered |
| Web path           | `webPath`                          | Display the web path to the job |
| With artifacts     | `withArtifacts`                    | Display whether the job has artifacts |
