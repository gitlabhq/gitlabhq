---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 애플리케이션 설정 API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 API를 사용하여 GitLab 인스턴스의 [애플리케이션 설정](#available-settings)과 상호작용합니다.

애플리케이션 설정 변경사항은 캐싱의 영향을 받으며 즉시 적용되지 않을 수 있습니다. 기본적으로 GitLab은 애플리케이션 설정을 60초 동안 캐시합니다. 인스턴스의 애플리케이션 설정 캐시를 제어하는 방법에 대한 자세한 내용은 [애플리케이션 캐시 간격](../administration/application_settings_cache.md)을 참조하세요.

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

## 현재 애플리케이션 설정에 대한 세부 정보 검색 {#retrieve-details-on-current-application-settings}

{{< history >}}

- `always_perform_delayed_deletion` 기능 플래그가 GitLab 15.11에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332)되었습니다.
- `delayed_project_deletion` 및 `delayed_group_deletion` 속성이 GitLab 16.0에서 제거되었습니다.
- `in_product_marketing_emails_enabled` 속성이 GitLab 16.6에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/418137)되었습니다.
- `repository_storages` 속성이 GitLab 16.6에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/429675)되었습니다.
- `user_email_lookup_limit` 속성이 GitLab 16.7에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136886)되었습니다.
- `allow_all_integrations` 및 `allowed_integrations` 속성이 GitLab 17.6에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)되었습니다.

{{< /history >}}

이 GitLab 인스턴스의 현재 [애플리케이션 설정](#available-settings)에 대한 세부 정보를 검색합니다.

```plaintext
GET /application/settings
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/settings"
```

응답 예시:

```json
{
  "default_projects_limit" : 100000,
  "signup_enabled" : true,
  "id" : 1,
  "default_branch_protection" : 2,
  "default_branch_protection_defaults": {
        "allowed_to_push": [
            {
                "access_level": 40
            }
        ],
        "allow_force_push": false,
        "allowed_to_merge": [
            {
                "access_level": 40
            }
        ]
    },
  "default_preferred_language" : "en",
  "deletion_adjourned_period": 7,
  "failed_login_attempts_unlock_period_in_minutes": 30,
  "restricted_visibility_levels" : [],
  "sign_in_restrictions": {},
  "password_authentication_enabled_for_web" : true,
  "after_sign_out_path" : null,
  "max_attachment_size" : 100,
  "max_decompressed_archive_size": 25600,
  "max_export_size": 50,
  "max_import_size": 50,
  "max_import_remote_file_size": 10240,
  "max_login_attempts": 3,
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
  "container_expiration_policies_enable_historic_entries": true,
  "container_registry_cleanup_tags_service_max_list_size": 200,
  "container_registry_delete_tags_service_timeout": 250,
  "container_registry_expiration_policies_caching": true,
  "container_registry_expiration_policies_worker_capacity": 4,
  "container_registry_token_expire_delay": 5,
  "decompress_archive_file_timeout": 210,
  "repository_storages_weighted": {"default": 100},
  "plantuml_enabled": false,
  "plantuml_url": null,
  "diagramsnet_enabled": true,
  "diagramsnet_url": "https://embed.diagrams.net",
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
  "inactive_resource_access_tokens_delete_after_days": 30,
  "performance_bar_allowed_group_id": 42,
  "user_show_add_ssh_key_message": true,
  "allow_account_deletion": true,
  "updating_name_disabled_for_users": false,
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
  "raw_blob_request_limit_unauthenticated": 800,
  "wiki_page_max_content_bytes": 5242880,
  "require_admin_approval_after_user_signup": false,
  "require_personal_access_token_expiry": true,
  "personal_access_token_prefix": "glpat-",
  "rate_limiting_response_text": null,
  "keep_latest_artifact": true,
  "admin_mode": false,
  "floc_enabled": false,
  "external_pipeline_validation_service_timeout": null,
  "external_pipeline_validation_service_token": null,
  "external_pipeline_validation_service_url": null,
  "jira_connect_application_key": null,
  "jira_connect_public_key_storage_enabled": false,
  "jira_connect_proxy_url": null,
  "jira_connect_additional_audience_url": null,
  "silent_mode_enabled": false,
  "package_registry_allow_anyone_to_pull_option": true,
  "bulk_import_max_download_file_size": 5120,
  "project_jobs_api_rate_limit": 600,
  "runner_jobs_request_api_limit": 2000,
  "runner_jobs_patch_trace_api_limit": 200,
  "runner_jobs_endpoints_api_limit": 200,
  "security_txt_content": null,
  "security_scan_stale_after_days": 90,
  "bulk_import_concurrent_pipeline_batch_limit": 25,
  "concurrent_relation_batch_export_limit": 25,
  "relation_export_batch_size": 50,
  "concurrent_github_import_jobs_limit": 1000,
  "concurrent_bitbucket_import_jobs_limit": 100,
  "concurrent_bitbucket_server_import_jobs_limit": 100,
  "silent_admin_exports_enabled": false,
  "top_level_group_creation_enabled": true,
  "disable_invite_members": false,
  "enforce_pipl_compliance": true,
  "model_prompt_cache_enabled": true,
  "lock_model_prompt_cache_enabled": false
}
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 사용자는 다음 매개변수도 볼 수 있습니다:

- `allow_all_integrations`
- `allowed_integrations`
- `default_project_deletion_protection`
- `delete_unconfirmed_users`
- `dependency_scanning_sbom_scan_api_download_limit`
- `dependency_scanning_sbom_scan_api_upload_limit`
- `disable_personal_access_tokens`
- `duo_features_enabled`
- `elasticsearch_index_settings`
- `file_template_project_id`
- `geo_node_allowed_ips`
- `geo_status_timeout`
- `group_owners_can_manage_default_branch_protection`
- `lock_duo_features_enabled`
- `scan_execution_policies_action_limit`
- `scan_execution_policies_schedule_limit`
- `secret_push_protection_available`
- `security_approval_policies_limit`
- `security_policy_global_group_approvers_enabled`
- `unconfirmed_users_delete_after_days`
- `use_clickhouse_for_analytics`
- `virtual_registries_endpoints_api_limit`
- `project_secrets_limit`
- `group_secrets_limit`
- `security_mr_report_cache_lifetime_minutes`
- `security_scan_stale_after_days`

```json
{
  "allow_all_integrations": true,
  "allowed_integrations": [],
  "default_project_deletion_protection": false,
  "disable_personal_access_tokens": false,
  "duo_features_enabled": true,
  "elasticsearch_index_settings": [
    {
      "alias_name": "gitlab-production",
      "number_of_shards": 5,
      "number_of_replicas": 1
    }
  ],
  "file_template_project_id": 1,
  "geo_node_allowed_ips": "0.0.0.0/0, ::/0",
  "group_owners_can_manage_default_branch_protection": true,
  "id": 1,
  "lock_duo_features_enabled": false,
  "signup_enabled": true,
  "virtual_registries_endpoints_api_limit": 4000,
  "project_secrets_limit": 100,
  "group_secrets_limit": 500
  ...
}
```

## 애플리케이션 설정 업데이트 {#update-application-settings}

{{< history >}}

- `always_perform_delayed_deletion` 기능 플래그가 GitLab 15.11에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332)되었습니다.
- `delayed_project_deletion` 및 `delayed_group_deletion` 속성이 GitLab 16.0에서 제거되었습니다.
- `always_perform_delayed_deletion` 기능 플래그가 GitLab 16.1에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120476)되었습니다.
- `user_email_lookup_limit` 속성이 GitLab 16.7에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136886)되었습니다.
- `default_branch_protection`이 GitLab 17.0에서 [지원 중단](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)되었습니다. `default_branch_protection_defaults` 대신 사용합니다.
- `throttle_unauthenticated_git_http_enabled`, `throttle_unauthenticated_git_http_period_in_seconds` 및 `throttle_unauthenticated_git_http_requests_per_period` 속성이 GitLab 17.0에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112)되었습니다.
- `allow_all_integrations` 및 `allowed_integrations` 속성이 GitLab 17.6에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)되었습니다.
- `throttle_authenticated_git_http_enabled`, `throttle_authenticated_git_http_period_in_seconds` 및 `throttle_authenticated_git_http_requests_per_period` 속성이 GitLab 18.1에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191552) 되었으며 [플래그](../administration/feature_flags/_index.md) 이름은 `git_authenticated_http_limit`입니다. 기본적으로 비활성화됨.
- `git_authenticated_http_limit` 기능 플래그가 GitLab 18.3에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/543768)되었습니다.
- `git_authenticated_http_limit` 기능 플래그가 GitLab 18.4에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/561577)되었습니다.

{{< /history >}}

이 GitLab 인스턴스의 현재 [애플리케이션 설정](#available-settings)을 업데이트합니다.

```plaintext
PUT /application/settings
```

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/settings" \
  --data "signup_enabled=false" \
  --data "default_project_visibility=internal"
```

응답 예시:

```json
{
  "id": 1,
  "default_projects_limit": 100000,
  "default_preferred_language": "en",
  "failed_login_attempts_unlock_period_in_minutes": 30,
  "signup_enabled": false,
  "password_authentication_enabled_for_web": true,
  "gravatar_enabled": true,
  "created_at": "2015-06-12T15:51:55.432Z",
  "updated_at": "2015-06-30T13:22:42.210Z",
  "home_page_url": "",
  "default_branch_protection": 2,
  "default_branch_protection_defaults": {
    "allowed_to_push": [
        {
            "access_level": 40
        }
    ],
    "allow_force_push": false,
    "allowed_to_merge": [
        {
            "access_level": 40
        }
    ]
  },
  "restricted_visibility_levels": [],
  "sign_in_restrictions": {},
  "max_attachment_size": 100,
  "max_decompressed_archive_size": 25600,
  "max_export_size": 50,
  "max_import_size": 50,
  "max_import_remote_file_size": 10240,
  "max_login_attempts": 3,
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
  "decompress_archive_file_timeout": 210,
  "package_registry_cleanup_policies_worker_capacity": 2,
  "plantuml_enabled": false,
  "plantuml_url": null,
  "diagramsnet_enabled": true,
  "diagramsnet_url": "https://embed.diagrams.net",
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
  "inactive_resource_access_tokens_delete_after_days": 30,
  "performance_bar_allowed_group_id": 42,
  "user_show_add_ssh_key_message": true,
  "file_template_project_id": 1,
  "local_markdown_version": 0,
  "asset_proxy_enabled": true,
  "asset_proxy_url": "https://assets.example.com",
  "asset_proxy_allowlist": ["example.com", "*.example.com", "your-instance.com"],
  "globally_allowed_ips": "",
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
  "raw_blob_request_limit_unauthenticated": 800,
  "wiki_page_max_content_bytes": 5242880,
  "require_admin_approval_after_user_signup": false,
  "require_personal_access_token_expiry": true,
  "personal_access_token_prefix": "glpat-",
  "rate_limiting_response_text": null,
  "keep_latest_artifact": true,
  "admin_mode": false,
  "external_pipeline_validation_service_timeout": null,
  "external_pipeline_validation_service_token": null,
  "external_pipeline_validation_service_url": null,
  "can_create_group": false,
  "jira_connect_application_key": "123",
  "jira_connect_public_key_storage_enabled": true,
  "jira_connect_proxy_url": "http://gitlab.example.com",
  "user_defaults_to_private_profile": true,
  "projects_api_rate_limit_unauthenticated": 400,
  "runner_jobs_request_api_limit": 2000,
  "runner_jobs_patch_trace_api_limit": 200,
  "runner_jobs_endpoints_api_limit": 200,
  "users_api_limit_followers": 100,
  "users_api_limit_following": 100,
  "users_api_limit_status": 240,
  "users_api_limit_ssh_keys": 120,
  "users_api_limit_ssh_key": 120,
  "users_api_limit_gpg_keys": 120,
  "users_api_limit_gpg_key": 120,
  "silent_mode_enabled": false,
  "security_policy_global_group_approvers_enabled": true,
  "security_approval_policies_limit": 5,
  "scan_execution_policies_action_limit": 0,
  "scan_execution_policies_schedule_limit": 0,
  "package_registry_allow_anyone_to_pull_option": true,
  "bulk_import_max_download_file_size": 5120,
  "project_jobs_api_rate_limit": 600,
  "security_txt_content": null,
  "security_scan_stale_after_days": 90,
  "bulk_import_concurrent_pipeline_batch_limit": 25,
  "concurrent_relation_batch_export_limit": 25,
  "relation_export_batch_size": 50,
  "downstream_pipeline_trigger_limit_per_project_user_sha": 0,
  "concurrent_github_import_jobs_limit": 1000,
  "concurrent_bitbucket_import_jobs_limit": 100,
  "concurrent_bitbucket_server_import_jobs_limit": 100,
  "silent_admin_exports_enabled": false,
  "enforce_pipl_compliance": true
}
```

[GitLab Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 사용자는 다음 매개변수도 볼 수 있습니다:

- `allow_all_integrations`
- `allowed_integrations`
- `group_owners_can_manage_default_branch_protection`
- `file_template_project_id`
- `geo_node_allowed_ips`
- `geo_status_timeout`
- `default_project_deletion_protection`
- `disable_personal_access_tokens`
- `security_policy_global_group_approvers_enabled`
- `security_approval_policies_limit`
- `scan_execution_policies_action_limit`
- `scan_execution_policies_schedule_limit`
- `delete_unconfirmed_users`
- `unconfirmed_users_delete_after_days`
- `duo_features_enabled`
- `lock_duo_features_enabled`
- `use_clickhouse_for_analytics`
- `virtual_registries_endpoints_api_limit`
- `lock_memberships_to_saml`
- `security_mr_report_cache_lifetime_minutes`
- `security_scan_stale_after_days`

응답 예시:

```json
  "file_template_project_id": 1,
  "geo_node_allowed_ips": "0.0.0.0/0, ::/0",
  "duo_features_enabled": true,
  "lock_duo_features_enabled": false,
  "allow_all_integrations": true,
  "allowed_integrations": [],
  "virtual_registries_endpoints_api_limit": 4000
```

## 사용 가능한 설정 {#available-settings}

<!--
This heading is referenced by a script: `scripts/cells/application-settings-analysis.rb`
 Any updates to this heading should be reflected for the DOC_API_SETTINGS_TABLE_REGEX variable.
 -->

{{< history >}}

- `housekeeping_full_repack_period`, `housekeeping_gc_period` 및 `housekeeping_incremental_repack_period`이 GitLab 15.8에서 [지원 중단](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106963)되었습니다. `housekeeping_optimize_repository_period` 대신 사용합니다.
- `allow_account_deletion` [GitLab 16.1에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/412411).
- `allow_project_creation_for_guest_and_below`이 GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134625)되었습니다.
- `silent_admin_exports_enabled` [GitLab 17.0에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148918).
- `require_personal_access_token_expiry`이 GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/470192)되었습니다.
- `receptive_cluster_agents_enabled` [GitLab 17.4에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/463427).
- `allow_all_integrations` 및 `allowed_integrations`이 GitLab 17.6에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)되었습니다.
- `iframe_rendering_enabled`, `iframe_rendering_allowlist` 및 `iframe_rendering_allowlist_raw`이 GitLab 18.6에서 도입되었습니다.
- `email_otp_enabled`이 GitLab 19.1에서 도입되었습니다.

{{< /history >}}

일반적으로 모든 설정은 선택사항입니다. 일부 설정을 활성화할 때 관련된 다른 설정도 구성해야 할 수 있습니다. 이러한 요구사항은 다음 표의 `Required` 열에 있습니다.

| 속성                                | 유형             | 필수                             | 설명 |
|------------------------------------------|------------------|:------------------------------------:|-------------|
| `admin_mode`                             | 부울          | 아니요                                   | 관리자는 관리 작업을 위해 Admin Mode를 다시 인증하여 활성화해야 합니다. |
| `admin_notification_email`               | 문자열           | 아니요                                   | 지원 중단됨:  `abuse_notification_email` 대신 사용합니다. 설정된 경우 [학대 리포트](../administration/review_abuse_reports.md)가 이 주소로 전송됩니다. 학대 리포트는 항상 **운영자** 영역에서 사용할 수 있습니다. |
| `abuse_notification_email`               | 문자열           | 아니요                                   | 설정된 경우 [학대 리포트](../administration/review_abuse_reports.md)가 이 주소로 전송됩니다. 학대 리포트는 항상 **운영자** 영역에서 사용할 수 있습니다. |
| `notify_on_unknown_sign_in`              | 부울          | 아니요                                   | 알 수 없는 IP 주소에서 로그인이 발생할 경우 알림 전송을 활성화합니다. |
| `after_sign_out_path`                    | 문자열           | 아니요                                   | 로그아웃 후 사용자를 리디렉션할 위치입니다. |
| `email_restrictions_enabled`             | 부울          | 아니요                                   | 새 사용자가 이메일로 계정을 만드는 것을 방지합니다. |
| `email_restrictions`                     | 문자열           | 필수: `email_restrictions_enabled` | 등록 중에 사용된 이메일에 대해 확인되는 정규식입니다. |
| `after_sign_up_text`                     | 문자열           | 아니요                                   | 가입 후 사용자에게 표시되는 텍스트입니다. |
| `akismet_api_key`                        | 문자열           | 필수: `akismet_enabled`       | Akismet 스팸 보호용 API 키입니다. |
| `akismet_enabled`                        | 부울          | 아니요                                   | (**If enabled, requires**: `akismet_api_key`) Akismet 스팸 보호를 활성화 또는 비활성화합니다. |
| `allow_all_integrations`                 | 부울          | 아니요                                   | `false`인 경우 `allowed_integrations`의 통합만 인스턴스에서 허용됩니다. Ultimate만 해당. |
| `allowed_integrations`                   | 문자열 배열 | 아니요                                   | `allow_all_integrations`이 `false`인 경우 이 목록의 통합만 인스턴스에서 허용됩니다. Ultimate만 해당. |
| `allow_account_deletion`                 | 부울          | 아니요                                   | `true`로 설정하여 사용자가 자신의 계정을 삭제하도록 허용합니다. Premium 및 Ultimate만 해당합니다. |
| `allow_group_owners_to_manage_ldap`      | 부울          | 아니요                                   | `true`로 설정하여 그룹 소유자가 LDAP을 관리하도록 허용합니다. Premium 및 Ultimate만 해당합니다. |
| `allow_local_requests_from_hooks_and_services` | 부울    | 아니요                                   | (지원 중단:  `allow_local_requests_from_web_hooks_and_services` 대신 사용) 웹후크와 통합의 로컬 네트워크에 대한 요청을 허용합니다. |
| `allow_local_requests_from_system_hooks` | 부울          | 아니요                                   | 시스템 훅에서 로컬 네트워크로의 요청을 허용합니다. |
| `allow_local_requests_from_web_hooks_and_services` | 부울 | 아니요                                  | 웹후크와 통합의 로컬 네트워크에 대한 요청을 허용합니다. |
| `allow_project_creation_for_guest_and_below` | 부울      | 아니요                                   | 게스트 역할 이하로 할당된 사용자가 그룹 및 개인 프로젝트를 만들 수 있는지 여부를 나타냅니다. `true`로 기본값이 설정됩니다. |
| `allow_runner_registration_token`        | 부울          | 아니요                                   | 등록 토큰을 사용하여 러너를 만들 수 있습니다. `true`로 기본값이 설정됩니다. |
| `archive_builds_in_human_readable`       | 문자열           | 아니요                                   | 작업이 오래되고 만료된 것으로 간주되는 기간을 설정합니다. 해당 시간이 지나면 작업이 아카이브되고 더 이상 재시도할 수 없습니다. 비어 있게 두어 작업이 절대 만료되지 않도록 합니다. 최소 1일 이상이어야 하며, 예: `15 days`, `1 month`, `2 years`. |
| `asset_proxy_enabled`                    | 부울          | 아니요                                   | (**If enabled, requires**: `asset_proxy_url`) 자산 프록시를 활성화합니다. GitLab을 다시 시작하여 변경사항을 적용합니다. |
| `asset_proxy_secret_key`                 | 문자열           | 아니요                                   | 자산 프록시 서버와 공유하는 비밀입니다. GitLab을 다시 시작하여 변경사항을 적용합니다. |
| `asset_proxy_url`                        | 문자열           | 아니요                                   | 자산 프록시 서버의 URL입니다. GitLab을 다시 시작하여 변경사항을 적용합니다. |
| `asset_proxy_whitelist`                  | 문자열 또는 문자열 배열 | 아니요                         | (지원 중단:  `asset_proxy_allowlist` 대신 사용) 이러한 도메인과 일치하는 자산은 프록시되지 않습니다. 와일드카드가 허용됩니다. GitLab 설치 URL은 자동으로 허용 목록에 추가됩니다. GitLab을 다시 시작하여 변경사항을 적용합니다. |
| `asset_proxy_allowlist`                  | 문자열 또는 문자열 배열 | 아니요                         | 이러한 도메인과 일치하는 자산은 프록시되지 않습니다. 와일드카드가 허용됩니다. GitLab 설치 URL은 자동으로 허용 목록에 추가됩니다. GitLab을 다시 시작하여 변경사항을 적용합니다. |
| `authn_data_retention_cleanup_enabled`   | 부울          | 아니요                                   | `true`인 경우 1년보다 오래된 인증 로그인 이력을 영구적으로 삭제하고, 1개월보다 오래된 이전에 취소된 OAuth 액세스 토큰 및 부여를 삭제하는 정리 작업자를 실행합니다. 기본값: `false`. GitLab 18.7에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/579002). |
| `authorized_keys_enabled`                | 부울          | 아니요                                   | 기본적으로 `authorized_keys` 파일은 추가 구성 없이 SSH를 통한 Git을 지원합니다. GitLab은 데이터베이스 파일을 통해 SSH 키를 인증하도록 최적화할 수 있습니다. AuthorizedKeysCommand를 사용하도록 OpenSSH 서버를 구성한 경우에만 비활성화합니다. |
| `auto_devops_domain`                     | 문자열           | 아니요                                   | 모든 프로젝트의 Auto Review Apps 및 Auto Deploy 스테이지에서 기본적으로 사용할 도메인을 지정합니다. |
| `auto_devops_enabled`                    | 부울          | 아니요                                   | 프로젝트에 대해 기본적으로 Auto DevOps를 활성화합니다. 사전 정의된 CI/CD 구성을 기반으로 애플리케이션을 자동으로 빌드, 테스트 및 배포합니다. |
| `autocomplete_users`                     | 정수          | 아니요                                   | `GET /autocomplete/users` 엔드포인트에 대한 분당 최대 인증 요청 수입니다. |
| `autocomplete_users_unauthenticated`     | 정수          | 아니요                                   | `GET /autocomplete/users` 엔드포인트에 대한 분당 최대 비인증 요청 수입니다. |
| `automatic_purchased_storage_allocation` | 부울          | 아니요                                   | 이를 활성화하면 네임스페이스에서 구매한 스토리지의 자동 할당이 허용됩니다. EE 배포판에만 해당합니다. |
| `bulk_import_enabled`                    | 부울          | 아니요                                   | 직접 전송으로 GitLab 그룹 마이그레이션을 활성화합니다. 설정도 [사용 가능](../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)하며 **운영자** 영역에서 사용할 수 있습니다. |
| `bulk_import_max_download_file_size`     | 정수          | 아니요                                   | 직접 전송으로 소스 GitLab 인스턴스에서 가져올 때 최대 다운로드 파일 크기입니다. [GitLab 16.3에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)됨. |
| `allow_bypass_placeholder_confirmation`  | 부울          | 아니요                                   | 관리자가 플레이스홀더 사용자를 다시 할당할 때 확인을 건너뜁니다. GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/534330)되었습니다. |
| `allow_s3_compatible_storage_for_offline_transfer` | 부울 | 아니요                                   | 오프라인 전송을 위해 S3 호환 객체 스토리지를 허용합니다. GitLab 18.9에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/579705). |
| `can_create_group`                       | 부울          | 아니요                                   | 사용자가 최상위 그룹을 만들 수 있는지 여부를 나타냅니다. `true`로 기본값이 설정됩니다. |
| `check_namespace_plan`                   | 부울          | 아니요                                   | 이를 활성화하면 프로젝트 네임스페이스의 플랜에 기능이 포함되어 있거나 프로젝트가 공개인 경우에만 라이선스가 있는 EE 기능을 사용할 수 있습니다. Premium 및 Ultimate만 해당합니다. |
| `ci_delete_pipelines_in_seconds_limit_human_readable` | 문자열 | 아니요                                | 파이프라인 보존을 구성할 수 있는 최대값입니다. `1 year`로 기본값이 설정됩니다. |
| `ci_job_live_trace_enabled`              | 부울          | 아니요                                   | 작업 로그에 대한 증분 로깅을 켭니다. 켜면 아카이브된 작업 로그가 객체 스토리지로 증분 업로드됩니다. 객체 스토리지를 구성해야 합니다. [**운영자** 영역](../administration/settings/continuous_integration.md#access-job-log-settings)에서도 이 설정을 구성할 수 있습니다. |
| `git_push_pipeline_limit`                | 정수          | 아니요                                   | 단일 Git 푸시로 트리거할 수 있는 태그 또는 브랜치 파이프라인의 최대 수를 설정합니다. 이 제한에 대한 자세한 내용은 [Git 푸시당 파이프라인 수](../administration/cicd/limits.md#number-of-pipelines-per-git-push)를 참조하세요. |
| `ci_max_total_yaml_size_bytes`           | 정수          | 아니요                                   | 파이프라인 구성을 위해 할당할 수 있는 최대 메모리(바이트)이며, 포함된 모든 YAML 구성 파일을 포함합니다. |
| `ci_max_includes`                        | 정수          | 아니요                                   | 파이프라인당 [최대 포함 수](../administration/cicd/limits.md#maximum-number-of-includes)입니다. 기본값은 `150`입니다. |
| `ci_partitions_size_limit`               | 정수          | 아니요                                   | 새 파티션을 만들기 전에 CI 테이블의 데이터베이스 파티션에서 사용할 수 있는 최대 디스크 공간(바이트)입니다. 기본값은 `100 GB`입니다. GitLab 18.11에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/429675)되었습니다.|
| `ci_partitions_in_seconds_limit`         | 정수          | 아니요                                   | 새 CI 파티션이 만들어지고 시스템이 다음 파티션 세트로 전환되기 전의 시간 창(초)입니다. 1개월에서 6개월 사이여야 합니다. 기본값은 1개월(`2592000`)입니다. |
| `concurrent_github_import_jobs_limit`    | 정수          | 아니요                                   | GitHub 임포터의 최대 동시 가져오기 작업 수입니다. 기본값은 1000입니다. [GitLab 16.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)됨. |
| `concurrent_bitbucket_import_jobs_limit` | 정수          | 아니요                                   | Bitbucket Cloud 임포터의 최대 동시 가져오기 작업 수입니다. 기본값은 100입니다. [GitLab 16.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)됨. |
| `concurrent_bitbucket_server_import_jobs_limit` | 정수   | 아니요                                   | Bitbucket Server 임포터의 최대 동시 가져오기 작업 수입니다. 기본값은 100입니다. [GitLab 16.11에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)됨. |
| `commit_email_hostname`                  | 문자열           | 아니요                                   | 사용자 정의 호스트명(개인 커밋 이메일용)입니다. |
| `container_expiration_policies_enable_historic_entries`   | 부울 | 아니요                           | 모든 프로젝트에 대해 [정리 정책](../user/packages/container_registry/reduce_container_registry_storage.md#enable-the-cleanup-policy)을 활성화합니다. |
| `container_registry_cleanup_tags_service_max_list_size`   | 정수 | 아니요                           | [정리 정책](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)의 단일 실행에서 삭제할 수 있는 최대 태그 수입니다. |
| `container_registry_delete_tags_service_timeout`          | 정수 | 아니요                           | [정리 정책](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)의 태그 배치 삭제에 걸릴 수 있는 최대 시간(초)입니다. |
| `container_registry_expiration_policies_caching`          | 부울 | 아니요                           | [정리 정책](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources) 실행 중 캐싱입니다. |
| `container_registry_expiration_policies_worker_capacity`  | 정수 | 아니요                           | [정리 정책](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)의 워커 수입니다. |
| `container_registry_token_expire_delay`                   | 정수 | 아니요                           | 컨테이너 레지스트리 토큰 기간(분)입니다. |
| `package_registry_cleanup_policies_worker_capacity`       | 정수 | 아니요                           | 패키지 정리 정책에 할당된 워커 수입니다. |
| `updating_name_disabled_for_users`       | 부울          | 아니요                                   | [사용자 프로필 이름 변경 비활성화](../administration/settings/account_and_limit_settings.md#disable-user-profile-name-changes). |
| `allow_account_deletion`                 | 부울          | 아니요                                   | [사용자가 자신의 계정을 삭제할 수 있도록](../administration/settings/account_and_limit_settings.md#prevent-users-from-deleting-their-accounts) 활성화합니다. |
| `deactivate_dormant_users`               | 부울          | 아니요                                   | [휴면 사용자의 자동 비활성화](../administration/moderate_users.md#automatically-deactivate-dormant-users)를 활성화합니다. |
| `deactivate_dormant_users_period`        | 정수          | 아니요                                   | 사용자가 휴면 상태로 간주되는 기간(일)입니다. |
| `decompress_archive_file_timeout`        | 정수          | 아니요                                   | 아카이브된 파일을 압축 해제하기 위한 기본 시간 초과(초)입니다. 시간 초과를 비활성화하려면 0으로 설정하세요. GitLab 16.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129161)되었습니다. |
| `default_artifacts_expire_in`            | 문자열           | 아니요                                   | 각 작업의 아티팩트에 대한 기본 만료 시간을 설정합니다. |
| `default_branch_name`                    | 문자열           | 아니요                                   | 인스턴스의 모든 프로젝트에 대해 [초기 브랜치 이름 설정](../user/project/repository/branches/default.md#change-the-default-branch-name-for-new-projects-in-an-instance)합니다. |
| `default_branch_protection`              | 정수          | 아니요                                   | [GitLab 17.0에서 더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/408314). `default_branch_protection_defaults` 대신 사용합니다. |
| `default_branch_protection_defaults`     | 해시             | 아니요                                   | [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/408314). 사용 가능한 옵션은 [`default_branch_protection_defaults`에 대한 옵션](groups.md#options-for-default_branch_protection_defaults)을 참조하세요. |
| `default_ci_config_path`                 | 문자열           | 아니요                                   | 새 프로젝트의 기본 CI/CD 구성 파일 및 경로(`.gitlab-ci.yml`이 설정되지 않은 경우)입니다. |
| `default_group_visibility`               | 문자열           | 아니요                                   | 새 그룹이 받는 가시성 수준입니다. 매개변수로 `private`, `internal` 및 `public`을 사용할 수 있습니다. 기본값은 `private`입니다. GitLab 16.4에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203)됨: `restricted_visibility_levels`의 모든 수준으로 설정할 수 없습니다.|
| `default_preferred_language`             | 문자열           | 아니요                                   | 로그인하지 않은 사용자를 위한 기본 선호 언어입니다. |
| `default_project_creation`               | 정수          | 아니요                                   | 프로젝트를 만들기 위해 필요한 기본 최소 역할입니다. 다음을 사용할 수 있습니다:  `0` _(No one)_, `1` _(Maintainers)_, `2` _(Developers)_, `3` _(Administrators)_ 또는 `4` _(Owners)_. |
| `default_project_visibility`             | 문자열           | 아니요                                   | 새 프로젝트가 받는 가시성 수준입니다. 매개변수로 `private`, `internal` 및 `public`을 사용할 수 있습니다. 기본값은 `private`입니다. GitLab 16.4에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203)됨: `restricted_visibility_levels`의 모든 수준으로 설정할 수 없습니다.|
| `default_projects_limit`                 | 정수          | 아니요                                   | 사용자당 프로젝트 제한입니다. 기본값은 `100000`입니다. |
| `default_snippet_visibility`             | 문자열           | 아니요                                   | 새 스니펫이 받는 가시성 수준입니다. 매개변수로 `private`, `internal` 및 `public`을 사용할 수 있습니다. 기본값은 `private`입니다. |
| `default_syntax_highlighting_theme`      | 정수          | 아니요                                   | 새로운 사용자 또는 로그인하지 않은 사용자를 위한 기본 구문 강조 테마입니다. [사용 가능한 테마의 ID](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16)를 참조하세요. |
| `default_dark_syntax_highlighting_theme` | 정수          | 아니요                                   | 새로운 사용자 또는 로그인하지 않은 사용자를 위한 기본 다크 모드 구문 강조 테마입니다. [사용 가능한 테마의 ID](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16)를 참조하세요. |
| `default_project_deletion_protection`    | 부울          | 아니요                                   | 기본 프로젝트 삭제 보호를 활성화하여 관리자만 프로젝트를 삭제할 수 있도록 합니다. 기본값은 `false`입니다. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `delete_unconfirmed_users`               | 부울          | 아니요                                   | 이메일을 확인하지 않은 사용자를 삭제할지 여부를 지정합니다. 기본값은 `false`입니다. `true`로 설정하면 확인되지 않은 사용자는 `unconfirmed_users_delete_after_days` 일 후 삭제됩니다. [GitLab 16.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/352514). GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `deletion_adjourned_period`              | 정수          | 아니요                                   | 삭제 표시된 프로젝트 또는 그룹을 삭제하기 전에 대기할 일 수입니다. 값은 `1` 및 `90` 사이여야 합니다. `30`로 기본값이 설정됩니다. |
| `description_and_note_max_size`          | 정수          | 아니요                                   | 최대 작업 항목, 머지 리퀘스트 및 취약성 설명 및 댓글 콘텐츠 크기(바이트)입니다. 기본값은 `1048576`입니다. |
| `diagramsnet_enabled`                    | 부울          | 아니요                                   | (활성화된 경우 `diagramsnet_url` 필수) [Diagrams.net 통합](../administration/integration/diagrams_net.md)을 활성화합니다. 기본값은 `true`입니다. |
| `diagramsnet_url`                        | 문자열           | 필수: `diagramsnet_enabled`   | 통합용 Diagrams.net 인스턴스 URL입니다. |
| `diff_max_patch_bytes`                   | 정수          | 아니요                                   | 최대 [diff 패치 크기](../administration/diff_limits.md)(바이트)입니다. |
| `diff_max_files`                         | 정수          | 아니요                                   | 최대 [diff의 파일](../administration/diff_limits.md) 수입니다. |
| `diff_max_lines`                         | 정수          | 아니요                                   | 최대 [diff의 라인](../administration/diff_limits.md) 수입니다. |
| `diff_max_versions`                      | 정수          | 아니요                                   | 머지 리퀘스트당 최대 [diff 버전](../administration/diff_limits.md) 수입니다. |
| `diff_max_commits`                       | 정수          | 아니요                                   | 머지 리퀘스트당 최대 [diff 커밋](../administration/diff_limits.md) 수입니다. |
| `disable_admin_oauth_scopes`             | 부울          | 아니요                                   | 관리자가 `api`, `read_api`, `read_repository`, `write_repository`, `read_registry`, `write_registry` 또는 `sudo` 범위를 갖는 신뢰할 수 없는 OAuth 2.0 애플리케이션에 GitLab 계정을 연결하는 것을 방지합니다. |
| `disable_feed_token`                     | 부울          | 아니요                                   | RSS/Atom 및 캘린더 피드 토큰 표시를 비활성화합니다. |
| `disable_personal_access_tokens`         | 부울          | 아니요                                   | 개인 액세스 토큰을 비활성화합니다. GitLab Self-Managed, Premium 및 Ultimate만 해당. API를 통해 비활성화된 개인 액세스 토큰을 활성화할 수 있는 방법이 없습니다. 이것은 [알려진 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/399233)입니다. 사용 가능한 해결 방법에 대한 자세한 내용은 [해결 방법](https://gitlab.com/gitlab-org/gitlab/-/issues/399233#workaround)을 참조하세요.     |
| `disabled_oauth_sign_in_sources`         | 문자열 배열 | 아니요                                   | 비활성화된 OAuth 로그인 소스입니다. |
| `disable_password_authentication_for_users_with_sso_identities` | 부울 | 아니요                     | SSO 자격을 가진 사용자의 웹 인터페이스에서 비밀번호 인증을 비활성화합니다. 이는 HTTP(S)를 통한 Git 작업에 영향을 주지 않습니다. 기본값은 `false`입니다. |
| `dns_rebinding_protection_enabled`       | 부울          | 아니요                                   | DNS 리바인딩 공격 보호를 강제합니다. |
| `domain_denylist_enabled`                | 부울          | 아니요                                   | (**If enabled, requires**: `domain_denylist`) 특정 도메인의 이메일로 새 사용자 계정을 차단할 수 있습니다. |
| `domain_denylist`                        | 문자열 배열 | 아니요                                   | 이러한 도메인과 일치하는 이메일 주소를 가진 사용자는 **불가**. 와일드카드가 허용됩니다. 여러 항목을 별도의 줄에 입력합니다. 예: `domain.com`, `*.domain.com`. |
| `domain_allowlist`                       | 문자열 배열 | 아니요                                   | 계정을 만들 때 사용자가 회사 이메일만 사용하도록 강제합니다. 기본값은 `null`이며, 제한이 없음을 의미합니다. |
| `downstream_pipeline_trigger_limit_per_project_user_sha` | 정수 | 아니요                            | [최대 다운스트림 파이프라인 트리거 속도](../administration/cicd/limits.md#limit-downstream-pipeline-trigger-rate). 기본값: `0` (제한 없음). GitLab 16.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144077)됨. |
| `dsa_key_restriction`                    | 정수          | 아니요                                   | 업로드된 DSA 키의 최소 허용 비트 길이입니다. 기본값은 `0`(제한 없음)입니다. `-1`는 DSA 키를 비활성화합니다. |
| `ecdsa_key_restriction`                  | 정수          | 아니요                                   | 업로드된 ECDSA 키의 최소 허용 곡선 크기(비트)입니다. 기본값은 `0`(제한 없음)입니다. `-1`는 ECDSA 키를 비활성화합니다. |
| `ecdsa_sk_key_restriction`               | 정수          | 아니요                                   | 업로드된 ECDSA_SK 키의 최소 허용 곡선 크기(비트)입니다. 기본값은 `0`(제한 없음)입니다. `-1`는 ECDSA_SK 키를 비활성화합니다. |
| `ed25519_key_restriction`                | 정수          | 아니요                                   | 업로드된 ED25519 키의 최소 허용 곡선 크기(비트)입니다. 기본값은 `0`(제한 없음)입니다. `-1`는 ED25519 키를 비활성화합니다. |
| `ed25519_sk_key_restriction`             | 정수          | 아니요                                   | 업로드된 ED25519_SK 키의 최소 허용 곡선 크기(비트)입니다. 기본값은 `0`(제한 없음)입니다. `-1`는 ED25519_SK 키를 비활성화합니다. |
| `eks_access_key_id`                      | 문자열           | 아니요                                   | AWS IAM 액세스 키 ID입니다. |
| `eks_account_id`                         | 문자열           | 아니요                                   | Amazon 계정 ID입니다. |
| `eks_integration_enabled`                | 부울          | 아니요                                   | Amazon EKS와의 통합을 활성화합니다. |
| `eks_secret_access_key`                  | 문자열           | 아니요                                   | AWS IAM 비밀 액세스 키입니다. |
| `elasticsearch_aws_access_key`           | 문자열           | 아니요                                   | AWS IAM 액세스 키입니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_aws_region`               | 문자열           | 아니요                                   | Elasticsearch 도메인이 구성된 AWS 지역입니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_aws_secret_access_key`    | 문자열           | 아니요                                   | AWS IAM 비밀 액세스 키입니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_aws`                      | 부울          | 아니요                                   | AWS 호스팅 Elasticsearch 사용을 활성화합니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_client_adapter`           | 문자열           | 아니요                                   | Elasticsearch Ruby 클라이언트에서 사용하는 Faraday 어댑터입니다. `typhoeus`로 기본값이 설정됩니다. 가능한 값은 `typhoeus` 및 `net_http`입니다. GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/550805)되었습니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_indexed_field_length_limit` | 정수        | 아니요                                   | Elasticsearch에서 인덱싱할 텍스트 필드의 최대 크기입니다. 0 값은 제한이 없음을 의미합니다. 이는 리포지토리 및 위키 인덱싱에는 적용되지 않습니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_indexed_file_size_limit_kb` | 정수        | 아니요                                   | Elasticsearch에서 인덱싱된 리포지토리 및 위키 파일의 최대 크기입니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_indexing`                   | 부울        | 아니요                                   | 고급 검색을 위한 인덱싱을 켭니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_requeue_workers`            | 부울        | 아니요                                   | 인덱싱 워커의 자동 재대기열을 활성화합니다. 이는 모든 문서가 처리될 때까지 Sidekiq 작업을 대기열에 추가하여 비코드 인덱싱 처리량을 개선합니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_limit_indexing`             | 부울        | 아니요                                   | 특정 네임스페이스 및 프로젝트의 인덱싱을 위해 Elasticsearch를 제한합니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_max_bulk_concurrency`       | 정수        | 아니요                                   | 인덱싱 작업당 Elasticsearch 벌크 요청의 최대 동시성입니다. 이는 리포지토리 인덱싱 작업에만 적용됩니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_max_code_indexing_concurrency` | 정수     | 아니요                                   | Elasticsearch 코드 인덱싱 백그라운드 작업의 최대 동시성입니다. 이는 리포지토리 인덱싱 작업에만 적용됩니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_worker_number_of_shards`    | 정수        | 아니요                                   | 인덱싱 워커 샤드 수입니다. 이는 더 많은 병렬 Sidekiq 작업을 대기열에 추가하여 비코드 인덱싱 처리량을 개선합니다. 기본값은 `2`입니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_max_bulk_size_mb`           | 정수        | 아니요                                   | Elasticsearch 벌크 인덱싱 요청의 최대 크기(MB)입니다. 이는 리포지토리 인덱싱 작업에만 적용됩니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_namespace_ids`              | 정수 배열 | 아니요                                | `elasticsearch_limit_indexing`이 활성화된 경우 Elasticsearch를 통해 인덱싱할 네임스페이스입니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_project_ids`                | 정수 배열 | 아니요                                | `elasticsearch_limit_indexing`이 활성화된 경우 Elasticsearch를 통해 인덱싱할 프로젝트입니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_search`                     | 부울        | 아니요                                   | Elasticsearch 검색을 활성화합니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_url`                        | 문자열 또는 문자열 배열 | 아니요                       | Elasticsearch에 연결하는 데 사용할 URL입니다. 쉼표로 구분된 목록 또는 배열을 사용하여 클러스터를 지원합니다(예: `http://localhost:9200, http://localhost:9201` 또는 `["http://localhost:9200", "http://localhost:9201"]`). Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_username`                   | 문자열         | 아니요                                   | Elasticsearch 인스턴스의 `username`입니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_password`                   | 문자열         | 아니요                                   | Elasticsearch 인스턴스의 비밀번호입니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_prefix`                     | 문자열         | 아니요                                   | Elasticsearch 인덱스 이름의 사용자 정의 접두사입니다. `gitlab`로 기본값이 설정됩니다. 1-100자여야 하며 소문자 영숫자, 하이픈 및 밑줄만 포함할 수 있고 하이픈 또는 밑줄로 시작하거나 끝날 수 없습니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_retry_on_failure`           | 정수        | 아니요                                   | Elasticsearch 검색 요청의 최대 재시도 횟수입니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_shards`                     | 정수 또는 객체 | `elasticsearch_replicas`이 객체로 정의된 경우 예 | Elasticsearch 인덱스의 샤드 수입니다. 모든 인덱스를 동일한 값으로 설정하려면 정수를 사용합니다. 인덱스별 값을 설정하려면 객체를 사용합니다. 예: `{"gitlab-production": 5, "gitlab-production-notes": 3}`. <br>객체를 사용할 때 각 인덱스에 대해 `elasticsearch_shards` 및 `elasticsearch_replicas`를 모두 제공해야 합니다. 인덱스에 대해 값이 없으면 해당 인덱스는 건너뜁니다. Premium 및 Ultimate만 해당합니다. |
| `elasticsearch_replicas`                   | 정수 또는 객체 | `elasticsearch_shards`이 객체로 정의된 경우 예 | Elasticsearch 인덱스의 복제본 수입니다. 모든 인덱스를 동일한 값으로 설정하려면 정수를 사용합니다. 인덱스별 값을 설정하려면 객체를 사용합니다. 예: `{"gitlab-production": 1, "gitlab-production-notes": 2}`. <br>객체를 사용할 때 각 인덱스에 대해 `elasticsearch_shards` 및 `elasticsearch_replicas`를 모두 제공해야 합니다. 인덱스에 대해 값이 없으면 해당 인덱스는 건너뜁니다. Premium 및 Ultimate만 해당합니다. |
| `email_additional_text`                    | 문자열         | 아니요                                   | 법적/감사/규정 준수 목적으로 모든 이메일 하단에 추가되는 추가 텍스트입니다. Premium 및 Ultimate만 해당합니다. |
| `email_author_in_body`                   | 부울          | 아니요                                   | 일부 이메일 서버는 이메일 발신자 이름 재정의를 지원하지 않습니다. 이 옵션을 활성화하면 이메일 본문에 이슈, 머지 리퀘스트 또는 댓글의 작성자 이름이 포함됩니다. |
| `email_confirmation_setting`             | 문자열           | 아니요                                   | 사용자가 로그인 전에 이메일을 확인해야 하는지 지정합니다. 가능한 값은 `off`, `soft`, `hard`입니다. |
| `email_otp_enabled`                      | 부울          | 아니요                                   | 이메일 기반 일회용 비밀번호(OTP)를 다중 인증 방법으로 활성화합니다. 기본적으로 비활성화됨. `require_email_verification_on_account_locked`이(가) `true`이어야 합니다. |
| `custom_http_clone_url_root`             | 문자열           | 아니요                                   | HTTP(S)에 대한 사용자 정의 Git 클론 URL을 설정합니다. |
| `enabled_git_access_protocol`            | 문자열           | 아니요                                   | Git 액세스에 대해 활성화된 프로토콜. 두 프로토콜을 모두 허용하는 값은 `ssh`, `http` 및 `all`입니다. `all` 값은 GitLab 16.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/12944)되었습니다. |
| `enforce_namespace_storage_limit`        | 부울          | 아니요                                   | 이를 활성화하면 네임스페이스 저장소 제한을 적용할 수 있습니다. |
| `enforce_terms`                          | 부울          | 아니요                                   | (**If enabled, requires**: `terms`) 모든 사용자에게 애플리케이션 이용약관을 적용합니다. |
| `external_auth_client_cert`              | 문자열           | 아니요                                   | (**If enabled, requires**: `external_auth_client_key`) 외부 권한 부여 서비스를 인증하는 데 사용할 인증서입니다. |
| `external_auth_client_key_pass`          | 문자열           | 아니요                                   | 외부 서비스를 인증할 때 개인 키에 사용할 암호입니다. 저장 시 암호화됩니다. |
| `external_auth_client_key`               | 문자열           | 필수: `external_auth_client_cert` | 외부 권한 부여 서비스가 필요한 경우 인증서의 개인 키입니다. 저장 시 암호화됩니다. |
| `external_authorization_service_default_label` | 문자열     | 필수:<br>`external_authorization_service_enabled` | 권한 부여를 요청할 때 사용할 기본 분류 레이블이며, 프로젝트에 분류 레이블이 지정되지 않은 경우에 사용됩니다. |
| `external_authorization_service_enabled`       | 부울    | 아니요                                   | (**If enabled, requires**: `external_authorization_service_default_label`, `external_authorization_service_timeout` 및 `external_authorization_service_url`) 프로젝트 액세스를 위해 외부 권한 부여 서비스를 사용하도록 설정합니다. |
| `external_authorization_service_timeout`       | 실수      | 필수:<br>`external_authorization_service_enabled` | 권한 부여 요청이 중단되는 시간(초)입니다. 요청이 시간 초과되면 사용자에게 액세스가 거부됩니다. (최소:  0.001, 최대:  10, 단계:  0.001). |
| `external_authorization_service_url`           | 문자열     | 필수:<br>`external_authorization_service_enabled` | 권한 부여 요청이 전달되는 URL입니다. |
| `external_pipeline_validation_service_url`     | 문자열     | 아니요                                   | 파이프라인 검증 요청에 사용할 URL입니다. |
| `external_pipeline_validation_service_token`   | 문자열     | 아니요                                   | 선택사항. `X-Gitlab-Token` 헤더를 `external_pipeline_validation_service_url`의 URL에 대한 요청에 포함합니다. |
| `external_pipeline_validation_service_timeout` | 정수    | 아니요                                   | 파이프라인 검증 서비스의 응답을 기다리는 시간입니다. 시간 초과되면 `OK`을(를) 가정합니다. |
| `static_objects_external_storage_url`        | 문자열       | 아니요                                   | 리포지토리 정적 객체에 대한 외부 저장소의 URL입니다. |
| `static_objects_external_storage_auth_token` | 문자열       | 필수: `static_objects_external_storage_url` | `static_objects_external_storage_url`에 연결된 외부 저장소의 인증 토큰입니다. |
| `failed_login_attempts_unlock_period_in_minutes` | 정수  | 아니요                                   | 최대 로그인 실패 횟수에 도달했을 때 사용자가 잠금 해제되는 시간(분)입니다. |
| `file_template_project_id`               | 정수          | 아니요                                   | 사용자 지정 파일 템플릿을 로드할 프로젝트의 ID입니다. Premium 및 Ultimate만 해당합니다. |
| `first_day_of_week`                      | 정수          | 아니요                                   | 달력 보기 및 날짜 선택기의 요일 시작입니다. 유효한 값은 `0`(기본값) 일요일, `1` 월요일, `6` 토요일입니다. |
| `globally_allowed_ips`                   | 문자열           | 아니요                                   | 인바운드 트래픽에 항상 허용되는 IP 주소 및 CIDR의 쉼표로 구분된 목록입니다. 예를 들어, `1.1.1.1, 2.2.2.0/24`입니다. |
| `geo_node_allowed_ips`                   | 문자열           | 예                                  | 허용된 보조 노드의 IP 및 CIDR 목록입니다. 예를 들어, `1.1.1.1, 2.2.2.0/24`입니다. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `geo_status_timeout`                     | 정수          | 아니요                                   | 보조 노드 상태를 가져오기 위한 요청이 시간 초과되는 시간(초)입니다. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `git_two_factor_session_expiry`          | 정수          | 아니요                                   | 2FA가 활성화되었을 때 Git 작업 세션의 최대 지속 시간(분)입니다. Premium 및 Ultimate만 해당합니다. |
| `gitaly_timeout_default`                 | 정수          | 아니요                                   | 기본 Gitaly 시간 초과(초)입니다. 이 시간 초과는 Git fetch/push 작업 또는 Sidekiq 작업에 적용되지 않습니다. `0`로 설정하여 시간 초과를 비활성화합니다. |
| `gitaly_timeout_fast`                    | 정수          | 아니요                                   | Gitaly 빠른 작업 시간 초과(초)입니다. 일부 Gitaly 작업은 빠르게 실행되어야 합니다. 이 임계값을 초과하면 저장소 샤드에 문제가 있을 수 있으며, '빠르게 실패'하면 GitLab 인스턴스의 안정성을 유지하는 데 도움이 됩니다. `0`로 설정하여 시간 초과를 비활성화합니다. |
| `gitaly_timeout_medium`                  | 정수          | 아니요                                   | Gitaly 중간 시간 초과(초)입니다. 이 값은 빠른 시간 초과와 기본 시간 초과 사이의 값이어야 합니다. `0`로 설정하여 시간 초과를 비활성화합니다. |
| `gitlab_dedicated_instance`              | 부울          | 아니요                                   | 인스턴스가 GitLab Dedicated용으로 프로비저닝되었는지 여부를 나타냅니다. |
| `gitlab_environment_toolkit_instance`    | 부울          | 아니요                                   | 인스턴스가 Service Ping 보고를 위해 GitLab Environment Toolkit으로 프로비저닝되었는지 여부를 나타냅니다. |
| `gitlab_shell_operation_limit`           | 정수          | 아니요                                   | 사용자가 분당 수행할 수 있는 최대 Git 작업 수입니다. 기본값: `600`. GitLab 16.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/412088)되었습니다. |
| `grafana_enabled`                        | 부울          | 아니요                                   | Grafana를 활성화합니다. |
| `grafana_url`                            | 문자열           | 아니요                                   | Grafana URL입니다. |
| `gravatar_enabled`                       | 부울          | 아니요                                   | Gravatar를 활성화합니다. |
| `group_owners_can_manage_default_branch_protection` | 부울 | 아니요                                 | 기본 브랜치 보호의 재정의를 방지합니다. GitLab Self-Managed, Premium 및 Ultimate만 해당.|
| `hashed_storage_enabled`                 | 부울          | 아니요                                   | 해시된 저장소 경로를 사용하여 새 프로젝트를 생성합니다:  변경 불가능한 해시 기반 경로 및 리포지토리 이름을 활성화하여 디스크에 저장소를 저장합니다. 이는 프로젝트 URL이 변경될 때 저장소를 이동하거나 이름을 바꿀 필요가 없으며, 디스크 I/O 성능을 향상시킬 수 있습니다. (GitLab 버전 13.0 이상에서는 항상 활성화되며, 구성은 14.0에서 제거될 예정입니다) |
| `help_page_hide_commercial_content`      | 부울          | 아니요                                   | 도움말에서 마케팅 관련 항목을 숨깁니다. |
| `help_page_support_url`                  | 문자열           | 아니요                                   | 도움말 페이지 및 도움말 드롭다운 목록의 대체 지원 URL입니다. |
| `help_page_documentation_base_url`       | 문자열           | 아니요                                   | 대체 설명서 페이지 URL입니다. |
| `help_page_text`                         | 문자열           | 아니요                                   | 도움말 페이지에 표시되는 사용자 정의 텍스트입니다. |
| `hide_third_party_offers`                | 부울          | 아니요                                   | GitLab에서 타사 제공 업체의 제안을 표시하지 않습니다. |
| `home_page_url`                          | 문자열           | 아니요                                   | 로그인하지 않은 경우 이 URL로 리디렉션합니다. |
| `housekeeping_bitmaps_enabled`           | 부울          | 아니요                                   | 지원 중단됨. Git packfile 비트맵 생성은 항상 활성화되어 있으며 API 및 UI를 통해 변경할 수 없습니다. 항상 `true`을(를) 반환합니다. |
| `housekeeping_enabled`                   | 부울          | 아니요                                   | Git 하우스키핑을 활성화하거나 비활성화합니다. 추가 필드를 설정해야 합니다. |
| `housekeeping_full_repack_period`        | 정수          | 아니요                                   | 지원 중단됨. Git 푸시 후 증분 `git repack`이(가) 실행되는 횟수입니다. `housekeeping_optimize_repository_period` 대신 사용합니다. |
| `housekeeping_gc_period`                 | 정수          | 아니요                                   | 지원 중단됨. Git 푸시 후 `git gc`이(가) 실행되는 횟수입니다. `housekeeping_optimize_repository_period` 대신 사용합니다. |
| `housekeeping_incremental_repack_period` | 정수          | 아니요                                   | 지원 중단됨. Git 푸시 후 증분 `git repack`이(가) 실행되는 횟수입니다. `housekeeping_optimize_repository_period` 대신 사용합니다. |
| `housekeeping_optimize_repository_period`| 정수          | 아니요                                   | Git 푸시 후 증분 `git repack`이(가) 실행되는 횟수입니다. |
| `html_emails_enabled`                    | 부울          | 아니요                                   | HTML 이메일을 활성화합니다. |
| `import_sources`                         | 문자열 배열 | 아니요                                   | 프로젝트 가져오기를 허용하는 소스입니다. 가능한 값: `github`, `bitbucket`, `bitbucket_server`, `fogbugz`, `git`, `gitlab_project`, `gitea`, `manifest`. |
| `invisible_captcha_enabled`              | 부울          | 아니요                                   | 계정 생성 중에 보이지 않는 CAPTCHA 스팸 탐지를 활성화합니다. 기본적으로 비활성화됨. |
| `issues_create_limit`                    | 정수          | 아니요                                   | 사용자당 분당 최대 이슈 생성 요청 수입니다. 기본적으로 비활성화됨.|
| `jira_connect_application_key`           | 문자열           | 아니요                                   | GitLab for Jira Cloud 앱을 인증하는 데 사용되는 OAuth 애플리케이션의 ID입니다. |
| `jira_connect_public_key_storage_enabled` | 부울         | 아니요                                   | GitLab for Jira Cloud 앱을 위한 공개 키 저장소를 활성화합니다. |
| `jira_connect_proxy_url`                 | 문자열           | 아니요                                   | GitLab for Jira Cloud 앱의 프록시로 사용되는 GitLab 인스턴스의 URL입니다. |
| `keep_latest_artifact`                   | 부울          | 아니요                                   | 만료 시간과 관계없이 가장 최근의 성공한 작업의 아티팩트 삭제를 방지합니다. 기본적으로 활성화됨. |
| `local_markdown_version`                 | 정수          | 아니요                                   | 캐시된 Markdown을 무효화해야 할 때 이 값을 증가시킵니다. |
| `lock_memberships_to_saml`               | 부울          | 아니요                                   | [SAML 그룹 멤버십에 대한 전역 잠금](../user/group/saml_sso/group_sync.md#global-saml-group-memberships-lock)을(를) 적용합니다. |
| `mailgun_signing_key`                    | 문자열           | 아니요                                   | 웹후크에서 이벤트를 수신하기 위한 Mailgun HTTP 웹후크 서명 키입니다. |
| `mailgun_events_enabled`                 | 부울          | 아니요                                   | Mailgun 이벤트 수신기를 활성화합니다. |
| `maintenance_mode_message`               | 문자열           | 아니요                                   | 인스턴스가 유지보수 모드일 때 표시되는 메시지입니다. Premium 및 Ultimate만 해당합니다. |
| `maintenance_mode`                       | 부울          | 아니요                                   | 인스턴스가 유지보수 모드에 있을 때, 관리자가 아닌 사용자는 읽기 전용 액세스로 로그인하고 읽기 전용 API 요청을 수행할 수 있습니다. Premium 및 Ultimate만 해당합니다. |
| `max_artifacts_size`                     | 정수          | 아니요                                   | 최대 아티팩트 크기(MB)입니다. |
| `max_attachment_size`                    | 정수          | 아니요                                   | 첨부 파일 크기를 MB로 제한합니다. |
| `max_decompressed_archive_size`          | 정수          | 아니요                                   | 가져온 아카이브의 최대 압축 해제 파일 크기(MB)입니다. 무제한은 `0`으(로) 설정합니다. 기본값은 `25600`입니다. |
| `max_export_size`                        | 정수          | 아니요                                   | 최대 내보내기 크기(MB)입니다. 무제한은 0입니다. 기본값 = 0(무제한). |
| `max_github_response_size_limit`         | 정수          | 아니요                                   | GitHub API 응답의 최대 허용 크기(MB)입니다. 무제한은 0입니다. |
| `max_github_response_json_value_count`   | 정수          | 아니요                                   | GitHub API 응답의 최대 허용 값 수입니다. 무제한은 0입니다. 개수는 응답의 `:`, `,`, `{` 및 `[` 발생 수에 기반한 추정값입니다. |
| `max_http_decompressed_size`             | 정수          | 아니요                                   | 압축 해제 후 아웃바운드 요청의 Gzip 압축 HTTP 응답에 대한 최대 허용 크기(MiB)입니다. 무제한은 0입니다. |
| `max_http_response_json_depth`           | 정수          | 아니요                                   | 아웃바운드 요청의 JSON HTTP 응답에 대한 최대 허용 중첩 깊이입니다. |
| `max_http_response_json_structural_chars` | 정수         | 아니요                                   | 아웃바운드 요청의 JSON HTTP 응답에 대한 최대 허용 객체 수입니다. 개수는 응답의 `:`, `,`, `{` 및 `[` 발생 수에 기반한 추정값입니다. GitLab 18.4에서 도입되었습니다. |
| `max_http_response_xml_structural_chars` | 정수          | 아니요                                   | 아웃바운드 요청의 XML HTTP 응답에 대한 최대 허용 객체 수입니다. 개수는 응답의 `<` 및 `=` 발생 수에 기반한 추정값입니다. GitLab 18.4에서 도입되었습니다. |
| `max_http_response_csv_structural_chars` | 정수          | 아니요                                   | 아웃바운드 요청의 CSV HTTP 응답에 대한 최대 허용 객체 수입니다. 개수는 응답의 `,`, `;`, `\t` 및 `\n` 발생 수에 기반한 추정값입니다. GitLab 18.4에서 도입되었습니다. |
| `max_http_response_size_limit`           | 정수          | 아니요                                   | 아웃바운드 요청의 HTTP 응답에 대한 최대 허용 크기(MiB)입니다. 무제한은 0입니다. 통합, 가져오기 및 웹후크에 적용됩니다. GitLab 18.4에서 도입되었습니다. |
| `max_import_size`                        | 정수          | 아니요                                   | 최대 가져오기 크기(MB)입니다. 무제한은 0입니다. 기본값 = 0(무제한). |
| `max_import_remote_file_size`            | 정수          | 아니요                                   | 외부 객체 저장소에서의 가져오기에 대한 최대 원격 파일 크기입니다. [GitLab 16.3에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)됨. |
| `max_login_attempts`                     | 정수          | 아니요                                   | 사용자를 잠그기 전의 최대 로그인 시도 횟수입니다. |
| `max_pages_size`                         | 정수          | 아니요                                   | Pages 저장소의 최대 크기(MB)입니다. |
| `max_personal_access_token_lifetime`     | 정수          | 아니요                                   | 액세스 토큰의 최대 허용 수명(일)입니다. 비워두면 기본값 365가 적용됩니다. 설정된 경우, 값은 365 이하여야 합니다. 변경되면, 최대 허용 수명을 초과하는 만료 날짜가 있는 기존 액세스 토큰은 취소됩니다. GitLab Self-Managed, Ultimate 전용입니다. GitLab 17.6 이상에서는 [400일로 연장](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) 할 수 있으며, [기능 플래그](../administration/feature_flags/_index.md) `buffered_token_expiration_limit`을(를) 활성화하여 연장할 수 있습니다.|
| `max_ssh_key_lifetime`                   | 정수          | 아니요                                   | SSH 키의 최대 허용 수명(일)입니다. GitLab Self-Managed, Ultimate 전용입니다. GitLab 17.6 이상에서는 [400일로 연장](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) 할 수 있으며, [기능 플래그](../administration/feature_flags/_index.md) `buffered_token_expiration_limit`을(를) 활성화하여 연장할 수 있습니다.|
| `max_terraform_state_size_bytes`         | 정수          | 아니요                                   | [Terraform 상태](../administration/terraform_state.md) 파일의 최대 크기(바이트)입니다. 무제한 파일 크기는 0으로 설정합니다. |
| `metrics_method_call_threshold`          | 정수          | 아니요                                   | 메서드 호출은 주어진 밀리초 이상 걸릴 때만 추적됩니다. |
| `max_number_of_repository_downloads`     | 정수          | 아니요                                   | 사용자가 지정된 시간 내에 다운로드할 수 있는 고유 저장소의 최대 수입니다. 초과하면 금지됩니다. 기본값:  0, 최대:  10,000개 저장소. GitLab Self-Managed, Ultimate 전용입니다. |
| `max_number_of_repository_downloads_within_time_period` | 정수 | 아니요                             | 보고 기간(초)입니다. 기본값:  0, 최대:  864000초(10일). GitLab Self-Managed, Ultimate 전용입니다. |
| `max_yaml_depth`                         | 정수          | 아니요                                   | [`include` 키워드](../ci/yaml/_index.md#include)로 추가된 중첩된 CI/CD 구성의 최대 깊이입니다. 기본값: `100`. |
| `max_yaml_size_bytes`                    | 정수          | 아니요                                   | 단일 CI/CD 구성 파일의 최대 크기(바이트)입니다. 기본값: `2097152`. |
| `git_rate_limit_users_allowlist`         | 문자열 배열  | 아니요                                  | Git 반대 남용 속도 제한에서 제외된 사용자 이름 목록입니다. 기본값: `[]`, 최대:  100명의 사용자. GitLab Self-Managed, Ultimate 전용입니다. |
| `git_rate_limit_users_alertlist`         | 정수 배열 | 아니요                                  | Git 반대 남용 속도 제한을 초과할 때 이메일이 발송되는 사용자 ID 목록입니다. 기본값: `[]`, 최대:  100명의 사용자 ID. GitLab Self-Managed, Ultimate 전용입니다. |
| `auto_ban_user_on_excessive_projects_download` | 부울    | 아니요                                   | 활성화되면, `max_number_of_repository_downloads` 및 `max_number_of_repository_downloads_within_time_period`로 지정된 시간 내에 최대 고유 프로젝트 수보다 많이 다운로드할 때 사용자가 자동으로 애플리케이션에서 금지됩니다. GitLab Self-Managed, Ultimate 전용입니다. |
| `mirror_available`                       | 부울          | 아니요                                   | 프로젝트 유지보수자가 리포지토리 미러링을 구성할 수 있도록 허용합니다. 비활성화된 경우, 관리자만 리포지토리 미러링을 구성할 수 있습니다. |
| `mirror_capacity_threshold`              | 정수          | 아니요                                   | 미러를 더 미리 예약하기 전에 사용 가능할 최소 용량입니다. Premium 및 Ultimate만 해당합니다. |
| `mirror_max_capacity`                    | 정수          | 아니요                                   | 동시에 동기화할 수 있는 미러의 최대 개수입니다. Premium 및 Ultimate만 해당합니다. |
| `mirror_max_delay`                       | 정수          | 아니요                                   | 미러가 동기화되도록 예약되었을 때 업데이트 사이의 최대 시간(분)입니다. Premium 및 Ultimate만 해당합니다. |
| `maven_package_requests_forwarding`      | 부울          | 아니요                                   | GitLab 패키지 레지스트리에서 패키지를 찾을 수 없을 때 Maven의 기본 원격 리포지토리로 repo.maven.apache.org를 사용합니다. Premium 및 Ultimate만 해당합니다. |
| `npm_package_requests_forwarding`        | 부울          | 아니요                                   | GitLab 패키지 레지스트리에서 패키지를 찾을 수 없을 때 npm의 기본 원격 리포지토리로 npmjs.org를 사용합니다. Premium 및 Ultimate만 해당합니다. |
| `pypi_package_requests_forwarding`       | 부울          | 아니요                                   | GitLab 패키지 레지스트리에서 패키지를 찾을 수 없을 때 PyPI의 기본 원격 리포지토리로 pypi.org를 사용합니다. Premium 및 Ultimate만 해당합니다. |
| `outbound_local_requests_whitelist`      | 문자열 배열 | 아니요                                   | 웹후크 및 통합을 위한 로컬 요청을 비활성화했을 때 로컬 요청이 허용되는 신뢰할 수 있는 도메인 또는 IP 주소 목록을 정의합니다. 현재 이 속성은 업데이트할 수 없습니다. 자세한 내용은 [이슈 569729](https://gitlab.com/gitlab-org/gitlab/-/issues/569729)를 참조하세요. |
| `package_registry_allow_anyone_to_pull_option` | 부울    | 아니요                                   | [패키지 레지스트리에서 누구나 가져올 수 있도록](../user/packages/package_registry/_index.md#allow-anyone-to-pull-from-package-registry) 활성화하여 표시하고 변경할 수 있습니다. |
| `package_metadata_purl_types`            | 정수 배열 | 아니요                                  | [동기화할 패키지 레지스트리 메타데이터](../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync) 목록입니다. [사용 가능한 값의 목록](https://gitlab.com/gitlab-org/gitlab/-/blob/ace16c20d5da7c4928dd03fb139692638b557fe3/app/models/concerns/enums/package_metadata.rb#L5)을(를) 참조하세요. GitLab Self-Managed, Ultimate 전용입니다. |
| `pages_domain_verification_enabled`       | 부울         | 아니요                                   | 사용자가 사용자 정의 도메인의 소유권을 증명하도록 요청합니다. 도메인 확인은 공개 GitLab 사이트의 필수 보안 조치입니다. 사용자는 도메인을 활성화하기 전에 도메인을 제어하고 있음을 증명해야 합니다. |
| `pages_unique_domain_default_enabled`    | 부울         | 아니요                                   | 주어진 네임스페이스 아래의 사이트 간 쿠키 공유를 피하기 위해 Pages 사이트의 기본값으로 고유 도메인을 활성화합니다. 기본값은 `true`입니다. |
| `password_authentication_enabled_for_git` | 부울         | 아니요                                   | GitLab 계정 비밀번호를 통한 HTTP(S) Git 인증을 활성화합니다. 기본값은 `true`입니다. |
| `password_authentication_enabled_for_web` | 부울         | 아니요                                   | GitLab 계정 비밀번호를 통한 웹 인터페이스 인증을 활성화합니다. 기본값은 `true`입니다. |
| `minimum_password_length`                | 정수          | 아니요                                   | 비밀번호에 최소 길이가 필요한지 여부를 나타냅니다. Premium 및 Ultimate만 해당합니다. |
| `password_number_required`               | 부울          | 아니요                                   | 비밀번호에 최소 한 개의 숫자가 필요한지 여부를 나타냅니다. Premium 및 Ultimate만 해당합니다. |
| `password_symbol_required`               | 부울          | 아니요                                   | 비밀번호에 최소 하나의 기호 문자가 필요한지 여부를 나타냅니다. Premium 및 Ultimate만 해당합니다. |
| `password_uppercase_required`            | 부울          | 아니요                                   | 비밀번호에 최소 한 개의 대문자가 필요한지 여부를 나타냅니다. Premium 및 Ultimate만 해당합니다. |
| `password_lowercase_required`            | 부울          | 아니요                                   | 비밀번호에 최소 한 개의 소문자가 필요한지 여부를 나타냅니다. Premium 및 Ultimate만 해당합니다. |
| `performance_bar_allowed_group_id`       | 문자열           | 아니요                                   | (지원 중단:  `performance_bar_allowed_group_path`을(를) 대신 사용합니다) 성능 표시줄을 토글할 수 있는 그룹의 경로입니다. |
| `performance_bar_allowed_group_path`     | 문자열           | 아니요                                   | 성능 표시줄을 토글할 수 있는 그룹의 경로입니다. |
| `performance_bar_enabled`                | 부울          | 아니요                                   | (지원 중단:  `performance_bar_allowed_group_path: nil`을(를) 대신 전달합니다) 성능 표시줄 활성화를 허용합니다. |
| `personal_access_token_prefix`           | 문자열           | 아니요                                   | 생성된 모든 개인 액세스 토큰의 접두사입니다. |
| `pipeline_limit_per_project_user_sha`    | 정수          | 아니요                                   | 사용자 및 커밋당 분당 최대 파이프라인 생성 요청 수입니다. 기본적으로 비활성화됨. |
| `pipeline_limit_per_user`                | 정수          | 아니요                                   | 사용자당 분당 최대 파이프라인 생성 요청 수입니다. |
| `gitpod_enabled`                         | 부울          | 아니요                                   | (**If enabled, requires**: `gitpod_url`) [Ona 통합](../integration/gitpod.md)을(를) 활성화합니다. 기본값은 `false`입니다. |
| `gitpod_url`                             | 문자열           | 필수: `gitpod_enabled`        | 통합을 위한 Ona 인스턴스 URL입니다. |
| `inactive_resource_access_tokens_delete_after_days`| 정수 | 아니요                                   | 비활성 프로젝트 및 그룹 액세스 토큰의 보존 기간을 지정합니다. 기본값은 `30`입니다. |
| `kroki_enabled`                          | 부울          | 아니요                                   | (**If enabled, requires**: `kroki_url`) [Kroki 통합](../administration/integration/kroki.md)을(를) 활성화합니다. 기본값은 `false`입니다. |
| `kroki_url`                              | 문자열           | 필수: `kroki_enabled`         | 통합을 위한 Kroki 인스턴스 URL입니다. |
| `kroki_formats`                          | 객체           | 아니요                                   | Kroki 인스턴스에서 지원하는 추가 형식입니다. 가능한 값은 형식 `bpmn`, `blockdiag`, `excalidraw` 및 `mermaid`의 경우 `true` 또는 `false`이며, `<format>: true` 또는 `<format>: false` 형식입니다. |
| `kroki_diagram_proxy_enabled`            | 부울          | 아니요                                   | [Kroki 다이어그램 프록시](../administration/integration/diagram_proxy.md)를 활성화합니다. 기본값은 `false`입니다. |
| `plantuml_enabled`                       | 부울          | 아니요                                   | (**If enabled, requires**: `plantuml_url`) [PlantUML 통합](../administration/integration/plantuml.md)을(를) 활성화합니다. 기본값은 `false`입니다. |
| `plantuml_url`                           | 문자열           | 필수: `plantuml_enabled`      | 통합을 위한 PlantUML 인스턴스 URL입니다. |
| `plantuml_diagram_proxy_enabled`         | 부울          | 아니요                                   | [PlantUML 다이어그램 프록시](../administration/integration/diagram_proxy.md)를 활성화합니다. 기본값은 `false`입니다. |
| `polling_interval_multiplier`            | 실수            | 아니요                                   | 폴링을 수행하는 엔드포인트에서 사용하는 간격 승수입니다. 폴링을 비활성화하려면 `0`로 설정합니다. |
| `project_export_enabled`                 | 부울          | 아니요                                   | 프로젝트 내보내기를 활성화합니다. |
| `project_jobs_api_rate_limit`            | 정수          | 아니요                                   | `/project/:id/jobs`에 대한 최대 인증 요청(분)입니다. [GitLab 16.5에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129319). 기본값:  600\. |
| `projects_api_rate_limit_unauthenticated` | 정수         | 아니요                                   | [모든 프로젝트 나열 API](projects.md#list-all-projects)에 대한 인증되지 않은 요청의 경우 IP 주소당 10분당 최대 요청 수입니다. 기본값:  400\. 스로틀링을 비활성화하려면 0으로 설정하세요.|
| `runner_jobs_request_api_limit`          | 정수          | 아니요                                   | `/jobs/request` 러너 작업 API 엔드포인트에 대한 요청의 경우 러너 토큰당 분당 최대 요청 수입니다. 기본값:  2000\. 스로틀링을 비활성화하려면 0으로 설정하세요. GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/462537)되었습니다. |
| `runner_jobs_patch_trace_api_limit`      | 정수          | 아니요                                   | `PATCH /jobs/:id/trace` 러너 작업 API 엔드포인트에 대한 요청의 경우 러너 토큰당 분당 최대 요청 수입니다. 기본값:  2000\. 스로틀링을 비활성화하려면 0으로 설정하세요. GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/462537)되었습니다. |
| `runner_jobs_endpoints_api_limit`        | 정수          | 아니요                                   | 러너 작업 API 엔드포인트에 대한 `/jobs/*` 요청의 경우 작업 토큰당 분당 최대 요청 수입니다. 기본값:  200\. 스로틀링을 비활성화하려면 0으로 설정하세요. GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/462537)되었습니다. |
| `users_api_limit_following` | 정수 |    아니요    | 사용자 또는 IP 주소당 분당 최대 요청 수입니다. 기본값:  100\. 제한을 비활성화하려면 `0`로 설정하세요. [GitLab 17.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054). |
| `users_api_limit_followers` | 정수 |    아니요    | 사용자 또는 IP 주소당 분당 최대 요청 수입니다. 기본값:  100\. 제한을 비활성화하려면 `0`로 설정하세요. [GitLab 17.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054). |
| `users_api_limit_status`    | 정수 |    아니요    | 사용자 또는 IP 주소당 분당 최대 요청 수입니다. 기본값:  240\. 제한을 비활성화하려면 `0`로 설정하세요. [GitLab 17.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054). |
| `users_api_limit_keys`      | 정수 |    아니요    | 사용자 또는 IP 주소당 분당 최대 요청 수입니다. 기본값:  120\. 제한을 비활성화하려면 `0`로 설정하세요. [GitLab 17.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054). |
| `users_api_limit_key`       | 정수 |    아니요    | 사용자 또는 IP 주소당 분당 최대 요청 수입니다. 기본값:  120\. 제한을 비활성화하려면 `0`로 설정하세요. [GitLab 17.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054). |
| `users_api_limit_gpg_keys`  | 정수 |    아니요    | 사용자 또는 IP 주소당 분당 최대 요청 수입니다. 기본값:  120\. 제한을 비활성화하려면 `0`로 설정하세요. [GitLab 17.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054). |
| `users_api_limit_gpg_key`   | 정수 |    아니요    | 사용자 또는 IP 주소당 분당 최대 요청 수입니다. 기본값:  120\. 제한을 비활성화하려면 `0`로 설정하세요. [GitLab 17.10에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054). |
| `virtual_registries_endpoints_api_limit`          | 정수          | 아니요                                   | 가상 레지스트리 엔드포인트에서 IP 주소당 15초당 최대 요청 수입니다. 기본값:  4000\. `0`로 설정하여 제한을 비활성화합니다. GitLab 17.11에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/521692). |
| `project_secrets_limit`                           | 정수          | 아니요                                   | Secrets Manager에서 프로젝트당 허용되는 최대 비밀 수입니다. 기본값:  100\. `0`로 설정하여 제한을 비활성화합니다. Ultimate만 해당. GitLab 18.9에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219436). |
| `group_secrets_limit`                             | 정수          | 아니요                                   | Secrets Manager에서 그룹당 허용되는 최대 비밀 수입니다. 기본값:  500\. `0`로 설정하여 제한을 비활성화합니다. Ultimate만 해당. GitLab 18.9에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219436). |
| `prometheus_metrics_enabled`             | 부울          | 아니요                                   | Prometheus 메트릭을 활성화합니다. |
| `protected_ci_variables`                 | 부울          | 아니요                                   | CI/CD 변수는 기본적으로 보호됩니다. |
| `disable_overriding_approvers_per_merge_request` | 부울  | 아니요                                   | 프로젝트 및 머지 리퀘스트에서 승인 규칙을 편집하지 못하도록 방지합니다. |
| `prevent_merge_requests_author_approval`         | 부울  | 아니요                                   | 머지 리퀘스트 작성자(작성자)의 승인을 방지합니다. |
| `prevent_merge_requests_committers_approval`     | 부울  | 아니요                                   | 머지 리퀘스트 커미터의 승인을 방지합니다. |
| `push_event_activities_limit`            | 정수          | 아니요                                   | 단일 푸시에서 [대량 푸시 이벤트가 생성](../administration/settings/push_event_activities_limit.md)되는 변경 사항(브랜치 또는 태그)의 최대 수입니다. `0`로 설정해도 제한이 비활성화되지 않습니다. |
| `push_event_hooks_limit`                 | 정수          | 아니요                                   | 단일 푸시에서 웹후크 및 통합이 트리거되지 않는 변경 사항(브랜치 또는 태그)의 최대 수입니다. `0`로 설정해도 제한이 비활성화되지 않습니다. 기본값: `3`. |
| `rate_limiting_response_text`            | 문자열           | 아니요                                   | `throttle_*` 설정을 통해 속도 제한이 활성화되면 속도 제한을 초과할 때 이 일반 텍스트 응답을 보냅니다. 이 값이 비어 있으면 '나중에 다시 시도'가 전송됩니다. |
| `raw_blob_request_limit`                 | 정수          | 아니요                                   | 각 원시 경로당 분당 최대 요청 수(기본값은 `300`)입니다. `0`로 설정하여 제한을 비활성화합니다.|
| `raw_blob_request_limit_unauthenticated` | 정수          | 아니요                                   | 프로젝트의 모든 원시 경로에서 분당 최대 인증되지 않은 요청 수(기본값은 `800`)입니다. `0`로 설정하여 제한을 비활성화합니다.|
| `search_rate_limit`                      | 정수          | 아니요                                   | 인증된 상태에서 검색을 수행하기 위한 분당 최대 요청 수입니다. 기본값:  30\. 스로틀링을 비활성화하려면 0으로 설정하세요.|
| `search_rate_limit_unauthenticated`      | 정수          | 아니요                                   | 인증되지 않은 상태에서 검색을 수행하기 위한 분당 최대 요청 수입니다. 기본값:  10\. 스로틀링을 비활성화하려면 0으로 설정하세요.|
| `recaptcha_enabled`                      | 부울          | 아니요                                   | (**If enabled, requires**: `recaptcha_private_key` 및 `recaptcha_site_key`) reCAPTCHA를 활성화합니다. |
| `login_recaptcha_protection_enabled`     | 부울          | 아니요                                   | 로그인을 위한 reCAPTCHA를 활성화합니다. |
| `recaptcha_private_key`                  | 문자열           | 필수: `recaptcha_enabled`     | reCAPTCHA용 개인 키입니다. |
| `recaptcha_site_key`                     | 문자열           | 필수: `recaptcha_enabled`     | reCAPTCHA용 사이트 키입니다. |
| `receptive_cluster_agents_enabled`       | 부울          | 아니요                                   | Kubernetes용 GitLab 에이전트에 대한 수용 모드를 활성화합니다. |
| `receive_max_input_size`                 | 정수          | 아니요                                   | 최대 푸시 크기(MB)입니다. |
| `relation_export_batch_size`             | 정수          | 아니요                                   | 배치 관계를 내보낼 때 각 배치의 크기입니다. [GitLab 18.2에서 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194607)됨. |
| `remember_me_enabled`                    | 부울          | 아니요                                   | [**계정 정보 저장** 설정](../administration/settings/account_and_limit_settings.md#configure-the-remember-me-option)을 활성화합니다. GitLab 16.0에서 도입되었습니다. |
| `repository_checks_enabled`              | 부울          | 아니요                                   | GitLab은 정기적으로 모든 프로젝트 및 위키 리포지토리에서 `git fsck`을(를) 실행하여 자동 디스크 손상 이슈를 찾습니다. |
| `repository_size_limit`                  | 정수          | 아니요                                   | 리포지토리당 크기 제한(MB)입니다. Premium 및 Ultimate만 해당합니다. |
| `repository_storages_weighted`           | 정수에 대한 문자열 해시 | 아니요                        | `gitlab.yml`에서 가져온 이름의 해시를 [가중치](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)로 지정합니다. 새 프로젝트는 가중치가 적용된 임의 선택에 의해 선택된 이 저장소 중 하나에서 생성됩니다. |
| `require_admin_approval_after_user_signup` | 부울        | 아니요                                   | 활성화된 경우 등록 양식을 사용하여 계정에 가입하는 모든 사용자는 **승인 대기중** 상태로 배치되며 관리자가 명시적으로 [승인](../administration/moderate_users.md)해야 합니다. |
| `require_email_verification_on_account_locked` | 부울    | 아니요                                   | `true`인 경우 인스턴스의 모든 사용자는 의심스러운 로그인 활동이 감지된 후 자신의 신원을 확인해야 합니다. |
| `require_personal_access_token_expiry`   | 부울          | 아니요                                   | 활성화된 경우 사용자는 그룹 또는 프로젝트 액세스 토큰 또는 비서비스 계정이 소유한 개인 액세스 토큰을 만들 때 만료 날짜를 설정해야 합니다. |
| `require_two_factor_authentication`      | 부울          | 아니요                                   | (**If enabled, requires**: `two_factor_grace_period`) 모든 사용자가 2단계 인증을 설정하도록 요구합니다. |
| `resource_usage_limits`                | 해시             | 아니요                                   | Sidekiq 작업자에서 적용되는 리소스 사용 제한 정의입니다. 이 설정은 GitLab.com에서만 사용할 수 있습니다. |
| `restricted_visibility_levels`           | 문자열 배열 | 아니요                                   | 선택한 수준은 관리자가 아닌 사용자가 그룹, 프로젝트 또는 스니펫에 사용할 수 없습니다. 매개변수로 `private`, `internal` 및 `public`을 사용할 수 있습니다. 기본값은 `null`입니다. 이는 제한이 없음을 의미합니다. GitLab 16.4에서 [변경됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203): `default_project_visibility` 및 `default_group_visibility`로 설정된 수준을 선택할 수 없습니다. |
| `rsa_key_restriction`                    | 정수          | 아니요                                   | 업로드된 RSA 키의 최소 허용 비트 길이입니다. 기본값은 `0`(제한 없음)입니다. `-1`는 RSA 키를 비활성화합니다. |
| `session_expire_delay`                   | 정수          | 아니요                                   | 세션 지속 시간(분)입니다. GitLab을 다시 시작하여 변경사항을 적용합니다. |
| `session_expire_from_init`               | 부울          | 아니요                                   | `true`인 경우 세션은 마지막 활동 후가 아니라 세션이 생성된 후 몇 분 후에 만료됩니다. 세션의 이 수명은 `session_expire_delay`에 의해 정의됩니다. |
| `security_policy_global_group_approvers_enabled` | 부울  | 아니요                                   | 머지 리퀘스트 승인 정책 승인 그룹을 전역적으로 조회할지 아니면 프로젝트 계층 구조 내에서 조회할지를 결정합니다. |
| `security_approval_policies_limit`       | 정수          | 아니요                                   | 보안 정책 프로젝트당 활성 머지 리퀘스트 승인 정책의 최대 수입니다. 기본값:  5\. 최대:  20 |
| `scan_execution_policies_action_limit`   | 정수          | 아니요                                   | 검사 실행 정책당 최대 `actions` 수입니다. 기본값:  0\. 최대:  20 |
| `scan_execution_policies_schedule_limit` | 정수          | 아니요                                   | 검사 실행 정책당 최대 `type: schedule` 규칙 수입니다. 기본값:  0\. 최대:  20 |
| `security_txt_content`                    | 문자열          | 아니요                                   | [공개 보안 연락처 정보](../administration/settings/security_contact_information.md). GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/433210)되었습니다. |
| `security_mr_report_cache_lifetime_minutes` | 정수       | 아니요                                   | 머지 리퀘스트에서 보안 보고서를 캐시할 분 수(10-60)입니다. 기본값:  10\. Premium 및 Ultimate만 해당합니다. GitLab 18.10에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223399). |
| `security_scan_stale_after_days`          | 정수          | 아니요                                   | 보안 검사 데이터를 삭제하기 전에 유지할 날 수입니다. 7~90일 사이여야 합니다. 기본값:  GitLab.com의 경우 30일, 자체 관리형의 경우 90일입니다. Premium 및 Ultimate만 해당합니다. GitLab 18.9에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/222998). |
| `service_access_tokens_expiration_enforced` | 부울       | 아니요                                   | 토큰 만료 날짜가 서비스 계정 사용자를 위해 선택 사항일 수 있는지 나타내는 플래그입니다. |
| `shared_runners_enabled`                 | 부울          | 아니요                                   | (**If enabled, requires**: `shared_runners_text` 및 `shared_runners_minutes`) 새 프로젝트에 대한 인스턴스 러너를 활성화합니다. |
| `shared_runners_minutes`                 | 정수          | 필수: `shared_runners_enabled` | 그룹이 월별 인스턴스 러너에서 사용할 수 있는 최대 컴퓨팅 분 수를 설정합니다. Premium 및 Ultimate만 해당합니다. |
| `shared_runners_text`                    | 문자열           | 필수: `shared_runners_enabled` | 인스턴스 러너 텍스트입니다. |
| `runner_token_expiration_interval`         | 정수        | 아니요                                   | 새로 등록된 인스턴스 러너의 인증 토큰 만료 시간(초)을 설정합니다. 최소값은 7200초입니다. 자세한 내용은 [인증 토큰 자동 회전](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens)을(를) 참조하세요. |
| `group_runner_token_expiration_interval`   | 정수        | 아니요                                   | 새로 등록된 그룹 러너의 인증 토큰 만료 시간(초)을 설정합니다. 최소값은 7200초입니다. 자세한 내용은 [인증 토큰 자동 회전](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens)을(를) 참조하세요. |
| `project_runner_token_expiration_interval` | 정수        | 아니요                                   | 새로 등록된 프로젝트 러너의 인증 토큰 만료 시간(초)을 설정합니다. 최소값은 7200초입니다. 자세한 내용은 [인증 토큰 자동 회전](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens)을(를) 참조하세요. |
| `sidekiq_job_limiter_mode`                        | 문자열  | 아니요                                   | `track` 또는 `compress`. [Sidekiq 작업 크기 제한](../administration/settings/sidekiq_job_limits.md)에 대한 동작을 설정합니다. 기본값: 'compress'. |
| `sidekiq_job_limiter_compression_threshold_bytes` | 정수 | 아니요                                   | Sidekiq 작업이 Redis에 저장되기 전에 압축되는 바이트 단위의 임계값입니다. 기본값:  100,000바이트(100KB). |
| `sidekiq_job_limiter_limit_bytes`                 | 정수 | 아니요                                   | Sidekiq 작업이 거부되는 바이트 단위의 임계값입니다. 기본값:  0바이트(어떤 작업도 거부하지 않음). |
| `signin_enabled`                         | 문자열           | 아니요                                   | (지원 중단:  `password_authentication_enabled_for_web` 대신 사용) 웹 인터페이스에 대해 암호 인증이 활성화되는지를 나타내는 플래그입니다. |
| `sign_in_restrictions`                   | 해시             | 아니요                                   | 응용 프로그램 로그인 제한입니다. |
| `signup_enabled`                         | 부울          | 아니요                                   | 등록을 활성화합니다. 기본값은 `true`입니다. |
| `silent_admin_exports_enabled`           | 부울          | 아니요                                   | [자동 관리자 내보내기](../administration/settings/import_and_export_settings.md#enable-silent-admin-exports)를 활성화합니다. 기본값은 `false`입니다. |
| `silent_mode_enabled`                    | 부울          | 아니요                                   | [자동 모드](../administration/silent_mode/_index.md)를 활성화합니다. 기본값은 `false`입니다. |
| `slack_app_enabled`                      | 부울          | 아니요                                   | (**If enabled, requires**: `slack_app_id`, `slack_app_secret`, `slack_app_signing_secret` 및 `slack_app_verification_token`) GitLab for Slack 앱을 활성화합니다. |
| `slack_app_id`                           | 문자열           | 필수: `slack_app_enabled`     | GitLab for Slack 앱의 클라이언트 ID입니다. |
| `slack_app_secret`                       | 문자열           | 필수: `slack_app_enabled`     | GitLab for Slack 앱의 클라이언트 비밀입니다. 앱에서 OAuth 요청을 인증하는 데 사용됩니다. |
| `slack_app_signing_secret`               | 문자열           | 필수: `slack_app_enabled`     | GitLab for Slack 앱의 서명 비밀입니다. 앱에서 API 요청을 인증하는 데 사용됩니다. |
| `slack_app_verification_token`           | 문자열           | 필수: `slack_app_enabled`     | GitLab for Slack 앱의 확인 토큰입니다. 이 인증 방법은 Slack에서 더 이상 사용되지 않으며 앱에서 슬래시 명령만 인증하는 데 사용됩니다. |
| `snippet_size_limit`                     | 정수          | 아니요                                   | 최대 스니펫 콘텐츠 크기(단위: **bytes**)입니다. 기본값:  52428800바이트(50MB).|
| `snowplow_app_id`                        | 문자열           | 아니요                                   | Snowplow 사이트 이름/응용 프로그램 ID입니다. (예: `gitlab`) |
| `snowplow_collector_hostname`            | 문자열           | 필수: `snowplow_enabled`      | Snowplow 수집기 호스트 이름입니다. (예: `snowplowprd.trx.gitlab.net`) |
| `snowplow_database_collector_hostname`   | 문자열           | 아니요                                   | 데이터베이스 이벤트용 Snowplow 수집기 호스트 이름입니다. (예: `db-snowplow.trx.gitlab.net`) |
| `snowplow_cookie_domain`                 | 문자열           | 아니요                                   | Snowplow 쿠키 도메인입니다. (예: `.gitlab.com`) |
| `snowplow_enabled`                       | 부울          | 아니요                                   | Snowplow 추적을 활성화합니다. |
| `sourcegraph_enabled`                    | 부울          | 아니요                                   | Sourcegraph 통합을 활성화합니다. 기본값은 `false`입니다. **If enabled, requires** `sourcegraph_url`. |
| `sourcegraph_public_only`                | 부울          | 아니요                                   | 개인 및 내부 프로젝트에서 Sourcegraph가 로드되지 않도록 차단합니다. 기본값은 `true`입니다. |
| `sourcegraph_url`                        | 문자열           | 필수: `sourcegraph_enabled`   | 통합을 위한 Sourcegraph 인스턴스 URL입니다. |
| `spam_check_endpoint_enabled`            | 부울          | 아니요                                   | 외부 스팸 확인 API 엔드포인트를 사용하여 스팸 확인을 활성화합니다. 기본값은 `false`입니다. |
| `spam_check_endpoint_url`                | 문자열           | 아니요                                   | 외부 스팸 검사 서비스 엔드포인트의 URL입니다. 유효한 URI 스키마는 `grpc` 또는 `tls`입니다. `tls`을(를) 지정하면 통신이 암호화됩니다.|
| `spam_check_api_key`                     | 문자열           | 아니요                                   | 스팸 검사 서비스 엔드포인트에 액세스하기 위해 GitLab에서 사용하는 API 키입니다. |
| `suggest_pipeline_enabled`               | 부울          | 아니요                                   | 파이프라인 제안 배너를 활성화합니다. |
| `enable_artifact_external_redirect_warning_page` | 부울  | 아니요                                   | GitLab Pages의 사용자 생성 콘텐츠에 대해 경고하는 외부 리디렉션 페이지를 표시합니다. |
| `terminal_max_session_time`              | 정수          | 아니요                                   | 웹 터미널 웹소켓 연결의 최대 시간(초)입니다. `0`로 설정하여 무제한 시간으로 설정합니다. |
| `terms`                                  | 텍스트             | 필수: `enforce_terms`         | (**Required by**: `enforce_terms`) ToS에 대한 마크다운 콘텐츠입니다. |
| `throttle_authenticated_api_enabled`                      | 부울 | 아니요                                                              | (**If enabled, requires**: `throttle_authenticated_api_period_in_seconds` 및 `throttle_authenticated_api_requests_per_period`) 인증된 API 요청 속도 제한을 활성화합니다. 요청 볼륨을 줄이는 데 도움이 됩니다(예: 크롤러 또는 악성 봇의 경우). |
| `throttle_authenticated_api_period_in_seconds`            | 정수 | 필수:<br>`throttle_authenticated_api_enabled`            | 속도 제한 기간(초)입니다. |
| `throttle_authenticated_api_requests_per_period`          | 정수 | 필수:<br>`throttle_authenticated_api_enabled`            | 사용자당 기간당 최대 요청 수입니다. |
| `throttle_authenticated_git_http_enabled`             | 부울 | 조건부 | `true`인 경우 인증된 Git HTTP 요청 속도 제한을 적용합니다. 기본값: `false`. |
| `throttle_authenticated_git_http_period_in_seconds`   | 정수 | 아니요            | 속도 제한 기간(초)입니다. `throttle_authenticated_git_http_enabled`은(는) `true`이어야 합니다. 기본값: `3600`. |
| `throttle_authenticated_git_http_requests_per_period` | 정수 | 아니요            | 사용자당 기간당 최대 요청 수입니다. `throttle_authenticated_git_http_enabled`은(는) `true`이어야 합니다. 기본값: `3600`. |
| `throttle_authenticated_packages_api_enabled`             | 부울 | 아니요                                                              | (**If enabled, requires**: `throttle_authenticated_packages_api_period_in_seconds` 및 `throttle_authenticated_packages_api_requests_per_period`) 인증된 API 요청 속도 제한을 활성화합니다. 요청 볼륨을 줄이는 데 도움이 됩니다(예: 크롤러 또는 악성 봇의 경우). [패키지 레지스트리 속도 제한](../administration/settings/package_registry_rate_limits.md)을(를) 참조하세요. |
| `throttle_authenticated_packages_api_period_in_seconds`   | 정수 | 필수:<br>`throttle_authenticated_packages_api_enabled`   | 속도 제한 기간(초)입니다. [패키지 레지스트리 속도 제한](../administration/settings/package_registry_rate_limits.md)을(를) 참조하세요. |
| `throttle_authenticated_packages_api_requests_per_period` | 정수 | 필수:<br>`throttle_authenticated_packages_api_enabled`   | 사용자당 기간당 최대 요청 수입니다. [패키지 레지스트리 속도 제한](../administration/settings/package_registry_rate_limits.md)을(를) 참조하세요. |
| `throttle_authenticated_web_enabled`                      | 부울 | 아니요                                                              | (**If enabled, requires**: `throttle_authenticated_web_period_in_seconds` 및 `throttle_authenticated_web_requests_per_period`) 인증된 웹 요청 속도 제한을 활성화합니다. 요청 볼륨을 줄이는 데 도움이 됩니다(예: 크롤러 또는 악성 봇의 경우). |
| `throttle_authenticated_web_period_in_seconds`            | 정수 | 필수:<br>`throttle_authenticated_web_enabled`            | 속도 제한 기간(초)입니다. |
| `throttle_authenticated_web_requests_per_period`          | 정수 | 필수:<br>`throttle_authenticated_web_enabled`            | 사용자당 기간당 최대 요청 수입니다. |
| `throttle_unauthenticated_enabled`                        | 부울 | 아니요                                                              | GitLab 14.3에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/335300). `throttle_unauthenticated_web_enabled` 또는 `throttle_unauthenticated_api_enabled` 대신 사용합니다.) (**If enabled, requires**: `throttle_unauthenticated_period_in_seconds` 및 `throttle_unauthenticated_requests_per_period`) 인증되지 않은 웹 요청 속도 제한을 활성화합니다. 요청 볼륨을 줄이는 데 도움이 됩니다(예: 크롤러 또는 악성 봇의 경우). |
| `throttle_unauthenticated_period_in_seconds`              | 정수 | 필수:<br>`throttle_unauthenticated_enabled`              | GitLab 14.3에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/335300). `throttle_unauthenticated_web_period_in_seconds` 또는 `throttle_unauthenticated_api_period_in_seconds` 대신 사용합니다.) 속도 제한 기간(초)입니다. |
| `throttle_unauthenticated_requests_per_period`            | 정수 | 필수:<br>`throttle_unauthenticated_enabled`              | GitLab 14.3에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/335300). `throttle_unauthenticated_web_requests_per_period` 또는 `throttle_unauthenticated_api_requests_per_period` 대신 사용합니다.) IP당 기간당 최대 요청 수입니다. |
| `throttle_unauthenticated_api_enabled`                    | 부울 | 아니요                                                              | (**If enabled, requires**: `throttle_unauthenticated_api_period_in_seconds` 및 `throttle_unauthenticated_api_requests_per_period`) 인증되지 않은 API 요청 속도 제한을 활성화합니다. 요청 볼륨을 줄이는 데 도움이 됩니다(예: 크롤러 또는 악성 봇의 경우). |
| `throttle_unauthenticated_api_period_in_seconds`          | 정수 | 필수:<br>`throttle_unauthenticated_api_enabled`          | 속도 제한 기간(초)입니다. |
| `throttle_unauthenticated_api_requests_per_period`        | 정수 | 필수:<br>`throttle_unauthenticated_api_enabled`          | IP당 기간당 최대 요청 수입니다. |
| `throttle_unauthenticated_git_http_enabled`             | 부울 | 조건부 | `true`인 경우 인증되지 않은 Git HTTP 요청 속도 제한을 적용합니다. 기본값: `false`. |
| `throttle_unauthenticated_git_http_period_in_seconds`   | 정수 | 아니요            | 속도 제한 기간(초)입니다. `throttle_unauthenticated_git_http_enabled`은(는) `true`이어야 합니다. 기본값: `3600`. |
| `throttle_unauthenticated_git_http_requests_per_period` | 정수 | 아니요            | IP당 기간당 최대 요청 수입니다. `throttle_unauthenticated_git_http_enabled`은(는) `true`이어야 합니다. 기본값: `3600`. |
| `throttle_unauthenticated_packages_api_enabled`           | 부울 | 아니요                                                              | (**If enabled, requires**: `throttle_unauthenticated_packages_api_period_in_seconds` 및 `throttle_unauthenticated_packages_api_requests_per_period`) 인증되지 않은 API 요청 속도 제한을 활성화합니다. 요청 볼륨을 줄이는 데 도움이 됩니다(예: 크롤러 또는 악성 봇의 경우). [패키지 레지스트리 속도 제한](../administration/settings/package_registry_rate_limits.md)을(를) 참조하세요. |
| `throttle_unauthenticated_packages_api_period_in_seconds` | 정수 | 필수:<br>`throttle_unauthenticated_packages_api_enabled` | 속도 제한 기간(초)입니다. [패키지 레지스트리 속도 제한](../administration/settings/package_registry_rate_limits.md)을(를) 참조하세요. |
| `throttle_unauthenticated_packages_api_requests_per_period` | 정수 | 필수:<br>`throttle_unauthenticated_packages_api_enabled` | 사용자당 기간당 최대 요청 수입니다. [패키지 레지스트리 속도 제한](../administration/settings/package_registry_rate_limits.md)을(를) 참조하세요. |
| `throttle_unauthenticated_web_enabled`                    | 부울 | 아니요                                                              | (**If enabled, requires**: `throttle_unauthenticated_web_period_in_seconds` 및 `throttle_unauthenticated_web_requests_per_period`) 인증되지 않은 웹 요청 속도 제한을 활성화합니다. 요청 볼륨을 줄이는 데 도움이 됩니다(예: 크롤러 또는 악성 봇의 경우). |
| `throttle_unauthenticated_web_period_in_seconds`          | 정수 | 필수:<br>`throttle_unauthenticated_web_enabled`          | 속도 제한 기간(초)입니다. |
| `throttle_unauthenticated_web_requests_per_period`        | 정수 | 필수:<br>`throttle_unauthenticated_web_enabled`          | IP당 기간당 최대 요청 수입니다. |
| `time_tracking_limit_to_hours`           | 부울          | 아니요                                   | 시간 추적 단위의 표시를 시간으로 제한합니다. 기본값은 `false`입니다. |
| `top_level_group_creation_enabled`           | 부울          | 아니요                                   | 사용자가 최상위 그룹을 만들 수 있습니다. 기본값은 `true`입니다. |
| `two_factor_grace_period`                | 정수          | 필수: `require_two_factor_authentication` | 사용자가 2단계 인증의 강제 구성을 건너뛸 수 있는 시간(시간)입니다. |
| `unconfirmed_users_delete_after_days`    | 정수          | 아니요                                   | 계정 생성 후 이메일을 확인하지 않은 사용자를 삭제할 날 수를 지정합니다. `delete_unconfirmed_users`이(가) `true`로 설정된 경우에만 적용됩니다. `1` 이상이어야 합니다. 기본값은 `7`입니다. [GitLab 16.1에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/352514). GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `unique_ips_limit_enabled`               | 부울          | 아니요                                   | (**If enabled, requires**: `unique_ips_limit_per_user` 및 `unique_ips_limit_time_window`) 여러 IP에서 로그인을 제한합니다. |
| `unique_ips_limit_per_user`              | 정수          | 필수: `unique_ips_limit_enabled` | 사용자당 최대 IP 수입니다. |
| `unique_ips_limit_time_window`           | 정수          | 필수: `unique_ips_limit_enabled` | IP가 제한에 포함되는 기간(초)입니다. |
| `update_runner_versions_enabled`         | 부울          | 아니요                                   | GitLab.com에서 GitLab 러너 릴리스 버전 데이터를 가져옵니다. 자세한 내용은 [업그레이드해야 하는 러너 결정](../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded)하는 방법을 참조하세요. |
| `usage_ping_enabled`                     | 부울          | 아니요                                   | GitLab은 매주 GitLab Inc.에 라이선스 사용 현황을 보고합니다. |
| `gitlab_product_usage_data_enabled`      | 부울          | 아니요                                   | 제품 사용 현황 데이터 수집이 활성화되는지 나타냅니다. `GITLAB_PRODUCT_USAGE_DATA_ENABLED` 환경 변수가 설정된 경우 API는 환경 변수에서 유효한 값을 반환합니다. |
| `gitlab_product_usage_data_source`       | 문자열           | 아니요                                   | 읽기 전용입니다. `gitlab_product_usage_data_enabled` 설정의 원본을 나타냅니다. `environment` 환경 변수가 설정된 경우 `GITLAB_PRODUCT_USAGE_DATA_ENABLED`을(를) 반환하고, 그렇지 않으면 `database`을(를) 반환합니다. |
| `use_clickhouse_for_analytics`           | 부울          | 아니요                                   | ClickHouse를 분석 보고서의 데이터 소스로 활성화합니다. 이 설정이 적용되려면 ClickHouse를 구성해야 합니다. Premium 및 Ultimate에서만 사용 가능합니다. |
| `include_optional_metrics_in_service_ping`| 부울         | 아니요                                   | Service Ping에서 선택 사항 메트릭이 활성화되는지 여부를 나타냅니다. GitLab 16.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141540)됨. |
| `user_deactivation_emails_enabled`       | 부울          | 아니요                                   | 계정 비활성화 시 사용자에게 이메일을 보냅니다. |
| `user_default_external`                  | 부울          | 아니요                                   | 새로 등록된 사용자는 기본적으로 외부입니다. |
| `user_default_internal_regex`            | 문자열           | 아니요                                   | 기본 내부 사용자를 식별하기 위해 이메일 주소 정규식 패턴을 지정합니다. |
| `user_defaults_to_private_profile`       | 부울          | 아니요                                   | 새로 생성된 사용자는 기본적으로 개인 프로필이 있습니다. `false`로 기본값이 설정됩니다. |
| `user_oauth_applications`                | 부울          | 아니요                                   | 사용자가 GitLab을 OAuth 공급자로 사용할 애플리케이션을 등록하도록 허용합니다. 이 설정은 그룹 수준 OAuth 애플리케이션에는 영향을 주지 않습니다. |
| `user_show_add_ssh_key_message`          | 부울          | 아니요                                   | `false`로 설정하면 업로드된 SSH 키가 없는 사용자에게 표시되는 `You won't be able to pull or push project code via SSH` 경고를 비활성화합니다. |
| `version_check_enabled`                  | 부울          | 아니요                                   | GitLab이 업데이트를 사용할 수 있을 때 알려줍니다. |
| `valid_runner_registrars`                | 문자열 배열 | 아니요                                   | GitLab 러너를 등록하도록 허용된 유형 목록입니다. `[]`, `['group']`, `['project']` 또는 `['group', 'project']`일 수 있습니다. |
| `vscode_extension_marketplace`           | 해시             | 아니요                                   | VS Code 확장 마켓플레이스 설정입니다. [웹 IDE](../user/project/web_ide/_index.md) 및 [워크스페이스](../user/workspace/_index.md)에서 사용됩니다. |
| `whats_new_variant`                      | 문자열           | 아니요                                   | 새로운 기능 변형, 가능한 값: `all_tiers`, `current_tier` 및 `disabled`. |
| `wiki_page_max_content_bytes`            | 정수          | 아니요                                   | 최대 위키 페이지 콘텐츠 크기(단위: **bytes**)입니다. 기본값:  5242880바이트(5MB). 최소값은 1024바이트입니다. |
| `bulk_import_concurrent_pipeline_batch_limit` | 정수     | 아니요                                   | 최대 동시 직접 전송 배치 내보내기를 처리합니다. |
| `concurrent_relation_batch_export_limit` | 정수          | 아니요                                   | 최대 동시 배치 내보내기 작업 수를 처리합니다. GitLab 17.6에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169122). |
| `asciidoc_max_includes`                  | 정수          | 아니요                                   | 단일 문서에서 처리되는 최대 AsciiDoc 포함 지시문입니다. 기본값:  32\. 최대:  64\. |
| `duo_custom_agents_enabled`              | 부울          | 아니요                                   | 사용자 지정 에이전트가 이 인스턴스에 대해 허용되는지를 나타냅니다. 기본값: `true`. GitLab Self-Managed, Premium 및 Ultimate만 해당. GitLab 19.0에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615). |
| `duo_custom_flows_enabled`               | 부울          | 아니요                                   | 사용자 지정 플로우가 이 인스턴스에 대해 허용되는지를 나타냅니다. 기본값: `true`. GitLab Self-Managed, Premium 및 Ultimate만 해당. GitLab 19.0에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615). |
| `duo_external_agents_enabled`            | 부울          | 아니요                                   | 외부 에이전트가 이 인스턴스에 대해 허용되는지를 나타냅니다. 기본값: `true`. GitLab Self-Managed, Premium 및 Ultimate만 해당. GitLab 19.0에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615). |
| `duo_features_enabled`                   | 부울          | 아니요                                   | GitLab Duo 기능이 이 인스턴스에 대해 활성화되는지를 나타냅니다. GitLab 16.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931)됨. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `lock_duo_custom_agents_enabled`         | 부울          | 아니요                                   | 사용자 지정 에이전트 활성화 설정이 모든 그룹에 대해 적용되는지를 나타냅니다. 기본값: `false`. GitLab Self-Managed, Premium 및 Ultimate만 해당. GitLab 19.0에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615). |
| `lock_duo_custom_flows_enabled`          | 부울          | 아니요                                   | 사용자 지정 플로우 활성화 설정이 모든 그룹에 대해 적용되는지를 나타냅니다. 기본값: `false`. GitLab Self-Managed, Premium 및 Ultimate만 해당. GitLab 19.0에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615). |
| `lock_duo_external_agents_enabled`       | 부울          | 아니요                                   | 외부 에이전트 활성화 설정이 모든 그룹에 대해 적용되는지를 나타냅니다. 기본값: `false`. GitLab Self-Managed, Premium 및 Ultimate만 해당. GitLab 19.0에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615). |
| `lock_duo_features_enabled`              | 부울          | 아니요                                   | GitLab Duo 기능 활성화 설정이 모든 서브그룹에 대해 적용되는지 나타냅니다. GitLab 16.10에 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931)됨. GitLab Self-Managed, Premium 및 Ultimate만 해당. |
| `nuget_skip_metadata_url_validation` | 부울     | 아니요                                   | NuGet 패키지에 대한 메타데이터 URL 유효성 검사를 건너뛸지 여부를 나타냅니다. [GitLab 17.0에 도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145887). |
| `helm_max_packages_count` | 정수     | 아니요                                   | 채널당 나열할 수 있는 최대 Helm 패키지 수입니다. 최소 1이어야 합니다. 기본값은 1000입니다. |
| `require_admin_two_factor_authentication` | 부울         | 아니요 | 관리자가 인스턴스의 모든 관리자에 대해 2FA를 요구할 수 있도록 허용합니다. |
| `secret_push_protection_available` | 부울         | 아니요 | 프로젝트가 비밀 푸시 보호를 활성화할 수 있도록 허용합니다. 이는 비밀 푸시 보호를 활성화하지 않습니다. Ultimate만 해당. |
| `disable_invite_members` | 부울         | 아니요 | 그룹에 대한 멤버 초대 기능을 비활성화합니다. |
| `enforce_pipl_compliance` | 부울 | 아니요 | SaaS 애플리케이션에 대해 pipl 규정 준수가 적용되는지 여부를 설정합니다. |
| `iframe_rendering_enabled`               | 부울          | 아니요                                   | Markdown에서 iframe 렌더링을 허용합니다. 기본적으로 비활성화됨. |
| `iframe_rendering_allowlist`             | 문자열 배열 | 아니요                                   | 콘텐츠 보안 정책 및 삭제에 사용되는 허용된 iframe `src` host[:port] 항목의 목록입니다. |
| `iframe_rendering_allowlist_raw`         | 문자열           | 아니요                                   | 허용된 iframe `src` host[:port] 항목의 줄 바꿈 또는 쉼표로 구분된 목록입니다. |
| `usage_billing`                          | 객체           | 아니요                                   | 사용 현황 청구 설정입니다. 스키마 정의는 `ee/app/validators/json_schemas/usage_billing_settings.json`을(를) 확인합니다. |

