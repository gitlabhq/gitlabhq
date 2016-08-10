# Group and project access requests

 >**Note:** This feature was introduced in GitLab 8.11

 **Valid access levels**

 The access levels are defined in the `Gitlab::Access` module. Currently, these levels are recognized:

```
10 => Guest access
20 => Reporter access
30 => Developer access
40 => Master access
50 => Owner access # Only valid for groups
```

## List access requests for a group or project

Gets a list of access requests viewable by the authenticated user.

Returns `200` if the request succeeds.

```
GET /groups/:id/access_requests
GET /projects/:id/access_requests
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The group/project ID or path |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups/:id/access_requests
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/:id/access_requests
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

Returns `201` if the request succeeds.

```
POST /groups/:id/access_requests
POST /projects/:id/access_requests
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The group/project ID or path |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups/:id/access_requests
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/:id/access_requests
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

Returns `201` if the request succeeds.

```
PUT /groups/:id/access_requests/:user_id/approve
PUT /projects/:id/access_requests/:user_id/approve
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The group/project ID or path |
| `user_id` | integer | yes   | The user ID of the access requester |
| `access_level` | integer | no | A valid access level (defaults: `30`, developer access level) |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups/:id/access_requests/:user_id/approve?access_level=20
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/:id/access_requests/:user_id/approve?access_level=20
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

Returns `200` if the request succeeds.

```
DELETE /groups/:id/access_requests/:user_id
DELETE /projects/:id/access_requests/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The group/project ID or path |
| `user_id` | integer | yes   | The user ID of the access requester |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/groups/:id/access_requests/:user_id
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/:id/access_requests/:user_id
```
