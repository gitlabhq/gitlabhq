---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User moderation API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Use this API to moderate user accounts. For more information, see [Moderate users](../administration/moderate_users.md).

## Approve access to a user

Approves access to a given user account that is pending approval.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/approve
```

Supported attributes:

| Attribute  | Type    | Required | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | yes      | ID of user account |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/42/approve"
```

Returns:

- `201 Created` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` if the user cannot be approved because they are blocked by an administrator or by LDAP synchronization.
- `409 Conflict` if the user has been deactivated.

Example Responses:

```json
{ "message": "Success" }
```

```json
{ "message": "404 User Not Found" }
```

```json
{ "message": "The user you are trying to approve is not pending approval" }
```

## Reject access to a user

Rejects access to a given user account that is pending approval.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/reject
```

Supported attributes:

| Attribute  | Type    | Required | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | yes      | ID of user account |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/42/reject"
```

Returns:

- `200 OK` on success.
- `403 Forbidden` if not authenticated as an administrator.
- `404 User Not Found` if user cannot be found.
- `409 Conflict` if user is not pending approval.

Example Responses:

```json
{ "message": "Success" }
```

```json
{ "message": "404 User Not Found" }
```

```json
{ "message": "User does not have a pending request" }
```

## Deactivate a user

Deactivates a given user account. For more information on banned users, see [Activate and deactivate users](../administration/moderate_users.md#deactivate-and-reactivate-users).

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/deactivate
```

Supported attributes:

| Attribute  | Type    | Required | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | yes      | ID of user account |

Returns:

- `201 OK` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` when trying to deactivate a user that is:
  - Blocked by administrator or by LDAP synchronization.
  - Not [dormant](../administration/moderate_users.md#automatically-deactivate-dormant-users).
  - Internal.

## Reactivate a user

Reactivates a given user account that was previously deactivated.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/activate
```

Supported attributes:

| Attribute  | Type    | Required | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | yes      | ID of user account |

Returns:

- `201 OK` on success.
- `404 User Not Found` if the user cannot be found.
- `403 Forbidden` if the user cannot be activated because they are blocked by an administrator or by LDAP synchronization.

## Block access to a user

Blocks a given user account. For more information on banned users, see [Block and unblock users](../administration/moderate_users.md#block-and-unblock-users).

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/block
```

Supported attributes:

| Attribute  | Type    | Required | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | yes      | ID of user account |

Returns:

- `201 OK` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` when trying to block:
  - A user that is blocked through LDAP.
  - An internal user.

## Unblock access to a user

Unblocks a given user account that was previously blocked.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/unblock
```

Supported attributes:

| Attribute  | Type    | Required | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | yes      | ID of user account |

Returns:

- `201 OK` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` when trying to unblock a user blocked by LDAP synchronization.

## Ban a user

Bans a given user account. For more information on banned users, see [Ban and unban users](../administration/moderate_users.md#ban-and-unban-users).

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/ban
```

Supported attributes:

| Attribute  | Type    | Required | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | yes      | ID of user account |

Returns:

- `201 OK` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` when trying to ban a user that is not active.

## Unban a user

Unbans a given user account that was previously banned.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /users/:id/unban
```

Supported attributes:

| Attribute  | Type    | Required | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | yes      | ID of user account |

Returns:

- `201 OK` on success.
- `404 User Not Found` if the user cannot be found.
- `403 Forbidden` when trying to unban a user that is not banned.

## Related topics

- [Review abuse reports](../administration/review_abuse_reports.md)
- [Review spam logs](../administration/review_spam_logs.md)
