---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Groups API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Interact with [groups](../user/group/index.md) by using the REST API.

The fields returned in responses vary based on the [permissions](../user/permissions.md) of the authenticated user.

## List groups

> - Support for keyset pagination introduced in GitLab 14.3.

Get a list of visible groups for the authenticated user. When accessed without
authentication, only public groups are returned.

By default, this request returns 20 results at a time because the API results [are paginated](rest/index.md#pagination).

When accessed without authentication, this endpoint also supports [keyset pagination](rest/index.md#keyset-based-pagination):

- When requesting consecutive pages of results, you should use keyset pagination.
- Beyond a specific offset limit (specified by [max offset allowed by the REST API for offset-based pagination](../administration/instance_limits.md#max-offset-allowed-by-the-rest-api-for-offset-based-pagination)), offset pagination is unavailable.

Parameters:

| Attribute                             | Type              | Required | Description |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `skip_groups`                         | array of integers | no       | Skip the group IDs passed |
| `all_available`                       | boolean           | no       | Show all the groups you have access to (defaults to `false` for authenticated users, `true` for administrators); Attributes `owned` and `min_access_level` have precedence |
| `search`                              | string            | no       | Return the list of authorized groups matching the search criteria |
| `order_by`                            | string            | no       | Order groups by `name`, `path`, `id`, or `similarity` (if searching, [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332889) in GitLab 14.1). Default is `name` |
| `sort`                                | string            | no       | Order groups in `asc` or `desc` order. Default is `asc` |
| `statistics`                          | boolean           | no       | Include group statistics (administrators only).<br>*Note:* The REST API response does not provide the full `RootStorageStatistics` data that is shown in the UI. To match the data in the UI, use GraphQL instead of REST. For more information, see the [Group GraphQL API resources](../api/graphql/reference/index.md#group).|
| `visibility`                          | string            | no       | Limit to groups with `public`, `internal`, or `private` visibility. |
| `with_custom_attributes`              | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only) |
| `owned`                               | boolean           | no       | Limit to groups explicitly owned by the current user |
| `min_access_level`                    | integer           | no       | Limit to groups where current user has at least this [role (`access_level`)](members.md#roles) |
| `top_level_only`                      | boolean           | no       | Limit to top level groups, excluding all subgroups |
| `repository_storage`                  | string            | no       | Filter by repository storage used by the group _(administrators only)_. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419643) in GitLab 16.3. Premium and Ultimate only. |

```plaintext
GET /groups
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "created_at": "2020-01-15T12:36:29.590Z",
    "ip_restriction_ranges": null
  }
]
```

When adding the parameter `statistics=true` and the authenticated user is an administrator, additional group statistics are returned.

```plaintext
GET /groups?statistics=true
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "created_at": "2020-01-15T12:36:29.590Z",
    "statistics": {
      "storage_size": 363,
      "repository_size": 33,
      "wiki_size": 100,
      "lfs_objects_size": 123,
      "job_artifacts_size": 57,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 50,
      "uploads_size": 0
    },
    "wiki_access_level": "private",
    "duo_features_enabled": true,
    "lock_duo_features_enabled": false,
  }
]
```

Users of [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see the `wiki_access_level`,
`duo_features_enabled`, and `lock_duo_features_enabled` attributes.

You can search for groups by name or path, see below.

You can filter by [custom attributes](custom_attributes.md) with:

```plaintext
GET /groups?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

## List a group's subgroups

Get a list of visible direct subgroups in this group.

By default, this request returns 20 results at a time because the API results [are paginated](rest/index.md#pagination).

If you request this list as:

- An unauthenticated user, the response returns only public groups.
- An authenticated user, the response returns only the groups you're
  a member of and does not include public groups.

Parameters:

| Attribute                | Type              | Required | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | integer/string    | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) of the immediate parent group |
| `skip_groups`            | array of integers | no       | Skip the group IDs passed |
| `all_available`          | boolean           | no       | Show all the groups you have access to (defaults to `false` for authenticated users, `true` for administrators); Attributes `owned` and `min_access_level` have precedence |
| `search`                 | string            | no       | Return the list of authorized groups matching the search criteria. Only subgroup short paths are searched (not full paths) |
| `order_by`               | string            | no       | Order groups by `name`, `path` or `id`. Default is `name` |
| `sort`                   | string            | no       | Order groups in `asc` or `desc` order. Default is `asc` |
| `statistics`             | boolean           | no       | Include group statistics (administrators only) |
| `with_custom_attributes` | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only) |
| `owned`                  | boolean           | no       | Limit to groups explicitly owned by the current user |
| `min_access_level`       | integer           | no       | Limit to groups where current user has at least this [role (`access_level`)](members.md#roles) |

```plaintext
GET /groups/:id/subgroups
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://gitlab.example.com/groups/foo-bar",
    "request_access_enabled": false,
    "repository_storage": "default",
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  }
]
```

Users of [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see the `wiki_access_level`,
`duo_features_enabled`, and `lock_duo_features_enabled` attributes.

## List a group's descendant groups

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217115) in GitLab 13.5

Get a list of visible descendant groups of this group.
When accessed without authentication, only public groups are returned.

By default, this request returns 20 results at a time because the API results [are paginated](rest/index.md#pagination).

Parameters:

| Attribute                | Type              | Required | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | integer/string    | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) of the immediate parent group |
| `skip_groups`            | array of integers | no       | Skip the group IDs passed |
| `all_available`          | boolean           | no       | Show all the groups you have access to (defaults to `false` for authenticated users, `true` for administrators). Attributes `owned` and `min_access_level` have precedence |
| `search`                 | string            | no       | Return the list of authorized groups matching the search criteria. Only descendant group short paths are searched (not full paths) |
| `order_by`               | string            | no       | Order groups by `name`, `path`, or `id`. Default is `name` |
| `sort`                   | string            | no       | Order groups in `asc` or `desc` order. Default is `asc` |
| `statistics`             | boolean           | no       | Include group statistics (administrators only) |
| `with_custom_attributes` | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only) |
| `owned`                  | boolean           | no       | Limit to groups explicitly owned by the current user |
| `min_access_level`       | integer           | no       | Limit to groups where current user has at least this [role (`access_level`)](members.md#roles) |

```plaintext
GET /groups/:id/descendant_groups
```

```json
[
  {
    "id": 2,
    "name": "Bar Group",
    "path": "bar",
    "description": "A subgroup of Foo Group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "request_access_enabled": false,
    "full_name": "Bar Group",
    "full_path": "foo/bar",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  },
  {
    "id": 3,
    "name": "Baz Group",
    "path": "baz",
    "description": "A subgroup of Bar Group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "emails_enabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch": null,
    "default_branch_protection": 2,
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/baz.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar/baz",
    "request_access_enabled": false,
    "full_name": "Baz Group",
    "full_path": "foo/bar/baz",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  }
]
```

Users of [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see the `wiki_access_level`,
`duo_features_enabled`, and `lock_duo_features_enabled` attributes.

## List a group's projects

Get a list of projects in this group. When accessed without authentication, only public projects are returned.

By default, this request returns 20 results at a time because the API results [are paginated](rest/index.md#pagination).

```plaintext
GET /groups/:id/projects
```

Parameters:

| Attribute                              | Type           | Required | Description |
| -------------------------------------- | -------------- | -------- | ----------- |
| `id`                                   | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `archived`                             | boolean        | no       | Limit by archived status |
| `visibility`                           | string         | no       | Limit by visibility `public`, `internal`, or `private` |
| `order_by`                             | string         | no       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `similarity` <sup>1</sup>, `star_count` or `last_activity_at` fields. Default is `created_at` |
| `sort`                                 | string         | no       | Return projects sorted in `asc` or `desc` order. Default is `desc` |
| `search`                               | string         | no       | Return list of authorized projects matching the search criteria |
| `simple`                               | boolean        | no       | Return only limited fields for each project. This is a no-op without authentication where only simple fields are returned. |
| `owned`                                | boolean        | no       | Limit by projects owned by the current user |
| `starred`                              | boolean        | no       | Limit by projects starred by the current user |
| `topic`                                | string         | no       | Return projects matching the topic |
| `with_issues_enabled`                  | boolean        | no       | Limit by projects with issues feature enabled. Default is `false` |
| `with_merge_requests_enabled`          | boolean        | no       | Limit by projects with merge requests feature enabled. Default is `false` |
| `with_shared`                          | boolean        | no       | Include projects shared to this group. Default is `true` |
| `include_subgroups`                    | boolean        | no       | Include projects in subgroups of this group. Default is `false` |
| `min_access_level`                     | integer        | no       | Limit to projects where current user has at least this [role (`access_level`)](members.md#roles) |
| `with_custom_attributes`               | boolean        | no       | Include [custom attributes](custom_attributes.md) in response (administrators only) |
| `with_security_reports`                | boolean    | no       | Return only projects that have security reports artifacts present in any of their builds. This means "projects with security reports enabled". Default is `false`. Ultimate only. |

**Footnotes:**

1. Orders the results by a similarity score calculated from the `search` URL parameter.
   When you use `order_by=similarity`, the `sort` parameter is ignored.
   When the `search` parameter is not provided, the API returns the projects ordered by `name`.

Example response:

```json
[
  {
    "id": 9,
    "description": "foo",
    "default_branch": "main",
    "tag_list": [], //deprecated, use `topics` instead
    "topics": [],
    "archived": false,
    "visibility": "internal",
    "ssh_url_to_repo": "git@gitlab.example.com/html5-boilerplate.git",
    "http_url_to_repo": "http://gitlab.example.com/h5bp/html5-boilerplate.git",
    "web_url": "http://gitlab.example.com/h5bp/html5-boilerplate",
    "name": "Html5 Boilerplate",
    "name_with_namespace": "Experimental / Html5 Boilerplate",
    "path": "html5-boilerplate",
    "path_with_namespace": "h5bp/html5-boilerplate",
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "jobs_enabled": true,
    "snippets_enabled": true,
    "created_at": "2016-04-05T21:40:50.169Z",
    "last_activity_at": "2016-04-06T16:52:08.432Z",
    "shared_runners_enabled": true,
    "creator_id": 1,
    "namespace": {
      "id": 5,
      "name": "Experimental",
      "path": "h5bp",
      "kind": "group"
    },
    "avatar_url": null,
    "star_count": 1,
    "forks_count": 0,
    "open_issues_count": 3,
    "public_jobs": true,
    "shared_with_groups": [],
    "request_access_enabled": false
  }
]
```

NOTE:
To distinguish between a project in the group and a project shared to the group, the `namespace` attribute can be used. When a project has been shared to the group, its `namespace` differs from the group the request is being made for.

## List a group's shared projects

Get a list of projects shared to this group. When accessed without authentication, only public shared projects are returned.

By default, this request returns 20 results at a time because the API results [are paginated](rest/index.md#pagination).

```plaintext
GET /groups/:id/projects/shared
```

Parameters:

| Attribute                     | Type           | Required | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `archived`                    | boolean        | no       | Limit by archived status |
| `visibility`                  | string         | no       | Limit by visibility `public`, `internal`, or `private` |
| `order_by`                    | string         | no       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `star_count` or `last_activity_at` fields. Default is `created_at` |
| `sort`                        | string         | no       | Return projects sorted in `asc` or `desc` order. Default is `desc` |
| `search`                      | string         | no       | Return list of authorized projects matching the search criteria |
| `simple`                      | boolean        | no       | Return only limited fields for each project. This is a no-op without authentication where only simple fields are returned. |
| `starred`                     | boolean        | no       | Limit by projects starred by the current user |
| `with_issues_enabled`         | boolean        | no       | Limit by projects with issues feature enabled. Default is `false` |
| `with_merge_requests_enabled` | boolean        | no       | Limit by projects with merge requests feature enabled. Default is `false` |
| `min_access_level`            | integer        | no       | Limit to projects where current user has at least this [role (`access_level`)](members.md#roles) |
| `with_custom_attributes`      | boolean        | no       | Include [custom attributes](custom_attributes.md) in response (administrators only) |

Example response:

```json
[
   {
      "id":8,
      "description":"Shared project for Html5 Boilerplate",
      "name":"Html5 Boilerplate",
      "name_with_namespace":"H5bp / Html5 Boilerplate",
      "path":"html5-boilerplate",
      "path_with_namespace":"h5bp/html5-boilerplate",
      "created_at":"2020-04-27T06:13:22.642Z",
      "default_branch":"main",
      "tag_list":[], //deprecated, use `topics` instead
      "topics":[],
      "ssh_url_to_repo":"ssh://git@gitlab.com/h5bp/html5-boilerplate.git",
      "http_url_to_repo":"https://gitlab.com/h5bp/html5-boilerplate.git",
      "web_url":"https://gitlab.com/h5bp/html5-boilerplate",
      "readme_url":"https://gitlab.com/h5bp/html5-boilerplate/-/blob/main/README.md",
      "avatar_url":null,
      "star_count":0,
      "forks_count":4,
      "last_activity_at":"2020-04-27T06:13:22.642Z",
      "namespace":{
         "id":28,
         "name":"H5bp",
         "path":"h5bp",
         "kind":"group",
         "full_path":"h5bp",
         "parent_id":null,
         "avatar_url":null,
         "web_url":"https://gitlab.com/groups/h5bp"
      },
      "_links":{
         "self":"https://gitlab.com/api/v4/projects/8",
         "issues":"https://gitlab.com/api/v4/projects/8/issues",
         "merge_requests":"https://gitlab.com/api/v4/projects/8/merge_requests",
         "repo_branches":"https://gitlab.com/api/v4/projects/8/repository/branches",
         "labels":"https://gitlab.com/api/v4/projects/8/labels",
         "events":"https://gitlab.com/api/v4/projects/8/events",
         "members":"https://gitlab.com/api/v4/projects/8/members"
      },
      "empty_repo":false,
      "archived":false,
      "visibility":"public",
      "resolve_outdated_diff_discussions":false,
      "container_registry_enabled":true,
      "container_expiration_policy":{
         "cadence":"7d",
         "enabled":true,
         "keep_n":null,
         "older_than":null,
         "name_regex":null,
         "name_regex_keep":null,
         "next_run_at":"2020-05-04T06:13:22.654Z"
      },
      "issues_enabled":true,
      "merge_requests_enabled":true,
      "wiki_enabled":true,
      "jobs_enabled":true,
      "snippets_enabled":true,
      "can_create_merge_request_in":true,
      "issues_access_level":"enabled",
      "repository_access_level":"enabled",
      "merge_requests_access_level":"enabled",
      "forking_access_level":"enabled",
      "wiki_access_level":"enabled",
      "builds_access_level":"enabled",
      "snippets_access_level":"enabled",
      "pages_access_level":"enabled",
      "security_and_compliance_access_level":"enabled",
      "emails_disabled":null,
      "emails_enabled": null,
      "shared_runners_enabled":true,
      "lfs_enabled":true,
      "creator_id":1,
      "import_status":"failed",
      "open_issues_count":10,
      "ci_default_git_depth":50,
      "ci_forward_deployment_enabled":true,
      "ci_forward_deployment_rollback_allowed": true,
      "ci_allow_fork_pipelines_to_run_in_parent_project":true,
      "public_jobs":true,
      "build_timeout":3600,
      "auto_cancel_pending_pipelines":"enabled",
      "ci_config_path":null,
      "shared_with_groups":[
         {
            "group_id":24,
            "group_name":"Commit451",
            "group_full_path":"Commit451",
            "group_access_level":30,
            "expires_at":null
         }
      ],
      "only_allow_merge_if_pipeline_succeeds":false,
      "request_access_enabled":true,
      "only_allow_merge_if_all_discussions_are_resolved":false,
      "remove_source_branch_after_merge":true,
      "printing_merge_request_link_enabled":true,
      "merge_method":"merge",
      "suggestion_commit_message":null,
      "auto_devops_enabled":true,
      "auto_devops_deploy_strategy":"continuous",
      "autoclose_referenced_issues":true,
      "repository_storage":"default"
   }
]
```

## Details of a group

> - The `membership_lock` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82271) in GitLab 14.10.

Get all details of a group. This endpoint can be accessed without authentication
if the group is publicly accessible. In case the user that requests is an administrator
if the group is publicly accessible. With authentication, it returns the `runners_token` and `enabled_git_access_protocol`
for the group too, if the user is an administrator or group owner.

```plaintext
GET /groups/:id
```

Parameters:

| Attribute                | Type           | Required | Description |
| ------------------------ | -------------- | -------- | ----------- |
| `id`                     | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `with_custom_attributes` | boolean        | no       | Include [custom attributes](custom_attributes.md) in response (administrators only). |
| `with_projects`          | boolean        | no       | Include details from projects that belong to the specified group (defaults to `true`). (Deprecated, [scheduled for removal in API v5](https://gitlab.com/gitlab-org/gitlab/-/issues/213797). To get the details of all projects within a group, use the [list a group's projects endpoint](#list-a-groups-projects).)  |

NOTE:
The `projects` and `shared_projects` attributes in the response are deprecated and [scheduled for removal in API v5](https://gitlab.com/gitlab-org/gitlab/-/issues/213797).
To get the details of all projects within a group, use either the [list a group's projects](#list-a-groups-projects) or the [list a group's shared projects](#list-a-groups-shared-projects) endpoint.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/4"
```

This endpoint returns:

- All projects and shared projects in GitLab 12.5 and earlier.
- A maximum of 100 projects and shared projects [in GitLab 12.6](https://gitlab.com/gitlab-org/gitlab/-/issues/31031)
  and later. To get the details of all projects within a group, use the
  [list a group's projects endpoint](#list-a-groups-projects) instead.

Example response:

```json
{
  "id": 4,
  "name": "Twitter",
  "path": "twitter",
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "visibility": "public",
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/twitter",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Twitter",
  "full_path": "twitter",
  "runners_token": "ba324ca7b1c77fc20bb9",
  "file_template_project_id": 1,
  "parent_id": null,
  "enabled_git_access_protocol": "all",
  "created_at": "2020-01-15T12:36:29.590Z",
  "shared_with_groups": [
    {
      "group_id": 28,
      "group_name": "H5bp",
      "group_full_path": "h5bp",
      "group_access_level": 20,
      "expires_at": null
    }
  ],
  "prevent_sharing_groups_outside_hierarchy": false,
  "projects": [ // Deprecated and will be removed in API v5
    {
      "id": 7,
      "description": "Voluptas veniam qui et beatae voluptas doloremque explicabo facilis.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "public",
      "ssh_url_to_repo": "git@gitlab.example.com:twitter/typeahead-js.git",
      "http_url_to_repo": "https://gitlab.example.com/twitter/typeahead-js.git",
      "web_url": "https://gitlab.example.com/twitter/typeahead-js",
      "name": "Typeahead.Js",
      "name_with_namespace": "Twitter / Typeahead.Js",
      "path": "typeahead-js",
      "path_with_namespace": "twitter/typeahead-js",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:25.578Z",
      "last_activity_at": "2016-06-17T07:47:25.881Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 4,
        "name": "Twitter",
        "path": "twitter",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 3,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    },
    {
      "id": 6,
      "description": "Aspernatur omnis repudiandae qui voluptatibus eaque.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "internal",
      "ssh_url_to_repo": "git@gitlab.example.com:twitter/flight.git",
      "http_url_to_repo": "https://gitlab.example.com/twitter/flight.git",
      "web_url": "https://gitlab.example.com/twitter/flight",
      "name": "Flight",
      "name_with_namespace": "Twitter / Flight",
      "path": "flight",
      "path_with_namespace": "twitter/flight",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:24.661Z",
      "last_activity_at": "2016-06-17T07:47:24.838Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 4,
        "name": "Twitter",
        "path": "twitter",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 8,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    }
  ],
  "shared_projects": [ // Deprecated and will be removed in API v5
    {
      "id": 8,
      "description": "Velit eveniet provident fugiat saepe eligendi autem.",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "archived": false,
      "visibility": "private",
      "ssh_url_to_repo": "git@gitlab.example.com:h5bp/html5-boilerplate.git",
      "http_url_to_repo": "https://gitlab.example.com/h5bp/html5-boilerplate.git",
      "web_url": "https://gitlab.example.com/h5bp/html5-boilerplate",
      "name": "Html5 Boilerplate",
      "name_with_namespace": "H5bp / Html5 Boilerplate",
      "path": "html5-boilerplate",
      "path_with_namespace": "h5bp/html5-boilerplate",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": false,
      "container_registry_enabled": true,
      "created_at": "2016-06-17T07:47:27.089Z",
      "last_activity_at": "2016-06-17T07:47:27.310Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 5,
        "name": "H5bp",
        "path": "h5bp",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 0,
      "forks_count": 0,
      "open_issues_count": 4,
      "public_jobs": true,
      "shared_with_groups": [
        {
          "group_id": 4,
          "group_name": "Twitter",
          "group_full_path": "twitter",
          "group_access_level": 30,
          "expires_at": null
        },
        {
          "group_id": 3,
          "group_name": "Gitlab Org",
          "group_full_path": "gitlab-org",
          "group_access_level": 10,
          "expires_at": "2018-08-14"
        }
      ]
    }
  ],
  "ip_restriction_ranges": null,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false
}
```

The `prevent_sharing_groups_outside_hierarchy` attribute is present only on top-level groups.

Users of [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see the attributes:

- `shared_runners_minutes_limit`
- `extra_shared_runners_minutes_limit`
- `marked_for_deletion_on`
- `membership_lock`
- `wiki_access_level`
- `duo_features_enabled`
- `lock_duo_features_enabled`

Additional response attributes:

```json
{
  "id": 4,
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  "marked_for_deletion_on": "2020-04-03",
  "membership_lock": false,
  "wiki_access_level": "disabled",
  "duo_features_enabled": true,
  "lock_duo_features_enabled": false,
  ...
}
```

When adding the parameter `with_projects=false`, projects aren't returned.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/4?with_projects=false"
```

Example response:

```json
{
  "id": 4,
  "name": "Twitter",
  "path": "twitter",
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "visibility": "public",
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/twitter",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Twitter",
  "full_path": "twitter",
  "file_template_project_id": 1,
  "parent_id": null
}
```

### Download a Group avatar

Get a group avatar. This endpoint can be accessed without authentication if the
group is publicly accessible.

```plaintext
GET /groups/:id/avatar
```

| Attribute | Type           | Required | Description           |
| --------- | -------------- | -------- | --------------------- |
| `id`      | integer/string | yes      | ID of the group       |

Example:

```shell
curl --header "PRIVATE-TOKEN: $GITLAB_LOCAL_TOKEN" \
  --remote-header-name \
  --remote-name \
  "https://gitlab.example.com/api/v4/groups/4/avatar"
```

### Disable the results limit

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

The 100 results limit can break integrations developed using GitLab 12.4 and earlier.

For GitLab 12.5 to GitLab 13.12, the limit can be disabled while migrating to using the
[list a group's projects](#list-a-groups-projects) endpoint.

Ask a GitLab administrator with Rails console access to run the following command:

```ruby
Feature.disable(:limit_projects_in_groups_api)
```

For GitLab 14.0 and later, the [limit cannot be disabled](https://gitlab.com/gitlab-org/gitlab/-/issues/257829).

## New group

NOTE:
On GitLab SaaS, you must use the GitLab UI to create groups without a parent group. You cannot
use the API to do this.

Creates a new project group. Available only for users who can create groups.

```plaintext
POST /groups
```

Parameters:

| Attribute                                               | Type    | Required | Description                                                                                                                                                                                     |
| ------------------------------------------------------- | ------- | -------- |-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`                                                  | string  | yes      | The name of the group.                                                                                                                                                                          |
| `path`                                                  | string  | yes      | The path of the group.                                                                                                                                                                          |
| `auto_devops_enabled`                                   | boolean | no       | Default to Auto DevOps pipeline for all projects within this group.                                                                                                                             |
| `avatar`                                                | mixed   | no       | Image file for avatar of the group. [Introduced in GitLab 12.9](https://gitlab.com/gitlab-org/gitlab/-/issues/36681)                                                                            |
| `default_branch`                                        | string  | no       | The [default branch](../user/project/repository/branches/default.md) name for group's projects. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442298) in GitLab 16.11.             |
| `default_branch_protection`                             | integer | no       | See [Options for `default_branch_protection`](#options-for-default_branch_protection). Default to the global level default branch protection setting.                                           |
| `default_branch_protection_defaults`                    | hash    | no       | See [Options for `default_branch_protection_defaults`](#options-for-default_branch_protection_defaults).                                                                                        |
| `description`                                           | string  | no       | The group's description.                                                                                                                                                                        |
| `enabled_git_access_protocol`                           | string  | no       | Enabled protocols for Git access. Allowed values are: `ssh`, `http`, and `all` to allow both protocols. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/436618) in GitLab 16.9. |
| `emails_disabled`                                       | boolean | no       | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899) in GitLab 16.5.)_ Disable email notifications. Use `emails_enabled` instead.                                       |
| `emails_enabled`                                        | boolean | no       | Enable email notifications.                                                                                                                                                                     |
| `lfs_enabled`                                           | boolean | no       | Enable/disable Large File Storage (LFS) for the projects in this group.                                                                                                                         |
| `mentions_disabled`                                     | boolean | no       | Disable the capability of a group from getting mentioned.                                                                                                                                       |
| `organization_id`                                       | integer | no       | The organization ID for the group.                                                                                                                                                              |
| `parent_id`                                             | integer | no       | The parent group ID for creating nested group.                                                                                                                                                  |
| `project_creation_level`                                | string  | no       | Determine if developers can create projects in the group. Can be `noone` (No one), `maintainer` (users with the Maintainer role), or `developer` (users with the Developer or Maintainer role). |
| `request_access_enabled`                                | boolean | no       | Allow users to request member access.                                                                                                                                                           |
| `require_two_factor_authentication`                     | boolean | no       | Require all users in this group to set up two-factor authentication.                                                                                                                            |
| `share_with_group_lock`                                 | boolean | no       | Prevent sharing a project with another group within this group.                                                                                                                                 |
| `subgroup_creation_level`                               | string  | no       | Allowed to [create subgroups](../user/group/subgroups/index.md#create-a-subgroup). Can be `owner` (Owners), or `maintainer` (users with the Maintainer role).                                   |
| `two_factor_grace_period`                               | integer | no       | Time before Two-factor authentication is enforced (in hours).                                                                                                                                   |
| `visibility`                                            | string  | no       | The group's visibility. Can be `private`, `internal`, or `public`.                                                                                                                              |
| `membership_lock`                                       | boolean | no       | Users cannot be added to projects in this group. Premium and Ultimate only.                                                                                              |
| `extra_shared_runners_minutes_limit`                    | integer | no       | Can be set by administrators only. Additional compute minutes for this group. Self-managed, Premium and Ultimate only.                                                                  |
| `shared_runners_minutes_limit`                          | integer | no       | Can be set by administrators only. Maximum number of monthly compute minutes for this group. Can be `nil` (default; inherit system default), `0` (unlimited), or `> 0`. Self-managed, Premium and Ultimate only.            |
| `wiki_access_level`                                     | string  | no       | The wiki access level. Can be `disabled`, `private`, or `enabled`. Premium and Ultimate only.                                                                       |

### Options for `default_branch_protection`

The `default_branch_protection` attribute determines whether users with the Developer or Maintainer role can push to the applicable [default branch](../user/project/repository/branches/default.md), as described in the following table:

| Value | Description |
|-------|-------------------------------------------------------------------------------------------------------------|
| `0`   | No protection. Users with the Developer or Maintainer role can:  <br>- Push new commits<br>- Force push changes<br>- Delete the branch |
| `1`   | Partial protection. Users with the Developer or Maintainer role can:  <br>- Push new commits |
| `2`   | Full protection. Only users with the Maintainer role can:  <br>- Push new commits |
| `3`   | Protected against pushes. Users with the Maintainer role can: <br>- Push new commits<br>- Force push changes<br>- Accept merge requests<br>Users with the Developer role can:<br>- Accept merge requests|
| `4`   | Full protection after initial push. User with the Developer role can: <br>- Push commit to empty repository.<br> Users with the Maintainer role can: <br>- Push new commits<br>- Accept merge requests|

### Options for `default_branch_protection_defaults`

The `default_branch_protection_defaults` attribute describes the default branch
protection defaults. All parameters are optional.

| Key                          | Type    | Description                                                                             |
|------------------------------|---------|-----------------------------------------------------------------------------------------|
| `allowed_to_push`            | array   | An array of access levels allowed to push. Supports Developer (30) or Maintainer (40).  |
| `allow_force_push`           | boolean | Allow force push for all users with push access.                                        |
| `allowed_to_merge`           | array   | An array of access levels allowed to merge. Supports Developer (30) or Maintainer (40). |
| `developer_can_initial_push` | boolean | Allow developers to initial push.                                                       |

## New Subgroup

This is similar to creating a [New group](#new-group). You need the `parent_id` from the [List groups](#list-groups) call. You can then enter the desired:

- `subgroup_path`
- `subgroup_name`

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"path": "<subgroup_path>", "name": "<subgroup_name>", "parent_id": <parent_group_id> }' \
     "https://gitlab.example.com/api/v4/groups/"
```

## Transfer project to group

Transfer a project to the Group namespace. Available only to instance administrators, although an [alternative API endpoint](projects.md#transfer-a-project-to-a-new-namespace)
is available which does not require administrator access on the instance. Transferring projects may fail when tagged packages exist in the project's repository.

```plaintext
POST  /groups/:id/projects/:project_id
```

Parameters:

| Attribute    | Type           | Required | Description |
| ------------ | -------------- | -------- | ----------- |
| `id`         | integer/string | yes      | The ID or [URL-encoded path of the target group](rest/index.md#namespaced-path-encoding) |
| `project_id` | integer/string | yes      | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/4/projects/56"
```

## Get groups to which a user can transfer a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371117) in GitLab 15.4

Retrieve a list of groups to which the user can transfer a group.

```plaintext
GET /groups/:id/transfer_locations
```

| Attribute   | Type           | Required               | Description |
|-------------|----------------|------------------------|-------------|
| `id`        | integer or string | Yes | The ID or [URL-encoded path of the group to be transferred](rest/index.md#namespaced-path-encoding). |
| `search` | string | No  | The group names to search for. |

Example request:

```shell
curl --request GET "https://gitlab.example.com/api/v4/groups/1/transfer_locations"
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

## Transfer a group to a new parent group / Turn a subgroup to a top-level group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23831) in GitLab 14.6.

Transfer a group to a new parent group or turn a subgroup to a top-level group. Available to administrators and users:

- With the Owner role for the group to transfer.
- With permission to [create a subgroup](../user/group/subgroups/index.md#create-a-subgroup) in the new parent group if transferring a group.
- With [permission to create a top-level group](../administration/user_settings.md) if turning a subgroup into a top-level group.

```plaintext
POST  /groups/:id/transfer
```

Parameters:

| Attribute    | Type           | Required | Description |
| ------------ | -------------- | -------- | ----------- |
| `id`         | integer | yes  | ID of the group to transfer. |
| `group_id`   | integer | no   | ID of the new parent group. When not specified, the group to transfer is instead turned into a top-level group. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/4/transfer?group_id=7"
```

## Update group

> - `unique_project_download_limit`, `unique_project_download_limit_interval_in_seconds`, and `unique_project_download_limit_allowlist` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92970) in GitLab 15.3 [with a flag](../administration/feature_flags.md) named `limit_unique_project_downloads_per_namespace_user`. Disabled by default.

FLAG:
On self-managed GitLab, by default `unique_project_download_limit`, `unique_project_download_limit_interval_in_seconds`, `unique_project_download_limit_allowlist` and `auto_ban_user_on_excessive_projects_download` are not available.
To make them available, an administrator can [enable the feature flag](../administration/feature_flags.md)
named `limit_unique_project_downloads_per_namespace_user`.

Updates the project group. Only available to group owners and administrators.

```plaintext
PUT /groups/:id
```

| Attribute                                               | Type    | Required | Description |
| ------------------------------------------------------- | ------- | -------- | ----------- |
| `id`                                                    | integer | yes      | The ID of the group. |
| `name`                                                  | string  | no       | The name of the group. |
| `path`                                                  | string  | no       | The path of the group. |
| `auto_devops_enabled`                                   | boolean | no       | Default to Auto DevOps pipeline for all projects within this group. |
| `avatar`                                                | mixed   | no       | Image file for avatar of the group. [Introduced in GitLab 12.9](https://gitlab.com/gitlab-org/gitlab/-/issues/36681) |
| `default_branch`                                        | string  | no       | The [default branch](../user/project/repository/branches/default.md) name for group's projects. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442298) in GitLab 16.11. |
| `default_branch_protection`                             | integer | no       | See [Options for `default_branch_protection`](#options-for-default_branch_protection). |
| `default_branch_protection_defaults`                    | hash    | no       | See [Options for `default_branch_protection_defaults`](#options-for-default_branch_protection_defaults). |
| `description`                                           | string  | no       | The description of the group. |
| `enabled_git_access_protocol`                           | string  | no       | Enabled protocols for Git access. Allowed values are: `ssh`, `http`, and `all` to allow both protocols. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/436618) in GitLab 16.9. |
| `emails_disabled`                                       | boolean | no       | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899) in GitLab 16.5.)_ Disable email notifications. Use `emails_enabled` instead. |
| `emails_enabled`                                        | boolean | no       | Enable email notifications. |
| `lfs_enabled`                                           | boolean | no       | Enable/disable Large File Storage (LFS) for the projects in this group. |
| `mentions_disabled`                                     | boolean | no       | Disable the capability of a group from getting mentioned. |
| `prevent_sharing_groups_outside_hierarchy`              | boolean | no       | See [Prevent group sharing outside the group hierarchy](../user/group/access_and_permissions.md#prevent-group-sharing-outside-the-group-hierarchy). This attribute is only available on top-level groups. [Introduced in GitLab 14.1](https://gitlab.com/gitlab-org/gitlab/-/issues/333721) |
| `project_creation_level`                                | string  | no       | Determine if developers can create projects in the group. Can be `noone` (No one), `maintainer` (users with the Maintainer role), or `developer` (users with the Developer or Maintainer role). |
| `request_access_enabled`                                | boolean | no       | Allow users to request member access. |
| `require_two_factor_authentication`                     | boolean | no       | Require all users in this group to set up two-factor authentication. |
| `shared_runners_setting`                                | string  | no       | See [Options for `shared_runners_setting`](#options-for-shared_runners_setting). Enable or disable shared runners for a group's subgroups and projects. |
| `share_with_group_lock`                                 | boolean | no       | Prevent sharing a project with another group within this group. |
| `subgroup_creation_level`                               | string  | no       | Allowed to [create subgroups](../user/group/subgroups/index.md#create-a-subgroup). Can be `owner` (Owners), or `maintainer` (users with the Maintainer role). |
| `two_factor_grace_period`                               | integer | no       | Time before Two-factor authentication is enforced (in hours). |
| `visibility`                                            | string  | no       | The visibility level of the group. Can be `private`, `internal`, or `public`. |
| `extra_shared_runners_minutes_limit`                    | integer | no       | Can be set by administrators only. Additional compute minutes for this group. Self-managed, Premium and Ultimate only. |
| `file_template_project_id`                              | integer | no       | The ID of a project to load custom file templates from. Premium and Ultimate only. |
| `membership_lock`                                       | boolean | no       | Users cannot be added to projects in this group. Premium and Ultimate only. |
| `prevent_forking_outside_group`                         | boolean | no       | When enabled, users can **not** fork projects from this group to external namespaces. Premium and Ultimate only. |
| `shared_runners_minutes_limit`                          | integer | no       | Can be set by administrators only. Maximum number of monthly compute minutes for this group. Can be `nil` (default; inherit system default), `0` (unlimited), or `> 0`. Self-managed, Premium and Ultimate only. |
| `unique_project_download_limit`                         | integer | no       | Maximum number of unique projects a user can download in the specified time period before they are banned. Available only on top-level groups. Default: 0, Maximum: 10,000. Ultimate only. |
| `unique_project_download_limit_interval_in_seconds`     | integer | no       | Time period during which a user can download a maximum amount of projects before they are banned. Available only on top-level groups. Default: 0, Maximum: 864,000 seconds (10 days). Ultimate only. |
| `unique_project_download_limit_allowlist`               | array of strings | no | List of usernames excluded from the unique project download limit. Available only on top-level groups. Default: `[]`, Maximum: 100 usernames. Ultimate only.|
| `unique_project_download_limit_alertlist`               | array of integers | no | List of user IDs that are emailed when the unique project download limit is exceeded. Available only on top-level groups. Default: `[]`, Maximum: 100 user IDs. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110201) in GitLab 15.9. Ultimate only.|
| `auto_ban_user_on_excessive_projects_download`          | boolean | no       | When enabled, users are automatically banned from the group when they download more than the maximum number of unique projects specified by `unique_project_download_limit` and `unique_project_download_limit_interval_in_seconds`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/94159) in GitLab 15.4. Ultimate only.|
| `ip_restriction_ranges`                                 | string  | no       | Comma-separated list of IP addresses or subnet masks to restrict group access. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/351493) in GitLab 15.4. Premium and Ultimate only.|
| `wiki_access_level`                                     | string  | no       | The wiki access level. Can be `disabled`, `private`, or `enabled`. Premium and Ultimate only.|
| `math_rendering_limits_enabled`                         | boolean | no       | Indicates if math rendering limits are used for this group.|
| `lock_math_rendering_limits_enabled`                    | boolean | no       | Indicates if math rendering limits are locked for all descendent groups.|
| `duo_features_enabled`                                  | boolean | no       | Indicates whether GitLab Duo features are enabled for this group. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931) in GitLab 16.10. Self-managed, Premium and Ultimate only. |
| `lock_duo_features_enabled`                             | boolean | no       | Indicates whether the GitLab Duo features enabled setting is enforced for all subgroups. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931) in GitLab 16.10. Self-managed, Premium and Ultimate only. |

NOTE:
The `projects` and `shared_projects` attributes in the response are deprecated and [scheduled for removal in API v5](https://gitlab.com/gitlab-org/gitlab/-/issues/213797).
To get the details of all projects within a group, use either the [list a group's projects](#list-a-groups-projects) or the [list a group's shared projects](#list-a-groups-shared-projects) endpoint.

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/5?name=Experimental"
```

This endpoint returns:

- All projects and shared projects in GitLab 12.5 and earlier.
- A maximum of 100 projects and shared projects [in GitLab 12.6](https://gitlab.com/gitlab-org/gitlab/-/issues/31031)
  and later. To get the details of all projects within a group, use the
  [list a group's projects endpoint](#list-a-groups-projects) instead.

Example response:

```json
{
  "id": 5,
  "name": "Experimental",
  "path": "h5bp",
  "description": "foo",
  "visibility": "internal",
  "avatar_url": null,
  "web_url": "http://gitlab.example.com/groups/h5bp",
  "request_access_enabled": false,
  "repository_storage": "default",
  "full_name": "Foobar Group",
  "full_path": "h5bp",
  "file_template_project_id": 1,
  "parent_id": null,
  "enabled_git_access_protocol": "all",
  "created_at": "2020-01-15T12:36:29.590Z",
  "prevent_sharing_groups_outside_hierarchy": false,
  "projects": [ // Deprecated and will be removed in API v5
    {
      "id": 9,
      "description": "foo",
      "default_branch": "main",
      "tag_list": [], //deprecated, use `topics` instead
      "topics": [],
      "public": false,
      "archived": false,
      "visibility": "internal",
      "ssh_url_to_repo": "git@gitlab.example.com/html5-boilerplate.git",
      "http_url_to_repo": "http://gitlab.example.com/h5bp/html5-boilerplate.git",
      "web_url": "http://gitlab.example.com/h5bp/html5-boilerplate",
      "name": "Html5 Boilerplate",
      "name_with_namespace": "Experimental / Html5 Boilerplate",
      "path": "html5-boilerplate",
      "path_with_namespace": "h5bp/html5-boilerplate",
      "issues_enabled": true,
      "merge_requests_enabled": true,
      "wiki_enabled": true,
      "jobs_enabled": true,
      "snippets_enabled": true,
      "created_at": "2016-04-05T21:40:50.169Z",
      "last_activity_at": "2016-04-06T16:52:08.432Z",
      "shared_runners_enabled": true,
      "creator_id": 1,
      "namespace": {
        "id": 5,
        "name": "Experimental",
        "path": "h5bp",
        "kind": "group"
      },
      "avatar_url": null,
      "star_count": 1,
      "forks_count": 0,
      "open_issues_count": 3,
      "public_jobs": true,
      "shared_with_groups": [],
      "request_access_enabled": false
    }
  ],
  "ip_restriction_ranges": null,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false
}
```

The `prevent_sharing_groups_outside_hierarchy` attribute is present in the response only for top-level groups.

Users of [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see the `wiki_access_level`,
`duo_features_enabled`, and`lock_duo_features_enabled` attributes.

### Disable the results limit

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

The 100 results limit can break integrations developed using GitLab 12.4 and earlier.

For GitLab 12.5 to GitLab 13.12, the limit can be disabled while migrating to using the
[list a group's projects](#list-a-groups-projects) endpoint.

Ask a GitLab administrator with Rails console access to run the following command:

```ruby
Feature.disable(:limit_projects_in_groups_api)
```

For GitLab 14.0 and later, the [limit cannot be disabled](https://gitlab.com/gitlab-org/gitlab/-/issues/257829).

### Options for `shared_runners_setting`

The `shared_runners_setting` attribute determines whether shared runners are enabled for a group's subgroups and projects.

| Value | Description |
|-------|-------------------------------------------------------------------------------------------------------------|
| `enabled`                      | Enables shared runners for all projects and subgroups in this group. |
| `disabled_and_overridable`     | Disables shared runners for all projects and subgroups in this group, but allows subgroups to override this setting. |
| `disabled_and_unoverridable`   | Disables shared runners for all projects and subgroups in this group, and prevents subgroups from overriding this setting. |
| `disabled_with_override`       | (Deprecated. Use `disabled_and_overridable`) Disables shared runners for all projects and subgroups in this group, but allows subgroups to override this setting. |

### Upload a group avatar

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36681) in GitLab 12.9.

To upload an avatar file from your file system, use the `--form` argument. This causes
curl to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to a file on your file system and be preceded by
`@`. For example:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22" \
     --form "avatar=@/tmp/example.png"
```

### Remove a group avatar

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96421) in GitLab 15.4.

To remove a group avatar, use a blank value for the `avatar` attribute.

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22" \
     --data "avatar="
```

## Remove group

> - Immediately deleting subgroups was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360008) in GitLab 15.3 [with a flag](../administration/feature_flags.md) named `immediate_delete_subgroup_api`. Disabled by default.
> - Immediately deleting subgroups was [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/368276) in GitLab 15.4.
> - Immediately deleting subgroups was [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/368276) by default in GitLab 15.4.
> - The flag `immediate_delete_subgroup_api` for immediately deleting subgroups was [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/374069) in GitLab 15.9.

Only available to group owners and administrators.

This endpoint:

- On Premium and Ultimate tiers, marks the group for deletion. The deletion happens 7 days later by default, but you can change the retention period in the [instance settings](../administration/settings/visibility_and_access_controls.md#deletion-protection).
- On Free tier, removes the group immediately and queues a background job to delete all projects in the group.
- Deletes a subgroup immediately if the subgroup is marked for deletion (GitLab 15.4 and later). The endpoint does not immediately delete top-level groups.

```plaintext
DELETE /groups/:id
```

Parameters:

| Attribute            | Type             | Required | Description                                                                                                                                                 |
|----------------------|------------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                 | integer/string   | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding)                                                                                |
| `permanently_remove` | boolean/string   | no       | Immediately deletes a subgroup if it is marked for deletion. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368276) in GitLab 15.4. Premium and Ultimate only. |
| `full_path`   | string           | no       | Full path of subgroup to use with `permanently_remove`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368276) in GitLab 15.4. To find the subgroup path, see the [group details](groups.md#details-of-a-group). Premium and Ultimate only. |

The response is `202 Accepted` if the user has authorization.

NOTE:
A GitLab.com group can't be removed if it is linked to a subscription. To remove such a group, first [link the subscription](../subscriptions/gitlab_com/index.md#change-the-linked-namespace) with a different group.

## Restore group marked for deletion

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33257) in GitLab 12.8.

Restores a group marked for deletion.

```plaintext
POST /groups/:id/restore
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |

## Search for group

Get all groups that match your string in their name or path.

```plaintext
GET /groups?search=foobar
```

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "path": "foo-bar",
    "description": "An interesting group"
  }
]
```

## List provisioned users

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Introduced in GitLab 14.8.

Get a list of users provisioned by a given group. Does not include subgroups.

Requires at least the Maintainer role on the group.

```plaintext
GET /groups/:id/provisioned_users
```

Parameters:

| Attribute        | Type           | Required | Description                                                              |
|:-----------------|:---------------|:---------|:-------------------------------------------------------------------------|
| `id`             | integer/string | yes      | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `username`       | string         | no       | Return single user with a specific username                              |
| `search`         | string         | no       | Search users by name, email, username                                    |
| `active`         | boolean        | no       | Return only active users                                                 |
| `blocked`        | boolean        | no       | Return only blocked users                                                |
| `created_after`  | datetime       | no       | Return users created after the specified time                            |
| `created_before` | datetime       | no       | Return users created before the specified time                           |

Example response:

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "John Doe22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [ ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  },
  ...
]
```

## List group users

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/424505) in GitLab 16.6. This feature is an [Experiment](../policy/experiment-beta-support.md).

Get a list of users for a group. This endpoint returns users that are related to a top-level group regardless
of their current membership. For example, users that have a SAML identity connected to the group, or service accounts created
by the group or subgroups.

This endpoint is an [Experiment](../policy/experiment-beta-support.md) and might be changed or removed without notice.

Requires Owner role in the group.

```plaintext
GET /groups/:id/users
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/users?include_saml_users=true&include_service_accounts=true"
```

Parameters:

| Attribute                  | Type           | Required                  | Description                                                                    |
|:---------------------------|:---------------|:--------------------------|:-------------------------------------------------------------------------------|
| `id`                       | integer/string | yes                       | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding). |
| `include_saml_users`       | boolean        | yes (see description)  | Include users with a SAML identity. Either this value or `include_service_accounts` must be `true`. |
| `include_service_accounts` | boolean        | yes (see description)  | Include service account users. Either this value or `include_saml_users` must be `true`. |
| `search`                   | string         | no                        | Search users by name, email, username.                                         |

If successful, returns [`200 OK`](../api/rest/index.md#status-codes) and the
following response attributes:

Example response:

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "John Doe22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [ ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  },
  ...
]
```

## Service Accounts

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

### Create Service Account User

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/407775) in GitLab 16.1.
> - Ability to specify a username or name was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841) in GitLab 16.10.

Creates a service account user. You can specify username and name. If you do not specify these attributes, the default name is `Service account user` and the username is automatically generated.

This API endpoint works on top-level groups only. It does not work on subgroups.

```plaintext
POST /groups/:id/service_accounts
```

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/345/service_accounts"
```

Supported attributes:

| Attribute                  | Type           | Required                  | Description                                                                    |
|:---------------------------|:---------------|:--------------------------|:-------------------------------------------------------------------------------|
| `name`       | string | no | Name of the user |
| `username`   | string | no | Username of the user |

Example response:

```json
{
  "id": 57,
  "username": "service_account_group_345_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user"
}
```

### Create Personal Access Token for Service Account User

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406781) in GitLab 16.1.

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens
```

This API endpoint works on top-level groups only. It does not work on subgroups.

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens" --data "scopes[]=api" --data "name=service_accounts_token"
```

Example response:

```json
{
  "id":6,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:47:13.900Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2024-06-12",
  "token":"<token_value>"
}
```

| Attribute | Type            | Required | Description |
| --------- | --------------- | -------- | ----------- |
| `expires_at`      | date | no      | Personal access token expiry date. When left blank, the token follows the [standard rule of expiry for personal access tokens](../user/profile/personal_access_tokens.md#when-personal-access-tokens-expire). |

### Rotate a Personal Access Token for Service Account User

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406781) in GitLab 16.1.

```plaintext
POST /groups/:id/service_accounts/:user_id/personal_access_tokens/:token_id/rotate
```

This API endpoint works on top-level groups only. It does not work on subgroups.

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/35/service_accounts/71/personal_access_tokens/6/rotate"
```

Example response:

```json
{
  "id":7,
  "name":"service_accounts_token",
  "revoked":false,
  "created_at":"2023-06-13T07:54:49.962Z",
  "scopes":["api"],
  "user_id":71,
  "last_used_at":null,
  "active":true,
  "expires_at":"2023-06-20",
  "token":"<token_value>"
}
```

## Hooks

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Also called Group Hooks and Webhooks.
These are different from [System Hooks](system_hooks.md) that are system wide and [Project Hooks](projects.md#hooks) that are limited to one project.

### List group hooks

Get a list of group hooks

```plaintext
GET /groups/:id/hooks
```

| Attribute | Type            | Required | Description |
| --------- | --------------- | -------- | ----------- |
| `id`      | integer/string  | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |

### Get group hook

Get a specific hook for a group.

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `hook_id` | integer        | yes      | The ID of a group hook |

```plaintext
GET /groups/:id/hooks/:hook_id
```

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "group_id": 3,
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
  "subgroup_events": true,
  "member_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z",
  "resource_access_token_events": true,
  "custom_webhook_template": "{\"event\":\"{{object_kind}}\"}"
}
```

### Add group hook

Adds a hook to a specified group.

```plaintext
POST /groups/:id/hooks
```

| Attribute                    | Type           | Required | Description |
| -----------------------------| -------------- |----------| ----------- |
| `id`                         | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `url`                        | string         | yes      | The hook URL |
| `push_events`                | boolean        | no       | Trigger hook on push events |
| `push_events_branch_filter`  | string         | No       | Trigger hook on push events for matching branches only. |
| `issues_events`              | boolean        | no       | Trigger hook on issues events |
| `confidential_issues_events` | boolean        | no       | Trigger hook on confidential issues events |
| `merge_requests_events`      | boolean        | no       | Trigger hook on merge requests events |
| `tag_push_events`            | boolean        | no       | Trigger hook on tag push events |
| `note_events`                | boolean        | no       | Trigger hook on note events |
| `confidential_note_events`   | boolean        | no       | Trigger hook on confidential note events |
| `job_events`                 | boolean        | no       | Trigger hook on job events |
| `pipeline_events`            | boolean        | no       | Trigger hook on pipeline events |
| `wiki_page_events`           | boolean        | no       | Trigger hook on wiki page events |
| `deployment_events`          | boolean        | no       | Trigger hook on deployment events |
| `releases_events`            | boolean        | no       | Trigger hook on release events |
| `subgroup_events`            | boolean        | no       | Trigger hook on subgroup events |
| `member_events`              | boolean        | no       | Trigger hook on member events |
| `enable_ssl_verification`    | boolean        | no       | Do SSL verification when triggering the hook |
| `token`                      | string         | no       | Secret token to validate received payloads; not returned in the response |
| `resource_access_token_events` | boolean         | no       | Trigger hook on project access token expiry events. |
| `custom_webhook_template`    | string         | No       | Custom webhook template for the hook. |

### Edit group hook

Edits a hook for a specified group.

```plaintext
PUT /groups/:id/hooks/:hook_id
```

| Attribute                    | Type           | Required | Description |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | integer or string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding). |
| `hook_id`                    | integer        | yes      | The ID of the group hook. |
| `url`                        | string         | yes      | The hook URL. |
| `push_events`                | boolean        | no       | Trigger hook on push events. |
| `push_events_branch_filter`  | string         | No       | Trigger hook on push events for matching branches only. |
| `issues_events`              | boolean        | no       | Trigger hook on issues events. |
| `confidential_issues_events` | boolean        | no       | Trigger hook on confidential issues events. |
| `merge_requests_events`      | boolean        | no       | Trigger hook on merge requests events. |
| `tag_push_events`            | boolean        | no       | Trigger hook on tag push events. |
| `note_events`                | boolean        | no       | Trigger hook on note events. |
| `confidential_note_events`   | boolean        | no       | Trigger hook on confidential note events. |
| `job_events`                 | boolean        | no       | Trigger hook on job events. |
| `pipeline_events`            | boolean        | no       | Trigger hook on pipeline events. |
| `wiki_page_events`           | boolean        | no       | Trigger hook on wiki page events. |
| `deployment_events`          | boolean        | no       | Trigger hook on deployment events. |
| `releases_events`            | boolean        | no       | Trigger hook on release events. |
| `subgroup_events`            | boolean        | no       | Trigger hook on subgroup events. |
| `member_events`              | boolean        | no       | Trigger hook on member events. |
| `enable_ssl_verification`    | boolean        | no       | Do SSL verification when triggering the hook. |
| `service_access_tokens_expiration_enforced` | boolean | no | Require service account access tokens to have an expiration date. |
| `token`                      | string         | no       | Secret token to validate received payloads. Not returned in the response. When you change the webhook URL, the secret token is reset and not retained. |
| `resource_access_token_events` | boolean      | no       | Trigger hook on project access token expiry events. |
| `custom_webhook_template`    | string         | No       | Custom webhook template for the hook. |

