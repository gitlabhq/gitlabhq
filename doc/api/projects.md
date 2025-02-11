---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Projects API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The Projects API provides programmatic access to manage GitLab projects and configure their key settings. A project is a central hub for collaboration where you store code, track issues, and organize team activities.

The Projects API contains endpoints that:

- Retrieve project information and metadata
- Create, edit, and remove projects
- Control project visibility, access permissions, and security settings
- Manage project features like issue tracking, merge requests, and CI/CD
- Archive and unarchive projects
- Transfer projects between namespaces
- Manage deployment and container registry settings

This page explains how to use the Projects REST API endpoints to interact with [GitLab projects](../user/project/_index.md).

## Permissions

Users with:

- Any [default role](../user/permissions.md#roles) on a project can read the project's properties.
- The Owner or Maintainer role on a project can also edit the project's properties.

## Project visibility level

A project in GitLab can have a visibility level of either:

- Private
- Internal
- Public

The visibility level is determined by the `visibility` field in the project.

For more information, see [Project visibility](../user/public_access.md).

The fields returned in responses vary based on the [permissions](../user/permissions.md) of the authenticated user.

## Deprecated attributes

These attributes are deprecated and could be removed in a future version of the REST API.
Use the alternative attributes instead.

| Deprecated attribute     | Alternative |
|:-------------------------|:------------|
| `tag_list`               | `topics` attribute |
| `marked_for_deletion_at` | `marked_for_deletion_on`. Premium and Ultimate tier only. |
| `approvals_before_merge` | [Merge request approvals API](merge_request_approvals.md). Premium and Ultimate tier only. |

## Get a single project

Get a specific project. This endpoint can be accessed without authentication if
the project is publicly accessible.

```plaintext
GET /projects/:id
```

Supported attributes:

| Attribute                | Type              | Required | Description |
|:-------------------------|:------------------|:---------|:------------|
| `id`                     | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `license`                | boolean           | No       | Include project license data. |
| `statistics`             | boolean           | No       | Include project statistics. Available only to users with at least the Reporter role. |
| `with_custom_attributes` | boolean           | No       | Include [custom attributes](custom_attributes.md) in response. _(administrators only)_ |

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
  "allow_pipeline_trigger_approve_deployment": false,
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
  "marked_for_deletion_at": "2020-04-03", // Deprecated in favor of marked_for_deletion_on. Planned for removal in a future version of the REST API.
  "marked_for_deletion_on": "2020-04-03",
  "compliance_frameworks": [ "sox" ],
  "warn_about_potentially_unwanted_characters": true,
  "pre_receive_secret_detection_enabled": false,
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
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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

## List projects

List projects.

### List all projects

> - The `_links.cluster_agents` attribute in the response was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 15.0.

Get a list of all visible projects across GitLab for the authenticated user.
When accessed without authentication, only public projects with _simple_ fields
are returned.

```plaintext
GET /projects
```

Supported attributes:

| Attribute                     | Type     | Required | Description |
|:------------------------------|:---------|:---------|:------------|
| `archived`                    | boolean  | No       | Limit by archived status. |
| `id_after`                    | integer  | No       | Limit results to projects with IDs greater than the specified ID. |
| `id_before`                   | integer  | No       | Limit results to projects with IDs less than the specified ID. |
| `imported`                    | boolean  | No       | Limit results to projects which were imported from external systems by current user. |
| `include_hidden`              | boolean  | No       | Include hidden projects. _(administrators only)_ Premium and Ultimate only. |
| `include_pending_delete`      | boolean  | No       | Include projects pending deletion. _(administrators only)_ |
| `last_activity_after`         | datetime | No       | Limit results to projects with last activity after specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `last_activity_before`        | datetime | No       | Limit results to projects with last activity before specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `membership`                  | boolean  | No       | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer  | No       | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `order_by`                    | string   | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `star_count`, `last_activity_at`, or `similarity` fields. `repository_size`, `storage_size`, `packages_size` or `wiki_size` fields are only allowed for administrators. `similarity` is only available when searching and is limited to projects that the current user is a member of. Default is `created_at`. |
| `owned`                       | boolean  | No       | Limit by projects explicitly owned by the current user. |
| `repository_checksum_failed`  | boolean  | No       | Limit projects where the repository checksum calculation has failed. Premium and Ultimate only. |
| `repository_storage`          | string   | No       | Limit results to projects stored on `repository_storage`. _(administrators only)_ |
| `search_namespaces`           | boolean  | No       | Include ancestor namespaces when matching search criteria. Default is `false`. |
| `search`                      | string   | No       | Return list of projects with a `path`, `name`, or `description` matching the search criteria (case-insensitive, substring match). Multiple terms can be provided, separated by an escaped space, either `+` or `%20`, and will be ANDed together. Example: `one+two` will match substrings `one` and `two` (in any order). |
| `simple`                      | boolean  | No       | Return only limited fields for each project. This operation is a no-op without authentication where only simple fields are returned. |
| `sort`                        | string   | No       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean  | No       | Limit by projects starred by the current user. |
| `statistics`                  | boolean  | No       | Include project statistics. Available only to users with at least the Reporter role. |
| `topic_id`                    | integer  | No       | Limit results to projects with the assigned topic given by the topic ID. |
| `topic`                       | string   | No       | Comma-separated topic names. Limit results to projects that match all of given topics. See `topics` attribute. |
| `updated_after`               | datetime | No       | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. For this filter to work, you must also provide `updated_at` as the `order_by` attribute. |
| `updated_before`              | datetime | No       | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. For this filter to work, you must also provide `updated_at` as the `order_by` attribute. |
| `visibility`                  | string   | No       | Limit by visibility `public`, `internal`, or `private`. |
| `wiki_checksum_failed`        | boolean  | No       | Limit projects where the wiki checksum calculation has failed. Premium and Ultimate only. |
| `with_custom_attributes`      | boolean  | No       | Include [custom attributes](custom_attributes.md) in response. _(administrator only)_ |
| `with_issues_enabled`         | boolean  | No       | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean  | No       | Limit by enabled merge requests feature. |
| `with_programming_language`   | string   | No       | Limit by projects which use the given programming language. |
| `marked_for_deletion_on`      | date     | No       | Filter by date when project was marked for deletion. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/463939) in GitLab 17.1. Premium and Ultimate only. |

