---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Groups API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to view and manage GitLab groups. For more information, see [groups](../user/group/_index.md).

Endpoint responses might vary based on the [permissions](../user/permissions.md) of the authenticated user in the group.

## Get a single group

Get all details of a group. This endpoint can be accessed without authentication
if the group is publicly accessible. In case the user that requests is an administrator
if the group is publicly accessible. With authentication, it returns the `runners_token` and `enabled_git_access_protocol`
for the group too, if the user is an administrator or has the Owner role.

```plaintext
GET /groups/:id
```

Parameters:

| Attribute                | Type           | Required | Description |
|--------------------------|----------------|----------|-------------|
| `id`                     | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `with_custom_attributes` | boolean        | no       | Include [custom attributes](custom_attributes.md) in response (administrators only). |
| `with_projects`          | boolean        | no       | Include details from projects that belong to the specified group (defaults to `true`). (Deprecated, [scheduled for removal in API v5](https://gitlab.com/gitlab-org/gitlab/-/issues/213797). To get the details of all projects in a group, use the [list a group's projects endpoint](#list-projects).) |

{{< alert type="note" >}}

The `projects` and `shared_projects` attributes in the response are deprecated and [scheduled for removal in API v5](https://gitlab.com/gitlab-org/gitlab/-/issues/213797).
To get the details of all projects within a group, use either the [list a group's projects](#list-projects) or the [list a group's shared projects](#list-shared-projects) endpoint.

{{< /alert >}}

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/4"
```

This endpoint returns a maximum of 100 projects and shared projects. To get the details of all projects within a group, use the [list a group's projects endpoint](#list-projects) instead.

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
- `duo_availability`
- `experiment_features_enabled`

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
  "duo_availability": "default_on",
  "experiment_features_enabled": false,
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

## List groups

### List all groups

Get a list of visible groups for the authenticated user. When accessed without
authentication, only public groups are returned.

By default, this request returns 20 results at a time because the API results [are paginated](rest/_index.md#pagination).

When accessed without authentication, this endpoint also supports [keyset pagination](rest/_index.md#keyset-based-pagination):

- When requesting consecutive pages of results, you should use keyset pagination.
- Beyond a specific offset limit (specified by [max offset allowed by the REST API for offset-based pagination](../administration/instance_limits.md#max-offset-allowed-by-the-rest-api-for-offset-based-pagination)), offset pagination is unavailable.

Parameters:

| Attribute                | Type              | Required | Description |
|--------------------------|-------------------|----------|-------------|
| `skip_groups`            | array of integers | no       | Skip the group IDs passed. |
| `all_available`          | boolean           | no       | When `true`, returns all accessible groups. When `false`, returns only groups where the user is a member. Defaults to `false` for users, `true` for administrators. Unauthenticated requests always return all public groups. The `owned` and `min_access_level` attributes take precedence. |
| `search`                 | string            | no       | Return the list of authorized groups matching the search criteria. |
| `order_by`               | string            | no       | Order groups by `name`, `path`, `id`, or `similarity`. Default is `name`. |
| `sort`                   | string            | no       | Order groups in `asc` or `desc` order. Default is `asc`. |
| `statistics`             | boolean           | no       | Include group statistics (administrators only).<br> For top-level groups, the response returns the full `root_storage_statistics` data displayed in the UI. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/469254) in GitLab 17.4. |
| `visibility`             | string            | no       | Limit to groups with `public`, `internal`, or `private` visibility. |
| `with_custom_attributes` | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only). |
| `owned`                  | boolean           | no       | Limit to groups explicitly owned by the current user. |
| `min_access_level`       | integer           | no       | Limit to groups where current user has at least this [role (`access_level`)](members.md#roles). |
| `top_level_only`         | boolean           | no       | Limit to top-level groups, excluding all subgroups. |
| `repository_storage`     | string            | no       | Filter by repository storage used by the group (administrators only). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419643) in GitLab 16.3. Premium and Ultimate only. |
| `marked_for_deletion_on` | date              | no       | Filter by date when group was marked for deletion. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429315) in GitLab 17.1. Premium and Ultimate only. |
| `active`                 | boolean           | no       | Limit by groups that are not archived and not marked for deletion. |
| `archived`               | boolean           | no       | Limit by groups that are archived. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/519587) in GitLab 18.2. This parameter is an experiment. |

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
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
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

When adding the parameter `statistics=true` and the authenticated user is an administrator, additional group statistics are returned. For top-level groups, `root_storage_statistics` are added as well.

```plaintext
GET /groups?statistics=true
```

When the parameter `statistics=true` is used and the authenticated user is an administrator, the response includes information about container registry storage size:

- `container_registry_size`: Total storage size in bytes used by all container repositories in the group and its subgroups. Calculated as the sum of all repository sizes within the group's projects and subgroups. Available only when the container registry metadata database is enabled.

- `container_registry_size_is_estimated`: Indicates whether the size is an exact calculation based on actual data from all repositories (`false`) or estimated due to performance constraints (`true`).

For GitLab Self-Managed instances, the [container registry metadata database](../administration/packages/container_registry_metadata_database.md) must be enabled to include the container registry size attributes.

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
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
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
    "root_storage_statistics": {
      "build_artifacts_size": 0,
      "container_registry_size": 0,
      "container_registry_size_is_estimated": false,
      "dependency_proxy_size": 0,
      "lfs_objects_size": 0,
      "packages_size": 0,
      "pipeline_artifacts_size": 0,
      "repository_size": 0,
      "snippets_size": 0,
      "storage_size": 0,
      "uploads_size": 0,
      "wiki_size": 0
  },
    "wiki_access_level": "private",
    "duo_features_enabled": true,
    "lock_duo_features_enabled": false,
    "duo_availability": "default_on",
    "experiment_features_enabled": false,
  }
]
```

Users of [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see the `wiki_access_level`,
`duo_features_enabled`,
`lock_duo_features_enabled`,
`duo_availability`, and `experiment_features_enabled` attributes.

You can search for groups by name or path, see below.

You can filter by [custom attributes](custom_attributes.md) with:

```plaintext
GET /groups?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

#### Group pagination

By default, only 20 groups are displayed at a time because the API results are paginated.

To get more (up to 100), pass the following as an argument to the API call:

```plaintext
/groups?per_page=100
```

And to switch pages add:

```plaintext
/groups?per_page=100&page=2
```

### Search for a group

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

## List group details

### List projects

Get a list of projects in this group. When accessed without authentication, only public projects are returned.

By default, this request returns 20 results at a time because the API results [are paginated](rest/_index.md#pagination).

```plaintext
GET /groups/:id/projects
```

Parameters:

| Attribute                     | Type           | Required | Description |
|-------------------------------|----------------|----------|-------------|
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `archived`                    | boolean        | no       | Limit by archived status. |
| `visibility`                  | string         | no       | Limit by visibility `public`, `internal`, or `private`. |
| `order_by`                    | string         | no       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `similarity` <sup>1</sup>, `star_count` or `last_activity_at` fields. Default is `created_at`. |
| `sort`                        | string         | no       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `search`                      | string         | no       | Return list of authorized projects matching the search criteria. |
| `simple`                      | boolean        | no       | Return only limited fields for each project. This is a no-op without authentication where only simple fields are returned. |
| `owned`                       | boolean        | no       | Limit by projects owned by the current user. |
| `starred`                     | boolean        | no       | Limit by projects starred by the current user. |
| `topic`                       | string         | no       | Return projects matching the topic. |
| `with_issues_enabled`         | boolean        | no       | Limit by projects with issues feature enabled. Default is `false`. |
| `with_merge_requests_enabled` | boolean        | no       | Limit by projects with merge requests feature enabled. Default is `false`. |
| `with_shared`                 | boolean        | no       | Include projects shared to this group. Default is `true`. |
| `include_subgroups`           | boolean        | no       | Include projects in subgroups of this group. Default is `false`. |
| `min_access_level`            | integer        | no       | Limit to projects where current user has at least this [role (`access_level`)](members.md#roles). |
| `with_custom_attributes`      | boolean        | no       | Include [custom attributes](custom_attributes.md) in response (administrators only). |
| `with_security_reports`       | boolean        | no       | Return only projects that have security reports artifacts present in any of their builds. This means "projects with security reports enabled". Default is `false`. Ultimate only. |

**Footnotes**:

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

{{< alert type="note" >}}

To distinguish between a project in the group and a project shared to the group, the `namespace` attribute can be used. When a project has been shared to the group, its `namespace` differs from the group the request is being made for.

{{< /alert >}}

### List shared projects

Get a list of projects shared to this group. When accessed without authentication, only public shared projects are returned.

By default, this request returns 20 results at a time because the API results [are paginated](rest/_index.md#pagination).

```plaintext
GET /groups/:id/projects/shared
```

Parameters:

| Attribute                     | Type           | Required | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `archived`                    | boolean        | no       | Limit by archived status. |
| `visibility`                  | string         | no       | Limit by visibility `public`, `internal`, or `private`. |
| `order_by`                    | string         | no       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `star_count` or `last_activity_at` fields. Default is `created_at`. |
| `sort`                        | string         | no       | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `search`                      | string         | no       | Return list of authorized projects matching the search criteria. |
| `simple`                      | boolean        | no       | Return only limited fields for each project. This is a no-op without authentication where only simple fields are returned. |
| `starred`                     | boolean        | no       | Limit by projects starred by the current user. |
| `with_issues_enabled`         | boolean        | no       | Limit by projects with issues feature enabled. Default is `false`. |
| `with_merge_requests_enabled` | boolean        | no       | Limit by projects with merge requests feature enabled. Default is `false`. |
| `min_access_level`            | integer        | no       | Limit to projects where current user has at least this [role (`access_level`)](members.md#roles). |
| `with_custom_attributes`      | boolean        | no       | Include [custom attributes](custom_attributes.md) in response (administrators only). |

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

### List all SAML users

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193748) in GitLab 18.1.

{{< /history >}}

Lists all SAML users for a given top-level group.

Use the `page` and `per_page` [pagination parameters](rest/_index.md#offset-based-pagination) to filter the results.

```plaintext
GET /groups/:id/saml_users
```

Supported attributes:

| Attribute        | Type           | Required | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | integer/string | yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a top-level group. |
| `username`       | string         | no       | Return a user with a given username. |
| `search`         | string         | no       | Return users with a matching name, email, or username. Use partial values to increase results. |
| `active`         | boolean        | no       | Return only active users. |
| `blocked`        | boolean        | no       | Return only blocked users. |
| `created_after`  | datetime       | no       | Return users created after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `created_before` | datetime       | no       | Return users created before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/saml_users"
```

Example response:

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "Sidney Jones22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
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
    "identities": [
      {
        "provider": "group_saml",
        "extern_uid": "2435223452345",
        "saml_provider_id": 1
      }
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null,
    "scim_identities": [
      {
        "extern_uid": "2435223452345",
        "group_id": 1,
        "active": true
      }
    ]
  },
  ...
]
```

### List provisioned users

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Get a list of users provisioned by a given group. Does not include subgroups.

Requires at least the Maintainer role on the group.

```plaintext
GET /groups/:id/provisioned_users
```

Parameters:

| Attribute        | Type           | Required | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | integer/string | yes      | ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `username`       | string         | no       | Return single user with a specific username. |
| `search`         | string         | no       | Search users by name, email, username. |
| `active`         | boolean        | no       | Return only active users. |
| `blocked`        | boolean        | no       | Return only blocked users. |
| `created_after`  | datetime       | no       | Return users created after the specified time. |
| `created_before` | datetime       | no       | Return users created before the specified time. |

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

### List subgroups

Get a list of visible direct subgroups in this group.

By default, this request returns 20 results at a time because the API results [are paginated](rest/_index.md#pagination).

If you request this list as:

- An unauthenticated user, the response returns only public groups.
- An authenticated user, the response returns only the groups you're
  a member of and does not include public groups.

Parameters:

| Attribute                | Type              | Required | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | integer/string    | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) of the immediate parent group. |
| `skip_groups`            | array of integers | no       | Skip the group IDs passed. |
| `all_available`          | boolean           | no       | Show all the groups you have access to (defaults to `false` for authenticated users, `true` for administrators). Attributes `owned` and `min_access_level` have precedence. |
| `search`                 | string            | no       | Return the list of authorized groups matching the search criteria. Only subgroup short paths are searched (not full paths). |
| `order_by`               | string            | no       | Order groups by `name`, `path` or `id`. Default is `name`. |
| `sort`                   | string            | no       | Order groups in `asc` or `desc` order. Default is `asc`. |
| `statistics`             | boolean           | no       | Include group statistics (administrators only). |
| `with_custom_attributes` | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only). |
| `owned`                  | boolean           | no       | Limit to groups explicitly owned by the current user. |
| `min_access_level`       | integer           | no       | Limit to groups where current user has at least this [role (`access_level`)](members.md#roles). |
| `all_available`          | boolean           | no       | When `true`, returns all accessible groups. When `false`, returns only groups where the user is a member. Defaults to `false` for users, `true` for administrators. Unauthenticated requests always return all public groups. The `owned` and `min_access_level` attributes take precedence. |
| `active`                 | boolean           | no       | Limit by groups that are not archived and not marked for deletion. |

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
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
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
`duo_features_enabled`,
`lock_duo_features_enabled`,
`duo_availability`, and `experiment_features_enabled` attributes.

### List descendant groups

Get a list of visible descendant groups of this group.
When accessed without authentication, only public groups are returned.

By default, this request returns 20 results at a time because the API results [are paginated](rest/_index.md#pagination).

Parameters:

| Attribute                | Type              | Required | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | integer/string    | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) of the immediate parent group. |
| `skip_groups`            | array of integers | no       | Skip the group IDs passed. |
| `all_available`          | boolean           | no       | When `true`, returns all accessible groups. When `false`, returns only groups where the user is a member. Defaults to `false` for users, `true` for administrators. Unauthenticated requests always return all public groups. The `owned` and `min_access_level` attributes take precedence. |
| `search`                 | string            | no       | Return the list of authorized groups matching the search criteria. Only descendant group short paths are searched (not full paths). |
| `order_by`               | string            | no       | Order groups by `name`, `path`, or `id`. Default is `name`. |
| `sort`                   | string            | no       | Order groups in `asc` or `desc` order. Default is `asc`. |
| `statistics`             | boolean           | no       | Include group statistics (administrators only). |
| `with_custom_attributes` | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only). |
| `owned`                  | boolean           | no       | Limit to groups explicitly owned by the current user. |
| `min_access_level`       | integer           | no       | Limit to groups where current user has at least this [role (`access_level`)](members.md#roles). |
| `active`                 | boolean           | no       | Limit by groups that are not archived and not marked for deletion. |

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
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
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
    "default_branch_protection_defaults": {
      "allowed_to_push": [
          {
              "access_level": 40
          }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
          {
              "access_level": 40
          }
      ]
    },
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
`duo_features_enabled`,
`lock_duo_features_enabled`,
`duo_availability`, and `experiment_features_enabled` attributes.

### List shared groups

Get a list of groups where the given group has been invited. When accessed without authentication, only public shared groups are returned.

By default, this request returns 20 results at a time because the API results [are paginated](rest/_index.md#pagination).

Parameters:

| Attribute                             | Type              | Required | Description |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | integer/string    | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `skip_groups`                         | array of integers | no       | Skip the specified group IDs. |
| `search`                              | string            | no       | Return the list of authorized groups matching the search criteria. |
| `order_by`                            | string            | no       | Order groups by `name`, `path`, `id`, or `similarity`. Default is `name`. |
| `sort`                                | string            | no       | Order groups in `asc` or `desc` order. Default is `asc`. |
| `visibility`                          | string            | no       | Limit to groups with `public`, `internal`, or `private` visibility. |
| `min_access_level`                    | integer           | no       | Limit to groups where current user has at least the specified [role (`access_level`)](members.md#roles). |
| `with_custom_attributes`              | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only). |

```plaintext
GET /groups/:id/groups/shared
```

Example response:

```json
[
  {
    "id": 101,
    "web_url": "http://gitlab.example.com/groups/some_path",
    "name": "group1",
    "path": "some_path",
    "description": "",
    "visibility": "public",
    "share_with_group_lock": "false",
    "require_two_factor_authentication": "false",
    "two_factor_grace_period": 48,
    "project_creation_level": "maintainer",
    "auto_devops_enabled": "nil",
    "subgroup_creation_level": "maintainer",
    "emails_disabled": "false",
    "emails_enabled": "true",
    "mentions_disabled": "nil",
    "lfs_enabled": "true",
    "math_rendering_limits_enabled": "true",
    "lock_math_rendering_limits_enabled": "false",
    "default_branch": "nil",
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
        "allowed_to_push": [
          {
              "access_level": 30
          }
        ],
        "allow_force_push": "true",
        "allowed_to_merge": [
          {
              "access_level": 30
          }
        ],
        "developer_can_initial_push": "false",
        "code_owner_approval_required": "false"
    },
    "avatar_url": "http://gitlab.example.com/uploads/-/system/group/avatar/101/banana_sample.gif",
    "request_access_enabled": "true",
    "full_name": "group1",
    "full_path": "some_path",
    "created_at": "2024-06-06T09:39:30.056Z",
    "parent_id": "nil",
    "organization_id": 1,
    "shared_runners_setting": "enabled",
    "ldap_cn": "nil",
    "ldap_access": "nil",
    "wiki_access_level": "enabled"
  }
]
```

### List invited groups

Get a list of invited groups in the given group. When accessed without authentication, only public invited groups are returned.
This endpoint is rate-limited to 60 requests per minute per user (for authenticated users) or IP (for unauthenticated users).

By default, this request returns 20 results at a time because the API results [are paginated](rest/_index.md#pagination).

Parameters:

| Attribute                             | Type              | Required | Description |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | integer/string    | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `search`                              | string            | no       | Return the list of authorized groups matching the search criteria. |
| `min_access_level`                    | integer           | no       | Limit to groups where current user has at least the specified [role (`access_level`)](members.md#roles). |
| `relation`                            | array of strings  | no       | Filter the groups by relation (direct or inherited). |
| `with_custom_attributes`              | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (administrators only). |

```plaintext
GET /groups/:id/invited_groups
```

Example response:

```json
[
  {
    "id": 33,
    "web_url": "http://gitlab.example.com/groups/flightjs",
    "name": "Flightjs",
    "path": "flightjs",
    "description": "Illo dolorum tempore eligendi minima ducimus provident.",
    "visibility": "public",
    "share_with_group_lock": false,
    "require_two_factor_authentication": false,
    "two_factor_grace_period": 48,
    "project_creation_level": "developer",
    "auto_devops_enabled": null,
    "subgroup_creation_level": "maintainer",
    "emails_disabled": false,
    "emails_enabled": true,
    "mentions_disabled": null,
    "lfs_enabled": true,
    "math_rendering_limits_enabled": true,
    "lock_math_rendering_limits_enabled": false,
    "default_branch": null,
    "default_branch_protection": 2,
    "default_branch_protection_defaults": {
      "allowed_to_push": [
        {
          "access_level": 40
        }
      ],
      "allow_force_push": false,
      "allowed_to_merge": [
        {
          "access_level": 40
        }
      ],
      "developer_can_initial_push": false
    },
    "avatar_url": null,
    "request_access_enabled": true,
    "full_name": "Flightjs",
    "full_path": "flightjs",
    "created_at": "2024-07-09T10:31:08.307Z",
    "parent_id": null,
    "organization_id": 1,
    "shared_runners_setting": "enabled",
    "ldap_cn": null,
    "ldap_access": null,
    "wiki_access_level": "enabled"
  }
]
```

### List audit events

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Group audit events can be accessed via the [Group audit events API](audit_events.md#group-audit-events)

## Manage groups

### Create a group

{{< alert type="note" >}}

On GitLab SaaS, you must use the GitLab UI to create groups without a parent group. You cannot
use the API to do this.

{{< /alert >}}

Creates a new project group. Available only for users who can create groups.

```plaintext
POST /groups
```

Parameters:

| Attribute                            | Type    | Required | Description |
|--------------------------------------|---------|----------|-------------|
| `name`                               | string  | yes      | The name of the group. |
| `path`                               | string  | yes      | The path of the group. |
| `auto_devops_enabled`                | boolean | no       | Default to Auto DevOps pipeline for all projects within this group. |
| `avatar`                             | mixed   | no       | Image file for avatar of the group. |
| `default_branch`                     | string  | no       | The [default branch](../user/project/repository/branches/default.md) name for group's projects. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442298) in GitLab 16.11. |
| `default_branch_protection`          | integer | no       | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) in GitLab 17.0. Use `default_branch_protection_defaults` instead. |
| `default_branch_protection_defaults` | hash    | no       | Introduced in GitLab 17.0. For available options, see [Options for `default_branch_protection_defaults`](#options-for-default_branch_protection_defaults). |
| `description`                        | string  | no       | The group's description. |
| `enabled_git_access_protocol`        | string  | no       | Enabled protocols for Git access. Allowed values are: `ssh`, `http`, and `all` to allow both protocols. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/436618) in GitLab 16.9. |
| `emails_disabled`                    | boolean | no       | ([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899) in GitLab 16.5.) Disable email notifications. Use `emails_enabled` instead. |
| `emails_enabled`                     | boolean | no       | Enable email notifications. |
| `lfs_enabled`                        | boolean | no       | Enable/disable Large File Storage (LFS) for the projects in this group. |
| `mentions_disabled`                  | boolean | no       | Disable the capability of a group from getting mentioned. |
| `organization_id`                    | integer | no       | The organization ID for the group. |
| `parent_id`                          | integer | no       | The parent group ID for creating nested group. |
| `project_creation_level`             | string  | no       | Determine if developers can create projects in the group. Can be `administrator` (users with Admin Mode enabled), `noone` (No one), `maintainer` (users with the Maintainer role), or `developer` (users with the Developer or Maintainer role). |
| `request_access_enabled`             | boolean | no       | Allow users to request member access. |
| `require_two_factor_authentication`  | boolean | no       | Require all users in this group to set up two-factor authentication. |
| `share_with_group_lock`              | boolean | no       | Prevent sharing a project with another group within this group. |
| `subgroup_creation_level`            | string  | no       | Allowed to [create subgroups](../user/group/subgroups/_index.md#create-a-subgroup). Can be `owner` (users with the Owner role), or `maintainer` (users with the Maintainer role). |
| `two_factor_grace_period`            | integer | no       | Time before Two-factor authentication is enforced (in hours). |
| `visibility`                         | string  | no       | The group's visibility. Can be `private`, `internal`, or `public`. |
| `membership_lock`                    | boolean | no       | Users cannot be added to projects in this group. Premium and Ultimate only. |
| `extra_shared_runners_minutes_limit` | integer | no       | Can be set by administrators only. Additional compute minutes for this group. GitLab Self-Managed, Premium and Ultimate only. |
| `shared_runners_minutes_limit`       | integer | no       | Can be set by administrators only. Maximum number of monthly compute minutes for this group. Can be `nil` (default; inherit system default), `0` (unlimited), or `> 0`. GitLab Self-Managed, Premium and Ultimate only. |
| `wiki_access_level`                  | string  | no       | The wiki access level. Can be `disabled`, `private`, or `enabled`. Premium and Ultimate only. |
| `duo_availability` | string | no | Duo availability setting. Valid values are: `default_on`, `default_off`, `never_on`. Note: In the UI, `never_on` is displayed as "Always Off". |
| `experiment_features_enabled` | boolean | no | Enable experiment features for this group. |

#### Options for `default_branch_protection`

The `default_branch_protection` attribute determines whether users with the Developer or Maintainer role can push to the applicable [default branch](../user/project/repository/branches/default.md), as described in the following table:

| Value | Description |
|-------|-------------|
| `0`   | No protection. Users with the Developer or Maintainer role can: <br>- Push new commits.<br>- Force push changes.<br>- Delete the branch. |
| `1`   | Partial protection. Users with the Developer or Maintainer role can: <br>- Push new commits. |
| `2`   | Full protection. Only users with the Maintainer role can: <br>- Push new commits. |
| `3`   | Protected against pushes. Users with the Maintainer role can: <br>- Push new commits.<br>- Force push changes.<br>- Accept merge requests.<br>Users with the Developer role can:<br>- Accept merge requests. |
| `4`   | Full protection after initial push. User with the Developer role can: <br>- Push commit to empty repository.<br> Users with the Maintainer role can: <br>- Push new commits.<br>- Accept merge requests. |

#### Options for `default_branch_protection_defaults`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) in GitLab 17.0.

{{< /history >}}

The `default_branch_protection_defaults` attribute describes the default branch
protection defaults. All parameters are optional.

| Key                          | Type    | Description |
|:-----------------------------|:--------|:------------|
| `allowed_to_push`            | array   | An array of access levels allowed to push. Supports Developer (30) or Maintainer (40). |
| `allow_force_push`           | boolean | Allow force push for all users with push access. |
| `allowed_to_merge`           | array   | An array of access levels allowed to merge. Supports Developer (30) or Maintainer (40). |
| `developer_can_initial_push` | boolean | Allow developers to initial push. |

### Create a subgroup

This is similar to creating a [New group](#create-a-group). You need the `parent_id` from the [List groups](#list-groups) call. You can then enter the desired:

- `subgroup_path`
- `subgroup_name`

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"path": "<subgroup_path>", "name": "<subgroup_name>", "parent_id": <parent_group_id> }' \
     "https://gitlab.example.com/api/v4/groups/"
```

### Delete a group

{{< history >}}

- Marking groups for deletion [available](https://gitlab.com/groups/gitlab-org/-/epics/17208) on Free tier in GitLab 18.0.

{{< /history >}}

Prerequisites:

- You must be an administrator or have the Owner role for the group.

Marks a group for deletion. Groups are deleted at the end of the retention period:

- On GitLab.com, groups are retained for 30 days.
- On GitLab Self-Managed, the retention period is controlled by the
  [instance settings](../administration/settings/visibility_and_access_controls.md#deletion-protection).

This endpoint can also immediately delete a subgroup that was previously marked for deletion.

```plaintext
DELETE /groups/:id
```

Parameters:

| `id`                 | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `permanently_remove` | boolean/string | no       | If `true`, immediately deletes a subgroup that is already marked for deletion. Cannot delete top-level groups. |
| `full_path`          | string         | no       | The full path to the subgroup. Used to confirm deletion of the subgroup. If `permanently_remove` is `true`, this attribute is required. To find the subgroup path, see the [group details](groups.md#get-a-single-group). |

The response is `202 Accepted` if the user has authorization.

{{< alert type="note" >}}

You cannot delete a GitLab.com group that is linked to a subscription. You must first [link the subscription](../subscriptions/manage_subscription.md#link-subscription-to-a-group) with a different group.

{{< /alert >}}

#### Restore a group marked for deletion

Restores a group that was previously marked for deletion.

```plaintext
POST /groups/:id/restore
```

Parameters:

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

### Archive a group

{{< details >}}

- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481969) in GitLab 18.0 [with a flag](../administration/feature_flags/_index.md) named `archive_group`. Disabled by default. This feature is an [experiment](../policy/development_stages_support.md).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

Archive a group.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

This endpoint returns a `422` unprocessable entity error if the group is already archived.

```plaintext
POST /groups/:id/archive
```

Parameters:

| Attribute                             | Type              | Required | Description |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | integer or string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) owned by the authenticated user. |

Example response:

```json
{
  "id": 96,
  "web_url": "https://gitlab.example.com/groups/test-1",
  "name": "test-1",
  "path": "test-1",
  "description": "",
  "visibility": "public",
  "share_with_group_lock": false,
  "require_two_factor_authentication": false,
  "two_factor_grace_period": 48,
  "project_creation_level": "developer",
  "auto_devops_enabled": null,
  "subgroup_creation_level": "maintainer",
  "emails_disabled": false,
  "emails_enabled": true,
  "mentions_disabled": null,
  "lfs_enabled": true,
  "archived": true,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false,
  "default_branch": null,
  "default_branch_protection": 2,
  "default_branch_protection_defaults": {
    "allowed_to_push": [
      {
        "access_level": 40
      }
    ],
    "allow_force_push": false,
    "allowed_to_merge": [
      {
        "access_level": 40
      }
    ],
    "developer_can_initial_push": false
  },
  "avatar_url": null,
  "request_access_enabled": true,
  "full_name": "test-1",
  "full_path": "test-1",
  "created_at": "2025-03-25T12:05:24.813Z",
  "parent_id": null,
  "organization_id": 1,
  "shared_runners_setting": "enabled",
  "max_artifacts_size": null,
  "ldap_cn": null,
  "ldap_access": null,
  "wiki_access_level": "enabled",
  "shared_with_groups": [],
  "prevent_sharing_groups_outside_hierarchy": false,
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "prevent_forking_outside_group": null,
  "membership_lock": false
}
```

#### Unarchive a group

{{< details >}}

- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/481969) in GitLab 18.0 [with a flag](../administration/feature_flags/_index.md) named `archive_group`. Disabled by default. This feature is an [experiment](../policy/development_stages_support.md).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

Unarchive a group.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

This endpoint returns a `422` unprocessable entity error if the group is not archived.

```plaintext
POST /groups/:id/unarchive
```

Parameters:

| Attribute                             | Type              | Required | Description |
| ------------------------------------- | ----------------- | -------- | ---------- |
| `id`                                  | integer or string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) owned by the authenticated user. |

Example response:

```json
{
  "id": 96,
  "web_url": "https://gitlab.example.com/groups/test-1",
  "name": "test-1",
  "path": "test-1",
  "description": "",
  "visibility": "public",
  "share_with_group_lock": false,
  "require_two_factor_authentication": false,
  "two_factor_grace_period": 48,
  "project_creation_level": "developer",
  "auto_devops_enabled": null,
  "subgroup_creation_level": "maintainer",
  "emails_disabled": false,
  "emails_enabled": true,
  "mentions_disabled": null,
  "lfs_enabled": true,
  "archived": false,
  "math_rendering_limits_enabled": true,
  "lock_math_rendering_limits_enabled": false,
  "default_branch": null,
  "default_branch_protection": 2,
  "default_branch_protection_defaults": {
    "allowed_to_push": [
      {
        "access_level": 40
      }
    ],
    "allow_force_push": false,
    "allowed_to_merge": [
      {
        "access_level": 40
      }
    ],
    "developer_can_initial_push": false
  },
  "avatar_url": null,
  "request_access_enabled": true,
  "full_name": "test-1",
  "full_path": "test-1",
  "created_at": "2025-03-25T12:05:24.813Z",
  "parent_id": null,
  "organization_id": 1,
  "shared_runners_setting": "enabled",
  "max_artifacts_size": null,
  "ldap_cn": null,
  "ldap_access": null,
  "wiki_access_level": "enabled",
  "shared_with_groups": [],
  "prevent_sharing_groups_outside_hierarchy": false,
  "shared_runners_minutes_limit": null,
  "extra_shared_runners_minutes_limit": null,
  "prevent_forking_outside_group": null,
  "membership_lock": false
}
```

### Transfer a group

Transfers a group to a new parent group or transforms a subgroup into a top-level group.

Prerequisites:

- You must have the Owner role for the group.
- If transferring a group, you must have permission to [create a subgroup](../user/group/subgroups/_index.md#create-a-subgroup) in the new parent group.
- If transforming a subgroup, you must have [permission to create a top-level group](../administration/user_settings.md).

```plaintext
POST /groups/:id/transfer
```

Parameters:

| Attribute  | Type    | Required | Description |
|------------|---------|----------|-------------|
| `id`       | integer | yes      | ID of the group to transfer. |
| `id`       | integer | yes      | ID of the group to transfer. |
| `group_id` | integer | no       | ID of the new parent group. If unspecified, the group is transformed into a top-level group. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/4/transfer?group_id=7"
```

#### List all locations available for group transfer

Lists all available parent groups to transfer a specified group.

```plaintext
GET /groups/:id/transfer_locations
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the group to transfer](rest/_index.md#namespaced-paths). |
| `search`  | string            | No       | The name of a specific group to search for. |

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

#### Transfer a project to a group

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Transfers a project to another group namespace. Alternatively, use the [transfer a project to a new namespace](projects.md#transfer-a-project-to-a-new-namespace) endpoint instead.

{{< alert type="note" >}}

The transfer process may fail if tagged packages exist in the project's repository.

{{< /alert >}}

Prerequisites:

- You must be an administrator for the instance.

```plaintext
POST /groups/:id/projects/:project_id
```

Parameters:

| Attribute    | Type           | Required | Description |
| ------------ | -------------- | -------- | ----------- |
| `id`         | integer/string | yes      | The ID or [URL-encoded path of the target group](rest/_index.md#namespaced-paths). |
| `project_id` | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/4/projects/56"
```

### Invite groups

These endpoints are used to for group invitations. For more information, see [invite a group to a group](../user/project/members/sharing_projects_groups.md#invite-a-group-to-a-group).

#### Create a group invitation

Creates a group invitation that adds a target group to a specified group.

```plaintext
POST /groups/:id/share
```

| `id`           | integer/string | yes      | The ID or [URL-encoded path of the target group](rest/_index.md#namespaced-paths). |
| `group_id`     | integer        | yes      | The ID of the group to invite. |
| `group_access` | integer        | yes      | The default [role (`access_level`)](members.md#roles) to assign to the invited group. |
| `expires_at`   | date (ISO 8601) | no       | The date the group invitation expires. |
| `member_role_id`   | integer         | no       | The ID of a [custom role](../user/custom_roles/_index.md#assign-a-custom-role-to-an-invited-group) to assign to the invited group. If defined, `group_access` must match the base role used to create the custom role. |

Returns `200` and the group details on success.

#### Delete a group invitation

Deletes a group invitation and removes access to the target group from the specified group.

```plaintext
DELETE /groups/:id/share/:group_id
```

| Attribute  | Type           | Required | Description |
|------------|----------------|----------|-------------|
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the target group](rest/_index.md#namespaced-paths). |
| `group_id` | integer        | yes      | The ID of the group to disinvite. |

Returns `204` and no content on success.

## Update group attributes

{{< history >}}

- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183101) in GitLab 18.0. Feature flag `limit_unique_project_downloads_per_namespace_user` removed.
- `web_based_commit_signing_enabled` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193928) in GitLab 18.2 [with a flag](../administration/feature_flags/_index.md) named `use_web_based_commit_signing_enabled`. Disabled by default.
{{< /history >}}

{{< alert type="flag" >}}

The availability of the  `web_based_commit_signing_enabled` attribute is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

{{< /alert >}}

Updates the attributes for a specified group.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

```plaintext
PUT /groups/:id
```

| Attribute                                            | Type              | Required | Description |
|------------------------------------------------------|-------------------|----------|-------------|
| `id`                                                 | integer           | yes      | The ID of the group. |
| `name`                                               | string            | no       | The name of the group. |
| `path`                                               | string            | no       | The path of the group. |
| `auto_devops_enabled`                                | boolean           | no       | Default to Auto DevOps pipeline for all projects within this group. |
| `avatar`                                             | mixed             | no       | Image file for avatar of the group. |
| `default_branch`                                     | string            | no       | The [default branch](../user/project/repository/branches/default.md) name for group's projects. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/442298) in GitLab 16.11. |
| `default_branch_protection`                          | integer           | no       | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) in GitLab 17.0. Use `default_branch_protection_defaults` instead. |
| `default_branch_protection_defaults`                 | hash              | no       | [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) in GitLab 17.0. For available options, see [Options for `default_branch_protection_defaults`](#options-for-default_branch_protection_defaults). |
| `description`                                        | string            | no       | The description of the group. |
| `enabled_git_access_protocol`                        | string            | no       | Enabled protocols for Git access. Allowed values are: `ssh`, `http`, and `all` to allow both protocols. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/436618) in GitLab 16.9. |
| `emails_disabled`                                    | boolean           | no       | ([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899) in GitLab 16.5.) Disable email notifications. Use `emails_enabled` instead. |
| `emails_enabled`                                     | boolean           | no       | Enable email notifications. |
| `lfs_enabled`                                        | boolean           | no       | Enable/disable Large File Storage (LFS) for the projects in this group. |
| `mentions_disabled`                                  | boolean           | no       | Disable the capability of a group from getting mentioned. |
| `prevent_sharing_groups_outside_hierarchy`           | boolean           | no       | See [Prevent group sharing outside the group hierarchy](../user/project/members/sharing_projects_groups.md#prevent-inviting-groups-outside-the-group-hierarchy). This attribute is only available on top-level groups. |
| `project_creation_level`                             | string            | no       | Determine if developers can create projects in the group. Can be `noone` (No one), `maintainer` (users with the Maintainer role), or `developer` (users with the Developer or Maintainer role). |
| `request_access_enabled`                             | boolean           | no       | Allow users to request member access. |
| `require_two_factor_authentication`                  | boolean           | no       | Require all users in this group to set up two-factor authentication. |
| `shared_runners_setting`                             | string            | no       | See [Options for `shared_runners_setting`](#options-for-shared_runners_setting). Enable or disable instance runners for a group's subgroups and projects. |
| `share_with_group_lock`                              | boolean           | no       | Prevent sharing a project with another group within this group. |
| `subgroup_creation_level`                            | string            | no       | Allowed to [create subgroups](../user/group/subgroups/_index.md#create-a-subgroup). Can be `owner` (users with the Owner role), or `maintainer` (users with the Maintainer role). |
| `two_factor_grace_period`                            | integer           | no       | Time before Two-factor authentication is enforced (in hours). |
| `visibility`                                         | string            | no       | The visibility level of the group. Can be `private`, `internal`, or `public`. |
| `extra_shared_runners_minutes_limit`                 | integer           | no       | Can be set by administrators only. Additional compute minutes for this group. GitLab Self-Managed, Premium and Ultimate only. |
| `file_template_project_id`                           | integer           | no       | The ID of a project to load custom file templates from. Premium and Ultimate only. |
| `membership_lock`                                    | boolean           | no       | Users cannot be added to projects in this group. Premium and Ultimate only. |
| `prevent_forking_outside_group`                      | boolean           | no       | When enabled, users can not fork projects from this group to external namespaces. Premium and Ultimate only. |
| `shared_runners_minutes_limit`                       | integer           | no       | Can be set by administrators only. Maximum number of monthly compute minutes for this group. Can be `nil` (default; inherit system default), `0` (unlimited), or `> 0`. GitLab Self-Managed, Premium and Ultimate only. |
| `unique_project_download_limit`                      | integer           | no       | Maximum number of unique projects a user can download in the specified time period before they are banned. Available only on top-level groups. Default: 0, Maximum: 10,000. Ultimate only. |
| `unique_project_download_limit_interval_in_seconds`  | integer           | no       | Time period during which a user can download a maximum amount of projects before they are banned. Available only on top-level groups. Default: 0, Maximum: 864,000 seconds (10 days). Ultimate only. |
| `unique_project_download_limit_allowlist`            | array of strings  | no       | List of usernames excluded from the unique project download limit. Available only on top-level groups. Default: `[]`, Maximum: 100 usernames. Ultimate only. |
| `unique_project_download_limit_alertlist`            | array of integers | no       | List of user IDs that are emailed when the unique project download limit is exceeded. Available only on top-level groups. Default: `[]`, Maximum: 100 user IDs. Ultimate only. |
| `auto_ban_user_on_excessive_projects_download`       | boolean           | no       | When enabled, users are automatically banned from the group when they download more than the maximum number of unique projects specified by `unique_project_download_limit` and `unique_project_download_limit_interval_in_seconds`. Ultimate only. |
| `ip_restriction_ranges`                              | string      | no       | Comma-separated list of IP addresses or subnet masks to restrict group access. Premium and Ultimate only. |
| `allowed_email_domains_list`                         | string      | no       | Comma-separated list of email address domains to allow group access. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/351494) in 17.4. GitLab Premium and Ultimate only. |
| `wiki_access_level`                                  | string            | no       | The wiki access level. Can be `disabled`, `private`, or `enabled`. Premium and Ultimate only. |
| `duo_availability`                                   | string | no | Duo availability setting. Valid values are: `default_on`, `default_off`, `never_on`. Note: In the UI, `never_on` is displayed as "Always Off". |
| `experiment_features_enabled`                        | boolean | no | Enable experiment features for this group. |
| `math_rendering_limits_enabled`                      | boolean           | no       | Indicates if math rendering limits are used for this group. |
| `lock_math_rendering_limits_enabled`                 | boolean           | no       | Indicates if math rendering limits are locked for all descendent groups. |
| `duo_features_enabled`                               | boolean           | no       | Indicates whether GitLab Duo features are enabled for this group. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931) in GitLab 16.10. GitLab Self-Managed, Premium and Ultimate only. |
| `lock_duo_features_enabled`                          | boolean           | no       | Indicates whether the GitLab Duo features enabled setting is enforced for all subgroups. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931) in GitLab 16.10. GitLab Self-Managed, Premium and Ultimate only. |
| `max_artifacts_size`                                 | integer           | No       | The maximum file size in megabytes for individual job artifacts. |
| `web_based_commit_signing_enabled`                  | boolean           | No       | Enables web-based commit signing for commits created from the GitLab UI. Available only for top-level groups on GitLab SaaS. When enabled for a group, applies to all projects in the group. |

{{< alert type="note" >}}

The `projects` and `shared_projects` attributes in the response are deprecated and [scheduled for removal in API v5](https://gitlab.com/gitlab-org/gitlab/-/issues/213797).
To get the details of all projects within a group, use either the [list a group's projects](#list-projects) or the [list a group's shared projects](#list-shared-projects) endpoint.

{{< /alert >}}

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/groups/5?name=Experimental"
```

This endpoint returns a maximum of 100 projects and shared projects. To get the details of all projects in a group, use the
[list a group's projects endpoint](#list-projects) instead.

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
`duo_features_enabled`,
`lock_duo_features_enabled`,
`duo_availability`, and `experiment_features_enabled` attributes.

### Options for `shared_runners_setting`

The `shared_runners_setting` attribute determines whether instance runners are enabled for a group's subgroups and projects.

| Value                        | Description |
|------------------------------|-------------|
| `enabled`                    | Enables instance runners for all projects and subgroups in this group. |
| `disabled_and_overridable`   | Disables instance runners for all projects and subgroups in this group, but allows subgroups to override this setting. |
| `disabled_and_unoverridable` | Disables instance runners for all projects and subgroups in this group, and prevents subgroups from overriding this setting. |
| `disabled_with_override`     | (Deprecated. Use `disabled_and_overridable`) Disables instance runners for all projects and subgroups in this group, but allows subgroups to override this setting. |

## Update group avatars

Update group avatars.

### Download a group avatar

Get a group avatar. This endpoint can be accessed without authentication if the
group is publicly accessible.

```plaintext
GET /groups/:id/avatar
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | yes      | ID of the group. |

Example:

```shell
curl --header "PRIVATE-TOKEN: $GITLAB_LOCAL_TOKEN" \
  --remote-header-name \
  --remote-name \
  "https://gitlab.example.com/api/v4/groups/4/avatar"
```

### Upload a group avatar

To upload an avatar file from your file system, use the `--form` argument. This causes
curl to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to a file on your file system and be preceded by
`@`. For example:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22" \
     --form "avatar=@/tmp/example.png"
```

### Remove a group avatar

To remove a group avatar, use a blank value for the `avatar` attribute.

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/22" \
     --data "avatar="
```

## Revoke a token

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371117) in GitLab 17.2 [with a flag](../administration/feature_flags/_index.md) named `group_agnostic_token_revocation`. Disabled by default.
- Revocation of user feed tokens [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/468599) in GitLab 17.3.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Revoke a token, if it has access to the group or any of its subgroups
and projects. If the token is revoked, or was already revoked, its
details are returned in the response.

The following criteria must be met:

- The group must be a top-level group.
- You must have the Owner role for the group.
- The token type is one of:
  - Personal access token
  - Group access token
  - Project access token
  - Group deploy token
  - User feed tokens

Additional token types may be supported at a later date.

```plaintext
POST /groups/:id/tokens/revoke
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `token`   | string            | Yes      | The plaintext token. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and
a JSON representation of the token. The attributes returned will vary by
token type.

Example request

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{"token":"glpat-EXAMPLE"}' \
  --url "https://gitlab.example.com/api/v4/groups/63/tokens/revoke"
```

Example response:

```json
{
    "id": 9,
    "name": "my-subgroup-deploytoken",
    "username": "gitlab+deploy-token-9",
    "expires_at": null,
    "scopes":
    [
        "read_repository",
        "read_package_registry",
        "write_package_registry"
    ],
    "revoked": true,
    "expired": false
}
```

## Sync a group with LDAP

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Syncs a specified group with its linked LDAP group.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

```plaintext
POST /groups/:id/ldap_sync
```

| Attribute | Type                | Required | Description                            |
| --------- | ------------------- | -------- | -------------------------------------- |
| `id`      | integer or string   | Yes      | The ID or URL-encoded path of a group. |

<!--
### Credentials inventory management

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16343) in GitLab 18.1 [with a flag](../administration/feature_flags/_index.md) named `manage_pat_by_group_owners_ready`. Disabled by default.

{{< /history >}}

View, revoke, and rotate the credentials of enterprise users on GitLab.com.

Prerequisites:

- You must have the Owner role for the group.

#### List all personal access tokens for a group

Lists all personal access tokens associated with enterprise users in a top-level group.

```plaintext
GET /groups/:id/manage/personal_access_tokens
```

| Attribute          | Type                | Required | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | integer or string   | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a group. |
| `created_after`    | datetime (ISO 8601) | No       | If defined, returns tokens created after the specified time. |
| `created_before`   | datetime (ISO 8601) | No       | If defined, returns tokens created before the specified time. |
| `last_used_after`  | datetime (ISO 8601) | No       | If defined, returns tokens last used after the specified time. |
| `last_used_before` | datetime (ISO 8601) | No       | If defined, returns tokens last used before the specified time. |
| `revoked`          | boolean             | No       | If `true`, only returns revoked tokens. |
| `search`           | string              | No       | If defined, returns tokens that include the specified value in the name. |
| `state`            | string              | No       | If defined, returns tokens with the specified state. Possible values: `active` and `inactive`. |
| `sort`             | string              | No       | If defined, sorts the results by the specified value. Possible values: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" "https://gitlab.example.com/api/v4/groups/1/manage/personal_access_tokens"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "Test Token",
    "revoked": false,
    "created_at": "2020-07-23T14:31:47.729Z",
    "description": "Test Token description",
    "scopes": [
        "api"
    ],
    "user_id": 3,
    "last_used_at": "2021-10-06T17:58:37.550Z",
    "active": true,
    "expires_at": 2025-11-08
  }
]
```

#### List all group and project access tokens for a group

Lists all group and project access tokens associated with a top-level-group.

```plaintext
GET /groups/:id/manage/resource_access_tokens
```

| Attribute          | Type                | Required | Description |
| ------------------ | ------------------- | -------- | ----------- |
| `id`               | integer or string   | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a group. |
| `created_after`    | datetime (ISO 8601) | No       | If defined, returns tokens created after the specified time. |
| `created_before`   | datetime (ISO 8601) | No       | If defined, returns tokens created before the specified time. |
| `last_used_after`  | datetime (ISO 8601) | No       | If defined, returns tokens last used after the specified time. |
| `last_used_before` | datetime (ISO 8601) | No       | If defined, returns tokens last used before the specified time. |
| `revoked`          | boolean             | No       | If `true`, only returns revoked tokens. |
| `search`           | string              | No       | If defined, returns tokens that include the specified value in the name. |
| `state`            | string              | No       | If defined, returns tokens with the specified state. Possible values: `active` and `inactive`. |
| `sort`             | string              | No       | If defined, sorts the results by the specified value. Possible values: `created_asc`, `created_desc`, `expires_asc`, `expires_desc`, `last_used_asc`, `last_used_desc`, `name_asc`, `name_desc`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" "https://gitlab.example.com/api/v4/groups/1/manage/resource_access_tokens"
```

Example response:

```json
[
  {
    "id": 12767703,
    "name": "Test Group Token",
    "revoked": false,
    "created_at": "2025-01-07T00:25:02.128Z",
    "description": "",
    "scopes": [
        "read_registry"
    ],
    "user_id": 25365147,
    "last_used_at": null,
    "active": true,
    "expires_at": "2025-06-19",
    "access_level": 10,
    "resource_type": "group",
    "resource_id": 77449520
  }
]
```

#### List all SSH keys for a group

Lists all SSH public keys associated with enterprise users in a top-level-group.

```plaintext
GET /groups/:id/manage/ssh_keys
```

| Attribute        | Type                | Required | Description |
| ---------------- | ------------------- | -------- | ----------- |
| `id`             | integer or string   | Yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of a group. |
| `created_after`  | datetime (ISO 8601) | No       | If defined, returns SSH keys created after the specified time. |
| `created_before` | datetime (ISO 8601) | No       | If defined, returns SSH keys created before the specified time. |
| `expires_before` | datetime (ISO 8601) | No       | If defined, returns SSH keys that expire before the specified time. |
| `expires_after`  | datetime (ISO 8601) | No       | If defined, returns SSH keys that expire after the specified time. |

```shell
curl --header "PRIVATE-TOKEN: <group_owner_token>" "https://gitlab.example.com/api/v4/groups/1/manage/ssh_keys"
```

Example response:

```json
[
  {
    "id":3,
    "title":"Sample key 3",
    "created_at":"2024-12-23T05:40:11.891Z",
    "expires_at":null,
    "last_used_at":"2024-13-23T05:40:11.891Z",
    "usage_type":"auth_and_signing",
    "user_id":3
  }
]
```

#### Revoke a personal access token for an enterprise user

Revokes a specified personal access token for an enterprise user.

```plaintext
DELETE groups/:id/manage/personal_access_tokens/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID of a personal access token or the keyword `self`. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/personal_access_tokens/<personal_access_token_id>"
```

If successful, returns `204: No Content`.

Other possible responses:

- `400: Bad Request` if not revoked successfully.
- `401: Unauthorized` if the access token is invalid.
- `403: Forbidden` if the access token does not have the required permissions.

#### Revoke a group or project access token for an enterprise user

Revokes a specified group or project access token for an enterprise user associated with the top-level group.

```plaintext
DELETE groups/:id/manage/resource_access_tokens/:id
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id` | integer or string | yes | ID of a resource access token or the keyword `self`. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/resource_access_tokens/<personal_access_token_id>"
```

If successful, returns `204: No Content`.

Other possible responses:

- `400: Bad Request` if not revoked successfully.
- `401: Unauthorized` if the access token is invalid.
- `403: Forbidden` if the access token does not have the required permissions.

#### Delete an SSH key for an enterprise user

Deletes a specified SSH public key for an enterprise user associated with the top-level group.

```plaintext
DELETE /groups/:id/manage/keys/:key_id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `key_id`  | integer | yes      | ID of existing key.  |

If successful, returns `204: No Content`.

Other possible responses:

- `400: Bad Request` if SSH Key is not deleted successfully.
- `401: Unauthorized` if the SSH Key is invalid.
- `403: Forbidden` if the user does not have the required permissions.

#### Rotate a personal access token for an enterprise user

Rotates a specified personal access token for an enterprise user associated with the top-level group. This revokes the previous token and creates a new token
that expires after one week.

```plaintext
POST groups/:id/manage/personal_access_tokens/:id/rotate
```

| Attribute | Type      | Required | Description         |
|-----------|-----------|----------|---------------------|
| `id` | integer or string | yes      | ID of a personal access token or the keyword `self`. |
| `expires_at` | date   | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). The date must be one year or less from the rotation date. If undefined, the token expires after one week. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/managepersonal_access_tokens/<personal_access_token_id>/rotate"
```

Example response:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "token": "s3cr3t"
}
```

If successful, returns `200: OK`.

Other possible responses:

- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if any of the following conditions are true:
  - The token does not exist.
  - The token has expired.
  - The token was revoked.
  - You do not have access to the specified token.
- `403: Forbidden` if the token is not allowed to rotate itself.
- `404: Not Found` if the user has the Owner role, but the token does not exist.
- `405: Method Not Allowed` if the token is not a personal access token.

#### Rotate a group or project access token for an enterprise user

Rotates a specified group or project access token for an enterprise user associated with the top-level group. This revokes the previous token and creates a new token
that expires after one week.

```plaintext
POST groups/:id/manage/resource_access_tokens/:id/rotate
```

| Attribute | Type      | Required | Description         |
|-----------|-----------|----------|---------------------|
| `id` | integer or string | yes      | ID of a personal access token or the keyword `self`. |
| `expires_at` | date   | no       | Expiration date of the access token in ISO format (`YYYY-MM-DD`). The date must be one year or less from the rotation date. If undefined, the token expires after one week. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/:id/manage/resource_access_tokens/<resource_access_token_id>/rotate"
```

Example response:

```json
{
    "id": 42,
    "name": "Rotated Token",
    "revoked": false,
    "created_at": "2023-08-01T15:00:00.000Z",
    "description": "Test Token description",
    "scopes": ["api"],
    "user_id": 1337,
    "last_used_at": null,
    "active": true,
    "expires_at": "2023-08-15",
    "token": "s3cr3t"
}
```

If successful, returns `200: OK`.

Other possible responses:

- `400: Bad Request` if not rotated successfully.
- `401: Unauthorized` if any of the following conditions are true:
  - The token does not exist.
  - The token has expired.
  - The token was revoked.
  - You do not have access to the specified token.
- `403: Forbidden` if the token is not allowed to rotate itself or token is not a bot user token.
- `404: Not Found` if the user has the Owner role, but the token does not exist.
-->
