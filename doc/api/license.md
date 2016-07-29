# License

## Retrieve information about the current license

In order to retrieve the license information, you need to authenticate yourself
as an admin.

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
  "active_users": 60
}
```