### 휴면 프로젝트 설정 {#dormant-project-settings}

휴면 프로젝트 삭제를 구성하거나 비활성화할 수 있습니다.

| 속성                                | 유형             | 필수                             | 설명 |
|------------------------------------------|------------------|:------------------------------------:|-------------|
| `delete_inactive_projects`               | 부울          | 아니요                                   | [휴면 프로젝트 삭제](../administration/dormant_project_deletion.md)를 활성화합니다. 기본값은 `false`입니다. GitLab 15.4에서 [기능 플래그 없이 운영되기 시작했습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96803). |
| `inactive_projects_delete_after_months`  | 정수          | 아니요                                   | `delete_inactive_projects`이(가) `true`인 경우, 휴면 프로젝트를 삭제하기 전에 대기할 시간(월 단위)입니다. 기본값은 `2`입니다. GitLab 15.0에서 [운영되기 시작했습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689). |
| `inactive_projects_min_size_mb`          | 정수          | 아니요                                   | `delete_inactive_projects`이(가) `true`인 경우, 비활성 상태를 확인할 프로젝트의 최소 리포지토리 크기입니다. 기본값은 `0`입니다. GitLab 15.0에서 [운영되기 시작했습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689). |
| `inactive_projects_send_warning_email_after_months` | 정수 | 아니요                                 | `delete_inactive_projects`이(가) `true`인 경우, 프로젝트가 휴면 상태로 인해 삭제 예정인 경우 유지 관리자에게 이메일을 보내기 전에 대기할 시간(월 단위)을 설정합니다. 기본값은 `1`입니다. GitLab 15.0에서 [운영되기 시작했습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689). |

### 패키지 레지스트리 설정:  패키지 파일 크기 제한 {#package-registry-settings-package-file-size-limits}

패키지 파일 크기 제한은 애플리케이션 설정 API의 일부가 아닙니다. 대신, 이러한 설정은 [계획 제한 API](plan_limits.md)를 사용하여 액세스할 수 있습니다.

## 관련 항목 {#related-topics}

- [`default_branch_protection_defaults`의 옵션](groups.md#options-for-default_branch_protection_defaults)
