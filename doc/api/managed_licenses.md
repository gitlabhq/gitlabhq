---
stage: Growth
group: Activation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Managed Licenses API **(ULTIMATE)**

## List managed licenses

Get all managed licenses for a given project.

```plaintext
GET /projects/:id/managed_licenses
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/managed_licenses"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "MIT",
    "approval_status": "approved"
  },
  {
    "id": 3,
    "name": "ISC",
    "approval_status": "blacklisted"
  }
]
```

## Show an existing managed license

Shows an existing managed license.

```plaintext
GET /projects/:id/managed_licenses/:managed_license_id
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `managed_license_id`      | integer/string    | yes      | The ID or URL-encoded name of the license belonging to the project |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/managed_licenses/6"
```

Example response:

```json
{
  "id": 1,
  "name": "MIT",
  "approval_status": "blacklisted"
}
```

## Create a new managed license

Creates a new managed license for the given project with the given name and approval status.

```plaintext
POST /projects/:id/managed_licenses
```

| Attribute     | Type    | Required | Description                  |
| ------------- | ------- | -------- | ---------------------------- |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `name`        | string  | yes      | The name of the managed license        |
| `approval_status`       | string  | yes      | The approval status. "approved" or "blacklisted" |

```shell
curl --data "name=MIT&approval_status=blacklisted" --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/managed_licenses"
```

Example response:

```json
{
  "id": 1,
  "name": "MIT",
  "approval_status": "approved"
}
```

## Delete a managed license

Deletes a managed license with a given ID.

```plaintext
DELETE /projects/:id/managed_licenses/:managed_license_id
```

| Attribute | Type    | Required | Description           |
| --------- | ------- | -------- | --------------------- |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `managed_license_id`      | integer/string    | yes      | The ID or URL-encoded name of the license belonging to the project |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/managed_licenses/4"
```

When successful, it replies with an HTTP 204 response.

## Edit an existing managed license

Updates an existing managed license with a new approval status.

```plaintext
PATCH /projects/:id/managed_licenses/:managed_license_id
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`      | integer/string    | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `managed_license_id`      | integer/string    | yes      | The ID or URL-encoded name of the license belonging to the project |
| `approval_status`       | string  | yes      | The approval status. "approved" or "blacklisted" |

```shell
curl --request PATCH --data "approval_status=blacklisted" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/managed_licenses/6"
```

Example response:

```json
{
  "id": 1,
  "name": "MIT",
  "approval_status": "blacklisted"
}
```
