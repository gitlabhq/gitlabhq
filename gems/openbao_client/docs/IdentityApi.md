# OpenbaoClient::IdentityApi

All URIs are relative to *http://localhost*

| Method | HTTP request | Description |
| ------ | ------------ | ----------- |
| [**alias_create**](IdentityApi.md#alias_create) | **POST** /identity/alias | Create a new alias. |
| [**alias_delete_by_id**](IdentityApi.md#alias_delete_by_id) | **DELETE** /identity/alias/id/{id} |  |
| [**alias_list_by_id**](IdentityApi.md#alias_list_by_id) | **GET** /identity/alias/id | List all the alias IDs. |
| [**alias_read_by_id**](IdentityApi.md#alias_read_by_id) | **GET** /identity/alias/id/{id} |  |
| [**alias_update_by_id**](IdentityApi.md#alias_update_by_id) | **POST** /identity/alias/id/{id} |  |
| [**entity_batch_delete**](IdentityApi.md#entity_batch_delete) | **POST** /identity/entity/batch-delete |  |
| [**entity_create**](IdentityApi.md#entity_create) | **POST** /identity/entity |  |
| [**entity_create_alias**](IdentityApi.md#entity_create_alias) | **POST** /identity/entity-alias | Create a new alias. |
| [**entity_delete_alias_by_id**](IdentityApi.md#entity_delete_alias_by_id) | **DELETE** /identity/entity-alias/id/{id} |  |
| [**entity_delete_by_id**](IdentityApi.md#entity_delete_by_id) | **DELETE** /identity/entity/id/{id} |  |
| [**entity_delete_by_name**](IdentityApi.md#entity_delete_by_name) | **DELETE** /identity/entity/name/{name} |  |
| [**entity_list_aliases_by_id**](IdentityApi.md#entity_list_aliases_by_id) | **GET** /identity/entity-alias/id | List all the alias IDs. |
| [**entity_list_by_id**](IdentityApi.md#entity_list_by_id) | **GET** /identity/entity/id |  |
| [**entity_list_by_name**](IdentityApi.md#entity_list_by_name) | **GET** /identity/entity/name |  |
| [**entity_look_up**](IdentityApi.md#entity_look_up) | **POST** /identity/lookup/entity | Query entities based on various properties. |
| [**entity_merge**](IdentityApi.md#entity_merge) | **POST** /identity/entity/merge |  |
| [**entity_read_alias_by_id**](IdentityApi.md#entity_read_alias_by_id) | **GET** /identity/entity-alias/id/{id} |  |
| [**entity_read_by_id**](IdentityApi.md#entity_read_by_id) | **GET** /identity/entity/id/{id} |  |
| [**entity_read_by_name**](IdentityApi.md#entity_read_by_name) | **GET** /identity/entity/name/{name} |  |
| [**entity_update_alias_by_id**](IdentityApi.md#entity_update_alias_by_id) | **POST** /identity/entity-alias/id/{id} |  |
| [**entity_update_by_id**](IdentityApi.md#entity_update_by_id) | **POST** /identity/entity/id/{id} |  |
| [**entity_update_by_name**](IdentityApi.md#entity_update_by_name) | **POST** /identity/entity/name/{name} |  |
| [**group_create**](IdentityApi.md#group_create) | **POST** /identity/group |  |
| [**group_create_alias**](IdentityApi.md#group_create_alias) | **POST** /identity/group-alias | Creates a new group alias, or updates an existing one. |
| [**group_delete_alias_by_id**](IdentityApi.md#group_delete_alias_by_id) | **DELETE** /identity/group-alias/id/{id} |  |
| [**group_delete_by_id**](IdentityApi.md#group_delete_by_id) | **DELETE** /identity/group/id/{id} |  |
| [**group_delete_by_name**](IdentityApi.md#group_delete_by_name) | **DELETE** /identity/group/name/{name} |  |
| [**group_list_aliases_by_id**](IdentityApi.md#group_list_aliases_by_id) | **GET** /identity/group-alias/id | List all the group alias IDs. |
| [**group_list_by_id**](IdentityApi.md#group_list_by_id) | **GET** /identity/group/id | List all the group IDs. |
| [**group_list_by_name**](IdentityApi.md#group_list_by_name) | **GET** /identity/group/name |  |
| [**group_look_up**](IdentityApi.md#group_look_up) | **POST** /identity/lookup/group | Query groups based on various properties. |
| [**group_read_alias_by_id**](IdentityApi.md#group_read_alias_by_id) | **GET** /identity/group-alias/id/{id} |  |
| [**group_read_by_id**](IdentityApi.md#group_read_by_id) | **GET** /identity/group/id/{id} |  |
| [**group_read_by_name**](IdentityApi.md#group_read_by_name) | **GET** /identity/group/name/{name} |  |
| [**group_update_alias_by_id**](IdentityApi.md#group_update_alias_by_id) | **POST** /identity/group-alias/id/{id} |  |
| [**group_update_by_id**](IdentityApi.md#group_update_by_id) | **POST** /identity/group/id/{id} |  |
| [**group_update_by_name**](IdentityApi.md#group_update_by_name) | **POST** /identity/group/name/{name} |  |
| [**mfa_admin_destroy_totp_secret**](IdentityApi.md#mfa_admin_destroy_totp_secret) | **POST** /identity/mfa/method/totp/admin-destroy | Destroys a TOTP secret for the given MFA method ID on the given entity |
| [**mfa_admin_generate_totp_secret**](IdentityApi.md#mfa_admin_generate_totp_secret) | **POST** /identity/mfa/method/totp/admin-generate | Update or create TOTP secret for the given method ID on the given entity. |
| [**mfa_configure_duo_method**](IdentityApi.md#mfa_configure_duo_method) | **POST** /identity/mfa/method/duo/{method_id} | Update or create a configuration for the given MFA method |
| [**mfa_configure_okta_method**](IdentityApi.md#mfa_configure_okta_method) | **POST** /identity/mfa/method/okta/{method_id} | Update or create a configuration for the given MFA method |
| [**mfa_configure_ping_id_method**](IdentityApi.md#mfa_configure_ping_id_method) | **POST** /identity/mfa/method/pingid/{method_id} | Update or create a configuration for the given MFA method |
| [**mfa_configure_totp_method**](IdentityApi.md#mfa_configure_totp_method) | **POST** /identity/mfa/method/totp/{method_id} | Update or create a configuration for the given MFA method |
| [**mfa_delete_duo_method**](IdentityApi.md#mfa_delete_duo_method) | **DELETE** /identity/mfa/method/duo/{method_id} | Delete a configuration for the given MFA method |
| [**mfa_delete_login_enforcement**](IdentityApi.md#mfa_delete_login_enforcement) | **DELETE** /identity/mfa/login-enforcement/{name} | Delete a login enforcement |
| [**mfa_delete_okta_method**](IdentityApi.md#mfa_delete_okta_method) | **DELETE** /identity/mfa/method/okta/{method_id} | Delete a configuration for the given MFA method |
| [**mfa_delete_ping_id_method**](IdentityApi.md#mfa_delete_ping_id_method) | **DELETE** /identity/mfa/method/pingid/{method_id} | Delete a configuration for the given MFA method |
| [**mfa_delete_totp_method**](IdentityApi.md#mfa_delete_totp_method) | **DELETE** /identity/mfa/method/totp/{method_id} | Delete a configuration for the given MFA method |
| [**mfa_generate_totp_secret**](IdentityApi.md#mfa_generate_totp_secret) | **POST** /identity/mfa/method/totp/generate | Update or create TOTP secret for the given method ID on the given entity. |
| [**mfa_list_duo_methods**](IdentityApi.md#mfa_list_duo_methods) | **GET** /identity/mfa/method/duo | List MFA method configurations for the given MFA method |
| [**mfa_list_login_enforcements**](IdentityApi.md#mfa_list_login_enforcements) | **GET** /identity/mfa/login-enforcement | List login enforcements |
| [**mfa_list_methods**](IdentityApi.md#mfa_list_methods) | **GET** /identity/mfa/method | List MFA method configurations for all MFA methods |
| [**mfa_list_okta_methods**](IdentityApi.md#mfa_list_okta_methods) | **GET** /identity/mfa/method/okta | List MFA method configurations for the given MFA method |
| [**mfa_list_ping_id_methods**](IdentityApi.md#mfa_list_ping_id_methods) | **GET** /identity/mfa/method/pingid | List MFA method configurations for the given MFA method |
| [**mfa_list_totp_methods**](IdentityApi.md#mfa_list_totp_methods) | **GET** /identity/mfa/method/totp | List MFA method configurations for the given MFA method |
| [**mfa_read_duo_method_configuration**](IdentityApi.md#mfa_read_duo_method_configuration) | **GET** /identity/mfa/method/duo/{method_id} | Read the current configuration for the given MFA method |
| [**mfa_read_login_enforcement**](IdentityApi.md#mfa_read_login_enforcement) | **GET** /identity/mfa/login-enforcement/{name} | Read the current login enforcement |
| [**mfa_read_method_configuration**](IdentityApi.md#mfa_read_method_configuration) | **GET** /identity/mfa/method/{method_id} | Read the current configuration for the given ID regardless of the MFA method type |
| [**mfa_read_okta_method_configuration**](IdentityApi.md#mfa_read_okta_method_configuration) | **GET** /identity/mfa/method/okta/{method_id} | Read the current configuration for the given MFA method |
| [**mfa_read_ping_id_method_configuration**](IdentityApi.md#mfa_read_ping_id_method_configuration) | **GET** /identity/mfa/method/pingid/{method_id} | Read the current configuration for the given MFA method |
| [**mfa_read_totp_method_configuration**](IdentityApi.md#mfa_read_totp_method_configuration) | **GET** /identity/mfa/method/totp/{method_id} | Read the current configuration for the given MFA method |
| [**mfa_write_login_enforcement**](IdentityApi.md#mfa_write_login_enforcement) | **POST** /identity/mfa/login-enforcement/{name} | Create or update a login enforcement |
| [**oidc_configure**](IdentityApi.md#oidc_configure) | **POST** /identity/oidc/config |  |
| [**oidc_delete_assignment**](IdentityApi.md#oidc_delete_assignment) | **DELETE** /identity/oidc/assignment/{name} |  |
| [**oidc_delete_client**](IdentityApi.md#oidc_delete_client) | **DELETE** /identity/oidc/client/{name} |  |
| [**oidc_delete_key**](IdentityApi.md#oidc_delete_key) | **DELETE** /identity/oidc/key/{name} | CRUD operations for OIDC keys. |
| [**oidc_delete_provider**](IdentityApi.md#oidc_delete_provider) | **DELETE** /identity/oidc/provider/{name} |  |
| [**oidc_delete_role**](IdentityApi.md#oidc_delete_role) | **DELETE** /identity/oidc/role/{name} | CRUD operations on OIDC Roles |
| [**oidc_delete_scope**](IdentityApi.md#oidc_delete_scope) | **DELETE** /identity/oidc/scope/{name} |  |
| [**oidc_generate_token**](IdentityApi.md#oidc_generate_token) | **GET** /identity/oidc/token/{name} | Generate an OIDC token |
| [**oidc_introspect**](IdentityApi.md#oidc_introspect) | **POST** /identity/oidc/introspect | Verify the authenticity of an OIDC token |
| [**oidc_list_assignments**](IdentityApi.md#oidc_list_assignments) | **GET** /identity/oidc/assignment |  |
| [**oidc_list_clients**](IdentityApi.md#oidc_list_clients) | **GET** /identity/oidc/client |  |
| [**oidc_list_keys**](IdentityApi.md#oidc_list_keys) | **GET** /identity/oidc/key | List OIDC keys |
| [**oidc_list_providers**](IdentityApi.md#oidc_list_providers) | **GET** /identity/oidc/provider |  |
| [**oidc_list_roles**](IdentityApi.md#oidc_list_roles) | **GET** /identity/oidc/role | List configured OIDC roles |
| [**oidc_list_scopes**](IdentityApi.md#oidc_list_scopes) | **GET** /identity/oidc/scope |  |
| [**oidc_provider_authorize**](IdentityApi.md#oidc_provider_authorize) | **GET** /identity/oidc/provider/{name}/authorize |  |
| [**oidc_provider_authorize_with_parameters**](IdentityApi.md#oidc_provider_authorize_with_parameters) | **POST** /identity/oidc/provider/{name}/authorize |  |
| [**oidc_provider_token**](IdentityApi.md#oidc_provider_token) | **POST** /identity/oidc/provider/{name}/token |  |
| [**oidc_provider_user_info**](IdentityApi.md#oidc_provider_user_info) | **GET** /identity/oidc/provider/{name}/userinfo |  |
| [**oidc_provider_user_info2**](IdentityApi.md#oidc_provider_user_info2) | **POST** /identity/oidc/provider/{name}/userinfo |  |
| [**oidc_read_assignment**](IdentityApi.md#oidc_read_assignment) | **GET** /identity/oidc/assignment/{name} |  |
| [**oidc_read_client**](IdentityApi.md#oidc_read_client) | **GET** /identity/oidc/client/{name} |  |
| [**oidc_read_configuration**](IdentityApi.md#oidc_read_configuration) | **GET** /identity/oidc/config |  |
| [**oidc_read_key**](IdentityApi.md#oidc_read_key) | **GET** /identity/oidc/key/{name} | CRUD operations for OIDC keys. |
| [**oidc_read_open_id_configuration**](IdentityApi.md#oidc_read_open_id_configuration) | **GET** /identity/oidc/.well-known/openid-configuration | Query OIDC configurations |
| [**oidc_read_provider**](IdentityApi.md#oidc_read_provider) | **GET** /identity/oidc/provider/{name} |  |
| [**oidc_read_provider_open_id_configuration**](IdentityApi.md#oidc_read_provider_open_id_configuration) | **GET** /identity/oidc/provider/{name}/.well-known/openid-configuration |  |
| [**oidc_read_provider_public_keys**](IdentityApi.md#oidc_read_provider_public_keys) | **GET** /identity/oidc/provider/{name}/.well-known/keys |  |
| [**oidc_read_public_keys**](IdentityApi.md#oidc_read_public_keys) | **GET** /identity/oidc/.well-known/keys | Retrieve public keys |
| [**oidc_read_role**](IdentityApi.md#oidc_read_role) | **GET** /identity/oidc/role/{name} | CRUD operations on OIDC Roles |
| [**oidc_read_scope**](IdentityApi.md#oidc_read_scope) | **GET** /identity/oidc/scope/{name} |  |
| [**oidc_rotate_key**](IdentityApi.md#oidc_rotate_key) | **POST** /identity/oidc/key/{name}/rotate | Rotate a named OIDC key. |
| [**oidc_write_assignment**](IdentityApi.md#oidc_write_assignment) | **POST** /identity/oidc/assignment/{name} |  |
| [**oidc_write_client**](IdentityApi.md#oidc_write_client) | **POST** /identity/oidc/client/{name} |  |
| [**oidc_write_key**](IdentityApi.md#oidc_write_key) | **POST** /identity/oidc/key/{name} | CRUD operations for OIDC keys. |
| [**oidc_write_provider**](IdentityApi.md#oidc_write_provider) | **POST** /identity/oidc/provider/{name} |  |
| [**oidc_write_role**](IdentityApi.md#oidc_write_role) | **POST** /identity/oidc/role/{name} | CRUD operations on OIDC Roles |
| [**oidc_write_scope**](IdentityApi.md#oidc_write_scope) | **POST** /identity/oidc/scope/{name} |  |
| [**persona_create**](IdentityApi.md#persona_create) | **POST** /identity/persona | Create a new alias. |
| [**persona_delete_by_id**](IdentityApi.md#persona_delete_by_id) | **DELETE** /identity/persona/id/{id} |  |
| [**persona_list_by_id**](IdentityApi.md#persona_list_by_id) | **GET** /identity/persona/id | List all the alias IDs. |
| [**persona_read_by_id**](IdentityApi.md#persona_read_by_id) | **GET** /identity/persona/id/{id} |  |
| [**persona_update_by_id**](IdentityApi.md#persona_update_by_id) | **POST** /identity/persona/id/{id} |  |


## alias_create

> alias_create(alias_create_request)

Create a new alias.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
alias_create_request = OpenbaoClient::AliasCreateRequest.new # AliasCreateRequest | 

begin
  # Create a new alias.
  api_instance.alias_create(alias_create_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->alias_create: #{e}"
end
```

#### Using the alias_create_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> alias_create_with_http_info(alias_create_request)

```ruby
begin
  # Create a new alias.
  data, status_code, headers = api_instance.alias_create_with_http_info(alias_create_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->alias_create_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **alias_create_request** | [**AliasCreateRequest**](AliasCreateRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## alias_delete_by_id

> alias_delete_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the alias

begin
  
  api_instance.alias_delete_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->alias_delete_by_id: #{e}"
end
```

#### Using the alias_delete_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> alias_delete_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.alias_delete_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->alias_delete_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the alias |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## alias_list_by_id

> alias_list_by_id(list)

List all the alias IDs.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List all the alias IDs.
  api_instance.alias_list_by_id(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->alias_list_by_id: #{e}"
end
```

#### Using the alias_list_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> alias_list_by_id_with_http_info(list)

```ruby
begin
  # List all the alias IDs.
  data, status_code, headers = api_instance.alias_list_by_id_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->alias_list_by_id_with_http_info: #{e}"
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


## alias_read_by_id

> alias_read_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the alias

begin
  
  api_instance.alias_read_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->alias_read_by_id: #{e}"
end
```

#### Using the alias_read_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> alias_read_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.alias_read_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->alias_read_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the alias |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## alias_update_by_id

> alias_update_by_id(id, alias_update_by_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the alias
alias_update_by_id_request = OpenbaoClient::AliasUpdateByIdRequest.new # AliasUpdateByIdRequest | 

begin
  
  api_instance.alias_update_by_id(id, alias_update_by_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->alias_update_by_id: #{e}"
end
```

#### Using the alias_update_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> alias_update_by_id_with_http_info(id, alias_update_by_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.alias_update_by_id_with_http_info(id, alias_update_by_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->alias_update_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the alias |  |
| **alias_update_by_id_request** | [**AliasUpdateByIdRequest**](AliasUpdateByIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## entity_batch_delete

> entity_batch_delete(entity_batch_delete_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
entity_batch_delete_request = OpenbaoClient::EntityBatchDeleteRequest.new # EntityBatchDeleteRequest | 

begin
  
  api_instance.entity_batch_delete(entity_batch_delete_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_batch_delete: #{e}"
end
```

#### Using the entity_batch_delete_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_batch_delete_with_http_info(entity_batch_delete_request)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_batch_delete_with_http_info(entity_batch_delete_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_batch_delete_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **entity_batch_delete_request** | [**EntityBatchDeleteRequest**](EntityBatchDeleteRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## entity_create

> entity_create(entity_create_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
entity_create_request = OpenbaoClient::EntityCreateRequest.new # EntityCreateRequest | 

begin
  
  api_instance.entity_create(entity_create_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_create: #{e}"
end
```

#### Using the entity_create_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_create_with_http_info(entity_create_request)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_create_with_http_info(entity_create_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_create_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **entity_create_request** | [**EntityCreateRequest**](EntityCreateRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## entity_create_alias

> entity_create_alias(entity_create_alias_request)

Create a new alias.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
entity_create_alias_request = OpenbaoClient::EntityCreateAliasRequest.new # EntityCreateAliasRequest | 

begin
  # Create a new alias.
  api_instance.entity_create_alias(entity_create_alias_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_create_alias: #{e}"
end
```

#### Using the entity_create_alias_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_create_alias_with_http_info(entity_create_alias_request)

```ruby
begin
  # Create a new alias.
  data, status_code, headers = api_instance.entity_create_alias_with_http_info(entity_create_alias_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_create_alias_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **entity_create_alias_request** | [**EntityCreateAliasRequest**](EntityCreateAliasRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## entity_delete_alias_by_id

> entity_delete_alias_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the alias

begin
  
  api_instance.entity_delete_alias_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_delete_alias_by_id: #{e}"
end
```

#### Using the entity_delete_alias_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_delete_alias_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_delete_alias_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_delete_alias_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the alias |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## entity_delete_by_id

> entity_delete_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the entity. If set, updates the corresponding existing entity.

begin
  
  api_instance.entity_delete_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_delete_by_id: #{e}"
end
```

#### Using the entity_delete_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_delete_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_delete_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_delete_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the entity. If set, updates the corresponding existing entity. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## entity_delete_by_name

> entity_delete_by_name(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the entity

begin
  
  api_instance.entity_delete_by_name(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_delete_by_name: #{e}"
end
```

#### Using the entity_delete_by_name_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_delete_by_name_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_delete_by_name_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_delete_by_name_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the entity |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## entity_list_aliases_by_id

> entity_list_aliases_by_id(list)

List all the alias IDs.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List all the alias IDs.
  api_instance.entity_list_aliases_by_id(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_list_aliases_by_id: #{e}"
end
```

#### Using the entity_list_aliases_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_list_aliases_by_id_with_http_info(list)

```ruby
begin
  # List all the alias IDs.
  data, status_code, headers = api_instance.entity_list_aliases_by_id_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_list_aliases_by_id_with_http_info: #{e}"
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


## entity_list_by_id

> entity_list_by_id(list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.entity_list_by_id(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_list_by_id: #{e}"
end
```

#### Using the entity_list_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_list_by_id_with_http_info(list)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_list_by_id_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_list_by_id_with_http_info: #{e}"
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


## entity_list_by_name

> entity_list_by_name(list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.entity_list_by_name(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_list_by_name: #{e}"
end
```

#### Using the entity_list_by_name_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_list_by_name_with_http_info(list)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_list_by_name_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_list_by_name_with_http_info: #{e}"
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


## entity_look_up

> entity_look_up(entity_look_up_request)

Query entities based on various properties.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
entity_look_up_request = OpenbaoClient::EntityLookUpRequest.new # EntityLookUpRequest | 

begin
  # Query entities based on various properties.
  api_instance.entity_look_up(entity_look_up_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_look_up: #{e}"
end
```

#### Using the entity_look_up_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_look_up_with_http_info(entity_look_up_request)

```ruby
begin
  # Query entities based on various properties.
  data, status_code, headers = api_instance.entity_look_up_with_http_info(entity_look_up_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_look_up_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **entity_look_up_request** | [**EntityLookUpRequest**](EntityLookUpRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## entity_merge

> entity_merge(entity_merge_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
entity_merge_request = OpenbaoClient::EntityMergeRequest.new # EntityMergeRequest | 

begin
  
  api_instance.entity_merge(entity_merge_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_merge: #{e}"
end
```

#### Using the entity_merge_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_merge_with_http_info(entity_merge_request)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_merge_with_http_info(entity_merge_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_merge_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **entity_merge_request** | [**EntityMergeRequest**](EntityMergeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## entity_read_alias_by_id

> entity_read_alias_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the alias

begin
  
  api_instance.entity_read_alias_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_read_alias_by_id: #{e}"
end
```

#### Using the entity_read_alias_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_read_alias_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_read_alias_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_read_alias_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the alias |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## entity_read_by_id

> entity_read_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the entity. If set, updates the corresponding existing entity.

begin
  
  api_instance.entity_read_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_read_by_id: #{e}"
end
```

#### Using the entity_read_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_read_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_read_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_read_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the entity. If set, updates the corresponding existing entity. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## entity_read_by_name

> entity_read_by_name(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the entity

begin
  
  api_instance.entity_read_by_name(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_read_by_name: #{e}"
end
```

#### Using the entity_read_by_name_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_read_by_name_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_read_by_name_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_read_by_name_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the entity |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## entity_update_alias_by_id

> entity_update_alias_by_id(id, entity_update_alias_by_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the alias
entity_update_alias_by_id_request = OpenbaoClient::EntityUpdateAliasByIdRequest.new # EntityUpdateAliasByIdRequest | 

begin
  
  api_instance.entity_update_alias_by_id(id, entity_update_alias_by_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_update_alias_by_id: #{e}"
end
```

#### Using the entity_update_alias_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_update_alias_by_id_with_http_info(id, entity_update_alias_by_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_update_alias_by_id_with_http_info(id, entity_update_alias_by_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_update_alias_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the alias |  |
| **entity_update_alias_by_id_request** | [**EntityUpdateAliasByIdRequest**](EntityUpdateAliasByIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## entity_update_by_id

> entity_update_by_id(id, entity_update_by_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the entity. If set, updates the corresponding existing entity.
entity_update_by_id_request = OpenbaoClient::EntityUpdateByIdRequest.new # EntityUpdateByIdRequest | 

begin
  
  api_instance.entity_update_by_id(id, entity_update_by_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_update_by_id: #{e}"
end
```

#### Using the entity_update_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_update_by_id_with_http_info(id, entity_update_by_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_update_by_id_with_http_info(id, entity_update_by_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_update_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the entity. If set, updates the corresponding existing entity. |  |
| **entity_update_by_id_request** | [**EntityUpdateByIdRequest**](EntityUpdateByIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## entity_update_by_name

> entity_update_by_name(name, entity_update_by_name_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the entity
entity_update_by_name_request = OpenbaoClient::EntityUpdateByNameRequest.new # EntityUpdateByNameRequest | 

begin
  
  api_instance.entity_update_by_name(name, entity_update_by_name_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_update_by_name: #{e}"
end
```

#### Using the entity_update_by_name_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> entity_update_by_name_with_http_info(name, entity_update_by_name_request)

```ruby
begin
  
  data, status_code, headers = api_instance.entity_update_by_name_with_http_info(name, entity_update_by_name_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->entity_update_by_name_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the entity |  |
| **entity_update_by_name_request** | [**EntityUpdateByNameRequest**](EntityUpdateByNameRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## group_create

> group_create(group_create_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
group_create_request = OpenbaoClient::GroupCreateRequest.new # GroupCreateRequest | 

begin
  
  api_instance.group_create(group_create_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_create: #{e}"
end
```

#### Using the group_create_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_create_with_http_info(group_create_request)

```ruby
begin
  
  data, status_code, headers = api_instance.group_create_with_http_info(group_create_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_create_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **group_create_request** | [**GroupCreateRequest**](GroupCreateRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## group_create_alias

> group_create_alias(group_create_alias_request)

Creates a new group alias, or updates an existing one.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
group_create_alias_request = OpenbaoClient::GroupCreateAliasRequest.new # GroupCreateAliasRequest | 

begin
  # Creates a new group alias, or updates an existing one.
  api_instance.group_create_alias(group_create_alias_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_create_alias: #{e}"
end
```

#### Using the group_create_alias_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_create_alias_with_http_info(group_create_alias_request)

```ruby
begin
  # Creates a new group alias, or updates an existing one.
  data, status_code, headers = api_instance.group_create_alias_with_http_info(group_create_alias_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_create_alias_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **group_create_alias_request** | [**GroupCreateAliasRequest**](GroupCreateAliasRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## group_delete_alias_by_id

> group_delete_alias_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the group alias.

begin
  
  api_instance.group_delete_alias_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_delete_alias_by_id: #{e}"
end
```

#### Using the group_delete_alias_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_delete_alias_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.group_delete_alias_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_delete_alias_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the group alias. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## group_delete_by_id

> group_delete_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the group. If set, updates the corresponding existing group.

begin
  
  api_instance.group_delete_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_delete_by_id: #{e}"
end
```

#### Using the group_delete_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_delete_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.group_delete_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_delete_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the group. If set, updates the corresponding existing group. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## group_delete_by_name

> group_delete_by_name(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the group.

begin
  
  api_instance.group_delete_by_name(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_delete_by_name: #{e}"
end
```

#### Using the group_delete_by_name_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_delete_by_name_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.group_delete_by_name_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_delete_by_name_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the group. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## group_list_aliases_by_id

> group_list_aliases_by_id(list)

List all the group alias IDs.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List all the group alias IDs.
  api_instance.group_list_aliases_by_id(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_list_aliases_by_id: #{e}"
end
```

#### Using the group_list_aliases_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_list_aliases_by_id_with_http_info(list)

```ruby
begin
  # List all the group alias IDs.
  data, status_code, headers = api_instance.group_list_aliases_by_id_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_list_aliases_by_id_with_http_info: #{e}"
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


## group_list_by_id

> group_list_by_id(list)

List all the group IDs.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List all the group IDs.
  api_instance.group_list_by_id(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_list_by_id: #{e}"
end
```

#### Using the group_list_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_list_by_id_with_http_info(list)

```ruby
begin
  # List all the group IDs.
  data, status_code, headers = api_instance.group_list_by_id_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_list_by_id_with_http_info: #{e}"
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


## group_list_by_name

> group_list_by_name(list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.group_list_by_name(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_list_by_name: #{e}"
end
```

#### Using the group_list_by_name_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_list_by_name_with_http_info(list)

```ruby
begin
  
  data, status_code, headers = api_instance.group_list_by_name_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_list_by_name_with_http_info: #{e}"
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


## group_look_up

> group_look_up(group_look_up_request)

Query groups based on various properties.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
group_look_up_request = OpenbaoClient::GroupLookUpRequest.new # GroupLookUpRequest | 

begin
  # Query groups based on various properties.
  api_instance.group_look_up(group_look_up_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_look_up: #{e}"
end
```

#### Using the group_look_up_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_look_up_with_http_info(group_look_up_request)

```ruby
begin
  # Query groups based on various properties.
  data, status_code, headers = api_instance.group_look_up_with_http_info(group_look_up_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_look_up_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **group_look_up_request** | [**GroupLookUpRequest**](GroupLookUpRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## group_read_alias_by_id

> group_read_alias_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the group alias.

begin
  
  api_instance.group_read_alias_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_read_alias_by_id: #{e}"
end
```

#### Using the group_read_alias_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_read_alias_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.group_read_alias_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_read_alias_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the group alias. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## group_read_by_id

> group_read_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the group. If set, updates the corresponding existing group.

begin
  
  api_instance.group_read_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_read_by_id: #{e}"
end
```

#### Using the group_read_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_read_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.group_read_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_read_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the group. If set, updates the corresponding existing group. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## group_read_by_name

> group_read_by_name(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the group.

begin
  
  api_instance.group_read_by_name(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_read_by_name: #{e}"
end
```

#### Using the group_read_by_name_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_read_by_name_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.group_read_by_name_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_read_by_name_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the group. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## group_update_alias_by_id

> group_update_alias_by_id(id, group_update_alias_by_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the group alias.
group_update_alias_by_id_request = OpenbaoClient::GroupUpdateAliasByIdRequest.new # GroupUpdateAliasByIdRequest | 

begin
  
  api_instance.group_update_alias_by_id(id, group_update_alias_by_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_update_alias_by_id: #{e}"
end
```

#### Using the group_update_alias_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_update_alias_by_id_with_http_info(id, group_update_alias_by_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.group_update_alias_by_id_with_http_info(id, group_update_alias_by_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_update_alias_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the group alias. |  |
| **group_update_alias_by_id_request** | [**GroupUpdateAliasByIdRequest**](GroupUpdateAliasByIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## group_update_by_id

> group_update_by_id(id, group_update_by_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the group. If set, updates the corresponding existing group.
group_update_by_id_request = OpenbaoClient::GroupUpdateByIdRequest.new # GroupUpdateByIdRequest | 

begin
  
  api_instance.group_update_by_id(id, group_update_by_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_update_by_id: #{e}"
end
```

#### Using the group_update_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_update_by_id_with_http_info(id, group_update_by_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.group_update_by_id_with_http_info(id, group_update_by_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_update_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the group. If set, updates the corresponding existing group. |  |
| **group_update_by_id_request** | [**GroupUpdateByIdRequest**](GroupUpdateByIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## group_update_by_name

> group_update_by_name(name, group_update_by_name_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the group.
group_update_by_name_request = OpenbaoClient::GroupUpdateByNameRequest.new # GroupUpdateByNameRequest | 

begin
  
  api_instance.group_update_by_name(name, group_update_by_name_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_update_by_name: #{e}"
end
```

#### Using the group_update_by_name_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> group_update_by_name_with_http_info(name, group_update_by_name_request)

```ruby
begin
  
  data, status_code, headers = api_instance.group_update_by_name_with_http_info(name, group_update_by_name_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->group_update_by_name_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the group. |  |
| **group_update_by_name_request** | [**GroupUpdateByNameRequest**](GroupUpdateByNameRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## mfa_admin_destroy_totp_secret

> mfa_admin_destroy_totp_secret(mfa_admin_destroy_totp_secret_request)

Destroys a TOTP secret for the given MFA method ID on the given entity

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
mfa_admin_destroy_totp_secret_request = OpenbaoClient::MfaAdminDestroyTotpSecretRequest.new({entity_id: 'entity_id_example', method_id: 'method_id_example'}) # MfaAdminDestroyTotpSecretRequest | 

begin
  # Destroys a TOTP secret for the given MFA method ID on the given entity
  api_instance.mfa_admin_destroy_totp_secret(mfa_admin_destroy_totp_secret_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_admin_destroy_totp_secret: #{e}"
end
```

#### Using the mfa_admin_destroy_totp_secret_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_admin_destroy_totp_secret_with_http_info(mfa_admin_destroy_totp_secret_request)

```ruby
begin
  # Destroys a TOTP secret for the given MFA method ID on the given entity
  data, status_code, headers = api_instance.mfa_admin_destroy_totp_secret_with_http_info(mfa_admin_destroy_totp_secret_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_admin_destroy_totp_secret_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **mfa_admin_destroy_totp_secret_request** | [**MfaAdminDestroyTotpSecretRequest**](MfaAdminDestroyTotpSecretRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## mfa_admin_generate_totp_secret

> mfa_admin_generate_totp_secret(mfa_admin_generate_totp_secret_request)

Update or create TOTP secret for the given method ID on the given entity.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
mfa_admin_generate_totp_secret_request = OpenbaoClient::MfaAdminGenerateTotpSecretRequest.new({entity_id: 'entity_id_example', method_id: 'method_id_example'}) # MfaAdminGenerateTotpSecretRequest | 

begin
  # Update or create TOTP secret for the given method ID on the given entity.
  api_instance.mfa_admin_generate_totp_secret(mfa_admin_generate_totp_secret_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_admin_generate_totp_secret: #{e}"
end
```

#### Using the mfa_admin_generate_totp_secret_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_admin_generate_totp_secret_with_http_info(mfa_admin_generate_totp_secret_request)

```ruby
begin
  # Update or create TOTP secret for the given method ID on the given entity.
  data, status_code, headers = api_instance.mfa_admin_generate_totp_secret_with_http_info(mfa_admin_generate_totp_secret_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_admin_generate_totp_secret_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **mfa_admin_generate_totp_secret_request** | [**MfaAdminGenerateTotpSecretRequest**](MfaAdminGenerateTotpSecretRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## mfa_configure_duo_method

> mfa_configure_duo_method(method_id, mfa_configure_duo_method_request)

Update or create a configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.
mfa_configure_duo_method_request = OpenbaoClient::MfaConfigureDuoMethodRequest.new # MfaConfigureDuoMethodRequest | 

begin
  # Update or create a configuration for the given MFA method
  api_instance.mfa_configure_duo_method(method_id, mfa_configure_duo_method_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_configure_duo_method: #{e}"
end
```

#### Using the mfa_configure_duo_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_configure_duo_method_with_http_info(method_id, mfa_configure_duo_method_request)

```ruby
begin
  # Update or create a configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_configure_duo_method_with_http_info(method_id, mfa_configure_duo_method_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_configure_duo_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |
| **mfa_configure_duo_method_request** | [**MfaConfigureDuoMethodRequest**](MfaConfigureDuoMethodRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## mfa_configure_okta_method

> mfa_configure_okta_method(method_id, mfa_configure_okta_method_request)

Update or create a configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.
mfa_configure_okta_method_request = OpenbaoClient::MfaConfigureOktaMethodRequest.new # MfaConfigureOktaMethodRequest | 

begin
  # Update or create a configuration for the given MFA method
  api_instance.mfa_configure_okta_method(method_id, mfa_configure_okta_method_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_configure_okta_method: #{e}"
end
```

#### Using the mfa_configure_okta_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_configure_okta_method_with_http_info(method_id, mfa_configure_okta_method_request)

```ruby
begin
  # Update or create a configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_configure_okta_method_with_http_info(method_id, mfa_configure_okta_method_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_configure_okta_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |
| **mfa_configure_okta_method_request** | [**MfaConfigureOktaMethodRequest**](MfaConfigureOktaMethodRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## mfa_configure_ping_id_method

> mfa_configure_ping_id_method(method_id, mfa_configure_ping_id_method_request)

Update or create a configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.
mfa_configure_ping_id_method_request = OpenbaoClient::MfaConfigurePingIdMethodRequest.new # MfaConfigurePingIdMethodRequest | 

begin
  # Update or create a configuration for the given MFA method
  api_instance.mfa_configure_ping_id_method(method_id, mfa_configure_ping_id_method_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_configure_ping_id_method: #{e}"
end
```

#### Using the mfa_configure_ping_id_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_configure_ping_id_method_with_http_info(method_id, mfa_configure_ping_id_method_request)

```ruby
begin
  # Update or create a configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_configure_ping_id_method_with_http_info(method_id, mfa_configure_ping_id_method_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_configure_ping_id_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |
| **mfa_configure_ping_id_method_request** | [**MfaConfigurePingIdMethodRequest**](MfaConfigurePingIdMethodRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## mfa_configure_totp_method

> mfa_configure_totp_method(method_id, mfa_configure_totp_method_request)

Update or create a configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.
mfa_configure_totp_method_request = OpenbaoClient::MfaConfigureTotpMethodRequest.new # MfaConfigureTotpMethodRequest | 

begin
  # Update or create a configuration for the given MFA method
  api_instance.mfa_configure_totp_method(method_id, mfa_configure_totp_method_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_configure_totp_method: #{e}"
end
```

#### Using the mfa_configure_totp_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_configure_totp_method_with_http_info(method_id, mfa_configure_totp_method_request)

```ruby
begin
  # Update or create a configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_configure_totp_method_with_http_info(method_id, mfa_configure_totp_method_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_configure_totp_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |
| **mfa_configure_totp_method_request** | [**MfaConfigureTotpMethodRequest**](MfaConfigureTotpMethodRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## mfa_delete_duo_method

> mfa_delete_duo_method(method_id)

Delete a configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.

begin
  # Delete a configuration for the given MFA method
  api_instance.mfa_delete_duo_method(method_id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_delete_duo_method: #{e}"
end
```

#### Using the mfa_delete_duo_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_delete_duo_method_with_http_info(method_id)

```ruby
begin
  # Delete a configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_delete_duo_method_with_http_info(method_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_delete_duo_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_delete_login_enforcement

> mfa_delete_login_enforcement(name)

Delete a login enforcement

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name for this login enforcement configuration

begin
  # Delete a login enforcement
  api_instance.mfa_delete_login_enforcement(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_delete_login_enforcement: #{e}"
end
```

#### Using the mfa_delete_login_enforcement_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_delete_login_enforcement_with_http_info(name)

```ruby
begin
  # Delete a login enforcement
  data, status_code, headers = api_instance.mfa_delete_login_enforcement_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_delete_login_enforcement_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name for this login enforcement configuration |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_delete_okta_method

> mfa_delete_okta_method(method_id)

Delete a configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.

begin
  # Delete a configuration for the given MFA method
  api_instance.mfa_delete_okta_method(method_id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_delete_okta_method: #{e}"
end
```

#### Using the mfa_delete_okta_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_delete_okta_method_with_http_info(method_id)

```ruby
begin
  # Delete a configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_delete_okta_method_with_http_info(method_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_delete_okta_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_delete_ping_id_method

> mfa_delete_ping_id_method(method_id)

Delete a configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.

begin
  # Delete a configuration for the given MFA method
  api_instance.mfa_delete_ping_id_method(method_id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_delete_ping_id_method: #{e}"
end
```

#### Using the mfa_delete_ping_id_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_delete_ping_id_method_with_http_info(method_id)

```ruby
begin
  # Delete a configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_delete_ping_id_method_with_http_info(method_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_delete_ping_id_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_delete_totp_method

> mfa_delete_totp_method(method_id)

Delete a configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.

begin
  # Delete a configuration for the given MFA method
  api_instance.mfa_delete_totp_method(method_id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_delete_totp_method: #{e}"
end
```

#### Using the mfa_delete_totp_method_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_delete_totp_method_with_http_info(method_id)

```ruby
begin
  # Delete a configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_delete_totp_method_with_http_info(method_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_delete_totp_method_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_generate_totp_secret

> mfa_generate_totp_secret(mfa_generate_totp_secret_request)

Update or create TOTP secret for the given method ID on the given entity.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
mfa_generate_totp_secret_request = OpenbaoClient::MfaGenerateTotpSecretRequest.new({method_id: 'method_id_example'}) # MfaGenerateTotpSecretRequest | 

begin
  # Update or create TOTP secret for the given method ID on the given entity.
  api_instance.mfa_generate_totp_secret(mfa_generate_totp_secret_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_generate_totp_secret: #{e}"
end
```

#### Using the mfa_generate_totp_secret_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_generate_totp_secret_with_http_info(mfa_generate_totp_secret_request)

```ruby
begin
  # Update or create TOTP secret for the given method ID on the given entity.
  data, status_code, headers = api_instance.mfa_generate_totp_secret_with_http_info(mfa_generate_totp_secret_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_generate_totp_secret_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **mfa_generate_totp_secret_request** | [**MfaGenerateTotpSecretRequest**](MfaGenerateTotpSecretRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## mfa_list_duo_methods

> mfa_list_duo_methods(list)

List MFA method configurations for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List MFA method configurations for the given MFA method
  api_instance.mfa_list_duo_methods(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_duo_methods: #{e}"
end
```

#### Using the mfa_list_duo_methods_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_list_duo_methods_with_http_info(list)

```ruby
begin
  # List MFA method configurations for the given MFA method
  data, status_code, headers = api_instance.mfa_list_duo_methods_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_duo_methods_with_http_info: #{e}"
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


## mfa_list_login_enforcements

> mfa_list_login_enforcements(list)

List login enforcements

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List login enforcements
  api_instance.mfa_list_login_enforcements(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_login_enforcements: #{e}"
end
```

#### Using the mfa_list_login_enforcements_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_list_login_enforcements_with_http_info(list)

```ruby
begin
  # List login enforcements
  data, status_code, headers = api_instance.mfa_list_login_enforcements_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_login_enforcements_with_http_info: #{e}"
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


## mfa_list_methods

> mfa_list_methods(list)

List MFA method configurations for all MFA methods

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List MFA method configurations for all MFA methods
  api_instance.mfa_list_methods(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_methods: #{e}"
end
```

#### Using the mfa_list_methods_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_list_methods_with_http_info(list)

```ruby
begin
  # List MFA method configurations for all MFA methods
  data, status_code, headers = api_instance.mfa_list_methods_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_methods_with_http_info: #{e}"
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


## mfa_list_okta_methods

> mfa_list_okta_methods(list)

List MFA method configurations for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List MFA method configurations for the given MFA method
  api_instance.mfa_list_okta_methods(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_okta_methods: #{e}"
end
```

#### Using the mfa_list_okta_methods_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_list_okta_methods_with_http_info(list)

```ruby
begin
  # List MFA method configurations for the given MFA method
  data, status_code, headers = api_instance.mfa_list_okta_methods_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_okta_methods_with_http_info: #{e}"
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


## mfa_list_ping_id_methods

> mfa_list_ping_id_methods(list)

List MFA method configurations for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List MFA method configurations for the given MFA method
  api_instance.mfa_list_ping_id_methods(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_ping_id_methods: #{e}"
end
```

#### Using the mfa_list_ping_id_methods_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_list_ping_id_methods_with_http_info(list)

```ruby
begin
  # List MFA method configurations for the given MFA method
  data, status_code, headers = api_instance.mfa_list_ping_id_methods_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_ping_id_methods_with_http_info: #{e}"
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


## mfa_list_totp_methods

> mfa_list_totp_methods(list)

List MFA method configurations for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List MFA method configurations for the given MFA method
  api_instance.mfa_list_totp_methods(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_totp_methods: #{e}"
end
```

#### Using the mfa_list_totp_methods_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_list_totp_methods_with_http_info(list)

```ruby
begin
  # List MFA method configurations for the given MFA method
  data, status_code, headers = api_instance.mfa_list_totp_methods_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_list_totp_methods_with_http_info: #{e}"
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


## mfa_read_duo_method_configuration

> mfa_read_duo_method_configuration(method_id)

Read the current configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.

begin
  # Read the current configuration for the given MFA method
  api_instance.mfa_read_duo_method_configuration(method_id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_duo_method_configuration: #{e}"
end
```

#### Using the mfa_read_duo_method_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_read_duo_method_configuration_with_http_info(method_id)

```ruby
begin
  # Read the current configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_read_duo_method_configuration_with_http_info(method_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_duo_method_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_read_login_enforcement

> mfa_read_login_enforcement(name)

Read the current login enforcement

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name for this login enforcement configuration

begin
  # Read the current login enforcement
  api_instance.mfa_read_login_enforcement(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_login_enforcement: #{e}"
end
```

#### Using the mfa_read_login_enforcement_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_read_login_enforcement_with_http_info(name)

```ruby
begin
  # Read the current login enforcement
  data, status_code, headers = api_instance.mfa_read_login_enforcement_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_login_enforcement_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name for this login enforcement configuration |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_read_method_configuration

> mfa_read_method_configuration(method_id)

Read the current configuration for the given ID regardless of the MFA method type

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.

begin
  # Read the current configuration for the given ID regardless of the MFA method type
  api_instance.mfa_read_method_configuration(method_id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_method_configuration: #{e}"
end
```

#### Using the mfa_read_method_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_read_method_configuration_with_http_info(method_id)

```ruby
begin
  # Read the current configuration for the given ID regardless of the MFA method type
  data, status_code, headers = api_instance.mfa_read_method_configuration_with_http_info(method_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_method_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_read_okta_method_configuration

> mfa_read_okta_method_configuration(method_id)

Read the current configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.

begin
  # Read the current configuration for the given MFA method
  api_instance.mfa_read_okta_method_configuration(method_id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_okta_method_configuration: #{e}"
end
```

#### Using the mfa_read_okta_method_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_read_okta_method_configuration_with_http_info(method_id)

```ruby
begin
  # Read the current configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_read_okta_method_configuration_with_http_info(method_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_okta_method_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_read_ping_id_method_configuration

> mfa_read_ping_id_method_configuration(method_id)

Read the current configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.

begin
  # Read the current configuration for the given MFA method
  api_instance.mfa_read_ping_id_method_configuration(method_id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_ping_id_method_configuration: #{e}"
end
```

#### Using the mfa_read_ping_id_method_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_read_ping_id_method_configuration_with_http_info(method_id)

```ruby
begin
  # Read the current configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_read_ping_id_method_configuration_with_http_info(method_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_ping_id_method_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_read_totp_method_configuration

> mfa_read_totp_method_configuration(method_id)

Read the current configuration for the given MFA method

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
method_id = 'method_id_example' # String | The unique identifier for this MFA method.

begin
  # Read the current configuration for the given MFA method
  api_instance.mfa_read_totp_method_configuration(method_id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_totp_method_configuration: #{e}"
end
```

#### Using the mfa_read_totp_method_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_read_totp_method_configuration_with_http_info(method_id)

```ruby
begin
  # Read the current configuration for the given MFA method
  data, status_code, headers = api_instance.mfa_read_totp_method_configuration_with_http_info(method_id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_read_totp_method_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **method_id** | **String** | The unique identifier for this MFA method. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## mfa_write_login_enforcement

> mfa_write_login_enforcement(name, mfa_write_login_enforcement_request)

Create or update a login enforcement

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name for this login enforcement configuration
mfa_write_login_enforcement_request = OpenbaoClient::MfaWriteLoginEnforcementRequest.new({mfa_method_ids: ['mfa_method_ids_example']}) # MfaWriteLoginEnforcementRequest | 

begin
  # Create or update a login enforcement
  api_instance.mfa_write_login_enforcement(name, mfa_write_login_enforcement_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_write_login_enforcement: #{e}"
end
```

#### Using the mfa_write_login_enforcement_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> mfa_write_login_enforcement_with_http_info(name, mfa_write_login_enforcement_request)

```ruby
begin
  # Create or update a login enforcement
  data, status_code, headers = api_instance.mfa_write_login_enforcement_with_http_info(name, mfa_write_login_enforcement_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->mfa_write_login_enforcement_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name for this login enforcement configuration |  |
| **mfa_write_login_enforcement_request** | [**MfaWriteLoginEnforcementRequest**](MfaWriteLoginEnforcementRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_configure

> oidc_configure(oidc_configure_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
oidc_configure_request = OpenbaoClient::OidcConfigureRequest.new # OidcConfigureRequest | 

begin
  
  api_instance.oidc_configure(oidc_configure_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_configure: #{e}"
end
```

#### Using the oidc_configure_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_configure_with_http_info(oidc_configure_request)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_configure_with_http_info(oidc_configure_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_configure_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **oidc_configure_request** | [**OidcConfigureRequest**](OidcConfigureRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_delete_assignment

> oidc_delete_assignment(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the assignment

begin
  
  api_instance.oidc_delete_assignment(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_assignment: #{e}"
end
```

#### Using the oidc_delete_assignment_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_delete_assignment_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_delete_assignment_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_assignment_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the assignment |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_delete_client

> oidc_delete_client(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the client.

begin
  
  api_instance.oidc_delete_client(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_client: #{e}"
end
```

#### Using the oidc_delete_client_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_delete_client_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_delete_client_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_client_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the client. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_delete_key

> oidc_delete_key(name)

CRUD operations for OIDC keys.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the key

begin
  # CRUD operations for OIDC keys.
  api_instance.oidc_delete_key(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_key: #{e}"
end
```

#### Using the oidc_delete_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_delete_key_with_http_info(name)

```ruby
begin
  # CRUD operations for OIDC keys.
  data, status_code, headers = api_instance.oidc_delete_key_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_delete_provider

> oidc_delete_provider(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the provider

begin
  
  api_instance.oidc_delete_provider(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_provider: #{e}"
end
```

#### Using the oidc_delete_provider_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_delete_provider_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_delete_provider_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_provider_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the provider |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_delete_role

> oidc_delete_role(name)

CRUD operations on OIDC Roles

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the role

begin
  # CRUD operations on OIDC Roles
  api_instance.oidc_delete_role(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_role: #{e}"
end
```

#### Using the oidc_delete_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_delete_role_with_http_info(name)

```ruby
begin
  # CRUD operations on OIDC Roles
  data, status_code, headers = api_instance.oidc_delete_role_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_delete_scope

> oidc_delete_scope(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the scope

begin
  
  api_instance.oidc_delete_scope(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_scope: #{e}"
end
```

#### Using the oidc_delete_scope_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_delete_scope_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_delete_scope_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_delete_scope_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the scope |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_generate_token

> oidc_generate_token(name)

Generate an OIDC token

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the role

begin
  # Generate an OIDC token
  api_instance.oidc_generate_token(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_generate_token: #{e}"
end
```

#### Using the oidc_generate_token_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_generate_token_with_http_info(name)

```ruby
begin
  # Generate an OIDC token
  data, status_code, headers = api_instance.oidc_generate_token_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_generate_token_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_introspect

> oidc_introspect(oidc_introspect_request)

Verify the authenticity of an OIDC token

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
oidc_introspect_request = OpenbaoClient::OidcIntrospectRequest.new # OidcIntrospectRequest | 

begin
  # Verify the authenticity of an OIDC token
  api_instance.oidc_introspect(oidc_introspect_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_introspect: #{e}"
end
```

#### Using the oidc_introspect_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_introspect_with_http_info(oidc_introspect_request)

```ruby
begin
  # Verify the authenticity of an OIDC token
  data, status_code, headers = api_instance.oidc_introspect_with_http_info(oidc_introspect_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_introspect_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **oidc_introspect_request** | [**OidcIntrospectRequest**](OidcIntrospectRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_list_assignments

> oidc_list_assignments(list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.oidc_list_assignments(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_assignments: #{e}"
end
```

#### Using the oidc_list_assignments_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_list_assignments_with_http_info(list)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_list_assignments_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_assignments_with_http_info: #{e}"
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


## oidc_list_clients

> oidc_list_clients(list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.oidc_list_clients(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_clients: #{e}"
end
```

#### Using the oidc_list_clients_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_list_clients_with_http_info(list)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_list_clients_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_clients_with_http_info: #{e}"
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


## oidc_list_keys

> oidc_list_keys(list)

List OIDC keys

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List OIDC keys
  api_instance.oidc_list_keys(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_keys: #{e}"
end
```

#### Using the oidc_list_keys_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_list_keys_with_http_info(list)

```ruby
begin
  # List OIDC keys
  data, status_code, headers = api_instance.oidc_list_keys_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_keys_with_http_info: #{e}"
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


## oidc_list_providers

> oidc_list_providers(list, opts)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`
opts = {
  allowed_client_id: 'allowed_client_id_example' # String | Filters the list of OIDC providers to those that allow the given client ID in their set of allowed_client_ids.
}

begin
  
  api_instance.oidc_list_providers(list, opts)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_providers: #{e}"
end
```

#### Using the oidc_list_providers_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_list_providers_with_http_info(list, opts)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_list_providers_with_http_info(list, opts)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_providers_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **list** | **String** | Must be set to &#x60;true&#x60; |  |
| **allowed_client_id** | **String** | Filters the list of OIDC providers to those that allow the given client ID in their set of allowed_client_ids. | [optional][default to &#39;&#39;] |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_list_roles

> oidc_list_roles(list)

List configured OIDC roles

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List configured OIDC roles
  api_instance.oidc_list_roles(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_roles: #{e}"
end
```

#### Using the oidc_list_roles_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_list_roles_with_http_info(list)

```ruby
begin
  # List configured OIDC roles
  data, status_code, headers = api_instance.oidc_list_roles_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_roles_with_http_info: #{e}"
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


## oidc_list_scopes

> oidc_list_scopes(list)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  
  api_instance.oidc_list_scopes(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_scopes: #{e}"
end
```

#### Using the oidc_list_scopes_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_list_scopes_with_http_info(list)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_list_scopes_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_list_scopes_with_http_info: #{e}"
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


## oidc_provider_authorize

> oidc_provider_authorize(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the provider

begin
  
  api_instance.oidc_provider_authorize(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_provider_authorize: #{e}"
end
```

#### Using the oidc_provider_authorize_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_provider_authorize_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_provider_authorize_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_provider_authorize_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the provider |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_provider_authorize_with_parameters

> oidc_provider_authorize_with_parameters(name, oidc_provider_authorize_with_parameters_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the provider
oidc_provider_authorize_with_parameters_request = OpenbaoClient::OidcProviderAuthorizeWithParametersRequest.new({client_id: 'client_id_example', redirect_uri: 'redirect_uri_example', response_type: 'response_type_example', scope: 'scope_example'}) # OidcProviderAuthorizeWithParametersRequest | 

begin
  
  api_instance.oidc_provider_authorize_with_parameters(name, oidc_provider_authorize_with_parameters_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_provider_authorize_with_parameters: #{e}"
end
```

#### Using the oidc_provider_authorize_with_parameters_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_provider_authorize_with_parameters_with_http_info(name, oidc_provider_authorize_with_parameters_request)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_provider_authorize_with_parameters_with_http_info(name, oidc_provider_authorize_with_parameters_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_provider_authorize_with_parameters_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the provider |  |
| **oidc_provider_authorize_with_parameters_request** | [**OidcProviderAuthorizeWithParametersRequest**](OidcProviderAuthorizeWithParametersRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_provider_token

> oidc_provider_token(name, oidc_provider_token_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the provider
oidc_provider_token_request = OpenbaoClient::OidcProviderTokenRequest.new({code: 'code_example', grant_type: 'grant_type_example', redirect_uri: 'redirect_uri_example'}) # OidcProviderTokenRequest | 

begin
  
  api_instance.oidc_provider_token(name, oidc_provider_token_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_provider_token: #{e}"
end
```

#### Using the oidc_provider_token_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_provider_token_with_http_info(name, oidc_provider_token_request)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_provider_token_with_http_info(name, oidc_provider_token_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_provider_token_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the provider |  |
| **oidc_provider_token_request** | [**OidcProviderTokenRequest**](OidcProviderTokenRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_provider_user_info

> oidc_provider_user_info(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the provider

begin
  
  api_instance.oidc_provider_user_info(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_provider_user_info: #{e}"
end
```

#### Using the oidc_provider_user_info_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_provider_user_info_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_provider_user_info_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_provider_user_info_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the provider |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_provider_user_info2

> oidc_provider_user_info2(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the provider

begin
  
  api_instance.oidc_provider_user_info2(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_provider_user_info2: #{e}"
end
```

#### Using the oidc_provider_user_info2_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_provider_user_info2_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_provider_user_info2_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_provider_user_info2_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the provider |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_read_assignment

> oidc_read_assignment(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the assignment

begin
  
  api_instance.oidc_read_assignment(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_assignment: #{e}"
end
```

#### Using the oidc_read_assignment_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_assignment_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_read_assignment_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_assignment_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the assignment |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_read_client

> oidc_read_client(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the client.

begin
  
  api_instance.oidc_read_client(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_client: #{e}"
end
```

#### Using the oidc_read_client_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_client_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_read_client_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_client_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the client. |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_read_configuration

> oidc_read_configuration



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new

begin
  
  api_instance.oidc_read_configuration
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_configuration: #{e}"
end
```

#### Using the oidc_read_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_configuration_with_http_info

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_read_configuration_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_configuration_with_http_info: #{e}"
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


## oidc_read_key

> oidc_read_key(name)

CRUD operations for OIDC keys.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the key

begin
  # CRUD operations for OIDC keys.
  api_instance.oidc_read_key(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_key: #{e}"
end
```

#### Using the oidc_read_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_key_with_http_info(name)

```ruby
begin
  # CRUD operations for OIDC keys.
  data, status_code, headers = api_instance.oidc_read_key_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_read_open_id_configuration

> oidc_read_open_id_configuration

Query OIDC configurations

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new

begin
  # Query OIDC configurations
  api_instance.oidc_read_open_id_configuration
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_open_id_configuration: #{e}"
end
```

#### Using the oidc_read_open_id_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_open_id_configuration_with_http_info

```ruby
begin
  # Query OIDC configurations
  data, status_code, headers = api_instance.oidc_read_open_id_configuration_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_open_id_configuration_with_http_info: #{e}"
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


## oidc_read_provider

> oidc_read_provider(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the provider

begin
  
  api_instance.oidc_read_provider(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_provider: #{e}"
end
```

#### Using the oidc_read_provider_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_provider_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_read_provider_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_provider_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the provider |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_read_provider_open_id_configuration

> oidc_read_provider_open_id_configuration(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the provider

begin
  
  api_instance.oidc_read_provider_open_id_configuration(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_provider_open_id_configuration: #{e}"
end
```

#### Using the oidc_read_provider_open_id_configuration_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_provider_open_id_configuration_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_read_provider_open_id_configuration_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_provider_open_id_configuration_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the provider |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_read_provider_public_keys

> oidc_read_provider_public_keys(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the provider

begin
  
  api_instance.oidc_read_provider_public_keys(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_provider_public_keys: #{e}"
end
```

#### Using the oidc_read_provider_public_keys_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_provider_public_keys_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_read_provider_public_keys_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_provider_public_keys_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the provider |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_read_public_keys

> oidc_read_public_keys

Retrieve public keys

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new

begin
  # Retrieve public keys
  api_instance.oidc_read_public_keys
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_public_keys: #{e}"
end
```

#### Using the oidc_read_public_keys_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_public_keys_with_http_info

```ruby
begin
  # Retrieve public keys
  data, status_code, headers = api_instance.oidc_read_public_keys_with_http_info
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_public_keys_with_http_info: #{e}"
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


## oidc_read_role

> oidc_read_role(name)

CRUD operations on OIDC Roles

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the role

begin
  # CRUD operations on OIDC Roles
  api_instance.oidc_read_role(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_role: #{e}"
end
```

#### Using the oidc_read_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_role_with_http_info(name)

```ruby
begin
  # CRUD operations on OIDC Roles
  data, status_code, headers = api_instance.oidc_read_role_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_read_scope

> oidc_read_scope(name)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the scope

begin
  
  api_instance.oidc_read_scope(name)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_scope: #{e}"
end
```

#### Using the oidc_read_scope_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_read_scope_with_http_info(name)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_read_scope_with_http_info(name)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_read_scope_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the scope |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## oidc_rotate_key

> oidc_rotate_key(name, oidc_rotate_key_request)

Rotate a named OIDC key.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the key
oidc_rotate_key_request = OpenbaoClient::OidcRotateKeyRequest.new # OidcRotateKeyRequest | 

begin
  # Rotate a named OIDC key.
  api_instance.oidc_rotate_key(name, oidc_rotate_key_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_rotate_key: #{e}"
end
```

#### Using the oidc_rotate_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_rotate_key_with_http_info(name, oidc_rotate_key_request)

```ruby
begin
  # Rotate a named OIDC key.
  data, status_code, headers = api_instance.oidc_rotate_key_with_http_info(name, oidc_rotate_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_rotate_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **oidc_rotate_key_request** | [**OidcRotateKeyRequest**](OidcRotateKeyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_write_assignment

> oidc_write_assignment(name, oidc_write_assignment_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the assignment
oidc_write_assignment_request = OpenbaoClient::OidcWriteAssignmentRequest.new # OidcWriteAssignmentRequest | 

begin
  
  api_instance.oidc_write_assignment(name, oidc_write_assignment_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_assignment: #{e}"
end
```

#### Using the oidc_write_assignment_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_write_assignment_with_http_info(name, oidc_write_assignment_request)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_write_assignment_with_http_info(name, oidc_write_assignment_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_assignment_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the assignment |  |
| **oidc_write_assignment_request** | [**OidcWriteAssignmentRequest**](OidcWriteAssignmentRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_write_client

> oidc_write_client(name, oidc_write_client_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the client.
oidc_write_client_request = OpenbaoClient::OidcWriteClientRequest.new # OidcWriteClientRequest | 

begin
  
  api_instance.oidc_write_client(name, oidc_write_client_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_client: #{e}"
end
```

#### Using the oidc_write_client_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_write_client_with_http_info(name, oidc_write_client_request)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_write_client_with_http_info(name, oidc_write_client_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_client_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the client. |  |
| **oidc_write_client_request** | [**OidcWriteClientRequest**](OidcWriteClientRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_write_key

> oidc_write_key(name, oidc_write_key_request)

CRUD operations for OIDC keys.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the key
oidc_write_key_request = OpenbaoClient::OidcWriteKeyRequest.new # OidcWriteKeyRequest | 

begin
  # CRUD operations for OIDC keys.
  api_instance.oidc_write_key(name, oidc_write_key_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_key: #{e}"
end
```

#### Using the oidc_write_key_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_write_key_with_http_info(name, oidc_write_key_request)

```ruby
begin
  # CRUD operations for OIDC keys.
  data, status_code, headers = api_instance.oidc_write_key_with_http_info(name, oidc_write_key_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_key_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the key |  |
| **oidc_write_key_request** | [**OidcWriteKeyRequest**](OidcWriteKeyRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_write_provider

> oidc_write_provider(name, oidc_write_provider_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the provider
oidc_write_provider_request = OpenbaoClient::OidcWriteProviderRequest.new # OidcWriteProviderRequest | 

begin
  
  api_instance.oidc_write_provider(name, oidc_write_provider_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_provider: #{e}"
end
```

#### Using the oidc_write_provider_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_write_provider_with_http_info(name, oidc_write_provider_request)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_write_provider_with_http_info(name, oidc_write_provider_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_provider_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the provider |  |
| **oidc_write_provider_request** | [**OidcWriteProviderRequest**](OidcWriteProviderRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_write_role

> oidc_write_role(name, oidc_write_role_request)

CRUD operations on OIDC Roles

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the role
oidc_write_role_request = OpenbaoClient::OidcWriteRoleRequest.new({key: 'key_example'}) # OidcWriteRoleRequest | 

begin
  # CRUD operations on OIDC Roles
  api_instance.oidc_write_role(name, oidc_write_role_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_role: #{e}"
end
```

#### Using the oidc_write_role_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_write_role_with_http_info(name, oidc_write_role_request)

```ruby
begin
  # CRUD operations on OIDC Roles
  data, status_code, headers = api_instance.oidc_write_role_with_http_info(name, oidc_write_role_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_role_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the role |  |
| **oidc_write_role_request** | [**OidcWriteRoleRequest**](OidcWriteRoleRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## oidc_write_scope

> oidc_write_scope(name, oidc_write_scope_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
name = 'name_example' # String | Name of the scope
oidc_write_scope_request = OpenbaoClient::OidcWriteScopeRequest.new # OidcWriteScopeRequest | 

begin
  
  api_instance.oidc_write_scope(name, oidc_write_scope_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_scope: #{e}"
end
```

#### Using the oidc_write_scope_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> oidc_write_scope_with_http_info(name, oidc_write_scope_request)

```ruby
begin
  
  data, status_code, headers = api_instance.oidc_write_scope_with_http_info(name, oidc_write_scope_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->oidc_write_scope_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **name** | **String** | Name of the scope |  |
| **oidc_write_scope_request** | [**OidcWriteScopeRequest**](OidcWriteScopeRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## persona_create

> persona_create(persona_create_request)

Create a new alias.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
persona_create_request = OpenbaoClient::PersonaCreateRequest.new # PersonaCreateRequest | 

begin
  # Create a new alias.
  api_instance.persona_create(persona_create_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->persona_create: #{e}"
end
```

#### Using the persona_create_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> persona_create_with_http_info(persona_create_request)

```ruby
begin
  # Create a new alias.
  data, status_code, headers = api_instance.persona_create_with_http_info(persona_create_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->persona_create_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **persona_create_request** | [**PersonaCreateRequest**](PersonaCreateRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined


## persona_delete_by_id

> persona_delete_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the persona

begin
  
  api_instance.persona_delete_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->persona_delete_by_id: #{e}"
end
```

#### Using the persona_delete_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> persona_delete_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.persona_delete_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->persona_delete_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the persona |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## persona_list_by_id

> persona_list_by_id(list)

List all the alias IDs.

### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
list = 'true' # String | Must be set to `true`

begin
  # List all the alias IDs.
  api_instance.persona_list_by_id(list)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->persona_list_by_id: #{e}"
end
```

#### Using the persona_list_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> persona_list_by_id_with_http_info(list)

```ruby
begin
  # List all the alias IDs.
  data, status_code, headers = api_instance.persona_list_by_id_with_http_info(list)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->persona_list_by_id_with_http_info: #{e}"
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


## persona_read_by_id

> persona_read_by_id(id)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the persona

begin
  
  api_instance.persona_read_by_id(id)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->persona_read_by_id: #{e}"
end
```

#### Using the persona_read_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> persona_read_by_id_with_http_info(id)

```ruby
begin
  
  data, status_code, headers = api_instance.persona_read_by_id_with_http_info(id)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->persona_read_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the persona |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: Not defined
- **Accept**: Not defined


## persona_update_by_id

> persona_update_by_id(id, persona_update_by_id_request)



### Examples

```ruby
require 'time'
require 'openbao_client'

api_instance = OpenbaoClient::IdentityApi.new
id = 'id_example' # String | ID of the persona
persona_update_by_id_request = OpenbaoClient::PersonaUpdateByIdRequest.new # PersonaUpdateByIdRequest | 

begin
  
  api_instance.persona_update_by_id(id, persona_update_by_id_request)
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->persona_update_by_id: #{e}"
end
```

#### Using the persona_update_by_id_with_http_info variant

This returns an Array which contains the response data (`nil` in this case), status code and headers.

> <Array(nil, Integer, Hash)> persona_update_by_id_with_http_info(id, persona_update_by_id_request)

```ruby
begin
  
  data, status_code, headers = api_instance.persona_update_by_id_with_http_info(id, persona_update_by_id_request)
  p status_code # => 2xx
  p headers # => { ... }
  p data # => nil
rescue OpenbaoClient::ApiError => e
  puts "Error when calling IdentityApi->persona_update_by_id_with_http_info: #{e}"
end
```

### Parameters

| Name | Type | Description | Notes |
| ---- | ---- | ----------- | ----- |
| **id** | **String** | ID of the persona |  |
| **persona_update_by_id_request** | [**PersonaUpdateByIdRequest**](PersonaUpdateByIdRequest.md) |  |  |

### Return type

nil (empty response body)

### Authorization

No authorization required

### HTTP request headers

- **Content-Type**: application/json
- **Accept**: Not defined

