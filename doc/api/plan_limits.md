---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Plan limits API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Use this API to interact with the application limits for your existing subscription plan.

The existing plans depend on the GitLab edition. In the Community Edition, only the plan `default`
is available. In the Enterprise Edition, additional plans are available as well.

Prerequisites:

- You must have administrator access to the instance.

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
  "ci_instance_level_variables": 25,
  "ci_pipeline_size": 0,
  "ci_active_jobs": 0,
  "ci_project_subscriptions": 2,
  "ci_pipeline_schedules": 10,
  "ci_needs_size_limit": 50,
  "ci_registered_group_runners": 1000,
  "ci_registered_project_runners": 1000,
  "dotenv_size": 5120,
  "dotenv_variables": 20,
  "conan_max_file_size": 3221225472,
  "enforcement_limit": 10000,
  "generic_packages_max_file_size": 5368709120,
  "helm_max_file_size": 5242880,
  "notification_limit": 10000,
  "maven_max_file_size": 3221225472,
  "npm_max_file_size": 524288000,
  "nuget_max_file_size": 524288000,
  "pypi_max_file_size": 3221225472,
  "terraform_module_max_file_size": 1073741824,
  "storage_size_limit": 15000
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
| `ci_instance_level_variables`     | integer | no       | Maximum number of Instance-level CI/CD variables that can be defined. |
| `ci_pipeline_size`                | integer | no       | Maximum number of jobs in a single pipeline. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_active_jobs`                  | integer | no       | Total number of jobs in currently active pipelines. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_project_subscriptions`        | integer | no       | Maximum number of pipeline subscriptions to and from a project. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_pipeline_schedules`           | integer | no       | Maximum number of pipeline schedules. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_needs_size_limit`             | integer | no       | Maximum number of [`needs`](../ci/yaml/needs.md) dependencies that a job can have. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_registered_group_runners`     | integer | no       | Maximum number of runners created or active in a group during the past seven days. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `ci_registered_project_runners`   | integer | no       | Maximum number of runners created or active in a project during the past seven days. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85895) in GitLab 15.0. |
| `dotenv_size`                     | integer | no       | Maximum size of a dotenv artifact in bytes. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/432529) in GitLab 17.1. |
| `dotenv_variables`                | integer | no       | Maximum number of variables in a dotenv artifact. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/432529) in GitLab 17.1. |
| `conan_max_file_size`             | integer | no       | Maximum Conan package file size in bytes. |
| `enforcement_limit`               | integer | no       | Maximum storage size for root namespace limit enforcement in MiB. |
| `generic_packages_max_file_size`  | integer | no       | Maximum generic package file size in bytes. |
| `helm_max_file_size`              | integer | no       | Maximum Helm chart file size in bytes. |
| `maven_max_file_size`             | integer | no       | Maximum Maven package file size in bytes. |
| `notification_limit`              | integer | no       | Maximum storage size for root namespace limit notifications in MiB. |
| `npm_max_file_size`               | integer | no       | Maximum NPM package file size in bytes. |
| `nuget_max_file_size`             | integer | no       | Maximum NuGet package file size in bytes. |
| `pypi_max_file_size`              | integer | no       | Maximum PyPI package file size in bytes. |
| `terraform_module_max_file_size`  | integer | no       | Maximum Terraform Module package file size in bytes. |
| `storage_size_limit`              | integer | no       | Maximum storage size for the root namespace in MiB. |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/plan_limits?plan_name=default&conan_max_file_size=3221225472"
```

Example response:

```json
{
  "ci_instance_level_variables": 25,
  "ci_pipeline_size": 0,
  "ci_active_jobs": 0,
  "ci_project_subscriptions": 2,
  "ci_pipeline_schedules": 10,
  "ci_needs_size_limit": 50,
  "ci_registered_group_runners": 1000,
  "ci_registered_project_runners": 1000,
  "conan_max_file_size": 3221225472,
  "dotenv_variables": 20,
  "dotenv_size": 5120,
  "generic_packages_max_file_size": 5368709120,
  "helm_max_file_size": 5242880,
  "maven_max_file_size": 3221225472,
  "npm_max_file_size": 524288000,
  "nuget_max_file_size": 524288000,
  "pypi_max_file_size": 3221225472,
  "terraform_module_max_file_size": 1073741824
}
```
