# frozen_string_literal: true

require_relative '../settings'
require_relative '../object_store_settings'
require_relative '../smime_signature_settings'

# Default settings
Settings['shared'] ||= {}
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.shared['path'] = Settings.absolute(Settings.shared['path'] || "shared")

Settings['encrypted_settings'] ||= {}
Settings.encrypted_settings['path'] ||= File.join(Settings.shared['path'], "encrypted_settings")
Settings.encrypted_settings['path'] = Settings.absolute(Settings.encrypted_settings['path'])

Settings['ldap'] ||= {}
Settings.ldap['enabled'] = false if Settings.ldap['enabled'].nil?
Settings.ldap['servers'] ||= {}
Settings.ldap['prevent_ldap_sign_in'] = false if Settings.ldap['prevent_ldap_sign_in'].blank?
Settings.ldap['secret_file'] = Settings.absolute(Settings.ldap['secret_file'] || File.join(Settings.encrypted_settings['path'], "ldap.yaml.enc"))

Gitlab.ee do
  Settings.ldap['sync_time'] = 3600 if Settings.ldap['sync_time'].nil?
  Settings.ldap['schedule_sync_daily'] = 1 if Settings.ldap['schedule_sync_daily'].nil?
  Settings.ldap['schedule_sync_hour'] = 1 if Settings.ldap['schedule_sync_hour'].nil?
  Settings.ldap['schedule_sync_minute'] = 30 if Settings.ldap['schedule_sync_minute'].nil?
end

# backwards compatibility, we only have one host
if Settings.ldap['enabled'] || Rails.env.test?
  if Settings.ldap['host'].present?
    # We detected old LDAP configuration syntax. Update the config to make it
    # look like it was entered with the new syntax.
    server = Settings.ldap.except('sync_time')
    Settings.ldap['servers'] = {
      'main' => server
    }
  end

  Settings.ldap['servers'].each do |key, server|
    server['label'] ||= 'LDAP'
    server['timeout'] ||= 10.seconds
    server['block_auto_created_users'] = false if server['block_auto_created_users'].nil?
    server['allow_username_or_email_login'] = false if server['allow_username_or_email_login'].nil?
    server['smartcard_auth'] = false unless %w[optional required].include?(server['smartcard_auth'])
    server['active_directory'] = true if server['active_directory'].nil?
    server['attributes'] = {} if server['attributes'].nil?
    server['lowercase_usernames'] = false if server['lowercase_usernames'].nil?
    server['provider_name'] ||= "ldap#{key}".downcase
    server['provider_class'] = OmniAuth::Utils.camelize(server['provider_name'])
    server['external_groups'] = [] if server['external_groups'].nil?
    server['sync_ssh_keys'] = 'sshPublicKey' if server['sync_ssh_keys'].to_s == 'true'

    # For backwards compatibility
    server['encryption'] ||= server['method']
    server['encryption'] = 'simple_tls' if server['encryption'] == 'ssl'
    server['encryption'] = 'start_tls' if server['encryption'] == 'tls'

    # Certificate verification was added in 9.4.2, and defaulted to false for
    # backwards-compatibility.
    #
    # Since GitLab 10.0, verify_certificates defaults to true for security.
    server['verify_certificates'] = true if server['verify_certificates'].nil?

    # Expose ability to set `tls_options` directly. Deprecate `ca_file` and
    # `ssl_version` in favor of `tls_options` hash option.
    server['tls_options'] ||= {}

    server['sync_name'] = true if server['sync_name'].nil?

    if server['ssl_version'] || server['ca_file']
      Gitlab::AppLogger.warn 'DEPRECATED: LDAP options `ssl_version` and `ca_file` should be nested within `tls_options`'
    end

    if server['ssl_version']
      server['tls_options']['ssl_version'] ||= server['ssl_version']
      server.delete('ssl_version')
    end

    if server['ca_file']
      server['tls_options']['ca_file'] ||= server['ca_file']
      server.delete('ca_file')
    end

    Settings.ldap['servers'][key] = server
  end
end

Settings['omniauth'] ||= {}
Settings.omniauth['enabled'] = true if Settings.omniauth['enabled'].nil?
Settings.omniauth['auto_sign_in_with_provider'] = false if Settings.omniauth['auto_sign_in_with_provider'].nil?
Settings.omniauth['allow_single_sign_on'] = false if Settings.omniauth['allow_single_sign_on'].nil?
Settings.omniauth['allow_bypass_two_factor'] = false if Settings.omniauth['allow_bypass_two_factor'].nil?
Settings.omniauth['external_providers'] = [] if Settings.omniauth['external_providers'].nil?
Settings.omniauth['block_auto_created_users'] = true if Settings.omniauth['block_auto_created_users'].nil?
Settings.omniauth['auto_link_ldap_user'] = false if Settings.omniauth['auto_link_ldap_user'].nil?
Settings.omniauth['auto_link_saml_user'] = false if Settings.omniauth['auto_link_saml_user'].nil?
Settings.omniauth['auto_link_user'] = false if Settings.omniauth['auto_link_user'].nil?
Settings.omniauth['saml_message_max_byte_size'] = 250000 if Settings.omniauth['saml_message_max_byte_size'].nil?

Settings.omniauth['sync_profile_from_provider'] = false if Settings.omniauth['sync_profile_from_provider'].nil?
Settings.omniauth['sync_profile_attributes'] = ['email'] if Settings.omniauth['sync_profile_attributes'].nil?

# Handle backwards compatibility with merge request 11268
if Settings.omniauth['sync_email_from_provider']
  if Settings.omniauth['sync_profile_from_provider'].is_a?(Array)
    Settings.omniauth['sync_profile_from_provider'] |= [Settings.omniauth['sync_email_from_provider']]
  elsif !Settings.omniauth['sync_profile_from_provider']
    Settings.omniauth['sync_profile_from_provider'] = [Settings.omniauth['sync_email_from_provider']]
  end

  Settings.omniauth['sync_profile_attributes'] |= ['email'] unless Settings.omniauth['sync_profile_attributes'] == true
end

Settings.omniauth['providers'] ||= []

Settings['oidc_provider'] ||= {}
Settings.oidc_provider['openid_id_token_expire_in_seconds'] = 120 if Settings.oidc_provider['openid_id_token_expire_in_seconds'].nil?

# Handle backward compatibility with the renamed kerberos_spnego provider
# https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96335#note_1094265436
Gitlab.ee do
  kerberos_spnego = Settings.omniauth.providers.find { |p| p.name == 'kerberos_spnego' }
  if kerberos_spnego
    Settings.omniauth.providers.delete_if { |p| p.name == 'kerberos' }
    kerberos_spnego['name'] = 'kerberos'

    omniauth_keys = %w[allow_single_sign_on auto_link_user external_providers sync_profile_from_provider allow_bypass_two_factor]
    omniauth_keys.each do |key|
      next unless Settings.omniauth[key].is_a?(Array)

      Settings.omniauth[key].map! { |p| p == 'kerberos_spnego' ? 'kerberos' : p }
    end

    if Settings.omniauth['auto_sign_in_with_provider'] == 'kerberos_spnego'
      Settings.omniauth['auto_sign_in_with_provider'] = 'kerberos'
    end
  end
end

# Fill out omniauth-gitlab settings. It is needed for easy set up GHE or GH by just specifying url.

github_default_url = "https://github.com"
github_settings = Settings.omniauth['providers'].find { |provider| provider["name"] == "github" }

if github_settings
  # For compatibility with old config files (before 7.8)
  # where people dont have url in github settings
  if github_settings['url'].blank?
    github_settings['url'] = github_default_url
  end

  github_settings["args"] ||= {}

  github_settings["args"]["client_options"] =
    if github_settings["url"].include?(github_default_url)
      OmniAuth::Strategies::GitHub.default_options[:client_options]
    else
      {
        "site" => File.join(github_settings["url"], "api/v3"),
        "authorize_url" => File.join(github_settings["url"], "login/oauth/authorize"),
        "token_url" => File.join(github_settings["url"], "login/oauth/access_token")
      }
    end
end

# Fill out default Settings for omniauth-saml

OmniAuth::Strategies::SAML.default_options['message_max_bytesize'] = Settings.omniauth['saml_message_max_byte_size']

# SAML should be enabled for the tests automatically, but only for EE.
saml_provider_enabled = Settings.omniauth.providers.any? do |provider|
  provider['name'] == 'group_saml'
end

if Gitlab.ee? && Rails.env.test? && !saml_provider_enabled
  Settings.omniauth.providers << GitlabSettings::Options.build({ 'name' => 'group_saml' })
end

Settings['issues_tracker'] ||= {}

#
# GitLab
#
Settings['gitlab'] ||= {}
Settings.gitlab['default_project_creation'] ||= ::Gitlab::Access::DEVELOPER_PROJECT_ACCESS
Settings.gitlab['default_project_deletion_protection'] ||= false
Settings.gitlab['default_projects_limit'] ||= 100000
Settings.gitlab['default_branch_protection'] ||= 2
Settings.gitlab['default_branch_protection_defaults'] ||= ::Gitlab::Access::BranchProtection.protected_fully
# `default_can_create_group` is deprecated since GitLab 15.5 in favour of the `can_create_group` column on `ApplicationSetting`.
Settings.gitlab['default_can_create_group'] = true if Settings.gitlab['default_can_create_group'].nil?
Settings.gitlab['default_theme'] = Gitlab::Themes::APPLICATION_DEFAULT if Settings.gitlab['default_theme'].nil?
Settings.gitlab['default_color_mode'] = Gitlab::ColorModes::APPLICATION_DEFAULT if Settings.gitlab['default_color_mode'].nil?
Settings.gitlab['dns_rebinding_protection_enabled'] ||= !Gitlab.http_proxy_env?
Settings.gitlab['custom_html_header_tags'] ||= Settings.gitlab['custom_html_header_tags'] || ''
Settings.gitlab['host'] ||= ENV['GITLAB_HOST'] || 'localhost'
Settings.gitlab['cdn_host'] ||= ENV['GITLAB_CDN_HOST'].presence
Settings.gitlab['ssh_host'] ||= Settings.gitlab.host
Settings.gitlab['https']        = false if Settings.gitlab['https'].nil?
Settings.gitlab['port']       ||= ENV['GITLAB_PORT'] || (Settings.gitlab.https ? 443 : 80)
Settings.gitlab['relative_url_root'] ||= ENV['RAILS_RELATIVE_URL_ROOT'] || ''
# / is not a valid relative URL root
Settings.gitlab['relative_url_root']   = '' if Settings.gitlab['relative_url_root'] == '/'
Settings.gitlab['protocol'] ||= Settings.gitlab.https ? "https" : "http"
Settings.gitlab['email_enabled'] ||= true if Settings.gitlab['email_enabled'].nil?
Settings.gitlab['email_from'] ||= ENV['GITLAB_EMAIL_FROM'] || "gitlab@#{Settings.gitlab.host}"
Settings.gitlab['email_display_name'] ||= ENV['GITLAB_EMAIL_DISPLAY_NAME'] || 'GitLab'
Settings.gitlab['email_reply_to'] ||= ENV['GITLAB_EMAIL_REPLY_TO'] || "noreply@#{Settings.gitlab.host}"
Settings.gitlab['email_subject_prefix'] ||= ENV['GITLAB_EMAIL_SUBJECT_PREFIX'] || ""
Settings.gitlab['email_subject_suffix'] ||= ENV['GITLAB_EMAIL_SUBJECT_SUFFIX'] || ""
Settings.gitlab['email_smime'] = SmimeSignatureSettings.parse(Settings.gitlab['email_smime'])
Settings.gitlab['email_smtp_secret_file'] = Settings.absolute(Settings.gitlab['email_smtp_secret_file'] || File.join(Settings.encrypted_settings['path'], "smtp.yaml.enc"))
Settings.gitlab['base_url'] ||= Settings.__send__(:build_base_gitlab_url)
Settings.gitlab['url'] ||= Settings.__send__(:build_gitlab_url)
Settings.gitlab['user'] ||= 'git'
# External configuration may cause the ssh user to differ from the GitLab user
Settings.gitlab['ssh_user'] ||= Settings.gitlab.user
Settings.gitlab['user_home'] ||= begin
  Etc.getpwnam(Settings.gitlab['user']).dir
rescue ArgumentError # no user configured
  '/home/' + Settings.gitlab['user']
end
Settings.gitlab['time_zone'] ||= nil
Settings.gitlab['signup_enabled'] ||= true if Settings.gitlab['signup_enabled'].nil?
Settings.gitlab['signin_enabled'] ||= true if Settings.gitlab['signin_enabled'].nil?
Settings.gitlab['restricted_visibility_levels'] = Settings.__send__(:verify_constant_array, Gitlab::VisibilityLevel, Settings.gitlab['restricted_visibility_levels'], [])
Settings.gitlab['username_changing_enabled'] = true if Settings.gitlab['username_changing_enabled'].nil?
Settings.gitlab['issue_closing_pattern'] = '\b((?:[Cc]los(?:e[sd]?|ing)|\b[Ff]ix(?:e[sd]|ing)?|\b[Rr]esolv(?:e[sd]?|ing)|\b[Ii]mplement(?:s|ed|ing)?)(:?) +(?:(?:issues? +)?%{issue_ref}(?:(?: *,? +and +| *,? *)?)|([A-Z][A-Z0-9_]+-\d+))+)' if Settings.gitlab['issue_closing_pattern'].nil?
Settings.gitlab['default_projects_features'] ||= {}
Settings.gitlab['webhook_timeout'] ||= 10
Settings.gitlab['graphql_timeout'] ||= 30
Settings.gitlab['max_attachment_size'] ||= 100
Settings.gitlab['session_expire_delay'] ||= 10080
Settings.gitlab['session_expire_from_init'] ||= false
Settings.gitlab['unauthenticated_session_expire_delay'] ||= 2.hours.to_i
Settings.gitlab.default_projects_features['issues']             = true if Settings.gitlab.default_projects_features['issues'].nil?
Settings.gitlab.default_projects_features['merge_requests']     = true if Settings.gitlab.default_projects_features['merge_requests'].nil?
Settings.gitlab.default_projects_features['wiki']               = true if Settings.gitlab.default_projects_features['wiki'].nil?
Settings.gitlab.default_projects_features['snippets']           = true if Settings.gitlab.default_projects_features['snippets'].nil?
Settings.gitlab.default_projects_features['builds']             = true if Settings.gitlab.default_projects_features['builds'].nil?
Settings.gitlab.default_projects_features['container_registry'] = true if Settings.gitlab.default_projects_features['container_registry'].nil?
Settings.gitlab.default_projects_features['visibility_level']   = Settings.__send__(:verify_constant, Gitlab::VisibilityLevel, Settings.gitlab.default_projects_features['visibility_level'], Gitlab::VisibilityLevel::PRIVATE)
Settings.gitlab['domain_allowlist'] ||= []
Settings.gitlab['import_sources'] ||= []
Settings.gitlab['trusted_proxies'] ||= []
Settings.gitlab['content_security_policy'] ||= {}
Settings.gitlab['allowed_hosts'] ||= []
Settings.gitlab['impersonation_enabled'] ||= true if Settings.gitlab['impersonation_enabled'].nil?
Settings.gitlab['server_fqdn'] ||= Settings.__send__(:build_server_fqdn)
Settings.gitlab['usage_ping_enabled'] = true if Settings.gitlab['usage_ping_enabled'].nil?
Settings.gitlab['max_request_duration_seconds'] ||= 57
Settings.gitlab['display_initial_root_password'] = false if Settings.gitlab['display_initial_root_password'].nil?
Settings.gitlab['weak_passwords_digest_set'] ||= YAML.safe_load(File.open(Rails.root.join('config', 'weak_password_digests.yml')), permitted_classes: [String]).to_set.freeze
Settings.gitlab['log_decompressed_response_bytesize'] = ENV["GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE"].to_i > 0 ? ENV["GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE"].to_i : 0
Settings.gitlab['initial_gitlab_product_usage_data'] = true if Settings.gitlab['initial_gitlab_product_usage_data'].nil?
Settings.gitlab['initial_gitlab_product_usage_data'] = Gitlab::Utils.to_boolean(ENV['GITLAB_PRODUCT_USAGE_DATA_ENABLED'], default: Settings.gitlab['initial_gitlab_product_usage_data'])

Settings['ci_id_tokens'] ||= {}
Settings.ci_id_tokens['issuer_url'] = Settings.gitlab.url if Settings.ci_id_tokens['issuer_url'].blank?

Gitlab.ee do
  Settings.gitlab['mirror_max_delay'] ||= 300
  Settings.gitlab['mirror_max_capacity'] ||= 30
  Settings.gitlab['mirror_capacity_threshold'] ||= 15
end

#
# Elasticseacrh
#
Gitlab.ee do
  Settings['elasticsearch'] ||= {}
  Settings.elasticsearch['indexer_path'] ||= Gitlab::Utils.which('gitlab-elasticsearch-indexer')

  Settings['zoekt'] ||= {}
  Settings.zoekt['bin_path'] ||= Gitlab::Utils.which('gitlab-zoekt')
end

#
# ActionCable
#
Settings.gitlab['action_cable_allowed_origins'] ||= []

#
# CI
#
Settings['gitlab_ci'] ||= {}
Settings.gitlab_ci['shared_runners_enabled'] = true if Settings.gitlab_ci['shared_runners_enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.gitlab_ci['builds_path']           = Settings.absolute(Settings.gitlab_ci['builds_path'] || "builds/")
Settings.gitlab_ci['url']                 ||= Settings.__send__(:build_gitlab_ci_url)

#
# CI Secure Files
#
Settings['ci_secure_files'] ||= {}
Settings.ci_secure_files['enabled']      = true if Settings.ci_secure_files['enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.ci_secure_files['storage_path'] = Settings.absolute(Settings.ci_secure_files['storage_path'] || File.join(Settings.shared['path'], "ci_secure_files"))
Settings.ci_secure_files['object_store'] = ObjectStoreSettings.legacy_parse(Settings.ci_secure_files['object_store'], 'secure_files')

#
# Agent Plan Content
#
Settings['agent_plan_content'] ||= {}
Settings.agent_plan_content['storage_path'] = Settings.absolute(Settings.agent_plan_content['storage_path'] || File.join(Settings.shared['path'], "agent_plan_content"))
Settings.agent_plan_content['object_store'] = ObjectStoreSettings.legacy_parse(Settings.agent_plan_content['object_store'], 'agent_plan_content')

# AI Catalog
#
Settings['ai_catalog'] ||= {}
Settings.ai_catalog['storage_path'] = Settings.absolute(Settings.ai_catalog['storage_path'] || File.join(Settings.shared['path'], "ai_catalog"))
Settings.ai_catalog['object_store'] = ObjectStoreSettings.legacy_parse(Settings.ai_catalog['object_store'], 'ai_catalog')

#
# Reply by email
#
Settings['incoming_email'] ||= {}
Settings.incoming_email['enabled'] = false if Settings.incoming_email['enabled'].nil?
Settings.incoming_email['inbox_method'] ||= 'imap'
Settings.incoming_email['encrypted_secret_file'] = Settings.absolute(Settings.incoming_email['encrypted_secret_file'] || File.join(Settings.encrypted_settings['path'], "incoming_email.yaml.enc"))

#
# Service desk email
#
Settings['service_desk_email'] ||= {}
Settings.service_desk_email['enabled'] = false if Settings.service_desk_email['enabled'].nil?
Settings.service_desk_email['encrypted_secret_file'] = Settings.absolute(Settings.service_desk_email['encrypted_secret_file'] || File.join(Settings.encrypted_settings['path'], "service_desk_email.yaml.enc"))

#
# Build Artifacts
#
Settings['artifacts'] ||= {}
Settings.artifacts['enabled']      = true if Settings.artifacts['enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.artifacts['storage_path'] = Settings.absolute(Settings.artifacts.values_at('path', 'storage_path').compact.first || File.join(Settings.shared['path'], "artifacts"))
# Settings.artifact['path'] is deprecated, use `storage_path` instead
Settings.artifacts['path']         = Settings.artifacts['storage_path']
Settings.artifacts['max_size'] ||= 100 # in megabytes
Settings.artifacts['object_store'] = ObjectStoreSettings.legacy_parse(Settings.artifacts['object_store'], 'artifacts')

#
# Registry
#
Settings['registry'] ||= {}
Settings.registry['enabled'] ||= false
Settings.registry['host'] ||= "example.com"
Settings.registry['port'] ||= nil
Settings.registry['api_url'] ||= "http://localhost:5000/"
Settings.registry['key'] ||= nil
Settings.registry['issuer'] ||= nil
Settings.registry['host_port'] ||= [Settings.registry['host'], Settings.registry['port']].compact.join(':')
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.registry['path']            = Settings.absolute(Settings.registry['path'] || File.join(Settings.shared['path'], 'registry'))
Settings.registry['notifications'] ||= []

#
# Error Reporting and Logging with Sentry
#
Settings['sentry'] ||= {}
Settings.sentry['enabled'] ||= false
Settings.sentry['dsn'] ||= nil
Settings.sentry['environment'] ||= nil
Settings.sentry['clientside_dsn'] ||= nil

#
# Pages
#
Settings['pages'] ||= {}
Settings['pages'] = ::Gitlab::Pages::Settings.new(Settings.pages) # For path access detection https://gitlab.com/gitlab-org/gitlab/-/issues/230702
Settings.pages['enabled']           = false if Settings.pages['enabled'].nil?
Settings.pages['access_control']    = false if Settings.pages['access_control'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.pages['path']              = Settings.absolute(Settings.pages['path'] || File.join(Settings.shared['path'], "pages"))
Settings.pages['https']             = false if Settings.pages['https'].nil?
Settings.pages['host'] ||= "example.com"
Settings.pages['port'] ||= Settings.pages.https ? 443 : 80
Settings.pages['protocol'] ||= Settings.pages.https ? "https" : "http"
Settings.pages['url'] ||= Settings.__send__(:build_pages_url)
Settings.pages['external_http'] ||= false unless Settings.pages['external_http'].present?
Settings.pages['external_https'] ||= false unless Settings.pages['external_https'].present?
Settings.pages['custom_domain_mode'] = 'http' if Settings.pages['external_http'].present?
Settings.pages['custom_domain_mode'] = 'https' if Settings.pages['external_https'].present?
Settings.pages['custom_domain_mode'] = nil unless Settings.pages['custom_domain_mode'].present?
Settings.pages['artifacts_server'] ||= Settings.pages['enabled'] if Settings.pages['artifacts_server'].nil?
Settings.pages['secret_file'] ||= Rails.root.join('.gitlab_pages_secret')
# We want pages zip archives to be stored on the same directory as old pages hierarchical structure
# this will allow us to easier migrate existing instances with NFS
Settings.pages['storage_path']      = Settings.pages['path']
Settings.pages['object_store']      = ObjectStoreSettings.legacy_parse(Settings.pages['object_store'], 'pages')
Settings.pages['local_store'] ||= {}
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.pages['local_store']['path'] = Settings.absolute(Settings.pages['local_store']['path'] || File.join(Settings.shared['path'], "pages"))
Settings.pages['local_store']['enabled'] = true if Settings.pages['local_store']['enabled'].nil?
Settings.pages['namespace_in_path'] = false if Settings.pages['namespace_in_path'].nil?

#
# GitLab documentation
#
Settings['gitlab_docs'] ||= {}
Settings.gitlab_docs['enabled'] ||= false
Settings.gitlab_docs['host'] = nil unless Settings.gitlab_docs.enabled

#
# Geo
#
Gitlab.ee do
  Settings['geo'] ||= {}
  # For backwards compatibility, default to gitlab_url
  Settings.geo['node_name'] = Settings.geo['node_name'].presence || Settings.gitlab['url']

  #
  # Registry replication
  #
  Settings.geo['registry_replication'] ||= {}
  Settings.geo.registry_replication['enabled'] ||= false
end

#
# Unleash
#
Settings['feature_flags'] ||= {}
Settings.feature_flags['unleash'] ||= {}
Settings.feature_flags.unleash['enabled'] = false if Settings.feature_flags.unleash['enabled'].nil?

#
# External merge request diffs
#
Settings['external_diffs'] ||= {}
Settings.external_diffs['enabled']      = false if Settings.external_diffs['enabled'].nil?
Settings.external_diffs['when']         = 'always' if Settings.external_diffs['when'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.external_diffs['storage_path'] = Settings.absolute(Settings.external_diffs['storage_path'] || File.join(Settings.shared['path'], 'external-diffs'))
Settings.external_diffs['object_store'] = ObjectStoreSettings.legacy_parse(Settings.external_diffs['object_store'], 'external_diffs')

#
# Git LFS
#
Settings['lfs'] ||= {}
Settings.lfs['enabled']      = true if Settings.lfs['enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.lfs['storage_path'] = Settings.absolute(Settings.lfs['storage_path'] || File.join(Settings.shared['path'], "lfs-objects"))
Settings.lfs['object_store'] = ObjectStoreSettings.legacy_parse(Settings.lfs['object_store'], 'lfs')

#
# Uploads
#
Settings['uploads'] ||= {}
Settings.uploads['storage_path'] = Settings.absolute(Settings.uploads['storage_path'] || 'public')
Settings.uploads['base_dir'] = Settings.uploads['base_dir'] || 'uploads/-/system'
Settings.uploads['object_store'] = ObjectStoreSettings.legacy_parse(Settings.uploads['object_store'], 'uploads')
Settings.uploads['object_store']['remote_directory'] ||= 'uploads'

#
# Packages
#
Settings['packages'] ||= {}
Settings.packages['enabled']       = true if Settings.packages['enabled'].nil?
Settings.packages['dpkg_deb_path'] = '/usr/bin/dpkg-deb' if Settings.packages['dpkg_deb_path'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.packages['storage_path']  = Settings.absolute(Settings.packages['storage_path'] || File.join(Settings.shared['path'], "packages"))
Settings.packages['object_store']  = ObjectStoreSettings.legacy_parse(Settings.packages['object_store'], 'packages')

#
# Dependency Proxy
#
Settings['dependency_proxy'] ||= {}
Settings.dependency_proxy['enabled']      = true if Settings.dependency_proxy['enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.dependency_proxy['storage_path'] = Settings.absolute(Settings.dependency_proxy['storage_path'] || File.join(Settings.shared['path'], "dependency_proxy"))
Settings.dependency_proxy['object_store'] = ObjectStoreSettings.legacy_parse(Settings.dependency_proxy['object_store'], 'dependency_proxy')

#
# Terraform state
#
Settings['terraform_state'] ||= {}
Settings.terraform_state['enabled']      = true if Settings.terraform_state['enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.terraform_state['storage_path'] = Settings.absolute(Settings.terraform_state['storage_path'] || File.join(Settings.shared['path'], "terraform_state"))
Settings.terraform_state['object_store'] = ObjectStoreSettings.legacy_parse(Settings.terraform_state['object_store'], 'terraform_state')

#
# Mattermost
#
Settings['mattermost'] ||= {}
Settings.mattermost['enabled'] = false if Settings.mattermost['enabled'].nil?
Settings.mattermost['host'] = nil unless Settings.mattermost.enabled

#
# Jira Connect (GitLab for Jira Cloud App)
#
Settings['jira_connect'] ||= {}

Settings.jira_connect['atlassian_js_url'] ||= 'https://connect-cdn.atl-paas.net/all.js'
Settings.jira_connect['enforce_jira_base_url_https'] = true if Settings.jira_connect['enforce_jira_base_url_https'].nil?
Settings.jira_connect['additional_iframe_ancestors'] ||= []

#
# Gravatar
#
Settings['gravatar'] ||= {}
Settings.gravatar['enabled']      = true if Settings.gravatar['enabled'].nil?
Settings.gravatar['plain_url']  ||= 'https://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon'
Settings.gravatar['ssl_url']    ||= 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon'
Settings.gravatar['host']         = Settings.host_without_www(Settings.gravatar['plain_url'])

#
# Cron Jobs
#
Settings['cron_jobs'] ||= {}

# Cron job defaults are now defined in config/schedule.yml (FOSS) and
# ee/config/schedule.yml (EE). Loaded by Gitlab::SidekiqConfig::CronJobInitializer.
Settings.cron_jobs['poll_interval'] ||= ENV["GITLAB_CRON_JOBS_POLL_INTERVAL"]&.to_i

#
# Sidekiq
#
Settings['sidekiq'] ||= {}
Settings['sidekiq']['log_format'] ||= 'default'
Settings['sidekiq']['routing_rules'] = Settings.build_sidekiq_routing_rules(Settings['sidekiq']['routing_rules'])

#
# GitLab Shell
#
Settings['gitlab_shell'] ||= {}
Settings.gitlab_shell['path']           = Settings.absolute(Settings.gitlab_shell['path'] || (Settings.gitlab['user_home'] + '/gitlab-shell/'))
Settings.gitlab_shell['hooks_path']     = :deprecated_use_gitlab_shell_path_instead
Settings.gitlab_shell['authorized_keys_file'] ||= File.join(Dir.home, '.ssh', 'authorized_keys')
Settings.gitlab_shell['secret_file'] ||= Rails.root.join('.gitlab_shell_secret')
Settings.gitlab_shell['receive_pack']   = true if Settings.gitlab_shell['receive_pack'].nil?
Settings.gitlab_shell['upload_pack']    = true if Settings.gitlab_shell['upload_pack'].nil?
Settings.gitlab_shell['ssh_host']     ||= Settings.gitlab.ssh_host
Settings.gitlab_shell['ssh_port']     ||= 22
Settings.gitlab_shell['ssh_user']       = Settings.gitlab.ssh_user
Settings.gitlab_shell['owner_group']  ||= Settings.gitlab.user
Settings.gitlab_shell['ssh_path_prefix'] ||= Settings.__send__(:build_gitlab_shell_ssh_path_prefix)
Settings.gitlab_shell['git_timeout'] ||= 10800

# Object storage
ObjectStoreSettings.new(Settings).parse!

#
# Workhorse
#
Settings['workhorse'] ||= {}
Settings.workhorse['secret_file'] ||= Rails.root.join('.gitlab_workhorse_secret')

#
# Database Traffic Capture Settings
#

Settings['database_traffic_capture'] ||= {}
Settings.database_traffic_capture['config'] ||= {}
Settings.database_traffic_capture.config['storage'] ||= {}
Settings.database_traffic_capture.config.storage['connector'] ||= {}

#
# Cells
#
Settings['cell'] ||= {}
Settings.cell['enabled'] ||= false # All Cells Features are disabled by default
Settings.cell['id'] ||= nil
Settings.cell['database'] ||= {}
Settings.cell.database['skip_sequence_alteration'] ||= false
# NOTE: `topology_service_client` is the configuration to use going forward as per https://docs.gitlab.com/administration/cells/#configuration
#   We continue to be backwards compatible and support `topology_service` as a top-level key.
Settings.cell['topology_service_client'] ||= Settings.respond_to?(:topology_service) ? Settings.topology_service || {} : {}
Settings.cell.topology_service_client['address'] ||= 'topology-service.example.com:443'
Settings.cell.topology_service_client['ca_file'] ||= nil
Settings.cell.topology_service_client['certificate_file'] ||= nil
Settings.cell.topology_service_client['private_key_file'] ||= nil
Settings.cell.topology_service_client['tls'] ||= {}
Settings.cell.topology_service_client['tls']['enabled'] = true if Settings.cell.topology_service_client['tls']['enabled'].nil?
Settings.cell.topology_service_client['metadata'] ||= {}

#
# GitLab KAS
#
Settings['gitlab_kas'] ||= {}
Settings.gitlab_kas['enabled'] ||= false
Settings.gitlab_kas['secret_file'] ||= Rails.root.join('.gitlab_kas_secret')
Settings.gitlab_kas['external_url'] ||= 'wss://kas.example.com'
Settings.gitlab_kas['internal_url'] ||= 'grpc://localhost:8153'
Settings.gitlab_kas['client_timeout_seconds'] ||= 5
# Settings.gitlab_kas['external_k8s_proxy_url'] ||= 'grpc://localhost:8154' # NOTE: Do not set a default until all distributions have been updated with a correct value

#
# Knowledge Graph
#
Gitlab.ee do
  Settings['knowledge_graph'] ||= {}
  Settings.knowledge_graph['secret_file'] ||= Rails.root.join('.gitlab_knowledge_graph_secret')
  Settings.knowledge_graph['enabled'] ||= false
  Settings.knowledge_graph['grpc_endpoint'] ||= ENV.fetch('KNOWLEDGE_GRAPH_GRPC_ENDPOINT', 'localhost:50054')
end

#
# IAM Auth Service
#
Settings['iam_auth_service'] ||= {}
Settings.iam_auth_service['enabled'] ||= false
Settings.iam_auth_service['secret_file'] ||= nil
Settings.iam_auth_service['http'] ||= {}
Settings.iam_auth_service.http['host'] ||= 'localhost'
Settings.iam_auth_service.http['port'] ||= 8084
Settings.iam_auth_service['grpc'] ||= {}
Settings.iam_auth_service.grpc['host'] ||= 'localhost'
Settings.iam_auth_service.grpc['port'] ||= 8085
Settings.iam_auth_service['jwt_audience'] ||= 'gitlab-rails'
Settings.iam_auth_service['jwt_issuer'] ||= 'http://localhost'

#
# Gitlab Secrets Manager Openbao Integration
#
Settings['openbao'] ||= {}
Settings.openbao['authentication_token_secret_file_path'] ||= Rails.root.join('.gitlab_openbao_authentication_token_secret')

#
# Workspaces
#
Gitlab.ee do
  Settings['workspaces'] ||= {}
  Settings.workspaces['enabled'] ||= false
  Settings.workspaces['host'] ||= nil
end

#
# Cloud connector
#
Gitlab.ee do
  Settings['cloud_connector'] = {}
  Settings.cloud_connector['base_url'] ||= ENV['CLOUD_CONNECTOR_BASE_URL'] || 'https://cloud.gitlab.com'
end

#
# Duo Workflow
#
Gitlab.ee do
  Settings['duo_workflow'] ||= {}
  executor_version = Rails.root.join('DUO_WORKFLOW_EXECUTOR_VERSION').read.chomp
  # The os/arch for which duo-workflow-executor binary is build: https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor/-/packages/35054593
  executor_binary_urls = %w[
    linux/arm linux/amd64 linux/arm64 linux/386 linux/ppc64le darwin/arm64 darwin/amd64
    freebsd/arm freebsd/386 freebsd/amd64 windows/amd64 windows/386 windows/arm64
  ].index_with do |os_info|
    "https://gitlab.com/api/v4/projects/58711783/packages/generic/duo-workflow-executor/#{executor_version}/#{os_info.sub('/', '-')}-duo-workflow-executor.tar.gz"
  end

  Settings.duo_workflow.reverse_merge!(
    secure: true,
    service_url: nil, # service_url is constructued in Gitlab::DuoWorkflow::Client
    debug: false,
    executor_binary_url: "https://gitlab.com/api/v4/projects/58711783/packages/generic/duo-workflow-executor/#{executor_version}/duo-workflow-executor.tar.gz",
    executor_binary_urls: executor_binary_urls,
    executor_version: executor_version
  )
end

#
# Repositories
#
Settings['repositories'] ||= {}
Settings.repositories['storages'] ||= {}

Settings.repositories.storages.each do |key, storage|
  next if Settings.repositories.storages[key].is_a?(Gitlab::GitalyClient::StorageSettings)

  Settings.repositories.storages[key] = Gitlab::GitalyClient::StorageSettings.new(storage)
end

repository_downloads_path = Settings.gitlab['repository_downloads_path'].to_s.gsub(%r{/$}, '')

if repository_downloads_path.blank?
  Settings.gitlab['repository_downloads_path'] = File.join(Settings.shared['path'], 'cache/archive')
end

#
# Backup
#
Settings['backup'] ||= {}
Settings.backup['keep_time'] ||= 0
Settings.backup['pg_schema']    = nil
Settings.backup['path']         = Settings.absolute(Settings.backup['path'] || "tmp/backups/")
Settings.backup['archive_permissions'] ||= 0600
Settings.backup['upload'] ||= { 'remote_directory' => nil, 'connection' => nil }
Settings.backup['upload']['multipart_chunk_size'] ||= 104857600
Settings.backup['upload']['encryption'] ||= nil
Settings.backup['upload']['encryption_key'] ||= ENV['GITLAB_BACKUP_ENCRYPTION_KEY']
Settings.backup['upload']['storage_class'] ||= nil
Settings.backup['gitaly_backup_path'] ||= Gitlab::Utils.which('gitaly-backup')

#
# Git
#
Settings['git'] ||= {}
Settings.git['bin_path'] ||= '/usr/bin/git'

# Important: keep the satellites.path setting until GitLab 9.0 at
# least. This setting is fed to 'rm -rf' in
# db/migrate/20151023144219_remove_satellites.rb
Settings['satellites'] ||= {}
Settings.satellites['path'] = Settings.absolute(Settings.satellites['path'] || "tmp/repo_satellites/")

#
# Microsoft Graph Mailer
#
Settings['microsoft_graph_mailer'] ||= {}
Settings.microsoft_graph_mailer['enabled'] = false if Settings.microsoft_graph_mailer['enabled'].nil?
Settings.microsoft_graph_mailer['user_id'] ||= nil
Settings.microsoft_graph_mailer['tenant'] ||= nil
Settings.microsoft_graph_mailer['client_id'] ||= nil
Settings.microsoft_graph_mailer['client_secret'] ||= nil
Settings.microsoft_graph_mailer['azure_ad_endpoint'] ||= 'https://login.microsoftonline.com'
Settings.microsoft_graph_mailer['graph_endpoint'] ||= 'https://graph.microsoft.com'

#
# Kerberos
#
Gitlab.ee do
  Settings['kerberos'] ||= {}
  Settings.kerberos['enabled'] = false if Settings.kerberos['enabled'].nil?
  Settings.kerberos['keytab'] = nil if Settings.kerberos['keytab'].blank? # nil means use default keytab
  Settings.kerberos['simple_ldap_linking_allowed_realms'] = [] if Settings.kerberos['simple_ldap_linking_allowed_realms'].blank?
  Settings.kerberos['service_principal_name'] = nil if Settings.kerberos['service_principal_name'].blank? # nil means any SPN in keytab
  Settings.kerberos['use_dedicated_port'] = false if Settings.kerberos['use_dedicated_port'].nil?
  Settings.kerberos['https'] = Settings.gitlab.https if Settings.kerberos['https'].nil?
  Settings.kerberos['port'] ||= Settings.kerberos.https ? 8443 : 8088

  if Settings.kerberos['enabled'] && Settings.omniauth.providers.map(&:name).exclude?('kerberos')
    Settings.omniauth.providers << GitlabSettings::Options.build({ 'name' => 'kerberos' })
  end
end

#
# Smartcard
#
Gitlab.ee do
  Settings['smartcard'] ||= {}
  Settings.smartcard['enabled'] = false if Settings.smartcard['enabled'].nil?
  Settings.smartcard['client_certificate_required_host'] = Settings.gitlab.host if Settings.smartcard['client_certificate_required_host'].nil?
  Settings.smartcard['client_certificate_required_port'] = 3444 if Settings.smartcard['client_certificate_required_port'].nil?
  Settings.smartcard['required_for_git_access'] = false if Settings.smartcard['required_for_git_access'].nil?
  Settings.smartcard['san_extensions'] = false if Settings.smartcard['san_extensions'].nil?
end

#
# FortiAuthenticator
#
Settings['forti_authenticator'] ||= {}
Settings.forti_authenticator['enabled'] = false if Settings.forti_authenticator['enabled'].nil?
Settings.forti_authenticator['port'] = 443 if Settings.forti_authenticator['port'].to_i == 0

#
# FortiToken Cloud
#
Settings['forti_token_cloud'] ||= {}
Settings.forti_token_cloud['enabled'] = false if Settings.forti_token_cloud['enabled'].nil?

#
# DuoAuth
#
Settings['duo_auth'] ||= {}
Settings.duo_auth['enabled'] = false if Settings.duo_auth['enabled'].nil?

#
# Extra customization
#
Settings['extra'] ||= {}
Settings.extra['matomo_site_id'] ||= Settings.extra['piwik_site_id'] if Settings.extra['piwik_site_id'].present?
Settings.extra['matomo_url'] ||= Settings.extra['piwik_url'] if Settings.extra['piwik_url'].present?
Settings.extra['matomo_disable_cookies'] = false if Settings.extra['matomo_disable_cookies'].nil?
Settings.extra['maximum_text_highlight_size_kilobytes'] = Settings.extra.fetch('maximum_text_highlight_size_kilobytes', 512)

#
# Rack::Attack settings
#
Settings['rack_attack'] ||= {}
Settings.rack_attack['git_basic_auth'] ||= {}
Settings.rack_attack.git_basic_auth['enabled'] = false if Settings.rack_attack.git_basic_auth['enabled'].nil?
Settings.rack_attack.git_basic_auth['ip_whitelist'] ||= %w[127.0.0.1]
Settings.rack_attack.git_basic_auth['maxretry'] ||= 10
Settings.rack_attack.git_basic_auth['findtime'] ||= 1.minute
Settings.rack_attack.git_basic_auth['bantime'] ||= 1.hour

#
# Gitaly
#
Settings['gitaly'] ||= {}

#
# Webpack settings
#
Settings['webpack'] ||= {}
Settings.webpack['config_file'] ||= 'config/webpack.config.js'
Settings.webpack['output_dir']  ||= 'public/assets/webpack'
Settings.webpack['public_path'] ||= 'assets/webpack'
Settings.webpack['manifest_filename'] ||= 'manifest.json'
Settings.webpack['dev_server'] ||= {}
Settings.webpack.dev_server['enabled'] ||= false
Settings.webpack.dev_server['host']    ||= 'localhost'
Settings.webpack.dev_server['port']    ||= 3808
Settings.webpack.dev_server['https']   ||= false

#
# Monitoring settings
#
Settings['monitoring'] ||= {}
Settings.monitoring['ip_whitelist'] ||= ['127.0.0.1/8']

Settings.monitoring['sidekiq_exporter'] ||= {}
Settings.monitoring.sidekiq_exporter['enabled'] ||= false
Settings.monitoring.sidekiq_exporter['log_enabled'] ||= false
Settings.monitoring.sidekiq_exporter['address'] ||= 'localhost'
Settings.monitoring.sidekiq_exporter['port'] ||= 8082
Settings.monitoring.sidekiq_exporter['tls_enabled'] ||= false
Settings.monitoring.sidekiq_exporter['tls_cert_path'] ||= nil
Settings.monitoring.sidekiq_exporter['tls_key_path'] ||= nil

Settings.monitoring['sidekiq_health_checks'] ||= {}
Settings.monitoring.sidekiq_health_checks['enabled'] ||= false
Settings.monitoring.sidekiq_health_checks['address'] ||= 'localhost'
Settings.monitoring.sidekiq_health_checks['port'] ||= 8092

Settings.monitoring['web_exporter'] ||= {}
Settings.monitoring.web_exporter['enabled'] ||= false
Settings.monitoring.web_exporter['log_enabled'] ||= true
Settings.monitoring.web_exporter['address'] ||= 'localhost'
Settings.monitoring.web_exporter['port'] ||= 8083
Settings.monitoring.web_exporter['tls_enabled'] ||= false
Settings.monitoring.web_exporter['tls_cert_path'] ||= nil
Settings.monitoring.web_exporter['tls_key_path'] ||= nil

#
# Prometheus settings
#
Settings['prometheus'] ||= {}
Settings.prometheus['enabled'] ||= false
Settings.prometheus['server_address'] ||= nil

#
# Bullet settings
#
Settings['bullet'] ||= {}
Settings.bullet['enabled'] = Gitlab::Utils.to_boolean(ENV['ENABLE_BULLET'], default: Settings.bullet['enabled'])
Settings.bullet['enabled'] = Rails.env.development? if Settings.bullet['enabled'].nil?

#
# Shutdown settings
#
Settings['shutdown'] ||= {}
Settings.shutdown['blackout_seconds'] ||= 10

#
# Testing settings
#
if Rails.env.test?
  Settings.gitlab['default_projects_limit']   = 42
  # `default_can_create_group` is deprecated since GitLab 15.5 in favour of the `can_create_group` column on `ApplicationSetting`.
  Settings.gitlab['default_can_create_group'] = true
  Settings.gitlab['default_can_create_team']  = false
end
