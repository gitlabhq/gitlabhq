# Session

Login to get private token

```
POST /session
```

Parameters:

+ `login` (required) - The login of user
+ `email` (required if login missing) - The email of user
+ `password` (required) - Valid password


__You can login with both GitLab and LDAP credentials now__

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "private_token": "dd34asd13as",
  "blocked": false,
  "created_at": "2012-05-23T08:00:58Z",
  "bio": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "dark_scheme": false,
  "theme_id": 1,
  "is_admin": false,
  "can_create_group": true,
  "can_create_team": true,
  "can_create_project": true
}
```
