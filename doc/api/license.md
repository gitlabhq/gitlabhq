# License

In order to interact with license endpoints, you need to authenticate yourself
as an admin.

## Retrieve information about the current license

```
GET /license
```

```json
{
  "starts_at": "2015-10-24",
  "expires_at": "2016-10-24",
  "licensee": {
    "Name": "John Doe",
    "Company": "Doe, Inc.",
    "Email": "john@doe.com"
  },
  "user_limit": 100,
  "active_users": 60,
  "add_ons": {
    "GitLab_FileLocks": 100
  }
}
```

## Add a new license

```
POST /license
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `license` | string | yes | The license string |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/license?license=eyJkYXRhIjoiMHM5Q...S01Udz09XG4ifQ=="
```

Example response:

```json
{
  "starts_at": "2015-10-24",
  "expires_at": "2016-10-24",
  "licensee": {
    "Name": "John Doe",
    "Company": "Doe, Inc.",
    "Email": "john@doe.com"
  },
  "user_limit": 100,
  "active_users": 60,
  "add_ons": {
    "GitLab_FileLocks": 100
  }
}
```

It returns `201` if it succeeds or `400` if failed with an error message
explaining the reason.
