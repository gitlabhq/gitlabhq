---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group enterprise users API

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

Use this API to interact with enterprise users accounts. For more information, see [enterprise users](../user/enterprise_user/index.md).

This API endpoint only works for top-level groups. Users do not have to be a member of the group.

Prerequisites:

- You must have the Owner role in the top-level group.

## List enterprise users

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/438366) in GitLab 17.7.

Gets a list of enterprise users for a given top-level group.

Takes [pagination parameters](rest/index.md#offset-based-pagination) `page` and `per_page` to restrict the list of enterprise users.

```plaintext
GET /groups/:id/enterprise_users
```

Parameters:

| Attribute        | Type           | Required | Description |
|:-----------------|:---------------|:---------|:------------|
| `id`             | integer/string | yes      | ID or [URL-encoded path](rest/index.md#namespaced-paths) of a top-level group. |
| `username`       | string         | no       | Return single user with a specific username. |
| `search`         | string         | no       | Search users by name, email, username. |
| `active`         | boolean        | no       | Return only active users. |
| `blocked`        | boolean        | no       | Return only blocked users. |
| `created_after`  | datetime       | no       | Return users created after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `created_before` | datetime       | no       | Return users created before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). |
| `two_factor`     | string         | no       | Filter users by two-factor authentication (2FA). Filter values are `enabled` or `disabled`. By default it returns all users. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/:id/enterprise_users"
```

Example response:

```json
[
  {
    "id": 66,
    "username": "user22",
    "name": "Sidney Jones22",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/xxx?s=80&d=identicon",
    "web_url": "http://my.gitlab.com/user22",
    "created_at": "2021-09-10T12:48:22.381Z",
    "bio": "",
    "location": null,
    "public_email": "",
    "skype": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "job_title": "",
    "pronouns": null,
    "bot": false,
    "work_information": null,
    "followers": 0,
    "following": 0,
    "local_time": null,
    "last_sign_in_at": null,
    "confirmed_at": "2021-09-10T12:48:22.330Z",
    "last_activity_on": null,
    "email": "user22@example.org",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": null,
    "identities": [
      {
        "provider": "group_saml",
        "extern_uid": "2435223452345",
        "saml_provider_id": 1
      }
    ],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "commit_email": "user22@example.org",
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null,
    "scim_identities": [
      {
        "extern_uid": "2435223452345",
        "group_id": 1,
        "active": true
      }
    ]
  },
  ...
]
```
