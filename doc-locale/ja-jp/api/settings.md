---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アプリケーション設定API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、GitLabのインスタンスの[アプリケーション設定](#available-settings)を操作します。

アプリケーション設定への変更はキャッシュの対象となるため、すぐに反映されない場合があります。デフォルトでは、GitLabはアプリケーション設定を60秒間キャッシュします。インスタンスのアプリケーション設定キャッシュを制御する方法については、[アプリケーションキャッシュ間隔](../administration/application_settings_cache.md)を参照してください。

前提条件: 

- インスタンスへの管理者アクセス権が必要です。

## 現在のアプリケーション設定に関する詳細を取得 {#retrieve-details-on-current-application-settings}

{{< history >}}

- `always_perform_delayed_deletion`フィーチャーフラグがGitLab 15.11で[有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332)されました。
- `delayed_project_deletion`および`delayed_group_deletion`の属性はGitLab 16.0で削除されました。
- `in_product_marketing_emails_enabled`属性はGitLab 16.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/418137)されました。
- `repository_storages`属性はGitLab 16.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/429675)されました。
- `user_email_lookup_limit`属性はGitLab 16.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136886)されました。
- `allow_all_integrations`および`allowed_integrations`の属性はGitLab 17.6で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)されました。

{{< /history >}}

このGitLabインスタンスの現在の[アプリケーション設定](#available-settings)に関する詳細を取得します。

```plaintext
GET /application/settings
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/settings"
```

レスポンス例: 

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
  "oauth_access_token_expires_in": 7200,
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

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)をご利用のユーザーは、以下のパラメータも参照できます:

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

## アプリケーション設定の更新 {#update-application-settings}

{{< history >}}

- `always_perform_delayed_deletion`フィーチャーフラグがGitLab 15.11で[有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332)されました。
- `delayed_project_deletion`および`delayed_group_deletion`の属性はGitLab 16.0で削除されました。
- `always_perform_delayed_deletion`フィーチャーフラグはGitLab 16.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120476)されました。
- `user_email_lookup_limit`属性はGitLab 16.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136886)されました。
- `default_branch_protection`はGitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)になりました。代わりに`default_branch_protection_defaults`を使用してください。
- `throttle_unauthenticated_git_http_enabled`、`throttle_unauthenticated_git_http_period_in_seconds`、および`throttle_unauthenticated_git_http_requests_per_period`の属性はGitLab 17.0で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112)されました。
- `allow_all_integrations`および`allowed_integrations`の属性はGitLab 17.6で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)されました。
- `throttle_authenticated_git_http_enabled`、`throttle_authenticated_git_http_period_in_seconds`、および`throttle_authenticated_git_http_requests_per_period`の属性はGitLab 18.1で`git_authenticated_http_limit`という名前の[フラグ](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191552)とともに[追加](../administration/feature_flags/_index.md)されました。デフォルトでは無効になっています。
- `git_authenticated_http_limit`フィーチャーフラグはGitLab 18.3で[有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/543768)されました。
- `git_authenticated_http_limit`フィーチャーフラグはGitLab 18.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/561577)されました。

{{< /history >}}

このGitLabインスタンスの現在の[アプリケーション設定](#available-settings)を更新します。

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

レスポンス例: 

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
  "oauth_access_token_expires_in": 7200,
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

[GitLab PremiumまたはUltimate](https://about.gitlab.com/pricing/)をご利用のユーザーは、以下のパラメータも参照できます:

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

レスポンス例:

```json
  "file_template_project_id": 1,
  "geo_node_allowed_ips": "0.0.0.0/0, ::/0",
  "duo_features_enabled": true,
  "lock_duo_features_enabled": false,
  "allow_all_integrations": true,
  "allowed_integrations": [],
  "virtual_registries_endpoints_api_limit": 4000
```

## 利用可能な設定 {#available-settings}

<!--
This heading is referenced by a script: `scripts/cells/application-settings-analysis.rb`
 Any updates to this heading should be reflected for the DOC_API_SETTINGS_TABLE_REGEX variable.
 -->

{{< history >}}

- `housekeeping_full_repack_period`、`housekeeping_gc_period`、および`housekeeping_incremental_repack_period`はGitLab 15.8で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106963)になりました。代わりに`housekeeping_optimize_repository_period`を使用してください。
- `allow_account_deletion`はGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412411)されました。
- `allow_project_creation_for_guest_and_below`はGitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134625)されました。
- GitLab 17.0で`silent_admin_exports_enabled`が[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148918)。
- `ai_action_api_rate_limit`はGitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149945)されました。
- `require_personal_access_token_expiry`はGitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/470192)されました。
- `receptive_cluster_agents_enabled`はGitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463427)されました。
- `allow_all_integrations`および`allowed_integrations`はGitLab 17.6で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)されました。
- `iframe_rendering_enabled`、`iframe_rendering_allowlist`、および`iframe_rendering_allowlist_raw`はGitLab 18.6で導入されました。
- `email_otp_enabled`はGitLab 19.1で導入されました。

{{< /history >}}

一般的に、すべての設定はオプションです。一部の設定を有効にする場合、他の関連する設定も設定する必要がある場合があります。これらの要件は、次の表の`Required`列に記載されています。

| 属性                                | 型             | 必須                             | 説明 |
|------------------------------------------|------------------|:------------------------------------:|-------------|
| `admin_mode`                             | ブール値          | いいえ                                   | 管理者が管理タスクのために再認証を行うことで、管理者モードを有効にするよう要求します。 |
| `admin_notification_email`               | 文字列           | いいえ                                   | 非推奨: 代わりに`abuse_notification_email`を使用してください。デフォルトが設定されている場合、[不正行為レポート](../administration/review_abuse_reports.md)はこのアドレスに送信されます。不正行為レポートは常に**管理者**エリアで利用できます。 |
| `abuse_notification_email`               | 文字列           | いいえ                                   | デフォルトが設定されている場合、[不正行為レポート](../administration/review_abuse_reports.md)はこのアドレスに送信されます。不正行為レポートは常に**管理者**エリアで利用できます。 |
| `notify_on_unknown_sign_in`              | ブール値          | いいえ                                   | 不明なIPアドレスからのサインインが発生した場合に通知を送信することを有効にします。 |
| `after_sign_out_path`                    | 文字列           | いいえ                                   | ログアウト後にユーザーをリダイレクトする場所。 |
| `email_restrictions_enabled`             | ブール値          | いいえ                                   | 新規ユーザーがメールでアカウントを作成することを防ぎます。 |
| `email_restrictions`                     | 文字列           | `email_restrictions_enabled`で必要 | 登録時に使用されたメールアドレスに対して確認される正規表現。 |
| `after_sign_up_text`                     | 文字列           | いいえ                                   | 登録後にユーザーに表示されるテキスト。 |
| `ai_action_api_rate_limit`               | 整数          | いいえ                                   | `aiAction` GraphQLミューテーションに対して、ユーザーごとに8時間あたりに許可されるリクエストの最大数。デフォルトは`160`です。`0`に設定すると、レート制限を無効にできます。 |
| `akismet_api_key`                        | 文字列           | `akismet_enabled`で必要       | Akismetスパム保護のAPIキー。 |
| `akismet_enabled`                        | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `akismet_api_key`) Akismetスパム保護を有効または無効にします。 |
| `allow_all_integrations`                 | ブール値          | いいえ                                   | `false`の場合、`allowed_integrations`に含まれるインテグレーションのみがインスタンスで許可されます。Ultimateのみ。 |
| `allowed_integrations`                   | 文字列の配列 | いいえ                                   | `allow_all_integrations`が`false`の場合、このリストに含まれるインテグレーションのみがインスタンスで許可されます。Ultimateのみ。 |
| `allow_account_deletion`                 | ブール値          | いいえ                                   | ユーザーがアカウントを削除できるように`true`に設定します。PremiumおよびUltimateのみです。 |
| `allow_group_owners_to_manage_ldap`      | ブール値          | いいえ                                   | グループオーナーがLDAPを管理できるように`true`に設定します。PremiumおよびUltimateのみです。 |
| `allow_local_requests_from_hooks_and_services` | ブール値    | いいえ                                   | (非推奨: `allow_local_requests_from_web_hooks_and_services`を使用してください) Webhookおよびインテグレーションからのローカルネットワークへのリクエストを許可します。 |
| `allow_local_requests_from_system_hooks` | ブール値          | いいえ                                   | システムフックからのローカルネットワークへのリクエストを許可します。 |
| `allow_local_requests_from_web_hooks_and_services` | ブール値 | いいえ                                  | Webhookおよびインテグレーションからのローカルネットワークへのリクエストを許可します。 |
| `allow_project_creation_for_guest_and_below` | ブール値      | いいえ                                   | ゲストロール以下の権限が割り当てられたユーザーがグループおよび個人プロジェクトを作成できるかどうかを示します。`true`がデフォルトです。 |
| `allow_runner_registration_token`        | ブール値          | いいえ                                   | 登録トークンを使用してRunnerを作成することを許可します。`true`がデフォルトです。 |
| `archive_builds_in_human_readable`       | 文字列           | いいえ                                   | ジョブが古いと見なされ、期限切れになる期間を設定します。その時間が経過すると、ジョブはアーカイブされ、再試行できなくなります。ジョブが期限切れにならないようにするには、値を空にしてください。例えば、`15 days`、`1 month`、`2 years`など、1日以上である必要があります。 |
| `asset_proxy_enabled`                    | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `asset_proxy_url`) アセットのプロキシを有効にします。変更を適用するにはGitLabの再起動が必要です。 |
| `asset_proxy_secret_key`                 | 文字列           | いいえ                                   | アセットプロキシサーバーとの共有シークレット。変更を適用するにはGitLabの再起動が必要です。 |
| `asset_proxy_url`                        | 文字列           | いいえ                                   | アセットプロキシサーバーのURL。変更を適用するにはGitLabの再起動が必要です。 |
| `asset_proxy_whitelist`                  | 文字列または文字列の配列 | いいえ                         | (非推奨: `asset_proxy_allowlist`を使用してください) これらのドメインに一致するアセットはプロキシされません。ワイルドカードが許可されます。あなたのGitLabインストールURLは自動的に許可リストに追加されます。変更を適用するにはGitLabの再起動が必要です。 |
| `asset_proxy_allowlist`                  | 文字列または文字列の配列 | いいえ                         | これらのドメインに一致するアセットはプロキシされません。ワイルドカードが許可されます。あなたのGitLabインストールURLは自動的に許可リストに追加されます。変更を適用するにはGitLabの再起動が必要です。 |
| `authn_data_retention_cleanup_enabled`   | ブール値          | いいえ                                   | `true`の場合、1年より古い認証ログイン履歴と1か月より古い、以前に失効されたOAuthアクセストークンおよび付与を完全に削除するクリーンアップワーカーが実行されます。デフォルト値: `false`。GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/579002)されました。 |
| `authorized_keys_enabled`                | ブール値          | いいえ                                   | デフォルトでは、`authorized_keys`ファイルは追加の設定なしでSSH経由のGitをサポートします。GitLabは、SSHキーをデータベースファイルを介して認証するように最適化できます。このオプションは、OpenSSHサーバーをAuthorizedKeysCommandを使用するように設定している場合にのみ無効にしてください。 |
| `auto_devops_domain`                     | 文字列           | いいえ                                   | すべてのプロジェクトのAuto Review AppsおよびAuto Deployステージでデフォルトで使用するドメインを指定します。 |
| `auto_devops_enabled`                    | ブール値          | いいえ                                   | デフォルトでプロジェクトのAuto DevOpsを有効にします。事前定義されたCI/CD設定に基づいて、アプリケーションを自動的にビルド、テスト、およびデプロイします。 |
| `autocomplete_users`                     | 整数          | いいえ                                   | `GET /autocomplete/users`エンドポイントへの1分あたりの最大認証済みリクエスト数。 |
| `autocomplete_users_unauthenticated`     | 整数          | いいえ                                   | `GET /autocomplete/users`エンドポイントへの1分あたりの最大未認証リクエスト数。 |
| `automatic_purchased_storage_allocation` | ブール値          | いいえ                                   | これを有効にすると、購入したストレージのネームスペースでの自動割り当てが許可されます。EEディストリビューションにのみ関連します。 |
| `bulk_import_enabled`                    | ブール値          | いいえ                                   | ダイレクト転送によるGitLabグループの移行を有効にします。設定は[管理者](../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)エリアでも**管理者**です。 |
| `bulk_import_max_download_file_size`     | 整数          | いいえ                                   | ダイレクト転送でソースGitLabインスタンスからインポートする場合の最大ダウンロードファイルサイズ。GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)されました。 |
| `allow_bypass_placeholder_confirmation`  | ブール値          | いいえ                                   | 管理者がプレースホルダーユーザーを再割り当てする際の確認をスキップします。GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/534330)されました。 |
| `allow_s3_compatible_storage_for_offline_transfer` | ブール値 | いいえ                                   | オフライン転送にS3互換のオブジェクトストレージを許可します。GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/579705)されました。 |
| `built_in_project_templates_enabled`     | ブール値          | いいえ                                   | ユーザーがプロジェクトを作成する際に、組み込みプロジェクトテンプレートを有効にします。PremiumおよびUltimateのみです。GitLab 19.0で`use_built_in_project_templates_enabled`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235284)されました。デフォルトでは無効になっています。 |
| `lock_built_in_project_templates_enabled` | ブール値         | いいえ                                   | すべてのグループに`built_in_project_templates_enabled`設定を適用します。PremiumおよびUltimateのみです。GitLab 19.0で`use_built_in_project_templates_enabled`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235284)されました。デフォルトでは無効になっています。 |
| `can_create_group`                       | ブール値          | いいえ                                   | ユーザーがトップレベルグループを作成できるかどうかを示します。`true`がデフォルトです。 |
| `check_namespace_plan`                   | ブール値          | いいえ                                   | これを有効にすると、プロジェクトのネームスペースのプランに機能が含まれている場合、またはプロジェクトが公開されている場合にのみ、ライセンスされたEE機能がプロジェクトで利用可能になります。PremiumおよびUltimateのみです。 |
| `ci_delete_pipelines_in_seconds_limit_human_readable` | 文字列 | いいえ                                | パイプライン保持を設定するために許可される最大値。`1 year`がデフォルトです。 |
| `ci_job_live_trace_enabled`              | ブール値          | いいえ                                   | ジョブログの増分ロギングを有効にします。有効にすると、アーカイブされたジョブログはオブジェクトストレージに増分アップロードされます。オブジェクトストレージを設定する必要があります。この設定は、[**管理者**エリア](../administration/settings/continuous_integration.md#access-job-log-settings)でも設定できます。 |
| `git_push_pipeline_limit`                | 整数          | いいえ                                   | 1回のGitプッシュによってトリガーできるタグパイプラインまたはブランチパイプラインの最大数を設定します。この制限の詳細については、[Gitプッシュごとのパイプライン数](../administration/cicd/limits.md#number-of-pipelines-per-git-push)を参照してください。 |
| `ci_max_total_yaml_size_bytes`           | 整数          | いいえ                                   | 含まれるすべてのYAML設定ファイルを含むパイプライン設定に割り当てることができる最大メモリ量（バイト単位）。 |
| `ci_max_includes`                        | 整数          | いいえ                                   | パイプラインごとの[最大インクルード数](../administration/cicd/limits.md#maximum-number-of-includes)。デフォルトは`150`です。 |
| `ci_partitions_size_limit`               | 整数          | いいえ                                   | 新しいパーティションを作成する前に、CIテーブルのデータベースパーティションが使用できる最大ディスク容量（バイト単位）。デフォルトは`100 GB`です。GitLab 18.11で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/429675)されました。|
| `ci_partitions_in_seconds_limit_human_readable` | 文字列    | いいえ                                   | 新しいCIパーティションが作成され、システムが次のパーティションセットに切り替わるまでの時間枠。`1 month`から`6 months`の間である必要があります。`1 month`がデフォルトです。 |
| `ci_partitions_in_seconds_limit`         | 整数          | いいえ                                   | 新しいCIパーティションが作成され、システムが次のパーティションセットに切り替わるまでの時間枠（秒単位）。1ヶ月から6ヶ月の間である必要があります。デフォルトは1ヶ月（`2592000`）です。書き込み専用。GET応答では返されません。`ci_partitions_in_seconds_limit_human_readable`のために非推奨となり、API v5で削除される予定です。 |
| `concurrent_github_import_jobs_limit`    | 整数          | いいえ                                   | GitHubインポーターの同時インポートジョブの最大数。デフォルトは1000です。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)されました。 |
| `concurrent_bitbucket_import_jobs_limit` | 整数          | いいえ                                   | Bitbucket Cloudインポーターの同時インポートジョブの最大数。デフォルトは100です。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)されました。 |
| `concurrent_bitbucket_server_import_jobs_limit` | 整数   | いいえ                                   | Bitbucket Serverインポーターの同時インポートジョブの最大数。デフォルトは100です。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)されました。 |
| `commit_email_hostname`                  | 文字列           | いいえ                                   | プライベートなコミットメール用のカスタムホスト名。 |
| `container_expiration_policies_enable_historic_entries`   | ブール値 | いいえ                           | すべてのプロジェクトで[クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#enable-the-cleanup-policy)を有効にします。 |
| `container_registry_cleanup_tags_service_max_list_size`   | 整数 | いいえ                           | [クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)の1回の実行で削除できるタグの最大数。 |
| `container_registry_delete_tags_service_timeout`          | 整数 | いいえ                           | [クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)のタグのバッチを削除するのにかかる最大時間（秒単位）。 |
| `container_registry_expiration_policies_caching`          | ブール値 | いいえ                           | [クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)の実行中のキャッシュ。 |
| `container_registry_expiration_policies_worker_capacity`  | 整数 | いいえ                           | [クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)のワーカー数。 |
| `container_registry_token_expire_delay`                   | 整数 | いいえ                           | コンテナレジストリトークンの期間（分単位）。 |
| `package_registry_cleanup_policies_worker_capacity`       | 整数 | いいえ                           | パッケージクリーンアップポリシーに割り当てられたワーカーの数。 |
| `updating_name_disabled_for_users`       | ブール値          | いいえ                                   | [ユーザープロファイル名の変更を無効にする](../administration/settings/account_and_limit_settings.md#disable-user-profile-name-changes)。 |
| `allow_account_deletion`                 | ブール値          | いいえ                                   | [ユーザーがアカウントを削除](../administration/settings/account_and_limit_settings.md#prevent-users-from-deleting-their-accounts)できるようにします。 |
| `deactivate_dormant_users`               | ブール値          | いいえ                                   | [休眠ユーザーの自動非アクティブ化](../administration/moderate_users.md#automatically-deactivate-dormant-users)を有効にします。 |
| `deactivate_dormant_users_period`        | 整数          | いいえ                                   | ユーザーが休眠と見なされるまでの期間（日数）。 |
| `decompress_archive_file_timeout`        | 整数          | いいえ                                   | アーカイブファイルの解凍のデフォルトタイムアウト（秒単位）。タイムアウトを無効にするには0に設定します。GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129161)されました。 |
| `default_artifacts_expire_in`            | 文字列           | いいえ                                   | 各ジョブのアーティファクトのデフォルト有効期限を設定します。 |
| `default_branch_name`                    | 文字列           | いいえ                                   | インスタンス内のすべてのプロジェクトに対して[初期ブランチ名](../user/project/repository/branches/default.md#change-the-default-branch-name-for-new-projects-in-an-instance)を設定します。 |
| `default_branch_protection`              | 整数          | いいえ                                   | GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)になりました。代わりに`default_branch_protection_defaults`を使用してください。 |
| `default_branch_protection_defaults`     | ハッシュ             | いいえ                                   | GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)されました。利用可能なオプションについては、[`default_branch_protection_defaults`のオプション](groups.md#options-for-default_branch_protection_defaults)を参照してください。 |
| `default_ci_config_path`                 | 文字列           | いいえ                                   | 新しいプロジェクトのデフォルトCI/CD設定ファイルとパス（設定されていない場合は`.gitlab-ci.yml`）。 |
| `default_group_visibility`               | 文字列           | いいえ                                   | 新しいグループが受け取る表示レベル。`private`、`internal`、および`public`をパラメータとして受け取ることができます。デフォルトは`private`です。GitLab 16.4で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203)されました: `restricted_visibility_levels`のどのレベルにも設定不可能です。|
| `default_preferred_language`             | 文字列           | いいえ                                   | ログインしていないユーザー向けのデフォルトの推奨言語。 |
| `default_project_creation`               | 整数          | いいえ                                   | プロジェクトを作成するために必要なデフォルトの最小ロール。以下を受け取ることができます: `0` _(誰でもない)_、`1` _(メンテナー)_、`2` _(デベロッパー)_、`3` _(管理者)_、または`4` _(オーナー)_。 |
| `default_project_visibility`             | 文字列           | いいえ                                   | 新しいプロジェクトが受け取る表示レベル。`private`、`internal`、および`public`をパラメータとして受け取ることができます。デフォルトは`private`です。GitLab 16.4で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203)されました: `restricted_visibility_levels`のどのレベルにも設定不可能です。|
| `default_projects_limit`                 | 整数          | いいえ                                   | ユーザーあたりのプロジェクト制限。デフォルトは`100000`です。 |
| `default_snippet_visibility`             | 文字列           | いいえ                                   | 新しいスニペットが受け取る表示レベル。`private`、`internal`、および`public`をパラメータとして受け取ることができます。デフォルトは`private`です。 |
| `default_syntax_highlighting_theme`      | 整数          | いいえ                                   | 新規ユーザーまたは未ログインユーザー向けのデフォルト構文ハイライトテーマ。[利用可能なテーマのID](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16)を参照してください。 |
| `default_dark_syntax_highlighting_theme` | 整数          | いいえ                                   | 新規ユーザーまたは未ログインユーザー向けのデフォルトダークモード構文ハイライトテーマ。[利用可能なテーマのID](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16)を参照してください。 |
| `default_project_deletion_protection`    | ブール値          | いいえ                                   | デフォルトプロジェクト削除保護を有効にして、管理者のみがプロジェクトを削除できるようにします。デフォルトは`false`です。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `delete_unconfirmed_users`               | ブール値          | いいえ                                   | メールアドレスを確認していないユーザーを削除すべきかどうかを指定します。デフォルトは`false`です。`true`に設定すると、未確認のユーザーは`unconfirmed_users_delete_after_days`日後に削除されます。GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352514)されました。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `deletion_adjourned_period`              | 整数          | いいえ                                   | 削除対象としてマークされたプロジェクトまたはグループを削除するまでに待機する日数。値は`1`から`90`の間である必要があります。`30`がデフォルトです。 |
| `dependency_management_settings`         | ハッシュ             | いいえ                                   | 依存関係管理設定。Sidekiqフリート全体で同時に実行されるセキュリティ更新スケジューラジョブの数を制限するには、`security_update_scheduler_max_concurrency` (整数) を設定します。デフォルトは`30`です。`200`に制限されています。`0`に設定すると、スケジュールを一時停止します。Ultimateのみ。GitLab 19.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239173)されました。 |
| `description_and_note_max_size`          | 整数          | いいえ                                   | 作業アイテム、マージリクエスト、および脆弱性の説明とコメントの内容の最大サイズ（バイト単位）。デフォルトは`1048576`です。 |
| `diagramsnet_enabled`                    | ブール値          | いいえ                                   | (有効な場合、`diagramsnet_url`が必要) [Diagrams.netインテグレーション](../administration/integration/diagrams_net.md)を有効にします。デフォルトは`true`です。 |
| `diagramsnet_url`                        | 文字列           | `diagramsnet_enabled`で必要   | インテグレーション用のDiagrams.netインスタンスURL。 |
| `diff_max_patch_bytes`                   | 整数          | いいえ                                   | 最大[差分パッチサイズ](../administration/diff_limits.md)（バイト単位）。 |
| `diff_max_files`                         | 整数          | いいえ                                   | 最大[差分内のファイル数](../administration/diff_limits.md)。 |
| `diff_max_lines`                         | 整数          | いいえ                                   | 最大[差分内の行数](../administration/diff_limits.md)。 |
| `diff_max_versions`                      | 整数          | いいえ                                   | マージリクエストごとの[差分バージョン](../administration/diff_limits.md)の最大数。 |
| `diff_max_commits`                       | 整数          | いいえ                                   | マージリクエストごとの[差分コミット](../administration/diff_limits.md)の最大数。 |
| `disable_admin_oauth_scopes`             | ブール値          | いいえ                                   | 管理者が`api`、`read_api`、`read_repository`、`write_repository`、`read_registry`、`write_registry`、または`sudo`のスコープを持つ信頼されていないOAuth 2.0アプリケーションにGitLabアカウントを接続するのを停止します。 |
| `disable_feed_token`                     | ブール値          | いいえ                                   | RSS/Atomおよびカレンダーフィードトークンの表示を無効にします。 |
| `disable_personal_access_tokens`         | ブール値          | いいえ                                   | パーソナルアクセストークンを無効にします。GitLab Self-Managed、Premium、およびUltimateのみです。APIを通じて無効にされたパーソナルアクセストークンを有効にする方法はありません。これは[既知のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/399233)です。利用可能な回避策の詳細については、[回避策](https://gitlab.com/gitlab-org/gitlab/-/issues/399233#workaround)を参照してください。     |
| `disabled_oauth_sign_in_sources`         | 文字列の配列 | いいえ                                   | 無効化されたOAuthサインイン元。 |
| `disable_password_authentication_for_users_with_sso_identities` | ブール値 | いいえ                     | SSO IDを持つユーザーのウェブインターフェースでのパスワード認証を無効にします。これはGit操作には影響しません。デフォルトは`false`です。 |
| `dns_rebinding_protection_enabled`       | ブール値          | いいえ                                   | DNSリバインディング攻撃保護を強制します。 |
| `domain_denylist_enabled`                | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `domain_denylist`) 特定のドメインからのメールを持つ新規ユーザーアカウントをブロックすることを許可します。 |
| `domain_denylist`                        | 文字列の配列 | いいえ                                   | これらのドメインに一致するメールアドレスを持つユーザーは**サインアップできません**。ワイルドカードが許可されます。複数のエントリを改行で入力してください。例: `domain.com`、`*.domain.com`。 |
| `domain_allowlist`                       | 文字列の配列 | いいえ                                   | アカウント作成時にユーザーに会社のメールのみを使用することを強制します。デフォルトは`null`であり、制限がないことを意味します。 |
| `downstream_pipeline_trigger_limit_per_project_user_sha` | 整数 | いいえ                            | [ダウンストリームパイプライントリガーレートの最大値](../administration/cicd/limits.md#limit-downstream-pipeline-trigger-rate)。デフォルト: `0`（制限なし）。GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144077)されました。 |
| `dsa_key_restriction`                    | 整数          | いいえ                                   | アップロードされたDSAキーの最小許容ビット長。デフォルトは`0`（制限なし）です。`-1`はDSAキーを無効にします。 |
| `ecdsa_key_restriction`                  | 整数          | いいえ                                   | アップロードされたECDSAキーの最小許容曲線サイズ（ビット単位）。デフォルトは`0`（制限なし）です。`-1`はECDSAキーを無効にします。 |
| `ecdsa_sk_key_restriction`               | 整数          | いいえ                                   | アップロードされたECDSA_SKキーの最小許容曲線サイズ（ビット単位）。デフォルトは`0`（制限なし）です。`-1`はECDSA_SKキーを無効にします。 |
| `ed25519_key_restriction`                | 整数          | いいえ                                   | アップロードされたED25519キーの最小許容曲線サイズ（ビット単位）。デフォルトは`0`（制限なし）です。`-1`はED25519キーを無効にします。 |
| `ed25519_sk_key_restriction`             | 整数          | いいえ                                   | アップロードされたED25519_SKキーの最小許容曲線サイズ（ビット単位）。デフォルトは`0`（制限なし）です。`-1`はED25519_SKキーを無効にします。 |
| `eks_access_key_id`                      | 文字列           | いいえ                                   | AWS IAMアクセスキーID。 |
| `eks_account_id`                         | 文字列           | いいえ                                   | アマゾンアカウントID。 |
| `eks_integration_enabled`                | ブール値          | いいえ                                   | Amazon EKSとのインテグレーションを有効にします。 |
| `eks_secret_access_key`                  | 文字列           | いいえ                                   | AWS IAMシークレットアクセスキー。 |
| `elasticsearch_aws_access_key`           | 文字列           | いいえ                                   | AWS IAMアクセスキー。PremiumおよびUltimateのみです。 |
| `elasticsearch_aws_region`               | 文字列           | いいえ                                   | Elasticsearchドメインが設定されているAWSリージョン。PremiumおよびUltimateのみです。 |
| `elasticsearch_aws_secret_access_key`    | 文字列           | いいえ                                   | AWS IAMシークレットアクセスキー。PremiumおよびUltimateのみです。 |
| `elasticsearch_aws`                      | ブール値          | いいえ                                   | AWSがホストするElasticsearchの使用を有効にします。PremiumおよびUltimateのみです。 |
| `elasticsearch_client_adapter`           | 文字列           | いいえ                                   | Elasticsearch Rubyクライアントで使用されるFaradayアダプター。`typhoeus`がデフォルトです。使用可能な値は`typhoeus`と`net_http`です。GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/550805)されました。PremiumおよびUltimateのみです。 |
| `elasticsearch_indexed_field_length_limit` | 整数        | いいえ                                   | Elasticsearchでインデックス付けするテキストフィールドの最大サイズ。値が0は無制限を意味します。これはリポジトリおよびWikiインデックス作成には適用されません。PremiumおよびUltimateのみです。 |
| `elasticsearch_indexed_file_size_limit_kb` | 整数        | いいえ                                   | Elasticsearchによってインデックス付けされるリポジトリおよびWikiファイルの最大サイズ。PremiumおよびUltimateのみです。 |
| `elasticsearch_indexing`                   | ブール値        | いいえ                                   | 高度な検索のインデックス作成を有効にします。PremiumおよびUltimateのみです。 |
| `elasticsearch_requeue_workers`            | ブール値        | いいえ                                   | インデックス作成ワーカーの自動再キューイングを有効にします。これにより、すべてのドキュメントが処理されるまでSidekiqジョブをエンキューすることで、非コードインデックス作成のスループットが向上します。PremiumおよびUltimateのみです。 |
| `elasticsearch_limit_indexing`             | ブール値        | いいえ                                   | Elasticsearchを特定のネームスペースおよびプロジェクトにインデックス付けするように制限します。PremiumおよびUltimateのみです。 |
| `elasticsearch_max_bulk_concurrency`       | 整数        | いいえ                                   | インデックス作成操作あたりのElasticsearchバルクリクエストの最大並行処理数。これは、リポジトリのインデックス作成オペレーションにのみ適用されます。PremiumおよびUltimateのみです。 |
| `elasticsearch_max_code_indexing_concurrency` | 整数     | いいえ                                   | Elasticsearchコードインデックス作成バックグラウンドジョブの最大並行処理数。これは、リポジトリのインデックス作成オペレーションにのみ適用されます。PremiumおよびUltimateのみです。 |
| `elasticsearch_worker_number_of_shards`    | 整数        | いいえ                                   | インデックス作成ワーカーのシャード数。これにより、より多くの並列Sidekiqジョブをエンキューすることで、コード以外のインデックス作成のスループットが向上します。デフォルトは`2`です。PremiumおよびUltimateのみです。 |
| `elasticsearch_max_bulk_size_mb`           | 整数        | いいえ                                   | Elasticsearchバルクインデックス作成リクエストの最大サイズ（MB）。これは、リポジトリのインデックス作成オペレーションにのみ適用されます。PremiumおよびUltimateのみです。 |
| `elasticsearch_namespace_ids`              | 整数の配列 | いいえ                                | `elasticsearch_limit_indexing`が有効になっている場合、Elasticsearchを介してインデックス付けするネームスペース。PremiumおよびUltimateのみです。 |
| `elasticsearch_project_ids`                | 整数の配列 | いいえ                                | `elasticsearch_limit_indexing`が有効になっている場合、Elasticsearchを介してインデックス付けするプロジェクト。PremiumおよびUltimateのみです。 |
| `elasticsearch_search`                     | ブール値        | いいえ                                   | Elasticsearch検索を有効にします。PremiumおよびUltimateのみです。 |
| `elasticsearch_url`                        | 文字列または文字列の配列 | いいえ                       | Elasticsearchに接続するために使用するURL。クラスターをサポートするために、カンマ区切りのリストまたは配列を使用します（例: `http://localhost:9200, http://localhost:9201`または`["http://localhost:9200", "http://localhost:9201"]`）。PremiumおよびUltimateのみです。 |
| `elasticsearch_username`                   | 文字列         | いいえ                                   | Elasticsearchインスタンスの`username`。PremiumおよびUltimateのみです。 |
| `elasticsearch_password`                   | 文字列         | いいえ                                   | Elasticsearchインスタンスのパスワード。PremiumおよびUltimateのみです。 |
| `elasticsearch_prefix`                     | 文字列         | いいえ                                   | Elasticsearchインデックス名のカスタムプレフィックス。`gitlab`がデフォルトです。1～100文字で、小文字の英数字、ハイフン、アンダースコアのみを含める必要があり、ハイフンまたはアンダースコアで開始または終了することはできません。PremiumおよびUltimateのみです。 |
| `elasticsearch_retry_on_failure`           | 整数        | いいえ                                   | Elasticsearch検索リクエストで可能な最大再試行回数。PremiumおよびUltimateのみです。 |
| `elasticsearch_shards`                     | 整数またはオブジェクト | `elasticsearch_replicas`がオブジェクトとして定義されている場合、Yes | Elasticsearchインデックスのシャード数。すべてのインデックスを同じ値に設定するには整数を使用します。インデックスごとの値を設定するにはオブジェクトを使用します。例: `{"gitlab-production": 5, "gitlab-production-notes": 3}`。<br>オブジェクトを使用する場合、各インデックスに対して`elasticsearch_shards`と`elasticsearch_replicas`の両方を指定する必要があります。どちらかの値がインデックスに欠落している場合、そのインデックスはスキップされます。PremiumおよびUltimateのみです。 |
| `elasticsearch_replicas`                   | 整数またはオブジェクト | `elasticsearch_shards`がオブジェクトとして定義されている場合、Yes | Elasticsearchインデックスのレプリカ数。すべてのインデックスを同じ値に設定するには整数を使用します。インデックスごとの値を設定するにはオブジェクトを使用します。例: `{"gitlab-production": 1, "gitlab-production-notes": 2}`。<br>オブジェクトを使用する場合、各インデックスに対して`elasticsearch_shards`と`elasticsearch_replicas`の両方を指定する必要があります。どちらかの値がインデックスに欠落している場合、そのインデックスはスキップされます。PremiumおよびUltimateのみです。 |
| `email_additional_text`                    | 文字列         | いいえ                                   | 法律/監査/コンプライアンス上の理由で、すべてのメールの最後に追記される追加テキスト。PremiumおよびUltimateのみです。 |
| `email_author_in_body`                   | ブール値          | いいえ                                   | 一部のメールサーバーはメール送信者名のオーバーライドをサポートしていません。このオプションを有効にすると、イシュー、マージリクエスト、またはコメントの作成者の名前が代わりにメール本文に含まれます。 |
| `email_confirmation_setting`             | 文字列           | いいえ                                   | ユーザーがサインインする前にメールを確認する必要があるかどうかを指定します。可能な値は`off`、`soft`、および`hard`です。 |
| `email_otp_enabled`                      | ブール値          | いいえ                                   | 多要素認証方法としてEmail-basedワンタイムパスワード（OTP）を有効にします。デフォルトでは無効になっています。`require_email_verification_on_account_locked`が`true`である必要があります。 |
| `custom_http_clone_url_root`             | 文字列           | いいえ                                   | HTTP(S)用のカスタムGitクローンURLを設定します。 |
| `enabled_git_access_protocol`            | 文字列           | いいえ                                   | Gitアクセスで有効になっているプロトコル。許可される値は`ssh`、`http`、および両方のプロトコルを許可する`all`です。`all`値はGitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/12944)されました。 |
| `enforce_namespace_storage_limit`        | ブール値          | いいえ                                   | これを有効にすると、ネームスペースストレージ制限の適用が許可されます。 |
| `enforce_terms`                          | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `terms`) すべてのユーザーにアプリケーション利用規約を強制します。 |
| `external_auth_client_cert`              | 文字列           | いいえ                                   | (**有効な場合、次が必須**: `external_auth_client_key`) 外部認可サービスで認証するために使用する証明書。 |
| `external_auth_client_key_pass`          | 文字列           | いいえ                                   | 外部サービスで認証する際にプライベートキーで使用するパスフレーズ。これは保存時に暗号化されます。 |
| `external_auth_client_key`               | 文字列           | `external_auth_client_cert`で必要 | 外部認可サービスで認証が必要な場合の証明書のプライベートキー。これは保存時に暗号化されます。 |
| `external_authorization_service_default_label` | 文字列     | 必須:<br>`external_authorization_service_enabled` | 認可をリクエストする際に使用するデフォルトの分類ラベルで、プロジェクトに分類ラベルが指定されていない場合に使用されます。 |
| `external_authorization_service_enabled`       | ブール値    | いいえ                                   | (**有効な場合、次が必須**: `external_authorization_service_default_label`、`external_authorization_service_timeout`、および`external_authorization_service_url`) プロジェクトへのアクセスに外部認可サービスを使用することを有効にします。 |
| `external_authorization_service_timeout`       | 浮動小数点数      | 必須:<br>`external_authorization_service_enabled` | 認可リクエストが中断されるまでのタイムアウト（秒単位）。リクエストがタイムアウトした場合、ユーザーへのアクセスは拒否されます（最小: 0.001、最大: 10、ステップ: 0.001）。 |
| `external_authorization_service_url`           | 文字列     | 必須:<br>`external_authorization_service_enabled` | 認可リクエストが送信されるURL。 |
| `external_pipeline_validation_service_url`     | 文字列     | いいえ                                   | パイプライン検証リクエストに使用するURL。 |
| `external_pipeline_validation_service_token`   | 文字列     | いいえ                                   | オプション。`external_pipeline_validation_service_url`のURLへのリクエストで`X-Gitlab-Token`ヘッダーとして含めるトークン。 |
| `external_pipeline_validation_service_timeout` | 整数    | いいえ                                   | パイプライン検証サービスからの応答を待機する時間。タイムアウトした場合は`OK`と見なされます。 |
| `static_objects_external_storage_url`        | 文字列       | いいえ                                   | リポジトリの静的オブジェクト用の外部ストレージへのURL。 |
| `static_objects_external_storage_auth_token` | 文字列       | `static_objects_external_storage_url`で必要 | `static_objects_external_storage_url`にリンクされた外部ストレージの認証トークン。 |
| `failed_login_attempts_unlock_period_in_minutes` | 整数  | いいえ                                   | 最大失敗サインイン試行回数に達したときにユーザーのロックが解除されるまでの期間（分単位）。 |
| `file_template_project_id`               | 整数          | いいえ                                   | カスタムファイルテンプレートの読み込み元のプロジェクトのID。PremiumおよびUltimateのみです。 |
| `first_day_of_week`                      | 整数          | いいえ                                   | カレンダービューおよび日付ピッカーの週の開始日。有効な値は、日曜日が`0`（デフォルト）、月曜日が`1`、土曜日が`6`です。 |
| `globally_allowed_ips`                   | 文字列           | いいえ                                   | 受信トラフィックに対して常に許可されるIPアドレスとCIDRのカンマ区切りリスト。例: `1.1.1.1, 2.2.2.0/24`。 |
| `geo_node_allowed_ips`                   | 文字列           | はい                                  | 許可されたセカンダリノードのIPとCIDRのカンマ区切りリスト。例: `1.1.1.1, 2.2.2.0/24`。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `geo_status_timeout`                     | 整数          | いいえ                                   | セカンダリノードの状態をリクエストするタイムアウト時間（秒単位）。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `git_two_factor_session_expiry`          | 整数          | いいえ                                   | 2FAが有効な場合のGit操作のセッションの最大期間（分単位）。PremiumおよびUltimateのみです。 |
| `gitaly_timeout_default`                 | 整数          | いいえ                                   | デフォルトGitalyタイムアウト（秒単位）。このタイムアウトはGitフェッチ/プッシュ操作またはSidekiqジョブには適用されません。タイムアウトを無効にするには`0`に設定します。 |
| `gitaly_timeout_fast`                    | 整数          | いいえ                                   | Gitaly高速操作タイムアウト（秒単位）。一部のGitaly操作は高速であると予想されます。このしきい値を超えると、ストレージシャードに問題がある可能性があり、「フェイルファスト」がGitLabインスタンスの安定性を維持するのに役立ちます。タイムアウトを無効にするには`0`に設定します。 |
| `gitaly_timeout_medium`                  | 整数          | いいえ                                   | 中程度のGitalyタイムアウト（秒単位）。これは高速とデフォルトのタイムアウトの間の値である必要があります。タイムアウトを無効にするには`0`に設定します。 |
| `gitlab_dedicated_instance`              | ブール値          | いいえ                                   | インスタンスがGitLab Dedicatedのためにプロビジョニングされたかどうかを示します。 |
| `gitlab_environment_toolkit_instance`    | ブール値          | いいえ                                   | インスタンスがService PingレポートのためにGitLab Environment Toolkitでプロビジョニングされたかどうかを示します。 |
| `gitlab_shell_operation_limit`           | 整数          | いいえ                                   | ユーザーが1分あたりに実行できるGit操作の最大数。デフォルトは`600`です。GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412088)されました。 |
| `grafana_enabled`                        | ブール値          | いいえ                                   | Grafanaを有効にします。 |
| `grafana_url`                            | 文字列           | いいえ                                   | Grafana URL。 |
| `gravatar_enabled`                       | ブール値          | いいえ                                   | Gravatarを有効にします。 |
| `group_owners_can_manage_default_branch_protection` | ブール値 | いいえ                                 | デフォルトブランチ保護のオーバーライドを防ぎます。GitLab Self-Managed、Premium、およびUltimateのみです。|
| `hashed_storage_enabled`                 | ブール値          | いいえ                                   | ハッシュベースのストレージパスを使用して新しいプロジェクトを作成します: イミュータブルなハッシュベースのパスとリポジトリ名でディスク上にリポジトリを保存することを有効にします。これにより、プロジェクトURLが変更されたときにリポジトリを移動または名前変更する必要がなくなり、ディスクI/Oパフォーマンスが向上する可能性があります。（GitLabバージョン13.0およびそれ以降で常に有効。設定は14.0で削除予定） |
| `help_page_hide_commercial_content`      | ブール値          | いいえ                                   | ヘルプからマーケティング関連のエントリを非表示にします。 |
| `help_page_support_url`                  | 文字列           | いいえ                                   | ヘルプページおよびヘルプドロップダウンリストの代替サポートURL。 |
| `help_page_documentation_base_url`       | 文字列           | いいえ                                   | 代替ドキュメントページURL。 |
| `help_page_text`                         | 文字列           | いいえ                                   | ヘルプページに表示されるカスタムテキスト。 |
| `hide_third_party_offers`                | ブール値          | いいえ                                   | GitLabでサードパーティからのオファーを表示しません。 |
| `home_page_url`                          | 文字列           | いいえ                                   | ログインしていない場合にこのURLにリダイレクトします。 |
| `housekeeping_bitmaps_enabled`           | ブール値          | いいえ                                   | 非推奨。Gitパックファイルビットマップの作成は常に有効であり、APIおよびUIを介して変更することはできません。常に`true`を返します。 |
| `housekeeping_enabled`                   | ブール値          | いいえ                                   | Gitハウスキーピングを有効または無効にします。追加のフィールドを設定する必要があります。 |
| `housekeeping_full_repack_period`        | 整数          | いいえ                                   | 非推奨。増分`git repack`が実行されるまでのGitプッシュ数。代わりに`housekeeping_optimize_repository_period`を使用してください。 |
| `housekeeping_gc_period`                 | 整数          | いいえ                                   | 非推奨。`git gc`が実行されるまでのGitプッシュ数。代わりに`housekeeping_optimize_repository_period`を使用してください。 |
| `housekeeping_incremental_repack_period` | 整数          | いいえ                                   | 非推奨。増分`git repack`が実行されるまでのGitプッシュ数。代わりに`housekeeping_optimize_repository_period`を使用してください。 |
| `housekeeping_optimize_repository_period`| 整数          | いいえ                                   | 増分`git repack`が実行されるまでのGitプッシュ数。 |
| `html_emails_enabled`                    | ブール値          | いいえ                                   | HTMLメールを有効にします。 |
| `import_sources`                         | 文字列の配列 | いいえ                                   | プロジェクトからのインポートを許可するソース。可能な値は、`github`、`bitbucket`、`bitbucket_server`、`fogbugz`、`git`、`gitlab_project`、`gitea`、および`manifest`です。 |
| `invisible_captcha_enabled`              | ブール値          | いいえ                                   | アカウント作成時に不可視CAPTCHAスパム検出を有効にします。デフォルトでは無効になっています。 |
| `issues_create_limit`                    | 整数          | いいえ                                   | ユーザーあたりの1分あたりのイシュー作成リクエストの最大数。デフォルトでは無効になっています。|
| `jira_connect_application_key`           | 文字列           | いいえ                                   | GitLab for Jira Cloudアプリで認証するために使用されるOAuthアプリケーションのID。 |
| `jira_connect_public_key_storage_enabled` | ブール値         | いいえ                                   | GitLab for Jira Cloudアプリの公開キーストレージを有効にします。 |
| `jira_connect_proxy_url`                 | 文字列           | いいえ                                   | GitLab for Jira Cloudアプリのプロキシとして使用されるGitLabインスタンスのURL。 |
| `keep_latest_artifact`                   | ブール値          | いいえ                                   | 有効期限にかかわらず、最も最近成功したジョブのアーティファクトの削除を防ぎます。デフォルトでは有効になっています。 |
| `local_markdown_version`                 | 整数          | いいえ                                   | キャッシュされたMarkdownを無効にする必要がある場合に、この値を増やします。 |
| `lock_memberships_to_saml`               | ブール値          | いいえ                                   | [SAMLグループメンバーシップのグローバルロック](../user/group/saml_sso/group_sync.md#global-saml-group-memberships-lock)を強制します。 |
| `mailgun_signing_key`                    | 文字列           | いいえ                                   | Webhookからイベントを受信するためのMailgun HTTP Webhook署名キー。 |
| `mailgun_events_enabled`                 | ブール値          | いいえ                                   | Mailgunイベントレシーバーを有効にします。 |
| `maintenance_mode_message`               | 文字列           | いいえ                                   | インスタンスがメンテナンスモードの場合に表示されるメッセージ。PremiumおよびUltimateのみです。 |
| `maintenance_mode`                       | ブール値          | いいえ                                   | インスタンスがメンテナンスモードの場合、非管理者ユーザーは読み取り専用アクセスでサインインし、読み取り専用APIリクエストを行うことができます。PremiumおよびUltimateのみです。 |
| `max_artifacts_size`                     | 整数          | いいえ                                   | 最大アーティファクトサイズ（MB）。 |
| `max_attachment_size`                    | 整数          | いいえ                                   | 添付ファイルサイズをMBで制限します。 |
| `max_decompressed_archive_size`          | 整数          | いいえ                                   | インポートされたアーカイブの最大解凍されたファイルサイズ（MB）。無制限にするには`0`に設定します。デフォルトは`25600`です。 |
| `max_export_size`                        | 整数          | いいえ                                   | 最大エクスポートサイズ（MB）。0は無制限です。デフォルト = 0 (無制限)。 |
| `max_github_response_size_limit`         | 整数          | いいえ                                   | GitHub API応答の最大許容サイズ（MB）。0は無制限です。 |
| `max_github_response_json_value_count`   | 整数          | いいえ                                   | GitHub API応答の最大許容値数。0は無制限です。応答における`:`、`,`、`{`、および`[`の出現回数に基づく推定値です。 |
| `max_http_decompressed_size`             | 整数          | いいえ                                   | 解凍後の送信リクエストからのGzip圧縮HTTP応答の最大許容サイズ（MiB）。0は無制限です。 |
| `max_http_response_json_depth`           | 整数          | いいえ                                   | 送信リクエストからのJSON HTTP応答の最大許容ネスト深度。 |
| `max_http_response_json_structural_chars` | 整数         | いいえ                                   | 送信リクエストからのJSON HTTP応答の最大許容オブジェクト数。応答における`:`、`,`、`{`、および`[`の出現回数に基づく推定値です。GitLab 18.4で導入されました。 |
| `max_http_response_xml_structural_chars` | 整数          | いいえ                                   | 送信リクエストからのXML HTTP応答の最大許容オブジェクト数。応答における`<`、および`=`の出現回数に基づく推定値です。GitLab 18.4で導入されました。 |
| `max_http_response_csv_structural_chars` | 整数          | いいえ                                   | 送信リクエストからのCSV HTTP応答の最大許容オブジェクト数。応答における`,`、`;`、`\t`、および`\n`の出現回数に基づく推定値です。GitLab 18.4で導入されました。 |
| `max_http_response_size_limit`           | 整数          | いいえ                                   | 送信リクエストからのHTTP応答の最大許容サイズ（MiB）。0は無制限です。インテグレーション、インポーター、およびWebhookに適用されます。GitLab 18.4で導入されました。 |
| `max_import_size`                        | 整数          | いいえ                                   | 最大インポートサイズ（MB）。0は無制限です。デフォルト = 0 (無制限)。 |
| `max_import_remote_file_size`            | 整数          | いいえ                                   | 外部オブジェクトストレージからのインポートに対するリモートファイルの最大サイズ。GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)されました。 |
| `max_login_attempts`                     | 整数          | いいえ                                   | ユーザーをロックアウトするまでのサインイン試行の最大数。 |
| `max_pages_size`                         | 整数          | いいえ                                   | ページリポジトリの最大サイズ（MB）。 |
| `max_personal_access_token_lifetime`     | 整数          | いいえ                                   | アクセストークンの最大許容ライフタイム（日数）。空白のままにした場合、デフォルト値の365が適用されます。設定した場合、値は365以下である必要があります。変更された場合、最大許容ライフタイムを超える有効期限を持つ既存のアクセストークンは失効されます。GitLab Self-Managed、Ultimateのみ。GitLab 17.6またはそれ以降では、`buffered_token_expiration_limit`という名前の[フィーチャーフラグ](../administration/feature_flags/_index.md)を有効にすることで、最大ライフタイム制限を[400日](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)に延長できます。|
| `max_ssh_key_lifetime`                   | 整数          | いいえ                                   | SSHキーの最大許容ライフタイム（日数）。GitLab Self-Managed、Ultimateのみ。GitLab 17.6またはそれ以降では、`buffered_token_expiration_limit`という名前の[フィーチャーフラグ](../administration/feature_flags/_index.md)を有効にすることで、最大ライフタイム制限を[400日](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)に延長できます。|
| `max_terraform_state_size_bytes`         | 整数          | いいえ                                   | [Terraformステートファイル](../administration/terraform_state.md)の最大サイズ（バイト単位）。無制限のファイルサイズにするには、これを0に設定します。 |
| `metrics_method_call_threshold`          | 整数          | いいえ                                   | メソッド呼び出しは、指定されたミリ秒数よりも長くかかった場合にのみ追跡されます。 |
| `max_number_of_repository_downloads`     | 整数          | いいえ                                   | ユーザーがBANされるまでに、指定された期間内にダウンロードできるユニークなリポジトリの最大数。デフォルト: 0、最大値は10,000リポジトリ。GitLab Self-Managed、Ultimateのみ。 |
| `max_number_of_repository_downloads_within_time_period` | 整数 | いいえ                             | レポート期間（秒単位）。デフォルト: 0、最大値は864000秒（10日）。GitLab Self-Managed、Ultimateのみ。 |
| `max_yaml_depth`                         | 整数          | いいえ                                   | [`include`キーワード](../ci/yaml/_index.md#include)で追加されたネストされたCI/CD設定の最大深度。デフォルトは`100`です。 |
| `max_yaml_size_bytes`                    | 整数          | いいえ                                   | 単一のCI/CD設定ファイルの最大サイズ（バイト単位）。デフォルトは`2097152`です。 |
| `git_rate_limit_users_allowlist`         | 文字列の配列  | いいえ                                  | Git不正利用レート制限から除外されるユーザー名のリスト。デフォルトは`[]`、最大値は100個のユーザー名です。GitLab Self-Managed、Ultimateのみ。 |
| `git_rate_limit_users_alertlist`         | 整数の配列 | いいえ                                  | Git不正利用レート制限を超過したときにメールが送信されるユーザーIDのリスト。デフォルトは`[]`、最大値は100個のユーザーIDです。GitLab Self-Managed、Ultimateのみ。 |
| `auto_ban_user_on_excessive_projects_download` | ブール値    | いいえ                                   | 有効にすると、ユーザーが`max_number_of_repository_downloads`および`max_number_of_repository_downloads_within_time_period`で指定された期間内に最大数のユニークなプロジェクトをダウンロードした場合、アプリケーションから自動的にBANされます。GitLab Self-Managed、Ultimateのみ。 |
| `mirror_available`                       | ブール値          | いいえ                                   | プロジェクトのメンテナーによってリポジトリのミラーリングを設定することを許可します。無効になっている場合、管理者のみがリポジトリのミラーリングを設定できます。 |
| `mirror_capacity_threshold`              | 整数          | いいえ                                   | より多くのミラーを事前にスケジューリングする前に利用可能であるべき最小容量。PremiumおよびUltimateのみです。 |
| `mirror_max_capacity`                    | 整数          | いいえ                                   | 同時に同期できるミラーの最大数。PremiumおよびUltimateのみです。 |
| `mirror_max_delay`                       | 整数          | いいえ                                   | 同期が予定されている場合にミラーが持つことができる更新間の最大時間（分単位）。PremiumおよびUltimateのみです。 |
| `maven_package_requests_forwarding`      | ブール値          | いいえ                                   | Maven用のGitLabパッケージレジストリでパッケージが見つからない場合、repo.maven.apache.orgをデフォルトリモートリポジトリとして使用します。PremiumおよびUltimateのみです。 |
| `npm_package_requests_forwarding`        | ブール値          | いいえ                                   | npm用のGitLabパッケージレジストリでパッケージが見つからない場合、npmjs.orgをデフォルトリモートリポジトリとして使用します。PremiumおよびUltimateのみです。 |
| `pypi_package_requests_forwarding`       | ブール値          | いいえ                                   | PyPI用のGitLabパッケージレジストリでパッケージが見つからない場合、pypi.orgをデフォルトリモートリポジトリとして使用します。PremiumおよびUltimateのみです。 |
| `oauth_access_token_expires_in`          | 整数          | いいえ                                   | インスタンスによって発行されるすべての新しいOAuthアクセストークンの最大ライフタイム (秒単位)。最小値: `300` (5分)。デフォルト値: `7200` (2時間)。空白または`null`の場合、デフォルト値を使用します。既存のOAuthアクセストークンには影響しません。 |
| `outbound_local_requests_whitelist`      | 文字列の配列 | いいえ                                   | Webhookおよびインテグレーションのローカルリクエストが無効になっている場合に、ローカルリクエストが許可される信頼済みドメインまたはIPアドレスのリストを定義します。現在、この属性は更新できません。詳細については、[イシュー569729](https://gitlab.com/gitlab-org/gitlab/-/issues/569729)を参照してください。 |
| `package_registry_allow_anyone_to_pull_option` | ブール値    | いいえ                                   | [パッケージレジストリからのプルを誰でも許可](../user/packages/package_registry/_index.md#allow-anyone-to-pull-from-package-registry)することを有効にし、表示および変更可能にします。 |
| `package_metadata_purl_types`            | 整数の配列 | いいえ                                  | [パッケージレジストリのメタデータを同期](../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)するリスト。利用可能な値の[リスト](https://gitlab.com/gitlab-org/gitlab/-/blob/ace16c20d5da7c4928dd03fb139692638b557fe3/app/models/concerns/enums/package_metadata.rb#L5)を参照してください。GitLab Self-Managed、Ultimateのみ。 |
| `pages_domain_verification_enabled`       | ブール値         | いいえ                                   | ユーザーにカスタムドメインの所有権を証明するよう要求します。ドメイン検証は、公開GitLabサイトにとって不可欠なセキュリティ対策です。ユーザーは、ドメインが有効になる前に、そのドメインを制御していることを実証する必要があります。 |
| `pages_unique_domain_default_enabled`    | ブール値         | いいえ                                   | 指定されたネームスペース下のサイト間のCookie共有を避けるために、ページサイトのデフォルトでユニークなドメインを有効にします。デフォルトは`true`です。 |
| `password_authentication_enabled_for_git` | ブール値         | いいえ                                   | GitLabアカウントパスワードを介したHTTP(S)経由のGitの認証を有効にします。デフォルトは`true`です。 |
| `password_authentication_enabled_for_web` | ブール値         | いいえ                                   | GitLabアカウントパスワードを介したウェブインターフェースの認証を有効にします。デフォルトは`true`です。 |
| `minimum_password_length`                | 整数          | いいえ                                   | パスワードが最小長を要求するかどうかを示します。PremiumおよびUltimateのみです。 |
| `password_number_required`               | ブール値          | いいえ                                   | パスワードが少なくとも1つの数字を要求するかどうかを示します。PremiumおよびUltimateのみです。 |
| `password_symbol_required`               | ブール値          | いいえ                                   | パスワードが少なくとも1つの記号文字を要求するかどうかを示します。PremiumおよびUltimateのみです。 |
| `password_uppercase_required`            | ブール値          | いいえ                                   | パスワードが少なくとも1つの大文字を要求するかどうかを示します。PremiumおよびUltimateのみです。 |
| `password_lowercase_required`            | ブール値          | いいえ                                   | パスワードが少なくとも1つの小文字を要求するかどうかを示します。PremiumおよびUltimateのみです。 |
| `performance_bar_allowed_group_id`       | 文字列           | いいえ                                   | (非推奨: `performance_bar_allowed_group_path`を使用してください) パフォーマンスバーを切り替えることが許可されているグループのパス。 |
| `performance_bar_allowed_group_path`     | 文字列           | いいえ                                   | パフォーマンスバーを切り替えることが許可されているグループのパス。 |
| `performance_bar_enabled`                | ブール値          | いいえ                                   | (非推奨: `performance_bar_allowed_group_path: nil`を渡してください) パフォーマンスバーの有効化を許可します。 |
| `personal_access_token_prefix`           | 文字列           | いいえ                                   | 生成されたすべてのパーソナルアクセストークンのプレフィックス。 |
| `pipeline_limit_per_project_user_sha`    | 整数          | いいえ                                   | ユーザーおよびコミットごとの1分あたりのパイプライン作成リクエストの最大数。デフォルトでは無効になっています。 |
| `pipeline_limit_per_user`                | 整数          | いいえ                                   | ユーザーごとの1分あたりのパイプライン作成リクエストの最大数。 |
| `ci_lint_limit_per_user`                 | 整数          | いいえ                                   | ユーザーごとに1分あたりのCI Lintリクエストの最大数。デフォルトでは無効になっています。 |
| `gitpod_enabled`                         | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `gitpod_url`) [Onaインテグレーション](../integration/gitpod.md)を有効にします。デフォルトは`false`です。 |
| `gitpod_url`                             | 文字列           | `gitpod_enabled`で必要        | インテグレーション用のOnaインスタンスURL。 |
| `inactive_resource_access_tokens_delete_after_days`| 整数 | いいえ                                   | 非アクティブなプロジェクトおよびグループアクセストークンの保持期間を指定します。デフォルトは`30`です。 |
| `kroki_enabled`                          | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `kroki_url`) [Krokiインテグレーション](../administration/integration/kroki.md)を有効にします。デフォルトは`false`です。 |
| `kroki_url`                              | 文字列           | `kroki_enabled`で必要         | インテグレーション用のKrokiインスタンスURL。 |
| `kroki_formats`                          | オブジェクト           | いいえ                                   | Krokiインスタンスでサポートされている追加のフォーマット。可能な値は`true`または`false`で、`bpmn`、`blockdiag`、`excalidraw`、および`mermaid`フォーマットの形式は`<format>: true`または`<format>: false`です。 |
| `kroki_diagram_proxy_enabled`            | ブール値          | いいえ                                   | [Krokiダイアグラムプロキシ](../administration/integration/diagram_proxy.md)を有効にします。デフォルトは`false`です。 |
| `plantuml_enabled`                       | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `plantuml_url`) [PlantUMLインテグレーション](../administration/integration/plantuml.md)を有効にします。デフォルトは`false`です。 |
| `plantuml_url`                           | 文字列           | `plantuml_enabled`で必要      | インテグレーション用のPlantUMLインスタンスURL。 |
| `plantuml_diagram_proxy_enabled`         | ブール値          | いいえ                                   | [PlantUMLダイアグラムプロキシ](../administration/integration/diagram_proxy.md)を有効にします。デフォルトは`false`です。 |
| `polling_interval_multiplier`            | 浮動小数点数            | いいえ                                   | ポーリングを実行するエンドポイントで使用される乗数の間隔。ポーリングを無効にするには`0`に設定します。 |
| `project_export_enabled`                 | ブール値          | いいえ                                   | プロジェクトエクスポートを有効にします。 |
| `project_jobs_api_rate_limit`            | 整数          | いいえ                                   | `/project/:id/jobs`への1分あたりの最大認証済みリクエスト数。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129319)されました。デフォルト: 600。 |
| `projects_api_rate_limit_unauthenticated` | 整数         | いいえ                                   | [すべてのプロジェクトAPIをリストアップする](projects.md#list-all-projects)ための未認証リクエストに対する、IPアドレスあたり10分あたりのリクエストの最大数。デフォルト: 400。スロットリングを無効にするには0に設定します。|
| `runner_jobs_request_api_limit`          | 整数          | いいえ                                   | `/jobs/request` RunnerジョブAPIエンドポイントへのリクエストに対する、Runnerトークンあたりの1分あたりのリクエストの最大数。デフォルト: 2000。スロットリングを無効にするには0に設定します。GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462537)されました。 |
| `runner_jobs_patch_trace_api_limit`      | 整数          | いいえ                                   | `PATCH /jobs/:id/trace` RunnerジョブAPIエンドポイントへのリクエストに対する、Runnerトークンあたりの1分あたりのリクエストの最大数。デフォルト: 2000。スロットリングを無効にするには0に設定します。GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462537)されました。 |
| `runner_jobs_endpoints_api_limit`        | 整数          | いいえ                                   | `/jobs/*`リクエストをRunnerジョブAPIエンドポイントへのリクエストに対する、ジョブトークンあたりの1分あたりのリクエストの最大数。デフォルト: 200。スロットリングを無効にするには0に設定します。GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462537)されました。 |
| `users_api_limit_following` | 整数 |    いいえ    | ユーザーまたはIPアドレスあたりの1分あたりのリクエストの最大数。デフォルト: 100。制限を無効にするには`0`に設定します。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。 |
| `users_api_limit_followers` | 整数 |    いいえ    | ユーザーまたはIPアドレスあたりの1分あたりのリクエストの最大数。デフォルト: 100。制限を無効にするには`0`に設定します。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。 |
| `users_api_limit_status`    | 整数 |    いいえ    | ユーザーまたはIPアドレスあたりの1分あたりのリクエストの最大数。デフォルト: 240。制限を無効にするには`0`に設定します。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。 |
| `users_api_limit_keys`      | 整数 |    いいえ    | ユーザーまたはIPアドレスあたりの1分あたりのリクエストの最大数。デフォルト: 120。制限を無効にするには`0`に設定します。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。 |
| `users_api_limit_key`       | 整数 |    いいえ    | ユーザーまたはIPアドレスあたりの1分あたりのリクエストの最大数。デフォルト: 120。制限を無効にするには`0`に設定します。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。 |
| `users_api_limit_gpg_keys`  | 整数 |    いいえ    | ユーザーまたはIPアドレスあたりの1分あたりのリクエストの最大数。デフォルト: 120。制限を無効にするには`0`に設定します。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。 |
| `users_api_limit_gpg_key`   | 整数 |    いいえ    | ユーザーまたはIPアドレスあたりの1分あたりのリクエストの最大数。デフォルト: 120。制限を無効にするには`0`に設定します。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。 |
| `virtual_registries_endpoints_api_limit`          | 整数          | いいえ                                   | 仮想レジストリエンドポイントへのIPアドレスあたり15秒あたりのリクエストの最大数。デフォルト: 4000。制限を無効にするには`0`に設定します。GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/521692)されました。 |
| `project_secrets_limit`                           | 整数          | いいえ                                   | シークレットマネージャーでプロジェクトごとに許可されるシークレットの最大数。デフォルト: 100。制限を無効にするには`0`に設定します。Ultimateのみ。GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219436)されました。 |
| `group_secrets_limit`                             | 整数          | いいえ                                   | シークレットマネージャーでグループごとに許可されるシークレットの最大数。デフォルト: 500。制限を無効にするには`0`に設定します。Ultimateのみ。GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219436)されました。 |
| `prometheus_metrics_enabled`             | ブール値          | いいえ                                   | Prometheusメトリクスを有効にします。 |
| `protected_ci_variables`                 | ブール値          | いいえ                                   | CI/CD変数はデフォルトで保護されています。 |
| `disable_overriding_approvers_per_merge_request` | ブール値  | いいえ                                   | プロジェクトおよびマージリクエストでの承認ルールの編集を防ぎます。 |
| `prevent_merge_requests_author_approval`         | ブール値  | いいえ                                   | マージリクエストの作成者による承認を防ぎます。 |
| `prevent_merge_requests_committers_approval`     | ブール値  | いいえ                                   | マージリクエストに対するコミッターによる承認を防ぎます。 |
| `push_event_activities_limit`            | 整数          | いいえ                                   | 単一のプッシュにおける変更（ブランチまたはタグ）の最大数。これを超えると[一括プッシュイベントが作成](../administration/settings/push_event_activities_limit.md)されます。`0`に設定してもスロットリングは無効になりません。 |
| `push_event_hooks_limit`                 | 整数          | いいえ                                   | 単一のプッシュにおける変更（ブランチまたはタグ）の最大数。これを超えるとWebhookおよびインテグレーションはトリガーされません。`0`に設定してもスロットリングは無効になりません。デフォルトは`3`です。 |
| `rate_limiting_response_text`            | 文字列           | いいえ                                   | レート制限が`throttle_*`設定を通じて有効になっている場合、レート制限を超過したときにこのプレーンテキスト応答を送信します。これが空白の場合、「後で再試行」が送信されます。 |
| `raw_blob_request_limit`                 | 整数          | いいえ                                   | 各rawパスの1分あたりのリクエストの最大数（デフォルトは`300`）。スロットリングを無効にするには`0`に設定します。|
| `raw_blob_request_limit_unauthenticated` | 整数          | いいえ                                   | プロジェクト内のすべてのrawパスを横断する1分あたりの未認証リクエストの最大数（デフォルトは`800`）。スロットリングを無効にするには`0`に設定します。|
| `search_rate_limit`                      | 整数          | いいえ                                   | 認証済みで検索を実行する際の1分あたりのリクエストの最大数。デフォルト: 30。スロットリングを無効にするには0に設定します。|
| `search_rate_limit_unauthenticated`      | 整数          | いいえ                                   | 未認証で検索を実行する際の1分あたりのリクエストの最大数。デフォルト: 10。スロットリングを無効にするには0に設定します。|
| `recaptcha_enabled`                      | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `recaptcha_private_key`および`recaptcha_site_key`) reCAPTCHAを有効にします。 |
| `login_recaptcha_protection_enabled`     | ブール値          | いいえ                                   | ログイン用のreCAPTCHAを有効にします。 |
| `recaptcha_private_key`                  | 文字列           | `recaptcha_enabled`で必要     | reCAPTCHAのプライベートキー。 |
| `recaptcha_site_key`                     | 文字列           | `recaptcha_enabled`で必要     | reCAPTCHAのサイトキー。 |
| `receptive_cluster_agents_enabled`       | ブール値          | いいえ                                   | Kubernetes用のGitLab Agent for Kubernetesの受付モードを有効にします。 |
| `receive_max_input_size`                 | 整数          | いいえ                                   | 最大プッシュサイズ（MB）。 |
| `relation_export_batch_size`             | 整数          | いいえ                                   | バッチ処理された関係をエクスポートする際の各バッチのサイズ。GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194607)されました。 |
| `remember_me_enabled`                    | ブール値          | いいえ                                   | [**ログイン情報を記憶する**設定](../administration/settings/account_and_limit_settings.md#configure-the-remember-me-option)を有効にします。GitLab 16.0で導入されました。 |
| `repository_checks_enabled`              | ブール値          | いいえ                                   | GitLabは定期的にすべてのプロジェクトおよびWikiリポジトリで`git fsck`を実行し、サイレントなディスク破損イシューを検索します。 |
| `repository_size_limit`                  | 整数          | いいえ                                   | リポジトリあたりのサイズ制限（MB）。PremiumおよびUltimateのみです。 |
| `repository_storages_weighted`           | 文字列から整数へのハッシュ | いいえ                        | `gitlab.yml`から取得した名前のハッシュから[重み](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)へのマッピング。新しいプロジェクトは、重み付きランダム選択によって選ばれたこれらのいずれかのストアに作成されます。 |
| `require_admin_approval_after_user_signup` | ブール値        | いいえ                                   | 有効にすると、登録フォームを使用してアカウントにサインアップしたユーザーはすべて**承認保留中**状態になり、管理者によって明示的に[承認](../administration/moderate_users.md)される必要があります。 |
| `require_email_verification_on_account_locked` | ブール値    | いいえ                                   | `true`の場合、不審なサインインアクティビティが検出された後、インスタンス上のすべてのユーザーが自身のIDを検証する必要があります。 |
| `require_personal_access_token_expiry`   | ブール値          | いいえ                                   | 有効にすると、ユーザーはグループアクセストークンまたはプロジェクトアクセストークン、あるいは非サービスアカウントが所有するパーソナルアクセストークンを作成する際に有効期限を設定する必要があります。 |
| `require_two_factor_authentication`      | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `two_factor_grace_period`) すべてのユーザーに2要素認証のセットアップを要求します。 |
| `resource_usage_limits`                | ハッシュ             | いいえ                                   | Sidekiqワーカーで適用されるリソース使用量制限の定義。この設定はGitLab.comでのみ利用可能です。 |
| `restricted_visibility_levels`           | 文字列の配列 | いいえ                                   | 選択されたレベルは、グループ、プロジェクト、またはスニペットに対して管理者以外のユーザーは使用できません。`private`、`internal`、および`public`をパラメータとして受け取ることができます。デフォルトは`null`であり、これは制限がないことを意味します。[GitLab 16.4で変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203): `default_project_visibility`および`default_group_visibility`に設定されているレベルは選択できません。 |
| `rsa_key_restriction`                    | 整数          | いいえ                                   | アップロードされたRSAキーの最小許容ビット長。デフォルトは`0`（制限なし）です。`-1`はRSAキーを無効にします。 |
| `session_expire_delay`                   | 整数          | いいえ                                   | セッションの継続時間（分）。変更を適用するにはGitLabの再起動が必要です。 |
| `session_expire_from_init`               | ブール値          | いいえ                                   | `true`の場合、セッションは、最後の活動後ではなく、セッション作成から数分後に期限切れになります。セッションのこのライフタイムは`session_expire_delay`によって定義されます。 |
| `security_policy_global_group_approvers_enabled` | ブール値  | いいえ                                   | マージリクエスト承認ポリシーの承認グループをグローバルに検索するか、プロジェクト階層内で検索するか。 |
| `security_approval_policies_limit`       | 整数          | いいえ                                   | セキュリティポリシープロジェクトごとのアクティブなマージリクエスト承認ポリシーの最大数。デフォルト: 5. 最大: 20 |
| `scan_execution_policies_action_limit`   | 整数          | いいえ                                   | スキャン実行ポリシーごとの`actions`の最大数。デフォルト: 0。最大: 20 |
| `scan_execution_policies_schedule_limit` | 整数          | いいえ                                   | スキャン実行ポリシーごとの`type: schedule`ルールの最大数。デフォルト: 0。最大: 20 |
| `security_txt_content`                    | 文字列          | いいえ                                   | [公開セキュリティ連絡先情報](../administration/settings/security_contact_information.md)。GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433210)されました。 |
| `security_mr_report_cache_lifetime_minutes` | 整数       | いいえ                                   | マージリクエストのセキュリティレポートをキャッシュする時間（分）（10～60）。デフォルト: 10。PremiumおよびUltimateのみです。GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223399)されました。 |
| `security_scan_stale_after_days`          | 整数          | いいえ                                   | スキャンデータをパージする前の保持日数。7日から90日の間でなければなりません。デフォルト: GitLab.comの場合は30日、セルフマネージドの場合は90日。PremiumおよびUltimateのみです。GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/222998)されました。 |
| `service_access_tokens_expiration_enforced` | ブール値       | いいえ                                   | サービスアカウントユーザーの場合、トークンの有効期限がオプションになるかどうかを示すフラグ。 |
| `shared_runners_enabled`                 | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `shared_runners_text`および`shared_runners_minutes`) 新しいプロジェクトでインスタンスRunnerを有効にします。 |
| `shared_runners_minutes`                 | 整数          | `shared_runners_enabled`で必要 | グループがインスタンスRunnerで1か月あたりに使用できる最大コンピューティング時間を設定します。PremiumおよびUltimateのみです。 |
| `shared_runners_text`                    | 文字列           | `shared_runners_enabled`で必要 | インスタンスRunnerのテキスト。 |
| `runner_token_expiration_interval`         | 整数        | いいえ                                   | 新しく登録されたインスタンスRunnerの認証トークンの有効期限（秒単位）を設定します。最小値は7200秒です。詳細については、[自動的に認証トークンをローテーションする](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens)を参照してください。 |
| `group_runner_token_expiration_interval`   | 整数        | いいえ                                   | 新しく登録されたグループRunnerの認証トークンの有効期限（秒単位）を設定します。最小値は7200秒です。詳細については、[自動的に認証トークンをローテーションする](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens)を参照してください。 |
| `project_runner_token_expiration_interval` | 整数        | いいえ                                   | 新しく登録されたプロジェクトRunnerの認証トークンの有効期限（秒単位）を設定します。最小値は7200秒です。詳細については、[自動的に認証トークンをローテーションする](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens)を参照してください。 |
| `sidekiq_job_limiter_mode`                        | 文字列  | いいえ                                   | `track`または`compress`。[Sidekiqジョブサイズ制限](../administration/settings/sidekiq_job_limits.md)の動作を設定します。デフォルト: 'compress'。 |
| `sidekiq_job_limiter_compression_threshold_bytes` | 整数 | いいえ                                   | SidekiqジョブがRedisに保存される前に圧縮されるバイト単位のしきい値。デフォルト: 100,000バイト (100 KB)。 |
| `sidekiq_job_limiter_limit_bytes`                 | 整数 | いいえ                                   | Sidekiqジョブが拒否されるバイト単位のしきい値。デフォルト: 0バイト（いずれのジョブも拒否しません）。 |
| `signin_enabled`                         | 文字列           | いいえ                                   | (非推奨: `password_authentication_enabled_for_web`を使用）Webインターフェースでパスワード認証が有効になっているかどうかを示すフラグ。 |
| `sign_in_restrictions`                   | ハッシュ             | いいえ                                   | アプリケーションのサインイン制限。 |
| `signup_enabled`                         | ブール値          | いいえ                                   | 登録を有効にします。デフォルトは`true`です。 |
| `silent_admin_exports_enabled`           | ブール値          | いいえ                                   | [サイレント管理者エクスポート](../administration/settings/import_and_export_settings.md#enable-silent-admin-exports)を有効にします。デフォルトは`false`です。 |
| `silent_mode_enabled`                    | ブール値          | いいえ                                   | [サイレントモード](../administration/silent_mode/_index.md)を有効にします。デフォルトは`false`です。 |
| `slack_app_enabled`                      | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `slack_app_id`、`slack_app_secret`、`slack_app_signing_secret`、および`slack_app_verification_token`) GitLab for Slackアプリを有効にします。 |
| `slack_app_id`                           | 文字列           | `slack_app_enabled`で必要     | GitLab for SlackアプリのクライアントID。 |
| `slack_app_secret`                       | 文字列           | `slack_app_enabled`で必要     | GitLab for Slackアプリのクライアントシークレット。アプリからのOAuthリクエストを認証するために使用されます。 |
| `slack_app_signing_secret`               | 文字列           | `slack_app_enabled`で必要     | GitLab for Slackアプリの署名シークレット。アプリからのAPIリクエストを認証するために使用されます。 |
| `slack_app_verification_token`           | 文字列           | `slack_app_enabled`で必要     | GitLab for Slackアプリの検証トークン。この認証方法はSlackによって非推奨とされており、アプリからのスラッシュコマンドを認証するためにのみ使用されます。 |
| `snippet_size_limit`                     | 整数          | いいえ                                   | スニペットコンテンツの最大サイズ（**バイト**単位）。デフォルト: 52428800バイト (50 MB)。|
| `snowplow_app_id`                        | 文字列           | いいえ                                   | Snowplowサイト名 / アプリケーションID。`gitlab`など）。 |
| `snowplow_collector_hostname`            | 文字列           | `snowplow_enabled`で必要      | Snowplowコレクターのホスト名。`snowplowprd.trx.gitlab.net`など）。 |
| `snowplow_database_collector_hostname`   | 文字列           | いいえ                                   | データベースイベント用のSnowplowコレクターのホスト名。`db-snowplow.trx.gitlab.net`など）。 |
| `snowplow_cookie_domain`                 | 文字列           | いいえ                                   | Snowplowのクッキードメイン。`.gitlab.com`など）。 |
| `snowplow_enabled`                       | ブール値          | いいえ                                   | Snowplowの追跡を有効にする。 |
| `sourcegraph_enabled`                    | ブール値          | いいえ                                   | Sourcegraphインテグレーションを有効にします。デフォルトは`false`です。**有効な場合、次が必須** `sourcegraph_url`。 |
| `sourcegraph_public_only`                | ブール値          | いいえ                                   | プライベートおよび内部プロジェクトでのSourcegraphの読み込みをブロックします。デフォルトは`true`です。 |
| `sourcegraph_url`                        | 文字列           | `sourcegraph_enabled`で必要   | SourcegraphインスタンスのインテグレーションURL。 |
| `spam_check_endpoint_enabled`            | ブール値          | いいえ                                   | 外部のSpam Check APIエンドポイントを使用したスパムチェックを有効にします。デフォルトは`false`です。 |
| `spam_check_endpoint_url`                | 文字列           | いいえ                                   | 外部SpamcheckサービスエンドポイントのURL。有効なURIスキームは`grpc`または`tls`です。`tls`を指定すると、通信が暗号化されます。|
| `spam_check_api_key`                     | 文字列           | いいえ                                   | GitLabがSpam Checkサービスエンドポイントにアクセスするために使用するAPIキー。 |
| `suggest_pipeline_enabled`               | ブール値          | いいえ                                   | パイプラインの提案バナーを有効にします。 |
| `enable_artifact_external_redirect_warning_page` | ブール値  | いいえ                                   | GitLab Pagesのユーザー生成コンテンツについて警告する外部リダイレクトページを表示します。 |
| `terminal_max_session_time`              | 整数          | いいえ                                   | WebターミナルのWebSocket接続の最大時間（秒単位）。無制限にするには`0`に設定します。 |
| `terms`                                  | text             | `enforce_terms`で必要         | (**次のパラメータで必要**: `enforce_terms`) ToSのMarkdownコンテンツ。 |
| `throttle_authenticated_api_enabled`                      | ブール値 | いいえ                                                              | (**有効な場合、次が必須**: `throttle_authenticated_api_period_in_seconds`および`throttle_authenticated_api_requests_per_period`) 認証済みAPIリクエストのレート制限を有効にします。リクエスト量（クローラーや悪意のあるボットなどからの）を減らすのに役立ちます。 |
| `throttle_authenticated_api_period_in_seconds`            | 整数 | 必須:<br>`throttle_authenticated_api_enabled`            | レート制限期間（秒単位）。 |
| `throttle_authenticated_api_requests_per_period`          | 整数 | 必須:<br>`throttle_authenticated_api_enabled`            | ユーザーごとの期間あたりの最大リクエスト数。 |
| `throttle_authenticated_git_http_enabled`             | ブール値 | 条件付き | `true`の場合、認証済みGit HTTPリクエストのレート制限を適用します。デフォルト値: `false`。 |
| `throttle_authenticated_git_http_period_in_seconds`   | 整数 | いいえ            | レート制限期間（秒単位）。`throttle_authenticated_git_http_enabled`は`true`である必要があります。デフォルト値: `3600`。 |
| `throttle_authenticated_git_http_requests_per_period` | 整数 | いいえ            | ユーザーごとの期間あたりの最大リクエスト数。`throttle_authenticated_git_http_enabled`は`true`である必要があります。デフォルト値: `3600`。 |
| `throttle_authenticated_packages_api_enabled`             | ブール値 | いいえ                                                              | (**有効な場合、次が必須**: `throttle_authenticated_packages_api_period_in_seconds`および`throttle_authenticated_packages_api_requests_per_period`) 認証済みAPIリクエストのレート制限を有効にします。リクエスト量（クローラーや悪意のあるボットなどからの）を減らすのに役立ちます。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_authenticated_packages_api_period_in_seconds`   | 整数 | 必須:<br>`throttle_authenticated_packages_api_enabled`   | レート制限期間（秒単位）。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_authenticated_packages_api_requests_per_period` | 整数 | 必須:<br>`throttle_authenticated_packages_api_enabled`   | ユーザーごとの期間あたりの最大リクエスト数。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_authenticated_web_enabled`                      | ブール値 | いいえ                                                              | (**有効な場合、次が必須**: `throttle_authenticated_web_period_in_seconds`および`throttle_authenticated_web_requests_per_period`) 認証済みWebリクエストのレート制限を有効にします。リクエスト量（クローラーや悪意のあるボットなどからの）を減らすのに役立ちます。 |
| `throttle_authenticated_web_period_in_seconds`            | 整数 | 必須:<br>`throttle_authenticated_web_enabled`            | レート制限期間（秒単位）。 |
| `throttle_authenticated_web_requests_per_period`          | 整数 | 必須:<br>`throttle_authenticated_web_enabled`            | ユーザーごとの期間あたりの最大リクエスト数。 |
| `throttle_unauthenticated_enabled`                        | ブール値 | いいえ                                                              | ([非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) \- GitLab 14.3で。代わりに`throttle_unauthenticated_web_enabled`または`throttle_unauthenticated_api_enabled`を使用してください。）(**有効な場合、次が必須**: `throttle_unauthenticated_period_in_seconds`および`throttle_unauthenticated_requests_per_period`) 認証されていないWebリクエストのレート制限を有効にします。リクエスト量（クローラーや悪意のあるボットなどからの）を減らすのに役立ちます。 |
| `throttle_unauthenticated_period_in_seconds`              | 整数 | 必須:<br>`throttle_unauthenticated_enabled`              | ([非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) \- GitLab 14.3で。代わりに`throttle_unauthenticated_web_period_in_seconds`または`throttle_unauthenticated_api_period_in_seconds`を使用してください。）レート制限期間（秒単位）。 |
| `throttle_unauthenticated_requests_per_period`            | 整数 | 必須:<br>`throttle_unauthenticated_enabled`              | ([非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) \- GitLab 14.3で。代わりに`throttle_unauthenticated_web_requests_per_period`または`throttle_unauthenticated_api_requests_per_period`を使用してください。）IPアドレスごとの期間あたりの最大リクエスト数。 |
| `throttle_unauthenticated_api_enabled`                    | ブール値 | いいえ                                                              | (**有効な場合、次が必須**: `throttle_unauthenticated_api_period_in_seconds`および`throttle_unauthenticated_api_requests_per_period`) 認証されていないAPIリクエストのレート制限を有効にします。リクエスト量（クローラーや悪意のあるボットなどからの）を減らすのに役立ちます。 |
| `throttle_unauthenticated_api_period_in_seconds`          | 整数 | 必須:<br>`throttle_unauthenticated_api_enabled`          | レート制限期間（秒単位）。 |
| `throttle_unauthenticated_api_requests_per_period`        | 整数 | 必須:<br>`throttle_unauthenticated_api_enabled`          | IPアドレスごとの期間あたりの最大リクエスト数。 |
| `throttle_unauthenticated_git_http_enabled`             | ブール値 | 条件付き | `true`の場合、認証されていないGit HTTPリクエストのレート制限を適用します。デフォルト値: `false`。 |
| `throttle_unauthenticated_git_http_period_in_seconds`   | 整数 | いいえ            | レート制限期間（秒単位）。`throttle_unauthenticated_git_http_enabled`は`true`である必要があります。デフォルト値: `3600`。 |
| `throttle_unauthenticated_git_http_requests_per_period` | 整数 | いいえ            | IPアドレスごとの期間あたりの最大リクエスト数。`throttle_unauthenticated_git_http_enabled`は`true`である必要があります。デフォルト値: `3600`。 |
| `throttle_unauthenticated_packages_api_enabled`           | ブール値 | いいえ                                                              | (**有効な場合、次が必須**: `throttle_unauthenticated_packages_api_period_in_seconds`および`throttle_unauthenticated_packages_api_requests_per_period`) 認証されていないAPIリクエストのレート制限を有効にします。リクエスト量（クローラーや悪意のあるボットなどからの）を減らすのに役立ちます。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_unauthenticated_packages_api_period_in_seconds` | 整数 | 必須:<br>`throttle_unauthenticated_packages_api_enabled` | レート制限期間（秒単位）。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_unauthenticated_packages_api_requests_per_period` | 整数 | 必須:<br>`throttle_unauthenticated_packages_api_enabled` | ユーザーごとの期間あたりの最大リクエスト数。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_unauthenticated_web_enabled`                    | ブール値 | いいえ                                                              | (**有効な場合、次が必須**: `throttle_unauthenticated_web_period_in_seconds`および`throttle_unauthenticated_web_requests_per_period`) 認証されていないWebリクエストのレート制限を有効にします。リクエスト量（クローラーや悪意のあるボットなどからの）を減らすのに役立ちます。 |
| `throttle_unauthenticated_web_period_in_seconds`          | 整数 | 必須:<br>`throttle_unauthenticated_web_enabled`          | レート制限期間（秒単位）。 |
| `throttle_unauthenticated_web_requests_per_period`        | 整数 | 必須:<br>`throttle_unauthenticated_web_enabled`          | IPアドレスごとの期間あたりの最大リクエスト数。 |
| `time_tracking_limit_to_hours`           | ブール値          | いいえ                                   | タイムトラッキング単位の表示を時間単位に制限します。デフォルトは`false`です。 |
| `top_level_group_creation_enabled`           | ブール値          | いいえ                                   | ユーザーがトップレベルグループを作成できるようにします。デフォルトは`true`です。 |
| `two_factor_grace_period`                | 整数          | `require_two_factor_authentication`で必要 | ユーザーが2要素認証の強制設定をスキップできる期間（時間単位）。 |
| `unconfirmed_users_delete_after_days`    | 整数          | いいえ                                   | アカウント作成後、メールアドレスを確認していないユーザーを削除するまでの日数を指定します。`delete_unconfirmed_users`が`true`に設定されている場合にのみ適用されます。`1`以上である必要があります。デフォルトは`7`です。GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352514)されました。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `unique_ips_limit_enabled`               | ブール値          | いいえ                                   | (**有効な場合、次が必須**: `unique_ips_limit_per_user`および`unique_ips_limit_time_window`) 複数のIPアドレスからのサインインを制限します。 |
| `unique_ips_limit_per_user`              | 整数          | `unique_ips_limit_enabled`で必要 | ユーザーごとの最大IPアドレス数。 |
| `unique_ips_limit_time_window`           | 整数          | `unique_ips_limit_enabled`で必要 | IPアドレスが制限にカウントされる秒数。 |
| `update_runner_versions_enabled`         | ブール値          | いいえ                                   | GitLab.comからGitLab Runnerのリリースバージョンデータをフェッチします。詳細については、[アップグレードが必要なRunnerを特定する](../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded)方法を参照してください。 |
| `usage_ping_enabled`                     | ブール値          | いいえ                                   | 毎週、GitLabはライセンス使用状況をGitLab, Inc.にレポートします。 |
| `gitlab_product_usage_data_enabled`      | ブール値          | いいえ                                   | 製品使用状況データ収集が有効になっているかどうかを示します。`GITLAB_PRODUCT_USAGE_DATA_ENABLED`環境変数が設定されている場合、APIは環境変数からの実効値を返します。 |
| `gitlab_product_usage_data_source`       | 文字列           | いいえ                                   | 読み取り専用になります。`gitlab_product_usage_data_enabled`設定のソースを示します。`GITLAB_PRODUCT_USAGE_DATA_ENABLED`環境変数が設定されている場合は`environment`を返し、そうでない場合は`database`を返します。 |
| `use_clickhouse_for_analytics`           | ブール値          | いいえ                                   | ClickHouseを分析レポートのデータソースとして有効にします。この設定を有効にするには、ClickHouseを設定する必要があります。PremiumおよびUltimateのみで利用可能です。 |
| `include_optional_metrics_in_service_ping`| ブール値         | いいえ                                   | Service Pingでオプションのメトリクスが有効になっているかどうか。GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141540)されました。 |
| `user_deactivation_emails_enabled`       | ブール値          | いいえ                                   | アカウント無効化時にユーザーにメールを送信します。 |
| `user_default_external`                  | ブール値          | いいえ                                   | 新規登録ユーザーはデフォルトで外部ユーザーです。 |
| `user_default_internal_regex`            | 文字列           | いいえ                                   | デフォルトの内部ユーザーを識別するためのメールアドレスの正規表現パターンを指定します。 |
| `user_defaults_to_private_profile`       | ブール値          | いいえ                                   | 新規作成されたユーザーはデフォルトでプライベートプロフィールを持ちます。`false`がデフォルトです。 |
| `user_oauth_applications`                | ブール値          | いいえ                                   | ユーザーがGitLabをOAuthプロバイダーとして使用するために、任意のアプリケーションを登録できるようにします。この設定はグループレベルのOAuthアプリケーションには影響しません。 |
| `user_show_add_ssh_key_message`          | ブール値          | いいえ                                   | `false`に設定すると、SSHキーがアップロードされていないユーザーに表示される`You won't be able to pull or push repositories via SSH until you add an SSH key to your profile`警告を無効にします。 |
| `version_check_enabled`                  | ブール値          | いいえ                                   | アップデートが利用可能な場合にGitLabに通知させます。 |
| `valid_runner_registrars`                | 文字列の配列 | いいえ                                   | GitLab Runnerを登録できるタイプのリスト。`[]`、`['group']`、`['project']`、または`['group', 'project']`のいずれかです。 |
| `vscode_extension_marketplace`           | ハッシュ             | いいえ                                   | VS Code拡張機能マーケットプレースの設定。[Web IDE](../user/project/web_ide/_index.md)および[ワークスペース](../user/workspace/_index.md)で使用されます。 |
| `whats_new_variant`                      | 文字列           | いいえ                                   | 新機能のバリアント、可能な値: `all_tiers`、`current_tier`、および`disabled`。 |
| `wiki_page_max_content_bytes`            | 整数          | いいえ                                   | Wikiページのコンテンツの最大サイズ（**バイト**単位）。デフォルト: 5242880バイト (5 MB)。最小値は1024バイトです。 |
| `bulk_import_concurrent_pipeline_batch_limit` | 整数     | いいえ                                   | 処理する同時ダイレクト転送バッチエクスポートの最大数。 |
| `concurrent_relation_batch_export_limit` | 整数          | いいえ                                   | 処理する同時バッチエクスポートジョブの最大数。GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169122)されました。 |
| `asciidoc_max_includes`                  | 整数          | いいえ                                   | いずれかのドキュメントで処理されるAsciiDocインクルードディレクティブの最大制限。デフォルト: 32。最大: 64。 |
| `duo_custom_agents_enabled`              | ブール値          | いいえ                                   | このインスタンスでカスタムエージェントが許可されているかどうかを示します。デフォルトは`true`です。GitLab Self-Managed、Premium、およびUltimateのみです。GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615)されました。 |
| `duo_custom_flows_enabled`               | ブール値          | いいえ                                   | このインスタンスでカスタムフローが許可されているかどうかを示します。デフォルトは`true`です。GitLab Self-Managed、Premium、およびUltimateのみです。GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615)されました。 |
| `duo_external_agents_enabled`            | ブール値          | いいえ                                   | このインスタンスで外部エージェントが許可されているかどうかを示します。デフォルトは`true`です。GitLab Self-Managed、Premium、およびUltimateのみです。GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615)されました。 |
| `duo_features_enabled`                   | ブール値          | いいえ                                   | このインスタンスでGitLab Duo機能が有効になっているかどうかを示します。GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931)されました。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `lock_duo_custom_agents_enabled`         | ブール値          | いいえ                                   | カスタムエージェントの有効化設定がすべてのグループに適用されるかどうかを示します。デフォルトは`false`です。GitLab Self-Managed、Premium、およびUltimateのみです。GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615)されました。 |
| `lock_duo_custom_flows_enabled`          | ブール値          | いいえ                                   | カスタムフローの有効化設定がすべてのグループに適用されるかどうかを示します。デフォルトは`false`です。GitLab Self-Managed、Premium、およびUltimateのみです。GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615)されました。 |
| `lock_duo_external_agents_enabled`       | ブール値          | いいえ                                   | 外部エージェントの有効化設定がすべてのグループに適用されるかどうかを示します。デフォルトは`false`です。GitLab Self-Managed、Premium、およびUltimateのみです。GitLab 19.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615)されました。 |
| `lock_duo_features_enabled`              | ブール値          | いいえ                                   | GitLab Duo機能で有効になっている設定がすべてのサブグループに適用されるかどうかを示します。GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931)されました。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `nuget_skip_metadata_url_validation` | ブール値     | いいえ                                   | NuGetパッケージのメタデータURL検証をスキップするかどうかを示します。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145887)されました。 |
| `helm_max_packages_count` | 整数     | いいえ                                   | チャンネルごとにリストできるHelmパッケージの最大数。1以上である必要があります。デフォルトは1000です。 |
| `require_admin_two_factor_authentication` | ブール値         | いいえ | 管理者が、インスタンス上のすべての管理者に2FAを要求することを許可します。 |
| `secret_push_protection_available` | ブール値         | いいえ | プロジェクトがシークレットプッシュ保護を有効にすることを許可します。これはシークレットプッシュ保護を有効にするものではありません。Ultimateのみ。 |
| `disable_invite_members` | ブール値         | いいえ | グループへのメンバー招待機能を無効にします。 |
| `enforce_pipl_compliance` | ブール値 | いいえ | SaaSアプリケーションでpiplコンプライアンスが強制されるかどうかを設定します。 |
| `iframe_rendering_enabled`               | ブール値          | いいえ                                   | Markdownでのiframeのレンダリングを許可します。デフォルトでは無効になっています。 |
| `iframe_rendering_allowlist`             | 文字列の配列 | いいえ                                   | Content-Security-Policyおよびサニタイズに使用される、許可されたiframe `src`ホスト[:ポート]エントリのリスト。 |
| `iframe_rendering_allowlist_raw`         | 文字列           | いいえ                                   | 許可されたiframe `src`ホスト[:ポート]エントリのrawな改行またはカンマ区切りのリスト。 |
| `usage_billing`                          | オブジェクト           | いいえ                                   | 使用量課金設定。スキーマ定義については`ee/app/validators/json_schemas/usage_billing_settings.json`を確認してください。 |

