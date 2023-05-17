---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Member roles API **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96996) in GitLab 15.4. [Deployed behind the `customizable_roles` flag](../administration/feature_flags.md), disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110810) in GitLab 15.9.

## List all member roles of a group

Gets a list of group member roles viewable by the authenticated user.

```plaintext
GET /groups/:id/member_roles
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |

If successful, returns [`200`](rest/index.md#status-codes) and the following response attributes:

| Attribute                | Type     | Description           |
|:-------------------------|:---------|:----------------------|
| `[].id`                  | integer | The ID of the member role. |
| `[].group_id`            | integer | The ID of the group that the member role belongs to. |
| `[].base_access_level`   | integer | Base access level for member role. |
| `[].read_code`           | boolean | Permission to read code. |

Example request:

```shell
curl --header "Authorization: Bearer <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/member_roles"
```

Example response:

```json
[
  {
    "id": 2,
    "group_id": 84,
    "base_access_level": 10,
    "read_code": true
  },
  {
    "id": 3,
    "group_id": 84,
    "base_access_level": 10,
    "read_code": false
  }
]
```

## Add a member role to a group

Adds a member role to a group.

```plaintext
POST /groups/:id/member_roles
```

To add a member role to a group, the group must be at root-level (have no parent group).

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `base_access_level` | integer | yes   | Base access level for configured role. |
| `read_code` | boolean | no | Permission to read code.  |

If successful, returns [`201`](rest/index.md#status-codes) and the following attributes:

| Attribute                | Type     | Description           |
|:-------------------------|:---------|:----------------------|
| `id`                     | integer | The ID of the member role. |
| `group_id`               | integer | The ID of the group that the member role belongs to. |
| `base_access_level`      | integer | Base access level for member role. |
| `read_code`              | boolean | Permission to read code. |

Example request:

```shell
 curl --request POST --header "Content-Type: application/json" --header "Authorization: Bearer $YOUR_ACCESS_TOKEN" --data '{"base_access_level" : 10, "read_code" : true}' "https://example.gitlab.com/api/v4/groups/:id/member_roles"
```

Example response:

```json
{
  "id": 3,
  "group_id": 84,
  "base_access_level": 10,
  "read_code": true
}
```

### Remove member role of a group

Deletes a member role of a group.

```plaintext
DELETE /groups/:id/member_roles/:member_role_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `member_role_id` | integer | yes   | The ID of the member role. |

If successful, returns [`204`](rest/index.md#status-codes) and an empty response.

Example request:

```shell
curl --request DELETE --header "Content-Type: application/json" --header "Authorization: Bearer $YOUR_ACCESS_TOKEN" "https://example.gitlab.com/api/v4/groups/:group_id/member_roles/:member_role_id"
```
