# Users API

## List users

Active users = Total accounts - Blocked users

Get a list of users.

This function takes pagination parameters `page` and `per_page` to restrict the list of users.

### For normal users

```plaintext
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

You can also search for users by name or primary email using `?search=`. For example. `/users?search=John`.

In addition, you can lookup users by username:

```plaintext
GET /users?username=:username
```

For example:

```plaintext
GET /users?username=jack_smith
```

In addition, you can filter users based on states eg. `blocked`, `active`
This works only to filter users who are `blocked` or `active`.
It does not support `active=false` or `blocked=false`.

```plaintext
GET /users?active=true
```

```plaintext
GET /users?blocked=true
```

NOTE: **Note:**
Username search is case insensitive.

### For admins

```plaintext
GET /users
```

| Attribute    | Type   | Required | Description |
| ------------ | ------ | -------- | ----------- |
| `order_by`   | string | no       | Return users ordered by `id`, `name`, `username`, `created_at`, or `updated_at` fields. Default is `id` |
| `sort`       | string | no       | Return users sorted in `asc` or `desc` order. Default is `desc` |
| `two_factor` | string | no       | Filter users by Two-factor authentication. Filter values are `enabled` or `disabled`. By default it returns all users |
| `without_projects` | boolean | no | Filter users without projects. Default is `false` |

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
    "job_title": "",
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
    "external": false,
    "private_profile": false,
    "current_sign_in_ip": "196.165.1.102",
    "last_sign_in_ip": "172.127.2.22"
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
    "job_title": "",
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
    "external": false,
    "private_profile": false,
    "current_sign_in_ip": "10.165.1.102",
    "last_sign_in_ip": "172.127.2.22"
  }
]
```

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see the `shared_runners_minutes_limit`, `extra_shared_runners_minutes_limit`, and `note` parameters.

```json
[
  {
    "id": 1,
    ...
    "shared_runners_minutes_limit": 133,
    "extra_shared_runners_minutes_limit": 133,
    "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
    ...
  }
]
```

Users on GitLab [Silver or higher](https://about.gitlab.com/pricing/) will also see
the `group_saml` provider option:

```json
[
  {
    "id": 1,
    ...
    "identities": [
      {"provider": "github", "extern_uid": "2435223452345"},
      {"provider": "bitbucket", "extern_uid": "john.smith"},
      {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"},
      {"provider": "group_saml", "extern_uid": "123789", "saml_provider_id": 10}
    ],
    ...
  }
]
```

You can lookup users by external UID and provider:

```plaintext
GET /users?extern_uid=:extern_uid&provider=:provider
```

For example:

```plaintext
GET /users?extern_uid=1234567&provider=github
```

You can search for users who are external with: `/users?external=true`

You can search users by creation date time range with:

```plaintext
GET /users?created_before=2001-01-02T00:00:00.060Z&created_after=1999-01-02T00:00:00.060
```

You can search for users without projects with: `/users?without_projects=true`

You can filter by [custom attributes](custom_attributes.md) with:

```plaintext
GET /users?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

You can include the users' [custom attributes](custom_attributes.md) in the response with:

```plaintext
GET /users?with_custom_attributes=true
```

## Single user

Get a single user.

### For user

```plaintext
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
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": "",
  "job_title": "Operations Specialist"
}
```

### For admin

```plaintext
GET /users/:id
```

Parameters:

- `id` (required) - The ID of a user

Example Responses:

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
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": "",
  "job_title": "Operations Specialist",
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
  "external": false,
  "private_profile": false,
  "current_sign_in_ip": "196.165.1.102",
  "last_sign_in_ip": "172.127.2.22",
  "plan": "gold",
  "trial": true
}
```

NOTE: **Note:** The `plan` and `trial` parameters are only available on GitLab Enterprise Edition.

