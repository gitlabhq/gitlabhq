---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アプリケーション設定APIを使用します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、GitLabインスタンスの[アプリケーション設定](#available-settings)を操作します。

アプリケーション設定への変更はキャッシュの影響を受け、すぐに有効にならない場合があります。デフォルトでは、GitLabはアプリケーション設定を60秒間キャッシュします。インスタンスのアプリケーション設定キャッシュを制御する方法については、[アプリケーションキャッシュ間隔](../administration/application_settings_cache.md)を参照してください。

前提要件: 

- インスタンスへの管理者アクセス権が必要です。

## 現在のアプリケーション設定の詳細を取得します {#get-details-on-current-application-settings}

{{< history >}}

- `always_perform_delayed_deletion`機能フラグがGitLab 15.11で[有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332)されました。
- `delayed_project_deletion`と`delayed_group_deletion`の属性はGitLab 16.0で削除されました。
- `in_product_marketing_emails_enabled`属性はGitLab 16.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/418137)されました。
- `repository_storages`属性はGitLab 16.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/429675)されました。
- `user_email_lookup_limit`属性はGitLab 16.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136886)されました。
- `allow_all_integrations`と`allowed_integrations`の属性がGitLab 17.6で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)されました。

{{< /history >}}

このGitLabインスタンスの現在の[アプリケーション設定](#available-settings)の詳細を取得します。

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
  "max_attachment_size" : 10,
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

[GitLab PremiumまたはGitLab Ultimate](https://about.gitlab.com/pricing/)をご利用のユーザーには、以下のパラメータも表示されます:

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
- `secret_push_protection_available`
- `virtual_registries_endpoints_api_limit`

```json
{
  "id": 1,
  "signup_enabled": true,
  "group_owners_can_manage_default_branch_protection": true,
  "file_template_project_id": 1,
  "geo_node_allowed_ips": "0.0.0.0/0, ::/0",
  "default_project_deletion_protection": false,
  "disable_personal_access_tokens": false,
  "duo_features_enabled": true,
  "lock_duo_features_enabled": false,
  "allow_all_integrations": true,
  "allowed_integrations": [],
  "virtual_registries_endpoints_api_limit": 1000,
  ...
}
```

## アプリケーション設定を更新 {#update-application-settings}

{{< history >}}

- `always_perform_delayed_deletion`機能フラグがGitLab 15.11で[有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332)されました。
- `delayed_project_deletion`と`delayed_group_deletion`の属性はGitLab 16.0で削除されました。
- `always_perform_delayed_deletion`機能フラグはGitLab 16.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120476)されました。
- `user_email_lookup_limit`属性はGitLab 16.7で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136886)されました。
- `default_branch_protection`はGitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)になりました。`default_branch_protection_defaults` を代わりに使用してください。代わりに`default_branch_protection_defaults`を使用してください。
- `throttle_unauthenticated_git_http_enabled`、`throttle_unauthenticated_git_http_period_in_seconds`、および`throttle_unauthenticated_git_http_requests_per_period`の属性がGitLab 17.0で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112)されました。
- `allow_all_integrations`と`allowed_integrations`の属性がGitLab 17.6で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)されました。
- `throttle_authenticated_git_http_enabled`、`throttle_authenticated_git_http_period_in_seconds`、および`throttle_authenticated_git_http_requests_per_period`の属性が、`git_authenticated_http_limit`という名前の[フラグ付き](../administration/feature_flags/_index.md)でGitLab 18.1で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191552)されました。デフォルトでは無効になっています。
- `git_authenticated_http_limit`機能フラグがGitLab 18.3で[有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/543768)されました。
- `git_authenticated_http_limit`機能フラグはGitLab 18.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/561577)されました。

{{< /history >}}

このGitLabインスタンスの現在の[アプリケーション設定](#available-settings)を更新します。

```plaintext
PUT /application/settings
```

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/settings?signup_enabled=false&default_project_visibility=internal"
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
  "max_attachment_size": 10,
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

[GitLab PremiumまたはGitLab Ultimate](https://about.gitlab.com/pricing/)をご利用のユーザーには、以下のパラメータも表示されます:

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

レスポンス例:

```json
  "file_template_project_id": 1,
  "geo_node_allowed_ips": "0.0.0.0/0, ::/0",
  "duo_features_enabled": true,
  "lock_duo_features_enabled": false,
  "allow_all_integrations": true,
  "allowed_integrations": [],
  "virtual_registries_endpoints_api_limit": 1000
```

## 使用可能な設定 {#available-settings}

<!--
This heading is referenced by a script: `scripts/cells/application-settings-analysis.rb`
 Any updates to this heading should be reflected for the DOC_API_SETTINGS_TABLE_REGEX variable.
 -->

{{< history >}}

- `housekeeping_full_repack_period`、`housekeeping_gc_period`、および`housekeeping_incremental_repack_period`は、GitLab 15.8で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106963)になりました。代わりに`housekeeping_optimize_repository_period`を使用してください。
- `allow_account_deletion`はGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412411)されました。
- `allow_project_creation_for_guest_and_below`はGitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134625)されました。
- `silent_admin_exports_enabled`はGitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148918)されました。
- `require_personal_access_token_expiry`はGitLab 17.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/470192)されました。
- `receptive_cluster_agents_enabled`はGitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463427)されました。
- `allow_all_integrations`と`allowed_integrations`がGitLab 17.6で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)されました。

{{< /history >}}

一般に、すべての設定はオプションです。一部の設定を有効にする場合は、他の関連設定も構成する必要がある場合があります。これらの要件は、次の表の`Required`列に記載されています。

| 属性                                | 型             | 必須                             | 説明 |
|------------------------------------------|------------------|:------------------------------------:|-------------|
| `admin_mode`                             | ブール値          | いいえ                                   | 管理タスクのために再認証することにより、管理者が管理者モードを有効にする必要があります。 |
| `admin_notification_email`               | 文字列           | いいえ                                   | 非推奨: 代わりに`abuse_notification_email`を使用してください。設定されている場合、[不正使用レポート](../administration/review_abuse_reports.md)がこのアドレスに送信されます。不正使用レポートは、常に**管理者**エリアで利用できます。 |
| `abuse_notification_email`               | 文字列           | いいえ                                   | 設定されている場合、[不正使用レポート](../administration/review_abuse_reports.md)がこのアドレスに送信されます。不正使用レポートは、常に**管理者**エリアで利用できます。 |
| `notify_on_unknown_sign_in`              | ブール値          | いいえ                                   | 不明なIPアドレスからサインインが発生した場合に通知を送信できるようにします。 |
| `after_sign_out_path`                    | 文字列           | いいえ                                   | ログアウト後にユーザーをリダイレクトする場所。 |
| `email_restrictions_enabled`             | ブール値          | いいえ                                   | メールによるサインアップの制限を有効にします。 |
| `email_restrictions`                     | 文字列           | `email_restrictions_enabled`で必要 | 登録時に使用されるメールに対してチェックされる正規表現。 |
| `after_sign_up_text`                     | 文字列           | いいえ                                   | サインアップ後にユーザーに表示されるテキスト。 |
| `akismet_api_key`                        | 文字列           | `akismet_enabled`で必要       | Akismetスパム対策のAPIキー。 |
| `akismet_enabled`                        | ブール値          | いいえ                                   | （**有効にする場合は以下が必要です**: `akismet_api_key`）Akismetスパム対策を有効または無効にします。 |
| `allow_all_integrations`                 | ブール値          | いいえ                                   | `false`の場合、インスタンスで許可されるのは`allowed_integrations`のインテグレーションのみです。Ultimateのみです。 |
| `allowed_integrations`                   | 文字列の配列 | いいえ                                   | `allow_all_integrations`が`false`の場合、インスタンスで許可されるのはこのリストのインテグレーションのみです。Ultimateのみです。 |
| `allow_account_deletion`                 | ブール値          | いいえ                                   | `true`に設定すると、ユーザーは自分のアカウントを削除できます。PremiumおよびUltimateのみです。 |
| `allow_group_owners_to_manage_ldap`      | ブール値          | いいえ                                   | `true`に設定すると、グループオーナーはLDAPを管理できます。PremiumおよびUltimateのみです。 |
| `allow_immediate_namespaces_deletion`    | ブール値           | いいえ                                   | 削除がスケジュールされているグループとプロジェクトを直ちに削除します。GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/569453)。`allow_immediate_namespaces_deletion`という名前の[機能フラグ](../administration/feature_flags/_index.md)の背後にあります。デフォルトでは無効になっています。 |
| `allow_local_requests_from_hooks_and_services` | ブール値    | いいえ                                   | 非推奨: 代わりに`allow_local_requests_from_web_hooks_and_services`を使用）Webhookおよびインテグレーションからのローカルネットワークへのリクエストを許可します。 |
| `allow_local_requests_from_system_hooks` | ブール値          | いいえ                                   | システムフックからのローカルネットワークへのリクエストを許可します。 |
| `allow_local_requests_from_web_hooks_and_services` | ブール値 | いいえ                                  | Webhookおよびインテグレーションからのローカルネットワークへのリクエストを許可します。 |
| `allow_project_creation_for_guest_and_below` | ブール値      | いいえ                                   | ゲストロールまでに割り当てられたユーザーが、グループと個人プロジェクトを作成できるかどうかを示します。`true`がデフォルトです。 |
| `allow_runner_registration_token`        | ブール値          | いいえ                                   | ランナーを作成するために登録トークンを使用できるようにします。`true`がデフォルトです。 |
| `archive_builds_in_human_readable`       | 文字列           | いいえ                                   | ジョブが古いとみなされ、有効期限が切れるまでの期間を設定します。その時間が経過すると、ジョブはアーカイブされ、再試行できなくなります。ジョブが期限切れにならないようにするには、値を空にしてください。1日以上にする必要があります。例: `15 days`、`1 month`、`2 years`。 |
| `asset_proxy_enabled`                    | ブール値          | いいえ                                   | （**有効にする場合は以下が必要です**: `asset_proxy_url`）アセットのプロキシ処理を有効にします。変更を適用するには、GitLabの再起動が必要です。 |
| `asset_proxy_secret_key`                 | 文字列           | いいえ                                   | アセットプロキシサーバーとの共有シークレット。変更を適用するには、GitLabの再起動が必要です。 |
| `asset_proxy_url`                        | 文字列           | いいえ                                   | アセットプロキシサーバーのURL。変更を適用するには、GitLabの再起動が必要です。 |
| `asset_proxy_whitelist`                  | 文字列、または文字列の配列 | いいえ                         | 非推奨: 代わりに`asset_proxy_allowlist`を使用）これらのドメインに一致するアセットはプロキシされ**ません**。ワイルドカードを使用できます。GitLabインストールURLは自動的に許可リストに追加されます。変更を適用するには、GitLabの再起動が必要です。 |
| `asset_proxy_allowlist`                  | 文字列、または文字列の配列 | いいえ                         | これらのドメインに一致するアセットはプロキシされ**not**（ません）。ワイルドカードを使用できます。GitLabインストールURLは自動的に許可リストに追加されます。変更を適用するには、GitLabの再起動が必要です。 |
| `authorized_keys_enabled`                | ブール値          | いいえ                                   | デフォルトでは、`authorized_keys`ファイルは追加の構成なしでSSH経由のGitをサポートします。データベースファイルを介してSSHキーを認証するようにGitLabを最適化できます。AuthorizedKeysCommandを使用するようにOpenSSHサーバーを構成している場合にのみ、これを無効にしてください。 |
| `auto_devops_domain`                     | 文字列           | いいえ                                   | すべてのプロジェクトの自動レビューアプリと自動デプロイステージでデフォルトで使用するドメインを指定します。 |
| `auto_devops_enabled`                    | ブール値          | いいえ                                   | デフォルトでプロジェクトのAuto DevOpsを有効にします。事前定義されたCI/CD構成に基づいて、アプリケーションを自動的にビルド、テスト、およびデプロイします。 |
| `autocomplete_users`                     | 整数          | いいえ                                   | `GET /autocomplete/users`エンドポイントに対する、1分あたりの認証済みリクエストの最大数。 |
| `autocomplete_users_unauthenticated`     | 整数          | いいえ                                   | `GET /autocomplete/users`エンドポイントに対する、1分あたりの認証されていないリクエストの最大数。 |
| `automatic_purchased_storage_allocation` | ブール値          | いいえ                                   | これにより、ネームスペースで購入したストレージの自動割り当てが許可されます。EEディストリビューションにのみ関連します。 |
| `bulk_import_enabled`                    | ブール値          | いいえ                                   | 直接転送によるGitLabグループの移行を有効にします。この設定は、**管理者**エリアでも[利用可能](../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)です。 |
| `bulk_import_max_download_file_size`     | 整数          | いいえ                                   | ダイレクト転送によるソースGitLabインスタンスからのインポート時の最大ダウンロードファイルサイズ。GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)されました。 |
| `allow_bypass_placeholder_confirmation`  | ブール値          | いいえ                                   | 管理者がプレースホルダユーザーを再割り当てする際に確認をスキップしますGitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/534330)されました。 |
| `can_create_group`                       | ブール値          | いいえ                                   | ユーザーがトップレベルグループを作成できるかどうかを示します。`true`がデフォルトです。 |
| `check_namespace_plan`                   | ブール値          | いいえ                                   | これにより、プロジェクトのネームスペースのプランにその機能が含まれている場合、またはプロジェクトがパブリックである場合にのみ、ライセンスされたEE機能がプロジェクトで使用できるようになります。PremiumおよびUltimateのみです。 |
| `ci_delete_pipelines_in_seconds_limit_human_readable` | 文字列 | いいえ                                | パイプラインの保持を構成するために許可される最大値。`1 year`がデフォルトです。 |
| `ci_job_live_trace_enabled`              | ブール値          | いいえ                                   | ジョブログのインクリメンタルロギングをオンにします。オンにすると、アーカイブされたジョブログがオブジェクトストレージにインクリメンタルにアップロードされます。オブジェクトストレージを構成する必要があります。この設定は、[**管理者**エリア](../administration/settings/continuous_integration.md#access-job-log-settings)でも構成できます。 |
| `git_push_pipeline_limit`                | 整数          | いいえ                                   | 1回のGitプッシュによってトリガーできるタグパイプラインまたはブランチパイプラインの最大数を設定します。この制限の詳細については、[Gitプッシュごとのパイプライン数](../administration/instance_limits.md#number-of-pipelines-per-git-push)を参照してください。 |
| `ci_max_total_yaml_size_bytes`           | 整数          | いいえ                                   | すべてのインポートされたファイルを含む、パイプラインの設定ファイルに割り当てることができるメモリの最大量（バイト単位）。 |
| `ci_max_includes`                        | 整数          | いいえ                                   | パイプラインあたりの[インクルードの最大数](../administration/settings/continuous_integration.md#set-maximum-includes)。デフォルトは`150`です。 |
| `ci_partitions_size_limit`               | 整数          | いいえ                                   | 新しいパーティションを作成する前に、データベースパーティションがCIテーブルに使用できるディスク容量の最大値（バイト単位）。デフォルトは`100 GB`です。 |
| `concurrent_github_import_jobs_limit`    | 整数          | いいえ                                   | GitHubインポーターの同時インポートジョブの最大数。デフォルトは1000です。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)されました。 |
| `concurrent_bitbucket_import_jobs_limit` | 整数          | いいえ                                   | Bitbucket Cloudインポーターの同時インポートジョブの最大数。デフォルトは100です。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)されました。 |
| `concurrent_bitbucket_server_import_jobs_limit` | 整数   | いいえ                                   | Bitbucket Serverインポーターの同時インポートジョブの最大数。デフォルトは100です。GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875)されました。 |
| `commit_email_hostname`                  | 文字列           | いいえ                                   | カスタムホスト名（プライベートコミットメール用）。 |
| `container_expiration_policies_enable_historic_entries`   | ブール値 | いいえ                           | すべてのプロジェクトに対して[クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#enable-the-cleanup-policy)を有効にします。 |
| `container_registry_cleanup_tags_service_max_list_size`   | 整数 | いいえ                           | [クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)の1回の実行で削除できるタグの最大数。 |
| `container_registry_delete_tags_service_timeout`          | 整数 | いいえ                           | [クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)のタグのバッチを削除するために、クリーンアッププロセスが実行できる最大時間 (秒)。 |
| `container_registry_expiration_policies_caching`          | ブール値 | いいえ                           | [クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)の実行中のキャッシュ。 |
| `container_registry_expiration_policies_worker_capacity`  | 整数 | いいえ                           | [クリーンアップポリシー](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources)のワーカー数。 |
| `container_registry_token_expire_delay`                   | 整数 | いいえ                           | コンテナレジストリトークンの有効期間（分単位）。 |
| `package_registry_cleanup_policies_worker_capacity`       | 整数 | いいえ                           | パッケージクリーンアップポリシーに割り当てられたワーカーの数。 |
| `updating_name_disabled_for_users`       | ブール値          | いいえ                                   | [ユーザープロファイル名の変更を無効にする](../administration/settings/account_and_limit_settings.md#disable-user-profile-name-changes)。 |
| `allow_account_deletion`                 | ブール値          | いいえ                                   | [ユーザーが自分のアカウントを削除](../administration/settings/account_and_limit_settings.md#prevent-users-from-deleting-their-accounts)できるようにします。 |
| `deactivate_dormant_users`               | ブール値          | いいえ                                   | [休眠状態のユーザーの自動非アクティブ化](../administration/moderate_users.md#automatically-deactivate-dormant-users)を有効にします。 |
| `deactivate_dormant_users_period`        | 整数          | いいえ                                   | ユーザーが休止状態と見なされるまでの期間（日数）。 |
| `decompress_archive_file_timeout`        | 整数          | いいえ                                   | アーカイブファイルの解凍のデフォルトのタイムアウト（秒単位）。タイムアウトを無効にするには、0に設定します。GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129161)されました。 |
| `default_artifacts_expire_in`            | 文字列           | いいえ                                   | 各ジョブのアーティファクトのデフォルトの有効期限を設定します。 |
| `default_branch_name`                    | 文字列           | いいえ                                   | インスタンス内のすべてのプロジェクトの[初期ブランチ名を設定](../user/project/repository/branches/default.md#change-the-default-branch-name-for-new-projects-in-an-instance)します。 |
| `default_branch_protection`              | 整数          | いいえ                                   | GitLab 17.0で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)になりました。代わりに`default_branch_protection_defaults`を使用してください。 |
| `default_branch_protection_defaults`     | ハッシュ             | いいえ                                   | GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/408314)されました。利用可能なオプションについては、[`default_branch_protection_defaults`のオプション](groups.md#options-for-default_branch_protection_defaults)を参照してください。 |
| `default_ci_config_path`                 | 文字列           | いいえ                                   | 新しいプロジェクトのデフォルトのCI/CD構成ファイルとパス（設定されていない場合は`.gitlab-ci.yml`）。 |
| `default_group_visibility`               | 文字列           | いいえ                                   | 新しいグループが受け取る表示レベル。パラメータとして`private`、`internal`、および`public`を使用できます。デフォルトは`private`です。GitLab 16.4で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203): `restricted_visibility_levels`で設定されたレベルには設定できません。|
| `default_preferred_language`             | 文字列           | いいえ                                   | ログインしていないユーザーのデフォルトの優先言語。 |
| `default_project_creation`               | 整数          | いいえ                                   | プロジェクトを作成するために必要なデフォルトの最小ロール。指定できる値: `0`_（だれも不可能）_、`1`_（メンテナー）_、`2`_（開発者）_、`3`_（管理者）_または`4`_（オーナー）_。 |
| `default_project_visibility`             | 文字列           | いいえ                                   | 新しいプロジェクトが受け取る表示レベル。パラメータとして`private`、`internal`、および`public`を使用できます。デフォルトは`private`です。GitLab 16.4で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203): `restricted_visibility_levels`で設定されたレベルには設定できません。|
| `default_projects_limit`                 | 整数          | いいえ                                   | ユーザーあたりのプロジェクト制限。デフォルトは`100000`です。 |
| `default_snippet_visibility`             | 文字列           | いいえ                                   | 新しいスニペットが受け取る表示レベル。パラメータとして`private`、`internal`、および`public`を使用できます。デフォルトは`private`です。 |
| `default_syntax_highlighting_theme`      | 整数          | いいえ                                   | 新規ユーザーまたはサインインしていないユーザーに対するデフォルトの構文ハイライトテーマ。[使用可能なテーマのID](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16)を参照してください。 |
| `default_dark_syntax_highlighting_theme` | 整数          | いいえ                                   | 新規ユーザーまたはサインインしていないユーザーに対するデフォルトのダークモード構文ハイライトテーマ。[使用可能なテーマのID](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16)を参照してください。 |
| `default_project_deletion_protection`    | ブール値          | いいえ                                   | 管理者のみがプロジェクトを削除できるように、デフォルトのプロジェクト削除保護を有効にします。デフォルトは`false`です。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `delete_unconfirmed_users`               | ブール値          | いいえ                                   | メールアドレスを確認していないユーザーを削除するかどうかを指定します。デフォルトは`false`です。`true`に設定すると、確認されていないユーザーは`unconfirmed_users_delete_after_days`日後に削除されます。GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352514)されました。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `deletion_adjourned_period`              | 整数          | いいえ                                   | 削除対象としてマークされているプロジェクトまたはグループを削除するまで待機する日数。値は`1`から`90`の間である必要があります。`30`がデフォルトです。 |
| `diagramsnet_enabled`                    | ブール値          | いいえ                                   | （有効にする場合は以下が必要です: `diagramsnet_url`）[Diagrams.net integration](../administration/integration/diagrams_net.md)を有効にします。デフォルトは`true`です。 |
| `diagramsnet_url`                        | 文字列           | `diagramsnet_enabled`で必要   | インテグレーション用のDiagrams.netインスタンスURL。 |
| `diff_max_patch_bytes`                   | 整数          | いいえ                                   | バイト単位の最大[差分パッチサイズ](../administration/diff_limits.md)。 |
| `diff_max_files`                         | 整数          | いいえ                                   | 最大[差分内のファイル数](../administration/diff_limits.md)。 |
| `diff_max_lines`                         | 整数          | いいえ                                   | 最大[差分内の行数](../administration/diff_limits.md)。 |
| `disable_admin_oauth_scopes`             | ブール値          | いいえ                                   | 管理者が、`api`、`read_api`、`read_repository`、`write_repository`、`read_registry`、`write_registry`、または`sudo`スコープを持つ、信頼されていないOAuth 2.0アプリケーションにGitLabアカウントを接続するのを停止します。 |
| `disable_feed_token`                     | ブール値          | いいえ                                   | RSS/Atomおよびカレンダーフィードトークンの表示を無効にします。 |
| `disable_personal_access_tokens`         | ブール値          | いいえ                                   | パーソナルアクセストークンを無効にする。GitLab Self-Managed、Premium、およびUltimateのみです。APIを介して無効にされたパーソナルアクセストークンを有効にするために利用できるメソッドはありません。これは既知の[問題](https://gitlab.com/gitlab-org/gitlab/-/issues/399233)です。利用可能な回避策の詳細については、[Workaround](https://gitlab.com/gitlab-org/gitlab/-/issues/399233#workaround)を参照してください。      |
| `disabled_oauth_sign_in_sources`         | 文字列の配列 | いいえ                                   | 無効になっているOAuthサインインソース。 |
| `disable_password_authentication_for_users_with_sso_identities` | ブール値 | いいえ                     | SSO IDを持つユーザーのWebインターフェースでのパスワード認証を無効にします。これはHTTP(S)経由のGit操作には影響しません。デフォルトは`false`です。 |
| `dns_rebinding_protection_enabled`       | ブール値          | いいえ                                   | DNSリバインディング攻撃保護を強制します。 |
| `domain_denylist_enabled`                | ブール値          | いいえ                                   | （**有効にする場合は以下が必要です**: `domain_denylist`）特定のドメインからのメールによるサインアップのブロックを許可します。 |
| `domain_denylist`                        | 文字列の配列 | いいえ                                   | これらのドメインに一致するメールアドレスを持つユーザーはサインアップ**不可能**。ワイルドカードを使用できます。複数のエントリを別々の行に入力します。例: `domain.com`、`*.domain.com`。 |
| `domain_allowlist`                       | 文字列の配列 | いいえ                                   | ユーザーにサインアップに企業メールのみを使用させます。デフォルトは`null`です。つまり、制限はありません。 |
| `downstream_pipeline_trigger_limit_per_project_user_sha` | 整数 | いいえ                            | [最大ダウンストリームパイプライントリガーレート](../administration/settings/continuous_integration.md#limit-downstream-pipeline-trigger-rate)。デフォルト: `0`（制限なし）。GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144077)されました。 |
| `dsa_key_restriction`                    | 整数          | いいえ                                   | アップロードされたDSAキーの最小許容ビット長。デフォルトは`0`（制限なし）。`-1`はDSAキーを無効にします。 |
| `ecdsa_key_restriction`                  | 整数          | いいえ                                   | アップロードされたECDSAキーの最小許容曲線サイズ（ビット単位）。デフォルトは`0`（制限なし）。`-1`はECDSAキーを無効にします。 |
| `ecdsa_sk_key_restriction`               | 整数          | いいえ                                   | アップロードされたECDSA_SKキーの最小許容曲線サイズ（ビット単位）。デフォルトは`0`（制限なし）。`-1`はECDSA_SKキーを無効にします。 |
| `ed25519_key_restriction`                | 整数          | いいえ                                   | アップロードされたED25519キーの最小許容曲線サイズ（ビット単位）。デフォルトは`0`（制限なし）。`-1`はED25519キーを無効にします。 |
| `ed25519_sk_key_restriction`             | 整数          | いいえ                                   | アップロードされたED25519_SKキーの最小許容曲線サイズ（ビット単位）。デフォルトは`0`（制限なし）。`-1`はED25519_SKキーを無効にします。 |
| `eks_access_key_id`                      | 文字列           | いいえ                                   | AWS IAMアクセスキーID。 |
| `eks_account_id`                         | 文字列           | いいえ                                   | AmazonアカウントID。 |
| `eks_integration_enabled`                | ブール値          | いいえ                                   | Amazon EKSとのインテグレーションを有効にします。 |
| `eks_secret_access_key`                  | 文字列           | いいえ                                   | AWS IAMシークレットアクセスキー。 |
| `elasticsearch_aws_access_key`           | 文字列           | いいえ                                   | AWS IAMアクセスキー。PremiumおよびUltimateのみです。 |
| `elasticsearch_aws_region`               | 文字列           | いいえ                                   | Elasticsearchドメインが構成されているAWSリージョン。PremiumおよびUltimateのみです。 |
| `elasticsearch_aws_secret_access_key`    | 文字列           | いいえ                                   | AWS IAMシークレットアクセスキー。PremiumおよびUltimateのみです。 |
| `elasticsearch_aws`                      | ブール値          | いいえ                                   | AWSホスト型Elasticsearchの使用を有効にします。PremiumおよびUltimateのみです。 |
| `elasticsearch_client_adapter`           | 文字列           | いいえ                                   | Elasticsearch Rubyクライアントで使用されるFaradayアダプター。デフォルトはです。指定可能な値はとです。`typhoeus`がデフォルトです。使用できる値は、`typhoeus`と`net_http`です。GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/550805)。PremiumおよびUltimateのみです。 |
| `elasticsearch_indexed_field_length_limit` | 整数        | いいえ                                   | Elasticsearchでインデックスを作成するテキストフィールドの最大サイズ。0の値は制限がないことを意味します。0の値は制限がないことを意味します。これは、リポジトリおよびWikiのインデックス作成には適用されません。PremiumおよびUltimateのみです。 |
| `elasticsearch_indexed_file_size_limit_kb` | 整数        | いいえ                                   | Elasticsearchによってインデックス作成されるリポジトリファイルとWikiファイルの最大サイズ。PremiumおよびUltimateのみです。 |
| `elasticsearch_indexing`                   | ブール値        | いいえ                                   | 高度な検索のためのインデックス作成をオンにします。PremiumおよびUltimateのみです。 |
| `elasticsearch_requeue_workers`            | ブール値        | いいえ                                   | インデックス作成ワーカーの自動再キューイングを有効にします。これにより、すべてのドキュメントが処理されるまでSidekiqジョブをエンキューすることで、非コードインデックス作成のスループットが向上します。PremiumおよびUltimateのみです。 |
| `elasticsearch_limit_indexing`             | ブール値        | いいえ                                   | 特定のネームスペースおよびプロジェクトにインデックス作成を制限するようにElasticsearchを設定します。PremiumおよびUltimateのみです。 |
| `elasticsearch_max_bulk_concurrency`       | 整数        | いいえ                                   | Elasticsearchのバルクリクエストの最大並行処理（インデックス作成操作ごと）。これは、リポジトリのインデックス作成オペレーションにのみ適用されます。PremiumおよびUltimateのみです。 |
| `elasticsearch_max_code_indexing_concurrency` | 整数     | いいえ                                   | Elasticsearchコードのインデックス作成バックグラウンドジョブの最大並行処理。これはリポジトリのインデックス作成操作にのみ適用されます。これは、リポジトリのインデックス作成オペレーションにのみ適用されます。PremiumおよびUltimateのみです。 |
| `elasticsearch_worker_number_of_shards`    | 整数        | いいえ                                   | インデックス作成ワーカーのシャード数。これにより、より多くの並列Sidekiqジョブをエンキューすることで、コード以外のインデックス作成のスループットが向上します。デフォルトは`2`です。PremiumおよびUltimateのみです。 |
| `elasticsearch_max_bulk_size_mb`           | 整数        | いいえ                                   | MB単位のElasticsearchバルクのインデックス作成リクエストの最大サイズ。これはリポジトリのインデックス作成操作にのみ適用されます。これは、リポジトリのインデックス作成オペレーションにのみ適用されます。PremiumおよびUltimateのみです。 |
| `elasticsearch_namespace_ids`              | 整数の配列 | いいえ                                | `elasticsearch_limit_indexing`が有効になっている場合にElasticsearchを介してインデックス作成するネームスペース。PremiumおよびUltimateのみです。 |
| `elasticsearch_project_ids`                | 整数の配列 | いいえ                                | `elasticsearch_limit_indexing`が有効になっている場合にElasticsearchを介してインデックス作成するプロジェクト。PremiumおよびUltimateのみです。 |
| `elasticsearch_search`                     | ブール値        | いいえ                                   | Elasticsearch検索を有効にします。PremiumおよびUltimateのみです。 |
| `elasticsearch_url`                        | 文字列         | いいえ                                   | Elasticsearchへの接続に使用するURL。コンマ区切りのリストを使用してクラスターをサポートします (例: `http://localhost:9200, http://localhost:9201"`)。PremiumおよびUltimateのみです。 |
| `elasticsearch_username`                   | 文字列         | いいえ                                   | Elasticsearchインスタンスの`username`。PremiumおよびUltimateのみです。 |
| `elasticsearch_password`                   | 文字列         | いいえ                                   | Elasticsearchインスタンスのパスワード。PremiumおよびUltimateのみです。 |
| `elasticsearch_prefix`                     | 文字列         | いいえ                                   | Elasticsearchインデックス名のカスタムプレフィックス。`gitlab`がデフォルトです。1～100文字で、小文字の英数字、ハイフン、アンダースコアのみを含める必要があり、ハイフンまたはアンダースコアで開始または終了することはできません。PremiumおよびUltimateのみです。 |
| `elasticsearch_retry_on_failure`           | 整数        | いいえ                                   | Elasticsearch検索リクエストで可能な最大再試行回数。PremiumおよびUltimateのみです。 |
| `email_additional_text`                    | 文字列         | いいえ                                   | すべてのメールの最下部に追加される、法律/監査/コンプライアンス上の理由による追加テキスト。PremiumおよびUltimateのみです。 |
| `email_author_in_body`                   | ブール値          | いいえ                                   | 一部のメールサーバーは、メール送信者の名前のオーバーライドをサポートしていません。代わりに、問題、マージリクエスト、またはコメントの作成者の名前をメール本文に含めるには、このオプションを有効にします。 |
| `email_confirmation_setting`             | 文字列           | いいえ                                   | サインインする前に、ユーザーがメールを確認する必要があるかどうかを指定します。使用できる値は、`off`、`soft`、`hard`です。 |
| `custom_http_clone_url_root`             | 文字列           | いいえ                                   | HTTP(S)のカスタムGitクローンURLを設定します。 |
| `enabled_git_access_protocol`            | 文字列           | いいえ                                   | Gitアクセスで有効になっているプロトコル。使用できる値は、`ssh`、`http`、および両方のプロトコルを許可する`all`です。`all`の値はGitLab 16.9で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/12944)。 |
| `enforce_namespace_storage_limit`        | ブール値          | いいえ                                   | これを有効にすると、ネームスペースストレージ制限の適用が許可されます。 |
| `enforce_terms`                          | ブール値          | いいえ                                   | （**有効にする場合は必須**: `terms`）すべてのユーザーにアプリケーションのToSを適用します。 |
| `external_auth_client_cert`              | 文字列           | いいえ                                   | （**有効にする場合は必須**: `external_auth_client_key`）外部認証サービスで認証するために使用する証明書。 |
| `external_auth_client_key_pass`          | 文字列           | いいえ                                   | 外部サービスで認証する際に秘密キーに使用するパスフレーズで、保存時に暗号化された状態になります。 |
| `external_auth_client_key`               | 文字列           | `external_auth_client_cert`で必要 | 外部認証サービスで認証が必要な場合に証明書に使用する秘密キーで、保存時に暗号化された状態になります。 |
| `external_authorization_service_default_label` | 文字列     | 以下で必要:<br>`external_authorization_service_enabled` | 認可を要求するときに使用するデフォルトの分類ラベルで、プロジェクトで分類ラベルが指定されていない場合に使用されます。 |
| `external_authorization_service_enabled`       | ブール値    | いいえ                                   | （**有効にする場合は必須**: `external_authorization_service_default_label`、`external_authorization_service_timeout`、`external_authorization_service_url`）プロジェクトへのアクセスに外部認可サービスを使用できるようにします。 |
| `external_authorization_service_timeout`       | 浮動小数点数      | 以下で必要:<br>`external_authorization_service_enabled` | 認可リクエストが中断されるまでのタイムアウト（秒単位）。リクエストがタイムアウトすると、ユーザーへのアクセスは拒否されます（最小: 0.001、最大: 10、ステップ: 0.001）。 |
| `external_authorization_service_url`           | 文字列     | 以下で必要:<br>`external_authorization_service_enabled` | 認可リクエストの送信先となるURL。 |
| `external_pipeline_validation_service_url`     | 文字列     | いいえ                                   | パイプラインの検証リクエストに使用するURL。 |
| `external_pipeline_validation_service_token`   | 文字列     | いいえ                                   | オプション。`external_pipeline_validation_service_url`のURLへのリクエストで、`X-Gitlab-Token`ヘッダーとして含めるトークン。 |
| `external_pipeline_validation_service_timeout` | 整数    | いいえ                                   | パイプラインの検証サービスからの応答を待機する時間。タイムアウトした場合、`OK`とみなされます。 |
| `static_objects_external_storage_url`        | 文字列       | いいえ                                   | リポジトリの静的オブジェクトの外部ストレージへのURL。 |
| `static_objects_external_storage_auth_token` | 文字列       | `static_objects_external_storage_url`で必要 | `static_objects_external_storage_url`でリンクされている外部ストレージの認証トークン。 |
| `failed_login_attempts_unlock_period_in_minutes` | 整数  | いいえ                                   | サインインの試行回数が上限に達した場合に、ユーザーのロックが解除されるまでの時間（分単位）。 |
| `file_template_project_id`               | 整数          | いいえ                                   | カスタムファイルテンプレートの読み込み元のプロジェクトのID。PremiumおよびUltimateのみです。 |
| `first_day_of_week`                      | 整数          | いいえ                                   | カレンダービューと日付ピッカーの週の開始日。有効な値は、日曜日が`0`（デフォルト）、月曜日が`1`、土曜日が`6`です。 |
| `globally_allowed_ips`                   | 文字列           | いいえ                                   | 受信トラフィックに対して常に許可されるIPアドレスとCIDRのカンマ区切りリスト。たとえば`1.1.1.1, 2.2.2.0/24`などです。 |
| `geo_node_allowed_ips`                   | 文字列           | はい                                  | 許可されているセカンダリノードのIPとCIDRのカンマ区切りリスト。たとえば`1.1.1.1, 2.2.2.0/24`などです。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `geo_status_timeout`                     | 整数          | いいえ                                   | セカンダリノードのステータスを取得するリクエストがタイムアウトになるまでの秒数。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `git_two_factor_session_expiry`          | 整数          | いいえ                                   | 2FAが有効な場合のGit操作のセッションの最大時間（分単位）。PremiumおよびUltimateのみです。 |
| `gitaly_timeout_default`                 | 整数          | いいえ                                   | デフォルトのGitalyタイムアウト（秒単位）。このタイムアウトは、Gitフェッチ/プッシュ操作またはSidekiqジョブには適用されません。タイムアウトを無効にするには、`0`に設定します。 |
| `gitaly_timeout_fast`                    | 整数          | いいえ                                   | Gitalyタイムアウト（高速操作、秒単位）。一部のGitaly操作は高速であることが期待されます。このしきい値を超えた場合、ストレージシャードに問題が発生している可能性があり、「フェイルファスト」は、GitLabインスタンスの安定性を維持するのに役立ちます。タイムアウトを無効にするには、`0`に設定します。 |
| `gitaly_timeout_medium`                  | 整数          | いいえ                                   | 中程度のGitalyタイムアウト（秒単位）。これは、高速タイムアウトとデフォルトタイムアウトの間の値である必要があります。タイムアウトを無効にするには、`0`に設定します。 |
| `gitlab_dedicated_instance`              | ブール値          | いいえ                                   | GitLab Dedicated用にプロビジョニングされたインスタンスかどうかを示します。 |
| `gitlab_environment_toolkit_instance`    | ブール値          | いいえ                                   | Service Pingのレポート用にGitLab Environment Toolkitでプロビジョニングされたインスタンスかどうかを示します。 |
| `gitlab_shell_operation_limit`           | 整数          | いいえ                                   | ユーザーが実行できる1分あたりのGit操作の最大数。デフォルトは`600`です。GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412088)されました。 |
| `grafana_enabled`                        | ブール値          | いいえ                                   | Grafanaを有効にします。 |
| `grafana_url`                            | 文字列           | いいえ                                   | GrafanaのURL。 |
| `gravatar_enabled`                       | ブール値          | いいえ                                   | Gravatarを有効にします。 |
| `group_owners_can_manage_default_branch_protection` | ブール値 | いいえ                                 | デフォルトブランチ保護のオーバーライドを防止する。GitLab Self-Managed、Premium、およびUltimateのみです。|
| `hashed_storage_enabled`                 | ブール値          | いいえ                                   | ハッシュストレージパスを使用して、新しいプロジェクトを作成します: イミュータブルなハッシュベースのパスとリポジトリ名を有効にして、ディスクにリポジトリを保存します。これにより、プロジェクトURLが変更されたときにリポジトリを移動または名前変更する必要がなくなり、ディスクI/Oパフォーマンスが向上する可能性があります。（GitLabバージョン13.0以降では常に有効になり、構成は14.0で削除される予定です） |
| `help_page_hide_commercial_content`      | ブール値          | いいえ                                   | ヘルプからマーケティング関連のエントリを非表示にします。 |
| `help_page_support_url`                  | 文字列           | いいえ                                   | ヘルプページとヘルプドロップダウンリストの代替サポートURL。 |
| `help_page_documentation_base_url`       | 文字列           | いいえ                                   | 代替ドキュメントページのURL。 |
| `help_page_text`                         | 文字列           | いいえ                                   | ヘルプページに表示されるカスタムテキスト。 |
| `hide_third_party_offers`                | ブール値          | いいえ                                   | GitLabでサードパーティからのオファーを表示しない。 |
| `home_page_url`                          | 文字列           | いいえ                                   | ログインしていないときに、このURLにリダイレクトします。 |
| `housekeeping_bitmaps_enabled`           | ブール値          | いいえ                                   | 非推奨。Gitパックファイルのビットマップ作成は常に有効になっており、APIおよびUI経由で変更することはできません。常に`true`を返します。 |
| `housekeeping_enabled`                   | ブール値          | いいえ                                   | Gitハウスキーピングを有効または無効にします。追加のフィールドを設定する必要があります。 |
| `housekeeping_full_repack_period`        | 整数          | いいえ                                   | 非推奨。`git repack`が実行されるまでのGitプッシュの回数。代わりに`housekeeping_optimize_repository_period`を使用してください。 |
| `housekeeping_gc_period`                 | 整数          | いいえ                                   | 非推奨。`git gc`が実行されるまでのGitプッシュの回数。代わりに`housekeeping_optimize_repository_period`を使用してください。 |
| `housekeeping_incremental_repack_period` | 整数          | いいえ                                   | 非推奨。`git repack`が実行されるまでのGitプッシュの回数。代わりに`housekeeping_optimize_repository_period`を使用してください。 |
| `housekeeping_optimize_repository_period`| 整数          | いいえ                                   | `git repack`が実行されるまでのGitプッシュの回数。 |
| `html_emails_enabled`                    | ブール値          | いいえ                                   | HTMLメールを有効にします。 |
| `import_sources`                         | 文字列の配列 | いいえ                                   | プロジェクトのインポートを許可するソース（使用できる値: `github`、`bitbucket`、`bitbucket_server`、`fogbugz`、`git`、`gitlab_project`、`gitea`、`manifest`）。 |
| `invisible_captcha_enabled`              | ブール値          | いいえ                                   | サインアップ時にInvisible CAPTCHAスパム検出を有効にします。デフォルトでは無効になっています。 |
| `issues_create_limit`                    | 整数          | いいえ                                   | ユーザーごとの1分あたりのイシュー作成リクエストの最大数。デフォルトでは無効になっています。|
| `jira_connect_application_key`           | 文字列           | いいえ                                   | GitLab for Jira Cloudアプリで認証するために使用されるOAuthアプリケーションのID。 |
| `jira_connect_public_key_storage_enabled` | ブール値         | いいえ                                   | GitLab for Jira Cloudアプリの公開キーストレージを有効にします。 |
| `jira_connect_proxy_url`                 | 文字列           | いいえ                                   | GitLab for Jira Cloudアプリのプロキシとして使用されるGitLabインスタンスのURL。 |
| `keep_latest_artifact`                   | ブール値          | いいえ                                   | 有効期限に関係なく、最新の成功したジョブからアーティファクトを削除できないようにします。デフォルトでは有効になっています。 |
| `local_markdown_version`                 | 整数          | いいえ                                   | キャッシュされたMarkdownを無効にする必要がある場合は、この値を増やしてください。 |
| `lock_memberships_to_saml`               | ブール値          | いいえ                                   | [SAMLグループメンバーシップ](../user/group/saml_sso/group_sync.md#global-saml-group-memberships-lock)に対するグローバルロックを適用します。 |
| `mailgun_signing_key`                    | 文字列           | いいえ                                   | Webhookからイベントを受信するためのMailgun HTTP Webhook署名キー。 |
| `mailgun_events_enabled`                 | ブール値          | いいえ                                   | Mailgunイベントレシーバーを有効にします。 |
| `maintenance_mode_message`               | 文字列           | いいえ                                   | インスタンスがメンテナンスモードの場合に表示されるメッセージ。PremiumおよびUltimateのみです。 |
| `maintenance_mode`                       | ブール値          | いいえ                                   | インスタンスがメンテナンスモードの場合、管理者以外のユーザーは読み取り専用アクセスでサインインし、読み取り専用APIリクエストを行うことができます。PremiumおよびUltimateのみです。 |
| `max_artifacts_size`                     | 整数          | いいえ                                   | アーティファクトの最大サイズMB。 |
| `max_attachment_size`                    | 整数          | いいえ                                   | MB単位の添付ファイルのサイズ制限。 |
| `max_decompressed_archive_size`          | 整数          | いいえ                                   | インポートされたアーカイブの最大解凍されたファイルサイズ。無制限にするには、`0`に設定します。デフォルトは`25600`です。  |
| `max_export_size`                        | 整数          | いいえ                                   | 最大エクスポートサイズMB。無制限の場合は0。デフォルト=0（無制限）。 |
| `max_github_response_size_limit`         | 整数          | いいえ                                   | 許可されるGitHub API応答サイズの最大値（MB単位）。無制限の場合は0。 |
| `max_github_response_json_value_count`   | 整数          | いいえ                                   | 許可されるGitHub API応答の値の数の最大値。無制限の場合は0。カウントは、応答内の`:` `,` `{`、`[`の出現回数に基づく概算です。 |
| `max_http_decompressed_size`             | 整数          | いいえ                                   | 解凍後のGzip圧縮HTTP応答で許可される最大サイズ（MiB単位）。無制限の場合は0。 |
| `max_http_response_size_limit`           | 整数          | いいえ                                   | HTTP応答で許可される最大サイズ（MiB単位）。無制限の場合は0。 |
| `max_import_size`                        | 整数          | いいえ                                   | 最大インポートサイズMB。無制限の場合は0。デフォルト=0（無制限）。 |
| `max_import_remote_file_size`            | 整数          | いいえ                                   | オブジェクトストレージからのインポートの最大リモートファイルサイズGitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)されました。 |
| `max_login_attempts`                     | 整数          | いいえ                                   | ユーザーがロックアウトされるまでのサインイン試行回数の最大数。 |
| `max_pages_size`                         | 整数          | いいえ                                   | MB単位のページリポジトリの最大サイズ。 |
| `max_personal_access_token_lifetime`     | 整数          | いいえ                                   | アクセストークンの最大許容ライフタイム（日数）。空白のままにすると、デフォルト値の365が適用されます。設定する場合、値は365以下でなければなりません。変更すると、最大許容ライフタイムを超える有効期限のある既存のアクセストークンは失効します。GitLabセルフマネージド、Ultimateのみ。GitLab 17.6以降では、[最大ライフタイム制限を400日まで延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)するには、`buffered_token_expiration_limit`という名前の[機能フラグ](../administration/feature_flags/_index.md)を有効にします。|
| `max_ssh_key_lifetime`                   | 整数          | いいえ                                   | SSHキーの最大許容ライフタイム（日数）。GitLabセルフマネージド、Ultimateのみ。GitLab 17.6以降では、[最大ライフタイム制限を400日まで延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)するには、`buffered_token_expiration_limit`という名前の[機能フラグ](../administration/feature_flags/_index.md)を有効にします。|
| `max_terraform_state_size_bytes`         | 整数          | いいえ                                   | [Terraformステートファイル](../administration/terraform_state.md)の最大サイズ（バイト単位）。無制限のファイルサイズにするには、これを0に設定します。 |
| `metrics_method_call_threshold`          | 整数          | いいえ                                   | メソッドの呼び出しは、指定されたミリ秒数よりも時間がかかる場合にのみ、追跡されます。 |
| `max_number_of_repository_downloads`     | 整数          | いいえ                                   | 指定された期間内にユーザーがダウンロードできる一意のリポジトリの最大数。この数を超えると、ユーザーはBANされます。デフォルト: 0、最大値は: 10,000リポジトリ。GitLabセルフマネージド、Ultimateのみ。 |
| `max_number_of_repository_downloads_within_time_period` | 整数 | いいえ                             | レポート期間（秒単位）。デフォルト: 0、最大値は: 864,000秒 (10日間)。GitLabセルフマネージド、Ultimateのみ。 |
| `max_yaml_depth`                         | 整数          | いいえ                                   | [`include`キーワード](../ci/yaml/_index.md#include)で追加されたネストされたCI/CD構成の最大の深さ。デフォルトは`100`です。 |
| `max_yaml_size_bytes`                    | 整数          | いいえ                                   | 単一のCI/CD設定ファイルの最大サイズ（バイト単位）。デフォルトは`2097152`です。 |
| `git_rate_limit_users_allowlist`         | 文字列の配列  | いいえ                                  | Gitのアンチアビューズレート制限から除外されるユーザー名のリスト。デフォルトは`[]`、最大値は: 100個のユーザー名です。GitLabセルフマネージド、Ultimateのみ。 |
| `git_rate_limit_users_alertlist`         | 整数の配列 | いいえ                                  | Gitの悪用レート制限を超えた場合にメールが送信されるユーザーIDのリスト。デフォルトは`[]`、最大値は: 100個のユーザーIDです。GitLabセルフマネージド、Ultimateのみ。 |
| `auto_ban_user_on_excessive_projects_download` | ブール値    | いいえ                                   | 有効にすると、ユーザーは、`max_number_of_repository_downloads`と`max_number_of_repository_downloads_within_time_period`で指定された期間内に最大数を超える固有のプロジェクトをダウンロードすると、アプリケーションから自動的にBANされます。GitLabセルフマネージド、Ultimateのみ。 |
| `mirror_available`                       | ブール値          | いいえ                                   | プロジェクトメンテナーが構成したリポジトリミラーリングを許可します。無効にすると、管理者のみがリポジトリミラーリングを構成できます。 |
| `mirror_capacity_threshold`              | 整数          | いいえ                                   | より多くのミラーを事前にスケジュールする前に、利用可能にする最小キャパシティ。PremiumおよびUltimateのみです。 |
| `mirror_max_capacity`                    | 整数          | いいえ                                   | 同時に同期できるミラーの最大数。PremiumおよびUltimateのみです。 |
| `mirror_max_delay`                       | 整数          | いいえ                                   | 同期するようにスケジュールされている場合に、ミラーが持つことができる更新間の最大時間（分単位）。PremiumおよびUltimateのみです。 |
| `maven_package_requests_forwarding`      | ブール値          | いいえ                                   | MavenのGitLabパッケージレジストリにパッケージが見つからない場合、デフォルトのリモートリポジトリとしてrepo.maven.apache.orgを使用します。PremiumおよびUltimateのみです。 |
| `npm_package_requests_forwarding`        | ブール値          | いいえ                                   | NPMのGitLabパッケージレジストリにパッケージが見つからない場合、npmjs.orgをデフォルトのリモートリポジトリとして使用します。PremiumおよびUltimateのみです。 |
| `pypi_package_requests_forwarding`       | ブール値          | いいえ                                   | PyPIのGitLabパッケージレジストリにパッケージが見つからない場合、pypi.orgをデフォルトのリモートリポジトリとして使用します。PremiumおよびUltimateのみです。 |
| `outbound_local_requests_whitelist`      | 文字列の配列 | いいえ                                   | Webhookとインテグレーションのローカルリクエストが無効になっている場合に、ローカルリクエストが許可される信頼できるドメインまたはIPアドレスのリストを定義します。現在、この属性は更新できません。詳細については、[issue 569729](https://gitlab.com/gitlab-org/gitlab/-/issues/569729)を参照してください。 |
| `package_registry_allow_anyone_to_pull_option` | ブール値    | いいえ                                   | 表示および変更可能な[パッケージレジストリから誰でもプルできるように](../user/packages/package_registry/_index.md#allow-anyone-to-pull-from-package-registry)有効にします。 |
| `package_metadata_purl_types`            | 整数の配列 | いいえ                                  | [パッケージレジストリのメタデータを同期する](../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)リスト。使用可能な値の[リスト](https://gitlab.com/gitlab-org/gitlab/-/blob/ace16c20d5da7c4928dd03fb139692638b557fe3/app/models/concerns/enums/package_metadata.rb#L5)を参照してください。GitLabセルフマネージド、Ultimateのみ。 |
| `pages_domain_verification_enabled`       | ブール値         | いいえ                                   | ユーザーにカスタムドメインの所有権を証明することを要求します。ドメインの検証は、公開GitLabサイトに不可欠なセキュリティ対策です。ユーザーは、ドメインが有効になる前に、ドメインを制御していることを証明する必要があります。 |
| `pages_unique_domain_default_enabled`    | ブール値         | いいえ                                   | 特定のネームスペースにあるサイト間でCookieの共有を回避するために、GitLab Pagesサイトに対してデフォルトで固有のドメインを有効にします。デフォルトは`true`です。 |
| `password_authentication_enabled_for_git` | ブール値         | いいえ                                   | GitLabアカウントのパスワードを介して、HTTP(S)経由でGitの認証を有効にします。デフォルトは`true`です。 |
| `password_authentication_enabled_for_web` | ブール値         | いいえ                                   | GitLabアカウントのパスワードを介して、Webユーザーインターフェースの認証を有効にします。デフォルトは`true`です。 |
| `minimum_password_length`                | 整数          | いいえ                                   | パスワードに最小文字数が必要かどうかを示します。PremiumおよびUltimateのみです。 |
| `password_number_required`               | ブール値          | いいえ                                   | パスワードに少なくとも1つの数字が必要かどうかを示します。PremiumおよびUltimateのみです。 |
| `password_symbol_required`               | ブール値          | いいえ                                   | パスワードに少なくとも1つの記号文字が必要かどうかを示します。PremiumおよびUltimateのみです。 |
| `password_uppercase_required`            | ブール値          | いいえ                                   | パスワードに少なくとも1つの大文字が必要かどうかを示します。PremiumおよびUltimateのみです。 |
| `password_lowercase_required`            | ブール値          | いいえ                                   | パスワードに少なくとも1つの小文字が必要かどうかを示します。PremiumおよびUltimateのみです。 |
| `performance_bar_allowed_group_id`       | 文字列           | いいえ                                   | 非推奨: `performance_bar_allowed_group_path`の代わりにパスを使用）パフォーマンスバーの切替を許可されたグループのパス。 |
| `performance_bar_allowed_group_path`     | 文字列           | いいえ                                   | パフォーマンスバーの切替を許可されたグループのパス。 |
| `performance_bar_enabled`                | ブール値          | いいえ                                   | 非推奨: `performance_bar_allowed_group_path: nil`を渡す代わりに、パフォーマンスバーを有効にすることを許可します。 |
| `personal_access_token_prefix`           | 文字列           | いいえ                                   | 生成されたすべてのパーソナルアクセストークンのプレフィックス。 |
| `pipeline_limit_per_project_user_sha`    | 整数          | いいえ                                   | ユーザーとコミットごとの1分あたりのパイプライン作成リクエストの最大数。デフォルトでは無効になっています。 |
| `gitpod_enabled`                         | ブール値          | いいえ                                   | （**有効にする場合は必須**: `gitpod_url`）[Onaインテグレーション](../integration/gitpod.md)を有効にします。デフォルトは`false`です。 |
| `gitpod_url`                             | 文字列           | `gitpod_enabled`で必要        | インテグレーション用のOnaインスタンスのURL。 |
| `inactive_resource_access_tokens_delete_after_days`| 整数 | いいえ                                   | 非アクティブなプロジェクトおよびグループのアクセストークンの保持期間を指定します。デフォルトは`30`です。 |
| `kroki_enabled`                          | ブール値          | いいえ                                   | （**有効にする場合は必須**: `kroki_url`）[Krokiインテグレーション](../administration/integration/kroki.md)を有効にします。デフォルトは`false`です。 |
| `kroki_url`                              | 文字列           | `kroki_enabled`で必要         | インテグレーション用のKrokiインスタンスのURL。 |
| `kroki_formats`                          | オブジェクト           | いいえ                                   | Krokiインスタンスでサポートされている追加の形式。使用できる値は、`true`または`false`（形式`bpmn`、`blockdiag`、`excalidraw`の場合）で、形式は`<format>: true`または`<format>: false`です。 |
| `plantuml_enabled`                       | ブール値          | いいえ                                   | （**有効にする場合は必須**: `plantuml_url`）[PlantUMLインテグレーション](../administration/integration/plantuml.md)を有効にします。デフォルトは`false`です。 |
| `plantuml_url`                           | 文字列           | `plantuml_enabled`で必要      | インテグレーション用のPlantUMLインスタンスのURL。 |
| `polling_interval_multiplier`            | 浮動小数点数            | いいえ                                   | ポーリングを実行するエンドポイントで使用される間隔乗算。ポーリングを無効にするには、`0`に設定します。 |
| `project_export_enabled`                 | ブール値          | いいえ                                   | プロジェクトのエクスポートを有効にする。 |
| `project_jobs_api_rate_limit`            | 整数          | いいえ                                   | `/project/:id/jobs`に対する認証されたリクエストの最大数（1分あたり）。GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129319)されました。デフォルト: 600。 |
| `projects_api_rate_limit_unauthenticated` | 整数         | いいえ                                   | [すべてのプロジェクトAPIをリストする](projects.md#list-all-projects)に対する認証されていないリクエストについて、IPアドレスごとに10分あたりの最大リクエスト数。デフォルト: 400。スロットリングを無効にするには、0に設定します。|
| `runner_jobs_request_api_limit`          | 整数          | いいえ                                   | `/jobs/request` RunnerジョブAPIエンドポイントへのリクエストについて、Runnerトークンごとの1分あたりの最大リクエスト数。デフォルト: 2000。スロットリングを無効にするには、0に設定します。GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462537)。 |
| `runner_jobs_patch_trace_api_limit`      | 整数          | いいえ                                   | `PATCH /jobs/:id/trace` RunnerジョブAPIエンドポイントへのリクエストについて、Runnerトークンごとの1分あたりの最大リクエスト数。デフォルト: 2000。スロットリングを無効にするには、0に設定します。GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462537)。 |
| `runner_jobs_endpoints_api_limit`        | 整数          | いいえ                                   | ランナージョブAPIエンドポイントへの`/jobs/*`リクエストに対する、ジョブトークンごとの1分あたりのリクエスト最大数。デフォルト: 200。スロットリングを無効にするには、0に設定します。GitLab 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462537)。 |
| `users_api_limit_following` | 整数 |    いいえ    | ユーザーまたはIPアドレスごとの1分あたりの最大リクエスト数。デフォルト: 100。`0`に設定すると、制限が無効になります。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。  |
| `users_api_limit_followers` | 整数 |    いいえ    | ユーザーまたはIPアドレスごとの1分あたりの最大リクエスト数。デフォルト: 100。`0`に設定すると、制限が無効になります。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。  |
| `users_api_limit_status`    | 整数 |    いいえ    | ユーザーまたはIPアドレスごとの1分あたりの最大リクエスト数。デフォルト: 240。`0`に設定すると、制限が無効になります。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。  |
| `users_api_limit_keys`      | 整数 |    いいえ    | ユーザーまたはIPアドレスごとの1分あたりの最大リクエスト数。デフォルト: 120。`0`に設定すると、制限が無効になります。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。  |
| `users_api_limit_key`       | 整数 |    いいえ    | ユーザーまたはIPアドレスごとの1分あたりの最大リクエスト数。デフォルト: 120。`0`に設定すると、制限が無効になります。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。  |
| `users_api_limit_gpg_keys`  | 整数 |    いいえ    | ユーザーまたはIPアドレスごとの1分あたりの最大リクエスト数。デフォルト: 120。`0`に設定すると、制限が無効になります。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。  |
| `users_api_limit_gpg_key`   | 整数 |    いいえ    | ユーザーまたはIPアドレスごとの1分あたりの最大リクエスト数。デフォルト: 120。`0`に設定すると、制限が無効になります。GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054)されました。  |
| `virtual_registries_endpoints_api_limit`          | 整数          | いいえ                                   | 仮想レジストリエンドポイントに対する、IPアドレスごとの15秒あたりの最大リクエスト数。デフォルト: 1000。制限を無効にするには、`0`に設定します。GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/521692)されました。 |
| `prometheus_metrics_enabled`             | ブール値          | いいえ                                   | Prometheusメトリクスを有効にします。 |
| `protected_ci_variables`                 | ブール値          | いいえ                                   | CI/CD変数は、デフォルトで保護されています。 |
| `disable_overriding_approvers_per_merge_request` | ブール値  | いいえ                                   | プロジェクトとマージリクエストでの承認ルールを編集できないようにします |
| `prevent_merge_requests_author_approval`         | ブール値  | いいえ                                   | マージリクエストの作成者による承認を禁止します。 |
| `prevent_merge_requests_committers_approval`     | ブール値  | いいえ                                   | マージリクエストへのコミッターによる承認を防止します |
| `push_event_activities_limit`            | 整数          | いいえ                                   | 単一のプッシュで、[バルクプッシュイベント](../administration/settings/push_event_activities_limit.md)が作成される上限の変更数（ブランチまたはタグ）。`0`に設定しても、レート制限は無効になりません。 |
| `push_event_hooks_limit`                 | 整数          | いいえ                                   | 単一のプッシュで、Webhookとインテグレーションがトリガーされない上限の変更数（ブランチまたはタグ）。`0`に設定しても、レート制限は無効になりません。デフォルトは`3`です。 |
| `rate_limiting_response_text`            | 文字列           | いいえ                                   | `throttle_*`設定でレート制限が有効になっている場合、レート制限を超えたときに、このプレーンテキストの応答を送信します。これが空白の場合、「後で再試行」が送信されます。 |
| `raw_blob_request_limit`                 | 整数          | いいえ                                   | 各rawパスに対する1分あたりの最大リクエスト数（デフォルトは`300`）。レート制限を無効にするには、`0`に設定します。|
| `search_rate_limit`                      | 整数          | いいえ                                   | 認証中に検索を実行するための1分あたりの最大リクエスト数。デフォルト: 30。スロットリングを無効にするには、0に設定します。|
| `search_rate_limit_unauthenticated`      | 整数          | いいえ                                   | 認証されていない状態で検索を実行するための1分あたりの最大リクエスト数。デフォルト: 10。スロットリングを無効にするには、0に設定します。|
| `recaptcha_enabled`                      | ブール値          | いいえ                                   | （**有効にするには、以下が必要です**: `recaptcha_private_key`および`recaptcha_site_key`）reCAPTCHAを有効にします。 |
| `login_recaptcha_protection_enabled`     | ブール値          | いいえ                                   | ログインにreCAPTCHAを有効にします。 |
| `recaptcha_private_key`                  | 文字列           | `recaptcha_enabled`で必要     | reCAPTCHAのシークレットキー。 |
| `recaptcha_site_key`                     | 文字列           | `recaptcha_enabled`で必要     | reCAPTCHAのサイトキー。 |
| `receptive_cluster_agents_enabled`       | ブール値          | いいえ                                   | KubernetesのGitLabエージェントのリセプティブモードを有効にします。 |
| `receive_max_input_size`                 | 整数          | いいえ                                   | 最大プッシュサイズ (MB)。 |
| `relation_export_batch_size`             | 整数          | いいえ                                   | バッチ処理されたリレーションをエクスポートする際の各バッチのサイズ。[Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194607) in GitLab 18.2. |
| `remember_me_enabled`                    | ブール値          | いいえ                                   | [**ログイン情報を記憶する**設定](../administration/settings/account_and_limit_settings.md#configure-the-remember-me-option)を有効にします。導入GitLab 16.0。 |
| `repository_checks_enabled`              | ブール値          | いいえ                                   | GitLabは、サイレントディスクの破損問題を検出するために、すべてのプロジェクトおよびWikiリポジトリで定期的に`git fsck`を実行します。 |
| `repository_size_limit`                  | 整数          | いいえ                                   | リポジトリごとのサイズ制限（MB）。PremiumおよびUltimateのみです。 |
| `repository_storages_weighted`           | 文字列から整数へのハッシュ | いいえ                        | [ウェイト](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored)に対する`gitlab.yml`から取得された名前のハッシュ。新しいプロジェクトは、重み付けされたランダム選択によって選択された、これらのストアの1つに作成されます。 |
| `require_admin_approval_after_user_signup` | ブール値        | いいえ                                   | 有効にすると、登録フォームを使用してアカウントにサインアップするすべてのユーザーが**承認保留中**の状態になり、管理者が明示的に[承認](../administration/moderate_users.md)する必要があります。 |
| `require_email_verification_on_account_locked` | ブール値    | いいえ                                   | `true`の場合、インスタンス上のすべてのユーザーは、疑わしいサインインアクティビティーが検出された後、自分のIDを確認する必要があります。 |
| `require_personal_access_token_expiry`   | ブール値          | いいえ                                   | 有効にすると、ユーザーは、グループまたはプロジェクトのアクセストークン、または非サービスアカウントが所有するパーソナルアクセストークンを作成するときに、有効期限を設定する必要があります。 |
| `require_two_factor_authentication`      | ブール値          | いいえ                                   | （**有効にするには、以下が必要です**: `two_factor_grace_period`）すべてのユーザーに2要素認証を設定するように要求します。 |
| `resource_usage_limits`                | ハッシュ             | いいえ                                   | Sidekiqワーカーで適用されるリソース使用量制限の定義。この設定はGitLab.comでのみ使用できます。  |
| `restricted_visibility_levels`           | 文字列の配列 | いいえ                                   | 選択したレベルは、管理者以外のユーザーがグループ、プロジェクト、またはスニペットに使用することはできません。パラメータとして`private`、`internal`、および`public`を使用できます。デフォルトは`null`で、制限がないことを意味します。[変更点](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203): GitLab 16.4では、`default_project_visibility`および`default_group_visibility`として設定されているレベルを選択することはできません。 |
| `rsa_key_restriction`                    | 整数          | いいえ                                   | アップロードされたRSAキーの最小許容ビット長。デフォルトは`0` （制限なし）。`-1`はRSAキーを無効にします。 |
| `session_expire_delay`                   | 整数          | いいえ                                   | セッションの継続時間（分）。変更を適用するには、GitLabの再起動が必要です。 |
| `session_expire_from_init`               | ブール値          | いいえ                                   | `true`の場合、セッションは最後のアクティビティーの後ではなく、セッションの作成後、一定の時間が経過すると有効期限が切れます。セッションのライフタイムは、`session_expire_delay`によって定義されます。 |
| `security_policy_global_group_approvers_enabled` | ブール値  | いいえ                                   | マージリクエスト承認ポリシーの承認グループをグローバルに検索するか、プロジェクト階層内で検索するか。 |
| `security_approval_policies_limit`       | 整数          | いいえ                                   | セキュリティポリシープロジェクトあたりのアクティブなマージリクエスト承認ポリシーの最大数。デフォルト: 5\.最大値は: 20 |
| `scan_execution_policies_action_limit`   | 整数          | いいえ                                   | スキャン実行ポリシーあたりの`actions`の最大数。デフォルト: 0。最大値は: 20 |
| `scan_execution_policies_schedule_limit` | 整数          | いいえ                                   | スキャン実行ポリシーごとの`type: schedule`ルールの最大数。デフォルト: 0。最大値は: 20 |
| `security_txt_content`                    | 文字列          | いいえ                                   | [公開セキュリティ連絡先情報](../administration/settings/security_contact_information.md)。GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/433210)されました。 |
| `service_access_tokens_expiration_enforced` | ブール値       | いいえ                                   | サービスアカウントユーザーの場合、トークンの有効期限を任意にできるかどうかを示すフラグ |
| `shared_runners_enabled`                 | ブール値          | いいえ                                   | （**有効にするには、以下が必要です**: `shared_runners_text`および`shared_runners_minutes`）新しいプロジェクトのインスタンスRunnerを有効にします。 |
| `shared_runners_minutes`                 | 整数          | `shared_runners_enabled`で必要 | グループがインスタンスRunnerで使用できるコンピューティング時間の最大数を月単位で設定します。PremiumおよびUltimateのみです。 |
| `shared_runners_text`                    | 文字列           | `shared_runners_enabled`で必要 | インスタンスRunnerのテキスト。 |
| `runner_token_expiration_interval`         | 整数        | いいえ                                   | 新しく登録されたインスタンスRunnerの認証トークンの有効期限（秒単位）を設定します。最小値は7200秒です。詳細については、[認証トークンを自動的にローテーションする](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens)方法を参照してください。 |
| `group_runner_token_expiration_interval`   | 整数        | いいえ                                   | 新しく登録されたグループRunnerの認証トークンの有効期限（秒単位）を設定します。最小値は7200秒です。詳細については、[認証トークンを自動的にローテーションする](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens)方法を参照してください。 |
| `project_runner_token_expiration_interval` | 整数        | いいえ                                   | 新しく登録されたプロジェクトRunnerの認証トークンの有効期限（秒単位）を設定します。最小値は7200秒です。詳細については、[認証トークンを自動的にローテーションする](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens)方法を参照してください。 |
| `sidekiq_job_limiter_mode`                        | 文字列  | いいえ                                   | `track`または`compress`。[Sidekiqジョブサイズ制限](../administration/settings/sidekiq_job_limits.md)の動作を設定します。デフォルト: 'compress' |
| `sidekiq_job_limiter_compression_threshold_bytes` | 整数 | いいえ                                   | SidekiqジョブがRedisに保存される前に圧縮されるバイト単位のしきい値。デフォルト: 100,000バイト（100 KB）。 |
| `sidekiq_job_limiter_limit_bytes`                 | 整数 | いいえ                                   | Sidekiqジョブが拒否されるバイト単位のしきい値。デフォルト: 0バイト（ジョブを拒否しません）。 |
| `signin_enabled`                         | 文字列           | いいえ                                   | 非推奨: （代わりに`password_authentication_enabled_for_web`を使用）パスワード認証がWebインターフェースに対して有効になっているかどうかを示すフラグ。 |
| `sign_in_restrictions`                   | ハッシュ             | いいえ                                   | アプリケーションのサインイン制限。 |
| `signup_enabled`                         | ブール値          | いいえ                                   | 登録を有効にします。デフォルトはです。デフォルトは`true`です。 |
| `silent_admin_exports_enabled`           | ブール値          | いいえ                                   | [サイレント管理者エクスポート](../administration/settings/import_and_export_settings.md#enable-silent-admin-exports)を有効にする。デフォルトは`false`です。 |
| `silent_mode_enabled`                    | ブール値          | いいえ                                   | [サイレントモード](../administration/silent_mode/_index.md)を有効にします。デフォルトは`false`です。 |
| `slack_app_enabled`                      | ブール値          | いいえ                                   | （**有効にするには、以下が必要です**: `slack_app_id`、`slack_app_secret`、`slack_app_signing_secret`、および`slack_app_verification_token`）GitLab for Slackアプリを有効にします。 |
| `slack_app_id`                           | 文字列           | `slack_app_enabled`で必要     | GitLab for SlackアプリのクライアントID。 |
| `slack_app_secret`                       | 文字列           | `slack_app_enabled`で必要     | GitLab for Slackアプリのクライアントシークレット。アプリからのOAuthリクエストの認証に使用されます。 |
| `slack_app_signing_secret`               | 文字列           | `slack_app_enabled`で必要     | GitLab for Slackアプリの署名シークレット。アプリからのAPIリクエストの認証に使用されます。 |
| `slack_app_verification_token`           | 文字列           | `slack_app_enabled`で必要     | GitLab for Slackアプリの検証トークン。この認証方法はSlackでは非推奨であり、アプリからのスラッシュコマンドの認証にのみ使用されます。 |
| `snippet_size_limit`                     | 整数          | いいえ                                   | 最大スニペットコンテンツサイズ（**bytes**（バイト）単位）。デフォルト: 52428800バイト（50MB）。|
| `snowplow_app_id`                        | 文字列           | いいえ                                   | Snowplowサイト名/アプリケーションID（例: `gitlab`）。 |
| `snowplow_collector_hostname`            | 文字列           | `snowplow_enabled`で必要      | Snowplowコレクターのホスト名（例: `snowplowprd.trx.gitlab.net`）。 |
| `snowplow_database_collector_hostname`   | 文字列           | いいえ                                   | データベースイベントのSnowplowコレクターのホスト名（例: `db-snowplow.trx.gitlab.net`）。 |
| `snowplow_cookie_domain`                 | 文字列           | いいえ                                   | Snowplowクッキードメイン（例: `.gitlab.com`）。 |
| `snowplow_enabled`                       | ブール値          | いいえ                                   | Snowplowトラッキングを有効にします。 |
| `sourcegraph_enabled`                    | ブール値          | いいえ                                   | Sourcegraphインテグレーションを有効にします。デフォルトは`false`です。（**If enabled, requires**（有効にするには、以下が必要です））`sourcegraph_url`。 |
| `sourcegraph_public_only`                | ブール値          | いいえ                                   | Sourcegraphがプライベートプロジェクトおよび内部プロジェクトに読み込むされないようにブロックします。デフォルトは`true`です。 |
| `sourcegraph_url`                        | 文字列           | `sourcegraph_enabled`で必要   | インテグレーション用のSourcegraphインスタンスURI。 |
| `spam_check_endpoint_enabled`            | ブール値          | いいえ                                   | 外部スパムチェックAPIエンドポイントを使用して、スパムチェックを有効にします。デフォルトは`false`です。 |
| `spam_check_endpoint_url`                | 文字列           | いいえ                                   | 外部SpamcheckサービスエンドポイントのURI。有効なURIスキームは、`grpc`または`tls`です。`tls`を指定すると、通信が暗号化された状態になります。|
| `spam_check_api_key`                     | 文字列           | いいえ                                   | スパムチェックサービスエンドポイントへのアクセスでGitLabが使用するAPIキー。 |
| `suggest_pipeline_enabled`               | ブール値          | いいえ                                   | パイプラインの提案バナーを有効にします。 |
| `enable_artifact_external_redirect_warning_page` | ブール値  | いいえ                                   | アーティファクトの外部リンクのリダイレクトページを有効にするGitLab Pagesでユーザーが作成したコンテンツについて警告する外部リンクのリダイレクトページを表示します。 |
| `terminal_max_session_time`              | 整数          | いいえ                                   | WebターミナルWeb端末のWebSocket接続の最大時間（秒単位）。時間を無制限にするには、`0`に設定します。 |
| `terms`                                  | テキスト             | `enforce_terms`で必要         | （**Required by**（必須）: `enforce_terms`）利用規約のMarkdownコンテンツ。 |
| `throttle_authenticated_api_enabled`                      | ブール値 | いいえ                                                              | （**有効にするには、以下が必要です**: `throttle_authenticated_api_period_in_seconds`および`throttle_authenticated_api_requests_per_period`）認証済みのAPIリクエストレート制限を有効にします。（クローラーや不正なボットなどからの）リクエスト量を削減するのに役立ちます。 |
| `throttle_authenticated_api_period_in_seconds`            | 整数 | 以下で必要:<br>`throttle_authenticated_api_enabled`            | レート制限期間（秒単位）。 |
| `throttle_authenticated_api_requests_per_period`          | 整数 | 以下で必要:<br>`throttle_authenticated_api_enabled`            | ユーザーごとの期間あたりの最大リクエスト数。 |
| `throttle_authenticated_git_http_enabled`             | ブール値 | 条件付き | `true`の場合、認証済みのGit HTTPリクエストレート制限が適用されます。デフォルト値: `false`。 |
| `throttle_authenticated_git_http_period_in_seconds`   | 整数 | いいえ            | レート制限期間（秒単位）。`throttle_authenticated_git_http_enabled`は`true`である必要があります。デフォルト値: `3600`。 |
| `throttle_authenticated_git_http_requests_per_period` | 整数 | いいえ            | ユーザーごとの期間あたりの最大リクエスト数。`throttle_authenticated_git_http_enabled`は`true`である必要があります。デフォルト値: `3600`。 |
| `throttle_authenticated_packages_api_enabled`             | ブール値 | いいえ                                                              | （**有効にするには、以下が必要です**: `throttle_authenticated_packages_api_period_in_seconds`および`throttle_authenticated_packages_api_requests_per_period`）認証済みのAPIリクエストレート制限を有効にします。（クローラーや不正なボットなどからの）リクエスト量を削減するのに役立ちます。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_authenticated_packages_api_period_in_seconds`   | 整数 | 以下で必要:<br>`throttle_authenticated_packages_api_enabled`   | レート制限期間（秒単位）。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_authenticated_packages_api_requests_per_period` | 整数 | 以下で必要:<br>`throttle_authenticated_packages_api_enabled`   | ユーザーごとの期間あたりの最大リクエスト数。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_authenticated_web_enabled`                      | ブール値 | いいえ                                                              | （**有効にするには、以下が必要です**: `throttle_authenticated_web_period_in_seconds`および`throttle_authenticated_web_requests_per_period`）認証済みのWebリクエストレート制限を有効にします。（クローラーや不正なボットなどからの）リクエスト量を削減するのに役立ちます。 |
| `throttle_authenticated_web_period_in_seconds`            | 整数 | 以下で必要:<br>`throttle_authenticated_web_enabled`            | レート制限期間（秒単位）。 |
| `throttle_authenticated_web_requests_per_period`          | 整数 | 以下で必要:<br>`throttle_authenticated_web_enabled`            | ユーザーごとの期間あたりの最大リクエスト数。 |
| `throttle_unauthenticated_enabled`                        | ブール値 | いいえ                                                              | ([非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) GitLab 14.3。（代わりに`throttle_unauthenticated_web_enabled`または`throttle_unauthenticated_api_enabled`を使用）。（**有効にするには、以下が必要です**: `throttle_unauthenticated_period_in_seconds`および`throttle_unauthenticated_requests_per_period`）認証されていないWebリクエストレート制限を有効にします。（クローラーや不正なボットなどからの）リクエスト量を削減するのに役立ちます。 |
| `throttle_unauthenticated_period_in_seconds`              | 整数 | 以下で必要:<br>`throttle_unauthenticated_enabled`              | ([非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) GitLab 14.3。代わりに`throttle_unauthenticated_web_period_in_seconds`または`throttle_unauthenticated_api_period_in_seconds`を使用してください。）レート制限期間（秒単位）。 |
| `throttle_unauthenticated_requests_per_period`            | 整数 | 以下で必要:<br>`throttle_unauthenticated_enabled`              | ([非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) GitLab 14.3。代わりに`throttle_unauthenticated_web_requests_per_period`または`throttle_unauthenticated_api_requests_per_period`を使用してください。）IPごとの期間あたりの最大リクエスト数。 |
| `throttle_unauthenticated_api_enabled`                    | ブール値 | いいえ                                                              | （**有効にするには、以下が必要です**: `throttle_unauthenticated_api_period_in_seconds`および`throttle_unauthenticated_api_requests_per_period`）認証されていないAPIリクエストレート制限を有効にします。（クローラーや不正なボットなどからの）リクエスト量を削減するのに役立ちます。 |
| `throttle_unauthenticated_api_period_in_seconds`          | 整数 | 以下で必要:<br>`throttle_unauthenticated_api_enabled`          | レート制限期間（秒単位）。 |
| `throttle_unauthenticated_api_requests_per_period`        | 整数 | 以下で必要:<br>`throttle_unauthenticated_api_enabled`          | IPごとの期間あたりの最大リクエスト数。 |
| `throttle_unauthenticated_git_http_enabled`             | ブール値 | 条件付き | `true`の場合、認証されていないGit HTTPリクエストレート制限が適用されます。デフォルト値: `false`。 |
| `throttle_unauthenticated_git_http_period_in_seconds`   | 整数 | いいえ            | レート制限期間（秒単位）。`throttle_unauthenticated_git_http_enabled`は`true`である必要があります。デフォルト値: `3600`。 |
| `throttle_unauthenticated_git_http_requests_per_period` | 整数 | いいえ            | ユーザーごとの期間あたりの最大リクエスト数。`throttle_unauthenticated_git_http_enabled`は`true`である必要があります。デフォルト値: `3600`。 |
| `throttle_unauthenticated_packages_api_enabled`           | ブール値 | いいえ                                                              | （**有効にするには、以下が必要です**: `throttle_unauthenticated_packages_api_period_in_seconds`および`throttle_unauthenticated_packages_api_requests_per_period`）認証済みのAPIリクエストレート制限を有効にします。（クローラーや不正なボットなどからの）リクエスト量を削減するのに役立ちます。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_unauthenticated_packages_api_period_in_seconds` | 整数 | 以下で必要:<br>`throttle_unauthenticated_packages_api_enabled` | レート制限期間（秒単位）。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_unauthenticated_packages_api_requests_per_period` | 整数 | 以下で必要:<br>`throttle_unauthenticated_packages_api_enabled` | ユーザーごとの期間あたりの最大リクエスト数。詳細については、[パッケージレジストリのレート制限](../administration/settings/package_registry_rate_limits.md)を参照してください。 |
| `throttle_unauthenticated_web_enabled`                    | ブール値 | いいえ                                                              | （**有効にするには、以下が必要です**: `throttle_unauthenticated_web_period_in_seconds`および`throttle_unauthenticated_web_requests_per_period`）認証されていないWebリクエストレート制限を有効にします。（クローラーや不正なボットなどからの）リクエスト量を削減するのに役立ちます。 |
| `throttle_unauthenticated_web_period_in_seconds`          | 整数 | 以下で必要:<br>`throttle_unauthenticated_web_enabled`          | レート制限期間（秒単位）。 |
| `throttle_unauthenticated_web_requests_per_period`        | 整数 | 以下で必要:<br>`throttle_unauthenticated_web_enabled`          | IPごとの期間あたりの最大リクエスト数。 |
| `time_tracking_limit_to_hours`           | ブール値          | いいえ                                   | タイムトラッキングユニットの表示を時間単位に制限します。デフォルトは`false`です。 |
| `top_level_group_creation_enabled`           | ブール値          | いいえ                                   | ユーザーがトップレベルグループを作成できるようにします。デフォルトは`true`です。 |
| `two_factor_grace_period`                | 整数          | `require_two_factor_authentication`で必要 | ユーザーが2要素認証の強制構成をスキップできる時間（時間単位）。 |
| `unconfirmed_users_delete_after_days`    | 整数          | いいえ                                   | メールを確認していないユーザーをサインアップ後に削除するまでの日数を指定します。`delete_unconfirmed_users`が`true`に設定されている場合にのみ適用されます。`1`以上である必要があります。デフォルトは`7`です。GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352514)されました。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `unique_ips_limit_enabled`               | ブール値          | いいえ                                   | （**有効にするには、以下が必要です**: `unique_ips_limit_per_user`および`unique_ips_limit_time_window`）複数のIPからのサインインを制限します。 |
| `unique_ips_limit_per_user`              | 整数          | `unique_ips_limit_enabled`で必要 | ユーザーごとのIPの最大数。 |
| `unique_ips_limit_time_window`           | 整数          | `unique_ips_limit_enabled`で必要 | IPが制限に対してカウントされる秒数。 |
| `update_runner_versions_enabled`         | ブール値          | いいえ                                   | GitLab.comからGitLab Runnerのリリースバージョンデータをフェッチします。詳しくは、[Runnerのアップグレードが必要かどうかを判断する方法](../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded)をご覧ください。 |
| `usage_ping_enabled`                     | ブール値          | いいえ                                   | 毎週、GitLabはライセンスの使用状況をGitLab, Inc.に報告します。 |
| `use_clickhouse_for_analytics`           | ブール値          | いいえ                                   | 分析レポートのデータソースとしてClickHouseを有効にします。この設定を有効にするには、ClickHouseを構成する必要があります。PremiumおよびUltimateプランでのみ利用可能です。 |
| `include_optional_metrics_in_service_ping`| ブール値         | いいえ                                   | Service Pingでオプションのメトリクスが有効になっているかどうか。GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141540)されました。 |
| `user_deactivation_emails_enabled`       | ブール値          | いいえ                                   | アカウントを無効にすると、ユーザーにメールが送信されます。 |
| `user_default_external`                  | ブール値          | いいえ                                   | 新しく登録したユーザーは、デフォルトで外部ユーザーになります。 |
| `user_default_internal_regex`            | 文字列           | いいえ                                   | デフォルトの内部ユーザーを識別するためのメールアドレスの正規表現パターンを指定します。 |
| `user_defaults_to_private_profile`       | ブール値          | いいえ                                   | 新しく作成されたユーザーは、デフォルトでプライベートプロファイルになります。`false`がデフォルトです。 |
| `user_oauth_applications`                | ブール値          | いいえ                                   | ユーザーがGitLabをOAuthプロバイダーとして使用するために、アプリケーションを登録できるようにします。この設定は、グループレベルのOAuthアプリケーションには影響しません。 |
| `user_show_add_ssh_key_message`          | ブール値          | いいえ                                   | `false`に設定すると、アップロードされたSSHキーがないユーザーに表示される`You won't be able to pull or push project code via SSH`警告を無効にします。 |
| `version_check_enabled`                  | ブール値          | いいえ                                   | アップデートが利用可能になったときに、GitLabから通知を受け取ります。 |
| `valid_runner_registrars`                | 文字列の配列 | いいえ                                   | GitLab Runnerの登録を許可されているタイプのリスト。`[]`、`['group']`、`['project']`、または`['group', 'project']`のいずれかです。 |
| `vscode_extension_marketplace`           | ハッシュ             | いいえ                                   | VS Code拡張機能マーケットプレースの設定。[Web IDE](../user/project/web_ide/_index.md)および[Workspaces](../user/workspace/_index.md)で使用されます。 |
| `whats_new_variant`                      | 文字列           | いいえ                                   | 新機能バリアント、可能な値: `all_tiers`、`current_tier`、および`disabled`。 |
| `wiki_page_max_content_bytes`            | 整数          | いいえ                                   | 最大Wikiページのコンテンツサイズ（**バイト**）。デフォルト: 5242880バイト（5MB）。最小値は1024バイトです。 |
| `bulk_import_concurrent_pipeline_batch_limit` | 整数     | いいえ                                   | 処理する同時ダイレクト転送バッチエクスポートの最大数。 |
| `concurrent_relation_batch_export_limit` | 整数          | いいえ                                   | 処理する同時バッチエクスポートジョブの最大数。GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169122)されました。 |
| `asciidoc_max_includes`                  | 整数          | いいえ                                   | 1つのドキュメントで処理されるAsciiDocインクルードディレクティブの最大制限。デフォルト: 32。最大値は: 64。 |
| `duo_features_enabled`                   | ブール値          | いいえ                                   | このインスタンスでGitLab Duo機能が有効になっているかどうかを示します。GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931)されました。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `lock_duo_features_enabled`              | ブール値          | いいえ                                   | GitLab Duo機能で有効になっている設定がすべてのサブグループに適用されるかどうかを示します。GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931)されました。GitLab Self-Managed、Premium、およびUltimateのみです。 |
| `nuget_skip_metadata_url_validation` | ブール値     | いいえ                                   | NuGetパッケージのメタデータURLの検証をスキップするかどうかを示します。GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145887)されました。 |
| `helm_max_packages_count` | 整数     | いいえ                                   | チャンネルごとにリストできるHelmパッケージの最大数を設定します。1以上である必要があります。デフォルトは1000です。 |
| `require_admin_two_factor_authentication` | ブール値         | いいえ | 管理者がインスタンス上のすべての管理者に2FAを要求できるようにします。 |
| `secret_push_protection_available` | ブール値         | いいえ | プロジェクトがシークレットプッシュ保護を有効にできるようにします。これは、シークレットプッシュ保護を有効にするものではありません。Ultimateのみです。 |
| `disable_invite_members` | ブール値         | いいえ | グループの招待メンバー機能を無効にします。 |
| `enforce_pipl_compliance` | ブール値 | いいえ | piplのコンプライアンスがSaaSアプリケーションに適用されるかどうかを設定します |

