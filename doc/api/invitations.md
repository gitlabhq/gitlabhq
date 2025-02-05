---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Invitations API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use the Invitations API to invite or add users to a group or project, and to list pending
invitations.

## Valid access levels

To send an invitation, you must have access to the project or group you are sending email for. Valid access
levels are defined in the `Gitlab::Access` module. Currently, these levels are valid:

- No access (`0`)
- Minimal access (`5`)
- Guest (`10`)
- Planner (`15`)
- Reporter (`20`)
- Developer (`30`)
- Maintainer (`40`)
- Owner (`50`)

## Add a member to a group or project

Adds a new member. You can specify a user ID or invite a user by email.

```plaintext
POST /groups/:id/invitations
POST /projects/:id/invitations
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/_index.md#namespaced-paths) |
| `email` | string | yes (if `user_id` isn't provided) | The email of the new member or multiple emails separated by commas. |
| `user_id`   | integer/string | yes (if `email` isn't provided) | The ID of the new member or multiple IDs separated by commas. |
| `access_level` | integer | yes | A valid access level |
| `expires_at` | string | no | A date string in the format YEAR-MONTH-DAY |
| `invite_source` | string | no | The source of the invitation that starts the member creation process. See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/327120). |
| `member_role_id` | integer | no | Assigns the new member to the provided custom role. ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134100)) in GitLab 16.6. Ultimate only. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "email=test@example.com&user_id=1&access_level=30" "https://gitlab.example.com/api/v4/groups/:id/invitations"
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "email=test@example.com&user_id=1&access_level=30" "https://gitlab.example.com/api/v4/projects/:id/invitations"
```

Example responses:

When all emails were successfully sent:

```json
{  "status":  "success"  }
```

When there was any error sending the email:

```json
{
  "status": "error",
  "message": {
               "test@example.com": "Invite email has already been taken",
               "test2@example.com": "User already exists in source",
               "test_username": "Access level is not included in the list"
             }
}
```

NOTE:
If [administrator approval for role promotions](../administration/settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) is turned on, membership requests that promote existing users into a billable role require administrator approval.

To enable **Manage non-billable promotions**,
you must first enable the `enable_member_promotion_management` application setting.

Example response:

```json
{
  "queued_users": {
    "username_1": "Request queued for administrator approval."
  },
  "status": "success"
}
```

## List all invitations pending for a group or project

Gets a list of invited group or project members viewable by the authenticated user.
Returns invitations to direct members only, and not through inherited ancestors' groups.

This function takes pagination parameters `page` and `per_page` to restrict the list of members.

```plaintext
GET /groups/:id/invitations
GET /projects/:id/invitations
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/_index.md#namespaced-paths) |
| `page`    | integer | no   | Page to retrieve                      |
| `per_page`| integer | no   | Number of member invitations to return per page |
| `query`   | string  | no   | A query string to search for invited members by invite email. Query text must match email address exactly. When empty, returns all invitations. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/invitations?query=member@example.org"
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/invitations?query=member@example.org"
```

Example response:

```json
 [
   {
     "id": 1,
     "invite_email": "member@example.org",
     "created_at": "2020-10-22T14:13:35Z",
     "access_level": 30,
     "expires_at": "2020-11-22T14:13:35Z",
     "user_name": "Raymond Smith",
     "created_by_name": "Administrator"
   },
]
```

## Update an invitation to a group or project

Updates a pending invitation's access level or access expiry date.

```plaintext
PUT /groups/:id/invitations/:email
PUT /projects/:id/invitations/:email
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/_index.md#namespaced-paths). |
| `email`   | string | yes    | The email address the invitation was previously sent to. |
| `access_level` | integer | no | A valid access level (defaults: `30`, the Developer role). |
| `expires_at` | string | no | A date string in ISO 8601 format (`YYYY-MM-DDTHH:MM:SSZ`). |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/55/invitations/email@example.org?access_level=40"
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/55/invitations/email@example.org?access_level=40"
```

Example response:

```json
{
  "expires_at": "2012-10-22T14:13:35Z",
  "access_level": 40,
}
```

## Delete an invitation to a group or project

Deletes a pending invitation by email address.

```plaintext
DELETE /groups/:id/invitations/:email
DELETE /projects/:id/invitations/:email
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project or group](rest/_index.md#namespaced-paths) |
| `email`   | string | yes    | The email address to which the invitation was previously sent |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/55/invitations/email@example.org"
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/55/invitations/email@example.org"
```

- Returns `204` and no content on success.
- Returns `403` forbidden if unauthorized to delete the invitation.
- Returns `404` not found if authorized and no invitation is found for that email address.
- Returns `409` if the request was valid but the invitation could not be deleted.
