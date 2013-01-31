## List users

Get a list of users.

```
GET /users
```

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:00:58Z",
    "bio": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "dark_scheme": false,
    "extern_uid": "john.smith",
    "provider": "provider_name",
    "theme_id": 1
  },
  {
    "id": 2,
    "username": "jack_smith",
    "email": "jack@example.com",
    "name": "Jack Smith",
    "blocked": false,
    "created_at": "2012-05-23T08:01:01Z",
    "bio": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "dark_scheme": true,
    "extern_uid": "jack.smith",
    "provider": "provider_name",
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
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "blocked": false,
  "created_at": "2012-05-23T08:00:58Z",
  "bio": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "dark_scheme": false,
  "extern_uid": "john.smith",
  "provider": "provider_name",
  "theme_id": 1
}
```

## User creation
Create user. Available only for admin

```
POST /users
```

Parameters:
+ `email` (required)                  - Email
+ `password` (required)               - Password
+ `username` (required)               - Username
+ `name` (required)                   - Name
+ `skype`                             - Skype ID
+ `linkedin`                          - Linkedin
+ `twitter`                           - Twitter account
+ `projects_limit`                    - Number of projects user can create
+ `extern_uid`                        - External UID
+ `provider`                          - External provider name
+ `bio`                               - User's bio

Will return created user with status `201 Created` on success, or `404 Not
found` on fail.

## User modification
Modify user. Available only for admin

```
PUT /users/:id
```

Parameters:
+ `email`                             - Email
+ `username`                          - Username
+ `name`                              - Name
+ `password`                          - Password
+ `skype`                             - Skype ID
+ `linkedin`                          - Linkedin
+ `twitter`                           - Twitter account
+ `projects_limit`                    - Limit projects wich user can create
+ `extern_uid`                        - External UID
+ `provider`                          - External provider name
+ `bio`                               - User's bio


Will return created user with status `200 OK` on success, or `404 Not
found` on fail.

## User deletion
Delete user. Available only for admin

```
DELETE /users/:id
```

Will return deleted user with status `200 OK` on success, or `404 Not
found` on fail.

## Current user

Get currently authenticated user.

```
GET /user
```

```json
{
  "id": 1,
  "username": "john_smith",
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

## List SSH keys

Get a list of currently authenticated user's SSH keys.

```
GET /user/keys
```

```json
[
  {
    "id": 1,
    "title" : "Public key"
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4
      596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4
      soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  },
  {
    "id": 3,
    "title" : "Another Public key"
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4
      596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4
      soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
  }
]
```

## Single SSH key

Get a single key.

```
GET /user/keys/:id
```

Parameters:

+ `id` (required) - The ID of an SSH key

```json
{
  "id": 1,
  "title" : "Public key"
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4
      596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4
      soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="
}
```
## Add SSH key

Create new key owned by currently authenticated user

```
POST /user/keys
```

Parameters:

+ `title` (required) - new SSH Key's title
+ `key` (required) - new SSH key

Will return created key with status `201 Created` on success, or `404 Not
found` on fail.

## Delete SSH key

Delete key owned by currently authenticated user

```
DELETE /user/keys/:id
```

Parameters:

+ `id` (required) - SSH key ID

Will return `200 OK` on success, or `404 Not Found` on fail.
