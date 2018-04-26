# Users API

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
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

In addition, you can filter users based on states eg. `blocked`, `active`
This works only to filter users who are `blocked` or `active`.
It does not support `active=false` or `blocked=false`.

```
GET /users?active=true
```

```
GET /users?blocked=true
```

### For admins

```
GET /users
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `order_by` | string | no | Return projects ordered by `id`, `name`, `username`, `created_at`, or `updated_at` fields. Default is `id` |
| `sort` | string | no | Return projects sorted in `asc` or `desc` order. Default is `desc` |
| `two_factor` | string | no | Filter users by Two-factor authentication. Filter values are `enabled` or `disabled`. By default it returns all users |

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
    "web_url": "http://localhost:3000/john_smith",
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
    "last_activity_on": "2012-05-23",
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
    "web_url": "http://localhost:3000/jack_smith",
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
    "last_activity_on": "2012-05-23",
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

You can also lookup users by external UID and provider:

```
GET /users?extern_uid=:extern_uid&provider=:provider
```

For example:

```
GET /users?extern_uid=1234567&provider=github
```

You can search for users who are external with: `/users?external=true`

You can search users by creation date time range with:

```
GET /users?created_before=2001-01-02T00:00:00.060Z&created_after=1999-01-02T00:00:00.060
```

You can filter by [custom attributes](custom_attributes.md) with:

```
GET /users?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

You can include the users' [custom attributes](custom_attributes.md) in the response with:

```
GET /users?with_custom_attributes=true
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
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
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
  "web_url": "http://localhost:3000/john_smith",
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
  "last_activity_on": "2012-05-23",
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

You can include the user's [custom attributes](custom_attributes.md) in the response with:

```
GET /users/:id?with_custom_attributes=true
```

## User creation

Creates a new user. Note only administrators can create new users. Either `password` or `reset_password` should be specified (`reset_password` takes priority).

```
POST /users
```

Parameters:

- `email` (required)             - Email
- `password` (optional)          - Password
- `reset_password` (optional)    - Send user password reset link - true or false(default)
- `username` (required)          - Username
- `name` (required)              - Name
- `skype` (optional)             - Skype ID
- `linkedin` (optional)          - LinkedIn
- `twitter` (optional)           - Twitter account
- `website_url` (optional)       - Website URL
- `organization` (optional)      - Organization name
- `projects_limit` (optional)    - Number of projects user can create
- `extern_uid` (optional)        - External UID
- `provider` (optional)          - External provider name
- `bio` (optional)               - User's biography
- `location` (optional)          - User's location
- `admin` (optional)             - User is admin - true or false (default)
- `can_create_group` (optional)  - User can create groups - true or false
- `skip_confirmation` (optional) - Skip confirmation - true or false (default)
- `external` (optional)          - Flags the user as external - true or false(default)
- `avatar` (optional)            - Image file for user's avatar

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
- `skip_reconfirmation` (optional) - Skip reconfirmation - true or false (default)
- `external` (optional)         - Flags the user as external - true or false(default)
- `avatar` (optional)           - Image file for user's avatar

On password update, user will be forced to change it upon next login.
Note, at the moment this method does only return a `404` error,
even in cases where a `409` (Conflict) would be more appropriate,
e.g. when renaming the email address to some existing one.

## User deletion

Deletes a user. Available only for administrators.
This returns a `204 No Content` status code if the operation was successfully or `404` if the resource was not found.

```
DELETE /users/:id
```

Parameters:

- `id` (required) - The ID of the user
- `hard_delete` (optional) - If true, contributions that would usually be
  [moved to the ghost user](../user/profile/account/delete_account.md#associated-records)
  will be deleted instead, as well as groups owned solely by this user.

## User

### For normal users

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
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
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
  "last_activity_on": "2012-05-23",
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

### For admins

Parameters:

- `sudo` (optional) - the ID of a user to make the call in their place

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
  "web_url": "http://localhost:3000/john_smith",
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
  "last_activity_on": "2012-05-23",
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

## List user projects

Please refer to the [List of user projects ](projects.md#list-user-projects).

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
GET /users/:id/keys
```

Parameters:

- `id` (required) - id of specified user

## Single SSH key

Get a single key.

```
GET /user/keys/:key_id
```

Parameters:

- `key_id` (required) - The ID of an SSH key

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

## Delete SSH key for current user

Deletes key owned by currently authenticated user.
This returns a `204 No Content` status code if the operation was successfully or `404` if the resource was not found.

