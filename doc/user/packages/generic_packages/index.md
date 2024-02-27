---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Generic Packages Repository

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4209) in GitLab 13.5 [with a flag](../../../administration/feature_flags.md) named `generic_packages`. Enabled by default.
> - [Feature flag `generic_packages`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80886) removed in GitLab 14.8.

Publish generic files, like release binaries, in your project's package registry. Then, install the packages whenever you need to use them as a dependency.

## Authenticate to the package registry

To authenticate to the package registry, you need either a [personal access token](../../../api/rest/index.md#personalprojectgroup-access-tokens),
[CI/CD job token](../../../ci/jobs/ci_job_token.md), or [deploy token](../../project/deploy_tokens/index.md).

In addition to the standard API authentication mechanisms, the generic package
API allows authentication with HTTP Basic authentication for use with tools that
do not support the other available mechanisms. The `user-id` is not checked and
may be any value, and the `password` must be either a [personal access token](../../../api/rest/index.md#personalprojectgroup-access-tokens),
a [CI/CD job token](../../../ci/jobs/ci_job_token.md), or a [deploy token](../../project/deploy_tokens/index.md).

Do not use authentication methods other than the methods documented here. Undocumented authentication methods might be removed in the future.

## Publish a package file

When you publish a package file, if the package does not exist, it is created.

Prerequisites:

- You must [authenticate with the API](../../../api/rest/index.md#authentication).
  If authenticating with a deploy token, it must be configured with the `write_package_registry`
  scope. If authenticating with a personal access token or project access token, it must be
  configured with the `api` scope. Project access tokens must have at least the Developer role.
- You must call this API endpoint serially when attempting to upload multiple files under the
  same package name and version. Attempts to concurrently upload multiple files into
  a new package name and version may face partial failures with
  `HTTP 500: Internal Server Error` responses due to the requests racing to
  create the package.

```plaintext
PUT /projects/:id/packages/generic/:package_name/:package_version/:file_name?status=:status
```

| Attribute          | Type            | Required | Description                                                                                                                      |
| -------------------| --------------- | ---------| -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | integer/string  | yes      | The ID or [URL-encoded path of the project](../../../api/rest/index.md#namespaced-path-encoding).                                              |
| `package_name`     | string          | yes      | The package name. It can contain only lowercase letters (`a-z`), uppercase letter (`A-Z`), numbers (`0-9`), dots (`.`), hyphens (`-`), or underscores (`_`). |
| `package_version`  | string          | yes      | The package version. The following regex validates this: `\A(\.?[\w\+-]+\.?)+\z`. You can test your version strings on [Rubular](https://rubular.com/r/aNCV0wG5K14uq8). |
| `file_name`        | string          | yes      | The filename. It can contain only lowercase letters (`a-z`), uppercase letter (`A-Z`), numbers (`0-9`), dots (`.`), hyphens (`-`), or underscores (`_`). |
| `status`           | string          | no       | The package status. It can be `default` or `hidden`. Hidden packages do not appear in the UI or [package API list endpoints](../../../api/packages.md). |
| `select`           | string          | no       | The response payload. By default, the response is empty. Valid values are: `package_file`. `package_file` returns details of the package file record created by this request. |

Provide the file context in the request body.

Example request using a personal access token:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/0.0.1/file.txt"
```

Example response without attribute `select`:

```json
{
  "message":"201 Created"
}
```

Example request with attribute `select = package_file`:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --user "<username>:<Project Access Token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/0.0.1/file.txt?select=package_file"
```

Example response with attribute `select = package_file`:

```json
{
  "id": 1,
  "package_id": 1,
  "created_at": "2021-10-12T12:05:23.387Z",
  "updated_at": "2021-10-12T12:05:23.387Z",
  "size": 0,
  "file_store": 1,
  "file_md5": null,
  "file_sha1": null,
  "file_name": "file.txt",
  "file": {
    "url": "/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b/packages/26/files/36/file.txt"
  },
  "file_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "verification_retry_at": null,
  "verified_at": null,
  "verification_failure": null,
  "verification_retry_count": null,
  "verification_checksum": null,
  "verification_state": 0,
  "verification_started_at": null,
  "new_file_path": null
}
```

### Publishing a package with the same name or version

When you publish a package with the same name and version as an existing package, the new package
files are added to the existing package. When you install a generic package that has a duplicate, GitLab downloads the latest version.

You can use the UI or API to access and view the
existing package's older files. To delete these older package revisions, consider using the Packages
API or the UI.

#### Do not allow duplicate Generic packages

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/293755) in GitLab 13.12.
> - Required role [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/350682) from Developer to Maintainer in GitLab 15.0.

To prevent users from publishing duplicate generic packages, you can use the [GraphQL API](../../../api/graphql/reference/index.md#packagesettings)
or the UI.

In the UI:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Packages and registries**.
1. In the **Generic** row of the **Duplicate packages** table, turn off the **Allow duplicates** toggle.
1. Optional. In the **Exceptions** text box, enter a regular expression that matches the names and versions of packages to allow.

Your changes are automatically saved.

## Download package file

Download a package file.

If multiple packages have the same name, version, and filename, then the most recent one is retrieved.

Prerequisites:

- You need to [authenticate with the API](../../../api/rest/index.md#authentication).
  - If authenticating with a deploy token, it must be configured with the `read_package_registry` and/or `write_package_registry` scope.
  - Project access tokens require the `read_api` scope and at least the `Reporter` role.

```plaintext
GET /projects/:id/packages/generic/:package_name/:package_version/:file_name
```

| Attribute          | Type            | Required | Description                                                                         |
| -------------------| --------------- | ---------| ------------------------------------------------------------------------------------|
| `id`               | integer/string  | yes      | The ID or [URL-encoded path of the project](../../../api/rest/index.md#namespaced-path-encoding). |
| `package_name`     | string          | yes      | The package name.                                                                   |
| `package_version`  | string          | yes      | The package version.                                                                |
| `file_name`        | string          | yes      | The filename.                                                                      |

The file context is served in the response body. The response content type is `application/octet-stream`.

Example request that uses a personal access token:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/0.0.1/file.txt"
```

Example request that uses HTTP Basic authentication:

```shell
curl --user "user:<your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/0.0.1/file.txt"
```

## Publish a generic package by using CI/CD

To work with generic packages in [GitLab CI/CD](../../../ci/index.md), you can use
`CI_JOB_TOKEN` in place of the personal access token in your commands.

For example:

```yaml
image: curlimages/curl:latest

stages:
  - upload
  - download

upload:
  stage: upload
  script:
    - 'curl --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file path/to/file.txt "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/0.0.1/file.txt"'

download:
  stage: download
  script:
    - 'wget --header="JOB-TOKEN: $CI_JOB_TOKEN" ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/0.0.1/file.txt'
```

When using a Windows runner with PowerShell, you must use `Invoke-WebRequest` or `Invoke-RestMethod`
instead of `curl` in the `upload` and `download` stages.

For example:

```yaml
upload:
  stage: upload
  script:
    - Invoke-RestMethod -Headers @{ "JOB-TOKEN"="$CI_JOB_TOKEN" } -InFile path/to/file.txt -uri "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/my_package/0.0.1/file.txt" -Method put
```

### Generic package sample project

The [Write CI-CD Variables in Pipeline](https://gitlab.com/guided-explorations/cfg-data/write-ci-cd-variables-in-pipeline) project contains a working example you can use to create, upload, and download generic packages in GitLab CI/CD.

It also demonstrates how to manage a semantic version for the generic package: storing it in a CI/CD variable, retrieving it, incrementing it, and writing it back to the CI/CD variable when tests for the download work correctly.

## Troubleshooting

### Internal Server error on large file uploads to S3

S3-compatible object storage [limits the size of a single PUT request to 5 GB](https://docs.aws.amazon.com/AmazonS3/latest/userguide/upload-objects.html). If the `aws_signature_version` is set to `2` in the [object storage connection settings](../../../administration/object_storage.md), attempting to publish a package file larger than the 5 GB limit can result in a `HTTP 500: Internal Server Error` response.

If you are receiving `HTTP 500: Internal Server Error` responses when publishing large files to S3, set the `aws_signature_version` to `4`:

```ruby
# Consolidated Object Storage settings
gitlab_rails['object_store']['connection'] = {
  # Other connection settings
  'aws_signature_version' => '4'
}
# OR 
# Storage-specific form settings
gitlab_rails['packages_object_store_connection'] = {
  # Other connection settings
  'aws_signature_version' => '4'
}
```
