# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  # We need to ignore these since these are non-Ruby files
  # that do not define Ruby classes / modules
  autoloader.ignore(Rails.root.join('lib/support'))
  # Ignore generators since these are loaded manually by Rails
  autoloader.ignore(Rails.root.join('lib/generators'))
  autoloader.ignore(Rails.root.join('ee/lib/generators')) if Gitlab.ee?
  # Mailer previews are also loaded manually by Rails
  autoloader.ignore(Rails.root.join('app/mailers/previews'))
  autoloader.ignore(Rails.root.join('ee/app/mailers/previews')) if Gitlab.ee?
  # Ignore these files because these are only used in Rake tasks
  # and are not available in production
  autoloader.ignore(Rails.root.join('lib/gitlab/graphql/docs'))

  autoloader.inflector.inflect(
    'authenticates_2fa_for_admin_mode' => 'Authenticates2FAForAdminMode',
    'api' => 'API',
    'api_guard' => 'APIGuard',
    'group_api_compatibility' => 'GroupAPICompatibility',
    'project_api_compatibility' => 'ProjectAPICompatibility',
    'cte' => 'CTE',
    'recursive_cte' => 'RecursiveCTE',
    'cidr' => 'CIDR',
    'cli' => 'CLI',
    'dn' => 'DN',
    'hmac_token' => 'HMACToken',
    'html' => 'HTML',
    'html_parser' => 'HTMLParser',
    'html_gitlab' => 'HTMLGitlab',
    'http' => 'HTTP',
    'http_connection_adapter' => 'HTTPConnectionAdapter',
    'http_clone_enabled_check' => 'HTTPCloneEnabledCheck',
    'chunked_io' => 'ChunkedIO',
    'http_io' => 'HttpIO',
    'json' => 'JSON',
    'json_formatter' => 'JSONFormatter',
    'json_web_token' => 'JSONWebToken',
    'as_json' => 'AsJSON',
    'ldap_key' => 'LDAPKey',
    'mr_note' => 'MRNote',
    'pdf' => 'PDF',
    'rsa_token' => 'RSAToken',
    'san_extension' => 'SANExtension',
    'sca' => 'SCA',
    'spdx' => 'SPDX',
    'sql' => 'SQL',
    'ssh_key' => 'SSHKey',
    'ssh_key_with_user' => 'SSHKeyWithUser',
    'ssh_public_key' => 'SSHPublicKey',
    'git_push_ssh_proxy' => 'GitPushSSHProxy',
    'git_user_default_ssh_config_check' => 'GitUserDefaultSSHConfigCheck',
    'binary_stl' => 'BinarySTL',
    'text_stl' => 'TextSTL',
    'svg' => 'SVG',
    'function_uri' => 'FunctionURI'
  )
end
