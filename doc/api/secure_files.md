---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Project-level Secure Files API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/350748) in GitLab 15.7. Feature flag `ci_secure_files` removed.

{{< /history >}}

Use this API to manage [secure files](../ci/secure_files/_index.md) for a project.

## List all secure files for a project

Lists all secure files for a specified project.

```plaintext
GET /projects/:project_id/secure_files
```

Supported attributes:

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `project_id` | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files"
```

Example response:

```json
[
    {
        "id": 1,
        "name": "myfile.jks",
        "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
        "checksum_algorithm": "sha256",
        "created_at": "2022-02-22T22:22:22.222Z",
        "expires_at": null,
        "metadata": null
    },
    {
        "id": 2,
        "name": "myfile.cer",
        "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aa2",
        "checksum_algorithm": "sha256",
        "created_at": "2022-02-22T22:22:22.222Z",
        "expires_at": "2023-09-21T14:55:59.000Z",
        "metadata": {
            "id":"75949910542696343243264405377658443914",
            "issuer": {
                "C":"US",
                "O":"Apple Inc.",
                "CN":"Apple Worldwide Developer Relations Certification Authority",
                "OU":"G3"
            },
            "subject": {
                "C":"US",
                "O":"Organization Name",
                "CN":"Apple Distribution: Organization Name (ABC123XYZ)",
                "OU":"ABC123XYZ",
                "UID":"ABC123XYZ"
            },
            "expires_at":"2023-09-21T14:55:59.000Z"
        }
    }
]
```

## Retrieve details of a secure file

Retrieves details of a specified secure file in a project.

```plaintext
GET /projects/:project_id/secure_files/:id
```

Supported attributes:

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `id`         | integer        | Yes      | The ID of a secure file. |
| `project_id` | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```

Example response:

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "created_at": "2022-02-22T22:22:22.222Z",
    "expires_at": null,
    "metadata": null
}
```

## Create a secure file

Creates a secure file in a specified project.

```plaintext
POST /projects/:project_id/secure_files
```

Supported attributes:

| Attribute       | Type           | Required | Description |
|-----------------|----------------|----------|-------------|
| `file`          | file           | Yes      | The file being uploaded (5 MB limit). |
| `name`          | string         | Yes      | The name of the file being uploaded. The filename must be unique in the project. |
| `project_id`    | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files" \
  --form "name=myfile.jks" \
  --form "file=@/path/to/file/myfile.jks"
```

Example response:

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "created_at": "2022-02-22T22:22:22.222Z",
    "expires_at": null,
    "metadata": null
}
```

## Download a secure file

Downloads the contents of a specified secure file in a project.

```plaintext
GET /projects/:project_id/secure_files/:id/download
```

Supported attributes:

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `id`         | integer        | Yes      | The ID of a secure file. |
| `project_id` | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1/download" \
  --output myfile.jks
```

## Delete a secure file

Deletes a specified secure file from a project.

```plaintext
DELETE /projects/:project_id/secure_files/:id
```

Supported attributes:

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `id`         | integer        | Yes      | The ID of a secure file. |
| `project_id` | integer or string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```
