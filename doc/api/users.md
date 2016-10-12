# Users

## List users

Get a list of users.

This function takes pagination parameters `page` and `per_page` to restrict the list of users.

### For normal users

```
GET /users
```

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/u/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/u/jack_smith"
  }
]
```

### For admins

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
    "state": "active",
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
    "web_url": "http://localhost:3000/u/john_smith",
    "created_at": "2012-05-23T08:00:58Z",
    "is_admin": false,
    "bio": null,
    "location": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": "",
    "last_sign_in_at": "2012-06-01T11:41:01Z",
    "confirmed_at": "2012-05-23T09:05:22Z",
    "theme_id": 1,
    "color_scheme_id": 2,
    "projects_limit": 100,
    "current_sign_in_at": "2012-06-02T06:36:55Z",
    "identities": [
      {"provider": "github", "extern_uid": "2435223452345"},
      {"provider": "bitbucket", "extern_uid": "john.smith"},
      {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": true,
    "external": false
  },
  {
    "id": 2,
    "username": "jack_smith",
    "email": "jack@example.com",
    "name": "Jack Smith",
    "state": "blocked",
    "avatar_url": "http://localhost:3000/uploads/user/avatar/2/index.jpg",
    "web_url": "http://localhost:3000/u/jack_smith",
    "created_at": "2012-05-23T08:01:01Z",
    "is_admin": false,
    "bio": null,
    "location": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": "",
    "last_sign_in_at": null,
    "confirmed_at": "2012-05-30T16:53:06.148Z",
    "theme_id": 1,
    "color_scheme_id": 3,
    "projects_limit": 100,
    "current_sign_in_at": "2014-03-19T17:54:13Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": true,
    "external": false
  }
]
```

You can search for users by email or username with: `/users?search=John`

In addition, you can lookup users by username:

```
GET /users?username=:username
```

For example:

```
GET /users?username=jack_smith
```

## Single user

Get a single user.

### For user

```
GET /users/:id
```

Parameters:

- `id` (required) - The ID of a user

```json
{
  "id": 1,
  "username": "john_smith",
  "name": "John Smith",
  "state": "active",
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
  "web_url": "http://localhost:3000/u/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": false,
  "bio": null,
  "location": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": ""
}
```

### For admin

```
GET /users/:id
```

Parameters:

- `id` (required) - The ID of a user

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/u/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": false,
  "bio": null,
  "location": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": "",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john.smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false
}
```

## User creation

Creates a new user. Note only administrators can create new users.

```
POST /users
```

Parameters:

- `email` (required)            - Email
- `password` (required)         - Password
- `username` (required)         - Username
- `name` (required)             - Name
- `skype` (optional)            - Skype ID
- `linkedin` (optional)         - LinkedIn
- `twitter` (optional)          - Twitter account
- `website_url` (optional)      - Website URL
- `organization` (optional)     - Organization name
- `projects_limit` (optional)   - Number of projects user can create
- `extern_uid` (optional)       - External UID
- `provider` (optional)         - External provider name
- `bio` (optional)              - User's biography
- `location` (optional)         - User's location
- `admin` (optional)            - User is admin - true or false (default)
- `can_create_group` (optional) - User can create groups - true or false
- `confirm` (optional)          - Require confirmation - true (default) or false
- `external` (optional)         - Flags the user as external - true or false(default)

## User modification

Modifies an existing user. Only administrators can change attributes of a user.

```
PUT /users/:id
```

Parameters:

- `email`                       - Email
- `username`                    - Username
- `name`                        - Name
- `password`                    - Password
- `skype`                       - Skype ID
- `linkedin`                    - LinkedIn
- `twitter`                     - Twitter account
- `website_url`                 - Website URL
- `organization`                - Organization name
- `projects_limit`              - Limit projects each user can create
- `extern_uid`                  - External UID
- `provider`                    - External provider name
- `bio`                         - User's biography
- `location` (optional)         - User's location
- `admin` (optional)            - User is admin - true or false (default)
- `can_create_group` (optional) - User can create groups - true or false
- `external` (optional)         - Flags the user as external - true or false(default)

Note, at the moment this method does only return a 404 error,
even in cases where a 409 (Conflict) would be more appropriate,
e.g. when renaming the email address to some existing one.

## User deletion

Deletes a user. Available only for administrators.
This is an idempotent function, calling this function for a non-existent user id
still returns a status code `200 OK`.
The JSON response differs if the user was actually deleted or not.
In the former the user is returned and in the latter not.

```
DELETE /users/:id
```

Parameters:

- `id` (required) - The ID of the user

## Current user

Gets currently authenticated user.

```
GET /user
```

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/u/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": false,
  "bio": null,
  "location": null,
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": "",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john_smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"}
  ],
  "can_create_group": true,
  "can_create_project": true,
  "two_factor_enabled": true,
  "external": false
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
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z"
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2014-08-01T14:47:39.080Z"
  }
]
```

