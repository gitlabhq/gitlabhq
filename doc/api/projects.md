---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Projects API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Interact with [projects](../user/project/index.md) by using the REST API.

NOTE:
Users with any [default role](../user/permissions.md#roles) can read project properties with the Projects API. Only users with the Owner or Maintainer role can edit project properties in the UI or with the API.

## Project visibility level

A project in GitLab can be private, internal, or public.
The visibility level is determined by the `visibility` field in the project.

For details, see [Project visibility](../user/public_access.md).

The fields returned in responses vary based on the [permissions](../user/permissions.md) of the authenticated user.

## Removals in API v5

These attributes are deprecated, and are scheduled to be removed in v5 of the API:

- `tag_list`: Use the `topics` attribute instead.
- `marked_for_deletion_at`: Use the `marked_for_deletion_on` attribute instead.
  Available only to [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/).
- `approvals_before_merge`: Use the [Merge request approvals API](merge_request_approvals.md) instead.
  Available only to [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/).

## Project merge method

The `merge_method` can use these options:

- `merge`: a merge commit is created for every merge, and merging is allowed if
  no conflicts are present.
- `rebase_merge`: a merge commit is created for every merge, but merging is only
  allowed if fast-forward merge is possible. You can make sure that the target
  branch would build after this merge request builds and merges.
- `ff`: no merge commits are created and all merges are fast-forwarded. Merging
  is only allowed if the branch could be fast-forwarded.

## List all projects

> - The `_links.cluster_agents` attribute in the response was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 15.0.

Get a list of all visible projects across GitLab for the authenticated user.
When accessed without authentication, only public projects with _simple_ fields
are returned.

```plaintext
GET /projects
```

| Attribute                                      | Type     | Required | Description |
|------------------------------------------------|----------|----------|-------------|
| `archived`                                     | boolean  | No       | Limit by archived status. |
| `id_after`                                     | integer  | No       | Limit results to projects with IDs greater than the specified ID. |
| `id_before`                                    | integer  | No       | Limit results to projects with IDs less than the specified ID. |
| `imported`                                     | boolean  | No       | Limit results to projects which were imported from external systems by current user. |
| `include_hidden`                               | boolean  | No       | Include hidden projects. _(administrators only)_ Premium and Ultimate only. |
| `include_pending_delete`                       | boolean  | No       | Include projects pending deletion. _(administrators only)_ |
| `last_activity_after`                          | datetime | No       | Limit results to projects with last activity after specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `last_activity_before`                         | datetime | No       | Limit results to projects with last activity before specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `membership`                                   | boolean  | No       | Limit by projects that the current user is a member of. |
| `min_access_level`                             | integer  | No       | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `order_by`                                     | string   | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `last_activity_at`, or `similarity` fields. `repository_size`, `storage_size`, `packages_size` or `wiki_size` fields are only allowed for administrators. `similarity` is only available when searching and is limited to projects that the current user is a member of. Default is `created_at`. |
| `owned`                                        | boolean  | No       | Limit by projects explicitly owned by the current user. |
| `repository_checksum_failed`                   | boolean  | No       | Limit projects where the repository checksum calculation has failed. Premium and Ultimate only. |
| `repository_storage`                           | string   | No       | Limit results to projects stored on `repository_storage`. _(administrators only)_ |
| `search_namespaces`                            | boolean  | No       | Include ancestor namespaces when matching search criteria. Default is `false`. |
| `search`                                       | string   | No       | Return list of projects matching the search criteria. |
| `simple`                                       | boolean  | No       | Return only limited fields for each project. This operation is a no-op without authentication where only simple fields are returned. |
| `sort`                                         | string   | No       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                                      | boolean  | No       | Limit by projects starred by the current user. |
| `statistics`                                   | boolean  | No       | Include project statistics. Available only to users with at least the Reporter role. |
| `topic_id`                                     | integer  | No       | Limit results to projects with the assigned topic given by the topic ID. |
| `topic`                                        | string   | No       | Comma-separated topic names. Limit results to projects that match all of given topics. See `topics` attribute. |
| `updated_after`                                | datetime | No       | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. For this filter to work, you must also provide `updated_at` as the `order_by` attribute. |
| `updated_before`                               | datetime | No       | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. For this filter to work, you must also provide `updated_at` as the `order_by` attribute. |
| `visibility`                                   | string   | No       | Limit by visibility `public`, `internal`, or `private`. |
| `wiki_checksum_failed`                         | boolean  | No       | Limit projects where the wiki checksum calculation has failed. Premium and Ultimate only. |
| `with_custom_attributes`                       | boolean  | No       | Include [custom attributes](custom_attributes.md) in response. _(administrator only)_ |
| `with_issues_enabled`                          | boolean  | No       | Limit by enabled issues feature. |
| `with_merge_requests_enabled`                  | boolean  | No       | Limit by enabled merge requests feature. |
| `with_programming_language`                    | string   | No       | Limit by projects which use the given programming language. |
| `marked_for_deletion_on`                       | date     | No       | Filter by date when project was marked for deletion. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463939) in GitLab 17.1. Premium and Ultimate only. |

This endpoint supports [keyset pagination](rest/index.md#keyset-based-pagination)
for selected `order_by` options.

When `simple=true` or the user is unauthenticated this returns something like:

Example request:

```shell
curl --request GET "https://gitlab.example.com/api/v4/projects"
```

Example response:

```json
[
  {
    "id": 4,
    "description": null,
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "star_count": 0,
    "last_activity_at": "2013-09-30T13:46:02Z",
    "namespace": {
      "id": 2,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/diaspora"
    }
  },
  {
    ...
  }
```

When the user is authenticated and `simple` is not set this returns something like:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "readme_url": "https://gitlab.example.com/diaspora/diaspora-client/blob/main/README.md",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "forks_count": 0,
    "star_count": 0,
    "last_activity_at": "2022-06-24T17:11:26.841Z",
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": "https://gitlab.example.com/uploads/project/avatar/6/uploads/avatar.png",
      "web_url": "https://gitlab.example.com/diaspora"
    },
    "container_registry_image_prefix": "registry.gitlab.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "https://gitlab.example.com/api/v4/projects/4",
      "issues": "https://gitlab.example.com/api/v4/projects/4/issues",
      "merge_requests": "https://gitlab.example.com/api/v4/projects/4/merge_requests",
      "repo_branches": "https://gitlab.example.com/api/v4/projects/4/repository/branches",
      "labels": "https://gitlab.example.com/api/v4/projects/4/labels",
      "events": "https://gitlab.example.com/api/v4/projects/4/events",
      "members": "https://gitlab.example.com/api/v4/projects/4/members",
      "cluster_agents": "https://gitlab.example.com/api/v4/projects/4/cluster_agents"
    },
    "packages_enabled": true,
    "empty_repo": false,
    "archived": false,
    "visibility": "public",
    "resolve_outdated_diff_discussions": false,
    "container_expiration_policy": {
      "cadence": "1month",
      "enabled": true,
      "keep_n": 1,
      "older_than": "14d",
      "name_regex": "",
      "name_regex_keep": ".*-main",
      "next_run_at": "2022-06-25T17:11:26.865Z"
    },
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "jobs_enabled": true,
    "snippets_enabled": true,
    "container_registry_enabled": true,
    "service_desk_enabled": true,
    "can_create_merge_request_in": true,
    "issues_access_level": "enabled",
    "repository_access_level": "enabled",
    "merge_requests_access_level": "enabled",
    "forking_access_level": "enabled",
    "wiki_access_level": "enabled",
    "builds_access_level": "enabled",
    "snippets_access_level": "enabled",
    "pages_access_level": "enabled",
    "analytics_access_level": "enabled",
    "container_registry_access_level": "enabled",
    "security_and_compliance_access_level": "private",
    "emails_disabled": null,
    "emails_enabled": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "lfs_enabled": true,
    "creator_id": 1,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "open_issues_count": 0,
    "ci_default_git_depth": 20,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_job_token_scope_enabled": false,
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "public_jobs": true,
    "build_timeout": 3600,
    "auto_cancel_pending_pipelines": "enabled",
    "ci_config_path": "",
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": null,
    "restrict_user_defined_variables": false,
    "request_access_enabled": true,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": true,
    "printing_merge_request_link_enabled": true,
    "merge_method": "merge",
    "squash_option": "default_off",
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "auto_devops_enabled": false,
    "auto_devops_deploy_strategy": "continuous",
    "autoclose_referenced_issues": true,
    "keep_latest_artifact": true,
    "runner_token_expiration_interval": null,
    "external_authorization_classification_label": "",
    "requirements_enabled": false,
    "requirements_access_level": "enabled",
    "security_and_compliance_enabled": false,
    "compliance_frameworks": [],
    "warn_about_potentially_unwanted_characters": true,
    "permissions": {
      "project_access": null,
      "group_access": null
    }
  },
  {
    ...
  }
]
```

NOTE:
`last_activity_at` is updated based on [project activity](../user/project/working_with_projects.md#view-project-activity) and [project events](events.md). `updated_at` is updated whenever the project record is changed in the database.

You can filter by [custom attributes](custom_attributes.md) with:

```plaintext
GET /projects?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

Example request:

```shell
curl --globoff --request GET "https://gitlab.example.com/api/v4/projects?custom_attributes[location]=Antarctica&custom_attributes[role]=Developer"
```

### Pagination limits

[Offset-based pagination](rest/index.md#offset-based-pagination)
is [limited to 50,000 records](https://gitlab.com/gitlab-org/gitlab/-/issues/34565).
[Keyset pagination](rest/index.md#keyset-based-pagination) is required to retrieve
projects beyond this limit.

Keyset pagination supports only `order_by=id`. Other sorting options aren't available.

## List user projects

Get a list of visible projects owned by the given user. When accessed without
authentication, only public projects are returned.

Prerequisites:

- To view [certain attributes](https://gitlab.com/gitlab-org/gitlab/-/blob/520776fa8e5a11b8275b7c597d75246fcfc74c89/lib/api/entities/project.rb#L109-130), you must be an administrator or have the Owner role for the project.

NOTE:
Only the projects in the user's (specified in `user_id`) namespace are returned. Projects owned by the user in any group or subgroups are not returned. An empty list is returned if a profile is set to private.

This endpoint supports [keyset pagination](rest/index.md#keyset-based-pagination)
for selected `order_by` options.

```plaintext
GET /users/:user_id/projects
```

| Attribute                     | Type     | Required | Description |
|-------------------------------|----------|----------|-------------|
| `user_id`                     | string   | Yes      | The ID or username of the user. |
| `archived`                    | boolean  | No       | Limit by archived status. |
| `id_after`                    | integer  | No       | Limit results to projects with IDs greater than the specified ID. |
| `id_before`                   | integer  | No       | Limit results to projects with IDs less than the specified ID. |
| `membership`                  | boolean  | No       | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer  | No       | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `order_by`                    | string   | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `owned`                       | boolean  | No       | Limit by projects explicitly owned by the current user. |
| `search`                      | string   | No       | Return list of projects matching the search criteria. |
| `simple`                      | boolean  | No       | Return only limited fields for each project. Without authentication, this operation is a no-op; only simple fields are returned. |
| `sort`                        | string   | No       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean  | No       | Limit by projects starred by the current user. |
| `statistics`                  | boolean  | No       | Include project statistics. Available only to users with at least the Reporter role. |
| `updated_after`               | datetime | No       | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |
| `updated_before`              | datetime | No       | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |
| `visibility`                  | string   | No       | Limit by visibility `public`, `internal`, or `private`. |
| `with_custom_attributes`      | boolean  | No       | Include [custom attributes](custom_attributes.md) in response. _(administrator only)_ |
| `with_issues_enabled`         | boolean  | No       | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean  | No       | Limit by enabled merge requests feature. |
| `with_programming_language`   | string   | No       | Limit by projects which use the given programming language. |

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 50,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "marked_for_deletion_at": "2020-04-03", // Deprecated and will be removed in API v5 in favor of marked_for_deletion_on
    "marked_for_deletion_on": "2020-04-03",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 0,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_separated_caches": true,
    "ci_restrict_pipeline_cancellation_role": "developer",
    "ci_pipeline_variables_minimum_override_role": "maintainer",
    "ci_push_repository_for_job_token_allowed": false,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true,
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## List projects a user has contributed to

Get a list of visible projects a given user has contributed to.

```plaintext
GET /users/:user_id/contributed_projects
```

| Attribute  | Type    | Required | Description |
|------------|---------|----------|-------------|
| `user_id`  | string  | Yes      | The ID or username of the user. |
| `order_by` | string  | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `simple`   | boolean | No       | Return only limited fields for each project. Without authentication, this operation is a no-op; only simple fields are returned. |
| `sort`     | string  | No       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/5/contributed_projects"
```

Example response:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true,
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## List projects starred by a user

Get a list of visible projects starred by the given user. When accessed without
authentication, only public projects are returned.

```plaintext
GET /users/:user_id/starred_projects
```

| Attribute                     | Type     | Required | Description |
|-------------------------------|----------|----------|-------------|
| `user_id`                     | string   | Yes      | The ID or username of the user. |
| `archived`                    | boolean  | No       | Limit by archived status. |
| `membership`                  | boolean  | No       | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer  | No       | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `order_by`                    | string   | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `owned`                       | boolean  | No       | Limit by projects explicitly owned by the current user. |
| `search`                      | string   | No       | Return list of projects matching the search criteria. |
| `simple`                      | boolean  | No       | Return only limited fields for each project. Without authentication, this operation is a no-op; only simple fields are returned. |
| `sort`                        | string   | No       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean  | No       | Limit by projects starred by the current user. |
| `statistics`                  | boolean  | No       | Include project statistics. Available only to users with at least the Reporter role. |
| `updated_after`               | datetime | No       | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |
| `updated_before`              | datetime | No       | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |
| `visibility`                  | string   | No       | Limit by visibility `public`, `internal`, or `private`. |
| `with_custom_attributes`      | boolean  | No       | Include [custom attributes](custom_attributes.md) in response. _(administrator only)_ |
| `with_issues_enabled`         | boolean  | No       | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean  | No       | Limit by enabled merge requests feature. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/5/starred_projects"
```

Example response:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true,
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0,
      "container_registry_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## Get single project

Get a specific project. This endpoint can be accessed without authentication if
the project is publicly accessible.

```plaintext
GET /projects/:id
```

| Attribute                | Type              | Required | Description |
|--------------------------|-------------------|----------|-------------|
| `id`                     | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `license`                | boolean           | No       | Include project license data. |
| `statistics`             | boolean           | No       | Include project statistics. Available only to users with at least the Reporter role. |
| `with_custom_attributes` | boolean           | No       | Include [custom attributes](custom_attributes.md) in response. _(administrators only)_ |

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null, // to be deprecated in GitLab 13.0 in favor of `name_regex_delete`
    "name_regex_delete": null,
    "name_regex_keep": null,
    "next_run_at": "2020-01-07T21:42:58.658Z"
  },
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/3/foo.jpg",
    "web_url": "http://localhost:3000/groups/diaspora"
  },
  "import_url": null,
  "import_type": null,
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "public_jobs": true,
  "shared_with_groups": [
    {
      "group_id": 4,
      "group_name": "Twitter",
      "group_full_path": "twitter",
      "group_access_level": 30
    },
    {
      "group_id": 3,
      "group_name": "Gitlab Org",
      "group_full_path": "gitlab-org",
      "group_access_level": 10
    }
  ],
  "repository_storage": "default",
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "printing_merge_requests_link_enabled": true,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "mirror_user_id": 45,
  "mirror_trigger_builds": false,
  "only_mirror_protected_branches": false,
  "mirror_overwrites_diverged_branches": false,
  "external_authorization_classification_label": null,
  "packages_enabled": true,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "autoclose_referenced_issues": true,
  "suggestion_commit_message": null,
  "enforce_auth_checks_on_uploads": true,
  "merge_commit_template": null,
  "squash_commit_template": null,
  "issue_branch_template": "gitlab/%{id}-%{title}",
  "marked_for_deletion_at": "2020-04-03", // Deprecated and will be removed in API v5 in favor of marked_for_deletion_on
  "marked_for_deletion_on": "2020-04-03",
  "compliance_frameworks": [ "sox" ],
  "warn_about_potentially_unwanted_characters": true,
  "statistics": {
    "commit_count": 37,
    "storage_size": 1038090,
    "repository_size": 1038090,
    "wiki_size" : 0,
    "lfs_objects_size": 0,
    "job_artifacts_size": 0,
    "pipeline_artifacts_size": 0,
    "packages_size": 0,
    "snippets_size": 0,
    "uploads_size": 0,
    "container_registry_size": 0
  },
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

Users of [GitLab Ultimate](https://about.gitlab.com/pricing/)
can also see the `only_allow_merge_if_all_status_checks_passed`
parameters using GitLab 15.5 and later:

```json
{
  "id": 1,
  "project_id": 3,
  "only_allow_merge_if_all_status_checks_passed": false,
  ...
}
```

If the project is a fork, the `forked_from_project` field appears in the response.
For this field, if the upstream project is private, a valid token for authentication must be provided.
The field `mr_default_target_self` appears as well. If this value is `false`, then all merge requests
target the upstream project by default.

```json
{
   "id":3,

   ...

   "mr_default_target_self": false,
   "forked_from_project":{
      "id":13083,
      "description":"GitLab Community Edition",
      "name":"GitLab Community Edition",
      "name_with_namespace":"GitLab.org / GitLab Community Edition",
      "path":"gitlab-foss",
      "path_with_namespace":"gitlab-org/gitlab-foss",
      "created_at":"2013-09-26T06:02:36.000Z",
      "default_branch":"main",
      "tag_list":[], //deprecated, use `topics` instead
      "topics":[],
      "ssh_url_to_repo":"git@gitlab.com:gitlab-org/gitlab-foss.git",
      "http_url_to_repo":"https://gitlab.com/gitlab-org/gitlab-foss.git",
      "web_url":"https://gitlab.com/gitlab-org/gitlab-foss",
      "avatar_url":"https://gitlab.com/uploads/-/system/project/avatar/13083/logo-extra-whitespace.png",
      "license_url": "https://gitlab.com/gitlab-org/gitlab/-/blob/main/LICENSE",
      "license": {
        "key": "mit",
        "name": "MIT License",
        "nickname": null,
        "html_url": "http://choosealicense.com/licenses/mit/",
        "source_url": "https://opensource.org/licenses/MIT"
      },
      "star_count":3812,
      "forks_count":3561,
      "last_activity_at":"2018-01-02T11:40:26.570Z",
      "namespace": {
            "id": 72,
            "name": "GitLab.org",
            "path": "gitlab-org",
            "kind": "group",
            "full_path": "gitlab-org",
            "parent_id": null
      },
      "repository_storage": "default"
   }

   ...

}
```

### Templates for issues and merge requests

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Users of [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/)
can also see the `issues_template` and `merge_requests_template` parameters for managing
[issue and merge request description templates](../user/project/description_templates.md).

```json
{
  "id": 3,
  "issues_template": null,
  "merge_requests_template": null,
  ...
}
```

## Get project users

Get the users list of a project.

```plaintext
GET /projects/:id/users
```

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `search`     | string            | No       | Search for specific users. |
| `skip_users` | integer array     | No       | Filter out users with the specified IDs. |

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

## List a project's groups

Get a list of ancestor groups for this project.

```plaintext
GET /projects/:id/groups
```

| Attribute                 | Type              | Required | Description |
|---------------------------|-------------------|----------|-------------|
| `id`                      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `search`                  | string            | No       | Search for specific groups. |
| `shared_min_access_level` | integer           | No       | Limit to shared groups with at least this [role (`access_level`)](members.md#roles). |
| `shared_visible_only`     | boolean           | No       | Limit to shared groups user has access to. |
| `skip_groups`             | array of integers | No       | Skip the group IDs passed. |
| `with_shared`             | boolean           | No       | Include projects shared with this group. Default is `false`. |

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "full_name": "Foobar Group",
    "full_path": "foo-bar"
  },
  {
    "id": 2,
    "name": "Shared Group",
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "full_name": "Shared Group",
    "full_path": "foo/shared"
  }
]
```

## List a project's shareable groups

Get a list of groups that can be shared with a project

```plaintext
GET /projects/:id/share_locations
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `search`  | string            | No       | Search for specific groups. |

```json
[
  {
    "id": 22,
    "web_url": "http://127.0.0.1:3000/groups/gitlab-org",
    "name": "Gitlab Org",
    "avatar_url": null,
    "full_name": "Gitlab Org",
    "full_path": "gitlab-org"
  },
  {
    "id": 25,
    "web_url": "http://127.0.0.1:3000/groups/gnuwget",
    "name": "Gnuwget",
    "avatar_url": null,
    "full_name": "Gnuwget",
    "full_path": "gnuwget"
  }
]
```

## Get project events

Refer to the [Events API documentation](events.md#list-a-projects-visible-events).

## Create project

> - `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.
> - `model_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) in GitLab 16.7.

Creates a new project owned by the authenticated user.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
POST /projects
```

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your-token>" \
     --header "Content-Type: application/json" --data '{
        "name": "new_project", "description": "New Project", "path": "new_project",
        "namespace_id": "42", "initialize_with_readme": "true"}' \
     --url "https://gitlab.example.com/api/v4/projects/"
```

General project attributes:

| Attribute                                          | Type    | Required                       | Description |
|----------------------------------------------------|---------|--------------------------------|-------------|
| `name`                                             | string  | Yes (if `path` isn't provided) | The name of the new project. Equals path if not provided. |
| `path`                                             | string  | Yes (if `name` isn't provided) | Repository name for new project. Generated based on name if not provided (generated as lowercase with dashes). The path must not start or end with a special character and must not contain consecutive special characters. |
| `allow_merge_on_skipped_pipeline`                  | boolean | No                             | Set whether or not merge requests can be merged with skipped jobs. |
| `approvals_before_merge`                           | integer | No                             | How many approvers should approve merge requests by default. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. Premium and Ultimate only. |
| `auto_cancel_pending_pipelines`                    | string  | No                             | Auto-cancel pending pipelines. This action toggles between an enabled state and a disabled state; it is not a boolean. |
| `auto_devops_deploy_strategy`                      | string  | No                             | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`). |
| `auto_devops_enabled`                              | boolean | No                             | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                      | boolean | No                             | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                           | mixed   | No                             | Image file for avatar of the project. |
| `build_git_strategy`                               | string  | No                             | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                    | integer | No                             | The maximum amount of time, in seconds, that a job can run. |
| `ci_config_path`                                   | string  | No                             | The path to CI configuration file. |
| `container_expiration_policy_attributes`           | hash    | No                             | Update the image cleanup policy for this project. Accepts: `cadence` (string), `keep_n` (integer), `older_than` (string), `name_regex` (string), `name_regex_delete` (string), `name_regex_keep` (string), `enabled` (boolean). See the [container registry](../user/packages/container_registry/reduce_container_registry_storage.md#use-the-cleanup-policy-api) documentation for more information on `cadence`, `keep_n` and `older_than` values. |
| `container_registry_enabled`                       | boolean | No                             | _(Deprecated)_ Enable container registry for this project. Use `container_registry_access_level` instead. |
| `default_branch`                                   | string  | No                             | The [default branch](../user/project/repository/branches/default.md) name. Requires `initialize_with_readme` to be `true`. |
| `description`                                      | string  | No                             | Short project description. |
| `emails_disabled`                                  | boolean | No                             | _(Deprecated)_ Disable email notifications. Use `emails_enabled` instead |
| `emails_enabled`                                   | boolean | No                             | Enable email notifications. |
| `external_authorization_classification_label`      | string  | No                             | The classification label for the project. Premium and Ultimate only. |
| `group_runners_enabled`                            | boolean | No                             | Enable group runners for this project. |
| `group_with_project_templates_id`                  | integer | No                             | For group-level custom templates, specifies ID of group from which all the custom project templates are sourced. Leave empty for instance-level templates. Requires `use_custom_template` to be true. Premium and Ultimate only. |
| `import_url`                                       | string  | No                             | URL to import repository from. When the URL value isn't empty, you must not set `initialize_with_readme` to `true`. Doing so might result in the [following error](https://gitlab.com/gitlab-org/gitlab/-/issues/360266): `not a git repository`. |
| `initialize_with_readme`                           | boolean | No                             | Whether to create a Git repository with just a `README.md` file. Default is `false`. When this boolean is true, you must not pass `import_url` or other attributes of this endpoint which specify alternative contents for the repository. Doing so might result in the [following error](https://gitlab.com/gitlab-org/gitlab/-/issues/360266): `not a git repository`. |
| `issues_enabled`                                   | boolean | No                             | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `jobs_enabled`                                     | boolean | No                             | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `lfs_enabled`                                      | boolean | No                             | Enable LFS. |
| `merge_method`                                     | string  | No                             | Set the [merge method](#project-merge-method) used. |
| `merge_pipelines_enabled`                          | boolean | No                             | Enable or disable merged results pipelines. |
| `merge_requests_enabled`                           | boolean | No                             | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `merge_trains_enabled`                             | boolean | No                             | Enable or disable merge trains. |
| `mirror_trigger_builds`                            | boolean | No                             | Pull mirroring triggers builds. Premium and Ultimate only. |
| `mirror`                                           | boolean | No                             | Enables pull mirroring in a project. Premium and Ultimate only. |
| `namespace_id`                                     | integer | No                             | Namespace for the new project (defaults to the current user's namespace). |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | No                             | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_all_status_checks_passed`     | boolean | No                             | Indicates that merges of merge requests should be blocked unless all status checks have passed. Defaults to false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) in GitLab 15.5 with feature flag `only_allow_merge_if_all_status_checks_passed` disabled by default. Ultimate only. |
| `only_allow_merge_if_pipeline_succeeds`            | boolean | No                             | Set whether merge requests can only be merged with successful pipelines. This setting is named [**Pipelines must succeed**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) in the project settings. |
| `packages_enabled`                                 | boolean | No                             | Enable or disable packages repository feature. |
| `printing_merge_request_link_enabled`              | boolean | No                             | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                    | boolean | No                             | _(Deprecated)_ If `true`, jobs can be viewed by non-project members. Use `public_jobs` instead. |
| `public_jobs`                                      | boolean | No                             | If `true`, jobs can be viewed by non-project members. |
| `repository_object_format`                         | string  | No                             | Repository object format. Defaults to `sha1`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419887) in GitLab 16.9. |
| `remove_source_branch_after_merge`                 | boolean | No                             | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_storage`                               | string  | No                             | Which storage shard the repository is on. _(administrator only)_ |
| `request_access_enabled`                           | boolean | No                             | Allow users to request member access. |
| `resolve_outdated_diff_discussions`                | boolean | No                             | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `shared_runners_enabled`                           | boolean | No                             | Enable shared runners for this project. |
| `show_default_award_emojis`                        | boolean | No                             | Show default emoji reactions. |
| `snippets_enabled`                                 | boolean | No                             | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `squash_option`                                    | string  | No                             | One of `never`, `always`, `default_on`, or `default_off`. |
| `tag_list`                                         | array   | No                             | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `template_name`                                    | string  | No                             | When used without `use_custom_template`, name of a [built-in project template](../user/project/index.md#create-a-project-from-a-built-in-template). When used with `use_custom_template`, name of a custom project template. |
| `template_project_id`                              | integer | No                             | When used with `use_custom_template`, project ID of a custom project template. Using a project ID is preferable to using `template_name` since `template_name` may be ambiguous. Premium and Ultimate only. |
| `topics`                                           | array   | No                             | The list of topics for a project; put array of topics, that should be finally assigned to a project. |
| `use_custom_template`                              | boolean | No                             | Use either custom [instance](../administration/custom_project_templates.md) or [group](../user/group/custom_project_templates.md) (with `group_with_project_templates_id`) project template. Premium and Ultimate only. |
| `visibility`                                       | string  | No                             | See [project visibility level](#project-visibility-level). |
| `warn_about_potentially_unwanted_characters`       | boolean | No                             | Enable warnings about usage of potentially unwanted characters in this project. |
| `wiki_enabled`                                     | boolean | No                             | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |

[Project feature visibility](../user/public_access.md#change-the-visibility-of-individual-features-in-a-project)
settings with access control options can be one of:

- `disabled`: Disable the feature.
- `private`: Enable and set the feature to **Only project members**.
- `enabled`: Enable and set the feature to **Everyone with access**.

| Attribute                              | Type   | Required | Description |
|----------------------------------------|--------|----------|-------------|
| `analytics_access_level`               | string | No       | Set visibility of [analytics](../user/analytics/index.md). |
| `builds_access_level`                  | string | No       | Set visibility of [pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines). |
| `container_registry_access_level`      | string | No       | Set visibility of [container registry](../user/packages/container_registry/index.md#change-visibility-of-the-container-registry). |
| `environments_access_level`            | string | No       | Set visibility of [environments](../ci/environments/index.md). |
| `feature_flags_access_level`           | string | No       | Set visibility of [feature flags](../operations/feature_flags.md). |
| `forking_access_level`                 | string | No       | Set visibility of [forks](../user/project/repository/forking_workflow.md). |
| `infrastructure_access_level`          | string | No       | Set visibility of [infrastructure management](../user/infrastructure/index.md). |
| `issues_access_level`                  | string | No       | Set visibility of [issues](../user/project/issues/index.md). |
| `merge_requests_access_level`          | string | No       | Set visibility of [merge requests](../user/project/merge_requests/index.md). |
| `model_experiments_access_level`       | string | No       | Set visibility of [machine learning model experiments](../user/project/ml/experiment_tracking/index.md). |
| `model_registry_access_level`          | string | No       | Set visibility of [machine learning model registry](../user/project/ml/model_registry/index.md#access-the-model-registry). |
| `monitor_access_level`                 | string | No       | Set visibility of [application performance monitoring](../operations/index.md). |
| `pages_access_level`                   | string | No       | Set visibility of [GitLab Pages](../user/project/pages/pages_access_control.md). |
| `releases_access_level`                | string | No       | Set visibility of [releases](../user/project/releases/index.md). |
| `repository_access_level`              | string | No       | Set visibility of [repository](../user/project/repository/index.md). |
| `requirements_access_level`            | string | No       | Set visibility of [requirements management](../user/project/requirements/index.md). |
| `security_and_compliance_access_level` | string | No       | Set visibility of [security and compliance](../user/application_security/index.md). |
| `snippets_access_level`                | string | No       | Set visibility of [snippets](../user/snippets.md#change-default-visibility-of-snippets). |
| `wiki_access_level`                    | string | No       | Set visibility of [wiki](../user/project/wiki/index.md#enable-or-disable-a-project-wiki). |

## Create project for user

> - `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.
> - `model_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) in GitLab 16.7.

Creates a new project owned by the specified user. Available only for administrators.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
POST /projects/user/:user_id
```

General project attributes:

| Attribute                                          | Type    | Required | Description |
|----------------------------------------------------|---------|----------|-------------|
| `name`                                             | string  | Yes      | The name of the new project. |
| `user_id`                                          | integer | Yes      | The user ID of the project owner. |
| `allow_merge_on_skipped_pipeline`                  | boolean | No       | Set whether or not merge requests can be merged with skipped jobs. |
| `approvals_before_merge`                           | integer | No       | How many approvers should approve merge requests by default. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). Premium and Ultimate only. |
| `auto_cancel_pending_pipelines`                    | string  | No       | Auto-cancel pending pipelines. This action toggles between an enabled state and a disabled state; it is not a boolean. |
| `auto_devops_deploy_strategy`                      | string  | No       | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`). |
| `auto_devops_enabled`                              | boolean | No       | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                      | boolean | No       | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                           | mixed   | No       | Image file for avatar of the project. |
| `build_git_strategy`                               | string  | No       | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                    | integer | No       | The maximum amount of time, in seconds, that a job can run. |
| `ci_config_path`                                   | string  | No       | The path to CI configuration file. |
| `container_registry_enabled`                       | boolean | No       | _(Deprecated)_ Enable container registry for this project. Use `container_registry_access_level` instead. |
| `default_branch`                                   | string  | No       | The [default branch](../user/project/repository/branches/default.md) name. Requires `initialize_with_readme` to be `true`. |
| `description`                                      | string  | No       | Short project description. |
| `emails_disabled`                                  | boolean | No       | _(Deprecated)_ Disable email notifications. Use `emails_enabled` instead |
| `emails_enabled`                                   | boolean | No       | Enable email notifications. |
| `enforce_auth_checks_on_uploads`                   | boolean | No       | Enforce [auth checks](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files) on uploads. |
| `external_authorization_classification_label`      | string  | No       | The classification label for the project. Premium and Ultimate only. |
| `group_runners_enabled`                            | boolean | No       | Enable group runners for this project. |
| `group_with_project_templates_id`                  | integer | No       | For group-level custom templates, specifies ID of group from which all the custom project templates are sourced. Leave empty for instance-level templates. Requires `use_custom_template` to be true. Premium and Ultimate only. |
| `import_url`                                       | string  | No       | URL to import repository from. |
| `initialize_with_readme`                           | boolean | No       | `false` by default. |
| `issue_branch_template`                            | string  | No       | Template used to suggest names for [branches created from issues](../user/project/merge_requests/creating_merge_requests.md#from-an-issue). _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21243) in GitLab 15.6.)_ |
| `issues_enabled`                                   | boolean | No       | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `jobs_enabled`                                     | boolean | No       | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `lfs_enabled`                                      | boolean | No       | Enable LFS. |
| `merge_commit_template`                            | string  | No       | [Template](../user/project/merge_requests/commit_templates.md) used to create merge commit message in merge requests. |
| `merge_method`                                     | string  | No       | Set the [merge method](#project-merge-method) used. |
| `merge_requests_enabled`                           | boolean | No       | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `mirror_trigger_builds`                            | boolean | No       | Pull mirroring triggers builds. Premium and Ultimate only. |
| `mirror`                                           | boolean | No       | Enables pull mirroring in a project. Premium and Ultimate only. |
| `namespace_id`                                     | integer | No       | Namespace for the new project (defaults to the current user's namespace). |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | No       | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_all_status_checks_passed`     | boolean | No       | Indicates that merges of merge requests should be blocked unless all status checks have passed. Defaults to false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) in GitLab 15.5 with feature flag `only_allow_merge_if_all_status_checks_passed` disabled by default. Ultimate only. |
| `only_allow_merge_if_pipeline_succeeds`            | boolean | No       | Set whether merge requests can only be merged with successful jobs. |
| `packages_enabled`                                 | boolean | No       | Enable or disable packages repository feature. |
| `path`                                             | string  | No       | Custom repository name for new project. By default generated based on name. |
| `printing_merge_request_link_enabled`              | boolean | No       | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                    | boolean | No       | _(Deprecated)_ If `true`, jobs can be viewed by non-project members. Use `public_jobs` instead. |
| `public_jobs`                                      | boolean | No       | If `true`, jobs can be viewed by non-project members. |
| `repository_object_format`                         | string  | No       | Repository object format. Defaults to `sha1`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419887) in GitLab 16.9. |
| `remove_source_branch_after_merge`                 | boolean | No       | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_storage`                               | string  | No       | Which storage shard the repository is on. _(administrators only)_ |
| `request_access_enabled`                           | boolean | No       | Allow users to request member access. |
| `resolve_outdated_diff_discussions`                | boolean | No       | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `shared_runners_enabled`                           | boolean | No       | Enable shared runners for this project. |
| `show_default_award_emojis`                        | boolean | No       | Show default emoji reactions. |
| `snippets_enabled`                                 | boolean | No       | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `squash_commit_template`                           | string  | No       | [Template](../user/project/merge_requests/commit_templates.md) used to create squash commit message in merge requests. |
| `squash_option`                                    | string  | No       | One of `never`, `always`, `default_on`, or `default_off`. |
| `suggestion_commit_message`                        | string  | No       | The commit message used to apply merge request [suggestions](../user/project/merge_requests/reviews/suggestions.md). |
| `tag_list`                                         | array   | No       | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `template_name`                                    | string  | No       | When used without `use_custom_template`, name of a [built-in project template](../user/project/index.md#create-a-project-from-a-built-in-template). When used with `use_custom_template`, name of a custom project template. |
| `topics`                                           | array   | No       | The list of topics for the project. |
| `use_custom_template`                              | boolean | No       | Use either custom [instance](../administration/custom_project_templates.md) or [group](../user/group/custom_project_templates.md) (with `group_with_project_templates_id`) project template. Premium and Ultimate only. |
| `visibility`                                       | string  | No       | See [project visibility level](#project-visibility-level). |
| `warn_about_potentially_unwanted_characters`       | boolean | No       | Enable warnings about usage of potentially unwanted characters in this project. |
| `wiki_enabled`                                     | boolean | No       | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |

[Project feature visibility](../user/public_access.md#change-the-visibility-of-individual-features-in-a-project)
settings with access control options can be one of:

- `disabled`: Disable the feature.
- `private`: Enable and set the feature to **Only project members**.
- `enabled`: Enable and set the feature to **Everyone with access**.

| Attribute                              | Type   | Required | Description |
|----------------------------------------|--------|----------|-------------|
| `analytics_access_level`               | string | No       | Set visibility of [analytics](../user/analytics/index.md). |
| `builds_access_level`                  | string | No       | Set visibility of [pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines). |
| `container_registry_access_level`      | string | No       | Set visibility of [container registry](../user/packages/container_registry/index.md#change-visibility-of-the-container-registry). |
| `environments_access_level`            | string | No       | Set visibility of [environments](../ci/environments/index.md). |
| `feature_flags_access_level`           | string | No       | Set visibility of [feature flags](../operations/feature_flags.md). |
| `forking_access_level`                 | string | No       | Set visibility of [forks](../user/project/repository/forking_workflow.md). |
| `infrastructure_access_level`          | string | No       | Set visibility of [infrastructure management](../user/infrastructure/index.md). |
| `issues_access_level`                  | string | No       | Set visibility of [issues](../user/project/issues/index.md). |
| `merge_requests_access_level`          | string | No       | Set visibility of [merge requests](../user/project/merge_requests/index.md). |
| `model_experiments_access_level`       | string | No       | Set visibility of [machine learning model experiments](../user/project/ml/experiment_tracking/index.md). |
| `model_registry_access_level`          | string | No       | Set visibility of [machine learning model registry](../user/project/ml/model_registry/index.md#access-the-model-registry). |
| `monitor_access_level`                 | string | No       | Set visibility of [application performance monitoring](../operations/index.md). |
| `pages_access_level`                   | string | No       | Set visibility of [GitLab Pages](../user/project/pages/pages_access_control.md). |
| `releases_access_level`                | string | No       | Set visibility of [releases](../user/project/releases/index.md). |
| `repository_access_level`              | string | No       | Set visibility of [repository](../user/project/repository/index.md). |
| `requirements_access_level`            | string | No       | Set visibility of [requirements management](../user/project/requirements/index.md). |
| `security_and_compliance_access_level` | string | No       | Set visibility of [security and compliance](../user/application_security/index.md). |
| `snippets_access_level`                | string | No       | Set visibility of [snippets](../user/snippets.md#change-default-visibility-of-snippets). |
| `wiki_access_level`                    | string | No       | Set visibility of [wiki](../user/project/wiki/index.md#enable-or-disable-a-project-wiki). |

## Edit project

> - `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.
> - `model_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) in GitLab 16.7.

Updates an existing project.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
PUT /projects/:id
```

For example, to toggle the setting for
[shared runners on a GitLab.com project](../ci/runners/index.md):

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your-token>" \
     --url "https://gitlab.com/api/v4/projects/<your-project-ID>" \
     --data "shared_runners_enabled=true" # to turn off: "shared_runners_enabled=false"
```

General project attributes:

| Attribute                                          | Type              | Required | Description |
|----------------------------------------------------|-------------------|----------|-------------|
| `id`                                               | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `allow_merge_on_skipped_pipeline`                  | boolean           | No       | Set whether or not merge requests can be merged with skipped jobs. |
| `allow_pipeline_trigger_approve_deployment`        | boolean           | No       | Set whether or not a pipeline triggerer is allowed to approve deployments. Premium and Ultimate only. |
| `only_allow_merge_if_all_status_checks_passed`     | boolean           | No       | Indicates that merges of merge requests should be blocked unless all status checks have passed. Defaults to false.<br/><br/>[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) in GitLab 15.5 with feature flag `only_allow_merge_if_all_status_checks_passed` disabled by default. The feature flag was enabled by default in GitLab 15.9. Ultimate only. |
| `approvals_before_merge`                           | integer           | No       | How many approvers should approve merge requests by default. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). Premium and Ultimate only. |
| `auto_cancel_pending_pipelines`                    | string            | No       | Auto-cancel pending pipelines. This action toggles between an enabled state and a disabled state; it is not a boolean. |
| `auto_devops_deploy_strategy`                      | string            | No       | Auto Deploy strategy (`continuous`, `manual`, or `timed_incremental`). |
| `auto_devops_enabled`                              | boolean           | No       | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                      | boolean           | No       | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                           | mixed             | No       | Image file for avatar of the project. |
| `build_git_strategy`                               | string            | No       | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                    | integer           | No       | The maximum amount of time, in seconds, that a job can run. |
| `ci_config_path`                                   | string            | No       | The path to CI configuration file. |
| `ci_default_git_depth`                             | integer           | No       | Default number of revisions for [shallow cloning](../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone). |
| `ci_forward_deployment_enabled`                    | boolean           | No       | Enable or disable [prevent outdated deployment jobs](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs). |
| `ci_forward_deployment_rollback_allowed`           | boolean           | No       | Enable or disable [allow job retries for rollback deployments](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs). |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | boolean           | No       | Enable or disable [running pipelines in the parent project for merge requests from forks](../ci/pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project). _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325189) in GitLab 15.3.)_ |
| `ci_separated_caches`                              | boolean           | No       | Set whether or not caches should be [separated](../ci/caching/index.md#cache-key-names) by branch protection status. |
| `ci_restrict_pipeline_cancellation_role`           | string            | No       | Set the [role required to cancel a pipeline or job](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs). One of `developer`, `maintainer`, or `no_one`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429921) in GitLab 16.8. Premium and Ultimate only. |
| `ci_pipeline_variables_minimum_override_role`           | string            | No       | When `restrict_user_defined_variables` is enabled, you can specify which role can override variables. One of `owner`, `maintainer`, `developer` or `no_one_allowed`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440338) in GitLab 17.1. |
| `ci_push_repository_for_job_token_allowed` | boolean           | No       | Enable or disable the ability to push to the project repository using job token. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/389060) in GitLab 17.2. |
| `container_expiration_policy_attributes`           | hash              | No       | Update the image cleanup policy for this project. Accepts: `cadence` (string), `keep_n` (integer), `older_than` (string), `name_regex` (string), `name_regex_delete` (string), `name_regex_keep` (string), `enabled` (boolean). |
| `container_registry_enabled`                       | boolean           | No       | _(Deprecated)_ Enable container registry for this project. Use `container_registry_access_level` instead. |
| `default_branch`                                   | string            | No       | The [default branch](../user/project/repository/branches/default.md) name. |
| `description`                                      | string            | No       | Short project description. |
| `emails_disabled`                                  | boolean           | No       | _(Deprecated)_ Disable email notifications. Use `emails_enabled` instead |
| `emails_enabled`                                   | boolean           | No       | Enable email notifications. |
| `enforce_auth_checks_on_uploads`                   | boolean           | No       | Enforce [auth checks](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files) on uploads. |
| `external_authorization_classification_label`      | string            | No       | The classification label for the project. Premium and Ultimate only. |
| `group_runners_enabled`                            | boolean           | No       | Enable group runners for this project. |
| `import_url`                                       | string            | No       | URL the repository was imported from. |
| `issues_enabled`                                   | boolean           | No       | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `issues_template`                                  | string            | No       | Default description for Issues. Description is parsed with GitLab Flavored Markdown. See [Templates for issues and merge requests](#templates-for-issues-and-merge-requests). Premium and Ultimate only. |
| `jobs_enabled`                                     | boolean           | No       | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `keep_latest_artifact`                             | boolean           | No       | Disable or enable the ability to keep the latest artifact for this project. |
| `lfs_enabled`                                      | boolean           | No       | Enable LFS. |
| `merge_commit_template`                            | string            | No       | [Template](../user/project/merge_requests/commit_templates.md) used to create merge commit message in merge requests. |
| `merge_method`                                     | string            | No       | Set the [merge method](#project-merge-method) used. |
| `merge_pipelines_enabled`                          | boolean           | No       | Enable or disable merged results pipelines. |
| `merge_requests_enabled`                           | boolean           | No       | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `merge_requests_template`                          | string            | No       | Default description for merge requests. Description is parsed with GitLab Flavored Markdown. See [Templates for issues and merge requests](#templates-for-issues-and-merge-requests). Premium and Ultimate only. |
| `merge_trains_enabled`                             | boolean           | No       | Enable or disable merge trains. |
| `mirror_overwrites_diverged_branches`              | boolean           | No       | Pull mirror overwrites diverged branches. Premium and Ultimate only. |
| `mirror_trigger_builds`                            | boolean           | No       | Pull mirroring triggers builds. Premium and Ultimate only. |
| `mirror_user_id`                                   | integer           | No       | User responsible for all the activity surrounding a pull mirror event. _(administrators only)_ Premium and Ultimate only. |
| `mirror`                                           | boolean           | No       | Enables pull mirroring in a project. Premium and Ultimate only. |
| `mr_default_target_self`                           | boolean           | No       | For forked projects, target merge requests to this project. If `false`, the target is the upstream project. |
| `name`                                             | string            | No       | The name of the project. |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean           | No       | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_pipeline_succeeds`            | boolean           | No       | Set whether merge requests can only be merged with successful jobs. |
| `only_mirror_protected_branches`                   | boolean           | No       | Only mirror protected branches. Premium and Ultimate only. |
| `packages_enabled`                                 | boolean           | No       | Enable or disable packages repository feature. |
| `path`                                             | string            | No       | Custom repository name for the project. By default generated based on name. |
| `prevent_merge_without_jira_issue`                 | boolean           | No       | Set whether merge requests require an associated issue from Jira. Premium and Ultimate only. |
| `printing_merge_request_link_enabled`              | boolean           | No       | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                    | boolean           | No       | _(Deprecated)_ If `true`, jobs can be viewed by non-project members. Use `public_jobs` instead. |
| `public_jobs`                                      | boolean           | No       | If `true`, jobs can be viewed by non-project members. |
| `remove_source_branch_after_merge`                 | boolean           | No       | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_storage`                               | string            | No       | Which storage shard the repository is on. _(administrators only)_ |
| `request_access_enabled`                           | boolean           | No       | Allow users to request member access. |
| `resolve_outdated_diff_discussions`                | boolean           | No       | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `restrict_user_defined_variables`                  | boolean           | No       | Allow only users with the Maintainer role to pass user-defined variables when triggering a pipeline. For example when the pipeline is triggered in the UI, with the API, or by a trigger token. |
| `service_desk_enabled`                             | boolean           | No       | Enable or disable Service Desk feature. |
| `shared_runners_enabled`                           | boolean           | No       | Enable shared runners for this project. |
| `show_default_award_emojis`                        | boolean           | No       | Show default emoji reactions. |
| `snippets_enabled`                                 | boolean           | No       | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `issue_branch_template`                            | string            | No       | Template used to suggest names for [branches created from issues](../user/project/merge_requests/creating_merge_requests.md#from-an-issue). _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21243) in GitLab 15.6.)_ |
| `squash_commit_template`                           | string            | No       | [Template](../user/project/merge_requests/commit_templates.md) used to create squash commit message in merge requests. |
| `squash_option`                                    | string            | No       | One of `never`, `always`, `default_on`, or `default_off`. |
| `suggestion_commit_message`                        | string            | No       | The commit message used to apply merge request suggestions. |
| `tag_list`                                         | array             | No       | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `topics`                                           | array             | No       | The list of topics for the project. This replaces any existing topics that are already added to the project. |
| `visibility`                                       | string            | No       | See [project visibility level](#project-visibility-level). |
| `warn_about_potentially_unwanted_characters`       | boolean           | No       | Enable warnings about usage of potentially unwanted characters in this project. |
| `wiki_enabled`                                     | boolean           | No       | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |

[Project feature visibility](../user/public_access.md#change-the-visibility-of-individual-features-in-a-project)
settings with access control options can be one of:

- `disabled`: Disable the feature.
- `private`: Enable and set the feature to **Only project members**.
- `enabled`: Enable and set the feature to **Everyone with access**.

| Attribute                              | Type   | Required | Description |
|----------------------------------------|--------|----------|-------------|
| `analytics_access_level`               | string | No       | Set visibility of [analytics](../user/analytics/index.md). |
| `builds_access_level`                  | string | No       | Set visibility of [pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines). |
| `container_registry_access_level`      | string | No       | Set visibility of [container registry](../user/packages/container_registry/index.md#change-visibility-of-the-container-registry). |
| `environments_access_level`            | string | No       | Set visibility of [environments](../ci/environments/index.md). |
| `feature_flags_access_level`           | string | No       | Set visibility of [feature flags](../operations/feature_flags.md). |
| `forking_access_level`                 | string | No       | Set visibility of [forks](../user/project/repository/forking_workflow.md). |
| `infrastructure_access_level`          | string | No       | Set visibility of [infrastructure management](../user/infrastructure/index.md). |
| `issues_access_level`                  | string | No       | Set visibility of [issues](../user/project/issues/index.md). |
| `merge_requests_access_level`          | string | No       | Set visibility of [merge requests](../user/project/merge_requests/index.md). |
| `model_experiments_access_level`       | string | No       | Set visibility of [machine learning model experiments](../user/project/ml/experiment_tracking/index.md). |
| `model_registry_access_level`          | string | No       | Set visibility of [machine learning model registry](../user/project/ml/model_registry/index.md#access-the-model-registry). |
| `monitor_access_level`                 | string | No       | Set visibility of [application performance monitoring](../operations/index.md). |
| `pages_access_level`                   | string | No       | Set visibility of [GitLab Pages](../user/project/pages/pages_access_control.md). |
| `releases_access_level`                | string | No       | Set visibility of [releases](../user/project/releases/index.md). |
| `repository_access_level`              | string | No       | Set visibility of [repository](../user/project/repository/index.md). |
| `requirements_access_level`            | string | No       | Set visibility of [requirements management](../user/project/requirements/index.md). |
| `security_and_compliance_access_level` | string | No       | Set visibility of [security and compliance](../user/application_security/index.md). |
| `snippets_access_level`                | string | No       | Set visibility of [snippets](../user/snippets.md#change-default-visibility-of-snippets). |
| `wiki_access_level`                    | string | No       | Set visibility of [wiki](../user/project/wiki/index.md#enable-or-disable-a-project-wiki). |

## Fork project

Forks a project into the user namespace of the authenticated user or the one provided.

The forking operation for a project is asynchronous and is completed in a
background job. The request returns immediately. To determine whether the
fork of the project has completed, query the `import_status` for the new project.

```plaintext
POST /projects/:id/fork
```

| Attribute                | Type              | Required | Description |
|--------------------------|-------------------|----------|-------------|
| `id`                     | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `branches`               | string            | No       | Branches to fork (empty for all branches). |
| `description`            | string            | No       | The description assigned to the resultant project after forking. |
| `mr_default_target_self` | boolean           | No       | For forked projects, target merge requests to this project. If `false`, the target is the upstream project. |
| `name`                   | string            | No       | The name assigned to the resultant project after forking. |
| `namespace_id`           | integer           | No       | The ID of the namespace that the project is forked to. |
| `namespace_path`         | string            | No       | The path of the namespace that the project is forked to. |
| `namespace`              | integer or string | No       | _(Deprecated)_ The ID or path of the namespace that the project is forked to. |
| `path`                   | string            | No       | The path assigned to the resultant project after forking. |
| `visibility`             | string            | No       | The [visibility level](#project-visibility-level) assigned to the resultant project after forking. |

## List forks of a project

List the projects accessible to the calling user that have an established,
forked relationship with the specified project

```plaintext
GET /projects/:id/forks
```

| Attribute                     | Type              | Required | Description |
|-------------------------------|-------------------|----------|-------------|
| `id`                          | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `archived`                    | boolean           | No       | Limit by archived status. |
| `membership`                  | boolean           | No       | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer           | No       | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `order_by`                    | string            | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `owned`                       | boolean           | No       | Limit by projects explicitly owned by the current user. |
| `search`                      | string            | No       | Return list of projects matching the search criteria. |
| `simple`                      | boolean           | No       | Return only limited fields for each project. Without authentication, this operation is a no-op; only simple fields are returned. |
| `sort`                        | string            | No       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean           | No       | Limit by projects starred by the current user. |
| `statistics`                  | boolean           | No       | Include project statistics. Available only to users with at least the Reporter role. |
| `updated_after`               | datetime          | No       | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |
| `updated_before`              | datetime          | No       | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |
| `visibility`                  | string            | No       | Limit by visibility `public`, `internal`, or `private`. |
| `with_custom_attributes`      | boolean           | No       | Include [custom attributes](custom_attributes.md) in response. _(administrators only)_ |
| `with_issues_enabled`         | boolean           | No       | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean           | No       | Limit by enabled merge requests feature. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/forks"
```

Example responses:

```json
[
  {
    "id": 3,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "main",
    "visibility": "internal",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
    "web_url": "http://example.com/diaspora/diaspora-project-site",
    "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora project"
    ],
    "topics": [
      "example",
      "disapora project"
    ],
    "name": "Diaspora Project Site",
    "name_with_namespace": "Diaspora / Diaspora Project Site",
    "path": "diaspora-project-site",
    "path_with_namespace": "diaspora/diaspora-project-site",
    "repository_object_format": "sha1",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": true,
    "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 1,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## Star a project

Stars a given project. Returns status code `304` if the project is already
starred.

```plaintext
POST /projects/:id/star
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/star"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "internal",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "repository_object_format": "sha1",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 1,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

## Unstar a project

Unstars a given project. Returns status code `304` if the project is not starred.

```plaintext
POST /projects/:id/unstar
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/unstar"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "internal",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "repository_object_format": "sha1",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

## List starrers of a project

List the users who starred the specified project.

```plaintext
GET /projects/:id/starrers
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `search`  | string         | No | Search for specific users. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/starrers"
```

Example responses:

```json
[
  {
    "starred_since": "2019-01-28T14:47:30.642Z",
    "user": {
        "id": 1,
        "username": "jane_smith",
        "name": "Jane Smith",
        "state": "active",
        "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
        "web_url": "http://localhost:3000/jane_smith"
    }
  },
  {
    "starred_since": "2018-01-02T11:40:26.570Z",
    "user": {
      "id": 2,
      "username": "janine_smith",
      "name": "Janine Smith",
      "state": "blocked",
      "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
      "web_url": "http://localhost:3000/janine_smith"
    }
  }
]
```

## Languages

Get languages used in a project with percentage value.

```plaintext
GET /projects/:id/languages
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/languages"
```

Example response:

```json
{
  "Ruby": 66.69,
  "JavaScript": 22.98,
  "HTML": 7.91,
  "CoffeeScript": 2.42
}
```

## Archive a project

Archives the project if the user is either an administrator or the owner of this
project. This action is idempotent, thus archiving an already archived project
does not change the project.

```plaintext
POST /projects/:id/archive
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/archive"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "repository_object_format": "sha1",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

## Unarchive a project

Unarchives the project if the user is either an administrator or the owner of
this project. This action is idempotent, thus unarchiving a non-archived project
doesn't change the project.

```plaintext
POST /projects/:id/unarchive
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/unarchive"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "main",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/main/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "repository_object_format": "sha1",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/main/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_separated_caches": true,
  "ci_restrict_pipeline_cancellation_role": "developer",
  "ci_pipeline_variables_minimum_override_role": "maintainer",
  "ci_push_repository_for_job_token_allowed": false,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

## Delete project

This endpoint:

- Deletes a project including all associated resources (including issues and
  merge requests).
- On [Premium or Ultimate](https://about.gitlab.com/pricing/) tiers,
  [delayed project deletion](../user/project/working_with_projects.md#delayed-project-deletion)
  is applied if enabled.
- From [GitLab 15.11](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) on
  [Premium or Ultimate](https://about.gitlab.com/pricing/) tiers, deletes a project immediately if the project is already
  marked for deletion, and the `permanently_remove` and `full_path` parameters are passed.
- From [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) on
  [Premium or Ultimate](https://about.gitlab.com/pricing/) tiers, delayed project deletion is enabled by default.
  The deletion happens after the number of days specified in the
  [default deletion delay](../administration/settings/visibility_and_access_controls.md#deletion-protection).

WARNING:
The option to delete projects immediately from deletion protection settings in the **Admin** area was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) in GitLab 15.9 and removed in GitLab 16.0.

```plaintext
DELETE /projects/:id
```

| Attribute                              | Type              | Required | Description |
|----------------------------------------|-------------------|----------|-------------|
| `id`                                   | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `full_path`                            | string            | no       | Full path of project to use with `permanently_remove`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) in GitLab 15.11. To find the project path, use `path_with_namespace` from [get single project](projects.md#get-single-project). Premium and Ultimate only. |
| `permanently_remove`                   | boolean/string    | no       | Immediately deletes a project if it is marked for deletion. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) in GitLab 15.11. Premium and Ultimate only. |

## Restore project marked for deletion

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Restores project marked for deletion.

```plaintext
POST /projects/:id/restore
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

## Markdown uploads

Markdown uploads are files uploaded to a project that can be referenced in Markdown text in an issue, merge request, snippet, or wiki page.

### Upload a file

> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112450) in GitLab 15.10. Feature flag `enforce_max_attachment_size_upload_api` removed.
> - `full_path` response attribute pattern [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150939) in GitLab 17.1.
> - `id` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161160) in GitLab 17.3.

Uploads a file to the specified project to be used in an issue or merge request
description, or a comment.

```plaintext
POST /projects/:id/uploads
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `file`    | string            | Yes      | The file to be uploaded. |
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

To upload a file from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to a file on your file system and be preceded by
`@`. For example:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "file=@dk.png" "https://gitlab.example.com/api/v4/projects/5/uploads"
```

Returned object:

```json
{
  "id": 5,
  "alt": "dk",
  "url": "/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "full_path": "/-/project/1234/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "markdown": "![dk](/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png)"
}
```

The returned `full_path` is the absolute path to the file.
The returned `url` can be used in Markdown contexts. The link is expanded when the format in `markdown` is used.

### List uploads

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) in GitLab 17.2.

Get all uploads of the project sorted by `created_at` in descending order.

You must have at least the Maintainer role to use this endpoint.

```plaintext
GET /projects/:id/uploads
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads"
```

Returned object:

```json
[
  {
    "id": 1,
    "size": 1024,
    "filename": "image.png",
    "created_at":"2024-06-20T15:53:03.067Z",
    "uploaded_by": {
      "id": 18,
      "name" : "Alexandra Bashirian",
      "username" : "eileen.lowe"
    }
  },
  {
    "id": 2,
    "size": 512,
    "filename": "other-image.png",
    "created_at":"2024-06-19T15:53:03.067Z",
    "uploaded_by": null
  }
]
```

### Download an uploaded file

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) in GitLab 17.2.

You must have at least the Maintainer role to use this endpoint.

```plaintext
GET /projects/:id/uploads/:upload_id
```

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `upload_id` | integer           | Yes      | The ID of the upload. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/1"
```

### Delete an uploaded file

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157066) in GitLab 17.2.

You must have at least the Maintainer role to use this endpoint.

```plaintext
DELETE /projects/:id/uploads/:upload_id
```

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `upload_id` | integer           | Yes      | The ID of the upload. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/uploads/1"
```

## Upload a project avatar

Uploads an avatar to the specified project.

```plaintext
PUT /projects/:id
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `avatar`  | string            | Yes      | The file to be uploaded. |
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

To upload an avatar from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to an image file on your file system and be
preceded by `@`. For example:

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "avatar=@dk.png" "https://gitlab.example.com/api/v4/projects/5"
```

Returned object:

```json
{
  "avatar_url": "https://gitlab.example.com/uploads/-/system/project/avatar/2/dk.png"
}
```

## Download a project avatar

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144039) in GitLab 16.9.

Get a project avatar.
You can access this endpoint without authentication if the project is publicly accessible.

```plaintext
GET /projects/:id/avatar
```

| Attribute | Type              | Required | Description           |
| --------- | ----------------- | -------- | --------------------- |
| `id`      | integer or string | yes      | ID or [URL-encoded path](rest/index.md#namespaced-path-encoding) of the project. |

Example:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/avatar"
```

## Remove a project avatar

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92604) in GitLab 15.4.

To remove a project avatar, use a blank value for the `avatar` attribute.

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "avatar=" "https://gitlab.example.com/api/v4/projects/5"
```

## Share project with group

Allow to share project with group.

```plaintext
POST /projects/:id/share
```

| Attribute      | Type              | Required | Description |
|----------------|-------------------|----------|-------------|
| `group_access` | integer           | Yes      | The [role (`access_level`)](members.md#roles) to grant the group. |
| `group_id`     | integer           | Yes      | The ID of the group to share with. |
| `id`           | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `expires_at`   | string            | No       | Share expiration date in ISO 8601 format. For example, `2016-09-26`. |

## Delete a shared project link within a group

Unshare the project from the group. Returns `204` and no content on success.

```plaintext
DELETE /projects/:id/share/:group_id
```

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|-------------|
| `group_id` | integer           | Yes      | The ID of the group. |
| `id`       | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/share/17"
```

## Import project members

Import members from another project.

If the importing member's role in the target project is:

- Maintainer, then members with the Owner role in the source project are imported with the Maintainer role.
- Owner, then members with the Owner role in the source project are imported with the Owner role.

```plaintext
POST /projects/:id/import_project_members/:project_id
```

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | Yes      | The ID or [URL-encoded path](rest/index.md#namespaced-path-encoding) of the target project to receive the members. |
| `project_id` | integer or string | Yes      | The ID or [URL-encoded path](rest/index.md#namespaced-path-encoding) of the source project to import the members from. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/import_project_members/32"
```

Returns:

- `200 OK` on success.
- `404 Project Not Found` if the target or source project does not exist or cannot be accessed by the requester.
- `422 Unprocessable Entity` if the import of project members does not complete successfully.

Example responses:

When all emails were successfully sent (`200` HTTP status code):

```json
{  "status":  "success"  }
```

When there was any error importing 1 or more members (`200` HTTP status code):

```json
{
  "status": "error",
  "message": {
               "john_smith": "Some individual error message",
               "jane_smith": "Some individual error message"
             },
  "total_members_count": 3
}
```

When there is a system error (`404` and `422` HTTP status codes):

```json
{  "message":  "Import failed"  }
```

## Hooks

Also called project hooks and webhooks. These are different for [system hooks](system_hooks.md)
that are system-wide.

Prerequisites:

- You must be an administrator or have at least the Maintainer role for the project.

### List project hooks

Get a list of project hooks.

```plaintext
GET /projects/:id/hooks
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

### Get project hook

Get a specific hook for a project.

```plaintext
GET /projects/:id/hooks/:hook_id
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `hook_id` | integer           | Yes      | The ID of a project hook. |
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "name": "Hook name",
  "description": "Hook description",
  "project_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "confidential_note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "deployment_events": true,
  "releases_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}",
  "custom_headers": [
    {
      "key": "Authorization"
    }
  ]
}
```

### Get project hook events

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048) in GitLab 17.3.

Get a list of events for a specific project hook in the past 7 days from start date.

```plaintext
GET /projects/:id/hooks/:hook_id/events
```

| Attribute | Type              | Required | Description                                                                                                                                                                                 |
|-----------|-------------------|----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `hook_id` | integer           | Yes      | The ID of a project hook.                                                                                                                                                                   |
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding).                                                                                                        |
 | `status` | integer or string | No | The response status code of the events, for example: `200` or `500`. You can search by status category: `successful` (200-299), `client_failure` (400-499), and `server_failure` (500-599). |
| `page`             | integer | No | Page to retrieve. Defaults to `1`.                      |
| `per_page`         | integer | No | Number of records to return per page. Defaults to `20`. |

```json
[
  {
    "id": 1,
    "url": "https://example.net/",
    "trigger": "push_hooks",
    "request_headers": {
      "Content-Type": "application/json",
      "User-Agent": "GitLab/17.1.0-pre",
      "Idempotency-Key": "3a427872-00df-429c-9bc9-a9475de2efe4",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "3c5c0404-c866-44bc-a5f6-452bb1bfc76e",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "9cebe914-4827-408f-b014-cfa23a47a35f",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
      "before": "468abc807a2b2572f43e72c743b76cee6db24025",
      "after": "f15b32277d2c55c6c595845a87109b09c913c556",
      "ref": "refs/heads/master",
      "ref_protected": true,
      "checkout_sha": "f15b32277d2c55c6c595845a87109b09c913c556",
      "message": null,
      "user_id": 1,
      "user_name": "Administrator",
      "user_username": "root",
      "user_email": null,
      "user_avatar": "https://www.gravatar.com/avatar/13efe0d4559475ba84ecc802061febbdea6e224fcbffd7ec7da9cd431845299c?s=80&d=identicon",
      "project_id": 7,
      "project": {
        "id": 7,
        "name": "Flight",
        "description": "Incidunt ea ab officia a veniam.",
        "web_url": "https://gitlab.example.com/flightjs/Flight",
        "avatar_url": null,
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "namespace": "Flightjs",
        "visibility_level": 10,
        "path_with_namespace": "flightjs/Flight",
        "default_branch": "master",
        "ci_config_path": null,
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "http_url": "https://gitlab.example.com/flightjs/Flight.git"
      },
      "commits": [
        {
          "id": "f15b32277d2c55c6c595845a87109b09c913c556",
          "message": "v1.5.2\n",
          "title": "v1.5.2",
          "timestamp": "2017-06-19T14:39:53-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/f15b32277d2c55c6c595845a87109b09c913c556",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "message": "Merge pull request #378 from flightjs/alunny/publish_lib\n\npublish lib and index to npm",
          "title": "Merge pull request #378 from flightjs/alunny/publish_lib",
          "timestamp": "2017-06-16T10:26:39-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "author": {
            "name": "angus croll",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "468abc807a2b2572f43e72c743b76cee6db24025",
          "message": "publish lib and index to npm\n",
          "title": "publish lib and index to npm",
          "timestamp": "2017-06-16T10:23:04-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/468abc807a2b2572f43e72c743b76cee6db24025",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        }
      ],
      "total_commits_count": 3,
      "push_options": {},
      "repository": {
        "name": "Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "description": "Incidunt ea ab officia a veniam.",
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "visibility_level": 10
      }
    },
    "response_headers": {
      "Date": "Sun, 26 May 2024 03:03:17 GMT",
      "Content-Type": "application/json; charset=utf-8",
      "Content-Length": "16",
      "Connection": "close",
      "X-Powered-By": "Express",
      "Access-Control-Allow-Origin": "*",
      "X-Pd-Status": "sent to primary"
    },
    "response_body": "{\"success\":true}",
    "execution_duration": 1.0906479999999874,
    "response_status": "200"
  },
  {
    "id": 2,
    "url": "https://example.net/",
    "trigger": "push_hooks",
    "request_headers": {
      "Content-Type": "application/json",
      "User-Agent": "GitLab/17.1.0-pre",
      "Idempotency-Key": "7c6e0583-49f2-4dc5-a50b-4c0bcf3c1b27",
      "X-Gitlab-Event": "Push Hook",
      "X-Gitlab-Webhook-UUID": "a753eedb-1d72-4549-9ca7-eac8ea8e50dd",
      "X-Gitlab-Instance": "https://gitlab.example.com",
      "X-Gitlab-Event-UUID": "842d7c3e-3114-4396-8a95-66c084d53cb1",
      "X-Gitlab-Token": "[REDACTED]"
    },
    "request_data": {
      "object_kind": "push",
      "event_name": "push",
      "before": "468abc807a2b2572f43e72c743b76cee6db24025",
      "after": "f15b32277d2c55c6c595845a87109b09c913c556",
      "ref": "refs/heads/master",
      "ref_protected": true,
      "checkout_sha": "f15b32277d2c55c6c595845a87109b09c913c556",
      "message": null,
      "user_id": 1,
      "user_name": "Administrator",
      "user_username": "root",
      "user_email": null,
      "user_avatar": "https://www.gravatar.com/avatar/13efe0d4559475ba84ecc802061febbdea6e224fcbffd7ec7da9cd431845299c?s=80&d=identicon",
      "project_id": 7,
      "project": {
        "id": 7,
        "name": "Flight",
        "description": "Incidunt ea ab officia a veniam.",
        "web_url": "https://gitlab.example.com/flightjs/Flight",
        "avatar_url": null,
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "namespace": "Flightjs",
        "visibility_level": 10,
        "path_with_namespace": "flightjs/Flight",
        "default_branch": "master",
        "ci_config_path": null,
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "http_url": "https://gitlab.example.com/flightjs/Flight.git"
      },
      "commits": [
        {
          "id": "f15b32277d2c55c6c595845a87109b09c913c556",
          "message": "v1.5.2\n",
          "title": "v1.5.2",
          "timestamp": "2017-06-19T14:39:53-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/f15b32277d2c55c6c595845a87109b09c913c556",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "message": "Merge pull request #378 from flightjs/alunny/publish_lib\n\npublish lib and index to npm",
          "title": "Merge pull request #378 from flightjs/alunny/publish_lib",
          "timestamp": "2017-06-16T10:26:39-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/8749d49930866a4871fa086adbd7d2057fcc3ebb",
          "author": {
            "name": "angus croll",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        },
        {
          "id": "468abc807a2b2572f43e72c743b76cee6db24025",
          "message": "publish lib and index to npm\n",
          "title": "publish lib and index to npm",
          "timestamp": "2017-06-16T10:23:04-07:00",
          "url": "https://gitlab.example.com/flightjs/Flight/-/commit/468abc807a2b2572f43e72c743b76cee6db24025",
          "author": {
            "name": "Andrew Lunny",
            "email": "[REDACTED]"
          },
          "added": [],
          "modified": [
            "package.json"
          ],
          "removed": []
        }
      ],
      "total_commits_count": 3,
      "push_options": {},
      "repository": {
        "name": "Flight",
        "url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "description": "Incidunt ea ab officia a veniam.",
        "homepage": "https://gitlab.example.com/flightjs/Flight",
        "git_http_url": "https://gitlab.example.com/flightjs/Flight.git",
        "git_ssh_url": "ssh://git@gitlab.example.com:2222/flightjs/Flight.git",
        "visibility_level": 10
      }
    },
    "response_headers": {
      "Date": "Sun, 26 May 2024 03:03:19 GMT",
      "Content-Type": "application/json; charset=utf-8",
      "Content-Length": "16",
      "Connection": "close",
      "X-Powered-By": "Express",
      "Access-Control-Allow-Origin": "*",
      "X-Pd-Status": "sent to primary"
    },
    "response_body": "{\"success\":true}",
    "execution_duration": 1.0716120000000728,
    "response_status": "200"
  }
]
```

### Add project hook

Adds a hook to a specified project.

```plaintext
POST /projects/:id/hooks
```

| Attribute                    | Type              | Required | Description |
|------------------------------|-------------------|----------|-------------|
| `id`                         | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `url`                        | string            | Yes      | The hook URL. |
| `name`                       | string            | No       | Name of the hook ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1). |
| `description`                | string            | No       | Description of the hook ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1). |
| `confidential_issues_events` | boolean           | No       | Trigger hook on confidential issues events. |
| `confidential_note_events`   | boolean           | No       | Trigger hook on confidential note events. |
| `deployment_events`          | boolean           | No       | Trigger hook on deployment events. |
| `enable_ssl_verification`    | boolean           | No       | Do SSL verification when triggering the hook. |
| `issues_events`              | boolean           | No       | Trigger hook on issues events. |
| `job_events`                 | boolean           | No       | Trigger hook on job events. |
| `merge_requests_events`      | boolean           | No       | Trigger hook on merge requests events. |
| `note_events`                | boolean           | No       | Trigger hook on note events. |
| `pipeline_events`            | boolean           | No       | Trigger hook on pipeline events. |
| `push_events_branch_filter`  | string            | No       | Trigger hook on push events for matching branches only. |
| `branch_filter_strategy`     | string         | No       | Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`. |
| `push_events`                | boolean           | No       | Trigger hook on push events. |
| `releases_events`            | boolean           | No       | Trigger hook on release events. |
| `tag_push_events`            | boolean           | No       | Trigger hook on tag push events. |
| `token`                      | string            | No       | Secret token to validate received payloads; the token isn't returned in the response. |
| `wiki_page_events`           | boolean           | No       | Trigger hook on wiki events. |
| `resource_access_token_events` | boolean         | No       | Trigger hook on project access token expiry events. |
| `custom_webhook_template`    | string            | No       | Custom webhook template for the hook. |
| `custom_headers`             | array             | No       | Custom headers for the hook. |

### Edit project hook

Edits a hook for a specified project.

```plaintext
PUT /projects/:id/hooks/:hook_id
```

| Attribute                    | Type              | Required | Description |
|------------------------------|-------------------|----------|-------------|
| `hook_id`                    | integer           | Yes      | The ID of the project hook. |
| `id`                         | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `url`                        | string            | Yes      | The hook URL. |
| `name`                       | string            | No       | Name of the hook ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1). |
| `description`                | string            | No       | Description of the hook ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/460887) in GitLab 17.1). |
| `confidential_issues_events` | boolean           | No       | Trigger hook on confidential issues events. |
| `confidential_note_events`   | boolean           | No       | Trigger hook on confidential note events. |
| `deployment_events`          | boolean           | No       | Trigger hook on deployment events. |
| `enable_ssl_verification`    | boolean           | No       | Do SSL verification when triggering the hook. |
| `issues_events`              | boolean           | No       | Trigger hook on issues events. |
| `job_events`                 | boolean           | No       | Trigger hook on job events. |
| `merge_requests_events`      | boolean           | No       | Trigger hook on merge requests events. |
| `note_events`                | boolean           | No       | Trigger hook on note events. |
| `pipeline_events`            | boolean           | No       | Trigger hook on pipeline events. |
| `push_events_branch_filter`  | string            | No       | Trigger hook on push events for matching branches only. |
| `branch_filter_strategy`     | string         | No       | Filter push events by branch. Possible values are `wildcard` (default), `regex`, and `all_branches`. |
| `push_events`                | boolean           | No       | Trigger hook on push events. |
| `releases_events`            | boolean           | No       | Trigger hook on release events. |
| `tag_push_events`            | boolean           | No       | Trigger hook on tag push events. |
| `token`                      | string            | No       | Secret token to validate received payloads. Not returned in the response. When you change the webhook URL, the secret token is reset and not retained. |
| `wiki_page_events`           | boolean           | No       | Trigger hook on wiki page events. |
| `resource_access_token_events` | boolean         | No       | Trigger hook on project access token expiry events. |
| `custom_webhook_template`    | string            | No       | Custom webhook template for the hook. |
| `custom_headers`             | array             | No       | Custom headers for the hook. |

