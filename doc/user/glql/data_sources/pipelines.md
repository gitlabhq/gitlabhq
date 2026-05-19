---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Pipelines
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228521) in GitLab 18.11.
- Fields `commit`, `commitPath`, `refPath`, `stages`, and `user` [added](https://gitlab.com/gitlab-org/glql/-/merge_requests/361) in GitLab 18.11.

{{< /history >}}

> [!note]
> Pipelines do not support sorting.

## Allowed scopes

| Scope     | Description                              |
| --------- | ---------------------------------------- |
| `project` | Query pipelines in a specific project.   |

For more information, see [scopes](_index.md#scopes).

## Query fields

| Field                                          | Name (and alias)                             | Operators                  |
| ---------------------------------------------- | -------------------------------------------- | -------------------------- |
| [Author](#pipeline-author)                     | `author`                                     | `=`                        |
| [Ref](#pipeline-ref)                           | `ref`                                        | `=`                        |
| [Scope](#pipeline-scope)                       | `scope`                                      | `=`                        |
| [SHA](#pipeline-sha)                           | `sha`                                        | `=`                        |
| [Source](#pipeline-source)                     | `source`                                     | `=`                        |
| [Status](#pipeline-status)                     | `status`                                     | `=`                        |
| [Updated at](#pipeline-updated-at)             | `updated`, `updatedAt`                       | `=`, `>`, `<`, `>=`, `<=`  |

### Author {#pipeline-author}

**Description**: Filter pipelines by the user who triggered them.

**Allowed value types**:

- `String`
- `User` (for example, `@username`)

### Ref {#pipeline-ref}

**Description**: Filter pipelines by the Git ref (branch or tag name) they ran on.

**Allowed value types**: `String`

### Scope {#pipeline-scope}

**Description**: Filter pipelines by their scope.

**Allowed value types**:

- `Enum`, one of `branches`, `tags`, `finished`, `pending`, or `running`

### SHA {#pipeline-sha}

**Description**: Filter pipelines by the commit SHA.

**Allowed value types**: `String`

### Source {#pipeline-source}

**Description**: Filter pipelines by what triggered them.

**Allowed value types**: `String`

### Status {#pipeline-status}

**Description**: Filter pipelines by their CI/CD status.

**Allowed value types**:

- `Enum`, one of `canceled`, `canceling`, `created`, `failed`, `manual`, `pending`,
  `preparing`, `running`, `scheduled`, `skipped`, `success`, `waiting_for_callback`,
  or `waiting_for_resource`

### Updated at {#pipeline-updated-at}

**Description**: Filter pipelines by when they were last updated.

**Allowed value types**:

- `AbsoluteDate` (in the format `YYYY-MM-DD`)
- `RelativeDate` (in the format `<sign><digit><unit>`, where sign is `+`, `-`, or omitted,
  digit is an integer, and `unit` is one of `d` (days), `w` (weeks), `m` (months) or `y` (years))

**Notes**:

- For the `=` operator, the time range is considered from 00:00 to 23:59 in the user's time zone.
- `>=` and `<=` operators are inclusive of the dates being queried, whereas `>` and `<` are not.

## Display fields

| Field              | Name (and alias)                   | Description |
| ------------------ | ---------------------------------- | ----------- |
| Active             | `active`                           | Display whether the pipeline is active |
| Cancelable         | `cancelable`                       | Display whether the pipeline can be canceled |
| Child              | `child`                            | Display whether this is a child pipeline |
| Commit             | `commit`                           | Display commit details (ID, short ID, title, author name, web URL) |
| Commit path        | `commitPath`                       | Display the path to the commit that triggered the pipeline |
| Committed at       | `committed`, `committedAt`         | Display the commit timestamp |
| Complete           | `complete`                         | Display whether the pipeline is complete |
| Compute minutes    | `computeMinutes`                   | Display the compute minutes used |
| Config source      | `configSource`                     | Display the pipeline configuration source |
| Coverage           | `coverage`                         | Display code coverage percentage |
| Created at         | `created`, `createdAt`             | Display when the pipeline was created |
| Duration           | `duration`                         | Display the pipeline duration |
| Failed jobs count  | `failedJobsCount`                  | Display the number of failed jobs |
| Failure reason     | `failureReason`                    | Display the reason for pipeline failure |
| Finished at        | `finished`, `finishedAt`           | Display when the pipeline finished |
| ID                 | `id`                               | Display the pipeline ID |
| IID                | `iid`                              | Display the pipeline internal ID |
| Latest             | `latest`                           | Display whether this is the latest pipeline for the ref |
| Name               | `name`                             | Display the pipeline name |
| Path               | `path`                             | Display the pipeline path |
| Ref                | `ref`                              | Display the Git ref (branch or tag) |
| Ref path           | `refPath`                          | Display the path to the ref that triggered the pipeline |
| Retryable          | `retryable`                        | Display whether the pipeline can be retried |
| SHA                | `sha`                              | Display the commit SHA |
| Source             | `source`                           | Display what triggered the pipeline |
| Stages             | `stages`                           | Display pipeline stages (name and status) |
| Started at         | `started`, `startedAt`             | Display when the pipeline started |
| Status             | `status`                           | Display the pipeline status |
| Stuck              | `stuck`                            | Display whether the pipeline is stuck |
| Total jobs         | `totalJobs`                        | Display the total number of jobs |
| Updated at         | `updated`, `updatedAt`             | Display when the pipeline was last updated |
| User               | `user`                             | Display the user who triggered the pipeline |
| Warnings           | `warnings`                         | Display pipeline warnings |
| YAML errors        | `yamlErrors`                       | Display whether the pipeline has YAML errors |
| YAML error messages| `yamlErrorMessages`                | Display YAML error messages |

## Known issues

- Queries with large date ranges can cause timeouts.

## Examples

- List all pipelines in the `gitlab-org/gitlab` project that failed today:

  ````yaml
  ```glql
  display: table
  fields: id, ref, status, startedAt
  query: type = Pipeline and project = "gitlab-org/gitlab" and status = failed and updated = today()
  ```
  ````

- List all Duo agent pipelines in the `gitlab-org/gitlab` project:

  ````yaml
  ```glql
  display: table
  fields: id, ref, status, source, startedAt
  query: type = Pipeline and project = "gitlab-org/gitlab" and source = "duo_workflow"
  ```
  ````
