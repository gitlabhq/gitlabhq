---
stage: Software Supply Chain Security
group: Authentication
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Group and project access requests API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use this API to interact with access requests for group and projects.

## Valid access levels

The access levels are defined in the `Gitlab::Access` module, and the
following levels are recognized:

- No access (`0`)
- Minimal access (`5`)
- Guest (`10`)
- Planner (`15`)
- Reporter (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`).

## List access requests for a group or project

Gets a list of access requests viewable by the authenticated user.

```plaintext
GET /groups/:id/access_requests
GET /projects/:id/access_requests
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/groups/:id/access_requests"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/projects/:id/access_requests"
```

Example response:

```json
[
 {
   "id": 1,
   "username": "raymond_smith",
   "name": "Raymond Smith",
   "state": "active",
   "locked": false,
   "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/1/avatar.png",
   "web_url": "https://gitlab.com/raymond_smith",
   "requested_at": "2024-10-22T14:13:35Z"
 },
 {
   "id": 2,
   "username": "john_doe",
   "name": "John Doe",
   "state": "active",
   "locked": false,
   "avatar_url": "https://gitlab.com/uploads/-/system/user/avatar/2/avatar.png",
   "web_url": "https://gitlab.com/john_doe",
   "requested_at": "2024-10-22T14:13:35Z"
 }
]
```

## Request access to a group or project

Requests access for the authenticated user to a group or project.

```plaintext
POST /groups/:id/access_requests
POST /projects/:id/access_requests
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group or project](rest/_index.md#namespaced-paths) |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>"  \
--url "https://gitlab.example.com/api/v4/groups/:id/access_requests"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>"  \
--url "https://gitlab.example.com/api/v4/projects/:id/access_requests"
```

Example response:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "created_at": "2012-10-22T14:13:35Z",
  "requested_at": "2012-10-22T14:13:35Z"
}
```

## Approve an access request

Approves an access request for the given user.

```plaintext
PUT /groups/:id/access_requests/:user_id/approve
PUT /projects/:id/access_requests/:user_id/approve
```

| Attribute      | Type           | Required | Description |
|----------------|----------------|----------|-------------|
| `id`           | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `user_id`      | integer        | yes      | The user ID of the access requester |
| `access_level` | integer        | no       | A valid access level (defaults: `30`, the Developer role) |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>"  \
--url "https://gitlab.example.com/api/v4/groups/:id/access_requests/:user_id/approve?access_level=20"
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>"  \
--url "https://gitlab.example.com/api/v4/projects/:id/access_requests/:user_id/approve?access_level=20"
```

Example response:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "created_at": "2012-10-22T14:13:35Z",
  "access_level": 20
}
```

## Deny an access request

Denies an access request for the given user.

```plaintext
DELETE /groups/:id/access_requests/:user_id
DELETE /projects/:id/access_requests/:user_id
```

| Attribute | Type           | Required | Description |
|-----------|----------------|----------|-------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `user_id` | integer        | yes      | The user ID of the access requester |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>"  \
--url "https://gitlab.example.com/api/v4/groups/:id/access_requests/:user_id"
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
--url "https://gitlab.example.com/api/v4/projects/:id/access_requests/:user_id"
```
