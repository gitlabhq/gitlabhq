---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Projects API **(FREE)**

Interact with [projects](../user/project/index.md) using the REST API.

## Project visibility level

Project in GitLab can be either private, internal or public.
This is determined by the `visibility` field in the project.

Values for the project visibility level are:

- `private`: project access must be granted explicitly for each user.
- `internal`: the project can be cloned by any signed-in user except [external users](../user/permissions.md#external-users).
- `public`: the project can be accessed without any authentication.

## Project merge method

There are three options for `merge_method` to choose from:

- `merge`: a merge commit is created for every merge, and merging is allowed if
  there are no conflicts.
- `rebase_merge`: a merge commit is created for every merge, but merging is only
  allowed if fast-forward merge is possible. This way you could make sure that
  if this merge request would build, after merging to target branch it would
  also build.
- `ff`: no merge commits are created and all merges are fast-forwarded, which
  means that merging is only allowed if the branch could be fast-forwarded.

## List all projects

Get a list of all visible projects across GitLab for the authenticated user.
When accessed without authentication, only public projects with _simple_ fields
are returned.

```plaintext
GET /projects
```

| Attribute                                  | Type     | Required               | Description |
|--------------------------------------------|----------|------------------------|-------------|
| `archived`                                 | boolean  | **{dotted-circle}** No | Limit by archived status. |
| `id_after`                                 | integer  | **{dotted-circle}** No | Limit results to projects with IDs greater than the specified ID. |
| `id_before`                                | integer  | **{dotted-circle}** No | Limit results to projects with IDs less than the specified ID. |
| `last_activity_after`                      | datetime | **{dotted-circle}** No | Limit results to projects with last_activity after specified time. Format: ISO 8601 `YYYY-MM-DDTHH:MM:SSZ` |
| `last_activity_before`                     | datetime | **{dotted-circle}** No | Limit results to projects with last_activity before specified time. Format: ISO 8601 `YYYY-MM-DDTHH:MM:SSZ` |
| `membership`                               | boolean  | **{dotted-circle}** No | Limit by projects that the current user is a member of. |
| `min_access_level`                         | integer  | **{dotted-circle}** No | Limit by current user minimal [access level](members.md#valid-access-levels). |
| `order_by`                                 | string   | **{dotted-circle}** No | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. `repository_size`, `storage_size`, `packages_size` or `wiki_size` fields are only allowed for admins. Default is `created_at`. |
| `owned`                                    | boolean  | **{dotted-circle}** No | Limit by projects explicitly owned by the current user. |
| `repository_checksum_failed` **(PREMIUM)** | boolean  | **{dotted-circle}** No | Limit projects where the repository checksum calculation has failed ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6137) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.2). |
| `repository_storage`                       | string   | **{dotted-circle}** No | Limit results to projects stored on `repository_storage`. _(admins only)_ |
| `search_namespaces`                        | boolean  | **{dotted-circle}** No | Include ancestor namespaces when matching search criteria. Default is `false`. |
| `search`                                   | string   | **{dotted-circle}** No | Return list of projects matching the search criteria. |
| `simple`                                   | boolean  | **{dotted-circle}** No | Return only limited fields for each project. This is a no-op without authentication as then _only_ simple fields are returned. |
| `sort`                                     | string   | **{dotted-circle}** No | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                                  | boolean  | **{dotted-circle}** No | Limit by projects starred by the current user. |
| `statistics`                               | boolean  | **{dotted-circle}** No | Include project statistics. |
| `topic`                                    | string   | **{dotted-circle}** No | Comma-separated topic names. Limit results to projects that match all of given topics. See `topics` attribute. |
| `visibility`                               | string   | **{dotted-circle}** No | Limit by visibility `public`, `internal`, or `private`. |
| `wiki_checksum_failed` **(PREMIUM)**       | boolean  | **{dotted-circle}** No | Limit projects where the wiki checksum calculation has failed ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/6137) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.2). |
| `with_custom_attributes`                   | boolean  | **{dotted-circle}** No | Include [custom attributes](custom_attributes.md) in response. _(admins only)_ |
| `with_issues_enabled`                      | boolean  | **{dotted-circle}** No | Limit by enabled issues feature. |
| `with_merge_requests_enabled`              | boolean  | **{dotted-circle}** No | Limit by enabled merge requests feature. |
| `with_programming_language`                | string   | **{dotted-circle}** No | Limit by projects which use the given programming language. |

