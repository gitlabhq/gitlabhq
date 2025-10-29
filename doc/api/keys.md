---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Keys API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to retrieve information about [SSH keys](../user/ssh.md). Queries about
deploy key fingerprints also retrieve information about the projects using that key.

If you use a SHA256 fingerprint in an API call, you should URL-encode the fingerprint.

## Get SSH key with user by ID

Prerequisites:

- You must have administrator access to the instance.

You can get an SSH key and information about the user who owns the key.

```plaintext
GET /keys/:id
```

Supported attributes:

| Attribute | Type    | Required | Description           |
|-----------|---------|----------|-----------------------|
| `id`      | integer | Yes      | ID of an SSH key. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute           | Type    | Description |
|---------------------|---------|-------------|
| `created_at`        | string  | Creation date and time of the SSH key in ISO 8601 format. |
| `expires_at`        | string  | Expiration date and time of the SSH key in ISO 8601 format. |
| `id`                | integer | ID of the SSH key. |
| `key`               | string  | SSH key content. |
| `last_used_at`      | string  | Last usage date and time of the SSH key in ISO 8601 format. |
| `title`             | string  | Title of the SSH key. |
| `usage_type`        | string  | Usage type of the SSH key (for example, `auth` or `auth_and_signing`). |
| `user`              | object  | User associated with the SSH key. |
| `user.avatar_url`   | string  | URL of the user's avatar. |
| `user.bio`          | string  | Biography of the user. |
| `user.created_at`   | string  | Creation date and time of the user account in ISO 8601 format. |
| `user.id`           | integer | ID of the user. |
| `user.linkedin`     | string  | LinkedIn profile URL of the user. |
| `user.location`     | string  | Location of the user. |
| `user.name`         | string  | Name of the user. |
| `user.organization` | string  | Organization of the user. |
| `user.public_email` | string  | Public email address of the user. |
| `user.state`        | string  | State of the user. |
| `user.twitter`      | string  | Twitter profile URL of the user. |
| `user.username`     | string  | Username of the user. |
| `user.web_url`      | string  | URL of the user's profile. |
| `user.website_url`  | string  | Website URL of the user. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys/1"
```

Example response:

```json
{
  "id": 1,
  "title": "Sample key 25",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1256k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2015-09-03T07:24:44.627Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "name": "John Smith",
    "username": "john_smith",
    "id": 25,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/cfa35b8cd2ec278026357769582fa563?s=40\u0026d=identicon",
    "web_url": "http://localhost:3000/john_smith",
    "created_at": "2015-09-03T07:24:01.670Z",
    "bio": null,
    "location": null,
    "public_email": "john@example.com",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2015-09-03T07:24:01.670Z",
    "confirmed_at": "2015-09-03T07:24:01.670Z",
    "last_activity_on": "2015-09-03",
    "email": "john@example.com",
    "theme_id": 2,
    "color_scheme_id": 1,
    "projects_limit": 10,
    "current_sign_in_at": null,
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": null
  }
}
```

## Get user by SSH key fingerprint

Prerequisites:

- You must have administrator access to the instance.

You can search for a user that owns a specific SSH key.

```plaintext
GET /keys
```

Supported attributes:

| Attribute     | Type   | Required | Description                    |
|---------------|--------|----------|--------------------------------|
| `fingerprint` | string | Yes      | Fingerprint of an SSH key. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                 | Type    | Description |
|---------------------------|---------|-------------|
| `created_at`              | string  | Creation date and time of the SSH key in ISO 8601 format. |
| `expires_at`              | string  | Expiration date and time of the SSH key in ISO 8601 format. |
| `id`                      | integer | ID of the SSH key. |
| `key`                     | string  | SSH key content. |
| `last_used_at`            | string  | Last usage date and time of the SSH key in ISO 8601 format. |
| `title`                   | string  | Title of the SSH key. |
| `usage_type`              | string  | Usage type of the SSH key (for example, `auth` or `auth_and_signing`). |
| `user`                    | object  | User associated with the SSH key. |
| `user.avatar_url`         | string  | URL of the user's avatar. |
| `user.bio`                | string  | Biography of the user. |
| `user.can_create_group`   | boolean | If `true`, the user can create groups. |
| `user.can_create_project` | boolean | If `true`, the user can create projects. |
| `user.color_scheme_id`    | integer | Color scheme ID of the user. |
| `user.confirmed_at`       | string  | Confirmation date and time of the user in ISO 8601 format. |
| `user.created_at`         | string  | Creation date and time of the user account in ISO 8601 format. |
| `user.current_sign_in_at` | string  | Current sign-in date and time of the user in ISO 8601 format. |
| `user.email`              | string  | Email address of the user. |
| `user.external`           | boolean | If `true`, the user is external. |
| `user.id`                 | integer | ID of the user. |
| `user.identities`         | array   | Identities associated with the user. |
| `user.last_activity_on`   | string  | Last activity date of the user. |
| `user.last_sign_in_at`    | string  | Last sign-in date and time of the user in ISO 8601 format. |
| `user.linkedin`           | string  | LinkedIn profile URL of the user. |
| `user.location`           | string  | Location of the user. |
| `user.name`               | string  | Name of the user. |
| `user.organization`       | string  | Organization of the user. |
| `user.private_profile`    | boolean | If `true`, the user's profile is private. |
| `user.projects_limit`     | integer | Project limit of the user. |
| `user.public_email`       | string  | Public email address of the user. |
| `user.state`              | string  | State of the user account. |
| `user.theme_id`           | integer | Theme ID of the user. |
| `user.twitter`            | string  | Twitter profile URL of the user. |
| `user.two_factor_enabled` | boolean | If `true`, two-factor authentication is enabled for the user. |
| `user.username`           | string  | Username of the user. |
| `user.web_url`            | string  | URL of the user's profile. |
| `user.website_url`        | string  | Website URL of the user. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1"
```

