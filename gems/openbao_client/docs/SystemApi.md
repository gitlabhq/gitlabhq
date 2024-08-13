# OpenbaoClient::SystemApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**auditing_calculate_hash**](SystemApi.md#auditing_calculate_hash) | **POST** /sys/audit-hash/{path} |  |
| [**auditing_disable_device**](SystemApi.md#auditing_disable_device) | **DELETE** /sys/audit/{path} | Disable the audit device at the given path. |
| [**auditing_disable_request_header**](SystemApi.md#auditing_disable_request_header) | **DELETE** /sys/config/auditing/request-headers/{header} | Disable auditing of the given request header. |
| [**auditing_enable_device**](SystemApi.md#auditing_enable_device) | **POST** /sys/audit/{path} | Enable a new audit device at the supplied path. |
| [**auditing_enable_request_header**](SystemApi.md#auditing_enable_request_header) | **POST** /sys/config/auditing/request-headers/{header} | Enable auditing of a header. |
| [**auditing_list_enabled_devices**](SystemApi.md#auditing_list_enabled_devices) | **GET** /sys/audit | List the enabled audit devices. |
| [**auditing_list_request_headers**](SystemApi.md#auditing_list_request_headers) | **GET** /sys/config/auditing/request-headers | List the request headers that are configured to be audited. |
| [**auditing_read_request_header_information**](SystemApi.md#auditing_read_request_header_information) | **GET** /sys/config/auditing/request-headers/{header} | List the information for the given request header. |
| [**auth_disable_method**](SystemApi.md#auth_disable_method) | **DELETE** /sys/auth/{path} | Disable the auth method at the given auth path |
| [**auth_enable_method**](SystemApi.md#auth_enable_method) | **POST** /sys/auth/{path} | Enables a new auth method. |
| [**auth_list_enabled_methods**](SystemApi.md#auth_list_enabled_methods) | **GET** /sys/auth |  |
| [**auth_read_configuration**](SystemApi.md#auth_read_configuration) | **GET** /sys/auth/{path} | Read the configuration of the auth engine at the given path. |
| [**auth_read_tuning_information**](SystemApi.md#auth_read_tuning_information) | **GET** /sys/auth/{path}/tune | Reads the given auth path&#39;s configuration. |
| [**auth_tune_configuration_parameters**](SystemApi.md#auth_tune_configuration_parameters) | **POST** /sys/auth/{path}/tune | Tune configuration parameters for a given auth path. |
| [**collect_host_information**](SystemApi.md#collect_host_information) | **GET** /sys/host-info | Information about the host instance that this OpenBao server is running on. |
| [**collect_in_flight_request_information**](SystemApi.md#collect_in_flight_request_information) | **GET** /sys/in-flight-req | reports in-flight requests |
| [**cors_configure**](SystemApi.md#cors_configure) | **POST** /sys/config/cors | Configure the CORS settings. |
| [**cors_delete_configuration**](SystemApi.md#cors_delete_configuration) | **DELETE** /sys/config/cors | Remove any CORS settings. |
| [**cors_read_configuration**](SystemApi.md#cors_read_configuration) | **GET** /sys/config/cors | Return the current CORS settings. |
| [**decode**](SystemApi.md#decode) | **POST** /sys/decode-token | Decodes the encoded token with the otp. |
| [**encryption_key_configure_rotation**](SystemApi.md#encryption_key_configure_rotation) | **POST** /sys/rotate/config |  |
| [**encryption_key_read_rotation_configuration**](SystemApi.md#encryption_key_read_rotation_configuration) | **GET** /sys/rotate/config |  |
| [**encryption_key_rotate**](SystemApi.md#encryption_key_rotate) | **POST** /sys/rotate |  |
| [**encryption_key_status**](SystemApi.md#encryption_key_status) | **GET** /sys/key-status | Provides information about the backend encryption key. |
| [**generate_hash**](SystemApi.md#generate_hash) | **POST** /sys/tools/hash |  |
| [**generate_hash_with_algorithm**](SystemApi.md#generate_hash_with_algorithm) | **POST** /sys/tools/hash/{urlalgorithm} |  |
| [**generate_random**](SystemApi.md#generate_random) | **POST** /sys/tools/random |  |
| [**generate_random_with_bytes**](SystemApi.md#generate_random_with_bytes) | **POST** /sys/tools/random/{urlbytes} |  |
| [**generate_random_with_source**](SystemApi.md#generate_random_with_source) | **POST** /sys/tools/random/{source} |  |
| [**generate_random_with_source_and_bytes**](SystemApi.md#generate_random_with_source_and_bytes) | **POST** /sys/tools/random/{source}/{urlbytes} |  |
| [**ha_status**](SystemApi.md#ha_status) | **GET** /sys/ha-status | Check the HA status of an OpenBao cluster |
| [**initialize**](SystemApi.md#initialize) | **POST** /sys/init | Initialize a new OpenBao instance. |
| [**internal_count_entities**](SystemApi.md#internal_count_entities) | **GET** /sys/internal/counters/entities | Backwards compatibility is not guaranteed for this API |
| [**internal_count_requests**](SystemApi.md#internal_count_requests) | **GET** /sys/internal/counters/requests | Backwards compatibility is not guaranteed for this API |
| [**internal_count_tokens**](SystemApi.md#internal_count_tokens) | **GET** /sys/internal/counters/tokens | Backwards compatibility is not guaranteed for this API |
| [**internal_generate_open_api_document**](SystemApi.md#internal_generate_open_api_document) | **GET** /sys/internal/specs/openapi |  |
| [**internal_generate_open_api_document_with_parameters**](SystemApi.md#internal_generate_open_api_document_with_parameters) | **POST** /sys/internal/specs/openapi |  |
| [**internal_inspect_router**](SystemApi.md#internal_inspect_router) | **GET** /sys/internal/inspect/router/{tag} | Expose the route entry and mount entry tables present in the router |
| [**internal_ui_list_enabled_feature_flags**](SystemApi.md#internal_ui_list_enabled_feature_flags) | **GET** /sys/internal/ui/feature-flags | Lists enabled feature flags. |
| [**internal_ui_list_enabled_visible_mounts**](SystemApi.md#internal_ui_list_enabled_visible_mounts) | **GET** /sys/internal/ui/mounts | Lists all enabled and visible auth and secrets mounts. |
| [**internal_ui_list_namespaces**](SystemApi.md#internal_ui_list_namespaces) | **GET** /sys/internal/ui/namespaces | Backwards compatibility is not guaranteed for this API |
| [**internal_ui_read_mount_information**](SystemApi.md#internal_ui_read_mount_information) | **GET** /sys/internal/ui/mounts/{path} | Return information about the given mount. |
| [**internal_ui_read_resultant_acl**](SystemApi.md#internal_ui_read_resultant_acl) | **GET** /sys/internal/ui/resultant-acl | Backwards compatibility is not guaranteed for this API |
| [**leader_status**](SystemApi.md#leader_status) | **GET** /sys/leader | Returns the high availability status and current leader instance of OpenBao. |
| [**leases_count**](SystemApi.md#leases_count) | **GET** /sys/leases/count |  |
| [**leases_force_revoke_lease_with_prefix**](SystemApi.md#leases_force_revoke_lease_with_prefix) | **POST** /sys/leases/revoke-force/{prefix} | Revokes all secrets or tokens generated under a given prefix immediately |
| [**leases_force_revoke_lease_with_prefix2**](SystemApi.md#leases_force_revoke_lease_with_prefix2) | **POST** /sys/revoke-force/{prefix} | Revokes all secrets or tokens generated under a given prefix immediately |
| [**leases_list**](SystemApi.md#leases_list) | **GET** /sys/leases |  |
| [**leases_look_up**](SystemApi.md#leases_look_up) | **GET** /sys/leases/lookup/ |  |
| [**leases_look_up_with_prefix**](SystemApi.md#leases_look_up_with_prefix) | **GET** /sys/leases/lookup/{prefix} |  |
| [**leases_read_lease**](SystemApi.md#leases_read_lease) | **POST** /sys/leases/lookup |  |
| [**leases_renew_lease**](SystemApi.md#leases_renew_lease) | **POST** /sys/leases/renew | Renews a lease, requesting to extend the lease. |
| [**leases_renew_lease2**](SystemApi.md#leases_renew_lease2) | **POST** /sys/renew | Renews a lease, requesting to extend the lease. |
| [**leases_renew_lease_with_id**](SystemApi.md#leases_renew_lease_with_id) | **POST** /sys/leases/renew/{url_lease_id} | Renews a lease, requesting to extend the lease. |
| [**leases_renew_lease_with_id2**](SystemApi.md#leases_renew_lease_with_id2) | **POST** /sys/renew/{url_lease_id} | Renews a lease, requesting to extend the lease. |
| [**leases_revoke_lease**](SystemApi.md#leases_revoke_lease) | **POST** /sys/leases/revoke | Revokes a lease immediately. |
| [**leases_revoke_lease2**](SystemApi.md#leases_revoke_lease2) | **POST** /sys/revoke | Revokes a lease immediately. |
| [**leases_revoke_lease_with_id**](SystemApi.md#leases_revoke_lease_with_id) | **POST** /sys/leases/revoke/{url_lease_id} | Revokes a lease immediately. |
| [**leases_revoke_lease_with_id2**](SystemApi.md#leases_revoke_lease_with_id2) | **POST** /sys/revoke/{url_lease_id} | Revokes a lease immediately. |
| [**leases_revoke_lease_with_prefix**](SystemApi.md#leases_revoke_lease_with_prefix) | **POST** /sys/leases/revoke-prefix/{prefix} | Revokes all secrets (via a lease ID prefix) or tokens (via the tokens&#39; path property) generated under a given prefix immediately. |
| [**leases_revoke_lease_with_prefix2**](SystemApi.md#leases_revoke_lease_with_prefix2) | **POST** /sys/revoke-prefix/{prefix} | Revokes all secrets (via a lease ID prefix) or tokens (via the tokens&#39; path property) generated under a given prefix immediately. |
| [**leases_tidy**](SystemApi.md#leases_tidy) | **POST** /sys/leases/tidy |  |
| [**locked_users_list**](SystemApi.md#locked_users_list) | **GET** /sys/locked-users | Report the locked user count metrics, for this namespace and all child namespaces. |
| [**locked_users_unlock**](SystemApi.md#locked_users_unlock) | **POST** /sys/locked-users/{mount_accessor}/unlock/{alias_identifier} | Unlocks the user with given mount_accessor and alias_identifier |
| [**loggers_read_verbosity_level**](SystemApi.md#loggers_read_verbosity_level) | **GET** /sys/loggers | Read the log level for all existing loggers. |
| [**loggers_read_verbosity_level_for**](SystemApi.md#loggers_read_verbosity_level_for) | **GET** /sys/loggers/{name} | Read the log level for a single logger. |
| [**loggers_revert_verbosity_level**](SystemApi.md#loggers_revert_verbosity_level) | **DELETE** /sys/loggers | Revert the all loggers to use log level provided in config. |
| [**loggers_revert_verbosity_level_for**](SystemApi.md#loggers_revert_verbosity_level_for) | **DELETE** /sys/loggers/{name} | Revert a single logger to use log level provided in config. |
| [**loggers_update_verbosity_level**](SystemApi.md#loggers_update_verbosity_level) | **POST** /sys/loggers | Modify the log level for all existing loggers. |
| [**loggers_update_verbosity_level_for**](SystemApi.md#loggers_update_verbosity_level_for) | **POST** /sys/loggers/{name} | Modify the log level of a single logger. |
| [**metrics**](SystemApi.md#metrics) | **GET** /sys/metrics |  |
| [**mfa_validate**](SystemApi.md#mfa_validate) | **POST** /sys/mfa/validate | Validates the login for the given MFA methods. Upon successful validation, it returns an auth response containing the client token |
| [**monitor**](SystemApi.md#monitor) | **GET** /sys/monitor |  |
| [**mounts_disable_secrets_engine**](SystemApi.md#mounts_disable_secrets_engine) | **DELETE** /sys/mounts/{path} | Disable the mount point specified at the given path. |
| [**mounts_enable_secrets_engine**](SystemApi.md#mounts_enable_secrets_engine) | **POST** /sys/mounts/{path} | Enable a new secrets engine at the given path. |
| [**mounts_list_secrets_engines**](SystemApi.md#mounts_list_secrets_engines) | **GET** /sys/mounts |  |
| [**mounts_read_configuration**](SystemApi.md#mounts_read_configuration) | **GET** /sys/mounts/{path} | Read the configuration of the secret engine at the given path. |
| [**mounts_read_tuning_information**](SystemApi.md#mounts_read_tuning_information) | **GET** /sys/mounts/{path}/tune |  |
| [**mounts_tune_configuration_parameters**](SystemApi.md#mounts_tune_configuration_parameters) | **POST** /sys/mounts/{path}/tune |  |
| [**plugins_catalog_list_plugins**](SystemApi.md#plugins_catalog_list_plugins) | **GET** /sys/plugins/catalog |  |
| [**plugins_catalog_list_plugins_with_type**](SystemApi.md#plugins_catalog_list_plugins_with_type) | **GET** /sys/plugins/catalog/{type} | List the plugins in the catalog. |
| [**plugins_catalog_read_plugin_configuration**](SystemApi.md#plugins_catalog_read_plugin_configuration) | **GET** /sys/plugins/catalog/{name} | Return the configuration data for the plugin with the given name. |
| [**plugins_catalog_read_plugin_configuration_with_type**](SystemApi.md#plugins_catalog_read_plugin_configuration_with_type) | **GET** /sys/plugins/catalog/{type}/{name} | Return the configuration data for the plugin with the given name. |
| [**plugins_catalog_register_plugin**](SystemApi.md#plugins_catalog_register_plugin) | **POST** /sys/plugins/catalog/{name} | Register a new plugin, or updates an existing one with the supplied name. |
| [**plugins_catalog_register_plugin_with_type**](SystemApi.md#plugins_catalog_register_plugin_with_type) | **POST** /sys/plugins/catalog/{type}/{name} | Register a new plugin, or updates an existing one with the supplied name. |
| [**plugins_catalog_remove_plugin**](SystemApi.md#plugins_catalog_remove_plugin) | **DELETE** /sys/plugins/catalog/{name} | Remove the plugin with the given name. |
| [**plugins_catalog_remove_plugin_with_type**](SystemApi.md#plugins_catalog_remove_plugin_with_type) | **DELETE** /sys/plugins/catalog/{type}/{name} | Remove the plugin with the given name. |
| [**plugins_reload_backends**](SystemApi.md#plugins_reload_backends) | **POST** /sys/plugins/reload/backend | Reload mounted plugin backends. |
| [**policies_delete_acl_policy**](SystemApi.md#policies_delete_acl_policy) | **DELETE** /sys/policies/acl/{name} | Delete the ACL policy with the given name. |
| [**policies_delete_acl_policy2**](SystemApi.md#policies_delete_acl_policy2) | **DELETE** /sys/policy/{name} | Delete the policy with the given name. |
| [**policies_delete_password_policy**](SystemApi.md#policies_delete_password_policy) | **DELETE** /sys/policies/password/{name} | Delete a password policy. |
| [**policies_generate_password_from_password_policy**](SystemApi.md#policies_generate_password_from_password_policy) | **GET** /sys/policies/password/{name}/generate | Generate a password from an existing password policy. |
| [**policies_list**](SystemApi.md#policies_list) | **GET** /sys/policy |  |
| [**policies_list_acl_policies**](SystemApi.md#policies_list_acl_policies) | **GET** /sys/policies/acl |  |
| [**policies_list_password_policies**](SystemApi.md#policies_list_password_policies) | **GET** /sys/policies/password | List the existing password policies. |
| [**policies_read_acl_policy**](SystemApi.md#policies_read_acl_policy) | **GET** /sys/policies/acl/{name} | Retrieve information about the named ACL policy. |
| [**policies_read_acl_policy2**](SystemApi.md#policies_read_acl_policy2) | **GET** /sys/policy/{name} | Retrieve the policy body for the named policy. |
| [**policies_read_password_policy**](SystemApi.md#policies_read_password_policy) | **GET** /sys/policies/password/{name} | Retrieve an existing password policy. |
| [**policies_write_acl_policy**](SystemApi.md#policies_write_acl_policy) | **POST** /sys/policies/acl/{name} | Add a new or update an existing ACL policy. |
| [**policies_write_acl_policy2**](SystemApi.md#policies_write_acl_policy2) | **POST** /sys/policy/{name} | Add a new or update an existing policy. |
| [**policies_write_password_policy**](SystemApi.md#policies_write_password_policy) | **POST** /sys/policies/password/{name} | Add a new or update an existing password policy. |
| [**pprof_blocking**](SystemApi.md#pprof_blocking) | **GET** /sys/pprof/block | Returns stack traces that led to blocking on synchronization primitives |
| [**pprof_command_line**](SystemApi.md#pprof_command_line) | **GET** /sys/pprof/cmdline | Returns the running program&#39;s command line. |
| [**pprof_cpu_profile**](SystemApi.md#pprof_cpu_profile) | **GET** /sys/pprof/profile | Returns a pprof-formatted cpu profile payload. |
| [**pprof_execution_trace**](SystemApi.md#pprof_execution_trace) | **GET** /sys/pprof/trace | Returns the execution trace in binary form. |
| [**pprof_goroutines**](SystemApi.md#pprof_goroutines) | **GET** /sys/pprof/goroutine | Returns stack traces of all current goroutines. |
| [**pprof_index**](SystemApi.md#pprof_index) | **GET** /sys/pprof | Returns an HTML page listing the available profiles. |
| [**pprof_memory_allocations**](SystemApi.md#pprof_memory_allocations) | **GET** /sys/pprof/allocs | Returns a sampling of all past memory allocations. |
| [**pprof_memory_allocations_live**](SystemApi.md#pprof_memory_allocations_live) | **GET** /sys/pprof/heap | Returns a sampling of memory allocations of live object. |
| [**pprof_mutexes**](SystemApi.md#pprof_mutexes) | **GET** /sys/pprof/mutex | Returns stack traces of holders of contended mutexes |
| [**pprof_symbols**](SystemApi.md#pprof_symbols) | **GET** /sys/pprof/symbol | Returns the program counters listed in the request. |
| [**pprof_thread_creations**](SystemApi.md#pprof_thread_creations) | **GET** /sys/pprof/threadcreate | Returns stack traces that led to the creation of new OS threads |
| [**query_token_accessor_capabilities**](SystemApi.md#query_token_accessor_capabilities) | **POST** /sys/capabilities-accessor |  |
| [**query_token_capabilities**](SystemApi.md#query_token_capabilities) | **POST** /sys/capabilities |  |
| [**query_token_self_capabilities**](SystemApi.md#query_token_self_capabilities) | **POST** /sys/capabilities-self |  |
| [**rate_limit_quotas_configure**](SystemApi.md#rate_limit_quotas_configure) | **POST** /sys/quotas/config |  |
| [**rate_limit_quotas_delete**](SystemApi.md#rate_limit_quotas_delete) | **DELETE** /sys/quotas/rate-limit/{name} |  |
| [**rate_limit_quotas_list**](SystemApi.md#rate_limit_quotas_list) | **GET** /sys/quotas/rate-limit |  |
| [**rate_limit_quotas_read**](SystemApi.md#rate_limit_quotas_read) | **GET** /sys/quotas/rate-limit/{name} |  |
| [**rate_limit_quotas_read_configuration**](SystemApi.md#rate_limit_quotas_read_configuration) | **GET** /sys/quotas/config |  |
| [**rate_limit_quotas_write**](SystemApi.md#rate_limit_quotas_write) | **POST** /sys/quotas/rate-limit/{name} |  |
| [**raw_delete**](SystemApi.md#raw_delete) | **DELETE** /sys/raw | Delete the key with given path. |
| [**raw_delete_path**](SystemApi.md#raw_delete_path) | **DELETE** /sys/raw/{path} | Delete the key with given path. |
| [**raw_read**](SystemApi.md#raw_read) | **GET** /sys/raw | Read the value of the key at the given path. |
| [**raw_read_path**](SystemApi.md#raw_read_path) | **GET** /sys/raw/{path} | Read the value of the key at the given path. |
| [**raw_write**](SystemApi.md#raw_write) | **POST** /sys/raw | Update the value of the key at the given path. |
| [**raw_write_path**](SystemApi.md#raw_write_path) | **POST** /sys/raw/{path} | Update the value of the key at the given path. |
| [**read_health_status**](SystemApi.md#read_health_status) | **GET** /sys/health | Returns the health status of OpenBao. |
| [**read_initialization_status**](SystemApi.md#read_initialization_status) | **GET** /sys/init | Returns the initialization status of OpenBao. |
| [**read_sanitized_configuration_state**](SystemApi.md#read_sanitized_configuration_state) | **GET** /sys/config/state/sanitized | Return a sanitized version of the OpenBao server configuration. |
| [**read_wrapping_properties**](SystemApi.md#read_wrapping_properties) | **POST** /sys/wrapping/lookup | Look up wrapping properties for the given token. |
| [**read_wrapping_properties2**](SystemApi.md#read_wrapping_properties2) | **GET** /sys/wrapping/lookup | Look up wrapping properties for the requester&#39;s token. |
| [**rekey_attempt_cancel**](SystemApi.md#rekey_attempt_cancel) | **DELETE** /sys/rekey/init | Cancels any in-progress rekey. |
| [**rekey_attempt_initialize**](SystemApi.md#rekey_attempt_initialize) | **POST** /sys/rekey/init | Initializes a new rekey attempt. |
| [**rekey_attempt_read_progress**](SystemApi.md#rekey_attempt_read_progress) | **GET** /sys/rekey/init | Reads the configuration and progress of the current rekey attempt. |
| [**rekey_attempt_update**](SystemApi.md#rekey_attempt_update) | **POST** /sys/rekey/update | Enter a single unseal key share to progress the rekey of the OpenBao. |
| [**rekey_delete_backup_key**](SystemApi.md#rekey_delete_backup_key) | **DELETE** /sys/rekey/backup | Delete the backup copy of PGP-encrypted unseal keys. |
| [**rekey_delete_backup_recovery_key**](SystemApi.md#rekey_delete_backup_recovery_key) | **DELETE** /sys/rekey/recovery-key-backup |  |
| [**rekey_read_backup_key**](SystemApi.md#rekey_read_backup_key) | **GET** /sys/rekey/backup | Return the backup copy of PGP-encrypted unseal keys. |
| [**rekey_read_backup_recovery_key**](SystemApi.md#rekey_read_backup_recovery_key) | **GET** /sys/rekey/recovery-key-backup |  |
| [**rekey_verification_cancel**](SystemApi.md#rekey_verification_cancel) | **DELETE** /sys/rekey/verify | Cancel any in-progress rekey verification operation. |
| [**rekey_verification_read_progress**](SystemApi.md#rekey_verification_read_progress) | **GET** /sys/rekey/verify | Read the configuration and progress of the current rekey verification attempt. |
| [**rekey_verification_update**](SystemApi.md#rekey_verification_update) | **POST** /sys/rekey/verify | Enter a single new key share to progress the rekey verification operation. |
| [**reload_subsystem**](SystemApi.md#reload_subsystem) | **POST** /sys/config/reload/{subsystem} | Reload the given subsystem |
| [**remount**](SystemApi.md#remount) | **POST** /sys/remount | Initiate a mount migration |
| [**remount_status**](SystemApi.md#remount_status) | **GET** /sys/remount/status/{migration_id} | Check status of a mount migration |
| [**rewrap**](SystemApi.md#rewrap) | **POST** /sys/wrapping/rewrap |  |
| [**root_token_generation_cancel**](SystemApi.md#root_token_generation_cancel) | **DELETE** /sys/generate-root/attempt | Cancels any in-progress root generation attempt. |
| [**root_token_generation_cancel2**](SystemApi.md#root_token_generation_cancel2) | **DELETE** /sys/generate-root | Cancels any in-progress root generation attempt. |
| [**root_token_generation_initialize**](SystemApi.md#root_token_generation_initialize) | **POST** /sys/generate-root/attempt | Initializes a new root generation attempt. |
| [**root_token_generation_initialize2**](SystemApi.md#root_token_generation_initialize2) | **POST** /sys/generate-root | Initializes a new root generation attempt. |
| [**root_token_generation_read_progress**](SystemApi.md#root_token_generation_read_progress) | **GET** /sys/generate-root/attempt | Read the configuration and progress of the current root generation attempt. |
| [**root_token_generation_read_progress2**](SystemApi.md#root_token_generation_read_progress2) | **GET** /sys/generate-root | Read the configuration and progress of the current root generation attempt. |
| [**root_token_generation_update**](SystemApi.md#root_token_generation_update) | **POST** /sys/generate-root/update | Enter a single unseal key share to progress the root generation attempt. |
| [**seal**](SystemApi.md#seal) | **POST** /sys/seal | Seal the OpenBao instance. |
| [**seal_status**](SystemApi.md#seal_status) | **GET** /sys/seal-status | Check the seal status of an OpenBao instance. |
| [**step_down_leader**](SystemApi.md#step_down_leader) | **POST** /sys/step-down | Cause the node to give up active status. |
| [**ui_headers_configure**](SystemApi.md#ui_headers_configure) | **POST** /sys/config/ui/headers/{header} | Configure the values to be returned for the UI header. |
| [**ui_headers_delete_configuration**](SystemApi.md#ui_headers_delete_configuration) | **DELETE** /sys/config/ui/headers/{header} | Remove a UI header. |
| [**ui_headers_list**](SystemApi.md#ui_headers_list) | **GET** /sys/config/ui/headers | Return a list of configured UI headers. |
| [**ui_headers_read_configuration**](SystemApi.md#ui_headers_read_configuration) | **GET** /sys/config/ui/headers/{header} | Return the given UI header&#39;s configuration |
| [**unseal**](SystemApi.md#unseal) | **POST** /sys/unseal | Unseal the OpenBao instance. |
| [**unwrap**](SystemApi.md#unwrap) | **POST** /sys/wrapping/unwrap |  |
| [**version_history**](SystemApi.md#version_history) | **GET** /sys/version-history | Returns map of historical version change entries |
| [**wrap**](SystemApi.md#wrap) | **POST** /sys/wrapping/wrap |  |


## auditing_calculate_hash

> <AuditingCalculateHashResponse> auditing_calculate_hash(path, auditing_calculate_hash_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The name of the backend. Cannot be delimited. Example: \"mysql\"
auditing_calculate_hash_request = OpenbaoClient::AuditingCalculateHashRequest.new # AuditingCalculateHashRequest | 

begin
  
  result = api_instance.auditing_calculate_hash(path, auditing_calculate_hash_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_calculate_hash: #{e}"
end
```

#### Using the auditing_calculate_hash_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AuditingCalculateHashResponse>, Integer, Hash)> auditing_calculate_hash_with_http_info(path, auditing_calculate_hash_request)

```ruby
begin
  
  data, status_code, headers = api_instance.auditing_calculate_hash_with_http_info(path, auditing_calculate_hash_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AuditingCalculateHashResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_calculate_hash_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The name of the backend. Cannot be delimited. Example: \&quot;mysql\&quot; |  |
| **auditing_calculate_hash_request** | [**AuditingCalculateHashRequest**](AuditingCalculateHashRequest.md) |  |  |

### Return type

[**AuditingCalculateHashResponse**](AuditingCalculateHashResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## auditing_disable_device

> auditing_disable_device(path)

Disable the audit device at the given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The name of the backend. Cannot be delimited. Example: \"mysql\"

begin
  # Disable the audit device at the given path.
  api_instance.auditing_disable_device(path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_disable_device: #{e}"
end
```

#### Using the auditing_disable_device_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> auditing_disable_device_with_http_info(path)

```ruby
begin
  # Disable the audit device at the given path.
  data, status_code, headers = api_instance.auditing_disable_device_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_disable_device_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The name of the backend. Cannot be delimited. Example: \&quot;mysql\&quot; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## auditing_disable_request_header

> auditing_disable_request_header(header)

Disable auditing of the given request header.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
header = 'header_example' # String | 

begin
  # Disable auditing of the given request header.
  api_instance.auditing_disable_request_header(header)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_disable_request_header: #{e}"
end
```

#### Using the auditing_disable_request_header_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> auditing_disable_request_header_with_http_info(header)

```ruby
begin
  # Disable auditing of the given request header.
  data, status_code, headers = api_instance.auditing_disable_request_header_with_http_info(header)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_disable_request_header_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **header** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## auditing_enable_device

> auditing_enable_device(path, auditing_enable_device_request)

Enable a new audit device at the supplied path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The name of the backend. Cannot be delimited. Example: \"mysql\"
auditing_enable_device_request = OpenbaoClient::AuditingEnableDeviceRequest.new # AuditingEnableDeviceRequest | 

begin
  # Enable a new audit device at the supplied path.
  api_instance.auditing_enable_device(path, auditing_enable_device_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_enable_device: #{e}"
end
```

#### Using the auditing_enable_device_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> auditing_enable_device_with_http_info(path, auditing_enable_device_request)

```ruby
begin
  # Enable a new audit device at the supplied path.
  data, status_code, headers = api_instance.auditing_enable_device_with_http_info(path, auditing_enable_device_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_enable_device_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The name of the backend. Cannot be delimited. Example: \&quot;mysql\&quot; |  |
| **auditing_enable_device_request** | [**AuditingEnableDeviceRequest**](AuditingEnableDeviceRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## auditing_enable_request_header

> auditing_enable_request_header(header, auditing_enable_request_header_request)

Enable auditing of a header.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
header = 'header_example' # String | 
auditing_enable_request_header_request = OpenbaoClient::AuditingEnableRequestHeaderRequest.new # AuditingEnableRequestHeaderRequest | 

begin
  # Enable auditing of a header.
  api_instance.auditing_enable_request_header(header, auditing_enable_request_header_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_enable_request_header: #{e}"
end
```

#### Using the auditing_enable_request_header_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> auditing_enable_request_header_with_http_info(header, auditing_enable_request_header_request)

```ruby
begin
  # Enable auditing of a header.
  data, status_code, headers = api_instance.auditing_enable_request_header_with_http_info(header, auditing_enable_request_header_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_enable_request_header_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **header** | **String** |  |  |
| **auditing_enable_request_header_request** | [**AuditingEnableRequestHeaderRequest**](AuditingEnableRequestHeaderRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## auditing_list_enabled_devices

> auditing_list_enabled_devices

List the enabled audit devices.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # List the enabled audit devices.
  api_instance.auditing_list_enabled_devices
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_list_enabled_devices: #{e}"
end
```

#### Using the auditing_list_enabled_devices_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> auditing_list_enabled_devices_with_http_info

```ruby
begin
  # List the enabled audit devices.
  data, status_code, headers = api_instance.auditing_list_enabled_devices_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_list_enabled_devices_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## auditing_list_request_headers

> <AuditingListRequestHeadersResponse> auditing_list_request_headers

List the request headers that are configured to be audited.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # List the request headers that are configured to be audited.
  result = api_instance.auditing_list_request_headers
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_list_request_headers: #{e}"
end
```

#### Using the auditing_list_request_headers_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AuditingListRequestHeadersResponse>, Integer, Hash)> auditing_list_request_headers_with_http_info

```ruby
begin
  # List the request headers that are configured to be audited.
  data, status_code, headers = api_instance.auditing_list_request_headers_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AuditingListRequestHeadersResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_list_request_headers_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**AuditingListRequestHeadersResponse**](AuditingListRequestHeadersResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## auditing_read_request_header_information

> auditing_read_request_header_information(header)

List the information for the given request header.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
header = 'header_example' # String | 

begin
  # List the information for the given request header.
  api_instance.auditing_read_request_header_information(header)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_read_request_header_information: #{e}"
end
```

#### Using the auditing_read_request_header_information_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> auditing_read_request_header_information_with_http_info(header)

```ruby
begin
  # List the information for the given request header.
  data, status_code, headers = api_instance.auditing_read_request_header_information_with_http_info(header)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auditing_read_request_header_information_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **header** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## auth_disable_method

> auth_disable_method(path)

Disable the auth method at the given auth path

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The path to mount to. Cannot be delimited. Example: \"user\"

begin
  # Disable the auth method at the given auth path
  api_instance.auth_disable_method(path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_disable_method: #{e}"
end
```

#### Using the auth_disable_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> auth_disable_method_with_http_info(path)

```ruby
begin
  # Disable the auth method at the given auth path
  data, status_code, headers = api_instance.auth_disable_method_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_disable_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The path to mount to. Cannot be delimited. Example: \&quot;user\&quot; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## auth_enable_method

> auth_enable_method(path, auth_enable_method_request)

Enables a new auth method.

After enabling, the auth method can be accessed and configured via the auth path specified as part of the URL. This auth path will be nested under the auth prefix.  For example, enable the \"foo\" auth method will make it accessible at /auth/foo.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The path to mount to. Cannot be delimited. Example: \"user\"
auth_enable_method_request = OpenbaoClient::AuthEnableMethodRequest.new # AuthEnableMethodRequest | 

begin
  # Enables a new auth method.
  api_instance.auth_enable_method(path, auth_enable_method_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_enable_method: #{e}"
end
```

#### Using the auth_enable_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> auth_enable_method_with_http_info(path, auth_enable_method_request)

```ruby
begin
  # Enables a new auth method.
  data, status_code, headers = api_instance.auth_enable_method_with_http_info(path, auth_enable_method_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_enable_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The path to mount to. Cannot be delimited. Example: \&quot;user\&quot; |  |
| **auth_enable_method_request** | [**AuthEnableMethodRequest**](AuthEnableMethodRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## auth_list_enabled_methods

> auth_list_enabled_methods



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  api_instance.auth_list_enabled_methods
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_list_enabled_methods: #{e}"
end
```

#### Using the auth_list_enabled_methods_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> auth_list_enabled_methods_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.auth_list_enabled_methods_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_list_enabled_methods_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## auth_read_configuration

> <AuthReadConfigurationResponse> auth_read_configuration(path)

Read the configuration of the auth engine at the given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The path to mount to. Cannot be delimited. Example: \"user\"

begin
  # Read the configuration of the auth engine at the given path.
  result = api_instance.auth_read_configuration(path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_read_configuration: #{e}"
end
```

#### Using the auth_read_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AuthReadConfigurationResponse>, Integer, Hash)> auth_read_configuration_with_http_info(path)

```ruby
begin
  # Read the configuration of the auth engine at the given path.
  data, status_code, headers = api_instance.auth_read_configuration_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AuthReadConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_read_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The path to mount to. Cannot be delimited. Example: \&quot;user\&quot; |  |

### Return type

[**AuthReadConfigurationResponse**](AuthReadConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## auth_read_tuning_information

> <AuthReadTuningInformationResponse> auth_read_tuning_information(path)

Reads the given auth path's configuration.

This endpoint requires sudo capability on the final path, but the same functionality can be achieved without sudo via `sys/mounts/auth/[auth-path]/tune`.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | Tune the configuration parameters for an auth path.

begin
  # Reads the given auth path's configuration.
  result = api_instance.auth_read_tuning_information(path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_read_tuning_information: #{e}"
end
```

#### Using the auth_read_tuning_information_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AuthReadTuningInformationResponse>, Integer, Hash)> auth_read_tuning_information_with_http_info(path)

```ruby
begin
  # Reads the given auth path's configuration.
  data, status_code, headers = api_instance.auth_read_tuning_information_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AuthReadTuningInformationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_read_tuning_information_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Tune the configuration parameters for an auth path. |  |

### Return type

[**AuthReadTuningInformationResponse**](AuthReadTuningInformationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## auth_tune_configuration_parameters

> auth_tune_configuration_parameters(path, auth_tune_configuration_parameters_request)

Tune configuration parameters for a given auth path.

This endpoint requires sudo capability on the final path, but the same functionality can be achieved without sudo via `sys/mounts/auth/[auth-path]/tune`.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | Tune the configuration parameters for an auth path.
auth_tune_configuration_parameters_request = OpenbaoClient::AuthTuneConfigurationParametersRequest.new # AuthTuneConfigurationParametersRequest | 

begin
  # Tune configuration parameters for a given auth path.
  api_instance.auth_tune_configuration_parameters(path, auth_tune_configuration_parameters_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_tune_configuration_parameters: #{e}"
end
```

#### Using the auth_tune_configuration_parameters_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> auth_tune_configuration_parameters_with_http_info(path, auth_tune_configuration_parameters_request)

```ruby
begin
  # Tune configuration parameters for a given auth path.
  data, status_code, headers = api_instance.auth_tune_configuration_parameters_with_http_info(path, auth_tune_configuration_parameters_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->auth_tune_configuration_parameters_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Tune the configuration parameters for an auth path. |  |
| **auth_tune_configuration_parameters_request** | [**AuthTuneConfigurationParametersRequest**](AuthTuneConfigurationParametersRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## collect_host_information

> <CollectHostInformationResponse> collect_host_information

Information about the host instance that this OpenBao server is running on.

Information about the host instance that this OpenBao server is running on.   The information that gets collected includes host hardware information, and CPU,   disk, and memory utilization

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Information about the host instance that this OpenBao server is running on.
  result = api_instance.collect_host_information
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->collect_host_information: #{e}"
end
```

#### Using the collect_host_information_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<CollectHostInformationResponse>, Integer, Hash)> collect_host_information_with_http_info

```ruby
begin
  # Information about the host instance that this OpenBao server is running on.
  data, status_code, headers = api_instance.collect_host_information_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <CollectHostInformationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->collect_host_information_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**CollectHostInformationResponse**](CollectHostInformationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## collect_in_flight_request_information

> collect_in_flight_request_information

reports in-flight requests

This path responds to the following HTTP methods.   GET /    Returns a map of in-flight requests.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # reports in-flight requests
  api_instance.collect_in_flight_request_information
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->collect_in_flight_request_information: #{e}"
end
```

#### Using the collect_in_flight_request_information_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> collect_in_flight_request_information_with_http_info

```ruby
begin
  # reports in-flight requests
  data, status_code, headers = api_instance.collect_in_flight_request_information_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->collect_in_flight_request_information_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cors_configure

> cors_configure(cors_configure_request)

Configure the CORS settings.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
cors_configure_request = OpenbaoClient::CorsConfigureRequest.new # CorsConfigureRequest | 

begin
  # Configure the CORS settings.
  api_instance.cors_configure(cors_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->cors_configure: #{e}"
end
```

#### Using the cors_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cors_configure_with_http_info(cors_configure_request)

```ruby
begin
  # Configure the CORS settings.
  data, status_code, headers = api_instance.cors_configure_with_http_info(cors_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->cors_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cors_configure_request** | [**CorsConfigureRequest**](CorsConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## cors_delete_configuration

> cors_delete_configuration

Remove any CORS settings.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Remove any CORS settings.
  api_instance.cors_delete_configuration
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->cors_delete_configuration: #{e}"
end
```

#### Using the cors_delete_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cors_delete_configuration_with_http_info

```ruby
begin
  # Remove any CORS settings.
  data, status_code, headers = api_instance.cors_delete_configuration_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->cors_delete_configuration_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cors_read_configuration

> <CorsReadConfigurationResponse> cors_read_configuration

Return the current CORS settings.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Return the current CORS settings.
  result = api_instance.cors_read_configuration
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->cors_read_configuration: #{e}"
end
```

#### Using the cors_read_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<CorsReadConfigurationResponse>, Integer, Hash)> cors_read_configuration_with_http_info

```ruby
begin
  # Return the current CORS settings.
  data, status_code, headers = api_instance.cors_read_configuration_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <CorsReadConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->cors_read_configuration_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**CorsReadConfigurationResponse**](CorsReadConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## decode

> decode(decode_request)

Decodes the encoded token with the otp.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
decode_request = OpenbaoClient::DecodeRequest.new # DecodeRequest | 

begin
  # Decodes the encoded token with the otp.
  api_instance.decode(decode_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->decode: #{e}"
end
```

#### Using the decode_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> decode_with_http_info(decode_request)

```ruby
begin
  # Decodes the encoded token with the otp.
  data, status_code, headers = api_instance.decode_with_http_info(decode_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->decode_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **decode_request** | [**DecodeRequest**](DecodeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## encryption_key_configure_rotation

> encryption_key_configure_rotation(encryption_key_configure_rotation_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
encryption_key_configure_rotation_request = OpenbaoClient::EncryptionKeyConfigureRotationRequest.new # EncryptionKeyConfigureRotationRequest | 

begin
  
  api_instance.encryption_key_configure_rotation(encryption_key_configure_rotation_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->encryption_key_configure_rotation: #{e}"
end
```

#### Using the encryption_key_configure_rotation_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> encryption_key_configure_rotation_with_http_info(encryption_key_configure_rotation_request)

```ruby
begin
  
  data, status_code, headers = api_instance.encryption_key_configure_rotation_with_http_info(encryption_key_configure_rotation_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->encryption_key_configure_rotation_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **encryption_key_configure_rotation_request** | [**EncryptionKeyConfigureRotationRequest**](EncryptionKeyConfigureRotationRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## encryption_key_read_rotation_configuration

> <EncryptionKeyReadRotationConfigurationResponse> encryption_key_read_rotation_configuration



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  result = api_instance.encryption_key_read_rotation_configuration
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->encryption_key_read_rotation_configuration: #{e}"
end
```

#### Using the encryption_key_read_rotation_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<EncryptionKeyReadRotationConfigurationResponse>, Integer, Hash)> encryption_key_read_rotation_configuration_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.encryption_key_read_rotation_configuration_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <EncryptionKeyReadRotationConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->encryption_key_read_rotation_configuration_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**EncryptionKeyReadRotationConfigurationResponse**](EncryptionKeyReadRotationConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## encryption_key_rotate

> encryption_key_rotate



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  api_instance.encryption_key_rotate
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->encryption_key_rotate: #{e}"
end
```

#### Using the encryption_key_rotate_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> encryption_key_rotate_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.encryption_key_rotate_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->encryption_key_rotate_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## encryption_key_status

> encryption_key_status

Provides information about the backend encryption key.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Provides information about the backend encryption key.
  api_instance.encryption_key_status
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->encryption_key_status: #{e}"
end
```

#### Using the encryption_key_status_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> encryption_key_status_with_http_info

```ruby
begin
  # Provides information about the backend encryption key.
  data, status_code, headers = api_instance.encryption_key_status_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->encryption_key_status_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## generate_hash

> <GenerateHashResponse> generate_hash(generate_hash_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
generate_hash_request = OpenbaoClient::GenerateHashRequest.new # GenerateHashRequest | 

begin
  
  result = api_instance.generate_hash(generate_hash_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_hash: #{e}"
end
```

#### Using the generate_hash_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GenerateHashResponse>, Integer, Hash)> generate_hash_with_http_info(generate_hash_request)

```ruby
begin
  
  data, status_code, headers = api_instance.generate_hash_with_http_info(generate_hash_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GenerateHashResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_hash_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **generate_hash_request** | [**GenerateHashRequest**](GenerateHashRequest.md) |  |  |

### Return type

[**GenerateHashResponse**](GenerateHashResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## generate_hash_with_algorithm

> <GenerateHashWithAlgorithmResponse> generate_hash_with_algorithm(urlalgorithm, generate_hash_with_algorithm_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
urlalgorithm = 'urlalgorithm_example' # String | Algorithm to use (POST URL parameter)
generate_hash_with_algorithm_request = OpenbaoClient::GenerateHashWithAlgorithmRequest.new # GenerateHashWithAlgorithmRequest | 

begin
  
  result = api_instance.generate_hash_with_algorithm(urlalgorithm, generate_hash_with_algorithm_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_hash_with_algorithm: #{e}"
end
```

#### Using the generate_hash_with_algorithm_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GenerateHashWithAlgorithmResponse>, Integer, Hash)> generate_hash_with_algorithm_with_http_info(urlalgorithm, generate_hash_with_algorithm_request)

```ruby
begin
  
  data, status_code, headers = api_instance.generate_hash_with_algorithm_with_http_info(urlalgorithm, generate_hash_with_algorithm_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GenerateHashWithAlgorithmResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_hash_with_algorithm_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **urlalgorithm** | **String** | Algorithm to use (POST URL parameter) |  |
| **generate_hash_with_algorithm_request** | [**GenerateHashWithAlgorithmRequest**](GenerateHashWithAlgorithmRequest.md) |  |  |

### Return type

[**GenerateHashWithAlgorithmResponse**](GenerateHashWithAlgorithmResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## generate_random

> <GenerateRandomResponse> generate_random(generate_random_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
generate_random_request = OpenbaoClient::GenerateRandomRequest.new # GenerateRandomRequest | 

begin
  
  result = api_instance.generate_random(generate_random_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_random: #{e}"
end
```

#### Using the generate_random_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GenerateRandomResponse>, Integer, Hash)> generate_random_with_http_info(generate_random_request)

```ruby
begin
  
  data, status_code, headers = api_instance.generate_random_with_http_info(generate_random_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GenerateRandomResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_random_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **generate_random_request** | [**GenerateRandomRequest**](GenerateRandomRequest.md) |  |  |

### Return type

[**GenerateRandomResponse**](GenerateRandomResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## generate_random_with_bytes

> <GenerateRandomWithBytesResponse> generate_random_with_bytes(urlbytes, generate_random_with_bytes_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
urlbytes = 'urlbytes_example' # String | The number of bytes to generate (POST URL parameter)
generate_random_with_bytes_request = OpenbaoClient::GenerateRandomWithBytesRequest.new # GenerateRandomWithBytesRequest | 

begin
  
  result = api_instance.generate_random_with_bytes(urlbytes, generate_random_with_bytes_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_random_with_bytes: #{e}"
end
```

#### Using the generate_random_with_bytes_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GenerateRandomWithBytesResponse>, Integer, Hash)> generate_random_with_bytes_with_http_info(urlbytes, generate_random_with_bytes_request)

```ruby
begin
  
  data, status_code, headers = api_instance.generate_random_with_bytes_with_http_info(urlbytes, generate_random_with_bytes_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GenerateRandomWithBytesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_random_with_bytes_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **urlbytes** | **String** | The number of bytes to generate (POST URL parameter) |  |
| **generate_random_with_bytes_request** | [**GenerateRandomWithBytesRequest**](GenerateRandomWithBytesRequest.md) |  |  |

### Return type

[**GenerateRandomWithBytesResponse**](GenerateRandomWithBytesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## generate_random_with_source

> <GenerateRandomWithSourceResponse> generate_random_with_source(source, generate_random_with_source_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
source = 'source_example' # String | Which system to source random data from, ether \"platform\", \"seal\", or \"all\".
generate_random_with_source_request = OpenbaoClient::GenerateRandomWithSourceRequest.new # GenerateRandomWithSourceRequest | 

begin
  
  result = api_instance.generate_random_with_source(source, generate_random_with_source_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_random_with_source: #{e}"
end
```

#### Using the generate_random_with_source_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GenerateRandomWithSourceResponse>, Integer, Hash)> generate_random_with_source_with_http_info(source, generate_random_with_source_request)

```ruby
begin
  
  data, status_code, headers = api_instance.generate_random_with_source_with_http_info(source, generate_random_with_source_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GenerateRandomWithSourceResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_random_with_source_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **source** | **String** | Which system to source random data from, ether \&quot;platform\&quot;, \&quot;seal\&quot;, or \&quot;all\&quot;. | [default to &#39;platform&#39;] |
| **generate_random_with_source_request** | [**GenerateRandomWithSourceRequest**](GenerateRandomWithSourceRequest.md) |  |  |

### Return type

[**GenerateRandomWithSourceResponse**](GenerateRandomWithSourceResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## generate_random_with_source_and_bytes

> <GenerateRandomWithSourceAndBytesResponse> generate_random_with_source_and_bytes(source, urlbytes, generate_random_with_source_and_bytes_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
source = 'source_example' # String | Which system to source random data from, ether \"platform\", \"seal\", or \"all\".
urlbytes = 'urlbytes_example' # String | The number of bytes to generate (POST URL parameter)
generate_random_with_source_and_bytes_request = OpenbaoClient::GenerateRandomWithSourceAndBytesRequest.new # GenerateRandomWithSourceAndBytesRequest | 

begin
  
  result = api_instance.generate_random_with_source_and_bytes(source, urlbytes, generate_random_with_source_and_bytes_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_random_with_source_and_bytes: #{e}"
end
```

#### Using the generate_random_with_source_and_bytes_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<GenerateRandomWithSourceAndBytesResponse>, Integer, Hash)> generate_random_with_source_and_bytes_with_http_info(source, urlbytes, generate_random_with_source_and_bytes_request)

```ruby
begin
  
  data, status_code, headers = api_instance.generate_random_with_source_and_bytes_with_http_info(source, urlbytes, generate_random_with_source_and_bytes_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <GenerateRandomWithSourceAndBytesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->generate_random_with_source_and_bytes_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **source** | **String** | Which system to source random data from, ether \&quot;platform\&quot;, \&quot;seal\&quot;, or \&quot;all\&quot;. | [default to &#39;platform&#39;] |
| **urlbytes** | **String** | The number of bytes to generate (POST URL parameter) |  |
| **generate_random_with_source_and_bytes_request** | [**GenerateRandomWithSourceAndBytesRequest**](GenerateRandomWithSourceAndBytesRequest.md) |  |  |

### Return type

[**GenerateRandomWithSourceAndBytesResponse**](GenerateRandomWithSourceAndBytesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## ha_status

> <HaStatusResponse> ha_status

Check the HA status of an OpenBao cluster

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Check the HA status of an OpenBao cluster
  result = api_instance.ha_status
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->ha_status: #{e}"
end
```

#### Using the ha_status_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<HaStatusResponse>, Integer, Hash)> ha_status_with_http_info

```ruby
begin
  # Check the HA status of an OpenBao cluster
  data, status_code, headers = api_instance.ha_status_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <HaStatusResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->ha_status_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**HaStatusResponse**](HaStatusResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## initialize

> initialize(initialize_request)

Initialize a new OpenBao instance.

The OpenBao instance must not have been previously initialized. The recovery options, as well as the stored shares option, are only available when using OpenBao HSM.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
initialize_request = OpenbaoClient::InitializeRequest.new # InitializeRequest | 

begin
  # Initialize a new OpenBao instance.
  api_instance.initialize(initialize_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->initialize: #{e}"
end
```

#### Using the initialize_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> initialize_with_http_info(initialize_request)

```ruby
begin
  # Initialize a new OpenBao instance.
  data, status_code, headers = api_instance.initialize_with_http_info(initialize_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->initialize_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **initialize_request** | [**InitializeRequest**](InitializeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## internal_count_entities

> <InternalCountEntitiesResponse> internal_count_entities

Backwards compatibility is not guaranteed for this API

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Backwards compatibility is not guaranteed for this API
  result = api_instance.internal_count_entities
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_count_entities: #{e}"
end
```

#### Using the internal_count_entities_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InternalCountEntitiesResponse>, Integer, Hash)> internal_count_entities_with_http_info

```ruby
begin
  # Backwards compatibility is not guaranteed for this API
  data, status_code, headers = api_instance.internal_count_entities_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InternalCountEntitiesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_count_entities_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**InternalCountEntitiesResponse**](InternalCountEntitiesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## internal_count_requests

> internal_count_requests

Backwards compatibility is not guaranteed for this API

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Backwards compatibility is not guaranteed for this API
  api_instance.internal_count_requests
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_count_requests: #{e}"
end
```

#### Using the internal_count_requests_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> internal_count_requests_with_http_info

```ruby
begin
  # Backwards compatibility is not guaranteed for this API
  data, status_code, headers = api_instance.internal_count_requests_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_count_requests_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## internal_count_tokens

> <InternalCountTokensResponse> internal_count_tokens

Backwards compatibility is not guaranteed for this API

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Backwards compatibility is not guaranteed for this API
  result = api_instance.internal_count_tokens
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_count_tokens: #{e}"
end
```

#### Using the internal_count_tokens_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InternalCountTokensResponse>, Integer, Hash)> internal_count_tokens_with_http_info

```ruby
begin
  # Backwards compatibility is not guaranteed for this API
  data, status_code, headers = api_instance.internal_count_tokens_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InternalCountTokensResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_count_tokens_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**InternalCountTokensResponse**](InternalCountTokensResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## internal_generate_open_api_document

> internal_generate_open_api_document(opts)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
opts = {
  generic_mount_paths: true # Boolean | Use generic mount paths
}

begin
  
  api_instance.internal_generate_open_api_document(opts)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_generate_open_api_document: #{e}"
end
```

#### Using the internal_generate_open_api_document_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> internal_generate_open_api_document_with_http_info(opts)

```ruby
begin
  
  data, status_code, headers = api_instance.internal_generate_open_api_document_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_generate_open_api_document_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **generic_mount_paths** | **Boolean** | Use generic mount paths | [optional][default to false] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## internal_generate_open_api_document_with_parameters

> internal_generate_open_api_document_with_parameters(internal_generate_open_api_document_with_parameters_request, opts)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
internal_generate_open_api_document_with_parameters_request = OpenbaoClient::InternalGenerateOpenApiDocumentWithParametersRequest.new # InternalGenerateOpenApiDocumentWithParametersRequest | 
opts = {
  generic_mount_paths: true # Boolean | Use generic mount paths
}

begin
  
  api_instance.internal_generate_open_api_document_with_parameters(internal_generate_open_api_document_with_parameters_request, opts)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_generate_open_api_document_with_parameters: #{e}"
end
```

#### Using the internal_generate_open_api_document_with_parameters_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> internal_generate_open_api_document_with_parameters_with_http_info(internal_generate_open_api_document_with_parameters_request, opts)

```ruby
begin
  
  data, status_code, headers = api_instance.internal_generate_open_api_document_with_parameters_with_http_info(internal_generate_open_api_document_with_parameters_request, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_generate_open_api_document_with_parameters_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **internal_generate_open_api_document_with_parameters_request** | [**InternalGenerateOpenApiDocumentWithParametersRequest**](InternalGenerateOpenApiDocumentWithParametersRequest.md) |  |  |
| **generic_mount_paths** | **Boolean** | Use generic mount paths | [optional][default to false] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## internal_inspect_router

> internal_inspect_router(tag)

Expose the route entry and mount entry tables present in the router

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
tag = 'tag_example' # String | Name of subtree being observed

begin
  # Expose the route entry and mount entry tables present in the router
  api_instance.internal_inspect_router(tag)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_inspect_router: #{e}"
end
```

#### Using the internal_inspect_router_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> internal_inspect_router_with_http_info(tag)

```ruby
begin
  # Expose the route entry and mount entry tables present in the router
  data, status_code, headers = api_instance.internal_inspect_router_with_http_info(tag)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_inspect_router_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **tag** | **String** | Name of subtree being observed |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## internal_ui_list_enabled_feature_flags

> <InternalUiListEnabledFeatureFlagsResponse> internal_ui_list_enabled_feature_flags

Lists enabled feature flags.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Lists enabled feature flags.
  result = api_instance.internal_ui_list_enabled_feature_flags
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_ui_list_enabled_feature_flags: #{e}"
end
```

#### Using the internal_ui_list_enabled_feature_flags_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InternalUiListEnabledFeatureFlagsResponse>, Integer, Hash)> internal_ui_list_enabled_feature_flags_with_http_info

```ruby
begin
  # Lists enabled feature flags.
  data, status_code, headers = api_instance.internal_ui_list_enabled_feature_flags_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InternalUiListEnabledFeatureFlagsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_ui_list_enabled_feature_flags_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**InternalUiListEnabledFeatureFlagsResponse**](InternalUiListEnabledFeatureFlagsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## internal_ui_list_enabled_visible_mounts

> <InternalUiListEnabledVisibleMountsResponse> internal_ui_list_enabled_visible_mounts

Lists all enabled and visible auth and secrets mounts.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Lists all enabled and visible auth and secrets mounts.
  result = api_instance.internal_ui_list_enabled_visible_mounts
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_ui_list_enabled_visible_mounts: #{e}"
end
```

#### Using the internal_ui_list_enabled_visible_mounts_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InternalUiListEnabledVisibleMountsResponse>, Integer, Hash)> internal_ui_list_enabled_visible_mounts_with_http_info

```ruby
begin
  # Lists all enabled and visible auth and secrets mounts.
  data, status_code, headers = api_instance.internal_ui_list_enabled_visible_mounts_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InternalUiListEnabledVisibleMountsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_ui_list_enabled_visible_mounts_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**InternalUiListEnabledVisibleMountsResponse**](InternalUiListEnabledVisibleMountsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## internal_ui_list_namespaces

> <InternalUiListNamespacesResponse> internal_ui_list_namespaces

Backwards compatibility is not guaranteed for this API

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Backwards compatibility is not guaranteed for this API
  result = api_instance.internal_ui_list_namespaces
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_ui_list_namespaces: #{e}"
end
```

#### Using the internal_ui_list_namespaces_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InternalUiListNamespacesResponse>, Integer, Hash)> internal_ui_list_namespaces_with_http_info

```ruby
begin
  # Backwards compatibility is not guaranteed for this API
  data, status_code, headers = api_instance.internal_ui_list_namespaces_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InternalUiListNamespacesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_ui_list_namespaces_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**InternalUiListNamespacesResponse**](InternalUiListNamespacesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## internal_ui_read_mount_information

> <InternalUiReadMountInformationResponse> internal_ui_read_mount_information(path)

Return information about the given mount.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The path of the mount.

begin
  # Return information about the given mount.
  result = api_instance.internal_ui_read_mount_information(path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_ui_read_mount_information: #{e}"
end
```

#### Using the internal_ui_read_mount_information_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InternalUiReadMountInformationResponse>, Integer, Hash)> internal_ui_read_mount_information_with_http_info(path)

```ruby
begin
  # Return information about the given mount.
  data, status_code, headers = api_instance.internal_ui_read_mount_information_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InternalUiReadMountInformationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_ui_read_mount_information_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The path of the mount. |  |

### Return type

[**InternalUiReadMountInformationResponse**](InternalUiReadMountInformationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## internal_ui_read_resultant_acl

> <InternalUiReadResultantAclResponse> internal_ui_read_resultant_acl

Backwards compatibility is not guaranteed for this API

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Backwards compatibility is not guaranteed for this API
  result = api_instance.internal_ui_read_resultant_acl
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_ui_read_resultant_acl: #{e}"
end
```

#### Using the internal_ui_read_resultant_acl_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<InternalUiReadResultantAclResponse>, Integer, Hash)> internal_ui_read_resultant_acl_with_http_info

```ruby
begin
  # Backwards compatibility is not guaranteed for this API
  data, status_code, headers = api_instance.internal_ui_read_resultant_acl_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <InternalUiReadResultantAclResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->internal_ui_read_resultant_acl_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**InternalUiReadResultantAclResponse**](InternalUiReadResultantAclResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## leader_status

> <LeaderStatusResponse> leader_status

Returns the high availability status and current leader instance of OpenBao.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns the high availability status and current leader instance of OpenBao.
  result = api_instance.leader_status
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leader_status: #{e}"
end
```

#### Using the leader_status_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LeaderStatusResponse>, Integer, Hash)> leader_status_with_http_info

```ruby
begin
  # Returns the high availability status and current leader instance of OpenBao.
  data, status_code, headers = api_instance.leader_status_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LeaderStatusResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leader_status_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**LeaderStatusResponse**](LeaderStatusResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## leases_count

> <LeasesCountResponse> leases_count



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  result = api_instance.leases_count
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_count: #{e}"
end
```

#### Using the leases_count_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LeasesCountResponse>, Integer, Hash)> leases_count_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.leases_count_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LeasesCountResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_count_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**LeasesCountResponse**](LeasesCountResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## leases_force_revoke_lease_with_prefix

> leases_force_revoke_lease_with_prefix(prefix)

Revokes all secrets or tokens generated under a given prefix immediately

Unlike `/sys/leases/revoke-prefix`, this path ignores backend errors encountered during revocation. This is potentially very dangerous and should only be used in specific emergency situations where errors in the backend or the connected backend service prevent normal revocation.  By ignoring these errors, OpenBao abdicates responsibility for ensuring that the issued credentials or secrets are properly revoked and/or cleaned up. Access to this endpoint should be tightly controlled.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
prefix = 'prefix_example' # String | The path to revoke keys under. Example: \"prod/aws/ops\"

begin
  # Revokes all secrets or tokens generated under a given prefix immediately
  api_instance.leases_force_revoke_lease_with_prefix(prefix)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_force_revoke_lease_with_prefix: #{e}"
end
```

#### Using the leases_force_revoke_lease_with_prefix_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_force_revoke_lease_with_prefix_with_http_info(prefix)

```ruby
begin
  # Revokes all secrets or tokens generated under a given prefix immediately
  data, status_code, headers = api_instance.leases_force_revoke_lease_with_prefix_with_http_info(prefix)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_force_revoke_lease_with_prefix_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **prefix** | **String** | The path to revoke keys under. Example: \&quot;prod/aws/ops\&quot; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## leases_force_revoke_lease_with_prefix2

> leases_force_revoke_lease_with_prefix2(prefix)

Revokes all secrets or tokens generated under a given prefix immediately

Unlike `/sys/leases/revoke-prefix`, this path ignores backend errors encountered during revocation. This is potentially very dangerous and should only be used in specific emergency situations where errors in the backend or the connected backend service prevent normal revocation.  By ignoring these errors, OpenBao abdicates responsibility for ensuring that the issued credentials or secrets are properly revoked and/or cleaned up. Access to this endpoint should be tightly controlled.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
prefix = 'prefix_example' # String | The path to revoke keys under. Example: \"prod/aws/ops\"

begin
  # Revokes all secrets or tokens generated under a given prefix immediately
  api_instance.leases_force_revoke_lease_with_prefix2(prefix)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_force_revoke_lease_with_prefix2: #{e}"
end
```

#### Using the leases_force_revoke_lease_with_prefix2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_force_revoke_lease_with_prefix2_with_http_info(prefix)

```ruby
begin
  # Revokes all secrets or tokens generated under a given prefix immediately
  data, status_code, headers = api_instance.leases_force_revoke_lease_with_prefix2_with_http_info(prefix)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_force_revoke_lease_with_prefix2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **prefix** | **String** | The path to revoke keys under. Example: \&quot;prod/aws/ops\&quot; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## leases_list

> <LeasesListResponse> leases_list



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  result = api_instance.leases_list
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_list: #{e}"
end
```

#### Using the leases_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LeasesListResponse>, Integer, Hash)> leases_list_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.leases_list_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LeasesListResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_list_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**LeasesListResponse**](LeasesListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## leases_look_up

> <LeasesLookUpResponse> leases_look_up(list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.leases_look_up(list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_look_up: #{e}"
end
```

#### Using the leases_look_up_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LeasesLookUpResponse>, Integer, Hash)> leases_look_up_with_http_info(list)

```ruby
begin
  
  data, status_code, headers = api_instance.leases_look_up_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LeasesLookUpResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_look_up_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**LeasesLookUpResponse**](LeasesLookUpResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## leases_look_up_with_prefix

> <LeasesLookUpWithPrefixResponse> leases_look_up_with_prefix(prefix, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
prefix = 'prefix_example' # String | The path to list leases under. Example: \"aws/creds/deploy\"
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.leases_look_up_with_prefix(prefix, list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_look_up_with_prefix: #{e}"
end
```

#### Using the leases_look_up_with_prefix_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LeasesLookUpWithPrefixResponse>, Integer, Hash)> leases_look_up_with_prefix_with_http_info(prefix, list)

```ruby
begin
  
  data, status_code, headers = api_instance.leases_look_up_with_prefix_with_http_info(prefix, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LeasesLookUpWithPrefixResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_look_up_with_prefix_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **prefix** | **String** | The path to list leases under. Example: \&quot;aws/creds/deploy\&quot; |  |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**LeasesLookUpWithPrefixResponse**](LeasesLookUpWithPrefixResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## leases_read_lease

> <LeasesReadLeaseResponse> leases_read_lease(leases_read_lease_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
leases_read_lease_request = OpenbaoClient::LeasesReadLeaseRequest.new # LeasesReadLeaseRequest | 

begin
  
  result = api_instance.leases_read_lease(leases_read_lease_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_read_lease: #{e}"
end
```

#### Using the leases_read_lease_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<LeasesReadLeaseResponse>, Integer, Hash)> leases_read_lease_with_http_info(leases_read_lease_request)

```ruby
begin
  
  data, status_code, headers = api_instance.leases_read_lease_with_http_info(leases_read_lease_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <LeasesReadLeaseResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_read_lease_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **leases_read_lease_request** | [**LeasesReadLeaseRequest**](LeasesReadLeaseRequest.md) |  |  |

### Return type

[**LeasesReadLeaseResponse**](LeasesReadLeaseResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## leases_renew_lease

> leases_renew_lease(leases_renew_lease_request)

Renews a lease, requesting to extend the lease.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
leases_renew_lease_request = OpenbaoClient::LeasesRenewLeaseRequest.new # LeasesRenewLeaseRequest | 

begin
  # Renews a lease, requesting to extend the lease.
  api_instance.leases_renew_lease(leases_renew_lease_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_renew_lease: #{e}"
end
```

#### Using the leases_renew_lease_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_renew_lease_with_http_info(leases_renew_lease_request)

```ruby
begin
  # Renews a lease, requesting to extend the lease.
  data, status_code, headers = api_instance.leases_renew_lease_with_http_info(leases_renew_lease_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_renew_lease_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **leases_renew_lease_request** | [**LeasesRenewLeaseRequest**](LeasesRenewLeaseRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## leases_renew_lease2

> leases_renew_lease2(leases_renew_lease2_request)

Renews a lease, requesting to extend the lease.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
leases_renew_lease2_request = OpenbaoClient::LeasesRenewLease2Request.new # LeasesRenewLease2Request | 

begin
  # Renews a lease, requesting to extend the lease.
  api_instance.leases_renew_lease2(leases_renew_lease2_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_renew_lease2: #{e}"
end
```

#### Using the leases_renew_lease2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_renew_lease2_with_http_info(leases_renew_lease2_request)

```ruby
begin
  # Renews a lease, requesting to extend the lease.
  data, status_code, headers = api_instance.leases_renew_lease2_with_http_info(leases_renew_lease2_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_renew_lease2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **leases_renew_lease2_request** | [**LeasesRenewLease2Request**](LeasesRenewLease2Request.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## leases_renew_lease_with_id

> leases_renew_lease_with_id(url_lease_id, leases_renew_lease_with_id_request)

Renews a lease, requesting to extend the lease.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
url_lease_id = 'url_lease_id_example' # String | The lease identifier to renew. This is included with a lease.
leases_renew_lease_with_id_request = OpenbaoClient::LeasesRenewLeaseWithIdRequest.new # LeasesRenewLeaseWithIdRequest | 

begin
  # Renews a lease, requesting to extend the lease.
  api_instance.leases_renew_lease_with_id(url_lease_id, leases_renew_lease_with_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_renew_lease_with_id: #{e}"
end
```

#### Using the leases_renew_lease_with_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_renew_lease_with_id_with_http_info(url_lease_id, leases_renew_lease_with_id_request)

```ruby
begin
  # Renews a lease, requesting to extend the lease.
  data, status_code, headers = api_instance.leases_renew_lease_with_id_with_http_info(url_lease_id, leases_renew_lease_with_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_renew_lease_with_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **url_lease_id** | **String** | The lease identifier to renew. This is included with a lease. |  |
| **leases_renew_lease_with_id_request** | [**LeasesRenewLeaseWithIdRequest**](LeasesRenewLeaseWithIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## leases_renew_lease_with_id2

> leases_renew_lease_with_id2(url_lease_id, leases_renew_lease_with_id2_request)

Renews a lease, requesting to extend the lease.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
url_lease_id = 'url_lease_id_example' # String | The lease identifier to renew. This is included with a lease.
leases_renew_lease_with_id2_request = OpenbaoClient::LeasesRenewLeaseWithId2Request.new # LeasesRenewLeaseWithId2Request | 

begin
  # Renews a lease, requesting to extend the lease.
  api_instance.leases_renew_lease_with_id2(url_lease_id, leases_renew_lease_with_id2_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_renew_lease_with_id2: #{e}"
end
```

#### Using the leases_renew_lease_with_id2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_renew_lease_with_id2_with_http_info(url_lease_id, leases_renew_lease_with_id2_request)

```ruby
begin
  # Renews a lease, requesting to extend the lease.
  data, status_code, headers = api_instance.leases_renew_lease_with_id2_with_http_info(url_lease_id, leases_renew_lease_with_id2_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_renew_lease_with_id2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **url_lease_id** | **String** | The lease identifier to renew. This is included with a lease. |  |
| **leases_renew_lease_with_id2_request** | [**LeasesRenewLeaseWithId2Request**](LeasesRenewLeaseWithId2Request.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## leases_revoke_lease

> leases_revoke_lease(leases_revoke_lease_request)

Revokes a lease immediately.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
leases_revoke_lease_request = OpenbaoClient::LeasesRevokeLeaseRequest.new # LeasesRevokeLeaseRequest | 

begin
  # Revokes a lease immediately.
  api_instance.leases_revoke_lease(leases_revoke_lease_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease: #{e}"
end
```

#### Using the leases_revoke_lease_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_revoke_lease_with_http_info(leases_revoke_lease_request)

```ruby
begin
  # Revokes a lease immediately.
  data, status_code, headers = api_instance.leases_revoke_lease_with_http_info(leases_revoke_lease_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **leases_revoke_lease_request** | [**LeasesRevokeLeaseRequest**](LeasesRevokeLeaseRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## leases_revoke_lease2

> leases_revoke_lease2(leases_revoke_lease2_request)

Revokes a lease immediately.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
leases_revoke_lease2_request = OpenbaoClient::LeasesRevokeLease2Request.new # LeasesRevokeLease2Request | 

begin
  # Revokes a lease immediately.
  api_instance.leases_revoke_lease2(leases_revoke_lease2_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease2: #{e}"
end
```

#### Using the leases_revoke_lease2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_revoke_lease2_with_http_info(leases_revoke_lease2_request)

```ruby
begin
  # Revokes a lease immediately.
  data, status_code, headers = api_instance.leases_revoke_lease2_with_http_info(leases_revoke_lease2_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **leases_revoke_lease2_request** | [**LeasesRevokeLease2Request**](LeasesRevokeLease2Request.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## leases_revoke_lease_with_id

> leases_revoke_lease_with_id(url_lease_id, leases_revoke_lease_with_id_request)

Revokes a lease immediately.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
url_lease_id = 'url_lease_id_example' # String | The lease identifier to renew. This is included with a lease.
leases_revoke_lease_with_id_request = OpenbaoClient::LeasesRevokeLeaseWithIdRequest.new # LeasesRevokeLeaseWithIdRequest | 

begin
  # Revokes a lease immediately.
  api_instance.leases_revoke_lease_with_id(url_lease_id, leases_revoke_lease_with_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease_with_id: #{e}"
end
```

#### Using the leases_revoke_lease_with_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_revoke_lease_with_id_with_http_info(url_lease_id, leases_revoke_lease_with_id_request)

```ruby
begin
  # Revokes a lease immediately.
  data, status_code, headers = api_instance.leases_revoke_lease_with_id_with_http_info(url_lease_id, leases_revoke_lease_with_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease_with_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **url_lease_id** | **String** | The lease identifier to renew. This is included with a lease. |  |
| **leases_revoke_lease_with_id_request** | [**LeasesRevokeLeaseWithIdRequest**](LeasesRevokeLeaseWithIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## leases_revoke_lease_with_id2

> leases_revoke_lease_with_id2(url_lease_id, leases_revoke_lease_with_id2_request)

Revokes a lease immediately.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
url_lease_id = 'url_lease_id_example' # String | The lease identifier to renew. This is included with a lease.
leases_revoke_lease_with_id2_request = OpenbaoClient::LeasesRevokeLeaseWithId2Request.new # LeasesRevokeLeaseWithId2Request | 

begin
  # Revokes a lease immediately.
  api_instance.leases_revoke_lease_with_id2(url_lease_id, leases_revoke_lease_with_id2_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease_with_id2: #{e}"
end
```

#### Using the leases_revoke_lease_with_id2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_revoke_lease_with_id2_with_http_info(url_lease_id, leases_revoke_lease_with_id2_request)

```ruby
begin
  # Revokes a lease immediately.
  data, status_code, headers = api_instance.leases_revoke_lease_with_id2_with_http_info(url_lease_id, leases_revoke_lease_with_id2_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease_with_id2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **url_lease_id** | **String** | The lease identifier to renew. This is included with a lease. |  |
| **leases_revoke_lease_with_id2_request** | [**LeasesRevokeLeaseWithId2Request**](LeasesRevokeLeaseWithId2Request.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## leases_revoke_lease_with_prefix

> leases_revoke_lease_with_prefix(prefix, leases_revoke_lease_with_prefix_request)

Revokes all secrets (via a lease ID prefix) or tokens (via the tokens' path property) generated under a given prefix immediately.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
prefix = 'prefix_example' # String | The path to revoke keys under. Example: \"prod/aws/ops\"
leases_revoke_lease_with_prefix_request = OpenbaoClient::LeasesRevokeLeaseWithPrefixRequest.new # LeasesRevokeLeaseWithPrefixRequest | 

begin
  # Revokes all secrets (via a lease ID prefix) or tokens (via the tokens' path property) generated under a given prefix immediately.
  api_instance.leases_revoke_lease_with_prefix(prefix, leases_revoke_lease_with_prefix_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease_with_prefix: #{e}"
end
```

#### Using the leases_revoke_lease_with_prefix_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_revoke_lease_with_prefix_with_http_info(prefix, leases_revoke_lease_with_prefix_request)

```ruby
begin
  # Revokes all secrets (via a lease ID prefix) or tokens (via the tokens' path property) generated under a given prefix immediately.
  data, status_code, headers = api_instance.leases_revoke_lease_with_prefix_with_http_info(prefix, leases_revoke_lease_with_prefix_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease_with_prefix_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **prefix** | **String** | The path to revoke keys under. Example: \&quot;prod/aws/ops\&quot; |  |
| **leases_revoke_lease_with_prefix_request** | [**LeasesRevokeLeaseWithPrefixRequest**](LeasesRevokeLeaseWithPrefixRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## leases_revoke_lease_with_prefix2

> leases_revoke_lease_with_prefix2(prefix, leases_revoke_lease_with_prefix2_request)

Revokes all secrets (via a lease ID prefix) or tokens (via the tokens' path property) generated under a given prefix immediately.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
prefix = 'prefix_example' # String | The path to revoke keys under. Example: \"prod/aws/ops\"
leases_revoke_lease_with_prefix2_request = OpenbaoClient::LeasesRevokeLeaseWithPrefix2Request.new # LeasesRevokeLeaseWithPrefix2Request | 

begin
  # Revokes all secrets (via a lease ID prefix) or tokens (via the tokens' path property) generated under a given prefix immediately.
  api_instance.leases_revoke_lease_with_prefix2(prefix, leases_revoke_lease_with_prefix2_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease_with_prefix2: #{e}"
end
```

#### Using the leases_revoke_lease_with_prefix2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_revoke_lease_with_prefix2_with_http_info(prefix, leases_revoke_lease_with_prefix2_request)

```ruby
begin
  # Revokes all secrets (via a lease ID prefix) or tokens (via the tokens' path property) generated under a given prefix immediately.
  data, status_code, headers = api_instance.leases_revoke_lease_with_prefix2_with_http_info(prefix, leases_revoke_lease_with_prefix2_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_revoke_lease_with_prefix2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **prefix** | **String** | The path to revoke keys under. Example: \&quot;prod/aws/ops\&quot; |  |
| **leases_revoke_lease_with_prefix2_request** | [**LeasesRevokeLeaseWithPrefix2Request**](LeasesRevokeLeaseWithPrefix2Request.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## leases_tidy

> leases_tidy



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  api_instance.leases_tidy
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_tidy: #{e}"
end
```

#### Using the leases_tidy_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> leases_tidy_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.leases_tidy_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->leases_tidy_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## locked_users_list

> locked_users_list

Report the locked user count metrics, for this namespace and all child namespaces.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Report the locked user count metrics, for this namespace and all child namespaces.
  api_instance.locked_users_list
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->locked_users_list: #{e}"
end
```

#### Using the locked_users_list_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> locked_users_list_with_http_info

```ruby
begin
  # Report the locked user count metrics, for this namespace and all child namespaces.
  data, status_code, headers = api_instance.locked_users_list_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->locked_users_list_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## locked_users_unlock

> locked_users_unlock(alias_identifier, mount_accessor)

Unlocks the user with given mount_accessor and alias_identifier

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
alias_identifier = 'alias_identifier_example' # String | It is the name of the alias (user). For example, if the alias belongs to userpass backend, the name should be a valid username within userpass auth method. If the alias belongs to an approle auth method, the name should be a valid RoleID
mount_accessor = 'mount_accessor_example' # String | MountAccessor is the identifier of the mount entry to which the user belongs

begin
  # Unlocks the user with given mount_accessor and alias_identifier
  api_instance.locked_users_unlock(alias_identifier, mount_accessor)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->locked_users_unlock: #{e}"
end
```

#### Using the locked_users_unlock_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> locked_users_unlock_with_http_info(alias_identifier, mount_accessor)

```ruby
begin
  # Unlocks the user with given mount_accessor and alias_identifier
  data, status_code, headers = api_instance.locked_users_unlock_with_http_info(alias_identifier, mount_accessor)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->locked_users_unlock_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **alias_identifier** | **String** | It is the name of the alias (user). For example, if the alias belongs to userpass backend, the name should be a valid username within userpass auth method. If the alias belongs to an approle auth method, the name should be a valid RoleID |  |
| **mount_accessor** | **String** | MountAccessor is the identifier of the mount entry to which the user belongs |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## loggers_read_verbosity_level

> loggers_read_verbosity_level

Read the log level for all existing loggers.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Read the log level for all existing loggers.
  api_instance.loggers_read_verbosity_level
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_read_verbosity_level: #{e}"
end
```

#### Using the loggers_read_verbosity_level_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> loggers_read_verbosity_level_with_http_info

```ruby
begin
  # Read the log level for all existing loggers.
  data, status_code, headers = api_instance.loggers_read_verbosity_level_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_read_verbosity_level_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## loggers_read_verbosity_level_for

> loggers_read_verbosity_level_for(name)

Read the log level for a single logger.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the logger to be modified.

begin
  # Read the log level for a single logger.
  api_instance.loggers_read_verbosity_level_for(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_read_verbosity_level_for: #{e}"
end
```

#### Using the loggers_read_verbosity_level_for_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> loggers_read_verbosity_level_for_with_http_info(name)

```ruby
begin
  # Read the log level for a single logger.
  data, status_code, headers = api_instance.loggers_read_verbosity_level_for_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_read_verbosity_level_for_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the logger to be modified. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## loggers_revert_verbosity_level

> loggers_revert_verbosity_level

Revert the all loggers to use log level provided in config.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Revert the all loggers to use log level provided in config.
  api_instance.loggers_revert_verbosity_level
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_revert_verbosity_level: #{e}"
end
```

#### Using the loggers_revert_verbosity_level_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> loggers_revert_verbosity_level_with_http_info

```ruby
begin
  # Revert the all loggers to use log level provided in config.
  data, status_code, headers = api_instance.loggers_revert_verbosity_level_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_revert_verbosity_level_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## loggers_revert_verbosity_level_for

> loggers_revert_verbosity_level_for(name)

Revert a single logger to use log level provided in config.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the logger to be modified.

begin
  # Revert a single logger to use log level provided in config.
  api_instance.loggers_revert_verbosity_level_for(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_revert_verbosity_level_for: #{e}"
end
```

#### Using the loggers_revert_verbosity_level_for_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> loggers_revert_verbosity_level_for_with_http_info(name)

```ruby
begin
  # Revert a single logger to use log level provided in config.
  data, status_code, headers = api_instance.loggers_revert_verbosity_level_for_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_revert_verbosity_level_for_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the logger to be modified. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## loggers_update_verbosity_level

> loggers_update_verbosity_level(loggers_update_verbosity_level_request)

Modify the log level for all existing loggers.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
loggers_update_verbosity_level_request = OpenbaoClient::LoggersUpdateVerbosityLevelRequest.new # LoggersUpdateVerbosityLevelRequest | 

begin
  # Modify the log level for all existing loggers.
  api_instance.loggers_update_verbosity_level(loggers_update_verbosity_level_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_update_verbosity_level: #{e}"
end
```

#### Using the loggers_update_verbosity_level_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> loggers_update_verbosity_level_with_http_info(loggers_update_verbosity_level_request)

```ruby
begin
  # Modify the log level for all existing loggers.
  data, status_code, headers = api_instance.loggers_update_verbosity_level_with_http_info(loggers_update_verbosity_level_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_update_verbosity_level_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **loggers_update_verbosity_level_request** | [**LoggersUpdateVerbosityLevelRequest**](LoggersUpdateVerbosityLevelRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## loggers_update_verbosity_level_for

> loggers_update_verbosity_level_for(name, loggers_update_verbosity_level_for_request)

Modify the log level of a single logger.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the logger to be modified.
loggers_update_verbosity_level_for_request = OpenbaoClient::LoggersUpdateVerbosityLevelForRequest.new # LoggersUpdateVerbosityLevelForRequest | 

begin
  # Modify the log level of a single logger.
  api_instance.loggers_update_verbosity_level_for(name, loggers_update_verbosity_level_for_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_update_verbosity_level_for: #{e}"
end
```

#### Using the loggers_update_verbosity_level_for_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> loggers_update_verbosity_level_for_with_http_info(name, loggers_update_verbosity_level_for_request)

```ruby
begin
  # Modify the log level of a single logger.
  data, status_code, headers = api_instance.loggers_update_verbosity_level_for_with_http_info(name, loggers_update_verbosity_level_for_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->loggers_update_verbosity_level_for_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the logger to be modified. |  |
| **loggers_update_verbosity_level_for_request** | [**LoggersUpdateVerbosityLevelForRequest**](LoggersUpdateVerbosityLevelForRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## metrics

> metrics(opts)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
opts = {
  format: 'format_example' # String | Format to export metrics into. Currently accepts only \"prometheus\".
}

begin
  
  api_instance.metrics(opts)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->metrics: #{e}"
end
```

#### Using the metrics_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> metrics_with_http_info(opts)

```ruby
begin
  
  data, status_code, headers = api_instance.metrics_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->metrics_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **format** | **String** | Format to export metrics into. Currently accepts only \&quot;prometheus\&quot;. | [optional] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_validate

> mfa_validate(mfa_validate_request)

Validates the login for the given MFA methods. Upon successful validation, it returns an auth response containing the client token

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
mfa_validate_request = OpenbaoClient::MfaValidateRequest.new({mfa_payload: 3.56, mfa_request_id: 'mfa_request_id_example'}) # MfaValidateRequest | 

begin
  # Validates the login for the given MFA methods. Upon successful validation, it returns an auth response containing the client token
  api_instance.mfa_validate(mfa_validate_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mfa_validate: #{e}"
end
```

#### Using the mfa_validate_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_validate_with_http_info(mfa_validate_request)

```ruby
begin
  # Validates the login for the given MFA methods. Upon successful validation, it returns an auth response containing the client token
  data, status_code, headers = api_instance.mfa_validate_with_http_info(mfa_validate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mfa_validate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **mfa_validate_request** | [**MfaValidateRequest**](MfaValidateRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## monitor

> monitor(opts)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
opts = {
  log_format: 'log_format_example', # String | Output format of logs. Supported values are \"standard\" and \"json\". The default is \"standard\".
  log_level: 'log_level_example' # String | Log level to view system logs at. Currently supported values are \"trace\", \"debug\", \"info\", \"warn\", \"error\".
}

begin
  
  api_instance.monitor(opts)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->monitor: #{e}"
end
```

#### Using the monitor_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> monitor_with_http_info(opts)

```ruby
begin
  
  data, status_code, headers = api_instance.monitor_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->monitor_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **log_format** | **String** | Output format of logs. Supported values are \&quot;standard\&quot; and \&quot;json\&quot;. The default is \&quot;standard\&quot;. | [optional][default to &#39;standard&#39;] |
| **log_level** | **String** | Log level to view system logs at. Currently supported values are \&quot;trace\&quot;, \&quot;debug\&quot;, \&quot;info\&quot;, \&quot;warn\&quot;, \&quot;error\&quot;. | [optional] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mounts_disable_secrets_engine

> mounts_disable_secrets_engine(path)

Disable the mount point specified at the given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The path to mount to. Example: \"aws/east\"

begin
  # Disable the mount point specified at the given path.
  api_instance.mounts_disable_secrets_engine(path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_disable_secrets_engine: #{e}"
end
```

#### Using the mounts_disable_secrets_engine_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mounts_disable_secrets_engine_with_http_info(path)

```ruby
begin
  # Disable the mount point specified at the given path.
  data, status_code, headers = api_instance.mounts_disable_secrets_engine_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_disable_secrets_engine_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The path to mount to. Example: \&quot;aws/east\&quot; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mounts_enable_secrets_engine

> mounts_enable_secrets_engine(path, mounts_enable_secrets_engine_request)

Enable a new secrets engine at the given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The path to mount to. Example: \"aws/east\"
mounts_enable_secrets_engine_request = OpenbaoClient::MountsEnableSecretsEngineRequest.new # MountsEnableSecretsEngineRequest | 

begin
  # Enable a new secrets engine at the given path.
  api_instance.mounts_enable_secrets_engine(path, mounts_enable_secrets_engine_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_enable_secrets_engine: #{e}"
end
```

#### Using the mounts_enable_secrets_engine_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mounts_enable_secrets_engine_with_http_info(path, mounts_enable_secrets_engine_request)

```ruby
begin
  # Enable a new secrets engine at the given path.
  data, status_code, headers = api_instance.mounts_enable_secrets_engine_with_http_info(path, mounts_enable_secrets_engine_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_enable_secrets_engine_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The path to mount to. Example: \&quot;aws/east\&quot; |  |
| **mounts_enable_secrets_engine_request** | [**MountsEnableSecretsEngineRequest**](MountsEnableSecretsEngineRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## mounts_list_secrets_engines

> mounts_list_secrets_engines



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  api_instance.mounts_list_secrets_engines
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_list_secrets_engines: #{e}"
end
```

#### Using the mounts_list_secrets_engines_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mounts_list_secrets_engines_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.mounts_list_secrets_engines_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_list_secrets_engines_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mounts_read_configuration

> <MountsReadConfigurationResponse> mounts_read_configuration(path)

Read the configuration of the secret engine at the given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The path to mount to. Example: \"aws/east\"

begin
  # Read the configuration of the secret engine at the given path.
  result = api_instance.mounts_read_configuration(path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_read_configuration: #{e}"
end
```

#### Using the mounts_read_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<MountsReadConfigurationResponse>, Integer, Hash)> mounts_read_configuration_with_http_info(path)

```ruby
begin
  # Read the configuration of the secret engine at the given path.
  data, status_code, headers = api_instance.mounts_read_configuration_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <MountsReadConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_read_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The path to mount to. Example: \&quot;aws/east\&quot; |  |

### Return type

[**MountsReadConfigurationResponse**](MountsReadConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## mounts_read_tuning_information

> <MountsReadTuningInformationResponse> mounts_read_tuning_information(path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The path to mount to. Example: \"aws/east\"

begin
  
  result = api_instance.mounts_read_tuning_information(path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_read_tuning_information: #{e}"
end
```

#### Using the mounts_read_tuning_information_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<MountsReadTuningInformationResponse>, Integer, Hash)> mounts_read_tuning_information_with_http_info(path)

```ruby
begin
  
  data, status_code, headers = api_instance.mounts_read_tuning_information_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <MountsReadTuningInformationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_read_tuning_information_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The path to mount to. Example: \&quot;aws/east\&quot; |  |

### Return type

[**MountsReadTuningInformationResponse**](MountsReadTuningInformationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## mounts_tune_configuration_parameters

> mounts_tune_configuration_parameters(path, mounts_tune_configuration_parameters_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | The path to mount to. Example: \"aws/east\"
mounts_tune_configuration_parameters_request = OpenbaoClient::MountsTuneConfigurationParametersRequest.new # MountsTuneConfigurationParametersRequest | 

begin
  
  api_instance.mounts_tune_configuration_parameters(path, mounts_tune_configuration_parameters_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_tune_configuration_parameters: #{e}"
end
```

#### Using the mounts_tune_configuration_parameters_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mounts_tune_configuration_parameters_with_http_info(path, mounts_tune_configuration_parameters_request)

```ruby
begin
  
  data, status_code, headers = api_instance.mounts_tune_configuration_parameters_with_http_info(path, mounts_tune_configuration_parameters_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->mounts_tune_configuration_parameters_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | The path to mount to. Example: \&quot;aws/east\&quot; |  |
| **mounts_tune_configuration_parameters_request** | [**MountsTuneConfigurationParametersRequest**](MountsTuneConfigurationParametersRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## plugins_catalog_list_plugins

> <PluginsCatalogListPluginsResponse> plugins_catalog_list_plugins



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  result = api_instance.plugins_catalog_list_plugins
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_list_plugins: #{e}"
end
```

#### Using the plugins_catalog_list_plugins_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PluginsCatalogListPluginsResponse>, Integer, Hash)> plugins_catalog_list_plugins_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.plugins_catalog_list_plugins_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PluginsCatalogListPluginsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_list_plugins_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**PluginsCatalogListPluginsResponse**](PluginsCatalogListPluginsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## plugins_catalog_list_plugins_with_type

> <PluginsCatalogListPluginsWithTypeResponse> plugins_catalog_list_plugins_with_type(type, list)

List the plugins in the catalog.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
type = 'type_example' # String | The type of the plugin, may be auth, secret, or database
list = 'true' # String | Must be set to `true`

begin
  # List the plugins in the catalog.
  result = api_instance.plugins_catalog_list_plugins_with_type(type, list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_list_plugins_with_type: #{e}"
end
```

#### Using the plugins_catalog_list_plugins_with_type_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PluginsCatalogListPluginsWithTypeResponse>, Integer, Hash)> plugins_catalog_list_plugins_with_type_with_http_info(type, list)

```ruby
begin
  # List the plugins in the catalog.
  data, status_code, headers = api_instance.plugins_catalog_list_plugins_with_type_with_http_info(type, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PluginsCatalogListPluginsWithTypeResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_list_plugins_with_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **type** | **String** | The type of the plugin, may be auth, secret, or database |  |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**PluginsCatalogListPluginsWithTypeResponse**](PluginsCatalogListPluginsWithTypeResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## plugins_catalog_read_plugin_configuration

> <PluginsCatalogReadPluginConfigurationResponse> plugins_catalog_read_plugin_configuration(name)

Return the configuration data for the plugin with the given name.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the plugin

begin
  # Return the configuration data for the plugin with the given name.
  result = api_instance.plugins_catalog_read_plugin_configuration(name)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_read_plugin_configuration: #{e}"
end
```

#### Using the plugins_catalog_read_plugin_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PluginsCatalogReadPluginConfigurationResponse>, Integer, Hash)> plugins_catalog_read_plugin_configuration_with_http_info(name)

```ruby
begin
  # Return the configuration data for the plugin with the given name.
  data, status_code, headers = api_instance.plugins_catalog_read_plugin_configuration_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PluginsCatalogReadPluginConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_read_plugin_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the plugin |  |

### Return type

[**PluginsCatalogReadPluginConfigurationResponse**](PluginsCatalogReadPluginConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## plugins_catalog_read_plugin_configuration_with_type

> <PluginsCatalogReadPluginConfigurationWithTypeResponse> plugins_catalog_read_plugin_configuration_with_type(name, type)

Return the configuration data for the plugin with the given name.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the plugin
type = 'type_example' # String | The type of the plugin, may be auth, secret, or database

begin
  # Return the configuration data for the plugin with the given name.
  result = api_instance.plugins_catalog_read_plugin_configuration_with_type(name, type)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_read_plugin_configuration_with_type: #{e}"
end
```

#### Using the plugins_catalog_read_plugin_configuration_with_type_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PluginsCatalogReadPluginConfigurationWithTypeResponse>, Integer, Hash)> plugins_catalog_read_plugin_configuration_with_type_with_http_info(name, type)

```ruby
begin
  # Return the configuration data for the plugin with the given name.
  data, status_code, headers = api_instance.plugins_catalog_read_plugin_configuration_with_type_with_http_info(name, type)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PluginsCatalogReadPluginConfigurationWithTypeResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_read_plugin_configuration_with_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the plugin |  |
| **type** | **String** | The type of the plugin, may be auth, secret, or database |  |

### Return type

[**PluginsCatalogReadPluginConfigurationWithTypeResponse**](PluginsCatalogReadPluginConfigurationWithTypeResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## plugins_catalog_register_plugin

> plugins_catalog_register_plugin(name, plugins_catalog_register_plugin_request)

Register a new plugin, or updates an existing one with the supplied name.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the plugin
plugins_catalog_register_plugin_request = OpenbaoClient::PluginsCatalogRegisterPluginRequest.new # PluginsCatalogRegisterPluginRequest | 

begin
  # Register a new plugin, or updates an existing one with the supplied name.
  api_instance.plugins_catalog_register_plugin(name, plugins_catalog_register_plugin_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_register_plugin: #{e}"
end
```

#### Using the plugins_catalog_register_plugin_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> plugins_catalog_register_plugin_with_http_info(name, plugins_catalog_register_plugin_request)

```ruby
begin
  # Register a new plugin, or updates an existing one with the supplied name.
  data, status_code, headers = api_instance.plugins_catalog_register_plugin_with_http_info(name, plugins_catalog_register_plugin_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_register_plugin_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the plugin |  |
| **plugins_catalog_register_plugin_request** | [**PluginsCatalogRegisterPluginRequest**](PluginsCatalogRegisterPluginRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## plugins_catalog_register_plugin_with_type

> plugins_catalog_register_plugin_with_type(name, type, plugins_catalog_register_plugin_with_type_request)

Register a new plugin, or updates an existing one with the supplied name.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the plugin
type = 'type_example' # String | The type of the plugin, may be auth, secret, or database
plugins_catalog_register_plugin_with_type_request = OpenbaoClient::PluginsCatalogRegisterPluginWithTypeRequest.new # PluginsCatalogRegisterPluginWithTypeRequest | 

begin
  # Register a new plugin, or updates an existing one with the supplied name.
  api_instance.plugins_catalog_register_plugin_with_type(name, type, plugins_catalog_register_plugin_with_type_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_register_plugin_with_type: #{e}"
end
```

#### Using the plugins_catalog_register_plugin_with_type_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> plugins_catalog_register_plugin_with_type_with_http_info(name, type, plugins_catalog_register_plugin_with_type_request)

```ruby
begin
  # Register a new plugin, or updates an existing one with the supplied name.
  data, status_code, headers = api_instance.plugins_catalog_register_plugin_with_type_with_http_info(name, type, plugins_catalog_register_plugin_with_type_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_register_plugin_with_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the plugin |  |
| **type** | **String** | The type of the plugin, may be auth, secret, or database |  |
| **plugins_catalog_register_plugin_with_type_request** | [**PluginsCatalogRegisterPluginWithTypeRequest**](PluginsCatalogRegisterPluginWithTypeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## plugins_catalog_remove_plugin

> plugins_catalog_remove_plugin(name)

Remove the plugin with the given name.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the plugin

begin
  # Remove the plugin with the given name.
  api_instance.plugins_catalog_remove_plugin(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_remove_plugin: #{e}"
end
```

#### Using the plugins_catalog_remove_plugin_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> plugins_catalog_remove_plugin_with_http_info(name)

```ruby
begin
  # Remove the plugin with the given name.
  data, status_code, headers = api_instance.plugins_catalog_remove_plugin_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_remove_plugin_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the plugin |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## plugins_catalog_remove_plugin_with_type

> plugins_catalog_remove_plugin_with_type(name, type)

Remove the plugin with the given name.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the plugin
type = 'type_example' # String | The type of the plugin, may be auth, secret, or database

begin
  # Remove the plugin with the given name.
  api_instance.plugins_catalog_remove_plugin_with_type(name, type)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_remove_plugin_with_type: #{e}"
end
```

#### Using the plugins_catalog_remove_plugin_with_type_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> plugins_catalog_remove_plugin_with_type_with_http_info(name, type)

```ruby
begin
  # Remove the plugin with the given name.
  data, status_code, headers = api_instance.plugins_catalog_remove_plugin_with_type_with_http_info(name, type)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_catalog_remove_plugin_with_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the plugin |  |
| **type** | **String** | The type of the plugin, may be auth, secret, or database |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## plugins_reload_backends

> <PluginsReloadBackendsResponse> plugins_reload_backends(plugins_reload_backends_request)

Reload mounted plugin backends.

Either the plugin name (`plugin`) or the desired plugin backend mounts (`mounts`) must be provided, but not both. In the case that the plugin name is provided, all mounted paths that use that plugin backend will be reloaded.  If (`scope`) is provided and is (`global`), the plugin(s) are reloaded globally.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
plugins_reload_backends_request = OpenbaoClient::PluginsReloadBackendsRequest.new # PluginsReloadBackendsRequest | 

begin
  # Reload mounted plugin backends.
  result = api_instance.plugins_reload_backends(plugins_reload_backends_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_reload_backends: #{e}"
end
```

#### Using the plugins_reload_backends_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PluginsReloadBackendsResponse>, Integer, Hash)> plugins_reload_backends_with_http_info(plugins_reload_backends_request)

```ruby
begin
  # Reload mounted plugin backends.
  data, status_code, headers = api_instance.plugins_reload_backends_with_http_info(plugins_reload_backends_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PluginsReloadBackendsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->plugins_reload_backends_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **plugins_reload_backends_request** | [**PluginsReloadBackendsRequest**](PluginsReloadBackendsRequest.md) |  |  |

### Return type

[**PluginsReloadBackendsResponse**](PluginsReloadBackendsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## policies_delete_acl_policy

> policies_delete_acl_policy(name)

Delete the ACL policy with the given name.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the policy. Example: \"ops\"

begin
  # Delete the ACL policy with the given name.
  api_instance.policies_delete_acl_policy(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_delete_acl_policy: #{e}"
end
```

#### Using the policies_delete_acl_policy_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> policies_delete_acl_policy_with_http_info(name)

```ruby
begin
  # Delete the ACL policy with the given name.
  data, status_code, headers = api_instance.policies_delete_acl_policy_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_delete_acl_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the policy. Example: \&quot;ops\&quot; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## policies_delete_acl_policy2

> policies_delete_acl_policy2(name)

Delete the policy with the given name.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the policy. Example: \"ops\"

begin
  # Delete the policy with the given name.
  api_instance.policies_delete_acl_policy2(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_delete_acl_policy2: #{e}"
end
```

#### Using the policies_delete_acl_policy2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> policies_delete_acl_policy2_with_http_info(name)

```ruby
begin
  # Delete the policy with the given name.
  data, status_code, headers = api_instance.policies_delete_acl_policy2_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_delete_acl_policy2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the policy. Example: \&quot;ops\&quot; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## policies_delete_password_policy

> policies_delete_password_policy(name)

Delete a password policy.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the password policy.

begin
  # Delete a password policy.
  api_instance.policies_delete_password_policy(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_delete_password_policy: #{e}"
end
```

#### Using the policies_delete_password_policy_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> policies_delete_password_policy_with_http_info(name)

```ruby
begin
  # Delete a password policy.
  data, status_code, headers = api_instance.policies_delete_password_policy_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_delete_password_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the password policy. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## policies_generate_password_from_password_policy

> <PoliciesGeneratePasswordFromPasswordPolicyResponse> policies_generate_password_from_password_policy(name)

Generate a password from an existing password policy.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the password policy.

begin
  # Generate a password from an existing password policy.
  result = api_instance.policies_generate_password_from_password_policy(name)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_generate_password_from_password_policy: #{e}"
end
```

#### Using the policies_generate_password_from_password_policy_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PoliciesGeneratePasswordFromPasswordPolicyResponse>, Integer, Hash)> policies_generate_password_from_password_policy_with_http_info(name)

```ruby
begin
  # Generate a password from an existing password policy.
  data, status_code, headers = api_instance.policies_generate_password_from_password_policy_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PoliciesGeneratePasswordFromPasswordPolicyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_generate_password_from_password_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the password policy. |  |

### Return type

[**PoliciesGeneratePasswordFromPasswordPolicyResponse**](PoliciesGeneratePasswordFromPasswordPolicyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## policies_list

> <PoliciesListResponse> policies_list(opts)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
opts = {
  list: 'list_example' # String | Return a list if `true`
}

begin
  
  result = api_instance.policies_list(opts)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_list: #{e}"
end
```

#### Using the policies_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PoliciesListResponse>, Integer, Hash)> policies_list_with_http_info(opts)

```ruby
begin
  
  data, status_code, headers = api_instance.policies_list_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PoliciesListResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Return a list if &#x60;true&#x60; | [optional] |

### Return type

[**PoliciesListResponse**](PoliciesListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## policies_list_acl_policies

> <PoliciesListAclPoliciesResponse> policies_list_acl_policies(list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.policies_list_acl_policies(list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_list_acl_policies: #{e}"
end
```

#### Using the policies_list_acl_policies_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PoliciesListAclPoliciesResponse>, Integer, Hash)> policies_list_acl_policies_with_http_info(list)

```ruby
begin
  
  data, status_code, headers = api_instance.policies_list_acl_policies_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PoliciesListAclPoliciesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_list_acl_policies_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**PoliciesListAclPoliciesResponse**](PoliciesListAclPoliciesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## policies_list_password_policies

> <PoliciesListPasswordPoliciesResponse> policies_list_password_policies(list)

List the existing password policies.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
list = 'true' # String | Must be set to `true`

begin
  # List the existing password policies.
  result = api_instance.policies_list_password_policies(list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_list_password_policies: #{e}"
end
```

#### Using the policies_list_password_policies_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PoliciesListPasswordPoliciesResponse>, Integer, Hash)> policies_list_password_policies_with_http_info(list)

```ruby
begin
  # List the existing password policies.
  data, status_code, headers = api_instance.policies_list_password_policies_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PoliciesListPasswordPoliciesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_list_password_policies_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**PoliciesListPasswordPoliciesResponse**](PoliciesListPasswordPoliciesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## policies_read_acl_policy

> <PoliciesReadAclPolicyResponse> policies_read_acl_policy(name)

Retrieve information about the named ACL policy.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the policy. Example: \"ops\"

begin
  # Retrieve information about the named ACL policy.
  result = api_instance.policies_read_acl_policy(name)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_read_acl_policy: #{e}"
end
```

#### Using the policies_read_acl_policy_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PoliciesReadAclPolicyResponse>, Integer, Hash)> policies_read_acl_policy_with_http_info(name)

```ruby
begin
  # Retrieve information about the named ACL policy.
  data, status_code, headers = api_instance.policies_read_acl_policy_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PoliciesReadAclPolicyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_read_acl_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the policy. Example: \&quot;ops\&quot; |  |

### Return type

[**PoliciesReadAclPolicyResponse**](PoliciesReadAclPolicyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## policies_read_acl_policy2

> <PoliciesReadAclPolicy2Response> policies_read_acl_policy2(name)

Retrieve the policy body for the named policy.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the policy. Example: \"ops\"

begin
  # Retrieve the policy body for the named policy.
  result = api_instance.policies_read_acl_policy2(name)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_read_acl_policy2: #{e}"
end
```

#### Using the policies_read_acl_policy2_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PoliciesReadAclPolicy2Response>, Integer, Hash)> policies_read_acl_policy2_with_http_info(name)

```ruby
begin
  # Retrieve the policy body for the named policy.
  data, status_code, headers = api_instance.policies_read_acl_policy2_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PoliciesReadAclPolicy2Response>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_read_acl_policy2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the policy. Example: \&quot;ops\&quot; |  |

### Return type

[**PoliciesReadAclPolicy2Response**](PoliciesReadAclPolicy2Response.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## policies_read_password_policy

> <PoliciesReadPasswordPolicyResponse> policies_read_password_policy(name)

Retrieve an existing password policy.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the password policy.

begin
  # Retrieve an existing password policy.
  result = api_instance.policies_read_password_policy(name)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_read_password_policy: #{e}"
end
```

#### Using the policies_read_password_policy_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PoliciesReadPasswordPolicyResponse>, Integer, Hash)> policies_read_password_policy_with_http_info(name)

```ruby
begin
  # Retrieve an existing password policy.
  data, status_code, headers = api_instance.policies_read_password_policy_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PoliciesReadPasswordPolicyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_read_password_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the password policy. |  |

### Return type

[**PoliciesReadPasswordPolicyResponse**](PoliciesReadPasswordPolicyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## policies_write_acl_policy

> policies_write_acl_policy(name, policies_write_acl_policy_request)

Add a new or update an existing ACL policy.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the policy. Example: \"ops\"
policies_write_acl_policy_request = OpenbaoClient::PoliciesWriteAclPolicyRequest.new # PoliciesWriteAclPolicyRequest | 

begin
  # Add a new or update an existing ACL policy.
  api_instance.policies_write_acl_policy(name, policies_write_acl_policy_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_write_acl_policy: #{e}"
end
```

#### Using the policies_write_acl_policy_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> policies_write_acl_policy_with_http_info(name, policies_write_acl_policy_request)

```ruby
begin
  # Add a new or update an existing ACL policy.
  data, status_code, headers = api_instance.policies_write_acl_policy_with_http_info(name, policies_write_acl_policy_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_write_acl_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the policy. Example: \&quot;ops\&quot; |  |
| **policies_write_acl_policy_request** | [**PoliciesWriteAclPolicyRequest**](PoliciesWriteAclPolicyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## policies_write_acl_policy2

> policies_write_acl_policy2(name, policies_write_acl_policy2_request)

Add a new or update an existing policy.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the policy. Example: \"ops\"
policies_write_acl_policy2_request = OpenbaoClient::PoliciesWriteAclPolicy2Request.new # PoliciesWriteAclPolicy2Request | 

begin
  # Add a new or update an existing policy.
  api_instance.policies_write_acl_policy2(name, policies_write_acl_policy2_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_write_acl_policy2: #{e}"
end
```

#### Using the policies_write_acl_policy2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> policies_write_acl_policy2_with_http_info(name, policies_write_acl_policy2_request)

```ruby
begin
  # Add a new or update an existing policy.
  data, status_code, headers = api_instance.policies_write_acl_policy2_with_http_info(name, policies_write_acl_policy2_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_write_acl_policy2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the policy. Example: \&quot;ops\&quot; |  |
| **policies_write_acl_policy2_request** | [**PoliciesWriteAclPolicy2Request**](PoliciesWriteAclPolicy2Request.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## policies_write_password_policy

> policies_write_password_policy(name, policies_write_password_policy_request)

Add a new or update an existing password policy.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | The name of the password policy.
policies_write_password_policy_request = OpenbaoClient::PoliciesWritePasswordPolicyRequest.new # PoliciesWritePasswordPolicyRequest | 

begin
  # Add a new or update an existing password policy.
  api_instance.policies_write_password_policy(name, policies_write_password_policy_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_write_password_policy: #{e}"
end
```

#### Using the policies_write_password_policy_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> policies_write_password_policy_with_http_info(name, policies_write_password_policy_request)

```ruby
begin
  # Add a new or update an existing password policy.
  data, status_code, headers = api_instance.policies_write_password_policy_with_http_info(name, policies_write_password_policy_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->policies_write_password_policy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the password policy. |  |
| **policies_write_password_policy_request** | [**PoliciesWritePasswordPolicyRequest**](PoliciesWritePasswordPolicyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pprof_blocking

> pprof_blocking

Returns stack traces that led to blocking on synchronization primitives

Returns stack traces that led to blocking on synchronization primitives

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns stack traces that led to blocking on synchronization primitives
  api_instance.pprof_blocking
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_blocking: #{e}"
end
```

#### Using the pprof_blocking_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_blocking_with_http_info

```ruby
begin
  # Returns stack traces that led to blocking on synchronization primitives
  data, status_code, headers = api_instance.pprof_blocking_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_blocking_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pprof_command_line

> pprof_command_line

Returns the running program's command line.

Returns the running program's command line, with arguments separated by NUL bytes.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns the running program's command line.
  api_instance.pprof_command_line
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_command_line: #{e}"
end
```

#### Using the pprof_command_line_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_command_line_with_http_info

```ruby
begin
  # Returns the running program's command line.
  data, status_code, headers = api_instance.pprof_command_line_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_command_line_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pprof_cpu_profile

> pprof_cpu_profile

Returns a pprof-formatted cpu profile payload.

Returns a pprof-formatted cpu profile payload. Profiling lasts for duration specified in seconds GET parameter, or for 30 seconds if not specified.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns a pprof-formatted cpu profile payload.
  api_instance.pprof_cpu_profile
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_cpu_profile: #{e}"
end
```

#### Using the pprof_cpu_profile_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_cpu_profile_with_http_info

```ruby
begin
  # Returns a pprof-formatted cpu profile payload.
  data, status_code, headers = api_instance.pprof_cpu_profile_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_cpu_profile_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pprof_execution_trace

> pprof_execution_trace

Returns the execution trace in binary form.

Returns  the execution trace in binary form. Tracing lasts for duration specified in seconds GET parameter, or for 1 second if not specified.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns the execution trace in binary form.
  api_instance.pprof_execution_trace
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_execution_trace: #{e}"
end
```

#### Using the pprof_execution_trace_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_execution_trace_with_http_info

```ruby
begin
  # Returns the execution trace in binary form.
  data, status_code, headers = api_instance.pprof_execution_trace_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_execution_trace_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pprof_goroutines

> pprof_goroutines

Returns stack traces of all current goroutines.

Returns stack traces of all current goroutines.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns stack traces of all current goroutines.
  api_instance.pprof_goroutines
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_goroutines: #{e}"
end
```

#### Using the pprof_goroutines_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_goroutines_with_http_info

```ruby
begin
  # Returns stack traces of all current goroutines.
  data, status_code, headers = api_instance.pprof_goroutines_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_goroutines_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pprof_index

> pprof_index

Returns an HTML page listing the available profiles.

Returns an HTML page listing the available  profiles. This should be mainly accessed via browsers or applications that can  render pages.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns an HTML page listing the available profiles.
  api_instance.pprof_index
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_index: #{e}"
end
```

#### Using the pprof_index_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_index_with_http_info

```ruby
begin
  # Returns an HTML page listing the available profiles.
  data, status_code, headers = api_instance.pprof_index_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_index_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pprof_memory_allocations

> pprof_memory_allocations

Returns a sampling of all past memory allocations.

Returns a sampling of all past memory allocations.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns a sampling of all past memory allocations.
  api_instance.pprof_memory_allocations
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_memory_allocations: #{e}"
end
```

#### Using the pprof_memory_allocations_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_memory_allocations_with_http_info

```ruby
begin
  # Returns a sampling of all past memory allocations.
  data, status_code, headers = api_instance.pprof_memory_allocations_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_memory_allocations_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pprof_memory_allocations_live

> pprof_memory_allocations_live

Returns a sampling of memory allocations of live object.

Returns a sampling of memory allocations of live object.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns a sampling of memory allocations of live object.
  api_instance.pprof_memory_allocations_live
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_memory_allocations_live: #{e}"
end
```

#### Using the pprof_memory_allocations_live_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_memory_allocations_live_with_http_info

```ruby
begin
  # Returns a sampling of memory allocations of live object.
  data, status_code, headers = api_instance.pprof_memory_allocations_live_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_memory_allocations_live_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pprof_mutexes

> pprof_mutexes

Returns stack traces of holders of contended mutexes

Returns stack traces of holders of contended mutexes

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns stack traces of holders of contended mutexes
  api_instance.pprof_mutexes
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_mutexes: #{e}"
end
```

#### Using the pprof_mutexes_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_mutexes_with_http_info

```ruby
begin
  # Returns stack traces of holders of contended mutexes
  data, status_code, headers = api_instance.pprof_mutexes_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_mutexes_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pprof_symbols

> pprof_symbols

Returns the program counters listed in the request.

Returns the program counters listed in the request.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns the program counters listed in the request.
  api_instance.pprof_symbols
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_symbols: #{e}"
end
```

#### Using the pprof_symbols_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_symbols_with_http_info

```ruby
begin
  # Returns the program counters listed in the request.
  data, status_code, headers = api_instance.pprof_symbols_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_symbols_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pprof_thread_creations

> pprof_thread_creations

Returns stack traces that led to the creation of new OS threads

Returns stack traces that led to the creation of new OS threads

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns stack traces that led to the creation of new OS threads
  api_instance.pprof_thread_creations
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_thread_creations: #{e}"
end
```

#### Using the pprof_thread_creations_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pprof_thread_creations_with_http_info

```ruby
begin
  # Returns stack traces that led to the creation of new OS threads
  data, status_code, headers = api_instance.pprof_thread_creations_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->pprof_thread_creations_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## query_token_accessor_capabilities

> query_token_accessor_capabilities(query_token_accessor_capabilities_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
query_token_accessor_capabilities_request = OpenbaoClient::QueryTokenAccessorCapabilitiesRequest.new # QueryTokenAccessorCapabilitiesRequest | 

begin
  
  api_instance.query_token_accessor_capabilities(query_token_accessor_capabilities_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->query_token_accessor_capabilities: #{e}"
end
```

#### Using the query_token_accessor_capabilities_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> query_token_accessor_capabilities_with_http_info(query_token_accessor_capabilities_request)

```ruby
begin
  
  data, status_code, headers = api_instance.query_token_accessor_capabilities_with_http_info(query_token_accessor_capabilities_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->query_token_accessor_capabilities_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **query_token_accessor_capabilities_request** | [**QueryTokenAccessorCapabilitiesRequest**](QueryTokenAccessorCapabilitiesRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## query_token_capabilities

> query_token_capabilities(query_token_capabilities_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
query_token_capabilities_request = OpenbaoClient::QueryTokenCapabilitiesRequest.new # QueryTokenCapabilitiesRequest | 

begin
  
  api_instance.query_token_capabilities(query_token_capabilities_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->query_token_capabilities: #{e}"
end
```

#### Using the query_token_capabilities_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> query_token_capabilities_with_http_info(query_token_capabilities_request)

```ruby
begin
  
  data, status_code, headers = api_instance.query_token_capabilities_with_http_info(query_token_capabilities_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->query_token_capabilities_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **query_token_capabilities_request** | [**QueryTokenCapabilitiesRequest**](QueryTokenCapabilitiesRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## query_token_self_capabilities

> query_token_self_capabilities(query_token_self_capabilities_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
query_token_self_capabilities_request = OpenbaoClient::QueryTokenSelfCapabilitiesRequest.new # QueryTokenSelfCapabilitiesRequest | 

begin
  
  api_instance.query_token_self_capabilities(query_token_self_capabilities_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->query_token_self_capabilities: #{e}"
end
```

#### Using the query_token_self_capabilities_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> query_token_self_capabilities_with_http_info(query_token_self_capabilities_request)

```ruby
begin
  
  data, status_code, headers = api_instance.query_token_self_capabilities_with_http_info(query_token_self_capabilities_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->query_token_self_capabilities_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **query_token_self_capabilities_request** | [**QueryTokenSelfCapabilitiesRequest**](QueryTokenSelfCapabilitiesRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## rate_limit_quotas_configure

> rate_limit_quotas_configure(rate_limit_quotas_configure_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
rate_limit_quotas_configure_request = OpenbaoClient::RateLimitQuotasConfigureRequest.new # RateLimitQuotasConfigureRequest | 

begin
  
  api_instance.rate_limit_quotas_configure(rate_limit_quotas_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_configure: #{e}"
end
```

#### Using the rate_limit_quotas_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rate_limit_quotas_configure_with_http_info(rate_limit_quotas_configure_request)

```ruby
begin
  
  data, status_code, headers = api_instance.rate_limit_quotas_configure_with_http_info(rate_limit_quotas_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **rate_limit_quotas_configure_request** | [**RateLimitQuotasConfigureRequest**](RateLimitQuotasConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## rate_limit_quotas_delete

> rate_limit_quotas_delete(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | Name of the quota rule.

begin
  
  api_instance.rate_limit_quotas_delete(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_delete: #{e}"
end
```

#### Using the rate_limit_quotas_delete_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rate_limit_quotas_delete_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.rate_limit_quotas_delete_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_delete_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the quota rule. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## rate_limit_quotas_list

> <RateLimitQuotasListResponse> rate_limit_quotas_list(list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.rate_limit_quotas_list(list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_list: #{e}"
end
```

#### Using the rate_limit_quotas_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RateLimitQuotasListResponse>, Integer, Hash)> rate_limit_quotas_list_with_http_info(list)

```ruby
begin
  
  data, status_code, headers = api_instance.rate_limit_quotas_list_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RateLimitQuotasListResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**RateLimitQuotasListResponse**](RateLimitQuotasListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## rate_limit_quotas_read

> <RateLimitQuotasReadResponse> rate_limit_quotas_read(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | Name of the quota rule.

begin
  
  result = api_instance.rate_limit_quotas_read(name)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_read: #{e}"
end
```

#### Using the rate_limit_quotas_read_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RateLimitQuotasReadResponse>, Integer, Hash)> rate_limit_quotas_read_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.rate_limit_quotas_read_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RateLimitQuotasReadResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_read_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the quota rule. |  |

### Return type

[**RateLimitQuotasReadResponse**](RateLimitQuotasReadResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## rate_limit_quotas_read_configuration

> <RateLimitQuotasReadConfigurationResponse> rate_limit_quotas_read_configuration



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  result = api_instance.rate_limit_quotas_read_configuration
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_read_configuration: #{e}"
end
```

#### Using the rate_limit_quotas_read_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RateLimitQuotasReadConfigurationResponse>, Integer, Hash)> rate_limit_quotas_read_configuration_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.rate_limit_quotas_read_configuration_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RateLimitQuotasReadConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_read_configuration_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**RateLimitQuotasReadConfigurationResponse**](RateLimitQuotasReadConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## rate_limit_quotas_write

> rate_limit_quotas_write(name, rate_limit_quotas_write_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
name = 'name_example' # String | Name of the quota rule.
rate_limit_quotas_write_request = OpenbaoClient::RateLimitQuotasWriteRequest.new # RateLimitQuotasWriteRequest | 

begin
  
  api_instance.rate_limit_quotas_write(name, rate_limit_quotas_write_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_write: #{e}"
end
```

#### Using the rate_limit_quotas_write_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rate_limit_quotas_write_with_http_info(name, rate_limit_quotas_write_request)

```ruby
begin
  
  data, status_code, headers = api_instance.rate_limit_quotas_write_with_http_info(name, rate_limit_quotas_write_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rate_limit_quotas_write_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the quota rule. |  |
| **rate_limit_quotas_write_request** | [**RateLimitQuotasWriteRequest**](RateLimitQuotasWriteRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## raw_delete

> raw_delete

Delete the key with given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Delete the key with given path.
  api_instance.raw_delete
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_delete: #{e}"
end
```

#### Using the raw_delete_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> raw_delete_with_http_info

```ruby
begin
  # Delete the key with given path.
  data, status_code, headers = api_instance.raw_delete_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_delete_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## raw_delete_path

> raw_delete_path(path)

Delete the key with given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | 

begin
  # Delete the key with given path.
  api_instance.raw_delete_path(path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_delete_path: #{e}"
end
```

#### Using the raw_delete_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> raw_delete_path_with_http_info(path)

```ruby
begin
  # Delete the key with given path.
  data, status_code, headers = api_instance.raw_delete_path_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_delete_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## raw_read

> <RawReadResponse> raw_read(opts)

Read the value of the key at the given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
opts = {
  list: 'list_example' # String | Return a list if `true`
}

begin
  # Read the value of the key at the given path.
  result = api_instance.raw_read(opts)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_read: #{e}"
end
```

#### Using the raw_read_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RawReadResponse>, Integer, Hash)> raw_read_with_http_info(opts)

```ruby
begin
  # Read the value of the key at the given path.
  data, status_code, headers = api_instance.raw_read_with_http_info(opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RawReadResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_read_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Return a list if &#x60;true&#x60; | [optional] |

### Return type

[**RawReadResponse**](RawReadResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## raw_read_path

> <RawReadPathResponse> raw_read_path(path, opts)

Read the value of the key at the given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | 
opts = {
  list: 'list_example' # String | Return a list if `true`
}

begin
  # Read the value of the key at the given path.
  result = api_instance.raw_read_path(path, opts)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_read_path: #{e}"
end
```

#### Using the raw_read_path_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RawReadPathResponse>, Integer, Hash)> raw_read_path_with_http_info(path, opts)

```ruby
begin
  # Read the value of the key at the given path.
  data, status_code, headers = api_instance.raw_read_path_with_http_info(path, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RawReadPathResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_read_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** |  |  |
| **list** | **String** | Return a list if &#x60;true&#x60; | [optional] |

### Return type

[**RawReadPathResponse**](RawReadPathResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## raw_write

> raw_write(raw_write_request)

Update the value of the key at the given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
raw_write_request = OpenbaoClient::RawWriteRequest.new # RawWriteRequest | 

begin
  # Update the value of the key at the given path.
  api_instance.raw_write(raw_write_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_write: #{e}"
end
```

#### Using the raw_write_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> raw_write_with_http_info(raw_write_request)

```ruby
begin
  # Update the value of the key at the given path.
  data, status_code, headers = api_instance.raw_write_with_http_info(raw_write_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_write_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **raw_write_request** | [**RawWriteRequest**](RawWriteRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## raw_write_path

> raw_write_path(path, raw_write_path_request)

Update the value of the key at the given path.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
path = 'path_example' # String | 
raw_write_path_request = OpenbaoClient::RawWritePathRequest.new # RawWritePathRequest | 

begin
  # Update the value of the key at the given path.
  api_instance.raw_write_path(path, raw_write_path_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_write_path: #{e}"
end
```

#### Using the raw_write_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> raw_write_path_with_http_info(path, raw_write_path_request)

```ruby
begin
  # Update the value of the key at the given path.
  data, status_code, headers = api_instance.raw_write_path_with_http_info(path, raw_write_path_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->raw_write_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** |  |  |
| **raw_write_path_request** | [**RawWritePathRequest**](RawWritePathRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## read_health_status

> read_health_status

Returns the health status of OpenBao.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns the health status of OpenBao.
  api_instance.read_health_status
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->read_health_status: #{e}"
end
```

#### Using the read_health_status_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> read_health_status_with_http_info

```ruby
begin
  # Returns the health status of OpenBao.
  data, status_code, headers = api_instance.read_health_status_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->read_health_status_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## read_initialization_status

> read_initialization_status

Returns the initialization status of OpenBao.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Returns the initialization status of OpenBao.
  api_instance.read_initialization_status
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->read_initialization_status: #{e}"
end
```

#### Using the read_initialization_status_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> read_initialization_status_with_http_info

```ruby
begin
  # Returns the initialization status of OpenBao.
  data, status_code, headers = api_instance.read_initialization_status_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->read_initialization_status_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## read_sanitized_configuration_state

> read_sanitized_configuration_state

Return a sanitized version of the OpenBao server configuration.

The sanitized output strips configuration values in the storage, HA storage, and seals stanzas, which may contain sensitive values such as API tokens. It also removes any token or secret fields in other stanzas, such as the circonus_api_token from telemetry.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Return a sanitized version of the OpenBao server configuration.
  api_instance.read_sanitized_configuration_state
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->read_sanitized_configuration_state: #{e}"
end
```

#### Using the read_sanitized_configuration_state_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> read_sanitized_configuration_state_with_http_info

```ruby
begin
  # Return a sanitized version of the OpenBao server configuration.
  data, status_code, headers = api_instance.read_sanitized_configuration_state_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->read_sanitized_configuration_state_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## read_wrapping_properties

> <ReadWrappingPropertiesResponse> read_wrapping_properties(read_wrapping_properties_request)

Look up wrapping properties for the given token.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
read_wrapping_properties_request = OpenbaoClient::ReadWrappingPropertiesRequest.new # ReadWrappingPropertiesRequest | 

begin
  # Look up wrapping properties for the given token.
  result = api_instance.read_wrapping_properties(read_wrapping_properties_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->read_wrapping_properties: #{e}"
end
```

#### Using the read_wrapping_properties_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ReadWrappingPropertiesResponse>, Integer, Hash)> read_wrapping_properties_with_http_info(read_wrapping_properties_request)

```ruby
begin
  # Look up wrapping properties for the given token.
  data, status_code, headers = api_instance.read_wrapping_properties_with_http_info(read_wrapping_properties_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ReadWrappingPropertiesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->read_wrapping_properties_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **read_wrapping_properties_request** | [**ReadWrappingPropertiesRequest**](ReadWrappingPropertiesRequest.md) |  |  |

### Return type

[**ReadWrappingPropertiesResponse**](ReadWrappingPropertiesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## read_wrapping_properties2

> <ReadWrappingProperties2Response> read_wrapping_properties2

Look up wrapping properties for the requester's token.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Look up wrapping properties for the requester's token.
  result = api_instance.read_wrapping_properties2
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->read_wrapping_properties2: #{e}"
end
```

#### Using the read_wrapping_properties2_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<ReadWrappingProperties2Response>, Integer, Hash)> read_wrapping_properties2_with_http_info

```ruby
begin
  # Look up wrapping properties for the requester's token.
  data, status_code, headers = api_instance.read_wrapping_properties2_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <ReadWrappingProperties2Response>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->read_wrapping_properties2_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**ReadWrappingProperties2Response**](ReadWrappingProperties2Response.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## rekey_attempt_cancel

> rekey_attempt_cancel

Cancels any in-progress rekey.

This clears the rekey settings as well as any progress made. This must be called to change the parameters of the rekey. Note: verification is still a part of a rekey. If rekeying is canceled during the verification flow, the current unseal keys remain valid.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Cancels any in-progress rekey.
  api_instance.rekey_attempt_cancel
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_attempt_cancel: #{e}"
end
```

#### Using the rekey_attempt_cancel_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rekey_attempt_cancel_with_http_info

```ruby
begin
  # Cancels any in-progress rekey.
  data, status_code, headers = api_instance.rekey_attempt_cancel_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_attempt_cancel_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## rekey_attempt_initialize

> <RekeyAttemptInitializeResponse> rekey_attempt_initialize(rekey_attempt_initialize_request)

Initializes a new rekey attempt.

Only a single rekey attempt can take place at a time, and changing the parameters of a rekey requires canceling and starting a new rekey, which will also provide a new nonce.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
rekey_attempt_initialize_request = OpenbaoClient::RekeyAttemptInitializeRequest.new # RekeyAttemptInitializeRequest | 

begin
  # Initializes a new rekey attempt.
  result = api_instance.rekey_attempt_initialize(rekey_attempt_initialize_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_attempt_initialize: #{e}"
end
```

#### Using the rekey_attempt_initialize_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RekeyAttemptInitializeResponse>, Integer, Hash)> rekey_attempt_initialize_with_http_info(rekey_attempt_initialize_request)

```ruby
begin
  # Initializes a new rekey attempt.
  data, status_code, headers = api_instance.rekey_attempt_initialize_with_http_info(rekey_attempt_initialize_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RekeyAttemptInitializeResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_attempt_initialize_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **rekey_attempt_initialize_request** | [**RekeyAttemptInitializeRequest**](RekeyAttemptInitializeRequest.md) |  |  |

### Return type

[**RekeyAttemptInitializeResponse**](RekeyAttemptInitializeResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## rekey_attempt_read_progress

> <RekeyAttemptReadProgressResponse> rekey_attempt_read_progress

Reads the configuration and progress of the current rekey attempt.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Reads the configuration and progress of the current rekey attempt.
  result = api_instance.rekey_attempt_read_progress
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_attempt_read_progress: #{e}"
end
```

#### Using the rekey_attempt_read_progress_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RekeyAttemptReadProgressResponse>, Integer, Hash)> rekey_attempt_read_progress_with_http_info

```ruby
begin
  # Reads the configuration and progress of the current rekey attempt.
  data, status_code, headers = api_instance.rekey_attempt_read_progress_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RekeyAttemptReadProgressResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_attempt_read_progress_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**RekeyAttemptReadProgressResponse**](RekeyAttemptReadProgressResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## rekey_attempt_update

> <RekeyAttemptUpdateResponse> rekey_attempt_update(rekey_attempt_update_request)

Enter a single unseal key share to progress the rekey of the OpenBao.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
rekey_attempt_update_request = OpenbaoClient::RekeyAttemptUpdateRequest.new # RekeyAttemptUpdateRequest | 

begin
  # Enter a single unseal key share to progress the rekey of the OpenBao.
  result = api_instance.rekey_attempt_update(rekey_attempt_update_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_attempt_update: #{e}"
end
```

#### Using the rekey_attempt_update_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RekeyAttemptUpdateResponse>, Integer, Hash)> rekey_attempt_update_with_http_info(rekey_attempt_update_request)

```ruby
begin
  # Enter a single unseal key share to progress the rekey of the OpenBao.
  data, status_code, headers = api_instance.rekey_attempt_update_with_http_info(rekey_attempt_update_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RekeyAttemptUpdateResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_attempt_update_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **rekey_attempt_update_request** | [**RekeyAttemptUpdateRequest**](RekeyAttemptUpdateRequest.md) |  |  |

### Return type

[**RekeyAttemptUpdateResponse**](RekeyAttemptUpdateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## rekey_delete_backup_key

> rekey_delete_backup_key

Delete the backup copy of PGP-encrypted unseal keys.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Delete the backup copy of PGP-encrypted unseal keys.
  api_instance.rekey_delete_backup_key
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_delete_backup_key: #{e}"
end
```

#### Using the rekey_delete_backup_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rekey_delete_backup_key_with_http_info

```ruby
begin
  # Delete the backup copy of PGP-encrypted unseal keys.
  data, status_code, headers = api_instance.rekey_delete_backup_key_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_delete_backup_key_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## rekey_delete_backup_recovery_key

> rekey_delete_backup_recovery_key



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  api_instance.rekey_delete_backup_recovery_key
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_delete_backup_recovery_key: #{e}"
end
```

#### Using the rekey_delete_backup_recovery_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rekey_delete_backup_recovery_key_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.rekey_delete_backup_recovery_key_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_delete_backup_recovery_key_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## rekey_read_backup_key

> <RekeyReadBackupKeyResponse> rekey_read_backup_key

Return the backup copy of PGP-encrypted unseal keys.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Return the backup copy of PGP-encrypted unseal keys.
  result = api_instance.rekey_read_backup_key
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_read_backup_key: #{e}"
end
```

#### Using the rekey_read_backup_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RekeyReadBackupKeyResponse>, Integer, Hash)> rekey_read_backup_key_with_http_info

```ruby
begin
  # Return the backup copy of PGP-encrypted unseal keys.
  data, status_code, headers = api_instance.rekey_read_backup_key_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RekeyReadBackupKeyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_read_backup_key_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**RekeyReadBackupKeyResponse**](RekeyReadBackupKeyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## rekey_read_backup_recovery_key

> <RekeyReadBackupRecoveryKeyResponse> rekey_read_backup_recovery_key



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  result = api_instance.rekey_read_backup_recovery_key
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_read_backup_recovery_key: #{e}"
end
```

#### Using the rekey_read_backup_recovery_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RekeyReadBackupRecoveryKeyResponse>, Integer, Hash)> rekey_read_backup_recovery_key_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.rekey_read_backup_recovery_key_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RekeyReadBackupRecoveryKeyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_read_backup_recovery_key_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**RekeyReadBackupRecoveryKeyResponse**](RekeyReadBackupRecoveryKeyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## rekey_verification_cancel

> <RekeyVerificationCancelResponse> rekey_verification_cancel

Cancel any in-progress rekey verification operation.

This clears any progress made and resets the nonce. Unlike a `DELETE` against `sys/rekey/init`, this only resets the current verification operation, not the entire rekey atttempt.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Cancel any in-progress rekey verification operation.
  result = api_instance.rekey_verification_cancel
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_verification_cancel: #{e}"
end
```

#### Using the rekey_verification_cancel_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RekeyVerificationCancelResponse>, Integer, Hash)> rekey_verification_cancel_with_http_info

```ruby
begin
  # Cancel any in-progress rekey verification operation.
  data, status_code, headers = api_instance.rekey_verification_cancel_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RekeyVerificationCancelResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_verification_cancel_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**RekeyVerificationCancelResponse**](RekeyVerificationCancelResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## rekey_verification_read_progress

> <RekeyVerificationReadProgressResponse> rekey_verification_read_progress

Read the configuration and progress of the current rekey verification attempt.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Read the configuration and progress of the current rekey verification attempt.
  result = api_instance.rekey_verification_read_progress
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_verification_read_progress: #{e}"
end
```

#### Using the rekey_verification_read_progress_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RekeyVerificationReadProgressResponse>, Integer, Hash)> rekey_verification_read_progress_with_http_info

```ruby
begin
  # Read the configuration and progress of the current rekey verification attempt.
  data, status_code, headers = api_instance.rekey_verification_read_progress_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RekeyVerificationReadProgressResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_verification_read_progress_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**RekeyVerificationReadProgressResponse**](RekeyVerificationReadProgressResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## rekey_verification_update

> <RekeyVerificationUpdateResponse> rekey_verification_update(rekey_verification_update_request)

Enter a single new key share to progress the rekey verification operation.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
rekey_verification_update_request = OpenbaoClient::RekeyVerificationUpdateRequest.new # RekeyVerificationUpdateRequest | 

begin
  # Enter a single new key share to progress the rekey verification operation.
  result = api_instance.rekey_verification_update(rekey_verification_update_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_verification_update: #{e}"
end
```

#### Using the rekey_verification_update_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RekeyVerificationUpdateResponse>, Integer, Hash)> rekey_verification_update_with_http_info(rekey_verification_update_request)

```ruby
begin
  # Enter a single new key share to progress the rekey verification operation.
  data, status_code, headers = api_instance.rekey_verification_update_with_http_info(rekey_verification_update_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RekeyVerificationUpdateResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rekey_verification_update_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **rekey_verification_update_request** | [**RekeyVerificationUpdateRequest**](RekeyVerificationUpdateRequest.md) |  |  |

### Return type

[**RekeyVerificationUpdateResponse**](RekeyVerificationUpdateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## reload_subsystem

> reload_subsystem(subsystem)

Reload the given subsystem

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
subsystem = 'subsystem_example' # String | 

begin
  # Reload the given subsystem
  api_instance.reload_subsystem(subsystem)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->reload_subsystem: #{e}"
end
```

#### Using the reload_subsystem_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> reload_subsystem_with_http_info(subsystem)

```ruby
begin
  # Reload the given subsystem
  data, status_code, headers = api_instance.reload_subsystem_with_http_info(subsystem)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->reload_subsystem_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **subsystem** | **String** |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## remount

> <RemountResponse> remount(remount_request)

Initiate a mount migration

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
remount_request = OpenbaoClient::RemountRequest.new # RemountRequest | 

begin
  # Initiate a mount migration
  result = api_instance.remount(remount_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->remount: #{e}"
end
```

#### Using the remount_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RemountResponse>, Integer, Hash)> remount_with_http_info(remount_request)

```ruby
begin
  # Initiate a mount migration
  data, status_code, headers = api_instance.remount_with_http_info(remount_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RemountResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->remount_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **remount_request** | [**RemountRequest**](RemountRequest.md) |  |  |

### Return type

[**RemountResponse**](RemountResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## remount_status

> <RemountStatusResponse> remount_status(migration_id)

Check status of a mount migration

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
migration_id = 'migration_id_example' # String | The ID of the migration operation

begin
  # Check status of a mount migration
  result = api_instance.remount_status(migration_id)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->remount_status: #{e}"
end
```

#### Using the remount_status_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RemountStatusResponse>, Integer, Hash)> remount_status_with_http_info(migration_id)

```ruby
begin
  # Check status of a mount migration
  data, status_code, headers = api_instance.remount_status_with_http_info(migration_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RemountStatusResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->remount_status_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **migration_id** | **String** | The ID of the migration operation |  |

### Return type

[**RemountStatusResponse**](RemountStatusResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## rewrap

> rewrap(rewrap_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
rewrap_request = OpenbaoClient::RewrapRequest.new # RewrapRequest | 

begin
  
  api_instance.rewrap(rewrap_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rewrap: #{e}"
end
```

#### Using the rewrap_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rewrap_with_http_info(rewrap_request)

```ruby
begin
  
  data, status_code, headers = api_instance.rewrap_with_http_info(rewrap_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->rewrap_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **rewrap_request** | [**RewrapRequest**](RewrapRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## root_token_generation_cancel

> root_token_generation_cancel

Cancels any in-progress root generation attempt.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Cancels any in-progress root generation attempt.
  api_instance.root_token_generation_cancel
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_cancel: #{e}"
end
```

#### Using the root_token_generation_cancel_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> root_token_generation_cancel_with_http_info

```ruby
begin
  # Cancels any in-progress root generation attempt.
  data, status_code, headers = api_instance.root_token_generation_cancel_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_cancel_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## root_token_generation_cancel2

> root_token_generation_cancel2

Cancels any in-progress root generation attempt.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Cancels any in-progress root generation attempt.
  api_instance.root_token_generation_cancel2
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_cancel2: #{e}"
end
```

#### Using the root_token_generation_cancel2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> root_token_generation_cancel2_with_http_info

```ruby
begin
  # Cancels any in-progress root generation attempt.
  data, status_code, headers = api_instance.root_token_generation_cancel2_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_cancel2_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## root_token_generation_initialize

> <RootTokenGenerationInitializeResponse> root_token_generation_initialize(root_token_generation_initialize_request)

Initializes a new root generation attempt.

Only a single root generation attempt can take place at a time. One (and only one) of otp or pgp_key are required.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
root_token_generation_initialize_request = OpenbaoClient::RootTokenGenerationInitializeRequest.new # RootTokenGenerationInitializeRequest | 

begin
  # Initializes a new root generation attempt.
  result = api_instance.root_token_generation_initialize(root_token_generation_initialize_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_initialize: #{e}"
end
```

#### Using the root_token_generation_initialize_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RootTokenGenerationInitializeResponse>, Integer, Hash)> root_token_generation_initialize_with_http_info(root_token_generation_initialize_request)

```ruby
begin
  # Initializes a new root generation attempt.
  data, status_code, headers = api_instance.root_token_generation_initialize_with_http_info(root_token_generation_initialize_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RootTokenGenerationInitializeResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_initialize_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **root_token_generation_initialize_request** | [**RootTokenGenerationInitializeRequest**](RootTokenGenerationInitializeRequest.md) |  |  |

### Return type

[**RootTokenGenerationInitializeResponse**](RootTokenGenerationInitializeResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## root_token_generation_initialize2

> <RootTokenGenerationInitialize2Response> root_token_generation_initialize2(root_token_generation_initialize2_request)

Initializes a new root generation attempt.

Only a single root generation attempt can take place at a time. One (and only one) of otp or pgp_key are required.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
root_token_generation_initialize2_request = OpenbaoClient::RootTokenGenerationInitialize2Request.new # RootTokenGenerationInitialize2Request | 

begin
  # Initializes a new root generation attempt.
  result = api_instance.root_token_generation_initialize2(root_token_generation_initialize2_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_initialize2: #{e}"
end
```

#### Using the root_token_generation_initialize2_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RootTokenGenerationInitialize2Response>, Integer, Hash)> root_token_generation_initialize2_with_http_info(root_token_generation_initialize2_request)

```ruby
begin
  # Initializes a new root generation attempt.
  data, status_code, headers = api_instance.root_token_generation_initialize2_with_http_info(root_token_generation_initialize2_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RootTokenGenerationInitialize2Response>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_initialize2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **root_token_generation_initialize2_request** | [**RootTokenGenerationInitialize2Request**](RootTokenGenerationInitialize2Request.md) |  |  |

### Return type

[**RootTokenGenerationInitialize2Response**](RootTokenGenerationInitialize2Response.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## root_token_generation_read_progress

> <RootTokenGenerationReadProgressResponse> root_token_generation_read_progress

Read the configuration and progress of the current root generation attempt.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Read the configuration and progress of the current root generation attempt.
  result = api_instance.root_token_generation_read_progress
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_read_progress: #{e}"
end
```

#### Using the root_token_generation_read_progress_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RootTokenGenerationReadProgressResponse>, Integer, Hash)> root_token_generation_read_progress_with_http_info

```ruby
begin
  # Read the configuration and progress of the current root generation attempt.
  data, status_code, headers = api_instance.root_token_generation_read_progress_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RootTokenGenerationReadProgressResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_read_progress_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**RootTokenGenerationReadProgressResponse**](RootTokenGenerationReadProgressResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## root_token_generation_read_progress2

> <RootTokenGenerationReadProgress2Response> root_token_generation_read_progress2

Read the configuration and progress of the current root generation attempt.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Read the configuration and progress of the current root generation attempt.
  result = api_instance.root_token_generation_read_progress2
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_read_progress2: #{e}"
end
```

#### Using the root_token_generation_read_progress2_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RootTokenGenerationReadProgress2Response>, Integer, Hash)> root_token_generation_read_progress2_with_http_info

```ruby
begin
  # Read the configuration and progress of the current root generation attempt.
  data, status_code, headers = api_instance.root_token_generation_read_progress2_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RootTokenGenerationReadProgress2Response>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_read_progress2_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**RootTokenGenerationReadProgress2Response**](RootTokenGenerationReadProgress2Response.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## root_token_generation_update

> <RootTokenGenerationUpdateResponse> root_token_generation_update(root_token_generation_update_request)

Enter a single unseal key share to progress the root generation attempt.

If the threshold number of unseal key shares is reached, OpenBao will complete the root generation and issue the new token. Otherwise, this API must be called multiple times until that threshold is met. The attempt nonce must be provided with each call.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
root_token_generation_update_request = OpenbaoClient::RootTokenGenerationUpdateRequest.new # RootTokenGenerationUpdateRequest | 

begin
  # Enter a single unseal key share to progress the root generation attempt.
  result = api_instance.root_token_generation_update(root_token_generation_update_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_update: #{e}"
end
```

#### Using the root_token_generation_update_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<RootTokenGenerationUpdateResponse>, Integer, Hash)> root_token_generation_update_with_http_info(root_token_generation_update_request)

```ruby
begin
  # Enter a single unseal key share to progress the root generation attempt.
  data, status_code, headers = api_instance.root_token_generation_update_with_http_info(root_token_generation_update_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <RootTokenGenerationUpdateResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->root_token_generation_update_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **root_token_generation_update_request** | [**RootTokenGenerationUpdateRequest**](RootTokenGenerationUpdateRequest.md) |  |  |

### Return type

[**RootTokenGenerationUpdateResponse**](RootTokenGenerationUpdateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## seal

> seal

Seal the OpenBao instance.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Seal the OpenBao instance.
  api_instance.seal
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->seal: #{e}"
end
```

#### Using the seal_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> seal_with_http_info

```ruby
begin
  # Seal the OpenBao instance.
  data, status_code, headers = api_instance.seal_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->seal_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## seal_status

> <SealStatusResponse> seal_status

Check the seal status of an OpenBao instance.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Check the seal status of an OpenBao instance.
  result = api_instance.seal_status
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->seal_status: #{e}"
end
```

#### Using the seal_status_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<SealStatusResponse>, Integer, Hash)> seal_status_with_http_info

```ruby
begin
  # Check the seal status of an OpenBao instance.
  data, status_code, headers = api_instance.seal_status_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <SealStatusResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->seal_status_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

[**SealStatusResponse**](SealStatusResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## step_down_leader

> step_down_leader

Cause the node to give up active status.

This endpoint forces the node to give up active status. If the node does not have active status, this endpoint does nothing. Note that the node will sleep for ten seconds before attempting to grab the active lock again, but if no standby nodes grab the active lock in the interim, the same node may become the active node again.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  # Cause the node to give up active status.
  api_instance.step_down_leader
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->step_down_leader: #{e}"
end
```

#### Using the step_down_leader_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> step_down_leader_with_http_info

```ruby
begin
  # Cause the node to give up active status.
  data, status_code, headers = api_instance.step_down_leader_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->step_down_leader_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ui_headers_configure

> ui_headers_configure(header, ui_headers_configure_request)

Configure the values to be returned for the UI header.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
header = 'header_example' # String | The name of the header.
ui_headers_configure_request = OpenbaoClient::UiHeadersConfigureRequest.new # UiHeadersConfigureRequest | 

begin
  # Configure the values to be returned for the UI header.
  api_instance.ui_headers_configure(header, ui_headers_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->ui_headers_configure: #{e}"
end
```

#### Using the ui_headers_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ui_headers_configure_with_http_info(header, ui_headers_configure_request)

```ruby
begin
  # Configure the values to be returned for the UI header.
  data, status_code, headers = api_instance.ui_headers_configure_with_http_info(header, ui_headers_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->ui_headers_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **header** | **String** | The name of the header. |  |
| **ui_headers_configure_request** | [**UiHeadersConfigureRequest**](UiHeadersConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ui_headers_delete_configuration

> ui_headers_delete_configuration(header)

Remove a UI header.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
header = 'header_example' # String | The name of the header.

begin
  # Remove a UI header.
  api_instance.ui_headers_delete_configuration(header)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->ui_headers_delete_configuration: #{e}"
end
```

#### Using the ui_headers_delete_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ui_headers_delete_configuration_with_http_info(header)

```ruby
begin
  # Remove a UI header.
  data, status_code, headers = api_instance.ui_headers_delete_configuration_with_http_info(header)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->ui_headers_delete_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **header** | **String** | The name of the header. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ui_headers_list

> <UiHeadersListResponse> ui_headers_list(list)

Return a list of configured UI headers.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
list = 'true' # String | Must be set to `true`

begin
  # Return a list of configured UI headers.
  result = api_instance.ui_headers_list(list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->ui_headers_list: #{e}"
end
```

#### Using the ui_headers_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UiHeadersListResponse>, Integer, Hash)> ui_headers_list_with_http_info(list)

```ruby
begin
  # Return a list of configured UI headers.
  data, status_code, headers = api_instance.ui_headers_list_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UiHeadersListResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->ui_headers_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**UiHeadersListResponse**](UiHeadersListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## ui_headers_read_configuration

> <UiHeadersReadConfigurationResponse> ui_headers_read_configuration(header)

Return the given UI header's configuration

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
header = 'header_example' # String | The name of the header.

begin
  # Return the given UI header's configuration
  result = api_instance.ui_headers_read_configuration(header)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->ui_headers_read_configuration: #{e}"
end
```

#### Using the ui_headers_read_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UiHeadersReadConfigurationResponse>, Integer, Hash)> ui_headers_read_configuration_with_http_info(header)

```ruby
begin
  # Return the given UI header's configuration
  data, status_code, headers = api_instance.ui_headers_read_configuration_with_http_info(header)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UiHeadersReadConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->ui_headers_read_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **header** | **String** | The name of the header. |  |

### Return type

[**UiHeadersReadConfigurationResponse**](UiHeadersReadConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## unseal

> <UnsealResponse> unseal(unseal_request)

Unseal the OpenBao instance.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
unseal_request = OpenbaoClient::UnsealRequest.new # UnsealRequest | 

begin
  # Unseal the OpenBao instance.
  result = api_instance.unseal(unseal_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->unseal: #{e}"
end
```

#### Using the unseal_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<UnsealResponse>, Integer, Hash)> unseal_with_http_info(unseal_request)

```ruby
begin
  # Unseal the OpenBao instance.
  data, status_code, headers = api_instance.unseal_with_http_info(unseal_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <UnsealResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->unseal_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **unseal_request** | [**UnsealRequest**](UnsealRequest.md) |  |  |

### Return type

[**UnsealResponse**](UnsealResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## unwrap

> unwrap(unwrap_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
unwrap_request = OpenbaoClient::UnwrapRequest.new # UnwrapRequest | 

begin
  
  api_instance.unwrap(unwrap_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->unwrap: #{e}"
end
```

#### Using the unwrap_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> unwrap_with_http_info(unwrap_request)

```ruby
begin
  
  data, status_code, headers = api_instance.unwrap_with_http_info(unwrap_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->unwrap_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **unwrap_request** | [**UnwrapRequest**](UnwrapRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## version_history

> <VersionHistoryResponse> version_history(list)

Returns map of historical version change entries

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new
list = 'true' # String | Must be set to `true`

begin
  # Returns map of historical version change entries
  result = api_instance.version_history(list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->version_history: #{e}"
end
```

#### Using the version_history_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<VersionHistoryResponse>, Integer, Hash)> version_history_with_http_info(list)

```ruby
begin
  # Returns map of historical version change entries
  data, status_code, headers = api_instance.version_history_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <VersionHistoryResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->version_history_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**VersionHistoryResponse**](VersionHistoryResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## wrap

> wrap



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SystemApi.new

begin
  
  api_instance.wrap
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->wrap: #{e}"
end
```

#### Using the wrap_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> wrap_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.wrap_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SystemApi->wrap_with_http_info: #{e}"
end
```

### Parameters

This endpoint does not need any parameter.

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined

