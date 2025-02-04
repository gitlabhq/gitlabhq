---
stage: Package
group: Package Registry
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Package Settings
---

This page includes an exhaustive list of settings related to and maintained by the package stage.

## Instance Settings

### Package registry

| Setting | Table | Description |
| ------- | ----- | -----------|
| `nuget_skip_metadata_url_validation` | `application_settings` | Indicates whether to skip metadata URL validation for the NuGet package. |
| `npm_package_requests_forwarding` | `application_settings` | Enables or disables npm package forwarding for the instance. |
| `pypi_package_requests_forwarding` | `application_settings` | Enables or disables PyPI package forwarding for the instance. |
| `packages_cleanup_package_file_worker_capacity` | `application_settings` | Number of concurrent workers allowed for package file cleanup. |
| `package_registry_allow_anyone_to_pull_option`  | `application_settings` | Enables or disables the `Allow anyone to pull from Package Registry` toggle. |
| `throttle_unauthenticated_packages_api_requests_per_period` | `application_settings` | Request limit for unauthenticated package API requests in the period defined by `throttle_unauthenticated_packages_api_period_in_seconds`. |
| `throttle_unauthenticated_packages_api_period_in_seconds`  | `application_settings` | Period in seconds to measure unauthenticated package API requests. |
| `throttle_authenticated_packages_api_requests_per_period` | `application_settings` | Request limit for authenticated package API requests in the period defined by `throttle_authenticated_packages_api_period_in_seconds`. |
| `throttle_authenticated_packages_api_period_in_seconds` | `application_settings` | Period in seconds to measure authenticated package API requests. |
| `throttle_unauthenticated_packages_api_enabled` | `application_settings` | |
| `throttle_authenticated_packages_api_enabled` | `application_settings` | Enables or disables request limits/throttling for the package API. |
| `conan_max_file_size` | `plan_limits` | Maximum file size for a Conan package file. |
| `maven_max_file_size` | `plan_limits` | Maximum file size for a Maven package file. |
| `npm_max_file_size` | `plan_limits` | Maximum file size for an npm package file. |
| `nuget_max_file_size` | `plan_limits` | Maximum file size for a NuGet package file. |
| `pypi_max_file_size` | `plan_limits` | Maximum file size for a PyPI package file. |
| `generic_packages_max_file_size` | `plan_limits` | Maximum file size for a generic package file. |
| `golang_max_file_size` | `plan_limits` | Maximum file size for a GoProxy package file. |
| `debian_max_file_size` | `plan_limits` | Maximum file size for a Debian package file. |
| `rubygems_max_file_size` | `plan_limits` | Maximum file size for a RubyGems package file. |
| `terraform_module_max_file_size` | `plan_limits` | Maximum file size for a Terraform package file. |
| `helm_max_file_size` | `plan_limits` | Maximum file size for a Helm package file. |

### Container registry

