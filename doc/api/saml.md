---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAML API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) in GitLab 15.5.

{{< /history >}}

Use this API to interact with SAML features.

## GitLab.com endpoints

### Get SAML identities for a group

```plaintext
GET /groups/:id/saml/identities
```

Fetch SAML identities for a group.

Supported attributes:

| Attribute         | Type    | Required | Description           |
|:------------------|:--------|:---------|:----------------------|
| `id`              | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
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

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591) in GitLab 16.1.

{{< /history >}}

```plaintext
GET /groups/:id/saml/:uid
```

Supported attributes:

| Attribute | Type           | Required | Description               |
| --------- | -------------- | -------- | ------------------------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
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
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `uid`     | string | yes      | External UID of the user. |

Example request:

```shell
curl --location --request PATCH "https://gitlab.com/api/v4/groups/33/saml/yrnZW46BrtBFqM7xDzE7dddd" \
--header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
--form "extern_uid=be20d8dcc028677c931e04f387"
```

### Delete a single SAML identity

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423592) in GitLab 16.5.

{{< /history >}}

```plaintext
DELETE /groups/:id/saml/:uid
```

Supported attributes:

| Attribute | Type    | Required | Description               |
| --------- | ------- | -------- | ------------------------- |
| `id`      | integer | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
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

## GitLab Self-Managed endpoints

### Get a single SAML identity

