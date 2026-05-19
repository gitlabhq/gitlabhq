---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Projects
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Field `avatarUrl` [added](https://gitlab.com/gitlab-org/glql/-/merge_requests/361) in GitLab 18.11.

{{< /history >}}

## Allowed scopes

| Scope       | Description                                                                              |
| ----------- | ---------------------------------------------------------------------------------------- |
| `namespace` | Query projects in a specific namespace. You can use `group` as an alias for `namespace`. |

For more information, see [scopes](_index.md#scopes).

## Query fields

| Field                                                    | Name (and alias)       | Operators  |
| -------------------------------------------------------- | ---------------------- | ---------- |
| [Archived only](#project-archived-only)                  | `archivedOnly`         | `=`, `!=`  |
| [Has code coverage](#project-has-code-coverage)          | `hasCodeCoverage`      | `=`, `!=`  |
| [Has vulnerabilities](#project-has-vulnerabilities)      | `hasVulnerabilities`   | `=`, `!=`  |
| [Include archived](#project-include-archived)            | `includeArchived`      | `=`, `!=`  |
| [Include subgroups](#project-include-subgroups)          | `includeSubgroups`     | `=`, `!=`  |
| [Issues enabled](#project-issues-enabled)                | `issuesEnabled`        | `=`, `!=`  |
| [Merge requests enabled](#project-merge-requests-enabled)| `mergeRequestsEnabled` | `=`, `!=`  |

### Archived only {#project-archived-only}

**Description**: Filter to show only archived projects.

**Allowed value types**: `Boolean` (either `true` or `false`)

**Notes**:

- Cannot be used together with `includeArchived`.

### Has code coverage {#project-has-code-coverage}

**Description**: Filter projects by whether they have code coverage reports.

**Allowed value types**: `Boolean` (either `true` or `false`)

### Has vulnerabilities {#project-has-vulnerabilities}

**Description**: Filter projects by whether they have security vulnerabilities.

**Allowed value types**: `Boolean` (either `true` or `false`)

### Include archived {#project-include-archived}

**Description**: Include archived projects in the results.

**Allowed value types**: `Boolean` (either `true` or `false`)

**Notes**:

- Cannot be used together with `archivedOnly`.
- By default, archived projects are not included.

### Include subgroups {#project-include-subgroups}

**Description**: Whether to include projects from subgroups.

**Allowed value types**: `Boolean` (either `true` or `false`)

**Notes**:

- This field can only be used with a `namespace` scope.
- Defaults to `true` when a `namespace` scope is specified.

### Issues enabled {#project-issues-enabled}

**Description**: Filter projects by whether they have issues enabled.

**Allowed value types**: `Boolean` (either `true` or `false`)

### Merge requests enabled {#project-merge-requests-enabled}

**Description**: Filter projects by whether they have merge requests enabled.

**Allowed value types**: `Boolean` (either `true` or `false`)

## Display fields

| Field                            | Name (and alias)                 | Description |
| -------------------------------- | -------------------------------- | ----------- |
| Archived                         | `archived`                       | Display whether the project is archived |
| Avatar URL                       | `avatarUrl`                      | Display the URL of the project avatar |
| Duo features enabled             | `duoFeaturesEnabled`             | Display whether Duo features are enabled |
| Forked                           | `forked`                         | Display whether the project is a fork |
| Forks count                      | `forksCount`                     | Display the number of forks |
| Full path                        | `fullPath`                       | Display the full path of the project |
| Group                            | `group`                          | Display the group the project belongs to |
| ID                               | `id`                             | Display the project ID |
| Issues enabled                   | `issuesEnabled`                  | Display whether issues are enabled |
| Last activity                    | `lastActivity`, `lastActivityAt` | Display when the project was last active |
| Merge requests enabled           | `mergeRequestsEnabled`           | Display whether merge requests are enabled |
| Name                             | `name`                           | Display the project name |
| Open issues count                | `openIssuesCount`                | Display the number of open issues |
| Open merge requests count        | `openMergeRequestsCount`         | Display the number of open merge requests |
| Path                             | `path`                           | Display the project path |
| Secret push protection enabled   | `secretPushProtectionEnabled`    | Display whether secret push protection is enabled |
| Star count                       | `starCount`                      | Display the number of stars |
| Visibility                       | `visibility`                     | Display the project visibility level |
| Web URL                          | `webUrl`                         | Display the web URL of the project |

## Sort fields

| Field         | Name (and alias)                 | Description                    |
| ------------- | -------------------------------- | ------------------------------ |
| Full path     | `fullPath`                       | Sort by full path              |
| Last activity | `lastActivity`, `lastActivityAt` | Sort by last activity date     |
| Path          | `path`                           | Sort by path                   |

**Notes**:

- `lastActivity` only supports descending (`desc`) sort order.

## Examples

- List all projects in the `gitlab-org` group sorted by path:

  ````yaml
  ```glql
  display: table
  fields: name, fullPath, starCount, openIssuesCount
  sort: path asc
  query: type = Project and group = "gitlab-org"
  ```
  ````

- List all projects in the `gitlab-org` group sorted by most recently active:

  ````yaml
  ```glql
  display: table
  fields: name, fullPath, lastActivity
  sort: lastActivity desc
  query: type = Project and group = "gitlab-org"
  ```
  ````
