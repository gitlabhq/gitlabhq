---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Namespaces API **(FREE)**

Usernames and group names fall under a special category called
[namespaces](../user/namespace/index.md).

You might also want to view documentation for:

- [Users](users.md)
- [Groups](groups.md)

[Pagination](rest/index.md#pagination) is used.

## List namespaces

Get a list of the namespaces of the authenticated user. If the user is an
administrator, a list of all namespaces in the GitLab instance is shown.

```plaintext
GET /namespaces
GET /namespaces?search=foobar
GET /namespaces?owned_only=true
```

| Attribute    | Type    | Required | Description |
| ------------ | ------- | -------- | ----------- |
| `search`     | string  | no       | Returns a list of namespaces the user is authorized to view based on the search criteria |
| `owned_only` | boolean | no       | In GitLab 14.2 and later, returns a list of owned namespaces only |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces"
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
    "plan": "default",
    "trial_ends_on": null,
    "trial": false
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
    "plan": "default",
    "trial_ends_on": null,
    "trial": false
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
    "plan": "default",
    "trial_ends_on": null,
    "trial": false
  }
]
```

Owners also see the `plan` property associated with a namespace:

```json
[
  {
    "id": 1,
    "name": "user1",
    "plan": "silver",
    ...
  }
]
```

Users on GitLab.com also see `max_seats_used`, `seats_in_use` and `max_seats_used_changed_at` parameters.
`max_seats_used` is the highest number of users the group had. `seats_in_use` is
the number of license seats currently being used. `max_seats_used_changed_at` shows the date when the `max_seats_used` value changed. All the values are updated
once a day.

`max_seats_used` and `seats_in_use` are non-zero only for namespaces on paid plans.

```json
[
  {
    "id": 1,
    "name": "user1",
    "billable_members_count": 2,
    "max_seats_used": 3,
    "max_seats_used_changed_at":"2023-02-13T12:00:02.000Z",
    "seats_in_use": 2,
    ...
  }
]
```

NOTE:
Only group owners are presented with `members_count_with_descendants` and `plan`.

## Get namespace by ID

Get a namespace by ID.

```plaintext
GET /namespaces/:id
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | ID or [URL-encoded path of the namespace](rest/index.md#namespaced-path-encoding) |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces/2"
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
  "trial_ends_on": null,
  "trial": false
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
  "trial_ends_on": null,
  "trial": false
}
```

## Get existence of a namespace

Get existence of a namespace by path. Suggests a new namespace path that does not already exist.

```plaintext
GET /namespaces/:namespace/exists
```

| Attribute   | Type    | Required | Description |
| ----------- | ------- | -------- | ----------- |
| `namespace` | string  | yes      | Namespace's path. |
| `parent_id` | integer | no       | The ID of the parent namespace. If no ID is specified, only top-level namespaces are considered. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces/my-group/exists?parent_id=1"
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