```
DELETE /user/keys/:key_id
```

Parameters:

- `key_id` (required) - SSH key ID

## Delete SSH key for given user

Deletes key owned by a specified user. Available only for admin.

```
DELETE /users/:id/keys/:key_id
```

Parameters:

- `id` (required) - id of specified user
- `key_id` (required)  - SSH key ID

## List all GPG keys

Get a list of currently authenticated user's GPG keys.

```
GET /user/gpg_keys
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/user/gpg_keys
```

Example response:

```json
[
    {
        "id": 1,
        "key": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n\r\nxsBNBFVjnlIBCACibzXOLCiZiL2oyzYUaTOCkYnSUhymg3pdbfKtd4mpBa58xKBj\r\nt1pTHVpw3Sk03wmzhM/Ndlt1AV2YhLv++83WKr+gAHFYFiCV/tnY8bx3HqvVoy8O\r\nCfxWhw4QZK7+oYzVmJj8ZJm3ZjOC4pzuegNWlNLCUdZDx9OKlHVXLCX1iUbjdYWa\r\nqKV6tdV8hZolkbyjedQgrpvoWyeSHHpwHF7yk4gNJWMMI5rpcssL7i6mMXb/sDzO\r\nVaAtU5wiVducsOa01InRFf7QSTxoAm6Xy0PGv/k48M6xCALa9nY+BzlOv47jUT57\r\nvilf4Szy9dKD0v9S0mQ+IHB+gNukWrnwtXx5ABEBAAHNFm5hbWUgKGNvbW1lbnQp\r\nIDxlbUBpbD7CwHUEEwECACkFAlVjnlIJEINgJNgv009/AhsDAhkBBgsJCAcDAgYV\r\nCAIJCgsEFgIDAQAAxqMIAFBHuBA8P1v8DtHonIK8Lx2qU23t8Mh68HBIkSjk2H7/\r\noO2cDWCw50jZ9D91PXOOyMPvBWV2IE3tARzCvnNGtzEFRtpIEtZ0cuctxeIF1id5\r\ncrfzdMDsmZyRHAOoZ9VtuD6mzj0ybQWMACb7eIHjZDCee3Slh3TVrLy06YRdq2I4\r\nbjMOPePtK5xnIpHGpAXkB3IONxyITpSLKsA4hCeP7gVvm7r7TuQg1ygiUBlWbBYn\r\niE5ROzqZjG1s7dQNZK/riiU2umGqGuwAb2IPvNiyuGR3cIgRE4llXH/rLuUlspAp\r\no4nlxaz65VucmNbN1aMbDXLJVSqR1DuE00vEsL1AItI=\r\n=XQoy\r\n-----END PGP PUBLIC KEY BLOCK-----",
        "created_at": "2017-09-05T09:17:46.264Z"
    }
]
```

## Get a specific GPG key

Get a specific GPG key of currently authenticated user.

```
GET /user/gpg_keys/:key_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `key_id`  | integer | yes   | The ID of the GPG key |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/user/gpg_keys/1
```

Example response:

```json
  {
      "id": 1,
      "key": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n\r\nxsBNBFVjnlIBCACibzXOLCiZiL2oyzYUaTOCkYnSUhymg3pdbfKtd4mpBa58xKBj\r\nt1pTHVpw3Sk03wmzhM/Ndlt1AV2YhLv++83WKr+gAHFYFiCV/tnY8bx3HqvVoy8O\r\nCfxWhw4QZK7+oYzVmJj8ZJm3ZjOC4pzuegNWlNLCUdZDx9OKlHVXLCX1iUbjdYWa\r\nqKV6tdV8hZolkbyjedQgrpvoWyeSHHpwHF7yk4gNJWMMI5rpcssL7i6mMXb/sDzO\r\nVaAtU5wiVducsOa01InRFf7QSTxoAm6Xy0PGv/k48M6xCALa9nY+BzlOv47jUT57\r\nvilf4Szy9dKD0v9S0mQ+IHB+gNukWrnwtXx5ABEBAAHNFm5hbWUgKGNvbW1lbnQp\r\nIDxlbUBpbD7CwHUEEwECACkFAlVjnlIJEINgJNgv009/AhsDAhkBBgsJCAcDAgYV\r\nCAIJCgsEFgIDAQAAxqMIAFBHuBA8P1v8DtHonIK8Lx2qU23t8Mh68HBIkSjk2H7/\r\noO2cDWCw50jZ9D91PXOOyMPvBWV2IE3tARzCvnNGtzEFRtpIEtZ0cuctxeIF1id5\r\ncrfzdMDsmZyRHAOoZ9VtuD6mzj0ybQWMACb7eIHjZDCee3Slh3TVrLy06YRdq2I4\r\nbjMOPePtK5xnIpHGpAXkB3IONxyITpSLKsA4hCeP7gVvm7r7TuQg1ygiUBlWbBYn\r\niE5ROzqZjG1s7dQNZK/riiU2umGqGuwAb2IPvNiyuGR3cIgRE4llXH/rLuUlspAp\r\no4nlxaz65VucmNbN1aMbDXLJVSqR1DuE00vEsL1AItI=\r\n=XQoy\r\n-----END PGP PUBLIC KEY BLOCK-----",
      "created_at": "2017-09-05T09:17:46.264Z"
  }
```

