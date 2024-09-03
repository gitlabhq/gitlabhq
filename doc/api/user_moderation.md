---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# User moderation API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

You can [approve, activate, ban, and block users](../administration/moderate_users.md) by using the REST API.

## Approve a user

Approves the specified user.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:id/approve
```

Parameters:

| Attribute  | Type    | Required | Description          |
|------------|---------|----------|----------------------|
| `id`       | integer | yes      | ID of specified user |

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

## Reject a user

Reject the specified user that is
[pending approval](../administration/moderate_users.md#users-pending-approval).

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:id/reject
```

Parameters:

- `id` (required) - ID of specified user

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

## Activate a user

Activate the specified user.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:id/activate
```

Parameters:

| Attribute  | Type    | Required | Description          |
|------------|---------|----------|----------------------|
| `id`       | integer | yes      | ID of specified user |

Returns:

- `201 OK` on success.
- `404 User Not Found` if the user cannot be found.
- `403 Forbidden` if the user cannot be activated because they are blocked by an administrator or by LDAP synchronization.

## Deactivate a user

Deactivate the specified user.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:id/deactivate
```

Parameters:

| Attribute  | Type    | Required | Description          |
|------------|---------|----------|----------------------|
| `id`       | integer | yes      | ID of specified user |

Returns:

- `201 OK` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` when trying to deactivate a user that is:
  - Blocked by administrator or by LDAP synchronization.
  - Not [dormant](../administration/moderate_users.md#automatically-deactivate-dormant-users).
  - Internal.

## Block a user

Block the specified user.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:id/block
```

Parameters:

| Attribute  | Type    | Required | Description          |
|------------|---------|----------|----------------------|
| `id`       | integer | yes      | ID of specified user |

Returns:

- `201 OK` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` when trying to block:
  - A user that is blocked through LDAP.
  - An internal user.

## Unblock a user

Unblock the specified user.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:id/unblock
```

Parameters:

| Attribute  | Type    | Required | Description          |
|------------|---------|----------|----------------------|
| `id`       | integer | yes      | ID of specified user |

Returns `201 OK` on success, `404 User Not Found` is user cannot be found or
`403 Forbidden` when trying to unblock a user blocked by LDAP synchronization.

## Ban a user

Ban the specified user.

Prerequisites:

- You must be an administrator.

```plaintext
POST /users/:id/ban
```

Parameters:

- `id` (required) - ID of specified user

Returns:

- `201 OK` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` when trying to ban a user that is not active.

## Unban a user

Unban the specified user. Available only for administrator.

```plaintext
POST /users/:id/unban
```

Parameters:

- `id` (required) - ID of specified user

Returns:

- `201 OK` on success.
- `404 User Not Found` if the user cannot be found.
- `403 Forbidden` when trying to unban a user that is not banned.

## Related topics

- [Review abuse reports](../administration/review_abuse_reports.md)
- [Review spam logs](../administration/review_spam_logs.md)
