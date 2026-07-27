---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des paramètres d'application"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [paramètres d'application](#available-settings) de votre instance GitLab.

Les modifications apportées à vos paramètres d'application sont soumises à la mise en cache et peuvent ne pas prendre effet immédiatement. Par défaut, GitLab met en cache les paramètres d'application pendant 60 secondes. Pour en savoir plus sur la façon de contrôler le cache des paramètres d'application pour une instance, voir [Intervalle de cache des applications](../administration/application_settings_cache.md).

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

## Récupérer les détails des paramètres d'application actuels {#retrieve-details-on-current-application-settings}

{{< history >}}

- Le feature flag `always_perform_delayed_deletion` a été [activé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332) dans GitLab 15.11.
- Les attributs `delayed_project_deletion` et `delayed_group_deletion` ont été supprimés dans GitLab 16.0.
- L'attribut `in_product_marketing_emails_enabled` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/418137) dans GitLab 16.6.
- L'attribut `repository_storages` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/429675) dans GitLab 16.6.
- L'attribut `user_email_lookup_limit` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136886) dans GitLab 16.7.
- Les attributs `allow_all_integrations` et `allowed_integrations` ont été [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/issues/500610) dans GitLab 17.6.

{{< /history >}}

Récupère les détails des [paramètres d'application](#available-settings) actuels de cette instance GitLab.

```plaintext
GET /application/settings
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/application/settings"
```

Exemple de réponse :

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

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) peuvent également voir ces paramètres :

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

## Mettre à jour les paramètres d'application {#update-application-settings}

{{< history >}}

- Le feature flag `always_perform_delayed_deletion` a été [activé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/113332) dans GitLab 15.11.
- Les attributs `delayed_project_deletion` et `delayed_group_deletion` ont été supprimés dans GitLab 16.0.
- Le feature flag `always_perform_delayed_deletion` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120476) dans GitLab 16.1.
- L'attribut `user_email_lookup_limit` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136886) dans GitLab 16.7.
- `default_branch_protection` a été [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) dans GitLab 17.0. Utilisez plutôt `default_branch_protection_defaults`.
- Les attributs `throttle_unauthenticated_git_http_enabled`, `throttle_unauthenticated_git_http_period_in_seconds` et `throttle_unauthenticated_git_http_requests_per_period` ont été [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147112) dans GitLab 17.0.
- Les attributs `allow_all_integrations` et `allowed_integrations` ont été [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/issues/500610) dans GitLab 17.6.
- Les attributs `throttle_authenticated_git_http_enabled`, `throttle_authenticated_git_http_period_in_seconds` et `throttle_authenticated_git_http_requests_per_period` ont été [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191552) dans GitLab 18.1 [avec un indicateur](../administration/feature_flags/_index.md) nommé `git_authenticated_http_limit`. Désactivé par défaut.
- Le feature flag `git_authenticated_http_limit` a été [activé](https://gitlab.com/gitlab-org/gitlab/-/issues/543768) dans GitLab 18.3.
- Le feature flag `git_authenticated_http_limit` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/561577) dans GitLab 18.4.

{{< /history >}}