## Add a GPG key

Creates a new GPG key owned by the currently authenticated user.

```
POST /user/gpg_keys
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| key       | string | yes    | The new GPG key |

```bash
curl --data "key=-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n\r\nxsBNBFV..."  --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/user/gpg_keys
```

Example response:

```json
[
    {
        "id": 1,
        "key": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n\r\nxsBNBFVjnlIBCACibzXOLCiZiL2oyzYUaTOCkYnSUhymg3pdbfKtd4mpBa58xKBj\r\nt1pTHVpw3Sk03wmzhM/Ndlt1AV2YhLv++83WKr+gAHFYFiCV/tnY8bx3HqvVoy8O\r\nCfxWhw4QZK7+oYzVmJj8ZJm3ZjOC4pzuegNWlNLCUdZDx9OKlHVXLCX1iUbjdYWa\r\nqKV6tdV8hZolkbyjedQgrpvoWyeSHHpwHF7yk4gNJWMMI5rpcssL7i6mMXb/sDzO\r\nVaAtU5wiVducsOa01InRFf7QSTxoAm6Xy0PGv/k48M6xCALa9nY+BzlOv47jUT57\r\nvilf4Szy9dKD0v9S0mQ+IHB+gNukWrnwtXx5ABEBAAHNFm5hbWUgKGNvbW1lbnQp\r\nIDxlbUBpbD7CwHUEEwECACkFAlVjnlIJEINgJNgv009/AhsDAhkBBgsJCAcDAgYV\r\nCAIJCgsEFgIDAQAAxqMIAFBHuBA8P1v8DtHonIK8Lx2qU23t8Mh68HBIkSjk2H7/\r\noO2cDWCw50jZ9D91PXOOyMPvBWV2IE3tARzCvnNGtzEFRtpIEtZ0cuctxeIF1id5\r\ncrfzdMDsmZyRHAOoZ9VtuD6mzj0ybQWMACb7eIHjZDCee3Slh3TVrLy06YRdq2I4\r\nbjMOPePtK5xnIpHGpAXkB3IONxyITpSLKsA4hCeP7gVvm7r7TuQg1ygiUBlWbBYn\r\niE5ROzqZjG1s7dQNZK/riiU2umGqGuwAb2IPvNiyuGR3cIgRE4llXH/rLuUlspAp\r\no4nlxaz65VucmNbN1aMbDXLJVSqR1DuE00vEsL1AItI=\r\n=XQoy\r\n-----END PGP PUBLIC KEY BLOCK-----",
        "created_at": "2017-09-05T09:17:46.264Z"
    }
]
```

## Delete a GPG key

Delete a GPG key owned by currently authenticated user.

```
DELETE /user/gpg_keys/:key_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `key_id`  | integer | yes   | The ID of the GPG key |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/user/gpg_keys/1
```

Returns `204 No Content` on success, or `404 Not found` if the key cannot be found.

## List all GPG keys for given user

Get a list of a specified user's GPG keys. Available only for admins.

```
GET /users/:id/gpg_keys
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes   | The ID of the user |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/users/2/gpg_keys
```

Example response:

```json
[
    {
        "id": 1,
        "key": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n\r\nxsBNBFVjnlIBCACibzXOLCiZiL2oyzYUaTOCkYnSUhymg3pdbfKtd4mpBa58xKBj\r\nt1pTHVpw3Sk03wmzhM/Ndlt1AV2YhLv++83WKr+gAHFYFiCV/tnY8bx3HqvVoy8O\r\nCfxWhw4QZK7+oYzVmJj8ZJm3ZjOC4pzuegNWlNLCUdZDx9OKlHVXLCX1iUbjdYWa\r\nqKV6tdV8hZolkbyjedQgrpvoWyeSHHpwHF7yk4gNJWMMI5rpcssL7i6mMXb/sDzO\r\nVaAtU5wiVducsOa01InRFf7QSTxoAm6Xy0PGv/k48M6xCALa9nY+BzlOv47jUT57\r\nvilf4Szy9dKD0v9S0mQ+IHB+gNukWrnwtXx5ABEBAAHNFm5hbWUgKGNvbW1lbnQp\r\nIDxlbUBpbD7CwHUEEwECACkFAlVjnlIJEINgJNgv009/AhsDAhkBBgsJCAcDAgYV\r\nCAIJCgsEFgIDAQAAxqMIAFBHuBA8P1v8DtHonIK8Lx2qU23t8Mh68HBIkSjk2H7/\r\noO2cDWCw50jZ9D91PXOOyMPvBWV2IE3tARzCvnNGtzEFRtpIEtZ0cuctxeIF1id5\r\ncrfzdMDsmZyRHAOoZ9VtuD6mzj0ybQWMACb7eIHjZDCee3Slh3TVrLy06YRdq2I4\r\nbjMOPePtK5xnIpHGpAXkB3IONxyITpSLKsA4hCeP7gVvm7r7TuQg1ygiUBlWbBYn\r\niE5ROzqZjG1s7dQNZK/riiU2umGqGuwAb2IPvNiyuGR3cIgRE4llXH/rLuUlspAp\r\no4nlxaz65VucmNbN1aMbDXLJVSqR1DuE00vEsL1AItI=\r\n=XQoy\r\n-----END PGP PUBLIC KEY BLOCK-----",
        "created_at": "2017-09-05T09:17:46.264Z"
    }
]
```

## Get a specific GPG key for a given user

Get a specific GPG key for a given user. Available only for admins.

```
GET /users/:id/gpg_keys/:key_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes   | The ID of the user |
| `key_id`  | integer | yes   | The ID of the GPG key |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/users/2/gpg_keys/1
```

Example response:

```json
  {
      "id": 1,
      "key": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n\r\nxsBNBFVjnlIBCACibzXOLCiZiL2oyzYUaTOCkYnSUhymg3pdbfKtd4mpBa58xKBj\r\nt1pTHVpw3Sk03wmzhM/Ndlt1AV2YhLv++83WKr+gAHFYFiCV/tnY8bx3HqvVoy8O\r\nCfxWhw4QZK7+oYzVmJj8ZJm3ZjOC4pzuegNWlNLCUdZDx9OKlHVXLCX1iUbjdYWa\r\nqKV6tdV8hZolkbyjedQgrpvoWyeSHHpwHF7yk4gNJWMMI5rpcssL7i6mMXb/sDzO\r\nVaAtU5wiVducsOa01InRFf7QSTxoAm6Xy0PGv/k48M6xCALa9nY+BzlOv47jUT57\r\nvilf4Szy9dKD0v9S0mQ+IHB+gNukWrnwtXx5ABEBAAHNFm5hbWUgKGNvbW1lbnQp\r\nIDxlbUBpbD7CwHUEEwECACkFAlVjnlIJEINgJNgv009/AhsDAhkBBgsJCAcDAgYV\r\nCAIJCgsEFgIDAQAAxqMIAFBHuBA8P1v8DtHonIK8Lx2qU23t8Mh68HBIkSjk2H7/\r\noO2cDWCw50jZ9D91PXOOyMPvBWV2IE3tARzCvnNGtzEFRtpIEtZ0cuctxeIF1id5\r\ncrfzdMDsmZyRHAOoZ9VtuD6mzj0ybQWMACb7eIHjZDCee3Slh3TVrLy06YRdq2I4\r\nbjMOPePtK5xnIpHGpAXkB3IONxyITpSLKsA4hCeP7gVvm7r7TuQg1ygiUBlWbBYn\r\niE5ROzqZjG1s7dQNZK/riiU2umGqGuwAb2IPvNiyuGR3cIgRE4llXH/rLuUlspAp\r\no4nlxaz65VucmNbN1aMbDXLJVSqR1DuE00vEsL1AItI=\r\n=XQoy\r\n-----END PGP PUBLIC KEY BLOCK-----",
      "created_at": "2017-09-05T09:17:46.264Z"
  }
```

## Add a GPG key for a given user

Create new GPG key owned by the specified user. Available only for admins.

```
POST /users/:id/gpg_keys
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes   | The ID of the user |
| `key_id`  | integer | yes   | The ID of the GPG key |

```bash
curl --data "key=-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n\r\nxsBNBFV..."  --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/users/2/gpg_keys
```

Example response:

```json
[
    {
        "id": 1,
        "key": "-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n\r\nxsBNBFVjnlIBCACibzXOLCiZiL2oyzYUaTOCkYnSUhymg3pdbfKtd4mpBa58xKBj\r\nt1pTHVpw3Sk03wmzhM/Ndlt1AV2YhLv++83WKr+gAHFYFiCV/tnY8bx3HqvVoy8O\r\nCfxWhw4QZK7+oYzVmJj8ZJm3ZjOC4pzuegNWlNLCUdZDx9OKlHVXLCX1iUbjdYWa\r\nqKV6tdV8hZolkbyjedQgrpvoWyeSHHpwHF7yk4gNJWMMI5rpcssL7i6mMXb/sDzO\r\nVaAtU5wiVducsOa01InRFf7QSTxoAm6Xy0PGv/k48M6xCALa9nY+BzlOv47jUT57\r\nvilf4Szy9dKD0v9S0mQ+IHB+gNukWrnwtXx5ABEBAAHNFm5hbWUgKGNvbW1lbnQp\r\nIDxlbUBpbD7CwHUEEwECACkFAlVjnlIJEINgJNgv009/AhsDAhkBBgsJCAcDAgYV\r\nCAIJCgsEFgIDAQAAxqMIAFBHuBA8P1v8DtHonIK8Lx2qU23t8Mh68HBIkSjk2H7/\r\noO2cDWCw50jZ9D91PXOOyMPvBWV2IE3tARzCvnNGtzEFRtpIEtZ0cuctxeIF1id5\r\ncrfzdMDsmZyRHAOoZ9VtuD6mzj0ybQWMACb7eIHjZDCee3Slh3TVrLy06YRdq2I4\r\nbjMOPePtK5xnIpHGpAXkB3IONxyITpSLKsA4hCeP7gVvm7r7TuQg1ygiUBlWbBYn\r\niE5ROzqZjG1s7dQNZK/riiU2umGqGuwAb2IPvNiyuGR3cIgRE4llXH/rLuUlspAp\r\no4nlxaz65VucmNbN1aMbDXLJVSqR1DuE00vEsL1AItI=\r\n=XQoy\r\n-----END PGP PUBLIC KEY BLOCK-----",
        "created_at": "2017-09-05T09:17:46.264Z"
    }
]
```

