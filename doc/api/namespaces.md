---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Namespaces API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use this API to interact with namespaces, a special resource category used to organize users and groups. For more information, see [Namespaces](../user/namespace/_index.md).

This API uses [Pagination](rest/_index.md#pagination) to filter results.

## List all namespaces

> - `top_level_only` [introduced](https://gitlab.com/gitlab-org/customers-gitlab-com/-/issues/7600) in GitLab 16.8.

Lists all namespaces available to the current user. If the user is an
administrator, this endpoint returns all namespaces in the instance.

```plaintext
GET /namespaces
```

| Attribute        | Type    | Required | Description |
| ---------------- | ------- | -------- | ----------- |
| `search`         | string  | no       | Only returns namespaces accessible by the current user. |
| `owned_only`     | boolean | no       | If `true`, only returns namespaces by the current user. |
| `top_level_only` | boolean | no       | In GitLab 16.8 and later, if `true`, only returns top-level namespaces. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "user1",
    "path": "user1",
    "kind": "user",
    "full_path": "user1",
    "parent_id": null,
    "avatar_url": "https://secure.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "https://gitlab.example.com/user1",
    "billable_members_count": 1,
    "plan": "ultimate",
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  },
  {
    "id": 2,
    "name": "group1",
    "path": "group1",
    "kind": "group",
    "full_path": "group1",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/group1",
    "members_count_with_descendants": 2,
    "billable_members_count": 2,
    "plan": "ultimate",
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  },
  {
    "id": 3,
    "name": "bar",
    "path": "bar",
    "kind": "group",
    "full_path": "foo/bar",
    "parent_id": 9,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/foo/bar",
    "members_count_with_descendants": 5,
    "billable_members_count": 5,
    "end_date": null,
    "trial_ends_on": null,
    "trial": false,
    "root_repository_size": 100,
    "projects_count": 3
  }
]
```

Additional attributes might be returned for Group owners or on GitLab.com:

```json
[
  {
    ...
    "max_seats_used": 3,
    "max_seats_used_changed_at":"2025-05-15T12:00:02.000Z",
    "seats_in_use": 2,
    "projects_count": 1,
    "root_repository_size":0,
    "members_count_with_descendants":26,
    "plan": "free",
    ...
  }
]
```

## Get details on a namespace

Gets details on a specified namespace.

```plaintext
GET /namespaces/:id
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the namespace. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces/2"
```

Example response:

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100,
  "projects_count": 3
}
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces/group1"
```

Example response:

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "avatar_url": null,
  "web_url": "https://gitlab.example.com/groups/group1",
  "members_count_with_descendants": 2,
  "billable_members_count": 2,
  "max_seats_used": 0,
  "seats_in_use": 0,
  "plan": "default",
  "end_date": null,
  "trial_ends_on": null,
  "trial": false,
  "root_repository_size": 100
}
```

## Verify namespace availability

Verifies if a specified namespace already exists. If the namespace does exist, the endpoint suggests an alternate name.

```plaintext
GET /namespaces/:namespace/exists
```

| Attribute   | Type    | Required | Description |
| ----------- | ------- | -------- | ----------- |
| `namespace` | string  | yes      | Path of the namespace. |
| `parent_id` | integer | no       | ID of the parent namespace. If unspecified, only returns top-level namespaces. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces/my-group/exists?parent_id=1"
```

Example response:

```json
{
    "exists": true,
    "suggests": [
        "my-group1"
    ]
}
```