This endpoint supports [keyset pagination](index.md#keyset-based-pagination)
for selected `order_by` options.

When `simple=true` or the user is unauthenticated this returns something like:

```json
[
  {
    "id": 4,
    "description": null,
    "default_branch": "master",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/master/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "forks_count": 0,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "star_count": 0
  },
  {
    "id": 6,
    "description": null,
    "default_branch": "master",
...
```

When the user is authenticated and `simple` is not set this returns something like:

```json
[
  {
    "id": 4,
    "description": null,
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/master/README.md",
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
    "container_registry_enabled": false,
    "created_at": "2013-09-30T13:46:02Z",
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
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 50,
    "ci_forward_deployment_enabled": true,
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
    "suggestion_commit_message": null,
    "marked_for_deletion_at": "2020-04-03", // Deprecated and will be removed in API v5 in favor of marked_for_deletion_on
    "marked_for_deletion_on": "2020-04-03",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members"
    }
  },
  {
    "id": 6,
    "description": null,
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/master/README.md",
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
    "container_registry_enabled": false,
    "created_at": "2013-09-30T13:46:02Z",
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
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 0,
    "ci_forward_deployment_enabled": true,
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
    "approvals_before_merge": 0,
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
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members"
    }
  }
]
```

NOTE:
The `tag_list` attribute has been deprecated
and is removed in API v5 in favor of the `topics` attribute.

NOTE:
For users of [GitLab Premium or higher](https://about.gitlab.com/pricing/),
the `marked_for_deletion_at` attribute has been deprecated, and is removed
in API v5 in favor of the `marked_for_deletion_on` attribute.

Users of [GitLab Premium or higher](https://about.gitlab.com/pricing/)
can also see the `approvals_before_merge` parameter:

```json
[
  {
    "id": 4,
    "description": null,
    "approvals_before_merge": 0,
    ...
  }
]
```

You can filter by [custom attributes](custom_attributes.md) with:

```plaintext
GET /projects?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

### Pagination limits

In GitLab 13.0 and later, [offset-based pagination](index.md#offset-based-pagination)
is [limited to 50,000 records](https://gitlab.com/gitlab-org/gitlab/-/issues/34565).
[Keyset pagination](index.md#keyset-based-pagination) is required to retrieve
projects beyond this limit.

Keyset pagination supports only `order_by=id`. Other sorting options aren't available.

## List user projects

Get a list of visible projects owned by the given user. When accessed without
authentication, only public projects are returned.

This endpoint supports [keyset pagination](index.md#keyset-based-pagination)
for selected `order_by` options.

```plaintext
GET /users/:user_id/projects
```

| Attribute                     | Type    | Required               | Description |
|-------------------------------|---------|------------------------|-------------|
| `archived`                    | boolean | **{dotted-circle}** No | Limit by archived status. |
| `id_after`                    | integer | **{dotted-circle}** No | Limit results to projects with IDs greater than the specified ID. |
| `id_before`                   | integer | **{dotted-circle}** No | Limit results to projects with IDs less than the specified ID. |
| `membership`                  | boolean | **{dotted-circle}** No | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer | **{dotted-circle}** No | Limit by current user minimal [access level](members.md#valid-access-levels). |
| `order_by`                    | string  | **{dotted-circle}** No | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `owned`                       | boolean | **{dotted-circle}** No | Limit by projects explicitly owned by the current user. |
| `search`                      | string  | **{dotted-circle}** No | Return list of projects matching the search criteria. |
| `simple`                      | boolean | **{dotted-circle}** No | Return only limited fields for each project. This is a no-op without authentication as then _only_ simple fields are returned. |
| `sort`                        | string  | **{dotted-circle}** No | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean | **{dotted-circle}** No | Limit by projects starred by the current user. |
| `statistics`                  | boolean | **{dotted-circle}** No | Include project statistics. |
| `user_id`                     | string  | **{check-circle}** Yes | The ID or username of the user. |
| `visibility`                  | string  | **{dotted-circle}** No | Limit by visibility `public`, `internal`, or `private`. |
| `with_custom_attributes`      | boolean | **{dotted-circle}** No | Include [custom attributes](custom_attributes.md) in response. _(admins only)_ |
| `with_issues_enabled`         | boolean | **{dotted-circle}** No | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean | **{dotted-circle}** No | Limit by enabled merge requests feature. |
| `with_programming_language`   | string  | **{dotted-circle}** No | Limit by projects which use the given programming language. |

```json
[
  {
    "id": 4,
    "description": null,
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/master/README.md",
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
    "container_registry_enabled": false,
    "created_at": "2013-09-30T13:46:02Z",
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
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 50,
    "ci_forward_deployment_enabled": true,
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
    "suggestion_commit_message": null,
    "marked_for_deletion_at": "2020-04-03", // Deprecated and will be removed in API v5 in favor of marked_for_deletion_on
    "marked_for_deletion_on": "2020-04-03",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members"
    }
  },
  {
    "id": 6,
    "description": null,
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/master/README.md",
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
    "container_registry_enabled": false,
    "created_at": "2013-09-30T13:46:02Z",
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
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 0,
    "ci_forward_deployment_enabled": true,
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
    "approvals_before_merge": 0,
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
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members"
    }
  }
]
```

## List projects starred by a user

Get a list of visible projects owned by the given user. When accessed without
authentication, only public projects are returned.

```plaintext
GET /users/:user_id/starred_projects
```

| Attribute                     | Type    | Required               | Description |
|-------------------------------|---------|------------------------|-------------|
| `archived`                    | boolean | **{dotted-circle}** No | Limit by archived status. |
| `membership`                  | boolean | **{dotted-circle}** No | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer | **{dotted-circle}** No | Limit by current user minimal [access level](members.md#valid-access-levels). |
| `order_by`                    | string  | **{dotted-circle}** No | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `owned`                       | boolean | **{dotted-circle}** No | Limit by projects explicitly owned by the current user. |
| `search`                      | string  | **{dotted-circle}** No | Return list of projects matching the search criteria. |
| `simple`                      | boolean | **{dotted-circle}** No | Return only limited fields for each project. This is a no-op without authentication as then _only_ simple fields are returned.. |
| `sort`                        | string  | **{dotted-circle}** No | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean | **{dotted-circle}** No | Limit by projects starred by the current user. |
| `statistics`                  | boolean | **{dotted-circle}** No | Include project statistics. |
| `user_id`                     | string  | **{check-circle}** Yes | The ID or username of the user. |
| `visibility`                  | string  | **{dotted-circle}** No | Limit by visibility `public`, `internal`, or `private`. |
| `with_custom_attributes`      | boolean | **{dotted-circle}** No | Include [custom attributes](custom_attributes.md) in response. _(admins only)_ |
| `with_issues_enabled`         | boolean | **{dotted-circle}** No | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean | **{dotted-circle}** No | Limit by enabled merge requests feature. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/5/starred_projects"
```

Example response:

```json
[
  {
    "id": 4,
    "description": null,
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/master/README.md",
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
    "container_registry_enabled": false,
    "created_at": "2013-09-30T13:46:02Z",
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
    "suggestion_commit_message": null,
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members"
    }
  },
  {
    "id": 6,
    "description": null,
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/master/README.md",
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
    "container_registry_enabled": false,
    "created_at": "2013-09-30T13:46:02Z",
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
    "approvals_before_merge": 0,
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
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members"
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

| Attribute                | Type           | Required               | Description |
|--------------------------|----------------|------------------------|-------------|
| `id`                     | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `license`                | boolean        | **{dotted-circle}** No | Include project license data. |
| `statistics`             | boolean        | **{dotted-circle}** No | Include project statistics. |
| `with_custom_attributes` | boolean        | **{dotted-circle}** No | Include [custom attributes](custom_attributes.md) in response. _(admins only)_ |

```json
{
  "id": 3,
  "description": null,
  "default_branch": "master",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
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
  "container_registry_enabled": false,
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
  "license_url": "http://example.com/diaspora/diaspora-client/blob/master/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
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
  "approvals_before_merge": 0,
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
  "marked_for_deletion_at": "2020-04-03", // Deprecated and will be removed in API v5 in favor of marked_for_deletion_on
  "marked_for_deletion_on": "2020-04-03",
  "compliance_frameworks": [ "sox" ],
  "statistics": {
    "commit_count": 37,
    "storage_size": 1038090,
    "repository_size": 1038090,
    "wiki_size" : 0,
    "lfs_objects_size": 0,
    "job_artifacts_size": 0,
    "packages_size": 0,
    "snippets_size": 0
  },
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members"
  }
}
```

NOTE:
The `tag_list` attribute has been deprecated
and is removed in API v5 in favor of the `topics` attribute.

Users of [GitLab Premium or higher](https://about.gitlab.com/pricing/)
can also see the `approvals_before_merge` parameter:

```json
{
  "id": 3,
  "description": null,
  "approvals_before_merge": 0,
  ...
}
```

The `web_url` and `avatar_url` attributes on `namespace` were
[introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/27427)
in GitLab 11.11.

If the project is a fork, and you provide a valid token to authenticate, the
`forked_from_project` field appears in the response.

```json
{
   "id":3,

   ...

   "forked_from_project":{
      "id":13083,
      "description":"GitLab Community Edition",
      "name":"GitLab Community Edition",
      "name_with_namespace":"GitLab.org / GitLab Community Edition",
      "path":"gitlab-foss",
      "path_with_namespace":"gitlab-org/gitlab-foss",
      "created_at":"2013-09-26T06:02:36.000Z",
      "default_branch":"master",
      "tag_list":[], //deprecated, use `topics` instead
      "topics":[],
      "ssh_url_to_repo":"git@gitlab.com:gitlab-org/gitlab-foss.git",
      "http_url_to_repo":"https://gitlab.com/gitlab-org/gitlab-foss.git",
      "web_url":"https://gitlab.com/gitlab-org/gitlab-foss",
      "avatar_url":"https://assets.gitlab-static.net/uploads/-/system/project/avatar/13083/logo-extra-whitespace.png",
      "license_url": "https://gitlab.com/gitlab-org/gitlab/-/blob/master/LICENSE",
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
      }
   }

   ...

}
```

### Templates for issues and merge requests **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55718) in GitLab 13.10.

Users of [GitLab Premium or higher](https://about.gitlab.com/pricing/)
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

| Attribute    | Type           | Required               | Description |
|--------------|----------------|------------------------|-------------|
| `id`         | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `search`     | string         | **{dotted-circle}** No | Search for specific users. |
| `skip_users` | integer array  | **{dotted-circle}** No | Filter out users with the specified IDs. |

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

| Attribute                   | Type              | Required               | Description |
|-----------------------------|-------------------|------------------------|-------------|
| `id`                        | integer or string    | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `search`                    | string            | **{dotted-circle}** No | Search for specific groups. |
| `skip_groups`               | array of integers | **{dotted-circle}** No | Skip the group IDs passed. |
| `with_shared`               | boolean           | **{dotted-circle}** No | Include projects shared with this group. Default is `false`. |
| `shared_min_access_level`   | integer           | **{dotted-circle}** No | Limit to shared groups with at least this [access level](members.md#valid-access-levels). |
| `shared_visible_only`       | boolean           | **{dotted-circle}** No | Limit to shared groups user has access to. |

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
  },
  {
    "id": 2,
    "name": "Shared Group",
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "full_name": "Shared Group",
    "full_path": "foo/shared",
  }
]
```