Users on GitLab [Starter, Bronze, or higher](https://about.gitlab.com/pricing/) will also see
the `shared_runners_minutes_limit`, `extra_shared_runners_minutes_limit`, and `note` parameters.

```json
{
  "id": 1,
  "username": "john_smith",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
  ...
}
```

Users on GitLab.com [Silver, or higher](https://about.gitlab.com/pricing/) will also
see the `group_saml` option:

```json
{
  "id": 1,
  "username": "john_smith",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john.smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"},
    {"provider": "group_saml", "extern_uid": "123789", "saml_provider_id": 10}
  ],
  ...
}
```

You can include the user's [custom attributes](custom_attributes.md) in the response with:

```plaintext
GET /users/:id?with_custom_attributes=true
```

## User creation

Creates a new user. Note only administrators can create new
users. Either `password`, `reset_password`, or `force_random_password`
must be specified. If `reset_password` and `force_random_password` are
both `false`, then `password` is required.

Note that `force_random_password` and `reset_password` take priority
over `password`. In addition, `reset_password` and
`force_random_password` can be used together.

NOTE: **Note:**
From [GitLab 12.1](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/29888/), `private_profile` will default to `false`.

```plaintext
POST /users
```

Parameters:

| Attribute                            | Required | Description                                                                                                                                             |
|:-------------------------------------|:---------|:--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `admin`                              | No       | User is admin - true or false (default)                                                                                                                 |
| `avatar`                             | No       | Image file for user's avatar                                                                                                                            |
| `bio`                                | No       | User's biography                                                                                                                                        |
| `can_create_group`                   | No       | User can create groups - true or false                                                                                                                  |
| `color_scheme_id`                    | No       | User's color scheme for the file viewer (see [the user preference docs](../user/profile/preferences.md#syntax-highlighting-theme) for more information) |
| `email`                              | Yes      | Email                                                                                                                                                   |
| `extern_uid`                         | No       | External UID                                                                                                                                            |
| `external`                           | No       | Flags the user as external - true or false (default)                                                                                                    |
| `extra_shared_runners_minutes_limit` | No       | Extra pipeline minutes quota for this user **(STARTER)**                                                                                                |
| `force_random_password`              | No       | Set user password to a random value - true or false (default)                                                                                           |
| `group_id_for_saml`                  | No       | ID of group where SAML has been configured                                                                                                              |
| `linkedin`                           | No       | LinkedIn                                                                                                                                                |
| `location`                           | No       | User's location                                                                                                                                         |
| `name`                               | Yes      | Name                                                                                                                                                    |
| `organization`                       | No       | Organization name                                                                                                                                       |
| `password`                           | No       | Password                                                                                                                                                |
| `private_profile`                    | No       | User's profile is private - true, false (default), or null (will be converted to false)                                                                 |
| `projects_limit`                     | No       | Number of projects user can create                                                                                                                      |
| `provider`                           | No       | External provider name                                                                                                                                  |
| `public_email`                       | No       | The public email of the user                                                                                                                            |
| `reset_password`                     | No       | Send user password reset link - true or false(default)                                                                                                  |
| `shared_runners_minutes_limit`       | No       | Pipeline minutes quota for this user **(STARTER)**                                                                                                      |
| `skip_confirmation`                  | No       | Skip confirmation - true or false (default)                                                                                                             |
| `skype`                              | No       | Skype ID                                                                                                                                                |
| `theme_id`                           | No       | The GitLab theme for the user (see [the user preference docs](../user/profile/preferences.md#navigation-theme) for more information)                    |
| `twitter`                            | No       | Twitter account                                                                                                                                         |
| `username`                           | Yes      | Username                                                                                                                                                |
| `website_url`                        | No       | Website URL                                                                                                                                             |

## User modification

Modifies an existing user. Only administrators can change attributes of a user.

```plaintext
PUT /users/:id
```

Parameters:

| Attribute                            | Required | Description                                                                                                                                             |
|:-------------------------------------|:---------|:--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `admin`                              | No       | User is admin - true or false (default)                                                                                                                 |
| `avatar`                             | No       | Image file for user's avatar                                                                                                                            |
| `bio`                                | No       | User's biography                                                                                                                                        |
| `can_create_group`                   | No       | User can create groups - true or false                                                                                                                  |
| `color_scheme_id`                    | No       | User's color scheme for the file viewer (see [the user preference docs](../user/profile/preferences.md#syntax-highlighting-theme) for more information) |
| `email`                              | No       | Email                                                                                                                                                   |
| `extern_uid`                         | No       | External UID                                                                                                                                            |
| `external`                           | No       | Flags the user as external - true or false (default)                                                                                                    |
| `extra_shared_runners_minutes_limit` | No       | Extra pipeline minutes quota for this user **(STARTER)**                                                                                                |
| `group_id_for_saml`                  | No       | ID of group where SAML has been configured                                                                                                              |
| `id`                                 | Yes      | The ID of the user                                                                                                                                      |
| `linkedin`                           | No       | LinkedIn                                                                                                                                                |
| `location`                           | No       | User's location                                                                                                                                         |
| `name`                               | No       | Name                                                                                                                                                    |
| `note`                               | No       | Admin notes for this user **(STARTER)**                                                                                                                 |
| `organization`                       | No       | Organization name                                                                                                                                       |
| `password`                           | No       | Password                                                                                                                                                |
| `private_profile`                    | No       | User's profile is private - true, false (default), or null (will be converted to false)                                                                 |
| `projects_limit`                     | No       | Limit projects each user can create                                                                                                                     |
| `provider`                           | No       | External provider name                                                                                                                                  |
| `public_email`                       | No       | The public email of the user                                                                                                                            |
| `shared_runners_minutes_limit`       | No       | Pipeline minutes quota for this user **(STARTER)**                                                                                                      |
| `skip_reconfirmation`                | No       | Skip reconfirmation - true or false (default)                                                                                                           |
| `skype`                              | No       | Skype ID                                                                                                                                                |
| `theme_id`                           | No       | The GitLab theme for the user (see [the user preference docs](../user/profile/preferences.md#navigation-theme) for more information)                    |
| `twitter`                            | No       | Twitter account                                                                                                                                         |
| `username`                           | No       | Username                                                                                                                                                |
| `website_url`                        | No       | Website URL                                                                                                                                             |

On password update, user will be forced to change it upon next login.
Note, at the moment this method does only return a `404` error,
even in cases where a `409` (Conflict) would be more appropriate.
For example, when renaming the email address to some existing one.

## Delete authentication identity from user

Deletes a user's authentication identity using the provider name associated with that identity. Available only for administrators.

```plaintext
DELETE /users/:id/identities/:provider
```

Parameters:

- `id` (required) - The ID of the user
- `provider` (required) - External provider name

## User deletion

Deletes a user. Available only for administrators.
This returns a `204 No Content` status code if the operation was successfully, `404` if the resource was not found or `409` if the user cannot be soft deleted.

```plaintext
DELETE /users/:id
```

Parameters:

- `id` (required) - The ID of the user
- `hard_delete` (optional) - If true, contributions that would usually be
  [moved to the ghost user](../user/profile/account/delete_account.md#associated-records)
  will be deleted instead, as well as groups owned solely by this user.

## List current user (for normal users)

Gets currently authenticated user.

```plaintext
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
  "public_email": "john@example.com",
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
  "external": false,
  "private_profile": false
}
```

## List current user (for admins)

Parameters:

- `sudo` (optional) - the ID of a user to make the call in their place

```plaintext
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
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "website_url": "",
  "organization": "",
  "job_title": "",
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
  "external": false,
  "private_profile": false,
  "current_sign_in_ip": "196.165.1.102",
  "last_sign_in_ip": "172.127.2.22"
}
```

## User status

Get the status of the currently signed in user.

```plaintext
GET /user/status
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/user/status"
```

Example response:

```json
{
  "emoji":"coffee",
  "message":"I crave coffee :coffee:",
  "message_html": "I crave coffee <gl-emoji title=\"hot beverage\" data-name=\"coffee\" data-unicode-version=\"4.0\">☕</gl-emoji>"
}
```

## Get the status of a user

Get the status of a user.

```plaintext
GET /users/:id_or_username/status
```

| Attribute        | Type   | Required | Description |
| ---------------- | ------ | -------- | ----------- |
| `id_or_username` | string | yes      | The id or username of the user to get a status of |

```shell
curl "https://gitlab.example.com/users/janedoe/status"
```

Example response:

```json
{
  "emoji":"coffee",
  "message":"I crave coffee :coffee:",
  "message_html": "I crave coffee <gl-emoji title=\"hot beverage\" data-name=\"coffee\" data-unicode-version=\"4.0\">☕</gl-emoji>"
}
```

## Set user status

Set the status of the current user.

```plaintext
PUT /user/status
```

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `emoji`   | string | no     | The name of the emoji to use as status, if omitted `speech_balloon` is used. Emoji name can be one of the specified names in the [Gemojione index](https://github.com/bonusly/gemojione/blob/master/config/index.json). |
| `message` | string | no     | The message to set as a status. It can also contain emoji codes. |

When both parameters `emoji` and `message` are empty, the status will be cleared.

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --data "emoji=coffee" --data "message=I crave coffee" https://gitlab.example.com/api/v4/user/status
```

Example responses

```json
{
  "emoji":"coffee",
  "message":"I crave coffee",
  "message_html": "I crave coffee"
}
```

## User counts

Get the counts (same as in top right menu) of the currently signed in user.

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| `merge_requests`   | number | Merge requests that are active and assigned to current user. |

```plaintext
GET /user_counts
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/user_counts"
```

Example response:

```json
{
  "merge_requests": 4
}
```

## List user projects

Please refer to the [List of user projects](projects.md#list-user-projects).

## List SSH keys

Get a list of currently authenticated user's SSH keys.

```plaintext
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

Get a list of a specified user's SSH keys.

```plaintext
GET /users/:id_or_username/keys
```

| Attribute        | Type   | Required | Description |
| ---------------- | ------ | -------- | ----------- |
| `id_or_username` | string | yes      | The id or username of the user to get the SSH keys for. |

## Single SSH key

Get a single key.

```plaintext
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

```plaintext
POST /user/keys
```

Parameters:

- `title` (required) - new SSH Key's title
- `key` (required) - new SSH key

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

```plaintext
POST /users/:id/keys
```

Parameters:

- `id` (required) - id of specified user
- `title` (required) - new SSH Key's title
- `key` (required) - new SSH key

## Delete SSH key for current user

Deletes key owned by currently authenticated user.
This returns a `204 No Content` status code if the operation was successfully or `404` if the resource was not found.

```plaintext
DELETE /user/keys/:key_id
```

Parameters:

- `key_id` (required) - SSH key ID

## Delete SSH key for given user

Deletes key owned by a specified user. Available only for admin.

```plaintext
DELETE /users/:id/keys/:key_id
```

Parameters:

- `id` (required) - id of specified user
- `key_id` (required) - SSH key ID

## List all GPG keys

Get a list of currently authenticated user's GPG keys.

```plaintext
GET /user/gpg_keys
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/user/gpg_keys
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

```plaintext
GET /user/gpg_keys/:key_id
```

Parameters:

| Attribute | Type    | Required | Description |
| --------- | ------- | -------- | ----------- |
| `key_id`  | integer | yes      | The ID of the GPG key |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/user/gpg_keys/1
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

```plaintext
POST /user/gpg_keys
```

Parameters:

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| key       | string | yes      | The new GPG key |

```shell
curl --data "key=-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n\r\nxsBNBFV..."  --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/user/gpg_keys
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

```plaintext
DELETE /user/gpg_keys/:key_id
```

Parameters:

| Attribute | Type    | Required | Description |
| --------- | ------- | -------- | ----------- |
| `key_id`  | integer | yes      | The ID of the GPG key |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/user/gpg_keys/1
```

Returns `204 No Content` on success, or `404 Not found` if the key cannot be found.

## List all GPG keys for given user

Get a list of a specified user's GPG keys. Available only for admins.

```plaintext
GET /users/:id/gpg_keys
```

Parameters:

| Attribute | Type    | Required | Description |
| --------- | ------- | -------- | ----------- |
| `id`      | integer | yes      | The ID of the user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/users/2/gpg_keys
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

```plaintext
GET /users/:id/gpg_keys/:key_id
```

Parameters:

| Attribute | Type    | Required | Description |
| --------- | ------- | -------- | ----------- |
| `id`      | integer | yes      | The ID of the user |
| `key_id`  | integer | yes      | The ID of the GPG key |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/users/2/gpg_keys/1
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

```plaintext
POST /users/:id/gpg_keys
```

Parameters:

| Attribute | Type    | Required | Description |
| --------- | ------- | -------- | ----------- |
| `id`      | integer | yes      | The ID of the user |
| `key_id`  | integer | yes      | The ID of the GPG key |

```shell
curl --data "key=-----BEGIN PGP PUBLIC KEY BLOCK-----\r\n\r\nxsBNBFV..."  --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/users/2/gpg_keys
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

```plaintext
DELETE /users/:id/gpg_keys/:key_id
```

Parameters:

| Attribute | Type    | Required | Description |
| --------- | ------- | -------- | ----------- |
| `id`      | integer | yes      | The ID of the user |
| `key_id`  | integer | yes      | The ID of the GPG key |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/users/2/gpg_keys/1
```

## List emails

Get a list of currently authenticated user's emails.

```plaintext
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

```plaintext
GET /users/:id/emails
```

Parameters:

- `id` (required) - id of specified user

## Single email

Get a single email.

```plaintext
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

```plaintext
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

```plaintext
POST /users/:id/emails
```

Parameters:

- `id` (required) - id of specified user
- `email` (required) - email address
- `skip_confirmation` (optional) - Skip confirmation and assume e-mail is verified - true or false (default)

## Delete email for current user

Deletes email owned by currently authenticated user.
This returns a `204 No Content` status code if the operation was successfully or `404` if the resource was not found.

```plaintext
DELETE /user/emails/:email_id
```

Parameters:

- `email_id` (required) - email ID

## Delete email for given user

Deletes email owned by a specified user. Available only for admin.

```plaintext
DELETE /users/:id/emails/:email_id
```

Parameters:

- `id` (required) - id of specified user
- `email_id` (required) - email ID

## Block user

Blocks the specified user. Available only for admin.

```plaintext
POST /users/:id/block
```

Parameters:

- `id` (required) - id of specified user

Returns:

- `201 OK` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` when trying to block an already blocked user by LDAP synchronization.

## Unblock user

Unblocks the specified user. Available only for admin.

```plaintext
POST /users/:id/unblock
```

Parameters:

- `id` (required) - id of specified user

Will return `201 OK` on success, `404 User Not Found` is user cannot be found or
`403 Forbidden` when trying to unblock a user blocked by LDAP synchronization.

## Deactivate user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/22257) in GitLab 12.4.

Deactivates the specified user. Available only for admin.

```plaintext
POST /users/:id/deactivate
```

Parameters:

- `id` (required) - id of specified user

Returns:

- `201 OK` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` when trying to deactivate a user:
  - Blocked by admin or by LDAP synchronization.
  - That has any activity in past 180 days. These users cannot be deactivated.

## Activate user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/22257) in GitLab 12.4.

Activates the specified user. Available only for admin.

```plaintext
POST /users/:id/activate
```

Parameters:

- `id` (required) - id of specified user

Returns:

- `201 OK` on success.
- `404 User Not Found` if user cannot be found.
- `403 Forbidden` when trying to activate a user blocked by admin or by LDAP synchronization.

### Get user contribution events

Please refer to the [Events API documentation](events.md#get-user-contribution-events)

## Get all impersonation tokens of a user

> Requires admin permissions.

It retrieves every impersonation token of the user. Use the pagination
parameters `page` and `per_page` to restrict the list of impersonation tokens.

```plaintext
GET /users/:user_id/impersonation_tokens
```

Parameters:

| Attribute | Type    | Required | Description                                                |
| --------- | ------- | -------- | ---------------------------------------------------------- |
| `user_id` | integer | yes      | The ID of the user                                         |
| `state`   | string  | no       | filter tokens based on state (`all`, `active`, `inactive`) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/users/42/impersonation_tokens
```

Example response:

```json
[
   {
      "active" : true,
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

```plaintext
GET /users/:user_id/impersonation_tokens/:impersonation_token_id
```

Parameters:

| Attribute                | Type    | Required | Description                       |
| ------------------------ | ------- | -------- | --------------------------------- |
| `user_id`                | integer | yes      | The ID of the user                |
| `impersonation_token_id` | integer | yes      | The ID of the impersonation token |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/users/42/impersonation_tokens/2
```

Example response:

```json
{
   "active" : true,
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
> Token values are returned once. Make sure you save it - you won't be able to access it again.

It creates a new impersonation token. Note that only administrators can do this.
You are only able to create impersonation tokens to impersonate the user and perform
both API calls and Git reads and writes. The user will not see these tokens in their profile
settings page.

```plaintext
POST /users/:user_id/impersonation_tokens
```

| Attribute    | Type    | Required | Description |
| ------------ | ------- | -------- | ----------- |
| `user_id`    | integer | yes      | The ID of the user |
| `name`       | string  | yes      | The name of the impersonation token |
| `expires_at` | date    | no       | The expiration date of the impersonation token in ISO format (`YYYY-MM-DD`)|
| `scopes`     | array   | yes      | The array of scopes of the impersonation token (`api`, `read_user`) |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "name=mytoken" --data "expires_at=2017-04-04" --data "scopes[]=api" https://gitlab.example.com/api/v4/users/42/impersonation_tokens
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

```plaintext
DELETE /users/:user_id/impersonation_tokens/:impersonation_token_id
```

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/users/42/impersonation_tokens/1
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `user_id` | integer | yes | The ID of the user |
| `impersonation_token_id` | integer | yes | The ID of the impersonation token |

### Get user activities (admin only)

NOTE: **Note:** This API endpoint is only available on 8.15 (EE) and 9.1 (CE) and above.

Get the last activity date for all users, sorted from oldest to newest.

The activities that update the timestamp are:

- Git HTTP/SSH activities (such as clone, push)
- User logging in into GitLab
- User visiting pages related to Dashboards, Projects, Issues, and Merge Requests ([introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/54947) in GitLab 11.8)
- User using the API

By default, it shows the activity for all users in the last 6 months, but this can be
amended by using the `from` parameter.

```plaintext
GET /user/activities
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `from` | string | no | Date string in the format YEAR-MONTH-DAY. For example, `2016-03-11`. Defaults to 6 months ago. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/user/activities
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

## User memberships (admin only)

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/20532) in GitLab 12.8.

Lists all projects and groups a user is a member of. This endpoint is available for admins only.
It returns the `source_id`, `source_name`, `source_type` and `access_level` of a membership.
Source can be of type `Namespace` (representing a group) or `Project`. The response represents only direct memberships. Inherited memberships, for example in subgroups, are not included.
Access levels are represented by an integer value. For more details, read about the meaning of [access level values](access_requests.md#valid-access-levels).

```plaintext
GET /users/:id/memberships
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a specified user |
| `type` | string | no | Filter memberships by type. Can be either `Project` or `Namespace` |

Returns:

- `200 OK` on success.
- `404 User Not Found` if user can't be found.
- `403 Forbidden` when not requested by an admin.
- `400 Bad Request` when requested type is not supported.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/users/<user_id>/memberships
```

Example response:

```json
[
  {
    "source_id": 1,
    "source_name": "Project one",
    "source_type": "Project",
    "access_level": "20"
  },
  {
    "source_id": 3,
    "source_name": "Group three",
    "source_type": "Namespace",
    "access_level": "20"
  },
]
```
