# OpenbaoClient::AuthApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**app_role_delete_bind_secret_id**](AuthApi.md#app_role_delete_bind_secret_id) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/bind-secret-id |  |
| [**app_role_delete_bound_cidr_list**](AuthApi.md#app_role_delete_bound_cidr_list) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/bound-cidr-list |  |
| [**app_role_delete_period**](AuthApi.md#app_role_delete_period) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/period |  |
| [**app_role_delete_policies**](AuthApi.md#app_role_delete_policies) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/policies |  |
| [**app_role_delete_role**](AuthApi.md#app_role_delete_role) | **DELETE** /auth/{approle_mount_path}/role/{role_name} |  |
| [**app_role_delete_secret_id_bound_cidrs**](AuthApi.md#app_role_delete_secret_id_bound_cidrs) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/secret-id-bound-cidrs |  |
| [**app_role_delete_secret_id_num_uses**](AuthApi.md#app_role_delete_secret_id_num_uses) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/secret-id-num-uses |  |
| [**app_role_delete_secret_id_ttl**](AuthApi.md#app_role_delete_secret_id_ttl) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/secret-id-ttl |  |
| [**app_role_delete_token_bound_cidrs**](AuthApi.md#app_role_delete_token_bound_cidrs) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/token-bound-cidrs |  |
| [**app_role_delete_token_max_ttl**](AuthApi.md#app_role_delete_token_max_ttl) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/token-max-ttl |  |
| [**app_role_delete_token_num_uses**](AuthApi.md#app_role_delete_token_num_uses) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/token-num-uses |  |
| [**app_role_delete_token_ttl**](AuthApi.md#app_role_delete_token_ttl) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/token-ttl |  |
| [**app_role_destroy_secret_id**](AuthApi.md#app_role_destroy_secret_id) | **POST** /auth/{approle_mount_path}/role/{role_name}/secret-id/destroy |  |
| [**app_role_destroy_secret_id2**](AuthApi.md#app_role_destroy_secret_id2) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/secret-id/destroy |  |
| [**app_role_destroy_secret_id_by_accessor**](AuthApi.md#app_role_destroy_secret_id_by_accessor) | **POST** /auth/{approle_mount_path}/role/{role_name}/secret-id-accessor/destroy |  |
| [**app_role_destroy_secret_id_by_accessor2**](AuthApi.md#app_role_destroy_secret_id_by_accessor2) | **DELETE** /auth/{approle_mount_path}/role/{role_name}/secret-id-accessor/destroy |  |
| [**app_role_list_roles**](AuthApi.md#app_role_list_roles) | **GET** /auth/{approle_mount_path}/role |  |
| [**app_role_list_secret_ids**](AuthApi.md#app_role_list_secret_ids) | **GET** /auth/{approle_mount_path}/role/{role_name}/secret-id |  |
| [**app_role_login**](AuthApi.md#app_role_login) | **POST** /auth/{approle_mount_path}/login |  |
| [**app_role_look_up_secret_id**](AuthApi.md#app_role_look_up_secret_id) | **POST** /auth/{approle_mount_path}/role/{role_name}/secret-id/lookup |  |
| [**app_role_look_up_secret_id_by_accessor**](AuthApi.md#app_role_look_up_secret_id_by_accessor) | **POST** /auth/{approle_mount_path}/role/{role_name}/secret-id-accessor/lookup |  |
| [**app_role_read_bind_secret_id**](AuthApi.md#app_role_read_bind_secret_id) | **GET** /auth/{approle_mount_path}/role/{role_name}/bind-secret-id |  |
| [**app_role_read_bound_cidr_list**](AuthApi.md#app_role_read_bound_cidr_list) | **GET** /auth/{approle_mount_path}/role/{role_name}/bound-cidr-list |  |
| [**app_role_read_local_secret_ids**](AuthApi.md#app_role_read_local_secret_ids) | **GET** /auth/{approle_mount_path}/role/{role_name}/local-secret-ids |  |
| [**app_role_read_period**](AuthApi.md#app_role_read_period) | **GET** /auth/{approle_mount_path}/role/{role_name}/period |  |
| [**app_role_read_policies**](AuthApi.md#app_role_read_policies) | **GET** /auth/{approle_mount_path}/role/{role_name}/policies |  |
| [**app_role_read_role**](AuthApi.md#app_role_read_role) | **GET** /auth/{approle_mount_path}/role/{role_name} |  |
| [**app_role_read_role_id**](AuthApi.md#app_role_read_role_id) | **GET** /auth/{approle_mount_path}/role/{role_name}/role-id |  |
| [**app_role_read_secret_id_bound_cidrs**](AuthApi.md#app_role_read_secret_id_bound_cidrs) | **GET** /auth/{approle_mount_path}/role/{role_name}/secret-id-bound-cidrs |  |
| [**app_role_read_secret_id_num_uses**](AuthApi.md#app_role_read_secret_id_num_uses) | **GET** /auth/{approle_mount_path}/role/{role_name}/secret-id-num-uses |  |
| [**app_role_read_secret_id_ttl**](AuthApi.md#app_role_read_secret_id_ttl) | **GET** /auth/{approle_mount_path}/role/{role_name}/secret-id-ttl |  |
| [**app_role_read_token_bound_cidrs**](AuthApi.md#app_role_read_token_bound_cidrs) | **GET** /auth/{approle_mount_path}/role/{role_name}/token-bound-cidrs |  |
| [**app_role_read_token_max_ttl**](AuthApi.md#app_role_read_token_max_ttl) | **GET** /auth/{approle_mount_path}/role/{role_name}/token-max-ttl |  |
| [**app_role_read_token_num_uses**](AuthApi.md#app_role_read_token_num_uses) | **GET** /auth/{approle_mount_path}/role/{role_name}/token-num-uses |  |
| [**app_role_read_token_ttl**](AuthApi.md#app_role_read_token_ttl) | **GET** /auth/{approle_mount_path}/role/{role_name}/token-ttl |  |
| [**app_role_tidy_secret_id**](AuthApi.md#app_role_tidy_secret_id) | **POST** /auth/{approle_mount_path}/tidy/secret-id |  |
| [**app_role_write_bind_secret_id**](AuthApi.md#app_role_write_bind_secret_id) | **POST** /auth/{approle_mount_path}/role/{role_name}/bind-secret-id |  |
| [**app_role_write_bound_cidr_list**](AuthApi.md#app_role_write_bound_cidr_list) | **POST** /auth/{approle_mount_path}/role/{role_name}/bound-cidr-list |  |
| [**app_role_write_custom_secret_id**](AuthApi.md#app_role_write_custom_secret_id) | **POST** /auth/{approle_mount_path}/role/{role_name}/custom-secret-id |  |
| [**app_role_write_period**](AuthApi.md#app_role_write_period) | **POST** /auth/{approle_mount_path}/role/{role_name}/period |  |
| [**app_role_write_policies**](AuthApi.md#app_role_write_policies) | **POST** /auth/{approle_mount_path}/role/{role_name}/policies |  |
| [**app_role_write_role**](AuthApi.md#app_role_write_role) | **POST** /auth/{approle_mount_path}/role/{role_name} |  |
| [**app_role_write_role_id**](AuthApi.md#app_role_write_role_id) | **POST** /auth/{approle_mount_path}/role/{role_name}/role-id |  |
| [**app_role_write_secret_id**](AuthApi.md#app_role_write_secret_id) | **POST** /auth/{approle_mount_path}/role/{role_name}/secret-id |  |
| [**app_role_write_secret_id_bound_cidrs**](AuthApi.md#app_role_write_secret_id_bound_cidrs) | **POST** /auth/{approle_mount_path}/role/{role_name}/secret-id-bound-cidrs |  |
| [**app_role_write_secret_id_num_uses**](AuthApi.md#app_role_write_secret_id_num_uses) | **POST** /auth/{approle_mount_path}/role/{role_name}/secret-id-num-uses |  |
| [**app_role_write_secret_id_ttl**](AuthApi.md#app_role_write_secret_id_ttl) | **POST** /auth/{approle_mount_path}/role/{role_name}/secret-id-ttl |  |
| [**app_role_write_token_bound_cidrs**](AuthApi.md#app_role_write_token_bound_cidrs) | **POST** /auth/{approle_mount_path}/role/{role_name}/token-bound-cidrs |  |
| [**app_role_write_token_max_ttl**](AuthApi.md#app_role_write_token_max_ttl) | **POST** /auth/{approle_mount_path}/role/{role_name}/token-max-ttl |  |
| [**app_role_write_token_num_uses**](AuthApi.md#app_role_write_token_num_uses) | **POST** /auth/{approle_mount_path}/role/{role_name}/token-num-uses |  |
| [**app_role_write_token_ttl**](AuthApi.md#app_role_write_token_ttl) | **POST** /auth/{approle_mount_path}/role/{role_name}/token-ttl |  |
| [**cert_configure**](AuthApi.md#cert_configure) | **POST** /auth/{cert_mount_path}/config |  |
| [**cert_delete_certificate**](AuthApi.md#cert_delete_certificate) | **DELETE** /auth/{cert_mount_path}/certs/{name} | Manage trusted certificates used for authentication. |
| [**cert_delete_crl**](AuthApi.md#cert_delete_crl) | **DELETE** /auth/{cert_mount_path}/crls/{name} | Manage Certificate Revocation Lists checked during authentication. |
| [**cert_list_certificates**](AuthApi.md#cert_list_certificates) | **GET** /auth/{cert_mount_path}/certs | Manage trusted certificates used for authentication. |
| [**cert_list_crls**](AuthApi.md#cert_list_crls) | **GET** /auth/{cert_mount_path}/crls |  |
| [**cert_login**](AuthApi.md#cert_login) | **POST** /auth/{cert_mount_path}/login |  |
| [**cert_read_certificate**](AuthApi.md#cert_read_certificate) | **GET** /auth/{cert_mount_path}/certs/{name} | Manage trusted certificates used for authentication. |
| [**cert_read_configuration**](AuthApi.md#cert_read_configuration) | **GET** /auth/{cert_mount_path}/config |  |
| [**cert_read_crl**](AuthApi.md#cert_read_crl) | **GET** /auth/{cert_mount_path}/crls/{name} | Manage Certificate Revocation Lists checked during authentication. |
| [**cert_write_certificate**](AuthApi.md#cert_write_certificate) | **POST** /auth/{cert_mount_path}/certs/{name} | Manage trusted certificates used for authentication. |
| [**cert_write_crl**](AuthApi.md#cert_write_crl) | **POST** /auth/{cert_mount_path}/crls/{name} | Manage Certificate Revocation Lists checked during authentication. |
| [**jwt_configure**](AuthApi.md#jwt_configure) | **POST** /auth/{jwt_mount_path}/config | Configure the JWT authentication backend. |
| [**jwt_delete_role**](AuthApi.md#jwt_delete_role) | **DELETE** /auth/{jwt_mount_path}/role/{name} | Delete an existing role. |
| [**jwt_list_roles**](AuthApi.md#jwt_list_roles) | **GET** /auth/{jwt_mount_path}/role | Lists all the roles registered with the backend. |
| [**jwt_login**](AuthApi.md#jwt_login) | **POST** /auth/{jwt_mount_path}/login | Authenticates to OpenBao using a JWT (or OIDC) token. |
| [**jwt_oidc_callback**](AuthApi.md#jwt_oidc_callback) | **GET** /auth/{jwt_mount_path}/oidc/callback | Callback endpoint to complete an OIDC login. |
| [**jwt_oidc_callback_form_post**](AuthApi.md#jwt_oidc_callback_form_post) | **POST** /auth/{jwt_mount_path}/oidc/callback | Callback endpoint to handle form_posts. |
| [**jwt_oidc_request_authorization_url**](AuthApi.md#jwt_oidc_request_authorization_url) | **POST** /auth/{jwt_mount_path}/oidc/auth_url | Request an authorization URL to start an OIDC login flow. |
| [**jwt_read_configuration**](AuthApi.md#jwt_read_configuration) | **GET** /auth/{jwt_mount_path}/config | Read the current JWT authentication backend configuration. |
| [**jwt_read_role**](AuthApi.md#jwt_read_role) | **GET** /auth/{jwt_mount_path}/role/{name} | Read an existing role. |
| [**jwt_write_role**](AuthApi.md#jwt_write_role) | **POST** /auth/{jwt_mount_path}/role/{name} | Register an role with the backend. |
| [**kerberos_configure**](AuthApi.md#kerberos_configure) | **POST** /auth/{kerberos_mount_path}/config |  |
| [**kerberos_configure_ldap**](AuthApi.md#kerberos_configure_ldap) | **POST** /auth/{kerberos_mount_path}/config/ldap |  |
| [**kerberos_delete_group**](AuthApi.md#kerberos_delete_group) | **DELETE** /auth/{kerberos_mount_path}/groups/{name} |  |
| [**kerberos_list_groups**](AuthApi.md#kerberos_list_groups) | **GET** /auth/{kerberos_mount_path}/groups |  |
| [**kerberos_login**](AuthApi.md#kerberos_login) | **POST** /auth/{kerberos_mount_path}/login |  |
| [**kerberos_login2**](AuthApi.md#kerberos_login2) | **GET** /auth/{kerberos_mount_path}/login |  |
| [**kerberos_read_configuration**](AuthApi.md#kerberos_read_configuration) | **GET** /auth/{kerberos_mount_path}/config |  |
| [**kerberos_read_group**](AuthApi.md#kerberos_read_group) | **GET** /auth/{kerberos_mount_path}/groups/{name} |  |
| [**kerberos_read_ldap_configuration**](AuthApi.md#kerberos_read_ldap_configuration) | **GET** /auth/{kerberos_mount_path}/config/ldap |  |
| [**kerberos_write_group**](AuthApi.md#kerberos_write_group) | **POST** /auth/{kerberos_mount_path}/groups/{name} |  |
| [**kubernetes_configure_auth**](AuthApi.md#kubernetes_configure_auth) | **POST** /auth/{kubernetes_mount_path}/config |  |
| [**kubernetes_delete_auth_role**](AuthApi.md#kubernetes_delete_auth_role) | **DELETE** /auth/{kubernetes_mount_path}/role/{name} | Register an role with the backend. |
| [**kubernetes_list_auth_roles**](AuthApi.md#kubernetes_list_auth_roles) | **GET** /auth/{kubernetes_mount_path}/role | Lists all the roles registered with the backend. |
| [**kubernetes_login**](AuthApi.md#kubernetes_login) | **POST** /auth/{kubernetes_mount_path}/login | Authenticates Kubernetes service accounts with OpenBao. |
| [**kubernetes_read_auth_configuration**](AuthApi.md#kubernetes_read_auth_configuration) | **GET** /auth/{kubernetes_mount_path}/config |  |
| [**kubernetes_read_auth_role**](AuthApi.md#kubernetes_read_auth_role) | **GET** /auth/{kubernetes_mount_path}/role/{name} | Register an role with the backend. |
| [**kubernetes_write_auth_role**](AuthApi.md#kubernetes_write_auth_role) | **POST** /auth/{kubernetes_mount_path}/role/{name} | Register an role with the backend. |
| [**ldap_configure_auth**](AuthApi.md#ldap_configure_auth) | **POST** /auth/{ldap_mount_path}/config |  |
| [**ldap_delete_group**](AuthApi.md#ldap_delete_group) | **DELETE** /auth/{ldap_mount_path}/groups/{name} | Manage additional groups for users allowed to authenticate. |
| [**ldap_delete_user**](AuthApi.md#ldap_delete_user) | **DELETE** /auth/{ldap_mount_path}/users/{name} | Manage users allowed to authenticate. |
| [**ldap_list_groups**](AuthApi.md#ldap_list_groups) | **GET** /auth/{ldap_mount_path}/groups | Manage additional groups for users allowed to authenticate. |
| [**ldap_list_users**](AuthApi.md#ldap_list_users) | **GET** /auth/{ldap_mount_path}/users | Manage users allowed to authenticate. |
| [**ldap_login**](AuthApi.md#ldap_login) | **POST** /auth/{ldap_mount_path}/login/{username} | Log in with a username and password. |
| [**ldap_read_auth_configuration**](AuthApi.md#ldap_read_auth_configuration) | **GET** /auth/{ldap_mount_path}/config |  |
| [**ldap_read_group**](AuthApi.md#ldap_read_group) | **GET** /auth/{ldap_mount_path}/groups/{name} | Manage additional groups for users allowed to authenticate. |
| [**ldap_read_user**](AuthApi.md#ldap_read_user) | **GET** /auth/{ldap_mount_path}/users/{name} | Manage users allowed to authenticate. |
| [**ldap_write_group**](AuthApi.md#ldap_write_group) | **POST** /auth/{ldap_mount_path}/groups/{name} | Manage additional groups for users allowed to authenticate. |
| [**ldap_write_user**](AuthApi.md#ldap_write_user) | **POST** /auth/{ldap_mount_path}/users/{name} | Manage users allowed to authenticate. |
| [**radius_configure**](AuthApi.md#radius_configure) | **POST** /auth/{radius_mount_path}/config |  |
| [**radius_delete_user**](AuthApi.md#radius_delete_user) | **DELETE** /auth/{radius_mount_path}/users/{name} | Manage users allowed to authenticate. |
| [**radius_list_users**](AuthApi.md#radius_list_users) | **GET** /auth/{radius_mount_path}/users | Manage users allowed to authenticate. |
| [**radius_login**](AuthApi.md#radius_login) | **POST** /auth/{radius_mount_path}/login | Log in with a username and password. |
| [**radius_login_with_username**](AuthApi.md#radius_login_with_username) | **POST** /auth/{radius_mount_path}/login/{urlusername} | Log in with a username and password. |
| [**radius_read_configuration**](AuthApi.md#radius_read_configuration) | **GET** /auth/{radius_mount_path}/config |  |
| [**radius_read_user**](AuthApi.md#radius_read_user) | **GET** /auth/{radius_mount_path}/users/{name} | Manage users allowed to authenticate. |
| [**radius_write_user**](AuthApi.md#radius_write_user) | **POST** /auth/{radius_mount_path}/users/{name} | Manage users allowed to authenticate. |
| [**token_create**](AuthApi.md#token_create) | **POST** /auth/token/create | The token create path is used to create new tokens. |
| [**token_create_against_role**](AuthApi.md#token_create_against_role) | **POST** /auth/token/create/{role_name} | This token create path is used to create new tokens adhering to the given role. |
| [**token_create_orphan**](AuthApi.md#token_create_orphan) | **POST** /auth/token/create-orphan | The token create path is used to create new orphan tokens. |
| [**token_delete_role**](AuthApi.md#token_delete_role) | **DELETE** /auth/token/roles/{role_name} |  |
| [**token_list_accessors**](AuthApi.md#token_list_accessors) | **GET** /auth/token/accessors | List token accessors, which can then be be used to iterate and discover their properties or revoke them. Because this can be used to cause a denial of service, this endpoint requires &#39;sudo&#39; capability in addition to &#39;list&#39;. |
| [**token_list_roles**](AuthApi.md#token_list_roles) | **GET** /auth/token/roles | This endpoint lists configured roles. |
| [**token_look_up**](AuthApi.md#token_look_up) | **POST** /auth/token/lookup |  |
| [**token_look_up2**](AuthApi.md#token_look_up2) | **GET** /auth/token/lookup |  |
| [**token_look_up_accessor**](AuthApi.md#token_look_up_accessor) | **POST** /auth/token/lookup-accessor | This endpoint will lookup a token associated with the given accessor and its properties. Response will not contain the token ID. |
| [**token_look_up_self**](AuthApi.md#token_look_up_self) | **GET** /auth/token/lookup-self |  |
| [**token_look_up_self2**](AuthApi.md#token_look_up_self2) | **POST** /auth/token/lookup-self |  |
| [**token_read_role**](AuthApi.md#token_read_role) | **GET** /auth/token/roles/{role_name} |  |
| [**token_renew**](AuthApi.md#token_renew) | **POST** /auth/token/renew | This endpoint will renew the given token and prevent expiration. |
| [**token_renew_accessor**](AuthApi.md#token_renew_accessor) | **POST** /auth/token/renew-accessor | This endpoint will renew a token associated with the given accessor and its properties. Response will not contain the token ID. |
| [**token_renew_self**](AuthApi.md#token_renew_self) | **POST** /auth/token/renew-self | This endpoint will renew the token used to call it and prevent expiration. |
| [**token_revoke**](AuthApi.md#token_revoke) | **POST** /auth/token/revoke | This endpoint will delete the given token and all of its child tokens. |
| [**token_revoke_accessor**](AuthApi.md#token_revoke_accessor) | **POST** /auth/token/revoke-accessor | This endpoint will delete the token associated with the accessor and all of its child tokens. |
| [**token_revoke_orphan**](AuthApi.md#token_revoke_orphan) | **POST** /auth/token/revoke-orphan | This endpoint will delete the token and orphan its child tokens. |
| [**token_revoke_self**](AuthApi.md#token_revoke_self) | **POST** /auth/token/revoke-self | This endpoint will delete the token used to call it and all of its child tokens. |
| [**token_tidy**](AuthApi.md#token_tidy) | **POST** /auth/token/tidy | This endpoint performs cleanup tasks that can be run if certain error conditions have occurred. |
| [**token_write_role**](AuthApi.md#token_write_role) | **POST** /auth/token/roles/{role_name} |  |
| [**userpass_delete_user**](AuthApi.md#userpass_delete_user) | **DELETE** /auth/{userpass_mount_path}/users/{username} | Manage users allowed to authenticate. |
| [**userpass_list_users**](AuthApi.md#userpass_list_users) | **GET** /auth/{userpass_mount_path}/users | Manage users allowed to authenticate. |
| [**userpass_login**](AuthApi.md#userpass_login) | **POST** /auth/{userpass_mount_path}/login/{username} | Log in with a username and password. |
| [**userpass_read_user**](AuthApi.md#userpass_read_user) | **GET** /auth/{userpass_mount_path}/users/{username} | Manage users allowed to authenticate. |
| [**userpass_reset_password**](AuthApi.md#userpass_reset_password) | **POST** /auth/{userpass_mount_path}/users/{username}/password | Reset user&#39;s password. |
| [**userpass_update_policies**](AuthApi.md#userpass_update_policies) | **POST** /auth/{userpass_mount_path}/users/{username}/policies | Update the policies associated with the username. |
| [**userpass_write_user**](AuthApi.md#userpass_write_user) | **POST** /auth/{userpass_mount_path}/users/{username} | Manage users allowed to authenticate. |


## app_role_delete_bind_secret_id

> app_role_delete_bind_secret_id(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_bind_secret_id(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_bind_secret_id: #{e}"
end
```

#### Using the app_role_delete_bind_secret_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_bind_secret_id_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_bind_secret_id_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_bind_secret_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_bound_cidr_list

> app_role_delete_bound_cidr_list(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_bound_cidr_list(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_bound_cidr_list: #{e}"
end
```

#### Using the app_role_delete_bound_cidr_list_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_bound_cidr_list_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_bound_cidr_list_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_bound_cidr_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_period

> app_role_delete_period(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_period(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_period: #{e}"
end
```

#### Using the app_role_delete_period_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_period_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_period_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_period_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_policies

> app_role_delete_policies(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_policies(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_policies: #{e}"
end
```

#### Using the app_role_delete_policies_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_policies_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_policies_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_policies_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_role

> app_role_delete_role(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_role(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_role: #{e}"
end
```

#### Using the app_role_delete_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_role_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_role_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_secret_id_bound_cidrs

> app_role_delete_secret_id_bound_cidrs(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_secret_id_bound_cidrs(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_secret_id_bound_cidrs: #{e}"
end
```

#### Using the app_role_delete_secret_id_bound_cidrs_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_secret_id_bound_cidrs_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_secret_id_bound_cidrs_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_secret_id_bound_cidrs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_secret_id_num_uses

> app_role_delete_secret_id_num_uses(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_secret_id_num_uses(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_secret_id_num_uses: #{e}"
end
```

#### Using the app_role_delete_secret_id_num_uses_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_secret_id_num_uses_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_secret_id_num_uses_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_secret_id_num_uses_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_secret_id_ttl

> app_role_delete_secret_id_ttl(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_secret_id_ttl(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_secret_id_ttl: #{e}"
end
```

#### Using the app_role_delete_secret_id_ttl_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_secret_id_ttl_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_secret_id_ttl_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_secret_id_ttl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_token_bound_cidrs

> app_role_delete_token_bound_cidrs(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_token_bound_cidrs(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_token_bound_cidrs: #{e}"
end
```

#### Using the app_role_delete_token_bound_cidrs_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_token_bound_cidrs_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_token_bound_cidrs_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_token_bound_cidrs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_token_max_ttl

> app_role_delete_token_max_ttl(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_token_max_ttl(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_token_max_ttl: #{e}"
end
```

#### Using the app_role_delete_token_max_ttl_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_token_max_ttl_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_token_max_ttl_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_token_max_ttl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_token_num_uses

> app_role_delete_token_num_uses(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_token_num_uses(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_token_num_uses: #{e}"
end
```

#### Using the app_role_delete_token_num_uses_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_token_num_uses_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_token_num_uses_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_token_num_uses_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_delete_token_ttl

> app_role_delete_token_ttl(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_delete_token_ttl(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_token_ttl: #{e}"
end
```

#### Using the app_role_delete_token_ttl_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_delete_token_ttl_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_delete_token_ttl_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_delete_token_ttl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_destroy_secret_id

> app_role_destroy_secret_id(role_name, approle_mount_path, app_role_destroy_secret_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_destroy_secret_id_request = OpenbaoClient::AppRoleDestroySecretIdRequest.new # AppRoleDestroySecretIdRequest | 

begin
  
  api_instance.app_role_destroy_secret_id(role_name, approle_mount_path, app_role_destroy_secret_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_destroy_secret_id: #{e}"
end
```

#### Using the app_role_destroy_secret_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_destroy_secret_id_with_http_info(role_name, approle_mount_path, app_role_destroy_secret_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_destroy_secret_id_with_http_info(role_name, approle_mount_path, app_role_destroy_secret_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_destroy_secret_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_destroy_secret_id_request** | [**AppRoleDestroySecretIdRequest**](AppRoleDestroySecretIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_destroy_secret_id2

> app_role_destroy_secret_id2(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_destroy_secret_id2(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_destroy_secret_id2: #{e}"
end
```

#### Using the app_role_destroy_secret_id2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_destroy_secret_id2_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_destroy_secret_id2_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_destroy_secret_id2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_destroy_secret_id_by_accessor

> app_role_destroy_secret_id_by_accessor(role_name, approle_mount_path, app_role_destroy_secret_id_by_accessor_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_destroy_secret_id_by_accessor_request = OpenbaoClient::AppRoleDestroySecretIdByAccessorRequest.new # AppRoleDestroySecretIdByAccessorRequest | 

begin
  
  api_instance.app_role_destroy_secret_id_by_accessor(role_name, approle_mount_path, app_role_destroy_secret_id_by_accessor_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_destroy_secret_id_by_accessor: #{e}"
end
```

#### Using the app_role_destroy_secret_id_by_accessor_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_destroy_secret_id_by_accessor_with_http_info(role_name, approle_mount_path, app_role_destroy_secret_id_by_accessor_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_destroy_secret_id_by_accessor_with_http_info(role_name, approle_mount_path, app_role_destroy_secret_id_by_accessor_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_destroy_secret_id_by_accessor_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_destroy_secret_id_by_accessor_request** | [**AppRoleDestroySecretIdByAccessorRequest**](AppRoleDestroySecretIdByAccessorRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_destroy_secret_id_by_accessor2

> app_role_destroy_secret_id_by_accessor2(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_destroy_secret_id_by_accessor2(role_name, approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_destroy_secret_id_by_accessor2: #{e}"
end
```

#### Using the app_role_destroy_secret_id_by_accessor2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_destroy_secret_id_by_accessor2_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_destroy_secret_id_by_accessor2_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_destroy_secret_id_by_accessor2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_list_roles

> <AppRoleListRolesResponse> app_role_list_roles(approle_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.app_role_list_roles(approle_mount_path, list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_list_roles: #{e}"
end
```

#### Using the app_role_list_roles_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleListRolesResponse>, Integer, Hash)> app_role_list_roles_with_http_info(approle_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_list_roles_with_http_info(approle_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleListRolesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_list_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**AppRoleListRolesResponse**](AppRoleListRolesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_list_secret_ids

> <AppRoleListSecretIdsResponse> app_role_list_secret_ids(role_name, approle_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  result = api_instance.app_role_list_secret_ids(role_name, approle_mount_path, list)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_list_secret_ids: #{e}"
end
```

#### Using the app_role_list_secret_ids_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleListSecretIdsResponse>, Integer, Hash)> app_role_list_secret_ids_with_http_info(role_name, approle_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_list_secret_ids_with_http_info(role_name, approle_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleListSecretIdsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_list_secret_ids_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

[**AppRoleListSecretIdsResponse**](AppRoleListSecretIdsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_login

> app_role_login(approle_mount_path, app_role_login_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_login_request = OpenbaoClient::AppRoleLoginRequest.new # AppRoleLoginRequest | 

begin
  
  api_instance.app_role_login(approle_mount_path, app_role_login_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_login: #{e}"
end
```

#### Using the app_role_login_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_login_with_http_info(approle_mount_path, app_role_login_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_login_with_http_info(approle_mount_path, app_role_login_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_login_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_login_request** | [**AppRoleLoginRequest**](AppRoleLoginRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_look_up_secret_id

> <AppRoleLookUpSecretIdResponse> app_role_look_up_secret_id(role_name, approle_mount_path, app_role_look_up_secret_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_look_up_secret_id_request = OpenbaoClient::AppRoleLookUpSecretIdRequest.new # AppRoleLookUpSecretIdRequest | 

begin
  
  result = api_instance.app_role_look_up_secret_id(role_name, approle_mount_path, app_role_look_up_secret_id_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_look_up_secret_id: #{e}"
end
```

#### Using the app_role_look_up_secret_id_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleLookUpSecretIdResponse>, Integer, Hash)> app_role_look_up_secret_id_with_http_info(role_name, approle_mount_path, app_role_look_up_secret_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_look_up_secret_id_with_http_info(role_name, approle_mount_path, app_role_look_up_secret_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleLookUpSecretIdResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_look_up_secret_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_look_up_secret_id_request** | [**AppRoleLookUpSecretIdRequest**](AppRoleLookUpSecretIdRequest.md) |  |  |

### Return type

[**AppRoleLookUpSecretIdResponse**](AppRoleLookUpSecretIdResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## app_role_look_up_secret_id_by_accessor

> <AppRoleLookUpSecretIdByAccessorResponse> app_role_look_up_secret_id_by_accessor(role_name, approle_mount_path, app_role_look_up_secret_id_by_accessor_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_look_up_secret_id_by_accessor_request = OpenbaoClient::AppRoleLookUpSecretIdByAccessorRequest.new # AppRoleLookUpSecretIdByAccessorRequest | 

begin
  
  result = api_instance.app_role_look_up_secret_id_by_accessor(role_name, approle_mount_path, app_role_look_up_secret_id_by_accessor_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_look_up_secret_id_by_accessor: #{e}"
end
```

#### Using the app_role_look_up_secret_id_by_accessor_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleLookUpSecretIdByAccessorResponse>, Integer, Hash)> app_role_look_up_secret_id_by_accessor_with_http_info(role_name, approle_mount_path, app_role_look_up_secret_id_by_accessor_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_look_up_secret_id_by_accessor_with_http_info(role_name, approle_mount_path, app_role_look_up_secret_id_by_accessor_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleLookUpSecretIdByAccessorResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_look_up_secret_id_by_accessor_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_look_up_secret_id_by_accessor_request** | [**AppRoleLookUpSecretIdByAccessorRequest**](AppRoleLookUpSecretIdByAccessorRequest.md) |  |  |

### Return type

[**AppRoleLookUpSecretIdByAccessorResponse**](AppRoleLookUpSecretIdByAccessorResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## app_role_read_bind_secret_id

> <AppRoleReadBindSecretIdResponse> app_role_read_bind_secret_id(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_bind_secret_id(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_bind_secret_id: #{e}"
end
```

#### Using the app_role_read_bind_secret_id_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadBindSecretIdResponse>, Integer, Hash)> app_role_read_bind_secret_id_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_bind_secret_id_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadBindSecretIdResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_bind_secret_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadBindSecretIdResponse**](AppRoleReadBindSecretIdResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_bound_cidr_list

> <AppRoleReadBoundCidrListResponse> app_role_read_bound_cidr_list(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_bound_cidr_list(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_bound_cidr_list: #{e}"
end
```

#### Using the app_role_read_bound_cidr_list_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadBoundCidrListResponse>, Integer, Hash)> app_role_read_bound_cidr_list_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_bound_cidr_list_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadBoundCidrListResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_bound_cidr_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadBoundCidrListResponse**](AppRoleReadBoundCidrListResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_local_secret_ids

> <AppRoleReadLocalSecretIdsResponse> app_role_read_local_secret_ids(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_local_secret_ids(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_local_secret_ids: #{e}"
end
```

#### Using the app_role_read_local_secret_ids_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadLocalSecretIdsResponse>, Integer, Hash)> app_role_read_local_secret_ids_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_local_secret_ids_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadLocalSecretIdsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_local_secret_ids_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadLocalSecretIdsResponse**](AppRoleReadLocalSecretIdsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_period

> <AppRoleReadPeriodResponse> app_role_read_period(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_period(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_period: #{e}"
end
```

#### Using the app_role_read_period_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadPeriodResponse>, Integer, Hash)> app_role_read_period_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_period_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadPeriodResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_period_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadPeriodResponse**](AppRoleReadPeriodResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_policies

> <AppRoleReadPoliciesResponse> app_role_read_policies(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_policies(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_policies: #{e}"
end
```

#### Using the app_role_read_policies_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadPoliciesResponse>, Integer, Hash)> app_role_read_policies_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_policies_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadPoliciesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_policies_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadPoliciesResponse**](AppRoleReadPoliciesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_role

> <AppRoleReadRoleResponse> app_role_read_role(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_role(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_role: #{e}"
end
```

#### Using the app_role_read_role_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadRoleResponse>, Integer, Hash)> app_role_read_role_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_role_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadRoleResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadRoleResponse**](AppRoleReadRoleResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_role_id

> <AppRoleReadRoleIdResponse> app_role_read_role_id(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_role_id(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_role_id: #{e}"
end
```

#### Using the app_role_read_role_id_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadRoleIdResponse>, Integer, Hash)> app_role_read_role_id_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_role_id_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadRoleIdResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_role_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadRoleIdResponse**](AppRoleReadRoleIdResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_secret_id_bound_cidrs

> <AppRoleReadSecretIdBoundCidrsResponse> app_role_read_secret_id_bound_cidrs(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_secret_id_bound_cidrs(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_secret_id_bound_cidrs: #{e}"
end
```

#### Using the app_role_read_secret_id_bound_cidrs_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadSecretIdBoundCidrsResponse>, Integer, Hash)> app_role_read_secret_id_bound_cidrs_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_secret_id_bound_cidrs_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadSecretIdBoundCidrsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_secret_id_bound_cidrs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadSecretIdBoundCidrsResponse**](AppRoleReadSecretIdBoundCidrsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_secret_id_num_uses

> <AppRoleReadSecretIdNumUsesResponse> app_role_read_secret_id_num_uses(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_secret_id_num_uses(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_secret_id_num_uses: #{e}"
end
```

#### Using the app_role_read_secret_id_num_uses_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadSecretIdNumUsesResponse>, Integer, Hash)> app_role_read_secret_id_num_uses_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_secret_id_num_uses_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadSecretIdNumUsesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_secret_id_num_uses_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadSecretIdNumUsesResponse**](AppRoleReadSecretIdNumUsesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_secret_id_ttl

> <AppRoleReadSecretIdTtlResponse> app_role_read_secret_id_ttl(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_secret_id_ttl(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_secret_id_ttl: #{e}"
end
```

#### Using the app_role_read_secret_id_ttl_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadSecretIdTtlResponse>, Integer, Hash)> app_role_read_secret_id_ttl_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_secret_id_ttl_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadSecretIdTtlResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_secret_id_ttl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadSecretIdTtlResponse**](AppRoleReadSecretIdTtlResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_token_bound_cidrs

> <AppRoleReadTokenBoundCidrsResponse> app_role_read_token_bound_cidrs(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_token_bound_cidrs(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_token_bound_cidrs: #{e}"
end
```

#### Using the app_role_read_token_bound_cidrs_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadTokenBoundCidrsResponse>, Integer, Hash)> app_role_read_token_bound_cidrs_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_token_bound_cidrs_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadTokenBoundCidrsResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_token_bound_cidrs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadTokenBoundCidrsResponse**](AppRoleReadTokenBoundCidrsResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_token_max_ttl

> <AppRoleReadTokenMaxTtlResponse> app_role_read_token_max_ttl(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_token_max_ttl(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_token_max_ttl: #{e}"
end
```

#### Using the app_role_read_token_max_ttl_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadTokenMaxTtlResponse>, Integer, Hash)> app_role_read_token_max_ttl_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_token_max_ttl_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadTokenMaxTtlResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_token_max_ttl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadTokenMaxTtlResponse**](AppRoleReadTokenMaxTtlResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_token_num_uses

> <AppRoleReadTokenNumUsesResponse> app_role_read_token_num_uses(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_token_num_uses(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_token_num_uses: #{e}"
end
```

#### Using the app_role_read_token_num_uses_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadTokenNumUsesResponse>, Integer, Hash)> app_role_read_token_num_uses_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_token_num_uses_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadTokenNumUsesResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_token_num_uses_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadTokenNumUsesResponse**](AppRoleReadTokenNumUsesResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_read_token_ttl

> <AppRoleReadTokenTtlResponse> app_role_read_token_ttl(role_name, approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  result = api_instance.app_role_read_token_ttl(role_name, approle_mount_path)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_token_ttl: #{e}"
end
```

#### Using the app_role_read_token_ttl_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleReadTokenTtlResponse>, Integer, Hash)> app_role_read_token_ttl_with_http_info(role_name, approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_read_token_ttl_with_http_info(role_name, approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleReadTokenTtlResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_read_token_ttl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

[**AppRoleReadTokenTtlResponse**](AppRoleReadTokenTtlResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: application/json


## app_role_tidy_secret_id

> app_role_tidy_secret_id(approle_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.app_role_tidy_secret_id(approle_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_tidy_secret_id: #{e}"
end
```

#### Using the app_role_tidy_secret_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_tidy_secret_id_with_http_info(approle_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_tidy_secret_id_with_http_info(approle_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_tidy_secret_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## app_role_write_bind_secret_id

> app_role_write_bind_secret_id(role_name, approle_mount_path, app_role_write_bind_secret_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_bind_secret_id_request = OpenbaoClient::AppRoleWriteBindSecretIdRequest.new # AppRoleWriteBindSecretIdRequest | 

begin
  
  api_instance.app_role_write_bind_secret_id(role_name, approle_mount_path, app_role_write_bind_secret_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_bind_secret_id: #{e}"
end
```

#### Using the app_role_write_bind_secret_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_bind_secret_id_with_http_info(role_name, approle_mount_path, app_role_write_bind_secret_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_bind_secret_id_with_http_info(role_name, approle_mount_path, app_role_write_bind_secret_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_bind_secret_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_bind_secret_id_request** | [**AppRoleWriteBindSecretIdRequest**](AppRoleWriteBindSecretIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_bound_cidr_list

> app_role_write_bound_cidr_list(role_name, approle_mount_path, app_role_write_bound_cidr_list_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_bound_cidr_list_request = OpenbaoClient::AppRoleWriteBoundCidrListRequest.new # AppRoleWriteBoundCidrListRequest | 

begin
  
  api_instance.app_role_write_bound_cidr_list(role_name, approle_mount_path, app_role_write_bound_cidr_list_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_bound_cidr_list: #{e}"
end
```

#### Using the app_role_write_bound_cidr_list_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_bound_cidr_list_with_http_info(role_name, approle_mount_path, app_role_write_bound_cidr_list_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_bound_cidr_list_with_http_info(role_name, approle_mount_path, app_role_write_bound_cidr_list_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_bound_cidr_list_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_bound_cidr_list_request** | [**AppRoleWriteBoundCidrListRequest**](AppRoleWriteBoundCidrListRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_custom_secret_id

> <AppRoleWriteCustomSecretIdResponse> app_role_write_custom_secret_id(role_name, approle_mount_path, app_role_write_custom_secret_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_custom_secret_id_request = OpenbaoClient::AppRoleWriteCustomSecretIdRequest.new # AppRoleWriteCustomSecretIdRequest | 

begin
  
  result = api_instance.app_role_write_custom_secret_id(role_name, approle_mount_path, app_role_write_custom_secret_id_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_custom_secret_id: #{e}"
end
```

#### Using the app_role_write_custom_secret_id_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleWriteCustomSecretIdResponse>, Integer, Hash)> app_role_write_custom_secret_id_with_http_info(role_name, approle_mount_path, app_role_write_custom_secret_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_custom_secret_id_with_http_info(role_name, approle_mount_path, app_role_write_custom_secret_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleWriteCustomSecretIdResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_custom_secret_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_custom_secret_id_request** | [**AppRoleWriteCustomSecretIdRequest**](AppRoleWriteCustomSecretIdRequest.md) |  |  |

### Return type

[**AppRoleWriteCustomSecretIdResponse**](AppRoleWriteCustomSecretIdResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## app_role_write_period

> app_role_write_period(role_name, approle_mount_path, app_role_write_period_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_period_request = OpenbaoClient::AppRoleWritePeriodRequest.new # AppRoleWritePeriodRequest | 

begin
  
  api_instance.app_role_write_period(role_name, approle_mount_path, app_role_write_period_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_period: #{e}"
end
```

#### Using the app_role_write_period_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_period_with_http_info(role_name, approle_mount_path, app_role_write_period_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_period_with_http_info(role_name, approle_mount_path, app_role_write_period_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_period_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_period_request** | [**AppRoleWritePeriodRequest**](AppRoleWritePeriodRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_policies

> app_role_write_policies(role_name, approle_mount_path, app_role_write_policies_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_policies_request = OpenbaoClient::AppRoleWritePoliciesRequest.new # AppRoleWritePoliciesRequest | 

begin
  
  api_instance.app_role_write_policies(role_name, approle_mount_path, app_role_write_policies_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_policies: #{e}"
end
```

#### Using the app_role_write_policies_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_policies_with_http_info(role_name, approle_mount_path, app_role_write_policies_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_policies_with_http_info(role_name, approle_mount_path, app_role_write_policies_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_policies_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_policies_request** | [**AppRoleWritePoliciesRequest**](AppRoleWritePoliciesRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_role

> app_role_write_role(role_name, approle_mount_path, app_role_write_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_role_request = OpenbaoClient::AppRoleWriteRoleRequest.new # AppRoleWriteRoleRequest | 

begin
  
  api_instance.app_role_write_role(role_name, approle_mount_path, app_role_write_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_role: #{e}"
end
```

#### Using the app_role_write_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_role_with_http_info(role_name, approle_mount_path, app_role_write_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_role_with_http_info(role_name, approle_mount_path, app_role_write_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_role_request** | [**AppRoleWriteRoleRequest**](AppRoleWriteRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_role_id

> app_role_write_role_id(role_name, approle_mount_path, app_role_write_role_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_role_id_request = OpenbaoClient::AppRoleWriteRoleIdRequest.new # AppRoleWriteRoleIdRequest | 

begin
  
  api_instance.app_role_write_role_id(role_name, approle_mount_path, app_role_write_role_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_role_id: #{e}"
end
```

#### Using the app_role_write_role_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_role_id_with_http_info(role_name, approle_mount_path, app_role_write_role_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_role_id_with_http_info(role_name, approle_mount_path, app_role_write_role_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_role_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_role_id_request** | [**AppRoleWriteRoleIdRequest**](AppRoleWriteRoleIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_secret_id

> <AppRoleWriteSecretIdResponse> app_role_write_secret_id(role_name, approle_mount_path, app_role_write_secret_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_secret_id_request = OpenbaoClient::AppRoleWriteSecretIdRequest.new # AppRoleWriteSecretIdRequest | 

begin
  
  result = api_instance.app_role_write_secret_id(role_name, approle_mount_path, app_role_write_secret_id_request)
  p result
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_secret_id: #{e}"
end
```

#### Using the app_role_write_secret_id_with_http_info variant

This returns an Array which contains the response data, status code and headers.

> <Array(<AppRoleWriteSecretIdResponse>, Integer, Hash)> app_role_write_secret_id_with_http_info(role_name, approle_mount_path, app_role_write_secret_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_secret_id_with_http_info(role_name, approle_mount_path, app_role_write_secret_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => <AppRoleWriteSecretIdResponse>
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_secret_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_secret_id_request** | [**AppRoleWriteSecretIdRequest**](AppRoleWriteSecretIdRequest.md) |  |  |

### Return type

[**AppRoleWriteSecretIdResponse**](AppRoleWriteSecretIdResponse.md)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: application/json


## app_role_write_secret_id_bound_cidrs

> app_role_write_secret_id_bound_cidrs(role_name, approle_mount_path, app_role_write_secret_id_bound_cidrs_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_secret_id_bound_cidrs_request = OpenbaoClient::AppRoleWriteSecretIdBoundCidrsRequest.new # AppRoleWriteSecretIdBoundCidrsRequest | 

begin
  
  api_instance.app_role_write_secret_id_bound_cidrs(role_name, approle_mount_path, app_role_write_secret_id_bound_cidrs_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_secret_id_bound_cidrs: #{e}"
end
```

#### Using the app_role_write_secret_id_bound_cidrs_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_secret_id_bound_cidrs_with_http_info(role_name, approle_mount_path, app_role_write_secret_id_bound_cidrs_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_secret_id_bound_cidrs_with_http_info(role_name, approle_mount_path, app_role_write_secret_id_bound_cidrs_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_secret_id_bound_cidrs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_secret_id_bound_cidrs_request** | [**AppRoleWriteSecretIdBoundCidrsRequest**](AppRoleWriteSecretIdBoundCidrsRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_secret_id_num_uses

> app_role_write_secret_id_num_uses(role_name, approle_mount_path, app_role_write_secret_id_num_uses_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_secret_id_num_uses_request = OpenbaoClient::AppRoleWriteSecretIdNumUsesRequest.new # AppRoleWriteSecretIdNumUsesRequest | 

begin
  
  api_instance.app_role_write_secret_id_num_uses(role_name, approle_mount_path, app_role_write_secret_id_num_uses_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_secret_id_num_uses: #{e}"
end
```

#### Using the app_role_write_secret_id_num_uses_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_secret_id_num_uses_with_http_info(role_name, approle_mount_path, app_role_write_secret_id_num_uses_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_secret_id_num_uses_with_http_info(role_name, approle_mount_path, app_role_write_secret_id_num_uses_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_secret_id_num_uses_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_secret_id_num_uses_request** | [**AppRoleWriteSecretIdNumUsesRequest**](AppRoleWriteSecretIdNumUsesRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_secret_id_ttl

> app_role_write_secret_id_ttl(role_name, approle_mount_path, app_role_write_secret_id_ttl_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_secret_id_ttl_request = OpenbaoClient::AppRoleWriteSecretIdTtlRequest.new # AppRoleWriteSecretIdTtlRequest | 

begin
  
  api_instance.app_role_write_secret_id_ttl(role_name, approle_mount_path, app_role_write_secret_id_ttl_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_secret_id_ttl: #{e}"
end
```

#### Using the app_role_write_secret_id_ttl_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_secret_id_ttl_with_http_info(role_name, approle_mount_path, app_role_write_secret_id_ttl_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_secret_id_ttl_with_http_info(role_name, approle_mount_path, app_role_write_secret_id_ttl_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_secret_id_ttl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_secret_id_ttl_request** | [**AppRoleWriteSecretIdTtlRequest**](AppRoleWriteSecretIdTtlRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_token_bound_cidrs

> app_role_write_token_bound_cidrs(role_name, approle_mount_path, app_role_write_token_bound_cidrs_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_token_bound_cidrs_request = OpenbaoClient::AppRoleWriteTokenBoundCidrsRequest.new # AppRoleWriteTokenBoundCidrsRequest | 

begin
  
  api_instance.app_role_write_token_bound_cidrs(role_name, approle_mount_path, app_role_write_token_bound_cidrs_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_token_bound_cidrs: #{e}"
end
```

#### Using the app_role_write_token_bound_cidrs_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_token_bound_cidrs_with_http_info(role_name, approle_mount_path, app_role_write_token_bound_cidrs_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_token_bound_cidrs_with_http_info(role_name, approle_mount_path, app_role_write_token_bound_cidrs_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_token_bound_cidrs_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_token_bound_cidrs_request** | [**AppRoleWriteTokenBoundCidrsRequest**](AppRoleWriteTokenBoundCidrsRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_token_max_ttl

> app_role_write_token_max_ttl(role_name, approle_mount_path, app_role_write_token_max_ttl_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_token_max_ttl_request = OpenbaoClient::AppRoleWriteTokenMaxTtlRequest.new # AppRoleWriteTokenMaxTtlRequest | 

begin
  
  api_instance.app_role_write_token_max_ttl(role_name, approle_mount_path, app_role_write_token_max_ttl_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_token_max_ttl: #{e}"
end
```

#### Using the app_role_write_token_max_ttl_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_token_max_ttl_with_http_info(role_name, approle_mount_path, app_role_write_token_max_ttl_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_token_max_ttl_with_http_info(role_name, approle_mount_path, app_role_write_token_max_ttl_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_token_max_ttl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_token_max_ttl_request** | [**AppRoleWriteTokenMaxTtlRequest**](AppRoleWriteTokenMaxTtlRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_token_num_uses

> app_role_write_token_num_uses(role_name, approle_mount_path, app_role_write_token_num_uses_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_token_num_uses_request = OpenbaoClient::AppRoleWriteTokenNumUsesRequest.new # AppRoleWriteTokenNumUsesRequest | 

begin
  
  api_instance.app_role_write_token_num_uses(role_name, approle_mount_path, app_role_write_token_num_uses_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_token_num_uses: #{e}"
end
```

#### Using the app_role_write_token_num_uses_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_token_num_uses_with_http_info(role_name, approle_mount_path, app_role_write_token_num_uses_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_token_num_uses_with_http_info(role_name, approle_mount_path, app_role_write_token_num_uses_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_token_num_uses_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_token_num_uses_request** | [**AppRoleWriteTokenNumUsesRequest**](AppRoleWriteTokenNumUsesRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## app_role_write_token_ttl

> app_role_write_token_ttl(role_name, approle_mount_path, app_role_write_token_ttl_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role. Must be less than 4096 bytes.
approle_mount_path = 'approle_mount_path_example' # String | Path that the backend was mounted at
app_role_write_token_ttl_request = OpenbaoClient::AppRoleWriteTokenTtlRequest.new # AppRoleWriteTokenTtlRequest | 

begin
  
  api_instance.app_role_write_token_ttl(role_name, approle_mount_path, app_role_write_token_ttl_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_token_ttl: #{e}"
end
```

#### Using the app_role_write_token_ttl_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> app_role_write_token_ttl_with_http_info(role_name, approle_mount_path, app_role_write_token_ttl_request)

```ruby
begin
  
  data, status_code, headers = api_instance.app_role_write_token_ttl_with_http_info(role_name, approle_mount_path, app_role_write_token_ttl_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->app_role_write_token_ttl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role. Must be less than 4096 bytes. |  |
| **approle_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;approle&#39;] |
| **app_role_write_token_ttl_request** | [**AppRoleWriteTokenTtlRequest**](AppRoleWriteTokenTtlRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## cert_configure

> cert_configure(cert_mount_path, cert_configure_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at
cert_configure_request = OpenbaoClient::CertConfigureRequest.new # CertConfigureRequest | 

begin
  
  api_instance.cert_configure(cert_mount_path, cert_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_configure: #{e}"
end
```

#### Using the cert_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_configure_with_http_info(cert_mount_path, cert_configure_request)

```ruby
begin
  
  data, status_code, headers = api_instance.cert_configure_with_http_info(cert_mount_path, cert_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |
| **cert_configure_request** | [**CertConfigureRequest**](CertConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## cert_delete_certificate

> cert_delete_certificate(name, cert_mount_path)

Manage trusted certificates used for authentication.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | The name of the certificate
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage trusted certificates used for authentication.
  api_instance.cert_delete_certificate(name, cert_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_delete_certificate: #{e}"
end
```

#### Using the cert_delete_certificate_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_delete_certificate_with_http_info(name, cert_mount_path)

```ruby
begin
  # Manage trusted certificates used for authentication.
  data, status_code, headers = api_instance.cert_delete_certificate_with_http_info(name, cert_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_delete_certificate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the certificate |  |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cert_delete_crl

> cert_delete_crl(name, cert_mount_path)

Manage Certificate Revocation Lists checked during authentication.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | The name of the certificate
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage Certificate Revocation Lists checked during authentication.
  api_instance.cert_delete_crl(name, cert_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_delete_crl: #{e}"
end
```

#### Using the cert_delete_crl_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_delete_crl_with_http_info(name, cert_mount_path)

```ruby
begin
  # Manage Certificate Revocation Lists checked during authentication.
  data, status_code, headers = api_instance.cert_delete_crl_with_http_info(name, cert_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_delete_crl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the certificate |  |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cert_list_certificates

> cert_list_certificates(cert_mount_path, list)

Manage trusted certificates used for authentication.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Manage trusted certificates used for authentication.
  api_instance.cert_list_certificates(cert_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_list_certificates: #{e}"
end
```

#### Using the cert_list_certificates_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_list_certificates_with_http_info(cert_mount_path, list)

```ruby
begin
  # Manage trusted certificates used for authentication.
  data, status_code, headers = api_instance.cert_list_certificates_with_http_info(cert_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_list_certificates_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cert_list_crls

> cert_list_crls(cert_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.cert_list_crls(cert_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_list_crls: #{e}"
end
```

#### Using the cert_list_crls_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_list_crls_with_http_info(cert_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.cert_list_crls_with_http_info(cert_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_list_crls_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cert_login

> cert_login(cert_mount_path, cert_login_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at
cert_login_request = OpenbaoClient::CertLoginRequest.new # CertLoginRequest | 

begin
  
  api_instance.cert_login(cert_mount_path, cert_login_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_login: #{e}"
end
```

#### Using the cert_login_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_login_with_http_info(cert_mount_path, cert_login_request)

```ruby
begin
  
  data, status_code, headers = api_instance.cert_login_with_http_info(cert_mount_path, cert_login_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_login_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |
| **cert_login_request** | [**CertLoginRequest**](CertLoginRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## cert_read_certificate

> cert_read_certificate(name, cert_mount_path)

Manage trusted certificates used for authentication.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | The name of the certificate
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage trusted certificates used for authentication.
  api_instance.cert_read_certificate(name, cert_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_read_certificate: #{e}"
end
```

#### Using the cert_read_certificate_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_read_certificate_with_http_info(name, cert_mount_path)

```ruby
begin
  # Manage trusted certificates used for authentication.
  data, status_code, headers = api_instance.cert_read_certificate_with_http_info(name, cert_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_read_certificate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the certificate |  |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cert_read_configuration

> cert_read_configuration(cert_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.cert_read_configuration(cert_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_read_configuration: #{e}"
end
```

#### Using the cert_read_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_read_configuration_with_http_info(cert_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.cert_read_configuration_with_http_info(cert_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_read_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cert_read_crl

> cert_read_crl(name, cert_mount_path)

Manage Certificate Revocation Lists checked during authentication.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | The name of the certificate
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage Certificate Revocation Lists checked during authentication.
  api_instance.cert_read_crl(name, cert_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_read_crl: #{e}"
end
```

#### Using the cert_read_crl_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_read_crl_with_http_info(name, cert_mount_path)

```ruby
begin
  # Manage Certificate Revocation Lists checked during authentication.
  data, status_code, headers = api_instance.cert_read_crl_with_http_info(name, cert_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_read_crl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the certificate |  |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## cert_write_certificate

> cert_write_certificate(name, cert_mount_path, cert_write_certificate_request)

Manage trusted certificates used for authentication.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | The name of the certificate
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at
cert_write_certificate_request = OpenbaoClient::CertWriteCertificateRequest.new # CertWriteCertificateRequest | 

begin
  # Manage trusted certificates used for authentication.
  api_instance.cert_write_certificate(name, cert_mount_path, cert_write_certificate_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_write_certificate: #{e}"
end
```

#### Using the cert_write_certificate_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_write_certificate_with_http_info(name, cert_mount_path, cert_write_certificate_request)

```ruby
begin
  # Manage trusted certificates used for authentication.
  data, status_code, headers = api_instance.cert_write_certificate_with_http_info(name, cert_mount_path, cert_write_certificate_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_write_certificate_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the certificate |  |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |
| **cert_write_certificate_request** | [**CertWriteCertificateRequest**](CertWriteCertificateRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## cert_write_crl

> cert_write_crl(name, cert_mount_path, cert_write_crl_request)

Manage Certificate Revocation Lists checked during authentication.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | The name of the certificate
cert_mount_path = 'cert_mount_path_example' # String | Path that the backend was mounted at
cert_write_crl_request = OpenbaoClient::CertWriteCrlRequest.new # CertWriteCrlRequest | 

begin
  # Manage Certificate Revocation Lists checked during authentication.
  api_instance.cert_write_crl(name, cert_mount_path, cert_write_crl_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_write_crl: #{e}"
end
```

#### Using the cert_write_crl_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> cert_write_crl_with_http_info(name, cert_mount_path, cert_write_crl_request)

```ruby
begin
  # Manage Certificate Revocation Lists checked during authentication.
  data, status_code, headers = api_instance.cert_write_crl_with_http_info(name, cert_mount_path, cert_write_crl_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->cert_write_crl_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | The name of the certificate |  |
| **cert_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;cert&#39;] |
| **cert_write_crl_request** | [**CertWriteCrlRequest**](CertWriteCrlRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## jwt_configure

> jwt_configure(jwt_mount_path, jwt_configure_request)

Configure the JWT authentication backend.

The JWT authentication backend validates JWTs (or OIDC) using the configured credentials. If using OIDC Discovery, the URL must be provided, along with (optionally) the CA cert to use for the connection. If performing JWT validation locally, a set of public keys must be provided.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
jwt_mount_path = 'jwt_mount_path_example' # String | Path that the backend was mounted at
jwt_configure_request = OpenbaoClient::JwtConfigureRequest.new # JwtConfigureRequest | 

begin
  # Configure the JWT authentication backend.
  api_instance.jwt_configure(jwt_mount_path, jwt_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_configure: #{e}"
end
```

#### Using the jwt_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> jwt_configure_with_http_info(jwt_mount_path, jwt_configure_request)

```ruby
begin
  # Configure the JWT authentication backend.
  data, status_code, headers = api_instance.jwt_configure_with_http_info(jwt_mount_path, jwt_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **jwt_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;jwt&#39;] |
| **jwt_configure_request** | [**JwtConfigureRequest**](JwtConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## jwt_delete_role

> jwt_delete_role(name, jwt_mount_path)

Delete an existing role.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the role.
jwt_mount_path = 'jwt_mount_path_example' # String | Path that the backend was mounted at

begin
  # Delete an existing role.
  api_instance.jwt_delete_role(name, jwt_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_delete_role: #{e}"
end
```

#### Using the jwt_delete_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> jwt_delete_role_with_http_info(name, jwt_mount_path)

```ruby
begin
  # Delete an existing role.
  data, status_code, headers = api_instance.jwt_delete_role_with_http_info(name, jwt_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_delete_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **jwt_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;jwt&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## jwt_list_roles

> jwt_list_roles(jwt_mount_path, list)

Lists all the roles registered with the backend.

The list will contain the names of the roles.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
jwt_mount_path = 'jwt_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Lists all the roles registered with the backend.
  api_instance.jwt_list_roles(jwt_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_list_roles: #{e}"
end
```

#### Using the jwt_list_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> jwt_list_roles_with_http_info(jwt_mount_path, list)

```ruby
begin
  # Lists all the roles registered with the backend.
  data, status_code, headers = api_instance.jwt_list_roles_with_http_info(jwt_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_list_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **jwt_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;jwt&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## jwt_login

> jwt_login(jwt_mount_path, jwt_login_request)

Authenticates to OpenBao using a JWT (or OIDC) token.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
jwt_mount_path = 'jwt_mount_path_example' # String | Path that the backend was mounted at
jwt_login_request = OpenbaoClient::JwtLoginRequest.new # JwtLoginRequest | 

begin
  # Authenticates to OpenBao using a JWT (or OIDC) token.
  api_instance.jwt_login(jwt_mount_path, jwt_login_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_login: #{e}"
end
```

#### Using the jwt_login_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> jwt_login_with_http_info(jwt_mount_path, jwt_login_request)

```ruby
begin
  # Authenticates to OpenBao using a JWT (or OIDC) token.
  data, status_code, headers = api_instance.jwt_login_with_http_info(jwt_mount_path, jwt_login_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_login_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **jwt_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;jwt&#39;] |
| **jwt_login_request** | [**JwtLoginRequest**](JwtLoginRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## jwt_oidc_callback

> jwt_oidc_callback(jwt_mount_path, opts)

Callback endpoint to complete an OIDC login.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
jwt_mount_path = 'jwt_mount_path_example' # String | Path that the backend was mounted at
opts = {
  client_nonce: 'client_nonce_example', # String | 
  code: 'code_example', # String | 
  state: 'state_example' # String | 
}

begin
  # Callback endpoint to complete an OIDC login.
  api_instance.jwt_oidc_callback(jwt_mount_path, opts)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_oidc_callback: #{e}"
end
```

#### Using the jwt_oidc_callback_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> jwt_oidc_callback_with_http_info(jwt_mount_path, opts)

```ruby
begin
  # Callback endpoint to complete an OIDC login.
  data, status_code, headers = api_instance.jwt_oidc_callback_with_http_info(jwt_mount_path, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_oidc_callback_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **jwt_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;jwt&#39;] |
| **client_nonce** | **String** |  | [optional] |
| **code** | **String** |  | [optional] |
| **state** | **String** |  | [optional] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## jwt_oidc_callback_form_post

> jwt_oidc_callback_form_post(jwt_mount_path, jwt_oidc_callback_form_post_request, opts)

Callback endpoint to handle form_posts.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
jwt_mount_path = 'jwt_mount_path_example' # String | Path that the backend was mounted at
jwt_oidc_callback_form_post_request = OpenbaoClient::JwtOidcCallbackFormPostRequest.new # JwtOidcCallbackFormPostRequest | 
opts = {
  client_nonce: 'client_nonce_example', # String | 
  code: 'code_example', # String | 
  state: 'state_example' # String | 
}

begin
  # Callback endpoint to handle form_posts.
  api_instance.jwt_oidc_callback_form_post(jwt_mount_path, jwt_oidc_callback_form_post_request, opts)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_oidc_callback_form_post: #{e}"
end
```

#### Using the jwt_oidc_callback_form_post_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> jwt_oidc_callback_form_post_with_http_info(jwt_mount_path, jwt_oidc_callback_form_post_request, opts)

```ruby
begin
  # Callback endpoint to handle form_posts.
  data, status_code, headers = api_instance.jwt_oidc_callback_form_post_with_http_info(jwt_mount_path, jwt_oidc_callback_form_post_request, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_oidc_callback_form_post_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **jwt_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;jwt&#39;] |
| **jwt_oidc_callback_form_post_request** | [**JwtOidcCallbackFormPostRequest**](JwtOidcCallbackFormPostRequest.md) |  |  |
| **client_nonce** | **String** |  | [optional] |
| **code** | **String** |  | [optional] |
| **state** | **String** |  | [optional] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## jwt_oidc_request_authorization_url

> jwt_oidc_request_authorization_url(jwt_mount_path, jwt_oidc_request_authorization_url_request)

Request an authorization URL to start an OIDC login flow.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
jwt_mount_path = 'jwt_mount_path_example' # String | Path that the backend was mounted at
jwt_oidc_request_authorization_url_request = OpenbaoClient::JwtOidcRequestAuthorizationUrlRequest.new # JwtOidcRequestAuthorizationUrlRequest | 

begin
  # Request an authorization URL to start an OIDC login flow.
  api_instance.jwt_oidc_request_authorization_url(jwt_mount_path, jwt_oidc_request_authorization_url_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_oidc_request_authorization_url: #{e}"
end
```

#### Using the jwt_oidc_request_authorization_url_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> jwt_oidc_request_authorization_url_with_http_info(jwt_mount_path, jwt_oidc_request_authorization_url_request)

```ruby
begin
  # Request an authorization URL to start an OIDC login flow.
  data, status_code, headers = api_instance.jwt_oidc_request_authorization_url_with_http_info(jwt_mount_path, jwt_oidc_request_authorization_url_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_oidc_request_authorization_url_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **jwt_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;jwt&#39;] |
| **jwt_oidc_request_authorization_url_request** | [**JwtOidcRequestAuthorizationUrlRequest**](JwtOidcRequestAuthorizationUrlRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## jwt_read_configuration

> jwt_read_configuration(jwt_mount_path)

Read the current JWT authentication backend configuration.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
jwt_mount_path = 'jwt_mount_path_example' # String | Path that the backend was mounted at

begin
  # Read the current JWT authentication backend configuration.
  api_instance.jwt_read_configuration(jwt_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_read_configuration: #{e}"
end
```

#### Using the jwt_read_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> jwt_read_configuration_with_http_info(jwt_mount_path)

```ruby
begin
  # Read the current JWT authentication backend configuration.
  data, status_code, headers = api_instance.jwt_read_configuration_with_http_info(jwt_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_read_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **jwt_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;jwt&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## jwt_read_role

> jwt_read_role(name, jwt_mount_path)

Read an existing role.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the role.
jwt_mount_path = 'jwt_mount_path_example' # String | Path that the backend was mounted at

begin
  # Read an existing role.
  api_instance.jwt_read_role(name, jwt_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_read_role: #{e}"
end
```

#### Using the jwt_read_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> jwt_read_role_with_http_info(name, jwt_mount_path)

```ruby
begin
  # Read an existing role.
  data, status_code, headers = api_instance.jwt_read_role_with_http_info(name, jwt_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_read_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **jwt_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;jwt&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## jwt_write_role

> jwt_write_role(name, jwt_mount_path, jwt_write_role_request)

Register an role with the backend.

A role is required to authenticate with this backend. The role binds   JWT token information with token policies and settings.   The bindings, token polices and token settings can all be configured   using this endpoint

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the role.
jwt_mount_path = 'jwt_mount_path_example' # String | Path that the backend was mounted at
jwt_write_role_request = OpenbaoClient::JwtWriteRoleRequest.new # JwtWriteRoleRequest | 

begin
  # Register an role with the backend.
  api_instance.jwt_write_role(name, jwt_mount_path, jwt_write_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_write_role: #{e}"
end
```

#### Using the jwt_write_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> jwt_write_role_with_http_info(name, jwt_mount_path, jwt_write_role_request)

```ruby
begin
  # Register an role with the backend.
  data, status_code, headers = api_instance.jwt_write_role_with_http_info(name, jwt_mount_path, jwt_write_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->jwt_write_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **jwt_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;jwt&#39;] |
| **jwt_write_role_request** | [**JwtWriteRoleRequest**](JwtWriteRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kerberos_configure

> kerberos_configure(kerberos_mount_path, kerberos_configure_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kerberos_mount_path = 'kerberos_mount_path_example' # String | Path that the backend was mounted at
kerberos_configure_request = OpenbaoClient::KerberosConfigureRequest.new # KerberosConfigureRequest | 

begin
  
  api_instance.kerberos_configure(kerberos_mount_path, kerberos_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_configure: #{e}"
end
```

#### Using the kerberos_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kerberos_configure_with_http_info(kerberos_mount_path, kerberos_configure_request)

```ruby
begin
  
  data, status_code, headers = api_instance.kerberos_configure_with_http_info(kerberos_mount_path, kerberos_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kerberos_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kerberos&#39;] |
| **kerberos_configure_request** | [**KerberosConfigureRequest**](KerberosConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kerberos_configure_ldap

> kerberos_configure_ldap(kerberos_mount_path, kerberos_configure_ldap_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kerberos_mount_path = 'kerberos_mount_path_example' # String | Path that the backend was mounted at
kerberos_configure_ldap_request = OpenbaoClient::KerberosConfigureLdapRequest.new # KerberosConfigureLdapRequest | 

begin
  
  api_instance.kerberos_configure_ldap(kerberos_mount_path, kerberos_configure_ldap_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_configure_ldap: #{e}"
end
```

#### Using the kerberos_configure_ldap_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kerberos_configure_ldap_with_http_info(kerberos_mount_path, kerberos_configure_ldap_request)

```ruby
begin
  
  data, status_code, headers = api_instance.kerberos_configure_ldap_with_http_info(kerberos_mount_path, kerberos_configure_ldap_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_configure_ldap_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kerberos_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kerberos&#39;] |
| **kerberos_configure_ldap_request** | [**KerberosConfigureLdapRequest**](KerberosConfigureLdapRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kerberos_delete_group

> kerberos_delete_group(name, kerberos_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the LDAP group.
kerberos_mount_path = 'kerberos_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kerberos_delete_group(name, kerberos_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_delete_group: #{e}"
end
```

#### Using the kerberos_delete_group_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kerberos_delete_group_with_http_info(name, kerberos_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kerberos_delete_group_with_http_info(name, kerberos_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_delete_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the LDAP group. |  |
| **kerberos_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kerberos&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kerberos_list_groups

> kerberos_list_groups(kerberos_mount_path, list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kerberos_mount_path = 'kerberos_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.kerberos_list_groups(kerberos_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_list_groups: #{e}"
end
```

#### Using the kerberos_list_groups_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kerberos_list_groups_with_http_info(kerberos_mount_path, list)

```ruby
begin
  
  data, status_code, headers = api_instance.kerberos_list_groups_with_http_info(kerberos_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_list_groups_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kerberos_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kerberos&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kerberos_login

> kerberos_login(kerberos_mount_path, kerberos_login_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kerberos_mount_path = 'kerberos_mount_path_example' # String | Path that the backend was mounted at
kerberos_login_request = OpenbaoClient::KerberosLoginRequest.new # KerberosLoginRequest | 

begin
  
  api_instance.kerberos_login(kerberos_mount_path, kerberos_login_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_login: #{e}"
end
```

#### Using the kerberos_login_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kerberos_login_with_http_info(kerberos_mount_path, kerberos_login_request)

```ruby
begin
  
  data, status_code, headers = api_instance.kerberos_login_with_http_info(kerberos_mount_path, kerberos_login_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_login_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kerberos_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kerberos&#39;] |
| **kerberos_login_request** | [**KerberosLoginRequest**](KerberosLoginRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kerberos_login2

> kerberos_login2(kerberos_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kerberos_mount_path = 'kerberos_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kerberos_login2(kerberos_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_login2: #{e}"
end
```

#### Using the kerberos_login2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kerberos_login2_with_http_info(kerberos_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kerberos_login2_with_http_info(kerberos_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_login2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kerberos_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kerberos&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kerberos_read_configuration

> kerberos_read_configuration(kerberos_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kerberos_mount_path = 'kerberos_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kerberos_read_configuration(kerberos_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_read_configuration: #{e}"
end
```

#### Using the kerberos_read_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kerberos_read_configuration_with_http_info(kerberos_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kerberos_read_configuration_with_http_info(kerberos_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_read_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kerberos_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kerberos&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kerberos_read_group

> kerberos_read_group(name, kerberos_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the LDAP group.
kerberos_mount_path = 'kerberos_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kerberos_read_group(name, kerberos_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_read_group: #{e}"
end
```

#### Using the kerberos_read_group_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kerberos_read_group_with_http_info(name, kerberos_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kerberos_read_group_with_http_info(name, kerberos_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_read_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the LDAP group. |  |
| **kerberos_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kerberos&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kerberos_read_ldap_configuration

> kerberos_read_ldap_configuration(kerberos_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kerberos_mount_path = 'kerberos_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kerberos_read_ldap_configuration(kerberos_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_read_ldap_configuration: #{e}"
end
```

#### Using the kerberos_read_ldap_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kerberos_read_ldap_configuration_with_http_info(kerberos_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kerberos_read_ldap_configuration_with_http_info(kerberos_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_read_ldap_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kerberos_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kerberos&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kerberos_write_group

> kerberos_write_group(name, kerberos_mount_path, kerberos_write_group_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the LDAP group.
kerberos_mount_path = 'kerberos_mount_path_example' # String | Path that the backend was mounted at
kerberos_write_group_request = OpenbaoClient::KerberosWriteGroupRequest.new # KerberosWriteGroupRequest | 

begin
  
  api_instance.kerberos_write_group(name, kerberos_mount_path, kerberos_write_group_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_write_group: #{e}"
end
```

#### Using the kerberos_write_group_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kerberos_write_group_with_http_info(name, kerberos_mount_path, kerberos_write_group_request)

```ruby
begin
  
  data, status_code, headers = api_instance.kerberos_write_group_with_http_info(name, kerberos_mount_path, kerberos_write_group_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kerberos_write_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the LDAP group. |  |
| **kerberos_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kerberos&#39;] |
| **kerberos_write_group_request** | [**KerberosWriteGroupRequest**](KerberosWriteGroupRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kubernetes_configure_auth

> kubernetes_configure_auth(kubernetes_mount_path, kubernetes_configure_auth_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at
kubernetes_configure_auth_request = OpenbaoClient::KubernetesConfigureAuthRequest.new # KubernetesConfigureAuthRequest | 

begin
  
  api_instance.kubernetes_configure_auth(kubernetes_mount_path, kubernetes_configure_auth_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_configure_auth: #{e}"
end
```

#### Using the kubernetes_configure_auth_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_configure_auth_with_http_info(kubernetes_mount_path, kubernetes_configure_auth_request)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_configure_auth_with_http_info(kubernetes_mount_path, kubernetes_configure_auth_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_configure_auth_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |
| **kubernetes_configure_auth_request** | [**KubernetesConfigureAuthRequest**](KubernetesConfigureAuthRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kubernetes_delete_auth_role

> kubernetes_delete_auth_role(name, kubernetes_mount_path)

Register an role with the backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the role.
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at

begin
  # Register an role with the backend.
  api_instance.kubernetes_delete_auth_role(name, kubernetes_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_delete_auth_role: #{e}"
end
```

#### Using the kubernetes_delete_auth_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_delete_auth_role_with_http_info(name, kubernetes_mount_path)

```ruby
begin
  # Register an role with the backend.
  data, status_code, headers = api_instance.kubernetes_delete_auth_role_with_http_info(name, kubernetes_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_delete_auth_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kubernetes_list_auth_roles

> kubernetes_list_auth_roles(kubernetes_mount_path, list)

Lists all the roles registered with the backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Lists all the roles registered with the backend.
  api_instance.kubernetes_list_auth_roles(kubernetes_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_list_auth_roles: #{e}"
end
```

#### Using the kubernetes_list_auth_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_list_auth_roles_with_http_info(kubernetes_mount_path, list)

```ruby
begin
  # Lists all the roles registered with the backend.
  data, status_code, headers = api_instance.kubernetes_list_auth_roles_with_http_info(kubernetes_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_list_auth_roles_with_http_info: #{e}"
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


## kubernetes_login

> kubernetes_login(kubernetes_mount_path, kubernetes_login_request)

Authenticates Kubernetes service accounts with OpenBao.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at
kubernetes_login_request = OpenbaoClient::KubernetesLoginRequest.new # KubernetesLoginRequest | 

begin
  # Authenticates Kubernetes service accounts with OpenBao.
  api_instance.kubernetes_login(kubernetes_mount_path, kubernetes_login_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_login: #{e}"
end
```

#### Using the kubernetes_login_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_login_with_http_info(kubernetes_mount_path, kubernetes_login_request)

```ruby
begin
  # Authenticates Kubernetes service accounts with OpenBao.
  data, status_code, headers = api_instance.kubernetes_login_with_http_info(kubernetes_mount_path, kubernetes_login_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_login_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |
| **kubernetes_login_request** | [**KubernetesLoginRequest**](KubernetesLoginRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## kubernetes_read_auth_configuration

> kubernetes_read_auth_configuration(kubernetes_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.kubernetes_read_auth_configuration(kubernetes_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_read_auth_configuration: #{e}"
end
```

#### Using the kubernetes_read_auth_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_read_auth_configuration_with_http_info(kubernetes_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.kubernetes_read_auth_configuration_with_http_info(kubernetes_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_read_auth_configuration_with_http_info: #{e}"
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


## kubernetes_read_auth_role

> kubernetes_read_auth_role(name, kubernetes_mount_path)

Register an role with the backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the role.
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at

begin
  # Register an role with the backend.
  api_instance.kubernetes_read_auth_role(name, kubernetes_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_read_auth_role: #{e}"
end
```

#### Using the kubernetes_read_auth_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_read_auth_role_with_http_info(name, kubernetes_mount_path)

```ruby
begin
  # Register an role with the backend.
  data, status_code, headers = api_instance.kubernetes_read_auth_role_with_http_info(name, kubernetes_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_read_auth_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## kubernetes_write_auth_role

> kubernetes_write_auth_role(name, kubernetes_mount_path, kubernetes_write_auth_role_request)

Register an role with the backend.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the role.
kubernetes_mount_path = 'kubernetes_mount_path_example' # String | Path that the backend was mounted at
kubernetes_write_auth_role_request = OpenbaoClient::KubernetesWriteAuthRoleRequest.new # KubernetesWriteAuthRoleRequest | 

begin
  # Register an role with the backend.
  api_instance.kubernetes_write_auth_role(name, kubernetes_mount_path, kubernetes_write_auth_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_write_auth_role: #{e}"
end
```

#### Using the kubernetes_write_auth_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> kubernetes_write_auth_role_with_http_info(name, kubernetes_mount_path, kubernetes_write_auth_role_request)

```ruby
begin
  # Register an role with the backend.
  data, status_code, headers = api_instance.kubernetes_write_auth_role_with_http_info(name, kubernetes_mount_path, kubernetes_write_auth_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->kubernetes_write_auth_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role. |  |
| **kubernetes_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;kubernetes&#39;] |
| **kubernetes_write_auth_role_request** | [**KubernetesWriteAuthRoleRequest**](KubernetesWriteAuthRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_configure_auth

> ldap_configure_auth(ldap_mount_path, ldap_configure_auth_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_configure_auth_request = OpenbaoClient::LdapConfigureAuthRequest.new # LdapConfigureAuthRequest | 

begin
  
  api_instance.ldap_configure_auth(ldap_mount_path, ldap_configure_auth_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_configure_auth: #{e}"
end
```

#### Using the ldap_configure_auth_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_configure_auth_with_http_info(ldap_mount_path, ldap_configure_auth_request)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_configure_auth_with_http_info(ldap_mount_path, ldap_configure_auth_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_configure_auth_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_configure_auth_request** | [**LdapConfigureAuthRequest**](LdapConfigureAuthRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_delete_group

> ldap_delete_group(name, ldap_mount_path)

Manage additional groups for users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the LDAP group.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage additional groups for users allowed to authenticate.
  api_instance.ldap_delete_group(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_delete_group: #{e}"
end
```

#### Using the ldap_delete_group_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_delete_group_with_http_info(name, ldap_mount_path)

```ruby
begin
  # Manage additional groups for users allowed to authenticate.
  data, status_code, headers = api_instance.ldap_delete_group_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_delete_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the LDAP group. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_delete_user

> ldap_delete_user(name, ldap_mount_path)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the LDAP user.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage users allowed to authenticate.
  api_instance.ldap_delete_user(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_delete_user: #{e}"
end
```

#### Using the ldap_delete_user_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_delete_user_with_http_info(name, ldap_mount_path)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.ldap_delete_user_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_delete_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the LDAP user. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_list_groups

> ldap_list_groups(ldap_mount_path, list)

Manage additional groups for users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Manage additional groups for users allowed to authenticate.
  api_instance.ldap_list_groups(ldap_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_list_groups: #{e}"
end
```

#### Using the ldap_list_groups_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_list_groups_with_http_info(ldap_mount_path, list)

```ruby
begin
  # Manage additional groups for users allowed to authenticate.
  data, status_code, headers = api_instance.ldap_list_groups_with_http_info(ldap_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_list_groups_with_http_info: #{e}"
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


## ldap_list_users

> ldap_list_users(ldap_mount_path, list)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Manage users allowed to authenticate.
  api_instance.ldap_list_users(ldap_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_list_users: #{e}"
end
```

#### Using the ldap_list_users_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_list_users_with_http_info(ldap_mount_path, list)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.ldap_list_users_with_http_info(ldap_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_list_users_with_http_info: #{e}"
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


## ldap_login

> ldap_login(username, ldap_mount_path, ldap_login_request)

Log in with a username and password.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
username = 'username_example' # String | DN (distinguished name) to be used for login.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_login_request = OpenbaoClient::LdapLoginRequest.new # LdapLoginRequest | 

begin
  # Log in with a username and password.
  api_instance.ldap_login(username, ldap_mount_path, ldap_login_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_login: #{e}"
end
```

#### Using the ldap_login_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_login_with_http_info(username, ldap_mount_path, ldap_login_request)

```ruby
begin
  # Log in with a username and password.
  data, status_code, headers = api_instance.ldap_login_with_http_info(username, ldap_mount_path, ldap_login_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_login_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **username** | **String** | DN (distinguished name) to be used for login. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_login_request** | [**LdapLoginRequest**](LdapLoginRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_read_auth_configuration

> ldap_read_auth_configuration(ldap_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.ldap_read_auth_configuration(ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_read_auth_configuration: #{e}"
end
```

#### Using the ldap_read_auth_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_read_auth_configuration_with_http_info(ldap_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.ldap_read_auth_configuration_with_http_info(ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_read_auth_configuration_with_http_info: #{e}"
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


## ldap_read_group

> ldap_read_group(name, ldap_mount_path)

Manage additional groups for users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the LDAP group.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage additional groups for users allowed to authenticate.
  api_instance.ldap_read_group(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_read_group: #{e}"
end
```

#### Using the ldap_read_group_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_read_group_with_http_info(name, ldap_mount_path)

```ruby
begin
  # Manage additional groups for users allowed to authenticate.
  data, status_code, headers = api_instance.ldap_read_group_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_read_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the LDAP group. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_read_user

> ldap_read_user(name, ldap_mount_path)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the LDAP user.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage users allowed to authenticate.
  api_instance.ldap_read_user(name, ldap_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_read_user: #{e}"
end
```

#### Using the ldap_read_user_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_read_user_with_http_info(name, ldap_mount_path)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.ldap_read_user_with_http_info(name, ldap_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_read_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the LDAP user. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## ldap_write_group

> ldap_write_group(name, ldap_mount_path, ldap_write_group_request)

Manage additional groups for users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the LDAP group.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_write_group_request = OpenbaoClient::LdapWriteGroupRequest.new # LdapWriteGroupRequest | 

begin
  # Manage additional groups for users allowed to authenticate.
  api_instance.ldap_write_group(name, ldap_mount_path, ldap_write_group_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_write_group: #{e}"
end
```

#### Using the ldap_write_group_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_write_group_with_http_info(name, ldap_mount_path, ldap_write_group_request)

```ruby
begin
  # Manage additional groups for users allowed to authenticate.
  data, status_code, headers = api_instance.ldap_write_group_with_http_info(name, ldap_mount_path, ldap_write_group_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_write_group_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the LDAP group. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_write_group_request** | [**LdapWriteGroupRequest**](LdapWriteGroupRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## ldap_write_user

> ldap_write_user(name, ldap_mount_path, ldap_write_user_request)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the LDAP user.
ldap_mount_path = 'ldap_mount_path_example' # String | Path that the backend was mounted at
ldap_write_user_request = OpenbaoClient::LdapWriteUserRequest.new # LdapWriteUserRequest | 

begin
  # Manage users allowed to authenticate.
  api_instance.ldap_write_user(name, ldap_mount_path, ldap_write_user_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_write_user: #{e}"
end
```

#### Using the ldap_write_user_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> ldap_write_user_with_http_info(name, ldap_mount_path, ldap_write_user_request)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.ldap_write_user_with_http_info(name, ldap_mount_path, ldap_write_user_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->ldap_write_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the LDAP user. |  |
| **ldap_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;ldap&#39;] |
| **ldap_write_user_request** | [**LdapWriteUserRequest**](LdapWriteUserRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## radius_configure

> radius_configure(radius_mount_path, radius_configure_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
radius_mount_path = 'radius_mount_path_example' # String | Path that the backend was mounted at
radius_configure_request = OpenbaoClient::RadiusConfigureRequest.new # RadiusConfigureRequest | 

begin
  
  api_instance.radius_configure(radius_mount_path, radius_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_configure: #{e}"
end
```

#### Using the radius_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> radius_configure_with_http_info(radius_mount_path, radius_configure_request)

```ruby
begin
  
  data, status_code, headers = api_instance.radius_configure_with_http_info(radius_mount_path, radius_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **radius_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;radius&#39;] |
| **radius_configure_request** | [**RadiusConfigureRequest**](RadiusConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## radius_delete_user

> radius_delete_user(name, radius_mount_path)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the RADIUS user.
radius_mount_path = 'radius_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage users allowed to authenticate.
  api_instance.radius_delete_user(name, radius_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_delete_user: #{e}"
end
```

#### Using the radius_delete_user_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> radius_delete_user_with_http_info(name, radius_mount_path)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.radius_delete_user_with_http_info(name, radius_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_delete_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the RADIUS user. |  |
| **radius_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;radius&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## radius_list_users

> radius_list_users(radius_mount_path, list)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
radius_mount_path = 'radius_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Manage users allowed to authenticate.
  api_instance.radius_list_users(radius_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_list_users: #{e}"
end
```

#### Using the radius_list_users_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> radius_list_users_with_http_info(radius_mount_path, list)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.radius_list_users_with_http_info(radius_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_list_users_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **radius_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;radius&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## radius_login

> radius_login(radius_mount_path, radius_login_request)

Log in with a username and password.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
radius_mount_path = 'radius_mount_path_example' # String | Path that the backend was mounted at
radius_login_request = OpenbaoClient::RadiusLoginRequest.new # RadiusLoginRequest | 

begin
  # Log in with a username and password.
  api_instance.radius_login(radius_mount_path, radius_login_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_login: #{e}"
end
```

#### Using the radius_login_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> radius_login_with_http_info(radius_mount_path, radius_login_request)

```ruby
begin
  # Log in with a username and password.
  data, status_code, headers = api_instance.radius_login_with_http_info(radius_mount_path, radius_login_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_login_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **radius_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;radius&#39;] |
| **radius_login_request** | [**RadiusLoginRequest**](RadiusLoginRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## radius_login_with_username

> radius_login_with_username(urlusername, radius_mount_path, radius_login_with_username_request)

Log in with a username and password.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
urlusername = 'urlusername_example' # String | Username to be used for login. (URL parameter)
radius_mount_path = 'radius_mount_path_example' # String | Path that the backend was mounted at
radius_login_with_username_request = OpenbaoClient::RadiusLoginWithUsernameRequest.new # RadiusLoginWithUsernameRequest | 

begin
  # Log in with a username and password.
  api_instance.radius_login_with_username(urlusername, radius_mount_path, radius_login_with_username_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_login_with_username: #{e}"
end
```

#### Using the radius_login_with_username_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> radius_login_with_username_with_http_info(urlusername, radius_mount_path, radius_login_with_username_request)

```ruby
begin
  # Log in with a username and password.
  data, status_code, headers = api_instance.radius_login_with_username_with_http_info(urlusername, radius_mount_path, radius_login_with_username_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_login_with_username_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **urlusername** | **String** | Username to be used for login. (URL parameter) |  |
| **radius_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;radius&#39;] |
| **radius_login_with_username_request** | [**RadiusLoginWithUsernameRequest**](RadiusLoginWithUsernameRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## radius_read_configuration

> radius_read_configuration(radius_mount_path)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
radius_mount_path = 'radius_mount_path_example' # String | Path that the backend was mounted at

begin
  
  api_instance.radius_read_configuration(radius_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_read_configuration: #{e}"
end
```

#### Using the radius_read_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> radius_read_configuration_with_http_info(radius_mount_path)

```ruby
begin
  
  data, status_code, headers = api_instance.radius_read_configuration_with_http_info(radius_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_read_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **radius_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;radius&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## radius_read_user

> radius_read_user(name, radius_mount_path)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the RADIUS user.
radius_mount_path = 'radius_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage users allowed to authenticate.
  api_instance.radius_read_user(name, radius_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_read_user: #{e}"
end
```

#### Using the radius_read_user_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> radius_read_user_with_http_info(name, radius_mount_path)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.radius_read_user_with_http_info(name, radius_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_read_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the RADIUS user. |  |
| **radius_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;radius&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## radius_write_user

> radius_write_user(name, radius_mount_path, radius_write_user_request)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
name = 'name_example' # String | Name of the RADIUS user.
radius_mount_path = 'radius_mount_path_example' # String | Path that the backend was mounted at
radius_write_user_request = OpenbaoClient::RadiusWriteUserRequest.new # RadiusWriteUserRequest | 

begin
  # Manage users allowed to authenticate.
  api_instance.radius_write_user(name, radius_mount_path, radius_write_user_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_write_user: #{e}"
end
```

#### Using the radius_write_user_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> radius_write_user_with_http_info(name, radius_mount_path, radius_write_user_request)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.radius_write_user_with_http_info(name, radius_mount_path, radius_write_user_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->radius_write_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the RADIUS user. |  |
| **radius_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;radius&#39;] |
| **radius_write_user_request** | [**RadiusWriteUserRequest**](RadiusWriteUserRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_create

> token_create(token_create_request)

The token create path is used to create new tokens.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_create_request = OpenbaoClient::TokenCreateRequest.new # TokenCreateRequest | 

begin
  # The token create path is used to create new tokens.
  api_instance.token_create(token_create_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_create: #{e}"
end
```

#### Using the token_create_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_create_with_http_info(token_create_request)

```ruby
begin
  # The token create path is used to create new tokens.
  data, status_code, headers = api_instance.token_create_with_http_info(token_create_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_create_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_create_request** | [**TokenCreateRequest**](TokenCreateRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_create_against_role

> token_create_against_role(role_name, token_create_against_role_request)

This token create path is used to create new tokens adhering to the given role.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role
token_create_against_role_request = OpenbaoClient::TokenCreateAgainstRoleRequest.new # TokenCreateAgainstRoleRequest | 

begin
  # This token create path is used to create new tokens adhering to the given role.
  api_instance.token_create_against_role(role_name, token_create_against_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_create_against_role: #{e}"
end
```

#### Using the token_create_against_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_create_against_role_with_http_info(role_name, token_create_against_role_request)

```ruby
begin
  # This token create path is used to create new tokens adhering to the given role.
  data, status_code, headers = api_instance.token_create_against_role_with_http_info(role_name, token_create_against_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_create_against_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role |  |
| **token_create_against_role_request** | [**TokenCreateAgainstRoleRequest**](TokenCreateAgainstRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_create_orphan

> token_create_orphan(token_create_orphan_request)

The token create path is used to create new orphan tokens.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_create_orphan_request = OpenbaoClient::TokenCreateOrphanRequest.new # TokenCreateOrphanRequest | 

begin
  # The token create path is used to create new orphan tokens.
  api_instance.token_create_orphan(token_create_orphan_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_create_orphan: #{e}"
end
```

#### Using the token_create_orphan_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_create_orphan_with_http_info(token_create_orphan_request)

```ruby
begin
  # The token create path is used to create new orphan tokens.
  data, status_code, headers = api_instance.token_create_orphan_with_http_info(token_create_orphan_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_create_orphan_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_create_orphan_request** | [**TokenCreateOrphanRequest**](TokenCreateOrphanRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_delete_role

> token_delete_role(role_name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role

begin
  
  api_instance.token_delete_role(role_name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_delete_role: #{e}"
end
```

#### Using the token_delete_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_delete_role_with_http_info(role_name)

```ruby
begin
  
  data, status_code, headers = api_instance.token_delete_role_with_http_info(role_name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_delete_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## token_list_accessors

> token_list_accessors(list)

List token accessors, which can then be be used to iterate and discover their properties or revoke them. Because this can be used to cause a denial of service, this endpoint requires 'sudo' capability in addition to 'list'.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
list = 'true' # String | Must be set to `true`

begin
  # List token accessors, which can then be be used to iterate and discover their properties or revoke them. Because this can be used to cause a denial of service, this endpoint requires 'sudo' capability in addition to 'list'.
  api_instance.token_list_accessors(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_list_accessors: #{e}"
end
```

#### Using the token_list_accessors_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_list_accessors_with_http_info(list)

```ruby
begin
  # List token accessors, which can then be be used to iterate and discover their properties or revoke them. Because this can be used to cause a denial of service, this endpoint requires 'sudo' capability in addition to 'list'.
  data, status_code, headers = api_instance.token_list_accessors_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_list_accessors_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## token_list_roles

> token_list_roles(list)

This endpoint lists configured roles.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
list = 'true' # String | Must be set to `true`

begin
  # This endpoint lists configured roles.
  api_instance.token_list_roles(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_list_roles: #{e}"
end
```

#### Using the token_list_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_list_roles_with_http_info(list)

```ruby
begin
  # This endpoint lists configured roles.
  data, status_code, headers = api_instance.token_list_roles_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_list_roles_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## token_look_up

> token_look_up(token_look_up_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_look_up_request = OpenbaoClient::TokenLookUpRequest.new # TokenLookUpRequest | 

begin
  
  api_instance.token_look_up(token_look_up_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_look_up: #{e}"
end
```

#### Using the token_look_up_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_look_up_with_http_info(token_look_up_request)

```ruby
begin
  
  data, status_code, headers = api_instance.token_look_up_with_http_info(token_look_up_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_look_up_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_look_up_request** | [**TokenLookUpRequest**](TokenLookUpRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_look_up2

> token_look_up2



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new

begin
  
  api_instance.token_look_up2
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_look_up2: #{e}"
end
```

#### Using the token_look_up2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_look_up2_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.token_look_up2_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_look_up2_with_http_info: #{e}"
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


## token_look_up_accessor

> token_look_up_accessor(token_look_up_accessor_request)

This endpoint will lookup a token associated with the given accessor and its properties. Response will not contain the token ID.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_look_up_accessor_request = OpenbaoClient::TokenLookUpAccessorRequest.new # TokenLookUpAccessorRequest | 

begin
  # This endpoint will lookup a token associated with the given accessor and its properties. Response will not contain the token ID.
  api_instance.token_look_up_accessor(token_look_up_accessor_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_look_up_accessor: #{e}"
end
```

#### Using the token_look_up_accessor_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_look_up_accessor_with_http_info(token_look_up_accessor_request)

```ruby
begin
  # This endpoint will lookup a token associated with the given accessor and its properties. Response will not contain the token ID.
  data, status_code, headers = api_instance.token_look_up_accessor_with_http_info(token_look_up_accessor_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_look_up_accessor_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_look_up_accessor_request** | [**TokenLookUpAccessorRequest**](TokenLookUpAccessorRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_look_up_self

> token_look_up_self



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new

begin
  
  api_instance.token_look_up_self
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_look_up_self: #{e}"
end
```

#### Using the token_look_up_self_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_look_up_self_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.token_look_up_self_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_look_up_self_with_http_info: #{e}"
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


## token_look_up_self2

> token_look_up_self2(token_look_up_self2_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_look_up_self2_request = OpenbaoClient::TokenLookUpSelf2Request.new # TokenLookUpSelf2Request | 

begin
  
  api_instance.token_look_up_self2(token_look_up_self2_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_look_up_self2: #{e}"
end
```

#### Using the token_look_up_self2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_look_up_self2_with_http_info(token_look_up_self2_request)

```ruby
begin
  
  data, status_code, headers = api_instance.token_look_up_self2_with_http_info(token_look_up_self2_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_look_up_self2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_look_up_self2_request** | [**TokenLookUpSelf2Request**](TokenLookUpSelf2Request.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_read_role

> token_read_role(role_name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role

begin
  
  api_instance.token_read_role(role_name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_read_role: #{e}"
end
```

#### Using the token_read_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_read_role_with_http_info(role_name)

```ruby
begin
  
  data, status_code, headers = api_instance.token_read_role_with_http_info(role_name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_read_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## token_renew

> token_renew(token_renew_request)

This endpoint will renew the given token and prevent expiration.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_renew_request = OpenbaoClient::TokenRenewRequest.new # TokenRenewRequest | 

begin
  # This endpoint will renew the given token and prevent expiration.
  api_instance.token_renew(token_renew_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_renew: #{e}"
end
```

#### Using the token_renew_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_renew_with_http_info(token_renew_request)

```ruby
begin
  # This endpoint will renew the given token and prevent expiration.
  data, status_code, headers = api_instance.token_renew_with_http_info(token_renew_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_renew_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_renew_request** | [**TokenRenewRequest**](TokenRenewRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_renew_accessor

> token_renew_accessor(token_renew_accessor_request)

This endpoint will renew a token associated with the given accessor and its properties. Response will not contain the token ID.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_renew_accessor_request = OpenbaoClient::TokenRenewAccessorRequest.new # TokenRenewAccessorRequest | 

begin
  # This endpoint will renew a token associated with the given accessor and its properties. Response will not contain the token ID.
  api_instance.token_renew_accessor(token_renew_accessor_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_renew_accessor: #{e}"
end
```

#### Using the token_renew_accessor_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_renew_accessor_with_http_info(token_renew_accessor_request)

```ruby
begin
  # This endpoint will renew a token associated with the given accessor and its properties. Response will not contain the token ID.
  data, status_code, headers = api_instance.token_renew_accessor_with_http_info(token_renew_accessor_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_renew_accessor_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_renew_accessor_request** | [**TokenRenewAccessorRequest**](TokenRenewAccessorRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_renew_self

> token_renew_self(token_renew_self_request)

This endpoint will renew the token used to call it and prevent expiration.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_renew_self_request = OpenbaoClient::TokenRenewSelfRequest.new # TokenRenewSelfRequest | 

begin
  # This endpoint will renew the token used to call it and prevent expiration.
  api_instance.token_renew_self(token_renew_self_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_renew_self: #{e}"
end
```

#### Using the token_renew_self_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_renew_self_with_http_info(token_renew_self_request)

```ruby
begin
  # This endpoint will renew the token used to call it and prevent expiration.
  data, status_code, headers = api_instance.token_renew_self_with_http_info(token_renew_self_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_renew_self_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_renew_self_request** | [**TokenRenewSelfRequest**](TokenRenewSelfRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_revoke

> token_revoke(token_revoke_request)

This endpoint will delete the given token and all of its child tokens.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_revoke_request = OpenbaoClient::TokenRevokeRequest.new # TokenRevokeRequest | 

begin
  # This endpoint will delete the given token and all of its child tokens.
  api_instance.token_revoke(token_revoke_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_revoke: #{e}"
end
```

#### Using the token_revoke_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_revoke_with_http_info(token_revoke_request)

```ruby
begin
  # This endpoint will delete the given token and all of its child tokens.
  data, status_code, headers = api_instance.token_revoke_with_http_info(token_revoke_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_revoke_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_revoke_request** | [**TokenRevokeRequest**](TokenRevokeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_revoke_accessor

> token_revoke_accessor(token_revoke_accessor_request)

This endpoint will delete the token associated with the accessor and all of its child tokens.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_revoke_accessor_request = OpenbaoClient::TokenRevokeAccessorRequest.new # TokenRevokeAccessorRequest | 

begin
  # This endpoint will delete the token associated with the accessor and all of its child tokens.
  api_instance.token_revoke_accessor(token_revoke_accessor_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_revoke_accessor: #{e}"
end
```

#### Using the token_revoke_accessor_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_revoke_accessor_with_http_info(token_revoke_accessor_request)

```ruby
begin
  # This endpoint will delete the token associated with the accessor and all of its child tokens.
  data, status_code, headers = api_instance.token_revoke_accessor_with_http_info(token_revoke_accessor_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_revoke_accessor_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_revoke_accessor_request** | [**TokenRevokeAccessorRequest**](TokenRevokeAccessorRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_revoke_orphan

> token_revoke_orphan(token_revoke_orphan_request)

This endpoint will delete the token and orphan its child tokens.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
token_revoke_orphan_request = OpenbaoClient::TokenRevokeOrphanRequest.new # TokenRevokeOrphanRequest | 

begin
  # This endpoint will delete the token and orphan its child tokens.
  api_instance.token_revoke_orphan(token_revoke_orphan_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_revoke_orphan: #{e}"
end
```

#### Using the token_revoke_orphan_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_revoke_orphan_with_http_info(token_revoke_orphan_request)

```ruby
begin
  # This endpoint will delete the token and orphan its child tokens.
  data, status_code, headers = api_instance.token_revoke_orphan_with_http_info(token_revoke_orphan_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_revoke_orphan_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **token_revoke_orphan_request** | [**TokenRevokeOrphanRequest**](TokenRevokeOrphanRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## token_revoke_self

> token_revoke_self

This endpoint will delete the token used to call it and all of its child tokens.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new

begin
  # This endpoint will delete the token used to call it and all of its child tokens.
  api_instance.token_revoke_self
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_revoke_self: #{e}"
end
```

#### Using the token_revoke_self_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_revoke_self_with_http_info

```ruby
begin
  # This endpoint will delete the token used to call it and all of its child tokens.
  data, status_code, headers = api_instance.token_revoke_self_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_revoke_self_with_http_info: #{e}"
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


## token_tidy

> token_tidy

This endpoint performs cleanup tasks that can be run if certain error conditions have occurred.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new

begin
  # This endpoint performs cleanup tasks that can be run if certain error conditions have occurred.
  api_instance.token_tidy
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_tidy: #{e}"
end
```

#### Using the token_tidy_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_tidy_with_http_info

```ruby
begin
  # This endpoint performs cleanup tasks that can be run if certain error conditions have occurred.
  data, status_code, headers = api_instance.token_tidy_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_tidy_with_http_info: #{e}"
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


## token_write_role

> token_write_role(role_name, token_write_role_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
role_name = 'role_name_example' # String | Name of the role
token_write_role_request = OpenbaoClient::TokenWriteRoleRequest.new # TokenWriteRoleRequest | 

begin
  
  api_instance.token_write_role(role_name, token_write_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_write_role: #{e}"
end
```

#### Using the token_write_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> token_write_role_with_http_info(role_name, token_write_role_request)

```ruby
begin
  
  data, status_code, headers = api_instance.token_write_role_with_http_info(role_name, token_write_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->token_write_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **role_name** | **String** | Name of the role |  |
| **token_write_role_request** | [**TokenWriteRoleRequest**](TokenWriteRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## userpass_delete_user

> userpass_delete_user(username, userpass_mount_path)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
username = 'username_example' # String | Username for this user.
userpass_mount_path = 'userpass_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage users allowed to authenticate.
  api_instance.userpass_delete_user(username, userpass_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_delete_user: #{e}"
end
```

#### Using the userpass_delete_user_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> userpass_delete_user_with_http_info(username, userpass_mount_path)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.userpass_delete_user_with_http_info(username, userpass_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_delete_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **username** | **String** | Username for this user. |  |
| **userpass_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;userpass&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## userpass_list_users

> userpass_list_users(userpass_mount_path, list)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
userpass_mount_path = 'userpass_mount_path_example' # String | Path that the backend was mounted at
list = 'true' # String | Must be set to `true`

begin
  # Manage users allowed to authenticate.
  api_instance.userpass_list_users(userpass_mount_path, list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_list_users: #{e}"
end
```

#### Using the userpass_list_users_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> userpass_list_users_with_http_info(userpass_mount_path, list)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.userpass_list_users_with_http_info(userpass_mount_path, list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_list_users_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **userpass_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;userpass&#39;] |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## userpass_login

> userpass_login(username, userpass_mount_path, userpass_login_request)

Log in with a username and password.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
username = 'username_example' # String | Username of the user.
userpass_mount_path = 'userpass_mount_path_example' # String | Path that the backend was mounted at
userpass_login_request = OpenbaoClient::UserpassLoginRequest.new # UserpassLoginRequest | 

begin
  # Log in with a username and password.
  api_instance.userpass_login(username, userpass_mount_path, userpass_login_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_login: #{e}"
end
```

#### Using the userpass_login_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> userpass_login_with_http_info(username, userpass_mount_path, userpass_login_request)

```ruby
begin
  # Log in with a username and password.
  data, status_code, headers = api_instance.userpass_login_with_http_info(username, userpass_mount_path, userpass_login_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_login_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **username** | **String** | Username of the user. |  |
| **userpass_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;userpass&#39;] |
| **userpass_login_request** | [**UserpassLoginRequest**](UserpassLoginRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## userpass_read_user

> userpass_read_user(username, userpass_mount_path)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
username = 'username_example' # String | Username for this user.
userpass_mount_path = 'userpass_mount_path_example' # String | Path that the backend was mounted at

begin
  # Manage users allowed to authenticate.
  api_instance.userpass_read_user(username, userpass_mount_path)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_read_user: #{e}"
end
```

#### Using the userpass_read_user_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> userpass_read_user_with_http_info(username, userpass_mount_path)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.userpass_read_user_with_http_info(username, userpass_mount_path)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_read_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **username** | **String** | Username for this user. |  |
| **userpass_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;userpass&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## userpass_reset_password

> userpass_reset_password(username, userpass_mount_path, userpass_reset_password_request)

Reset user's password.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
username = 'username_example' # String | Username for this user.
userpass_mount_path = 'userpass_mount_path_example' # String | Path that the backend was mounted at
userpass_reset_password_request = OpenbaoClient::UserpassResetPasswordRequest.new # UserpassResetPasswordRequest | 

begin
  # Reset user's password.
  api_instance.userpass_reset_password(username, userpass_mount_path, userpass_reset_password_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_reset_password: #{e}"
end
```

#### Using the userpass_reset_password_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> userpass_reset_password_with_http_info(username, userpass_mount_path, userpass_reset_password_request)

```ruby
begin
  # Reset user's password.
  data, status_code, headers = api_instance.userpass_reset_password_with_http_info(username, userpass_mount_path, userpass_reset_password_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_reset_password_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **username** | **String** | Username for this user. |  |
| **userpass_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;userpass&#39;] |
| **userpass_reset_password_request** | [**UserpassResetPasswordRequest**](UserpassResetPasswordRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## userpass_update_policies

> userpass_update_policies(username, userpass_mount_path, userpass_update_policies_request)

Update the policies associated with the username.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
username = 'username_example' # String | Username for this user.
userpass_mount_path = 'userpass_mount_path_example' # String | Path that the backend was mounted at
userpass_update_policies_request = OpenbaoClient::UserpassUpdatePoliciesRequest.new # UserpassUpdatePoliciesRequest | 

begin
  # Update the policies associated with the username.
  api_instance.userpass_update_policies(username, userpass_mount_path, userpass_update_policies_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_update_policies: #{e}"
end
```

#### Using the userpass_update_policies_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> userpass_update_policies_with_http_info(username, userpass_mount_path, userpass_update_policies_request)

```ruby
begin
  # Update the policies associated with the username.
  data, status_code, headers = api_instance.userpass_update_policies_with_http_info(username, userpass_mount_path, userpass_update_policies_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_update_policies_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **username** | **String** | Username for this user. |  |
| **userpass_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;userpass&#39;] |
| **userpass_update_policies_request** | [**UserpassUpdatePoliciesRequest**](UserpassUpdatePoliciesRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## userpass_write_user

> userpass_write_user(username, userpass_mount_path, userpass_write_user_request)

Manage users allowed to authenticate.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::AuthApi.new
username = 'username_example' # String | Username for this user.
userpass_mount_path = 'userpass_mount_path_example' # String | Path that the backend was mounted at
userpass_write_user_request = OpenbaoClient::UserpassWriteUserRequest.new # UserpassWriteUserRequest | 

begin
  # Manage users allowed to authenticate.
  api_instance.userpass_write_user(username, userpass_mount_path, userpass_write_user_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_write_user: #{e}"
end
```

#### Using the userpass_write_user_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> userpass_write_user_with_http_info(username, userpass_mount_path, userpass_write_user_request)

```ruby
begin
  # Manage users allowed to authenticate.
  data, status_code, headers = api_instance.userpass_write_user_with_http_info(username, userpass_mount_path, userpass_write_user_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling AuthApi->userpass_write_user_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **username** | **String** | Username for this user. |  |
| **userpass_mount_path** | **String** | Path that the backend was mounted at | [default to &#39;userpass&#39;] |
| **userpass_write_user_request** | [**UserpassWriteUserRequest**](UserpassWriteUserRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined

