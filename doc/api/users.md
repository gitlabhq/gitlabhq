---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Users API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can [manage your account](../user/profile/_index.md) and
[manage other users](../user/profile/account/create_accounts.md) by using the REST API.

## List users

Get a list of users.

Takes [pagination parameters](rest/_index.md#offset-based-pagination) `page` and `per_page` to restrict the list of users.

### As a regular user

> - Keyset pagination [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/419556) in GitLab 16.5.

```plaintext
GET /users
```

Supported attributes:

| Attribute              | Type     | Required | Description |
|:-----------------------|:---------|:---------|:------------|
| `username`             | string   | no       | Get a single user with a specific username. |
| `search`               | string   | no       | Search for users by name, username, or public email. |
| `active`               | boolean  | no       | Filters only active users. Default is `false`. |
| `external`             | boolean  | no       | Filters only external users. Default is `false`. |
| `blocked`              | boolean  | no       | Filters only blocked users. Default is `false`. |
| `humans`               | boolean  | no       | Filters only regular users that are not bot or internal users. Default is `false`. |
| `created_after`        | DateTime | no       | Returns users created after specified time. |
| `created_before`       | DateTime | no       | Returns users created before specified time. |
| `exclude_active`       | boolean  | no       | Filters only non active users. Default is `false`. |
| `exclude_external`     | boolean  | no       | Filters only non external users. Default is `false`. |
| `exclude_humans`       | boolean  | no       | Filters only bot or internal users. Default is `false`. |
| `exclude_internal`     | boolean  | no       | Filters only non internal users. Default is `false`. |
| `without_project_bots` | boolean  | no       | Filters user without project bots. Default is `false`. |

Example response:

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "locked": false,
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

This endpoint supports [keyset pagination](rest/_index.md#keyset-based-pagination). In GitLab 17.0 and later, keyset pagination is required for responses of 50,000 and above.

You can also use `?search=` to search for users by name, username, or public email. For example, `/users?search=John`. When you search for a:

- Public email, you must use the full email address to get an exact match.
- Name or username, you do not have to get an exact match because this is a fuzzy search.

In addition, you can lookup users by username:

```plaintext
GET /users?username=:username
```

For example:

```plaintext
GET /users?username=jack_smith
```

NOTE:
Username search is case insensitive.

In addition, you can filter users based on the states `blocked` and `active`.
It does not support `active=false` or `blocked=false`.

```plaintext
GET /users?active=true
```

```plaintext
GET /users?blocked=true
```

In addition, you can search for external users only with `external=true`.
It does not support `external=false`.

```plaintext
GET /users?external=true
```

GitLab supports bot users such as the [alert bot](../operations/incident_management/integrations.md)
or the [support bot](../user/project/service_desk/configure.md#support-bot-user).
You can exclude the following types of [internal users](../administration/internal_users.md)
from the users' list with the `exclude_internal=true` parameter:

- Alert bot
- Support bot

However, this action does not exclude [bot users for projects](../user/project/settings/project_access_tokens.md#bot-users-for-projects)
or [bot users for groups](../user/group/settings/group_access_tokens.md#bot-users-for-groups).

```plaintext
GET /users?exclude_internal=true
```

In addition, to exclude external users from the users' list, you can use the parameter `exclude_external=true`.

```plaintext
GET /users?exclude_external=true
```

To exclude [bot users for projects](../user/project/settings/project_access_tokens.md#bot-users-for-projects)
and [bot users for groups](../user/group/settings/group_access_tokens.md#bot-users-for-groups), you can use the
parameter `without_project_bots=true`.

```plaintext
GET /users?without_project_bots=true
```

### As an administrator

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - The `created_by` field in the response was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092) in GitLab 15.6.
> - The `scim_identities` field in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/324247) in GitLab 16.1.
> - The `auditors` field in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/418023) in GitLab 16.2.
> - The `email_reset_offered_at` field in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610) in GitLab 16.7.

```plaintext
GET /users
```

You can use all [parameters available for everyone](#as-a-regular-user) plus these additional attributes
available only for administrators.

Supported attributes:

| Attribute          | Type    | Required | Description |
|:-------------------|:--------|:---------|:------------|
| `search`           | string  | no       | Search for users by name, username, public email, or private email. |
| `extern_uid`       | string  | no       | Get a single user with a specific external authentication provider UID. |
| `provider`         | string  | no       | The external provider. |
| `order_by`         | string  | no       | Return users ordered by `id`, `name`, `username`, `created_at`, or `updated_at` fields. Default is `id` |
| `sort`             | string  | no       | Return users sorted in `asc` or `desc` order. Default is `desc` |
| `two_factor`       | string  | no       | Filter users by Two-factor authentication. Filter values are `enabled` or `disabled`. By default it returns all users |
| `without_projects` | boolean | no       | Filter users without projects. Default is `false`, which means that all users are returned, with and without projects. |
| `admins`           | boolean | no       | Return only administrators. Default is `false` |
| `auditors`         | boolean | no       | Return only auditor users. Default is `false`. If not included, it returns all users. Premium and Ultimate only. |
| `saml_provider_id` | number  | no       | Return only users created by the specified SAML provider ID. If not included, it returns all users. Premium and Ultimate only. |
| `skip_ldap`        | boolean | no       | Skip LDAP users. Premium and Ultimate only. |

Example response:

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "email": "john@example.com",
    "name": "John Smith",
    "state": "active",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
    "web_url": "http://localhost:3000/john_smith",
    "created_at": "2012-05-23T08:00:58Z",
    "is_admin": false,
    "bio": "",
    "location": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "discord": "",
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
    "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
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
    "namespace_id": 1,
    "created_by": null,
    "email_reset_offered_at": null
  },
  {
    "id": 2,
    "username": "jack_smith",
    "email": "jack@example.com",
    "name": "Jack Smith",
    "state": "blocked",
    "locked": false,
    "avatar_url": "http://localhost:3000/uploads/user/avatar/2/index.jpg",
    "web_url": "http://localhost:3000/jack_smith",
    "created_at": "2012-05-23T08:01:01Z",
    "is_admin": false,
    "bio": "",
    "location": null,
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "discord": "",
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
    "last_sign_in_ip": "172.127.2.22",
    "namespace_id": 2,
    "created_by": null,
    "email_reset_offered_at": null
  }
]
```

Users on [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see the
`shared_runners_minutes_limit`, `extra_shared_runners_minutes_limit`, `is_auditor`, and `using_license_seat` parameters.

```json
[
  {
    "id": 1,
    ...
    "shared_runners_minutes_limit": 133,
    "extra_shared_runners_minutes_limit": 133,
    "is_auditor": false,
    "using_license_seat": true
    ...
  }
]
```

Users on [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see
the `group_saml` provider option and `provisioned_by_group_id` parameter:

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
    "provisioned_by_group_id": 123789
    ...
  }
]
```

You can also use `?search=` to search for users by name, username, or email. For example, `/users?search=John`. When you search for a:

- Email, you must use the full email address to get an exact match. As an administrator, you can search for both public and private email addresses.
- Name or username, you do not have to get an exact match because this is a fuzzy search.

You can lookup users by external UID and provider:

```plaintext
GET /users?extern_uid=:extern_uid&provider=:provider
```

For example:

```plaintext
GET /users?extern_uid=1234567&provider=github
```

Users on [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) have the `scim` provider available:

```plaintext
GET /users?extern_uid=1234567&provider=scim
```

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

You can use the `created_by` parameter to see if a user account was created:

- [Manually by an administrator](../user/profile/account/create_accounts.md#create-users-in-admin-area).
- As a [project bot user](../user/project/settings/project_access_tokens.md#bot-users-for-projects).

If the returned value is `null`, the account was created by a user who registered an account themselves.

## Get a single user

Get a single user.

### As a regular user

Get a single user as a regular user.

Prerequisites:

- You must be signed in to use this endpoint.

```plaintext
GET /users/:id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of a user |

Example response:

```json
{
  "id": 1,
  "username": "john_smith",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "bio": "",
  "bot": false,
  "location": null,
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "website_url": "",
  "organization": "",
  "job_title": "Operations Specialist",
  "pronouns": "he/him",
  "work_information": null,
  "followers": 1,
  "following": 1,
  "local_time": "3:38 PM",
  "is_followed": false
}
```

### As an administrator

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - The `created_by` field in the response was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092) in GitLab 15.6.
> - The `email_reset_offered_at` field in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610) in GitLab 16.7.

Get a single user as an administrator.

```plaintext
GET /users/:id
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of a user |

Example response:

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": false,
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "website_url": "",
  "organization": "",
  "job_title": "Operations Specialist",
  "pronouns": "he/him",
  "work_information": null,
  "followers": 1,
  "following": 1,
  "local_time": "3:38 PM",
  "last_sign_in_at": "2012-06-01T11:41:01Z",
  "confirmed_at": "2012-05-23T09:05:22Z",
  "theme_id": 1,
  "last_activity_on": "2012-05-23",
  "color_scheme_id": 2,
  "projects_limit": 100,
  "current_sign_in_at": "2012-06-02T06:36:55Z",
  "note": "DMCA Request: 2018-11-05 | DMCA Violation | Abuse | https://gitlab.zendesk.com/agent/tickets/123",
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
  "commit_email": "john-codes@example.com",
  "current_sign_in_ip": "196.165.1.102",
  "last_sign_in_ip": "172.127.2.22",
  "plan": "gold",
  "trial": true,
  "sign_in_count": 1337,
  "namespace_id": 1,
  "created_by": null,
  "email_reset_offered_at": null
}
```

NOTE:
The `plan` and `trial` parameters are only available on GitLab Enterprise Edition.

Users on [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see
the `shared_runners_minutes_limit`, `is_auditor`, and `extra_shared_runners_minutes_limit` parameters.

```json
{
  "id": 1,
  "username": "john_smith",
  "is_auditor": false,
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  ...
}
```

Users on [GitLab.com Premium or Ultimate](https://about.gitlab.com/pricing/) also
see the `group_saml` option and `provisioned_by_group_id` parameter:

```json
{
  "id": 1,
  "username": "john_smith",
  "shared_runners_minutes_limit": 133,
  "extra_shared_runners_minutes_limit": 133,
  "identities": [
    {"provider": "github", "extern_uid": "2435223452345"},
    {"provider": "bitbucket", "extern_uid": "john.smith"},
    {"provider": "google_oauth2", "extern_uid": "8776128412476123468721346"},
    {"provider": "group_saml", "extern_uid": "123789", "saml_provider_id": 10}
  ],
  "provisioned_by_group_id": 123789
  ...
}
```

Users on [GitLab.com Premium or Ultimate](https://about.gitlab.com/pricing/) also
see the `scim_identities` parameter:

```json
{
  ...
  "extra_shared_runners_minutes_limit": null,
  "scim_identities": [
      {"extern_uid": "2435223452345", "group_id": "3", "active": true},
      {"extern_uid": "john.smith", "group_id": "42", "active": false}
    ]
  ...
}
```

Administrators can use the `created_by` parameter to see if a user account was created:

- [Manually by an administrator](../user/profile/account/create_accounts.md#create-users-in-admin-area).
- As a [project bot user](../user/project/settings/project_access_tokens.md#bot-users-for-projects).

If the returned value is `null`, the account was created by a user who registered an account themselves.

You can include the user's [custom attributes](custom_attributes.md) in the response with:

```plaintext
GET /users/:id?with_custom_attributes=true
```

## Get the current user

Get the current user.

### As a regular user

Get your user details.

```plaintext
GET /user
```

Example response:

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "discord": "",
  "website_url": "",
  "organization": "",
  "job_title": "",
  "pronouns": "he/him",
  "bot": false,
  "work_information": null,
  "followers": 0,
  "following": 0,
  "local_time": "3:38 PM",
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
  "commit_email": "admin@example.com",
}
```

Users on [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see the `shared_runners_minutes_limit`, `extra_shared_runners_minutes_limit` parameters.

### As an administrator

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - The `created_by` field in the response was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93092) in GitLab 15.6.
> - The `email_reset_offered_at` field in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137610) in GitLab 16.7.

Get your user details, or the details of another user.

```plaintext
GET /user
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `sudo`    | integer | no       | ID of a user to make the call in their place |

```json
{
  "id": 1,
  "username": "john_smith",
  "email": "john@example.com",
  "name": "John Smith",
  "state": "active",
  "locked": false,
  "avatar_url": "http://localhost:3000/uploads/user/avatar/1/index.jpg",
  "web_url": "http://localhost:3000/john_smith",
  "created_at": "2012-05-23T08:00:58Z",
  "is_admin": true,
  "bio": "",
  "location": null,
  "public_email": "john@example.com",
  "skype": "",
  "linkedin": "",
  "twitter": "",
  "discord": "",
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
  "commit_email": "john-codes@example.com",
  "current_sign_in_ip": "196.165.1.102",
  "last_sign_in_ip": "172.127.2.22",
  "namespace_id": 1,
  "created_by": null,
  "email_reset_offered_at": null,
  "note": null
}
```

Users on [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) also see these
parameters:

- `shared_runners_minutes_limit`
- `extra_shared_runners_minutes_limit`
- `is_auditor`
- `provisioned_by_group_id`
- `using_license_seat`

## Create a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - Ability to create an auditor user was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366404) in GitLab 15.3.

Create a user.

Prerequisites:

- You must be an administrator.

When you create a user, you must specify at least one of the following:

- `password`
- `reset_password`
- `force_random_password`

If `reset_password` and `force_random_password` are both `false`, then `password` is required.

`force_random_password` and `reset_password` take priority over `password`. Also, `reset_password` and
`force_random_password` can be used together.

NOTE:
`private_profile` defaults to the value of the
[Set profiles of new users to private by default](../administration/settings/account_and_limit_settings.md#set-profiles-of-new-users-to-private-by-default) setting.
`bio` defaults to `""` instead of `null`.

```plaintext
POST /users
```

Supported attributes:

| Attribute                            | Required | Description |
|:-------------------------------------|:---------|:------------|
| `admin`                              | No       | User is an administrator. Valid values are `true` or `false`. Defaults to false. |
| `auditor`                            | No       | User is an auditor. Valid values are `true` or `false`. Defaults to false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366404) in GitLab 15.3. Premium and Ultimate only. |
| `avatar`                             | No       | Image file for user's avatar |
| `bio`                                | No       | User's biography |
| `can_create_group`                   | No       | User can create top-level groups - true or false |
| `color_scheme_id`                    | No       | User's color scheme for the file viewer (for more information, see the [user preference documentation](../user/profile/preferences.md#change-the-syntax-highlighting-theme)) |
| `commit_email`                       | No       | User's commit email address |
| `email`                              | Yes      | Email       |
| `extern_uid`                         | No       | External UID |
| `external`                           | No       | Flags the user as external - true or false (default) |
| `extra_shared_runners_minutes_limit` | No       | Can be set by administrators only. Additional compute minutes for this user. Premium and Ultimate only. |
| `force_random_password`              | No       | Set user password to a random value - true or false (default) |
| `group_id_for_saml`                  | No       | ID of group where SAML has been configured |
| `linkedin`                           | No       | LinkedIn    |
| `location`                           | No       | User's location |
| `name`                               | Yes      | Name        |
| `note`                               | No       | Administrator notes for this user |
| `organization`                       | No       | Organization name |
| `password`                           | No       | Password    |
| `private_profile`                    | No       | User's profile is private - true or false. The default value is determined by [a setting](../administration/settings/account_and_limit_settings.md#set-profiles-of-new-users-to-private-by-default). |
| `projects_limit`                     | No       | Number of projects user can create |
| `pronouns`                           | No       | User's pronouns |
| `provider`                           | No       | External provider name |
| `public_email`                       | No       | User's public email address |
| `reset_password`                     | No       | Send user password reset link - true or false(default) |
| `shared_runners_minutes_limit`       | No       | Can be set by administrators only. Maximum number of monthly compute minutes for this user. Can be `nil` (default; inherit system default), `0` (unlimited), or `> 0`. Premium and Ultimate only. |
| `skip_confirmation`                  | No       | Skip confirmation - true or false (default) |
| `skype`                              | No       | Skype ID    |
| `theme_id`                           | No       | GitLab theme for the user (for more information, see the [user preference documentation](../user/profile/preferences.md#change-the-color-theme) for more information) |
| `twitter`                            | No       | X (formerly Twitter) account |
| `discord`                            | No       | Discord account |
| `username`                           | Yes      | Username    |
| `view_diffs_file_by_file`            | No       | Flag indicating the user sees only one file diff per page |
| `website_url`                        | No       | Website URL |

## Modify a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - Ability to modify an auditor user was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366404) in GitLab 15.3.

Modify an existing user.

Prerequisites:

- You must be an administrator.

The `email` field is the user's primary email address. You can only change this field to an already-added secondary
email address for that user. To add more email addresses to the same user, use the [add email endpoint](user_email_addresses.md#add-an-email-address).

```plaintext
PUT /users/:id
```

Supported attributes:

| Attribute                            | Required | Description |
|:-------------------------------------|:---------|:------------|
| `admin`                              | No       | User is an administrator. Valid values are `true` or `false`. Defaults to false. |
| `auditor`                            | No       | User is an auditor. Valid values are `true` or `false`. Defaults to false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366404) in GitLab 15.3.(default) Premium and Ultimate only. |
| `avatar`                             | No       | Image file for user's avatar |
| `bio`                                | No       | User's biography |
| `can_create_group`                   | No       | User can create groups - true or false |
| `color_scheme_id`                    | No       | User's color scheme for the file viewer (for more information, see the [user preference documentation](../user/profile/preferences.md#change-the-syntax-highlighting-theme) for more information) |
| `commit_email`                       | No       | User's commit email. Set to `_private` to use the private commit email. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375148) in GitLab 15.5. |
| `email`                              | No       | Email       |
| `extern_uid`                         | No       | External UID |
| `external`                           | No       | Flags the user as external - true or false (default) |
| `extra_shared_runners_minutes_limit` | No       | Can be set by administrators only. Additional compute minutes for this user. Premium and Ultimate only. |
| `group_id_for_saml`                  | No       | ID of group where SAML has been configured |
| `id`                                 | Yes      | ID of the user |
| `linkedin`                           | No       | LinkedIn    |
| `location`                           | No       | User's location |
| `name`                               | No       | Name        |
| `note`                               | No       | Administration notes for this user |
| `organization`                       | No       | Organization name |
| `password`                           | No       | Password    |
| `private_profile`                    | No       | User's profile is private - true or false. |
| `projects_limit`                     | No       | Limit projects each user can create |
| `pronouns`                           | No       | Pronouns    |
| `provider`                           | No       | External provider name |
| `public_email`                       | No       | Public email of the user (must be already verified) |
| `shared_runners_minutes_limit`       | No       | Can be set by administrators only. Maximum number of monthly compute minutes for this user. Can be `nil` (default; inherit system default), `0` (unlimited) or `> 0`. Premium and Ultimate only. |
| `skip_reconfirmation`                | No       | Skip reconfirmation - true or false (default) |
| `skype`                              | No       | Skype ID    |
| `theme_id`                           | No       | GitLab theme for the user (for more information, see the [user preference documentation](../user/profile/preferences.md#change-the-color-theme) for more information) |
| `twitter`                            | No       | X (formerly Twitter) account |
| `discord`                            | No       | Discord account |
| `username`                           | No       | Username    |
| `view_diffs_file_by_file`            | No       | Flag indicating the user sees only one file diff per page |
| `website_url`                        | No       | Website URL |

If you update a user's password, they are forced to change it when they next sign in.

Returns a `404` error, even in cases where a `409` (Conflict) would be more appropriate.
For example, when renaming the email address to an existing one.

## Delete a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Delete a user.

Prerequisites:

- You must be an administrator.

Returns:

- `204 No Content` status code if the operation was successful.
- `404` if the resource was not found.
- `409` if the user cannot be soft deleted.

```plaintext
DELETE /users/:id
```

Supported attributes:

| Attribute     | Type    | Required | Description |
|:--------------|:--------|:---------|:------------|
| `id`          | integer | yes      | ID of a user |
| `hard_delete` | boolean | no       | If true, contributions that would usually be [moved to Ghost User](../user/profile/account/delete_account.md#associated-records) are deleted instead, and also groups owned solely by this user. |

## Get your user status

Get your user status.

Prerequisites:

- You must be authenticated.

```plaintext
GET /user/status
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/user/status"
```

Example response:

```json
{
  "emoji":"coffee",
  "availability":"busy",
  "message":"I crave coffee :coffee:",
  "message_html": "I crave coffee <gl-emoji title=\"hot beverage\" data-name=\"coffee\" data-unicode-version=\"4.0\">☕</gl-emoji>",
  "clear_status_at": null
}
```

## Get the status of a user

Get the status of a user. You can access this endpoint without authentication.

```plaintext
GET /users/:id_or_username/status
```

Supported attributes:

| Attribute        | Type   | Required | Description |
|:-----------------|:-------|:---------|:------------|
| `id_or_username` | string | yes      | ID or username of the user to get a status of |

Example request:

```shell
curl "https://gitlab.example.com/users/<username>/status"
```

Example response:

```json
{
  "emoji":"coffee",
  "availability":"busy",
  "message":"I crave coffee :coffee:",
  "message_html": "I crave coffee <gl-emoji title=\"hot beverage\" data-name=\"coffee\" data-unicode-version=\"4.0\">☕</gl-emoji>",
  "clear_status_at": null
}
```

## Set your user status

Set your user status.

Prerequisites:

- You must be authenticated.

```plaintext
PUT /user/status
PATCH /user/status
```

Supported attributes:

| Attribute            | Type   | Required | Description |
|:---------------------|:-------|:---------|:------------|
| `emoji`              | string | no       | Name of the emoji to use as status. If omitted `speech_balloon` is used. Emoji name can be one of the specified names in the [Gemojione index](https://github.com/bonusly/gemojione/blob/master/config/index.json). |
| `message`            | string | no       | Message to set as a status. It can also contain emoji codes. Cannot exceed 100 characters. |
| `clear_status_after` | string | no       | Automatically clean up the status after a given time interval, allowed values: `30_minutes`, `3_hours`, `8_hours`, `1_day`, `3_days`, `7_days`, `30_days` |

Difference between `PUT` and `PATCH`:

- When using `PUT` any parameters that are not passed are set to `null` and therefore cleared.
- When using `PATCH` any parameters that are not passed are ignored. Explicitly pass `null` to clear a field.

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --data "clear_status_after=1_day" --data "emoji=coffee" \
     --data "message=I crave coffee" "https://gitlab.example.com/api/v4/user/status"
```

Example response:

```json
{
  "emoji":"coffee",
  "message":"I crave coffee",
  "message_html": "I crave coffee",
  "clear_status_at":"2021-02-15T10:49:01.311Z"
}
```

## Get your user preferences

Get your user preferences.

Prerequisites:

- You must be authenticated.

```plaintext
GET /user/preferences
```

Example response:

```json
{
  "id": 1,
  "user_id": 1,
  "view_diffs_file_by_file": true,
  "show_whitespace_in_diffs": false,
  "pass_user_identities_to_ci_jwt": false
}
```

## Update your user preferences

Update your user preferences.

Prerequisites:

- You must be authenticated.

```plaintext
PUT /user/preferences
```

```json
{
  "id": 1,
  "user_id": 1,
  "view_diffs_file_by_file": true,
  "show_whitespace_in_diffs": false,
  "pass_user_identities_to_ci_jwt": false
}
```

Supported attributes:

| Attribute                        | Required | Description |
|:---------------------------------|:---------|:------------|
| `view_diffs_file_by_file`        | Yes      | Flag indicating the user sees only one file diff per page. |
| `show_whitespace_in_diffs`       | Yes      | Flag indicating the user sees whitespace changes in diffs. |
| `pass_user_identities_to_ci_jwt` | Yes      | Flag indicating the user passes their external identities as CI information. This attribute does not contain enough information to identify or authorize the user in an external system. The attribute is internal to GitLab, and must not be passed to third-party services. For more information and examples, see [Token Payload](../ci/secrets/id_token_authentication.md#token-payload). |

## Upload an avatar for yourself

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148130) in GitLab 17.0.

Upload an avatar for yourself.

Prerequisites:

- You must be authenticated.

```plaintext
PUT /user/avatar
```

Supported attributes:

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `avatar`  | string | Yes      | The file to be uploaded. The ideal image size is 192 x 192 pixels. The maximum file size allowed is 200 KiB. |

To upload an avatar from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to an image file on your file system and be
preceded by `@`. For example:

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "avatar=@avatar.png" \
     --url "https://gitlab.example.com/api/v4/user/avatar"
```

Example response:

```json
{
  "avatar_url": "http://gdk.test:3000/uploads/-/system/user/avatar/76/avatar.png",
}
```

Returns:

- `200` if successful.
- `400 Bad Request` for file sizes greater than 200 KiB.

## Get a count of your assigned issues, merge requests, and reviews

Get a count of your assigned issues, merge requests, and reviews.

Prerequisites:

- You must be authenticated.

Supported attributes:

| Attribute                         | Type   | Description |
|:----------------------------------|:-------|:------------|
| `assigned_issues`                 | number | Number of issues that are open and assigned to the current user. |
| `assigned_merge_requests`         | number | Number of merge requests that are active and assigned to the current user. |
| `merge_requests`                  | number | [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50026) in GitLab 13.8. Equivalent to and replaced by `assigned_merge_requests`. |
| `review_requested_merge_requests` | number | Number of merge requests that the current user has been requested to review. |
| `todos`                           | number | Number of pending to-do items for current user. |

```plaintext
GET /user_counts
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/user_counts"
```

Example response:

```json
{
  "merge_requests": 4,
  "assigned_issues": 15,
  "assigned_merge_requests": 11,
  "review_requested_merge_requests": 0,
  "todos": 1
}
```

## Get a count of a user's projects, groups, issues, and merge requests

Get a list of a user's count of:

- Projects.
- Groups.
- Issues.
- Merge requests.

Administrators can query any user, but non-administrators can only query themselves.

```plaintext
GET /users/:id/associations_count
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of a user |

Example response:

```json
{
  "groups_count": 2,
  "projects_count": 3,
  "issues_count": 8,
  "merge_requests_count": 5
}
```

## List a user's activity

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Prerequisites:

- You must be an administrator to view the activity of users with private profiles.

Get the last activity date for users with public profiles, sorted from oldest to newest.

The activities that update the user event timestamps (`last_activity_on` and `current_sign_in_at`) are:

- Git HTTP/SSH activities (such as clone, push)
- User logging in to GitLab
- User visiting pages related to dashboards, projects, issues, and merge requests
- User using the API
- User using the GraphQL API

By default, it shows the activity for users with public profiles in the last 6 months, but this can be
amended by using the `from` parameter.

```plaintext
GET /user/activities
```

Supported attributes:

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `from`    | string | no       | Date string in the format `YEAR-MM-DD`. For example, `2016-03-11`. Defaults to 6 months ago. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/user/activities"
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

`last_activity_at` is deprecated. Use `last_activity_on` instead.

## List projects and groups that a user is a member of

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Prerequisites:

- You must be an administrator.

Lists all projects and groups a user is a member of.

Returns the `source_id`, `source_name`, `source_type`, and `access_level` of a membership.
Source can be of type `Namespace` (representing a group) or `Project`. The response represents only direct memberships. Inherited memberships, for example in subgroups, are not included.
Access levels are represented by an integer value. For more details, read about the meaning of [access level values](access_requests.md#valid-access-levels).

```plaintext
GET /users/:id/memberships
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of a specified user |
| `type`    | string  | no       | Filter memberships by type. Can be either `Project` or `Namespace` |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/:user_id/memberships"
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
  }
]
```

Returns:

- `200 OK` on success.
- `404 User Not Found` if user can't be found.
- `403 Forbidden` when not requested by an administrator.
- `400 Bad Request` when requested type is not supported.

## Disable two-factor authentication for a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/295260) in GitLab 15.2.

Prerequisites:

- You must be an administrator.

Disables two-factor authentication (2FA) for the specified user.

Administrators cannot disable 2FA for their own user account or other administrators using the API. Instead, they can disable an
administrator's 2FA [using the Rails console](../security/two_factor_authentication.md#for-a-single-user).

```plaintext
PATCH /users/:id/disable_two_factor
```

Supported attributes:

| Attribute | Type    | Required | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | yes      | ID of the user |

Example request:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/1/disable_two_factor"
```

Returns:

- `204 No content` on success.
- `400 Bad request` if two factor authentication is not enabled for the specified user.
- `403 Forbidden` if not authenticated as an administrator.
- `404 User Not Found` if user cannot be found.

## Create a runner linked to a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Create a runner linked to the current user.

Prerequisites:

- You must be an administrator or have the Owner role for the target namespace or project.
- For `instance_type`, you must be an administrator of the GitLab instance.
- For `group_type` or `project_type` with an Owner role, an administrator must not have enabled [restrict runner registration](../administration/settings/continuous_integration.md#restrict-runner-registration-by-all-users-in-an-instance).
- An access token with the `create_runner` scope.

Be sure to copy or save the `token` in the response, the value cannot be retrieved again.

```plaintext
POST /user/runners
```

Supported attributes:

| Attribute          | Type         | Required | Description |
|:-------------------|:-------------|:---------|:------------|
| `runner_type`      | string       | yes      | Specifies the scope of the runner; `instance_type`, `group_type`, or `project_type`. |
| `group_id`         | integer      | no       | The ID of the group that the runner is created in. Required if `runner_type` is `group_type`. |
| `project_id`       | integer      | no       | The ID of the project that the runner is created in. Required if `runner_type` is `project_type`. |
| `description`      | string       | no       | Description of the runner. |
| `paused`           | boolean      | no       | Specifies if the runner should ignore new jobs. |
| `locked`           | boolean      | no       | Specifies if the runner should be locked for the current project. |
| `run_untagged`     | boolean      | no       | Specifies if the runner should handle untagged jobs. |
| `tag_list`         | string array | no       | A list of runner tags. |
| `access_level`     | string       | no       | The access level of the runner; `not_protected` or `ref_protected`. |
| `maximum_timeout`  | integer      | no       | Maximum timeout that limits the amount of time (in seconds) that runners can run jobs. |
| `maintenance_note` | string       | no       | Free-form maintenance notes for the runner (1024 characters). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "runner_type=instance_type" \
     "https://gitlab.example.com/api/v4/user/runners"
```

Example response:

```json
{
    "id": 9171,
    "token": "<access-token>",
    "token_expires_at": null
}
```

## Delete authentication identity from a user

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Delete a user's authentication identity using the provider name associated with that identity.

Prerequisites:

- You must be an administrator.

```plaintext
DELETE /users/:id/identities/:provider
```

Supported attributes:

| Attribute  | Type    | Required | Description |
|:-----------|:--------|:---------|:------------|
| `id`       | integer | yes      | ID of a user |
| `provider` | string  | yes      | External provider name |
