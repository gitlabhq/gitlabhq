# Groups API

## List groups

Get a list of visible groups for the authenticated user. When accessed without
authentication, only public groups are returned.

Parameters:

| Attribute                | Type              | Required | Description |
| ------------------------ | ----------------- | -------- | ---------- |
| `skip_groups`            | array of integers | no       | Skip the group IDs passed |
| `all_available`          | boolean           | no       | Show all the groups you have access to (defaults to `false` for authenticated users, `true` for admin); Attributes `owned` and `min_access_level` have precedence |
| `search`                 | string            | no       | Return the list of authorized groups matching the search criteria |
| `order_by`               | string            | no       | Order groups by `name`, `path` or `id`. Default is `name` |
| `sort`                   | string            | no       | Order groups in `asc` or `desc` order. Default is `asc` |
| `statistics`             | boolean           | no       | Include group statistics (admins only) |
| `with_custom_attributes` | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (admins only) |
| `owned`                  | boolean           | no       | Limit to groups explicitly owned by the current user |
| `min_access_level`       | integer           | no       | Limit to groups where current user has at least this [access level](members.md) |

```
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
    "lfs_enabled": true,
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null
  }
]
```

When adding the parameter `statistics=true` and the authenticated user is an admin, additional group statistics are returned.

```
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
    "lfs_enabled": true,
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "request_access_enabled": false,
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": null,
    "statistics": {
      "storage_size" : 212,
      "repository_size" : 33,
      "wiki_size" : 100,
      "lfs_objects_size" : 123,
      "job_artifacts_size" : 57,
      "packages_size": 0
    }
  }
]
```

You can search for groups by name or path, see below.

You can filter by [custom attributes](custom_attributes.md) with:

```
GET /groups?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

## List a group's subgroups

> [Introduced][ce-15142] in GitLab 10.3.

Get a list of visible direct subgroups in this group.
When accessed without authentication, only public groups are returned.

Parameters:

| Attribute                | Type              | Required | Description |
| ------------------------ | ----------------- | -------- | ----------- |
| `id`                     | integer/string    | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) of the parent group |
| `skip_groups`            | array of integers | no       | Skip the group IDs passed |
| `all_available`          | boolean           | no       | Show all the groups you have access to (defaults to `false` for authenticated users, `true` for admin); Attributes `owned` and `min_access_level` have preceden |
| `search`                 | string            | no       | Return the list of authorized groups matching the search criteria |
| `order_by`               | string            | no       | Order groups by `name`, `path` or `id`. Default is `name` |
| `sort`                   | string            | no       | Order groups in `asc` or `desc` order. Default is `asc` |
| `statistics`             | boolean           | no       | Include group statistics (admins only) |
| `with_custom_attributes` | boolean           | no       | Include [custom attributes](custom_attributes.md) in response (admins only) |
| `owned`                  | boolean           | no       | Limit to groups explicitly owned by the current user |
| `min_access_level`       | integer           | no       | Limit to groups where current user has at least this [access level](members.md) |

```
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
    "lfs_enabled": true,
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://gitlab.example.com/groups/foo-bar",
    "request_access_enabled": false,
    "full_name": "Foobar Group",
    "full_path": "foo-bar",
    "file_template_project_id": 1,
    "parent_id": 123
  }
]
```

## List a group's projects

Get a list of projects in this group. When accessed without authentication, only
public projects are returned.

```
GET /groups/:id/projects
```

Parameters:

| Attribute                     | Type           | Required | Description |
| ----------------------------- | -------------- | -------- | ----------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `archived`                    | boolean        | no       | Limit by archived status |
| `visibility`                  | string         | no       | Limit by visibility `public`, `internal`, or `private` |
| `order_by`                    | string         | no       | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at` |
| `sort`                        | string         | no       | Return projects sorted in `asc` or `desc` order. Default is `desc` |
| `search`                      | string         | no       | Return list of authorized projects matching the search criteria |
| `simple`                      | boolean        | no       | Return only the ID, URL, name, and path of each project |
| `owned`                       | boolean        | no       | Limit by projects owned by the current user |
| `starred`                     | boolean        | no       | Limit by projects starred by the current user |
| `with_issues_enabled`         | boolean        | no       | Limit by projects with issues feature enabled. Default is `false` |
| `with_merge_requests_enabled` | boolean        | no       | Limit by projects with merge requests feature enabled. Default is `false` |
| `with_shared`                 | boolean        | no       | Include projects shared to this group. Default is `true` |
| `include_subgroups`           | boolean        | no       | Include projects in subgroups of this group. Default is `false`   |
| `min_access_level`            | integer        | no       | Limit to projects where current user has at least this [access level](members.md) |
| `with_custom_attributes`      | boolean        | no       | Include [custom attributes](custom_attributes.md) in response (admins only) |
| `with_security_reports`       | boolean        | no       | **(ULTIMATE)** Return only projects that have security reports artifacts present in any of their builds. This means "projects with security reports enabled". Default is `false` |

Example response:

```json
[
  {
    "id": 9,
    "description": "foo",
    "default_branch": "master",
    "tag_list": [],
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

## Details of a group

Get all details of a group. This endpoint can be accessed without authentication
if the group is publicly accessible. In case the user that requests is admin of the group, it will return the `runners_token` for the group too.

```
GET /groups/:id
```

Parameters:

| Attribute                | Type           | Required | Description |
| ------------------------ | -------------- | -------- | ----------- |
| `id`                     | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `with_custom_attributes` | boolean        | no       | Include [custom attributes](custom_attributes.md) in response (admins only). |
| `with_projects`          | boolean        | no       | Include details from projects that belong to the specified group (defaults to `true`). |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/4
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
  "runners_token": "ba324ca7b1c77fc20bb9",
  "file_template_project_id": 1,
  "parent_id": null,
  "projects": [
    {
      "id": 7,
      "description": "Voluptas veniam qui et beatae voluptas doloremque explicabo facilis.",
      "default_branch": "master",
      "tag_list": [],
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
      "tag_list": [],
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
  "shared_projects": [
    {
      "id": 8,
      "description": "Velit eveniet provident fugiat saepe eligendi autem.",
      "default_branch": "master",
      "tag_list": [],
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

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
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

When adding the parameter `with_projects=false`, projects will not be returned.

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/4?with_projects=false
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

## New group

Creates a new project group. Available only for users who can create groups.

```
POST /groups
```

Parameters:

| Attribute                            | Type    | Required | Description |
| ------------------------------------ | ------- | -------- | ----------- |
| `name`                               | string  | yes      | The name of the group. |
| `path`                               | string  | yes      | The path of the group. |
| `description`                        | string  | no       | The group's description. |
| `visibility`                         | string  | no       | The group's visibility. Can be `private`, `internal`, or `public`. |
| `share_with_group_lock`              | boolean | no       | Prevent sharing a project with another group within this group. |
| `require_two_factor_authentication`  | boolean | no       | Require all users in this group to setup Two-factor authentication. |
| `two_factor_grace_period`            | integer | no       | Time before Two-factor authentication is enforced (in hours). |
| `project_creation_level`             | string  | no       | Determine if developers can create projects in the group. Can be `noone` (No one), `maintainer` (Maintainers), or `developer` (Developers + Maintainers). |
| `auto_devops_enabled`                | boolean | no       | Default to Auto DevOps pipeline for all projects within this group. |
| `subgroup_creation_level`            | integer | no       | Allowed to create subgroups. Can be `owner` (Owners), or `maintainer` (Maintainers). |
| `emails_disabled`                    | boolean | no       | Disable email notifications |
| `lfs_enabled`                        | boolean | no       | Enable/disable Large File Storage (LFS) for the projects in this group. |
| `request_access_enabled`             | boolean | no       | Allow users to request member access. |
| `parent_id`                          | integer | no       | The parent group ID for creating nested group. |
| `shared_runners_minutes_limit`       | integer | no       | **(STARTER ONLY)** Pipeline minutes quota for this group. |
| `extra_shared_runners_minutes_limit` | integer | no       | **(STARTER ONLY)** Extra pipeline minutes quota for this group. |

## Transfer project to group

Transfer a project to the Group namespace. Available only for admin

```
POST  /groups/:id/projects/:project_id
```

Parameters:

| Attribute    | Type           | Required | Description |
| ------------ | -------------- | -------- | ----------- |
| `id`         | integer/string | yes      | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `project_id` | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |

## Update group

Updates the project group. Only available to group owners and administrators.

```
PUT /groups/:id
```

| Attribute                            | Type    | Required | Description |
| ------------------------------------ | ------- | -------- | ----------- |
| `id`                                 | integer | yes      | The ID of the group. |
| `name`                               | string  | no       | The name of the group. |
| `path`                               | string  | no       | The path of the group. |
| `description`                        | string  | no       | The description of the group. |
| `membership_lock`                    | boolean | no       | **(STARTER)** Prevent adding new members to project membership within this group. |
| `share_with_group_lock`              | boolean | no       | Prevent sharing a project with another group within this group. |
| `visibility`                         | string  | no       | The visibility level of the group. Can be `private`, `internal`, or `public`. |
| `share_with_group_lock`              | boolean | no       | Prevent sharing a project with another group within this group. |
| `require_two_factor_authentication`  | boolean | no       | Require all users in this group to setup Two-factor authentication. |
| `two_factor_grace_period`            | integer | no       | Time before Two-factor authentication is enforced (in hours). |
| `project_creation_level`             | string  | no       | Determine if developers can create projects in the group. Can be `noone` (No one), `maintainer` (Maintainers), or `developer` (Developers + Maintainers). |
| `auto_devops_enabled`                | boolean | no       | Default to Auto DevOps pipeline for all projects within this group. |
| `subgroup_creation_level`            | integer | no       | Allowed to create subgroups. Can be `owner` (Owners), or `maintainer` (Maintainers). |
| `emails_disabled`                    | boolean | no       | Disable email notifications |
| `lfs_enabled` (optional)             | boolean | no       | Enable/disable Large File Storage (LFS) for the projects in this group. |
| `request_access_enabled`             | boolean | no       | Allow users to request member access. |
| `file_template_project_id`           | integer | no       | **(PREMIUM)** The ID of a project to load custom file templates from. |
| `shared_runners_minutes_limit`       | integer | no       | **(STARTER ONLY)** Pipeline minutes quota for this group. |
| `extra_shared_runners_minutes_limit` | integer | no       | **(STARTER ONLY)** Extra pipeline minutes quota for this group. |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5?name=Experimental"

```

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
  "projects": [
    {
      "id": 9,
      "description": "foo",
      "default_branch": "master",
      "tag_list": [],
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

## Remove group

Removes group with all projects inside. Only available to group owners and administrators.

```
DELETE /groups/:id
```

Parameters:

- `id` (required) - The ID or path of a user group

This will queue a background job to delete all projects in the group. The
response will be a 202 Accepted if the user has authorization.

## Search for group

Get all groups that match your string in their name or path.

```
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

## Group Audit Events **(STARTER)**

Group audit events can be accessed via the [Group Audit Events API](audit_events.md#group-audit-events-starter)

## Sync group with LDAP **(CORE ONLY)**

Syncs the group with its linked LDAP group. Only available to group owners and administrators.

```
POST /groups/:id/ldap_sync
```

Parameters:

- `id` (required) - The ID or path of a user group

## Group members

Please consult the [Group Members](members.md) documentation.

### Add LDAP group link **(CORE ONLY)**

Adds an LDAP group link.

```
POST /groups/:id/ldap_group_links
```

Parameters:

- `id` (required) - The ID of a group
- `cn` (required) - The CN of a LDAP group
- `group_access` (required) - Minimum access level for members of the LDAP group
- `provider` (required) - LDAP provider for the LDAP group

### Delete LDAP group link **(CORE ONLY)**

Deletes an LDAP group link.

```
DELETE /groups/:id/ldap_group_links/:cn
```

Parameters:

- `id` (required) - The ID of a group
- `cn` (required) - The CN of a LDAP group

Deletes a LDAP group link for a specific LDAP provider

```
DELETE /groups/:id/ldap_group_links/:provider/:cn
```

Parameters:

- `id` (required) - The ID of a group
- `cn` (required) - The CN of a LDAP group
- `provider` (required) - Name of a LDAP provider

## Namespaces in groups

By default, groups only get 20 namespaces at a time because the API results are paginated.

To get more (up to 100), pass the following as an argument to the API call:

```
/groups?per_page=100
```

And to switch pages add:

```
/groups?per_page=100&page=2
```

[ce-15142]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/15142

## Group badges

Read more in the [Group Badges](group_badges.md) documentation.
