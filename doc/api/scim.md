---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SCIM API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98354) in GitLab 15.5.

Use this API to manage SCIM identities in groups.

Prerequisites:

- You must enable [Group SSO](../user/group/saml_sso/_index.md).
- You must enable [SCIM for Group SSO](../user/group/saml_sso/scim_setup.md).

This API differs from the [internal group SCIM API](../development/internal_api/_index.md#group-scim-api) and the [instance SCIM API](../development/internal_api/_index.md#instance-scim-api):

- This API:
  - Does not implement the [RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644).
  - Gets, checks, updates, and deletes SCIM identities within groups.

- The internal group and instance SCIM APIs:
  - Are for system use for SCIM provider integration.
  - Implement the [RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644).
  - Get a list of SCIM provisioned users for the group or instance.
  - Create, delete and update SCIM provisioned users for the group or instance.

## Get SCIM identities for a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) in GitLab 15.5.

```plaintext
GET /groups/:id/scim/identities
```

Supported attributes:

| Attribute         | Type    | Required | Description           |
|:------------------|:--------|:---------|:----------------------|
| `id`      | integer/string | Yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute    | Type    | Description               |
| ------------ | ------- | ------------------------- |
| `extern_uid` | string  | External UID for the user |
| `user_id`    | integer | ID for the user           |
| `active`     | boolean | Status of the identity    |

Example response:

```json
[
    {
        "extern_uid": "be20d8dcc028677c931e04f387",
        "user_id": 48,
        "active": true
    }
]
```

Example request:

```shell
curl --location --request GET "https://gitlab.example.com/api/v4/groups/33/scim/identities" \
--header "PRIVATE-TOKEN: <PRIVATE-TOKEN>"
```

## Get a single SCIM identity

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591) in GitLab 16.1.

```plaintext
GET /groups/:id/scim/:uid
```

Supported attributes:

| Attribute | Type    | Required | Description               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | integer | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `uid`     | string  | yes      | External UID of the user. |

Example request:

```shell
curl --location --request GET "https://gitlab.example.com/api/v4/groups/33/scim/be20d8dcc028677c931e04f387" --header "PRIVATE-TOKEN: <PRIVATE TOKEN>"
```

Example response:

```json
{
    "extern_uid": "be20d8dcc028677c931e04f387",
    "user_id": 48,
    "active": true
}
```

## Update `extern_uid` field for a SCIM identity

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) in GitLab 15.5.

Fields that can be updated are:

| SCIM/IdP field  | GitLab field |
| --------------- | ------------ |
| `id/externalId` | `extern_uid` |

```plaintext
PATCH /groups/:groups_id/scim/:uid
```

Parameters:

| Attribute | Type   | Required | Description               |
| --------- | ------ | -------- | ------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths) |
| `uid`     | string | yes      | External UID of the user. |

Example request:

```shell
curl --location --request PATCH "https://gitlab.example.com/api/v4/groups/33/scim/be20d8dcc028677c931e04f387" \
--header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
--form "extern_uid=yrnZW46BrtBFqM7xDzE7dddd"
```

## Delete a single SCIM identity

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423592) in GitLab 16.5.

```plaintext
DELETE /groups/:id/scim/:uid
```

Supported attributes:

| Attribute | Type    | Required | Description               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | integer | yes      | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `uid`     | string  | yes      | External UID of the user. |

Example request:

```shell
curl --location --request DELETE "https://gitlab.example.com/api/v4/groups/33/scim/yrnZW46BrtBFqM7xDzE7dddd" --header "PRIVATE-TOKEN: <your_access_token>"
```

Example response:

```json
{
    "message" : "204 No Content"
}
```
