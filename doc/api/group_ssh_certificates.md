---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Group SSH certificates API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/421915) in GitLab 16.4 [with a feature flag](../administration/feature_flags/_index.md) named `ssh_certificates_rest_endpoints`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/424501) in GitLab 16.9.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/424501) in GitLab 17.7. Feature flag `ssh_certificates_rest_endpoints` removed.

{{< /history >}}

Use this API to manage [SSH certificates for groups](../user/group/ssh_certificates.md).
Only top-level groups can store SSH certificates.

Prerequisites:

- You must be an Owner for a top-level group.

## List all group SSH certificates

{{< history >}}

- `fingerprint` response attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/629633) in GitLab 19.5.

{{< /history >}}

Lists all SSH certificates for a specified group.

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
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW2o6syFnRbO6D++jJHc3Eqj1k+XspAgCvLq8lXlDUj ca@example.com",
    "fingerprint": "SHA256:1CrrRznEotAVn+wfXVzYlDCaVcGoTvHIup4eNWBPK2k",
    "created_at": "2023-09-08T12:39:00.172Z"
  },
  {
    "id":12346,
    "title":"SSH Title 2",
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJfRGzblvgogdxwPnwsH+h4U5eo+xOzGru08CCaezaL ca@example.com",
    "fingerprint": "SHA256:/P+kBF3hlgEYGohCvKCLQXewtPcI+4B4phcctFeExG8",
    "created_at": "2023-09-08T12:39:00.244Z"
  }
]
```

## Add a group SSH certificate

{{< history >}}

- `fingerprint` response attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/629633) in GitLab 19.5.

{{< /history >}}

Adds a group SSH certificate for a specified group.

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
  --data-urlencode "title=newtitle" \
  --data-urlencode "key=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW2o6syFnRbO6D++jJHc3Eqj1k+XspAgCvLq8lXlDUj ca@example.com" \
  --url "https://gitlab.example.com/api/v4/groups/5/ssh_certificates"
```

Example response:

```json
{
  "id": 54321,
  "title": "newtitle",
  "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW2o6syFnRbO6D++jJHc3Eqj1k+XspAgCvLq8lXlDUj ca@example.com",
  "fingerprint": "SHA256:1CrrRznEotAVn+wfXVzYlDCaVcGoTvHIup4eNWBPK2k",
  "created_at": "2023-09-08T12:39:00.172Z"
}
```

## Delete a group SSH certificate

Deletes a specified group SSH certificate.

```plaintext
DELETE /groups/:id/ssh_certificates/:id
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
