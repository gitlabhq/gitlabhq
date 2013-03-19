Login to get private token

```
POST /session
```

Parameters:

+ `email` (required) - The email of user
+ `password` (required) - Valid password


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
  "dark_scheme": false,
  "theme_id": 1
  "is_admin": false,
  "can_create_group" : true,
  "can_create_team" : true,
  "can_create_project" : true
}
```
