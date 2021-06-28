---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Generic Packages Repository **(FREE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4209) in GitLab 13.5.
> - It's [deployed behind a feature flag](../../../user/feature_flags.md), enabled by default.
> - It's enabled on GitLab.com.
> - It's able to be enabled or disabled per-project.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#enable-or-disable-generic-packages-in-the-package-registry).

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

Publish generic files, like release binaries, in your project's Package Registry. Then, install the packages whenever you need to use them as a dependency.

## Authenticate to the Package Registry

To authenticate to the Package Registry, you need either a [personal access token](../../../api/index.md#personalproject-access-tokens),
[CI/CD job token](../../../api/index.md#gitlab-cicd-job-token), or [deploy token](../../project/deploy_tokens/index.md).

In addition to the standard API authentication mechanisms, the generic package
API allows authentication with HTTP Basic authentication for use with tools that
do not support the other available mechanisms. The `user-id` is not checked and
may be any value, and the `password` must be either a [personal access token](../../../api/index.md#personalproject-access-tokens),
a [CI/CD job token](../../../api/index.md#gitlab-cicd-job-token), or a [deploy token](../../project/deploy_tokens/index.md).

## Publish a package file

When you publish a package file, if the package does not exist, it is created.

If a package with the same name, version, and filename already exists, it is also created. It does not overwrite the existing package.

Prerequisites:

- You need to [authenticate with the API](../../../api/index.md#authentication). If authenticating with a deploy token, it must be configured with the `write_package_registry` scope.

```plaintext
PUT /projects/:id/packages/generic/:package_name/:package_version/:file_name?status=:status
```

| Attribute          | Type            | Required | Description                                                                                                                      |
| -------------------| --------------- | ---------| -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | integer/string  | yes      | The ID or [URL-encoded path of the project](../../../api/index.md#namespaced-path-encoding).                                              |
| `package_name`     | string          | yes      | The package name. It can contain only lowercase letters (`a-z`), uppercase letter (`A-Z`), numbers (`0-9`), dots (`.`), hyphens (`-`), or underscores (`_`).
| `package_version`  | string          | yes      | The package version. The following regex validates this: `\A(\.?[\w\+-]+\.?)+\z`. You can test your version strings on [Rubular](https://rubular.com/r/aNCV0wG5K14uq8).
| `file_name`        | string          | yes      | The filename. It can contain only lowercase letters (`a-z`), uppercase letter (`A-Z`), numbers (`0-9`), dots (`.`), hyphens (`-`), or underscores (`_`).
| `status`           | string          | no       | The package status. It can be `default` (default) or `hidden`. Hidden packages do not appear in the UI or [package API list endpoints](../../../api/packages.md).

Provide the file context in the request body.

Example request using a personal access token:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --upload-file path/to/file.txt \
     "https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/0.0.1/file.txt?status=hidden"
```

Example response:

```json
{
  "message":"201 Created"
}
```

## Download package file

Download a package file.

If multiple packages have the same name, version, and filename, then the most recent one is retrieved.

Prerequisites:

- You need to [authenticate with the API](../../../api/index.md#authentication). If authenticating with a deploy token, it must be configured with the `read_package_registry` and/or `write_package_registry` scope.

```plaintext
GET /projects/:id/packages/generic/:package_name/:package_version/:file_name
```

| Attribute          | Type            | Required | Description                                                                         |
| -------------------| --------------- | ---------| ------------------------------------------------------------------------------------|
| `id`               | integer/string  | yes      | The ID or [URL-encoded path of the project](../../../api/index.md#namespaced-path-encoding). |
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
     https://gitlab.example.com/api/v4/projects/24/packages/generic/my_package/0.0.1/file.txt
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

### Enable or disable generic packages in the Package Registry

Support for generic packages is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can opt to disable it.

To enable it:

```ruby
# For the instance
Feature.enable(:generic_packages)
# For a single project
Feature.enable(:generic_packages, Project.find(<project id>))
```

To disable it:

```ruby
# For the instance
Feature.disable(:generic_packages)
# For a single project
Feature.disable(:generic_packages, Project.find(<project id>))
```

### Generic package sample project

The [Write CI-CD Variables in Pipeline](https://gitlab.com/guided-explorations/cfg-data/write-ci-cd-variables-in-pipeline) project contains a working example you can use to create, upload, and download generic packages in GitLab CI/CD.

It also demonstrates how to manage a semantic version for the generic package: storing it in a CI/CD variable, retrieving it, incrementing it, and writing it back to the CI/CD variable when tests for the download work correctly.