Example response:

```json
{
  "id": 1,
  "title": "Sample key 1",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1016k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2019-11-14T15:11:13.222Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://0.0.0.0:3000/root",
    "created_at": "2019-11-14T15:09:34.831Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2019-11-16T22:41:26.663Z",
    "confirmed_at": "2019-11-14T15:09:34.575Z",
    "last_activity_on": "2019-11-20",
    "email": "admin@example.com",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": "2019-11-19T14:42:18.078Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  }
}
```

## Get user by deploy key fingerprint

Deploy keys are bound to the creating user. When you query with a deploy key fingerprint, you get additional information about the projects using that key.

```plaintext
GET /keys
```

Supported attributes:

| Attribute     | Type   | Required | Description                        |
|---------------|--------|----------|------------------------------------|
| `fingerprint` | string | Yes      | Fingerprint of a deploy key.   |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                                 | Type    | Description |
|-------------------------------------------|---------|-------------|
| `created_at`                              | string  | Creation date and time of the deploy key in ISO 8601 format. |
| `deploy_keys_projects`                    | array   | Deploy key projects information. |
| `deploy_keys_projects[].can_push`         | boolean | If `true`, the deploy key can push to the project. |
| `deploy_keys_projects[].created_at`       | string  | Creation date and time in ISO 8601 format. |
| `deploy_keys_projects[].deploy_key_id`    | integer | ID of the deploy key. |
| `deploy_keys_projects[].id`               | integer | ID of the deploy key project relationship. |
| `deploy_keys_projects[].project_id`       | integer | ID of the project. |
| `deploy_keys_projects[].updated_at`       | string  | Last update date and time in ISO 8601 format. |
| `expires_at`                              | string  | Expiration date and time of the deploy key in ISO 8601 format. |
| `id`                                      | integer | ID of the deploy key. |
| `key`                                     | string  | Deploy key content. |
| `last_used_at`                            | string  | Last usage date and time of the deploy key in ISO 8601 format. |
| `title`                                   | string  | Title of the deploy key. |
| `usage_type`                              | string  | Usage type of the deploy key (for example, `auth` or `auth_and_signing`). |
| `user`                                    | object  | User associated with the deploy key. |
| `user.avatar_url`                         | string  | URL of the user's avatar. |
| `user.bio`                                | string  | Biography of the user. |
| `user.can_create_group`                   | boolean | If `true`, the user can create groups. |
| `user.can_create_project`                 | boolean | If `true`, the user can create projects. |
| `user.color_scheme_id`                    | integer | Color scheme ID of the user. |
| `user.confirmed_at`                       | string  | Confirmation date and time of the user in ISO 8601 format. |
| `user.created_at`                         | string  | Creation date and time of the user account in ISO 8601 format. |
| `user.current_sign_in_at`                 | string  | Current sign-in date and time of the user in ISO 8601 format. |
| `user.email`                              | string  | Email address of the user. |
| `user.external`                           | boolean | If `true`, the user is external. |
| `user.extra_shared_runners_minutes_limit` | integer | Extra shared runners minutes limit of the user. |
| `user.id`                                 | integer | ID of the user. |
| `user.identities`                         | array   | Identities associated with the user. |
| `user.last_activity_on`                   | string  | Last activity date of the user. |
| `user.last_sign_in_at`                    | string  | Last sign-in date and time of the user in ISO 8601 format. |
| `user.linkedin`                           | string  | LinkedIn profile URL of the user. |
| `user.location`                           | string  | Location of the user. |
| `user.name`                               | string  | Name of the user. |
| `user.organization`                       | string  | Organization of the user. |
| `user.private_profile`                    | boolean | If `true`, the user's profile is private. |
| `user.projects_limit`                     | integer | Project limit of the user. |
| `user.public_email`                       | string  | Public email address of the user. |
| `user.shared_runners_minutes_limit`       | integer | Shared runners minutes limit of the user. |
| `user.state`                              | string  | State of the user account. |
| `user.theme_id`                           | integer | Theme ID of the user. |
| `user.twitter`                            | string  | Twitter profile URL of the user. |
| `user.two_factor_enabled`                 | boolean | If `true`, two-factor authentication is enabled for the user. |
| `user.username`                           | string  | Username of the user. |
| `user.web_url`                            | string  | URL of the user's profile. |
| `user.website_url`                        | string  | Website URL of the user. |

