# License **(CORE ONLY)**

In order to interact with license endpoints, you need to authenticate yourself
as an admin.

## Retrieve information about the current license

```
GET /license
```

```json
{
  "id": 2,
  "plan": "gold",
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
    "Name": "John Doe1"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

## Retrieve information about all licenses

```
GET /licenses
```

```json
[
  {
    "id": 1,
    "plan": "silver",
    "created_at": "2018-02-27T23:21:58.674Z",
    "starts_at": "2018-01-27",
    "expires_at": "2022-01-27",
    "historical_max": 300,
    "maximum_user_count": 300,
    "expired": false,
    "overage": 200,
    "user_limit": 100,
    "licensee": {
      "Name": "John Doe1"
    },
    "add_ons": {
      "GitLab_FileLocks": 1,
      "GitLab_Auditor_User": 1
    }
  },
  {
    "id": 2,
    "plan": "gold",
    "created_at": "2018-02-27T23:21:58.674Z",
    "starts_at": "2018-01-27",
    "expires_at": "2022-01-27",
    "historical_max": 300,
    "maximum_user_count": 300,
    "expired": false,
    "overage": 200,
    "user_limit": 100,
    "licensee": {
      "Name": "Doe John"
    },
    "add_ons": {
      "GitLab_FileLocks": 1,
    }
  }
]
```

Overage is the difference between the number of active users and the licensed number of users.
This is calculated differently depending on whether the license has expired or not.

- If the license has expired, it uses the historical maximum active user count (`historical_max`).
- If the license has not expired, it uses the current active users count.

Returns:

- `200 OK` with response containing the licenses in JSON format. This will be an empty JSON array if there are no licenses.
- `403 Forbidden` if the current user in not permitted to read the licenses.

## Add a new license

```
POST /license
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `license` | string | yes | The license string |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/license?license=eyJkYXRhIjoiMHM5Q...S01Udz09XG4ifQ=="
```

Example response:

```json
{
  "id": 1,
  "plan": "gold",
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
    "Name": "John Doe1"
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

```
DELETE /license/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | ID of the GitLab license. |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/license/:id"
```

Example response:

```json
{
  "id": 2,
  "plan": "gold",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "licensee": {
    "Name": "John Doe"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

Returns:

- `204 No Content` if the license is successfully deleted.
- `403 Forbidden` if the current user in not permitted to delete the license.
- `404 Not Found` if the license to delete could not be found.