### 休止プロジェクトの設定 {#dormant-project-settings}

休止プロジェクトの削除を設定またはオフにできます。

| 属性                                | 型             | 必須                             | 説明 |
|------------------------------------------|------------------|:------------------------------------:|-------------|
| `delete_inactive_projects`               | ブール値          | いいえ                                   | [休止プロジェクトの削除](../administration/dormant_project_deletion.md)を有効にします。デフォルトは`false`です。GitLab 15.4で[機能フラグなしで運用可能になりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96803)。 |
| `inactive_projects_delete_after_months`  | 整数          | いいえ                                   | `delete_inactive_projects`が`true`の場合、休止プロジェクトを削除するまでの期間（月単位）。デフォルトは`2`です。GitLab 15.0で[運用可能になりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689)。 |
| `inactive_projects_min_size_mb`          | 整数          | いいえ                                   | `delete_inactive_projects`が`true`の場合、プロジェクトの非アクティブ状態がチェックされる最小リポジトリサイズ。デフォルトは`0`です。GitLab 15.0で[運用可能になりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689)。 |
| `inactive_projects_send_warning_email_after_months` | 整数 | いいえ                                 | `delete_inactive_projects`が`true`の場合、プロジェクトが休止状態であるため削除される予定であることをメンテナーにメールで通知するまでの期間（月単位）を設定します。デフォルトは`1`です。GitLab 15.0で[運用可能になりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689)。 |

### パッケージレジストリの設定: パッケージファイルサイズ制限 {#package-registry-settings-package-file-size-limits}

パッケージファイルサイズ制限は、アプリケーション設定APIの一部ではありません。代わりに、これらの設定は[プラン制限API](plan_limits.md)を使用してアクセスできます。

## 関連トピック {#related-topics}

- [`default_branch_protection_defaults`](groups.md#options-for-default_branch_protection_defaults)のオプション