Example request with MD5 fingerprint:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=ba:81:59:68:d7:6c:cd:02:02:bf:6a:9b:55:4e:af:d1"
```

Example request with SHA256 fingerprint (URL-encoded):

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/keys?fingerprint=SHA256%3AnUhzNyftwADy8AH3wFY31tAKs7HufskYTte2aXo%2FlCg"
```

In the SHA256 example, `/` is represented by `%2F` and `:` is represented by `%3A`.

Example response:

```json
{
  "id": 1,
  "title": "Sample key 1",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt1016k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2019-11-14T15:11:13.222Z",
  "expires_at": "2020-05-05T00:00:00.000Z",
  "last_used_at": "2020-04-07T00:00:00.000Z",
  "usage_type": "auth",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://0.0.0.0:3000/root",
    "created_at": "2019-11-14T15:09:34.831Z",
    "bio": null,
    "location": null,
    "public_email": "",
    "linkedin": "",
    "twitter": "",
    "website_url": "",
    "organization": null,
    "last_sign_in_at": "2019-11-16T22:41:26.663Z",
    "confirmed_at": "2019-11-14T15:09:34.575Z",
    "last_activity_on": "2019-11-20",
    "email": "admin@example.com",
    "theme_id": 1,
    "color_scheme_id": 1,
    "projects_limit": 100000,
    "current_sign_in_at": "2019-11-19T14:42:18.078Z",
    "identities": [],
    "can_create_group": true,
    "can_create_project": true,
    "two_factor_enabled": false,
    "external": false,
    "private_profile": false,
    "shared_runners_minutes_limit": null,
    "extra_shared_runners_minutes_limit": null
  },
  "deploy_keys_projects": [
    {
      "id": 1,
      "deploy_key_id": 1,
      "project_id": 1,
      "created_at": "2020-01-09T07:32:52.453Z",
      "updated_at": "2020-01-09T07:32:52.453Z",
      "can_push": false
    }
  ]
}
```
