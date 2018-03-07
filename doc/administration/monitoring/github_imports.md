# Monitoring GitHub imports

>**Note:**
Available since [GitLab 10.2][14731].

The GitHub importer exposes various Prometheus metrics that you can use to
monitor the health and progress of the importer.

## Import Duration Times

| Name                                     | Type      |
|------------------------------------------|-----------|
| `github_importer_total_duration_seconds` | histogram |

This metric tracks the total time spent (in seconds) importing a project (from
project creation until the import process finishes), for every imported project.

The name of the project is stored in the `project` label in the format
`namespace/name` (e.g. `gitlab-org/gitlab-ce`).

## Number of imported projects

| Name                                | Type    |
|-------------------------------------|---------|
| `github_importer_imported_projects` | counter |

This metric tracks the total number of projects imported over time. This metric
does not expose any labels.

## Number of GitHub API calls

| Name                            | Type    |
|---------------------------------|---------|
| `github_importer_request_count` | counter |

This metric tracks the total number of GitHub API calls performed over time, for
all projects. This metric does not expose any labels.

## Rate limit errors

| Name                              | Type    |
|-----------------------------------|---------|
| `github_importer_rate_limit_hits` | counter |

This metric tracks the number of times we hit the GitHub rate limit, for all
projects. This metric does not expose any labels.

## Number of imported issues

| Name                              | Type    |
|-----------------------------------|---------|
| `github_importer_imported_issues` | counter |

This metric tracks the number of imported issues across all projects.

The name of the project is stored in the `project` label in the format
`namespace/name` (e.g. `gitlab-org/gitlab-ce`).

## Number of imported pull requests

| Name                                     | Type    |
|------------------------------------------|---------|
| `github_importer_imported_pull_requests` | counter |

This metric tracks the number of imported pull requests across all projects.

The name of the project is stored in the `project` label in the format
`namespace/name` (e.g. `gitlab-org/gitlab-ce`).

## Number of imported comments

| Name                             | Type    |
|----------------------------------|---------|
| `github_importer_imported_notes` | counter |

This metric tracks the number of imported comments across all projects.

The name of the project is stored in the `project` label in the format
`namespace/name` (e.g. `gitlab-org/gitlab-ce`).

## Number of imported pull request review comments

| Name                                  | Type    |
|---------------------------------------|---------|
| `github_importer_imported_diff_notes` | counter |

This metric tracks the number of imported comments across all projects.

The name of the project is stored in the `project` label in the format
`namespace/name` (e.g. `gitlab-org/gitlab-ce`).

## Number of imported repositories

| Name                                    | Type    |
|-----------------------------------------|---------|
| `github_importer_imported_repositories` | counter |

This metric tracks the number of imported repositories across all projects. This
metric does not expose any labels.

[14731]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/14731
