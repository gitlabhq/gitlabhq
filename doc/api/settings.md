---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Application settings API **(FREE SELF)**

These API calls allow you to read and modify GitLab instance
[application settings](#list-of-settings-that-can-be-accessed-via-api-calls)
as they appear in `/admin/application_settings/general`. You must be an
administrator to perform this action.

Application settings are subject to caching and may not immediately take effect.
By default, GitLab caches application settings for 60 seconds.
For information on how to control the application settings cache for an instance, see [Application cache interval](../administration/application_settings_cache.md).

## Get current application settings

List the current [application settings](#list-of-settings-that-can-be-accessed-via-api-calls)
of the GitLab instance.

```plaintext
GET /application/settings
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings"
```

Example response:

```json
{
  "default_projects_limit" : 100000,
  "signup_enabled" : true,
  "id" : 1,
  "default_branch_protection" : 2,
  "default_preferred_language" : "en",
  "restricted_visibility_levels" : [],
  "password_authentication_enabled_for_web" : true,
  "after_sign_out_path" : null,
  "max_attachment_size" : 10,
  "max_export_size": 50,
  "max_import_size": 50,
  "user_oauth_applications" : true,
  "updated_at" : "2016-01-04T15:44:55.176Z",
  "session_expire_delay" : 10080,
  "home_page_url" : null,
  "default_snippet_visibility" : "private",
  "outbound_local_requests_whitelist": [],
  "domain_allowlist" : [],
  "domain_denylist_enabled" : false,
  "domain_denylist" : [],
  "created_at" : "2016-01-04T15:44:55.176Z",
  "default_ci_config_path" : null,
  "default_project_visibility" : "private",
  "default_group_visibility" : "private",
  "gravatar_enabled" : true,
  "sign_in_text" : null,
  "container_expiration_policies_enable_historic_entries": true,
  "container_registry_cleanup_tags_service_max_list_size": 200,
  "container_registry_delete_tags_service_timeout": 250,
  "container_registry_expiration_policies_caching": true,
  "container_registry_expiration_policies_worker_capacity": 4,
  "container_registry_token_expire_delay": 5,
  "repository_storages_weighted": {"default": 100},
  "plantuml_enabled": false,
  "plantuml_url": null,
  "kroki_enabled": false,
  "kroki_url": null,
  "terminal_max_session_time": 0,
  "polling_interval_multiplier": 1.0,
  "rsa_key_restriction": 0,
  "dsa_key_restriction": 0,
  "ecdsa_key_restriction": 0,
  "ed25519_key_restriction": 0,
  "ecdsa_sk_key_restriction": 0,
  "ed25519_sk_key_restriction": 0,
  "first_day_of_week": 0,
  "enforce_terms": true,
  "terms": "Hello world!",
  "performance_bar_allowed_group_id": 42,
  "user_show_add_ssh_key_message": true,
  "local_markdown_version": 0,
  "allow_local_requests_from_hooks_and_services": true,
  "allow_local_requests_from_web_hooks_and_services": true,
  "allow_local_requests_from_system_hooks": false,
  "asset_proxy_enabled": true,
  "asset_proxy_url": "https://assets.example.com",
  "asset_proxy_whitelist": ["example.com", "*.example.com", "your-instance.com"],
  "asset_proxy_allowlist": ["example.com", "*.example.com", "your-instance.com"],
  "maven_package_requests_forwarding": true,
  "npm_package_requests_forwarding": true,
  "pypi_package_requests_forwarding": true,
  "snippet_size_limit": 52428800,
  "issues_create_limit": 300,
  "raw_blob_request_limit": 300,
  "wiki_page_max_content_bytes": 52428800,
  "require_admin_approval_after_user_signup": false,
  "personal_access_token_prefix": "glpat-",
  "rate_limiting_response_text": null,
  "keep_latest_artifact": true,
  "admin_mode": false,
  "floc_enabled": false,
  "external_pipeline_validation_service_timeout": null,
  "external_pipeline_validation_service_token": null,
  "external_pipeline_validation_service_url": null,
  "jira_connect_application_key": null,
  "jira_connect_proxy_url": null,
  "silent_mode_enabled": false
}
```

Users on [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) may also see
the `group_owners_can_manage_default_branch_protection`, `file_template_project_id`, `delayed_project_deletion`,
`delayed_group_deletion`, `default_project_deletion_protection`, `deletion_adjourned_period`, `disable_personal_access_tokens`, `geo_node_allowed_ips`,
or the `security_policy_global_group_approvers_enabled` parameters.

From [GitLab 15.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332), with the `always_perform_delayed_deletion` feature flag enabled,
the `delayed_project_deletion` and `delayed_group_deletion` attributes will not be exposed. These attributes will be removed in GitLab 16.0.

```json
{
  "id": 1,
  "signup_enabled": true,
  "group_owners_can_manage_default_branch_protection": true,
  "file_template_project_id": 1,
  "geo_node_allowed_ips": "0.0.0.0/0, ::/0",
  "delayed_project_deletion": false,
  "delayed_group_deletion": false,
  "default_project_deletion_protection": false,
  "deletion_adjourned_period": 7,
  "disable_personal_access_tokens": false,
  ...
}
```

## Change application settings

Use an API call to modify GitLab instance
[application settings](#list-of-settings-that-can-be-accessed-via-api-calls).

```plaintext
PUT /application/settings
```

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings?signup_enabled=false&default_project_visibility=internal"
```

Example response:

```json
{
  "id": 1,
  "default_projects_limit": 100000,
  "default_preferred_language": "en",
  "signup_enabled": false,
  "password_authentication_enabled_for_web": true,
  "gravatar_enabled": true,
  "sign_in_text": "",
  "created_at": "2015-06-12T15:51:55.432Z",
  "updated_at": "2015-06-30T13:22:42.210Z",
  "home_page_url": "",
  "default_branch_protection": 2,
  "restricted_visibility_levels": [],
  "max_attachment_size": 10,
  "max_export_size": 50,
  "max_import_size": 50,
  "session_expire_delay": 10080,
  "default_ci_config_path" : null,
  "default_project_visibility": "internal",
  "default_snippet_visibility": "private",
  "default_group_visibility": "private",
  "outbound_local_requests_whitelist": [],
  "domain_allowlist": [],
  "domain_denylist_enabled" : false,
  "domain_denylist" : [],
  "external_authorization_service_enabled": true,
  "external_authorization_service_url": "https://authorize.me",
  "external_authorization_service_default_label": "default",
  "external_authorization_service_timeout": 0.5,
  "user_oauth_applications": true,
  "after_sign_out_path": "",
  "container_expiration_policies_enable_historic_entries": true,
  "container_registry_cleanup_tags_service_max_list_size": 200,
  "container_registry_delete_tags_service_timeout": 250,
  "container_registry_expiration_policies_caching": true,
  "container_registry_expiration_policies_worker_capacity": 4,
  "container_registry_token_expire_delay": 5,
  "package_registry_cleanup_policies_worker_capacity": 2,
  "repository_storages": ["default"],
  "plantuml_enabled": false,
  "plantuml_url": null,
  "terminal_max_session_time": 0,
  "polling_interval_multiplier": 1.0,
  "rsa_key_restriction": 0,
  "dsa_key_restriction": 0,
  "ecdsa_key_restriction": 0,
  "ed25519_key_restriction": 0,
  "ecdsa_sk_key_restriction": 0,
  "ed25519_sk_key_restriction": 0,
  "first_day_of_week": 0,
  "enforce_terms": true,
  "terms": "Hello world!",
  "performance_bar_allowed_group_id": 42,
  "user_show_add_ssh_key_message": true,
  "file_template_project_id": 1,
  "local_markdown_version": 0,
  "asset_proxy_enabled": true,
  "asset_proxy_url": "https://assets.example.com",
  "asset_proxy_allowlist": ["example.com", "*.example.com", "your-instance.com"],
  "geo_node_allowed_ips": "0.0.0.0/0, ::/0",
  "allow_local_requests_from_hooks_and_services": true,
  "allow_local_requests_from_web_hooks_and_services": true,
  "allow_local_requests_from_system_hooks": false,
  "maven_package_requests_forwarding": true,
  "npm_package_requests_forwarding": true,
  "pypi_package_requests_forwarding": true,
  "snippet_size_limit": 52428800,
  "issues_create_limit": 300,
  "raw_blob_request_limit": 300,
  "wiki_page_max_content_bytes": 52428800,
  "require_admin_approval_after_user_signup": false,
  "personal_access_token_prefix": "glpat-",
  "rate_limiting_response_text": null,
  "keep_latest_artifact": true,
  "admin_mode": false,
  "external_pipeline_validation_service_timeout": null,
  "external_pipeline_validation_service_token": null,
  "external_pipeline_validation_service_url": null,
  "can_create_group": false,
  "jira_connect_application_key": "123",
  "jira_connect_proxy_url": "http://gitlab.example.com",
  "user_defaults_to_private_profile": true,
  "projects_api_rate_limit_unauthenticated": 400,
  "silent_mode_enabled": false,
  "security_policy_global_group_approvers_enabled": true
}
```

Users on [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) may also see
these parameters:

- `group_owners_can_manage_default_branch_protection`
- `file_template_project_id`
- `geo_node_allowed_ips`
- `geo_status_timeout`
- `delayed_project_deletion`
- `delayed_group_deletion`
- `default_project_deletion_protection`
- `deletion_adjourned_period`
- `disable_personal_access_tokens`
- `security_policy_global_group_approvers_enabled`

From [GitLab 15.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332), with the `always_perform_delayed_deletion` feature flag enabled,
the `delayed_project_deletion` and `delayed_group_deletion` attributes will not be exposed. These attributes will be removed in GitLab 16.0.

Example responses: **(PREMIUM SELF)**

```json
  "file_template_project_id": 1,
  "geo_node_allowed_ips": "0.0.0.0/0, ::/0"
```

## List of settings that can be accessed via API calls

> Fields `housekeeping_full_repack_period`, `housekeeping_gc_period`, and `housekeeping_incremental_repack_period` [deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106963) in GitLab 15.8. Use `housekeeping_optimize_repository_period` instead.

In general, all settings are optional. Certain settings though, if enabled,
require other settings to be set to function properly. These requirements are
listed in the descriptions of the relevant settings.

| Attribute                                | Type             | Required                             | Description |
|------------------------------------------|------------------|:------------------------------------:|-------------|
| `admin_mode`                             | boolean          | no                                   | Require administrators to enable Admin Mode by re-authenticating for administrative tasks. |
| `admin_notification_email`                | string           | no                                   | Deprecated: Use `abuse_notification_email` instead. If set, [abuse reports](../user/admin_area/review_abuse_reports.md) are sent to this address. Abuse reports are always available in the Admin Area. |
| `abuse_notification_email`                | string           | no                                   | If set, [abuse reports](../user/admin_area/review_abuse_reports.md) are sent to this address. Abuse reports are always available in the Admin Area. |
| `after_sign_out_path`                    | string           | no                                   | Where to redirect users after logout. |
| `after_sign_up_text`                     | string           | no                                   | Text shown to the user after signing up. |
| `akismet_api_key`                        | string           | required by: `akismet_enabled`       | API key for Akismet spam protection. |
| `akismet_enabled`                        | boolean          | no                                   | (**If enabled, requires:** `akismet_api_key`) Enable or disable Akismet spam protection. |
| `allow_group_owners_to_manage_ldap` **(PREMIUM)** | boolean | no                                   | Set to `true` to allow group owners to manage LDAP. |
| `allow_local_requests_from_hooks_and_services` | boolean    | no                                   | (Deprecated: Use `allow_local_requests_from_web_hooks_and_services` instead) Allow requests to the local network from webhooks and integrations. |
| `allow_local_requests_from_system_hooks` | boolean          | no                                   | Allow requests to the local network from system hooks. |
| `allow_local_requests_from_web_hooks_and_services` | boolean | no                                  | Allow requests to the local network from webhooks and integrations. |
| `allow_runner_registration_token`        | boolean          | no                                   | Allow using a registration token to create a runner. Defaults to `true`. |
| `archive_builds_in_human_readable`       | string           | no                                   | Set the duration for which the jobs are considered as old and expired. After that time passes, the jobs are archived and no longer able to be retried. Make it empty to never expire jobs. It has to be no less than 1 day, for example: <code>15 days</code>, <code>1 month</code>, <code>2 years</code>. |
| `asset_proxy_enabled`                    | boolean          | no                                   | (**If enabled, requires:** `asset_proxy_url`) Enable proxying of assets. GitLab restart is required to apply changes. |
| `asset_proxy_secret_key`                 | string           | no                                   | Shared secret with the asset proxy server. GitLab restart is required to apply changes. |
| `asset_proxy_url`                        | string           | no                                   | URL of the asset proxy server. GitLab restart is required to apply changes. |
| `asset_proxy_whitelist`                  | string or array of strings | no                         | (Deprecated: Use `asset_proxy_allowlist` instead) Assets that match these domains are **not** proxied. Wildcards allowed. Your GitLab installation URL is automatically allowlisted. GitLab restart is required to apply changes. |
| `asset_proxy_allowlist`                  | string or array of strings | no                         | Assets that match these domains are **not** proxied. Wildcards allowed. Your GitLab installation URL is automatically allowlisted. GitLab restart is required to apply changes. |
| `authorized_keys_enabled`                | boolean          | no                                   | By default, we write to the `authorized_keys` file to support Git over SSH without additional configuration. GitLab can be optimized to authenticate SSH keys via the database file. Only disable this if you have configured your OpenSSH server to use the AuthorizedKeysCommand. |
| `auto_devops_domain`                     | string           | no                                   | Specify a domain to use by default for every project's Auto Review Apps and Auto Deploy stages. |
| `auto_devops_enabled`                    | boolean          | no                                   | Enable Auto DevOps for projects by default. It automatically builds, tests, and deploys applications based on a predefined CI/CD configuration. |
| `automatic_purchased_storage_allocation` | boolean          | no                                   | Enabling this permits automatic allocation of purchased storage in a namespace. |
| `bulk_import_enabled`                    | boolean          | no                                   | Enable migrating GitLab groups by direct transfer. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383268) in GitLab 15.8. Setting also [available](../user/admin_area/settings/visibility_and_access_controls.md#enable-migration-of-groups-and-projects-by-direct-transfer) in the Admin Area. |
| `can_create_group` | boolean | no | Indicates whether users can create top-level groups. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367754) in GitLab 15.5. Defaults to `true`. |
| `check_namespace_plan` **(PREMIUM)**     | boolean          | no                                   | Enabling this makes only licensed EE features available to projects if the project namespace's plan includes the feature or if the project is public. |
| `ci_max_includes`                        | integer          | no                                   | The maximum number of [includes](../ci/yaml/includes.md) per pipeline. Default is `150`. |
| `commit_email_hostname`                  | string           | no                                   | Custom hostname (for private commit emails). |
| `container_expiration_policies_enable_historic_entries`  | boolean | no                            | Enable [cleanup policies](../user/packages/container_registry/reduce_container_registry_storage.md#enable-the-cleanup-policy) for all projects. |
| `container_registry_cleanup_tags_service_max_list_size`  | integer | no                            | The maximum number of tags that can be deleted in a single execution of [cleanup policies](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources). |
| `container_registry_delete_tags_service_timeout`  | integer | no                                   | The maximum time, in seconds, that the cleanup process can take to delete a batch of tags for [cleanup policies](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources). |
| `container_registry_expiration_policies_caching`  | boolean | no                                   | Caching during the execution of [cleanup policies](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources). |
| `container_registry_expiration_policies_worker_capacity`  | integer          | no                  | Number of workers for [cleanup policies](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources). |
| `container_registry_token_expire_delay`  | integer          | no                                   | Container Registry token duration in minutes. |
| `package_registry_cleanup_policies_worker_capacity`  | integer          | no                  | Number of workers assigned to the packages cleanup policies. |
| `deactivate_dormant_users`               | boolean          | no                                   | Enable [automatic deactivation of dormant users](../user/admin_area/moderate_users.md#automatically-deactivate-dormant-users). |
| `deactivate_dormant_users_period`        | integer          | no                                   | Length of time (in days) after which a user is considered dormant. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336747) in GitLab 15.3. |
| `default_artifacts_expire_in`            | string           | no                                   | Set the default expiration time for each job's artifacts. |
| `default_branch_name`                    | string           | no                                   | [Instance-level custom initial branch name](../user/project/repository/branches/default.md#instance-level-custom-initial-branch-name). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225258) in GitLab 13.2. |
| `default_branch_protection`              | integer          | no                                   | Determine if developers can push to the default branch. Can take: `0` _(not protected, both users with the Developer role or Maintainer role can push new commits and force push)_, `1` _(partially protected, users with the Developer role or Maintainer role can push new commits, but cannot force push)_ or `2` _(fully protected, users with the Developer or Maintainer role cannot push new commits, but users with the Developer or Maintainer role can; no one can force push)_ as a parameter. Default is `2`. |
| `default_ci_config_path`                  | string           | no                                   | Default CI/CD configuration file and path for new projects (`.gitlab-ci.yml` if not set). |
| `default_group_visibility`               | string           | no                                   | What visibility level new groups receive. Can take `private`, `internal` and `public` as a parameter. Default is `private`. |
| `default_preferred_language`             | string           | no                                   | Default preferred language for users who are not logged in. |
| `default_project_creation`               | integer          | no                                   | Default project creation protection. Can take: `0` _(No one)_, `1` _(Maintainers)_ or `2` _(Developers + Maintainers)_|
| `default_project_visibility`             | string           | no                                   | What visibility level new projects receive. Can take `private`, `internal` and `public` as a parameter. Default is `private`. |
| `default_projects_limit`                 | integer          | no                                   | Project limit per user. Default is `100000`. |
| `default_snippet_visibility`             | string           | no                                   | What visibility level new snippets receive. Can take `private`, `internal` and `public` as a parameter. Default is `private`. |
| `default_syntax_highlighting_theme`      | integer          | no                                   | Default syntax highlighting theme for new users and users who are not signed in. See [IDs of available themes](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16).
| `delayed_project_deletion` **(PREMIUM SELF)** | boolean     | no                                   | Enable delayed project deletion by default in new groups. Default is `false`. [From GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/352960), can only be enabled when `delayed_group_deletion` is true. From [GitLab 15.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332), with the `always_perform_delayed_deletion` feature flag enabled, this attribute has been removed. This attribute will be completely removed in GitLab 16.0. |
| `delayed_group_deletion` **(PREMIUM SELF)**   | boolean     | no                                   | Enable delayed group deletion. Default is `true`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352959) in GitLab 15.0. [From GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/352960), disables and locks the group-level setting for delayed protect deletion when set to `false`. From [GitLab 15.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332), with the `always_perform_delayed_deletion` feature flag enabled, this attribute has been removed. This attribute will be completely removed in GitLab 16.0. |
| `default_project_deletion_protection` **(PREMIUM SELF)** | boolean | no                            | Enable default project deletion protection so only administrators can delete projects. Default is `false`. |
| `deletion_adjourned_period` **(PREMIUM SELF)** | integer    | no                                   | The number of days to wait before deleting a project or group that is marked for deletion. Value must be between `1` and `90`. Defaults to `7`. [From GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/352960), a hook on `deletion_adjourned_period` sets the period to `1` on every update, and sets both `delayed_project_deletion` and `delayed_group_deletion` to `false` if the period is `0`. |
| `diff_max_patch_bytes`                   | integer          | no                                   | Maximum [diff patch size](../user/admin_area/diff_limits.md), in bytes. |
| `diff_max_files`                         | integer          | no                                   | Maximum [files in a diff](../user/admin_area/diff_limits.md). |
| `diff_max_lines`                         | integer          | no                                   | Maximum [lines in a diff](../user/admin_area/diff_limits.md). |
| `disable_admin_oauth_scopes`             | boolean          | no                                   | Stops administrators from connecting their GitLab accounts to non-trusted OAuth 2.0 applications that have the `api`, `read_api`, `read_repository`, `write_repository`, `read_registry`, `write_registry`, or `sudo` scopes. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/375043) in GitLab 15.6. |
| `disable_feed_token`                     | boolean          | no                                   | Disable display of RSS/Atom and calendar feed tokens. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/231493) in GitLab 13.7. |
| `disable_personal_access_token` **(PREMIUM SELF)** | boolean | no                                  | Disable personal access tokens. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/384201) in GitLab 15.7. |
| `disabled_oauth_sign_in_sources`         | array of strings | no                                   | Disabled OAuth sign-in sources. |
| `dns_rebinding_protection_enabled`       | boolean          | no                                   | Enforce DNS-rebinding attack protection. |
| `domain_denylist_enabled`                | boolean          | no                                   | (**If enabled, requires:** `domain_denylist`) Allows blocking sign-ups from emails from specific domains. |
| `domain_denylist`                        | array of strings | no                                   | Users with email addresses that match these domains **cannot** sign up. Wildcards allowed. Use separate lines for multiple entries. For example: `domain.com`, `*.domain.com`. |
| `domain_allowlist`                       | array of strings | no                                   | Force people to use only corporate emails for sign-up. Default is `null`, meaning there is no restriction. |
| `dsa_key_restriction`                    | integer          | no                                   | The minimum allowed bit length of an uploaded DSA key. Default is `0` (no restriction). `-1` disables DSA keys. |
| `ecdsa_key_restriction`                  | integer          | no                                   | The minimum allowed curve size (in bits) of an uploaded ECDSA key. Default is `0` (no restriction). `-1` disables ECDSA keys. |
| `ecdsa_sk_key_restriction`               | integer          | no                                   | The minimum allowed curve size (in bits) of an uploaded ECDSA_SK key. Default is `0` (no restriction). `-1` disables ECDSA_SK keys. |
| `ed25519_key_restriction`                | integer          | no                                   | The minimum allowed curve size (in bits) of an uploaded ED25519 key. Default is `0` (no restriction). `-1` disables ED25519 keys. |
| `ed25519_sk_key_restriction`             | integer          | no                                   | The minimum allowed curve size (in bits) of an uploaded ED25519_SK key. Default is `0` (no restriction). `-1` disables ED25519_SK keys. |
| `eks_access_key_id`                      | string           | no                                   | AWS IAM access key ID. |
| `eks_account_id`                         | string           | no                                   | Amazon account ID. |
| `eks_integration_enabled`                | boolean          | no                                   | Enable integration with Amazon EKS. |
| `eks_secret_access_key`                  | string           | no                                   | AWS IAM secret access key. |
| `elasticsearch_aws_access_key` **(PREMIUM)** | string       | no                                   | AWS IAM access key. |
| `elasticsearch_aws_region` **(PREMIUM)** | string           | no                                   | The AWS region the Elasticsearch domain is configured. |
| `elasticsearch_aws_secret_access_key` **(PREMIUM)** | string | no                                   | AWS IAM secret access key. |
| `elasticsearch_aws` **(PREMIUM)**        | boolean          | no                                   | Enable the use of AWS hosted Elasticsearch. |
| `elasticsearch_indexed_field_length_limit` **(PREMIUM)** | integer | no                                   | Maximum size of text fields to index by Elasticsearch. 0 value means no limit. This does not apply to repository and wiki indexing. |
| `elasticsearch_indexed_file_size_limit_kb` **(PREMIUM)** | integer | no                                   | Maximum size of repository and wiki files that are indexed by Elasticsearch. |
| `elasticsearch_indexing` **(PREMIUM)**   | boolean          | no                                   | Enable Elasticsearch indexing. |
| `elasticsearch_limit_indexing` **(PREMIUM)** | boolean      | no                                   | Limit Elasticsearch to index certain namespaces and projects. |
| `elasticsearch_max_bulk_concurrency` **(PREMIUM)** | integer | no                                   | Maximum concurrency of Elasticsearch bulk requests per indexing operation. This only applies to repository indexing operations. |
| `elasticsearch_max_bulk_size_mb` **(PREMIUM)** | integer    | no                                   | Maximum size of Elasticsearch bulk indexing requests in MB. This only applies to repository indexing operations. |
| `elasticsearch_namespace_ids` **(PREMIUM)** | array of integers | no                                  | The namespaces to index via Elasticsearch if `elasticsearch_limit_indexing` is enabled. |
| `elasticsearch_project_ids` **(PREMIUM)** | array of integers | no                                  | The projects to index via Elasticsearch if `elasticsearch_limit_indexing` is enabled. |
| `elasticsearch_search` **(PREMIUM)**     | boolean          | no                                   | Enable Elasticsearch search. |
| `elasticsearch_url` **(PREMIUM)**        | string           | no                                   | The URL to use for connecting to Elasticsearch. Use a comma-separated list to support cluster (for example, `http://localhost:9200, http://localhost:9201"`). |
| `elasticsearch_username` **(PREMIUM)**   | string           | no                                   | The `username` of your Elasticsearch instance. |
| `elasticsearch_password` **(PREMIUM)**   | string           | no                                   | The password of your Elasticsearch instance. |
| `email_additional_text` **(PREMIUM)**    | string           | no                                   | Additional text added to the bottom of every email for legal/auditing/compliance reasons. |
| `email_author_in_body`                   | boolean          | no                                   | Some email servers do not support overriding the email sender name. Enable this option to include the name of the author of the issue, merge request or comment in the email body instead. |
| `email_confirmation_setting`             | string           | no                                   | Specifies whether users must confirm their email before sign in. Possible values are `off`, `soft`, and `hard`. |
| `enabled_git_access_protocol`            | string           | no                                   | Enabled protocols for Git access. Allowed values are: `ssh`, `http`, and `nil` to allow both protocols. |
| `enforce_namespace_storage_limit`        | boolean          | no                                   | Enabling this permits enforcement of namespace storage limits. |
| `enforce_terms`                          | boolean          | no                                   | (**If enabled, requires:** `terms`) Enforce application ToS to all users. |
| `external_auth_client_cert`              | string           | no                                   | (**If enabled, requires:** `external_auth_client_key`) The certificate to use to authenticate with the external authorization service. |
| `external_auth_client_key_pass`          | string           | no                                   | Passphrase to use for the private key when authenticating with the external service this is encrypted when stored. |
| `external_auth_client_key`               | string           | required by: `external_auth_client_cert` | Private key for the certificate when authentication is required for the external authorization service, this is encrypted when stored. |
| `external_authorization_service_default_label` | string     | required by:<br>`external_authorization_service_enabled` | The default classification label to use when requesting authorization and no classification label has been specified on the project. |
| `external_authorization_service_enabled` | boolean          | no                                   | (**If enabled, requires:** `external_authorization_service_default_label`, `external_authorization_service_timeout` and `external_authorization_service_url`) Enable using an external authorization service for accessing projects. |
| `external_authorization_service_timeout` | float             | required by:<br>`external_authorization_service_enabled` | The timeout after which an authorization request is aborted, in seconds. When a request times out, access is denied to the user. (min: 0.001, max: 10, step: 0.001). |
| `external_authorization_service_url`     | string           | required by:<br>`external_authorization_service_enabled` | URL to which authorization requests are directed. |
| `external_pipeline_validation_service_url` | string         | no                                   | URL to use for pipeline validation requests. |
| `external_pipeline_validation_service_token` | string       | no                                   | Optional. Token to include as the `X-Gitlab-Token` header in requests to the URL in `external_pipeline_validation_service_url`. |
| `external_pipeline_validation_service_timeout` | integer    | no                                   | How long to wait for a response from the pipeline validation service. Assumes `OK` if it times out. |
| `file_template_project_id` **(PREMIUM)**  | integer          | no                                   | The ID of a project to load custom file templates from. |
| `first_day_of_week`                       | integer          | no                                   | Start day of the week for calendar views and date pickers. Valid values are `0` (default) for Sunday, `1` for Monday, and `6` for Saturday. |
| `geo_node_allowed_ips` **(PREMIUM)**     | string           | yes                                  | Comma-separated list of IPs and CIDRs of allowed secondary nodes. For example, `1.1.1.1, 2.2.2.0/24`. |
| `geo_status_timeout` **(PREMIUM)**       | integer          | no                                   | The amount of seconds after which a request to get a secondary node status times out. |
| `git_two_factor_session_expiry` **(PREMIUM)** | integer     | no                                   | Maximum duration (in minutes) of a session for Git operations when 2FA is enabled. |
| `gitaly_timeout_default`                 | integer          | no                                   | Default Gitaly timeout, in seconds. This timeout is not enforced for Git fetch/push operations or Sidekiq jobs. Set to `0` to disable timeouts. |
| `gitaly_timeout_fast`                    | integer          | no                                   | Gitaly fast operation timeout, in seconds. Some Gitaly operations are expected to be fast. If they exceed this threshold, there may be a problem with a storage shard and 'failing fast' can help maintain the stability of the GitLab instance. Set to `0` to disable timeouts. |
| `gitaly_timeout_medium`                  | integer          | no                                   | Medium Gitaly timeout, in seconds. This should be a value between the Fast and the Default timeout. Set to `0` to disable timeouts. |
| `gitlab_dedicated_instance`              | boolean          | no                                   | Indicates whether the instance was provisioned for GitLab Dedicated. |
| `grafana_enabled`                        | boolean          | no                                   | Enable Grafana. |
| `grafana_url`                            | string           | no                                   | Grafana URL. |
| `gravatar_enabled`                       | boolean          | no                                   | Enable Gravatar. |
| `group_owners_can_manage_default_branch_protection` **(PREMIUM SELF)** | boolean | no                                 | Prevent overrides of default branch protection. |
| `hashed_storage_enabled`                 | boolean          | no                                   | Create new projects using hashed storage paths: Enable immutable, hash-based paths and repository names to store repositories on disk. This prevents repositories from having to be moved or renamed when the Project URL changes and may improve disk I/O performance. (Always enabled in GitLab versions 13.0 and later, configuration is scheduled for removal in 14.0) |
| `help_page_hide_commercial_content`      | boolean          | no                                   | Hide marketing-related entries from help. |
| `help_page_support_url`                  | string           | no                                   | Alternate support URL for help page and help dropdown list. |
| `help_page_text`                         | string           | no                                   | Custom text displayed on the help page. |
| `help_text` **(PREMIUM)**                | string           | no                                   | GitLab server administrator information. |
| `hide_third_party_offers`                | boolean          | no                                   | Do not display offers from third parties in GitLab. |
| `home_page_url`                          | string           | no                                   | Redirect to this URL when not logged in. |
| `housekeeping_bitmaps_enabled`           | boolean          | no                                   | Deprecated. Git pack file bitmap creation is always enabled and cannot be changed via API and UI. Always returns `true`. |
| `housekeeping_enabled`                   | boolean          | no                                   | Enable or disable Git housekeeping. Requires additional fields to be set. For more information, see [Housekeeping fields](#housekeeping-fields). |
| `housekeeping_full_repack_period`        | integer          | no                                   | Deprecated. Number of Git pushes after which an incremental `git repack` is run. Use `housekeeping_optimize_repository_period` instead. For more information, see [Housekeeping fields](#housekeeping-fields). |
| `housekeeping_gc_period`                 | integer          | no                                   | Deprecated. Number of Git pushes after which `git gc` is run. Use `housekeeping_optimize_repository_period` instead. For more information, see [Housekeeping fields](#housekeeping-fields). |
| `housekeeping_incremental_repack_period` | integer          | no                                   | Deprecated. Number of Git pushes after which an incremental `git repack` is run. Use `housekeeping_optimize_repository_period` instead. For more information, see [Housekeeping fields](#housekeeping-fields).|
| `housekeeping_optimize_repository_period`| integer          | no                                   | Number of Git pushes after which an incremental `git repack` is run. |
| `html_emails_enabled`                    | boolean          | no                                   | Enable HTML emails. |
| `import_sources`                         | array of strings | no                                   | Sources to allow project import from, possible values: `github`, `bitbucket`, `bitbucket_server`, `fogbugz`, `git`, `gitlab_project`, `gitea`, and `manifest`. |
| `in_product_marketing_emails_enabled`    | boolean          | no                                   | Enable [in-product marketing emails](../user/profile/notifications.md#global-notification-settings). Enabled by default. |
| `invisible_captcha_enabled`              | boolean          | no                                   | Enable Invisible CAPTCHA spam detection during sign-up. Disabled by default. |
| `issues_create_limit`                    | integer          | no                                   | Max number of issue creation requests per minute per user. Disabled by default.|
| `keep_latest_artifact`                   | boolean          | no                                   | Prevent the deletion of the artifacts from the most recent successful jobs, regardless of the expiry time. Enabled by default. |
| `local_markdown_version`                 | integer          | no                                   | Increase this value when any cached Markdown should be invalidated. |
| `mailgun_signing_key`                    | string           | no                                   | The Mailgun HTTP webhook signing key for receiving events from webhook. |
| `mailgun_events_enabled`                 | boolean          | no                                   | Enable Mailgun event receiver. |
| `maintenance_mode_message` **(PREMIUM)** | string           | no                                   | Message displayed when instance is in maintenance mode. |
| `maintenance_mode` **(PREMIUM)**         | boolean          | no                                   | When instance is in maintenance mode, non-administrative users can sign in with read-only access and make read-only API requests. |
| `max_artifacts_size`                     | integer          | no                                   | Maximum artifacts size in MB. |
| `max_attachment_size`                    | integer          | no                                   | Limit attachment size in MB. |
| `max_export_size`                        | integer          | no                                   | Maximum export size in MB. 0 for unlimited. Default = 0 (unlimited). |
| `max_import_size`                        | integer          | no                                   | Maximum import size in MB. 0 for unlimited. Default = 0 (unlimited). [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50 MB to 0 in GitLab 13.8. |
| `max_pages_size`                         | integer          | no                                   | Maximum size of pages repositories in MB. |
| `max_personal_access_token_lifetime` **(ULTIMATE SELF)** | integer | no                                   | Maximum allowable lifetime for access tokens in days. |
| `max_ssh_key_lifetime` **(ULTIMATE SELF)** | integer        | no                                   | Maximum allowable lifetime for SSH keys in days. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1007) in GitLab 14.6. |
| `max_terraform_state_size_bytes`         | integer | no                                         | Maximum size in bytes of the [Terraform state](../administration/terraform_state.md) files. Set this to 0 for unlimited file size. |
| `metrics_method_call_threshold`          | integer          | no                                   | A method call is only tracked when it takes longer than the given amount of milliseconds. |
| `max_number_of_repository_downloads` **(ULTIMATE SELF)**                             | integer          | no | Maximum number of unique repositories a user can download in the specified time period before they are banned. Default: 0, Maximum: 10,000 repositories. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87980) in GitLab 15.1. |
| `max_number_of_repository_downloads_within_time_period` **(ULTIMATE SELF)**          | integer          | no | Reporting time period (in seconds). Default: 0, Maximum: 864000 seconds (10 days). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87980) in GitLab 15.1. |
| `git_rate_limit_users_allowlist` **(ULTIMATE SELF)**          | array of strings          | no                                   | List of usernames excluded from Git anti-abuse rate limits. Default: `[]`, Maximum: 100 usernames. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90815) in GitLab 15.2. |
| `git_rate_limit_users_alertlist` **(ULTIMATE SELF)**          | array of integers         | no     | List of user IDs that are emailed when the Git abuse rate limit is exceeded. Default: `[]`, Maximum: 100 user IDs. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110201) in GitLab 15.9. |
| `auto_ban_user_on_excessive_projects_download` **(ULTIMATE SELF)**          | boolean          | no                                   | When enabled, users will get automatically banned from the application when they download more than the maximum number of unique projects in the time period specified by `max_number_of_repository_downloads` and `max_number_of_repository_downloads_within_time_period` respectively. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/94153) in GitLab 15.4 |
| `mirror_available`                       | boolean          | no                                   | Allow repository mirroring to configured by project Maintainers. If disabled, only Administrators can configure repository mirroring. |
| `mirror_capacity_threshold` **(PREMIUM)** | integer          | no                                   | Minimum capacity to be available before scheduling more mirrors preemptively. |
| `mirror_max_capacity` **(PREMIUM)**      | integer          | no                                   | Maximum number of mirrors that can be synchronizing at the same time. |
| `mirror_max_delay` **(PREMIUM)**         | integer          | no                                   | Maximum time (in minutes) between updates that a mirror can have when scheduled to synchronize. |
| `maven_package_requests_forwarding` **(PREMIUM)** | boolean   | no                                   | Use repo.maven.apache.org as a default remote repository when the package is not found in the GitLab Package Registry for Maven. |
| `npm_package_requests_forwarding` **(PREMIUM)** | boolean   | no                                   | Use npmjs.org as a default remote repository when the package is not found in the GitLab Package Registry for npm. |
| `pypi_package_requests_forwarding` **(PREMIUM)** | boolean  | no                                   | Use pypi.org as a default remote repository when the package is not found in the GitLab Package Registry for PyPI. |
| `outbound_local_requests_whitelist`      | array of strings | no                                   | Define a list of trusted domains or IP addresses to which local requests are allowed when local requests for webhooks and integrations are disabled.
| `pages_domain_verification_enabled`       | boolean          | no                                   | Require users to prove ownership of custom domains. Domain verification is an essential security measure for public GitLab sites. Users are required to demonstrate they control a domain before it is enabled. |
| `password_authentication_enabled_for_git` | boolean         | no                                   | Enable authentication for Git over HTTP(S) via a GitLab account password. Default is `true`. |
| `password_authentication_enabled_for_web` | boolean         | no                                   | Enable authentication for the web interface via a GitLab account password. Default is `true`. |
| `password_number_required` **(PREMIUM)**    | boolean       | no                                   | Indicates whether passwords require at least one number. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85763) in GitLab 15.1. |
| `password_symbol_required` **(PREMIUM)**    | boolean       | no                                   | Indicates whether passwords require at least one symbol character. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85763) in GitLab 15.1. |
| `password_uppercase_required` **(PREMIUM)** | boolean       | no                                   | Indicates whether passwords require at least one uppercase letter. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85763) in GitLab 15.1. |
| `password_lowercase_required` **(PREMIUM)** | boolean       | no                                   | Indicates whether passwords require at least one lowercase letter. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85763) in GitLab 15.1. |
| `performance_bar_allowed_group_id`       | string           | no                                   | (Deprecated: Use `performance_bar_allowed_group_path` instead) Path of the group that is allowed to toggle the performance bar. |
| `performance_bar_allowed_group_path`     | string           | no                                   | Path of the group that is allowed to toggle the performance bar. |
| `performance_bar_enabled`                | boolean          | no                                   | (Deprecated: Pass `performance_bar_allowed_group_path: nil` instead) Allow enabling the performance bar. |
| `personal_access_token_prefix`            | string           | no                                   | Prefix for all generated personal access tokens. |
| `pipeline_limit_per_project_user_sha`    | integer          | no                                   | Maximum number of pipeline creation requests per minute per user and commit. Disabled by default. |
| `plantuml_enabled`                       | boolean          | no                                   | (**If enabled, requires:** `plantuml_url`) Enable [PlantUML integration](../administration/integration/plantuml.md). Default is `false`. |
| `plantuml_url`                           | string           | required by: `plantuml_enabled`      | The PlantUML instance URL for integration. |
| `polling_interval_multiplier`            | decimal          | no                                   | Interval multiplier used by endpoints that perform polling. Set to `0` to disable polling. |
| `project_export_enabled`                 | boolean          | no                                   | Enable project export. |
| `projects_api_rate_limit_unauthenticated`      | integer          | no                                   | [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112283) in GitLab 15.10. Max number of requests per 10 minutes per IP address for unauthenticated requests to the [list all projects API](projects.md#list-all-projects). Default: 400. To disable throttling set to 0.|
| `prometheus_metrics_enabled`             | boolean          | no                                   | Enable Prometheus metrics. |
| `protected_ci_variables`                 | boolean          | no                                   | CI/CD variables are protected by default. |
| `push_event_activities_limit`            | integer          | no                                   | Number of changes (branches or tags) in a single push to determine whether individual push events or bulk push events are created. [Bulk push events are created](../user/admin_area/settings/push_event_activities_limit.md) if it surpasses that value. |
| `push_event_hooks_limit`                 | integer          | no                                   | Number of changes (branches or tags) in a single push to determine whether webhooks and services fire or not. Webhooks and services aren't submitted if it surpasses that value. |
| `rate_limiting_response_text`            | string           | no                                   | When rate limiting is enabled via the `throttle_*` settings, send this plain text response when a rate limit is exceeded. 'Retry later' is sent if this is blank. |
| `raw_blob_request_limit`                 | integer          | no                                   | Max number of requests per minute for each raw path. Default: 300. To disable throttling set to 0.|
| `user_email_lookup_limit`                | integer          | no                                   | **{warning}** **[Deprecated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80631/)** in GitLab 14.9 will be removed in 15.0. Replaced by `search_rate_limit`. Max number of requests per minute for email lookup. Default: 60. To disable throttling set to 0.|
| `search_rate_limit`                      | integer          | no                                   | Max number of requests per minute for performing a search while authenticated. Default: 30. To disable throttling set to 0.|
| `search_rate_limit_unauthenticated`      | integer          | no                                   | Max number of requests per minute for performing a search while unauthenticated. Default: 10. To disable throttling set to 0.|
| `recaptcha_enabled`                      | boolean          | no                                   | (**If enabled, requires:** `recaptcha_private_key` and `recaptcha_site_key`) Enable reCAPTCHA. |
| `recaptcha_private_key`                  | string           | required by: `recaptcha_enabled`     | Private key for reCAPTCHA. |
| `recaptcha_site_key`                     | string           | required by: `recaptcha_enabled`     | Site key for reCAPTCHA. |
| `receive_max_input_size`                 | integer          | no                                   | Maximum push size (MB). |
| `repository_checks_enabled`              | boolean          | no                                   | GitLab periodically runs `git fsck` in all project and wiki repositories to look for silent disk corruption issues. |
| `repository_size_limit` **(PREMIUM)**    | integer          | no                                   | Size limit per repository (MB) |
| `repository_storages_weighted`           | hash of strings to integers | no                        | (GitLab 13.1 and later) Hash of names of taken from `gitlab.yml` to [weights](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored). New projects are created in one of these stores, chosen by a weighted random selection. |
| `repository_storages`                    | array of strings | no                                   | (GitLab 13.0 and earlier) List of names of enabled storage paths, taken from `gitlab.yml`. New projects are created in one of these stores, chosen at random. |
| `require_admin_approval_after_user_signup` | boolean        | no                                   | When enabled, any user that signs up for an account using the registration form is placed under a **Pending approval** state and has to be explicitly [approved](../user/admin_area/moderate_users.md) by an administrator. |
| `require_two_factor_authentication`      | boolean          | no                                   | (**If enabled, requires:** `two_factor_grace_period`) Require all users to set up Two-factor authentication. |
| `restricted_visibility_levels`           | array of strings | no                                   | Selected levels cannot be used by non-Administrator users for groups, projects or snippets. Can take `private`, `internal` and `public` as a parameter. Default is `null` which means there is no restriction. |
| `rsa_key_restriction`                    | integer          | no                                   | The minimum allowed bit length of an uploaded RSA key. Default is `0` (no restriction). `-1` disables RSA keys. |
| `session_expire_delay`                   | integer          | no                                   | Session duration in minutes. GitLab restart is required to apply changes. |
| `security_policy_global_group_approvers_enabled` | boolean  | no                                   | Whether to look up scan result policy approval groups globally or within project hierarchies. |
| `shared_runners_enabled`                 | boolean          | no                                   | (**If enabled, requires:** `shared_runners_text` and `shared_runners_minutes`) Enable shared runners for new projects. |
| `shared_runners_minutes` **(PREMIUM)**   | integer          | required by: `shared_runners_enabled` | Set the maximum number of CI/CD minutes that a group can use on shared runners per month. |
| `shared_runners_text`                    | string           | required by: `shared_runners_enabled` | Shared runners text. |
| `sidekiq_job_limiter_mode` | string | no | `track` or `compress`. Sets the behavior for [Sidekiq job size limits](../user/admin_area/settings/sidekiq_job_limits.md). Default: 'compress'. |
| `sidekiq_job_limiter_compression_threshold_bytes` | integer | no | The threshold in bytes at which Sidekiq jobs are compressed before being stored in Redis. Default: 100,000 bytes (100 KB). |
| `sidekiq_job_limiter_limit_bytes` | integer | no | The threshold in bytes at which Sidekiq jobs are rejected. Default: 0 bytes (doesn't reject any job). |
| `sign_in_text`                           | string           | no                                   | Text on the login page. |
| `signin_enabled`                         | string           | no                                   | (Deprecated: Use `password_authentication_enabled_for_web` instead) Flag indicating if password authentication is enabled for the web interface. |
| `signup_enabled`                         | boolean          | no                                   | Enable registration. Default is `true`. |
| `silent_mode_enabled`                    | boolean          | no                                   | Enable [Silent mode](../administration/silent_mode/index.md). Default is `false`. |
| `slack_app_enabled`                      | boolean          | no                                   | (**If enabled, requires:** `slack_app_id`, `slack_app_secret` and `slack_app_secret`) Enable Slack app. |
| `slack_app_id`                           | string           | required by: `slack_app_enabled`     | The app ID of the Slack-app. |
| `slack_app_secret`                       | string           | required by: `slack_app_enabled`     | The app secret of the Slack-app. |
| `slack_app_signing_secret`               | string           | no                                   | The signing secret of the Slack-app. |
| `slack_app_verification_token`           | string           | required by: `slack_app_enabled`     | The verification token of the Slack-app. |
| `snippet_size_limit`                     | integer          | no                                   | Max snippet content size in **bytes**. Default: 52428800 Bytes (50 MB).|
| `snowplow_app_id`                        | string           | no                                   | The Snowplow site name / application ID. (for example, `gitlab`) |
| `snowplow_collector_hostname`            | string           | required by: `snowplow_enabled`      | The Snowplow collector hostname. (for example, `snowplow.trx.gitlab.net`) |
| `snowplow_cookie_domain`                 | string           | no                                   | The Snowplow cookie domain. (for example, `.gitlab.com`) |
| `snowplow_enabled`                       | boolean          | no                                   | Enable snowplow tracking. |
| `sourcegraph_enabled`                    | boolean          | no                                   | Enables Sourcegraph integration. Default is `false`. **If enabled, requires** `sourcegraph_url`. |
| `sourcegraph_public_only`                | boolean          | no                                   | Blocks Sourcegraph from being loaded on private and internal projects. Default is `true`. |
| `sourcegraph_url`                        | string           | required by: `sourcegraph_enabled`   | The Sourcegraph instance URL for integration. |
| `spam_check_endpoint_enabled`            | boolean          | no                                   | Enables spam checking using external Spam Check API endpoint. Default is `false`. |
| `spam_check_endpoint_url`                | string           | no                                   | URL of the external Spamcheck service endpoint. Valid URI schemes are `grpc` or `tls`. Specifying `tls` forces communication to be encrypted.|
| `spam_check_api_key`                     | string           | no                                   | API key used by GitLab for accessing the Spam Check service endpoint. |
| `suggest_pipeline_enabled`               | boolean          | no                                   | Enable pipeline suggestion banner. |
| `terminal_max_session_time`              | integer          | no                                   | Maximum time for web terminal websocket connection (in seconds). Set to `0` for unlimited time. |
| `terms`                                  | text             | required by: `enforce_terms`         | (**Required by:** `enforce_terms`) Markdown content for the ToS. |
| `throttle_authenticated_api_enabled`     | boolean          | no                                   | (**If enabled, requires:** `throttle_authenticated_api_period_in_seconds` and `throttle_authenticated_api_requests_per_period`) Enable authenticated API request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). |
| `throttle_authenticated_api_period_in_seconds` | integer    | required by:<br>`throttle_authenticated_api_enabled` | Rate limit period (in seconds). |
| `throttle_authenticated_api_requests_per_period` | integer  | required by:<br>`throttle_authenticated_api_enabled` | Maximum requests per period per user. |
| `throttle_authenticated_packages_api_enabled` | boolean     | no | (**If enabled, requires:** `throttle_authenticated_packages_api_period_in_seconds` and `throttle_authenticated_packages_api_requests_per_period`) Enable authenticated API request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). View [Package Registry rate limits](../user/admin_area/settings/package_registry_rate_limits.md) for more details. |
| `throttle_authenticated_packages_api_period_in_seconds` | integer    | required by:<br>`throttle_authenticated_packages_api_enabled` | Rate limit period (in seconds). View [Package Registry rate limits](../user/admin_area/settings/package_registry_rate_limits.md) for more details. |
| `throttle_authenticated_packages_api_requests_per_period` | integer    | required by:<br>`throttle_authenticated_packages_api_enabled` | Maximum requests per period per user. View [Package Registry rate limits](../user/admin_area/settings/package_registry_rate_limits.md) for more details. |
| `throttle_authenticated_web_enabled`     | boolean          | no                                   | (**If enabled, requires:** `throttle_authenticated_web_period_in_seconds` and `throttle_authenticated_web_requests_per_period`) Enable authenticated web request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). |
| `throttle_authenticated_web_period_in_seconds` | integer    | required by:<br>`throttle_authenticated_web_enabled` | Rate limit period (in seconds). |
| `throttle_authenticated_web_requests_per_period` | integer  | required by:<br>`throttle_authenticated_web_enabled` | Maximum requests per period per user. |
| `throttle_unauthenticated_enabled`       | boolean          | no                                   | ([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) in GitLab 14.3. Use `throttle_unauthenticated_web_enabled` or `throttle_unauthenticated_api_enabled` instead.) (**If enabled, requires:** `throttle_unauthenticated_period_in_seconds` and `throttle_unauthenticated_requests_per_period`) Enable unauthenticated web request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). |
| `throttle_unauthenticated_period_in_seconds` | integer      | required by:<br>`throttle_unauthenticated_enabled` | ([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) in GitLab 14.3. Use `throttle_unauthenticated_web_period_in_seconds` or `throttle_unauthenticated_api_period_in_seconds` instead.) Rate limit period in seconds. |
| `throttle_unauthenticated_requests_per_period` | integer    | required by:<br>`throttle_unauthenticated_enabled` | ([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) in GitLab 14.3. Use `throttle_unauthenticated_web_requests_per_period` or `throttle_unauthenticated_api_requests_per_period` instead.) Max requests per period per IP. |
| `throttle_unauthenticated_api_enabled`       | boolean          | no                                   | (**If enabled, requires:** `throttle_unauthenticated_api_period_in_seconds` and `throttle_unauthenticated_api_requests_per_period`) Enable unauthenticated API request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). |
| `throttle_unauthenticated_api_period_in_seconds` | integer      | required by:<br>`throttle_unauthenticated_api_enabled` | Rate limit period in seconds. |
| `throttle_unauthenticated_api_requests_per_period` | integer    | required by:<br>`throttle_unauthenticated_api_enabled` | Max requests per period per IP. |
| `throttle_unauthenticated_packages_api_enabled` | boolean     | no | (**If enabled, requires:** `throttle_unauthenticated_packages_api_period_in_seconds` and `throttle_unauthenticated_packages_api_requests_per_period`) Enable authenticated API request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). View [Package Registry rate limits](../user/admin_area/settings/package_registry_rate_limits.md) for more details. |
| `throttle_unauthenticated_packages_api_period_in_seconds` | integer    | required by:<br>`throttle_unauthenticated_packages_api_enabled` | Rate limit period (in seconds). View [Package Registry rate limits](../user/admin_area/settings/package_registry_rate_limits.md) for more details. |
| `throttle_unauthenticated_packages_api_requests_per_period` | integer    | required by:<br>`throttle_unauthenticated_packages_api_enabled` | Maximum requests per period per user. View [Package Registry rate limits](../user/admin_area/settings/package_registry_rate_limits.md) for more details. |
| `throttle_unauthenticated_web_enabled`       | boolean          | no                                   | (**If enabled, requires:** `throttle_unauthenticated_web_period_in_seconds` and `throttle_unauthenticated_web_requests_per_period`) Enable unauthenticated web request rate limit. Helps reduce request volume (for example, from crawlers or abusive bots). |
| `throttle_unauthenticated_web_period_in_seconds` | integer      | required by:<br>`throttle_unauthenticated_web_enabled` | Rate limit period in seconds. |
| `throttle_unauthenticated_web_requests_per_period` | integer    | required by:<br>`throttle_unauthenticated_web_enabled` | Max requests per period per IP. |
| `time_tracking_limit_to_hours`           | boolean          | no                                   | Limit display of time tracking units to hours. Default is `false`. |
| `two_factor_grace_period`                | integer          | required by: `require_two_factor_authentication` | Amount of time (in hours) that users are allowed to skip forced configuration of two-factor authentication. |
| `unique_ips_limit_enabled`               | boolean          | no                                   | (**If enabled, requires:** `unique_ips_limit_per_user` and `unique_ips_limit_time_window`) Limit sign in from multiple IPs. |
| `unique_ips_limit_per_user`              | integer          | required by: `unique_ips_limit_enabled` | Maximum number of IPs per user. |
| `unique_ips_limit_time_window`           | integer          | required by: `unique_ips_limit_enabled` | How many seconds an IP is counted towards the limit. |
| `usage_ping_enabled`                     | boolean          | no                                   | Every week GitLab reports license usage back to GitLab, Inc. |
| `user_deactivation_emails_enabled`       | boolean          | no                                   | Send an email to users upon account deactivation. |
| `user_default_external`                  | boolean          | no                                   | Newly registered users are external by default. |
| `user_default_internal_regex`            | string           | no                                   | Specify an email address regex pattern to identify default internal users. |
| `user_defaults_to_private_profile` | boolean | no | Newly created users have private profile by default. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/231301) in GitLab 15.8. Defaults to `false`. |
| `user_oauth_applications`                | boolean          | no                                   | Allow users to register any application to use GitLab as an OAuth provider. |
| `user_show_add_ssh_key_message`          | boolean          | no                                   | When set to `false` disable the `You won't be able to pull or push project code via SSH` warning shown to users with no uploaded SSH key. |
| `version_check_enabled`                  | boolean          | no                                   | Let GitLab inform you when an update is available. |
| `valid_runner_registrars`                | array of strings | no                                   | List of types which are allowed to register a GitLab Runner. Can be `[]`, `['group']`, `['project']` or `['group', 'project']`. |
| `whats_new_variant`                      | string           | no                                   | What's new variant, possible values: `all_tiers`, `current_tier`, and `disabled`. |
| `wiki_page_max_content_bytes`            | integer          | no                                   | Maximum wiki page content size in **bytes**. Default: 52428800 Bytes (50 MB). The minimum value is 1024 bytes. |
| `jira_connect_application_key`           | String           | no                                   | Application ID of the OAuth application that should be used to authenticate with the GitLab for Jira Cloud app |
| `jira_connect_proxy_url`                 | String           | no                                   | URL of the GitLab instance that should be used as a proxy for the GitLab for Jira Cloud app |

