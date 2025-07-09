---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Service account users API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to interact with instance service accounts. Instance service accounts are available to
an entire GitLab instance, but must still be added to groups and projects like a human user.
For more information, see [service accounts](../user/profile/service_accounts.md).

You can also interact with service accounts through the [users API](users.md).

## List all instance service accounts

{{< history >}}

- List all service accounts [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/416729) in GitLab 17.1.

{{< /history >}}

Lists all instance service accounts.

Use the `page` and `per_page` [pagination parameters](rest/_index.md#offset-based-pagination) to filter the results.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
GET /service_accounts
```

Supported attributes:

| Attribute  | Type   | Required | Description |
| ---------- | ------ | -------- | ----------- |
| `order_by` | string | no       | Attribute to order results by. Possible values: `id` or `username`. Default value: `id`. |
| `sort`     | string | no       | Direction to sort results by. Possible values: `desc` or `asc`. Default value: `desc`. |

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

## Create an instance service account

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/406782) in GitLab 16.1
- `username` and `name` attributes [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144841) in GitLab 16.10.
- `email` attribute [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178689) in GitLab 17.9.

{{< /history >}}

Creates an instance service account.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
POST /service_accounts
POST /service_accounts?email=custom_email@gitlab.example.com
```

Supported attributes:

| Attribute  | Type   | Required | Description |
| ---------- | ------ | -------- | ----------- |
| `name`     | string | no       | Name of the user. If not set, uses `Service account user`. |
| `username` | string | no       | Username of the user account. If undefined, generates a name prepended with `service_account_`. |
| `email`    | string | no       | Email of the user account. If undefined, generates a no-reply email address. Custom email addresses require confirmation, unless the email confirmation settings are [turned off](../administration/settings/sign_up_restrictions.md#confirm-user-email). |

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

If the email address defined by the `email` attribute is already in use by another user,
returns a `400 Bad request` error.

## Update an instance service account

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196309/) in GitLab 18.2.

{{< /history >}}

Updates a specified instance service account.

Prerequisites:

- You must have administrator access to the instance.

```plaintext
PATCH /service_accounts/:id
```

Parameters:

| Attribute  | Type           | Required | Description                                                                                                                                                                                                               |
|:-----------|:---------------|:---------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`       | integer        | yes      | ID of the service account.  |
| `name`     | string         | no       | Name of the user.  |
| `username` | string         | no       | Username of the user account. |
| `email`    | string         | no       | Email of the user account. Custom email addresses require confirmation, unless the email confirmation settings are [turned off](../administration/settings/sign_up_restrictions.md#confirm-user-email). |

Example request:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/service_accounts/57" --data "name=Updated Service Account email=updated_email@example.com"
```

Example response:

```json
{
  "id": 57,
  "username": "service_account_6018816a18e515214e0c34c2b33523fc",
  "name": "Updated Service Account",
  "email": "service_account_<random_hash>@noreply.gitlab.example.com",
  "unconfirmed_email": "custom_email@example.com"
}
```
