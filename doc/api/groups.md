---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Groups API

## List groups

Get a list of visible groups for the authenticated user. When accessed without
authentication, only public groups are returned.

By default, this request returns 20 results at a time because the API results [are paginated](index.md#pagination).

Parameters:

| Attribute                | Type              | Required | Description |
| ------------------------ | ----------------- | -------- | ---------- |
| `skip_groups`            | array of integers | no       | Skip the group IDs passed |
| `all_available`          | boolean           | no       | Show all the groups you have access to (defaults to `false` for authenticated users, `true` for administrators); Attributes `owned` and `min_access_level` have precedence |
| `search`                 | string            | no       | Return the list of authorized groups matching the search criteria |
| `order_by`               | string            | no       | Order groups by `name`, `path`, `id`, or `similarity` (if searching, [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332889) in GitLab 14.1). Default is `name` |
| `sort`                   | string            | no       | Order groups in `asc` or `desc` order. Default is `asc` |
| `statistics`             | boolean           | no       | Include group statistics (administrators only) |
| `with_custom_attributes` | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only) |
| `owned`                  | boolean           | no       | Limit to groups explicitly owned by the current user |
| `min_access_level`       | integer           | no       | Limit to groups where current user has at least this [access level](members.md#valid-access-levels) |
| `top_level_only`         | boolean           | no       | Limit to top level groups, excluding all subgroups |

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
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch_protection": 2,
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "created_at": "2020-01-15T12:36:29.590Z"
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
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch_protection": 2,
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "created_at": "2020-01-15T12:36:29.590Z",
    "statistics": {
      "storage_size" : 363,
      "repository_size" : 33,
      "wiki_size" : 100,
      "lfs_objects_size" : 123,
      "job_artifacts_size" : 57,
      "packages_size": 0,
      "snippets_size" : 50
    }
  }
]
```

You can search for groups by name or path, see below.

You can filter by [custom attributes](custom_attributes.md) with:

```plaintext
GET /groups?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

## List a group's subgroups

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/15142) in GitLab 10.3.

Get a list of visible direct subgroups in this group.
When accessed without authentication, only public groups are returned.

