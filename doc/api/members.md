# Group and project members API

**Valid access levels**

The access levels are defined in the `Gitlab::Access` module. Currently, these levels are recognized:

- No access (`0`)
- Guest (`10`)
- Reporter (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`) - Only valid to set for groups

CAUTION: **Caution:**
Due to [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/219299),
projects in personal namespaces will not show owner (`50`) permission
for owner.

## List all members of a group or project

Gets a list of group or project members viewable by the authenticated user.
Returns only direct members and not inherited members through ancestors groups.

This function takes pagination parameters `page` and `per_page` to restrict the list of users.

```plaintext
GET /groups/:id/members
GET /projects/:id/members
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `query`   | string | no     | A query string to search for members |
| `user_ids`   | array of integers | no     | Filter the results on the given user IDs |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members"
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/members"
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
    "access_level": 30,
    "group_saml_identity": null
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "expires_at": "2012-10-22T14:13:35Z",
    "access_level": 30,
    "email": "john@example.com",
    "group_saml_identity": {
      "extern_uid":"ABC-1234567890",
      "provider": "group_saml",
      "saml_provider_id": 10
    }
  }
]
```

## List all members of a group or project including inherited members

Gets a list of group or project members viewable by the authenticated user, including inherited members through ancestor groups.
When a user is a member of the project/group and of one or more ancestor groups the user is returned only once with the project `access_level` (if exists)
or the `access_level` for the user in the first group which they belong to in the project groups ancestors chain.

This function takes pagination parameters `page` and `per_page` to restrict the list of users.

```plaintext
GET /groups/:id/members/all
GET /projects/:id/members/all
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `query`   | string | no     | A query string to search for members |
| `user_ids`   | array of integers | no     | Filter the results on the given user IDs |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/all"
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/members/all"
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
    "access_level": 30,
    "group_saml_identity": null
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
    "email": "john@example.com",
    "group_saml_identity": {
      "extern_uid":"ABC-1234567890",
      "provider": "group_saml",
      "saml_provider_id": 10
    }
  },
  {
    "id": 3,
    "username": "foo_bar",
    "name": "Foo bar",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "expires_at": "2012-11-22T14:13:35Z",
    "access_level": 30,
    "group_saml_identity": null
  }
]
```

## Get a member of a group or project

Gets a member of a group or project. Returns only direct members and not inherited members through ancestor groups.

```plaintext
GET /groups/:id/members/:user_id
GET /projects/:id/members/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
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
  "expires_at": null,
  "group_saml_identity": null
}
```

## Get a member of a group or project, including inherited members

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17744) in GitLab 12.4.

Gets a member of a group or project, including members inherited through ancestor groups. See the corresponding [endpoint to list all inherited members](#list-all-members-of-a-group-or-project-including-inherited-members) for details.

```plaintext
GET /groups/:id/members/all/:user_id
GET /projects/:id/members/all/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/all/:user_id"
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/members/all/:user_id"
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
  "expires_at": null,
  "group_saml_identity": null
}
```

## Add a member to a group or project

Adds a member to a group or project.

```plaintext
POST /groups/:id/members
POST /projects/:id/members
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer         | yes | The user ID of the new member |
| `access_level` | integer | yes | A valid access level |
| `expires_at` | string | no | A date string in the format YEAR-MONTH-DAY |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/projects/:id/members"
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
  "access_level": 30,
  "group_saml_identity": null
}
```

## Edit a member of a group or project

Updates a member of a group or project.

```plaintext
PUT /groups/:id/members/:user_id
PUT /projects/:id/members/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |
| `access_level` | integer | yes | A valid access level |
| `expires_at` | string | no | A date string in the format YEAR-MONTH-DAY |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id?access_level=40"
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/members/:user_id?access_level=40"
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
  "access_level": 40,
  "group_saml_identity": null
}
```

### Set override flag for a member of a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/4875) in GitLab 12.10.

By default, the access level of LDAP group members is set to the value specified
by LDAP through Group Sync. You can allow access level overrides by calling this endpoint.

```plaintext
POST /groups/:id/members/:user_id/override
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```shell
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
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
  "access_level": 40,
  "override": true
}
```

### Remove override for a member of a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/4875) in GitLab 12.10.

Sets the override flag to false and allows LDAP Group Sync to reset the access
level to the LDAP-prescribed value.

```plaintext
DELETE /groups/:id/members/:user_id/override
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```shell
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
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
  "access_level": 40,
  "override": false
}
```

## Remove a member from a group or project

Removes a user from a group or project.

```plaintext
DELETE /groups/:id/members/:user_id
DELETE /projects/:id/members/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](README.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

## Give a group access to a project

See [share project with group](projects.md#share-project-with-group)
