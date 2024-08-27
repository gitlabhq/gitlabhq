---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# SAML API

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) in GitLab 15.5.

API for accessing SAML features.

## GitLab.com endpoints

### Get SAML identities for a group

```plaintext
GET /groups/:id/saml/identities
```

Fetch SAML identities for a group.

Supported attributes:

| Attribute         | Type    | Required | Description           |
|:------------------|:--------|:---------|:----------------------|
| `id`              | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |

If successful, returns [`200`](rest/index.md#status-codes) and the following
response attributes:

| Attribute    | Type   | Description               |
| ------------ | ------ | ------------------------- |
| `extern_uid` | string | External UID for the user |
| `user_id`    | string | ID for the user           |

Example request:

```shell
curl --location --request GET "https://gitlab.com/api/v4/groups/33/saml/identities" --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>"
```

Example response:

```json
[
    {
        "extern_uid": "yrnZW46BrtBFqM7xDzE7dddd",
        "user_id": 48
    }
]
```

### Get a single SAML identity

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591) in GitLab 16.1.

```plaintext
GET /groups/:id/saml/:uid
```

Supported attributes:

| Attribute | Type           | Required | Description               |
| --------- | -------------- | -------- | ------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `uid`     | string         | yes      | External UID of the user. |

Example request:

```shell
curl --location --request GET "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd" --header "PRIVATE-TOKEN: <PRIVATE TOKEN>"
```

Example response:

```json
{
    "extern_uid": "yrnZW46BrtBFqM7xDzE7dddd",
    "user_id": 48
}
```

### Update `extern_uid` field for a SAML identity

Update `extern_uid` field for a SAML identity:

| SAML IdP attribute | GitLab field |
| ------------------ | ------------ |
| `id/externalId`    | `extern_uid` |

```plaintext
PATCH /groups/:id/saml/:uid
```

Supported attributes:

| Attribute | Type   | Required | Description               |
| --------- | ------ | -------- | ------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `uid`     | string | yes      | External UID of the user. |

Example request:

```shell
curl --location --request PATCH "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd" \
--header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
--form "extern_uid=be20d8dcc028677c931e04f387"
```

### Delete a single SAML identity

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423592) in GitLab 16.5.

```plaintext
DELETE /groups/:id/saml/:uid
```

Supported attributes:

| Attribute | Type    | Required | Description               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | integer | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding). |
| `uid`     | string  | yes      | External UID of the user. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.com/api/v4/groups/33/saml/be20d8dcc028677c931e04f387"

```

Example response:

```json
{
    "message" : "204 No Content"
}
```

## Self-managed GitLab endpoints

### Get a single SAML identity

Use the Users API to [get a single SAML identity](../api/users.md#for-administrators).

### Update `extern_uid` field for a SAML identity

Use the Users API to [update the `extern_uid` field of a user](../api/users.md#user-modification).

### Delete a single SAML identity

Use the Users API to [delete a single identity of a user](../api/users.md#delete-authentication-identity-from-user).
