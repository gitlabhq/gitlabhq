# Projects API

## Project visibility level

Project in GitLab can be either private, internal or public.
This is determined by the `visibility` field in the project.

Values for the project visibility level are:

- `private`:
  Project access must be granted explicitly for each user.

- `internal`:
  The project can be cloned by any logged in user.

- `public`:
  The project can be accessed without any authentication.

## Project merge method

There are currently three options for `merge_method` to choose from:

- `merge`:
  A merge commit is created for every merge, and merging is allowed as long as there are no conflicts.

- `rebase_merge`:
  A merge commit is created for every merge, but merging is only allowed if fast-forward merge is possible.
  This way you could make sure that if this merge request would build, after merging to target branch it would also build.

- `ff`:
  No merge commits are created and all merges are fast-forwarded, which means that merging is only allowed if the branch could be fast-forwarded.

## List all projects

Get a list of all visible projects across GitLab for the authenticated user.
When accessed without authentication, only public projects with "simple" fields are returned.

```
GET /projects
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `archived`                    | boolean | no | Limit by archived status |
| `visibility`                  | string  | no | Limit by visibility `public`, `internal`, or `private` |
| `order_by`                    | string  | no | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at` |
| `sort`                        | string  | no | Return projects sorted in `asc` or `desc` order. Default is `desc` |
| `search`                      | string  | no | Return list of projects matching the search criteria |
| `simple`                      | boolean | no | Return only limited fields for each project. This is a no-op without authentication as then _only_ simple fields are returned. |
| `owned`                       | boolean | no | Limit by projects explicitly owned by the current user |
| `membership`                  | boolean | no | Limit by projects that the current user is a member of |
| `starred`                     | boolean | no | Limit by projects starred by the current user |
| `statistics`                  | boolean | no | Include project statistics |
| `with_custom_attributes`      | boolean | no | Include [custom attributes](custom_attributes.md) in response (admins only) |
| `with_issues_enabled`         | boolean | no | Limit by enabled issues feature |
| `with_merge_requests_enabled` | boolean | no | Limit by enabled merge requests feature |
| `with_programming_language`   | string  | no | Limit by projects which use the given programming language |
| `wiki_checksum_failed`        | boolean | no | **(PREMIUM)** Limit projects where the wiki checksum calculation has failed ([Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/6137) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.2) |
| `repository_checksum_failed`  | boolean | no | **(PREMIUM)** Limit projects where the repository checksum calculation has failed ([Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/6137) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.2) |
| `min_access_level`            | integer | no | Limit by current user minimal [access level](members.md) |
| `id_after`                    | integer | no | Limit results to projects with IDs greater than the specified ID |
| `id_before`                   | integer | no | Limit results to projects with IDs less than the specified ID |