| Setting | Table | Description |
| ------- | ----- | -----------|
| `container_registry_token_expire_delay` | `application_settings` | The time in minutes before the container registry auth token (JWT) expires. |
| `container_expiration_policies_enable_historic_entries` | `application_settings` | Allow or prevent projects older than 12.8 to use container cleanup policies. |
| `container_registry_vendor` | `application_settings` | The vendor of the container registry. `gitlab` for the GitLab container registry, other values for external registries. |
| `container_registry_version` | `application_settings` | The current version of the container registry. |
| `container_registry_features` | `application_settings` | Features supported by the connected container registry. For example, tag deletion. |
| `container_registry_delete_tags_service_timeout` | `application_settings` | The maximum time (in seconds) that the cleanup process can take to delete a batch of tags. |
| `container_registry_expiration_policies_worker_capacity` | `application_settings` | Number of concurrent container image cleanup policy workers allowed. |
| `container_registry_cleanup_tags_service_max_list_size` | `application_settings` | The maximum number of tags that can be deleted in a cleanup policy single execution. Additional tags must be deleted in another execution. |
| `container_registry_expiration_policies_caching` | `application_settings` | Enable or disable tag creation timestamp caching during execution of cleanup policies. |
| `container_registry_import_max_tags_count` | `application_settings` | **Deprecated** in 17.0. The migration for GitLab.com is now complete so we are starting to cleanup this field. This field returns 0 until it gets removed. |
| `container_registry_import_max_retries` | `application_settings` | **Deprecated** in 17.0. The migration for GitLab.com is now complete so we are starting to cleanup this field. This field returns 0 until it gets removed. |
| `container_registry_import_start_max_retries` | `application_settings` | **Deprecated** in 17.0. The migration for GitLab.com is now complete so we are starting to cleanup this field. This field returns 0 until it gets removed. |
| `container_registry_import_max_step_duration` | `application_settings` | **Deprecated** in 17.0. The migration for GitLab.com is now complete so we are starting to cleanup this field. This field returns 0 until it gets removed. |
| `container_registry_import_target_plan` | `application_settings` | **Deprecated** in 17.0. The migration for GitLab.com is now complete so we are starting to cleanup this field. This field returns an empty string ('') until it gets removed. |
| `container_registry_import_created_before` | `application_settings` | **Deprecated** in 17.0. The migration for GitLab.com is now complete so we are starting to cleanup this field. This field returns an empty string ('') until it gets removed. |
| `container_registry_pre_import_timeout` | `application_settings` | **Deprecated** in 17.0. The migration for GitLab.com is now complete so we are starting to cleanup this field. This field returns an empty string ('') until it gets removed. |
| `container_registry_import_timeout` | `application_settings` | **Deprecated** in 17.0. The migration for GitLab.com is now complete so we are starting to cleanup this field. This field returns an empty string ('') until it gets removed. |
| `dependency_proxy_ttl_group_policy_worker_capacity` | `application_settings` | Number of concurrent dependency proxy cleanup policy workers allowed. |

## Namespace/Group Settings

| Setting | Table | Description |
| ------- | ----- | -----------|
| `maven_duplicates_allowed` | `namespace_package_settings` | Allow or prevent duplicate Maven packages. |
| `maven_duplicate_exception_regex` | `namespace_package_settings` | Regex defining Maven packages that are allowed to be duplicate when duplicates are not allowed. This matches the name and version of the package. |
| `generic_duplicates_allowed` | `namespace_package_settings` | Allow or prevent duplicate generic packages. |
| `generic_duplicate_exception_regex` | `namespace_package_settings` | Regex defining generic packages that are allowed to be duplicate when duplicates are not allowed. |
| `nuget_duplicates_allowed` | `namespace_package_settings` | Allow or prevent duplicate NuGet packages. |
| `nuget_duplicate_exception_regex` | `namespace_package_settings` | Regex defining NuGet packages that are allowed to be duplicate when duplicates are not allowed. |
| `nuget_symbol_server_enabled` | `namespace_package_settings` | Enable or disable the NuGet symbol server. |
| `terraform_module_duplicates_allowed` | `namespace_package_settings` | Allow or prevent duplicate Terraform module packages. |
| `terraform_module_duplicate_exception_regex` | `namespace_package_settings` | Regex defining Terraform module packages that are allowed to be duplicate when duplicates are not allowed. |
| Dependency Proxy Cleanup Policies - `ttl` | `dependency_proxy_image_ttl_group_policies` | Number of days to retain an unused Dependency Proxy file before it is removed. |
| Dependency Proxy - `enabled` | `dependency_proxy_image_ttl_group_policies` | Enable or disable the Dependency Proxy cleanup policy. |

## Project Settings

| Setting | Table | Description |
| ------- | ----- | -----------|
| Container Cleanup Policies - `next_run_at` | `container_expiration_policies` | When the project qualifies for the next container cleanup policy cron worker. |
| Container Cleanup Policies - `name_regex` | `container_expiration_policies` | Regex defining image names to remove with the container cleanup policy. |
| Container Cleanup Policies - `cadence` | `container_expiration_policies` | How often the container cleanup policy should run. |
| Container Cleanup Policies - `older_than` | `container_expiration_policies` | Age of images to remove with the container cleanup policy. |
| Container Cleanup Policies - `keep_n` | `container_expiration_policies` | Number of images to retain in a container cleanup policy. |
| Container Cleanup Policies - `enabled` | `container_expiration_policies` | Enable or disable a container cleanup policy. |
| Container Cleanup Policies - `name_regex_keep` | `container_expiration_policies` | Regex defining image names to always keep regardless of other rules with the container cleanup policy. |
