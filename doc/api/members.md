---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Group and project members API

## Valid access levels

The access levels are defined in the `Gitlab::Access` module. Currently, these levels are recognized:

- No access (`0`)
- Minimal access (`5`) ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/220203) in GitLab 13.5.)
- Guest (`10`)
- Reporter (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`) - Only valid to set for groups

WARNING:
Due to [an issue](https://gitlab.com/gitlab-org/gitlab/-/issues/219299),
projects in personal namespaces don't show owner (`50`) permission
for owner.

## Limitations

The `group_saml_identity` attribute is only visible to a group owner for [SSO enabled groups](../user/group/saml_sso/index.md).

The `email` attribute is only visible to a group owner who manages the user through [Group Managed Accounts](../user/group/saml_sso/group_managed_accounts.md).

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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](index.md#namespaced-path-encoding) owned by the authenticated user |
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

Gets a list of group or project members viewable by the authenticated user, including inherited members and permissions through ancestor groups.

If a user is a member of this group or project and also of one or more ancestor groups,
only its membership with the highest `access_level` is returned.
([Improved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56677)] in GitLab 13.11.)
This represents the effective permission of the user.

This function takes pagination parameters `page` and `per_page` to restrict the list of users.

```plaintext
GET /groups/:id/members/all
GET /projects/:id/members/all
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](index.md#namespaced-path-encoding) owned by the authenticated user |
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
    "access_level": 30,
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](index.md#namespaced-path-encoding) owned by the authenticated user |
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
  "email": "john@example.com",
  "created_at": "2012-10-22T14:13:35Z",
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](index.md#namespaced-path-encoding) owned by the authenticated user |
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
  "email": "john@example.com",
  "expires_at": null,
  "group_saml_identity": null
}
```

## List all billable members of a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217384) in GitLab 13.5.

Gets a list of group members that count as billable. The list includes members in the subgroup or subproject.

This API endpoint works on top-level groups only. It does not work on subgroups.

NOTE:
Unlike other API endpoints, billable members is updated once per day at 12:00 UTC.

This function takes [pagination](index.md#pagination) parameters `page` and `per_page` to restrict the list of users.

[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/262875) in GitLab 13.7, the `search` and
`sort` parameters allow you to search for billable group members by name and sort the results,
respectively.

```plaintext
GET /groups/:id/billable_members
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `search`  | string         | no  | A query string to search for group members by name, username, or email. |
| `sort`    | string         | no  | A query string containing parameters that specify the sort attribute and order. See supported values below.|

The supported values for the `sort` attribute are:

| Value                   | Description                  |
| ----------------------- | ---------------------------- |
| `access_level_asc`      | Access level, ascending      |
| `access_level_desc`     | Access level, descending     |
| `last_joined`           | Last joined                  |
| `name_asc`              | Name, ascending              |
| `name_desc`             | Name, descending             |
| `oldest_joined`         | Oldest joined                |
| `oldest_sign_in`        | Oldest sign in               |
| `recent_sign_in`        | Recent sign in               |
| `last_activity_on_asc`  | Last active date, ascending  |
| `last_activity_on_desc` | Last active date, descending |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/billable_members"
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
    "last_activity_on": "2021-01-27",
    "membership_type": "group_member",
    "removable": true
  },
  {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "email": "john@example.com",
    "last_activity_on": "2021-01-25",
    "membership_type": "group_member",
    "removable": true
  },
  {
    "id": 3,
    "username": "foo_bar",
    "name": "Foo bar",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root",
    "last_activity_on": "2021-01-20",
    "membership_type": "group_invite",
    "removable": false
  }
]
```

## List memberships for a billable member of a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/321560) in GitLab 13.11.

Gets a list of memberships for a billable member of a group.

Lists all projects and groups a user is a member of. Only projects and groups within the group hierarchy are included.
For instance, if the requested group is `Root Group`, and the requested user is a direct member of both `Root Group / Sub Group One` and `Other Group / Sub Group Two`, then only `Root Group / Sub Group One` will be returned, because `Other Group / Sub Group Two` is not within the `Root Group` hierarchy.

The response represents only direct memberships. Inherited memberships are not included.

This API endpoint works on top-level groups only. It does not work on subgroups.

This API endpoint requires permission to admin memberships for the group.

This API endpoint takes [pagination](index.md#pagination) parameters `page` and `per_page` to restrict the list of memberships.

```plaintext
GET /groups/:id/billable_members/:user_id/memberships
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer        | yes | The user ID of the billable member |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id/memberships"
```

Example response:

```json
[
  {
    "id": 168,
    "source_id": 131,
    "source_full_name": "Root Group / Sub Group One",
    "source_members_url": "https://gitlab.example.com/groups/root-group/sub-group-one/-/group_members",
    "created_at": "2021-03-31T17:28:44.812Z",
    "expires_at": "2022-03-21",
    "access_level": {
      "string_value": "Developer",
      "integer_value": 30
    }
  },
  {
    "id": 169,
    "source_id": 63,
    "source_full_name": "Root Group / Sub Group One / My Project",
    "source_members_url": "https://gitlab.example.com/root-group/sub-group-one/my-project/-/project_members",
    "created_at": "2021-03-31T17:29:14.934Z",
    "expires_at": null,
    "access_level": {
      "string_value": "Maintainer",
      "integer_value": 40
    }
  }
]
```

## Remove a billable member from a group

Removes a billable member from a group and its subgroups and projects.

The user does not need to be a group member to qualify for removal.
For example, if the user was added directly to a project within the group, you can
still use this API to remove them.

```plaintext
DELETE /groups/:id/billable_members/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id"
```

## Add a member to a group or project

Adds a member to a group or project.

```plaintext
POST /groups/:id/members
POST /projects/:id/members
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer/string | yes | The user ID of the new member or multiple IDs separated by commas |
| `access_level` | integer | yes | A valid access level |
| `expires_at` | string | no | A date string in the format `YEAR-MONTH-DAY` |
| `invite_source` | string | no | The source of the invitation that starts the member creation process. See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/327120). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/members"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" "https://gitlab.example.com/api/v4/projects/:id/members"
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
  "email": "john@example.com",
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |
| `access_level` | integer | yes | A valid access level |
| `expires_at` | string | no | A date string in the format `YEAR-MONTH-DAY` |

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
  "email": "john@example.com",
  "group_saml_identity": null
}
```

### Set override flag for a member of a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/4875) in GitLab 13.0.

By default, the access level of LDAP group members is set to the value specified
by LDAP through Group Sync. You can allow access level overrides by calling this endpoint.

```plaintext
POST /groups/:id/members/:user_id/override
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
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
  "email": "john@example.com",
  "override": true
}
```

### Remove override for a member of a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/4875) in GitLab 13.0.

Sets the override flag to false and allows LDAP Group Sync to reset the access
level to the LDAP-prescribed value.

```plaintext
DELETE /groups/:id/members/:user_id/override
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
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
  "email": "john@example.com",
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |
| `skip_subresources` | boolean | false   | Whether the deletion of direct memberships of the removed member in subgroups and projects should be skipped. Default is `false`. |
| `unassign_issuables` | boolean | false   | Whether the removed member should be unassigned from any issues or merge requests inside a given group or project. Default is `false`. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

## Give a group access to a project

See [share project with group](projects.md#share-project-with-group)
