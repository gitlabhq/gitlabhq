## List users

Get a list of users.

```
GET /users
```

```json
[
  {
    "id": 1,
    "email": "john@example.com",
    "name": "John Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:00:58Z",
    "bio": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "dark_scheme": false,
    "theme_id": 1
  },
  {
    "id": 2,
    "email": "jack@example.com",
    "name": "Jack Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:01:01Z",
    "bio": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "dark_scheme": true,
    "theme_id": 1
  }
]
```

## Single user

Get a single user.

```
GET /users/:id
```

Parameters:

+ `id` (required) - The ID of a user

```json
{
  "id": 1,
  "email": "john@example.com",
  "name": "John Smith",
  "blocked": false,
  "created_at": "2012-05-23T08:00:58Z",
  "bio": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "dark_scheme": false,
  "theme_id": 1
}
```

## Current user

Get currently authenticated user.

```
GET /user
```

```json
{
  "id": 1,
  "email": "john@example.com",
  "name": "John Smith",
  "blocked": false,
  "created_at": "2012-05-23T08:00:58Z",
  "bio": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "dark_scheme": false,
  "theme_id": 1
}
```
