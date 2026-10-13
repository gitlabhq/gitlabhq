---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Instance SSH certificates API
description: REST API to list, add, and delete instance SSH certificate authority public keys.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/611314) in GitLab 19.5 [with a feature flag](../administration/feature_flags/_index.md) named `instance_ssh_certificates`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

Use this API to manage the SSH certificate authority (CA) public keys that an instance trusts.
GitLab stores each CA public key in the database and trusts it instance-wide, so you rotate a CA
with an API call instead of a change to `sshd_config` or the `gitlab-sshd` configuration file. For
the file-based alternatives, see
[instance-level SSH certificates with `gitlab-sshd`](../administration/operations/gitlab_sshd_ssh_certificates.md).

The `key` attribute contains a CA public key, not a private key or a signed user certificate.

## Authentication and availability

All endpoints require an administrator authenticated with the
[REST API](rest/authentication.md).
If Admin Mode is enabled for the instance, the existing
[Admin Mode requirements](../administration/settings/sign_in_restrictions.md#admin-mode)
apply, including the `admin_mode` scope for personal access tokens or OAuth tokens.

GitLab checks authentication and administrator access before feature availability.
The following errors apply to all endpoints, even when the feature flag is disabled:

| Status | Description |
|--------|-------------|
| `401 Unauthorized` | The request is unauthenticated. |
| `403 Forbidden` | The authenticated user does not have administrator access. |
| `404 Not Found` | The user has administrator access, but the feature is unavailable. |

## List all instance SSH certificates

Lists all instance SSH CA public key records in descending ID order.

```plaintext
GET /admin/ssh_certificates
```

This endpoint supports standard [pagination](rest/_index.md#offset-based-pagination).

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `page` | integer | No | Page to retrieve. Default: `1`. |
| `per_page` | integer | No | Number of records per page. Default: `20`. Maximum: `100`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and an array of
objects with the following response attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `created_at` | string | Date and time the record was created, in ISO 8601 format. |
| `fingerprint` | string | SHA256 fingerprint of the SSH CA public key. |
| `id` | integer | ID of the instance SSH certificate record. |
| `key` | string | SSH CA public key. |
| `title` | string | Title of the record. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ssh_certificates?page=1&per_page=20"
```

Example response (`<ca_public_key>` represents the full SSH CA public key):

```json
[
  {
    "id": 2,
    "title": "Engineering CA",
    "key": "<ca_public_key>",
    "fingerprint": "<ca_public_key_fingerprint>",
    "created_at": "2026-09-08T12:39:00.172Z"
  },
  {
    "id": 1,
    "title": "Operations CA",
    "key": "<ca_public_key>",
    "fingerprint": "<ca_public_key_fingerprint>",
    "created_at": "2026-09-08T11:30:00.000Z"
  }
]
```

An empty result returns `[]`.

## Add an instance SSH certificate

Adds an instance SSH CA public key record.

```plaintext
POST /admin/ssh_certificates
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `key` | string | Yes | SSH CA public key. Must not be blank. Maximum: 5,000 characters. |
| `title` | string | Yes | Title of the record. Must not be blank. Maximum: 255 characters. |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type | Description |
|-----------|------|-------------|
| `created_at` | string | Date and time the record was created, in ISO 8601 format. |
| `fingerprint` | string | SHA256 fingerprint of the SSH CA public key. |
| `id` | integer | ID of the instance SSH certificate record. |
| `key` | string | SSH CA public key. |
| `title` | string | Title of the record. |

Example request, with the CA public key in `/path/to/ca_key.pub`:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data-urlencode "title=Engineering CA" \
  --data-urlencode "key@/path/to/ca_key.pub" \
  --url "https://gitlab.example.com/api/v4/admin/ssh_certificates"
```

Example response:

```json
{
  "id": 2,
  "title": "Engineering CA",
  "key": "<ca_public_key>",
  "fingerprint": "<ca_public_key_fingerprint>",
  "created_at": "2026-09-08T12:39:00.172Z"
}
```

In addition to the shared authentication and availability errors, this endpoint can return:

| Status | Description |
|--------|-------------|
| `400 Bad Request` | A required parameter is missing, or `title` or `key` exceeds its maximum length. |
| `422 Unprocessable Entity` | A value is blank or invalid. Also returned for a duplicate key fingerprint, or for a key rejected by [SSH key restrictions](../security/ssh_keys_restrictions.md) or Federal Information Processing Standards (FIPS) restrictions. |

## Delete an instance SSH certificate

Deletes a specified instance SSH CA public key record.

```plaintext
DELETE /admin/ssh_certificates/:id
```

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | ID of the instance SSH certificate record. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes) with an empty response body and no response attributes.

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ssh_certificates/2"
```

In addition to the shared authentication and availability errors, this endpoint can return:

| Status | Description |
|--------|-------------|
| `404 Not Found` | No instance SSH certificate record has the specified ID. |
| `422 Unprocessable Entity` | GitLab could not delete the record. |