### 休止プロジェクトの設定 {#dormant-project-settings}

休止プロジェクトの削除を構成するか、オフにすることができます。

| 属性                                | 型             | 必須                             | 説明 |
|------------------------------------------|------------------|:------------------------------------:|-------------|
| `delete_inactive_projects`               | ブール値          | いいえ                                   | [休止プロジェクトの削除](../administration/dormant_project_deletion.md)を有効にします。デフォルトは`false`です。[機能フラグなしで運用可能になった](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96803) GitLab 15.4。 |
| `inactive_projects_delete_after_months`  | 整数          | いいえ                                   | `delete_inactive_projects`が`true`の場合、休止プロジェクトを削除するまでに待機する時間（月単位）。デフォルトは`2`です。[運用可能になった](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) GitLab 15.0。 |
| `inactive_projects_min_size_mb`          | 整数          | いいえ                                   | `delete_inactive_projects`が`true`の場合、プロジェクトが非アクティブかどうかを確認するための最小リポジトリサイズ。デフォルトは`0`です。[運用可能になった](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) GitLab 15.0。 |
| `inactive_projects_send_warning_email_after_months` | 整数 | いいえ                                 | `delete_inactive_projects`が`true`の場合、プロジェクトが休止状態のため削除される予定であるというメンテナーにメールを送信するまでに待機する時間（月単位）を設定します。デフォルトは`1`です。[運用可能になった](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) GitLab 15.0。 |

### パッケージレジストリ設定: パッケージファイルのサイズ制限 {#package-registry-settings-package-file-size-limits}

パッケージファイルのサイズ制限は、Application APIの一部ではありません。代わりに、これらの設定には[プラン制限API](plan_limits.md)を使用してアクセスできます。

## 関連トピック {#related-topics}

- [`default_branch_protection_defaults`のオプション](groups.md#options-for-default_branch_protection_defaults)