### Delete group hook

Removes a hook from a group. This is an idempotent method and can be called multiple times.
Either the hook is available or not.

```plaintext
DELETE /groups/:id/hooks/:hook_id
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `hook_id` | integer        | yes      | The ID of the group hook. |

## Group Audit Events

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

Group audit events can be accessed via the [Group Audit Events API](audit_events.md#group-audit-events)

## Sync group with LDAP

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

Syncs the group with its linked LDAP group. Only available to group owners and administrators.

```plaintext
POST /groups/:id/ldap_sync
```

Parameters:

- `id` (required) - The ID or path of a user group

## Group members

See the [Group Members](members.md) documentation.

## LDAP Group Links

List, add, and delete LDAP group links.

### List LDAP group links

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

Lists LDAP group links.

```plaintext
GET /groups/:id/ldap_group_links
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |

### Add LDAP group link with CN or filter

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

Adds an LDAP group link using a CN or filter. Adding a group link by filter is only supported in the Premium and Ultimate tier.

```plaintext
POST /groups/:id/ldap_group_links
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `cn`      | string         | no       | The CN of an LDAP group |
| `filter`  | string         | no       | The LDAP filter for the group |
| `group_access` | integer   | yes      | [Role (`access_level`)](members.md#roles) for members of the LDAP group |
| `provider` | string        | yes      | LDAP provider for the LDAP group link |

NOTE:
To define the LDAP group link, provide either a `cn` or a `filter`, but not both.

### Delete LDAP group link

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

Deletes an LDAP group link. Deprecated. Scheduled for removal in a future release.

```plaintext
DELETE /groups/:id/ldap_group_links/:cn
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `cn`      | string         | yes      | The CN of an LDAP group |

Deletes an LDAP group link for a specific LDAP provider. Deprecated. Scheduled for removal in a future release.

```plaintext
DELETE /groups/:id/ldap_group_links/:provider/:cn
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `cn`      | string         | yes      | The CN of an LDAP group |
| `provider` | string        | yes      | LDAP provider for the LDAP group link |

### Delete LDAP group link with CN or filter

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

Deletes an LDAP group link using a CN or filter. Deleting by filter is only supported in the Premium and Ultimate tier.

```plaintext
DELETE /groups/:id/ldap_group_links
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `cn`      | string         | no       | The CN of an LDAP group |
| `filter`  | string         | no       | The LDAP filter for the group |
| `provider` | string        | yes       | LDAP provider for the LDAP group link |

NOTE:
To delete the LDAP group link, provide either a `cn` or a `filter`, but not both.

## SAML Group Links

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/290367) in GitLab 15.3.0.
> - `access_level` type [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95607) from `string` to `integer` in GitLab 15.3.3.
> - `member_role_id` type [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/417201) in GitLab 16.7 [with a flag](../administration/feature_flags.md) named `custom_roles_for_saml_group_links`. Disabled by default.
> - `member_role_id` type [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/417201) in GitLab 16.8. Feature flag `custom_roles_for_saml_group_links` removed.

List, get, add, and delete SAML group links.

### List SAML group links

Lists SAML group links.

```plaintext
GET /groups/:id/saml_group_links
```

Supported attributes:

| Attribute | Type           | Required | Description                                                              |
|:----------|:---------------|:---------|:-------------------------------------------------------------------------|
| `id`      | integer/string | yes      | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |

If successful, returns [`200`](rest/index.md#status-codes) and the following response attributes:

| Attribute          | Type    | Description                                                                  |
|:-------------------|:--------|:-----------------------------------------------------------------------------|
| `[].name`          | string  | Name of the SAML group                                                       |
| `[].access_level`  | integer | [Role (`access_level`)](members.md#roles) for members of the SAML group. The attribute had a string type from GitLab 15.3.0 to GitLab 15.3.3 |
| `[].member_role_id` | integer | [Member Role ID (`member_role_id`)](member_roles.md) for members of the SAML group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/saml_group_links"
```

Example response:

```json
[
  {
    "name": "saml-group-1",
    "access_level": 10,
    "member_role_id": 12
  },
  {
    "name": "saml-group-2",
    "access_level": 40,
    "member_role_id": 99
  }
]
```

### Get SAML group link

Get a SAML group link for the group.

```plaintext
GET /groups/:id/saml_group_links/:saml_group_name
```

Supported attributes:

| Attribute          | Type           | Required | Description                                                              |
|:-------------------|:---------------|:---------|:-------------------------------------------------------------------------|
| `id`               | integer/string | yes      | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `saml_group_name`  | string         | yes      | Name of an SAML group                                                    |

If successful, returns [`200`](rest/index.md#status-codes) and the following response attributes:

| Attribute      | Type    | Description                                                                  |
|:---------------|:--------|:-----------------------------------------------------------------------------|
| `name`         | string  | Name of the SAML group                                                       |
| `access_level` | integer | [Role (`access_level`)](members.md#roles) for members of the SAML group. The attribute had a string type from GitLab 15.3.0 to GitLab 15.3.3 |
| `member_role_id` | integer | [Member Role ID (`member_role_id`)](member_roles.md) for members of the SAML group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

Example response:

```json
{
"name": "saml-group-1",
"access_level": 10,
"member_role_id": 12
}
```

### Add SAML group link

Adds a SAML group link for a group.

```plaintext
POST /groups/:id/saml_group_links
```

Supported attributes:

| Attribute          | Type           | Required | Description                                                                  |
|:-------------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`               | integer or string | yes      | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding)     |
| `saml_group_name`  | string         | yes      | Name of a SAML group                                                         |
| `access_level`     | integer        | yes      | [Role (`access_level`)](members.md#roles) for members of the SAML group |
| `member_role_id`   | integer        | no       | [Member Role ID (`member_role_id`)](member_roles.md) for members of the SAML group. |

If successful, returns [`201`](rest/index.md#status-codes) and the following response attributes:

| Attribute      | Type    | Description                                                                  |
|:---------------|:--------|:-----------------------------------------------------------------------------|
| `name`         | string  | Name of the SAML group                                                       |
| `access_level` | integer | [Role (`access_level`)](members.md#roles) for members of the for members of the SAML group. The attribute had a string type from GitLab 15.3.0 to GitLab 15.3.3 |
| `member_role_id` | integer | [Member Role ID (`member_role_id`)](member_roles.md) for members of the SAML group. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" --data '{ "saml_group_name": "<your_saml_group_name`>", "access_level": <chosen_access_level>, "member_role_id": <chosen_member_role_id> }' --url  "https://gitlab.example.com/api/v4/groups/1/saml_group_links"
```

Example response:

```json
{
"name": "saml-group-1",
"access_level": 10,
"member_role_id": 12
}
```

### Delete SAML group link

Deletes a SAML group link for the group.

```plaintext
DELETE /groups/:id/saml_group_links/:saml_group_name
```

Supported attributes:

| Attribute          | Type           | Required | Description                                                              |
|:-------------------|:---------------|:---------|:-------------------------------------------------------------------------|
| `id`               | integer/string | yes      | ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `saml_group_name`  | string         | yes      | Name of a SAML group                                                     |

If successful, returns [`204`](rest/index.md#status-codes) status code without any response body.

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

## Namespaces in groups

By default, groups only get 20 namespaces at a time because the API results are paginated.

To get more (up to 100), pass the following as an argument to the API call:

```plaintext
/groups?per_page=100
```

And to switch pages add:

```plaintext
/groups?per_page=100&page=2
```

## Group badges

Read more in the [Group Badges](group_badges.md) documentation.

## Group Import/Export

Read more in the [Group Import/Export](group_import_export.md)
and [Group Relations Export](group_relations_export.md)
documentation.

## Share Groups with Groups

These endpoints create and delete links for sharing a group with another group. For more information, see the related discussion in the [GitLab Groups](../user/group/manage.md#share-a-group-with-another-group) page.

### Create a link to share a group with another group

Share group with another group. Returns `200` and the [group details](#details-of-a-group) on success.

```plaintext
POST /groups/:id/share
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `group_id` | integer | yes | The ID of the group to share with |
| `group_access` | integer | yes | The [role (`access_level`)](members.md#roles) to grant the group |
| `expires_at` | string | no | Share expiration date in ISO 8601 format: 2016-09-26 |

### Delete link sharing group with another group

Unshare the group from another group. Returns `204` and no content on success.

```plaintext
DELETE /groups/:id/share/:group_id
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `group_id` | integer | yes | The ID of the group to share with |

## Push Rules

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - Introduced in GitLab 13.4.

### Get group push rules

Get the [push rules](../user/group/access_and_permissions.md#group-push-rules) of a group.

Only available to group owners and administrators.

```plaintext
GET /groups/:id/push_rule
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID of the group or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |

```json
{
  "id": 2,
  "created_at": "2020-08-17T19:09:19.580Z",
  "commit_committer_check": true,
  "commit_committer_name_check": true,
  "reject_unsigned_commits": false,
  "commit_message_regex": "[a-zA-Z]",
  "commit_message_negative_regex": "[x+]",
  "branch_name_regex": "[a-z]",
  "deny_delete_tag": true,
  "member_check": true,
  "prevent_secrets": true,
  "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
  "file_name_regex": "(exe)$",
  "max_file_size": 100
}
```

### Add group push rule

Adds [push rules](../user/group/access_and_permissions.md#group-push-rules) to the specified group.

Only available to group owners and administrators.

```plaintext
POST /groups/:id/push_rule
```

<!-- markdownlint-disable MD056 -->

| Attribute                                     | Type           | Required | Description |
| --------------------------------------------- | -------------- | -------- | ----------- |
| `id`                                          | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `deny_delete_tag`                             | boolean        | no       | Deny deleting a tag |
| `member_check`                                | boolean        | no       | Allows only GitLab users to author commits |
| `prevent_secrets`                             | boolean        | no       | [Files that are likely to contain secrets](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml) are rejected |
| `commit_committer_name_check`                 | boolean        | no       | Users can only push commits to this repository if the commit author name is consistent with their GitLab account name |
| `commit_message_regex`                        | string         | no       | All commit messages must match the regular expression provided in this attribute, for example, `Fixed \d+\..*` |
| `commit_message_negative_regex`               | string         | no       | Commit messages matching the regular expression provided in this attribute aren't allowed, for example, `ssh\:\/\/` |
| `branch_name_regex`                           | string         | no       | All branch names must match the regular expression provided in this attribute, for example, `(feature|hotfix)\/*` |
| `author_email_regex`                          | string         | no       | All commit author emails must match the regular expression provided in this attribute, for example, `@my-company.com$` |
| `file_name_regex`                             | string         | no       | Filenames matching the regular expression provided in this attribute are **not** allowed, for example, `(jar|exe)$` |
| `max_file_size`                               | integer        | no       | Maximum file size (MB) allowed |
| `commit_committer_check`                      | boolean        | no       | Only commits pushed using verified emails are allowed |
| `reject_unsigned_commits`                     | boolean        | no       | Only signed commits are allowed |

<!-- markdownlint-enable MD056 -->

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/19/push_rule"
```

Response:

```json
{
    "id": 19,
    "created_at": "2020-08-31T15:53:00.073Z",
    "commit_committer_name_check": false,
    "commit_message_regex": "[a-zA-Z]",
    "commit_message_negative_regex": "[x+]",
    "branch_name_regex": null,
    "deny_delete_tag": false,
    "member_check": false,
    "prevent_secrets": false,
    "author_email_regex": "^[A-Za-z0-9.]+@gitlab.com$",
    "file_name_regex": null,
    "max_file_size": 100
}
```

### Edit group push rule

Edit push rules for a specified group.

Only available to group owners and administrators.

```plaintext
PUT /groups/:id/push_rule
```

<!-- markdownlint-disable MD056 -->

| Attribute                                     | Type           | Required | Description |
| --------------------------------------------- | -------------- | -------- | ----------- |
| `id`                                          | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `deny_delete_tag`                             | boolean        | no       | Deny deleting a tag |
| `member_check`                                | boolean        | no       | Restricts commits to be authored by existing GitLab users only |
| `prevent_secrets`                             | boolean        | no       | [Files that are likely to contain secrets](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml) are rejected |
| `commit_committer_name_check`                 | boolean        | no       | Users can only push commits to this repository if the commit author name is consistent with their GitLab account name |
| `commit_message_regex`                        | string         | no       | All commit messages must match the regular expression provided in this attribute, for example, `Fixed \d+\..*` |
| `commit_message_negative_regex`               | string         | no       | Commit messages matching the regular expression provided in this attribute aren't allowed, for example, `ssh\:\/\/` |
| `branch_name_regex`                           | string         | no       | All branch names must match the regular expression provided in this attribute, for example, `(feature|hotfix)\/*` |
| `author_email_regex`                          | string         | no       | All commit author emails must match the regular expression provided in this attribute, for example, `@my-company.com$` |
| `file_name_regex`                             | string         | no       | Filenames matching the regular expression provided in this attribute are **not** allowed, for example, `(jar|exe)$` |
| `max_file_size`                               | integer        | no       | Maximum file size (MB) allowed |
| `commit_committer_check`                      | boolean        | no       | Only commits pushed using verified emails are allowed |
| `reject_unsigned_commits`                     | boolean        | no       | Only signed commits are allowed |

<!-- markdownlint-enable MD056 -->

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/19/push_rule"
```

Response:

```json
{
    "id": 19,
    "created_at": "2020-08-31T15:53:00.073Z",
    "commit_committer_name_check": false,
    "commit_message_regex": "[a-zA-Z]",
    "commit_message_negative_regex": "[x+]",
    "branch_name_regex": null,
    "deny_delete_tag": false,
    "member_check": false,
    "prevent_secrets": false,
    "author_email_regex": "^[A-Za-z0-9.]+@staging.gitlab.com$",
    "file_name_regex": null,
    "max_file_size": 100
}
```

### Delete group push rule

Deletes the [push rules](../user/group/access_and_permissions.md#group-push-rules) of a group.

Only available to group owners and administrators.

```plaintext
DELETE /groups/:id/push_rule
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