Use the Users API to [get a single SAML identity](users.md#as-an-administrator).

### Update `extern_uid` field for a SAML identity

Use the Users API to [update the `extern_uid` field of a user](users.md#modify-a-user).

### Delete a single SAML identity

Use the Users API to [delete a single identity of a user](users.md#delete-authentication-identity-from-a-user).

## SAML group links

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/290367) in GitLab 15.3.0.
- `access_level` type [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95607) from `string` to `integer` in GitLab 15.3.3.
- `member_role_id` type [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/417201) in GitLab 16.7 [with a flag](../administration/feature_flags/_index.md) named `custom_roles_for_saml_group_links`. Disabled by default.
- `member_role_id` type [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/417201) in GitLab 16.8. Feature flag `custom_roles_for_saml_group_links` removed.
- `provider` parameter [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/548725) in GitLab 18.2.

{{< /history >}}

List, get, add, and delete [SAML group links](../user/group/saml_sso/group_sync.md#configure-saml-group-links) by using
the REST API.

### List SAML group links

List SAML group links for a group.

```plaintext
GET /groups/:id/saml_group_links
```

Supported attributes:

| Attribute | Type           | Required | Description |
|:----------|:---------------|:---------|:------------|
| `id`      | integer or string | yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute           | Type    | Description |
|:--------------------|:--------|:------------|
| `[].name`           | string  | Name of the SAML group. |
| `[].access_level`   | integer | [Role (`access_level`)](members.md#roles) for members of the SAML group. The attribute had a string type from GitLab 15.3.0 to GitLab 15.3.3. |
| `[].member_role_id` | integer | [Member Role ID (`member_role_id`)](member_roles.md) for members of the SAML group. |
| `[].provider`       | string  | Unique [provider name](../integration/saml.md#configure-saml-support-in-gitlab) that must match for this group link to be applied. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/saml_group_links"
```

Example response:

```json
[
  {
    "name": "saml-group-1",
    "access_level": 10,
    "member_role_id": 12,
    "provider": null
  },
  {
    "name": "saml-group-2",
    "access_level": 40,
    "member_role_id": 99,
    "provider": "saml_provider_1"
  }
]
```

### Get a SAML group link

Get a SAML group link for a group.

```plaintext
GET /groups/:id/saml_group_links/:saml_group_name
```

Supported attributes:

| Attribute         | Type           | Required | Description |
|:------------------|:---------------|:---------|:------------|
| `id`              | integer or string | yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `saml_group_name` | string         | yes      | Name of the SAML group. |
| `provider`        | string         | no       | Unique [provider name](../integration/saml.md#configure-saml-support-in-gitlab) to disambiguate when multiple links exist with the same name. Required when multiple links exist with the same `saml_group_name`. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute        | Type    | Description |
|:-----------------|:--------|:------------|
| `name`           | string  | Name of the SAML group. |
| `access_level`   | integer | [Role (`access_level`)](members.md#roles) for members of the SAML group. The attribute had a string type from GitLab 15.3.0 to GitLab 15.3.3. |
| `member_role_id` | integer | [Member Role ID (`member_role_id`)](member_roles.md) for members of the SAML group. |
| `provider`       | string  | Unique [provider name](../integration/saml.md#configure-saml-support-in-gitlab) that must match for this group link to be applied. |

If multiple SAML group links exist with the same name but different providers, and no `provider` parameter is specified, returns [`422`](rest/troubleshooting.md#status-codes) with an error message indicating that the `provider` parameter is required to disambiguate.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

Example request with provider parameter:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1?provider=saml_provider_1"
```

Example response:

```json
{
"name": "saml-group-1",
"access_level": 10,
"member_role_id": 12,
"provider": "saml_provider_1"
}
```

### Add a SAML group link

Add a SAML group link for a group.

```plaintext
POST /groups/:id/saml_group_links
```

Supported attributes:

| Attribute         | Type              | Required | Description |
|:------------------|:------------------|:---------|:------------|
| `id`              | integer or string | yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `saml_group_name` | string            | yes      | Name of the SAML group. |
| `access_level`    | integer           | yes      | [Role (`access_level`)](members.md#roles) for members of the SAML group. |
| `member_role_id`  | integer           | no       | [Member Role ID (`member_role_id`)](member_roles.md) for members of the SAML group. |
| `provider`        | string            | no       | Unique [provider name](../integration/saml.md#configure-saml-support-in-gitlab) that must match for this group link to be applied. |

If successful, returns [`201`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute        | Type    | Description |
|:-----------------|:--------|:------------|
| `name`           | string  | Name of the SAML group. |
| `access_level`   | integer | [Role (`access_level`)](members.md#roles) for members of the for members of the SAML group. The attribute had a string type from GitLab 15.3.0 to GitLab 15.3.3. |
| `member_role_id` | integer | [Member Role ID (`member_role_id`)](member_roles.md) for members of the SAML group. |
| `provider`       | string  | Unique [provider name](../integration/saml.md#configure-saml-support-in-gitlab) that must match for this group link to be applied. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" --data '{ "saml_group_name": "<your_saml_group_name`>", "access_level": <chosen_access_level>, "member_role_id": <chosen_member_role_id>, "provider": "<your_provider>" }' --url  "https://gitlab.example.com/api/v4/groups/1/saml_group_links"
```

Example response:

```json
{
"name": "saml-group-1",
"access_level": 10,
"member_role_id": 12,
"provider": "saml_provider_1"
}
```

### Delete a SAML group link

Delete a SAML group link for a group.

```plaintext
DELETE /groups/:id/saml_group_links/:saml_group_name
```

Supported attributes:

| Attribute         | Type           | Required | Description |
|:------------------|:---------------|:---------|:------------|
| `id`              | integer or string | yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `saml_group_name` | string         | yes      | Name of the SAML group. |
| `provider`        | string         | no       | Unique [provider name](../integration/saml.md#configure-saml-support-in-gitlab) to disambiguate when multiple links exist with the same name. Required when multiple links exist with the same `saml_group_name`. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1"
```

Example request with provider parameter:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1/saml_group_links/saml-group-1?provider=saml_provider_1"
```

If successful, returns [`204`](rest/troubleshooting.md#status-codes) status code without any response body.

If multiple SAML group links exist with the same name but different providers, and no `provider` parameter is specified, returns [`422`](rest/troubleshooting.md#status-codes) with an error message indicating that the `provider` parameter is required to disambiguate.
