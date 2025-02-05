---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group SSH certificates API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/421915) in GitLab 16.4 [with a flag](../user/feature_flags.md) named `ssh_certificates_rest_endpoints`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/424501) in GitLab 16.9.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/424501) in GitLab 17.7. Feature flag `ssh_certificates_rest_endpoints` removed.

Use this API to create, read and delete SSH certificates for a group.
Only top-level groups can store SSH certificates.
To use this API, you must [authenticate yourself](rest/authentication.md) as user assigned the Owner role.

## Get all SSH certificates for a particular group

```plaintext
GET /groups/:id/ssh_certificates
```

Parameters:

| Attribute  | Type   | Required | Description          |
| ---------- | ------ | -------- |----------------------|
| `id`      | integer | Yes       | The ID of the group. |

By default, `GET` requests return 20 results at a time because the API results are paginated.
Read more on [pagination](rest/_index.md#pagination).

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/groups/90/ssh_certificates"
```

Example response:

```json
[
  {
    "id": 12345,
    "title": "SSH Title 1",
    "key": "ssh-rsa AAAAB3NzaC1ea2dAAAADAQABAAAAgQDGbLkF44ScxRQi2FfA7VsHgGqptguSbmW26jkJhEiRZpGS4/+UzaaSqc8Psw2OhSsKc5QwfrB/ANpO4LhOjDzhf2FuD8ACkv3R7XtaJ+rN6PlyzoBfLAiSyzxhEoMFDBprTgaiZKgg2yQ9dRH55w3f6XMZ4hnaUae53nQgfQLxFw== example@gitlab.com",
    "created_at": "2023-09-08T12:39:00.172Z"
  },
  {
    "id":12346,
    "title":"SSH Title 2",
    "key": "ssh-rsa AAAAB3NzaC1ac2EAAAADAQABAAAAgQDTl/hHfu1F/KlR+QfgM2wUmyxcN5YeiaWluEGIrfXUeJuI+bK6xjpE3+2afHDYtE9VQkeL32KRjefX2d72Jeoa68ewt87Vn8CcGkUTOTpHNzeL8pHMKFs3m7ArSBxNg5vTdgAsq5dbDGNtat7b2WCHTNvtWoON1Jetne30uW2EwQ== example@gitlab.com",
    "created_at": "2023-09-08T12:39:00.244Z"
  }
]
```

## Create SSH Certificate

Create a new SSH certificate in the group.

```plaintext
POST /groups/:id/ssh_certificates
```

Parameters:

| Attribute | Type       | Required | Description                           |
|-----------|------------| -------- |---------------------------------------|
| `id`      | integer    | Yes       | The ID of the group.                  |
| `key`     | string     | Yes       | The public key of the SSH certificate.|
| `title`   | string     | Yes       | The title of the SSH certificate.     |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/ssh_certificates?title=newtitle&key=ssh-rsa+REDACTED+example%40gitlab.com"
```

Example response:

```json
{
  "id": 54321,
  "title": "newtitle",
  "key": "ssh-rsa ssh-rsa AAAAB3NzaC1ea2dAAAADAQABAAAAgQDGbLkF44ScxRQi2FfA7VsHgGqptguSbmW26jkJhEiRZpGS4/+UzaaSqc8Psw2OhSsKc5QwfrB/ANpO4LhOjDzhf2FuD8ACkv3R7XtaJ+rN6PlyzoBfLAiSyzxhEoMFDBprTgaiZKgg2yQ9dRH55w3f6XMZ4hnaUae53nQgfQLxFw== example@gitlab.com",
  "created_at": "2023-09-08T12:39:00.172Z"
}
```

## Delete group SSH certificate

Delete a SSH certificate from a group.

```plaintext
DELETE /groups/:id/ssh_certificate/:id
```

Parameters:

| Attribute | Type    | Required | Description                   |
|-----------|---------| -------- |-------------------------------|
| `id`      | integer | Yes       | The ID of the group           |
| `id`      | integer | Yes       | The ID of the SSH certificate |

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/ssh_certificates/12345"
```
