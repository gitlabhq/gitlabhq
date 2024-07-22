---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group and project members API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

## Roles

The [role](../user/permissions.md) assigned to a user or group is defined
in the `Gitlab::Access` module as `access_level`.

- No access (`0`)
- Minimal access (`5`)
- Guest (`10`)
- Reporter (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`)
- Admin (`60`)

## Limitations

The `group_saml_identity` attribute is only visible to group owners for [SSO-enabled groups](../user/group/saml_sso/index.md).

The `email` attribute is only visible to group owners for [enterprise users](../user/enterprise_user/index.md) of the group when an API request is sent to the group itself, or that group's subgroups or projects.

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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `query`   | string | no     | A query string to search for members |
| `user_ids`   | array of integers | no     | Filter the results on the given user IDs |
| `skip_users`   | array of integers | no     | Filter skipped users out of the results |
| `show_seat_info`   | boolean | no     | Show seat information for users |

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
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
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
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 1,
      "username": "raymond_smith",
      "name": "Raymond Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
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

## List all members of a group or project including inherited and invited members

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) to return members of the invited private group if the current user is a member of the shared group or project in GitLab 16.10 [with a flag](../administration/feature_flags.md) named `webui_members_inherited_users`. Disabled by default.
> - Feature flag `webui_members_inherited_users` was [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) in GitLab 17.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature per user, an administrator can [disable the feature flag](../administration/feature_flags.md) named `webui_members_inherited_users`.
On GitLab.com and GitLab Dedicated, this feature is available.

Gets a list of group or project members viewable by the authenticated user, including inherited members, invited users, and permissions through ancestor groups.

If a user is a member of this group or project and also of one or more ancestor groups,
only its membership with the highest `access_level` is returned.
This represents the effective permission of the user.

Members from an invited group are returned if either:

- The invited group is public.
- The requester is also a member of the invited group.
- The requester is a member of the shared group or project.

NOTE:
The invited group members have shared membership in the shared group or project.
This means that if the requester is a member of a shared group or project, but not a member of an invited private group,
then using this endpoint the requester can get all the shared group or project members, including the invited private group members.

This function takes pagination parameters `page` and `per_page` to restrict the list of users.

```plaintext
GET /groups/:id/members/all
GET /projects/:id/members/all
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `query`   | string | no     | A query string to search for members. |
| `user_ids`   | array of integers | no     | Filter the results on the given user IDs. |
| `show_seat_info`   | boolean | no     | Show seat information for users. |
| `state`   | string | no | Filter results by member state, one of `awaiting` or `active`. Premium and Ultimate only. |

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
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
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
    "created_at": "2012-09-22T14:13:35Z",
    "created_by": {
      "id": 1,
      "username": "raymond_smith",
      "name": "Raymond Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-10-22",
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
    "created_at": "2012-10-22T14:13:35Z",
    "created_by": {
      "id": 2,
      "username": "john_doe",
      "name": "John Doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
      "web_url": "http://192.168.1.8:3000/root"
    },
    "expires_at": "2012-11-22",
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
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
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": null,
  "group_saml_identity": null
}
```

## Get a member of a group or project, including inherited and invited members

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17744) in GitLab 12.4.
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) to return members of the invited private group if the current user is a member of the shared group or project in GitLab 16.10 [with a flag](../administration/feature_flags.md) named `webui_members_inherited_users`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) in GitLab 17.0.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature per user, an administrator can [disable the feature flag](../administration/feature_flags.md) named `webui_members_inherited_users`.
On GitLab.com and GitLab Dedicated, this feature is available.

Gets a member of a group or project, including members inherited or invited through ancestor groups. See the corresponding [endpoint to list all inherited members](#list-all-members-of-a-group-or-project-including-inherited-and-invited-members) for details.

NOTE:
The invited group members have shared membership in the shared group or project.
This means that if the requester is a member of a shared group or project, but not a member of an invited private group,
then using this endpoint the requester can get all the shared group or project members, including the invited private group members.

```plaintext
GET /groups/:id/members/all/:user_id
GET /projects/:id/members/all/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
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
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "email": "john@example.com",
  "expires_at": null,
  "group_saml_identity": null
}
```

## List all billable members of a group

Prerequisites:

- You must have the Owner role to access the API endpoint for billing permissions, as shown in [billing permissions](../user/free_user_limit.md).

Gets a list of group members that count as billable. The list includes members in subgroups and projects.

This API endpoint works on top-level groups only. It does not work on subgroups.

This function takes [pagination](rest/index.md#pagination) parameters `page` and `per_page` to restrict the list of users.

Use the `search` parameter to search for billable group members by name and `sort` to sort the results.

```plaintext
GET /groups/:id/billable_members
```

| Attribute                     | Type            | Required  | Description                                                                                                   |
| ----------------------------- | --------------- | --------- |-------------------------------------------------------------------------------------------------------------- |
| `id`                          | integer/string  | yes       | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user  |
| `search`                      | string          | no        | A query string to search for group members by name, username, or public email.                                |
| `sort`                        | string          | no        | A query string containing parameters that specify the sort attribute and order. See supported values below.   |

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
    "removable": true,
    "created_at": "2021-01-03T12:16:02.000Z",
    "last_login_at": "2022-10-09T01:33:06.000Z"
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
    "removable": true,
    "created_at": "2021-01-04T18:46:42.000Z",
    "last_login_at": "2022-09-29T22:18:46.000Z"
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
    "removable": false,
    "created_at": "2021-01-09T07:12:31.000Z",
    "last_login_at": "2022-10-10T07:28:56.000Z"
  }
]
```

