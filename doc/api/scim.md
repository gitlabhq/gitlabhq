---
type: reference, howto
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# SCIM API (SYSTEM ONLY) **(PREMIUM SAAS)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/9388) in GitLab Premium 11.10.

The SCIM API implements the [RFC7644 protocol](https://tools.ietf.org/html/rfc7644). As this API is for
**system** use for SCIM provider integration, it is subject to change without notice.

To use this API, [Group SSO](../user/group/saml_sso/index.md) must be enabled for the group.
This API is only in use where [SCIM for Group SSO](../user/group/saml_sso/scim_setup.md) is enabled. It's a prerequisite to the creation of SCIM identities.

## Get a list of SCIM provisioned users

This endpoint is used as part of the SCIM syncing mechanism. It only returns
a single user based on a unique ID which should match the `extern_uid` of the user.

```plaintext
GET /api/scim/v2/groups/:group_path/Users
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `filter`   | string  | no     | A [filter](#available-filters) expression. |
| `group_path` | string | yes    | Full path to the group. |
| `startIndex` | integer | no    | The 1-based index indicating where to start returning results from. A value of less than one will be interpreted as 1. |
| `count` | integer | no    | Desired maximum number of query results. |

NOTE:
Pagination follows the [SCIM spec](https://tools.ietf.org/html/rfc7644#section-3.4.2.4) rather than GitLab pagination as used elsewhere. If records change between requests it is possible for a page to either be missing records that have moved to a different page or repeat records from a previous request.

Example request:

```shell
curl "https://gitlab.example.com/api/scim/v2/groups/test_group/Users?filter=id%20eq%20%220b1d561c-21ff-4092-beab-8154b17f82f2%22" \
     --header "Authorization: Bearer <your_scim_token>" \
     --header "Content-Type: application/scim+json"
```

Example response:

```json
{
  "schemas": [
    "urn:ietf:params:scim:api:messages:2.0:ListResponse"
  ],
  "totalResults": 1,
  "itemsPerPage": 20,
  "startIndex": 1,
  "Resources": [
    {
      "schemas": [
        "urn:ietf:params:scim:schemas:core:2.0:User"
      ],
      "id": "0b1d561c-21ff-4092-beab-8154b17f82f2",
      "active": true,
      "name.formatted": "Test User",
      "userName": "username",
      "meta": { "resourceType":"User" },
      "emails": [
        {
          "type": "work",
          "value": "name@example.com",
          "primary": true
        }
      ]
    }
  ]
}
```

## Get a single SCIM provisioned user

```plaintext
GET /api/scim/v2/groups/:group_path/Users/:id
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `id`   | string  | yes     | External UID of the user. |
| `group_path` | string | yes    | Full path to the group. |

Example request:

```shell
curl "https://gitlab.example.com/api/scim/v2/groups/test_group/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Example response:

```json
{
  "schemas": [
    "urn:ietf:params:scim:schemas:core:2.0:User"
  ],
  "id": "0b1d561c-21ff-4092-beab-8154b17f82f2",
  "active": true,
  "name.formatted": "Test User",
  "userName": "username",
  "meta": { "resourceType":"User" },
  "emails": [
    {
      "type": "work",
      "value": "name@example.com",
      "primary": true
    }
  ]
}
```

## Create a SCIM provisioned user

```plaintext
POST /api/scim/v2/groups/:group_path/Users/
```

Parameters:

| Attribute      | Type    | Required | Description            |
|:---------------|:----------|:----|:--------------------------|
| `externalId` | string      | yes | External UID of the user. |
| `userName`   | string      | yes | Username of the user. |
| `emails`     | JSON string | yes | Work email. |
| `name`       | JSON string | yes | Name of the user. |
| `meta`       | string      | no  | Resource type (`User`). |

Example request:

```shell
curl --verbose --request POST "https://gitlab.example.com/api/scim/v2/groups/test_group/Users" \
     --data '{"externalId":"test_uid","active":null,"userName":"username","emails":[{"primary":true,"type":"work","value":"name@example.com"}],"name":{"formatted":"Test User","familyName":"User","givenName":"Test"},"schemas":["urn:ietf:params:scim:schemas:core:2.0:User"],"meta":{"resourceType":"User"}}' \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Example response:

```json
{
  "schemas": [
    "urn:ietf:params:scim:schemas:core:2.0:User"
  ],
  "id": "0b1d561c-21ff-4092-beab-8154b17f82f2",
  "active": true,
  "name.formatted": "Test User",
  "userName": "username",
  "meta": { "resourceType":"User" },
  "emails": [
    {
      "type": "work",
      "value": "name@example.com",
      "primary": true
    }
  ]
}
```

Returns a `201` status code if successful.

## Update a single SCIM provisioned user

Fields that can be updated are:

| SCIM/IdP field                   | GitLab field                           |
|:---------------------------------|:---------------------------------------|
| `id/externalId`                  | `extern_uid`                           |
| `name.formatted`                 | `name`                                 |
| `emails\[type eq "work"\].value` | `email`                                |
| `active`                         | Identity removal if `active` = `false` |
| `userName`                       | `username`                             |

```plaintext
PATCH /api/scim/v2/groups/:group_path/Users/:id
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `id`   | string  | yes     | External UID of the user. |
| `group_path` | string | yes    | Full path to the group. |
| `Operations`   | JSON string  | yes     | An [operations](#available-operations) expression. |

Example request:

```shell
curl --verbose --request PATCH "https://gitlab.example.com/api/scim/v2/groups/test_group/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" \
     --data '{ "Operations": [{"op":"Add","path":"name.formatted","value":"New Name"}] }' \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Returns an empty response with a `204` status code if successful.

## Remove a single SCIM provisioned user

Removes the user's SSO identity and group membership.

```plaintext
DELETE /api/scim/v2/groups/:group_path/Users/:id
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `id`   | string  | yes     | External UID of the user. |
| `group_path` | string | yes    | Full path to the group. |

Example request:

```shell
curl --verbose --request DELETE "https://gitlab.example.com/api/scim/v2/groups/test_group/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Returns an empty response with a `204` status code if successful.

## Available filters

They match an expression as specified in [the RFC7644 filtering section](https://tools.ietf.org/html/rfc7644#section-3.4.2.2).

| Filter | Description |
| ----- | ----------- |
| `eq` | The attribute matches exactly the specified value. |

Example:

```plaintext
id eq a-b-c-d
```

## Available operations

They perform an operation as specified in [the RFC7644 update section](https://tools.ietf.org/html/rfc7644#section-3.5.2).

| Operator | Description |
| ----- | ----------- |
| `Replace` | The attribute's value is updated. |
| `Add` | The attribute has a new value. |

Example:

```json
{ "op": "Add", "path": "name.formatted", "value": "New Name" }
```