By default, this request returns 20 results at a time because the API results [are paginated](index.md#pagination).

Parameters:

| Attribute                | Type              | Required | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | integer/string    | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) of the immediate parent group |
| `skip_groups`            | array of integers | no       | Skip the group IDs passed |
| `all_available`          | boolean           | no       | Show all the groups you have access to (defaults to `false` for authenticated users, `true` for administrators); Attributes `owned` and `min_access_level` have precedence |
| `search`                 | string            | no       | Return the list of authorized groups matching the search criteria |
| `order_by`               | string            | no       | Order groups by `name`, `path` or `id`. Default is `name` |
| `sort`                   | string            | no       | Order groups in `asc` or `desc` order. Default is `asc` |
| `statistics`             | boolean           | no       | Include group statistics (administrators only) |
| `with_custom_attributes` | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only) |
| `owned`                  | boolean           | no       | Limit to groups explicitly owned by the current user |
| `min_access_level`       | integer           | no       | Limit to groups where current user has at least this [access level](members.md#valid-access-levels) |

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
    "mentions_disabled": null,
    "lfs_enabled": true,
    "default_branch_protection": 2,
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://gitlab.example.com/groups/foo-bar",
    "request_access_enabled": false,
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": 123,
    "created_at": "2020-01-15T12:36:29.590Z"
  }
]
```

## List a group's descendant groups

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217115) in GitLab 13.5

Get a list of visible descendant groups of this group.
When accessed without authentication, only public groups are returned.

By default, this request returns 20 results at a time because the API results [are paginated](index.md#pagination).

Parameters:

| Attribute                | Type              | Required | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | integer/string    | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) of the immediate parent group |
| `skip_groups`            | array of integers | no       | Skip the group IDs passed |
| `all_available`          | boolean           | no       | Show all the groups you have access to (defaults to `false` for authenticated users, `true` for administrators). Attributes `owned` and `min_access_level` have precedence |
| `search`                 | string            | no       | Return the list of authorized groups matching the search criteria |
| `order_by`               | string            | no       | Order groups by `name`, `path`, or `id`. Default is `name` |
| `sort`                   | string            | no       | Order groups in `asc` or `desc` order. Default is `asc` |
| `statistics`             | boolean           | no       | Include group statistics (administrators only) |
| `with_custom_attributes` | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only) |
| `owned`                  | boolean           | no       | Limit to groups explicitly owned by the current user |
| `min_access_level`       | integer           | no       | Limit to groups where current user has at least this [access level](members.md#valid-access-levels) |

```plaintext
GET /groups/:id/descendant_groups
```

```json
[
  {
    "id": 2,
    "name": "Bar Group",
    "path": "foo/bar",
    "description": "A subgroup of Foo Group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
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
    "path": "foo/bar/baz",
    "description": "A subgroup of Bar Group",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "owner",
    "emails_disabled": null,
    "mentions_disabled": null,
    "lfs_enabled": true,
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

## List a group's projects

Get a list of projects in this group. When accessed without authentication, only public projects are returned.

By default, this request returns 20 results at a time because the API results [are paginated](index.md#pagination).

```plaintext
GET /groups/:id/projects
```

Parameters:

| Attribute                     | Type           | Required | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `archived`                    | boolean        | no       | Limit by archived status |
| `visibility`                  | string         | no       | Limit by visibility `public`, `internal`, or `private` |
| `order_by`                    | string         | no       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `similarity` (1), or `last_activity_at` fields. Default is `created_at` |
| `sort`                        | string         | no       | Return projects sorted in `asc` or `desc` order. Default is `desc` |
| `search`                      | string         | no       | Return list of authorized projects matching the search criteria |
| `simple`                      | boolean        | no       | Return only the ID, URL, name, and path of each project |
| `owned`                       | boolean        | no       | Limit by projects owned by the current user |
| `starred`                     | boolean        | no       | Limit by projects starred by the current user |
| `with_issues_enabled`         | boolean        | no       | Limit by projects with issues feature enabled. Default is `false` |
| `with_merge_requests_enabled` | boolean        | no       | Limit by projects with merge requests feature enabled. Default is `false` |
| `with_shared`                 | boolean        | no       | Include projects shared to this group. Default is `true` |
| `include_subgroups`           | boolean        | no       | Include projects in subgroups of this group. Default is `false`   |
| `min_access_level`            | integer        | no       | Limit to projects where current user has at least this [access level](members.md#valid-access-levels) |
| `with_custom_attributes`      | boolean        | no       | Include [custom attributes](custom_attributes.md) in response (administrators only) |
| `with_security_reports`       | boolean        | no       | **(ULTIMATE)** Return only projects that have security reports artifacts present in any of their builds. This means "projects with security reports enabled". Default is `false` |

1. Order by similarity: Orders the results by a similarity score calculated from the provided `search`
URL parameter. This is an [alpha](https://about.gitlab.com/handbook/product/gitlab-the-product/#alpha) feature [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/221043) in GitLab 13.3.

   The feature is behind a feature flag, you can [enable it](../administration/feature_flags.md#enable-or-disable-the-feature)
with the `similarity_search` flag. When using `order_by=similarity` the `sort` parameter is
ignored. When the `search` parameter is not provided, the API returns the projects ordered by `name`.

Example response:

```json
[
  {
    "id": 9,
    "description": "foo",
    "default_branch": "master",
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

By default, this request returns 20 results at a time because the API results [are paginated](index.md#pagination).

```plaintext
GET /groups/:id/projects/shared
```

Parameters:

| Attribute                     | Type           | Required | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `archived`                    | boolean        | no       | Limit by archived status |
| `visibility`                  | string         | no       | Limit by visibility `public`, `internal`, or `private` |
| `order_by`                    | string         | no       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at` |
| `sort`                        | string         | no       | Return projects sorted in `asc` or `desc` order. Default is `desc` |
| `search`                      | string         | no       | Return list of authorized projects matching the search criteria |
| `simple`                      | boolean        | no       | Return only the ID, URL, name, and path of each project |
| `starred`                     | boolean        | no       | Limit by projects starred by the current user |
| `with_issues_enabled`         | boolean        | no       | Limit by projects with issues feature enabled. Default is `false` |
| `with_merge_requests_enabled` | boolean        | no       | Limit by projects with merge requests feature enabled. Default is `false` |
| `min_access_level`            | integer        | no       | Limit to projects where current user has at least this [access level](members.md#valid-access-levels) |
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
      "default_branch":"master",
      "tag_list":[], //deprecated, use `topics` instead
      "topics":[],
      "ssh_url_to_repo":"ssh://git@gitlab.com/h5bp/html5-boilerplate.git",
      "http_url_to_repo":"http://gitlab.com/h5bp/html5-boilerplate.git",
      "web_url":"http://gitlab.com/h5bp/html5-boilerplate",
      "readme_url":"http://gitlab.com/h5bp/html5-boilerplate/-/blob/master/README.md",
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
         "web_url":"http://gitlab.com/groups/h5bp"
      },
      "_links":{
         "self":"http://gitlab.com/api/v4/projects/8",
         "issues":"http://gitlab.com/api/v4/projects/8/issues",
         "merge_requests":"http://gitlab.com/api/v4/projects/8/merge_requests",
         "repo_branches":"http://gitlab.com/api/v4/projects/8/repository/branches",
         "labels":"http://gitlab.com/api/v4/projects/8/labels",
         "events":"http://gitlab.com/api/v4/projects/8/events",
         "members":"http://gitlab.com/api/v4/projects/8/members"
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
      "emails_disabled":null,
      "shared_runners_enabled":true,
      "lfs_enabled":true,
      "creator_id":1,
      "import_status":"failed",
      "open_issues_count":10,
      "ci_default_git_depth":50,
      "ci_forward_deployment_enabled":true,
      "public_jobs":true,
      "build_timeout":3600,
      "auto_cancel_pending_pipelines":"enabled",
      "build_coverage_regex":null,
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

Get all details of a group. This endpoint can be accessed without authentication
if the group is publicly accessible. In case the user that requests is administrator of the group, it returns the `runners_token` for the group too.

```plaintext
GET /groups/:id
```

Parameters:

| Attribute                | Type           | Required | Description |
| ------------------------ | -------------- | -------- | ----------- |
| `id`                     | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user. |
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
  "full_name": "Twitter",
  "full_path": "twitter",
  "runners_token": "ba324ca7b1c77fc20bb9",
  "file_template_project_id": 1,
  "parent_id": null,
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
      "default_branch": "master",
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
      "default_branch": "master",
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
      "default_branch": "master",
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
  ]
}
```

The `prevent_sharing_groups_outside_hierarchy` attribute is present only on top-level groups.

Users of [GitLab Premium or higher](https://about.gitlab.com/pricing/) also see
the `shared_runners_minutes_limit` and `extra_shared_runners_minutes_limit` parameters:

Additional response parameters:

```json
{
  "id": 4,
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  ...
}
```

Users of [GitLab Premium or higher](https://about.gitlab.com/pricing/) also see
the `marked_for_deletion_on` attribute:

```json
{
  "id": 4,
  "description": "Aliquid qui quis dignissimos distinctio ut commodi voluptas est.",
  "marked_for_deletion_on": "2020-04-03",
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

### Disable the results limit **(FREE SELF)**

The 100 results limit can break integrations developed using GitLab 12.4 and earlier.

For GitLab 12.5 to GitLab 13.12, the limit can be disabled while migrating to using the
[list a group's projects](#list-a-groups-projects) endpoint.

Ask a GitLab administrator with Rails console access to run the following command:

```ruby
Feature.disable(:limit_projects_in_groups_api)
```

For GitLab 14.0 and later, the [limit cannot be disabled](https://gitlab.com/gitlab-org/gitlab/-/issues/257829).

## New group

Creates a new project group. Available only for users who can create groups.

```plaintext
POST /groups
```

Parameters:

| Attribute                            | Type    | Required | Description |
| ------------------------------------ | ------- | -------- | ----------- |
| `name`                               | string  | yes      | The name of the group. |
| `path`                               | string  | yes      | The path of the group. |
| `description`                        | string  | no       | The group's description. |
| `membership_lock`                    | boolean | no       | **(PREMIUM)** Prevent adding new members to project membership within this group. |
| `visibility`                         | string  | no       | The group's visibility. Can be `private`, `internal`, or `public`. |
| `share_with_group_lock`              | boolean | no       | Prevent sharing a project with another group within this group. |
| `require_two_factor_authentication`  | boolean | no       | Require all users in this group to setup Two-factor authentication. |
| `two_factor_grace_period`            | integer | no       | Time before Two-factor authentication is enforced (in hours). |
| `project_creation_level`             | string  | no       | Determine if developers can create projects in the group. Can be `noone` (No one), `maintainer` (Maintainers), or `developer` (Developers + Maintainers). |
| `auto_devops_enabled`                | boolean | no       | Default to Auto DevOps pipeline for all projects within this group. |
| `subgroup_creation_level`            | string  | no       | Allowed to [create subgroups](../user/group/subgroups/index.md#creating-a-subgroup). Can be `owner` (Owners), or `maintainer` (Maintainers). |
| `emails_disabled`                    | boolean | no       | Disable email notifications |
| `avatar`                             | mixed   | no       | Image file for avatar of the group. [Introduced in GitLab 12.9](https://gitlab.com/gitlab-org/gitlab/-/issues/36681) |
| `mentions_disabled`                  | boolean | no       | Disable the capability of a group from getting mentioned |
| `lfs_enabled`                        | boolean | no       | Enable/disable Large File Storage (LFS) for the projects in this group. |
| `request_access_enabled`             | boolean | no       | Allow users to request member access. |
| `parent_id`                          | integer | no       | The parent group ID for creating nested group. |
| `default_branch_protection`          | integer | no       | See [Options for `default_branch_protection`](#options-for-default_branch_protection). Default to the global level default branch protection setting.      |
| `shared_runners_minutes_limit`       | integer | no       | **(PREMIUM SELF)** Pipeline minutes quota for this group (included in plan). Can be `nil` (default; inherit system default), `0` (unlimited) or `> 0` |
| `extra_shared_runners_minutes_limit` | integer | no       | **(PREMIUM SELF)** Extra pipeline minutes quota for this group (purchased in addition to the minutes included in the plan). |

NOTE:
On GitLab SaaS, you must use the GitLab UI to create groups without a parent group. You cannot
use the API to do this.

### Options for `default_branch_protection`

The `default_branch_protection` attribute determines whether developers and maintainers can push to the applicable [default branch](../user/project/repository/branches/default.md), as described in the following table:

| Value | Description |
|-------|-------------------------------------------------------------------------------------------------------------|
| `0`   | No protection. Developers and maintainers can:  <br>- Push new commits<br>- Force push changes<br>- Delete the branch |
| `1`   | Partial protection. Developers and maintainers can:  <br>- Push new commits |
| `2`   | Full protection. Only maintainers can:  <br>- Push new commits |

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

Transfer a project to the Group namespace. Available only to instance administrators, although an [alternative API endpoint](projects.md#transfer-a-project-to-a-new-namespace) is available which does not require instance administrator access. Transferring projects may fail when tagged packages exist in the project's repository.

```plaintext
POST  /groups/:id/projects/:project_id
```

Parameters:

| Attribute    | Type           | Required | Description |
| ------------ | -------------- | -------- | ----------- |
| `id`         | integer/string | yes      | The ID or [URL-encoded path of the target group](index.md#namespaced-path-encoding) |
| `project_id` | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/4/projects/56"
```

## Update group

Updates the project group. Only available to group owners and administrators.

```plaintext
PUT /groups/:id
```

| Attribute                                  | Type    | Required | Description |
| ------------------------------------------ | ------- | -------- | ----------- |
| `id`                                       | integer | yes      | The ID of the group. |
| `name`                                     | string  | no       | The name of the group. |
| `path`                                     | string  | no       | The path of the group. |
| `description`                              | string  | no       | The description of the group. |
| `membership_lock`                          | boolean | no       | **(PREMIUM)** Prevent adding new members to project membership within this group. |
| `share_with_group_lock`                    | boolean | no       | Prevent sharing a project with another group within this group. |
| `visibility`                               | string  | no       | The visibility level of the group. Can be `private`, `internal`, or `public`. |
| `require_two_factor_authentication`        | boolean | no       | Require all users in this group to setup Two-factor authentication. |
| `two_factor_grace_period`                  | integer | no       | Time before Two-factor authentication is enforced (in hours). |
| `project_creation_level`                   | string  | no       | Determine if developers can create projects in the group. Can be `noone` (No one), `maintainer` (Maintainers), or `developer` (Developers + Maintainers). |
| `auto_devops_enabled`                      | boolean | no       | Default to Auto DevOps pipeline for all projects within this group. |
| `subgroup_creation_level`                  | string  | no       | Allowed to [create subgroups](../user/group/subgroups/index.md#creating-a-subgroup). Can be `owner` (Owners), or `maintainer` (Maintainers). |
| `emails_disabled`                          | boolean | no       | Disable email notifications |
| `avatar`                                   | mixed   | no       | Image file for avatar of the group. [Introduced in GitLab 12.9](https://gitlab.com/gitlab-org/gitlab/-/issues/36681) |
| `mentions_disabled`                        | boolean | no       | Disable the capability of a group from getting mentioned |
| `lfs_enabled` (optional)                   | boolean | no       | Enable/disable Large File Storage (LFS) for the projects in this group. |
| `request_access_enabled`                   | boolean | no       | Allow users to request member access. |
| `default_branch_protection`                | integer | no       | See [Options for `default_branch_protection`](#options-for-default_branch_protection). |
| `file_template_project_id`                 | integer | no       | **(PREMIUM)** The ID of a project to load custom file templates from. |
| `shared_runners_minutes_limit`             | integer | no       | **(PREMIUM SELF)** Pipeline minutes quota for this group (included in plan). Can be `nil` (default; inherit system default), `0` (unlimited) or `> 0` |
| `extra_shared_runners_minutes_limit`       | integer | no       | **(PREMIUM SELF)** Extra pipeline minutes quota for this group (purchased in addition to the minutes included in the plan). |
| `prevent_forking_outside_group`            | boolean | no       | **(PREMIUM)** When enabled, users can **not** fork projects from this group to external namespaces
| `shared_runners_setting`                   | string  | no       | See [Options for `shared_runners_setting`](#options-for-shared_runners_setting). Enable or disable shared runners for a group's subgroups and projects. |
| `prevent_sharing_groups_outside_hierarchy` | boolean | no       | See [Prevent group sharing outside the group hierarchy](../user/group/index.md#prevent-group-sharing-outside-the-group-hierarchy). This attribute is only available on top-level groups. [Introduced in GitLab 14.1](https://gitlab.com/gitlab-org/gitlab/-/issues/333721) |

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
  "full_name": "Foobar Group",
  "full_path": "foo-bar",
  "file_template_project_id": 1,
  "parent_id": null,
  "created_at": "2020-01-15T12:36:29.590Z",
  "prevent_sharing_groups_outside_hierarchy": false,
  "projects": [ // Deprecated and will be removed in API v5
    {
      "id": 9,
      "description": "foo",
      "default_branch": "master",
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
  ]
}
```

The `prevent_sharing_groups_outside_hierarchy` attribute is present in the response only for top-level groups.

### Disable the results limit **(FREE SELF)**

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
| `disabled_with_override`       | Disables shared runners for all projects and subgroups in this group, but allows subgroups to override this setting. |
| `disabled_and_unoverridable`   | Disables shared runners for all projects and subgroups in this group, and prevents subgroups from overriding this setting. |

### Upload a group avatar

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36681) in GitLab 12.9.

To upload an avatar file from your file system, use the `--form` argument. This causes
curl to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to a file on your file system and be preceded by
`@`. For example:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22" \
     --form "avatar=@/tmp/example.png"
```

## Remove group

Only available to group owners and administrators.

This endpoint either:

- Removes group, and queues a background job to delete all projects in the group as well.
- Since [GitLab 12.8](https://gitlab.com/gitlab-org/gitlab/-/issues/33257), on [Premium](https://about.gitlab.com/pricing/) or higher tiers, marks a group for deletion. The deletion happens 7 days later by default, but this can be changed in the [instance settings](../user/admin_area/settings/visibility_and_access_controls.md#default-deletion-delay).

```plaintext
DELETE /groups/:id
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |

The response is `202 Accepted` if the user has authorization.

NOTE:
A GitLab.com group can't be removed if it is linked to a subscription. To remove such a group, first [link the subscription](../subscriptions/index.md#change-the-linked-namespace) with a different group.

## Restore group marked for deletion **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/33257) in GitLab 12.8.

Restores a group marked for deletion.

```plaintext
POST /groups/:id/restore
```

Parameters:

| Attribute       | Type           | Required | Description |
| --------------- | -------------- | -------- | ----------- |
| `id`            | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |

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

## Hooks **(PREMIUM)**

Also called Group Hooks and Webhooks.
These are different from [System Hooks](system_hooks.md) that are system wide and [Project Hooks](projects.md#hooks) that are limited to one project.

### List group hooks

Get a list of group hooks

```plaintext
GET /groups/:id/hooks
```

| Attribute | Type            | Required | Description |
| --------- | --------------- | -------- | ----------- |
| `id`      | integer/string  | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |

### Get group hook

Get a specific hook for a group.

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
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
  "enable_ssl_verification": true,
  "created_at": "2012-10-12T17:04:47Z"
}
```

### Add group hook

Adds a hook to a specified group.

```plaintext
POST /groups/:id/hooks
```

| Attribute                    | Type           | Required | Description |
| -----------------------------| -------------- | ---------| ----------- |
| `id`                         | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `url`                        | string         | yes      | The hook URL |
| `push_events`                | boolean        | no       | Trigger hook on push events |
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
| `enable_ssl_verification`    | boolean        | no       | Do SSL verification when triggering the hook |
| `token`                      | string         | no       | Secret token to validate received payloads; not returned in the response |

### Edit group hook

Edits a hook for a specified group.

```plaintext
PUT /groups/:id/hooks/:hook_id
```

| Attribute                    | Type           | Required | Description |
| ---------------------------- | -------------- | -------- | ----------- |
| `id`                         | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `hook_id`                    | integer        | yes      | The ID of the group hook |
| `url`                        | string         | yes      | The hook URL |
| `push_events`                | boolean        | no       | Trigger hook on push events |
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
| `enable_ssl_verification`    | boolean        | no       | Do SSL verification when triggering the hook |
| `token`                      | string         | no       | Secret token to validate received payloads; not returned in the response |

### Delete group hook

Removes a hook from a group. This is an idempotent method and can be called multiple times.
Either the hook is available or not.

```plaintext
DELETE /groups/:id/hooks/:hook_id
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `hook_id` | integer        | yes      | The ID of the group hook. |

## Group Audit Events **(PREMIUM)**

Group audit events can be accessed via the [Group Audit Events API](audit_events.md#group-audit-events)

## Sync group with LDAP **(PREMIUM SELF)**

Syncs the group with its linked LDAP group. Only available to group owners and administrators.

```plaintext
POST /groups/:id/ldap_sync
```

Parameters:

- `id` (required) - The ID or path of a user group

## Group members

Please consult the [Group Members](members.md) documentation.

## LDAP Group Links

List, add, and delete LDAP group links.

### List LDAP group links **(PREMIUM SELF)**

Lists LDAP group links.

```plaintext
GET /groups/:id/ldap_group_links
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |

### Add LDAP group link with CN or filter **(PREMIUM SELF)**

Adds an LDAP group link using a CN or filter. Adding a group link by filter is only supported in the Premium tier and above.

```plaintext
POST /groups/:id/ldap_group_links
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `cn`      | string         | no       | The CN of an LDAP group |
| `filter`  | string         | no       | The LDAP filter for the group |
| `group_access` | integer   | yes      | Minimum [access level](members.md#valid-access-levels) for members of the LDAP group |
| `provider` | string        | yes      | LDAP provider for the LDAP group link |

NOTE:
To define the LDAP group link, provide either a `cn` or a `filter`, but not both.

### Delete LDAP group link **(PREMIUM SELF)**

Deletes an LDAP group link. Deprecated. Scheduled for removal in a future release.

```plaintext
DELETE /groups/:id/ldap_group_links/:cn
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `cn`      | string         | yes      | The CN of an LDAP group |

Deletes an LDAP group link for a specific LDAP provider. Deprecated. Scheduled for removal in a future release.

```plaintext
DELETE /groups/:id/ldap_group_links/:provider/:cn
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `cn`      | string         | yes      | The CN of an LDAP group |
| `provider` | string        | yes      | LDAP provider for the LDAP group link |

### Delete LDAP group link with CN or filter **(PREMIUM SELF)**

Deletes an LDAP group link using a CN or filter. Deleting by filter is only supported in the Premium tier and above.

```plaintext
DELETE /groups/:id/ldap_group_links
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `cn`      | string         | no       | The CN of an LDAP group |
| `filter`  | string         | no       | The LDAP filter for the group |
| `provider` | string        | yes       | LDAP provider for the LDAP group link |

NOTE:
To delete the LDAP group link, provide either a `cn` or a `filter`, but not both.

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

These endpoints create and delete links for sharing a group with another group. For more information, see the related discussion in the [GitLab Groups](../user/group/index.md#share-a-group-with-another-group) page.

### Create a link to share a group with another group

Share group with another group. Returns `200` and the [group details](#details-of-a-group) on success.

```plaintext
POST /groups/:id/share
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `group_id` | integer | yes | The ID of the group to share with |
| `group_access` | integer | yes | The [access level](members.md#valid-access-levels) to grant the group |
| `expires_at` | string | no | Share expiration date in ISO 8601 format: 2016-09-26 |

### Delete link sharing group with another group

Unshare the group from another group. Returns `204` and no content on success.

```plaintext
DELETE /groups/:id/share/:group_id
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `group_id` | integer | yes | The ID of the group to share with |

## Push Rules **(PREMIUM)**

> Introduced in [GitLab](https://about.gitlab.com/pricing/) 13.4.

### Get group push rules **(PREMIUM)**

Get the [push rules](../user/group/index.md#group-push-rules) of a group.

Only available to group owners and administrators.

```plaintext
GET /groups/:id/push_rule
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID of the group or [URL-encoded path of the group](index.md#namespaced-path-encoding) |

```json
{
  "id": 2,
  "created_at": "2020-08-17T19:09:19.580Z",
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

Users on GitLab [Premium or higher](https://about.gitlab.com/pricing/) also see
the `commit_committer_check` and `reject_unsigned_commits` parameters:

```json
{
  "id": 2,
  "created_at": "2020-08-17T19:09:19.580Z",
  "commit_committer_check": true,
  "reject_unsigned_commits": false,
  ...
}
```

### Add group push rule **(PREMIUM)**

Adds [push rules](../user/group/index.md#group-push-rules) to the specified group.

Only available to group owners and administrators.

```plaintext
POST /groups/:id/push_rule
```

| Attribute                                     | Type           | Required | Description |
| --------------------------------------------- | -------------- | -------- | ----------- |
| `id`                                          | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `deny_delete_tag`                             | boolean        | no       | Deny deleting a tag |
| `member_check`                                | boolean        | no       | Allows only GitLab users to author commits |
| `prevent_secrets`                             | boolean        | no       | [Files that are likely to contain secrets](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml) are rejected |
| `commit_message_regex`                        | string         | no       | All commit messages must match the regular expression provided in this attribute, e.g. `Fixed \d+\..*` |
| `commit_message_negative_regex`               | string         | no       | Commit messages matching the regular expression provided in this attribute aren't allowed, e.g. `ssh\:\/\/` |
| `branch_name_regex`                           | string         | no       | All branch names must match the regular expression provided in this attribute, e.g. `(feature|hotfix)\/*` |
| `author_email_regex`                          | string         | no       | All commit author emails must match the regular expression provided in this attribute, e.g. `@my-company.com$` |
| `file_name_regex`                             | string         | no       | Filenames matching the regular expression provided in this attribute are **not** allowed, e.g. `(jar|exe)$` |
| `max_file_size`                               | integer        | no       | Maximum file size (MB) allowed |
| `commit_committer_check`                      | boolean        | no       | Only commits pushed using verified emails are allowed |
| `reject_unsigned_commits`                     | boolean        | no       | Only commits signed through GPG are allowed |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/19/push_rule"
```

Response:

```json
{
    "id": 19,
    "created_at": "2020-08-31T15:53:00.073Z",
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

### Edit group push rule **(PREMIUM)**

Edit push rules for a specified group.

Only available to group owners and administrators.

```plaintext
PUT /groups/:id/push_rule
```

| Attribute                                     | Type           | Required | Description |
| --------------------------------------------- | -------------- | -------- | ----------- |
| `id`                                          | integer/string | yes      | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
| `deny_delete_tag`                             | boolean        | no       | Deny deleting a tag |
| `member_check`                                | boolean        | no       | Restricts commits to be authored by existing GitLab users only |
| `prevent_secrets`                             | boolean        | no       | [Files that are likely to contain secrets](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml) are rejected |
| `commit_message_regex`                        | string         | no       | All commit messages must match the regular expression provided in this attribute, e.g. `Fixed \d+\..*` |
| `commit_message_negative_regex`               | string         | no       | Commit messages matching the regular expression provided in this attribute aren't allowed, e.g. `ssh\:\/\/` |
| `branch_name_regex`                           | string         | no       | All branch names must match the regular expression provided in this attribute, e.g. `(feature|hotfix)\/*` |
| `author_email_regex`                          | string         | no       | All commit author emails must match the regular expression provided in this attribute, e.g. `@my-company.com$` |
| `file_name_regex`                             | string         | no       | Filenames matching the regular expression provided in this attribute are **not** allowed, e.g. `(jar|exe)$` |
| `max_file_size`                               | integer        | no       | Maximum file size (MB) allowed |
| `commit_committer_check`                      | boolean        | no       | Only commits pushed using verified emails are allowed |
| `reject_unsigned_commits`                     | boolean        | no       | Only commits signed through GPG are allowed |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/19/push_rule"
```

Response:

```json
{
    "id": 19,
    "created_at": "2020-08-31T15:53:00.073Z",
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

### Delete group push rule **(PREMIUM)**

Deletes the [push rules](../user/group/index.md#group-push-rules) of a group.

Only available to group owners and administrators.

```plaintext
DELETE /groups/:id/push_rule
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) |