Met à jour les [paramètres d'application](#available-settings) actuels de cette instance GitLab.

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

Exemple de réponse :

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

Les utilisateurs de [GitLab Premium ou Ultimate](https://about.gitlab.com/pricing/) peuvent également voir ces paramètres :

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

Exemples de réponses :

```json
  "file_template_project_id": 1,
  "geo_node_allowed_ips": "0.0.0.0/0, ::/0",
  "duo_features_enabled": true,
  "lock_duo_features_enabled": false,
  "allow_all_integrations": true,
  "allowed_integrations": [],
  "virtual_registries_endpoints_api_limit": 4000
```

## Paramètres disponibles {#available-settings}

<!--
This heading is referenced by a script: `scripts/cells/application-settings-analysis.rb`
 Any updates to this heading should be reflected for the DOC_API_SETTINGS_TABLE_REGEX variable.
 -->

{{< history >}}

- `housekeeping_full_repack_period`, `housekeeping_gc_period` et `housekeeping_incremental_repack_period` ont été [dépréciés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106963) dans GitLab 15.8. Utilisez plutôt `housekeeping_optimize_repository_period`.
- `allow_account_deletion` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/412411) dans GitLab 16.1.
- `allow_project_creation_for_guest_and_below` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134625) dans GitLab 16.8.
- `silent_admin_exports_enabled` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148918) dans GitLab 17.0.
- `require_personal_access_token_expiry` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/470192) dans GitLab 17.3.
- `receptive_cluster_agents_enabled` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/463427) dans GitLab 17.4.
- `allow_all_integrations` et `allowed_integrations` ont été [ajoutés](https://gitlab.com/gitlab-org/gitlab/-/issues/500610) dans GitLab 17.6.
- `iframe_rendering_enabled`, `iframe_rendering_allowlist` et `iframe_rendering_allowlist_raw` ont été introduits dans GitLab 18.6.
- `email_otp_enabled` a été introduit dans GitLab 19.1.

{{< /history >}}

En général, tous les paramètres sont facultatifs. Lors de l'activation de certains paramètres, vous pourriez également avoir besoin de configurer d'autres paramètres associés. Ces exigences figurent dans la colonne `Required` du tableau suivant.

| Attribut                                | Type             | Obligatoire                             | Description |
|------------------------------------------|------------------|:------------------------------------:|-------------|
| `admin_mode`                             | boolean          | non                                   | Exiger des administrateurs qu'ils activent le mode Admin en se réauthentifiant pour les tâches administratives. |
| `admin_notification_email`               | string           | non                                   | Déprécié : Utilisez plutôt `abuse_notification_email`. Si défini, les [signalements d'abus](../administration/review_abuse_reports.md) sont envoyés à cette adresse. Les signalements d'abus sont toujours disponibles dans la zone **Admin**. |
| `abuse_notification_email`               | string           | non                                   | Si défini, les [signalements d'abus](../administration/review_abuse_reports.md) sont envoyés à cette adresse. Les signalements d'abus sont toujours disponibles dans la zone **Admin**. |
| `notify_on_unknown_sign_in`              | boolean          | non                                   | Activer l'envoi de notifications en cas de connexion depuis une adresse IP inconnue. |
| `after_sign_out_path`                    | string           | non                                   | Vers quel emplacement rediriger les utilisateurs après la déconnexion. |
| `email_restrictions_enabled`             | boolean          | non                                   | Empêcher les nouveaux utilisateurs de créer un compte par e-mail. |
| `email_restrictions`                     | string           | requis par : `email_restrictions_enabled` | Expression régulière vérifiée par rapport à l'adresse e-mail utilisée lors de l'inscription. |
| `after_sign_up_text`                     | string           | non                                   | Texte affiché à l'utilisateur après son inscription. |
| `akismet_api_key`                        | string           | requis par : `akismet_enabled`       | Clé API pour la protection anti-spam Akismet. |
| `akismet_enabled`                        | boolean          | non                                   | (**Si activé, nécessite** : `akismet_api_key`) Activer ou désactiver la protection anti-spam Akismet. |
| `allow_all_integrations`                 | boolean          | non                                   | Lorsque `false`, seules les intégrations dans `allowed_integrations` sont autorisées sur l'instance. Ultimate uniquement. |
| `allowed_integrations`                   | tableau de chaînes de caractères | non                                   | Lorsque `allow_all_integrations` est `false`, seules les intégrations de cette liste sont autorisées sur l'instance. Ultimate uniquement. |
| `allow_account_deletion`                 | boolean          | non                                   | Définir sur `true` pour permettre aux utilisateurs de supprimer leurs comptes. Premium et Ultimate uniquement. |
| `allow_group_owners_to_manage_ldap`      | boolean          | non                                   | Définir sur `true` pour permettre aux propriétaires de groupes de gérer LDAP. Premium et Ultimate uniquement. |
| `allow_local_requests_from_hooks_and_services` | boolean    | non                                   | (Déprécié : Utilisez plutôt `allow_local_requests_from_web_hooks_and_services`) Autoriser les requêtes vers le réseau local depuis les webhooks et les intégrations. |
| `allow_local_requests_from_system_hooks` | boolean          | non                                   | Autoriser les requêtes vers le réseau local depuis les hooks système. |
| `allow_local_requests_from_web_hooks_and_services` | boolean | non                                  | Autoriser les requêtes vers le réseau local depuis les webhooks et les intégrations. |
| `allow_project_creation_for_guest_and_below` | boolean      | non                                   | Indique si les utilisateurs assignés jusqu'au rôle Invité peuvent créer des groupes et des projets personnels. La valeur par défaut est `true`. |
| `allow_runner_registration_token`        | boolean          | non                                   | Autoriser l'utilisation d'un jeton d'inscription pour créer un runner. La valeur par défaut est `true`. |
| `archive_builds_in_human_readable`       | string           | non                                   | Définir la durée pendant laquelle les jobs sont considérés comme anciens et expirés. Passé ce délai, les jobs sont archivés et ne peuvent plus être relancés. Laisser vide pour ne jamais faire expirer les jobs. La durée minimale est d'1 jour, par exemple : `15 days`, `1 month`, `2 years`. |
| `asset_proxy_enabled`                    | boolean          | non                                   | (**Si activé, nécessite** : `asset_proxy_url`) Activer le proxying des ressources. Un redémarrage de GitLab est nécessaire pour appliquer les modifications. |
| `asset_proxy_secret_key`                 | string           | non                                   | Secret partagé avec le serveur proxy de ressources. Un redémarrage de GitLab est nécessaire pour appliquer les modifications. |
| `asset_proxy_url`                        | string           | non                                   | URL du serveur proxy de ressources. Un redémarrage de GitLab est nécessaire pour appliquer les modifications. |
| `asset_proxy_whitelist`                  | chaîne ou tableau de chaînes | non                         | (Déprécié : Utilisez plutôt `asset_proxy_allowlist`) Les ressources correspondant à ces domaines ne sont pas proxifiées. Les caractères génériques sont autorisés. L'URL de votre installation GitLab est automatiquement ajoutée à la liste d'autorisation. Un redémarrage de GitLab est nécessaire pour appliquer les modifications. |
| `asset_proxy_allowlist`                  | chaîne ou tableau de chaînes | non                         | Les ressources correspondant à ces domaines ne sont pas proxifiées. Les caractères génériques sont autorisés. L'URL de votre installation GitLab est automatiquement ajoutée à la liste d'autorisation. Un redémarrage de GitLab est nécessaire pour appliquer les modifications. |
| `authn_data_retention_cleanup_enabled`   | boolean          | non                                   | Si `true`, exécute des nettoyeurs qui suppriment définitivement l'historique de connexion d'authentification datant de plus d'un an, ainsi que les jetons d'accès OAuth et les autorisations précédemment révoqués datant de plus d'un mois. Valeur par défaut : `false`. [Introduites](https://gitlab.com/gitlab-org/gitlab/-/work_items/579002) dans GitLab 18.7. |
| `authorized_keys_enabled`                | boolean          | non                                   | Par défaut, le fichier `authorized_keys` prend en charge Git via SSH sans configuration supplémentaire. GitLab peut être optimisé pour authentifier les clés SSH via le fichier de base de données. Ne désactivez cette option que si vous avez configuré votre serveur OpenSSH pour utiliser la commande AuthorizedKeysCommand. |
| `auto_devops_domain`                     | string           | non                                   | Spécifier un domaine à utiliser par défaut pour les environnements éphémères et les étapes de déploiement automatique de chaque projet. |
| `auto_devops_enabled`                    | boolean          | non                                   | Activer Auto DevOps pour les projets par défaut. Il génère, teste et déploie automatiquement les applications sur la base d'une configuration CI/CD prédéfinie. |
| `autocomplete_users`                     | integer          | non                                   | Nombre maximum de requêtes authentifiées par minute vers le point de terminaison `GET /autocomplete/users`. |
| `autocomplete_users_unauthenticated`     | integer          | non                                   | Nombre maximum de requêtes non authentifiées par minute vers le point de terminaison `GET /autocomplete/users`. |
| `automatic_purchased_storage_allocation` | boolean          | non                                   | L'activation de cette option permet l'allocation automatique du stockage acheté dans un espace de nommage. Pertinent uniquement pour les distributions EE. |
| `bulk_import_enabled`                    | boolean          | non                                   | Activer la migration des groupes GitLab par transfert direct. Ce paramètre est également [disponible](../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer) dans la zone **Admin**. |
| `bulk_import_max_download_file_size`     | integer          | non                                   | Taille maximale du fichier téléchargé lors de l'importation depuis des instances GitLab sources par transfert direct. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/384976) dans GitLab 16.3. |
| `allow_bypass_placeholder_confirmation`  | boolean          | non                                   | Ignorer la confirmation lorsque les administrateurs réaffectent des utilisateurs d'espace réservé. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/534330) dans GitLab 18.0. |
| `allow_s3_compatible_storage_for_offline_transfer` | boolean | non                                   | Autoriser le stockage d'objets compatible S3 pour le transfert hors ligne. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/579705) dans GitLab 18.9. |
| `can_create_group`                       | boolean          | non                                   | Indique si les utilisateurs peuvent créer des groupes principaux. La valeur par défaut est `true`. |
| `check_namespace_plan`                   | boolean          | non                                   | L'activation de cette option rend uniquement les fonctionnalités EE sous licence disponibles pour les projets si le plan de l'espace de nommage du projet inclut la fonctionnalité ou si le projet est public. Premium et Ultimate uniquement. |
| `ci_delete_pipelines_in_seconds_limit_human_readable` | string | non                                | Valeur maximale autorisée pour la configuration de la rétention des pipelines. La valeur par défaut est `1 year`. |
| `ci_job_live_trace_enabled`              | boolean          | non                                   | Active la journalisation incrémentielle pour les job logs. Lorsqu'activé, les job logs archivés sont téléchargés de manière incrémentielle vers le stockage d'objets. Le stockage d'objets doit être configuré. Vous pouvez également configurer ce paramètre dans la [zone **Admin**](../administration/settings/continuous_integration.md#access-job-log-settings). |
| `git_push_pipeline_limit`                | integer          | non                                   | Définir le nombre maximum de pipelines de balises ou de branches pouvant être déclenchés par un seul push Git. Pour plus d'informations sur cette limite, voir [nombre de pipelines par push Git](../administration/cicd/limits.md#number-of-pipelines-per-git-push). |
| `ci_max_total_yaml_size_bytes`           | integer          | non                                   | La quantité maximale de mémoire, en octets, pouvant être allouée à la configuration du pipeline, avec tous les fichiers de configuration YAML inclus. |
| `ci_max_includes`                        | integer          | non                                   | Le [nombre maximum d'inclusions](../administration/cicd/limits.md#maximum-number-of-includes) par pipeline. La valeur par défaut est `150`. |
| `ci_partitions_size_limit`               | integer          | non                                   | La quantité maximale d'espace disque, en octets, pouvant être utilisée par une partition de base de données pour les tables CI avant la création de nouvelles partitions. La valeur par défaut est `100 GB`. [Supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/429675) dans GitLab 18.11.|
| `ci_partitions_in_seconds_limit`         | integer          | non                                   | La fenêtre temporelle, en secondes, avant que de nouvelles partitions CI soient créées et que le système bascule vers le prochain ensemble de partitions. Doit être compris entre 1 mois et 6 mois. La valeur par défaut est 1 mois (`2592000`). |
| `concurrent_github_import_jobs_limit`    | integer          | non                                   | Nombre maximum de jobs d'importation simultanés pour l'importateur GitHub. La valeur par défaut est 1000. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875) dans GitLab 16.11. |
| `concurrent_bitbucket_import_jobs_limit` | integer          | non                                   | Nombre maximum de jobs d'importation simultanés pour l'importateur Bitbucket Cloud. La valeur par défaut est 100. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875) dans GitLab 16.11. |
| `concurrent_bitbucket_server_import_jobs_limit` | integer   | non                                   | Nombre maximum de jobs d'importation simultanés pour l'importateur Bitbucket Server. La valeur par défaut est 100. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/143875) dans GitLab 16.11. |
| `commit_email_hostname`                  | string           | non                                   | Nom d'hôte personnalisé (pour les e-mails de commit privés). |
| `container_expiration_policies_enable_historic_entries`   | boolean | non                           | Activer les [politiques de nettoyage](../user/packages/container_registry/reduce_container_registry_storage.md#enable-the-cleanup-policy) pour tous les projets. |
| `container_registry_cleanup_tags_service_max_list_size`   | integer | non                           | Le nombre maximum de balises pouvant être supprimées lors d'une seule exécution des [politiques de nettoyage](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources). |
| `container_registry_delete_tags_service_timeout`          | integer | non                           | Le temps maximum, en secondes, que le processus de nettoyage peut prendre pour supprimer un lot de balises pour les [politiques de nettoyage](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources). |
| `container_registry_expiration_policies_caching`          | boolean | non                           | Mise en cache lors de l'exécution des [politiques de nettoyage](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources). |
| `container_registry_expiration_policies_worker_capacity`  | integer | non                           | Nombre de workers pour les [politiques de nettoyage](../user/packages/container_registry/reduce_container_registry_storage.md#set-cleanup-limits-to-conserve-resources). |
| `container_registry_token_expire_delay`                   | integer | non                           | Durée du jeton du registre de conteneurs en minutes. |
| `package_registry_cleanup_policies_worker_capacity`       | integer | non                           | Nombre de workers affectés aux politiques de nettoyage des paquets. |
| `updating_name_disabled_for_users`       | boolean          | non                                   | [Désactiver les modifications du nom du profil utilisateur](../administration/settings/account_and_limit_settings.md#disable-user-profile-name-changes). |
| `allow_account_deletion`                 | boolean          | non                                   | Permettre aux [utilisateurs de supprimer leurs comptes](../administration/settings/account_and_limit_settings.md#prevent-users-from-deleting-their-accounts). |
| `deactivate_dormant_users`               | boolean          | non                                   | Activer la [désactivation automatique des utilisateurs dormants](../administration/moderate_users.md#automatically-deactivate-dormant-users). |
| `deactivate_dormant_users_period`        | integer          | non                                   | Durée (en jours) après laquelle un utilisateur est considéré comme dormant. |
| `decompress_archive_file_timeout`        | integer          | non                                   | Délai d'expiration par défaut pour la décompression des fichiers archivés, en secondes. Définir sur 0 pour désactiver les délais d'expiration. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129161) dans GitLab 16.4. |
| `default_artifacts_expire_in`            | string           | non                                   | Définir le délai d'expiration par défaut pour les artefacts de chaque job. |
| `default_branch_name`                    | string           | non                                   | [Définir le nom de branche initial](../user/project/repository/branches/default.md#change-the-default-branch-name-for-new-projects-in-an-instance) pour tous les projets d'une instance. |
| `default_branch_protection`              | integer          | non                                   | [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) dans GitLab 17.0. Utilisez plutôt `default_branch_protection_defaults`. |
| `default_branch_protection_defaults`     | hash             | non                                   | [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/408314) dans GitLab 17.0. Pour les options disponibles, voir [Options pour `default_branch_protection_defaults`](groups.md#options-for-default_branch_protection_defaults). |
| `default_ci_config_path`                 | string           | non                                   | Fichier et chemin de configuration CI/CD par défaut pour les nouveaux projets (`.gitlab-ci.yml` si non défini). |
| `default_group_visibility`               | string           | non                                   | Quel niveau de visibilité reçoivent les nouveaux groupes. Peut prendre `private`, `internal` et `public` comme paramètre. La valeur par défaut est `private`. [Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203) dans GitLab 16.4 : ne peut pas être défini sur des niveaux présents dans `restricted_visibility_levels`.|
| `default_preferred_language`             | string           | non                                   | Langue préférée par défaut pour les utilisateurs non connectés. |
| `default_project_creation`               | integer          | non                                   | Rôle minimum par défaut requis pour créer des projets. Peut prendre : `0` _(Personne)_, `1` _(Mainteneurs)_, `2` _(Développeurs)_, `3` _(Administrateurs)_ ou `4` _(Propriétaires)_. |
| `default_project_visibility`             | string           | non                                   | Quel niveau de visibilité reçoivent les nouveaux projets. Peut prendre `private`, `internal` et `public` comme paramètre. La valeur par défaut est `private`. [Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203) dans GitLab 16.4 : ne peut pas être défini sur des niveaux présents dans `restricted_visibility_levels`.|
| `default_projects_limit`                 | integer          | non                                   | Limite de projets par utilisateur. La valeur par défaut est `100000`. |
| `default_snippet_visibility`             | string           | non                                   | Quel niveau de visibilité reçoivent les nouveaux extraits de code. Peut prendre `private`, `internal` et `public` comme paramètre. La valeur par défaut est `private`. |
| `default_syntax_highlighting_theme`      | integer          | non                                   | Thème de coloration syntaxique par défaut pour les nouveaux utilisateurs ou les utilisateurs non connectés. Voir [les identifiants des thèmes disponibles](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16). |
| `default_dark_syntax_highlighting_theme` | integer          | non                                   | Thème de coloration syntaxique en mode sombre par défaut pour les nouveaux utilisateurs ou les utilisateurs non connectés. Voir [les identifiants des thèmes disponibles](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/themes.rb#L16). |
| `default_project_deletion_protection`    | boolean          | non                                   | Activer la protection par défaut contre la suppression de projets afin que seuls les administrateurs puissent supprimer des projets. La valeur par défaut est `false`. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `delete_unconfirmed_users`               | boolean          | non                                   | Indique si les utilisateurs n'ayant pas confirmé leur adresse e-mail doivent être supprimés. La valeur par défaut est `false`. Lorsque défini sur `true`, les utilisateurs non confirmés sont supprimés après `unconfirmed_users_delete_after_days` jours. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352514) dans GitLab 16.1. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `deletion_adjourned_period`              | integer          | non                                   | Nombre de jours à attendre avant de supprimer un projet ou un groupe marqué pour suppression. La valeur doit être comprise entre `1` et `90`. La valeur par défaut est `30`. |
| `description_and_note_max_size`          | integer          | non                                   | Taille maximale en octets du contenu des descriptions et commentaires des éléments de travail, merge requests et vulnérabilités. La valeur par défaut est `1048576`. |
| `diagramsnet_enabled`                    | boolean          | non                                   | (Si activé, requiert `diagramsnet_url`) Activer l'[intégration Diagrams.net](../administration/integration/diagrams_net.md). La valeur par défaut est `true`. |
| `diagramsnet_url`                        | string           | requis par : `diagramsnet_enabled`   | L'URL de l'instance Diagrams.net pour l'intégration. |
| `diff_max_patch_bytes`                   | integer          | non                                   | Taille maximale du [patch de diff](../administration/diff_limits.md), en octets. |
| `diff_max_files`                         | integer          | non                                   | Nombre maximum de [fichiers dans un diff](../administration/diff_limits.md). |
| `diff_max_lines`                         | integer          | non                                   | Nombre maximum de [lignes dans un diff](../administration/diff_limits.md). |
| `diff_max_versions`                      | integer          | non                                   | Nombre maximum de [versions de diff](../administration/diff_limits.md) par merge request. |
| `diff_max_commits`                       | integer          | non                                   | Nombre maximum de [commits de diff](../administration/diff_limits.md) par merge request. |
| `disable_admin_oauth_scopes`             | boolean          | non                                   | Empêche les administrateurs de connecter leurs comptes GitLab à des applications OAuth 2.0 non fiables ayant les portées `api`, `read_api`, `read_repository`, `write_repository`, `read_registry`, `write_registry` ou `sudo`. |
| `disable_feed_token`                     | boolean          | non                                   | Désactiver l'affichage des jetons de flux RSS/Atom et de calendrier. |
| `disable_personal_access_tokens`         | boolean          | non                                   | Désactiver les jetons d'accès personnels. GitLab Self-Managed, Premium et Ultimate uniquement. Il n'existe aucune méthode disponible pour activer un jeton d'accès personnel qui a été désactivé via l'API. Il s'agit d'un [problème connu](https://gitlab.com/gitlab-org/gitlab/-/issues/399233). Pour plus d'informations sur les solutions de contournement disponibles, voir [Solution de contournement](https://gitlab.com/gitlab-org/gitlab/-/issues/399233#workaround).     |
| `disabled_oauth_sign_in_sources`         | tableau de chaînes de caractères | non                                   | Sources de connexion OAuth désactivées. |
| `disable_password_authentication_for_users_with_sso_identities` | boolean | non                     | Désactiver l'authentification par mot de passe dans l'interface web pour les utilisateurs disposant d'une identité SSO. Cela n'affecte pas les opérations Git via HTTP(S). La valeur par défaut est `false`. |
| `dns_rebinding_protection_enabled`       | boolean          | non                                   | Appliquer la protection contre les attaques de DNS rebinding. |
| `domain_denylist_enabled`                | boolean          | non                                   | (**Si activé, nécessite** : `domain_denylist`) Vous permet de bloquer les nouveaux comptes utilisateurs avec des e-mails de domaines spécifiques. |
| `domain_denylist`                        | tableau de chaînes de caractères | non                                   | Les utilisateurs dont les adresses e-mail correspondent à ces domaines **ne peut pas** s'inscrire. Les caractères génériques sont autorisés. Saisissez plusieurs entrées sur des lignes séparées. Par exemple : `domain.com`, `*.domain.com`. |
| `domain_allowlist`                       | tableau de chaînes de caractères | non                                   | Forcer les utilisateurs à utiliser uniquement des e-mails professionnels lors de la création de comptes. La valeur par défaut est `null`, ce qui signifie qu'il n'y a aucune restriction. |
| `downstream_pipeline_trigger_limit_per_project_user_sha` | integer | non                            | [Taux maximum de déclenchement de pipeline downstream](../administration/cicd/limits.md#limit-downstream-pipeline-trigger-rate). Par défaut : `0` (aucune restriction). [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144077) dans GitLab 16.10. |
| `dsa_key_restriction`                    | integer          | non                                   | La longueur de bits minimale autorisée d'une clé DSA téléchargée. La valeur par défaut est `0` (aucune restriction). `-1` désactive les clés DSA. |
| `ecdsa_key_restriction`                  | integer          | non                                   | La taille de courbe minimale autorisée (en bits) d'une clé ECDSA téléchargée. La valeur par défaut est `0` (aucune restriction). `-1` désactive les clés ECDSA. |
| `ecdsa_sk_key_restriction`               | integer          | non                                   | La taille de courbe minimale autorisée (en bits) d'une clé ECDSA_SK téléchargée. La valeur par défaut est `0` (aucune restriction). `-1` désactive les clés ECDSA_SK. |
| `ed25519_key_restriction`                | integer          | non                                   | La taille de courbe minimale autorisée (en bits) d'une clé ED25519 téléchargée. La valeur par défaut est `0` (aucune restriction). `-1` désactive les clés ED25519. |
| `ed25519_sk_key_restriction`             | integer          | non                                   | La taille de courbe minimale autorisée (en bits) d'une clé ED25519_SK téléchargée. La valeur par défaut est `0` (aucune restriction). `-1` désactive les clés ED25519_SK. |
| `eks_access_key_id`                      | string           | non                                   | ID de clé d'accès AWS IAM. |
| `eks_account_id`                         | string           | non                                   | ID de compte Amazon. |
| `eks_integration_enabled`                | boolean          | non                                   | Activer l'intégration avec Amazon EKS. |
| `eks_secret_access_key`                  | string           | non                                   | Clé d'accès secrète AWS IAM. |
| `elasticsearch_aws_access_key`           | string           | non                                   | Clé d'accès AWS IAM. Premium et Ultimate uniquement. |
| `elasticsearch_aws_region`               | string           | non                                   | La région AWS dans laquelle le domaine Elasticsearch est configuré. Premium et Ultimate uniquement. |
| `elasticsearch_aws_secret_access_key`    | string           | non                                   | Clé d'accès secrète AWS IAM. Premium et Ultimate uniquement. |
| `elasticsearch_aws`                      | boolean          | non                                   | Activer l'utilisation d'Elasticsearch hébergé par AWS. Premium et Ultimate uniquement. |
| `elasticsearch_client_adapter`           | string           | non                                   | L'adaptateur Faraday utilisé par le client Ruby Elasticsearch. La valeur par défaut est `typhoeus`. Les valeurs possibles sont `typhoeus` et `net_http`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/550805) dans GitLab 18.5. Premium et Ultimate uniquement. |
| `elasticsearch_indexed_field_length_limit` | integer        | non                                   | Taille maximale des champs texte à indexer par Elasticsearch. La valeur 0 signifie aucune limite. Cela ne s'applique pas à l'indexation des dépôts et des wikis. Premium et Ultimate uniquement. |
| `elasticsearch_indexed_file_size_limit_kb` | integer        | non                                   | Taille maximale des fichiers de dépôt et wiki indexés par Elasticsearch. Premium et Ultimate uniquement. |
| `elasticsearch_indexing`                   | boolean        | non                                   | Activer l'indexation pour la recherche avancée. Premium et Ultimate uniquement. |
| `elasticsearch_requeue_workers`            | boolean        | non                                   | Activer la remise en file d'attente automatique des workers d'indexation. Cela améliore le débit d'indexation hors code en mettant des jobs Sidekiq en file d'attente jusqu'à ce que tous les documents soient traités. Premium et Ultimate uniquement. |
| `elasticsearch_limit_indexing`             | boolean        | non                                   | Limiter Elasticsearch à l'indexation de certains espaces de nommage et projets. Premium et Ultimate uniquement. |
| `elasticsearch_max_bulk_concurrency`       | integer        | non                                   | Concurrence maximale des requêtes en masse Elasticsearch par opération d'indexation. Cela s'applique uniquement aux opérations d'indexation de dépôt. Premium et Ultimate uniquement. |
| `elasticsearch_max_code_indexing_concurrency` | integer     | non                                   | Concurrence maximale des jobs en arrière-plan d'indexation de code Elasticsearch. Cela s'applique uniquement aux opérations d'indexation de dépôt. Premium et Ultimate uniquement. |
| `elasticsearch_worker_number_of_shards`    | integer        | non                                   | Nombre de fragments de worker d'indexation. Cela améliore le débit d'indexation hors code en mettant en file d'attente davantage de jobs Sidekiq parallèles. La valeur par défaut est `2`. Premium et Ultimate uniquement. |
| `elasticsearch_max_bulk_size_mb`           | integer        | non                                   | Taille maximale des requêtes d'indexation en masse Elasticsearch en Mo. Cela s'applique uniquement aux opérations d'indexation de dépôt. Premium et Ultimate uniquement. |
| `elasticsearch_namespace_ids`              | tableau d'entiers | non                                | Les espaces de nommage à indexer via Elasticsearch si `elasticsearch_limit_indexing` est activé. Premium et Ultimate uniquement. |
| `elasticsearch_project_ids`                | tableau d'entiers | non                                | Les projets à indexer via Elasticsearch si `elasticsearch_limit_indexing` est activé. Premium et Ultimate uniquement. |
| `elasticsearch_search`                     | boolean        | non                                   | Activer la recherche Elasticsearch. Premium et Ultimate uniquement. |
| `elasticsearch_url`                        | chaîne ou tableau de chaînes | non                       | L'URL à utiliser pour se connecter à Elasticsearch. Utilisez une liste séparée par des virgules ou un tableau pour prendre en charge le cluster (par exemple, `http://localhost:9200, http://localhost:9201` ou `["http://localhost:9200", "http://localhost:9201"]`). Premium et Ultimate uniquement. |
| `elasticsearch_username`                   | string         | non                                   | Le `username` de votre instance Elasticsearch. Premium et Ultimate uniquement. |
| `elasticsearch_password`                   | string         | non                                   | Le mot de passe de votre instance Elasticsearch. Premium et Ultimate uniquement. |
| `elasticsearch_prefix`                     | string         | non                                   | Préfixe personnalisé pour les noms d'index Elasticsearch. La valeur par défaut est `gitlab`. Doit comporter entre 1 et 100 caractères, ne contenir que des caractères alphanumériques minuscules, des tirets et des underscores, et ne peut pas commencer ou se terminer par un tiret ou un underscore. Premium et Ultimate uniquement. |
| `elasticsearch_retry_on_failure`           | integer        | non                                   | Nombre maximum de tentatives possibles pour les requêtes de recherche Elasticsearch. Premium et Ultimate uniquement. |
| `elasticsearch_shards`                     | entier ou objet | Oui, si `elasticsearch_replicas` est défini en tant qu'objet | Nombre de fragments pour les index Elasticsearch. Utilisez un entier pour définir la même valeur pour tous les index. Utilisez un objet pour définir des valeurs par index. Par exemple : `{"gitlab-production": 5, "gitlab-production-notes": 3}`. <br>Lorsque vous utilisez un objet, vous devez fournir `elasticsearch_shards` et `elasticsearch_replicas` pour chaque index. Si l'une des valeurs est manquante pour un index, cet index est ignoré. Premium et Ultimate uniquement. |
| `elasticsearch_replicas`                   | entier ou objet | Oui, si `elasticsearch_shards` est défini en tant qu'objet | Nombre de répliques pour les index Elasticsearch. Utilisez un entier pour définir la même valeur pour tous les index. Utilisez un objet pour définir des valeurs par index. Par exemple : `{"gitlab-production": 1, "gitlab-production-notes": 2}`. <br>Lorsque vous utilisez un objet, vous devez fournir `elasticsearch_shards` et `elasticsearch_replicas` pour chaque index. Si l'une des valeurs est manquante pour un index, cet index est ignoré. Premium et Ultimate uniquement. |
| `email_additional_text`                    | string         | non                                   | Texte supplémentaire ajouté au bas de chaque e-mail pour des raisons juridiques/d'audit/de conformité. Premium et Ultimate uniquement. |
| `email_author_in_body`                   | boolean          | non                                   | Certains serveurs de messagerie ne prennent pas en charge le remplacement du nom de l'expéditeur de l'e-mail. Activez cette option pour inclure à la place le nom de l'auteur du ticket, du merge request ou du commentaire dans le corps de l'e-mail. |
| `email_confirmation_setting`             | string           | non                                   | Indique si les utilisateurs doivent confirmer leur adresse e-mail avant de se connecter. Les valeurs possibles sont `off`, `soft` et `hard`. |
| `email_otp_enabled`                      | boolean          | non                                   | Activer les mots de passe à usage unique (OTP) par e-mail comme méthode d'authentification multifacteur. Désactivé par défaut. Requiert que `require_email_verification_on_account_locked` soit `true`. |
| `custom_http_clone_url_root`             | string           | non                                   | Définir une URL clone Git personnalisée pour HTTP(S). |
| `enabled_git_access_protocol`            | string           | non                                   | Protocoles activés pour l'accès Git. Les valeurs autorisées sont : `ssh`, `http` et `all` pour autoriser les deux protocoles. La valeur `all` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/12944) dans GitLab 16.9. |
| `enforce_namespace_storage_limit`        | boolean          | non                                   | L'activation de ce paramètre permet l'application des limites de stockage de l'espace de nommage. |
| `enforce_terms`                          | boolean          | non                                   | (**Si activé, nécessite** : `terms`) Appliquer les conditions d'utilisation de l'application à tous les utilisateurs. |
| `external_auth_client_cert`              | string           | non                                   | (**Si activé, nécessite** : `external_auth_client_key`) Le certificat à utiliser pour s'authentifier auprès du service d'autorisation externe. |
| `external_auth_client_key_pass`          | string           | non                                   | Phrase secrète à utiliser pour la clé privée lors de l'authentification auprès du service externe ; elle est chiffrée lors du stockage. |
| `external_auth_client_key`               | string           | requis par : `external_auth_client_cert` | Clé privée pour le certificat lorsque l'authentification est requise pour le service d'autorisation externe ; elle est chiffrée lors du stockage. |
| `external_authorization_service_default_label` | string     | requis par :<br>`external_authorization_service_enabled` | Le libellé de classification par défaut à utiliser lors d'une demande d'autorisation lorsqu'aucun libellé de classification n'a été spécifié sur le projet. |
| `external_authorization_service_enabled`       | boolean    | non                                   | (**Si activé, nécessite** : `external_authorization_service_default_label`, `external_authorization_service_timeout` et `external_authorization_service_url`) Activer l'utilisation d'un service d'autorisation externe pour accéder aux projets. |
| `external_authorization_service_timeout`       | flottant      | requis par :<br>`external_authorization_service_enabled` | Le délai au bout duquel une demande d'autorisation est abandonnée, en secondes. Lorsqu'une demande expire, l'accès est refusé à l'utilisateur. (min :  0,001, max : 10, pas : 0,001). |
| `external_authorization_service_url`           | string     | requis par :<br>`external_authorization_service_enabled` | URL vers laquelle les demandes d'autorisation sont dirigées. |
| `external_pipeline_validation_service_url`     | string     | non                                   | URL à utiliser pour les demandes de validation de pipeline. |
| `external_pipeline_validation_service_token`   | string     | non                                   | Facultatif. Jeton à inclure comme en-tête `X-Gitlab-Token` dans les requêtes vers l'URL dans `external_pipeline_validation_service_url`. |
| `external_pipeline_validation_service_timeout` | integer    | non                                   | Durée d'attente d'une réponse du service de validation de pipeline. Suppose `OK` en cas d'expiration du délai. |
| `static_objects_external_storage_url`        | string       | non                                   | URL vers un stockage externe pour les objets statiques du dépôt. |
| `static_objects_external_storage_auth_token` | string       | requis par : `static_objects_external_storage_url` | Jeton d'authentification pour le stockage externe lié dans `static_objects_external_storage_url`. |
| `failed_login_attempts_unlock_period_in_minutes` | integer  | non                                   | Période de temps en minutes après laquelle l'utilisateur est déverrouillé lorsque le nombre maximum de tentatives de connexion échouées est atteint. |
| `file_template_project_id`               | integer          | non                                   | L'identifiant d'un projet à partir duquel charger des modèles de fichiers personnalisés. Premium et Ultimate uniquement. |
| `first_day_of_week`                      | integer          | non                                   | Premier jour de la semaine pour les vues de calendrier et les sélecteurs de date. Les valeurs valides sont `0` (par défaut) pour dimanche, `1` pour lundi et `6` pour samedi. |
| `globally_allowed_ips`                   | string           | non                                   | Liste d'adresses IP et de CIDRs séparés par des virgules, toujours autorisés pour le trafic entrant. Par exemple, `1.1.1.1, 2.2.2.0/24`. |
| `geo_node_allowed_ips`                   | string           | oui                                  | Liste d'adresses IP et de CIDRs des nœuds secondaires autorisés, séparés par des virgules. Par exemple, `1.1.1.1, 2.2.2.0/24`. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `geo_status_timeout`                     | integer          | non                                   | Le nombre de secondes après lesquelles une demande d'obtention du statut d'un nœud secondaire expire. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `git_two_factor_session_expiry`          | integer          | non                                   | Durée maximale (en minutes) d'une session pour les opérations Git lorsque la 2FA est activée. Premium et Ultimate uniquement. |
| `gitaly_timeout_default`                 | integer          | non                                   | Délai d'attente Gitaly par défaut, en secondes. Ce délai d'attente n'est pas appliqué aux opérations Git fetch/push ni aux jobs Sidekiq. Définir sur `0` pour désactiver les délais d'attente. |
| `gitaly_timeout_fast`                    | integer          | non                                   | Délai d'attente des opérations rapides Gitaly, en secondes. Certaines opérations Gitaly sont censées être rapides. Si elles dépassent ce seuil, il peut y avoir un problème avec un shard de stockage et « l'échec rapide » peut aider à maintenir la stabilité de l'instance GitLab. Définir sur `0` pour désactiver les délais d'attente. |
| `gitaly_timeout_medium`                  | integer          | non                                   | Délai d'attente Gitaly moyen, en secondes. Cette valeur doit être comprise entre le délai rapide et le délai par défaut. Définir sur `0` pour désactiver les délais d'attente. |
| `gitlab_dedicated_instance`              | boolean          | non                                   | Indique si l'instance a été provisionnée pour GitLab Dedicated. |
| `gitlab_environment_toolkit_instance`    | boolean          | non                                   | Indique si l'instance a été provisionnée avec le GitLab Environment Toolkit pour le reporting Service Ping. |
| `gitlab_shell_operation_limit`           | integer          | non                                   | Nombre maximum d'opérations Git par minute qu'un utilisateur peut effectuer. Par défaut : `600`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/412088) dans GitLab 16.2. |
| `grafana_enabled`                        | boolean          | non                                   | Activer Grafana. |
| `grafana_url`                            | string           | non                                   | URL Grafana. |
| `gravatar_enabled`                       | boolean          | non                                   | Activer Gravatar. |
| `group_owners_can_manage_default_branch_protection` | boolean | non                                 | Empêcher les remplacements de la protection de la branche par défaut. GitLab Self-Managed, Premium et Ultimate uniquement.|
| `hashed_storage_enabled`                 | boolean          | non                                   | Créer de nouveaux projets en utilisant des chemins de stockage hachés :  Activer des chemins immuables basés sur des hachages et des noms de dépôt pour stocker les dépôts sur le disque. Cela évite que les dépôts aient à être déplacés ou renommés lorsque l'URL du projet change et peut améliorer les performances d'E/S du disque. (Toujours activé dans les versions 13.0 et ultérieures de GitLab, la configuration est prévue pour être supprimée dans la version 14.0) |
| `help_page_hide_commercial_content`      | boolean          | non                                   | Masquer les entrées liées au marketing dans l'aide. |
| `help_page_support_url`                  | string           | non                                   | URL d'assistance alternative pour la page d'aide et la liste déroulante d'aide. |
| `help_page_documentation_base_url`       | string           | non                                   | URL alternative des pages de documentation. |
| `help_page_text`                         | string           | non                                   | Texte personnalisé affiché sur la page d'aide. |
| `hide_third_party_offers`                | boolean          | non                                   | Ne pas afficher les offres de tiers dans GitLab. |
| `home_page_url`                          | string           | non                                   | Rediriger vers cette URL lorsque l'utilisateur n'est pas connecté. |
| `housekeeping_bitmaps_enabled`           | boolean          | non                                   | Déprécié. La création de bitmaps de packfiles Git est toujours activée et ne peut pas être modifiée via l'API et l'interface utilisateur. Retourne toujours `true`. |
| `housekeeping_enabled`                   | boolean          | non                                   | Activer ou désactiver la maintenance Git. Des champs supplémentaires doivent être définis. |
| `housekeeping_full_repack_period`        | integer          | non                                   | Déprécié. Nombre de pushs Git après lesquels un `git repack` incrémental est exécuté. Utilisez plutôt `housekeeping_optimize_repository_period`. |
| `housekeeping_gc_period`                 | integer          | non                                   | Déprécié. Nombre de pushs Git après lesquels `git gc` est exécuté. Utilisez plutôt `housekeeping_optimize_repository_period`. |
| `housekeeping_incremental_repack_period` | integer          | non                                   | Déprécié. Nombre de pushs Git après lesquels un `git repack` incrémental est exécuté. Utilisez plutôt `housekeeping_optimize_repository_period`. |
| `housekeeping_optimize_repository_period`| integer          | non                                   | Nombre de pushs Git après lesquels un `git repack` incrémental est exécuté. |
| `html_emails_enabled`                    | boolean          | non                                   | Activer les e-mails HTML. |
| `import_sources`                         | tableau de chaînes de caractères | non                                   | Sources à autoriser pour l'importation de projets, valeurs possibles : `github`, `bitbucket`, `bitbucket_server`, `fogbugz`, `git`, `gitlab_project`, `gitea` et `manifest`. |
| `invisible_captcha_enabled`              | boolean          | non                                   | Activer la détection de spam par CAPTCHA invisible lors de la création de compte. Désactivé par défaut. |
| `issues_create_limit`                    | integer          | non                                   | Nombre maximum de demandes de création de tickets par minute et par utilisateur. Désactivé par défaut.|
| `jira_connect_application_key`           | string           | non                                   | ID de l'application OAuth utilisée pour s'authentifier avec l'application GitLab for Jira Cloud. |
| `jira_connect_public_key_storage_enabled` | boolean         | non                                   | Activer le stockage de clés publiques pour l'application GitLab for Jira Cloud. |
| `jira_connect_proxy_url`                 | string           | non                                   | URL de l'instance GitLab utilisée comme proxy pour l'application GitLab for Jira Cloud. |
| `keep_latest_artifact`                   | boolean          | non                                   | Empêcher la suppression des artefacts des jobs réussis les plus récents, quelle que soit la date d'expiration. Activé par défaut. |
| `local_markdown_version`                 | integer          | non                                   | Augmenter cette valeur lorsque tout Markdown mis en cache doit être invalidé. |
| `lock_memberships_to_saml`               | boolean          | non                                   | Appliquer un [verrou global sur les appartenances aux groupes SAML](../user/group/saml_sso/group_sync.md#global-saml-group-memberships-lock). |
| `mailgun_signing_key`                    | string           | non                                   | La clé de signature du webhook HTTP Mailgun pour la réception d'événements depuis le webhook. |
| `mailgun_events_enabled`                 | boolean          | non                                   | Activer le récepteur d'événements Mailgun. |
| `maintenance_mode_message`               | string           | non                                   | Message affiché lorsque l'instance est en mode maintenance. Premium et Ultimate uniquement. |
| `maintenance_mode`                       | boolean          | non                                   | Lorsque l'instance est en mode maintenance, les utilisateurs non-administrateurs peuvent se connecter avec un accès en lecture seule et effectuer des requêtes API en lecture seule. Premium et Ultimate uniquement. |
| `max_artifacts_size`                     | integer          | non                                   | Taille maximale des artefacts en Mo. |
| `max_attachment_size`                    | integer          | non                                   | Limiter la taille des pièces jointes en Mo. |
| `max_decompressed_archive_size`          | integer          | non                                   | Taille maximale des fichiers décompressés pour les archives importées en Mo. Définir sur `0` pour illimité. La valeur par défaut est `25600`. |
| `max_export_size`                        | integer          | non                                   | Taille maximale d'export en Mo. 0 pour illimité. Valeur par défaut = 0 (illimité). |
| `max_github_response_size_limit`         | integer          | non                                   | Taille maximale autorisée de la réponse de l'API GitHub en Mo. 0 pour illimité. |
| `max_github_response_json_value_count`   | integer          | non                                   | Nombre maximum de valeurs autorisées pour les réponses de l'API GitHub. 0 pour illimité. Le nombre est une estimation basée sur le nombre d'occurrences de `:`, `,`, `{` et `[` dans la réponse. |
| `max_http_decompressed_size`             | integer          | non                                   | Taille maximale autorisée en Mio pour les réponses HTTP compressées par Gzip provenant de requêtes sortantes après décompression. 0 pour illimité. |
| `max_http_response_json_depth`           | integer          | non                                   | Profondeur d'imbrication maximale autorisée dans les réponses HTTP JSON provenant de requêtes sortantes. |
| `max_http_response_json_structural_chars` | integer         | non                                   | Nombre maximum d'objets autorisés dans les réponses HTTP JSON provenant de requêtes sortantes. Le nombre est une estimation basée sur le nombre d'occurrences de `:`, `,`, `{` et `[` dans la réponse. Introduit dans GitLab 18.4. |
| `max_http_response_xml_structural_chars` | integer          | non                                   | Nombre maximum d'objets autorisés dans les réponses HTTP XML provenant de requêtes sortantes. Le nombre est une estimation basée sur le nombre d'occurrences de `<` et `=` dans la réponse. Introduit dans GitLab 18.4. |
| `max_http_response_csv_structural_chars` | integer          | non                                   | Nombre maximum d'objets autorisés dans les réponses HTTP CSV provenant de requêtes sortantes. Le nombre est une estimation basée sur le nombre d'occurrences de `,`, `;`, `\t` et `\n` dans la réponse. Introduit dans GitLab 18.4. |
| `max_http_response_size_limit`           | integer          | non                                   | Taille maximale autorisée en Mio pour les réponses HTTP provenant de requêtes sortantes. 0 pour illimité. Applicable aux intégrations, importateurs et webhooks. Introduit dans GitLab 18.4. |
| `max_import_size`                        | integer          | non                                   | Taille maximale d'import en Mo. 0 pour illimité. Valeur par défaut = 0 (illimité). |
| `max_import_remote_file_size`            | integer          | non                                   | Taille maximale des fichiers distants pour les imports depuis des stockages d'objets externes. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/384976) dans GitLab 16.3. |
| `max_login_attempts`                     | integer          | non                                   | Nombre maximum de tentatives de connexion avant de verrouiller l'utilisateur. |
| `max_pages_size`                         | integer          | non                                   | Taille maximale des dépôts de pages en Mo. |
| `max_personal_access_token_lifetime`     | integer          | non                                   | Durée de vie maximale autorisée pour les jetons d'accès en jours. Si laissé vide, la valeur par défaut de 365 est appliquée. Si défini, la valeur doit être inférieure ou égale à 365. En cas de modification, les jetons d'accès existants dont la date d'expiration dépasse la durée de vie maximale autorisée sont révoqués. GitLab Self-Managed, Ultimate uniquement. Dans GitLab 17.6 ou version ultérieure, la limite de durée de vie maximale peut être [étendue à 400 jours](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) en activant un [feature flag](../administration/feature_flags/_index.md) nommé `buffered_token_expiration_limit`.|
| `max_ssh_key_lifetime`                   | integer          | non                                   | Durée de vie maximale autorisée pour les clés SSH en jours. GitLab Self-Managed, Ultimate uniquement. Dans GitLab 17.6 ou version ultérieure, la limite de durée de vie maximale peut être [étendue à 400 jours](https://gitlab.com/gitlab-org/gitlab/-/issues/461901) en activant un [feature flag](../administration/feature_flags/_index.md) nommé `buffered_token_expiration_limit`.|
| `max_terraform_state_size_bytes`         | integer          | non                                   | Taille maximale en octets des fichiers d'[état Terraform](../administration/terraform_state.md). Définir sur 0 pour une taille de fichier illimitée. |
| `metrics_method_call_threshold`          | integer          | non                                   | Un appel de méthode n'est suivi que lorsqu'il prend plus longtemps que le nombre de millisecondes indiqué. |
| `max_number_of_repository_downloads`     | integer          | non                                   | Nombre maximum de dépôts uniques qu'un utilisateur peut télécharger dans la période spécifiée avant d'être banni. Par défaut : 0, Maximum : 10 000 dépôts. GitLab Self-Managed, Ultimate uniquement. |
| `max_number_of_repository_downloads_within_time_period` | integer | non                             | Période de rapport (en secondes). Par défaut : 0, Maximum : 864 000 secondes (10 jours). GitLab Self-Managed, Ultimate uniquement. |
| `max_yaml_depth`                         | integer          | non                                   | La profondeur maximale de la configuration CI/CD imbriquée ajoutée avec le [mot-clé `include`](../ci/yaml/_index.md#include). Par défaut : `100`. |
| `max_yaml_size_bytes`                    | integer          | non                                   | La taille maximale en octets d'un seul fichier de configuration CI/CD. Par défaut : `2097152`. |
| `git_rate_limit_users_allowlist`         | tableau de chaînes de caractères  | non                                  | Liste des noms d'utilisateurs exclus des limites de débit anti-abus Git. Par défaut : `[]`, Maximum : 100 noms d'utilisateurs. GitLab Self-Managed, Ultimate uniquement. |
| `git_rate_limit_users_alertlist`         | tableau d'entiers | non                                  | Liste des ID d'utilisateurs qui reçoivent un e-mail lorsque la limite de débit d'abus Git est dépassée. Par défaut : `[]`, Maximum : 100 ID d'utilisateurs. GitLab Self-Managed, Ultimate uniquement. |
| `auto_ban_user_on_excessive_projects_download` | boolean    | non                                   | Lorsqu'activé, les utilisateurs sont automatiquement bannis de l'application lorsqu'ils téléchargent plus que le nombre maximum de projets uniques dans la période spécifiée par `max_number_of_repository_downloads` et `max_number_of_repository_downloads_within_time_period`. GitLab Self-Managed, Ultimate uniquement. |
| `mirror_available`                       | boolean          | non                                   | Autoriser la mise en miroir des dépôts à être configurée par les Maintainers du projet. Si désactivé, seuls les administrateurs peuvent configurer la mise en miroir des dépôts. |
| `mirror_capacity_threshold`              | integer          | non                                   | Capacité minimale à maintenir disponible avant de planifier davantage de miroirs de manière préemptive. Premium et Ultimate uniquement. |
| `mirror_max_capacity`                    | integer          | non                                   | Nombre maximum de miroirs pouvant se synchroniser simultanément. Premium et Ultimate uniquement. |
| `mirror_max_delay`                       | integer          | non                                   | Temps maximum (en minutes) entre les mises à jour qu'un miroir peut avoir lorsqu'il est planifié pour la synchronisation. Premium et Ultimate uniquement. |
| `maven_package_requests_forwarding`      | boolean          | non                                   | Utiliser repo.maven.apache.org comme dépôt distant par défaut lorsque le paquet n'est pas trouvé dans le registre de paquets GitLab pour Maven. Premium et Ultimate uniquement. |
| `npm_package_requests_forwarding`        | boolean          | non                                   | Utiliser npmjs.org comme dépôt distant par défaut lorsque le paquet n'est pas trouvé dans le registre de paquets GitLab pour npm. Premium et Ultimate uniquement. |
| `pypi_package_requests_forwarding`       | boolean          | non                                   | Utiliser pypi.org comme dépôt distant par défaut lorsque le paquet n'est pas trouvé dans le registre de paquets GitLab pour PyPI. Premium et Ultimate uniquement. |
| `outbound_local_requests_whitelist`      | tableau de chaînes de caractères | non                                   | Définir une liste de domaines ou d'adresses IP de confiance vers lesquels les requêtes locales sont autorisées lorsque les requêtes locales pour les webhooks et les intégrations sont désactivées. Actuellement, cet attribut ne peut pas être mis à jour. Pour plus de détails, voir [ticket 569729](https://gitlab.com/gitlab-org/gitlab/-/issues/569729). |
| `package_registry_allow_anyone_to_pull_option` | boolean    | non                                   | Activer pour rendre visible et modifiable le paramètre [autoriser n'importe qui à télécharger depuis le registre de paquets](../user/packages/package_registry/_index.md#allow-anyone-to-pull-from-package-registry). |
| `package_metadata_purl_types`            | tableau d'entiers | non                                  | Liste des [métadonnées du registre de paquets à synchroniser](../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync). Voir [la liste](https://gitlab.com/gitlab-org/gitlab/-/blob/ace16c20d5da7c4928dd03fb139692638b557fe3/app/models/concerns/enums/package_metadata.rb#L5) des valeurs disponibles. GitLab Self-Managed, Ultimate uniquement. |
| `pages_domain_verification_enabled`       | boolean         | non                                   | Exiger que les utilisateurs prouvent la propriété des domaines personnalisés. La vérification des domaines est une mesure de sécurité essentielle pour les sites GitLab publics. Les utilisateurs doivent démontrer qu'ils contrôlent un domaine avant qu'il soit activé. |
| `pages_unique_domain_default_enabled`    | boolean         | non                                   | Activer les domaines uniques par défaut pour les sites Pages afin d'éviter le partage de cookies entre les sites sous un espace de nommage donné. La valeur par défaut est `true`. |
| `password_authentication_enabled_for_git` | boolean         | non                                   | Activer l'authentification pour Git via HTTP(S) avec un mot de passe de compte GitLab. La valeur par défaut est `true`. |
| `password_authentication_enabled_for_web` | boolean         | non                                   | Activer l'authentification pour l'interface web via un mot de passe de compte GitLab. La valeur par défaut est `true`. |
| `minimum_password_length`                | integer          | non                                   | Indique si les mots de passe requièrent une longueur minimale. Premium et Ultimate uniquement. |
| `password_number_required`               | boolean          | non                                   | Indique si les mots de passe requièrent au moins un chiffre. Premium et Ultimate uniquement. |
| `password_symbol_required`               | boolean          | non                                   | Indique si les mots de passe requièrent au moins un caractère symbole. Premium et Ultimate uniquement. |
| `password_uppercase_required`            | boolean          | non                                   | Indique si les mots de passe requièrent au moins une lettre majuscule. Premium et Ultimate uniquement. |
| `password_lowercase_required`            | boolean          | non                                   | Indique si les mots de passe requièrent au moins une lettre minuscule. Premium et Ultimate uniquement. |
| `performance_bar_allowed_group_id`       | string           | non                                   | (Déprécié : Utiliser `performance_bar_allowed_group_path` à la place) Chemin du groupe autorisé à activer ou désactiver la barre de performance. |
| `performance_bar_allowed_group_path`     | string           | non                                   | Chemin du groupe autorisé à activer ou désactiver la barre de performance. |
| `performance_bar_enabled`                | boolean          | non                                   | (Déprécié : Passer `performance_bar_allowed_group_path: nil` à la place) Autoriser l'activation de la barre de performance. |
| `personal_access_token_prefix`           | string           | non                                   | Préfixe pour tous les jetons d'accès personnel générés. |
| `pipeline_limit_per_project_user_sha`    | integer          | non                                   | Nombre maximum de demandes de création de pipeline par minute par utilisateur et par commit. Désactivé par défaut. |
| `pipeline_limit_per_user`                | integer          | non                                   | Nombre maximum de demandes de création de pipeline par minute par utilisateur. |
| `gitpod_enabled`                         | boolean          | non                                   | (**Si activé, nécessite** : `gitpod_url`) Activer [l'intégration Ona](../integration/gitpod.md). La valeur par défaut est `false`. |
| `gitpod_url`                             | string           | requis par : `gitpod_enabled`        | L'URL de l'instance Ona pour l'intégration. |
| `inactive_resource_access_tokens_delete_after_days`| integer | non                                   | Spécifie la période de rétention pour les jetons d'accès inactifs de projet et de groupe. La valeur par défaut est `30`. |
| `kroki_enabled`                          | boolean          | non                                   | (**Si activé, nécessite** : `kroki_url`) Activer [l'intégration Kroki](../administration/integration/kroki.md). La valeur par défaut est `false`. |
| `kroki_url`                              | string           | requis par : `kroki_enabled`         | L'URL de l'instance Kroki pour l'intégration. |
| `kroki_formats`                          | objet           | non                                   | Formats supplémentaires pris en charge par l'instance Kroki. Les valeurs possibles sont `true` ou `false` pour les formats `bpmn`, `blockdiag`, `excalidraw` et `mermaid` dans le format `<format>: true` ou `<format>: false`. |
| `kroki_diagram_proxy_enabled`            | boolean          | non                                   | Activer le [proxy de diagrammes Kroki](../administration/integration/diagram_proxy.md). La valeur par défaut est `false`. |
| `plantuml_enabled`                       | boolean          | non                                   | (**Si activé, nécessite** : `plantuml_url`) Activer [l'intégration PlantUML](../administration/integration/plantuml.md). La valeur par défaut est `false`. |
| `plantuml_url`                           | string           | requis par : `plantuml_enabled`      | L'URL de l'instance PlantUML pour l'intégration. |
| `plantuml_diagram_proxy_enabled`         | boolean          | non                                   | Activer le [proxy de diagrammes PlantUML](../administration/integration/diagram_proxy.md). La valeur par défaut est `false`. |
| `polling_interval_multiplier`            | flottant            | non                                   | Multiplicateur d'intervalle utilisé par les points de terminaison qui effectuent une interrogation. Définir sur `0` pour désactiver l'interrogation. |
| `project_export_enabled`                 | boolean          | non                                   | Activer l'export de projet. |
| `project_jobs_api_rate_limit`            | integer          | non                                   | Nombre maximum de requêtes authentifiées vers `/project/:id/jobs` par minute. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129319) dans GitLab 16.5. Par défaut : 600\. |
| `projects_api_rate_limit_unauthenticated` | integer         | non                                   | Nombre maximum de requêtes par 10 minutes par adresse IP pour les requêtes non authentifiées vers l'[API de liste de tous les projets](projects.md#list-all-projects). Par défaut : 400\. Pour désactiver la limitation, définir sur 0.|
| `runner_jobs_request_api_limit`          | integer          | non                                   | Nombre maximum de requêtes par minute par jeton de runner pour les requêtes vers le point de terminaison de l'API des jobs de runner `/jobs/request`. Par défaut : 2000\. Pour désactiver la limitation, définir sur 0. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/462537) dans GitLab 18.5. |
| `runner_jobs_patch_trace_api_limit`      | integer          | non                                   | Nombre maximum de requêtes par minute par jeton de runner pour les requêtes vers le point de terminaison de l'API des jobs de runner `PATCH /jobs/:id/trace`. Par défaut : 2000\. Pour désactiver la limitation, définir sur 0. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/462537) dans GitLab 18.5. |
| `runner_jobs_endpoints_api_limit`        | integer          | non                                   | Nombre maximum de requêtes par minute par jeton de job pour les requêtes `/jobs/*` vers les points de terminaison de l'API des jobs de runner. Par défaut : 200\. Pour désactiver la limitation, définir sur 0. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/462537) dans GitLab 18.5. |
| `users_api_limit_following` | integer |    non    | Nombre maximum de requêtes par minute, par utilisateur ou adresse IP. Par défaut : 100\. Définir sur `0` pour désactiver les limites. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) dans GitLab 17.10. |
| `users_api_limit_followers` | integer |    non    | Nombre maximum de requêtes par minute, par utilisateur ou adresse IP. Par défaut : 100\. Définir sur `0` pour désactiver les limites. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) dans GitLab 17.10. |
| `users_api_limit_status`    | integer |    non    | Nombre maximum de requêtes par minute, par utilisateur ou adresse IP. Par défaut : 240\. Définir sur `0` pour désactiver les limites. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) dans GitLab 17.10. |
| `users_api_limit_keys`      | integer |    non    | Nombre maximum de requêtes par minute, par utilisateur ou adresse IP. Par défaut : 120\. Définir sur `0` pour désactiver les limites. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) dans GitLab 17.10. |
| `users_api_limit_key`       | integer |    non    | Nombre maximum de requêtes par minute, par utilisateur ou adresse IP. Par défaut : 120\. Définir sur `0` pour désactiver les limites. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) dans GitLab 17.10. |
| `users_api_limit_gpg_keys`  | integer |    non    | Nombre maximum de requêtes par minute, par utilisateur ou adresse IP. Par défaut : 120\. Définir sur `0` pour désactiver les limites. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) dans GitLab 17.10. |
| `users_api_limit_gpg_key`   | integer |    non    | Nombre maximum de requêtes par minute, par utilisateur ou adresse IP. Par défaut : 120\. Définir sur `0` pour désactiver les limites. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181054) dans GitLab 17.10. |
| `virtual_registries_endpoints_api_limit`          | integer          | non                                   | Nombre maximum de requêtes sur les points de terminaison des registres virtuels, par adresse IP, par tranche de 15 secondes. Par défaut : 4000\. Pour désactiver les limites, définir sur `0`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/521692) dans GitLab 17.11. |
| `project_secrets_limit`                           | integer          | non                                   | Nombre maximum de secrets autorisés par projet dans le Gestionnaire de secrets. Par défaut : 100\. Pour désactiver la limite, définir sur `0`. Ultimate uniquement. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219436) dans GitLab 18.9. |
| `group_secrets_limit`                             | integer          | non                                   | Nombre maximum de secrets autorisés par groupe dans le Gestionnaire de secrets. Par défaut : 500\. Pour désactiver la limite, définir sur `0`. Ultimate uniquement. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219436) dans GitLab 18.9. |
| `prometheus_metrics_enabled`             | boolean          | non                                   | Activer les métriques Prometheus. |
| `protected_ci_variables`                 | boolean          | non                                   | Les variables CI/CD sont protégées par défaut. |
| `disable_overriding_approvers_per_merge_request` | boolean  | non                                   | Empêcher la modification des règles d'approbation dans les projets et les merge requests |
| `prevent_merge_requests_author_approval`         | boolean  | non                                   | Empêcher l'approbation par le créateur (auteur) de la merge request |
| `prevent_merge_requests_committers_approval`     | boolean  | non                                   | Empêcher l'approbation par les contributeurs de la merge request |
| `push_event_activities_limit`            | integer          | non                                   | Nombre maximum de modifications (branches ou tags) dans un seul push au-delà duquel un [événement de push groupé est créé](../administration/settings/push_event_activities_limit.md). La valeur `0` ne désactive pas le limiteur de débit. |
| `push_event_hooks_limit`                 | integer          | non                                   | Nombre maximum de modifications (branches ou tags) dans un seul push au-delà duquel les webhooks et les intégrations ne sont pas déclenchés. La valeur `0` ne désactive pas le limiteur de débit. Par défaut : `3`. |
| `rate_limiting_response_text`            | string           | non                                   | Lorsque la limitation de débit est activée via les paramètres `throttle_*`, envoyer cette réponse en texte brut lorsqu'une limite de débit est dépassée. « Réessayez plus tard » est envoyé si ce champ est vide. |
| `raw_blob_request_limit`                 | integer          | non                                   | Nombre maximum de requêtes par minute pour chaque chemin brut (la valeur par défaut est `300`). Définir sur `0` pour désactiver la limitation de débit.|
| `raw_blob_request_limit_unauthenticated` | integer          | non                                   | Nombre maximum de requêtes non authentifiées par minute sur tous les chemins bruts d'un projet (la valeur par défaut est `800`). Définir sur `0` pour désactiver la limitation de débit.|
| `search_rate_limit`                      | integer          | non                                   | Nombre maximum de requêtes par minute pour effectuer une recherche en étant authentifié. Par défaut : 30\. Pour désactiver la limitation, définir sur 0.|
| `search_rate_limit_unauthenticated`      | integer          | non                                   | Nombre maximum de requêtes par minute pour effectuer une recherche sans être authentifié. Par défaut : 10\. Pour désactiver la limitation, définir sur 0.|
| `recaptcha_enabled`                      | boolean          | non                                   | (**Si activé, nécessite** : `recaptcha_private_key` et `recaptcha_site_key`) Activer reCAPTCHA. |
| `login_recaptcha_protection_enabled`     | boolean          | non                                   | Activer reCAPTCHA pour la connexion. |
| `recaptcha_private_key`                  | string           | requis par : `recaptcha_enabled`     | Clé privée pour reCAPTCHA. |
| `recaptcha_site_key`                     | string           | requis par : `recaptcha_enabled`     | Clé de site pour reCAPTCHA. |
| `receptive_cluster_agents_enabled`       | boolean          | non                                   | Activer le mode réceptif pour les agents GitLab pour Kubernetes. |
| `receive_max_input_size`                 | integer          | non                                   | Taille maximale des pushs (Mo). |
| `relation_export_batch_size`             | integer          | non                                   | La taille de chaque lot lors de l'exportation de relations par lots. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194607) dans GitLab 18.2. |
| `remember_me_enabled`                    | boolean          | non                                   | Activer le [paramètre **Se souvenir de moi**](../administration/settings/account_and_limit_settings.md#configure-the-remember-me-option). Introduit dans GitLab 16.0. |
| `repository_checks_enabled`              | boolean          | non                                   | GitLab exécute périodiquement `git fsck` dans tous les dépôts de projets et de wikis pour rechercher des problèmes silencieux de corruption de disque. |
| `repository_size_limit`                  | integer          | non                                   | Limite de taille par dépôt (Mo). Premium et Ultimate uniquement. |
| `repository_storages_weighted`           | table de correspondance de chaînes vers des entiers | non                        | Table de correspondance de noms tirés de `gitlab.yml` vers les [poids](../administration/repository_storage_paths.md#configure-where-new-repositories-are-stored). Les nouveaux projets sont créés dans l'un de ces espaces de stockage, choisi par une sélection aléatoire pondérée. |
| `require_admin_approval_after_user_signup` | boolean        | non                                   | Lorsque cette option est activée, tout utilisateur qui s'inscrit à un compte via le formulaire d'inscription est placé dans un état **En attente d'approbation** et doit être explicitement [approuvé](../administration/moderate_users.md) par un administrateur. |
| `require_email_verification_on_account_locked` | boolean    | non                                   | Si `true`, tous les utilisateurs de l'instance doivent vérifier leur identité après la détection d'une activité de connexion suspecte. |
| `require_personal_access_token_expiry`   | boolean          | non                                   | Lorsque cette option est activée, les utilisateurs doivent définir une date d'expiration lors de la création d'un jeton d'accès au projet ou de groupe, ou d'un jeton d'accès personnel appartenant à un compte non-service. |
| `require_two_factor_authentication`      | boolean          | non                                   | (**Si activé, nécessite** : `two_factor_grace_period`) Exiger que tous les utilisateurs configurent l'authentification à deux facteurs. |
| `resource_usage_limits`                | hash             | non                                   | Définition des limites d'utilisation des ressources appliquées dans les workers Sidekiq. Ce paramètre est disponible uniquement pour GitLab.com. |
| `restricted_visibility_levels`           | tableau de chaînes de caractères | non                                   | Les niveaux sélectionnés ne peuvent pas être utilisés par les utilisateurs non-administrateurs pour les groupes, les projets ou les snippets. Peut prendre `private`, `internal` et `public` comme paramètre. La valeur par défaut est `null`, ce qui signifie qu'il n'y a pas de restriction.[Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203) dans GitLab 16.4 : impossible de sélectionner des niveaux définis comme `default_project_visibility` et `default_group_visibility`. |
| `rsa_key_restriction`                    | integer          | non                                   | La longueur de bits minimale autorisée d'une clé RSA téléversée. La valeur par défaut est `0` (sans restriction). `-1` désactive les clés RSA. |
| `session_expire_delay`                   | integer          | non                                   | Durée de la session en minutes. Un redémarrage de GitLab est nécessaire pour appliquer les modifications. |
| `session_expire_from_init`               | boolean          | non                                   | Si `true`, les sessions expirent un certain nombre de minutes après la création de la session plutôt qu'après la dernière activité. La durée de vie d'une session est définie par `session_expire_delay`. |
| `security_policy_global_group_approvers_enabled` | boolean  | non                                   | Indique si les groupes d'approbation des politiques d'approbation des merge requests doivent être recherchés globalement ou au sein des hiérarchies de projets. |
| `security_approval_policies_limit`       | integer          | non                                   | Nombre maximum de politiques d'approbation de merge request actives par projet de politique de sécurité. Par défaut : 5\. Maximum : 20 |
| `scan_execution_policies_action_limit`   | integer          | non                                   | Nombre maximum de `actions` par politique d'exécution de scan. Par défaut : 0\. Maximum : 20 |
| `scan_execution_policies_schedule_limit` | integer          | non                                   | Nombre maximum de règles `type: schedule` par politique d'exécution de scan. Par défaut : 0\. Maximum : 20 |
| `security_txt_content`                    | string          | non                                   | [Informations de contact de sécurité publiques](../administration/settings/security_contact_information.md). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/433210) dans GitLab 16.7. |
| `security_mr_report_cache_lifetime_minutes` | integer       | non                                   | Nombre de minutes pour mettre en cache les rapports de sécurité sur les merge requests (10-60). Par défaut : 10\. Premium et Ultimate uniquement. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223399) dans GitLab 18.10. |
| `security_scan_stale_after_days`          | integer          | non                                   | Nombre de jours de conservation des données de scan de sécurité avant purge. Doit être compris entre 7 et 90 jours. Par défaut : 30 jours pour GitLab.com, 90 jours pour les instances auto-hébergées. Premium et Ultimate uniquement. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/222998) dans GitLab 18.9. |
| `service_access_tokens_expiration_enforced` | boolean       | non                                   | Indicateur indiquant si la date d'expiration du jeton peut être facultative pour les utilisateurs de compte de service |
| `shared_runners_enabled`                 | boolean          | non                                   | (**Si activé, nécessite** : `shared_runners_text` et `shared_runners_minutes`) Activer les runners d'instance pour les nouveaux projets. |
| `shared_runners_minutes`                 | integer          | requis par : `shared_runners_enabled` | Définir le nombre maximum de minutes de calcul qu'un groupe peut utiliser sur les runners d'instance par mois. Premium et Ultimate uniquement. |
| `shared_runners_text`                    | string           | requis par : `shared_runners_enabled` | Texte des runners d'instance. |
| `runner_token_expiration_interval`         | integer        | non                                   | Définir le délai d'expiration (en secondes) des jetons d'authentification des runners d'instance nouvellement enregistrés. La valeur minimale est 7200 secondes. Pour plus d'informations, voir [Rotation automatique des jetons d'authentification](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens). |
| `group_runner_token_expiration_interval`   | integer        | non                                   | Définir le délai d'expiration (en secondes) des jetons d'authentification des runners de groupe nouvellement enregistrés. La valeur minimale est 7200 secondes. Pour plus d'informations, voir [Rotation automatique des jetons d'authentification](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens). |
| `project_runner_token_expiration_interval` | integer        | non                                   | Définir le délai d'expiration (en secondes) des jetons d'authentification des runners de projet nouvellement enregistrés. La valeur minimale est 7200 secondes. Pour plus d'informations, voir [Rotation automatique des jetons d'authentification](../ci/runners/configure_runners.md#automatically-rotate-runner-authentication-tokens). |
| `sidekiq_job_limiter_mode`                        | string  | non                                   | `track` ou `compress`. Définit le comportement pour les [limites de taille des jobs Sidekiq](../administration/settings/sidekiq_job_limits.md). Par défaut : 'compress'. |
| `sidekiq_job_limiter_compression_threshold_bytes` | integer | non                                   | Le seuil en octets à partir duquel les jobs Sidekiq sont compressés avant d'être stockés dans Redis. Par défaut : 100 000 octets (100 Ko). |
| `sidekiq_job_limiter_limit_bytes`                 | integer | non                                   | Le seuil en octets à partir duquel les jobs Sidekiq sont rejetés. Par défaut : 0 octet (ne rejette aucun job). |
| `signin_enabled`                         | string           | non                                   | (Déprécié : Utiliser `password_authentication_enabled_for_web` à la place) Indicateur indiquant si l'authentification par mot de passe est activée pour l'interface web. |
| `sign_in_restrictions`                   | hash             | non                                   | Restrictions de connexion à l'application. |
| `signup_enabled`                         | boolean          | non                                   | Activer l'inscription. La valeur par défaut est `true`. |
| `silent_admin_exports_enabled`           | boolean          | non                                   | Activer les [exportations d'administration silencieuses](../administration/settings/import_and_export_settings.md#enable-silent-admin-exports). La valeur par défaut est `false`. |
| `silent_mode_enabled`                    | boolean          | non                                   | Activer le [mode silencieux](../administration/silent_mode/_index.md). La valeur par défaut est `false`. |
| `slack_app_enabled`                      | boolean          | non                                   | (**Si activé, nécessite** : `slack_app_id`, `slack_app_secret`, `slack_app_signing_secret` et `slack_app_verification_token`) Activer l'application GitLab pour Slack. |
| `slack_app_id`                           | string           | requis par : `slack_app_enabled`     | L'ID client de l'application GitLab pour Slack. |
| `slack_app_secret`                       | string           | requis par : `slack_app_enabled`     | Le secret client de l'application GitLab pour Slack. Utilisé pour authentifier les requêtes OAuth provenant de l'application. |
| `slack_app_signing_secret`               | string           | requis par : `slack_app_enabled`     | Le secret de signature de l'application GitLab pour Slack. Utilisé pour authentifier les requêtes API provenant de l'application. |
| `slack_app_verification_token`           | string           | requis par : `slack_app_enabled`     | Le jeton de vérification de l'application GitLab pour Slack. Cette méthode d'authentification est dépréciée par Slack et utilisée uniquement pour authentifier les commandes slash provenant de l'application. |
| `snippet_size_limit`                     | integer          | non                                   | Taille maximale du contenu des snippets en **octets**. Par défaut : 52428800 octets (50 Mo).|
| `snowplow_app_id`                        | string           | non                                   | Le nom de site / ID d'application Snowplow. (par exemple, `gitlab`) |
| `snowplow_collector_hostname`            | string           | requis par : `snowplow_enabled`      | Le nom d'hôte du collecteur Snowplow. (par exemple, `snowplowprd.trx.gitlab.net`) |
| `snowplow_database_collector_hostname`   | string           | non                                   | Le collecteur Snowplow pour le nom d'hôte des événements de base de données. (par exemple, `db-snowplow.trx.gitlab.net`) |
| `snowplow_cookie_domain`                 | string           | non                                   | Le domaine de cookie Snowplow. (par exemple, `.gitlab.com`) |
| `snowplow_enabled`                       | boolean          | non                                   | Activer le suivi Snowplow. |
| `sourcegraph_enabled`                    | boolean          | non                                   | Active l'intégration Sourcegraph. La valeur par défaut est `false`. **Si activé, nécessite** `sourcegraph_url`. |
| `sourcegraph_public_only`                | boolean          | non                                   | Empêche le chargement de Sourcegraph sur les projets privés et internes. La valeur par défaut est `true`. |
| `sourcegraph_url`                        | string           | requis par : `sourcegraph_enabled`   | L'URL de l'instance Sourcegraph pour l'intégration. |
| `spam_check_endpoint_enabled`            | boolean          | non                                   | Active la vérification anti-spam via un point de terminaison d'API Spam Check externe. La valeur par défaut est `false`. |
| `spam_check_endpoint_url`                | string           | non                                   | URL du point de terminaison du service Spamcheck externe. Les schémas d'URI valides sont `grpc` ou `tls`. Spécifier `tls` force le chiffrement des communications.|
| `spam_check_api_key`                     | string           | non                                   | Clé API utilisée par GitLab pour accéder au point de terminaison du service Spam Check. |
| `suggest_pipeline_enabled`               | boolean          | non                                   | Activer la bannière de suggestion de pipeline. |
| `enable_artifact_external_redirect_warning_page` | boolean  | non                                   | Afficher la page de redirection externe qui vous avertit du contenu généré par les utilisateurs dans GitLab Pages. |
| `terminal_max_session_time`              | integer          | non                                   | Durée maximale de la connexion WebSocket du terminal web (en secondes). Définir sur `0` pour une durée illimitée. |
| `terms`                                  | texte             | requis par : `enforce_terms`         | (**Requis par** : `enforce_terms`) Contenu Markdown pour les CGU. |
| `throttle_authenticated_api_enabled`                      | boolean | non                                                              | (**Si activé, nécessite** : `throttle_authenticated_api_period_in_seconds` et `throttle_authenticated_api_requests_per_period`) Activer la limite de débit des requêtes API authentifiées. Aide à réduire le volume de requêtes (par exemple, provenant de crawlers ou de bots malveillants). |
| `throttle_authenticated_api_period_in_seconds`            | integer | requis par :<br>`throttle_authenticated_api_enabled`            | Période de limitation de débit (en secondes). |
| `throttle_authenticated_api_requests_per_period`          | integer | requis par :<br>`throttle_authenticated_api_enabled`            | Nombre maximum de requêtes par période par utilisateur. |
| `throttle_authenticated_git_http_enabled`             | boolean | conditionnellement | Si `true`, applique la limite de débit des requêtes Git HTTP authentifiées. Valeur par défaut : `false`. |
| `throttle_authenticated_git_http_period_in_seconds`   | integer | non            | Période de limitation de débit en secondes. `throttle_authenticated_git_http_enabled` doit être `true`. Valeur par défaut : `3600`. |
| `throttle_authenticated_git_http_requests_per_period` | integer | non            | Nombre maximum de requêtes par période par utilisateur. `throttle_authenticated_git_http_enabled` doit être `true`. Valeur par défaut : `3600`. |
| `throttle_authenticated_packages_api_enabled`             | boolean | non                                                              | (**Si activé, nécessite** : `throttle_authenticated_packages_api_period_in_seconds` et `throttle_authenticated_packages_api_requests_per_period`) Activer la limite de débit des requêtes API authentifiées. Aide à réduire le volume de requêtes (par exemple, provenant de crawlers ou de bots malveillants). Consulter les [limites de débit du registre de paquets](../administration/settings/package_registry_rate_limits.md) pour plus de détails. |
| `throttle_authenticated_packages_api_period_in_seconds`   | integer | requis par :<br>`throttle_authenticated_packages_api_enabled`   | Période de limitation de débit (en secondes). Consulter les [limites de débit du registre de paquets](../administration/settings/package_registry_rate_limits.md) pour plus de détails. |
| `throttle_authenticated_packages_api_requests_per_period` | integer | requis par :<br>`throttle_authenticated_packages_api_enabled`   | Nombre maximum de requêtes par période par utilisateur. Consulter les [limites de débit du registre de paquets](../administration/settings/package_registry_rate_limits.md) pour plus de détails. |
| `throttle_authenticated_web_enabled`                      | boolean | non                                                              | (**Si activé, nécessite** : `throttle_authenticated_web_period_in_seconds` et `throttle_authenticated_web_requests_per_period`) Activer la limite de débit des requêtes web authentifiées. Aide à réduire le volume de requêtes (par exemple, provenant de crawlers ou de bots malveillants). |
| `throttle_authenticated_web_period_in_seconds`            | integer | requis par :<br>`throttle_authenticated_web_enabled`            | Période de limitation de débit (en secondes). |
| `throttle_authenticated_web_requests_per_period`          | integer | requis par :<br>`throttle_authenticated_web_enabled`            | Nombre maximum de requêtes par période par utilisateur. |
| `throttle_unauthenticated_enabled`                        | boolean | non                                                              | ([Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) dans GitLab 14.3. Utiliser `throttle_unauthenticated_web_enabled` ou `throttle_unauthenticated_api_enabled` à la place.) (**Si activé, nécessite** : `throttle_unauthenticated_period_in_seconds` et `throttle_unauthenticated_requests_per_period`) Activer la limite de débit des requêtes web non authentifiées. Aide à réduire le volume de requêtes (par exemple, provenant de crawlers ou de bots malveillants). |
| `throttle_unauthenticated_period_in_seconds`              | integer | requis par :<br>`throttle_unauthenticated_enabled`              | ([Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) dans GitLab 14.3. Utiliser `throttle_unauthenticated_web_period_in_seconds` ou `throttle_unauthenticated_api_period_in_seconds` à la place.) Période de limitation de débit en secondes. |
| `throttle_unauthenticated_requests_per_period`            | integer | requis par :<br>`throttle_unauthenticated_enabled`              | ([Déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) dans GitLab 14.3. Utiliser `throttle_unauthenticated_web_requests_per_period` ou `throttle_unauthenticated_api_requests_per_period` à la place.) Nombre maximum de requêtes par période par IP. |
| `throttle_unauthenticated_api_enabled`                    | boolean | non                                                              | (**Si activé, nécessite** : `throttle_unauthenticated_api_period_in_seconds` et `throttle_unauthenticated_api_requests_per_period`) Activer la limite de débit des requêtes API non authentifiées. Aide à réduire le volume de requêtes (par exemple, provenant de crawlers ou de bots malveillants). |
| `throttle_unauthenticated_api_period_in_seconds`          | integer | requis par :<br>`throttle_unauthenticated_api_enabled`          | Période de limitation de débit en secondes. |
| `throttle_unauthenticated_api_requests_per_period`        | integer | requis par :<br>`throttle_unauthenticated_api_enabled`          | Nombre maximum de requêtes par période par IP. |
| `throttle_unauthenticated_git_http_enabled`             | boolean | conditionnellement | Si `true`, applique la limite de débit des requêtes Git HTTP non authentifiées. Valeur par défaut : `false`. |
| `throttle_unauthenticated_git_http_period_in_seconds`   | integer | non            | Période de limitation de débit en secondes. `throttle_unauthenticated_git_http_enabled` doit être `true`. Valeur par défaut : `3600`. |
| `throttle_unauthenticated_git_http_requests_per_period` | integer | non            | Nombre maximum de requêtes par période par IP. `throttle_unauthenticated_git_http_enabled` doit être `true`. Valeur par défaut : `3600`. |
| `throttle_unauthenticated_packages_api_enabled`           | boolean | non                                                              | (**Si activé, nécessite** : `throttle_unauthenticated_packages_api_period_in_seconds` et `throttle_unauthenticated_packages_api_requests_per_period`) Activer la limite de débit des requêtes API non authentifiées. Aide à réduire le volume de requêtes (par exemple, provenant de crawlers ou de bots malveillants). Consulter les [limites de débit du registre de paquets](../administration/settings/package_registry_rate_limits.md) pour plus de détails. |
| `throttle_unauthenticated_packages_api_period_in_seconds` | integer | requis par :<br>`throttle_unauthenticated_packages_api_enabled` | Période de limitation de débit (en secondes). Consulter les [limites de débit du registre de paquets](../administration/settings/package_registry_rate_limits.md) pour plus de détails. |
| `throttle_unauthenticated_packages_api_requests_per_period` | integer | requis par :<br>`throttle_unauthenticated_packages_api_enabled` | Nombre maximum de requêtes par période par utilisateur. Consulter les [limites de débit du registre de paquets](../administration/settings/package_registry_rate_limits.md) pour plus de détails. |
| `throttle_unauthenticated_web_enabled`                    | boolean | non                                                              | (**Si activé, nécessite** : `throttle_unauthenticated_web_period_in_seconds` et `throttle_unauthenticated_web_requests_per_period`) Activer la limite de débit des requêtes web non authentifiées. Aide à réduire le volume de requêtes (par exemple, provenant de crawlers ou de bots malveillants). |
| `throttle_unauthenticated_web_period_in_seconds`          | integer | requis par :<br>`throttle_unauthenticated_web_enabled`          | Période de limitation de débit en secondes. |
| `throttle_unauthenticated_web_requests_per_period`        | integer | requis par :<br>`throttle_unauthenticated_web_enabled`          | Nombre maximum de requêtes par période par IP. |
| `time_tracking_limit_to_hours`           | boolean          | non                                   | Limiter l'affichage des unités de suivi du temps aux heures. La valeur par défaut est `false`. |
| `top_level_group_creation_enabled`           | boolean          | non                                   | Permet à un utilisateur de créer des groupes principaux. La valeur par défaut est `true`. |
| `two_factor_grace_period`                | integer          | requis par : `require_two_factor_authentication` | Durée (en heures) pendant laquelle les utilisateurs sont autorisés à ignorer la configuration forcée de l'authentification à deux facteurs. |
| `unconfirmed_users_delete_after_days`    | integer          | non                                   | Indique combien de jours après la création du compte supprimer les utilisateurs qui n'ont pas confirmé leur adresse e-mail. Applicable uniquement si `delete_unconfirmed_users` est défini sur `true`. Doit être `1` ou supérieur. La valeur par défaut est `7`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/352514) dans GitLab 16.1. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `unique_ips_limit_enabled`               | boolean          | non                                   | (**Si activé, nécessite** : `unique_ips_limit_per_user` et `unique_ips_limit_time_window`) Limiter la connexion depuis plusieurs adresses IP. |
| `unique_ips_limit_per_user`              | integer          | requis par : `unique_ips_limit_enabled` | Nombre maximum d'adresses IP par utilisateur. |
| `unique_ips_limit_time_window`           | integer          | requis par : `unique_ips_limit_enabled` | Nombre de secondes pendant lesquelles une adresse IP est comptabilisée dans la limite. |
| `update_runner_versions_enabled`         | boolean          | non                                   | Récupérer les données de version de release de GitLab Runner depuis GitLab.com. Pour plus d'informations, voir comment [déterminer quels runners doivent être mis à niveau](../ci/runners/runners_scope.md#determine-which-runners-need-to-be-upgraded). |
| `usage_ping_enabled`                     | boolean          | non                                   | Chaque semaine, GitLab signale l'utilisation des licences à GitLab, Inc. |
| `gitlab_product_usage_data_enabled`      | boolean          | non                                   | Indique si la collecte des données d'utilisation du produit est activée. Lorsque la variable d'environnement `GITLAB_PRODUCT_USAGE_DATA_ENABLED` est définie, l'API retourne la valeur effective de la variable d'environnement. |
| `gitlab_product_usage_data_source`       | string           | non                                   | Lecture seule. Indique la source du paramètre `gitlab_product_usage_data_enabled`. Retourne `environment` si la variable d'environnement `GITLAB_PRODUCT_USAGE_DATA_ENABLED` est définie, sinon retourne `database`. |
| `use_clickhouse_for_analytics`           | boolean          | non                                   | Active ClickHouse comme source de données pour les rapports d'analyse. ClickHouse doit être configuré pour que ce paramètre prenne effet. Disponible sur Premium et Ultimate uniquement. |
| `include_optional_metrics_in_service_ping`| boolean         | non                                   | Indique si les métriques optionnelles sont activées dans Service Ping. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141540) dans GitLab 16.10. |
| `user_deactivation_emails_enabled`       | boolean          | non                                   | Envoyer un e-mail aux utilisateurs lors de la désactivation de leur compte. |
| `user_default_external`                  | boolean          | non                                   | Les nouveaux utilisateurs enregistrés sont externes par défaut. |
| `user_default_internal_regex`            | string           | non                                   | Spécifier un modèle d'expression régulière d'adresse e-mail pour identifier les utilisateurs internes par défaut. |
| `user_defaults_to_private_profile`       | boolean          | non                                   | Les nouveaux utilisateurs créés ont un profil privé par défaut. La valeur par défaut est `false`. |
| `user_oauth_applications`                | boolean          | non                                   | Permettre aux utilisateurs d'enregistrer n'importe quelle application pour utiliser GitLab comme fournisseur OAuth. Ce paramètre n'affecte pas les applications OAuth au niveau du groupe. |
| `user_show_add_ssh_key_message`          | boolean          | non                                   | Lorsque défini sur `false`, désactiver l'avertissement `You won't be able to pull or push project code via SSH` affiché aux utilisateurs sans clé SSH téléversée. |
| `version_check_enabled`                  | boolean          | non                                   | Laisser GitLab vous informer lorsqu'une mise à jour est disponible. |
| `valid_runner_registrars`                | tableau de chaînes de caractères | non                                   | Liste des types autorisés à enregistrer un GitLab Runner. Peut être `[]`, `['group']`, `['project']` ou `['group', 'project']`. |
| `vscode_extension_marketplace`           | hash             | non                                   | Paramètres pour VS Code Extension Marketplace. Utilisé par [Web IDE](../user/project/web_ide/_index.md) et [Workspaces](../user/workspace/_index.md). |
| `whats_new_variant`                      | string           | non                                   | Variante de « Quoi de neuf », valeurs possibles : `all_tiers`, `current_tier` et `disabled`. |
| `wiki_page_max_content_bytes`            | integer          | non                                   | Taille maximale du contenu d'une page wiki en **octets**. Par défaut : 5242880 octets (5 Mo). La valeur minimale est 1024 octets. |
| `bulk_import_concurrent_pipeline_batch_limit` | integer     | non                                   | Nombre maximum d'exportations par lots de transfert direct simultanées à traiter. |
| `concurrent_relation_batch_export_limit` | integer          | non                                   | Nombre maximum de jobs d'exportation par lots simultanés à traiter. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169122) dans GitLab 17.6. |
| `asciidoc_max_includes`                  | integer          | non                                   | Limite maximale des directives include AsciiDoc traitées dans un document. Par défaut : 32\. Maximum : 64\. |
| `duo_custom_agents_enabled`              | boolean          | non                                   | Indique si les agents personnalisés sont autorisés pour cette instance. Par défaut : `true`. GitLab Self-Managed, Premium et Ultimate uniquement. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615) dans GitLab 19.0. |
| `duo_custom_flows_enabled`               | boolean          | non                                   | Indique si les flows personnalisés sont autorisés pour cette instance. Par défaut : `true`. GitLab Self-Managed, Premium et Ultimate uniquement. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615) dans GitLab 19.0. |
| `duo_external_agents_enabled`            | boolean          | non                                   | Indique si les agents externes sont autorisés pour cette instance. Par défaut : `true`. GitLab Self-Managed, Premium et Ultimate uniquement. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615) dans GitLab 19.0. |
| `duo_features_enabled`                   | boolean          | non                                   | Indique si les fonctionnalités GitLab Duo sont activées pour cette instance. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931) dans GitLab 16.10. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `lock_duo_custom_agents_enabled`         | boolean          | non                                   | Indique si le paramètre d'activation des agents personnalisés est appliqué à tous les groupes. Par défaut : `false`. GitLab Self-Managed, Premium et Ultimate uniquement. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615) dans GitLab 19.0. |
| `lock_duo_custom_flows_enabled`          | boolean          | non                                   | Indique si le paramètre d'activation des flows personnalisés est appliqué à tous les groupes. Par défaut : `false`. GitLab Self-Managed, Premium et Ultimate uniquement. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615) dans GitLab 19.0. |
| `lock_duo_external_agents_enabled`       | boolean          | non                                   | Indique si le paramètre d'activation des agents externes est appliqué à tous les groupes. Par défaut : `false`. GitLab Self-Managed, Premium et Ultimate uniquement. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/594615) dans GitLab 19.0. |
| `lock_duo_features_enabled`              | boolean          | non                                   | Indique si le paramètre d'activation des fonctionnalités GitLab Duo est appliqué à tous les sous-groupes. [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931) dans GitLab 16.10. GitLab Self-Managed, Premium et Ultimate uniquement. |
| `nuget_skip_metadata_url_validation` | boolean     | non                                   | Indique s'il faut ignorer la validation de l'URL des métadonnées pour le paquet NuGet. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145887) dans GitLab 17.0. |
| `helm_max_packages_count` | integer     | non                                   | Nombre maximum de paquets Helm pouvant être listés par canal. Doit être au moins 1. La valeur par défaut est 1000. |
| `require_admin_two_factor_authentication` | boolean         | non | Permettre aux administrateurs d'exiger la 2FA pour tous les administrateurs de l'instance. |
| `secret_push_protection_available` | boolean         | non | Permettre aux projets d'activer la protection contre les pushs secrets. Cela n'active pas la protection contre les pushs secrets. Ultimate uniquement. |
| `disable_invite_members` | boolean         | non | Désactiver la fonctionnalité d'invitation de membres pour le groupe. |
| `enforce_pipl_compliance` | boolean | non | Définit si la conformité PIPL est appliquée pour l'application SaaS ou non |
| `iframe_rendering_enabled`               | boolean          | non                                   | Autoriser le rendu des iframes dans Markdown. Désactivé par défaut. |
| `iframe_rendering_allowlist`             | tableau de chaînes de caractères | non                                   | Liste des entrées host[:port] `src` d'iframe autorisées utilisées pour la politique de sécurité du contenu et la désinfection. |
| `iframe_rendering_allowlist_raw`         | string           | non                                   | Liste brute séparée par des nouvelles lignes ou des virgules des entrées host[:port] `src` d'iframe autorisées. |
| `usage_billing`                          | objet           | non                                   | Paramètres de facturation d'utilisation. Consulter `ee/app/validators/json_schemas/usage_billing_settings.json` pour la définition du schéma |

### Paramètres des projets dormants {#dormant-project-settings}

Vous pouvez configurer la suppression des projets dormants ou la désactiver.

| Attribut                                | Type             | Obligatoire                             | Description |
|------------------------------------------|------------------|:------------------------------------:|-------------|
| `delete_inactive_projects`               | boolean          | non                                   | Activer la [suppression des projets dormants](../administration/dormant_project_deletion.md). La valeur par défaut est `false`. [Devenu opérationnel sans feature flag](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96803) dans GitLab 15.4. |
| `inactive_projects_delete_after_months`  | integer          | non                                   | Si `delete_inactive_projects` est `true`, la durée (en mois) à attendre avant de supprimer les projets dormants. La valeur par défaut est `2`. [Devenu opérationnel](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) dans GitLab 15.0. |
| `inactive_projects_min_size_mb`          | integer          | non                                   | Si `delete_inactive_projects` est `true`, la taille minimale du dépôt pour les projets à vérifier pour inactivité. La valeur par défaut est `0`. [Devenu opérationnel](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) dans GitLab 15.0. |
| `inactive_projects_send_warning_email_after_months` | integer | non                                 | Si `delete_inactive_projects` est `true`, définit le délai (en mois) à attendre avant d'envoyer un e-mail aux Mainteneurs pour les informer que le projet est programmé pour être supprimé car il est inactif. La valeur par défaut est `1`. [Devenu opérationnel](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85689) dans GitLab 15.0. |

### Paramètres du registre de paquets : Limites de taille des fichiers de paquets {#package-registry-settings-package-file-size-limits}

Les limites de taille des fichiers de paquets ne font pas partie de l'API des paramètres d'application. Ces paramètres sont accessibles via l'[API des limites de plan](plan_limits.md).

## Sujets connexes {#related-topics}

- [Options pour `default_branch_protection_defaults`](groups.md#options-for-default_branch_protection_defaults)
