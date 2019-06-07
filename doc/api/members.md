# Group and project members API

**Valid access levels**

The access levels are defined in the `Gitlab::Access` module. Currently, these levels are recognized:

```
10 => Guest access
20 => Reporter access
30 => Developer access
40 => Maintainer access
50 => Owner access # Only valid for groups
```

## List all members of a group or project

Gets a list of group or project members viewable by the authenticated user.
Returns only direct members and not inherited members through ancestors groups.

```
GET /groups/:id/members
GET /projects/:id/members
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `query`   | string | no     | A query string to search for members |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/:id/members
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/members
```

Example response:

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "expires_at": "2012-10-22T14:13:35Z",
    "access_level": 30
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "expires_at": "2012-10-22T14:13:35Z",
    "access_level": 30
  }
]
```

## List all members of a group or project including inherited members

Gets a list of group or project members viewable by the authenticated user, including inherited members through ancestor groups.
When a user is a member of the project/group and of one or more ancestor groups the user is returned only once with the project access_level (if exists)
or the access_level for the user in the first group which he belongs to in the project groups ancestors chain.
**Note:** We plan to [change](https://gitlab.com/gitlab-org/gitlab-ce/issues/62284) this behavior to return highest access_level instead.

```
GET /groups/:id/members/all
GET /projects/:id/members/all
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `query`   | string | no     | A query string to search for members |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/:id/members/all
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/members/all
```

Example response:

```json
[
  {
    "id": 1,
    "username": "raymond_smith",
    "name": "Raymond Smith",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "expires_at": "2012-10-22T14:13:35Z",
    "access_level": 30
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "expires_at": "2012-10-22T14:13:35Z",
    "access_level": 30
  },
  {
    "id": 3,
    "username": "foo_bar",
    "name": "Foo bar",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "expires_at": "2012-11-22T14:13:35Z",
    "access_level": 30
  }
]
```

## Get a member of a group or project

Gets a member of a group or project.

```
GET /groups/:id/members/:user_id
GET /projects/:id/members/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```bash
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/:id/members/:user_id
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/members/:user_id
```

Example response:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "access_level": 30,
  "expires_at": null
}
```

## Add a member to a group or project

Adds a member to a group or project.

```
POST /groups/:id/members
POST /projects/:id/members
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer         | yes | The user ID of the new member |
| `access_level` | integer | yes | A valid access level |
| `expires_at` | string | no | A date string in the format YEAR-MONTH-DAY |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "user_id=1&access_level=30" https://gitlab.example.com/api/v4/groups/:id/members
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "user_id=1&access_level=30" https://gitlab.example.com/api/v4/projects/:id/members
```

Example response:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "expires_at": "2012-10-22T14:13:35Z",
  "access_level": 30
}
```

## Edit a member of a group or project

Updates a member of a group or project.

```
PUT /groups/:id/members/:user_id
PUT /projects/:id/members/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |
| `access_level` | integer | yes | A valid access level |
| `expires_at` | string | no | A date string in the format YEAR-MONTH-DAY |

```bash
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/:id/members/:user_id?access_level=40
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/members/:user_id?access_level=40
```

Example response:

```json
{
  "id": 1,
  "username": "raymond_smith",
  "name": "Raymond Smith",
  "state": "active",
  "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
  "web_url": "http://192.168.1.8:3000/root",
  "expires_at": "2012-10-22T14:13:35Z",
  "access_level": 40
}
```

## Remove a member from a group or project

Removes a user from a group or project.

```
DELETE /groups/:id/members/:user_id
DELETE /projects/:id/members/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/groups/:id/members/:user_id
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/:id/members/:user_id
```

## Give a group access to a project

Look at [share project with group](projects.md#share-project-with-group)
