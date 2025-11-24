---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Projects members API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this endpoint to interact with project members.

For information about group members, see the [Group members API](group_members.md).

## Known issues

- The `group_saml_identity` and `group_scim_identity` attributes are only visible to group owners for [SSO-enabled groups](../user/group/saml_sso/_index.md).
- The `email` attribute is only visible to group owners for [enterprise users](../user/enterprise_user/_index.md)
  of the group when an API request is sent to the group itself, or that group's subgroups or projects.

## List all members of a project

Gets a list of project members viewable by the authenticated user.

This function takes pagination parameters `page` and `per_page` to restrict the list of users.

```plaintext
GET /projects/:id/members
```

| Attribute        | Type              | Required | Description |
|------------------|-------------------|----------|-------------|
| `id`             | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `query`          | string            | no       | Filters results based on a given name, email, or username. Use partial values to widen the scope of the query. |
| `user_ids`       | array of integers | no       | Filter the results on the given user IDs. |
| `skip_users`     | array of integers | no       | Filter skipped users out of the results. |
| `show_seat_info` | boolean           | no       | Show seat information for users. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members"
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

## List all members of a project, including inherited and invited members

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) to return members of the invited private group if the current user is a member of the shared group or project in GitLab 16.10 [with a flag](../administration/feature_flags/_index.md) named `webui_members_inherited_users`. Disabled by default.
- Feature flag `webui_members_inherited_users` was [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) in GitLab 17.0.
- Feature flag `webui_members_inherited_users` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627) in GitLab 17.4. Members of invited groups displayed by default.

{{< /history >}}

Gets a list of project members viewable by the authenticated user, including inherited members, invited users, and permissions through ancestor groups.

If a user is a member of this project and also of one or more ancestor groups,
only its membership with the highest `access_level` is returned.
This represents the effective permission of the user.

Members from an invited group are returned if either:

- The invited group is public.
- The requester is also a member of the invited group.
- The requester is a member of the shared group or project.

{{< alert type="note" >}}

The invited group members have shared membership in the shared group or project.
This means that if the requester is a member of a shared group or project, but not a member of an invited private group,
then using this endpoint the requester can get all the shared group or project members, including the invited private group members.

{{< /alert >}}

This function takes pagination parameters `page` and `per_page` to restrict the list of users.

```plaintext
GET /projects/:id/members/all
```

| Attribute        | Type              | Required | Description |
|------------------|-------------------|----------|-------------|
| `id`             | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `query`          | string            | no       | Filters results based on a given name, email, or username. Use partial values to widen the scope of the query. |
| `user_ids`       | array of integers | no       | Filter the results on the given user IDs. |
| `show_seat_info` | boolean           | no       | Show seat information for users. |
| `state`          | string            | no       | Filter results by member state, one of `awaiting` or `active`. Premium and Ultimate only. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/all"
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

## Get a member of a project

Gets a member of a project. Returns only direct members and not inherited members through ancestor groups.

```plaintext
GET /projects/:id/members/:user_id
```

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `user_id` | integer           | yes      | The user ID of the member. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```

To update or remove a custom role from a group member, pass an empty `member_role_id` value:

```shell
# Updates a project membership
curl --request PUT --header "Content-Type: application/json" \
  --header "Authorization: Bearer <your_access_token>" \
  --data '{"member_role_id": null, "access_level": 10}' \
  --url "https://gitlab.example.com/api/v4/projects/<project_id>/members/<user_id>"
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

## Get a member of a project, including inherited and invited members

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17744) in GitLab 12.4.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) to return members of the invited private group if the current user is a member of the shared group or project in GitLab 16.10 [with a flag](../administration/feature_flags/_index.md) named `webui_members_inherited_users`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/219230) in GitLab 17.0.
- Feature flag `webui_members_inherited_users` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163627) in GitLab 17.4. Members of invited groups displayed by default.

{{< /history >}}

