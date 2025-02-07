---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project-level Secure Files API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/350748) in GitLab 15.7. Feature flag `ci_secure_files` removed.

This feature is part of [Mobile DevOps](../ci/mobile_devops/_index.md) developed by [GitLab Incubation Engineering](https://handbook.gitlab.com/handbook/engineering/development/incubation/).
The feature is still in development, but you can:

- [Request a feature](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=feature_request).
- [Report a bug](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=report_bug).
- [Share feedback](https://gitlab.com/gitlab-org/incubation-engineering/mobile-devops/feedback/-/issues/new?issuable_template=general_feedback).

You can securely store up to 100 files for use in CI/CD pipelines as secure files. These files are stored securely outside of your project's repository and are not version controlled. It is safe to store sensitive information in these files. Secure files support both plain text and binary file types but must be 5 MB or less.

## List project secure files

Get list of secure files in a project.

```plaintext
GET /projects/:project_id/secure_files
```

Supported attributes:

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `project_id` | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

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

## Show secure file details

Get the details of a specific secure file in a project.

```plaintext
GET /projects/:project_id/secure_files/:id
```

Supported attributes:

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `id`         | integer        | Yes      | The ID of a secure file. |
| `project_id` | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

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
    "created_at": "2022-02-22T22:22:22.222Z",
    "expires_at": null,
    "metadata": null
}
```

## Create secure file

Create a new secure file.

```plaintext
POST /projects/:project_id/secure_files
```

Supported attributes:

| Attribute       | Type           | Required | Description |
|-----------------|----------------|----------|-------------|
| `file`          | file           | Yes      | The file being uploaded (5 MB limit). |
| `name`          | string         | Yes      | The name of the file being uploaded. The filename must be unique in the project. |
| `project_id`    | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

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
    "created_at": "2022-02-22T22:22:22.222Z",
    "expires_at": null,
    "metadata": null
}
```

## Download secure file

Download the contents of a project's secure file.

```plaintext
GET /projects/:project_id/secure_files/:id/download
```

Supported attributes:

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `id`         | integer        | Yes      | The ID of a secure file. |
| `project_id` | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

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

| Attribute    | Type           | Required | Description |
|--------------|----------------|----------|-------------|
| `id`         | integer        | Yes      | The ID of a secure file. |
| `project_id` | integer/string | Yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```
