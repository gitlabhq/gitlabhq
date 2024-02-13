# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  # We need to ignore these since these are non-Ruby files
  # that do not define Ruby classes / modules
  autoloader.ignore(Rails.root.join('lib/support'))
  autoloader.ignore(Rails.root.join('lib/gitlab/ci/parsers/security/validators/schemas'))
  autoloader.ignore(Rails.root.join('ee/lib/ee/gitlab/ci/parsers/security/validators/schemas')) if Gitlab.ee?

  # Mailer previews are loaded manually by Rails
  # https://github.com/rails/rails/blob/v6.1.3.2/actionmailer/lib/action_mailer/preview.rb#L121-L125
  autoloader.ignore(Rails.root.join('app/mailers/previews'))
  autoloader.ignore(Rails.root.join('ee/app/mailers/previews')) if Gitlab.ee?
  autoloader.ignore(Rails.root.join('jh/app/mailers/previews')) if Gitlab.jh?

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
    'gitlab_cli_activity_unique_counter' => 'GitLabCliActivityUniqueCounter',
    'global_id_type' => 'GlobalIDType',
    'hll' => 'HLL',
    'hll_redis_counter' => 'HLLRedisCounter',
    'redis_hll_metric' => 'RedisHLLMetric',
    'hmac_token' => 'HMACToken',
    'html' => 'HTML',
    'html_parser' => 'HTMLParser',
    'html_gitlab' => 'HTMLGitlab',
    'http' => 'HTTP',
    'http_clone_enabled_check' => 'HTTPCloneEnabledCheck',
    'hangouts_chat_http_override' => 'HangoutsChatHTTPOverride',
    'chunked_io' => 'ChunkedIO',
    'http_io' => 'HttpIO',
    'jetbrains_plugin_activity_unique_counter' => 'JetBrainsPluginActivityUniqueCounter',
    'jetbrains_bundled_plugin_activity_unique_counter' => 'JetBrainsBundledPluginActivityUniqueCounter',
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
    'occurrence_uuid' => 'OccurrenceUUID',
    'vulnerability_uuid' => 'VulnerabilityUUID'
  )
end
