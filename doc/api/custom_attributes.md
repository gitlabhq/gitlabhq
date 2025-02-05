---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom Attributes API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Every API call to custom attributes must be authenticated as administrator.

Custom attributes are currently available on users, groups, and projects,
which is referred to as "resource" in this documentation.

## List custom attributes

Get all custom attributes on a resource.

```plaintext
GET /users/:id/custom_attributes
GET /groups/:id/custom_attributes
GET /projects/:id/custom_attributes
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a resource |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/42/custom_attributes"
```

Example response:

```json
[
   {
      "key": "location",
      "value": "Antarctica"
   },
   {
      "key": "role",
      "value": "Developer"
   }
]
```

## Single custom attribute

Get a single custom attribute on a resource.

```plaintext
GET /users/:id/custom_attributes/:key
GET /groups/:id/custom_attributes/:key
GET /projects/:id/custom_attributes/:key
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a resource |
| `key` | string | yes | The key of the custom attribute |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```

Example response:

```json
{
   "key": "location",
   "value": "Antarctica"
}
```

## Set custom attribute

Set a custom attribute on a resource. The attribute is updated if it already exists,
or newly created otherwise.

```plaintext
PUT /users/:id/custom_attributes/:key
PUT /groups/:id/custom_attributes/:key
PUT /projects/:id/custom_attributes/:key
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a resource |
| `key` | string | yes | The key of the custom attribute |
| `value` | string | yes | The value of the custom attribute |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "value=Greenland" "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```

Example response:

```json
{
   "key": "location",
   "value": "Greenland"
}
```

## Delete custom attribute

Delete a custom attribute on a resource.

```plaintext
DELETE /users/:id/custom_attributes/:key
DELETE /groups/:id/custom_attributes/:key
DELETE /projects/:id/custom_attributes/:key
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a resource |
| `key` | string | yes | The key of the custom attribute |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```
