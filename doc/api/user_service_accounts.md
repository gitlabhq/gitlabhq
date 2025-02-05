---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Service account users API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Use this API to interact with service accounts. For more information, see [Service accounts](../user/profile/service_accounts.md).

## List all service account users

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - List all service account users [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) in GitLab 17.1.

Lists all service account users.

Use the `page` and `per_page` [pagination parameters](rest/_index.md#offset-based-pagination) to filter the results.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
GET /service_accounts
```

Supported attributes:

| Attribute  | Type   | Required | Description |
|:-----------|:-------|:---------|:------------|
| `order_by` | string | no       | Attribute to order results by. Possible values: `id` or `username`. Default value: `id`. |
| `sort`     | string | no       | Direction to sort results by. Possible values: `desc` or `asc`. Default value: `desc`.   |

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

## Create a service account user

> - Create a service account user was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406782) in GitLab 16.1
> - Username and name attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841) in GitLab 16.10.

Creates a service account user.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /service_accounts
```

Supported attributes:

| Attribute  | Type   | Required | Description |
|:-----------|:-------|:---------|:------------|
| `name`     | string | no       | Name of the user. If not set, uses `Service account user`. |
| `username` | string | no       | Username of the user account. If not set, generates a name prepended with `service_account_`. |
| `email`    | string | no       | Email of the user account. If not set, generates a no-reply email address. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/service_accounts"
```

Example response:

```json
{
  "id": 57,
  "username": "service_account_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "service_account_6018816a18e515214e0c34c2b33523fc@noreply.gitlab.example.com"
}
```

### Specify a custom email address

You can specify a custom email address at service account creation to receive
notifications on this service account's actions.

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "email=custom_email@gitlab.example.com" "https://gitlab.example.com/api/v4/service_accounts"
```

Example response:

```json
{
  "id": 57,
  "username": "service_account_6018816a18e515214e0c34c2b33523fc",
  "name": "Service account user",
  "email": "custom_email@gitlab.example.com"
}
```

This fails if the email address has already been taken by another user:

```json
{
  "message": "400 Bad request - Email has already been taken"
}
```