### Delete project hook

Removes a hook from a project. This method is idempotent, and can be called
multiple times. Either the hook is available or not.

```plaintext
DELETE /projects/:id/hooks/:hook_id
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `hook_id` | integer           | Yes      | The ID of the project hook. |
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

Note the JSON response differs if the hook is available or not. If the project
hook is available before it's returned in the JSON response or an empty response
is returned.

### Trigger a test project hook

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147656) in GitLab 16.11.
> - Special rate limit [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150066) in GitLab 17.0 [with a flag](../administration/feature_flags.md) named `web_hook_test_api_endpoint_rate_limit`. Enabled by default.

Trigger a test hook for a specified project.

In GitLab 17.0 and later, this endpoint has a special rate limit. In GitLab 17.0 the rate was three requests per minute for each project hook.
In GitLab 17.1 this was changed to five requests per minute for each project and authenticated user.
To disable this limit on self-managed GitLab and GitLab Dedicated, an administrator can
[disable the feature flag](../administration/feature_flags.md) named `web_hook_test_api_endpoint_rate_limit`.

```plaintext
POST /projects/:id/hooks/:hook_id/test/:trigger
```

| Attribute | Type              | Required | Description                                                                                                                                                                                                                                                |
|-----------|-------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `hook_id` | integer           | Yes      | The ID of the project hook.                                                                                                                                                                                                                                |
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding).                                                                                                                                                                       |
| `trigger` | string            | Yes      | One of `push_events`, `tag_push_events`, `issues_events`, `confidential_issues_events`, `note_events`, `merge_requests_events`, `job_events`, `pipeline_events`, `wiki_page_events`, `releases_events`, `emoji_events`, or `resource_access_token_events`. |

```json
{"message":"201 Created"}
```

### Set a custom header

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) in GitLab 17.1.

```plaintext
PUT /projects/:id/hooks/:hook_id/custom_headers/:key
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `hook_id` | integer           | Yes      | The ID of the project hook. |
| `key`     | string            | Yes      | The key of the custom header. |
| `value`   | string            | Yes      | The value of the custom header. |

On success, this endpoint returns the response code `204 No Content`.

### Delete a custom header

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768) in GitLab 17.1.

```plaintext
DELETE /projects/:id/hooks/:hook_id/custom_headers/:key
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `hook_id` | integer           | Yes      | The ID of the project hook. |
| `key`     | string            | Yes      | The key of the custom header. |

On success, this endpoint returns the response code `204 No Content`.

## Fork relationship

Allows modification of the forked relationship between existing projects.
Available only for project owners and administrators.

### Create a forked from/to relation between existing projects

```plaintext
POST /projects/:id/fork/:forked_from_id
```

| Attribute        | Type              | Required | Description |
|------------------|-------------------|----------|-------------|
| `forked_from_id` | ID                | Yes      | The ID of the project that was forked from. |
| `id`             | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

### Delete an existing forked from relationship

```plaintext
DELETE /projects/:id/fork
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

## Search for projects by name

Search for projects by name which are accessible to the authenticated user. This
endpoint can be accessed without authentication if the project is publicly
accessible.

```plaintext
GET /projects
```

| Attribute  | Type   | Required | Description |
|------------|--------|----------|-------------|
| `search`   | string | Yes      | A string contained in the project name. |
| `order_by` | string | No       | Return requests ordered by `id`, `name`, `created_at` or `last_activity_at` fields. |
| `sort`     | string | No       | Return requests sorted in `asc` or `desc` order. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects?search=test"
```

## Start the Housekeeping task for a project

```plaintext
POST /projects/:id/housekeeping
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `task`    | string            | No       | `prune` to trigger manual prune of unreachable objects or `eager` to trigger eager housekeeping. |

## Push rules

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

### Get project push rules

Get the [push rules](../user/project/repository/push_rules.md) of a
project.