Parameters:

- **none**

## List SSH keys for user

Get a list of a specified user's SSH keys. Available only for admin

```
GET /users/:uid/keys
```

Parameters:

- `uid` (required) - id of specified user

## Single SSH key

Get a single key.

```
GET /user/keys/:id
```

Parameters:

- `id` (required) - The ID of an SSH key

```json
{
  "id": 1,
  "title": "Public key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2014-08-01T14:47:39.080Z"
}
```

## Add SSH key

Creates a new key owned by the currently authenticated user.

```
POST /user/keys
```

Parameters:

- `title` (required) - new SSH Key's title
- `key` (required)   - new SSH key

```json
{
  "created_at": "2015-01-21T17:44:33.512Z",
  "key": "ssh-dss AAAAB3NzaC1kc3MAAACBAMLrhYgI3atfrSD6KDas1b/3n6R/HP+bLaHHX6oh+L1vg31mdUqK0Ac/NjZoQunavoyzqdPYhFz9zzOezCrZKjuJDS3NRK9rspvjgM0xYR4d47oNZbdZbwkI4cTv/gcMlquRy0OvpfIvJtjtaJWMwTLtM5VhRusRuUlpH99UUVeXAAAAFQCVyX+92hBEjInEKL0v13c/egDCTQAAAIEAvFdWGq0ccOPbw4f/F8LpZqvWDydAcpXHV3thwb7WkFfppvm4SZte0zds1FJ+Hr8Xzzc5zMHe6J4Nlay/rP4ewmIW7iFKNBEYb/yWa+ceLrs+TfR672TaAgO6o7iSRofEq5YLdwgrwkMmIawa21FrZ2D9SPao/IwvENzk/xcHu7YAAACAQFXQH6HQnxOrw4dqf0NqeKy1tfIPxYYUZhPJfo9O0AmBW2S36pD2l14kS89fvz6Y1g8gN/FwFnRncMzlLY/hX70FSc/3hKBSbH6C6j8hwlgFKfizav21eS358JJz93leOakJZnGb8XlWvz1UJbwCsnR2VEY8Dz90uIk1l/UqHkA= loic@call",
  "title": "ABC",
  "id": 4
}
```

Will return created key with status `201 Created` on success. If an
error occurs a `400 Bad Request` is returned with a message explaining the error:

```json
{
  "message": {
    "fingerprint": [
      "has already been taken"
    ],
    "key": [
      "has already been taken"
    ]
  }
}
```

## Add SSH key for user

Create new key owned by specified user. Available only for admin

```
POST /users/:id/keys
```

Parameters:

- `id` (required)    - id of specified user
- `title` (required) - new SSH Key's title
- `key` (required)   - new SSH key

Will return created key with status `201 Created` on success, or `404 Not found` on fail.

## Delete SSH key for current user

Deletes key owned by currently authenticated user.
This is an idempotent function and calling it on a key that is already deleted
or not available results in `200 OK`.

```
DELETE /user/keys/:id
```

Parameters:

- `id` (required) - SSH key ID

## Delete SSH key for given user

Deletes key owned by a specified user. Available only for admin.

```
DELETE /users/:uid/keys/:id
```

Parameters:

- `uid` (required) - id of specified user
- `id` (required)  - SSH key ID

Will return `200 OK` on success, or `404 Not found` if either user or key cannot be found.

## List emails

Get a list of currently authenticated user's emails.

```
GET /user/emails
```

```json
[
  {
    "id": 1,
    "email": "email@example.com"
  },
  {
    "id": 3,
    "email": "email2@example.com"
  }
]
```

Parameters:

- **none**

## List emails for user

Get a list of a specified user's emails. Available only for admin

```
GET /users/:uid/emails
```

Parameters:

- `uid` (required) - id of specified user

## Single email

Get a single email.

```
GET /user/emails/:id
```

Parameters:

- `id` (required) - email ID

```json
{
  "id": 1,
  "email": "email@example.com"
}
```

## Add email

Creates a new email owned by the currently authenticated user.

```
POST /user/emails
```

Parameters:

- `email` (required) - email address

```json
{
  "id": 4,
  "email": "email@example.com"
}
```

