---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API to register and unregister mobile devices for push notifications.
title: Mobile push subscriptions API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248023) in GitLab 19.3 [with a flag](../administration/feature_flags/_index.md) named `mobile_push_registration_api`. Disabled by default.

{{< /history >}}

Register mobile devices to receive push notifications for the authenticated
user's [to-do items](todos.md). Every push notification corresponds to a
to-do item.

## Register a device

Registers a device token for the authenticated user. This endpoint is an
idempotent upsert: registering an existing token again refreshes its
attributes and `last_seen_at` timestamp, so clients re-register on every
application start. Attributes omitted from the request keep their stored
values when the token is already registered. Registering a token that
belongs to another user reassigns it to the authenticated user.

Each user can register up to 20 devices. Subscriptions not seen for 90 days
are removed automatically.

```plaintext
POST /user/push_subscriptions
```

Supported attributes:

| Attribute          | Type   | Required | Description |
|--------------------|--------|----------|-------------|
| `device_token`     | string | Yes      | The hexadecimal APNs device token. |
| `platform`         | string | No       | The device platform. Only `ios` is supported. New registrations default to `ios`. |
| `apns_environment` | string | No       | The APNs environment the token was issued for: `production` or `sandbox`. Default: `production`. |
| `bundle_id`        | string | No       | The application bundle identifier. |
| `device_name`      | string | No       | A human-readable device name. |
| `app_version`      | string | No       | The installed application version. |
| `locale`           | string | No       | The device locale. |
| `payload_mode`     | string | No       | `full` sends notification content in the push payload. `id_only` sends only record identifiers, for content-free payloads. New registrations default to `full`. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "device_token=abcdef0123456789abcdef0123456789" \
  --data "apns_environment=sandbox" \
  --url "https://gitlab.example.com/api/v4/user/push_subscriptions"
```

If successful, returns [`201`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute    | Type    | Description |
|--------------|---------|-------------|
| `id`         | integer | The ID of the subscription. |
| `created_at` | string  | The date and time the subscription was created, in ISO 8601 format. |

Example response:

```json
{
  "id": 1,
  "created_at": "2026-07-30T18:15:31.189Z"
}
```

## Unregister a device

Deletes the authenticated user's subscription for a device token, for
example on sign-out. The token is passed in the request body rather than
the URL so it does not appear in access logs. Returns `204 No Content` on
success and `404 Not Found` when no matching subscription exists.

```plaintext
DELETE /user/push_subscriptions
```

Supported attributes:

| Attribute      | Type   | Required | Description |
|----------------|--------|----------|-------------|
| `device_token` | string | Yes      | The hexadecimal APNs device token. |

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "device_token=abcdef0123456789abcdef0123456789" \
  --url "https://gitlab.example.com/api/v4/user/push_subscriptions"
```