```plaintext
GET /projects/:id/push_rule
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |

```json
{
  "id": 1,
  "project_id": 3,
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "ssh\\:\\/\\/",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "created_at": "2012-10-12T17:04:47Z",
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 5,
  "commit_committer_check": false,
  "commit_committer_name_check": false,
  "reject_unsigned_commits": false,
  "reject_non_dco_commits": false
}
```

### Add project push rule

Adds a push rule to a specified project.

```plaintext
POST /projects/:id/push_rule
```

<!-- markdownlint-disable MD056 -->

| Attribute                       | Type              | Required | Description |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `author_email_regex`            | string            | No       | All commit author emails must match this, for example `@my-company.com$`. |
| `branch_name_regex`             | string            | No       | All branch names must match this, for example `(feature|hotfix)\/.*`. |
| `commit_message_negative_regex` | string            | No       | No commit message is allowed to match this, for example `ssh\:\/\/`. |
| `commit_message_regex`          | string            | No       | All commit messages must match this, for example `Fixed \d+\..*`. |
| `deny_delete_tag`               | boolean           | No       | Deny deleting a tag. |
| `file_name_regex`               | string            | No       | All committed filenames must **not** match this, for example `(jar|exe)$`. |
| `max_file_size`                 | integer           | No       | Maximum file size (MB). |
| `member_check`                  | boolean           | No       | Restrict commits by author (email) to existing GitLab users. |
| `prevent_secrets`               | boolean           | No       | GitLab rejects any files that are likely to contain secrets. |
| `commit_committer_check`        | boolean           | No       | Users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_committer_name_check`   | boolean           | No       | Users can only push commits to this repository if the commit author name is consistent with their GitLab account name. |
| `reject_unsigned_commits`       | boolean           | No       | Reject commit when it's not signed. |
| `reject_non_dco_commits`        | boolean           | No       | Reject commit when it's not DCO certified. |

<!-- markdownlint-enable MD056 -->

### Edit project push rule

Edits a push rule for a specified project.

```plaintext
PUT /projects/:id/push_rule
```

<!-- markdownlint-disable MD056 -->

| Attribute                       | Type              | Required | Description |
|---------------------------------|-------------------|----------|-------------|
| `id`                            | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `author_email_regex`            | string            | No       | All commit author emails must match this, for example `@my-company.com$`. |
| `branch_name_regex`             | string            | No       | All branch names must match this, for example `(feature|hotfix)\/.*`. |
| `commit_message_negative_regex` | string            | No       | No commit message is allowed to match this, for example `ssh\:\/\/`. |
| `commit_message_regex`          | string            | No       | All commit messages must match this, for example `Fixed \d+\..*`. |
| `deny_delete_tag`               | boolean           | No       | Deny deleting a tag. |
| `file_name_regex`               | string            | No       | All committed filenames must **not** match this, for example `(jar|exe)$`. |
| `max_file_size`                 | integer           | No       | Maximum file size (MB). |
| `member_check`                  | boolean           | No       | Restrict commits by author (email) to existing GitLab users. |
| `prevent_secrets`               | boolean           | No       | GitLab rejects any files that are likely to contain secrets. |
| `commit_committer_check`        | boolean           | No       | Users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_committer_name_check`   | boolean           | No       | Users can only push commits to this repository if the commit author name is consistent with their GitLab account name. |
| `reject_unsigned_commits`       | boolean           | No       | Reject commits when they are not signed. |
| `reject_non_dco_commits`        | boolean           | No       | Reject commit when it's not DCO certified. |

<!-- markdownlint-enable MD056 -->

### Delete project push rule

> - Moved to GitLab Premium in 13.9.

Removes a push rule from a project.

```plaintext
DELETE /projects/:id/push_rule
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

## Get groups to which a user can transfer a project

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371006) in GitLab 15.4

Retrieve a list of groups to which the user can transfer a project.

```plaintext
GET /projects/:id/transfer_locations
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `search`  | string            | No       | The group names to search for. |

Example request:

```shell
curl --request GET "https://gitlab.example.com/api/v4/projects/1/transfer_locations"
```

Example response:

```json
[
  {
    "id": 27,
    "web_url": "https://gitlab.example.com/groups/gitlab",
    "name": "GitLab",
    "avatar_url": null,
    "full_name": "GitLab",
    "full_path": "GitLab"
  },
  {
    "id": 31,
    "web_url": "https://gitlab.example.com/groups/foobar",
    "name": "FooBar",
    "avatar_url": null,
    "full_name": "FooBar",
    "full_path": "FooBar"
  }
]
```

## Transfer a project to a new namespace

See the [Project documentation](../user/project/settings/migrate_projects.md#transfer-a-project-to-another-namespace)
for prerequisites to transfer a project.

```plaintext
PUT /projects/:id/transfer
```

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `namespace` | integer or string | Yes      | The ID or path of the namespace to transfer to project to. |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/transfer?namespace=14"
```

Example response:

```json
  {
  "id": 7,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "name": "hello-world",
  "name_with_namespace": "cute-cats / hello-world",
  "path": "hello-world",
  "path_with_namespace": "cute-cats/hello-world",
  "created_at": "2020-10-15T16:25:22.415Z",
  "updated_at": "2020-10-15T16:25:22.415Z",
  "default_branch": "main",
  "tag_list": [], //deprecated, use `topics` instead
  "topics": [],
  "ssh_url_to_repo": "git@gitlab.example.com:cute-cats/hello-world.git",
  "http_url_to_repo": "https://gitlab.example.com/cute-cats/hello-world.git",
  "web_url": "https://gitlab.example.com/cute-cats/hello-world",
  "readme_url": "https://gitlab.example.com/cute-cats/hello-world/-/blob/main/README.md",
  "avatar_url": null,
  "forks_count": 0,
  "star_count": 0,
  "last_activity_at": "2020-10-15T16:25:22.415Z",
  "namespace": {
    "id": 18,
    "name": "cute-cats",
    "path": "cute-cats",
    "kind": "group",
    "full_path": "cute-cats",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/cute-cats"
  },
  "container_registry_image_prefix": "registry.example.com/cute-cats/hello-world",
  "_links": {
    "self": "https://gitlab.example.com/api/v4/projects/7",
    "issues": "https://gitlab.example.com/api/v4/projects/7/issues",
    "merge_requests": "https://gitlab.example.com/api/v4/projects/7/merge_requests",
    "repo_branches": "https://gitlab.example.com/api/v4/projects/7/repository/branches",
    "labels": "https://gitlab.example.com/api/v4/projects/7/labels",
    "events": "https://gitlab.example.com/api/v4/projects/7/events",
    "members": "https://gitlab.example.com/api/v4/projects/7/members"
  },
  "packages_enabled": true,
  "empty_repo": false,
  "archived": false,
  "visibility": "private",
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": true, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "enabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null,
    "name_regex_keep": null,
    "next_run_at": "2020-10-22T16:25:22.746Z"
  },
  "issues_enabled": true,
  "merge_requests_enabled": true,
  "wiki_enabled": true,
  "jobs_enabled": true,
  "snippets_enabled": true,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "can_create_merge_request_in": true,
  "issues_access_level": "enabled",
  "repository_access_level": "enabled",
  "merge_requests_access_level": "enabled",
  "forking_access_level": "enabled",
  "analytics_access_level": "enabled",
  "wiki_access_level": "enabled",
  "builds_access_level": "enabled",
  "snippets_access_level": "enabled",
  "pages_access_level": "enabled",
  "security_and_compliance_access_level": "enabled",
  "emails_disabled": null,
  "emails_enabled": null,
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "lfs_enabled": true,
  "creator_id": 2,
  "import_status": "none",
  "open_issues_count": 0,
  "ci_default_git_depth": 50,
  "public_jobs": true,
  "build_timeout": 3600,
  "auto_cancel_pending_pipelines": "enabled",
  "ci_config_path": null,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": null,
  "restrict_user_defined_variables": false,
  "request_access_enabled": true,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": true,
  "printing_merge_request_link_enabled": true,
  "merge_method": "merge",
  "squash_option": "default_on",
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "autoclose_referenced_issues": true,
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "compliance_frameworks": [],
  "warn_about_potentially_unwanted_characters": true
}
```

## Branches

Read more in the [Branches](branches.md) documentation.

## Project import/export

Read more in the [Project import/export](project_import_export.md) documentation.

## Project members

Read more in the [Project members](members.md) documentation.

## Project vulnerabilities

Read more in the [Project vulnerabilities](project_vulnerabilities.md) documentation.

## Get a project's pull mirror details

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354506) in GitLab 15.6.

Returns the details of the project's pull mirror.

```plaintext
GET /projects/:id/mirror/pull
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

Example response:

```json
{
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git"
}
```

## Configure pull mirroring for a project

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Field `mirror_branch_regex` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 15.8 [with a flag](../administration/feature_flags.md) named `mirror_only_branches_match_regex`. Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/410354) in GitLab 16.2. Feature flag `mirror_only_branches_match_regex` removed.

Configure pull mirroring while [creating a new project](#create-project)
or [updating an existing project](#edit-project) using the API
if the remote repository is publicly accessible
or via `username:token` authentication.
In case your HTTP repository is not publicly accessible,
you can add the authentication information to the URL:
`https://username:token@gitlab.company.com/group/project.git`,
where `token` is a [personal access token](../user/profile/personal_access_tokens.md)
with the API scope enabled.

| Attribute                        | Type    | Required | Description |
|----------------------------------|---------|----------|-------------|
| `import_url`                     | string  | Yes      | URL of remote repository being mirrored (with `user:token` if needed). |
| `mirror`                         | boolean | Yes      | Enables pull mirroring on project when set to `true`. |
| `mirror_trigger_builds`          | boolean | No       | Trigger pipelines for mirror updates when set to `true`. |
| `only_mirror_protected_branches` | boolean | No       | Limits mirroring to only protected branches when set to `true`. |
| `mirror_branch_regex`            | String  | No       | Contains a regular expression. Only branches with names matching the regex are mirrored. Requires `only_mirror_protected_branches` to be disabled. |

Example creating a project with pull mirroring:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
 --header "Content-Type: application/json" \
 --data '{
  "name": "new_project",
  "namespace_id": "1",
  "mirror": true,
  "import_url": "https://username:token@gitlab.example.com/group/project.git"
 }' \
 --url "https://gitlab.example.com/api/v4/projects/"
```

Example adding pull mirroring:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
 --url "https://gitlab.example.com/api/v4/projects/:id" \
 --data "mirror=true&import_url=https://username:token@gitlab.example.com/group/project.git"
```

Example removing pull mirroring:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
 --url "https://gitlab.example.com/api/v4/projects/:id"  \
 --data "mirror=false"
```

## Start the pull mirroring process for a Project

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Moved to GitLab Premium in 13.9.

```plaintext
POST /projects/:id/mirror/pull
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

## Project badges

Read more in the [Project Badges](project_badges.md) documentation.

## Download snapshot of a Git repository

This endpoint may only be accessed by an administrative user.

Download a snapshot of the project (or wiki, if requested) Git repository. This
snapshot is always in uncompressed [tar](https://en.wikipedia.org/wiki/Tar_(computing))
format.

If a repository is corrupted to the point where `git clone` doesn't work, the
snapshot may allow some of the data to be retrieved.

```plaintext
GET /projects/:id/snapshot
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `wiki`    | boolean           | No       | Whether to download the wiki, rather than project, repository. |

## Get the path to repository storage

Get the path to repository storage for specified project if Gitaly Cluster is not being used. If Gitaly Cluster is being used, see
[Praefect-generated replica paths](../administration/gitaly/index.md#praefect-generated-replica-paths).

Available for administrators only.

```plaintext
GET /projects/:id/storage
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```json
[
  {
    "project_id": 1,
    "disk_path": "@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b",
    "created_at": "2012-10-12T17:04:47Z",
    "repository_storage": "default"
  }
]
```