## Get project events

Refer to the [Events API documentation](events.md#list-a-projects-visible-events).

## Create project

Creates a new project owned by the authenticated user.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
POST /projects
```

| Attribute                                                   | Type    | Required               | Description |
|-------------------------------------------------------------|---------|------------------------|-------------|
| `name`                                                      | string  | **{check-circle}** Yes (if path isn't provided) | The name of the new project. Equals path if not provided. |
| `path`                                                      | string  | **{check-circle}** Yes (if name isn't provided) | Repository name for new project. Generated based on name if not provided (generated as lowercase with dashes). |
| `allow_merge_on_skipped_pipeline`                           | boolean | **{dotted-circle}** No | Set whether or not merge requests can be merged with skipped jobs. |
| `analytics_access_level`                                    | string  | **{dotted-circle}** No | One of `disabled`, `private` or `enabled` |
| `approvals_before_merge` **(PREMIUM)**                      | integer | **{dotted-circle}** No | How many approvers should approve merge requests by default. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). |
| `auto_cancel_pending_pipelines`                             | string  | **{dotted-circle}** No | Auto-cancel pending pipelines. This isn't a boolean, but enabled/disabled. |
| `auto_devops_deploy_strategy`                               | string  | **{dotted-circle}** No | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`). |
| `auto_devops_enabled`                                       | boolean | **{dotted-circle}** No | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                               | boolean | **{dotted-circle}** No | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                                    | mixed   | **{dotted-circle}** No | Image file for avatar of the project.                |
| `build_coverage_regex`                                      | string  | **{dotted-circle}** No | Test coverage parsing. |
| `build_git_strategy`                                        | string  | **{dotted-circle}** No | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                             | integer | **{dotted-circle}** No | The maximum amount of time, in seconds, that a job can run. |
| `builds_access_level`                                       | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `ci_config_path`                                            | string  | **{dotted-circle}** No | The path to CI configuration file. |
| `container_expiration_policy_attributes`                    | hash    | **{dotted-circle}** No | Update the image cleanup policy for this project. Accepts: `cadence` (string), `keep_n` (integer), `older_than` (string), `name_regex` (string), `name_regex_delete` (string), `name_regex_keep` (string), `enabled` (boolean). Valid values for `cadence` are: `1d` (every day), `7d` (every week), `14d` (every two weeks), `1month` (every month), or `3month` (every quarter). |
| `container_registry_enabled`                                | boolean | **{dotted-circle}** No | Enable container registry for this project. |
| `default_branch`                                            | string  | **{dotted-circle}** No | The [default branch](../user/project/repository/branches/default.md) name. Requires `initialize_with_readme` to be `true`. |
| `description`                                               | string  | **{dotted-circle}** No | Short project description. |
| `emails_disabled`                                           | boolean | **{dotted-circle}** No | Disable email notifications. |
| `external_authorization_classification_label` **(PREMIUM)** | string  | **{dotted-circle}** No | The classification label for the project. |
| `forking_access_level`                                      | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `group_with_project_templates_id` **(PREMIUM)**             | integer | **{dotted-circle}** No | For group-level custom templates, specifies ID of group from which all the custom project templates are sourced. Leave empty for instance-level templates. Requires `use_custom_template` to be true. |
| `import_url`                                                | string  | **{dotted-circle}** No | URL to import repository from. |
| `initialize_with_readme`                                    | boolean | **{dotted-circle}** No | `false` by default. |
| `issues_access_level`                                       | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `issues_enabled`                                            | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `jobs_enabled`                                              | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `lfs_enabled`                                               | boolean | **{dotted-circle}** No | Enable LFS. |
| `merge_method`                                              | string  | **{dotted-circle}** No | Set the [merge method](#project-merge-method) used. |
| `merge_requests_access_level`                               | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `merge_requests_enabled`                                    | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `mirror_trigger_builds` **(PREMIUM)**                       | boolean | **{dotted-circle}** No | Pull mirroring triggers builds. |
| `mirror` **(PREMIUM)**                                      | boolean | **{dotted-circle}** No | Enables pull mirroring in a project. |
| `namespace_id`                                              | integer | **{dotted-circle}** No | Namespace for the new project (defaults to the current user's namespace). |
| `operations_access_level`                                   | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `only_allow_merge_if_all_discussions_are_resolved`          | boolean | **{dotted-circle}** No | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_pipeline_succeeds`                     | boolean | **{dotted-circle}** No | Set whether merge requests can only be merged with successful pipelines. This setting is named [**Pipelines must succeed**](../user/project/merge_requests/merge_when_pipeline_succeeds.md#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds) in the project settings. |
| `packages_enabled`                                          | boolean | **{dotted-circle}** No | Enable or disable packages repository feature. |
| `pages_access_level`                                        | string  | **{dotted-circle}** No | One of `disabled`, `private`, `enabled`, or `public`. |
| `requirements_access_level`                                 | string  | **{dotted-circle}** No | One of `disabled`, `private`, `enabled` or `public` |
| `printing_merge_request_link_enabled`                       | boolean | **{dotted-circle}** No | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                             | boolean | **{dotted-circle}** No | If `true`, jobs can be viewed by non-project members. |
| `remove_source_branch_after_merge`                          | boolean | **{dotted-circle}** No | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_access_level`                                   | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `repository_storage`                                        | string  | **{dotted-circle}** No | Which storage shard the repository is on. _(admins only)_ |
| `request_access_enabled`                                    | boolean | **{dotted-circle}** No | Allow users to request member access. |
| `resolve_outdated_diff_discussions`                         | boolean | **{dotted-circle}** No | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `shared_runners_enabled`                                    | boolean | **{dotted-circle}** No | Enable shared runners for this project. |
| `show_default_award_emojis`                                 | boolean | **{dotted-circle}** No | Show default award emojis. |
| `snippets_access_level`                                     | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `snippets_enabled`                                          | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `tag_list`                                                  | array   | **{dotted-circle}** No | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `template_name`                                             | string  | **{dotted-circle}** No | When used without `use_custom_template`, name of a [built-in project template](../user/project/working_with_projects.md#built-in-templates). When used with `use_custom_template`, name of a custom project template. |
| `template_project_id` **(PREMIUM)**                         | integer | **{dotted-circle}** No | When used with `use_custom_template`, project ID of a custom project template. This is preferable to using `template_name` since `template_name` may be ambiguous. |
| `topics`                                                    | array   | **{dotted-circle}** No | The list of topics for a project; put array of topics, that should be finally assigned to a project. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0.)_ |
| `use_custom_template` **(PREMIUM)**                         | boolean | **{dotted-circle}** No | Use either custom [instance](../user/admin_area/custom_project_templates.md) or [group](../user/group/custom_project_templates.md) (with `group_with_project_templates_id`) project template. |
| `visibility`                                                | string  | **{dotted-circle}** No | See [project visibility level](#project-visibility-level). |
| `wiki_access_level`                                         | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `wiki_enabled`                                              | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |

## Create project for user

Creates a new project owned by the specified user. Available only for admins.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
POST /projects/user/:user_id
```

| Attribute                                                   | Type    | Required               | Description |
|-------------------------------------------------------------|---------|------------------------|-------------|
| `user_id`                                                   | integer | **{check-circle}** Yes | The user ID of the project owner. |
| `name`                                                      | string  | **{check-circle}** Yes | The name of the new project. |
| `allow_merge_on_skipped_pipeline`                           | boolean | **{dotted-circle}** No | Set whether or not merge requests can be merged with skipped jobs. |
| `analytics_access_level`                                    | string  | **{dotted-circle}** No | One of `disabled`, `private` or `enabled` |
| `approvals_before_merge` **(PREMIUM)**                      | integer | **{dotted-circle}** No | How many approvers should approve merge requests by default. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). |
| `auto_cancel_pending_pipelines`                             | string  | **{dotted-circle}** No | Auto-cancel pending pipelines. This isn't a boolean, but enabled/disabled. |
| `auto_devops_deploy_strategy`                               | string  | **{dotted-circle}** No | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`). |
| `auto_devops_enabled`                                       | boolean | **{dotted-circle}** No | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                               | boolean | **{dotted-circle}** No | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                                    | mixed   | **{dotted-circle}** No | Image file for avatar of the project. |
| `build_coverage_regex`                                      | string  | **{dotted-circle}** No | Test coverage parsing. |
| `build_git_strategy`                                        | string  | **{dotted-circle}** No | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                             | integer | **{dotted-circle}** No | The maximum amount of time, in seconds, that a job can run. |
| `builds_access_level`                                       | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `ci_config_path`                                            | string  | **{dotted-circle}** No | The path to CI configuration file. |
| `container_registry_enabled`                                | boolean | **{dotted-circle}** No | Enable container registry for this project. |
| `description`                                               | string  | **{dotted-circle}** No | Short project description. |
| `default_branch`                                            | string  | **{dotted-circle}** No | The [default branch](../user/project/repository/branches/default.md) name. Requires `initialize_with_readme` to be `true`. |
| `emails_disabled`                                           | boolean | **{dotted-circle}** No | Disable email notifications. |
| `external_authorization_classification_label` **(PREMIUM)** | string  | **{dotted-circle}** No | The classification label for the project. |
| `forking_access_level`                                      | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `group_with_project_templates_id` **(PREMIUM)**             | integer | **{dotted-circle}** No | For group-level custom templates, specifies ID of group from which all the custom project templates are sourced. Leave empty for instance-level templates. Requires `use_custom_template` to be true. |
| `import_url`                                                | string  | **{dotted-circle}** No | URL to import repository from. |
| `initialize_with_readme`                                    | boolean | **{dotted-circle}** No | `false` by default. |
| `issues_access_level`                                       | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `issues_enabled`                                            | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `jobs_enabled`                                              | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `lfs_enabled`                                               | boolean | **{dotted-circle}** No | Enable LFS. |
| `merge_method`                                              | string  | **{dotted-circle}** No | Set the [merge method](#project-merge-method) used. |
| `merge_requests_access_level`                               | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `merge_requests_enabled`                                    | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `mirror_trigger_builds` **(PREMIUM)**                       | boolean | **{dotted-circle}** No | Pull mirroring triggers builds. |
| `mirror` **(PREMIUM)**                                      | boolean | **{dotted-circle}** No | Enables pull mirroring in a project. |
| `namespace_id`                                              | integer | **{dotted-circle}** No | Namespace for the new project (defaults to the current user's namespace). |
| `operations_access_level`                                   | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `only_allow_merge_if_all_discussions_are_resolved`          | boolean | **{dotted-circle}** No | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_pipeline_succeeds`                     | boolean | **{dotted-circle}** No | Set whether merge requests can only be merged with successful jobs. |
| `packages_enabled`                                          | boolean | **{dotted-circle}** No | Enable or disable packages repository feature. |
| `pages_access_level`                                        | string  | **{dotted-circle}** No | One of `disabled`, `private`, `enabled`, or `public`. |
| `requirements_access_level`                                 | string  | **{dotted-circle}** No | One of `disabled`, `private`, `enabled` or `public` |
| `path`                                                      | string  | **{dotted-circle}** No | Custom repository name for new project. By default generated based on name. |
| `printing_merge_request_link_enabled`                       | boolean | **{dotted-circle}** No | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                             | boolean | **{dotted-circle}** No | If `true`, jobs can be viewed by non-project-members. |
| `remove_source_branch_after_merge`                          | boolean | **{dotted-circle}** No | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_access_level`                                   | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `repository_storage`                                        | string  | **{dotted-circle}** No | Which storage shard the repository is on. _(admins only)_ |
| `request_access_enabled`                                    | boolean | **{dotted-circle}** No | Allow users to request member access. |
| `resolve_outdated_diff_discussions`                         | boolean | **{dotted-circle}** No | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `shared_runners_enabled`                                    | boolean | **{dotted-circle}** No | Enable shared runners for this project. |
| `show_default_award_emojis`                                 | boolean | **{dotted-circle}** No | Show default award emojis. |
| `snippets_access_level`                                     | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `snippets_enabled`                                          | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `suggestion_commit_message`                                 | string  | **{dotted-circle}** No | The commit message used to apply merge request [suggestions](../user/project/merge_requests/reviews/suggestions.md). |
| `tag_list`                                                  | array   | **{dotted-circle}** No | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `template_name`                                             | string  | **{dotted-circle}** No | When used without `use_custom_template`, name of a [built-in project template](../user/project/working_with_projects.md#built-in-templates). When used with `use_custom_template`, name of a custom project template. |
| `topics`                                                    | array   | **{dotted-circle}** No | The list of topics for the project. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0.)_ |
| `use_custom_template` **(PREMIUM)**                         | boolean | **{dotted-circle}** No | Use either custom [instance](../user/admin_area/custom_project_templates.md) or [group](../user/group/custom_project_templates.md) (with `group_with_project_templates_id`) project template. |
| `visibility`                                                | string  | **{dotted-circle}** No | See [project visibility level](#project-visibility-level). |
| `wiki_access_level`                                         | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `wiki_enabled`                                              | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |

## Edit project

Updates an existing project.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
PUT /projects/:id
```

| Attribute                                                   | Type           | Required               | Description |
|-------------------------------------------------------------|----------------|------------------------|-------------|
| `allow_merge_on_skipped_pipeline`                           | boolean        | **{dotted-circle}** No | Set whether or not merge requests can be merged with skipped jobs. |
| `analytics_access_level`                                    | string         | **{dotted-circle}** No | One of `disabled`, `private` or `enabled` |
| `approvals_before_merge` **(PREMIUM)**                      | integer        | **{dotted-circle}** No | How many approvers should approve merge request by default. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). |
| `auto_cancel_pending_pipelines`                             | string         | **{dotted-circle}** No | Auto-cancel pending pipelines. This isn't a boolean, but enabled/disabled. |
| `auto_devops_deploy_strategy`                               | string         | **{dotted-circle}** No | Auto Deploy strategy (`continuous`, `manual`, or `timed_incremental`). |
| `auto_devops_enabled`                                       | boolean        | **{dotted-circle}** No | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                               | boolean        | **{dotted-circle}** No | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                                    | mixed          | **{dotted-circle}** No | Image file for avatar of the project.                |
| `build_coverage_regex`                                      | string         | **{dotted-circle}** No | Test coverage parsing. |
| `build_git_strategy`                                        | string         | **{dotted-circle}** No | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                             | integer        | **{dotted-circle}** No | The maximum amount of time, in seconds, that a job can run. |
| `builds_access_level`                                       | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `ci_config_path`                                            | string         | **{dotted-circle}** No | The path to CI configuration file. |
| `ci_default_git_depth`                                      | integer        | **{dotted-circle}** No | Default number of revisions for [shallow cloning](../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone). |
| `ci_forward_deployment_enabled`                             | boolean        | **{dotted-circle}** No | When a new deployment job starts, [skip older deployment jobs](../ci/pipelines/settings.md#skip-outdated-deployment-jobs) that are still pending |
| `container_expiration_policy_attributes`                    | hash           | **{dotted-circle}** No | Update the image cleanup policy for this project. Accepts: `cadence` (string), `keep_n` (integer), `older_than` (string), `name_regex` (string), `name_regex_delete` (string), `name_regex_keep` (string), `enabled` (boolean). |
| `container_registry_enabled`                                | boolean        | **{dotted-circle}** No | Enable container registry for this project. |
| `default_branch`                                            | string         | **{dotted-circle}** No | The [default branch](../user/project/repository/branches/default.md) name. |
| `description`                                               | string         | **{dotted-circle}** No | Short project description. |
| `emails_disabled`                                           | boolean        | **{dotted-circle}** No | Disable email notifications. |
| `external_authorization_classification_label` **(PREMIUM)** | string         | **{dotted-circle}** No | The classification label for the project. |
| `forking_access_level`                                      | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `id`                                                        | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `import_url`                                                | string         | **{dotted-circle}** No | URL to import repository from. |
| `issues_access_level`                                       | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `issues_enabled`                                            | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `jobs_enabled`                                              | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `lfs_enabled`                                               | boolean        | **{dotted-circle}** No | Enable LFS. |
| `merge_method`                                              | string         | **{dotted-circle}** No | Set the [merge method](#project-merge-method) used. |
| `merge_requests_access_level`                               | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `merge_requests_enabled`                                    | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `mirror_overwrites_diverged_branches` **(PREMIUM)**         | boolean        | **{dotted-circle}** No | Pull mirror overwrites diverged branches. |
| `mirror_trigger_builds` **(PREMIUM)**                       | boolean        | **{dotted-circle}** No | Pull mirroring triggers builds. |
| `mirror_user_id` **(PREMIUM)**                              | integer        | **{dotted-circle}** No | User responsible for all the activity surrounding a pull mirror event. _(admins only)_ |
| `mirror` **(PREMIUM)**                                      | boolean        | **{dotted-circle}** No | Enables pull mirroring in a project. |
| `name`                                                      | string         | **{dotted-circle}** No | The name of the project. |
| `operations_access_level`                                   | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `only_allow_merge_if_all_discussions_are_resolved`          | boolean        | **{dotted-circle}** No | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_pipeline_succeeds`                     | boolean        | **{dotted-circle}** No | Set whether merge requests can only be merged with successful jobs. |
| `only_mirror_protected_branches` **(PREMIUM)**              | boolean        | **{dotted-circle}** No | Only mirror protected branches. |
| `packages_enabled`                                          | boolean        | **{dotted-circle}** No | Enable or disable packages repository feature. |
| `pages_access_level`                                        | string         | **{dotted-circle}** No | One of `disabled`, `private`, `enabled`, or `public`. |
| `requirements_access_level`                                 | string         | **{dotted-circle}** No | One of `disabled`, `private`, `enabled` or `public` |
| `restrict_user_defined_variables`                           | boolean        | **{dotted-circle}** No | Allow only maintainers to pass user-defined variables when triggering a pipeline. For example when the pipeline is triggered in the UI, with the API, or by a trigger token. |
| `path`                                                      | string         | **{dotted-circle}** No | Custom repository name for the project. By default generated based on name. |
| `public_builds`                                             | boolean        | **{dotted-circle}** No | If `true`, jobs can be viewed by non-project members. |
| `remove_source_branch_after_merge`                          | boolean        | **{dotted-circle}** No | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_access_level`                                   | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `repository_storage`                                        | string         | **{dotted-circle}** No | Which storage shard the repository is on. _(admins only)_ |
| `request_access_enabled`                                    | boolean        | **{dotted-circle}** No | Allow users to request member access. |
| `resolve_outdated_diff_discussions`                         | boolean        | **{dotted-circle}** No | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `service_desk_enabled`                                      | boolean        | **{dotted-circle}** No | Enable or disable Service Desk feature. |
| `shared_runners_enabled`                                    | boolean        | **{dotted-circle}** No | Enable shared runners for this project. |
| `show_default_award_emojis`                                 | boolean        | **{dotted-circle}** No | Show default award emojis. |
| `snippets_access_level`                                     | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `snippets_enabled`                                          | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `suggestion_commit_message`                                 | string         | **{dotted-circle}** No | The commit message used to apply merge request suggestions. |
| `tag_list`                                                  | array          | **{dotted-circle}** No | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `topics`                                                    | array          | **{dotted-circle}** No | The list of topics for the project. This replaces any existing topics that are already added to the project. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0.)_ |
| `visibility`                                                | string         | **{dotted-circle}** No | See [project visibility level](#project-visibility-level). |
| `wiki_access_level`                                         | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `wiki_enabled`                                              | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |
| `issues_template` **(PREMIUM)**                             | string         | **{dotted-circle}** No | Default description for Issues. Description is parsed with GitLab Flavored Markdown. See [Templates for issues and merge requests](#templates-for-issues-and-merge-requests). |
| `merge_requests_template` **(PREMIUM)**                     | string         | **{dotted-circle}** No | Default description for Merge Requests. Description is parsed with GitLab Flavored Markdown. See [Templates for issues and merge requests](#templates-for-issues-and-merge-requests). |
| `keep_latest_artifact`                                      | boolean        | **{dotted-circle}** No | Disable or enable the ability to keep the latest artifact for this project. |

## Fork project

Forks a project into the user namespace of the authenticated user or the one provided.

The forking operation for a project is asynchronous and is completed in a
background job. The request returns immediately. To determine whether the
fork of the project has completed, query the `import_status` for the new project.

```plaintext
POST /projects/:id/fork
```

| Attribute        | Type           | Required               | Description |
|------------------|----------------|------------------------|-------------|
| `id`             | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `name`           | string         | **{dotted-circle}** No | The name assigned to the resultant project after forking.                        |
| `namespace_id`   | integer        | **{dotted-circle}** No | The ID of the namespace that the project is forked to.                           |
| `namespace_path` | string         | **{dotted-circle}** No | The path of the namespace that the project is forked to.                         |
| `namespace`      | integer or string | **{dotted-circle}** No | _(Deprecated)_ The ID or path of the namespace that the project is forked to.    |
| `path`           | string         | **{dotted-circle}** No | The path assigned to the resultant project after forking.                        |
| `description`    | string         | **{dotted-circle}** No | The description assigned to the resultant project after forking.                 |
| `visibility`     | string         | **{dotted-circle}** No | The [visibility level](#project-visibility-level) assigned to the resultant project after forking. |

## List Forks of a project

> Introduced in GitLab 10.1.

List the projects accessible to the calling user that have an established,
forked relationship with the specified project

```plaintext
GET /projects/:id/forks
```

| Attribute                     | Type           | Required               | Description |
|-------------------------------|----------------|------------------------|-------------|
| `archived`                    | boolean        | **{dotted-circle}** No | Limit by archived status. |
| `id`                          | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `membership`                  | boolean        | **{dotted-circle}** No | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer        | **{dotted-circle}** No | Limit by current user minimal [access level](members.md#valid-access-levels). |
| `order_by`                    | string         | **{dotted-circle}** No | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `owned`                       | boolean        | **{dotted-circle}** No | Limit by projects explicitly owned by the current user. |
| `search`                      | string         | **{dotted-circle}** No | Return list of projects matching the search criteria. |
| `simple`                      | boolean        | **{dotted-circle}** No | Return only limited fields for each project. This is a no-op without authentication as then _only_ simple fields are returned. |
| `sort`                        | string         | **{dotted-circle}** No | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean        | **{dotted-circle}** No | Limit by projects starred by the current user. |
| `statistics`                  | boolean        | **{dotted-circle}** No | Include project statistics. |
| `visibility`                  | string         | **{dotted-circle}** No | Limit by visibility `public`, `internal`, or `private`. |
| `with_custom_attributes`      | boolean        | **{dotted-circle}** No | Include [custom attributes](custom_attributes.md) in response. _(admins only)_ |
| `with_issues_enabled`         | boolean        | **{dotted-circle}** No | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean        | **{dotted-circle}** No | Limit by enabled merge requests feature. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/forks"
```

Example responses:

```json
[
  {
    "id": 3,
    "description": null,
    "default_branch": "master",
    "visibility": "internal",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
    "web_url": "http://example.com/diaspora/diaspora-project-site",
    "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
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
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false,
    "created_at": "2013-09-30T13:46:02Z",
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
    "suggestion_commit_message": null,
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members"
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

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/star"
```

Example response:

```json
{
  "id": 3,
  "description": null,
  "default_branch": "master",
  "visibility": "internal",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
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
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false,
  "created_at": "2013-09-30T13:46:02Z",
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
  "license_url": "http://example.com/diaspora/diaspora-client/blob/master/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
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
  "suggestion_commit_message": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members"
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
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/unstar"
```

Example response:

```json
{
  "id": 3,
  "description": null,
  "default_branch": "master",
  "visibility": "internal",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
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
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false,
  "created_at": "2013-09-30T13:46:02Z",
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
  "license_url": "http://example.com/diaspora/diaspora-client/blob/master/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
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
  "suggestion_commit_message": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members"
  }
}
```

## List Starrers of a project

List the users who starred the specified project.

```plaintext
GET /projects/:id/starrers
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `search`  | string         | **{dotted-circle}** No | Search for specific users. |

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

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

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

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/archive"
```

Example response:

```json
{
  "id": 3,
  "description": null,
  "default_branch": "master",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
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
  "container_registry_enabled": false,
  "created_at": "2013-09-30T13:46:02Z",
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
  "license_url": "http://example.com/diaspora/diaspora-client/blob/master/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
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
  "suggestion_commit_message": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members"
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

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/unarchive"
```

Example response:

```json
{
  "id": 3,
  "description": null,
  "default_branch": "master",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
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
  "container_registry_enabled": false,
  "created_at": "2013-09-30T13:46:02Z",
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
  "license_url": "http://example.com/diaspora/diaspora-client/blob/master/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
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
  "suggestion_commit_message": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members"
  }
}
```

## Delete project

This endpoint:

- Deletes a project including all associated resources (including issues and
  merge requests).
- From [GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) on
  [Premium or higher](https://about.gitlab.com/pricing/) tiers, group
  admins can [configure](../user/group/index.md#enable-delayed-project-removal)
  projects within a group to be deleted after a delayed period. When enabled,
  actual deletion happens after the number of days specified in the
  [default deletion delay](../user/admin_area/settings/visibility_and_access_controls.md#default-deletion-delay).

WARNING:
The default behavior of [Delayed Project deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/32935)
in GitLab 12.6 was changed to [Immediate deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/220382)
in GitLab 13.2, as discussed in [Enable delayed project removal](../user/group/index.md#enable-delayed-project-removal).

```plaintext
DELETE /projects/:id
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

## Restore project marked for deletion **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32935) in GitLab 12.6.

Restores project marked for deletion.

```plaintext
POST /projects/:id/restore
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

## Upload a file

Uploads a file to the specified project to be used in an issue or merge request
description, or a comment. GitLab versions 14.0 and later
[enforce](#max-attachment-size-enforcement) this limit.

```plaintext
POST /projects/:id/uploads
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `file`    | string         | **{check-circle}** Yes | The file to be uploaded. |
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

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
  "alt": "dk",
  "url": "/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "full_path": "/namespace1/project1/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "markdown": "![dk](/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png)"
}
```

The returned `url` is relative to the project path. The returned `full_path` is
the absolute path to the file. In Markdown contexts, the link is expanded when
the format in `markdown` is used.

### Max attachment size enforcement

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57250) in GitLab 13.11.

GitLab 13.11 added enforcement of the [maximum attachment size limit](../user/admin_area/settings/account_and_limit_settings.md#max-attachment-size) behind the `enforce_max_attachment_size_upload_api` feature flag. GitLab 14.0 enables this by default.
To disable this enforcement:

**In Omnibus installations:**

1. Enter the Rails console:

   ```shell
   sudo gitlab-rails console
   ```

1. Disable the feature flag:

   ```ruby
   Feature.disable(:enforce_max_attachment_size_upload_api)
   ```

**In installations from source:**

1. Enter the Rails console:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H bundle exec rails console -e production
   ```

1. Disable the feature flag:

   ```ruby
   Feature.disable(:enforce_max_attachment_size_upload_api)
   ```

## Upload a project avatar

Uploads an avatar to the specified project.

```plaintext
PUT /projects/:id
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `avatar`  | string         | **{check-circle}** Yes | The file to be uploaded. |
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

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

## Share project with group

Allow to share project with group.

```plaintext
POST /projects/:id/share
```

| Attribute      | Type           | Required               | Description |
|----------------|----------------|------------------------|-------------|
| `expires_at`   | string         | **{dotted-circle}** No | Share expiration date in ISO 8601 format: 2016-09-26 |
| `group_access` | integer        | **{check-circle}** Yes | The [access level](members.md#valid-access-levels) to grant the group. |
| `group_id`     | integer        | **{check-circle}** Yes | The ID of the group to share with. |
| `id`           | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

## Delete a shared project link within a group

Unshare the project from the group. Returns `204` and no content on success.

```plaintext
DELETE /projects/:id/share/:group_id
```

| Attribute  | Type           | Required               | Description |
|------------|----------------|------------------------|-------------|
| `group_id` | integer        | **{check-circle}** Yes | The ID of the group. |
| `id`       | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/share/17"
```

## Hooks

Also called Project Hooks and Webhooks. These are different for [System Hooks](system_hooks.md)
that are system-wide.

### List project hooks

Get a list of project hooks.

```plaintext
GET /projects/:id/hooks
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

### Get project hook

Get a specific hook for a project.

```plaintext
GET /projects/:id/hooks/:hook_id
```

| Attribute | Type           | Required               | Description               |
|-----------|----------------|------------------------|---------------------------|
| `hook_id` | integer        | **{check-circle}** Yes | The ID of a project hook. |
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

```json
{
  "id": 1,
  "url": "http://example.com/hook",
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
  "created_at": "2012-10-12T17:04:47Z"
}
```

### Add project hook

Adds a hook to a specified project.

```plaintext
POST /projects/:id/hooks
```

| Attribute                    | Type           | Required               | Description |
|------------------------------|----------------|------------------------|-------------|
| `confidential_issues_events` | boolean        | **{dotted-circle}** No | Trigger hook on confidential issues events. |
| `confidential_note_events`   | boolean        | **{dotted-circle}** No | Trigger hook on confidential note events. |
| `deployment_events`          | boolean        | **{dotted-circle}** No | Trigger hook on deployment events. |
| `enable_ssl_verification`    | boolean        | **{dotted-circle}** No | Do SSL verification when triggering the hook. |
| `id`                         | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `issues_events`              | boolean        | **{dotted-circle}** No | Trigger hook on issues events. |
| `job_events`                 | boolean        | **{dotted-circle}** No | Trigger hook on job events. |
| `merge_requests_events`      | boolean        | **{dotted-circle}** No | Trigger hook on merge requests events. |
| `note_events`                | boolean        | **{dotted-circle}** No | Trigger hook on note events. |
| `pipeline_events`            | boolean        | **{dotted-circle}** No | Trigger hook on pipeline events. |
| `push_events_branch_filter`  | string         | **{dotted-circle}** No | Trigger hook on push events for matching branches only. |
| `push_events`                | boolean        | **{dotted-circle}** No | Trigger hook on push events. |
| `tag_push_events`            | boolean        | **{dotted-circle}** No | Trigger hook on tag push events. |
| `token`                      | string         | **{dotted-circle}** No | Secret token to validate received payloads; this isn't returned in the response. |
| `url`                        | string         | **{check-circle}** Yes | The hook URL. |
| `wiki_page_events`           | boolean        | **{dotted-circle}** No | Trigger hook on wiki events. |

### Edit project hook

Edits a hook for a specified project.

```plaintext
PUT /projects/:id/hooks/:hook_id
```

| Attribute                    | Type           | Required               | Description |
|------------------------------|----------------|------------------------|-------------|
| `confidential_issues_events` | boolean        | **{dotted-circle}** No | Trigger hook on confidential issues events. |
| `confidential_note_events`   | boolean        | **{dotted-circle}** No | Trigger hook on confidential note events. |
| `deployment_events`          | boolean        | **{dotted-circle}** No | Trigger hook on deployment events. |
| `enable_ssl_verification`    | boolean        | **{dotted-circle}** No | Do SSL verification when triggering the hook. |
| `hook_id`                    | integer        | **{check-circle}** Yes | The ID of the project hook. |
| `id`                         | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `issues_events`              | boolean        | **{dotted-circle}** No | Trigger hook on issues events. |
| `job_events`                 | boolean        | **{dotted-circle}** No | Trigger hook on job events. |
| `merge_requests_events`      | boolean        | **{dotted-circle}** No | Trigger hook on merge requests events. |
| `note_events`                | boolean        | **{dotted-circle}** No | Trigger hook on note events. |
| `pipeline_events`            | boolean        | **{dotted-circle}** No | Trigger hook on pipeline events. |
| `push_events_branch_filter`  | string         | **{dotted-circle}** No | Trigger hook on push events for matching branches only. |
| `push_events`                | boolean        | **{dotted-circle}** No | Trigger hook on push events. |
| `tag_push_events`            | boolean        | **{dotted-circle}** No | Trigger hook on tag push events. |
| `token`                      | string         | **{dotted-circle}** No | Secret token to validate received payloads; this isn't returned in the response. |
| `url`                        | string         | **{check-circle}** Yes | The hook URL. |
| `wiki_page_events`           | boolean        | **{dotted-circle}** No | Trigger hook on wiki page events. |
| `releases_events`            | boolean        | **{dotted-circle}** No | Trigger hook on release events. |

### Delete project hook

Removes a hook from a project. This is an idempotent method and can be called
multiple times. Either the hook is available or not.

```plaintext
DELETE /projects/:id/hooks/:hook_id
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `hook_id` | integer        | **{check-circle}** Yes | The ID of the project hook. |
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

Note the JSON response differs if the hook is available or not. If the project
hook is available before it's returned in the JSON response or an empty response
is returned.

## Fork relationship

Allows modification of the forked relationship between existing projects.
Available only for project owners and admins.

### Create a forked from/to relation between existing projects

```plaintext
POST /projects/:id/fork/:forked_from_id
```

| Attribute        | Type           | Required               | Description |
|------------------|----------------|------------------------|-------------|
| `forked_from_id` | ID             | **{check-circle}** Yes | The ID of the project that was forked from. |
| `id`             | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

### Delete an existing forked from relationship

```plaintext
DELETE /projects/:id/fork
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

## Search for projects by name

Search for projects by name which are accessible to the authenticated user. This
endpoint can be accessed without authentication if the project is publicly
accessible.

```plaintext
GET /projects
```

| Attribute  | Type   | Required               | Description |
|------------|--------|------------------------|-------------|
| `order_by` | string | **{dotted-circle}** No | Return requests ordered by `id`, `name`, `created_at` or `last_activity_at` fields. |
| `search`   | string | **{check-circle}** Yes | A string contained in the project name. |
| `sort`     | string | **{dotted-circle}** No | Return requests sorted in `asc` or `desc` order. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects?search=test"
```

## Start the Housekeeping task for a project

```plaintext
POST /projects/:id/housekeeping
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

## Push Rules **(PREMIUM)**

### Get project push rules **(PREMIUM)**

Get the [push rules](../push_rules/push_rules.md#enabling-push-rules) of a
project.

```plaintext
GET /projects/:id/push_rule
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |

```json
{
  "id": 1,
  "project_id": 3,
  "commit_message_regex": "Fixes \d+\..*",
  "commit_message_negative_regex": "ssh\:\/\/",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "created_at": "2012-10-12T17:04:47Z",
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 5,
  "commit_committer_check": false,
  "reject_unsigned_commits": false
}
```

Users of [GitLab Premium or higher](https://about.gitlab.com/pricing/)
can also see the `commit_committer_check` and `reject_unsigned_commits`
parameters:

```json
{
  "id": 1,
  "project_id": 3,
  "commit_committer_check": false,
  "reject_unsigned_commits": false
  ...
}
```

### Add project push rule **(PREMIUM)**

Adds a push rule to a specified project.

```plaintext
POST /projects/:id/push_rule
```

| Attribute                               | Type           | Required               | Description |
|-----------------------------------------|----------------|------------------------|-------------|
| `author_email_regex`                    | string         | **{dotted-circle}** No | All commit author emails must match this, for example `@my-company.com$`. |
| `branch_name_regex`                     | string         | **{dotted-circle}** No | All branch names must match this, for example `(feature|hotfix)\/*`. |
| `commit_committer_check` **(PREMIUM)**  | boolean        | **{dotted-circle}** No | Users can only push commits to this repository that were committed with one of their own verified emails. |
| `commit_message_negative_regex`         | string         | **{dotted-circle}** No | No commit message is allowed to match this, for example `ssh\:\/\/`. |
| `commit_message_regex`                  | string         | **{dotted-circle}** No | All commit messages must match this, for example `Fixed \d+\..*`. |
| `deny_delete_tag`                       | boolean        | **{dotted-circle}** No | Deny deleting a tag. |
| `file_name_regex`                       | string         | **{dotted-circle}** No | All committed filenames must **not** match this, for example `(jar|exe)$`. |
| `id`                                    | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding), |
| `max_file_size`                         | integer        | **{dotted-circle}** No | Maximum file size (MB). |
| `member_check`                          | boolean        | **{dotted-circle}** No | Restrict commits by author (email) to existing GitLab users. |
| `prevent_secrets`                       | boolean        | **{dotted-circle}** No | GitLab rejects any files that are likely to contain secrets. |
| `reject_unsigned_commits` **(PREMIUM)** | boolean        | **{dotted-circle}** No | Reject commit when it's not signed through GPG. |

### Edit project push rule **(PREMIUM)**

Edits a push rule for a specified project.

```plaintext
PUT /projects/:id/push_rule
```

| Attribute                               | Type           | Required               | Description |
|-----------------------------------------|----------------|------------------------|-------------|
| `author_email_regex`                    | string         | **{dotted-circle}** No | All commit author emails must match this, for example `@my-company.com$`. |
| `branch_name_regex`                     | string         | **{dotted-circle}** No | All branch names must match this, for example `(feature|hotfix)\/*`. |
| `commit_committer_check` **(PREMIUM)**  | boolean        | **{dotted-circle}** No | Users can only push commits to this repository that were committed with one of their own verified emails. |
| `commit_message_negative_regex`         | string         | **{dotted-circle}** No | No commit message is allowed to match this, for example `ssh\:\/\/`. |
| `commit_message_regex`                  | string         | **{dotted-circle}** No | All commit messages must match this, for example `Fixed \d+\..*`. |
| `deny_delete_tag`                       | boolean        | **{dotted-circle}** No | Deny deleting a tag. |
| `file_name_regex`                       | string         | **{dotted-circle}** No | All committed filenames must **not** match this, for example `(jar|exe)$`. |
| `id`                                    | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `max_file_size`                         | integer        | **{dotted-circle}** No | Maximum file size (MB). |
| `member_check`                          | boolean        | **{dotted-circle}** No | Restrict commits by author (email) to existing GitLab users. |
| `prevent_secrets`                       | boolean        | **{dotted-circle}** No | GitLab rejects any files that are likely to contain secrets. |
| `reject_unsigned_commits` **(PREMIUM)** | boolean        | **{dotted-circle}** No | Reject commits when they are not GPG signed. |

### Delete project push rule

> - Moved to GitLab Premium in 13.9.

Removes a push rule from a project. This is an idempotent method and can be
called multiple times. Either the push rule is available or not.

```plaintext
DELETE /projects/:id/push_rule
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

## Transfer a project to a new namespace

> Introduced in GitLab 11.1.

```plaintext
PUT /projects/:id/transfer
```

| Attribute   | Type           | Required               | Description |
|-------------|----------------|------------------------|-------------|
| `id`        | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `namespace` | integer or string | **{check-circle}** Yes | The ID or path of the namespace to transfer to project to. |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/transfer?namespace=14"
```

Example response:

```json
  {
  "id": 7,
  "description": "",
  "name": "hello-world",
  "name_with_namespace": "cute-cats / hello-world",
  "path": "hello-world",
  "path_with_namespace": "cute-cats/hello-world",
  "created_at": "2020-10-15T16:25:22.415Z",
  "default_branch": "master",
  "tag_list": [], //deprecated, use `topics` instead
  "topics": [],
  "ssh_url_to_repo": "git@gitlab.example.com:cute-cats/hello-world.git",
  "http_url_to_repo": "https://gitlab.example.com/cute-cats/hello-world.git",
  "web_url": "https://gitlab.example.com/cute-cats/hello-world",
  "readme_url": "https://gitlab.example.com/cute-cats/hello-world/-/blob/master/README.md",
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
  "container_registry_enabled": true,
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
  "emails_disabled": null,
  "shared_runners_enabled": true,
  "lfs_enabled": true,
  "creator_id": 2,
  "import_status": "none",
  "open_issues_count": 0,
  "ci_default_git_depth": 50,
  "public_jobs": true,
  "build_timeout": 3600,
  "auto_cancel_pending_pipelines": "enabled",
  "build_coverage_regex": null,
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
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "autoclose_referenced_issues": true,
  "approvals_before_merge": 0,
  "mirror": false,
  "compliance_frameworks": []
}
```

## Branches

Read more in the [Branches](branches.md) documentation.

## Project Import/Export

Read more in the [Project import/export](project_import_export.md) documentation.

## Project members

Read more in the [Project members](members.md) documentation.

## Configure pull mirroring for a project **(PREMIUM)**

> - Introduced in GitLab 11.
> - Moved to GitLab Premium in 13.9.

Configure pull mirroring while [creating a new project](#create-project) or [updating an existing project](#edit-project) using the API if the remote repository is publicly accessible or via `username/password` authentication. In case your HTTP repository is not publicly accessible, you can add the authentication information to the URL: `https://username:password@gitlab.company.com/group/project.git`, where password is a [personal access token](../user/profile/personal_access_tokens.md) with the API scope enabled.

The relevant API parameters to update are:

- `import_url`: URL of remote repository being mirrored (with `username:password` if needed).
- `mirror`: Enables pull mirroring on project when set to `true`.
- `only_mirror_protected_branches`: Set to `true` for protected branches.

## Start the pull mirroring process for a Project **(PREMIUM)**

> - Moved to GitLab Premium in 13.9.

```plaintext
POST /projects/:id/mirror/pull
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

## Project badges

Read more in the [Project Badges](project_badges.md) documentation.

## Download snapshot of a Git repository

> Introduced in GitLab 10.7

This endpoint may only be accessed by an administrative user.

Download a snapshot of the project (or wiki, if requested) Git repository. This
snapshot is always in uncompressed [tar](https://en.wikipedia.org/wiki/Tar_(computing))
format.

If a repository is corrupted to the point where `git clone` doesn't work, the
snapshot may allow some of the data to be retrieved.

```plaintext
GET /projects/:id/snapshot
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |
| `wiki`    | boolean        | **{dotted-circle}** No | Whether to download the wiki, rather than project, repository. |

## Get the path to repository storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29861) in GitLab 14.0.

Get the path to repository storage for specified project. Available for administrators only.

```plaintext
GET /projects/:id/storage
```

| Attribute    | Type           | Required               | Description |
|--------------|----------------|------------------------|-------------|
| `id`         | integer or string | **{check-circle}** Yes | ID or [URL-encoded path of the project](index.md#namespaced-path-encoding). |

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
