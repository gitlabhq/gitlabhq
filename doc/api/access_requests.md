---
stage: Manage
group: Access
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Group and project access requests API

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/18583) in GitLab 8.11.

## Valid access levels

The access levels are defined in the `Gitlab::Access` module, and the
following levels are recognized:

- No access (`0`)
- Minimal access (`5`) ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220203) in GitLab 13.5.)
- Guest (`10`)
- Reporter (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`) - Only valid to set for groups

## List access requests for a group or project

Gets a list of access requests viewable by the authenticated user.

```plaintext
GET /groups/:id/access_requests
GET /projects/:id/access_requests
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/access_requests"
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/access_requests"
```

Example response:

```json
[
 {
   "id": 1,
   "username": "raymond_smith",
   "name": "Raymond Smith",
   "state": "active",
   "created_at": "2012-10-22T14:13:35Z",
   "requested_at": "2012-10-22T14:13:35Z"
 },
 {
   "id": 2,
   "username": "john_doe",
   "name": "John Doe",
   "state": "active",
   "created_at": "2012-10-22T14:13:35Z",
   "requested_at": "2012-10-22T14:13:35Z"
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
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/access_requests"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/access_requests"
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
| -------------- | -------------- | -------- | ----------- |
| `id`           | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id`      | integer        | yes      | The user ID of the access requester                                                                             |
| `access_level` | integer        | no       | A valid access level (defaults: `30`, developer access level)                                                   |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/access_requests/:user_id/approve?access_level=20"
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/access_requests/:user_id/approve?access_level=20"
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
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer        | yes      | The user ID of the access requester                                                                             |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/access_requests/:user_id"
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/access_requests/:user_id"
```
