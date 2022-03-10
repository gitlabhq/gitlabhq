---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, api
---

# Project-level Secure Files API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78227) in GitLab 14.8. [Deployed behind the `ci_secure_files` flag](../administration/feature_flags.md), disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
ask an administrator to [enable the feature flag](../administration/feature_flags.md) named `ci_secure_files`.
The feature is not ready for production use.

## List project secure files

Get list of secure files in a project.

```plaintext
GET /projects/:project_id/secure_files
```

Supported attributes:

| Attribute    | Type           | Required               | Description |
|--------------|----------------|------------------------|-------------|
| `project_id` | integer/string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/secure_files"
```

Example response:

```json
[
    {
        "id": 1,
        "name": "myfile.jks",
        "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
        "checksum_algorithm": "sha256",
        "permissions": "read_only",
        "created_at": "2022-02-22T22:22:22.222Z"
    },
    {
        "id": 2,
        "name": "myotherfile.jks",
        "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aa2",
        "checksum_algorithm": "sha256",
        "permissions": "execute",
        "created_at": "2022-02-22T22:22:22.222Z"
    }
]
```

## Show secure file details

Get the details of a specific secure file in a project.

```plaintext
GET /projects/:project_id/secure_files/:id
```

Supported attributes:

| Attribute    | Type           | Required               | Description |
|--------------|----------------|------------------------|-------------|
| `project_id` | integer/string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `id`         | integer        | **{check-circle}** Yes | The `id` of a secure file. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```

Example response:

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "permissions": "read_only",
    "created_at": "2022-02-22T22:22:22.222Z"
}
```

## Create secure file

Create a new secure file.

```plaintext
POST /projects/:project_id/secure_files
```

Supported attributes:

| Attribute     | Type           | Required               | Description |
|---------------|----------------|------------------------|-------------|
| `project_id`  | integer/string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `name`        | string         | **{check-circle}** Yes | The `name` of the file being uploaded. |
| `file`        | file           | **{check-circle}** Yes | The `file` being uploaded. |
| `permissions` | string         | **{dotted-circle}** No | The file is created with the specified permissions when created in the CI/CD job. Available types are: `read_only` (default), `read_write`, and `execute`. |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/1/secure_files"  --form "name=myfile.jks" --form "file=@/path/to/file/myfile.jks"
```

Example response:

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "permissions": "read_only",
    "created_at": "2022-02-22T22:22:22.222Z"
}
```

## Download secure file

Download the contents of a project's secure file.

```plaintext
GET /projects/:project_id/download/:id
```

Supported attributes:

| Attribute    | Type           | Required               | Description |
|--------------|----------------|------------------------|-------------|
| `project_id` | integer/string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `id`         | integer        | **{check-circle}** Yes | The `id` of a secure file. |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/1/secure_files/1/download --output myfile.jks
```

## Remove secure file

Remove a project's secure file.

```plaintext
DELETE /projects/:project_id/secure_files/:id
```

Supported attributes:

| Attribute    | Type           | Required               | Description |
|--------------|----------------|------------------------|-------------|
| `project_id` | integer/string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `id`         | integer        | **{check-circle}** Yes | The `id` of a secure file. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```