## List memberships for a billable member of a group

Gets a list of memberships for a billable member of a group.

Lists all projects and groups a user is a member of. Only projects and groups within the group hierarchy are included.
For instance, if the requested group is `Root Group`, and the requested user is a direct member of both `Root Group / Sub Group One` and `Other Group / Sub Group Two`, then only `Root Group / Sub Group One` will be returned, because `Other Group / Sub Group Two` is not within the `Root Group` hierarchy.

The response represents only direct memberships. Inherited memberships are not included.

This API endpoint works on top-level groups only. It does not work on subgroups.

This API endpoint requires permission to administer memberships for the group.

This API endpoint takes [pagination](rest/index.md#pagination) parameters `page` and `per_page` to restrict the list of memberships.

```plaintext
GET /groups/:id/billable_members/:user_id/memberships
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
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

## List indirect memberships for a billable member of a group

DETAILS:
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/386583) in GitLab 16.11.

Gets a list of indirect memberships for a billable member of a group.

Lists all projects and groups that a user is a member of, that have been invited to the requested root group.
For instance, if the requested group is `Root Group`, and the requested user is a direct member of `Other Group / Sub Group Two`, which was invited to `Root Group`, then only `Other Group / Sub Group Two` is returned.

The response lists only indirect memberships. Direct memberships are not included.

This API endpoint works on top-level groups only. It does not work on subgroups.

This API endpoint requires permission to administer memberships for the group.

This API endpoint takes [pagination](rest/index.md#pagination) parameters `page` and `per_page` to restrict the list of memberships.

```plaintext
GET /groups/:id/billable_members/:user_id/indirect
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer        | yes | The user ID of the billable member |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id/indirect"
```

Example response:

```json
[
  {
    "id": 168,
    "source_id": 132,
    "source_full_name": "Invited Group / Sub Group One",
    "source_members_url": "https://gitlab.example.com/groups/invited-group/sub-group-one/-/group_members",
    "created_at": "2021-03-31T17:28:44.812Z",
    "expires_at": "2022-03-21",
    "access_level": {
      "string_value": "Developer",
      "integer_value": 30
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/billable_members/:user_id"
```

## Change membership state of a user in a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86705) in GitLab 15.0.

Changes the membership state of a user in a group.
When a user is over [the free user limit](../user/free_user_limit.md), changing their membership state for a group or project to `awaiting` or `active` can allow them to
access that group or project. The change is applied to applied to all subgroups and projects.

```plaintext
PUT /groups/:id/members/:user_id/state
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `user_id` | integer | yes   | The user ID of the member. |
| `state`   | string | yes   | The new state for the user. State is either `awaiting` or `active`. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/state?state=active"
```

Example response:

```json
{
  "success":true
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `user_id` | integer/string | yes, if `username` is not provided | The user ID of the new member or multiple IDs separated by commas. |
| `username` | string | yes, if `user_id` is not provided | The username of the new member or multiple usernames separated by commas. |
| `access_level` | integer | yes | [A valid access level](access_requests.md#valid-access-levels). |
| `expires_at` | string | no | A date string in the format `YEAR-MONTH-DAY`. |
| `invite_source` | string | no | The source of the invitation that starts the member creation process. GitLab team members can view more information in this confidential issue: `https://gitlab.com/gitlab-org/gitlab/-/issues/327120>`. |
| `member_role_id` | integer | no | The ID of a member role. Ultimate only. |

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
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |
| `access_level` | integer | yes | A [valid access level](access_requests.md#valid-access-levels) |
| `expires_at` | string | no | A date string in the format `YEAR-MONTH-DAY` |
| `member_role_id` | integer | no | The ID of a member role. Ultimate only. |

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
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "group_saml_identity": null
}
```

### Set override flag for a member of a group

By default, the access level of LDAP group members is set to the value specified
by LDAP through Group Sync. You can allow access level overrides by calling this endpoint.

```plaintext
POST /groups/:id/members/:user_id/override
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id/override"
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
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "override": true
}
```

### Remove override for a member of a group

Sets the override flag to false and allows LDAP Group Sync to reset the access
level to the LDAP-prescribed value.

```plaintext
DELETE /groups/:id/members/:user_id/override
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
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
  "created_at": "2012-10-22T14:13:35Z",
  "created_by": {
    "id": 2,
    "username": "john_doe",
    "name": "John Doe",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/c2525a7f58ae3776070e44c106c48e15?s=80&d=identicon",
    "web_url": "http://192.168.1.8:3000/root"
  },
  "expires_at": "2012-10-22",
  "access_level": 40,
  "email": "john@example.com",
  "override": false
}
```

## Remove a member from a group or project

Removes a user from a group or project where the user has been explicitly assigned a role.

The user needs to be a group member to qualify for removal.
For example, if the user was added directly to a project within the group but not this
group explicitly, you cannot use this API to remove them. See
[Remove a billable member from a group](#remove-a-billable-member-from-a-group) for an alternative approach.

```plaintext
DELETE /groups/:id/members/:user_id
DELETE /projects/:id/members/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `user_id` | integer | yes   | The user ID of the member |
| `skip_subresources` | boolean | false   | Whether the deletion of direct memberships of the removed member in subgroups and projects should be skipped. Default is `false`. |
| `unassign_issuables` | boolean | false   | Whether the removed member should be unassigned from any issues or merge requests inside a given group or project. Default is `false`. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/:user_id"
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

## Approve a member for a group

Approves a pending user for a group and its subgroups and projects.

```plaintext
PUT /groups/:id/members/:member_id/approve
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the root group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |
| `member_id` | integer | yes   | The ID of the member |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/:member_id/approve"
```

## Approve all pending members for a group

Approves all pending users for a group and its subgroups and projects.

```plaintext
POST /groups/:id/members/approve_all
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the root group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/members/approve_all"
```

## List pending members of a group and its subgroups and projects

For a group and its subgroups and projects, get a list of all members in an `awaiting` state and those who are invited but do not have a GitLab account.

This request returns all matching group and project members from all groups and projects in the root group's hierarchy.

When the member is an invited user that has not signed up for a GitLab account yet, the invited email address is returned.

This API endpoint works on top-level groups only. It does not work on subgroups.

This API endpoint requires permission to administer members for the group.

This API endpoint takes [pagination](rest/index.md#pagination) parameters `page` and `per_page` to restrict the list of members.

```plaintext
GET /groups/:id/pending_members
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/pending_members"
```

Example response:

```json
[
  {
    "id": 168,
    "name": "Alex Garcia",
    "username": "alex_garcia",
    "email": "alex@example.com",
    "avatar_url": "http://example.com/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://example.com/alex_garcia",
    "approved": false,
    "invited": false
  },
  {
    "id": 169,
    "email": "sidney@example.com",
    "avatar_url": "http://gravatar.com/../e346561cd8.jpeg",
    "approved": false,
    "invited": true
  },
  {
    "id": 170,
    "email": "zhang@example.com",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "approved": true,
    "invited": true
  }
]
```

## Give a group access to a project

See [share project with group](projects.md#share-project-with-group)
