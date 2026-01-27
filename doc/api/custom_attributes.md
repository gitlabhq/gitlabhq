---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Custom Attributes API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage custom attributes for users, groups, and projects.

Prerequisites:

- You must be an administrator for the instance.

## List all custom attributes

Lists all custom attributes for a specified resource.

```plaintext
GET /users/:id/custom_attributes
GET /groups/:id/custom_attributes
GET /projects/:id/custom_attributes
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a resource |

```shell
curl --request GET \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes"
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

## Retrieve a custom attribute

Retrieves a specified custom attribute for a resource.

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
curl --request GET \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```

Example response:

```json
{
   "key": "location",
   "value": "Antarctica"
}
```

## Update a custom attribute

Updates or creates a custom attribute for a specified resource. The attribute is updated if it already exists, or newly created otherwise.

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
curl --request PUT \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --data "value=Greenland" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```

Example response:

```json
{
   "key": "location",
   "value": "Greenland"
}
```

## Delete custom attribute

Deletes a specified custom attribute for a resource.

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
curl --request DELETE \
   --header "PRIVATE-TOKEN: <your_access_token>" \
   --url "https://gitlab.example.com/api/v4/users/42/custom_attributes/location"
```