### Configure inactive project deletion

You can configure inactive projects deletion or turn it off.

| Attribute                                | Type             | Required                             | Description |
|------------------------------------------|------------------|:------------------------------------:|-------------|
| `delete_inactive_projects`               | boolean          | no                                   | Enable [inactive project deletion](../administration/inactive_project_deletion.md). Default is `false`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84519) in GitLab 14.10. [Became operational without feature flag](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96803) in GitLab 15.4. |
| `inactive_projects_delete_after_months`  | integer          | no                                   | If `delete_inactive_projects` is `true`, the time (in months) to wait before deleting inactive projects. Default is `2`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84519) in GitLab 14.10. [Became operational](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) in GitLab 15.0. |
| `inactive_projects_min_size_mb`          | integer          | no                                   | If `delete_inactive_projects` is `true`, the minimum repository size for projects to be checked for inactivity. Default is `0`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84519) in GitLab 14.10. [Became operational](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) in GitLab 15.0. |
| `inactive_projects_send_warning_email_after_months` | integer | no                                 | If `delete_inactive_projects` is `true`, sets the time (in months) to wait before emailing maintainers that the project is scheduled be deleted because it is inactive. Default is `1`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84519) in GitLab 14.10. [Became operational](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) in GitLab 15.0. |

## Housekeeping fields

::Tabs

:::TabTitle 15.8 and later

If the `housekeeping_optimize_repository_period`
field is set to an integer, housekeeping operations are performed after the number
of Git pushes you specify.

:::TabTitle 15.7 and earlier

The `housekeeping_enabled` field enables or disables
Git housekeeping. To function properly, this field requires `housekeeping_optimize_repository_period`
to be set, or _all_ of these values to be set:

- `housekeeping_bitmaps_enabled`
- `housekeeping_full_repack_period`
- `housekeeping_gc_period`

::EndTabs

### Package Registry: Package file size limits

The package file size limits are not part of the Application settings API.
Instead, these settings can be accessed using the [Plan limits API](plan_limits.md).