This endpoint supports [keyset pagination](rest/_index.md#keyset-based-pagination) for selected `order_by` options.

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

When the user is authenticated and `simple` is not set, this endpoint returns something like:

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
    "allow_pipeline_trigger_approve_deployment": false,
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
    "pre_receive_secret_detection_enabled": false,
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
`last_activity_at` is updated based on [project activity](../user/project/working_with_projects.md#view-project-activity)
and [project events](events.md). `updated_at` is updated whenever the project record is changed in the database.

You can filter by [custom attributes](custom_attributes.md) with:

```plaintext
GET /projects?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

Example request:

```shell
curl --globoff --request GET "https://gitlab.example.com/api/v4/projects?custom_attributes[location]=Antarctica&custom_attributes[role]=Developer"
```

#### Pagination limits

You can use [offset-based pagination](rest/_index.md#offset-based-pagination) to access
[up to 50,000 projects](https://gitlab.com/gitlab-org/gitlab/-/issues/34565).

Use [keyset pagination](rest/_index.md#keyset-based-pagination) to retrieve projects beyond this limit.
Keyset pagination supports only `order_by=id`. Other sorting options aren't available.

### List a user's projects

Get a list of visible projects owned by the given user. When accessed without
authentication, only public projects are returned.

Prerequisites:

- To view [certain attributes](https://gitlab.com/gitlab-org/gitlab/-/blob/520776fa8e5a11b8275b7c597d75246fcfc74c89/lib/api/entities/project.rb#L109-130), you must be an administrator or have the Owner role for the project.

NOTE:
Only the projects in the user's (specified in `user_id`) namespace are returned. Projects owned by the user in any group or subgroups are not returned. An empty list is returned if a profile is set to private.

This endpoint supports [keyset pagination](rest/_index.md#keyset-based-pagination)
for selected `order_by` options.

```plaintext
GET /users/:user_id/projects
```

Supported attributes:

| Attribute                     | Type     | Required | Description |
|:------------------------------|:---------|:---------|:------------|
| `user_id`                     | string   | Yes      | The ID or username of the user. |
| `archived`                    | boolean  | No       | Limit by archived status. |
| `id_after`                    | integer  | No       | Limit results to projects with IDs greater than the specified ID. |
| `id_before`                   | integer  | No       | Limit results to projects with IDs less than the specified ID. |
| `membership`                  | boolean  | No       | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer  | No       | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `order_by`                    | string   | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `star_count`, or `last_activity_at` fields. Default is `created_at`. |
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
    "allow_pipeline_trigger_approve_deployment": false,
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
    "pre_receive_secret_detection_enabled": false,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "marked_for_deletion_at": "2020-04-03", // Deprecated in favor of marked_for_deletion_on. Planned for removal in a future version of the REST API.
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
    "allow_pipeline_trigger_approve_deployment": false,
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
    "pre_receive_secret_detection_enabled": false,
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

### List projects a user has contributed to

Get a list of visible projects a given user has contributed to.

```plaintext
GET /users/:user_id/contributed_projects
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|:-----------|:--------|:---------|:------------|
| `user_id`  | string  | Yes      | The ID or username of the user. |
| `order_by` | string  | No       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `star_count`, or `last_activity_at` fields. Default is `created_at`. |
| `simple`   | boolean | No       | Return only limited fields for each project. Without authentication, this operation is a no-op; only simple fields are returned. |
| `sort`     | string  | No       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |

Example request:

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
    "allow_pipeline_trigger_approve_deployment": false,
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
    "pre_receive_secret_detection_enabled": false,
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
    "allow_pipeline_trigger_approve_deployment": false,
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
    "pre_receive_secret_detection_enabled": false,
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

### Search for projects by name

Search for projects by name that are accessible to the authenticated user. If this endpoint is accessed without
authentication, it lists projects that are publicly accessible.

```plaintext
GET /projects
```

Example attributes:

| Attribute  | Type   | Required | Description |
|:-----------|:-------|:---------|:------------|
| `search`   | string | Yes      | A string contained in the project name. |
| `order_by` | string | No       | Return requests ordered by `id`, `name`, `created_at`, `star_count`, or `last_activity_at` fields. |
| `sort`     | string | No       | Return requests sorted in `asc` or `desc` order. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects?search=test"
```

## List attributes

List attributes of a project.

### List users

Get the users list of a project.

```plaintext
GET /projects/:id/users
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|:-------------|:------------------|:---------|:------------|
| `id`         | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `search`     | string            | No       | Search for specific users. |
| `skip_users` | integer array     | No       | Filter out users with the specified IDs. |

Example response:

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

### List groups

Get a list of ancestor groups for this project.

```plaintext
GET /projects/:id/groups
```

Supported attributes:

| Attribute                 | Type              | Required | Description |
|:--------------------------|:------------------|:---------|:------------|
| `id`                      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `search`                  | string            | No       | Search for specific groups. |
| `shared_min_access_level` | integer           | No       | Limit to shared groups with at least this [role (`access_level`)](members.md#roles). |
| `shared_visible_only`     | boolean           | No       | Limit to shared groups user has access to. |
| `skip_groups`             | array of integers | No       | Skip the group IDs passed. |
| `with_shared`             | boolean           | No       | Include projects shared with this group. Default is `false`. |

Example response:

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

### List shareable groups

Get a list of groups that can be shared with a project

```plaintext
GET /projects/:id/share_locations
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `search`  | string            | No       | Search for specific groups. |

Example response:

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

### List a project's invited groups

Get a list of invited groups in a project. When accessed without authentication, only public invited groups are returned.
This endpoint is rate-limited to 60 requests per minute per:

- User for authenticated users.
- IP address for unauthenticated users.

By default, this request returns 20 results at a time because the API results [are paginated](rest/_index.md#pagination).

```plaintext
GET /projects/:id/invited_groups
```

Supported attributes:

| Attribute                | Type             | Required | Description |
|:-------------------------|:-----------------|:---------|:------------|
| `id`                     | integer/string   | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `search`                 | string           | no       | Return the list of authorized groups matching the search criteria |
| `min_access_level`       | integer          | no       | Limit to groups where current user has at least the specified [role (`access_level`)](members.md#roles) |
| `relation`               | array of strings | no       | Filter the groups by relation (direct or inherited) |
| `with_custom_attributes` | boolean          | no       | Include [custom attributes](custom_attributes.md) in response (administrators only) |

Example response:

```json
[
  {
    "id": 35,
    "web_url": "https://gitlab.example.com/groups/twitter",
    "name": "Twitter",
    "avatar_url": null,
    "full_name": "Twitter",
    "full_path": "twitter"
  }
]
```

### List programming languages used

Get the list and usage percentage of programming languages used in a project.

```plaintext
GET /projects/:id/languages
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

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

## Manage projects

Manage a project, including creation, deletion, and archival.

### Create a project

> - `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.
> - `model_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) in GitLab 16.7.

Creates a new project owned by the authenticated user.

If your HTTP repository isn't publicly accessible, add authentication information to the URL
`https://username:password@gitlab.company.com/group/project.git`, where `password` is a public access key with the `api`
scope enabled.

```plaintext
POST /projects
```

Supported general project attributes:

| Attribute                                          | Type    | Required                       | Description |
|:---------------------------------------------------|:--------|:-------------------------------|:------------|
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
| `merge_method`                                     | string  | No                             | Set the project's [merge method](../user/project/merge_requests/methods/_index.md). Can be `merge` (merge commit), `rebase_merge` (merge commit with semi-linear history), or `ff` (fast-forward merge). |
| `merge_pipelines_enabled`                          | boolean | No                             | Enable or disable merged results pipelines. |
| `merge_requests_enabled`                           | boolean | No                             | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `merge_trains_enabled`                             | boolean | No                             | Enable or disable merge trains. |
| `merge_trains_skip_train_allowed`                  | boolean | No                             | Allows merge train merge requests to be merged without waiting for pipelines to finish. |
| `mirror_trigger_builds`                            | boolean | No                             | Pull mirroring triggers builds. Premium and Ultimate only. |
| `mirror`                                           | boolean | No                             | Enables pull mirroring in a project. Premium and Ultimate only. |
| `namespace_id`                                     | integer | No                             | Namespace for the new project. Specify a group ID or subgroup ID. If not provided, defaults to the current user's personal namespace. |
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
| `shared_runners_enabled`                           | boolean | No                             | Enable instance runners for this project. |
| `show_default_award_emojis`                        | boolean | No                             | Show default emoji reactions. |
| `snippets_enabled`                                 | boolean | No                             | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `squash_option`                                    | string  | No                             | One of `never`, `always`, `default_on`, or `default_off`. |
| `tag_list`                                         | array   | No                             | The list of tags for a project; put array of tags, that should be finally assigned to a project. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0. Use `topics` instead. |
| `template_name`                                    | string  | No                             | When used without `use_custom_template`, name of a [built-in project template](../user/project/_index.md#create-a-project-from-a-built-in-template). When used with `use_custom_template`, name of a custom project template. |
| `template_project_id`                              | integer | No                             | When used with `use_custom_template`, project ID of a custom project template. Using a project ID is preferable to using `template_name` because `template_name` can be ambiguous. Premium and Ultimate only. |
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
- `public`: Enable and set the feature to **Everyone**. Only available for `pages_access_level`.

| Attribute                              | Type   | Required | Description |
|:---------------------------------------|:-------|:---------|:------------|
| `analytics_access_level`               | string | No       | Set visibility of [analytics](../user/analytics/_index.md). |
| `builds_access_level`                  | string | No       | Set visibility of [pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines). |
| `container_registry_access_level`      | string | No       | Set visibility of [container registry](../user/packages/container_registry/_index.md#change-visibility-of-the-container-registry). |
| `environments_access_level`            | string | No       | Set visibility of [environments](../ci/environments/_index.md). |
| `feature_flags_access_level`           | string | No       | Set visibility of [feature flags](../operations/feature_flags.md). |
| `forking_access_level`                 | string | No       | Set visibility of [forks](../user/project/repository/forking_workflow.md). |
| `infrastructure_access_level`          | string | No       | Set visibility of [infrastructure management](../user/infrastructure/_index.md). |
| `issues_access_level`                  | string | No       | Set visibility of [issues](../user/project/issues/_index.md). |
| `merge_requests_access_level`          | string | No       | Set visibility of [merge requests](../user/project/merge_requests/_index.md). |
| `model_experiments_access_level`       | string | No       | Set visibility of [machine learning model experiments](../user/project/ml/experiment_tracking/_index.md). |
| `model_registry_access_level`          | string | No       | Set visibility of [machine learning model registry](../user/project/ml/model_registry/_index.md#access-the-model-registry). |
| `monitor_access_level`                 | string | No       | Set visibility of [application performance monitoring](../operations/_index.md). |
| `pages_access_level`                   | string | No       | Set visibility of [GitLab Pages](../user/project/pages/pages_access_control.md). |
| `releases_access_level`                | string | No       | Set visibility of [releases](../user/project/releases/_index.md). |
| `repository_access_level`              | string | No       | Set visibility of [repository](../user/project/repository/_index.md). |
| `requirements_access_level`            | string | No       | Set visibility of [requirements management](../user/project/requirements/_index.md). |
| `security_and_compliance_access_level` | string | No       | Set visibility of [security and compliance](../user/application_security/_index.md). |
| `snippets_access_level`                | string | No       | Set visibility of [snippets](../user/snippets.md#change-default-visibility-of-snippets). |
| `wiki_access_level`                    | string | No       | Set visibility of [wiki](../user/project/wiki/_index.md#enable-or-disable-a-project-wiki). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your-token>" \
     --header "Content-Type: application/json" --data '{
        "name": "new_project", "description": "New Project", "path": "new_project",
        "namespace_id": "42", "initialize_with_readme": "true"}' \
     --url "https://gitlab.example.com/api/v4/projects/"
```

### Create a project for a user

> - `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.
> - `model_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) in GitLab 16.7.

Create a project for a user.

Prerequisites:

- You must be an administrator.

If your HTTP repository isn't publicly accessible, add authentication information to the URL. For example,
`https://username:password@gitlab.company.com/group/project.git` where `password` is a public access key with the `api`
scope enabled.

```plaintext
POST /projects/user/:user_id
```

Supported general project attributes:

| Attribute                                          | Type    | Required | Description |
|:---------------------------------------------------|:--------|:---------|:------------|
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
| `merge_method`                                     | string  | No       | Set the project's [merge method](../user/project/merge_requests/methods/_index.md). Can be `merge` (merge commit), `rebase_merge` (merge commit with semi-linear history), or `ff` (fast-forward merge). |
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
| `shared_runners_enabled`                           | boolean | No       | Enable instance runners for this project. |
| `show_default_award_emojis`                        | boolean | No       | Show default emoji reactions. |
| `snippets_enabled`                                 | boolean | No       | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `squash_commit_template`                           | string  | No       | [Template](../user/project/merge_requests/commit_templates.md) used to create squash commit message in merge requests. |
| `squash_option`                                    | string  | No       | One of `never`, `always`, `default_on`, or `default_off`. |
| `suggestion_commit_message`                        | string  | No       | The commit message used to apply merge request [suggestions](../user/project/merge_requests/reviews/suggestions.md). |
| `tag_list`                                         | array   | No       | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `template_name`                                    | string  | No       | When used without `use_custom_template`, name of a [built-in project template](../user/project/_index.md#create-a-project-from-a-built-in-template). When used with `use_custom_template`, name of a custom project template. |
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
- `public`: Enable and set the feature to **Everyone**. Only available for `pages_access_level`.

| Attribute                              | Type   | Required | Description |
|:---------------------------------------|:-------|:---------|:------------|
| `analytics_access_level`               | string | No       | Set visibility of [analytics](../user/analytics/_index.md). |
| `builds_access_level`                  | string | No       | Set visibility of [pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines). |
| `container_registry_access_level`      | string | No       | Set visibility of [container registry](../user/packages/container_registry/_index.md#change-visibility-of-the-container-registry). |
| `environments_access_level`            | string | No       | Set visibility of [environments](../ci/environments/_index.md). |
| `feature_flags_access_level`           | string | No       | Set visibility of [feature flags](../operations/feature_flags.md). |
| `forking_access_level`                 | string | No       | Set visibility of [forks](../user/project/repository/forking_workflow.md). |
| `infrastructure_access_level`          | string | No       | Set visibility of [infrastructure management](../user/infrastructure/_index.md). |
| `issues_access_level`                  | string | No       | Set visibility of [issues](../user/project/issues/_index.md). |
| `merge_requests_access_level`          | string | No       | Set visibility of [merge requests](../user/project/merge_requests/_index.md). |
| `model_experiments_access_level`       | string | No       | Set visibility of [machine learning model experiments](../user/project/ml/experiment_tracking/_index.md). |
| `model_registry_access_level`          | string | No       | Set visibility of [machine learning model registry](../user/project/ml/model_registry/_index.md#access-the-model-registry). |
| `monitor_access_level`                 | string | No       | Set visibility of [application performance monitoring](../operations/_index.md). |
| `pages_access_level`                   | string | No       | Set visibility of [GitLab Pages](../user/project/pages/pages_access_control.md). |
| `releases_access_level`                | string | No       | Set visibility of [releases](../user/project/releases/_index.md). |
| `repository_access_level`              | string | No       | Set visibility of [repository](../user/project/repository/_index.md). |
| `requirements_access_level`            | string | No       | Set visibility of [requirements management](../user/project/requirements/_index.md). |
| `security_and_compliance_access_level` | string | No       | Set visibility of [security and compliance](../user/application_security/_index.md). |
| `snippets_access_level`                | string | No       | Set visibility of [snippets](../user/snippets.md#change-default-visibility-of-snippets). |
| `wiki_access_level`                    | string | No       | Set visibility of [wiki](../user/project/wiki/_index.md#enable-or-disable-a-project-wiki). |

### Edit a project

> - `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.
> - `model_registry_access_level` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/412734) in GitLab 16.7.

Update an existing project.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
PUT /projects/:id
```

Supported general project attributes:

| Attribute                                          | Type              | Required | Description |
|:---------------------------------------------------|:------------------|:---------|:------------|
| `id`                                               | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
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
| `ci_delete_pipelines_in_seconds`                   | integer           | No       | Pipelines older than the configured time are deleted. |
| `ci_forward_deployment_enabled`                    | boolean           | No       | Enable or disable [prevent outdated deployment jobs](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs). |
| `ci_forward_deployment_rollback_allowed`           | boolean           | No       | Enable or disable [allow job retries for rollback deployments](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs). |
| `ci_allow_fork_pipelines_to_run_in_parent_project` | boolean           | No       | Enable or disable [running pipelines in the parent project for merge requests from forks](../ci/pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project). _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325189) in GitLab 15.3.)_ |
| `ci_separated_caches`                              | boolean           | No       | Set whether or not caches should be [separated](../ci/caching/_index.md#cache-key-names) by branch protection status. |
| `ci_restrict_pipeline_cancellation_role`           | string            | No       | Set the [role required to cancel a pipeline or job](../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs). One of `developer`, `maintainer`, or `no_one`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429921) in GitLab 16.8. Premium and Ultimate only. |
| `ci_pipeline_variables_minimum_override_role`      | string            | No       | When `restrict_user_defined_variables` is enabled, you can specify which role can override variables. One of `owner`, `maintainer`, `developer` or `no_one_allowed`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440338) in GitLab 17.1. |
| `ci_push_repository_for_job_token_allowed`         | boolean           | No       | Enable or disable the ability to push to the project repository using job token. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/389060) in GitLab 17.2. |
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
| `max_artifacts_size`                               | integer           | No       | The maximum file size in megabytes for individual job artifacts. |
| `merge_commit_template`                            | string            | No       | [Template](../user/project/merge_requests/commit_templates.md) used to create merge commit message in merge requests. |
| `merge_method`                                     | string            | No       | Set the project's [merge method](../user/project/merge_requests/methods/_index.md). Can be `merge` (merge commit), `rebase_merge` (merge commit with semi-linear history), or `ff` (fast-forward merge). |
| `merge_pipelines_enabled`                          | boolean           | No       | Enable or disable merged results pipelines. |
| `merge_requests_enabled`                           | boolean           | No       | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `merge_requests_template`                          | string            | No       | Default description for merge requests. Description is parsed with GitLab Flavored Markdown. See [Templates for issues and merge requests](#templates-for-issues-and-merge-requests). Premium and Ultimate only. |
| `merge_trains_enabled`                             | boolean           | No       | Enable or disable merge trains. |
| `merge_trains_skip_train_allowed`                  | boolean           | No       | Allows merge train merge requests to be merged without waiting for pipelines to finish. |
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
| `shared_runners_enabled`                           | boolean           | No       | Enable instance runners for this project. |
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

For example, to toggle the setting for [instance runners on a GitLab.com project](../ci/runners/_index.md):

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your-token>" \
     --url "https://gitlab.com/api/v4/projects/<your-project-ID>" \
     --data "shared_runners_enabled=true" # to turn off: "shared_runners_enabled=false"
```

[Project feature visibility](../user/public_access.md#change-the-visibility-of-individual-features-in-a-project)
settings with access control options can be one of:

- `disabled`: Disable the feature.
- `private`: Enable and set the feature to **Only project members**.
- `enabled`: Enable and set the feature to **Everyone with access**.
- `public`: Enable and set the feature to **Everyone**. Only available for `pages_access_level`.

Supported project visibility attributes:

| Attribute                              | Type   | Required | Description |
|:---------------------------------------|:-------|:---------|:------------|
| `analytics_access_level`               | string | No       | Set visibility of [analytics](../user/analytics/_index.md). |
| `builds_access_level`                  | string | No       | Set visibility of [pipelines](../ci/pipelines/settings.md#change-which-users-can-view-your-pipelines). |
| `container_registry_access_level`      | string | No       | Set visibility of [container registry](../user/packages/container_registry/_index.md#change-visibility-of-the-container-registry). |
| `environments_access_level`            | string | No       | Set visibility of [environments](../ci/environments/_index.md). |
| `feature_flags_access_level`           | string | No       | Set visibility of [feature flags](../operations/feature_flags.md). |
| `forking_access_level`                 | string | No       | Set visibility of [forks](../user/project/repository/forking_workflow.md). |
| `infrastructure_access_level`          | string | No       | Set visibility of [infrastructure management](../user/infrastructure/_index.md). |
| `issues_access_level`                  | string | No       | Set visibility of [issues](../user/project/issues/_index.md). |
| `merge_requests_access_level`          | string | No       | Set visibility of [merge requests](../user/project/merge_requests/_index.md). |
| `model_experiments_access_level`       | string | No       | Set visibility of [machine learning model experiments](../user/project/ml/experiment_tracking/_index.md). |
| `model_registry_access_level`          | string | No       | Set visibility of [machine learning model registry](../user/project/ml/model_registry/_index.md#access-the-model-registry). |
| `monitor_access_level`                 | string | No       | Set visibility of [application performance monitoring](../operations/_index.md). |
| `pages_access_level`                   | string | No       | Set visibility of [GitLab Pages](../user/project/pages/pages_access_control.md). |
| `releases_access_level`                | string | No       | Set visibility of [releases](../user/project/releases/_index.md). |
| `repository_access_level`              | string | No       | Set visibility of [repository](../user/project/repository/_index.md). |
| `requirements_access_level`            | string | No       | Set visibility of [requirements management](../user/project/requirements/_index.md). |
| `security_and_compliance_access_level` | string | No       | Set visibility of [security and compliance](../user/application_security/_index.md). |
| `snippets_access_level`                | string | No       | Set visibility of [snippets](../user/snippets.md#change-default-visibility-of-snippets). |
| `wiki_access_level`                    | string | No       | Set visibility of [wiki](../user/project/wiki/_index.md#enable-or-disable-a-project-wiki). |

### Import members

Import members from another project.

If the importing member's role for the target project is:

- Maintainer, then members with the Owner role for the source project are imported with the Maintainer role.
- Owner, then members with the Owner role for the source project are imported with the Owner role.

```plaintext
POST /projects/:id/import_project_members/:project_id
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|:-------------|:------------------|:---------|:------------|
| `id`         | integer or string | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the target project to receive the members. |
| `project_id` | integer or string | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the source project to import the members from. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/import_project_members/32"
```

Returns:

- `200 OK` on success.
- `404 Project Not Found` if the target or source project does not exist or cannot be accessed by the requester.
- `422 Unprocessable Entity` if the import of project members does not complete successfully.

Example responses:

- When all emails were successfully sent (`200` HTTP status code):

  ```json
  {  "status":  "success"  }
  ```

- When there was any error importing 1 or more members (`200` HTTP status code):

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

- When there is a system error (`404` and `422` HTTP status codes):

```json
{  "message":  "Import failed"  }
```

### Archive a project

Archive a project.

Prerequisites:

- You must be an administrator or be assigned the Owner role on the project.

This endpoint is idempotent. Archiving an already-archived project does not change the project.

```plaintext
POST /projects/:id/archive
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

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
  "allow_pipeline_trigger_approve_deployment": false,
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
  "pre_receive_secret_detection_enabled": false,
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

### Unarchive a project

Unarchive a project.

Prerequisites:

- You must be an administrator or be assigned the Owner role on the project.

This endpoint is idempotent. Unarchiving a project that isn't archived doesn't change the project.

```plaintext
POST /projects/:id/unarchive
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

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
  "allow_pipeline_trigger_approve_deployment": false,
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
  "pre_receive_secret_detection_enabled": false,
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

### Delete a project

Delete a project. This endpoint:

- Deletes a project including all associated resources, including issues and merge requests.
- On [Premium or Ultimate](https://about.gitlab.com/pricing/) tiers,
  [delayed project deletion](../user/project/working_with_projects.md#delayed-project-deletion)
  is applied if enabled.
- From [GitLab 15.11](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) on
  [Premium or Ultimate](https://about.gitlab.com/pricing/) tiers, deletes a project immediately if:
  - The project is already marked for deletion.
  - The `permanently_remove` and `full_path` parameters are passed.
- From [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) on
  [Premium or Ultimate](https://about.gitlab.com/pricing/) tiers, delayed project deletion is enabled by default.
  The deletion happens after the number of days specified in the
  [default deletion delay](../administration/settings/visibility_and_access_controls.md#deletion-protection).

WARNING:
The option to delete projects immediately from deletion protection settings in the **Admin** area was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) in GitLab 15.9 and removed in GitLab 16.0.

```plaintext
DELETE /projects/:id
```

Supported attributes:

| Attribute            | Type              | Required | Description |
|:---------------------|:------------------|:---------|:------------|
| `id`                 | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `full_path`          | string            | no       | Full path of project to use with `permanently_remove`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) in GitLab 15.11. To find the project path, use `path_with_namespace` from [get single project](projects.md#get-a-single-project). Premium and Ultimate only. |
| `permanently_remove` | boolean/string    | no       | Immediately deletes a project if it is marked for deletion. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) in GitLab 15.11. Premium and Ultimate only. |

### Restore a project marked for deletion

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Restore a project that is marked for deletion.

```plaintext
POST /projects/:id/restore
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

### Transfer a project to a new namespace

Transfer a project to a new namespace.

For information on prerequisites for transferring a project, see
[Transfer a project to another namespace](../user/project/settings/migrate_projects.md#transfer-a-project-to-another-namespace).

```plaintext
PUT /projects/:id/transfer
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|:------------|:------------------|:---------|:------------|
| `id`        | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
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
  "allow_pipeline_trigger_approve_deployment": false,
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
  "warn_about_potentially_unwanted_characters": true,
  "pre_receive_secret_detection_enabled": false
}
```

#### List groups available for project transfer

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371006) in GitLab 15.4

Retrieve a list of groups to which the user can transfer a project.

```plaintext
GET /projects/:id/transfer_locations
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
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

### Upload a project avatar

Upload an avatar to the specified project.

```plaintext
PUT /projects/:id
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `avatar`  | string            | Yes      | The file to be uploaded. |
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

To upload an avatar from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to an image file on your file system and be
preceded by `@`. For example:

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "avatar=@dk.png" "https://gitlab.example.com/api/v4/projects/5"
```

Example response:

```json
{
  "avatar_url": "https://gitlab.example.com/uploads/-/system/project/avatar/2/dk.png"
}
```

### Download a project avatar

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144039) in GitLab 16.9.

Download a project avatar. You can access this endpoint without authentication if the project is publicly accessible.

```plaintext
GET /projects/:id/avatar
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/4/avatar"
```

### Remove a project avatar

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92604) in GitLab 15.4.

To remove a project avatar, use a blank value for the `avatar` attribute.

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "avatar=" "https://gitlab.example.com/api/v4/projects/5"
```

## Share projects

Share a project with a group.

### Share a project with a group

Share a project with a group.

```plaintext
POST /projects/:id/share
```

Supported attributes:

| Attribute      | Type              | Required | Description |
|:---------------|:------------------|:---------|:------------|
| `group_access` | integer           | Yes      | The [role (`access_level`)](members.md#roles) to grant the group. |
| `group_id`     | integer           | Yes      | The ID of the group to share with. |
| `id`           | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `expires_at`   | string            | No       | Share expiration date in ISO 8601 format. For example, `2016-09-26`. |

### Delete a shared project link in a group

Unshare the project from the group. Returns `204` and no content on success.

```plaintext
DELETE /projects/:id/share/:group_id
```

Supported attributes:

| Attribute  | Type              | Required | Description |
|:-----------|:------------------|:---------|:------------|
| `group_id` | integer           | Yes      | The ID of the group. |
| `id`       | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/share/17"
```

## Start the housekeeping task for a project

Start the [housekeeping task](../administration/housekeeping.md) for a project.

```plaintext
POST /projects/:id/housekeeping
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `task`    | string            | No       | `prune` to trigger manual prune of unreachable objects or `eager` to trigger eager housekeeping. |

## Real-time security scan

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/479210) in GitLab 17.6. This feature is an [experiment](../policy/development_stages_support.md).

Returns SAST scan results for a single file in real-time.

```plaintext
POST /projects/:id/security_scans/sast/scan
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
 --header "Content-Type: application/json" \
 --data '{
  "file_path":"src/main.c",
  "content":"#include<string.h>\nint main(int argc, char **argv) {\n  char buff[128];\n  strcpy(buff, argv[1]);\n  return 0;\n}\n"
 }' \
 --url "https://gitlab.example.com/api/v4/projects/:id/security_scans/sast/scan"
```

Example response:

```json
{
  "vulnerabilities": [
    {
      "name": "Insecure string processing function (strcpy)",
      "description": "The `strcpy` family of functions do not provide the ability to limit or check buffer\nsizes before copying to a destination buffer. This can lead to buffer overflows. Consider\nusing more secure alternatives such as `strncpy` and provide the correct limit to the\ndestination buffer and ensure the string is null terminated.\n\nFor more information please see: https://linux.die.net/man/3/strncpy\n\nIf developing for C Runtime Library (CRT), more secure versions of these functions should be\nused, see:\nhttps://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/strncpy-s-strncpy-s-l-wcsncpy-s-wcsncpy-s-l-mbsncpy-s-mbsncpy-s-l?view=msvc-170\n",
      "severity": "High",
      "location": {
        "file": "src/main.c",
        "start_line": 5,
        "end_line": 5,
        "start_column": 3,
        "end_column": 23
      }
    }
  ]
}
```

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

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `wiki`    | boolean           | No       | Whether to download the wiki, rather than project, repository. |

## Get the path to repository storage

Get the path to repository storage for specified project if Gitaly Cluster is not being used. If Gitaly Cluster is being used, see
[Praefect-generated replica paths](../administration/gitaly/_index.md#praefect-generated-replica-paths).

Available for administrators only.

```plaintext
GET /projects/:id/storage
```

Supported attributes:

| Attribute | Type              | Required | Description |
|:----------|:------------------|:---------|:------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

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

## Secret push protection status

DETAILS:
**Tier:** Ultimate

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160960) in GitLab 17.3.

If you have at least the Developer role, the following requests could also return the `pre_receive_secret_detection_enabled` value.
Note that some of these requests have stricter requirements about roles. Refer to the endpoints above for clarification.
Use this information to determine whether secret push protection is enabled for a project.
To modify the `pre_receive_secret_detection_enabled` value, please use the [Project Security Settings API](project_security_settings.md).

- `GET /projects`
- `GET /projects/:id`
- `GET /users/:user_id/projects`
- `GET /users/:user_id/contributed_projects`
- `PUT /projects/:project_id/transfer?namespace=:namespace_id`
- `PUT /projects/:id`
- `POST /projects`
- `POST /projects/user/:user_id`
- `POST /projects/:id/archive`
- `POST /projects/:id/unarchive`

Example response:

```json
{
  "id": 1,
  "project_id": 3,
  "pre_receive_secret_detection_enabled": true,
  ...
}
```