NOTE: **Note:**
This endpoint supports [keyset pagination](README.md#keyset-based-pagination) for selected `order_by` options.

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
    "tag_list": [
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
    "star_count": 0,
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
    "tag_list": [
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
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "packages_size": 0
    },
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members"
    },
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
    "tag_list": [
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
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "packages_size": 0
    },
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

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `approvals_before_merge` parameter:

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

```
GET /projects?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

## List user projects

Get a list of visible projects owned by the given user. When accessed without authentication, only public projects are returned.

```
GET /users/:user_id/projects
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `user_id` | string | yes | The ID or username of the user |
| `archived` | boolean | no | Limit by archived status |
| `visibility` | string | no | Limit by visibility `public`, `internal`, or `private` |
| `order_by` | string | no | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at` |
| `sort` | string | no | Return projects sorted in `asc` or `desc` order. Default is `desc` |
| `search` | string | no | Return list of projects matching the search criteria |
| `simple` | boolean | no | Return only limited fields for each project. This is a no-op without authentication as then _only_ simple fields are returned. |
| `owned` | boolean | no | Limit by projects explicitly owned by the current user |
| `membership` | boolean | no | Limit by projects that the current user is a member of |
| `starred` | boolean | no | Limit by projects starred by the current user |
| `statistics` | boolean | no | Include project statistics |
| `with_custom_attributes` | boolean | no | Include [custom attributes](custom_attributes.md) in response (admins only) |
| `with_issues_enabled` | boolean | no | Limit by enabled issues feature |
| `with_merge_requests_enabled` | boolean | no | Limit by enabled merge requests feature |
| `with_programming_language` | string | no | Limit by projects which use the given programming language |
| `min_access_level` | integer | no | Limit by current user minimal [access level](members.md) |
| `id_after`                    | integer | no | Limit results to projects with IDs greater than the specified ID |
| `id_before`                   | integer | no | Limit results to projects with IDs less than the specified ID |

NOTE: **Note:**
This endpoint supports [keyset pagination](README.md#keyset-based-pagination) for selected `order_by` options.

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
    "tag_list": [
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
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "packages_size": 0
    },
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
    "tag_list": [
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
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "packages_size": 0
    },
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

Get a list of visible projects owned by the given user. When accessed without authentication, only public projects are returned.

```
GET /users/:user_id/starred_projects
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `user_id` | string | yes | The ID or username of the user. |
| `archived` | boolean | no | Limit by archived status. |
| `visibility` | string | no | Limit by visibility `public`, `internal`, or `private`. |
| `order_by` | string | no | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `sort` | string | no | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `search` | string | no | Return list of projects matching the search criteria. |
| `simple` | boolean | no | Return only limited fields for each project. This is a no-op without authentication as then _only_ simple fields are returned.. |
| `owned` | boolean | no | Limit by projects explicitly owned by the current user. |
| `membership` | boolean | no | Limit by projects that the current user is a member of. |
| `starred` | boolean | no | Limit by projects starred by the current user. |
| `statistics` | boolean | no | Include project statistics. |
| `with_custom_attributes` | boolean | no | Include [custom attributes](custom_attributes.md) in response (admins only). |
| `with_issues_enabled` | boolean | no | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean | no | Limit by enabled merge requests feature. |
| `min_access_level` | integer | no | Limit by current user minimal [access level](members.md). |

```bash
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
    "tag_list": [
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
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0
    },
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
    "tag_list": [
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
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0
    },
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

```
GET /projects/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `statistics` | boolean | no | Include project statistics |
| `license` | boolean | no | Include project license data |
| `with_custom_attributes` | boolean | no | Include [custom attributes](custom_attributes.md) in response (admins only) |

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
  "tag_list": [
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
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "printing_merge_requests_link_enabled": true,
  "request_access_enabled": false,
  "merge_method": "merge",
  "statistics": {
    "commit_count": 37,
    "storage_size": 1038090,
    "repository_size": 1038090,
    "wiki_size" : 0,
    "lfs_objects_size": 0,
    "job_artifacts_size": 0,
    "packages_size": 0
  },
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

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `approvals_before_merge` parameter:

```json
{
  "id": 3,
  "description": null,
  "approvals_before_merge": 0,
  ...
}
```

**Note**: The `web_url` and `avatar_url` attributes on `namespace` were [introduced][ce-27427] in GitLab 11.11.

If the project is a fork, and you provide a valid token to authenticate, the
`forked_from_project` field will appear in the response.

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
      "tag_list":[],
      "ssh_url_to_repo":"git@gitlab.com:gitlab-org/gitlab-foss.git",
      "http_url_to_repo":"https://gitlab.com/gitlab-org/gitlab-foss.git",
      "web_url":"https://gitlab.com/gitlab-org/gitlab-foss",
      "avatar_url":"https://assets.gitlab-static.net/uploads/-/system/project/avatar/13083/logo-extra-whitespace.png",
      "license_url": "https://gitlab.com/gitlab-org/gitlab/blob/master/LICENSE",
      "license": {
        "key": "mit",
        "name": "MIT License",
        "nickname": null,
        "html_url": "http://choosealicense.com/licenses/mit/",
        "source_url": "https://opensource.org/licenses/MIT",
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

## Get project users

Get the users list of a project.

```
GET /projects/:id/users
```

| Attribute    | Type          | Required | Description |
| ------------ | ------------- | -------- | ----------- |
| `search`     | string        | no       | Search for specific users |
| `skip_users` | integer array | no       | Filter out users with the specified IDs |

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

## Get project events

Please refer to the [Events API documentation](events.md#list-a-projects-visible-events).

## Create project

Creates a new project owned by the authenticated user.

```
POST /projects
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | yes if path is not provided | The name of the new project. Equals path if not provided. |
| `path` | string | yes if name is not provided | Repository name for new project. Generated based on name if not provided (generated lowercased with dashes). |
| `namespace_id` | integer | no | Namespace for the new project (defaults to the current user's namespace) |
| `default_branch` | string | no | `master` by default |
| `description` | string | no | Short project description |
| `issues_enabled` | boolean | no | (deprecated) Enable issues for this project. Use `issues_access_level` instead |
| `merge_requests_enabled` | boolean | no | (deprecated) Enable merge requests for this project. Use `merge_requests_access_level` instead |
| `jobs_enabled` | boolean | no | (deprecated) Enable jobs for this project. Use `builds_access_level` instead |
| `wiki_enabled` | boolean | no | (deprecated) Enable wiki for this project. Use `wiki_access_level` instead |
| `snippets_enabled` | boolean | no | (deprecated) Enable snippets for this project. Use `snippets_access_level` instead |
| `issues_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `repository_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `merge_requests_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `builds_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `wiki_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `snippets_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `resolve_outdated_diff_discussions` | boolean | no | Automatically resolve merge request diffs discussions on lines changed with a push |
| `container_registry_enabled` | boolean | no | Enable container registry for this project |
| `shared_runners_enabled` | boolean | no | Enable shared runners for this project |
| `visibility` | string | no | See [project visibility level](#project-visibility-level) |
| `import_url` | string | no | URL to import repository from |
| `public_builds` | boolean | no | If `true`, jobs can be viewed by non-project-members |
| `only_allow_merge_if_pipeline_succeeds` | boolean | no | Set whether merge requests can only be merged with successful jobs |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | no | Set whether merge requests can only be merged when all the discussions are resolved |
| `merge_method` | string | no | Set the [merge method](#project-merge-method) used |
| `remove_source_branch_after_merge` | boolean | no | Enable `Delete source branch` option by default for all new merge requests |
| `lfs_enabled` | boolean | no | Enable LFS |
| `request_access_enabled` | boolean | no | Allow users to request member access |
| `tag_list`    | array   | no       | The list of tags for a project; put array of tags, that should be finally assigned to a project |
| `avatar`    | mixed   | no      | Image file for avatar of the project                |
| `printing_merge_request_link_enabled` | boolean | no | Show link to create/view merge request when pushing from the command line |
| `build_git_strategy` | string | no | The Git strategy. Defaults to `fetch` |
| `build_timeout` | integer | no | The maximum amount of time in minutes that a job is able run (in seconds) |
| `auto_cancel_pending_pipelines` | string | no | Auto-cancel pending pipelines (Note: this is not a boolean, but enabled/disabled |
| `build_coverage_regex` | string | no | Test coverage parsing |
| `ci_config_path` | string | no | The path to CI config file |
| `auto_devops_enabled` | boolean | no | Enable Auto DevOps for this project |
| `auto_devops_deploy_strategy` | string | no | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`) |
| `repository_storage` | string | no | **(STARTER ONLY)** Which storage shard the repository is on. Available only to admins |
| `approvals_before_merge` | integer | no | **(STARTER)** How many approvers should approve merge requests by default |
| `external_authorization_classification_label` | string | no | **(PREMIUM)** The classification label for the project |
| `mirror` | boolean | no | **(STARTER)** Enables pull mirroring in a project |
| `mirror_trigger_builds` | boolean | no | **(STARTER)** Pull mirroring triggers builds |
| `initialize_with_readme` | boolean | no | `false` by default |
| `template_name` | string | no | When used without `use_custom_template`, name of a [built-in project template](../gitlab-basics/create-project.md#built-in-templates). When used with `use_custom_template`, name of a custom project template |
| `template_project_id` | integer | no | **(PREMIUM)** When used with `use_custom_template`, project ID of a custom project template. This is preferable to using `template_name` since `template_name` may be ambiguous. |
| `use_custom_template` | boolean | no | **(PREMIUM)** Use either custom [instance](../user/admin_area/custom_project_templates.md) or [group](../user/group/custom_project_templates.md) (with `group_with_project_templates_id`) project template |
| `group_with_project_templates_id` | integer | no | **(PREMIUM)** For group-level custom templates, specifies ID of group from which all the custom project templates are sourced. Leave empty for instance-level templates. Requires `use_custom_template` to be true |

NOTE: **Note:** If your HTTP repository is not publicly accessible,
add authentication information to the URL: `https://username:password@gitlab.company.com/group/project.git`
where `password` is a public access key with the `api` scope enabled.

## Create project for user

Creates a new project owned by the specified user. Available only for admins.

```
POST /projects/user/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `user_id` | integer | yes | The user ID of the project owner |
| `name` | string | yes | The name of the new project |
| `path` | string | no | Custom repository name for new project. By default generated based on name |
| `namespace_id` | integer | no | Namespace for the new project (defaults to the current user's namespace) |
| `description` | string | no | Short project description |
| `issues_enabled` | boolean | no | (deprecated) Enable issues for this project. Use `issues_access_level` instead |
| `merge_requests_enabled` | boolean | no | (deprecated) Enable merge requests for this project. Use `merge_requests_access_level` instead |
| `jobs_enabled` | boolean | no | (deprecated) Enable jobs for this project. Use `builds_access_level` instead |
| `wiki_enabled` | boolean | no | (deprecated) Enable wiki for this project. Use `wiki_access_level` instead |
| `snippets_enabled` | boolean | no | (deprecated) Enable snippets for this project. Use `snippets_access_level` instead |
| `issues_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `repository_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `merge_requests_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `builds_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `wiki_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `snippets_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `resolve_outdated_diff_discussions` | boolean | no | Automatically resolve merge request diffs discussions on lines changed with a push |
| `container_registry_enabled` | boolean | no | Enable container registry for this project |
| `shared_runners_enabled` | boolean | no | Enable shared runners for this project |
| `visibility` | string | no | See [project visibility level](#project-visibility-level) |
| `import_url` | string | no | URL to import repository from |
| `public_builds` | boolean | no | If `true`, jobs can be viewed by non-project-members |
| `only_allow_merge_if_pipeline_succeeds` | boolean | no | Set whether merge requests can only be merged with successful jobs |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | no | Set whether merge requests can only be merged when all the discussions are resolved |
| `merge_method` | string | no | Set the [merge method](#project-merge-method) used |
| `remove_source_branch_after_merge` | boolean | no | Enable `Delete source branch` option by default for all new merge requests |
| `lfs_enabled` | boolean | no | Enable LFS |
| `request_access_enabled` | boolean | no | Allow users to request member access |
| `tag_list`    | array   | no       | The list of tags for a project; put array of tags, that should be finally assigned to a project |
| `avatar`    | mixed   | no      | Image file for avatar of the project                |
| `printing_merge_request_link_enabled` | boolean | no | Show link to create/view merge request when pushing from the command line |
| `build_git_strategy` | string | no | The Git strategy. Defaults to `fetch` |
| `build_timeout` | integer | no | The maximum amount of time in minutes that a job is able run (in seconds) |
| `auto_cancel_pending_pipelines` | string | no | Auto-cancel pending pipelines (Note: this is not a boolean, but enabled/disabled |
| `build_coverage_regex` | string | no | Test coverage parsing |
| `ci_config_path` | string | no | The path to CI config file |
| `auto_devops_enabled` | boolean | no | Enable Auto DevOps for this project |
| `auto_devops_deploy_strategy` | string | no | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`) |
| `repository_storage` | string | no | **(STARTER ONLY)** Which storage shard the repository is on. Available only to admins |
| `approvals_before_merge` | integer | no | **(STARTER)** How many approvers should approve merge requests by default |
| `external_authorization_classification_label` | string | no | **(PREMIUM)** The classification label for the project |
| `mirror` | boolean | no | **(STARTER)** Enables pull mirroring in a project |
| `mirror_trigger_builds` | boolean | no | **(STARTER)** Pull mirroring triggers builds |
| `initialize_with_readme` | boolean | no | `false` by default |
| `template_name` | string | no | When used without `use_custom_template`, name of a [built-in project template](../gitlab-basics/create-project.md#built-in-templates). When used with `use_custom_template`, name of a custom project template |
| `use_custom_template` | boolean | no | **(PREMIUM)** Use either custom [instance](../user/admin_area/custom_project_templates.md) or [group](../user/group/custom_project_templates.md) (with `group_with_project_templates_id`) project template |
| `group_with_project_templates_id` | integer | no | **(PREMIUM)** For group-level custom templates, specifies ID of group from which all the custom project templates are sourced. Leave empty for instance-level templates. Requires `use_custom_template` to be true |

NOTE: **Note:** If your HTTP repository is not publicly accessible,
add authentication information to the URL: `https://username:password@gitlab.company.com/group/project.git`
where `password` is a public access key with the `api` scope enabled.

## Edit project

Updates an existing project.

```
PUT /projects/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `name` | string | no | The name of the project |
| `path` | string | no | Custom repository name for the project. By default generated based on name |
| `default_branch` | string | no | `master` by default |
| `description` | string | no | Short project description |
| `issues_enabled` | boolean | no | (deprecated) Enable issues for this project. Use `issues_access_level` instead |
| `merge_requests_enabled` | boolean | no | (deprecated) Enable merge requests for this project. Use `merge_requests_access_level` instead |
| `jobs_enabled` | boolean | no | (deprecated) Enable jobs for this project. Use `builds_access_level` instead |
| `wiki_enabled` | boolean | no | (deprecated) Enable wiki for this project. Use `wiki_access_level` instead |
| `snippets_enabled` | boolean | no | (deprecated) Enable snippets for this project. Use `snippets_access_level` instead |
| `issues_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `repository_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `merge_requests_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `builds_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `wiki_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `snippets_access_level` | string | no | One of `disabled`, `private` or `enabled` |
| `resolve_outdated_diff_discussions` | boolean | no | Automatically resolve merge request diffs discussions on lines changed with a push |
| `container_registry_enabled` | boolean | no | Enable container registry for this project |
| `shared_runners_enabled` | boolean | no | Enable shared runners for this project |
| `visibility` | string | no | See [project visibility level](#project-visibility-level) |
| `import_url` | string | no | URL to import repository from |
| `public_builds` | boolean | no | If `true`, jobs can be viewed by non-project-members |
| `only_allow_merge_if_pipeline_succeeds` | boolean | no | Set whether merge requests can only be merged with successful jobs |
| `only_allow_merge_if_all_discussions_are_resolved` | boolean | no | Set whether merge requests can only be merged when all the discussions are resolved |
| `merge_method` | string | no | Set the [merge method](#project-merge-method) used |
| `remove_source_branch_after_merge` | boolean | no | Enable `Delete source branch` option by default for all new merge requests |
| `lfs_enabled` | boolean | no | Enable LFS |
| `request_access_enabled` | boolean | no | Allow users to request member access |
| `tag_list`    | array   | no       | The list of tags for a project; put array of tags, that should be finally assigned to a project |
| `avatar`    | mixed   | no      | Image file for avatar of the project                |
| `build_git_strategy` | string | no | The Git strategy. Defaults to `fetch` |
| `build_timeout` | integer | no | The maximum amount of time in minutes that a job is able run (in seconds) |
| `auto_cancel_pending_pipelines` | string | no | Auto-cancel pending pipelines (Note: this is not a boolean, but enabled/disabled |
| `build_coverage_regex` | string | no | Test coverage parsing |
| `ci_config_path` | string | no | The path to CI config file |
| `ci_default_git_depth` | integer | no | Default number of revisions for [shallow cloning](../user/project/pipelines/settings.md#git-shallow-clone) |
| `auto_devops_enabled` | boolean | no | Enable Auto DevOps for this project |
| `auto_devops_deploy_strategy` | string | no | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`) |
| `repository_storage` | string | no | **(STARTER ONLY)** Which storage shard the repository is on. Available only to admins |
| `approvals_before_merge` | integer | no | **(STARTER)** How many approvers should approve merge request by default |
| `external_authorization_classification_label` | string | no | **(PREMIUM)** The classification label for the project |
| `mirror` | boolean | no | **(STARTER)** Enables pull mirroring in a project |
| `mirror_user_id` | integer | no | **(STARTER)** User responsible for all the activity surrounding a pull mirror event |
| `mirror_trigger_builds` | boolean | no | **(STARTER)** Pull mirroring triggers builds |
| `only_mirror_protected_branches` | boolean | no | **(STARTER)** Only mirror protected branches |
| `mirror_overwrites_diverged_branches` | boolean | no | **(STARTER)** Pull mirror overwrites diverged branches |
| `packages_enabled` | boolean | no | **(PREMIUM ONLY)** Enable or disable packages repository feature |

NOTE: **Note:** If your HTTP repository is not publicly accessible,
add authentication information to the URL: `https://username:password@gitlab.company.com/group/project.git`
where `password` is a public access key with the `api` scope enabled.

## Fork project

Forks a project into the user namespace of the authenticated user or the one provided.

The forking operation for a project is asynchronous and is completed in a
background job. The request will return immediately. To determine whether the
fork of the project has completed, query the `import_status` for the new project.

```
POST /projects/:id/fork
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `namespace` | integer/string | yes | The ID or path of the namespace that the project will be forked to |
| `path` | string | no | The path that will be assigned to the resultant project after forking |
| `name` | string | no | The name that will be assigned to the resultant project after forking |

## List Forks of a project

>**Note:** This feature was introduced in GitLab 10.1

List the projects accessible to the calling user that have an established, forked relationship with the specified project

```
GET /projects/:id/forks
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `archived` | boolean | no | Limit by archived status |
| `visibility` | string | no | Limit by visibility `public`, `internal`, or `private` |
| `order_by` | string | no | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at` |
| `sort` | string | no | Return projects sorted in `asc` or `desc` order. Default is `desc` |
| `search` | string | no | Return list of projects matching the search criteria |
| `simple` | boolean | no | Return only limited fields for each project. This is a no-op without authentication as then _only_ simple fields are returned. |
| `owned` | boolean | no | Limit by projects explicitly owned by the current user |
| `membership` | boolean | no | Limit by projects that the current user is a member of |
| `starred` | boolean | no | Limit by projects starred by the current user |
| `statistics` | boolean | no | Include project statistics |
| `with_custom_attributes` | boolean | no | Include [custom attributes](custom_attributes.md) in response (admins only) |
| `with_issues_enabled` | boolean | no | Limit by enabled issues feature |
| `with_merge_requests_enabled` | boolean | no | Limit by enabled merge requests feature |
| `min_access_level` | integer | no | Limit by current user minimal [access level](members.md) |

```bash
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
    "tag_list": [
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
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
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

Stars a given project. Returns status code `304` if the project is already starred.

```
POST /projects/:id/star
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

```bash
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
  "tag_list": [
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
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
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

```
POST /projects/:id/unstar
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

```bash
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
  "tag_list": [
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
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
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

```
GET /projects/:id/starrers
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `search` | string | no | Search for specific users. |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/starrers"
```

Example responses:

```json
[
  {
    "starred_since": "2019-01-28T14:47:30.642Z",
    "user":
      {
        "id": 1,
        "username": "jane_smith",
        "name": "Jane Smith",
        "state": "active",
        "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
        "web_url": "http://localhost:3000/jane_smith"
      }
  },
    "starred_since": "2018-01-02T11:40:26.570Z",
    "user":
      {
        "id": 2,
        "username": "janine_smith",
        "name": "Janine Smith",
        "state": "blocked",
        "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
        "web_url": "http://localhost:3000/janine_smith"
      }
]
```

## Languages

Get languages used in a project with percentage value.

```
GET /projects/:id/languages
```

```bash
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

Archives the project if the user is either admin or the project owner of this project. This action is
idempotent, thus archiving an already archived project will not change the project.

```
POST /projects/:id/archive
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

```bash
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
  "tag_list": [
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
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
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

Unarchives the project if the user is either admin or the project owner of this project. This action is
idempotent, thus unarchiving a non-archived project will not change the project.

```
POST /projects/:id/unarchive
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

```bash
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
  "tag_list": [
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
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
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

## Remove project

Removes a project including all associated resources (issues, merge requests etc).

```
DELETE /projects/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

## Upload a file

Uploads a file to the specified project to be used in an issue or merge request description, or a comment.

```
POST /projects/:id/uploads
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `file` | string | yes | The file to be uploaded |

To upload a file from your filesystem, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`.
The `file=` parameter must point to a file on your filesystem and be preceded
by `@`. For example:

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --form "file=@dk.png" https://gitlab.example.com/api/v4/projects/5/uploads
```

Returned object:

```json
{
  "alt": "dk",
  "url": "/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "markdown": "![dk](/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png)"
}
```

>**Note**: The returned `url` is relative to the project path.
In Markdown contexts, the link is automatically expanded when the format in
`markdown` is used.

## Share project with group

Allow to share project with group.

```
POST /projects/:id/share
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `group_id` | integer | yes | The ID of the group to share with |
| `group_access` | integer | yes | The [permissions level](members.md) to grant the group |
| `expires_at` | string | no | Share expiration date in ISO 8601 format: 2016-09-26 |

## Delete a shared project link within a group

Unshare the project from the group. Returns `204` and no content on success.

```
DELETE /projects/:id/share/:group_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `group_id` | integer | yes | The ID of the group |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/5/share/17
```

## Hooks

Also called Project Hooks and Webhooks.
These are different for [System Hooks](system_hooks.md) that are system wide.

### List project hooks

Get a list of project hooks.

```
GET /projects/:id/hooks
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

### Get project hook

Get a specific hook for a project.

```
GET /projects/:id/hooks/:hook_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `hook_id` | integer | yes | The ID of a project hook |

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
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "enable_ssl_verification": true,
  "created_at": "2012-10-12T17:04:47Z"
}
```

### Add project hook

Adds a hook to a specified project.

```
POST /projects/:id/hooks
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `url` | string | yes | The hook URL |
| `push_events` | boolean | no | Trigger hook on push events |
| `push_events_branch_filter` | string | no | Trigger hook on push events for matching branches only |
| `issues_events` | boolean | no | Trigger hook on issues events |
| `confidential_issues_events` | boolean | no | Trigger hook on confidential issues events |
| `merge_requests_events` | boolean | no | Trigger hook on merge requests events |
| `tag_push_events` | boolean | no | Trigger hook on tag push events |
| `note_events` | boolean | no | Trigger hook on note events |
| `job_events` | boolean | no | Trigger hook on job events |
| `pipeline_events` | boolean | no | Trigger hook on pipeline events |
| `wiki_page_events` | boolean | no | Trigger hook on wiki events |
| `enable_ssl_verification` | boolean | no | Do SSL verification when triggering the hook |
| `token` | string | no | Secret token to validate received payloads; this will not be returned in the response |

### Edit project hook

Edits a hook for a specified project.

```
PUT /projects/:id/hooks/:hook_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `hook_id` | integer | yes | The ID of the project hook |
| `url` | string | yes | The hook URL |
| `push_events` | boolean | no | Trigger hook on push events |
| `push_events_branch_filter` | string | no | Trigger hook on push events for matching branches only |
| `issues_events` | boolean | no | Trigger hook on issues events |
| `confidential_issues_events` | boolean | no | Trigger hook on confidential issues events |
| `merge_requests_events` | boolean | no | Trigger hook on merge requests events |
| `tag_push_events` | boolean | no | Trigger hook on tag push events |
| `note_events` | boolean | no | Trigger hook on note events |
| `job_events` | boolean | no | Trigger hook on job events |
| `pipeline_events` | boolean | no | Trigger hook on pipeline events |
| `wiki_events` | boolean | no | Trigger hook on wiki events |
| `enable_ssl_verification` | boolean | no | Do SSL verification when triggering the hook |
| `token` | string | no | Secret token to validate received payloads; this will not be returned in the response |

### Delete project hook

Removes a hook from a project. This is an idempotent method and can be called multiple times.
Either the hook is available or not.

```
DELETE /projects/:id/hooks/:hook_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `hook_id` | integer | yes | The ID of the project hook |

Note the JSON response differs if the hook is available or not. If the project hook
is available before it is returned in the JSON response or an empty response is returned.

## Fork relationship

Allows modification of the forked relationship between existing projects. Available only for project owners and admins.

### Create a forked from/to relation between existing projects

CAUTION: **Warning:**
This will destroy the LFS objects stored in the fork.
So to retain the LFS objects, make sure you've pulled them **before** creating the fork relation,
and push them again **after** creating the fork relation.

```
POST /projects/:id/fork/:forked_from_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `forked_from_id` | ID | yes | The ID of the project that was forked from |

### Delete an existing forked from relationship

```
DELETE /projects/:id/fork
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

## Search for projects by name

Search for projects by name which are accessible to the authenticated user. This
endpoint can be accessed without authentication if the project is publicly
accessible.

```
GET /projects
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `search` | string | yes | A string contained in the project name |
| `order_by` | string | no | Return requests ordered by `id`, `name`, `created_at` or `last_activity_at` fields |
| `sort` | string | no | Return requests sorted in `asc` or `desc` order |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects?search=test
```

## Start the Housekeeping task for a Project

> Introduced in GitLab 9.0.

```
POST /projects/:id/housekeeping
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID of the project or NAMESPACE/PROJECT_NAME |

## Push Rules **(STARTER)**

### Get project push rules

Get the push rules of a project.

```
GET /projects/:id/push_rule
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID of the project or NAMESPACE/PROJECT_NAME |

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

Users on GitLab [Premium, Silver, or higher](https://about.gitlab.com/pricing/) will also see
the `commit_committer_check` and `reject_unsigned_commits` parameters:

```json
{
  "id": 1,
  "project_id": 3,
  "commit_committer_check": false,
  "reject_unsigned_commits": false
  ...
}
```

### Add project push rule

Adds a push rule to a specified project.

```
POST /projects/:id/push_rule
```

| Attribute                                     | Type           | Required | Description |
| --------------------------------------------- | -------------- | -------- | ----------- |
| `id`                                          | integer/string | yes      | The ID of the project or NAMESPACE/PROJECT_NAME |
| `deny_delete_tag` **(STARTER)**               | boolean        | no       | Deny deleting a tag |
| `member_check` **(STARTER)**                  | boolean        | no       | Restrict commits by author (email) to existing GitLab users |
| `prevent_secrets` **(STARTER)**               | boolean        | no       | GitLab will reject any files that are likely to contain secrets |
| `commit_message_regex` **(STARTER)**          | string         | no       | All commit messages must match this, e.g. `Fixed \d+\..*` |
| `commit_message_negative_regex` **(STARTER)** | string         | no       | No commit message is allowed to match this, e.g. `ssh\:\/\/` |
| `branch_name_regex` **(STARTER)**             | string         | no       | All branch names must match this, e.g. `(feature|hotfix)\/*` |
| `author_email_regex` **(STARTER)**            | string         | no       | All commit author emails must match this, e.g. `@my-company.com$` |
| `file_name_regex` **(STARTER)**               | string         | no       | All commited filenames must **not** match this, e.g. `(jar|exe)$` |
| `max_file_size` **(STARTER)**                 | integer        | no       | Maximum file size (MB) |
| `commit_committer_check` **(PREMIUM)**        | boolean        | no       | Users can only push commits to this repository that were committed with one of their own verified emails. |
| `reject_unsigned_commits` **(PREMIUM)**        | boolean        | no       | Reject commit when it is not signed through GPG. |

### Edit project push rule

Edits a push rule for a specified project.

```
PUT /projects/:id/push_rule
```

| Attribute                                     | Type           | Required | Description |
| --------------------------------------------- | -------------- | -------- | ----------- |
| `id`                                          | integer/string | yes      | The ID of the project or NAMESPACE/PROJECT_NAME |
| `deny_delete_tag` **(STARTER)**               | boolean        | no       | Deny deleting a tag |
| `member_check` **(STARTER)**                  | boolean        | no       | Restrict commits by author (email) to existing GitLab users |
| `prevent_secrets` **(STARTER)**               | boolean        | no       | GitLab will reject any files that are likely to contain secrets |
| `commit_message_regex` **(STARTER)**          | string         | no       | All commit messages must match this, e.g. `Fixed \d+\..*` |
| `commit_message_negative_regex` **(STARTER)** | string         | no       | No commit message is allowed to match this, e.g. `ssh\:\/\/` |
| `branch_name_regex` **(STARTER)**             | string         | no       | All branch names must match this, e.g. `(feature|hotfix)\/*` |
| `author_email_regex` **(STARTER)**            | string         | no       | All commit author emails must match this, e.g. `@my-company.com$` |
| `file_name_regex` **(STARTER)**               | string         | no       | All commited filenames must **not** match this, e.g. `(jar|exe)$` |
| `max_file_size` **(STARTER)**                 | integer        | no       | Maximum file size (MB) |
| `commit_committer_check` **(PREMIUM)**        | boolean        | no       | Users can only push commits to this repository that were committed with one of their own verified emails. |
| `reject_unsigned_commits` **(PREMIUM)**        | boolean        | no       | Reject commits when they are not GPG signed. |

### Delete project push rule

> Introduced in [GitLab Starter](https://about.gitlab.com/pricing/) 9.0.

Removes a push rule from a project. This is an idempotent method and can be called multiple times.
Either the push rule is available or not.

```
DELETE /projects/:id/push_rule
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

## Transfer a project to a new namespace

> Introduced in GitLab 11.1.

```
PUT /projects/:id/transfer
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `namespace` | integer/string | yes | The ID or path of the namespace to transfer to project to |

## Branches

Read more in the [Branches](branches.md) documentation.

## Project Import/Export

Read more in the [Project import/export](project_import_export.md) documentation.

## Project members

Read more in the [Project members](members.md) documentation.

## Start the pull mirroring process for a Project **(STARTER)**

> Introduced in [GitLab Starter](https://about.gitlab.com/pricing/) 10.3.

```
POST /projects/:id/mirror/pull
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/mirror/pull
```

## Project badges

Read more in the [Project Badges](project_badges.md) documentation.

## Issue and merge request description templates

The non-default [issue and merge request description templates](../user/project/description_templates.md) are managed inside the project's repository. So you can manage them via the API through the [Repositories API](repositories.md) and the [Repository Files API](repository_files.md).

## Download snapshot of a Git repository

> Introduced in GitLab 10.7

This endpoint may only be accessed by an administrative user.

Download a snapshot of the project (or wiki, if requested) Git repository. This
snapshot is always in uncompressed [tar](https://en.wikipedia.org/wiki/Tar_(computing))
format.

If a repository is corrupted to the point where `git clone` does not work, the
snapshot may allow some of the data to be retrieved.

```
GET /projects/:id/snapshot
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `wiki`    | boolean | no | Whether to download the wiki, rather than project, repository |

[ce-27427]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/27427
