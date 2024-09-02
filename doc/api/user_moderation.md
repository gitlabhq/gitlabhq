---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# User moderation API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

You can [activate, ban, and block users](../administration/moderate_users.md) by using the REST API.

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