Gets a member of a project, including members inherited or invited through ancestor groups. See the corresponding [endpoint to list all inherited members](#list-all-members-of-a-project-including-inherited-and-invited-members) for details.

{{< alert type="note" >}}

The invited group members have shared membership in the shared group or project.
This means that if the requester is a member of a shared group or project, but not a member of an invited private group,
then using this endpoint the requester can get all the shared group or project members, including the invited private group members.

{{< /alert >}}

```plaintext
GET /projects/:id/members/all/:user_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer or string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `user_id` | integer | yes   | The user ID of the member. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/all/:user_id"
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

## Add a member to a project

Adds a member to a project.

```plaintext
POST /projects/:id/members
```

| Attribute        | Type              | Required                           | Description |
| ---------------- | ----------------- | ---------------------------------- | ----------- |
| `id`             | integer or string | yes                                | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `user_id`        | integer or string | yes, if `username` is not provided | The user ID of the new member or multiple IDs separated by commas. |
| `username`       | string            | yes, if `user_id` is not provided  | The username of the new member or multiple usernames separated by commas. |
| `access_level`   | integer           | yes                                | A valid [access level](../user/permissions.md#default-roles) Possible values: `0` (No access), `5` (Minimal access), `10` (Guest), `15` (Planner), `20` (Reporter), `30` (Developer), `40` (Maintainer), or `50` (Owner). Default: `30`. |
| `expires_at`     | string            | no                                 | A date string in the format `YEAR-MONTH-DAY`. |
| `invite_source`  | string            | no                                 | The source of the invitation that starts the member creation process. GitLab team members can view more information in this confidential issue: `https://gitlab.com/gitlab-org/gitlab/-/issues/327120`. |
| `member_role_id` | integer           | no                                 | Ultimate only. The ID of a custom member role. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
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

{{< alert type="note" >}}

If [administrator approval for role promotions](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) is turned on, membership requests that promote existing users into a billable role require administrator approval.

{{< /alert >}}

To enable **Manage Non-Billable Promotions**,
you must first enable the `enable_member_promotion_management` application setting.

Example of queueing a single user:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

Example of queueing multiple users:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "user_id=1,2&access_level=30" \
     --url "https://gitlab.example.com/api/v4/projects/:id/members"
```

```json
{
  "queued_users": {
    "username_1": "Request queued for administrator approval.",
    "username_2": "Request queued for administrator approval."
  },
  "status": "success"
}
```

## Edit a member of a project

Updates a member of a project.

```plaintext
PUT /projects/:id/members/:user_id
```

| Attribute        | Type              | Required | Description |
| ---------------- | ----------------- | -------- | ----------- |
| `id`             | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `user_id`        | integer           | yes      | The user ID of the member. |
| `access_level`   | integer           | yes       | A valid [access level](../user/permissions.md#default-roles) Possible values: `0` (No access), `5` (Minimal access), `10` (Guest), `15` (Planner), `20` (Reporter), `30` (Developer), `40` (Maintainer), or `50` (Owner). Default: `30`. |
| `expires_at`     | string            | no       | A date string in the format `YEAR-MONTH-DAY`. |
| `member_role_id` | integer           | no       | Ultimate only. The ID of a custom member role. If no value is specified, removes all roles. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id?access_level=40"
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

{{< alert type="note" >}}

If [administrator approval for role promotions](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) is turned on, membership requests that promote existing users into a billable role require administrator approval.

{{< /alert >}}

To enable **Manage non-billable promotions**,
you must first enable the `enable_member_promotion_management` application setting.

Example response:

```json
{
  "message":{
    "username_1":"Request queued for administrator approval."
  }
}
```

## Remove a member from a project

Removes a user from a project where the user has been explicitly assigned a role.

The user needs to be a group member to qualify for removal.
For example, if the user was added directly to a project in the group but not this
group explicitly, you cannot use this endpoint to remove them. For more information, see
[Remove a billable member from a group](group_members.md#remove-a-billable-member-from-a-group).

```plaintext
DELETE /projects/:id/members/:user_id
```

| Attribute            | Type              | Required | Description |
|----------------------|-------------------|----------|-------------|
| `id`                 | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `user_id`            | integer           | yes      | The user ID of the member. |
| `skip_subresources`  | boolean           | false    | Whether the deletion of direct memberships of the removed member in subgroups and projects should be skipped. Default is `false`. |
| `unassign_issuables` | boolean           | false    | Whether the removed member should be unassigned from any issues or merge requests inside a given project. Default is `false`. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/members/:user_id"
```
