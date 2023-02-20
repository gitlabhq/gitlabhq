---
type: reference, howto
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
# SCIM API **(PREMIUM SAAS)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98354) in GitLab 15.5.

GitLab provides an SCIM API that both implements [the RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644)
and provides the `/Users` endpoint. The base URL is `/api/scim/v2/groups/:group_path/Users/`.

To use this API, [Group SSO](../user/group/saml_sso/index.md) must be enabled for the group.
This API is only in use where [SCIM for Group SSO](../user/group/saml_sso/scim_setup.md) is enabled. It's a prerequisite to the creation of SCIM identities.

Not to be confused with the [internal group SCIM API](../development/internal_api/index.md#group-scim-api).

## Get SCIM identities for a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) in GitLab 15.5.

```plaintext
GET /groups/:id/scim/identities
```

Supported attributes:

| Attribute         | Type    | Required | Description           |
|:------------------|:--------|:---------|:----------------------|
| `id`              | integer | Yes      | Return SCIM identities for the given group ID. |

If successful, returns [`200`](rest/index.md#status-codes) and the following
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
        "extern_uid": "4",
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

## Update `extern_uid` field for a SCIM identity

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) in GitLab 15.5.

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
| `uid`     | string | yes      | External UID of the user. |

Example request:

```shell
curl --location --request PATCH "https://gitlab.example.com/api/v4/groups/33/scim/sydney_jones" \
--header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
--form "extern_uid=sydney_jones_new"
```
