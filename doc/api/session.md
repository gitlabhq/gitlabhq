# Session

You can login with both GitLab and LDAP credentials in order to obtain the
private token.

```
POST /session
```

| Parameters | Required | Comments |
| ---------- | -------- | -------- |
| `login`    | yes      | The login of user|
| `email`    | yes if login is not provided | The email of the user |
| `password` | yes      | The password of the user |

cURL example:

```bash
curl --data "login=john_smith&password=strongpassw0rd" https://gitlab.com/api/v3/session
```

Output:

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
  "private_token": "gDGnJwv56z2Xfj2B83Es"
}
```
