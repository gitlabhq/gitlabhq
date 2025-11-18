---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project remote mirrors API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage [remote mirrors](../user/project/repository/mirror/push.md). You
can query and modify the state of these mirrors with the remote mirror API.

For security reasons, the `url` attribute in the API response is always scrubbed of username
and password information.

{{< alert type="note" >}}

[Pull mirrors](../user/project/repository/mirror/pull.md) use
[a different API endpoint](project_pull_mirroring.md#configure-pull-mirroring-for-a-project) to
display and update them.

{{< /alert >}}

## List a project's remote mirrors

{{< history >}}

- Attribute `host_keys` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435) in GitLab 18.4.

{{< /history >}}

Get an array of remote mirrors and their statuses for a project.

```plaintext
GET /projects/:id/remote_mirrors
```

Supported attributes:

| Attribute | Type              | Required | Description                                                                      |
|-----------|-------------------|----------|----------------------------------------------------------------------------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths).       |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                   | Type    | Description |
|-----------------------------|---------|-------------|
| `auth_method`               | string  | Authentication method used for the mirror. |
| `enabled`                   | boolean | If `true`, the mirror is enabled. |
| `host_keys`                 | array   | Array of SSH host key fingerprints for the remote mirror. |
| `id`                        | integer | ID of the remote mirror. |
| `keep_divergent_refs`       | boolean | If `true`, divergent refs are kept when mirroring. |
| `last_error`                | string  | Error message from the last mirror attempt. `null` if successful. |
| `last_successful_update_at` | string  | Timestamp of the last successful mirror update. ISO 8601 format. |
| `last_update_at`            | string  | Timestamp of the last mirror attempt. ISO 8601 format. |
| `last_update_started_at`    | string  | Timestamp when the last mirror attempt started. ISO 8601 format. |
| `only_protected_branches`   | boolean | If `true`, only protected branches are mirrored. |
| `update_status`             | string  | Status of the mirror update. Possible values: `none`, `scheduled`, `started`, `finished`, `failed`. |
| `url`                       | string  | Mirror URL with credentials scrubbed for security. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors"
```

Example response:

```json
[
  {
    "enabled": true,
    "id": 101486,
    "auth_method": "ssh_public_key",
    "last_error": null,
    "last_successful_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_started_at": "2020-01-06T17:31:55.864Z",
    "only_protected_branches": true,
    "keep_divergent_refs": true,
    "update_status": "finished",
    "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
  }
]
```

## Get a single project's remote mirror

{{< history >}}

- Attribute `host_keys` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435) in GitLab 18.4.

{{< /history >}}

Get a single remote mirror and its status for a project.

```plaintext
GET /projects/:id/remote_mirrors/:mirror_id
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `mirror_id` | integer           | Yes      | ID of the remote mirror. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                   | Type    | Description |
|-----------------------------|---------|-------------|
| `enabled`                   | boolean | If `true`, the mirror is enabled. |
| `id`                        | integer | ID of the remote mirror. |
| `host_keys`                 | array   | Array of SSH host key fingerprints for the remote mirror. |
| `keep_divergent_refs`       | boolean | If `true`, divergent refs are kept when mirroring. |
| `last_error`                | string  | Error message from the last mirror attempt. `null` if successful. |
| `last_successful_update_at` | string  | Timestamp of the last successful mirror update. ISO 8601 format. |
| `last_update_at`            | string  | Timestamp of the last mirror attempt. ISO 8601 format. |
| `last_update_started_at`    | string  | Timestamp when the last mirror attempt started. ISO 8601 format. |
| `only_protected_branches`   | boolean | If `true`, only protected branches are mirrored. |
| `update_status`             | string  | Status of the mirror update. Possible values: `none`, `scheduled`, `started`, `finished`, `failed`. |
| `url`                       | string  | Mirror URL with credentials scrubbed for security. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

Example response:

```json
{
  "enabled": true,
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "only_protected_branches": true,
  "keep_divergent_refs": true,
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
  "host_keys": [
    {
      "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
    }
  ]
}
```

## Get a single project's remote mirror public key

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180291) in GitLab 17.9.

{{< /history >}}

Get the public key of a remote mirror that uses SSH authentication.

```plaintext
GET /projects/:id/remote_mirrors/:mirror_id/public_key
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `mirror_id` | integer           | Yes      | ID of the remote mirror. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute   | Type   | Description                        |
|-------------|--------|------------------------------------|
| `public_key`| string | Public key of the remote mirror.  |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486/public_key"
```

Example response:

```json
{
  "public_key": "ssh-rsa AAAAB3NzaC1yc2EA..."
}
```

## Create a pull mirror

Learn how to [configure a pull mirror](project_pull_mirroring.md#configure-pull-mirroring-for-a-project) by using the
project pull mirroring API.

## Create a push mirror

{{< history >}}

- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 16.0.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/410354) in GitLab 16.2. Feature flag `mirror_only_branches_match_regex` removed.
- Field `auth_method` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75155) in GitLab 16.10.
- Attribute `host_keys` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435) in GitLab 18.4.

{{< /history >}}

Create a push mirror for a project. Push mirroring is disabled by default. To enable it, include the optional parameter
`enabled` when you create the mirror.

```plaintext
POST /projects/:id/remote_mirrors
```

Supported attributes:

| Attribute                 | Type              | Required | Description |
|---------------------------|-------------------|----------|-------------|
| `id`                      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `url`                     | string            | Yes      | Target URL to which the repository is mirrored. |
| `auth_method`             | string            | No       | Mirror authentication method. Accepted values: `ssh_public_key`, `password`. |
| `enabled`                 | boolean           | No       | If `true`, the mirror is enabled. |
| `keep_divergent_refs`     | boolean           | No       | If `true`, divergent refs are kept when mirroring. |
| `mirror_branch_regex`     | string            | No       | Regular expression for branch names to mirror. Only branches with names matching the regex are mirrored. Requires `only_protected_branches` to be disabled. Premium and Ultimate only. |
| `only_protected_branches` | boolean           | No       | If `true`, only protected branches are mirrored. |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                   | Type    | Description |
|-----------------------------|---------|-------------|
| `auth_method`               | string  | Authentication method used for the mirror. |
| `enabled`                   | boolean | If `true`, the mirror is enabled. |
| `host_keys`                 | array   | Array of SSH host key fingerprints for the remote mirror. |
| `id`                        | integer | ID of the remote mirror. |
| `keep_divergent_refs`       | boolean | If `true`, divergent refs are kept when mirroring. |
| `last_error`                | string  | Error message from the last mirror attempt. `null` if successful. |
| `last_successful_update_at` | string  | Timestamp of the last successful mirror update. ISO 8601 format. |
| `last_update_at`            | string  | Timestamp of the last mirror attempt. ISO 8601 format. |
| `last_update_started_at`    | string  | Timestamp when the last mirror attempt started. ISO 8601 format. |
| `only_protected_branches`   | boolean | If `true`, only protected branches are mirrored. |
| `update_status`             | string  | Status of the mirror update. Possible values: `none`, `scheduled`, `started`, `finished`, `failed`. |
| `url`                       | string  | Mirror URL with credentials scrubbed for security. |

Example request:

```shell
curl --request POST \
  --data "url=https://username:token@example.com/gitlab/example.git" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors"
```

Example response:

```json
{
    "enabled": false,
    "id": 101486,
    "auth_method": "password",
    "last_error": null,
    "last_successful_update_at": null,
    "last_update_at": null,
    "last_update_started_at": null,
    "only_protected_branches": false,
    "keep_divergent_refs": false,
    "update_status": "none",
    "url": "https://*****:*****@example.com/gitlab/example.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
}
```

## Update a remote mirror's attributes

{{< history >}}

- Field `auth_method` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75155) in GitLab 16.10.
- Attribute `host_keys` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203435) in GitLab 18.4.

{{< /history >}}

Update a remote mirror's configuration. Toggle a remote mirror on or off, or change which types of branches are
mirrored.

```plaintext
PUT /projects/:id/remote_mirrors/:mirror_id
```

Supported attributes:

| Attribute                 | Type              | Required | Description |
|---------------------------|-------------------|----------|-------------|
| `id`                      | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `mirror_id`               | integer           | Yes      | ID of the remote mirror. |
| `auth_method`             | string            | No       | Mirror authentication method. Accepted values: `ssh_public_key`, `password`. |
| `enabled`                 | boolean           | No       | If `true`, the mirror is enabled. |
| `keep_divergent_refs`     | boolean           | No       | If `true`, divergent refs are kept when mirroring. |
| `mirror_branch_regex`     | string            | No       | Regular expression for branch names to mirror. Only branches with names matching the regex are mirrored. Does not work with `only_protected_branches` enabled. Premium and Ultimate only. |
| `only_protected_branches` | boolean           | No       | If `true`, only protected branches are mirrored. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the
following response attributes:

| Attribute                   | Type    | Description |
|-----------------------------|---------|-------------|
| `auth_method`               | string  | Authentication method used for the mirror. |
| `enabled`                   | boolean | If `true`, the mirror is enabled. |
| `host_keys`                 | array   | Array of SSH host key fingerprints for the remote mirror. |
| `id`                        | integer | ID of the remote mirror. |
| `keep_divergent_refs`       | boolean | If `true`, divergent refs are kept when mirroring. |
| `last_error`                | string  | Error message from the last mirror attempt. `null` if successful. |
| `last_successful_update_at` | string  | Timestamp of the last successful mirror update. ISO 8601 format. |
| `last_update_at`            | string  | Timestamp of the last mirror attempt. ISO 8601 format. |
| `last_update_started_at`    | string  | Timestamp when the last mirror attempt started. ISO 8601 format. |
| `only_protected_branches`   | boolean | If `true`, only protected branches are mirrored. |
| `update_status`             | string  | Status of the mirror update. Possible values: `none`, `scheduled`, `started`, `finished`, `failed`. |
| `url`                       | string  | Mirror URL with credentials scrubbed for security. |

Example request:

```shell
curl --request PUT \
  --data "enabled=false" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```

Example response:

```json
{
    "enabled": false,
    "id": 101486,
    "auth_method": "password",
    "last_error": null,
    "last_successful_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_at": "2020-01-06T17:32:02.823Z",
    "last_update_started_at": "2020-01-06T17:31:55.864Z",
    "only_protected_branches": true,
    "keep_divergent_refs": true,
    "update_status": "finished",
    "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git",
    "host_keys": [
      {
        "fingerprint_sha256": "SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw"
      }
    ]
}
```

## Force push mirror update

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/388907) in GitLab 16.11.

{{< /history >}}

[Force an update](../user/project/repository/mirror/_index.md#force-an-update) to a push mirror.

```plaintext
POST /projects/:id/remote_mirrors/:mirror_id/sync
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `mirror_id` | integer           | Yes      | ID of the remote mirror. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486/sync"
```

## Delete a remote mirror

Delete a remote mirror.

```plaintext
DELETE /projects/:id/remote_mirrors/:mirror_id
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | Yes      | ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `mirror_id` | integer           | Yes      | ID of the remote mirror. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/remote_mirrors/101486"
```
