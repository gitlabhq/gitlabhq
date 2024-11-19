---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Service account users API

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

Create and list [service account](../user/profile/service_accounts.md) users by using the REST API.

## Create a service account user

> - Ability to create a service account user was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406782) in GitLab 16.1
> - Ability to specify a username or name was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841) in GitLab 16.10.

Create a service account user. You can specify the account username and name. If you do not specify any attributes:

- The default name is `Service account user`.
- The username is automatically generated.

Prerequisites:

- You must be an administrator.

```plaintext
POST /service_accounts
```

Supported attributes:

| Attribute  | Type   | Required | Description |
|:-----------|:-------|:---------|:------------|
| `name`     | string | no       | Name of the user. |
| `username` | string | no       | Username of the user. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/service_accounts"
```

Example response:

```json
{
  "id": 57,
  "username": "service_account_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user"
}
```

## List all service account users

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

> - Ability to list all service account users [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) in GitLab 17.1.

Lists all service account users.

Prerequisites:

- You must be an administrator.

This function takes [pagination parameters](rest/index.md#offset-based-pagination) `page` and `per_page` to restrict the
list of users.

```plaintext
GET /service_accounts
```

Supported attributes:

| Attribute  | Type   | Required | Description |
|:-----------|:-------|:---------|:------------|
| `order_by` | string | no       | Order list of users by `username` or `id` Default is `id`. |
| `sort`     | string | no       | Specify sorting by `asc` or `desc`. Default is `desc`. |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/service_accounts"
```

Example response:

```json
[
  {
    "id": 114,
    "username": "service_account_33",
    "name": "Service account user"
  },
  {
    "id": 137,
    "username": "service_account_34",
    "name": "john doe"
  }
]
```