Will return created email with status `201 Created` on success. If an
error occurs a `400 Bad Request` is returned with a message explaining the error:

```json
{
  "message": {
    "email": [
      "has already been taken"
    ]
  }
}
```

## Add email for user

Create new email owned by specified user. Available only for admin

```
POST /users/:id/emails
```

Parameters:

- `id` (required)    - id of specified user
- `email` (required) - email address

Will return created email with status `201 Created` on success, or `404 Not found` on fail.

## Delete email for current user

Deletes email owned by currently authenticated user.
This is an idempotent function and calling it on a email that is already deleted
or not available results in `200 OK`.

```
DELETE /user/emails/:id
```

Parameters:

- `id` (required) - email ID

## Delete email for given user

Deletes email owned by a specified user. Available only for admin.

```
DELETE /users/:uid/emails/:id
```

Parameters:

- `uid` (required) - id of specified user
- `id` (required)  - email ID

Will return `200 OK` on success, or `404 Not found` if either user or email cannot be found.

## Block user

Blocks the specified user.  Available only for admin.

```
PUT /users/:uid/block
```

Parameters:

- `uid` (required) - id of specified user

Will return `200 OK` on success, `404 User Not Found` is user cannot be found or
`403 Forbidden` when trying to block an already blocked user by LDAP synchronization.

## Unblock user

Unblocks the specified user.  Available only for admin.

```
PUT /users/:uid/unblock
```

Parameters:

- `uid` (required) - id of specified user

Will return `200 OK` on success, `404 User Not Found` is user cannot be found or
`403 Forbidden` when trying to unblock a user blocked by LDAP synchronization.

### Get user contribution events

Get the contribution events for the specified user, sorted from newest to oldest.

```
GET /users/:id/events
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of the user |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/user/:id/events
```

Example response:

```json
[
  {
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 830,
    "target_type": "Issue",
    "author_id": 1,
    "data": null,
    "target_title": "Public project search field",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/u/root"
    },
    "author_username": "root"
  },
  {
    "title": null,
    "project_id": 15,
    "action_name": "opened",
    "target_id": null,
    "target_type": null,
    "author_id": 1,
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/u/root"
    },
    "author_username": "john",
    "data": {
      "before": "50d4420237a9de7be1304607147aec22e4a14af7",
      "after": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
      "ref": "refs/heads/master",
      "user_id": 1,
      "user_name": "Dmitriy Zaporozhets",
      "repository": {
        "name": "gitlabhq",
        "url": "git@dev.gitlab.org:gitlab/gitlabhq.git",
        "description": "GitLab: self hosted Git management software. \r\nDistributed under the MIT License.",
        "homepage": "https://dev.gitlab.org/gitlab/gitlabhq"
      },
      "commits": [
        {
          "id": "c5feabde2d8cd023215af4d2ceeb7a64839fc428",
          "message": "Add simple search to projects in public area",
          "timestamp": "2013-05-13T18:18:08+00:00",
          "url": "https://dev.gitlab.org/gitlab/gitlabhq/commit/c5feabde2d8cd023215af4d2ceeb7a64839fc428",
          "author": {
            "name": "Dmitriy Zaporozhets",
            "email": "dmitriy.zaporozhets@gmail.com"
          }
        }
      ],
      "total_commits_count": 1
    },
    "target_title": null
  },
  {
    "title": null,
    "project_id": 15,
    "action_name": "closed",
    "target_id": 840,
    "target_type": "Issue",
    "author_id": 1,
    "data": null,
    "target_title": "Finish & merge Code search PR",
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/u/root"
    },
    "author_username": "root"
  },
  {
    "title": null,
    "project_id": 15,
    "action_name": "commented on",
    "target_id": 1312,
    "target_type": "Note",
    "author_id": 1,
    "data": null,
    "target_title": null,
    "created_at": "2015-12-04T10:33:58.089Z",
    "note": {
      "id": 1312,
      "body": "What an awesome day!",
      "attachment": null,
      "author": {
        "name": "Dmitriy Zaporozhets",
        "username": "root",
        "id": 1,
        "state": "active",
        "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
        "web_url": "http://localhost:3000/u/root"
      },
      "created_at": "2015-12-04T10:33:56.698Z",
      "system": false,
      "upvote": false,
      "downvote": false,
      "noteable_id": 377,
      "noteable_type": "Issue"
    },
    "author": {
      "name": "Dmitriy Zaporozhets",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://localhost:3000/uploads/user/avatar/1/fox_avatar.png",
      "web_url": "http://localhost:3000/u/root"
    },
    "author_username": "root"
  }
]
```
