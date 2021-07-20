# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  # We need to ignore these since these are non-Ruby files
  # that do not define Ruby classes / modules
  autoloader.ignore(Rails.root.join('lib/support'))

  # Ignore generators since these are loaded manually by Rails
  # https://github.com/rails/rails/blob/v6.1.3.2/railties/lib/rails/command/behavior.rb#L56-L65
  autoloader.ignore(Rails.root.join('lib/generators'))
  autoloader.ignore(Rails.root.join('ee/lib/generators')) if Gitlab.ee?

  # Mailer previews are also loaded manually by Rails
  # https://github.com/rails/rails/blob/v6.1.3.2/actionmailer/lib/action_mailer/preview.rb#L121-L125
  autoloader.ignore(Rails.root.join('app/mailers/previews'))
  autoloader.ignore(Rails.root.join('ee/app/mailers/previews')) if Gitlab.ee?

  autoloader.inflector.inflect(
    'api' => 'API',
    'api_authentication' => 'APIAuthentication',
    'api_guard' => 'APIGuard',
    'group_api_compatibility' => 'GroupAPICompatibility',
    'project_api_compatibility' => 'ProjectAPICompatibility',
    'ast' => 'AST',
    'cte' => 'CTE',
    'recursive_cte' => 'RecursiveCTE',
    'cidr' => 'CIDR',
    'cli' => 'CLI',
    'dn' => 'DN',
    'global_id_type' => 'GlobalIDType',
    'global_id_compatibility' => 'GlobalIDCompatibility',
    'hll' => 'HLL',
    'hll_redis_counter' => 'HLLRedisCounter',
    'redis_hll_metric' => 'RedisHLLMetric',
    'hmac_token' => 'HMACToken',
    'html' => 'HTML',
    'html_parser' => 'HTMLParser',
    'html_gitlab' => 'HTMLGitlab',
    'http' => 'HTTP',
    'http_connection_adapter' => 'HTTPConnectionAdapter',
    'http_clone_enabled_check' => 'HTTPCloneEnabledCheck',
    'hangouts_chat_http_override' => 'HangoutsChatHTTPOverride',
    'chunked_io' => 'ChunkedIO',
    'http_io' => 'HttpIO',
    'json_formatter' => 'JSONFormatter',
    'json_web_token' => 'JSONWebToken',
    'as_json' => 'AsJSON',
    'jwt_token' => 'JWTToken',
    'ldap_key' => 'LDAPKey',
    'mr_note' => 'MRNote',
    'pdf' => 'PDF',
    'csv' => 'CSV',
    'rsa_token' => 'RSAToken',
    'san_extension' => 'SANExtension',
    'sca' => 'SCA',
    'spdx' => 'SPDX',
    'sql' => 'SQL',
    'sse_helpers' => 'SSEHelpers',
    'ssh_key' => 'SSHKey',
    'ssh_key_with_user' => 'SSHKeyWithUser',
    'ssh_public_key' => 'SSHPublicKey',
    'git_ssh_proxy' => 'GitSSHProxy',
    'git_user_default_ssh_config_check' => 'GitUserDefaultSSHConfigCheck',
    'binary_stl' => 'BinarySTL',
    'text_stl' => 'TextSTL',
    'svg' => 'SVG',
    'function_uri' => 'FunctionURI',
    'uuid' => 'UUID',
    'vulnerability_uuid' => 'VulnerabilityUUID',
    'vs_code_extension_activity_unique_counter' => 'VSCodeExtensionActivityUniqueCounter'
  )
end
