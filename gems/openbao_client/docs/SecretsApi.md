# OpenbaoClient::SecretsApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**cubbyhole_delete**](SecretsApi.md#cubbyhole_delete) | **DELETE** /cubbyhole/{path} | Deletes the secret at the specified location. |
| [**cubbyhole_read**](SecretsApi.md#cubbyhole_read) | **GET** /cubbyhole/{path} | Retrieve the secret at the specified location. |
| [**cubbyhole_write**](SecretsApi.md#cubbyhole_write) | **POST** /cubbyhole/{path} | Store a secret at the specified location. |
| [**database_configure_connection**](SecretsApi.md#database_configure_connection) | **POST** /{database_mount_path}/config/{name} |  |
| [**database_delete_connection_configuration**](SecretsApi.md#database_delete_connection_configuration) | **DELETE** /{database_mount_path}/config/{name} |  |
| [**database_delete_role**](SecretsApi.md#database_delete_role) | **DELETE** /{database_mount_path}/roles/{name} | Manage the roles that can be created with this backend. |
| [**database_delete_static_role**](SecretsApi.md#database_delete_static_role) | **DELETE** /{database_mount_path}/static-roles/{name} | Manage the static roles that can be created with this backend. |
| [**database_generate_credentials**](SecretsApi.md#database_generate_credentials) | **GET** /{database_mount_path}/creds/{name} | Request database credentials for a certain role. |
| [**database_list_connections**](SecretsApi.md#database_list_connections) | **GET** /{database_mount_path}/config | Configure connection details to a database plugin. |
| [**database_list_roles**](SecretsApi.md#database_list_roles) | **GET** /{database_mount_path}/roles | Manage the roles that can be created with this backend. |
| [**database_list_static_roles**](SecretsApi.md#database_list_static_roles) | **GET** /{database_mount_path}/static-roles | Manage the static roles that can be created with this backend. |
| [**database_read_connection_configuration**](SecretsApi.md#database_read_connection_configuration) | **GET** /{database_mount_path}/config/{name} |  |
| [**database_read_role**](SecretsApi.md#database_read_role) | **GET** /{database_mount_path}/roles/{name} | Manage the roles that can be created with this backend. |
| [**database_read_static_role**](SecretsApi.md#database_read_static_role) | **GET** /{database_mount_path}/static-roles/{name} | Manage the static roles that can be created with this backend. |
| [**database_read_static_role_credentials**](SecretsApi.md#database_read_static_role_credentials) | **GET** /{database_mount_path}/static-creds/{name} | Request database credentials for a certain static role. These credentials are rotated periodically. |
| [**database_reset_connection**](SecretsApi.md#database_reset_connection) | **POST** /{database_mount_path}/reset/{name} | Resets a database plugin. |
| [**database_rotate_root_credentials**](SecretsApi.md#database_rotate_root_credentials) | **POST** /{database_mount_path}/rotate-root/{name} |  |
| [**database_rotate_static_role_credentials**](SecretsApi.md#database_rotate_static_role_credentials) | **POST** /{database_mount_path}/rotate-role/{name} |  |
| [**database_write_role**](SecretsApi.md#database_write_role) | **POST** /{database_mount_path}/roles/{name} | Manage the roles that can be created with this backend. |
| [**database_write_static_role**](SecretsApi.md#database_write_static_role) | **POST** /{database_mount_path}/static-roles/{name} | Manage the static roles that can be created with this backend. |
| [**kubernetes_check_configuration**](SecretsApi.md#kubernetes_check_configuration) | **GET** /{kubernetes_mount_path}/check |  |
| [**kubernetes_configure**](SecretsApi.md#kubernetes_configure) | **POST** /{kubernetes_mount_path}/config |  |
| [**kubernetes_delete_configuration**](SecretsApi.md#kubernetes_delete_configuration) | **DELETE** /{kubernetes_mount_path}/config |  |
| [**kubernetes_delete_role**](SecretsApi.md#kubernetes_delete_role) | **DELETE** /{kubernetes_mount_path}/roles/{name} |  |
| [**kubernetes_generate_credentials**](SecretsApi.md#kubernetes_generate_credentials) | **POST** /{kubernetes_mount_path}/creds/{name} |  |
| [**kubernetes_list_roles**](SecretsApi.md#kubernetes_list_roles) | **GET** /{kubernetes_mount_path}/roles |  |
| [**kubernetes_read_configuration**](SecretsApi.md#kubernetes_read_configuration) | **GET** /{kubernetes_mount_path}/config |  |
| [**kubernetes_read_role**](SecretsApi.md#kubernetes_read_role) | **GET** /{kubernetes_mount_path}/roles/{name} |  |
| [**kubernetes_write_role**](SecretsApi.md#kubernetes_write_role) | **POST** /{kubernetes_mount_path}/roles/{name} |  |
| [**kv_delete_data_path**](SecretsApi.md#kv_delete_data_path) | **DELETE** /{kv_v2_mount_path}/data/{path} | Write, Patch, Read, and Delete data in the Key-Value Store. |
| [**kv_delete_metadata_path**](SecretsApi.md#kv_delete_metadata_path) | **DELETE** /{kv_v2_mount_path}/metadata/{path} | Configures settings for the KV store |
| [**kv_delete_path**](SecretsApi.md#kv_delete_path) | **DELETE** /{kv_v1_mount_path}/{path} | Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage. |
| [**kv_read_config**](SecretsApi.md#kv_read_config) | **GET** /{kv_v2_mount_path}/config | Read the backend level settings. |
| [**kv_read_data_path**](SecretsApi.md#kv_read_data_path) | **GET** /{kv_v2_mount_path}/data/{path} | Write, Patch, Read, and Delete data in the Key-Value Store. |
| [**kv_read_metadata_path**](SecretsApi.md#kv_read_metadata_path) | **GET** /{kv_v2_mount_path}/metadata/{path} | Configures settings for the KV store |
| [**kv_read_path**](SecretsApi.md#kv_read_path) | **GET** /{kv_v1_mount_path}/{path} | Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage. |
| [**kv_read_subkeys_path**](SecretsApi.md#kv_read_subkeys_path) | **GET** /{kv_v2_mount_path}/subkeys/{path} | Read the structure of a secret entry from the Key-Value store with the values removed. |
| [**kv_write_config**](SecretsApi.md#kv_write_config) | **POST** /{kv_v2_mount_path}/config | Configure backend level settings that are applied to every key in the key-value store. |
| [**kv_write_data_path**](SecretsApi.md#kv_write_data_path) | **POST** /{kv_v2_mount_path}/data/{path} | Write, Patch, Read, and Delete data in the Key-Value Store. |
| [**kv_write_delete_path**](SecretsApi.md#kv_write_delete_path) | **POST** /{kv_v2_mount_path}/delete/{path} | Marks one or more versions as deleted in the KV store. |
| [**kv_write_destroy_path**](SecretsApi.md#kv_write_destroy_path) | **POST** /{kv_v2_mount_path}/destroy/{path} | Permanently removes one or more versions in the KV store |
| [**kv_write_metadata_path**](SecretsApi.md#kv_write_metadata_path) | **POST** /{kv_v2_mount_path}/metadata/{path} | Configures settings for the KV store |
| [**kv_write_path**](SecretsApi.md#kv_write_path) | **POST** /{kv_v1_mount_path}/{path} | Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage. |
| [**kv_write_undelete_path**](SecretsApi.md#kv_write_undelete_path) | **POST** /{kv_v2_mount_path}/undelete/{path} | Undeletes one or more versions from the KV store. |
| [**ldap_configure**](SecretsApi.md#ldap_configure) | **POST** /{ldap_mount_path}/config |  |
| [**ldap_delete_configuration**](SecretsApi.md#ldap_delete_configuration) | **DELETE** /{ldap_mount_path}/config |  |
| [**ldap_delete_dynamic_role**](SecretsApi.md#ldap_delete_dynamic_role) | **DELETE** /{ldap_mount_path}/role/{name} |  |
| [**ldap_delete_static_role**](SecretsApi.md#ldap_delete_static_role) | **DELETE** /{ldap_mount_path}/static-role/{name} |  |
| [**ldap_library_check_in**](SecretsApi.md#ldap_library_check_in) | **POST** /{ldap_mount_path}/library/{name}/check-in | Check service accounts in to the library. |
| [**ldap_library_check_out**](SecretsApi.md#ldap_library_check_out) | **POST** /{ldap_mount_path}/library/{name}/check-out | Check a service account out from the library. |
| [**ldap_library_check_status**](SecretsApi.md#ldap_library_check_status) | **GET** /{ldap_mount_path}/library/{name}/status | Check the status of the service accounts in a library set. |
| [**ldap_library_configure**](SecretsApi.md#ldap_library_configure) | **POST** /{ldap_mount_path}/library/{name} | Update a library set. |
| [**ldap_library_delete**](SecretsApi.md#ldap_library_delete) | **DELETE** /{ldap_mount_path}/library/{name} | Delete a library set. |
| [**ldap_library_force_check_in**](SecretsApi.md#ldap_library_force_check_in) | **POST** /{ldap_mount_path}/library/manage/{name}/check-in | Check service accounts in to the library. |
| [**ldap_library_list**](SecretsApi.md#ldap_library_list) | **GET** /{ldap_mount_path}/library |  |
| [**ldap_library_read**](SecretsApi.md#ldap_library_read) | **GET** /{ldap_mount_path}/library/{name} | Read a library set. |
| [**ldap_list_dynamic_roles**](SecretsApi.md#ldap_list_dynamic_roles) | **GET** /{ldap_mount_path}/role |  |
| [**ldap_list_static_roles**](SecretsApi.md#ldap_list_static_roles) | **GET** /{ldap_mount_path}/static-role |  |
| [**ldap_read_configuration**](SecretsApi.md#ldap_read_configuration) | **GET** /{ldap_mount_path}/config |  |
| [**ldap_read_dynamic_role**](SecretsApi.md#ldap_read_dynamic_role) | **GET** /{ldap_mount_path}/role/{name} |  |
| [**ldap_read_static_role**](SecretsApi.md#ldap_read_static_role) | **GET** /{ldap_mount_path}/static-role/{name} |  |
| [**ldap_request_dynamic_role_credentials**](SecretsApi.md#ldap_request_dynamic_role_credentials) | **GET** /{ldap_mount_path}/creds/{name} |  |
| [**ldap_request_static_role_credentials**](SecretsApi.md#ldap_request_static_role_credentials) | **GET** /{ldap_mount_path}/static-cred/{name} |  |
| [**ldap_rotate_root_credentials**](SecretsApi.md#ldap_rotate_root_credentials) | **POST** /{ldap_mount_path}/rotate-root |  |
| [**ldap_rotate_static_role**](SecretsApi.md#ldap_rotate_static_role) | **POST** /{ldap_mount_path}/rotate-role/{name} |  |
| [**ldap_write_dynamic_role**](SecretsApi.md#ldap_write_dynamic_role) | **POST** /{ldap_mount_path}/role/{name} |  |
| [**ldap_write_static_role**](SecretsApi.md#ldap_write_static_role) | **POST** /{ldap_mount_path}/static-role/{name} |  |
| [**pki_configure_acme**](SecretsApi.md#pki_configure_acme) | **POST** /{pki_mount_path}/config/acme |  |
| [**pki_configure_auto_tidy**](SecretsApi.md#pki_configure_auto_tidy) | **POST** /{pki_mount_path}/config/auto-tidy |  |
| [**pki_configure_ca**](SecretsApi.md#pki_configure_ca) | **POST** /{pki_mount_path}/config/ca |  |
| [**pki_configure_cluster**](SecretsApi.md#pki_configure_cluster) | **POST** /{pki_mount_path}/config/cluster |  |
| [**pki_configure_crl**](SecretsApi.md#pki_configure_crl) | **POST** /{pki_mount_path}/config/crl |  |
| [**pki_configure_issuers**](SecretsApi.md#pki_configure_issuers) | **POST** /{pki_mount_path}/config/issuers |  |
| [**pki_configure_keys**](SecretsApi.md#pki_configure_keys) | **POST** /{pki_mount_path}/config/keys |  |
| [**pki_configure_urls**](SecretsApi.md#pki_configure_urls) | **POST** /{pki_mount_path}/config/urls |  |
| [**pki_cross_sign_intermediate**](SecretsApi.md#pki_cross_sign_intermediate) | **POST** /{pki_mount_path}/intermediate/cross-sign |  |
| [**pki_delete_eab_key**](SecretsApi.md#pki_delete_eab_key) | **DELETE** /{pki_mount_path}/eab/{key_id} |  |
| [**pki_delete_issuer**](SecretsApi.md#pki_delete_issuer) | **DELETE** /{pki_mount_path}/issuer/{issuer_ref} |  |
| [**pki_delete_key**](SecretsApi.md#pki_delete_key) | **DELETE** /{pki_mount_path}/key/{key_ref} |  |
| [**pki_delete_role**](SecretsApi.md#pki_delete_role) | **DELETE** /{pki_mount_path}/roles/{name} |  |
| [**pki_delete_root**](SecretsApi.md#pki_delete_root) | **DELETE** /{pki_mount_path}/root |  |
| [**pki_generate_eab_key**](SecretsApi.md#pki_generate_eab_key) | **POST** /{pki_mount_path}/acme/new-eab |  |
| [**pki_generate_eab_key_for_issuer**](SecretsApi.md#pki_generate_eab_key_for_issuer) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/new-eab |  |
| [**pki_generate_eab_key_for_issuer_and_role**](SecretsApi.md#pki_generate_eab_key_for_issuer_and_role) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/new-eab |  |
| [**pki_generate_eab_key_for_role**](SecretsApi.md#pki_generate_eab_key_for_role) | **POST** /{pki_mount_path}/roles/{role}/acme/new-eab |  |
| [**pki_generate_exported_key**](SecretsApi.md#pki_generate_exported_key) | **POST** /{pki_mount_path}/keys/generate/exported |  |
| [**pki_generate_intermediate**](SecretsApi.md#pki_generate_intermediate) | **POST** /{pki_mount_path}/intermediate/generate/{exported} |  |
| [**pki_generate_internal_key**](SecretsApi.md#pki_generate_internal_key) | **POST** /{pki_mount_path}/keys/generate/internal |  |
| [**pki_generate_kms_key**](SecretsApi.md#pki_generate_kms_key) | **POST** /{pki_mount_path}/keys/generate/kms |  |
| [**pki_generate_root**](SecretsApi.md#pki_generate_root) | **POST** /{pki_mount_path}/root/generate/{exported} |  |
| [**pki_import_key**](SecretsApi.md#pki_import_key) | **POST** /{pki_mount_path}/keys/import |  |
| [**pki_issue_with_role**](SecretsApi.md#pki_issue_with_role) | **POST** /{pki_mount_path}/issue/{role} |  |
| [**pki_issuer_issue_with_role**](SecretsApi.md#pki_issuer_issue_with_role) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/issue/{role} |  |
| [**pki_issuer_read_crl**](SecretsApi.md#pki_issuer_read_crl) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/crl |  |
| [**pki_issuer_read_crl_delta**](SecretsApi.md#pki_issuer_read_crl_delta) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/crl/delta |  |
| [**pki_issuer_read_crl_delta_der**](SecretsApi.md#pki_issuer_read_crl_delta_der) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/crl/delta/der |  |
| [**pki_issuer_read_crl_delta_pem**](SecretsApi.md#pki_issuer_read_crl_delta_pem) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/crl/delta/pem |  |
| [**pki_issuer_read_crl_der**](SecretsApi.md#pki_issuer_read_crl_der) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/crl/der |  |
| [**pki_issuer_read_crl_pem**](SecretsApi.md#pki_issuer_read_crl_pem) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/crl/pem |  |
| [**pki_issuer_resign_crls**](SecretsApi.md#pki_issuer_resign_crls) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/resign-crls |  |
| [**pki_issuer_sign_intermediate**](SecretsApi.md#pki_issuer_sign_intermediate) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/sign-intermediate |  |
| [**pki_issuer_sign_revocation_list**](SecretsApi.md#pki_issuer_sign_revocation_list) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/sign-revocation-list |  |
| [**pki_issuer_sign_self_issued**](SecretsApi.md#pki_issuer_sign_self_issued) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/sign-self-issued |  |
| [**pki_issuer_sign_verbatim**](SecretsApi.md#pki_issuer_sign_verbatim) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/sign-verbatim |  |
| [**pki_issuer_sign_verbatim_with_role**](SecretsApi.md#pki_issuer_sign_verbatim_with_role) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/sign-verbatim/{role} |  |
| [**pki_issuer_sign_with_role**](SecretsApi.md#pki_issuer_sign_with_role) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/sign/{role} |  |
| [**pki_issuers_generate_intermediate**](SecretsApi.md#pki_issuers_generate_intermediate) | **POST** /{pki_mount_path}/issuers/generate/intermediate/{exported} |  |
| [**pki_issuers_generate_root**](SecretsApi.md#pki_issuers_generate_root) | **POST** /{pki_mount_path}/issuers/generate/root/{exported} |  |
| [**pki_issuers_import_bundle**](SecretsApi.md#pki_issuers_import_bundle) | **POST** /{pki_mount_path}/issuers/import/bundle |  |
| [**pki_issuers_import_cert**](SecretsApi.md#pki_issuers_import_cert) | **POST** /{pki_mount_path}/issuers/import/cert |  |
| [**pki_list_certs**](SecretsApi.md#pki_list_certs) | **GET** /{pki_mount_path}/certs |  |
| [**pki_list_eab_keys**](SecretsApi.md#pki_list_eab_keys) | **GET** /{pki_mount_path}/eab |  |
| [**pki_list_issuers**](SecretsApi.md#pki_list_issuers) | **GET** /{pki_mount_path}/issuers |  |
| [**pki_list_keys**](SecretsApi.md#pki_list_keys) | **GET** /{pki_mount_path}/keys |  |
| [**pki_list_revoked_certs**](SecretsApi.md#pki_list_revoked_certs) | **GET** /{pki_mount_path}/certs/revoked |  |
| [**pki_list_roles**](SecretsApi.md#pki_list_roles) | **GET** /{pki_mount_path}/roles |  |
| [**pki_query_ocsp**](SecretsApi.md#pki_query_ocsp) | **POST** /{pki_mount_path}/ocsp |  |
| [**pki_query_ocsp_with_get_req**](SecretsApi.md#pki_query_ocsp_with_get_req) | **GET** /{pki_mount_path}/ocsp/{req} |  |
| [**pki_read_acme_configuration**](SecretsApi.md#pki_read_acme_configuration) | **GET** /{pki_mount_path}/config/acme |  |
| [**pki_read_acme_directory**](SecretsApi.md#pki_read_acme_directory) | **GET** /{pki_mount_path}/acme/directory |  |
| [**pki_read_acme_new_nonce**](SecretsApi.md#pki_read_acme_new_nonce) | **GET** /{pki_mount_path}/acme/new-nonce |  |
| [**pki_read_auto_tidy_configuration**](SecretsApi.md#pki_read_auto_tidy_configuration) | **GET** /{pki_mount_path}/config/auto-tidy |  |
| [**pki_read_ca_chain_pem**](SecretsApi.md#pki_read_ca_chain_pem) | **GET** /{pki_mount_path}/ca_chain |  |
| [**pki_read_ca_der**](SecretsApi.md#pki_read_ca_der) | **GET** /{pki_mount_path}/ca |  |
| [**pki_read_ca_pem**](SecretsApi.md#pki_read_ca_pem) | **GET** /{pki_mount_path}/ca/pem |  |
| [**pki_read_cert**](SecretsApi.md#pki_read_cert) | **GET** /{pki_mount_path}/cert/{serial} |  |
| [**pki_read_cert_ca_chain**](SecretsApi.md#pki_read_cert_ca_chain) | **GET** /{pki_mount_path}/cert/ca_chain |  |
| [**pki_read_cert_crl**](SecretsApi.md#pki_read_cert_crl) | **GET** /{pki_mount_path}/cert/crl |  |
| [**pki_read_cert_delta_crl**](SecretsApi.md#pki_read_cert_delta_crl) | **GET** /{pki_mount_path}/cert/delta-crl |  |
| [**pki_read_cert_raw_der**](SecretsApi.md#pki_read_cert_raw_der) | **GET** /{pki_mount_path}/cert/{serial}/raw |  |
| [**pki_read_cert_raw_pem**](SecretsApi.md#pki_read_cert_raw_pem) | **GET** /{pki_mount_path}/cert/{serial}/raw/pem |  |
| [**pki_read_cluster_configuration**](SecretsApi.md#pki_read_cluster_configuration) | **GET** /{pki_mount_path}/config/cluster |  |
| [**pki_read_crl_configuration**](SecretsApi.md#pki_read_crl_configuration) | **GET** /{pki_mount_path}/config/crl |  |
| [**pki_read_crl_delta**](SecretsApi.md#pki_read_crl_delta) | **GET** /{pki_mount_path}/crl/delta |  |
| [**pki_read_crl_delta_pem**](SecretsApi.md#pki_read_crl_delta_pem) | **GET** /{pki_mount_path}/crl/delta/pem |  |
| [**pki_read_crl_der**](SecretsApi.md#pki_read_crl_der) | **GET** /{pki_mount_path}/crl |  |
| [**pki_read_crl_pem**](SecretsApi.md#pki_read_crl_pem) | **GET** /{pki_mount_path}/crl/pem |  |
| [**pki_read_issuer**](SecretsApi.md#pki_read_issuer) | **GET** /{pki_mount_path}/issuer/{issuer_ref} |  |
| [**pki_read_issuer_der**](SecretsApi.md#pki_read_issuer_der) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/der |  |
| [**pki_read_issuer_issuer_ref_acme_directory**](SecretsApi.md#pki_read_issuer_issuer_ref_acme_directory) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/acme/directory |  |
| [**pki_read_issuer_issuer_ref_acme_new_nonce**](SecretsApi.md#pki_read_issuer_issuer_ref_acme_new_nonce) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/acme/new-nonce |  |
| [**pki_read_issuer_issuer_ref_roles_role_acme_directory**](SecretsApi.md#pki_read_issuer_issuer_ref_roles_role_acme_directory) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/directory |  |
| [**pki_read_issuer_issuer_ref_roles_role_acme_new_nonce**](SecretsApi.md#pki_read_issuer_issuer_ref_roles_role_acme_new_nonce) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/new-nonce |  |
| [**pki_read_issuer_json**](SecretsApi.md#pki_read_issuer_json) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/json |  |
| [**pki_read_issuer_pem**](SecretsApi.md#pki_read_issuer_pem) | **GET** /{pki_mount_path}/issuer/{issuer_ref}/pem |  |
| [**pki_read_issuers_configuration**](SecretsApi.md#pki_read_issuers_configuration) | **GET** /{pki_mount_path}/config/issuers |  |
| [**pki_read_key**](SecretsApi.md#pki_read_key) | **GET** /{pki_mount_path}/key/{key_ref} |  |
| [**pki_read_keys_configuration**](SecretsApi.md#pki_read_keys_configuration) | **GET** /{pki_mount_path}/config/keys |  |
| [**pki_read_role**](SecretsApi.md#pki_read_role) | **GET** /{pki_mount_path}/roles/{name} |  |
| [**pki_read_roles_role_acme_directory**](SecretsApi.md#pki_read_roles_role_acme_directory) | **GET** /{pki_mount_path}/roles/{role}/acme/directory |  |
| [**pki_read_roles_role_acme_new_nonce**](SecretsApi.md#pki_read_roles_role_acme_new_nonce) | **GET** /{pki_mount_path}/roles/{role}/acme/new-nonce |  |
| [**pki_read_urls_configuration**](SecretsApi.md#pki_read_urls_configuration) | **GET** /{pki_mount_path}/config/urls |  |
| [**pki_replace_root**](SecretsApi.md#pki_replace_root) | **POST** /{pki_mount_path}/root/replace |  |
| [**pki_revoke**](SecretsApi.md#pki_revoke) | **POST** /{pki_mount_path}/revoke |  |
| [**pki_revoke_issuer**](SecretsApi.md#pki_revoke_issuer) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/revoke |  |
| [**pki_revoke_with_key**](SecretsApi.md#pki_revoke_with_key) | **POST** /{pki_mount_path}/revoke-with-key |  |
| [**pki_root_sign_intermediate**](SecretsApi.md#pki_root_sign_intermediate) | **POST** /{pki_mount_path}/root/sign-intermediate |  |
| [**pki_root_sign_self_issued**](SecretsApi.md#pki_root_sign_self_issued) | **POST** /{pki_mount_path}/root/sign-self-issued |  |
| [**pki_rotate_crl**](SecretsApi.md#pki_rotate_crl) | **GET** /{pki_mount_path}/crl/rotate |  |
| [**pki_rotate_delta_crl**](SecretsApi.md#pki_rotate_delta_crl) | **GET** /{pki_mount_path}/crl/rotate-delta |  |
| [**pki_rotate_root**](SecretsApi.md#pki_rotate_root) | **POST** /{pki_mount_path}/root/rotate/{exported} |  |
| [**pki_set_signed_intermediate**](SecretsApi.md#pki_set_signed_intermediate) | **POST** /{pki_mount_path}/intermediate/set-signed |  |
| [**pki_sign_verbatim**](SecretsApi.md#pki_sign_verbatim) | **POST** /{pki_mount_path}/sign-verbatim |  |
| [**pki_sign_verbatim_with_role**](SecretsApi.md#pki_sign_verbatim_with_role) | **POST** /{pki_mount_path}/sign-verbatim/{role} |  |
| [**pki_sign_with_role**](SecretsApi.md#pki_sign_with_role) | **POST** /{pki_mount_path}/sign/{role} |  |
| [**pki_tidy**](SecretsApi.md#pki_tidy) | **POST** /{pki_mount_path}/tidy |  |
| [**pki_tidy_cancel**](SecretsApi.md#pki_tidy_cancel) | **POST** /{pki_mount_path}/tidy-cancel |  |
| [**pki_tidy_status**](SecretsApi.md#pki_tidy_status) | **GET** /{pki_mount_path}/tidy-status |  |
| [**pki_write_acme_account_kid**](SecretsApi.md#pki_write_acme_account_kid) | **POST** /{pki_mount_path}/acme/account/{kid} |  |
| [**pki_write_acme_authorization_auth_id**](SecretsApi.md#pki_write_acme_authorization_auth_id) | **POST** /{pki_mount_path}/acme/authorization/{auth_id} |  |
| [**pki_write_acme_challenge_auth_id_challenge_type**](SecretsApi.md#pki_write_acme_challenge_auth_id_challenge_type) | **POST** /{pki_mount_path}/acme/challenge/{auth_id}/{challenge_type} |  |
| [**pki_write_acme_new_account**](SecretsApi.md#pki_write_acme_new_account) | **POST** /{pki_mount_path}/acme/new-account |  |
| [**pki_write_acme_new_order**](SecretsApi.md#pki_write_acme_new_order) | **POST** /{pki_mount_path}/acme/new-order |  |
| [**pki_write_acme_order_order_id**](SecretsApi.md#pki_write_acme_order_order_id) | **POST** /{pki_mount_path}/acme/order/{order_id} |  |
| [**pki_write_acme_order_order_id_cert**](SecretsApi.md#pki_write_acme_order_order_id_cert) | **POST** /{pki_mount_path}/acme/order/{order_id}/cert |  |
| [**pki_write_acme_order_order_id_finalize**](SecretsApi.md#pki_write_acme_order_order_id_finalize) | **POST** /{pki_mount_path}/acme/order/{order_id}/finalize |  |
| [**pki_write_acme_orders**](SecretsApi.md#pki_write_acme_orders) | **POST** /{pki_mount_path}/acme/orders |  |
| [**pki_write_acme_revoke_cert**](SecretsApi.md#pki_write_acme_revoke_cert) | **POST** /{pki_mount_path}/acme/revoke-cert |  |
| [**pki_write_issuer**](SecretsApi.md#pki_write_issuer) | **POST** /{pki_mount_path}/issuer/{issuer_ref} |  |
| [**pki_write_issuer_issuer_ref_acme_account_kid**](SecretsApi.md#pki_write_issuer_issuer_ref_acme_account_kid) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/account/{kid} |  |
| [**pki_write_issuer_issuer_ref_acme_authorization_auth_id**](SecretsApi.md#pki_write_issuer_issuer_ref_acme_authorization_auth_id) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/authorization/{auth_id} |  |
| [**pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type**](SecretsApi.md#pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/challenge/{auth_id}/{challenge_type} |  |
| [**pki_write_issuer_issuer_ref_acme_new_account**](SecretsApi.md#pki_write_issuer_issuer_ref_acme_new_account) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/new-account |  |
| [**pki_write_issuer_issuer_ref_acme_new_order**](SecretsApi.md#pki_write_issuer_issuer_ref_acme_new_order) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/new-order |  |
| [**pki_write_issuer_issuer_ref_acme_order_order_id**](SecretsApi.md#pki_write_issuer_issuer_ref_acme_order_order_id) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/order/{order_id} |  |
| [**pki_write_issuer_issuer_ref_acme_order_order_id_cert**](SecretsApi.md#pki_write_issuer_issuer_ref_acme_order_order_id_cert) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/order/{order_id}/cert |  |
| [**pki_write_issuer_issuer_ref_acme_order_order_id_finalize**](SecretsApi.md#pki_write_issuer_issuer_ref_acme_order_order_id_finalize) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/order/{order_id}/finalize |  |
| [**pki_write_issuer_issuer_ref_acme_orders**](SecretsApi.md#pki_write_issuer_issuer_ref_acme_orders) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/orders |  |
| [**pki_write_issuer_issuer_ref_acme_revoke_cert**](SecretsApi.md#pki_write_issuer_issuer_ref_acme_revoke_cert) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/acme/revoke-cert |  |
| [**pki_write_issuer_issuer_ref_roles_role_acme_account_kid**](SecretsApi.md#pki_write_issuer_issuer_ref_roles_role_acme_account_kid) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/account/{kid} |  |
| [**pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id**](SecretsApi.md#pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/authorization/{auth_id} |  |
| [**pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type**](SecretsApi.md#pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/challenge/{auth_id}/{challenge_type} |  |
| [**pki_write_issuer_issuer_ref_roles_role_acme_new_account**](SecretsApi.md#pki_write_issuer_issuer_ref_roles_role_acme_new_account) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/new-account |  |
| [**pki_write_issuer_issuer_ref_roles_role_acme_new_order**](SecretsApi.md#pki_write_issuer_issuer_ref_roles_role_acme_new_order) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/new-order |  |
| [**pki_write_issuer_issuer_ref_roles_role_acme_order_order_id**](SecretsApi.md#pki_write_issuer_issuer_ref_roles_role_acme_order_order_id) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/order/{order_id} |  |
| [**pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert**](SecretsApi.md#pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/order/{order_id}/cert |  |
| [**pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize**](SecretsApi.md#pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/order/{order_id}/finalize |  |
| [**pki_write_issuer_issuer_ref_roles_role_acme_orders**](SecretsApi.md#pki_write_issuer_issuer_ref_roles_role_acme_orders) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/orders |  |
| [**pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert**](SecretsApi.md#pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert) | **POST** /{pki_mount_path}/issuer/{issuer_ref}/roles/{role}/acme/revoke-cert |  |
| [**pki_write_key**](SecretsApi.md#pki_write_key) | **POST** /{pki_mount_path}/key/{key_ref} |  |
| [**pki_write_role**](SecretsApi.md#pki_write_role) | **POST** /{pki_mount_path}/roles/{name} |  |
| [**pki_write_roles_role_acme_account_kid**](SecretsApi.md#pki_write_roles_role_acme_account_kid) | **POST** /{pki_mount_path}/roles/{role}/acme/account/{kid} |  |
| [**pki_write_roles_role_acme_authorization_auth_id**](SecretsApi.md#pki_write_roles_role_acme_authorization_auth_id) | **POST** /{pki_mount_path}/roles/{role}/acme/authorization/{auth_id} |  |
| [**pki_write_roles_role_acme_challenge_auth_id_challenge_type**](SecretsApi.md#pki_write_roles_role_acme_challenge_auth_id_challenge_type) | **POST** /{pki_mount_path}/roles/{role}/acme/challenge/{auth_id}/{challenge_type} |  |
| [**pki_write_roles_role_acme_new_account**](SecretsApi.md#pki_write_roles_role_acme_new_account) | **POST** /{pki_mount_path}/roles/{role}/acme/new-account |  |
| [**pki_write_roles_role_acme_new_order**](SecretsApi.md#pki_write_roles_role_acme_new_order) | **POST** /{pki_mount_path}/roles/{role}/acme/new-order |  |
| [**pki_write_roles_role_acme_order_order_id**](SecretsApi.md#pki_write_roles_role_acme_order_order_id) | **POST** /{pki_mount_path}/roles/{role}/acme/order/{order_id} |  |
| [**pki_write_roles_role_acme_order_order_id_cert**](SecretsApi.md#pki_write_roles_role_acme_order_order_id_cert) | **POST** /{pki_mount_path}/roles/{role}/acme/order/{order_id}/cert |  |
| [**pki_write_roles_role_acme_order_order_id_finalize**](SecretsApi.md#pki_write_roles_role_acme_order_order_id_finalize) | **POST** /{pki_mount_path}/roles/{role}/acme/order/{order_id}/finalize |  |
| [**pki_write_roles_role_acme_orders**](SecretsApi.md#pki_write_roles_role_acme_orders) | **POST** /{pki_mount_path}/roles/{role}/acme/orders |  |
| [**pki_write_roles_role_acme_revoke_cert**](SecretsApi.md#pki_write_roles_role_acme_revoke_cert) | **POST** /{pki_mount_path}/roles/{role}/acme/revoke-cert |  |
| [**rabbit_mq_configure_connection**](SecretsApi.md#rabbit_mq_configure_connection) | **POST** /{rabbitmq_mount_path}/config/connection | Configure the connection URI, username, and password to talk to RabbitMQ management HTTP API. |
| [**rabbit_mq_configure_lease**](SecretsApi.md#rabbit_mq_configure_lease) | **POST** /{rabbitmq_mount_path}/config/lease |  |
| [**rabbit_mq_delete_role**](SecretsApi.md#rabbit_mq_delete_role) | **DELETE** /{rabbitmq_mount_path}/roles/{name} | Manage the roles that can be created with this backend. |
| [**rabbit_mq_list_roles**](SecretsApi.md#rabbit_mq_list_roles) | **GET** /{rabbitmq_mount_path}/roles | Manage the roles that can be created with this backend. |
| [**rabbit_mq_read_lease_configuration**](SecretsApi.md#rabbit_mq_read_lease_configuration) | **GET** /{rabbitmq_mount_path}/config/lease |  |
| [**rabbit_mq_read_role**](SecretsApi.md#rabbit_mq_read_role) | **GET** /{rabbitmq_mount_path}/roles/{name} | Manage the roles that can be created with this backend. |
| [**rabbit_mq_request_credentials**](SecretsApi.md#rabbit_mq_request_credentials) | **GET** /{rabbitmq_mount_path}/creds/{name} | Request RabbitMQ credentials for a certain role. |
| [**rabbit_mq_write_role**](SecretsApi.md#rabbit_mq_write_role) | **POST** /{rabbitmq_mount_path}/roles/{name} | Manage the roles that can be created with this backend. |
| [**ssh_configure_ca**](SecretsApi.md#ssh_configure_ca) | **POST** /{ssh_mount_path}/config/ca |  |
| [**ssh_configure_zero_address**](SecretsApi.md#ssh_configure_zero_address) | **POST** /{ssh_mount_path}/config/zeroaddress |  |
| [**ssh_delete_ca_configuration**](SecretsApi.md#ssh_delete_ca_configuration) | **DELETE** /{ssh_mount_path}/config/ca |  |
| [**ssh_delete_role**](SecretsApi.md#ssh_delete_role) | **DELETE** /{ssh_mount_path}/roles/{role} | Manage the &#39;roles&#39; that can be created with this backend. |
| [**ssh_delete_zero_address_configuration**](SecretsApi.md#ssh_delete_zero_address_configuration) | **DELETE** /{ssh_mount_path}/config/zeroaddress |  |
| [**ssh_generate_credentials**](SecretsApi.md#ssh_generate_credentials) | **POST** /{ssh_mount_path}/creds/{role} | Creates a credential for establishing SSH connection with the remote host. |
| [**ssh_issue_certificate**](SecretsApi.md#ssh_issue_certificate) | **POST** /{ssh_mount_path}/issue/{role} |  |
| [**ssh_list_roles**](SecretsApi.md#ssh_list_roles) | **GET** /{ssh_mount_path}/roles | Manage the &#39;roles&#39; that can be created with this backend. |
| [**ssh_list_roles_by_ip**](SecretsApi.md#ssh_list_roles_by_ip) | **POST** /{ssh_mount_path}/lookup | List all the roles associated with the given IP address. |
| [**ssh_read_ca_configuration**](SecretsApi.md#ssh_read_ca_configuration) | **GET** /{ssh_mount_path}/config/ca |  |
| [**ssh_read_public_key**](SecretsApi.md#ssh_read_public_key) | **GET** /{ssh_mount_path}/public_key | Retrieve the public key. |
| [**ssh_read_role**](SecretsApi.md#ssh_read_role) | **GET** /{ssh_mount_path}/roles/{role} | Manage the &#39;roles&#39; that can be created with this backend. |
| [**ssh_read_zero_address_configuration**](SecretsApi.md#ssh_read_zero_address_configuration) | **GET** /{ssh_mount_path}/config/zeroaddress |  |
| [**ssh_sign_certificate**](SecretsApi.md#ssh_sign_certificate) | **POST** /{ssh_mount_path}/sign/{role} | Request signing an SSH key using a certain role with the provided details. |
| [**ssh_tidy_dynamic_host_keys**](SecretsApi.md#ssh_tidy_dynamic_host_keys) | **DELETE** /{ssh_mount_path}/tidy/dynamic-keys | This endpoint removes the stored host keys used for the removed Dynamic Key feature, if present. |
| [**ssh_verify_otp**](SecretsApi.md#ssh_verify_otp) | **POST** /{ssh_mount_path}/verify | Validate the OTP provided by OpenBao SSH Agent. |
| [**ssh_write_role**](SecretsApi.md#ssh_write_role) | **POST** /{ssh_mount_path}/roles/{role} | Manage the &#39;roles&#39; that can be created with this backend. |
| [**totp_create_key**](SecretsApi.md#totp_create_key) | **POST** /{totp_mount_path}/keys/{name} |  |
| [**totp_delete_key**](SecretsApi.md#totp_delete_key) | **DELETE** /{totp_mount_path}/keys/{name} |  |
| [**totp_generate_code**](SecretsApi.md#totp_generate_code) | **GET** /{totp_mount_path}/code/{name} |  |
| [**totp_list_keys**](SecretsApi.md#totp_list_keys) | **GET** /{totp_mount_path}/keys | Manage the keys that can be created with this backend. |
| [**totp_read_key**](SecretsApi.md#totp_read_key) | **GET** /{totp_mount_path}/keys/{name} |  |
| [**totp_validate_code**](SecretsApi.md#totp_validate_code) | **POST** /{totp_mount_path}/code/{name} |  |
| [**transit_back_up_key**](SecretsApi.md#transit_back_up_key) | **GET** /{transit_mount_path}/backup/{name} | Backup the named key |
| [**transit_byok_key**](SecretsApi.md#transit_byok_key) | **GET** /{transit_mount_path}/byok-export/{destination}/{source} | Securely export named encryption or signing key |
| [**transit_byok_key_version**](SecretsApi.md#transit_byok_key_version) | **GET** /{transit_mount_path}/byok-export/{destination}/{source}/{version} | Securely export named encryption or signing key |
| [**transit_configure_cache**](SecretsApi.md#transit_configure_cache) | **POST** /{transit_mount_path}/cache-config | Configures a new cache of the specified size |
| [**transit_configure_key**](SecretsApi.md#transit_configure_key) | **POST** /{transit_mount_path}/keys/{name}/config | Configure a named encryption key |
| [**transit_configure_keys**](SecretsApi.md#transit_configure_keys) | **POST** /{transit_mount_path}/config/keys |  |
| [**transit_create_key**](SecretsApi.md#transit_create_key) | **POST** /{transit_mount_path}/keys/{name} |  |
| [**transit_decrypt**](SecretsApi.md#transit_decrypt) | **POST** /{transit_mount_path}/decrypt/{name} | Decrypt a ciphertext value using a named key |
| [**transit_delete_key**](SecretsApi.md#transit_delete_key) | **DELETE** /{transit_mount_path}/keys/{name} |  |
| [**transit_encrypt**](SecretsApi.md#transit_encrypt) | **POST** /{transit_mount_path}/encrypt/{name} | Encrypt a plaintext value or a batch of plaintext blocks using a named key |
| [**transit_export_key**](SecretsApi.md#transit_export_key) | **GET** /{transit_mount_path}/export/{type}/{name} | Export named encryption or signing key |
| [**transit_export_key_version**](SecretsApi.md#transit_export_key_version) | **GET** /{transit_mount_path}/export/{type}/{name}/{version} | Export named encryption or signing key |
| [**transit_generate_data_key**](SecretsApi.md#transit_generate_data_key) | **POST** /{transit_mount_path}/datakey/{plaintext}/{name} | Generate a data key |
| [**transit_generate_hmac**](SecretsApi.md#transit_generate_hmac) | **POST** /{transit_mount_path}/hmac/{name} | Generate an HMAC for input data using the named key |
| [**transit_generate_hmac_with_algorithm**](SecretsApi.md#transit_generate_hmac_with_algorithm) | **POST** /{transit_mount_path}/hmac/{name}/{urlalgorithm} | Generate an HMAC for input data using the named key |
| [**transit_generate_random**](SecretsApi.md#transit_generate_random) | **POST** /{transit_mount_path}/random | Generate random bytes |
| [**transit_generate_random_with_bytes**](SecretsApi.md#transit_generate_random_with_bytes) | **POST** /{transit_mount_path}/random/{urlbytes} | Generate random bytes |
| [**transit_generate_random_with_source**](SecretsApi.md#transit_generate_random_with_source) | **POST** /{transit_mount_path}/random/{source} | Generate random bytes |
| [**transit_generate_random_with_source_and_bytes**](SecretsApi.md#transit_generate_random_with_source_and_bytes) | **POST** /{transit_mount_path}/random/{source}/{urlbytes} | Generate random bytes |
| [**transit_hash**](SecretsApi.md#transit_hash) | **POST** /{transit_mount_path}/hash | Generate a hash sum for input data |
| [**transit_hash_with_algorithm**](SecretsApi.md#transit_hash_with_algorithm) | **POST** /{transit_mount_path}/hash/{urlalgorithm} | Generate a hash sum for input data |
| [**transit_import_key**](SecretsApi.md#transit_import_key) | **POST** /{transit_mount_path}/keys/{name}/import | Imports an externally-generated key into a new transit key |
| [**transit_import_key_version**](SecretsApi.md#transit_import_key_version) | **POST** /{transit_mount_path}/keys/{name}/import_version | Imports an externally-generated key into an existing imported key |
| [**transit_list_keys**](SecretsApi.md#transit_list_keys) | **GET** /{transit_mount_path}/keys | Managed named encryption keys |
| [**transit_read_cache_configuration**](SecretsApi.md#transit_read_cache_configuration) | **GET** /{transit_mount_path}/cache-config | Returns the size of the active cache |
| [**transit_read_key**](SecretsApi.md#transit_read_key) | **GET** /{transit_mount_path}/keys/{name} |  |
| [**transit_read_keys_configuration**](SecretsApi.md#transit_read_keys_configuration) | **GET** /{transit_mount_path}/config/keys |  |
| [**transit_read_wrapping_key**](SecretsApi.md#transit_read_wrapping_key) | **GET** /{transit_mount_path}/wrapping_key | Returns the public key to use for wrapping imported keys |
| [**transit_restore_and_rename_key**](SecretsApi.md#transit_restore_and_rename_key) | **POST** /{transit_mount_path}/restore/{name} | Restore the named key |
| [**transit_restore_key**](SecretsApi.md#transit_restore_key) | **POST** /{transit_mount_path}/restore | Restore the named key |
| [**transit_rewrap**](SecretsApi.md#transit_rewrap) | **POST** /{transit_mount_path}/rewrap/{name} | Rewrap ciphertext |
| [**transit_rotate_key**](SecretsApi.md#transit_rotate_key) | **POST** /{transit_mount_path}/keys/{name}/rotate | Rotate named encryption key |
| [**transit_sign**](SecretsApi.md#transit_sign) | **POST** /{transit_mount_path}/sign/{name} | Generate a signature for input data using the named key |
| [**transit_sign_with_algorithm**](SecretsApi.md#transit_sign_with_algorithm) | **POST** /{transit_mount_path}/sign/{name}/{urlalgorithm} | Generate a signature for input data using the named key |
| [**transit_soft_delete_key**](SecretsApi.md#transit_soft_delete_key) | **DELETE** /{transit_mount_path}/keys/{name}/soft-delete |  |
| [**transit_soft_delete_restore_key**](SecretsApi.md#transit_soft_delete_restore_key) | **POST** /{transit_mount_path}/keys/{name}/soft-delete-restore |  |
| [**transit_trim_key**](SecretsApi.md#transit_trim_key) | **POST** /{transit_mount_path}/keys/{name}/trim | Trim key versions of a named key |
| [**transit_verify**](SecretsApi.md#transit_verify) | **POST** /{transit_mount_path}/verify/{name} | Verify a signature or HMAC for input data created using the named key |
| [**transit_verify_with_algorithm**](SecretsApi.md#transit_verify_with_algorithm) | **POST** /{transit_mount_path}/verify/{name}/{urlalgorithm} | Verify a signature or HMAC for input data created using the named key |


## cubbyhole_delete

> cubbyhole_delete(path)

Deletes the secret at the specified location.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Specifies the path of the secret.

begin
  # Deletes the secret at the specified location.
  api_instance.cubbyhole_delete(path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->cubbyhole_delete: #{e}"
end
```

#### Using the cubbyhole_delete_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cubbyhole_delete_with_http_info(path)

```ruby
begin
  # Deletes the secret at the specified location.
  data, status_code, headers = api_instance.cubbyhole_delete_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->cubbyhole_delete_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Specifies the path of the secret. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cubbyhole_read

> cubbyhole_read(path, opts)

Retrieve the secret at the specified location.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Specifies the path of the secret.
opts = {
  list: 'list_example' # String | Return a list if `true`
}

begin
  # Retrieve the secret at the specified location.
  api_instance.cubbyhole_read(path, opts)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->cubbyhole_read: #{e}"
end
```

#### Using the cubbyhole_read_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cubbyhole_read_with_http_info(path, opts)

```ruby
begin
  # Retrieve the secret at the specified location.
  data, status_code, headers = api_instance.cubbyhole_read_with_http_info(path, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->cubbyhole_read_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Specifies the path of the secret. |  |
| **list** | **String** | Return a list if &#x60;true&#x60; | [optional] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cubbyhole_write

> cubbyhole_write(path)

Store a secret at the specified location.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Specifies the path of the secret.

begin
  # Store a secret at the specified location.
  api_instance.cubbyhole_write(path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->cubbyhole_write: #{e}"
end
```

#### Using the cubbyhole_write_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cubbyhole_write_with_http_info(path)

```ruby
begin
  # Store a secret at the specified location.
  data, status_code, headers = api_instance.cubbyhole_write_with_http_info(path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->cubbyhole_write_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Specifies the path of the secret. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_configure_connection

> database_configure_connection(name, database_mount_path, database_configure_connection_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of this database connection
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at
database_configure_connection_request = OpenbaoClient::DatabaseConfigureConnectionRequest.new # DatabaseConfigureConnectionRequest | 

begin
  
  api_instance.database_configure_connection(name, database_mount_path, database_configure_connection_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_configure_connection: #{e}"
end
```

#### Using the database_configure_connection_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_configure_connection_with_http_info(name, database_mount_path, database_configure_connection_request)

```ruby
begin
  
  data, status_code, headers = api_instance.database_configure_connection_with_http_info(name, database_mount_path, database_configure_connection_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_configure_connection_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of this database connection |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |
| **database_configure_connection_request** | [**DatabaseConfigureConnectionRequest**](DatabaseConfigureConnectionRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## database_delete_connection_configuration

> database_delete_connection_configuration(name, database_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of this database connection
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.database_delete_connection_configuration(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_delete_connection_configuration: #{e}"
end
```

#### Using the database_delete_connection_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_delete_connection_configuration_with_http_info(name, database_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.database_delete_connection_configuration_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_delete_connection_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of this database connection |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_delete_role

> database_delete_role(name, database_mount_path)

Manage the roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage the roles that can be created with this backend.
  api_instance.database_delete_role(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_delete_role: #{e}"
end
```

#### Using the database_delete_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_delete_role_with_http_info(name, database_mount_path)

```ruby
begin
  # Manage the roles that can be created with this backend.
  data, status_code, headers = api_instance.database_delete_role_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_delete_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_delete_static_role

> database_delete_static_role(name, database_mount_path)

Manage the static roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage the static roles that can be created with this backend.
  api_instance.database_delete_static_role(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_delete_static_role: #{e}"
end
```

#### Using the database_delete_static_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_delete_static_role_with_http_info(name, database_mount_path)

```ruby
begin
  # Manage the static roles that can be created with this backend.
  data, status_code, headers = api_instance.database_delete_static_role_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_delete_static_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_generate_credentials

> database_generate_credentials(name, database_mount_path)

Request database credentials for a certain role.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  # Request database credentials for a certain role.
  api_instance.database_generate_credentials(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_generate_credentials: #{e}"
end
```

#### Using the database_generate_credentials_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_generate_credentials_with_http_info(name, database_mount_path)

```ruby
begin
  # Request database credentials for a certain role.
  data, status_code, headers = api_instance.database_generate_credentials_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_generate_credentials_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_list_connections

> database_list_connections(database_mount_path, list)

Configure connection details to a database plugin.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Configure connection details to a database plugin.
  api_instance.database_list_connections(database_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_list_connections: #{e}"
end
```

#### Using the database_list_connections_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_list_connections_with_http_info(database_mount_path, list)

```ruby
begin
  # Configure connection details to a database plugin.
  data, status_code, headers = api_instance.database_list_connections_with_http_info(database_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_list_connections_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_list_roles

> database_list_roles(database_mount_path, list)

Manage the roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Manage the roles that can be created with this backend.
  api_instance.database_list_roles(database_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_list_roles: #{e}"
end
```

#### Using the database_list_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_list_roles_with_http_info(database_mount_path, list)

```ruby
begin
  # Manage the roles that can be created with this backend.
  data, status_code, headers = api_instance.database_list_roles_with_http_info(database_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_list_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_list_static_roles

> database_list_static_roles(database_mount_path, list)

Manage the static roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Manage the static roles that can be created with this backend.
  api_instance.database_list_static_roles(database_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_list_static_roles: #{e}"
end
```

#### Using the database_list_static_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_list_static_roles_with_http_info(database_mount_path, list)

```ruby
begin
  # Manage the static roles that can be created with this backend.
  data, status_code, headers = api_instance.database_list_static_roles_with_http_info(database_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_list_static_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_read_connection_configuration

> database_read_connection_configuration(name, database_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of this database connection
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.database_read_connection_configuration(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_read_connection_configuration: #{e}"
end
```

#### Using the database_read_connection_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_read_connection_configuration_with_http_info(name, database_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.database_read_connection_configuration_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_read_connection_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of this database connection |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_read_role

> database_read_role(name, database_mount_path)

Manage the roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage the roles that can be created with this backend.
  api_instance.database_read_role(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_read_role: #{e}"
end
```

#### Using the database_read_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_read_role_with_http_info(name, database_mount_path)

```ruby
begin
  # Manage the roles that can be created with this backend.
  data, status_code, headers = api_instance.database_read_role_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_read_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_read_static_role

> database_read_static_role(name, database_mount_path)

Manage the static roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage the static roles that can be created with this backend.
  api_instance.database_read_static_role(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_read_static_role: #{e}"
end
```

#### Using the database_read_static_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_read_static_role_with_http_info(name, database_mount_path)

```ruby
begin
  # Manage the static roles that can be created with this backend.
  data, status_code, headers = api_instance.database_read_static_role_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_read_static_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_read_static_role_credentials

> database_read_static_role_credentials(name, database_mount_path)

Request database credentials for a certain static role. These credentials are rotated periodically.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the static role.
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  # Request database credentials for a certain static role. These credentials are rotated periodically.
  api_instance.database_read_static_role_credentials(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_read_static_role_credentials: #{e}"
end
```

#### Using the database_read_static_role_credentials_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_read_static_role_credentials_with_http_info(name, database_mount_path)

```ruby
begin
  # Request database credentials for a certain static role. These credentials are rotated periodically.
  data, status_code, headers = api_instance.database_read_static_role_credentials_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_read_static_role_credentials_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the static role. |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_reset_connection

> database_reset_connection(name, database_mount_path)

Resets a database plugin.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of this database connection
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  # Resets a database plugin.
  api_instance.database_reset_connection(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_reset_connection: #{e}"
end
```

#### Using the database_reset_connection_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_reset_connection_with_http_info(name, database_mount_path)

```ruby
begin
  # Resets a database plugin.
  data, status_code, headers = api_instance.database_reset_connection_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_reset_connection_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of this database connection |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_rotate_root_credentials

> database_rotate_root_credentials(name, database_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of this database connection
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.database_rotate_root_credentials(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_rotate_root_credentials: #{e}"
end
```

#### Using the database_rotate_root_credentials_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_rotate_root_credentials_with_http_info(name, database_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.database_rotate_root_credentials_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_rotate_root_credentials_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of this database connection |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_rotate_static_role_credentials

> database_rotate_static_role_credentials(name, database_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the static role
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.database_rotate_static_role_credentials(name, database_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_rotate_static_role_credentials: #{e}"
end
```

#### Using the database_rotate_static_role_credentials_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_rotate_static_role_credentials_with_http_info(name, database_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.database_rotate_static_role_credentials_with_http_info(name, database_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_rotate_static_role_credentials_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the static role |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## database_write_role

> database_write_role(name, database_mount_path, database_write_role_request)

Manage the roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at
database_write_role_request = OpenbaoClient::DatabaseWriteRoleRequest.new # DatabaseWriteRoleRequest | 

begin
  # Manage the roles that can be created with this backend.
  api_instance.database_write_role(name, database_mount_path, database_write_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_write_role: #{e}"
end
```

#### Using the database_write_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_write_role_with_http_info(name, database_mount_path, database_write_role_request)

```ruby
begin
  # Manage the roles that can be created with this backend.
  data, status_code, headers = api_instance.database_write_role_with_http_info(name, database_mount_path, database_write_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_write_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |
| **database_write_role_request** | [**DatabaseWriteRoleRequest**](DatabaseWriteRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## database_write_static_role

> database_write_static_role(name, database_mount_path, database_write_static_role_request)

Manage the static roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
database_mount_path = 'database_mount_path_example' # String | Path that the backend was mounted at
database_write_static_role_request = OpenbaoClient::DatabaseWriteStaticRoleRequest.new # DatabaseWriteStaticRoleRequest | 

begin
  # Manage the static roles that can be created with this backend.
  api_instance.database_write_static_role(name, database_mount_path, database_write_static_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_write_static_role: #{e}"
end
```

#### Using the database_write_static_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> database_write_static_role_with_http_info(name, database_mount_path, database_write_static_role_request)

```ruby
begin
  # Manage the static roles that can be created with this backend.
  data, status_code, headers = api_instance.database_write_static_role_with_http_info(name, database_mount_path, database_write_static_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->database_write_static_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **database_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;database&#39;] |
| **database_write_static_role_request** | [**DatabaseWriteStaticRoleRequest**](DatabaseWriteStaticRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kubernetes_check_configuration

> kubernetes_check_configuration(kubernetes_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kubernetes_check_configuration(kubernetes_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_check_configuration: #{e}"
end
```

#### Using the kubernetes_check_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_check_configuration_with_http_info(kubernetes_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_check_configuration_with_http_info(kubernetes_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_check_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kubernetes_configure

> kubernetes_configure(kubernetes_mount_path, kubernetes_configure_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at
kubernetes_configure_request = OpenbaoClient::KubernetesConfigureRequest.new # KubernetesConfigureRequest | 

begin
  
  api_instance.kubernetes_configure(kubernetes_mount_path, kubernetes_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_configure: #{e}"
end
```

#### Using the kubernetes_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_configure_with_http_info(kubernetes_mount_path, kubernetes_configure_request)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_configure_with_http_info(kubernetes_mount_path, kubernetes_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |
| **kubernetes_configure_request** | [**KubernetesConfigureRequest**](KubernetesConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kubernetes_delete_configuration

> kubernetes_delete_configuration(kubernetes_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kubernetes_delete_configuration(kubernetes_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_delete_configuration: #{e}"
end
```

#### Using the kubernetes_delete_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_delete_configuration_with_http_info(kubernetes_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_delete_configuration_with_http_info(kubernetes_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_delete_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kubernetes_delete_role

> kubernetes_delete_role(name, kubernetes_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kubernetes_delete_role(name, kubernetes_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_delete_role: #{e}"
end
```

#### Using the kubernetes_delete_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_delete_role_with_http_info(name, kubernetes_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_delete_role_with_http_info(name, kubernetes_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_delete_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kubernetes_generate_credentials

> kubernetes_generate_credentials(name, kubernetes_mount_path, kubernetes_generate_credentials_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the OpenBao role
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at
kubernetes_generate_credentials_request = OpenbaoClient::KubernetesGenerateCredentialsRequest.new({kubernetes_namespace: 'kubernetes_namespace_example'}) # KubernetesGenerateCredentialsRequest | 

begin
  
  api_instance.kubernetes_generate_credentials(name, kubernetes_mount_path, kubernetes_generate_credentials_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_generate_credentials: #{e}"
end
```

#### Using the kubernetes_generate_credentials_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_generate_credentials_with_http_info(name, kubernetes_mount_path, kubernetes_generate_credentials_request)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_generate_credentials_with_http_info(name, kubernetes_mount_path, kubernetes_generate_credentials_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_generate_credentials_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the OpenBao role |  |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |
| **kubernetes_generate_credentials_request** | [**KubernetesGenerateCredentialsRequest**](KubernetesGenerateCredentialsRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kubernetes_list_roles

> kubernetes_list_roles(kubernetes_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.kubernetes_list_roles(kubernetes_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_list_roles: #{e}"
end
```

#### Using the kubernetes_list_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_list_roles_with_http_info(kubernetes_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_list_roles_with_http_info(kubernetes_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_list_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kubernetes_read_configuration

> kubernetes_read_configuration(kubernetes_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kubernetes_read_configuration(kubernetes_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_read_configuration: #{e}"
end
```

#### Using the kubernetes_read_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_read_configuration_with_http_info(kubernetes_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_read_configuration_with_http_info(kubernetes_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_read_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kubernetes_read_role

> kubernetes_read_role(name, kubernetes_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kubernetes_read_role(name, kubernetes_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_read_role: #{e}"
end
```

#### Using the kubernetes_read_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_read_role_with_http_info(name, kubernetes_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_read_role_with_http_info(name, kubernetes_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_read_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kubernetes_write_role

> kubernetes_write_role(name, kubernetes_mount_path, kubernetes_write_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at
kubernetes_write_role_request = OpenbaoClient::KubernetesWriteRoleRequest.new # KubernetesWriteRoleRequest | 

begin
  
  api_instance.kubernetes_write_role(name, kubernetes_mount_path, kubernetes_write_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_write_role: #{e}"
end
```

#### Using the kubernetes_write_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_write_role_with_http_info(name, kubernetes_mount_path, kubernetes_write_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_write_role_with_http_info(name, kubernetes_mount_path, kubernetes_write_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kubernetes_write_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |
| **kubernetes_write_role_request** | [**KubernetesWriteRoleRequest**](KubernetesWriteRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kv_delete_data_path

> kv_delete_data_path(path, kv_v2_mount_path)

Write, Patch, Read, and Delete data in the Key-Value Store.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at

begin
  # Write, Patch, Read, and Delete data in the Key-Value Store.
  api_instance.kv_delete_data_path(path, kv_v2_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_delete_data_path: #{e}"
end
```

#### Using the kv_delete_data_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_delete_data_path_with_http_info(path, kv_v2_mount_path)

```ruby
begin
  # Write, Patch, Read, and Delete data in the Key-Value Store.
  data, status_code, headers = api_instance.kv_delete_data_path_with_http_info(path, kv_v2_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_delete_data_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kv_delete_metadata_path

> kv_delete_metadata_path(path, kv_v2_mount_path)

Configures settings for the KV store

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at

begin
  # Configures settings for the KV store
  api_instance.kv_delete_metadata_path(path, kv_v2_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_delete_metadata_path: #{e}"
end
```

#### Using the kv_delete_metadata_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_delete_metadata_path_with_http_info(path, kv_v2_mount_path)

```ruby
begin
  # Configures settings for the KV store
  data, status_code, headers = api_instance.kv_delete_metadata_path_with_http_info(path, kv_v2_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_delete_metadata_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kv_delete_path

> kv_delete_path(path, kv_v1_mount_path)

Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v1_mount_path = 'kv_v1_mount_path_example' # String | Path that the backend was mounted at

begin
  # Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage.
  api_instance.kv_delete_path(path, kv_v1_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_delete_path: #{e}"
end
```

#### Using the kv_delete_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_delete_path_with_http_info(path, kv_v1_mount_path)

```ruby
begin
  # Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage.
  data, status_code, headers = api_instance.kv_delete_path_with_http_info(path, kv_v1_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_delete_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v1_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v1&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kv_read_config

> kv_read_config(kv_v2_mount_path)

Read the backend level settings.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at

begin
  # Read the backend level settings.
  api_instance.kv_read_config(kv_v2_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_read_config: #{e}"
end
```

#### Using the kv_read_config_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_read_config_with_http_info(kv_v2_mount_path)

```ruby
begin
  # Read the backend level settings.
  data, status_code, headers = api_instance.kv_read_config_with_http_info(kv_v2_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_read_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kv_read_data_path

> kv_read_data_path(path, kv_v2_mount_path)

Write, Patch, Read, and Delete data in the Key-Value Store.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at

begin
  # Write, Patch, Read, and Delete data in the Key-Value Store.
  api_instance.kv_read_data_path(path, kv_v2_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_read_data_path: #{e}"
end
```

#### Using the kv_read_data_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_read_data_path_with_http_info(path, kv_v2_mount_path)

```ruby
begin
  # Write, Patch, Read, and Delete data in the Key-Value Store.
  data, status_code, headers = api_instance.kv_read_data_path_with_http_info(path, kv_v2_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_read_data_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kv_read_metadata_path

> kv_read_metadata_path(path, kv_v2_mount_path, opts)

Configures settings for the KV store

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at
opts = {
  list: 'list_example' # String | Return a list if `true`
}

begin
  # Configures settings for the KV store
  api_instance.kv_read_metadata_path(path, kv_v2_mount_path, opts)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_read_metadata_path: #{e}"
end
```

#### Using the kv_read_metadata_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_read_metadata_path_with_http_info(path, kv_v2_mount_path, opts)

```ruby
begin
  # Configures settings for the KV store
  data, status_code, headers = api_instance.kv_read_metadata_path_with_http_info(path, kv_v2_mount_path, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_read_metadata_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |
| **list** | **String** | Return a list if &#x60;true&#x60; | [optional] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kv_read_path

> kv_read_path(path, kv_v1_mount_path, opts)

Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v1_mount_path = 'kv_v1_mount_path_example' # String | Path that the backend was mounted at
opts = {
  list: 'list_example' # String | Return a list if `true`
}

begin
  # Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage.
  api_instance.kv_read_path(path, kv_v1_mount_path, opts)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_read_path: #{e}"
end
```

#### Using the kv_read_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_read_path_with_http_info(path, kv_v1_mount_path, opts)

```ruby
begin
  # Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage.
  data, status_code, headers = api_instance.kv_read_path_with_http_info(path, kv_v1_mount_path, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_read_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v1_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v1&#39;] |
| **list** | **String** | Return a list if &#x60;true&#x60; | [optional] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kv_read_subkeys_path

> kv_read_subkeys_path(path, kv_v2_mount_path)

Read the structure of a secret entry from the Key-Value store with the values removed.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at

begin
  # Read the structure of a secret entry from the Key-Value store with the values removed.
  api_instance.kv_read_subkeys_path(path, kv_v2_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_read_subkeys_path: #{e}"
end
```

#### Using the kv_read_subkeys_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_read_subkeys_path_with_http_info(path, kv_v2_mount_path)

```ruby
begin
  # Read the structure of a secret entry from the Key-Value store with the values removed.
  data, status_code, headers = api_instance.kv_read_subkeys_path_with_http_info(path, kv_v2_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_read_subkeys_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kv_write_config

> kv_write_config(kv_v2_mount_path, kv_write_config_request)

Configure backend level settings that are applied to every key in the key-value store.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at
kv_write_config_request = OpenbaoClient::KvWriteConfigRequest.new # KvWriteConfigRequest | 

begin
  # Configure backend level settings that are applied to every key in the key-value store.
  api_instance.kv_write_config(kv_v2_mount_path, kv_write_config_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_config: #{e}"
end
```

#### Using the kv_write_config_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_write_config_with_http_info(kv_v2_mount_path, kv_write_config_request)

```ruby
begin
  # Configure backend level settings that are applied to every key in the key-value store.
  data, status_code, headers = api_instance.kv_write_config_with_http_info(kv_v2_mount_path, kv_write_config_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_config_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |
| **kv_write_config_request** | [**KvWriteConfigRequest**](KvWriteConfigRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kv_write_data_path

> kv_write_data_path(path, kv_v2_mount_path, kv_write_data_path_request)

Write, Patch, Read, and Delete data in the Key-Value Store.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at
kv_write_data_path_request = OpenbaoClient::KvWriteDataPathRequest.new # KvWriteDataPathRequest | 

begin
  # Write, Patch, Read, and Delete data in the Key-Value Store.
  api_instance.kv_write_data_path(path, kv_v2_mount_path, kv_write_data_path_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_data_path: #{e}"
end
```

#### Using the kv_write_data_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_write_data_path_with_http_info(path, kv_v2_mount_path, kv_write_data_path_request)

```ruby
begin
  # Write, Patch, Read, and Delete data in the Key-Value Store.
  data, status_code, headers = api_instance.kv_write_data_path_with_http_info(path, kv_v2_mount_path, kv_write_data_path_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_data_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |
| **kv_write_data_path_request** | [**KvWriteDataPathRequest**](KvWriteDataPathRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kv_write_delete_path

> kv_write_delete_path(path, kv_v2_mount_path, kv_write_delete_path_request)

Marks one or more versions as deleted in the KV store.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at
kv_write_delete_path_request = OpenbaoClient::KvWriteDeletePathRequest.new # KvWriteDeletePathRequest | 

begin
  # Marks one or more versions as deleted in the KV store.
  api_instance.kv_write_delete_path(path, kv_v2_mount_path, kv_write_delete_path_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_delete_path: #{e}"
end
```

#### Using the kv_write_delete_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_write_delete_path_with_http_info(path, kv_v2_mount_path, kv_write_delete_path_request)

```ruby
begin
  # Marks one or more versions as deleted in the KV store.
  data, status_code, headers = api_instance.kv_write_delete_path_with_http_info(path, kv_v2_mount_path, kv_write_delete_path_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_delete_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |
| **kv_write_delete_path_request** | [**KvWriteDeletePathRequest**](KvWriteDeletePathRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kv_write_destroy_path

> kv_write_destroy_path(path, kv_v2_mount_path, kv_write_destroy_path_request)

Permanently removes one or more versions in the KV store

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at
kv_write_destroy_path_request = OpenbaoClient::KvWriteDestroyPathRequest.new # KvWriteDestroyPathRequest | 

begin
  # Permanently removes one or more versions in the KV store
  api_instance.kv_write_destroy_path(path, kv_v2_mount_path, kv_write_destroy_path_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_destroy_path: #{e}"
end
```

#### Using the kv_write_destroy_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_write_destroy_path_with_http_info(path, kv_v2_mount_path, kv_write_destroy_path_request)

```ruby
begin
  # Permanently removes one or more versions in the KV store
  data, status_code, headers = api_instance.kv_write_destroy_path_with_http_info(path, kv_v2_mount_path, kv_write_destroy_path_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_destroy_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |
| **kv_write_destroy_path_request** | [**KvWriteDestroyPathRequest**](KvWriteDestroyPathRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kv_write_metadata_path

> kv_write_metadata_path(path, kv_v2_mount_path, kv_write_metadata_path_request)

Configures settings for the KV store

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at
kv_write_metadata_path_request = OpenbaoClient::KvWriteMetadataPathRequest.new # KvWriteMetadataPathRequest | 

begin
  # Configures settings for the KV store
  api_instance.kv_write_metadata_path(path, kv_v2_mount_path, kv_write_metadata_path_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_metadata_path: #{e}"
end
```

#### Using the kv_write_metadata_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_write_metadata_path_with_http_info(path, kv_v2_mount_path, kv_write_metadata_path_request)

```ruby
begin
  # Configures settings for the KV store
  data, status_code, headers = api_instance.kv_write_metadata_path_with_http_info(path, kv_v2_mount_path, kv_write_metadata_path_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_metadata_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |
| **kv_write_metadata_path_request** | [**KvWriteMetadataPathRequest**](KvWriteMetadataPathRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kv_write_path

> kv_write_path(path, kv_v1_mount_path)

Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v1_mount_path = 'kv_v1_mount_path_example' # String | Path that the backend was mounted at

begin
  # Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage.
  api_instance.kv_write_path(path, kv_v1_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_path: #{e}"
end
```

#### Using the kv_write_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_write_path_with_http_info(path, kv_v1_mount_path)

```ruby
begin
  # Pass-through secret storage to the storage backend, allowing you to read/write arbitrary data into secret storage.
  data, status_code, headers = api_instance.kv_write_path_with_http_info(path, kv_v1_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v1_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v1&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kv_write_undelete_path

> kv_write_undelete_path(path, kv_v2_mount_path, kv_write_undelete_path_request)

Undeletes one or more versions from the KV store.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
path = 'path_example' # String | Location of the secret.
kv_v2_mount_path = 'kv_v2_mount_path_example' # String | Path that the backend was mounted at
kv_write_undelete_path_request = OpenbaoClient::KvWriteUndeletePathRequest.new # KvWriteUndeletePathRequest | 

begin
  # Undeletes one or more versions from the KV store.
  api_instance.kv_write_undelete_path(path, kv_v2_mount_path, kv_write_undelete_path_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_undelete_path: #{e}"
end
```

#### Using the kv_write_undelete_path_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kv_write_undelete_path_with_http_info(path, kv_v2_mount_path, kv_write_undelete_path_request)

```ruby
begin
  # Undeletes one or more versions from the KV store.
  data, status_code, headers = api_instance.kv_write_undelete_path_with_http_info(path, kv_v2_mount_path, kv_write_undelete_path_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->kv_write_undelete_path_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **path** | **String** | Location of the secret. |  |
| **kv_v2_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kv-v2&#39;] |
| **kv_write_undelete_path_request** | [**KvWriteUndeletePathRequest**](KvWriteUndeletePathRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_configure

> ldap_configure(ldap_mount_path, ldap_configure_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_configure_request = OpenbaoClient::LdapConfigureRequest.new # LdapConfigureRequest | 

begin
  
  api_instance.ldap_configure(ldap_mount_path, ldap_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_configure: #{e}"
end
```

#### Using the ldap_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_configure_with_http_info(ldap_mount_path, ldap_configure_request)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_configure_with_http_info(ldap_mount_path, ldap_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_configure_request** | [**LdapConfigureRequest**](LdapConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_delete_configuration

> ldap_delete_configuration(ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_delete_configuration(ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_delete_configuration: #{e}"
end
```

#### Using the ldap_delete_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_delete_configuration_with_http_info(ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_delete_configuration_with_http_info(ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_delete_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_delete_dynamic_role

> ldap_delete_dynamic_role(name, ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role (lowercase)
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_delete_dynamic_role(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_delete_dynamic_role: #{e}"
end
```

#### Using the ldap_delete_dynamic_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_delete_dynamic_role_with_http_info(name, ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_delete_dynamic_role_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_delete_dynamic_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role (lowercase) |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_delete_static_role

> ldap_delete_static_role(name, ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_delete_static_role(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_delete_static_role: #{e}"
end
```

#### Using the ldap_delete_static_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_delete_static_role_with_http_info(name, ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_delete_static_role_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_delete_static_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_library_check_in

> ldap_library_check_in(name, ldap_mount_path, ldap_library_check_in_request)

Check service accounts in to the library.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the set.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_library_check_in_request = OpenbaoClient::LdapLibraryCheckInRequest.new # LdapLibraryCheckInRequest | 

begin
  # Check service accounts in to the library.
  api_instance.ldap_library_check_in(name, ldap_mount_path, ldap_library_check_in_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_check_in: #{e}"
end
```

#### Using the ldap_library_check_in_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_library_check_in_with_http_info(name, ldap_mount_path, ldap_library_check_in_request)

```ruby
begin
  # Check service accounts in to the library.
  data, status_code, headers = api_instance.ldap_library_check_in_with_http_info(name, ldap_mount_path, ldap_library_check_in_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_check_in_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the set. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_library_check_in_request** | [**LdapLibraryCheckInRequest**](LdapLibraryCheckInRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_library_check_out

> ldap_library_check_out(name, ldap_mount_path, ldap_library_check_out_request)

Check a service account out from the library.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the set
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_library_check_out_request = OpenbaoClient::LdapLibraryCheckOutRequest.new # LdapLibraryCheckOutRequest | 

begin
  # Check a service account out from the library.
  api_instance.ldap_library_check_out(name, ldap_mount_path, ldap_library_check_out_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_check_out: #{e}"
end
```

#### Using the ldap_library_check_out_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_library_check_out_with_http_info(name, ldap_mount_path, ldap_library_check_out_request)

```ruby
begin
  # Check a service account out from the library.
  data, status_code, headers = api_instance.ldap_library_check_out_with_http_info(name, ldap_mount_path, ldap_library_check_out_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_check_out_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the set |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_library_check_out_request** | [**LdapLibraryCheckOutRequest**](LdapLibraryCheckOutRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_library_check_status

> ldap_library_check_status(name, ldap_mount_path)

Check the status of the service accounts in a library set.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the set.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  # Check the status of the service accounts in a library set.
  api_instance.ldap_library_check_status(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_check_status: #{e}"
end
```

#### Using the ldap_library_check_status_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_library_check_status_with_http_info(name, ldap_mount_path)

```ruby
begin
  # Check the status of the service accounts in a library set.
  data, status_code, headers = api_instance.ldap_library_check_status_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_check_status_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the set. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_library_configure

> ldap_library_configure(name, ldap_mount_path, ldap_library_configure_request)

Update a library set.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the set.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_library_configure_request = OpenbaoClient::LdapLibraryConfigureRequest.new # LdapLibraryConfigureRequest | 

begin
  # Update a library set.
  api_instance.ldap_library_configure(name, ldap_mount_path, ldap_library_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_configure: #{e}"
end
```

#### Using the ldap_library_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_library_configure_with_http_info(name, ldap_mount_path, ldap_library_configure_request)

```ruby
begin
  # Update a library set.
  data, status_code, headers = api_instance.ldap_library_configure_with_http_info(name, ldap_mount_path, ldap_library_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the set. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_library_configure_request** | [**LdapLibraryConfigureRequest**](LdapLibraryConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_library_delete

> ldap_library_delete(name, ldap_mount_path)

Delete a library set.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the set.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  # Delete a library set.
  api_instance.ldap_library_delete(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_delete: #{e}"
end
```

#### Using the ldap_library_delete_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_library_delete_with_http_info(name, ldap_mount_path)

```ruby
begin
  # Delete a library set.
  data, status_code, headers = api_instance.ldap_library_delete_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_delete_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the set. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_library_force_check_in

> ldap_library_force_check_in(name, ldap_mount_path, ldap_library_force_check_in_request)

Check service accounts in to the library.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the set.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_library_force_check_in_request = OpenbaoClient::LdapLibraryForceCheckInRequest.new # LdapLibraryForceCheckInRequest | 

begin
  # Check service accounts in to the library.
  api_instance.ldap_library_force_check_in(name, ldap_mount_path, ldap_library_force_check_in_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_force_check_in: #{e}"
end
```

#### Using the ldap_library_force_check_in_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_library_force_check_in_with_http_info(name, ldap_mount_path, ldap_library_force_check_in_request)

```ruby
begin
  # Check service accounts in to the library.
  data, status_code, headers = api_instance.ldap_library_force_check_in_with_http_info(name, ldap_mount_path, ldap_library_force_check_in_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_force_check_in_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the set. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_library_force_check_in_request** | [**LdapLibraryForceCheckInRequest**](LdapLibraryForceCheckInRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_library_list

> ldap_library_list(ldap_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.ldap_library_list(ldap_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_list: #{e}"
end
```

#### Using the ldap_library_list_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_library_list_with_http_info(ldap_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_library_list_with_http_info(ldap_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_library_read

> ldap_library_read(name, ldap_mount_path)

Read a library set.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the set.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  # Read a library set.
  api_instance.ldap_library_read(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_read: #{e}"
end
```

#### Using the ldap_library_read_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_library_read_with_http_info(name, ldap_mount_path)

```ruby
begin
  # Read a library set.
  data, status_code, headers = api_instance.ldap_library_read_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_library_read_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the set. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_list_dynamic_roles

> ldap_list_dynamic_roles(ldap_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.ldap_list_dynamic_roles(ldap_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_list_dynamic_roles: #{e}"
end
```

#### Using the ldap_list_dynamic_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_list_dynamic_roles_with_http_info(ldap_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_list_dynamic_roles_with_http_info(ldap_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_list_dynamic_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_list_static_roles

> ldap_list_static_roles(ldap_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.ldap_list_static_roles(ldap_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_list_static_roles: #{e}"
end
```

#### Using the ldap_list_static_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_list_static_roles_with_http_info(ldap_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_list_static_roles_with_http_info(ldap_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_list_static_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_read_configuration

> ldap_read_configuration(ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_read_configuration(ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_read_configuration: #{e}"
end
```

#### Using the ldap_read_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_read_configuration_with_http_info(ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_read_configuration_with_http_info(ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_read_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_read_dynamic_role

> ldap_read_dynamic_role(name, ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role (lowercase)
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_read_dynamic_role(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_read_dynamic_role: #{e}"
end
```

#### Using the ldap_read_dynamic_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_read_dynamic_role_with_http_info(name, ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_read_dynamic_role_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_read_dynamic_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role (lowercase) |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_read_static_role

> ldap_read_static_role(name, ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_read_static_role(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_read_static_role: #{e}"
end
```

#### Using the ldap_read_static_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_read_static_role_with_http_info(name, ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_read_static_role_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_read_static_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_request_dynamic_role_credentials

> ldap_request_dynamic_role_credentials(name, ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the dynamic role.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_request_dynamic_role_credentials(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_request_dynamic_role_credentials: #{e}"
end
```

#### Using the ldap_request_dynamic_role_credentials_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_request_dynamic_role_credentials_with_http_info(name, ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_request_dynamic_role_credentials_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_request_dynamic_role_credentials_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the dynamic role. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_request_static_role_credentials

> ldap_request_static_role_credentials(name, ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the static role.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_request_static_role_credentials(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_request_static_role_credentials: #{e}"
end
```

#### Using the ldap_request_static_role_credentials_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_request_static_role_credentials_with_http_info(name, ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_request_static_role_credentials_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_request_static_role_credentials_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the static role. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_rotate_root_credentials

> ldap_rotate_root_credentials(ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_rotate_root_credentials(ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_rotate_root_credentials: #{e}"
end
```

#### Using the ldap_rotate_root_credentials_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_rotate_root_credentials_with_http_info(ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_rotate_root_credentials_with_http_info(ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_rotate_root_credentials_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_rotate_static_role

> ldap_rotate_static_role(name, ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the static role
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_rotate_static_role(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_rotate_static_role: #{e}"
end
```

#### Using the ldap_rotate_static_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_rotate_static_role_with_http_info(name, ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_rotate_static_role_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_rotate_static_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the static role |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_write_dynamic_role

> ldap_write_dynamic_role(name, ldap_mount_path, ldap_write_dynamic_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role (lowercase)
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_write_dynamic_role_request = OpenbaoClient::LdapWriteDynamicRoleRequest.new({creation_ldif: 'creation_ldif_example', deletion_ldif: 'deletion_ldif_example'}) # LdapWriteDynamicRoleRequest | 

begin
  
  api_instance.ldap_write_dynamic_role(name, ldap_mount_path, ldap_write_dynamic_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_write_dynamic_role: #{e}"
end
```

#### Using the ldap_write_dynamic_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_write_dynamic_role_with_http_info(name, ldap_mount_path, ldap_write_dynamic_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_write_dynamic_role_with_http_info(name, ldap_mount_path, ldap_write_dynamic_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_write_dynamic_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role (lowercase) |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_write_dynamic_role_request** | [**LdapWriteDynamicRoleRequest**](LdapWriteDynamicRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_write_static_role

> ldap_write_static_role(name, ldap_mount_path, ldap_write_static_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_write_static_role_request = OpenbaoClient::LdapWriteStaticRoleRequest.new # LdapWriteStaticRoleRequest | 

begin
  
  api_instance.ldap_write_static_role(name, ldap_mount_path, ldap_write_static_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_write_static_role: #{e}"
end
```

#### Using the ldap_write_static_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_write_static_role_with_http_info(name, ldap_mount_path, ldap_write_static_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_write_static_role_with_http_info(name, ldap_mount_path, ldap_write_static_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ldap_write_static_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_write_static_role_request** | [**LdapWriteStaticRoleRequest**](LdapWriteStaticRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_configure_acme

> pki_configure_acme(pki_mount_path, pki_configure_acme_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_configure_acme_request = OpenbaoClient::PkiConfigureAcmeRequest.new # PkiConfigureAcmeRequest | 

begin
  
  api_instance.pki_configure_acme(pki_mount_path, pki_configure_acme_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_acme: #{e}"
end
```

#### Using the pki_configure_acme_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_configure_acme_with_http_info(pki_mount_path, pki_configure_acme_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_configure_acme_with_http_info(pki_mount_path, pki_configure_acme_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_acme_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_configure_acme_request** | [**PkiConfigureAcmeRequest**](PkiConfigureAcmeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_configure_auto_tidy

> <PkiConfigureAutoTidyResponse> pki_configure_auto_tidy(pki_mount_path, pki_configure_auto_tidy_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_configure_auto_tidy_request = OpenbaoClient::PkiConfigureAutoTidyRequest.new # PkiConfigureAutoTidyRequest | 

begin
  
  result = api_instance.pki_configure_auto_tidy(pki_mount_path, pki_configure_auto_tidy_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_auto_tidy: #{e}"
end
```

#### Using the pki_configure_auto_tidy_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiConfigureAutoTidyResponse>, Integer, Hash)> pki_configure_auto_tidy_with_http_info(pki_mount_path, pki_configure_auto_tidy_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_configure_auto_tidy_with_http_info(pki_mount_path, pki_configure_auto_tidy_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiConfigureAutoTidyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_auto_tidy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_configure_auto_tidy_request** | [**PkiConfigureAutoTidyRequest**](PkiConfigureAutoTidyRequest.md) |  |  |

### Return type

[**PkiConfigureAutoTidyResponse**](PkiConfigureAutoTidyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_configure_ca

> <PkiConfigureCaResponse> pki_configure_ca(pki_mount_path, pki_configure_ca_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_configure_ca_request = OpenbaoClient::PkiConfigureCaRequest.new # PkiConfigureCaRequest | 

begin
  
  result = api_instance.pki_configure_ca(pki_mount_path, pki_configure_ca_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_ca: #{e}"
end
```

#### Using the pki_configure_ca_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiConfigureCaResponse>, Integer, Hash)> pki_configure_ca_with_http_info(pki_mount_path, pki_configure_ca_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_configure_ca_with_http_info(pki_mount_path, pki_configure_ca_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiConfigureCaResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_ca_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_configure_ca_request** | [**PkiConfigureCaRequest**](PkiConfigureCaRequest.md) |  |  |

### Return type

[**PkiConfigureCaResponse**](PkiConfigureCaResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_configure_cluster

> <PkiConfigureClusterResponse> pki_configure_cluster(pki_mount_path, pki_configure_cluster_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_configure_cluster_request = OpenbaoClient::PkiConfigureClusterRequest.new # PkiConfigureClusterRequest | 

begin
  
  result = api_instance.pki_configure_cluster(pki_mount_path, pki_configure_cluster_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_cluster: #{e}"
end
```

#### Using the pki_configure_cluster_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiConfigureClusterResponse>, Integer, Hash)> pki_configure_cluster_with_http_info(pki_mount_path, pki_configure_cluster_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_configure_cluster_with_http_info(pki_mount_path, pki_configure_cluster_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiConfigureClusterResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_cluster_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_configure_cluster_request** | [**PkiConfigureClusterRequest**](PkiConfigureClusterRequest.md) |  |  |

### Return type

[**PkiConfigureClusterResponse**](PkiConfigureClusterResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_configure_crl

> <PkiConfigureCrlResponse> pki_configure_crl(pki_mount_path, pki_configure_crl_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_configure_crl_request = OpenbaoClient::PkiConfigureCrlRequest.new # PkiConfigureCrlRequest | 

begin
  
  result = api_instance.pki_configure_crl(pki_mount_path, pki_configure_crl_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_crl: #{e}"
end
```

#### Using the pki_configure_crl_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiConfigureCrlResponse>, Integer, Hash)> pki_configure_crl_with_http_info(pki_mount_path, pki_configure_crl_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_configure_crl_with_http_info(pki_mount_path, pki_configure_crl_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiConfigureCrlResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_crl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_configure_crl_request** | [**PkiConfigureCrlRequest**](PkiConfigureCrlRequest.md) |  |  |

### Return type

[**PkiConfigureCrlResponse**](PkiConfigureCrlResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_configure_issuers

> <PkiConfigureIssuersResponse> pki_configure_issuers(pki_mount_path, pki_configure_issuers_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_configure_issuers_request = OpenbaoClient::PkiConfigureIssuersRequest.new # PkiConfigureIssuersRequest | 

begin
  
  result = api_instance.pki_configure_issuers(pki_mount_path, pki_configure_issuers_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_issuers: #{e}"
end
```

#### Using the pki_configure_issuers_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiConfigureIssuersResponse>, Integer, Hash)> pki_configure_issuers_with_http_info(pki_mount_path, pki_configure_issuers_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_configure_issuers_with_http_info(pki_mount_path, pki_configure_issuers_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiConfigureIssuersResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_issuers_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_configure_issuers_request** | [**PkiConfigureIssuersRequest**](PkiConfigureIssuersRequest.md) |  |  |

### Return type

[**PkiConfigureIssuersResponse**](PkiConfigureIssuersResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_configure_keys

> <PkiConfigureKeysResponse> pki_configure_keys(pki_mount_path, pki_configure_keys_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_configure_keys_request = OpenbaoClient::PkiConfigureKeysRequest.new # PkiConfigureKeysRequest | 

begin
  
  result = api_instance.pki_configure_keys(pki_mount_path, pki_configure_keys_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_keys: #{e}"
end
```

#### Using the pki_configure_keys_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiConfigureKeysResponse>, Integer, Hash)> pki_configure_keys_with_http_info(pki_mount_path, pki_configure_keys_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_configure_keys_with_http_info(pki_mount_path, pki_configure_keys_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiConfigureKeysResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_keys_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_configure_keys_request** | [**PkiConfigureKeysRequest**](PkiConfigureKeysRequest.md) |  |  |

### Return type

[**PkiConfigureKeysResponse**](PkiConfigureKeysResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_configure_urls

> <PkiConfigureUrlsResponse> pki_configure_urls(pki_mount_path, pki_configure_urls_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_configure_urls_request = OpenbaoClient::PkiConfigureUrlsRequest.new # PkiConfigureUrlsRequest | 

begin
  
  result = api_instance.pki_configure_urls(pki_mount_path, pki_configure_urls_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_urls: #{e}"
end
```

#### Using the pki_configure_urls_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiConfigureUrlsResponse>, Integer, Hash)> pki_configure_urls_with_http_info(pki_mount_path, pki_configure_urls_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_configure_urls_with_http_info(pki_mount_path, pki_configure_urls_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiConfigureUrlsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_configure_urls_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_configure_urls_request** | [**PkiConfigureUrlsRequest**](PkiConfigureUrlsRequest.md) |  |  |

### Return type

[**PkiConfigureUrlsResponse**](PkiConfigureUrlsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_cross_sign_intermediate

> <PkiCrossSignIntermediateResponse> pki_cross_sign_intermediate(pki_mount_path, pki_cross_sign_intermediate_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_cross_sign_intermediate_request = OpenbaoClient::PkiCrossSignIntermediateRequest.new # PkiCrossSignIntermediateRequest | 

begin
  
  result = api_instance.pki_cross_sign_intermediate(pki_mount_path, pki_cross_sign_intermediate_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_cross_sign_intermediate: #{e}"
end
```

#### Using the pki_cross_sign_intermediate_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiCrossSignIntermediateResponse>, Integer, Hash)> pki_cross_sign_intermediate_with_http_info(pki_mount_path, pki_cross_sign_intermediate_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_cross_sign_intermediate_with_http_info(pki_mount_path, pki_cross_sign_intermediate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiCrossSignIntermediateResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_cross_sign_intermediate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_cross_sign_intermediate_request** | [**PkiCrossSignIntermediateRequest**](PkiCrossSignIntermediateRequest.md) |  |  |

### Return type

[**PkiCrossSignIntermediateResponse**](PkiCrossSignIntermediateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_delete_eab_key

> pki_delete_eab_key(key_id, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
key_id = 'key_id_example' # String | EAB key identifier
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_delete_eab_key(key_id, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_delete_eab_key: #{e}"
end
```

#### Using the pki_delete_eab_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_delete_eab_key_with_http_info(key_id, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_delete_eab_key_with_http_info(key_id, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_delete_eab_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key_id** | **String** | EAB key identifier |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_delete_issuer

> pki_delete_issuer(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_delete_issuer(issuer_ref, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_delete_issuer: #{e}"
end
```

#### Using the pki_delete_issuer_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_delete_issuer_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_delete_issuer_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_delete_issuer_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_delete_key

> pki_delete_key(key_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
key_ref = 'key_ref_example' # String | Reference to key; either \"default\" for the configured default key, an identifier of a key, or the name assigned to the key.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_delete_key(key_ref, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_delete_key: #{e}"
end
```

#### Using the pki_delete_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_delete_key_with_http_info(key_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_delete_key_with_http_info(key_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_delete_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key_ref** | **String** | Reference to key; either \&quot;default\&quot; for the configured default key, an identifier of a key, or the name assigned to the key. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_delete_role

> pki_delete_role(name, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_delete_role(name, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_delete_role: #{e}"
end
```

#### Using the pki_delete_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_delete_role_with_http_info(name, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_delete_role_with_http_info(name, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_delete_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_delete_root

> pki_delete_root(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_delete_root(pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_delete_root: #{e}"
end
```

#### Using the pki_delete_root_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_delete_root_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_delete_root_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_delete_root_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_generate_eab_key

> <PkiGenerateEabKeyResponse> pki_generate_eab_key(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_generate_eab_key(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_eab_key: #{e}"
end
```

#### Using the pki_generate_eab_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiGenerateEabKeyResponse>, Integer, Hash)> pki_generate_eab_key_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_generate_eab_key_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiGenerateEabKeyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_eab_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiGenerateEabKeyResponse**](PkiGenerateEabKeyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_generate_eab_key_for_issuer

> <PkiGenerateEabKeyForIssuerResponse> pki_generate_eab_key_for_issuer(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_generate_eab_key_for_issuer(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_eab_key_for_issuer: #{e}"
end
```

#### Using the pki_generate_eab_key_for_issuer_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiGenerateEabKeyForIssuerResponse>, Integer, Hash)> pki_generate_eab_key_for_issuer_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_generate_eab_key_for_issuer_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiGenerateEabKeyForIssuerResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_eab_key_for_issuer_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiGenerateEabKeyForIssuerResponse**](PkiGenerateEabKeyForIssuerResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_generate_eab_key_for_issuer_and_role

> <PkiGenerateEabKeyForIssuerAndRoleResponse> pki_generate_eab_key_for_issuer_and_role(issuer_ref, role, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_generate_eab_key_for_issuer_and_role(issuer_ref, role, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_eab_key_for_issuer_and_role: #{e}"
end
```

#### Using the pki_generate_eab_key_for_issuer_and_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiGenerateEabKeyForIssuerAndRoleResponse>, Integer, Hash)> pki_generate_eab_key_for_issuer_and_role_with_http_info(issuer_ref, role, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_generate_eab_key_for_issuer_and_role_with_http_info(issuer_ref, role, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiGenerateEabKeyForIssuerAndRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_eab_key_for_issuer_and_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiGenerateEabKeyForIssuerAndRoleResponse**](PkiGenerateEabKeyForIssuerAndRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_generate_eab_key_for_role

> <PkiGenerateEabKeyForRoleResponse> pki_generate_eab_key_for_role(role, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_generate_eab_key_for_role(role, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_eab_key_for_role: #{e}"
end
```

#### Using the pki_generate_eab_key_for_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiGenerateEabKeyForRoleResponse>, Integer, Hash)> pki_generate_eab_key_for_role_with_http_info(role, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_generate_eab_key_for_role_with_http_info(role, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiGenerateEabKeyForRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_eab_key_for_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiGenerateEabKeyForRoleResponse**](PkiGenerateEabKeyForRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_generate_exported_key

> <PkiGenerateExportedKeyResponse> pki_generate_exported_key(pki_mount_path, pki_generate_exported_key_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_generate_exported_key_request = OpenbaoClient::PkiGenerateExportedKeyRequest.new # PkiGenerateExportedKeyRequest | 

begin
  
  result = api_instance.pki_generate_exported_key(pki_mount_path, pki_generate_exported_key_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_exported_key: #{e}"
end
```

#### Using the pki_generate_exported_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiGenerateExportedKeyResponse>, Integer, Hash)> pki_generate_exported_key_with_http_info(pki_mount_path, pki_generate_exported_key_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_generate_exported_key_with_http_info(pki_mount_path, pki_generate_exported_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiGenerateExportedKeyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_exported_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_generate_exported_key_request** | [**PkiGenerateExportedKeyRequest**](PkiGenerateExportedKeyRequest.md) |  |  |

### Return type

[**PkiGenerateExportedKeyResponse**](PkiGenerateExportedKeyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_generate_intermediate

> <PkiGenerateIntermediateResponse> pki_generate_intermediate(exported, pki_mount_path, pki_generate_intermediate_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
exported = 'internal' # String | Must be \"internal\", \"exported\" or \"kms\". If set to \"exported\", the generated private key will be returned. This is your *only* chance to retrieve the private key!
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_generate_intermediate_request = OpenbaoClient::PkiGenerateIntermediateRequest.new # PkiGenerateIntermediateRequest | 

begin
  
  result = api_instance.pki_generate_intermediate(exported, pki_mount_path, pki_generate_intermediate_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_intermediate: #{e}"
end
```

#### Using the pki_generate_intermediate_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiGenerateIntermediateResponse>, Integer, Hash)> pki_generate_intermediate_with_http_info(exported, pki_mount_path, pki_generate_intermediate_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_generate_intermediate_with_http_info(exported, pki_mount_path, pki_generate_intermediate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiGenerateIntermediateResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_intermediate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **exported** | **String** | Must be \&quot;internal\&quot;, \&quot;exported\&quot; or \&quot;kms\&quot;. If set to \&quot;exported\&quot;, the generated private key will be returned. This is your *only* chance to retrieve the private key! |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_generate_intermediate_request** | [**PkiGenerateIntermediateRequest**](PkiGenerateIntermediateRequest.md) |  |  |

### Return type

[**PkiGenerateIntermediateResponse**](PkiGenerateIntermediateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_generate_internal_key

> <PkiGenerateInternalKeyResponse> pki_generate_internal_key(pki_mount_path, pki_generate_internal_key_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_generate_internal_key_request = OpenbaoClient::PkiGenerateInternalKeyRequest.new # PkiGenerateInternalKeyRequest | 

begin
  
  result = api_instance.pki_generate_internal_key(pki_mount_path, pki_generate_internal_key_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_internal_key: #{e}"
end
```

#### Using the pki_generate_internal_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiGenerateInternalKeyResponse>, Integer, Hash)> pki_generate_internal_key_with_http_info(pki_mount_path, pki_generate_internal_key_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_generate_internal_key_with_http_info(pki_mount_path, pki_generate_internal_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiGenerateInternalKeyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_internal_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_generate_internal_key_request** | [**PkiGenerateInternalKeyRequest**](PkiGenerateInternalKeyRequest.md) |  |  |

### Return type

[**PkiGenerateInternalKeyResponse**](PkiGenerateInternalKeyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_generate_kms_key

> <PkiGenerateKmsKeyResponse> pki_generate_kms_key(pki_mount_path, pki_generate_kms_key_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_generate_kms_key_request = OpenbaoClient::PkiGenerateKmsKeyRequest.new # PkiGenerateKmsKeyRequest | 

begin
  
  result = api_instance.pki_generate_kms_key(pki_mount_path, pki_generate_kms_key_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_kms_key: #{e}"
end
```

#### Using the pki_generate_kms_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiGenerateKmsKeyResponse>, Integer, Hash)> pki_generate_kms_key_with_http_info(pki_mount_path, pki_generate_kms_key_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_generate_kms_key_with_http_info(pki_mount_path, pki_generate_kms_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiGenerateKmsKeyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_kms_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_generate_kms_key_request** | [**PkiGenerateKmsKeyRequest**](PkiGenerateKmsKeyRequest.md) |  |  |

### Return type

[**PkiGenerateKmsKeyResponse**](PkiGenerateKmsKeyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_generate_root

> <PkiGenerateRootResponse> pki_generate_root(exported, pki_mount_path, pki_generate_root_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
exported = 'internal' # String | Must be \"internal\", \"exported\" or \"kms\". If set to \"exported\", the generated private key will be returned. This is your *only* chance to retrieve the private key!
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_generate_root_request = OpenbaoClient::PkiGenerateRootRequest.new # PkiGenerateRootRequest | 

begin
  
  result = api_instance.pki_generate_root(exported, pki_mount_path, pki_generate_root_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_root: #{e}"
end
```

#### Using the pki_generate_root_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiGenerateRootResponse>, Integer, Hash)> pki_generate_root_with_http_info(exported, pki_mount_path, pki_generate_root_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_generate_root_with_http_info(exported, pki_mount_path, pki_generate_root_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiGenerateRootResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_generate_root_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **exported** | **String** | Must be \&quot;internal\&quot;, \&quot;exported\&quot; or \&quot;kms\&quot;. If set to \&quot;exported\&quot;, the generated private key will be returned. This is your *only* chance to retrieve the private key! |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_generate_root_request** | [**PkiGenerateRootRequest**](PkiGenerateRootRequest.md) |  |  |

### Return type

[**PkiGenerateRootResponse**](PkiGenerateRootResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_import_key

> <PkiImportKeyResponse> pki_import_key(pki_mount_path, pki_import_key_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_import_key_request = OpenbaoClient::PkiImportKeyRequest.new # PkiImportKeyRequest | 

begin
  
  result = api_instance.pki_import_key(pki_mount_path, pki_import_key_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_import_key: #{e}"
end
```

#### Using the pki_import_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiImportKeyResponse>, Integer, Hash)> pki_import_key_with_http_info(pki_mount_path, pki_import_key_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_import_key_with_http_info(pki_mount_path, pki_import_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiImportKeyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_import_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_import_key_request** | [**PkiImportKeyRequest**](PkiImportKeyRequest.md) |  |  |

### Return type

[**PkiImportKeyResponse**](PkiImportKeyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issue_with_role

> <PkiIssueWithRoleResponse> pki_issue_with_role(role, pki_mount_path, pki_issue_with_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role with configuration for this request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issue_with_role_request = OpenbaoClient::PkiIssueWithRoleRequest.new # PkiIssueWithRoleRequest | 

begin
  
  result = api_instance.pki_issue_with_role(role, pki_mount_path, pki_issue_with_role_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issue_with_role: #{e}"
end
```

#### Using the pki_issue_with_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssueWithRoleResponse>, Integer, Hash)> pki_issue_with_role_with_http_info(role, pki_mount_path, pki_issue_with_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issue_with_role_with_http_info(role, pki_mount_path, pki_issue_with_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssueWithRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issue_with_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role with configuration for this request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issue_with_role_request** | [**PkiIssueWithRoleRequest**](PkiIssueWithRoleRequest.md) |  |  |

### Return type

[**PkiIssueWithRoleResponse**](PkiIssueWithRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuer_issue_with_role

> <PkiIssuerIssueWithRoleResponse> pki_issuer_issue_with_role(issuer_ref, role, pki_mount_path, pki_issuer_issue_with_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
role = 'role_example' # String | The desired role with configuration for this request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuer_issue_with_role_request = OpenbaoClient::PkiIssuerIssueWithRoleRequest.new # PkiIssuerIssueWithRoleRequest | 

begin
  
  result = api_instance.pki_issuer_issue_with_role(issuer_ref, role, pki_mount_path, pki_issuer_issue_with_role_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_issue_with_role: #{e}"
end
```

#### Using the pki_issuer_issue_with_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerIssueWithRoleResponse>, Integer, Hash)> pki_issuer_issue_with_role_with_http_info(issuer_ref, role, pki_mount_path, pki_issuer_issue_with_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_issue_with_role_with_http_info(issuer_ref, role, pki_mount_path, pki_issuer_issue_with_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerIssueWithRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_issue_with_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **role** | **String** | The desired role with configuration for this request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuer_issue_with_role_request** | [**PkiIssuerIssueWithRoleRequest**](PkiIssuerIssueWithRoleRequest.md) |  |  |

### Return type

[**PkiIssuerIssueWithRoleResponse**](PkiIssuerIssueWithRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuer_read_crl

> <PkiIssuerReadCrlResponse> pki_issuer_read_crl(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_issuer_read_crl(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl: #{e}"
end
```

#### Using the pki_issuer_read_crl_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerReadCrlResponse>, Integer, Hash)> pki_issuer_read_crl_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_read_crl_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerReadCrlResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiIssuerReadCrlResponse**](PkiIssuerReadCrlResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_issuer_read_crl_delta

> <PkiIssuerReadCrlDeltaResponse> pki_issuer_read_crl_delta(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_issuer_read_crl_delta(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_delta: #{e}"
end
```

#### Using the pki_issuer_read_crl_delta_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerReadCrlDeltaResponse>, Integer, Hash)> pki_issuer_read_crl_delta_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_read_crl_delta_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerReadCrlDeltaResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_delta_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiIssuerReadCrlDeltaResponse**](PkiIssuerReadCrlDeltaResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_issuer_read_crl_delta_der

> <PkiIssuerReadCrlDeltaDerResponse> pki_issuer_read_crl_delta_der(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_issuer_read_crl_delta_der(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_delta_der: #{e}"
end
```

#### Using the pki_issuer_read_crl_delta_der_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerReadCrlDeltaDerResponse>, Integer, Hash)> pki_issuer_read_crl_delta_der_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_read_crl_delta_der_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerReadCrlDeltaDerResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_delta_der_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiIssuerReadCrlDeltaDerResponse**](PkiIssuerReadCrlDeltaDerResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_issuer_read_crl_delta_pem

> <PkiIssuerReadCrlDeltaPemResponse> pki_issuer_read_crl_delta_pem(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_issuer_read_crl_delta_pem(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_delta_pem: #{e}"
end
```

#### Using the pki_issuer_read_crl_delta_pem_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerReadCrlDeltaPemResponse>, Integer, Hash)> pki_issuer_read_crl_delta_pem_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_read_crl_delta_pem_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerReadCrlDeltaPemResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_delta_pem_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiIssuerReadCrlDeltaPemResponse**](PkiIssuerReadCrlDeltaPemResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_issuer_read_crl_der

> <PkiIssuerReadCrlDerResponse> pki_issuer_read_crl_der(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_issuer_read_crl_der(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_der: #{e}"
end
```

#### Using the pki_issuer_read_crl_der_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerReadCrlDerResponse>, Integer, Hash)> pki_issuer_read_crl_der_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_read_crl_der_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerReadCrlDerResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_der_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiIssuerReadCrlDerResponse**](PkiIssuerReadCrlDerResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_issuer_read_crl_pem

> <PkiIssuerReadCrlPemResponse> pki_issuer_read_crl_pem(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_issuer_read_crl_pem(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_pem: #{e}"
end
```

#### Using the pki_issuer_read_crl_pem_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerReadCrlPemResponse>, Integer, Hash)> pki_issuer_read_crl_pem_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_read_crl_pem_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerReadCrlPemResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_read_crl_pem_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiIssuerReadCrlPemResponse**](PkiIssuerReadCrlPemResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_issuer_resign_crls

> <PkiIssuerResignCrlsResponse> pki_issuer_resign_crls(issuer_ref, pki_mount_path, pki_issuer_resign_crls_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuer_resign_crls_request = OpenbaoClient::PkiIssuerResignCrlsRequest.new # PkiIssuerResignCrlsRequest | 

begin
  
  result = api_instance.pki_issuer_resign_crls(issuer_ref, pki_mount_path, pki_issuer_resign_crls_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_resign_crls: #{e}"
end
```

#### Using the pki_issuer_resign_crls_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerResignCrlsResponse>, Integer, Hash)> pki_issuer_resign_crls_with_http_info(issuer_ref, pki_mount_path, pki_issuer_resign_crls_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_resign_crls_with_http_info(issuer_ref, pki_mount_path, pki_issuer_resign_crls_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerResignCrlsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_resign_crls_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuer_resign_crls_request** | [**PkiIssuerResignCrlsRequest**](PkiIssuerResignCrlsRequest.md) |  |  |

### Return type

[**PkiIssuerResignCrlsResponse**](PkiIssuerResignCrlsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuer_sign_intermediate

> <PkiIssuerSignIntermediateResponse> pki_issuer_sign_intermediate(issuer_ref, pki_mount_path, pki_issuer_sign_intermediate_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuer_sign_intermediate_request = OpenbaoClient::PkiIssuerSignIntermediateRequest.new # PkiIssuerSignIntermediateRequest | 

begin
  
  result = api_instance.pki_issuer_sign_intermediate(issuer_ref, pki_mount_path, pki_issuer_sign_intermediate_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_intermediate: #{e}"
end
```

#### Using the pki_issuer_sign_intermediate_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerSignIntermediateResponse>, Integer, Hash)> pki_issuer_sign_intermediate_with_http_info(issuer_ref, pki_mount_path, pki_issuer_sign_intermediate_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_sign_intermediate_with_http_info(issuer_ref, pki_mount_path, pki_issuer_sign_intermediate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerSignIntermediateResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_intermediate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuer_sign_intermediate_request** | [**PkiIssuerSignIntermediateRequest**](PkiIssuerSignIntermediateRequest.md) |  |  |

### Return type

[**PkiIssuerSignIntermediateResponse**](PkiIssuerSignIntermediateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuer_sign_revocation_list

> <PkiIssuerSignRevocationListResponse> pki_issuer_sign_revocation_list(issuer_ref, pki_mount_path, pki_issuer_sign_revocation_list_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuer_sign_revocation_list_request = OpenbaoClient::PkiIssuerSignRevocationListRequest.new # PkiIssuerSignRevocationListRequest | 

begin
  
  result = api_instance.pki_issuer_sign_revocation_list(issuer_ref, pki_mount_path, pki_issuer_sign_revocation_list_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_revocation_list: #{e}"
end
```

#### Using the pki_issuer_sign_revocation_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerSignRevocationListResponse>, Integer, Hash)> pki_issuer_sign_revocation_list_with_http_info(issuer_ref, pki_mount_path, pki_issuer_sign_revocation_list_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_sign_revocation_list_with_http_info(issuer_ref, pki_mount_path, pki_issuer_sign_revocation_list_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerSignRevocationListResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_revocation_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuer_sign_revocation_list_request** | [**PkiIssuerSignRevocationListRequest**](PkiIssuerSignRevocationListRequest.md) |  |  |

### Return type

[**PkiIssuerSignRevocationListResponse**](PkiIssuerSignRevocationListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuer_sign_self_issued

> <PkiIssuerSignSelfIssuedResponse> pki_issuer_sign_self_issued(issuer_ref, pki_mount_path, pki_issuer_sign_self_issued_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuer_sign_self_issued_request = OpenbaoClient::PkiIssuerSignSelfIssuedRequest.new # PkiIssuerSignSelfIssuedRequest | 

begin
  
  result = api_instance.pki_issuer_sign_self_issued(issuer_ref, pki_mount_path, pki_issuer_sign_self_issued_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_self_issued: #{e}"
end
```

#### Using the pki_issuer_sign_self_issued_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerSignSelfIssuedResponse>, Integer, Hash)> pki_issuer_sign_self_issued_with_http_info(issuer_ref, pki_mount_path, pki_issuer_sign_self_issued_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_sign_self_issued_with_http_info(issuer_ref, pki_mount_path, pki_issuer_sign_self_issued_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerSignSelfIssuedResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_self_issued_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuer_sign_self_issued_request** | [**PkiIssuerSignSelfIssuedRequest**](PkiIssuerSignSelfIssuedRequest.md) |  |  |

### Return type

[**PkiIssuerSignSelfIssuedResponse**](PkiIssuerSignSelfIssuedResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuer_sign_verbatim

> <PkiIssuerSignVerbatimResponse> pki_issuer_sign_verbatim(issuer_ref, pki_mount_path, pki_issuer_sign_verbatim_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuer_sign_verbatim_request = OpenbaoClient::PkiIssuerSignVerbatimRequest.new # PkiIssuerSignVerbatimRequest | 

begin
  
  result = api_instance.pki_issuer_sign_verbatim(issuer_ref, pki_mount_path, pki_issuer_sign_verbatim_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_verbatim: #{e}"
end
```

#### Using the pki_issuer_sign_verbatim_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerSignVerbatimResponse>, Integer, Hash)> pki_issuer_sign_verbatim_with_http_info(issuer_ref, pki_mount_path, pki_issuer_sign_verbatim_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_sign_verbatim_with_http_info(issuer_ref, pki_mount_path, pki_issuer_sign_verbatim_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerSignVerbatimResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_verbatim_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuer_sign_verbatim_request** | [**PkiIssuerSignVerbatimRequest**](PkiIssuerSignVerbatimRequest.md) |  |  |

### Return type

[**PkiIssuerSignVerbatimResponse**](PkiIssuerSignVerbatimResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuer_sign_verbatim_with_role

> <PkiIssuerSignVerbatimWithRoleResponse> pki_issuer_sign_verbatim_with_role(issuer_ref, role, pki_mount_path, pki_issuer_sign_verbatim_with_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
role = 'role_example' # String | The desired role with configuration for this request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuer_sign_verbatim_with_role_request = OpenbaoClient::PkiIssuerSignVerbatimWithRoleRequest.new # PkiIssuerSignVerbatimWithRoleRequest | 

begin
  
  result = api_instance.pki_issuer_sign_verbatim_with_role(issuer_ref, role, pki_mount_path, pki_issuer_sign_verbatim_with_role_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_verbatim_with_role: #{e}"
end
```

#### Using the pki_issuer_sign_verbatim_with_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerSignVerbatimWithRoleResponse>, Integer, Hash)> pki_issuer_sign_verbatim_with_role_with_http_info(issuer_ref, role, pki_mount_path, pki_issuer_sign_verbatim_with_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_sign_verbatim_with_role_with_http_info(issuer_ref, role, pki_mount_path, pki_issuer_sign_verbatim_with_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerSignVerbatimWithRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_verbatim_with_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **role** | **String** | The desired role with configuration for this request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuer_sign_verbatim_with_role_request** | [**PkiIssuerSignVerbatimWithRoleRequest**](PkiIssuerSignVerbatimWithRoleRequest.md) |  |  |

### Return type

[**PkiIssuerSignVerbatimWithRoleResponse**](PkiIssuerSignVerbatimWithRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuer_sign_with_role

> <PkiIssuerSignWithRoleResponse> pki_issuer_sign_with_role(issuer_ref, role, pki_mount_path, pki_issuer_sign_with_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
role = 'role_example' # String | The desired role with configuration for this request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuer_sign_with_role_request = OpenbaoClient::PkiIssuerSignWithRoleRequest.new # PkiIssuerSignWithRoleRequest | 

begin
  
  result = api_instance.pki_issuer_sign_with_role(issuer_ref, role, pki_mount_path, pki_issuer_sign_with_role_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_with_role: #{e}"
end
```

#### Using the pki_issuer_sign_with_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuerSignWithRoleResponse>, Integer, Hash)> pki_issuer_sign_with_role_with_http_info(issuer_ref, role, pki_mount_path, pki_issuer_sign_with_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuer_sign_with_role_with_http_info(issuer_ref, role, pki_mount_path, pki_issuer_sign_with_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuerSignWithRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuer_sign_with_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **role** | **String** | The desired role with configuration for this request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuer_sign_with_role_request** | [**PkiIssuerSignWithRoleRequest**](PkiIssuerSignWithRoleRequest.md) |  |  |

### Return type

[**PkiIssuerSignWithRoleResponse**](PkiIssuerSignWithRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuers_generate_intermediate

> <PkiIssuersGenerateIntermediateResponse> pki_issuers_generate_intermediate(exported, pki_mount_path, pki_issuers_generate_intermediate_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
exported = 'internal' # String | Must be \"internal\", \"exported\" or \"kms\". If set to \"exported\", the generated private key will be returned. This is your *only* chance to retrieve the private key!
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuers_generate_intermediate_request = OpenbaoClient::PkiIssuersGenerateIntermediateRequest.new # PkiIssuersGenerateIntermediateRequest | 

begin
  
  result = api_instance.pki_issuers_generate_intermediate(exported, pki_mount_path, pki_issuers_generate_intermediate_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuers_generate_intermediate: #{e}"
end
```

#### Using the pki_issuers_generate_intermediate_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuersGenerateIntermediateResponse>, Integer, Hash)> pki_issuers_generate_intermediate_with_http_info(exported, pki_mount_path, pki_issuers_generate_intermediate_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuers_generate_intermediate_with_http_info(exported, pki_mount_path, pki_issuers_generate_intermediate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuersGenerateIntermediateResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuers_generate_intermediate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **exported** | **String** | Must be \&quot;internal\&quot;, \&quot;exported\&quot; or \&quot;kms\&quot;. If set to \&quot;exported\&quot;, the generated private key will be returned. This is your *only* chance to retrieve the private key! |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuers_generate_intermediate_request** | [**PkiIssuersGenerateIntermediateRequest**](PkiIssuersGenerateIntermediateRequest.md) |  |  |

### Return type

[**PkiIssuersGenerateIntermediateResponse**](PkiIssuersGenerateIntermediateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuers_generate_root

> <PkiIssuersGenerateRootResponse> pki_issuers_generate_root(exported, pki_mount_path, pki_issuers_generate_root_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
exported = 'internal' # String | Must be \"internal\", \"exported\" or \"kms\". If set to \"exported\", the generated private key will be returned. This is your *only* chance to retrieve the private key!
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuers_generate_root_request = OpenbaoClient::PkiIssuersGenerateRootRequest.new # PkiIssuersGenerateRootRequest | 

begin
  
  result = api_instance.pki_issuers_generate_root(exported, pki_mount_path, pki_issuers_generate_root_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuers_generate_root: #{e}"
end
```

#### Using the pki_issuers_generate_root_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuersGenerateRootResponse>, Integer, Hash)> pki_issuers_generate_root_with_http_info(exported, pki_mount_path, pki_issuers_generate_root_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuers_generate_root_with_http_info(exported, pki_mount_path, pki_issuers_generate_root_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuersGenerateRootResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuers_generate_root_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **exported** | **String** | Must be \&quot;internal\&quot;, \&quot;exported\&quot; or \&quot;kms\&quot;. If set to \&quot;exported\&quot;, the generated private key will be returned. This is your *only* chance to retrieve the private key! |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuers_generate_root_request** | [**PkiIssuersGenerateRootRequest**](PkiIssuersGenerateRootRequest.md) |  |  |

### Return type

[**PkiIssuersGenerateRootResponse**](PkiIssuersGenerateRootResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuers_import_bundle

> <PkiIssuersImportBundleResponse> pki_issuers_import_bundle(pki_mount_path, pki_issuers_import_bundle_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuers_import_bundle_request = OpenbaoClient::PkiIssuersImportBundleRequest.new # PkiIssuersImportBundleRequest | 

begin
  
  result = api_instance.pki_issuers_import_bundle(pki_mount_path, pki_issuers_import_bundle_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuers_import_bundle: #{e}"
end
```

#### Using the pki_issuers_import_bundle_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuersImportBundleResponse>, Integer, Hash)> pki_issuers_import_bundle_with_http_info(pki_mount_path, pki_issuers_import_bundle_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuers_import_bundle_with_http_info(pki_mount_path, pki_issuers_import_bundle_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuersImportBundleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuers_import_bundle_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuers_import_bundle_request** | [**PkiIssuersImportBundleRequest**](PkiIssuersImportBundleRequest.md) |  |  |

### Return type

[**PkiIssuersImportBundleResponse**](PkiIssuersImportBundleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_issuers_import_cert

> <PkiIssuersImportCertResponse> pki_issuers_import_cert(pki_mount_path, pki_issuers_import_cert_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_issuers_import_cert_request = OpenbaoClient::PkiIssuersImportCertRequest.new # PkiIssuersImportCertRequest | 

begin
  
  result = api_instance.pki_issuers_import_cert(pki_mount_path, pki_issuers_import_cert_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuers_import_cert: #{e}"
end
```

#### Using the pki_issuers_import_cert_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiIssuersImportCertResponse>, Integer, Hash)> pki_issuers_import_cert_with_http_info(pki_mount_path, pki_issuers_import_cert_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_issuers_import_cert_with_http_info(pki_mount_path, pki_issuers_import_cert_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiIssuersImportCertResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_issuers_import_cert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_issuers_import_cert_request** | [**PkiIssuersImportCertRequest**](PkiIssuersImportCertRequest.md) |  |  |

### Return type

[**PkiIssuersImportCertResponse**](PkiIssuersImportCertResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_list_certs

> <PkiListCertsResponse> pki_list_certs(pki_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.pki_list_certs(pki_mount_path, list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_certs: #{e}"
end
```

#### Using the pki_list_certs_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiListCertsResponse>, Integer, Hash)> pki_list_certs_with_http_info(pki_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_list_certs_with_http_info(pki_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiListCertsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_certs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**PkiListCertsResponse**](PkiListCertsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_list_eab_keys

> <PkiListEabKeysResponse> pki_list_eab_keys(pki_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.pki_list_eab_keys(pki_mount_path, list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_eab_keys: #{e}"
end
```

#### Using the pki_list_eab_keys_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiListEabKeysResponse>, Integer, Hash)> pki_list_eab_keys_with_http_info(pki_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_list_eab_keys_with_http_info(pki_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiListEabKeysResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_eab_keys_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**PkiListEabKeysResponse**](PkiListEabKeysResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_list_issuers

> <PkiListIssuersResponse> pki_list_issuers(pki_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.pki_list_issuers(pki_mount_path, list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_issuers: #{e}"
end
```

#### Using the pki_list_issuers_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiListIssuersResponse>, Integer, Hash)> pki_list_issuers_with_http_info(pki_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_list_issuers_with_http_info(pki_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiListIssuersResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_issuers_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**PkiListIssuersResponse**](PkiListIssuersResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_list_keys

> <PkiListKeysResponse> pki_list_keys(pki_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.pki_list_keys(pki_mount_path, list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_keys: #{e}"
end
```

#### Using the pki_list_keys_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiListKeysResponse>, Integer, Hash)> pki_list_keys_with_http_info(pki_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_list_keys_with_http_info(pki_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiListKeysResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_keys_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**PkiListKeysResponse**](PkiListKeysResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_list_revoked_certs

> <PkiListRevokedCertsResponse> pki_list_revoked_certs(pki_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.pki_list_revoked_certs(pki_mount_path, list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_revoked_certs: #{e}"
end
```

#### Using the pki_list_revoked_certs_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiListRevokedCertsResponse>, Integer, Hash)> pki_list_revoked_certs_with_http_info(pki_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_list_revoked_certs_with_http_info(pki_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiListRevokedCertsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_revoked_certs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**PkiListRevokedCertsResponse**](PkiListRevokedCertsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_list_roles

> <PkiListRolesResponse> pki_list_roles(pki_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.pki_list_roles(pki_mount_path, list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_roles: #{e}"
end
```

#### Using the pki_list_roles_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiListRolesResponse>, Integer, Hash)> pki_list_roles_with_http_info(pki_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_list_roles_with_http_info(pki_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiListRolesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_list_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**PkiListRolesResponse**](PkiListRolesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_query_ocsp

> pki_query_ocsp(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_query_ocsp(pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_query_ocsp: #{e}"
end
```

#### Using the pki_query_ocsp_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_query_ocsp_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_query_ocsp_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_query_ocsp_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_query_ocsp_with_get_req

> pki_query_ocsp_with_get_req(req, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
req = 'req_example' # String | base-64 encoded ocsp request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_query_ocsp_with_get_req(req, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_query_ocsp_with_get_req: #{e}"
end
```

#### Using the pki_query_ocsp_with_get_req_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_query_ocsp_with_get_req_with_http_info(req, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_query_ocsp_with_get_req_with_http_info(req, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_query_ocsp_with_get_req_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **req** | **String** | base-64 encoded ocsp request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_read_acme_configuration

> pki_read_acme_configuration(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_read_acme_configuration(pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_acme_configuration: #{e}"
end
```

#### Using the pki_read_acme_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_read_acme_configuration_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_acme_configuration_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_acme_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_read_acme_directory

> pki_read_acme_directory(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_read_acme_directory(pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_acme_directory: #{e}"
end
```

#### Using the pki_read_acme_directory_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_read_acme_directory_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_acme_directory_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_acme_directory_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_read_acme_new_nonce

> pki_read_acme_new_nonce(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_read_acme_new_nonce(pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_acme_new_nonce: #{e}"
end
```

#### Using the pki_read_acme_new_nonce_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_read_acme_new_nonce_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_acme_new_nonce_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_acme_new_nonce_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_read_auto_tidy_configuration

> <PkiReadAutoTidyConfigurationResponse> pki_read_auto_tidy_configuration(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_auto_tidy_configuration(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_auto_tidy_configuration: #{e}"
end
```

#### Using the pki_read_auto_tidy_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadAutoTidyConfigurationResponse>, Integer, Hash)> pki_read_auto_tidy_configuration_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_auto_tidy_configuration_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadAutoTidyConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_auto_tidy_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadAutoTidyConfigurationResponse**](PkiReadAutoTidyConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_ca_chain_pem

> <PkiReadCaChainPemResponse> pki_read_ca_chain_pem(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_ca_chain_pem(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_ca_chain_pem: #{e}"
end
```

#### Using the pki_read_ca_chain_pem_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCaChainPemResponse>, Integer, Hash)> pki_read_ca_chain_pem_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_ca_chain_pem_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCaChainPemResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_ca_chain_pem_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCaChainPemResponse**](PkiReadCaChainPemResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_ca_der

> <PkiReadCaDerResponse> pki_read_ca_der(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_ca_der(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_ca_der: #{e}"
end
```

#### Using the pki_read_ca_der_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCaDerResponse>, Integer, Hash)> pki_read_ca_der_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_ca_der_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCaDerResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_ca_der_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCaDerResponse**](PkiReadCaDerResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_ca_pem

> <PkiReadCaPemResponse> pki_read_ca_pem(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_ca_pem(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_ca_pem: #{e}"
end
```

#### Using the pki_read_ca_pem_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCaPemResponse>, Integer, Hash)> pki_read_ca_pem_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_ca_pem_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCaPemResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_ca_pem_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCaPemResponse**](PkiReadCaPemResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_cert

> <PkiReadCertResponse> pki_read_cert(serial, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
serial = 'serial_example' # String | Certificate serial number, in colon- or hyphen-separated octal
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_cert(serial, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert: #{e}"
end
```

#### Using the pki_read_cert_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCertResponse>, Integer, Hash)> pki_read_cert_with_http_info(serial, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_cert_with_http_info(serial, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCertResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **serial** | **String** | Certificate serial number, in colon- or hyphen-separated octal |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCertResponse**](PkiReadCertResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_cert_ca_chain

> <PkiReadCertCaChainResponse> pki_read_cert_ca_chain(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_cert_ca_chain(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_ca_chain: #{e}"
end
```

#### Using the pki_read_cert_ca_chain_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCertCaChainResponse>, Integer, Hash)> pki_read_cert_ca_chain_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_cert_ca_chain_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCertCaChainResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_ca_chain_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCertCaChainResponse**](PkiReadCertCaChainResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_cert_crl

> <PkiReadCertCrlResponse> pki_read_cert_crl(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_cert_crl(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_crl: #{e}"
end
```

#### Using the pki_read_cert_crl_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCertCrlResponse>, Integer, Hash)> pki_read_cert_crl_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_cert_crl_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCertCrlResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_crl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCertCrlResponse**](PkiReadCertCrlResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_cert_delta_crl

> <PkiReadCertDeltaCrlResponse> pki_read_cert_delta_crl(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_cert_delta_crl(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_delta_crl: #{e}"
end
```

#### Using the pki_read_cert_delta_crl_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCertDeltaCrlResponse>, Integer, Hash)> pki_read_cert_delta_crl_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_cert_delta_crl_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCertDeltaCrlResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_delta_crl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCertDeltaCrlResponse**](PkiReadCertDeltaCrlResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_cert_raw_der

> <PkiReadCertRawDerResponse> pki_read_cert_raw_der(serial, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
serial = 'serial_example' # String | Certificate serial number, in colon- or hyphen-separated octal
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_cert_raw_der(serial, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_raw_der: #{e}"
end
```

#### Using the pki_read_cert_raw_der_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCertRawDerResponse>, Integer, Hash)> pki_read_cert_raw_der_with_http_info(serial, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_cert_raw_der_with_http_info(serial, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCertRawDerResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_raw_der_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **serial** | **String** | Certificate serial number, in colon- or hyphen-separated octal |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCertRawDerResponse**](PkiReadCertRawDerResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_cert_raw_pem

> <PkiReadCertRawPemResponse> pki_read_cert_raw_pem(serial, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
serial = 'serial_example' # String | Certificate serial number, in colon- or hyphen-separated octal
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_cert_raw_pem(serial, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_raw_pem: #{e}"
end
```

#### Using the pki_read_cert_raw_pem_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCertRawPemResponse>, Integer, Hash)> pki_read_cert_raw_pem_with_http_info(serial, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_cert_raw_pem_with_http_info(serial, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCertRawPemResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cert_raw_pem_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **serial** | **String** | Certificate serial number, in colon- or hyphen-separated octal |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCertRawPemResponse**](PkiReadCertRawPemResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_cluster_configuration

> <PkiReadClusterConfigurationResponse> pki_read_cluster_configuration(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_cluster_configuration(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cluster_configuration: #{e}"
end
```

#### Using the pki_read_cluster_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadClusterConfigurationResponse>, Integer, Hash)> pki_read_cluster_configuration_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_cluster_configuration_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadClusterConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_cluster_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadClusterConfigurationResponse**](PkiReadClusterConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_crl_configuration

> <PkiReadCrlConfigurationResponse> pki_read_crl_configuration(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_crl_configuration(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_crl_configuration: #{e}"
end
```

#### Using the pki_read_crl_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCrlConfigurationResponse>, Integer, Hash)> pki_read_crl_configuration_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_crl_configuration_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCrlConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_crl_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCrlConfigurationResponse**](PkiReadCrlConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_crl_delta

> <PkiReadCrlDeltaResponse> pki_read_crl_delta(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_crl_delta(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_crl_delta: #{e}"
end
```

#### Using the pki_read_crl_delta_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCrlDeltaResponse>, Integer, Hash)> pki_read_crl_delta_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_crl_delta_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCrlDeltaResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_crl_delta_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCrlDeltaResponse**](PkiReadCrlDeltaResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_crl_delta_pem

> <PkiReadCrlDeltaPemResponse> pki_read_crl_delta_pem(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_crl_delta_pem(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_crl_delta_pem: #{e}"
end
```

#### Using the pki_read_crl_delta_pem_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCrlDeltaPemResponse>, Integer, Hash)> pki_read_crl_delta_pem_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_crl_delta_pem_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCrlDeltaPemResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_crl_delta_pem_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCrlDeltaPemResponse**](PkiReadCrlDeltaPemResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_crl_der

> <PkiReadCrlDerResponse> pki_read_crl_der(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_crl_der(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_crl_der: #{e}"
end
```

#### Using the pki_read_crl_der_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCrlDerResponse>, Integer, Hash)> pki_read_crl_der_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_crl_der_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCrlDerResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_crl_der_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCrlDerResponse**](PkiReadCrlDerResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_crl_pem

> <PkiReadCrlPemResponse> pki_read_crl_pem(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_crl_pem(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_crl_pem: #{e}"
end
```

#### Using the pki_read_crl_pem_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadCrlPemResponse>, Integer, Hash)> pki_read_crl_pem_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_crl_pem_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadCrlPemResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_crl_pem_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadCrlPemResponse**](PkiReadCrlPemResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_issuer

> <PkiReadIssuerResponse> pki_read_issuer(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_issuer(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer: #{e}"
end
```

#### Using the pki_read_issuer_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadIssuerResponse>, Integer, Hash)> pki_read_issuer_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_issuer_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadIssuerResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadIssuerResponse**](PkiReadIssuerResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_issuer_der

> <PkiReadIssuerDerResponse> pki_read_issuer_der(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_issuer_der(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_der: #{e}"
end
```

#### Using the pki_read_issuer_der_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadIssuerDerResponse>, Integer, Hash)> pki_read_issuer_der_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_issuer_der_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadIssuerDerResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_der_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadIssuerDerResponse**](PkiReadIssuerDerResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_issuer_issuer_ref_acme_directory

> pki_read_issuer_issuer_ref_acme_directory(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_read_issuer_issuer_ref_acme_directory(issuer_ref, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_issuer_ref_acme_directory: #{e}"
end
```

#### Using the pki_read_issuer_issuer_ref_acme_directory_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_read_issuer_issuer_ref_acme_directory_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_issuer_issuer_ref_acme_directory_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_issuer_ref_acme_directory_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_read_issuer_issuer_ref_acme_new_nonce

> pki_read_issuer_issuer_ref_acme_new_nonce(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_read_issuer_issuer_ref_acme_new_nonce(issuer_ref, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_issuer_ref_acme_new_nonce: #{e}"
end
```

#### Using the pki_read_issuer_issuer_ref_acme_new_nonce_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_read_issuer_issuer_ref_acme_new_nonce_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_issuer_issuer_ref_acme_new_nonce_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_issuer_ref_acme_new_nonce_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_read_issuer_issuer_ref_roles_role_acme_directory

> pki_read_issuer_issuer_ref_roles_role_acme_directory(issuer_ref, role, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_read_issuer_issuer_ref_roles_role_acme_directory(issuer_ref, role, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_issuer_ref_roles_role_acme_directory: #{e}"
end
```

#### Using the pki_read_issuer_issuer_ref_roles_role_acme_directory_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_read_issuer_issuer_ref_roles_role_acme_directory_with_http_info(issuer_ref, role, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_issuer_issuer_ref_roles_role_acme_directory_with_http_info(issuer_ref, role, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_issuer_ref_roles_role_acme_directory_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_read_issuer_issuer_ref_roles_role_acme_new_nonce

> pki_read_issuer_issuer_ref_roles_role_acme_new_nonce(issuer_ref, role, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_read_issuer_issuer_ref_roles_role_acme_new_nonce(issuer_ref, role, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_issuer_ref_roles_role_acme_new_nonce: #{e}"
end
```

#### Using the pki_read_issuer_issuer_ref_roles_role_acme_new_nonce_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_read_issuer_issuer_ref_roles_role_acme_new_nonce_with_http_info(issuer_ref, role, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_issuer_issuer_ref_roles_role_acme_new_nonce_with_http_info(issuer_ref, role, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_issuer_ref_roles_role_acme_new_nonce_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_read_issuer_json

> <PkiReadIssuerJsonResponse> pki_read_issuer_json(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_issuer_json(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_json: #{e}"
end
```

#### Using the pki_read_issuer_json_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadIssuerJsonResponse>, Integer, Hash)> pki_read_issuer_json_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_issuer_json_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadIssuerJsonResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_json_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadIssuerJsonResponse**](PkiReadIssuerJsonResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_issuer_pem

> <PkiReadIssuerPemResponse> pki_read_issuer_pem(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_issuer_pem(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_pem: #{e}"
end
```

#### Using the pki_read_issuer_pem_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadIssuerPemResponse>, Integer, Hash)> pki_read_issuer_pem_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_issuer_pem_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadIssuerPemResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuer_pem_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadIssuerPemResponse**](PkiReadIssuerPemResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_issuers_configuration

> <PkiReadIssuersConfigurationResponse> pki_read_issuers_configuration(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_issuers_configuration(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuers_configuration: #{e}"
end
```

#### Using the pki_read_issuers_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadIssuersConfigurationResponse>, Integer, Hash)> pki_read_issuers_configuration_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_issuers_configuration_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadIssuersConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_issuers_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadIssuersConfigurationResponse**](PkiReadIssuersConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_key

> <PkiReadKeyResponse> pki_read_key(key_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
key_ref = 'key_ref_example' # String | Reference to key; either \"default\" for the configured default key, an identifier of a key, or the name assigned to the key.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_key(key_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_key: #{e}"
end
```

#### Using the pki_read_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadKeyResponse>, Integer, Hash)> pki_read_key_with_http_info(key_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_key_with_http_info(key_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadKeyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key_ref** | **String** | Reference to key; either \&quot;default\&quot; for the configured default key, an identifier of a key, or the name assigned to the key. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadKeyResponse**](PkiReadKeyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_keys_configuration

> <PkiReadKeysConfigurationResponse> pki_read_keys_configuration(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_keys_configuration(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_keys_configuration: #{e}"
end
```

#### Using the pki_read_keys_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadKeysConfigurationResponse>, Integer, Hash)> pki_read_keys_configuration_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_keys_configuration_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadKeysConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_keys_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadKeysConfigurationResponse**](PkiReadKeysConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_role

> <PkiReadRoleResponse> pki_read_role(name, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_role(name, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_role: #{e}"
end
```

#### Using the pki_read_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadRoleResponse>, Integer, Hash)> pki_read_role_with_http_info(name, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_role_with_http_info(name, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadRoleResponse**](PkiReadRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_read_roles_role_acme_directory

> pki_read_roles_role_acme_directory(role, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_read_roles_role_acme_directory(role, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_roles_role_acme_directory: #{e}"
end
```

#### Using the pki_read_roles_role_acme_directory_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_read_roles_role_acme_directory_with_http_info(role, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_roles_role_acme_directory_with_http_info(role, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_roles_role_acme_directory_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_read_roles_role_acme_new_nonce

> pki_read_roles_role_acme_new_nonce(role, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.pki_read_roles_role_acme_new_nonce(role, pki_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_roles_role_acme_new_nonce: #{e}"
end
```

#### Using the pki_read_roles_role_acme_new_nonce_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_read_roles_role_acme_new_nonce_with_http_info(role, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_roles_role_acme_new_nonce_with_http_info(role, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_roles_role_acme_new_nonce_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## pki_read_urls_configuration

> <PkiReadUrlsConfigurationResponse> pki_read_urls_configuration(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_read_urls_configuration(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_urls_configuration: #{e}"
end
```

#### Using the pki_read_urls_configuration_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReadUrlsConfigurationResponse>, Integer, Hash)> pki_read_urls_configuration_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_read_urls_configuration_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReadUrlsConfigurationResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_read_urls_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiReadUrlsConfigurationResponse**](PkiReadUrlsConfigurationResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_replace_root

> <PkiReplaceRootResponse> pki_replace_root(pki_mount_path, pki_replace_root_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_replace_root_request = OpenbaoClient::PkiReplaceRootRequest.new # PkiReplaceRootRequest | 

begin
  
  result = api_instance.pki_replace_root(pki_mount_path, pki_replace_root_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_replace_root: #{e}"
end
```

#### Using the pki_replace_root_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiReplaceRootResponse>, Integer, Hash)> pki_replace_root_with_http_info(pki_mount_path, pki_replace_root_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_replace_root_with_http_info(pki_mount_path, pki_replace_root_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiReplaceRootResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_replace_root_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_replace_root_request** | [**PkiReplaceRootRequest**](PkiReplaceRootRequest.md) |  |  |

### Return type

[**PkiReplaceRootResponse**](PkiReplaceRootResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_revoke

> <PkiRevokeResponse> pki_revoke(pki_mount_path, pki_revoke_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_revoke_request = OpenbaoClient::PkiRevokeRequest.new # PkiRevokeRequest | 

begin
  
  result = api_instance.pki_revoke(pki_mount_path, pki_revoke_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_revoke: #{e}"
end
```

#### Using the pki_revoke_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiRevokeResponse>, Integer, Hash)> pki_revoke_with_http_info(pki_mount_path, pki_revoke_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_revoke_with_http_info(pki_mount_path, pki_revoke_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiRevokeResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_revoke_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_revoke_request** | [**PkiRevokeRequest**](PkiRevokeRequest.md) |  |  |

### Return type

[**PkiRevokeResponse**](PkiRevokeResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_revoke_issuer

> <PkiRevokeIssuerResponse> pki_revoke_issuer(issuer_ref, pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_revoke_issuer(issuer_ref, pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_revoke_issuer: #{e}"
end
```

#### Using the pki_revoke_issuer_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiRevokeIssuerResponse>, Integer, Hash)> pki_revoke_issuer_with_http_info(issuer_ref, pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_revoke_issuer_with_http_info(issuer_ref, pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiRevokeIssuerResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_revoke_issuer_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiRevokeIssuerResponse**](PkiRevokeIssuerResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_revoke_with_key

> <PkiRevokeWithKeyResponse> pki_revoke_with_key(pki_mount_path, pki_revoke_with_key_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_revoke_with_key_request = OpenbaoClient::PkiRevokeWithKeyRequest.new # PkiRevokeWithKeyRequest | 

begin
  
  result = api_instance.pki_revoke_with_key(pki_mount_path, pki_revoke_with_key_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_revoke_with_key: #{e}"
end
```

#### Using the pki_revoke_with_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiRevokeWithKeyResponse>, Integer, Hash)> pki_revoke_with_key_with_http_info(pki_mount_path, pki_revoke_with_key_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_revoke_with_key_with_http_info(pki_mount_path, pki_revoke_with_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiRevokeWithKeyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_revoke_with_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_revoke_with_key_request** | [**PkiRevokeWithKeyRequest**](PkiRevokeWithKeyRequest.md) |  |  |

### Return type

[**PkiRevokeWithKeyResponse**](PkiRevokeWithKeyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_root_sign_intermediate

> <PkiRootSignIntermediateResponse> pki_root_sign_intermediate(pki_mount_path, pki_root_sign_intermediate_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_root_sign_intermediate_request = OpenbaoClient::PkiRootSignIntermediateRequest.new # PkiRootSignIntermediateRequest | 

begin
  
  result = api_instance.pki_root_sign_intermediate(pki_mount_path, pki_root_sign_intermediate_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_root_sign_intermediate: #{e}"
end
```

#### Using the pki_root_sign_intermediate_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiRootSignIntermediateResponse>, Integer, Hash)> pki_root_sign_intermediate_with_http_info(pki_mount_path, pki_root_sign_intermediate_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_root_sign_intermediate_with_http_info(pki_mount_path, pki_root_sign_intermediate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiRootSignIntermediateResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_root_sign_intermediate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_root_sign_intermediate_request** | [**PkiRootSignIntermediateRequest**](PkiRootSignIntermediateRequest.md) |  |  |

### Return type

[**PkiRootSignIntermediateResponse**](PkiRootSignIntermediateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_root_sign_self_issued

> <PkiRootSignSelfIssuedResponse> pki_root_sign_self_issued(pki_mount_path, pki_root_sign_self_issued_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_root_sign_self_issued_request = OpenbaoClient::PkiRootSignSelfIssuedRequest.new # PkiRootSignSelfIssuedRequest | 

begin
  
  result = api_instance.pki_root_sign_self_issued(pki_mount_path, pki_root_sign_self_issued_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_root_sign_self_issued: #{e}"
end
```

#### Using the pki_root_sign_self_issued_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiRootSignSelfIssuedResponse>, Integer, Hash)> pki_root_sign_self_issued_with_http_info(pki_mount_path, pki_root_sign_self_issued_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_root_sign_self_issued_with_http_info(pki_mount_path, pki_root_sign_self_issued_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiRootSignSelfIssuedResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_root_sign_self_issued_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_root_sign_self_issued_request** | [**PkiRootSignSelfIssuedRequest**](PkiRootSignSelfIssuedRequest.md) |  |  |

### Return type

[**PkiRootSignSelfIssuedResponse**](PkiRootSignSelfIssuedResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_rotate_crl

> <PkiRotateCrlResponse> pki_rotate_crl(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_rotate_crl(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_rotate_crl: #{e}"
end
```

#### Using the pki_rotate_crl_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiRotateCrlResponse>, Integer, Hash)> pki_rotate_crl_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_rotate_crl_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiRotateCrlResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_rotate_crl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiRotateCrlResponse**](PkiRotateCrlResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_rotate_delta_crl

> <PkiRotateDeltaCrlResponse> pki_rotate_delta_crl(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_rotate_delta_crl(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_rotate_delta_crl: #{e}"
end
```

#### Using the pki_rotate_delta_crl_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiRotateDeltaCrlResponse>, Integer, Hash)> pki_rotate_delta_crl_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_rotate_delta_crl_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiRotateDeltaCrlResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_rotate_delta_crl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiRotateDeltaCrlResponse**](PkiRotateDeltaCrlResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_rotate_root

> <PkiRotateRootResponse> pki_rotate_root(exported, pki_mount_path, pki_rotate_root_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
exported = 'internal' # String | Must be \"internal\", \"exported\" or \"kms\". If set to \"exported\", the generated private key will be returned. This is your *only* chance to retrieve the private key!
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_rotate_root_request = OpenbaoClient::PkiRotateRootRequest.new # PkiRotateRootRequest | 

begin
  
  result = api_instance.pki_rotate_root(exported, pki_mount_path, pki_rotate_root_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_rotate_root: #{e}"
end
```

#### Using the pki_rotate_root_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiRotateRootResponse>, Integer, Hash)> pki_rotate_root_with_http_info(exported, pki_mount_path, pki_rotate_root_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_rotate_root_with_http_info(exported, pki_mount_path, pki_rotate_root_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiRotateRootResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_rotate_root_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **exported** | **String** | Must be \&quot;internal\&quot;, \&quot;exported\&quot; or \&quot;kms\&quot;. If set to \&quot;exported\&quot;, the generated private key will be returned. This is your *only* chance to retrieve the private key! |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_rotate_root_request** | [**PkiRotateRootRequest**](PkiRotateRootRequest.md) |  |  |

### Return type

[**PkiRotateRootResponse**](PkiRotateRootResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_set_signed_intermediate

> <PkiSetSignedIntermediateResponse> pki_set_signed_intermediate(pki_mount_path, pki_set_signed_intermediate_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_set_signed_intermediate_request = OpenbaoClient::PkiSetSignedIntermediateRequest.new # PkiSetSignedIntermediateRequest | 

begin
  
  result = api_instance.pki_set_signed_intermediate(pki_mount_path, pki_set_signed_intermediate_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_set_signed_intermediate: #{e}"
end
```

#### Using the pki_set_signed_intermediate_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiSetSignedIntermediateResponse>, Integer, Hash)> pki_set_signed_intermediate_with_http_info(pki_mount_path, pki_set_signed_intermediate_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_set_signed_intermediate_with_http_info(pki_mount_path, pki_set_signed_intermediate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiSetSignedIntermediateResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_set_signed_intermediate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_set_signed_intermediate_request** | [**PkiSetSignedIntermediateRequest**](PkiSetSignedIntermediateRequest.md) |  |  |

### Return type

[**PkiSetSignedIntermediateResponse**](PkiSetSignedIntermediateResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_sign_verbatim

> <PkiSignVerbatimResponse> pki_sign_verbatim(pki_mount_path, pki_sign_verbatim_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_sign_verbatim_request = OpenbaoClient::PkiSignVerbatimRequest.new # PkiSignVerbatimRequest | 

begin
  
  result = api_instance.pki_sign_verbatim(pki_mount_path, pki_sign_verbatim_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_sign_verbatim: #{e}"
end
```

#### Using the pki_sign_verbatim_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiSignVerbatimResponse>, Integer, Hash)> pki_sign_verbatim_with_http_info(pki_mount_path, pki_sign_verbatim_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_sign_verbatim_with_http_info(pki_mount_path, pki_sign_verbatim_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiSignVerbatimResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_sign_verbatim_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_sign_verbatim_request** | [**PkiSignVerbatimRequest**](PkiSignVerbatimRequest.md) |  |  |

### Return type

[**PkiSignVerbatimResponse**](PkiSignVerbatimResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_sign_verbatim_with_role

> <PkiSignVerbatimWithRoleResponse> pki_sign_verbatim_with_role(role, pki_mount_path, pki_sign_verbatim_with_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role with configuration for this request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_sign_verbatim_with_role_request = OpenbaoClient::PkiSignVerbatimWithRoleRequest.new # PkiSignVerbatimWithRoleRequest | 

begin
  
  result = api_instance.pki_sign_verbatim_with_role(role, pki_mount_path, pki_sign_verbatim_with_role_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_sign_verbatim_with_role: #{e}"
end
```

#### Using the pki_sign_verbatim_with_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiSignVerbatimWithRoleResponse>, Integer, Hash)> pki_sign_verbatim_with_role_with_http_info(role, pki_mount_path, pki_sign_verbatim_with_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_sign_verbatim_with_role_with_http_info(role, pki_mount_path, pki_sign_verbatim_with_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiSignVerbatimWithRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_sign_verbatim_with_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role with configuration for this request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_sign_verbatim_with_role_request** | [**PkiSignVerbatimWithRoleRequest**](PkiSignVerbatimWithRoleRequest.md) |  |  |

### Return type

[**PkiSignVerbatimWithRoleResponse**](PkiSignVerbatimWithRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_sign_with_role

> <PkiSignWithRoleResponse> pki_sign_with_role(role, pki_mount_path, pki_sign_with_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role with configuration for this request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_sign_with_role_request = OpenbaoClient::PkiSignWithRoleRequest.new # PkiSignWithRoleRequest | 

begin
  
  result = api_instance.pki_sign_with_role(role, pki_mount_path, pki_sign_with_role_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_sign_with_role: #{e}"
end
```

#### Using the pki_sign_with_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiSignWithRoleResponse>, Integer, Hash)> pki_sign_with_role_with_http_info(role, pki_mount_path, pki_sign_with_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_sign_with_role_with_http_info(role, pki_mount_path, pki_sign_with_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiSignWithRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_sign_with_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role with configuration for this request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_sign_with_role_request** | [**PkiSignWithRoleRequest**](PkiSignWithRoleRequest.md) |  |  |

### Return type

[**PkiSignWithRoleResponse**](PkiSignWithRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_tidy

> pki_tidy(pki_mount_path, pki_tidy_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_tidy_request = OpenbaoClient::PkiTidyRequest.new # PkiTidyRequest | 

begin
  
  api_instance.pki_tidy(pki_mount_path, pki_tidy_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_tidy: #{e}"
end
```

#### Using the pki_tidy_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_tidy_with_http_info(pki_mount_path, pki_tidy_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_tidy_with_http_info(pki_mount_path, pki_tidy_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_tidy_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_tidy_request** | [**PkiTidyRequest**](PkiTidyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_tidy_cancel

> <PkiTidyCancelResponse> pki_tidy_cancel(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_tidy_cancel(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_tidy_cancel: #{e}"
end
```

#### Using the pki_tidy_cancel_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiTidyCancelResponse>, Integer, Hash)> pki_tidy_cancel_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_tidy_cancel_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiTidyCancelResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_tidy_cancel_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiTidyCancelResponse**](PkiTidyCancelResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_tidy_status

> <PkiTidyStatusResponse> pki_tidy_status(pki_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.pki_tidy_status(pki_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_tidy_status: #{e}"
end
```

#### Using the pki_tidy_status_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiTidyStatusResponse>, Integer, Hash)> pki_tidy_status_with_http_info(pki_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_tidy_status_with_http_info(pki_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiTidyStatusResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_tidy_status_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |

### Return type

[**PkiTidyStatusResponse**](PkiTidyStatusResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## pki_write_acme_account_kid

> pki_write_acme_account_kid(kid, pki_mount_path, pki_write_acme_account_kid_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
kid = 'kid_example' # String | The key identifier provided by the CA
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_acme_account_kid_request = OpenbaoClient::PkiWriteAcmeAccountKidRequest.new # PkiWriteAcmeAccountKidRequest | 

begin
  
  api_instance.pki_write_acme_account_kid(kid, pki_mount_path, pki_write_acme_account_kid_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_account_kid: #{e}"
end
```

#### Using the pki_write_acme_account_kid_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_acme_account_kid_with_http_info(kid, pki_mount_path, pki_write_acme_account_kid_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_acme_account_kid_with_http_info(kid, pki_mount_path, pki_write_acme_account_kid_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_account_kid_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kid** | **String** | The key identifier provided by the CA |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_acme_account_kid_request** | [**PkiWriteAcmeAccountKidRequest**](PkiWriteAcmeAccountKidRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_acme_authorization_auth_id

> pki_write_acme_authorization_auth_id(auth_id, pki_mount_path, pki_write_acme_authorization_auth_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
auth_id = 'auth_id_example' # String | ACME authorization identifier value
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_acme_authorization_auth_id_request = OpenbaoClient::PkiWriteAcmeAuthorizationAuthIdRequest.new # PkiWriteAcmeAuthorizationAuthIdRequest | 

begin
  
  api_instance.pki_write_acme_authorization_auth_id(auth_id, pki_mount_path, pki_write_acme_authorization_auth_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_authorization_auth_id: #{e}"
end
```

#### Using the pki_write_acme_authorization_auth_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_acme_authorization_auth_id_with_http_info(auth_id, pki_mount_path, pki_write_acme_authorization_auth_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_acme_authorization_auth_id_with_http_info(auth_id, pki_mount_path, pki_write_acme_authorization_auth_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_authorization_auth_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **auth_id** | **String** | ACME authorization identifier value |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_acme_authorization_auth_id_request** | [**PkiWriteAcmeAuthorizationAuthIdRequest**](PkiWriteAcmeAuthorizationAuthIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_acme_challenge_auth_id_challenge_type

> pki_write_acme_challenge_auth_id_challenge_type(auth_id, challenge_type, pki_mount_path, pki_write_acme_challenge_auth_id_challenge_type_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
auth_id = 'auth_id_example' # String | ACME authorization identifier value
challenge_type = 'challenge_type_example' # String | ACME challenge type
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_acme_challenge_auth_id_challenge_type_request = OpenbaoClient::PkiWriteAcmeChallengeAuthIdChallengeTypeRequest.new # PkiWriteAcmeChallengeAuthIdChallengeTypeRequest | 

begin
  
  api_instance.pki_write_acme_challenge_auth_id_challenge_type(auth_id, challenge_type, pki_mount_path, pki_write_acme_challenge_auth_id_challenge_type_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_challenge_auth_id_challenge_type: #{e}"
end
```

#### Using the pki_write_acme_challenge_auth_id_challenge_type_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_acme_challenge_auth_id_challenge_type_with_http_info(auth_id, challenge_type, pki_mount_path, pki_write_acme_challenge_auth_id_challenge_type_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_acme_challenge_auth_id_challenge_type_with_http_info(auth_id, challenge_type, pki_mount_path, pki_write_acme_challenge_auth_id_challenge_type_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_challenge_auth_id_challenge_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **auth_id** | **String** | ACME authorization identifier value |  |
| **challenge_type** | **String** | ACME challenge type |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_acme_challenge_auth_id_challenge_type_request** | [**PkiWriteAcmeChallengeAuthIdChallengeTypeRequest**](PkiWriteAcmeChallengeAuthIdChallengeTypeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_acme_new_account

> pki_write_acme_new_account(pki_mount_path, pki_write_acme_new_account_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_acme_new_account_request = OpenbaoClient::PkiWriteAcmeNewAccountRequest.new # PkiWriteAcmeNewAccountRequest | 

begin
  
  api_instance.pki_write_acme_new_account(pki_mount_path, pki_write_acme_new_account_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_new_account: #{e}"
end
```

#### Using the pki_write_acme_new_account_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_acme_new_account_with_http_info(pki_mount_path, pki_write_acme_new_account_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_acme_new_account_with_http_info(pki_mount_path, pki_write_acme_new_account_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_new_account_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_acme_new_account_request** | [**PkiWriteAcmeNewAccountRequest**](PkiWriteAcmeNewAccountRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_acme_new_order

> pki_write_acme_new_order(pki_mount_path, pki_write_acme_new_order_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_acme_new_order_request = OpenbaoClient::PkiWriteAcmeNewOrderRequest.new # PkiWriteAcmeNewOrderRequest | 

begin
  
  api_instance.pki_write_acme_new_order(pki_mount_path, pki_write_acme_new_order_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_new_order: #{e}"
end
```

#### Using the pki_write_acme_new_order_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_acme_new_order_with_http_info(pki_mount_path, pki_write_acme_new_order_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_acme_new_order_with_http_info(pki_mount_path, pki_write_acme_new_order_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_new_order_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_acme_new_order_request** | [**PkiWriteAcmeNewOrderRequest**](PkiWriteAcmeNewOrderRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_acme_order_order_id

> pki_write_acme_order_order_id(order_id, pki_mount_path, pki_write_acme_order_order_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
order_id = 'order_id_example' # String | The ACME order identifier to fetch
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_acme_order_order_id_request = OpenbaoClient::PkiWriteAcmeOrderOrderIdRequest.new # PkiWriteAcmeOrderOrderIdRequest | 

begin
  
  api_instance.pki_write_acme_order_order_id(order_id, pki_mount_path, pki_write_acme_order_order_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_order_order_id: #{e}"
end
```

#### Using the pki_write_acme_order_order_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_acme_order_order_id_with_http_info(order_id, pki_mount_path, pki_write_acme_order_order_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_acme_order_order_id_with_http_info(order_id, pki_mount_path, pki_write_acme_order_order_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_order_order_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_acme_order_order_id_request** | [**PkiWriteAcmeOrderOrderIdRequest**](PkiWriteAcmeOrderOrderIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_acme_order_order_id_cert

> pki_write_acme_order_order_id_cert(order_id, pki_mount_path, pki_write_acme_order_order_id_cert_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
order_id = 'order_id_example' # String | The ACME order identifier to fetch
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_acme_order_order_id_cert_request = OpenbaoClient::PkiWriteAcmeOrderOrderIdCertRequest.new # PkiWriteAcmeOrderOrderIdCertRequest | 

begin
  
  api_instance.pki_write_acme_order_order_id_cert(order_id, pki_mount_path, pki_write_acme_order_order_id_cert_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_order_order_id_cert: #{e}"
end
```

#### Using the pki_write_acme_order_order_id_cert_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_acme_order_order_id_cert_with_http_info(order_id, pki_mount_path, pki_write_acme_order_order_id_cert_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_acme_order_order_id_cert_with_http_info(order_id, pki_mount_path, pki_write_acme_order_order_id_cert_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_order_order_id_cert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_acme_order_order_id_cert_request** | [**PkiWriteAcmeOrderOrderIdCertRequest**](PkiWriteAcmeOrderOrderIdCertRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_acme_order_order_id_finalize

> pki_write_acme_order_order_id_finalize(order_id, pki_mount_path, pki_write_acme_order_order_id_finalize_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
order_id = 'order_id_example' # String | The ACME order identifier to fetch
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_acme_order_order_id_finalize_request = OpenbaoClient::PkiWriteAcmeOrderOrderIdFinalizeRequest.new # PkiWriteAcmeOrderOrderIdFinalizeRequest | 

begin
  
  api_instance.pki_write_acme_order_order_id_finalize(order_id, pki_mount_path, pki_write_acme_order_order_id_finalize_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_order_order_id_finalize: #{e}"
end
```

#### Using the pki_write_acme_order_order_id_finalize_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_acme_order_order_id_finalize_with_http_info(order_id, pki_mount_path, pki_write_acme_order_order_id_finalize_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_acme_order_order_id_finalize_with_http_info(order_id, pki_mount_path, pki_write_acme_order_order_id_finalize_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_order_order_id_finalize_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_acme_order_order_id_finalize_request** | [**PkiWriteAcmeOrderOrderIdFinalizeRequest**](PkiWriteAcmeOrderOrderIdFinalizeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_acme_orders

> pki_write_acme_orders(pki_mount_path, pki_write_acme_orders_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_acme_orders_request = OpenbaoClient::PkiWriteAcmeOrdersRequest.new # PkiWriteAcmeOrdersRequest | 

begin
  
  api_instance.pki_write_acme_orders(pki_mount_path, pki_write_acme_orders_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_orders: #{e}"
end
```

#### Using the pki_write_acme_orders_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_acme_orders_with_http_info(pki_mount_path, pki_write_acme_orders_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_acme_orders_with_http_info(pki_mount_path, pki_write_acme_orders_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_orders_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_acme_orders_request** | [**PkiWriteAcmeOrdersRequest**](PkiWriteAcmeOrdersRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_acme_revoke_cert

> pki_write_acme_revoke_cert(pki_mount_path, pki_write_acme_revoke_cert_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_acme_revoke_cert_request = OpenbaoClient::PkiWriteAcmeRevokeCertRequest.new # PkiWriteAcmeRevokeCertRequest | 

begin
  
  api_instance.pki_write_acme_revoke_cert(pki_mount_path, pki_write_acme_revoke_cert_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_revoke_cert: #{e}"
end
```

#### Using the pki_write_acme_revoke_cert_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_acme_revoke_cert_with_http_info(pki_mount_path, pki_write_acme_revoke_cert_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_acme_revoke_cert_with_http_info(pki_mount_path, pki_write_acme_revoke_cert_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_acme_revoke_cert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_acme_revoke_cert_request** | [**PkiWriteAcmeRevokeCertRequest**](PkiWriteAcmeRevokeCertRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer

> <PkiWriteIssuerResponse> pki_write_issuer(issuer_ref, pki_mount_path, pki_write_issuer_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to a existing issuer; either \"default\" for the configured default issuer, an identifier or the name assigned to the issuer.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_request = OpenbaoClient::PkiWriteIssuerRequest.new # PkiWriteIssuerRequest | 

begin
  
  result = api_instance.pki_write_issuer(issuer_ref, pki_mount_path, pki_write_issuer_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer: #{e}"
end
```

#### Using the pki_write_issuer_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiWriteIssuerResponse>, Integer, Hash)> pki_write_issuer_with_http_info(issuer_ref, pki_mount_path, pki_write_issuer_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_with_http_info(issuer_ref, pki_mount_path, pki_write_issuer_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiWriteIssuerResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to a existing issuer; either \&quot;default\&quot; for the configured default issuer, an identifier or the name assigned to the issuer. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_request** | [**PkiWriteIssuerRequest**](PkiWriteIssuerRequest.md) |  |  |

### Return type

[**PkiWriteIssuerResponse**](PkiWriteIssuerResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_write_issuer_issuer_ref_acme_account_kid

> pki_write_issuer_issuer_ref_acme_account_kid(issuer_ref, kid, pki_mount_path, pki_write_issuer_issuer_ref_acme_account_kid_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
kid = 'kid_example' # String | The key identifier provided by the CA
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_acme_account_kid_request = OpenbaoClient::PkiWriteIssuerIssuerRefAcmeAccountKidRequest.new # PkiWriteIssuerIssuerRefAcmeAccountKidRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_acme_account_kid(issuer_ref, kid, pki_mount_path, pki_write_issuer_issuer_ref_acme_account_kid_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_account_kid: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_acme_account_kid_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_acme_account_kid_with_http_info(issuer_ref, kid, pki_mount_path, pki_write_issuer_issuer_ref_acme_account_kid_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_acme_account_kid_with_http_info(issuer_ref, kid, pki_mount_path, pki_write_issuer_issuer_ref_acme_account_kid_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_account_kid_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **kid** | **String** | The key identifier provided by the CA |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_acme_account_kid_request** | [**PkiWriteIssuerIssuerRefAcmeAccountKidRequest**](PkiWriteIssuerIssuerRefAcmeAccountKidRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_acme_authorization_auth_id

> pki_write_issuer_issuer_ref_acme_authorization_auth_id(auth_id, issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_authorization_auth_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
auth_id = 'auth_id_example' # String | ACME authorization identifier value
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_acme_authorization_auth_id_request = OpenbaoClient::PkiWriteIssuerIssuerRefAcmeAuthorizationAuthIdRequest.new # PkiWriteIssuerIssuerRefAcmeAuthorizationAuthIdRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_acme_authorization_auth_id(auth_id, issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_authorization_auth_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_authorization_auth_id: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_acme_authorization_auth_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_acme_authorization_auth_id_with_http_info(auth_id, issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_authorization_auth_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_acme_authorization_auth_id_with_http_info(auth_id, issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_authorization_auth_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_authorization_auth_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **auth_id** | **String** | ACME authorization identifier value |  |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_acme_authorization_auth_id_request** | [**PkiWriteIssuerIssuerRefAcmeAuthorizationAuthIdRequest**](PkiWriteIssuerIssuerRefAcmeAuthorizationAuthIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type

> pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type(auth_id, challenge_type, issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
auth_id = 'auth_id_example' # String | ACME authorization identifier value
challenge_type = 'challenge_type_example' # String | ACME challenge type
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type_request = OpenbaoClient::PkiWriteIssuerIssuerRefAcmeChallengeAuthIdChallengeTypeRequest.new # PkiWriteIssuerIssuerRefAcmeChallengeAuthIdChallengeTypeRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type(auth_id, challenge_type, issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type_with_http_info(auth_id, challenge_type, issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type_with_http_info(auth_id, challenge_type, issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **auth_id** | **String** | ACME authorization identifier value |  |
| **challenge_type** | **String** | ACME challenge type |  |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_acme_challenge_auth_id_challenge_type_request** | [**PkiWriteIssuerIssuerRefAcmeChallengeAuthIdChallengeTypeRequest**](PkiWriteIssuerIssuerRefAcmeChallengeAuthIdChallengeTypeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_acme_new_account

> pki_write_issuer_issuer_ref_acme_new_account(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_new_account_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_acme_new_account_request = OpenbaoClient::PkiWriteIssuerIssuerRefAcmeNewAccountRequest.new # PkiWriteIssuerIssuerRefAcmeNewAccountRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_acme_new_account(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_new_account_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_new_account: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_acme_new_account_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_acme_new_account_with_http_info(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_new_account_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_acme_new_account_with_http_info(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_new_account_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_new_account_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_acme_new_account_request** | [**PkiWriteIssuerIssuerRefAcmeNewAccountRequest**](PkiWriteIssuerIssuerRefAcmeNewAccountRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_acme_new_order

> pki_write_issuer_issuer_ref_acme_new_order(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_new_order_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_acme_new_order_request = OpenbaoClient::PkiWriteIssuerIssuerRefAcmeNewOrderRequest.new # PkiWriteIssuerIssuerRefAcmeNewOrderRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_acme_new_order(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_new_order_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_new_order: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_acme_new_order_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_acme_new_order_with_http_info(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_new_order_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_acme_new_order_with_http_info(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_new_order_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_new_order_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_acme_new_order_request** | [**PkiWriteIssuerIssuerRefAcmeNewOrderRequest**](PkiWriteIssuerIssuerRefAcmeNewOrderRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_acme_order_order_id

> pki_write_issuer_issuer_ref_acme_order_order_id(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
order_id = 'order_id_example' # String | The ACME order identifier to fetch
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_acme_order_order_id_request = OpenbaoClient::PkiWriteIssuerIssuerRefAcmeOrderOrderIdRequest.new # PkiWriteIssuerIssuerRefAcmeOrderOrderIdRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_acme_order_order_id(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_order_order_id: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_acme_order_order_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_acme_order_order_id_with_http_info(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_acme_order_order_id_with_http_info(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_order_order_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_acme_order_order_id_request** | [**PkiWriteIssuerIssuerRefAcmeOrderOrderIdRequest**](PkiWriteIssuerIssuerRefAcmeOrderOrderIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_acme_order_order_id_cert

> pki_write_issuer_issuer_ref_acme_order_order_id_cert(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_cert_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
order_id = 'order_id_example' # String | The ACME order identifier to fetch
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_acme_order_order_id_cert_request = OpenbaoClient::PkiWriteIssuerIssuerRefAcmeOrderOrderIdCertRequest.new # PkiWriteIssuerIssuerRefAcmeOrderOrderIdCertRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_acme_order_order_id_cert(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_cert_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_order_order_id_cert: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_acme_order_order_id_cert_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_acme_order_order_id_cert_with_http_info(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_cert_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_acme_order_order_id_cert_with_http_info(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_cert_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_order_order_id_cert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_acme_order_order_id_cert_request** | [**PkiWriteIssuerIssuerRefAcmeOrderOrderIdCertRequest**](PkiWriteIssuerIssuerRefAcmeOrderOrderIdCertRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_acme_order_order_id_finalize

> pki_write_issuer_issuer_ref_acme_order_order_id_finalize(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_finalize_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
order_id = 'order_id_example' # String | The ACME order identifier to fetch
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_acme_order_order_id_finalize_request = OpenbaoClient::PkiWriteIssuerIssuerRefAcmeOrderOrderIdFinalizeRequest.new # PkiWriteIssuerIssuerRefAcmeOrderOrderIdFinalizeRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_acme_order_order_id_finalize(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_finalize_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_order_order_id_finalize: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_acme_order_order_id_finalize_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_acme_order_order_id_finalize_with_http_info(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_finalize_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_acme_order_order_id_finalize_with_http_info(issuer_ref, order_id, pki_mount_path, pki_write_issuer_issuer_ref_acme_order_order_id_finalize_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_order_order_id_finalize_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_acme_order_order_id_finalize_request** | [**PkiWriteIssuerIssuerRefAcmeOrderOrderIdFinalizeRequest**](PkiWriteIssuerIssuerRefAcmeOrderOrderIdFinalizeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_acme_orders

> pki_write_issuer_issuer_ref_acme_orders(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_orders_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_acme_orders_request = OpenbaoClient::PkiWriteIssuerIssuerRefAcmeOrdersRequest.new # PkiWriteIssuerIssuerRefAcmeOrdersRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_acme_orders(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_orders_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_orders: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_acme_orders_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_acme_orders_with_http_info(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_orders_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_acme_orders_with_http_info(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_orders_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_orders_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_acme_orders_request** | [**PkiWriteIssuerIssuerRefAcmeOrdersRequest**](PkiWriteIssuerIssuerRefAcmeOrdersRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_acme_revoke_cert

> pki_write_issuer_issuer_ref_acme_revoke_cert(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_revoke_cert_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_acme_revoke_cert_request = OpenbaoClient::PkiWriteIssuerIssuerRefAcmeRevokeCertRequest.new # PkiWriteIssuerIssuerRefAcmeRevokeCertRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_acme_revoke_cert(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_revoke_cert_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_revoke_cert: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_acme_revoke_cert_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_acme_revoke_cert_with_http_info(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_revoke_cert_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_acme_revoke_cert_with_http_info(issuer_ref, pki_mount_path, pki_write_issuer_issuer_ref_acme_revoke_cert_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_acme_revoke_cert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_acme_revoke_cert_request** | [**PkiWriteIssuerIssuerRefAcmeRevokeCertRequest**](PkiWriteIssuerIssuerRefAcmeRevokeCertRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_roles_role_acme_account_kid

> pki_write_issuer_issuer_ref_roles_role_acme_account_kid(issuer_ref, kid, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_account_kid_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
kid = 'kid_example' # String | The key identifier provided by the CA
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_roles_role_acme_account_kid_request = OpenbaoClient::PkiWriteIssuerIssuerRefRolesRoleAcmeAccountKidRequest.new # PkiWriteIssuerIssuerRefRolesRoleAcmeAccountKidRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_roles_role_acme_account_kid(issuer_ref, kid, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_account_kid_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_account_kid: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_roles_role_acme_account_kid_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_roles_role_acme_account_kid_with_http_info(issuer_ref, kid, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_account_kid_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_roles_role_acme_account_kid_with_http_info(issuer_ref, kid, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_account_kid_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_account_kid_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **kid** | **String** | The key identifier provided by the CA |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_roles_role_acme_account_kid_request** | [**PkiWriteIssuerIssuerRefRolesRoleAcmeAccountKidRequest**](PkiWriteIssuerIssuerRefRolesRoleAcmeAccountKidRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id

> pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id(auth_id, issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
auth_id = 'auth_id_example' # String | ACME authorization identifier value
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id_request = OpenbaoClient::PkiWriteIssuerIssuerRefRolesRoleAcmeAuthorizationAuthIdRequest.new # PkiWriteIssuerIssuerRefRolesRoleAcmeAuthorizationAuthIdRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id(auth_id, issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id_with_http_info(auth_id, issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id_with_http_info(auth_id, issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **auth_id** | **String** | ACME authorization identifier value |  |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_roles_role_acme_authorization_auth_id_request** | [**PkiWriteIssuerIssuerRefRolesRoleAcmeAuthorizationAuthIdRequest**](PkiWriteIssuerIssuerRefRolesRoleAcmeAuthorizationAuthIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type

> pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type(auth_id, challenge_type, issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
auth_id = 'auth_id_example' # String | ACME authorization identifier value
challenge_type = 'challenge_type_example' # String | ACME challenge type
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type_request = OpenbaoClient::PkiWriteIssuerIssuerRefRolesRoleAcmeChallengeAuthIdChallengeTypeRequest.new # PkiWriteIssuerIssuerRefRolesRoleAcmeChallengeAuthIdChallengeTypeRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type(auth_id, challenge_type, issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type_with_http_info(auth_id, challenge_type, issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type_with_http_info(auth_id, challenge_type, issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **auth_id** | **String** | ACME authorization identifier value |  |
| **challenge_type** | **String** | ACME challenge type |  |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_roles_role_acme_challenge_auth_id_challenge_type_request** | [**PkiWriteIssuerIssuerRefRolesRoleAcmeChallengeAuthIdChallengeTypeRequest**](PkiWriteIssuerIssuerRefRolesRoleAcmeChallengeAuthIdChallengeTypeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_roles_role_acme_new_account

> pki_write_issuer_issuer_ref_roles_role_acme_new_account(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_new_account_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_roles_role_acme_new_account_request = OpenbaoClient::PkiWriteIssuerIssuerRefRolesRoleAcmeNewAccountRequest.new # PkiWriteIssuerIssuerRefRolesRoleAcmeNewAccountRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_roles_role_acme_new_account(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_new_account_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_new_account: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_roles_role_acme_new_account_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_roles_role_acme_new_account_with_http_info(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_new_account_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_roles_role_acme_new_account_with_http_info(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_new_account_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_new_account_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_roles_role_acme_new_account_request** | [**PkiWriteIssuerIssuerRefRolesRoleAcmeNewAccountRequest**](PkiWriteIssuerIssuerRefRolesRoleAcmeNewAccountRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_roles_role_acme_new_order

> pki_write_issuer_issuer_ref_roles_role_acme_new_order(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_new_order_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_roles_role_acme_new_order_request = OpenbaoClient::PkiWriteIssuerIssuerRefRolesRoleAcmeNewOrderRequest.new # PkiWriteIssuerIssuerRefRolesRoleAcmeNewOrderRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_roles_role_acme_new_order(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_new_order_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_new_order: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_roles_role_acme_new_order_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_roles_role_acme_new_order_with_http_info(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_new_order_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_roles_role_acme_new_order_with_http_info(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_new_order_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_new_order_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_roles_role_acme_new_order_request** | [**PkiWriteIssuerIssuerRefRolesRoleAcmeNewOrderRequest**](PkiWriteIssuerIssuerRefRolesRoleAcmeNewOrderRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_roles_role_acme_order_order_id

> pki_write_issuer_issuer_ref_roles_role_acme_order_order_id(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
order_id = 'order_id_example' # String | The ACME order identifier to fetch
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_request = OpenbaoClient::PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdRequest.new # PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_roles_role_acme_order_order_id(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_order_order_id: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_with_http_info(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_with_http_info(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_request** | [**PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdRequest**](PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert

> pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
order_id = 'order_id_example' # String | The ACME order identifier to fetch
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert_request = OpenbaoClient::PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdCertRequest.new # PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdCertRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert_with_http_info(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert_with_http_info(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_cert_request** | [**PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdCertRequest**](PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdCertRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize

> pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
order_id = 'order_id_example' # String | The ACME order identifier to fetch
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize_request = OpenbaoClient::PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdFinalizeRequest.new # PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdFinalizeRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize_with_http_info(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize_with_http_info(issuer_ref, order_id, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_roles_role_acme_order_order_id_finalize_request** | [**PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdFinalizeRequest**](PkiWriteIssuerIssuerRefRolesRoleAcmeOrderOrderIdFinalizeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_roles_role_acme_orders

> pki_write_issuer_issuer_ref_roles_role_acme_orders(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_orders_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_roles_role_acme_orders_request = OpenbaoClient::PkiWriteIssuerIssuerRefRolesRoleAcmeOrdersRequest.new # PkiWriteIssuerIssuerRefRolesRoleAcmeOrdersRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_roles_role_acme_orders(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_orders_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_orders: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_roles_role_acme_orders_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_roles_role_acme_orders_with_http_info(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_orders_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_roles_role_acme_orders_with_http_info(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_orders_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_orders_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_roles_role_acme_orders_request** | [**PkiWriteIssuerIssuerRefRolesRoleAcmeOrdersRequest**](PkiWriteIssuerIssuerRefRolesRoleAcmeOrdersRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert

> pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
issuer_ref = 'issuer_ref_example' # String | Reference to an existing issuer name or issuer id
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert_request = OpenbaoClient::PkiWriteIssuerIssuerRefRolesRoleAcmeRevokeCertRequest.new # PkiWriteIssuerIssuerRefRolesRoleAcmeRevokeCertRequest | 

begin
  
  api_instance.pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert: #{e}"
end
```

#### Using the pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert_with_http_info(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert_with_http_info(issuer_ref, role, pki_mount_path, pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **issuer_ref** | **String** | Reference to an existing issuer name or issuer id |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_issuer_issuer_ref_roles_role_acme_revoke_cert_request** | [**PkiWriteIssuerIssuerRefRolesRoleAcmeRevokeCertRequest**](PkiWriteIssuerIssuerRefRolesRoleAcmeRevokeCertRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_key

> <PkiWriteKeyResponse> pki_write_key(key_ref, pki_mount_path, pki_write_key_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
key_ref = 'key_ref_example' # String | Reference to key; either \"default\" for the configured default key, an identifier of a key, or the name assigned to the key.
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_key_request = OpenbaoClient::PkiWriteKeyRequest.new # PkiWriteKeyRequest | 

begin
  
  result = api_instance.pki_write_key(key_ref, pki_mount_path, pki_write_key_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_key: #{e}"
end
```

#### Using the pki_write_key_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiWriteKeyResponse>, Integer, Hash)> pki_write_key_with_http_info(key_ref, pki_mount_path, pki_write_key_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_key_with_http_info(key_ref, pki_mount_path, pki_write_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiWriteKeyResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **key_ref** | **String** | Reference to key; either \&quot;default\&quot; for the configured default key, an identifier of a key, or the name assigned to the key. | [default to &#39;default&#39;] |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_key_request** | [**PkiWriteKeyRequest**](PkiWriteKeyRequest.md) |  |  |

### Return type

[**PkiWriteKeyResponse**](PkiWriteKeyResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_write_role

> <PkiWriteRoleResponse> pki_write_role(name, pki_mount_path, pki_write_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_role_request = OpenbaoClient::PkiWriteRoleRequest.new # PkiWriteRoleRequest | 

begin
  
  result = api_instance.pki_write_role(name, pki_mount_path, pki_write_role_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_role: #{e}"
end
```

#### Using the pki_write_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<PkiWriteRoleResponse>, Integer, Hash)> pki_write_role_with_http_info(name, pki_mount_path, pki_write_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_role_with_http_info(name, pki_mount_path, pki_write_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <PkiWriteRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_role_request** | [**PkiWriteRoleRequest**](PkiWriteRoleRequest.md) |  |  |

### Return type

[**PkiWriteRoleResponse**](PkiWriteRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## pki_write_roles_role_acme_account_kid

> pki_write_roles_role_acme_account_kid(kid, role, pki_mount_path, pki_write_roles_role_acme_account_kid_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
kid = 'kid_example' # String | The key identifier provided by the CA
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_roles_role_acme_account_kid_request = OpenbaoClient::PkiWriteRolesRoleAcmeAccountKidRequest.new # PkiWriteRolesRoleAcmeAccountKidRequest | 

begin
  
  api_instance.pki_write_roles_role_acme_account_kid(kid, role, pki_mount_path, pki_write_roles_role_acme_account_kid_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_account_kid: #{e}"
end
```

#### Using the pki_write_roles_role_acme_account_kid_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_roles_role_acme_account_kid_with_http_info(kid, role, pki_mount_path, pki_write_roles_role_acme_account_kid_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_roles_role_acme_account_kid_with_http_info(kid, role, pki_mount_path, pki_write_roles_role_acme_account_kid_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_account_kid_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kid** | **String** | The key identifier provided by the CA |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_roles_role_acme_account_kid_request** | [**PkiWriteRolesRoleAcmeAccountKidRequest**](PkiWriteRolesRoleAcmeAccountKidRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_roles_role_acme_authorization_auth_id

> pki_write_roles_role_acme_authorization_auth_id(auth_id, role, pki_mount_path, pki_write_roles_role_acme_authorization_auth_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
auth_id = 'auth_id_example' # String | ACME authorization identifier value
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_roles_role_acme_authorization_auth_id_request = OpenbaoClient::PkiWriteRolesRoleAcmeAuthorizationAuthIdRequest.new # PkiWriteRolesRoleAcmeAuthorizationAuthIdRequest | 

begin
  
  api_instance.pki_write_roles_role_acme_authorization_auth_id(auth_id, role, pki_mount_path, pki_write_roles_role_acme_authorization_auth_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_authorization_auth_id: #{e}"
end
```

#### Using the pki_write_roles_role_acme_authorization_auth_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_roles_role_acme_authorization_auth_id_with_http_info(auth_id, role, pki_mount_path, pki_write_roles_role_acme_authorization_auth_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_roles_role_acme_authorization_auth_id_with_http_info(auth_id, role, pki_mount_path, pki_write_roles_role_acme_authorization_auth_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_authorization_auth_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **auth_id** | **String** | ACME authorization identifier value |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_roles_role_acme_authorization_auth_id_request** | [**PkiWriteRolesRoleAcmeAuthorizationAuthIdRequest**](PkiWriteRolesRoleAcmeAuthorizationAuthIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_roles_role_acme_challenge_auth_id_challenge_type

> pki_write_roles_role_acme_challenge_auth_id_challenge_type(auth_id, challenge_type, role, pki_mount_path, pki_write_roles_role_acme_challenge_auth_id_challenge_type_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
auth_id = 'auth_id_example' # String | ACME authorization identifier value
challenge_type = 'challenge_type_example' # String | ACME challenge type
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_roles_role_acme_challenge_auth_id_challenge_type_request = OpenbaoClient::PkiWriteRolesRoleAcmeChallengeAuthIdChallengeTypeRequest.new # PkiWriteRolesRoleAcmeChallengeAuthIdChallengeTypeRequest | 

begin
  
  api_instance.pki_write_roles_role_acme_challenge_auth_id_challenge_type(auth_id, challenge_type, role, pki_mount_path, pki_write_roles_role_acme_challenge_auth_id_challenge_type_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_challenge_auth_id_challenge_type: #{e}"
end
```

#### Using the pki_write_roles_role_acme_challenge_auth_id_challenge_type_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_roles_role_acme_challenge_auth_id_challenge_type_with_http_info(auth_id, challenge_type, role, pki_mount_path, pki_write_roles_role_acme_challenge_auth_id_challenge_type_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_roles_role_acme_challenge_auth_id_challenge_type_with_http_info(auth_id, challenge_type, role, pki_mount_path, pki_write_roles_role_acme_challenge_auth_id_challenge_type_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_challenge_auth_id_challenge_type_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **auth_id** | **String** | ACME authorization identifier value |  |
| **challenge_type** | **String** | ACME challenge type |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_roles_role_acme_challenge_auth_id_challenge_type_request** | [**PkiWriteRolesRoleAcmeChallengeAuthIdChallengeTypeRequest**](PkiWriteRolesRoleAcmeChallengeAuthIdChallengeTypeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_roles_role_acme_new_account

> pki_write_roles_role_acme_new_account(role, pki_mount_path, pki_write_roles_role_acme_new_account_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_roles_role_acme_new_account_request = OpenbaoClient::PkiWriteRolesRoleAcmeNewAccountRequest.new # PkiWriteRolesRoleAcmeNewAccountRequest | 

begin
  
  api_instance.pki_write_roles_role_acme_new_account(role, pki_mount_path, pki_write_roles_role_acme_new_account_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_new_account: #{e}"
end
```

#### Using the pki_write_roles_role_acme_new_account_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_roles_role_acme_new_account_with_http_info(role, pki_mount_path, pki_write_roles_role_acme_new_account_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_roles_role_acme_new_account_with_http_info(role, pki_mount_path, pki_write_roles_role_acme_new_account_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_new_account_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_roles_role_acme_new_account_request** | [**PkiWriteRolesRoleAcmeNewAccountRequest**](PkiWriteRolesRoleAcmeNewAccountRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_roles_role_acme_new_order

> pki_write_roles_role_acme_new_order(role, pki_mount_path, pki_write_roles_role_acme_new_order_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_roles_role_acme_new_order_request = OpenbaoClient::PkiWriteRolesRoleAcmeNewOrderRequest.new # PkiWriteRolesRoleAcmeNewOrderRequest | 

begin
  
  api_instance.pki_write_roles_role_acme_new_order(role, pki_mount_path, pki_write_roles_role_acme_new_order_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_new_order: #{e}"
end
```

#### Using the pki_write_roles_role_acme_new_order_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_roles_role_acme_new_order_with_http_info(role, pki_mount_path, pki_write_roles_role_acme_new_order_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_roles_role_acme_new_order_with_http_info(role, pki_mount_path, pki_write_roles_role_acme_new_order_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_new_order_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_roles_role_acme_new_order_request** | [**PkiWriteRolesRoleAcmeNewOrderRequest**](PkiWriteRolesRoleAcmeNewOrderRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_roles_role_acme_order_order_id

> pki_write_roles_role_acme_order_order_id(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
order_id = 'order_id_example' # String | The ACME order identifier to fetch
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_roles_role_acme_order_order_id_request = OpenbaoClient::PkiWriteRolesRoleAcmeOrderOrderIdRequest.new # PkiWriteRolesRoleAcmeOrderOrderIdRequest | 

begin
  
  api_instance.pki_write_roles_role_acme_order_order_id(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_order_order_id: #{e}"
end
```

#### Using the pki_write_roles_role_acme_order_order_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_roles_role_acme_order_order_id_with_http_info(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_roles_role_acme_order_order_id_with_http_info(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_order_order_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_roles_role_acme_order_order_id_request** | [**PkiWriteRolesRoleAcmeOrderOrderIdRequest**](PkiWriteRolesRoleAcmeOrderOrderIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_roles_role_acme_order_order_id_cert

> pki_write_roles_role_acme_order_order_id_cert(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_cert_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
order_id = 'order_id_example' # String | The ACME order identifier to fetch
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_roles_role_acme_order_order_id_cert_request = OpenbaoClient::PkiWriteRolesRoleAcmeOrderOrderIdCertRequest.new # PkiWriteRolesRoleAcmeOrderOrderIdCertRequest | 

begin
  
  api_instance.pki_write_roles_role_acme_order_order_id_cert(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_cert_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_order_order_id_cert: #{e}"
end
```

#### Using the pki_write_roles_role_acme_order_order_id_cert_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_roles_role_acme_order_order_id_cert_with_http_info(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_cert_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_roles_role_acme_order_order_id_cert_with_http_info(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_cert_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_order_order_id_cert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_roles_role_acme_order_order_id_cert_request** | [**PkiWriteRolesRoleAcmeOrderOrderIdCertRequest**](PkiWriteRolesRoleAcmeOrderOrderIdCertRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_roles_role_acme_order_order_id_finalize

> pki_write_roles_role_acme_order_order_id_finalize(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_finalize_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
order_id = 'order_id_example' # String | The ACME order identifier to fetch
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_roles_role_acme_order_order_id_finalize_request = OpenbaoClient::PkiWriteRolesRoleAcmeOrderOrderIdFinalizeRequest.new # PkiWriteRolesRoleAcmeOrderOrderIdFinalizeRequest | 

begin
  
  api_instance.pki_write_roles_role_acme_order_order_id_finalize(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_finalize_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_order_order_id_finalize: #{e}"
end
```

#### Using the pki_write_roles_role_acme_order_order_id_finalize_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_roles_role_acme_order_order_id_finalize_with_http_info(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_finalize_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_roles_role_acme_order_order_id_finalize_with_http_info(order_id, role, pki_mount_path, pki_write_roles_role_acme_order_order_id_finalize_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_order_order_id_finalize_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **order_id** | **String** | The ACME order identifier to fetch |  |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_roles_role_acme_order_order_id_finalize_request** | [**PkiWriteRolesRoleAcmeOrderOrderIdFinalizeRequest**](PkiWriteRolesRoleAcmeOrderOrderIdFinalizeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_roles_role_acme_orders

> pki_write_roles_role_acme_orders(role, pki_mount_path, pki_write_roles_role_acme_orders_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_roles_role_acme_orders_request = OpenbaoClient::PkiWriteRolesRoleAcmeOrdersRequest.new # PkiWriteRolesRoleAcmeOrdersRequest | 

begin
  
  api_instance.pki_write_roles_role_acme_orders(role, pki_mount_path, pki_write_roles_role_acme_orders_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_orders: #{e}"
end
```

#### Using the pki_write_roles_role_acme_orders_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_roles_role_acme_orders_with_http_info(role, pki_mount_path, pki_write_roles_role_acme_orders_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_roles_role_acme_orders_with_http_info(role, pki_mount_path, pki_write_roles_role_acme_orders_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_orders_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_roles_role_acme_orders_request** | [**PkiWriteRolesRoleAcmeOrdersRequest**](PkiWriteRolesRoleAcmeOrdersRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## pki_write_roles_role_acme_revoke_cert

> pki_write_roles_role_acme_revoke_cert(role, pki_mount_path, pki_write_roles_role_acme_revoke_cert_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role for the acme request
pki_mount_path = 'pki_mount_path_example' # String | Path that the backend was mounted at
pki_write_roles_role_acme_revoke_cert_request = OpenbaoClient::PkiWriteRolesRoleAcmeRevokeCertRequest.new # PkiWriteRolesRoleAcmeRevokeCertRequest | 

begin
  
  api_instance.pki_write_roles_role_acme_revoke_cert(role, pki_mount_path, pki_write_roles_role_acme_revoke_cert_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_revoke_cert: #{e}"
end
```

#### Using the pki_write_roles_role_acme_revoke_cert_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> pki_write_roles_role_acme_revoke_cert_with_http_info(role, pki_mount_path, pki_write_roles_role_acme_revoke_cert_request)

```ruby
begin
  
  data, status_code, headers = api_instance.pki_write_roles_role_acme_revoke_cert_with_http_info(role, pki_mount_path, pki_write_roles_role_acme_revoke_cert_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->pki_write_roles_role_acme_revoke_cert_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role for the acme request |  |
| **pki_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;pki&#39;] |
| **pki_write_roles_role_acme_revoke_cert_request** | [**PkiWriteRolesRoleAcmeRevokeCertRequest**](PkiWriteRolesRoleAcmeRevokeCertRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## rabbit_mq_configure_connection

> rabbit_mq_configure_connection(rabbitmq_mount_path, rabbit_mq_configure_connection_request)

Configure the connection URI, username, and password to talk to RabbitMQ management HTTP API.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
rabbitmq_mount_path = 'rabbitmq_mount_path_example' # String | Path that the backend was mounted at
rabbit_mq_configure_connection_request = OpenbaoClient::RabbitMqConfigureConnectionRequest.new # RabbitMqConfigureConnectionRequest | 

begin
  # Configure the connection URI, username, and password to talk to RabbitMQ management HTTP API.
  api_instance.rabbit_mq_configure_connection(rabbitmq_mount_path, rabbit_mq_configure_connection_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_configure_connection: #{e}"
end
```

#### Using the rabbit_mq_configure_connection_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rabbit_mq_configure_connection_with_http_info(rabbitmq_mount_path, rabbit_mq_configure_connection_request)

```ruby
begin
  # Configure the connection URI, username, and password to talk to RabbitMQ management HTTP API.
  data, status_code, headers = api_instance.rabbit_mq_configure_connection_with_http_info(rabbitmq_mount_path, rabbit_mq_configure_connection_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_configure_connection_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **rabbitmq_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;rabbitmq&#39;] |
| **rabbit_mq_configure_connection_request** | [**RabbitMqConfigureConnectionRequest**](RabbitMqConfigureConnectionRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## rabbit_mq_configure_lease

> rabbit_mq_configure_lease(rabbitmq_mount_path, rabbit_mq_configure_lease_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
rabbitmq_mount_path = 'rabbitmq_mount_path_example' # String | Path that the backend was mounted at
rabbit_mq_configure_lease_request = OpenbaoClient::RabbitMqConfigureLeaseRequest.new # RabbitMqConfigureLeaseRequest | 

begin
  
  api_instance.rabbit_mq_configure_lease(rabbitmq_mount_path, rabbit_mq_configure_lease_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_configure_lease: #{e}"
end
```

#### Using the rabbit_mq_configure_lease_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rabbit_mq_configure_lease_with_http_info(rabbitmq_mount_path, rabbit_mq_configure_lease_request)

```ruby
begin
  
  data, status_code, headers = api_instance.rabbit_mq_configure_lease_with_http_info(rabbitmq_mount_path, rabbit_mq_configure_lease_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_configure_lease_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **rabbitmq_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;rabbitmq&#39;] |
| **rabbit_mq_configure_lease_request** | [**RabbitMqConfigureLeaseRequest**](RabbitMqConfigureLeaseRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## rabbit_mq_delete_role

> rabbit_mq_delete_role(name, rabbitmq_mount_path)

Manage the roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
rabbitmq_mount_path = 'rabbitmq_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage the roles that can be created with this backend.
  api_instance.rabbit_mq_delete_role(name, rabbitmq_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_delete_role: #{e}"
end
```

#### Using the rabbit_mq_delete_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rabbit_mq_delete_role_with_http_info(name, rabbitmq_mount_path)

```ruby
begin
  # Manage the roles that can be created with this backend.
  data, status_code, headers = api_instance.rabbit_mq_delete_role_with_http_info(name, rabbitmq_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_delete_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **rabbitmq_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;rabbitmq&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## rabbit_mq_list_roles

> rabbit_mq_list_roles(rabbitmq_mount_path, list)

Manage the roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
rabbitmq_mount_path = 'rabbitmq_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Manage the roles that can be created with this backend.
  api_instance.rabbit_mq_list_roles(rabbitmq_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_list_roles: #{e}"
end
```

#### Using the rabbit_mq_list_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rabbit_mq_list_roles_with_http_info(rabbitmq_mount_path, list)

```ruby
begin
  # Manage the roles that can be created with this backend.
  data, status_code, headers = api_instance.rabbit_mq_list_roles_with_http_info(rabbitmq_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_list_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **rabbitmq_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;rabbitmq&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## rabbit_mq_read_lease_configuration

> rabbit_mq_read_lease_configuration(rabbitmq_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
rabbitmq_mount_path = 'rabbitmq_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.rabbit_mq_read_lease_configuration(rabbitmq_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_read_lease_configuration: #{e}"
end
```

#### Using the rabbit_mq_read_lease_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rabbit_mq_read_lease_configuration_with_http_info(rabbitmq_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.rabbit_mq_read_lease_configuration_with_http_info(rabbitmq_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_read_lease_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **rabbitmq_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;rabbitmq&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## rabbit_mq_read_role

> rabbit_mq_read_role(name, rabbitmq_mount_path)

Manage the roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
rabbitmq_mount_path = 'rabbitmq_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage the roles that can be created with this backend.
  api_instance.rabbit_mq_read_role(name, rabbitmq_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_read_role: #{e}"
end
```

#### Using the rabbit_mq_read_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rabbit_mq_read_role_with_http_info(name, rabbitmq_mount_path)

```ruby
begin
  # Manage the roles that can be created with this backend.
  data, status_code, headers = api_instance.rabbit_mq_read_role_with_http_info(name, rabbitmq_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_read_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **rabbitmq_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;rabbitmq&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## rabbit_mq_request_credentials

> rabbit_mq_request_credentials(name, rabbitmq_mount_path)

Request RabbitMQ credentials for a certain role.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
rabbitmq_mount_path = 'rabbitmq_mount_path_example' # String | Path that the backend was mounted at

begin
  # Request RabbitMQ credentials for a certain role.
  api_instance.rabbit_mq_request_credentials(name, rabbitmq_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_request_credentials: #{e}"
end
```

#### Using the rabbit_mq_request_credentials_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rabbit_mq_request_credentials_with_http_info(name, rabbitmq_mount_path)

```ruby
begin
  # Request RabbitMQ credentials for a certain role.
  data, status_code, headers = api_instance.rabbit_mq_request_credentials_with_http_info(name, rabbitmq_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_request_credentials_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **rabbitmq_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;rabbitmq&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## rabbit_mq_write_role

> rabbit_mq_write_role(name, rabbitmq_mount_path, rabbit_mq_write_role_request)

Manage the roles that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the role.
rabbitmq_mount_path = 'rabbitmq_mount_path_example' # String | Path that the backend was mounted at
rabbit_mq_write_role_request = OpenbaoClient::RabbitMqWriteRoleRequest.new # RabbitMqWriteRoleRequest | 

begin
  # Manage the roles that can be created with this backend.
  api_instance.rabbit_mq_write_role(name, rabbitmq_mount_path, rabbit_mq_write_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_write_role: #{e}"
end
```

#### Using the rabbit_mq_write_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> rabbit_mq_write_role_with_http_info(name, rabbitmq_mount_path, rabbit_mq_write_role_request)

```ruby
begin
  # Manage the roles that can be created with this backend.
  data, status_code, headers = api_instance.rabbit_mq_write_role_with_http_info(name, rabbitmq_mount_path, rabbit_mq_write_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->rabbit_mq_write_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **rabbitmq_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;rabbitmq&#39;] |
| **rabbit_mq_write_role_request** | [**RabbitMqWriteRoleRequest**](RabbitMqWriteRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ssh_configure_ca

> ssh_configure_ca(ssh_mount_path, ssh_configure_ca_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at
ssh_configure_ca_request = OpenbaoClient::SshConfigureCaRequest.new # SshConfigureCaRequest | 

begin
  
  api_instance.ssh_configure_ca(ssh_mount_path, ssh_configure_ca_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_configure_ca: #{e}"
end
```

#### Using the ssh_configure_ca_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_configure_ca_with_http_info(ssh_mount_path, ssh_configure_ca_request)

```ruby
begin
  
  data, status_code, headers = api_instance.ssh_configure_ca_with_http_info(ssh_mount_path, ssh_configure_ca_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_configure_ca_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |
| **ssh_configure_ca_request** | [**SshConfigureCaRequest**](SshConfigureCaRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ssh_configure_zero_address

> ssh_configure_zero_address(ssh_mount_path, ssh_configure_zero_address_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at
ssh_configure_zero_address_request = OpenbaoClient::SshConfigureZeroAddressRequest.new # SshConfigureZeroAddressRequest | 

begin
  
  api_instance.ssh_configure_zero_address(ssh_mount_path, ssh_configure_zero_address_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_configure_zero_address: #{e}"
end
```

#### Using the ssh_configure_zero_address_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_configure_zero_address_with_http_info(ssh_mount_path, ssh_configure_zero_address_request)

```ruby
begin
  
  data, status_code, headers = api_instance.ssh_configure_zero_address_with_http_info(ssh_mount_path, ssh_configure_zero_address_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_configure_zero_address_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |
| **ssh_configure_zero_address_request** | [**SshConfigureZeroAddressRequest**](SshConfigureZeroAddressRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ssh_delete_ca_configuration

> ssh_delete_ca_configuration(ssh_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ssh_delete_ca_configuration(ssh_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_delete_ca_configuration: #{e}"
end
```

#### Using the ssh_delete_ca_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_delete_ca_configuration_with_http_info(ssh_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ssh_delete_ca_configuration_with_http_info(ssh_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_delete_ca_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ssh_delete_role

> ssh_delete_role(role, ssh_mount_path)

Manage the 'roles' that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | [Required for all types] Name of the role being created.
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage the 'roles' that can be created with this backend.
  api_instance.ssh_delete_role(role, ssh_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_delete_role: #{e}"
end
```

#### Using the ssh_delete_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_delete_role_with_http_info(role, ssh_mount_path)

```ruby
begin
  # Manage the 'roles' that can be created with this backend.
  data, status_code, headers = api_instance.ssh_delete_role_with_http_info(role, ssh_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_delete_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | [Required for all types] Name of the role being created. |  |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ssh_delete_zero_address_configuration

> ssh_delete_zero_address_configuration(ssh_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ssh_delete_zero_address_configuration(ssh_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_delete_zero_address_configuration: #{e}"
end
```

#### Using the ssh_delete_zero_address_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_delete_zero_address_configuration_with_http_info(ssh_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ssh_delete_zero_address_configuration_with_http_info(ssh_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_delete_zero_address_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ssh_generate_credentials

> ssh_generate_credentials(role, ssh_mount_path, ssh_generate_credentials_request)

Creates a credential for establishing SSH connection with the remote host.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | [Required] Name of the role
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at
ssh_generate_credentials_request = OpenbaoClient::SshGenerateCredentialsRequest.new # SshGenerateCredentialsRequest | 

begin
  # Creates a credential for establishing SSH connection with the remote host.
  api_instance.ssh_generate_credentials(role, ssh_mount_path, ssh_generate_credentials_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_generate_credentials: #{e}"
end
```

#### Using the ssh_generate_credentials_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_generate_credentials_with_http_info(role, ssh_mount_path, ssh_generate_credentials_request)

```ruby
begin
  # Creates a credential for establishing SSH connection with the remote host.
  data, status_code, headers = api_instance.ssh_generate_credentials_with_http_info(role, ssh_mount_path, ssh_generate_credentials_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_generate_credentials_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | [Required] Name of the role |  |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |
| **ssh_generate_credentials_request** | [**SshGenerateCredentialsRequest**](SshGenerateCredentialsRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ssh_issue_certificate

> ssh_issue_certificate(role, ssh_mount_path, ssh_issue_certificate_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role with configuration for this request.
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at
ssh_issue_certificate_request = OpenbaoClient::SshIssueCertificateRequest.new # SshIssueCertificateRequest | 

begin
  
  api_instance.ssh_issue_certificate(role, ssh_mount_path, ssh_issue_certificate_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_issue_certificate: #{e}"
end
```

#### Using the ssh_issue_certificate_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_issue_certificate_with_http_info(role, ssh_mount_path, ssh_issue_certificate_request)

```ruby
begin
  
  data, status_code, headers = api_instance.ssh_issue_certificate_with_http_info(role, ssh_mount_path, ssh_issue_certificate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_issue_certificate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role with configuration for this request. |  |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |
| **ssh_issue_certificate_request** | [**SshIssueCertificateRequest**](SshIssueCertificateRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ssh_list_roles

> ssh_list_roles(ssh_mount_path, list)

Manage the 'roles' that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Manage the 'roles' that can be created with this backend.
  api_instance.ssh_list_roles(ssh_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_list_roles: #{e}"
end
```

#### Using the ssh_list_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_list_roles_with_http_info(ssh_mount_path, list)

```ruby
begin
  # Manage the 'roles' that can be created with this backend.
  data, status_code, headers = api_instance.ssh_list_roles_with_http_info(ssh_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_list_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ssh_list_roles_by_ip

> ssh_list_roles_by_ip(ssh_mount_path, ssh_list_roles_by_ip_request)

List all the roles associated with the given IP address.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at
ssh_list_roles_by_ip_request = OpenbaoClient::SshListRolesByIpRequest.new # SshListRolesByIpRequest | 

begin
  # List all the roles associated with the given IP address.
  api_instance.ssh_list_roles_by_ip(ssh_mount_path, ssh_list_roles_by_ip_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_list_roles_by_ip: #{e}"
end
```

#### Using the ssh_list_roles_by_ip_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_list_roles_by_ip_with_http_info(ssh_mount_path, ssh_list_roles_by_ip_request)

```ruby
begin
  # List all the roles associated with the given IP address.
  data, status_code, headers = api_instance.ssh_list_roles_by_ip_with_http_info(ssh_mount_path, ssh_list_roles_by_ip_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_list_roles_by_ip_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |
| **ssh_list_roles_by_ip_request** | [**SshListRolesByIpRequest**](SshListRolesByIpRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ssh_read_ca_configuration

> ssh_read_ca_configuration(ssh_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ssh_read_ca_configuration(ssh_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_read_ca_configuration: #{e}"
end
```

#### Using the ssh_read_ca_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_read_ca_configuration_with_http_info(ssh_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ssh_read_ca_configuration_with_http_info(ssh_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_read_ca_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ssh_read_public_key

> ssh_read_public_key(ssh_mount_path)

Retrieve the public key.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at

begin
  # Retrieve the public key.
  api_instance.ssh_read_public_key(ssh_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_read_public_key: #{e}"
end
```

#### Using the ssh_read_public_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_read_public_key_with_http_info(ssh_mount_path)

```ruby
begin
  # Retrieve the public key.
  data, status_code, headers = api_instance.ssh_read_public_key_with_http_info(ssh_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_read_public_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ssh_read_role

> ssh_read_role(role, ssh_mount_path)

Manage the 'roles' that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | [Required for all types] Name of the role being created.
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage the 'roles' that can be created with this backend.
  api_instance.ssh_read_role(role, ssh_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_read_role: #{e}"
end
```

#### Using the ssh_read_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_read_role_with_http_info(role, ssh_mount_path)

```ruby
begin
  # Manage the 'roles' that can be created with this backend.
  data, status_code, headers = api_instance.ssh_read_role_with_http_info(role, ssh_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_read_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | [Required for all types] Name of the role being created. |  |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ssh_read_zero_address_configuration

> ssh_read_zero_address_configuration(ssh_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ssh_read_zero_address_configuration(ssh_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_read_zero_address_configuration: #{e}"
end
```

#### Using the ssh_read_zero_address_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_read_zero_address_configuration_with_http_info(ssh_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ssh_read_zero_address_configuration_with_http_info(ssh_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_read_zero_address_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ssh_sign_certificate

> ssh_sign_certificate(role, ssh_mount_path, ssh_sign_certificate_request)

Request signing an SSH key using a certain role with the provided details.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | The desired role with configuration for this request.
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at
ssh_sign_certificate_request = OpenbaoClient::SshSignCertificateRequest.new # SshSignCertificateRequest | 

begin
  # Request signing an SSH key using a certain role with the provided details.
  api_instance.ssh_sign_certificate(role, ssh_mount_path, ssh_sign_certificate_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_sign_certificate: #{e}"
end
```

#### Using the ssh_sign_certificate_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_sign_certificate_with_http_info(role, ssh_mount_path, ssh_sign_certificate_request)

```ruby
begin
  # Request signing an SSH key using a certain role with the provided details.
  data, status_code, headers = api_instance.ssh_sign_certificate_with_http_info(role, ssh_mount_path, ssh_sign_certificate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_sign_certificate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | The desired role with configuration for this request. |  |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |
| **ssh_sign_certificate_request** | [**SshSignCertificateRequest**](SshSignCertificateRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ssh_tidy_dynamic_host_keys

> ssh_tidy_dynamic_host_keys(ssh_mount_path)

This endpoint removes the stored host keys used for the removed Dynamic Key feature, if present.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at

begin
  # This endpoint removes the stored host keys used for the removed Dynamic Key feature, if present.
  api_instance.ssh_tidy_dynamic_host_keys(ssh_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_tidy_dynamic_host_keys: #{e}"
end
```

#### Using the ssh_tidy_dynamic_host_keys_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_tidy_dynamic_host_keys_with_http_info(ssh_mount_path)

```ruby
begin
  # This endpoint removes the stored host keys used for the removed Dynamic Key feature, if present.
  data, status_code, headers = api_instance.ssh_tidy_dynamic_host_keys_with_http_info(ssh_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_tidy_dynamic_host_keys_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ssh_verify_otp

> ssh_verify_otp(ssh_mount_path, ssh_verify_otp_request)

Validate the OTP provided by OpenBao SSH Agent.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at
ssh_verify_otp_request = OpenbaoClient::SshVerifyOtpRequest.new # SshVerifyOtpRequest | 

begin
  # Validate the OTP provided by OpenBao SSH Agent.
  api_instance.ssh_verify_otp(ssh_mount_path, ssh_verify_otp_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_verify_otp: #{e}"
end
```

#### Using the ssh_verify_otp_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_verify_otp_with_http_info(ssh_mount_path, ssh_verify_otp_request)

```ruby
begin
  # Validate the OTP provided by OpenBao SSH Agent.
  data, status_code, headers = api_instance.ssh_verify_otp_with_http_info(ssh_mount_path, ssh_verify_otp_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_verify_otp_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |
| **ssh_verify_otp_request** | [**SshVerifyOtpRequest**](SshVerifyOtpRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ssh_write_role

> ssh_write_role(role, ssh_mount_path, ssh_write_role_request)

Manage the 'roles' that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
role = 'role_example' # String | [Required for all types] Name of the role being created.
ssh_mount_path = 'ssh_mount_path_example' # String | Path that the backend was mounted at
ssh_write_role_request = OpenbaoClient::SshWriteRoleRequest.new # SshWriteRoleRequest | 

begin
  # Manage the 'roles' that can be created with this backend.
  api_instance.ssh_write_role(role, ssh_mount_path, ssh_write_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_write_role: #{e}"
end
```

#### Using the ssh_write_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ssh_write_role_with_http_info(role, ssh_mount_path, ssh_write_role_request)

```ruby
begin
  # Manage the 'roles' that can be created with this backend.
  data, status_code, headers = api_instance.ssh_write_role_with_http_info(role, ssh_mount_path, ssh_write_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->ssh_write_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role** | **String** | [Required for all types] Name of the role being created. |  |
| **ssh_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ssh&#39;] |
| **ssh_write_role_request** | [**SshWriteRoleRequest**](SshWriteRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## totp_create_key

> totp_create_key(name, totp_mount_path, totp_create_key_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key.
totp_mount_path = 'totp_mount_path_example' # String | Path that the backend was mounted at
totp_create_key_request = OpenbaoClient::TotpCreateKeyRequest.new # TotpCreateKeyRequest | 

begin
  
  api_instance.totp_create_key(name, totp_mount_path, totp_create_key_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_create_key: #{e}"
end
```

#### Using the totp_create_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> totp_create_key_with_http_info(name, totp_mount_path, totp_create_key_request)

```ruby
begin
  
  data, status_code, headers = api_instance.totp_create_key_with_http_info(name, totp_mount_path, totp_create_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_create_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key. |  |
| **totp_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;totp&#39;] |
| **totp_create_key_request** | [**TotpCreateKeyRequest**](TotpCreateKeyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## totp_delete_key

> totp_delete_key(name, totp_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key.
totp_mount_path = 'totp_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.totp_delete_key(name, totp_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_delete_key: #{e}"
end
```

#### Using the totp_delete_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> totp_delete_key_with_http_info(name, totp_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.totp_delete_key_with_http_info(name, totp_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_delete_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key. |  |
| **totp_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;totp&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## totp_generate_code

> totp_generate_code(name, totp_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key.
totp_mount_path = 'totp_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.totp_generate_code(name, totp_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_generate_code: #{e}"
end
```

#### Using the totp_generate_code_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> totp_generate_code_with_http_info(name, totp_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.totp_generate_code_with_http_info(name, totp_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_generate_code_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key. |  |
| **totp_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;totp&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## totp_list_keys

> totp_list_keys(totp_mount_path, list)

Manage the keys that can be created with this backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
totp_mount_path = 'totp_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Manage the keys that can be created with this backend.
  api_instance.totp_list_keys(totp_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_list_keys: #{e}"
end
```

#### Using the totp_list_keys_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> totp_list_keys_with_http_info(totp_mount_path, list)

```ruby
begin
  # Manage the keys that can be created with this backend.
  data, status_code, headers = api_instance.totp_list_keys_with_http_info(totp_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_list_keys_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **totp_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;totp&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## totp_read_key

> totp_read_key(name, totp_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key.
totp_mount_path = 'totp_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.totp_read_key(name, totp_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_read_key: #{e}"
end
```

#### Using the totp_read_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> totp_read_key_with_http_info(name, totp_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.totp_read_key_with_http_info(name, totp_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_read_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key. |  |
| **totp_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;totp&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## totp_validate_code

> totp_validate_code(name, totp_mount_path, totp_validate_code_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key.
totp_mount_path = 'totp_mount_path_example' # String | Path that the backend was mounted at
totp_validate_code_request = OpenbaoClient::TotpValidateCodeRequest.new # TotpValidateCodeRequest | 

begin
  
  api_instance.totp_validate_code(name, totp_mount_path, totp_validate_code_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_validate_code: #{e}"
end
```

#### Using the totp_validate_code_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> totp_validate_code_with_http_info(name, totp_mount_path, totp_validate_code_request)

```ruby
begin
  
  data, status_code, headers = api_instance.totp_validate_code_with_http_info(name, totp_mount_path, totp_validate_code_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->totp_validate_code_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key. |  |
| **totp_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;totp&#39;] |
| **totp_validate_code_request** | [**TotpValidateCodeRequest**](TotpValidateCodeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_back_up_key

> transit_back_up_key(name, transit_mount_path)

Backup the named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  # Backup the named key
  api_instance.transit_back_up_key(name, transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_back_up_key: #{e}"
end
```

#### Using the transit_back_up_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_back_up_key_with_http_info(name, transit_mount_path)

```ruby
begin
  # Backup the named key
  data, status_code, headers = api_instance.transit_back_up_key_with_http_info(name, transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_back_up_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_byok_key

> transit_byok_key(destination, source, transit_mount_path)

Securely export named encryption or signing key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
destination = 'destination_example' # String | Destination key to export to; usually the public wrapping key of another Transit instance.
source = 'source_example' # String | Source key to export; could be any present key within Transit.
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  # Securely export named encryption or signing key
  api_instance.transit_byok_key(destination, source, transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_byok_key: #{e}"
end
```

#### Using the transit_byok_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_byok_key_with_http_info(destination, source, transit_mount_path)

```ruby
begin
  # Securely export named encryption or signing key
  data, status_code, headers = api_instance.transit_byok_key_with_http_info(destination, source, transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_byok_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **destination** | **String** | Destination key to export to; usually the public wrapping key of another Transit instance. |  |
| **source** | **String** | Source key to export; could be any present key within Transit. |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_byok_key_version

> transit_byok_key_version(destination, source, version, transit_mount_path)

Securely export named encryption or signing key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
destination = 'destination_example' # String | Destination key to export to; usually the public wrapping key of another Transit instance.
source = 'source_example' # String | Source key to export; could be any present key within Transit.
version = 'version_example' # String | Optional version of the key to export, else all key versions are exported.
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  # Securely export named encryption or signing key
  api_instance.transit_byok_key_version(destination, source, version, transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_byok_key_version: #{e}"
end
```

#### Using the transit_byok_key_version_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_byok_key_version_with_http_info(destination, source, version, transit_mount_path)

```ruby
begin
  # Securely export named encryption or signing key
  data, status_code, headers = api_instance.transit_byok_key_version_with_http_info(destination, source, version, transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_byok_key_version_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **destination** | **String** | Destination key to export to; usually the public wrapping key of another Transit instance. |  |
| **source** | **String** | Source key to export; could be any present key within Transit. |  |
| **version** | **String** | Optional version of the key to export, else all key versions are exported. |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_configure_cache

> transit_configure_cache(transit_mount_path, transit_configure_cache_request)

Configures a new cache of the specified size

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_configure_cache_request = OpenbaoClient::TransitConfigureCacheRequest.new # TransitConfigureCacheRequest | 

begin
  # Configures a new cache of the specified size
  api_instance.transit_configure_cache(transit_mount_path, transit_configure_cache_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_configure_cache: #{e}"
end
```

#### Using the transit_configure_cache_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_configure_cache_with_http_info(transit_mount_path, transit_configure_cache_request)

```ruby
begin
  # Configures a new cache of the specified size
  data, status_code, headers = api_instance.transit_configure_cache_with_http_info(transit_mount_path, transit_configure_cache_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_configure_cache_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_configure_cache_request** | [**TransitConfigureCacheRequest**](TransitConfigureCacheRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_configure_key

> transit_configure_key(name, transit_mount_path, transit_configure_key_request)

Configure a named encryption key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_configure_key_request = OpenbaoClient::TransitConfigureKeyRequest.new # TransitConfigureKeyRequest | 

begin
  # Configure a named encryption key
  api_instance.transit_configure_key(name, transit_mount_path, transit_configure_key_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_configure_key: #{e}"
end
```

#### Using the transit_configure_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_configure_key_with_http_info(name, transit_mount_path, transit_configure_key_request)

```ruby
begin
  # Configure a named encryption key
  data, status_code, headers = api_instance.transit_configure_key_with_http_info(name, transit_mount_path, transit_configure_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_configure_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_configure_key_request** | [**TransitConfigureKeyRequest**](TransitConfigureKeyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_configure_keys

> transit_configure_keys(transit_mount_path, transit_configure_keys_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_configure_keys_request = OpenbaoClient::TransitConfigureKeysRequest.new # TransitConfigureKeysRequest | 

begin
  
  api_instance.transit_configure_keys(transit_mount_path, transit_configure_keys_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_configure_keys: #{e}"
end
```

#### Using the transit_configure_keys_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_configure_keys_with_http_info(transit_mount_path, transit_configure_keys_request)

```ruby
begin
  
  data, status_code, headers = api_instance.transit_configure_keys_with_http_info(transit_mount_path, transit_configure_keys_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_configure_keys_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_configure_keys_request** | [**TransitConfigureKeysRequest**](TransitConfigureKeysRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_create_key

> transit_create_key(name, transit_mount_path, transit_create_key_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_create_key_request = OpenbaoClient::TransitCreateKeyRequest.new # TransitCreateKeyRequest | 

begin
  
  api_instance.transit_create_key(name, transit_mount_path, transit_create_key_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_create_key: #{e}"
end
```

#### Using the transit_create_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_create_key_with_http_info(name, transit_mount_path, transit_create_key_request)

```ruby
begin
  
  data, status_code, headers = api_instance.transit_create_key_with_http_info(name, transit_mount_path, transit_create_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_create_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_create_key_request** | [**TransitCreateKeyRequest**](TransitCreateKeyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_decrypt

> transit_decrypt(name, transit_mount_path, transit_decrypt_request)

Decrypt a ciphertext value using a named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_decrypt_request = OpenbaoClient::TransitDecryptRequest.new # TransitDecryptRequest | 

begin
  # Decrypt a ciphertext value using a named key
  api_instance.transit_decrypt(name, transit_mount_path, transit_decrypt_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_decrypt: #{e}"
end
```

#### Using the transit_decrypt_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_decrypt_with_http_info(name, transit_mount_path, transit_decrypt_request)

```ruby
begin
  # Decrypt a ciphertext value using a named key
  data, status_code, headers = api_instance.transit_decrypt_with_http_info(name, transit_mount_path, transit_decrypt_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_decrypt_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_decrypt_request** | [**TransitDecryptRequest**](TransitDecryptRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_delete_key

> transit_delete_key(name, transit_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.transit_delete_key(name, transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_delete_key: #{e}"
end
```

#### Using the transit_delete_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_delete_key_with_http_info(name, transit_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.transit_delete_key_with_http_info(name, transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_delete_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_encrypt

> transit_encrypt(name, transit_mount_path, transit_encrypt_request)

Encrypt a plaintext value or a batch of plaintext blocks using a named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_encrypt_request = OpenbaoClient::TransitEncryptRequest.new # TransitEncryptRequest | 

begin
  # Encrypt a plaintext value or a batch of plaintext blocks using a named key
  api_instance.transit_encrypt(name, transit_mount_path, transit_encrypt_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_encrypt: #{e}"
end
```

#### Using the transit_encrypt_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_encrypt_with_http_info(name, transit_mount_path, transit_encrypt_request)

```ruby
begin
  # Encrypt a plaintext value or a batch of plaintext blocks using a named key
  data, status_code, headers = api_instance.transit_encrypt_with_http_info(name, transit_mount_path, transit_encrypt_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_encrypt_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_encrypt_request** | [**TransitEncryptRequest**](TransitEncryptRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_export_key

> transit_export_key(name, type, transit_mount_path)

Export named encryption or signing key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
type = 'type_example' # String | Type of key to export (encryption-key, signing-key, hmac-key, public-key)
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  # Export named encryption or signing key
  api_instance.transit_export_key(name, type, transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_export_key: #{e}"
end
```

#### Using the transit_export_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_export_key_with_http_info(name, type, transit_mount_path)

```ruby
begin
  # Export named encryption or signing key
  data, status_code, headers = api_instance.transit_export_key_with_http_info(name, type, transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_export_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **type** | **String** | Type of key to export (encryption-key, signing-key, hmac-key, public-key) |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_export_key_version

> transit_export_key_version(name, type, version, transit_mount_path)

Export named encryption or signing key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
type = 'type_example' # String | Type of key to export (encryption-key, signing-key, hmac-key, public-key)
version = 'version_example' # String | Version of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  # Export named encryption or signing key
  api_instance.transit_export_key_version(name, type, version, transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_export_key_version: #{e}"
end
```

#### Using the transit_export_key_version_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_export_key_version_with_http_info(name, type, version, transit_mount_path)

```ruby
begin
  # Export named encryption or signing key
  data, status_code, headers = api_instance.transit_export_key_version_with_http_info(name, type, version, transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_export_key_version_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **type** | **String** | Type of key to export (encryption-key, signing-key, hmac-key, public-key) |  |
| **version** | **String** | Version of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_generate_data_key

> transit_generate_data_key(name, plaintext, transit_mount_path, transit_generate_data_key_request)

Generate a data key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | The backend key used for encrypting the data key
plaintext = 'plaintext_example' # String | \"plaintext\" will return the key in both plaintext and ciphertext; \"wrapped\" will return the ciphertext only.
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_generate_data_key_request = OpenbaoClient::TransitGenerateDataKeyRequest.new # TransitGenerateDataKeyRequest | 

begin
  # Generate a data key
  api_instance.transit_generate_data_key(name, plaintext, transit_mount_path, transit_generate_data_key_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_data_key: #{e}"
end
```

#### Using the transit_generate_data_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_generate_data_key_with_http_info(name, plaintext, transit_mount_path, transit_generate_data_key_request)

```ruby
begin
  # Generate a data key
  data, status_code, headers = api_instance.transit_generate_data_key_with_http_info(name, plaintext, transit_mount_path, transit_generate_data_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_data_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The backend key used for encrypting the data key |  |
| **plaintext** | **String** | \&quot;plaintext\&quot; will return the key in both plaintext and ciphertext; \&quot;wrapped\&quot; will return the ciphertext only. |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_generate_data_key_request** | [**TransitGenerateDataKeyRequest**](TransitGenerateDataKeyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_generate_hmac

> transit_generate_hmac(name, transit_mount_path, transit_generate_hmac_request)

Generate an HMAC for input data using the named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | The key to use for the HMAC function
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_generate_hmac_request = OpenbaoClient::TransitGenerateHmacRequest.new # TransitGenerateHmacRequest | 

begin
  # Generate an HMAC for input data using the named key
  api_instance.transit_generate_hmac(name, transit_mount_path, transit_generate_hmac_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_hmac: #{e}"
end
```

#### Using the transit_generate_hmac_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_generate_hmac_with_http_info(name, transit_mount_path, transit_generate_hmac_request)

```ruby
begin
  # Generate an HMAC for input data using the named key
  data, status_code, headers = api_instance.transit_generate_hmac_with_http_info(name, transit_mount_path, transit_generate_hmac_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_hmac_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The key to use for the HMAC function |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_generate_hmac_request** | [**TransitGenerateHmacRequest**](TransitGenerateHmacRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_generate_hmac_with_algorithm

> transit_generate_hmac_with_algorithm(name, urlalgorithm, transit_mount_path, transit_generate_hmac_with_algorithm_request)

Generate an HMAC for input data using the named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | The key to use for the HMAC function
urlalgorithm = 'urlalgorithm_example' # String | Algorithm to use (POST URL parameter)
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_generate_hmac_with_algorithm_request = OpenbaoClient::TransitGenerateHmacWithAlgorithmRequest.new # TransitGenerateHmacWithAlgorithmRequest | 

begin
  # Generate an HMAC for input data using the named key
  api_instance.transit_generate_hmac_with_algorithm(name, urlalgorithm, transit_mount_path, transit_generate_hmac_with_algorithm_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_hmac_with_algorithm: #{e}"
end
```

#### Using the transit_generate_hmac_with_algorithm_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_generate_hmac_with_algorithm_with_http_info(name, urlalgorithm, transit_mount_path, transit_generate_hmac_with_algorithm_request)

```ruby
begin
  # Generate an HMAC for input data using the named key
  data, status_code, headers = api_instance.transit_generate_hmac_with_algorithm_with_http_info(name, urlalgorithm, transit_mount_path, transit_generate_hmac_with_algorithm_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_hmac_with_algorithm_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The key to use for the HMAC function |  |
| **urlalgorithm** | **String** | Algorithm to use (POST URL parameter) |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_generate_hmac_with_algorithm_request** | [**TransitGenerateHmacWithAlgorithmRequest**](TransitGenerateHmacWithAlgorithmRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_generate_random

> transit_generate_random(transit_mount_path, transit_generate_random_request)

Generate random bytes

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_generate_random_request = OpenbaoClient::TransitGenerateRandomRequest.new # TransitGenerateRandomRequest | 

begin
  # Generate random bytes
  api_instance.transit_generate_random(transit_mount_path, transit_generate_random_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_random: #{e}"
end
```

#### Using the transit_generate_random_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_generate_random_with_http_info(transit_mount_path, transit_generate_random_request)

```ruby
begin
  # Generate random bytes
  data, status_code, headers = api_instance.transit_generate_random_with_http_info(transit_mount_path, transit_generate_random_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_random_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_generate_random_request** | [**TransitGenerateRandomRequest**](TransitGenerateRandomRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_generate_random_with_bytes

> transit_generate_random_with_bytes(urlbytes, transit_mount_path, transit_generate_random_with_bytes_request)

Generate random bytes

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
urlbytes = 'urlbytes_example' # String | The number of bytes to generate (POST URL parameter)
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_generate_random_with_bytes_request = OpenbaoClient::TransitGenerateRandomWithBytesRequest.new # TransitGenerateRandomWithBytesRequest | 

begin
  # Generate random bytes
  api_instance.transit_generate_random_with_bytes(urlbytes, transit_mount_path, transit_generate_random_with_bytes_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_random_with_bytes: #{e}"
end
```

#### Using the transit_generate_random_with_bytes_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_generate_random_with_bytes_with_http_info(urlbytes, transit_mount_path, transit_generate_random_with_bytes_request)

```ruby
begin
  # Generate random bytes
  data, status_code, headers = api_instance.transit_generate_random_with_bytes_with_http_info(urlbytes, transit_mount_path, transit_generate_random_with_bytes_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_random_with_bytes_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **urlbytes** | **String** | The number of bytes to generate (POST URL parameter) |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_generate_random_with_bytes_request** | [**TransitGenerateRandomWithBytesRequest**](TransitGenerateRandomWithBytesRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_generate_random_with_source

> transit_generate_random_with_source(source, transit_mount_path, transit_generate_random_with_source_request)

Generate random bytes

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
source = 'source_example' # String | Which system to source random data from, ether \"platform\", \"seal\", or \"all\".
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_generate_random_with_source_request = OpenbaoClient::TransitGenerateRandomWithSourceRequest.new # TransitGenerateRandomWithSourceRequest | 

begin
  # Generate random bytes
  api_instance.transit_generate_random_with_source(source, transit_mount_path, transit_generate_random_with_source_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_random_with_source: #{e}"
end
```

#### Using the transit_generate_random_with_source_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_generate_random_with_source_with_http_info(source, transit_mount_path, transit_generate_random_with_source_request)

```ruby
begin
  # Generate random bytes
  data, status_code, headers = api_instance.transit_generate_random_with_source_with_http_info(source, transit_mount_path, transit_generate_random_with_source_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_random_with_source_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **source** | **String** | Which system to source random data from, ether \&quot;platform\&quot;, \&quot;seal\&quot;, or \&quot;all\&quot;. | [default to &#39;platform&#39;] |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_generate_random_with_source_request** | [**TransitGenerateRandomWithSourceRequest**](TransitGenerateRandomWithSourceRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_generate_random_with_source_and_bytes

> transit_generate_random_with_source_and_bytes(source, urlbytes, transit_mount_path, transit_generate_random_with_source_and_bytes_request)

Generate random bytes

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
source = 'source_example' # String | Which system to source random data from, ether \"platform\", \"seal\", or \"all\".
urlbytes = 'urlbytes_example' # String | The number of bytes to generate (POST URL parameter)
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_generate_random_with_source_and_bytes_request = OpenbaoClient::TransitGenerateRandomWithSourceAndBytesRequest.new # TransitGenerateRandomWithSourceAndBytesRequest | 

begin
  # Generate random bytes
  api_instance.transit_generate_random_with_source_and_bytes(source, urlbytes, transit_mount_path, transit_generate_random_with_source_and_bytes_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_random_with_source_and_bytes: #{e}"
end
```

#### Using the transit_generate_random_with_source_and_bytes_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_generate_random_with_source_and_bytes_with_http_info(source, urlbytes, transit_mount_path, transit_generate_random_with_source_and_bytes_request)

```ruby
begin
  # Generate random bytes
  data, status_code, headers = api_instance.transit_generate_random_with_source_and_bytes_with_http_info(source, urlbytes, transit_mount_path, transit_generate_random_with_source_and_bytes_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_generate_random_with_source_and_bytes_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **source** | **String** | Which system to source random data from, ether \&quot;platform\&quot;, \&quot;seal\&quot;, or \&quot;all\&quot;. | [default to &#39;platform&#39;] |
| **urlbytes** | **String** | The number of bytes to generate (POST URL parameter) |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_generate_random_with_source_and_bytes_request** | [**TransitGenerateRandomWithSourceAndBytesRequest**](TransitGenerateRandomWithSourceAndBytesRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_hash

> transit_hash(transit_mount_path, transit_hash_request)

Generate a hash sum for input data

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_hash_request = OpenbaoClient::TransitHashRequest.new # TransitHashRequest | 

begin
  # Generate a hash sum for input data
  api_instance.transit_hash(transit_mount_path, transit_hash_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_hash: #{e}"
end
```

#### Using the transit_hash_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_hash_with_http_info(transit_mount_path, transit_hash_request)

```ruby
begin
  # Generate a hash sum for input data
  data, status_code, headers = api_instance.transit_hash_with_http_info(transit_mount_path, transit_hash_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_hash_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_hash_request** | [**TransitHashRequest**](TransitHashRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_hash_with_algorithm

> transit_hash_with_algorithm(urlalgorithm, transit_mount_path, transit_hash_with_algorithm_request)

Generate a hash sum for input data

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
urlalgorithm = 'urlalgorithm_example' # String | Algorithm to use (POST URL parameter)
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_hash_with_algorithm_request = OpenbaoClient::TransitHashWithAlgorithmRequest.new # TransitHashWithAlgorithmRequest | 

begin
  # Generate a hash sum for input data
  api_instance.transit_hash_with_algorithm(urlalgorithm, transit_mount_path, transit_hash_with_algorithm_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_hash_with_algorithm: #{e}"
end
```

#### Using the transit_hash_with_algorithm_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_hash_with_algorithm_with_http_info(urlalgorithm, transit_mount_path, transit_hash_with_algorithm_request)

```ruby
begin
  # Generate a hash sum for input data
  data, status_code, headers = api_instance.transit_hash_with_algorithm_with_http_info(urlalgorithm, transit_mount_path, transit_hash_with_algorithm_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_hash_with_algorithm_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **urlalgorithm** | **String** | Algorithm to use (POST URL parameter) |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_hash_with_algorithm_request** | [**TransitHashWithAlgorithmRequest**](TransitHashWithAlgorithmRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_import_key

> transit_import_key(name, transit_mount_path, transit_import_key_request)

Imports an externally-generated key into a new transit key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | The name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_import_key_request = OpenbaoClient::TransitImportKeyRequest.new # TransitImportKeyRequest | 

begin
  # Imports an externally-generated key into a new transit key
  api_instance.transit_import_key(name, transit_mount_path, transit_import_key_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_import_key: #{e}"
end
```

#### Using the transit_import_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_import_key_with_http_info(name, transit_mount_path, transit_import_key_request)

```ruby
begin
  # Imports an externally-generated key into a new transit key
  data, status_code, headers = api_instance.transit_import_key_with_http_info(name, transit_mount_path, transit_import_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_import_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_import_key_request** | [**TransitImportKeyRequest**](TransitImportKeyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_import_key_version

> transit_import_key_version(name, transit_mount_path, transit_import_key_version_request)

Imports an externally-generated key into an existing imported key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | The name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_import_key_version_request = OpenbaoClient::TransitImportKeyVersionRequest.new # TransitImportKeyVersionRequest | 

begin
  # Imports an externally-generated key into an existing imported key
  api_instance.transit_import_key_version(name, transit_mount_path, transit_import_key_version_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_import_key_version: #{e}"
end
```

#### Using the transit_import_key_version_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_import_key_version_with_http_info(name, transit_mount_path, transit_import_key_version_request)

```ruby
begin
  # Imports an externally-generated key into an existing imported key
  data, status_code, headers = api_instance.transit_import_key_version_with_http_info(name, transit_mount_path, transit_import_key_version_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_import_key_version_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_import_key_version_request** | [**TransitImportKeyVersionRequest**](TransitImportKeyVersionRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_list_keys

> transit_list_keys(transit_mount_path, list)

Managed named encryption keys

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Managed named encryption keys
  api_instance.transit_list_keys(transit_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_list_keys: #{e}"
end
```

#### Using the transit_list_keys_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_list_keys_with_http_info(transit_mount_path, list)

```ruby
begin
  # Managed named encryption keys
  data, status_code, headers = api_instance.transit_list_keys_with_http_info(transit_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_list_keys_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_read_cache_configuration

> transit_read_cache_configuration(transit_mount_path)

Returns the size of the active cache

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  # Returns the size of the active cache
  api_instance.transit_read_cache_configuration(transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_read_cache_configuration: #{e}"
end
```

#### Using the transit_read_cache_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_read_cache_configuration_with_http_info(transit_mount_path)

```ruby
begin
  # Returns the size of the active cache
  data, status_code, headers = api_instance.transit_read_cache_configuration_with_http_info(transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_read_cache_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_read_key

> transit_read_key(name, transit_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.transit_read_key(name, transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_read_key: #{e}"
end
```

#### Using the transit_read_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_read_key_with_http_info(name, transit_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.transit_read_key_with_http_info(name, transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_read_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_read_keys_configuration

> transit_read_keys_configuration(transit_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.transit_read_keys_configuration(transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_read_keys_configuration: #{e}"
end
```

#### Using the transit_read_keys_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_read_keys_configuration_with_http_info(transit_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.transit_read_keys_configuration_with_http_info(transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_read_keys_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_read_wrapping_key

> transit_read_wrapping_key(transit_mount_path)

Returns the public key to use for wrapping imported keys

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  # Returns the public key to use for wrapping imported keys
  api_instance.transit_read_wrapping_key(transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_read_wrapping_key: #{e}"
end
```

#### Using the transit_read_wrapping_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_read_wrapping_key_with_http_info(transit_mount_path)

```ruby
begin
  # Returns the public key to use for wrapping imported keys
  data, status_code, headers = api_instance.transit_read_wrapping_key_with_http_info(transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_read_wrapping_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_restore_and_rename_key

> transit_restore_and_rename_key(name, transit_mount_path, transit_restore_and_rename_key_request)

Restore the named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | If set, this will be the name of the restored key.
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_restore_and_rename_key_request = OpenbaoClient::TransitRestoreAndRenameKeyRequest.new # TransitRestoreAndRenameKeyRequest | 

begin
  # Restore the named key
  api_instance.transit_restore_and_rename_key(name, transit_mount_path, transit_restore_and_rename_key_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_restore_and_rename_key: #{e}"
end
```

#### Using the transit_restore_and_rename_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_restore_and_rename_key_with_http_info(name, transit_mount_path, transit_restore_and_rename_key_request)

```ruby
begin
  # Restore the named key
  data, status_code, headers = api_instance.transit_restore_and_rename_key_with_http_info(name, transit_mount_path, transit_restore_and_rename_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_restore_and_rename_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | If set, this will be the name of the restored key. |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_restore_and_rename_key_request** | [**TransitRestoreAndRenameKeyRequest**](TransitRestoreAndRenameKeyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_restore_key

> transit_restore_key(transit_mount_path, transit_restore_key_request)

Restore the named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_restore_key_request = OpenbaoClient::TransitRestoreKeyRequest.new # TransitRestoreKeyRequest | 

begin
  # Restore the named key
  api_instance.transit_restore_key(transit_mount_path, transit_restore_key_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_restore_key: #{e}"
end
```

#### Using the transit_restore_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_restore_key_with_http_info(transit_mount_path, transit_restore_key_request)

```ruby
begin
  # Restore the named key
  data, status_code, headers = api_instance.transit_restore_key_with_http_info(transit_mount_path, transit_restore_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_restore_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_restore_key_request** | [**TransitRestoreKeyRequest**](TransitRestoreKeyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_rewrap

> transit_rewrap(name, transit_mount_path, transit_rewrap_request)

Rewrap ciphertext

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_rewrap_request = OpenbaoClient::TransitRewrapRequest.new # TransitRewrapRequest | 

begin
  # Rewrap ciphertext
  api_instance.transit_rewrap(name, transit_mount_path, transit_rewrap_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_rewrap: #{e}"
end
```

#### Using the transit_rewrap_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_rewrap_with_http_info(name, transit_mount_path, transit_rewrap_request)

```ruby
begin
  # Rewrap ciphertext
  data, status_code, headers = api_instance.transit_rewrap_with_http_info(name, transit_mount_path, transit_rewrap_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_rewrap_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_rewrap_request** | [**TransitRewrapRequest**](TransitRewrapRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_rotate_key

> transit_rotate_key(name, transit_mount_path)

Rotate named encryption key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  # Rotate named encryption key
  api_instance.transit_rotate_key(name, transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_rotate_key: #{e}"
end
```

#### Using the transit_rotate_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_rotate_key_with_http_info(name, transit_mount_path)

```ruby
begin
  # Rotate named encryption key
  data, status_code, headers = api_instance.transit_rotate_key_with_http_info(name, transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_rotate_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_sign

> transit_sign(name, transit_mount_path, transit_sign_request)

Generate a signature for input data using the named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | The key to use
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_sign_request = OpenbaoClient::TransitSignRequest.new # TransitSignRequest | 

begin
  # Generate a signature for input data using the named key
  api_instance.transit_sign(name, transit_mount_path, transit_sign_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_sign: #{e}"
end
```

#### Using the transit_sign_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_sign_with_http_info(name, transit_mount_path, transit_sign_request)

```ruby
begin
  # Generate a signature for input data using the named key
  data, status_code, headers = api_instance.transit_sign_with_http_info(name, transit_mount_path, transit_sign_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_sign_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The key to use |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_sign_request** | [**TransitSignRequest**](TransitSignRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_sign_with_algorithm

> transit_sign_with_algorithm(name, urlalgorithm, transit_mount_path, transit_sign_with_algorithm_request)

Generate a signature for input data using the named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | The key to use
urlalgorithm = 'urlalgorithm_example' # String | Hash algorithm to use (POST URL parameter)
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_sign_with_algorithm_request = OpenbaoClient::TransitSignWithAlgorithmRequest.new # TransitSignWithAlgorithmRequest | 

begin
  # Generate a signature for input data using the named key
  api_instance.transit_sign_with_algorithm(name, urlalgorithm, transit_mount_path, transit_sign_with_algorithm_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_sign_with_algorithm: #{e}"
end
```

#### Using the transit_sign_with_algorithm_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_sign_with_algorithm_with_http_info(name, urlalgorithm, transit_mount_path, transit_sign_with_algorithm_request)

```ruby
begin
  # Generate a signature for input data using the named key
  data, status_code, headers = api_instance.transit_sign_with_algorithm_with_http_info(name, urlalgorithm, transit_mount_path, transit_sign_with_algorithm_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_sign_with_algorithm_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The key to use |  |
| **urlalgorithm** | **String** | Hash algorithm to use (POST URL parameter) |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_sign_with_algorithm_request** | [**TransitSignWithAlgorithmRequest**](TransitSignWithAlgorithmRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_soft_delete_key

> transit_soft_delete_key(name, transit_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.transit_soft_delete_key(name, transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_soft_delete_key: #{e}"
end
```

#### Using the transit_soft_delete_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_soft_delete_key_with_http_info(name, transit_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.transit_soft_delete_key_with_http_info(name, transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_soft_delete_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_soft_delete_restore_key

> transit_soft_delete_restore_key(name, transit_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.transit_soft_delete_restore_key(name, transit_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_soft_delete_restore_key: #{e}"
end
```

#### Using the transit_soft_delete_restore_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_soft_delete_restore_key_with_http_info(name, transit_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.transit_soft_delete_restore_key_with_http_info(name, transit_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_soft_delete_restore_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## transit_trim_key

> transit_trim_key(name, transit_mount_path, transit_trim_key_request)

Trim key versions of a named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | Name of the key
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_trim_key_request = OpenbaoClient::TransitTrimKeyRequest.new # TransitTrimKeyRequest | 

begin
  # Trim key versions of a named key
  api_instance.transit_trim_key(name, transit_mount_path, transit_trim_key_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_trim_key: #{e}"
end
```

#### Using the transit_trim_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_trim_key_with_http_info(name, transit_mount_path, transit_trim_key_request)

```ruby
begin
  # Trim key versions of a named key
  data, status_code, headers = api_instance.transit_trim_key_with_http_info(name, transit_mount_path, transit_trim_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_trim_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_trim_key_request** | [**TransitTrimKeyRequest**](TransitTrimKeyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_verify

> transit_verify(name, transit_mount_path, transit_verify_request)

Verify a signature or HMAC for input data created using the named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | The key to use
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_verify_request = OpenbaoClient::TransitVerifyRequest.new # TransitVerifyRequest | 

begin
  # Verify a signature or HMAC for input data created using the named key
  api_instance.transit_verify(name, transit_mount_path, transit_verify_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_verify: #{e}"
end
```

#### Using the transit_verify_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_verify_with_http_info(name, transit_mount_path, transit_verify_request)

```ruby
begin
  # Verify a signature or HMAC for input data created using the named key
  data, status_code, headers = api_instance.transit_verify_with_http_info(name, transit_mount_path, transit_verify_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_verify_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The key to use |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_verify_request** | [**TransitVerifyRequest**](TransitVerifyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## transit_verify_with_algorithm

> transit_verify_with_algorithm(name, urlalgorithm, transit_mount_path, transit_verify_with_algorithm_request)

Verify a signature or HMAC for input data created using the named key

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::SecretsApi.new
name = 'name_example' # String | The key to use
urlalgorithm = 'urlalgorithm_example' # String | Hash algorithm to use (POST URL parameter)
transit_mount_path = 'transit_mount_path_example' # String | Path that the backend was mounted at
transit_verify_with_algorithm_request = OpenbaoClient::TransitVerifyWithAlgorithmRequest.new # TransitVerifyWithAlgorithmRequest | 

begin
  # Verify a signature or HMAC for input data created using the named key
  api_instance.transit_verify_with_algorithm(name, urlalgorithm, transit_mount_path, transit_verify_with_algorithm_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_verify_with_algorithm: #{e}"
end
```

#### Using the transit_verify_with_algorithm_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> transit_verify_with_algorithm_with_http_info(name, urlalgorithm, transit_mount_path, transit_verify_with_algorithm_request)

```ruby
begin
  # Verify a signature or HMAC for input data created using the named key
  data, status_code, headers = api_instance.transit_verify_with_algorithm_with_http_info(name, urlalgorithm, transit_mount_path, transit_verify_with_algorithm_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling SecretsApi->transit_verify_with_algorithm_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The key to use |  |
| **urlalgorithm** | **String** | Hash algorithm to use (POST URL parameter) |  |
| **transit_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;transit&#39;] |
| **transit_verify_with_algorithm_request** | [**TransitVerifyWithAlgorithmRequest**](TransitVerifyWithAlgorithmRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined

