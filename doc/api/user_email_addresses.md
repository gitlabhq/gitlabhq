---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User email addresses API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use this API to interact with email addresses for user accounts. For more information, see [User account](../user/profile/_index.md).

## List all email addresses

Lists all email addresses for your user account.

Prerequisites:

- You must be authenticated.

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

## List all email addresses for a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Lists all email addresses for a given user account.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
GET /users/:id/emails
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of user account |

## Get details on an email address

Gets details on a given email address for your user account.

```plaintext
GET /user/emails/:email_id
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|:-----------|:--------|:---------|:------------|
| `email_id` | integer | yes      | ID of email address |

Example response:

```json
{
  "id": 1,
  "email": "email@example.com",
  "confirmed_at" : "2021-03-26T19:07:56.248Z"
}
```

## Add an email address

Adds an email address for your user account.

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
**Offering:** GitLab Self-Managed, GitLab Dedicated

Adds an email address for a given user account.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/emails
```

Supported attributes:

| Attribute           | Type    | Required | Description |
|:--------------------|:--------|:---------|:------------|
| `id`                | string  | yes      | ID of user account|
| `email`             | string  | yes      | Email address |
| `skip_confirmation` | boolean | no       | Skip confirmation and assume email is verified. Possible values: `true`, `false`. Default value: `false`. |

## Delete an email address

Deletes an email address for your user account. You cannot delete a primary email address.

Any future emails sent to the deleted email address are sent to the primary email address instead.

Prerequisites:

- You must be authenticated.

```plaintext
DELETE /user/emails/:email_id
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|:-----------|:--------|:---------|:------------|
| `email_id` | integer | yes      | ID of email address |

Returns:

- `204 No Content` if the operation was successful.
- `404` if the resource was not found.

## Delete an email address for a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Deletes an email address for a given user account. You cannot delete a primary email address.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
DELETE /users/:id/emails/:email_id
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|:-----------|:--------|:---------|:------------|
| `id`       | integer | yes      | ID of user account |
| `email_id` | integer | yes      | ID of email address |
