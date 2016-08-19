# Session

## Deprecation Notice

1. Starting in GitLab 8.11, this feature has been *disabled* for users with two-factor authentication turned on.
2. These users can access the API using [personal access tokens] instead.

---

You can login with both GitLab and LDAP credentials in order to obtain the
private token.

```
POST /session
```

| Attribute  | Type    | Required | Description |
| ---------- | ------- | -------- | -------- |
| `login`    | string  | yes      | The username of the user|
| `email`    | string  | yes if login is not provided | The email of the user |
| `password` | string  | yes     | The password of the user |

```bash
curl --request POST "https://gitlab.example.com/api/v3/session?login=john_smith&password=strongpassw0rd"
```

Example response:

```json
{
  "name": "John Smith",
  "username": "john_smith",
  "id": 32,
  "state": "active",
  "avatar_url": null,
  "created_at": "2015-01-29T21:07:19.440Z",
  "is_admin": true,
  "bio": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "email": "john@example.com",
  "theme_id": 1,
  "color_scheme_id": 1,
  "projects_limit": 10,
  "current_sign_in_at": "2015-07-07T07:10:58.392Z",
  "identities": [],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": false,
  "private_token": "9koXpg98eAheJpvBs5tK"
}
```

[personal access tokens]: ./README.md#personal-access-tokens
