---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: License
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

To interact with license endpoints, you need to authenticate yourself as an
administrator.

## Retrieve information about the current license

```plaintext
GET /license
```

```json
{
  "id": 2,
  "plan": "ultimate",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 300,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

## Retrieve information about all licenses

```plaintext
GET /licenses
```

```json
[
  {
    "id": 1,
    "plan": "premium",
    "created_at": "2018-02-27T23:21:58.674Z",
    "starts_at": "2018-01-27",
    "expires_at": "2022-01-27",
    "historical_max": 300,
    "maximum_user_count": 300,
    "expired": false,
    "overage": 200,
    "user_limit": 100,
    "licensee": {
      "Name": "John Doe1",
      "Email": "johndoe1@gitlab.com",
      "Company": "GitLab"
    },
    "add_ons": {
      "GitLab_FileLocks": 1,
      "GitLab_Auditor_User": 1
    }
  },
  {
    "id": 2,
    "plan": "ultimate",
    "created_at": "2018-02-27T23:21:58.674Z",
    "starts_at": "2018-01-27",
    "expires_at": "2022-01-27",
    "historical_max": 300,
    "maximum_user_count": 300,
    "expired": false,
    "overage": 200,
    "user_limit": 100,
    "licensee": {
      "Name": "Doe John",
      "Email": "doejohn@gitlab.com",
      "Company": "GitLab"
    },
    "add_ons": {
      "GitLab_FileLocks": 1
    }
  }
]
```

Overage is the difference between the number of billable users and the licensed number of users.
This is calculated differently depending on whether the license has expired or not.

- If the license has expired, it uses the historical maximum billable user count (`historical_max`).
- If the license has not expired, it uses the current billable users count.

Returns:

- `200 OK` with response containing the licenses in JSON format. This is an empty JSON array if there are no licenses.
- `403 Forbidden` if the current user in not permitted to read the licenses.

## Retrieve information about a single license

```plaintext
GET /license/:id
```

Supported attributes:

| Attribute | Type    | Required | Description               |
|-----------|---------|----------|---------------------------|
| `id`      | integer | yes      | ID of the GitLab license. |

Returns the following status codes:

- `200 OK`: Response contains the licenses in JSON format.
- `404 Not Found`: The requested license doesn't exist.
- `403 Forbidden`: The current user is not permitted to read the licenses.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/license/:id"
```

Example response:

```json
{
  "id": 1,
  "plan": "premium",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 50,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

## Add a new license

```plaintext
POST /license
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `license` | string | yes | The license string |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/license?license=eyJkYXRhIjoiMHM5Q...S01Udz09XG4ifQ=="
```

Example response:

```json
{
  "id": 1,
  "plan": "ultimate",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 300,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

Returns:

- `201 Created` if the license is successfully added.
- `400 Bad Request` if the license couldn't be added, with an error message explaining the reason.

## Delete a license

```plaintext
DELETE /license/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | ID of the GitLab license. |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/license/:id"
```

Returns:

- `204 No Content` if the license is successfully deleted.
- `403 Forbidden` if the current user in not permitted to delete the license.
- `404 Not Found` if the license to delete could not be found.

## Trigger recalculation of billable users

```plaintext
PUT /license/:id/refresh_billable_users
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | ID of the GitLab license. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/license/:id/refresh_billable_users"
```

Example response:

```json
{
  "success": true
}
```

Returns:

- `202 Accepted` if the request to refresh billable users is successfully initiated.
- `403 Forbidden` if the current user in not permitted to refresh billable users for the license.
- `404 Not Found` if the license could not be found.

| Attribute                    | Type          | Description                               |
|:-----------------------------|:--------------|:------------------------------------------|
| `success`                    | boolean       | Whether the request succeeded or not.     |

## Retrieve usage information about the current license

Gets usage information about the current license and exports it in CSV format.

```plaintext
GET /license/usage_export.csv
```

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/license/usage_export.csv"
```

Example response:

```csv
License Key,"eyJkYXRhIjoib1EwRWZXU3RobDY2Yl=
"
Email,user@example.com
License Start Date,2023-02-22
License End Date,2024-02-22
Company,Example Corp.
Generated At,2023-09-05 06:56:23
"",""
Date,Billable User Count
2023-07-11 12:00:05,21
2023-07-13 12:00:06,21
2023-08-16 12:00:02,21
2023-09-04 12:00:12,21
```

Returns:

- `200 OK`: Response contains the license usage in CSV format.
- `403 Forbidden` if the current user in not permitted to view license usage.
