---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Plan limits API **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/54232) in GitLab 13.10.

The plan limits API allows you to maintain the application limits for the existing subscription plans.

The existing plans depend on the GitLab edition. In the Community Edition, only the plan `default`
is available. In the Enterprise Edition, additional plans are available as well.

NOTE:
Administrator access is required to use this API.

## Get current plan limits

List the current limits of a plan on the GitLab instance.

```plaintext
GET /application/plan_limits
```

| Attribute                         | Type    | Required | Description |
| --------------------------------- | ------- | -------- | ----------- |
| `plan_name`                       | string  | no       | Name of the plan to get the limits from. Default: `default`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/plan_limits"
```

Example response:

```json
{
  "conan_max_file_size": 3221225472,
  "generic_packages_max_file_size": 5368709120,
  "helm_max_file_size": 5242880,
  "maven_max_file_size": 3221225472,
  "npm_max_file_size": 524288000,
  "nuget_max_file_size": 524288000,
  "pypi_max_file_size": 3221225472,
  "terraform_module_max_file_size": 1073741824
}
```

## Change plan limits

Modify the limits of a plan on the GitLab instance.

```plaintext
PUT /application/plan_limits
```

| Attribute                         | Type    | Required | Description |
| --------------------------------- | ------- | -------- | ----------- |
| `plan_name`                       | string  | yes      | Name of the plan to update. |
| `conan_max_file_size`             | integer | no       | Maximum Conan package file size in bytes. |
| `generic_packages_max_file_size`  | integer | no       | Maximum generic package file size in bytes. |
| `helm_max_file_size`              | integer | no       | Maximum Helm chart file size in bytes. |
| `maven_max_file_size`             | integer | no       | Maximum Maven package file size in bytes. |
| `npm_max_file_size`               | integer | no       | Maximum NPM package file size in bytes. |
| `nuget_max_file_size`             | integer | no       | Maximum NuGet package file size in bytes. |
| `pypi_max_file_size`              | integer | no       | Maximum PyPI package file size in bytes. |
| `terraform_module_max_file_size`  | integer | no       | Maximum Terraform Module package file size in bytes. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/plan_limits?plan_name=default&conan_max_file_size=3221225472"
```

Example response:

```json
{
  "conan_max_file_size": 3221225472,
  "generic_packages_max_file_size": 5368709120,
  "helm_max_file_size": 5242880,
  "maven_max_file_size": 3221225472,
  "npm_max_file_size": 524288000,
  "nuget_max_file_size": 524288000,
  "pypi_max_file_size": 3221225472,
  "terraform_module_max_file_size": 1073741824
}
```