## Delete a GPG key for a given user

Delete a GPG key owned by a specified user. Available only for admins.

```
DELETE /users/:id/gpg_keys/:key_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes   | The ID of the user |
| `key_id`  | integer | yes   | The ID of the GPG key |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/users/2/gpg_keys/1
```

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
GET /users/:id/emails
```

Parameters:

- `id` (required) - id of specified user

## Single email

Get a single email.

```
GET /user/emails/:email_id
```

Parameters:

- `email_id` (required) - email ID

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

## Delete email for current user

Deletes email owned by currently authenticated user.
This returns a `204 No Content` status code if the operation was successfully or `404` if the resource was not found.

```
DELETE /user/emails/:email_id
```

Parameters:

- `email_id` (required) - email ID

## Delete email for given user

Deletes email owned by a specified user. Available only for admin.

```
DELETE /users/:id/emails/:email_id
```

Parameters:

- `id` (required) - id of specified user
- `email_id` (required)  - email ID

## Block user

Blocks the specified user.  Available only for admin.

```
POST /users/:id/block
```

Parameters:

- `id` (required) - id of specified user

Will return `201 OK` on success, `404 User Not Found` is user cannot be found or
`403 Forbidden` when trying to block an already blocked user by LDAP synchronization.

## Unblock user

Unblocks the specified user.  Available only for admin.

```
POST /users/:id/unblock
```

Parameters:

- `id` (required) - id of specified user

Will return `201 OK` on success, `404 User Not Found` is user cannot be found or
`403 Forbidden` when trying to unblock a user blocked by LDAP synchronization.

### Get user contribution events

Please refer to the [Events API documentation](events.md#get-user-contribution-events)


## Get all impersonation tokens of a user

> Requires admin permissions.

It retrieves every impersonation token of the user. Use the pagination
parameters `page` and `per_page` to restrict the list of impersonation tokens.

```
GET /users/:user_id/impersonation_tokens
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `user_id` | integer | yes | The ID of the user |
| `state`   | string  | no | filter tokens based on state (`all`, `active`, `inactive`) |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/users/42/impersonation_tokens
```

Example response:

```json
[
   {
      "active" : true,
      "token" : "EsMo-vhKfXGwX9RKrwiy",
      "scopes" : [
         "api"
      ],
      "revoked" : false,
      "name" : "mytoken",
      "id" : 2,
      "created_at" : "2017-03-17T17:18:09.283Z",
      "impersonation" : true,
      "expires_at" : "2017-04-04"
   },
   {
      "active" : false,
      "scopes" : [
         "read_user"
      ],
      "revoked" : true,
      "token" : "ZcZRpLeEuQRprkRjYydY",
      "name" : "mytoken2",
      "created_at" : "2017-03-17T17:19:28.697Z",
      "id" : 3,
      "impersonation" : true,
      "expires_at" : "2017-04-14"
   }
]
```

## Get an impersonation token of a user

> Requires admin permissions.

It shows a user's impersonation token.

```
GET /users/:user_id/impersonation_tokens/:impersonation_token_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `user_id` | integer | yes | The ID of the user |
| `impersonation_token_id` | integer | yes | The ID of the impersonation token |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/users/42/impersonation_tokens/2
```

Example response:

```json
{
   "active" : true,
   "token" : "EsMo-vhKfXGwX9RKrwiy",
   "scopes" : [
      "api"
   ],
   "revoked" : false,
   "name" : "mytoken",
   "id" : 2,
   "created_at" : "2017-03-17T17:18:09.283Z",
   "impersonation" : true,
   "expires_at" : "2017-04-04"
}
```

## Create an impersonation token

> Requires admin permissions.

It creates a new impersonation token. Note that only administrators can do this.
You are only able to create impersonation tokens to impersonate the user and perform
both API calls and Git reads and writes. The user will not see these tokens in their profile
settings page.

```
POST /users/:user_id/impersonation_tokens
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `user_id` | integer | yes | The ID of the user |
| `name`    | string  | yes | The name of the impersonation token |
| `expires_at` | date | no  | The expiration date of the impersonation token in ISO format (`YYYY-MM-DD`)|
| `scopes` | array    | yes | The array of scopes of the impersonation token (`api`, `read_user`) |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --data "name=mytoken" --data "expires_at=2017-04-04" --data "scopes[]=api" https://gitlab.example.com/api/v4/users/42/impersonation_tokens
```

Example response:

```json
{
   "id" : 2,
   "revoked" : false,
   "scopes" : [
      "api"
   ],
   "token" : "EsMo-vhKfXGwX9RKrwiy",
   "active" : true,
   "impersonation" : true,
   "name" : "mytoken",
   "created_at" : "2017-03-17T17:18:09.283Z",
   "expires_at" : "2017-04-04"
}
```

## Revoke an impersonation token

> Requires admin permissions.

It revokes an impersonation token.

```
DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id
```

```
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/users/42/impersonation_tokens/1
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `user_id` | integer | yes | The ID of the user |
| `impersonation_token_id` | integer | yes | The ID of the impersonation token |

### Get user activities (admin only)

>**Note:** This API endpoint is only available on 8.15 (EE) and 9.1 (CE) and above.

Get the last activity date for all users, sorted from oldest to newest.

The activities that update the timestamp are:

  - Git HTTP/SSH activities (such as clone, push)
  - User logging in into GitLab

By default, it shows the activity for all users in the last 6 months, but this can be
amended by using the `from` parameter.

```
GET /user/activities
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `from` | string | no | Date string in the format YEAR-MONTH-DAY, e.g. `2016-03-11`. Defaults to 6 months ago. |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/user/activities
```

Example response:

```json
[
  {
    "username": "user1",
    "last_activity_on": "2015-12-14",
    "last_activity_at": "2015-12-14"
  },
  {
    "username": "user2",
    "last_activity_on": "2015-12-15",
    "last_activity_at": "2015-12-15"
  },
  {
    "username": "user3",
    "last_activity_on": "2015-12-16",
    "last_activity_at": "2015-12-16"
  }
]
```

Please note that `last_activity_at` is deprecated, please use `last_activity_on`.
