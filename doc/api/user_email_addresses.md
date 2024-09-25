---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# User email addresses API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can manage [user email addresses](../user/profile/index.md) by using the REST API.

## List your email addresses

Get a list of your email addresses.

Prerequisites:

- You must be authenticated.

This endpoint does not return the primary email address, but [issue 25077](https://gitlab.com/gitlab-org/gitlab/-/issues/25077)
proposes to change this behavior.

```plaintext
GET /user/emails
```

Example response:

```json
[
  {
    "id": 1,
    "email": "email@example.com",
    "confirmed_at" : "2021-03-26T19:07:56.248Z"
  },
  {
    "id": 3,
    "email": "email2@example.com",
    "confirmed_at" : null
  }
]
```

## List email addresses for a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

Get a list of a specified user's emails.

Prerequisites:

- You must be an administrator.

This endpoint does not return the primary email address, but [issue 25077](https://gitlab.com/gitlab-org/gitlab/-/issues/25077)
proposes to change this behavior.

```plaintext
GET /users/:id/emails
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of specified user |

## Get a single email address

Get a single email address.

```plaintext
GET /user/emails/:email_id
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|:-----------|:--------|:---------|:------------|
| `email_id` | integer | yes      | Email ID    |

Example response:

```json
{
  "id": 1,
  "email": "email@example.com",
  "confirmed_at" : "2021-03-26T19:07:56.248Z"
}
```

## Add an email address

Creates a new email owned by the authenticated user.

```plaintext
POST /user/emails
```

Supported attributes:

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `email`   | string | yes      | Email address |

```json
{
  "id": 4,
  "email": "email@example.com",
  "confirmed_at" : "2021-03-26T19:07:56.248Z"
}
```

Returns a created email with status `201 Created` on success. If an
error occurs a `400 Bad Request` is returned with a message explaining the error:

```json
{
  "message": {
    "email": [
      "has already been taken"
    ]
  }
}
```

## Add an email address for a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

Create a new email address owned by the specified user.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:id/emails
```

Supported attributes:

| Attribute           | Type    | Required | Description |
|:--------------------|:--------|:---------|:------------|
| `id`                | string  | yes      | ID of specified user |
| `email`             | string  | yes      | Email address |
| `skip_confirmation` | boolean | no       | Skip confirmation and assume email is verified - true or false (default) |

## Delete one of your email addresses

Delete one of your email addresses, other than your primary email address.

Prerequisites:

- You must be authenticated.

If the deleted email address is used for any user emails, those user emails are sent to the primary email address instead.

Because of [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/438600), group notifications are still sent to
the deleted email address.

```plaintext
DELETE /user/emails/:email_id
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|:-----------|:--------|:---------|:------------|
| `email_id` | integer | yes      | Email ID    |

Returns:

- `204 No Content` if the operation was successful.
- `404` if the resource was not found.

## Delete an email address for a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

Delete an email address for a user.

Prerequisites:

- You must be an administrator.

Deletes an email address of a specified user. You cannot delete a primary email address.

```plaintext
DELETE /users/:id/emails/:email_id
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|:-----------|:--------|:---------|:------------|
| `id`       | integer | yes      | ID of specified user |
| `email_id` | integer | yes      | Email ID    |
