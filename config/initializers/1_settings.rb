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
Settings.gitlab['default_project_creation'] ||= ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS
Settings.gitlab['default_project_deletion_protection'] ||= false
Settings.gitlab['default_projects_limit'] ||= 100000
Settings.gitlab['default_branch_protection'] ||= 2
Settings.gitlab['default_branch_protection_defaults'] ||= ::Gitlab::Access::BranchProtection.protected_fully
# `default_can_create_group` is deprecated since GitLab 15.5 in favour of the `can_create_group` column on `ApplicationSetting`.
Settings.gitlab['default_can_create_group'] = true if Settings.gitlab['default_can_create_group'].nil?
Settings.gitlab['default_theme'] = Gitlab::Themes::APPLICATION_DEFAULT if Settings.gitlab['default_theme'].nil?
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
Settings.gitlab['usage_ping_enabled'] = true if Settings.gitlab['usage_ping_enabled'].nil?
Settings.gitlab['max_request_duration_seconds'] ||= 57
Settings.gitlab['display_initial_root_password'] = false if Settings.gitlab['display_initial_root_password'].nil?
Settings.gitlab['weak_passwords_digest_set'] ||= YAML.safe_load(File.open(Rails.root.join('config', 'weak_password_digests.yml')), permitted_classes: [String]).to_set.freeze
Settings.gitlab['log_decompressed_response_bytesize'] = ENV["GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE"].to_i > 0 ? ENV["GITLAB_LOG_DECOMPRESSED_RESPONSE_BYTESIZE"].to_i : 0

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
end

#
# CI
#
Settings['gitlab_ci'] ||= {}
Settings.gitlab_ci['shared_runners_enabled'] = true if Settings.gitlab_ci['shared_runners_enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.gitlab_ci['builds_path']           = Settings.absolute(Settings.gitlab_ci['builds_path'] || "builds/")
Settings.gitlab_ci['url']                 ||= Settings.__send__(:build_gitlab_ci_url)
Settings.gitlab_ci['server_fqdn']         ||= Settings.__send__(:build_ci_server_fqdn)

#
# CI Secure Files
#
Settings['ci_secure_files'] ||= {}
Settings.ci_secure_files['enabled']      = true if Settings.ci_secure_files['enabled'].nil?
# If you are changing default storage paths, then you must change them in the gitlab-backup-cli gem as well
Settings.ci_secure_files['storage_path'] = Settings.absolute(Settings.ci_secure_files['storage_path'] || File.join(Settings.shared['path'], "ci_secure_files"))
Settings.ci_secure_files['object_store'] = ObjectStoreSettings.legacy_parse(Settings.ci_secure_files['object_store'], 'secure_files')

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
  # For backwards compatibility, default to gitlab_url and if so, ensure it ends with "/"
  Settings.geo['node_name'] = Settings.geo['node_name'].presence || Settings.gitlab['url'].chomp('/').concat('/')

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

# For first iteration dependency proxy uses Rails server to download blobs.
# To ensure acceptable performance we only allow feature to be used with
# multithreaded web-server Puma. This will be removed once download logic is moved
# to GitLab workhorse
Settings.dependency_proxy['enabled'] = false unless Gitlab::Runtime.puma?

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

if Gitlab.ee? && Settings['ee_cron_jobs']
  Settings.cron_jobs.merge!(Settings.ee_cron_jobs)
end

Settings.cron_jobs['poll_interval'] ||= ENV["GITLAB_CRON_JOBS_POLL_INTERVAL"] ? ENV["GITLAB_CRON_JOBS_POLL_INTERVAL"].to_i : nil
Settings.cron_jobs['stuck_ci_jobs_worker'] ||= {}
Settings.cron_jobs['stuck_ci_jobs_worker']['cron'] ||= '0 * * * *'
Settings.cron_jobs['stuck_ci_jobs_worker']['job_class'] = 'StuckCiJobsWorker'
Settings.cron_jobs['pipeline_schedule_worker'] ||= {}
Settings.cron_jobs['pipeline_schedule_worker']['cron'] ||= '3-59/10 * * * *'
Settings.cron_jobs['pipeline_schedule_worker']['job_class'] = 'PipelineScheduleWorker'
Settings.cron_jobs['expire_build_artifacts_worker'] ||= {}
Settings.cron_jobs['expire_build_artifacts_worker']['cron'] ||= '*/7 * * * *'
Settings.cron_jobs['expire_build_artifacts_worker']['job_class'] = 'ExpireBuildArtifactsWorker'
Settings.cron_jobs['update_locked_unknown_artifacts_worker'] ||= {}
Settings.cron_jobs['update_locked_unknown_artifacts_worker']['cron'] ||= '*/7 * * * *'
Settings.cron_jobs['update_locked_unknown_artifacts_worker']['job_class'] = 'Ci::UpdateLockedUnknownArtifactsWorker'
Settings.cron_jobs['ci_partitioning_worker'] ||= {}
Settings.cron_jobs['ci_partitioning_worker']['cron'] ||= '0 2 * * *'
Settings.cron_jobs['ci_partitioning_worker']['job_class'] = 'Ci::PartitioningWorker'
Settings.cron_jobs['ci_pipelines_expire_artifacts_worker'] ||= {}
Settings.cron_jobs['ci_pipelines_expire_artifacts_worker']['cron'] ||= '*/23 * * * *'
Settings.cron_jobs['ci_pipelines_expire_artifacts_worker']['job_class'] = 'Ci::PipelineArtifacts::ExpireArtifactsWorker'
Settings.cron_jobs['ci_schedule_delete_objects_worker'] ||= {}
Settings.cron_jobs['ci_schedule_delete_objects_worker']['cron'] ||= '*/16 * * * *'
Settings.cron_jobs['ci_schedule_delete_objects_worker']['job_class'] = 'Ci::ScheduleDeleteObjectsCronWorker'
Settings.cron_jobs['environments_auto_stop_cron_worker'] ||= {}
Settings.cron_jobs['environments_auto_stop_cron_worker']['cron'] ||= '24 * * * *'
Settings.cron_jobs['environments_auto_stop_cron_worker']['job_class'] = 'Environments::AutoStopCronWorker'
Settings.cron_jobs['environments_auto_delete_cron_worker'] ||= {}
Settings.cron_jobs['environments_auto_delete_cron_worker']['cron'] ||= '34 * * * *'
Settings.cron_jobs['environments_auto_delete_cron_worker']['job_class'] = 'Environments::AutoDeleteCronWorker'
Settings.cron_jobs['repository_check_worker'] ||= {}
Settings.cron_jobs['repository_check_worker']['cron'] ||= '20 * * * *'
Settings.cron_jobs['repository_check_worker']['job_class'] = 'RepositoryCheck::DispatchWorker'
Settings.cron_jobs['admin_email_worker'] ||= {}
Settings.cron_jobs['admin_email_worker']['cron'] ||= '0 0 * * 0'
Settings.cron_jobs['admin_email_worker']['job_class'] = 'AdminEmailWorker'
Settings.cron_jobs['personal_access_tokens_expiring_worker'] ||= {}
Settings.cron_jobs['personal_access_tokens_expiring_worker']['cron'] ||= '0 1 * * *'
Settings.cron_jobs['personal_access_tokens_expiring_worker']['job_class'] = 'PersonalAccessTokens::ExpiringWorker'
Settings.cron_jobs['personal_access_tokens_expired_notification_worker'] ||= {}
Settings.cron_jobs['personal_access_tokens_expired_notification_worker']['cron'] ||= '0 2 * * *'
Settings.cron_jobs['personal_access_tokens_expired_notification_worker']['job_class'] = 'PersonalAccessTokens::ExpiredNotificationWorker'
Settings.cron_jobs['resource_access_tokens_inactive_tokens_deletion_cron_worker'] ||= {}
Settings.cron_jobs['resource_access_tokens_inactive_tokens_deletion_cron_worker']['cron'] ||= '0 0 * * *'
Settings.cron_jobs['resource_access_tokens_inactive_tokens_deletion_cron_worker']['job_class'] = 'ResourceAccessTokens::InactiveTokensDeletionCronWorker'
Settings.cron_jobs['repository_archive_cache_worker'] ||= {}
Settings.cron_jobs['repository_archive_cache_worker']['cron'] ||= '0 * * * *'
Settings.cron_jobs['repository_archive_cache_worker']['job_class'] = 'RepositoryArchiveCacheWorker'
Settings.cron_jobs['import_export_project_cleanup_worker'] ||= {}
Settings.cron_jobs['import_export_project_cleanup_worker']['cron'] ||= '0 * * * *'
Settings.cron_jobs['import_export_project_cleanup_worker']['job_class'] = 'ImportExportProjectCleanupWorker'
Settings.cron_jobs['ci_archive_traces_cron_worker'] ||= {}
Settings.cron_jobs['ci_archive_traces_cron_worker']['cron'] ||= '17 * * * *'
Settings.cron_jobs['ci_archive_traces_cron_worker']['job_class'] = 'Ci::ArchiveTracesCronWorker'
Settings.cron_jobs['members_expiring_worker'] ||= {}
Settings.cron_jobs['members_expiring_worker']['cron'] ||= '0 1 * * *'
Settings.cron_jobs['members_expiring_worker']['job_class'] = 'Members::ExpiringWorker'
Settings.cron_jobs['remove_expired_members_worker'] ||= {}
Settings.cron_jobs['remove_expired_members_worker']['cron'] ||= '10 0 * * *'
Settings.cron_jobs['remove_expired_members_worker']['job_class'] = 'RemoveExpiredMembersWorker'
Settings.cron_jobs['remove_expired_group_links_worker'] ||= {}
Settings.cron_jobs['remove_expired_group_links_worker']['cron'] ||= '10 0 * * *'
Settings.cron_jobs['remove_expired_group_links_worker']['job_class'] = 'RemoveExpiredGroupLinksWorker'
Settings.cron_jobs['remove_unaccepted_member_invites_worker'] ||= {}
Settings.cron_jobs['remove_unaccepted_member_invites_worker']['cron'] ||= '10 15 * * *'
Settings.cron_jobs['remove_unaccepted_member_invites_worker']['job_class'] = 'RemoveUnacceptedMemberInvitesWorker'
Settings.cron_jobs['prune_old_events_worker'] ||= {}
Settings.cron_jobs['prune_old_events_worker']['cron'] ||= '0 */6 * * *'
Settings.cron_jobs['prune_old_events_worker']['job_class'] = 'PruneOldEventsWorker'
Settings.cron_jobs['gitlab_export_prune_project_export_jobs_worker'] ||= {}
Settings.cron_jobs['gitlab_export_prune_project_export_jobs_worker']['cron'] ||= '30 3 * * *'
Settings.cron_jobs['gitlab_export_prune_project_export_jobs_worker']['job_class'] = 'Gitlab::Export::PruneProjectExportJobsWorker'
Settings.cron_jobs['trending_projects_worker'] ||= {}
Settings.cron_jobs['trending_projects_worker']['cron'] = '0 1 * * *'
Settings.cron_jobs['trending_projects_worker']['job_class'] = 'TrendingProjectsWorker'
Settings.cron_jobs['remove_unreferenced_lfs_objects_worker'] ||= {}
Settings.cron_jobs['remove_unreferenced_lfs_objects_worker']['cron'] ||= '20 0 * * *'
Settings.cron_jobs['remove_unreferenced_lfs_objects_worker']['job_class'] = 'RemoveUnreferencedLfsObjectsWorker'
Settings.cron_jobs['bulk_imports_stale_import_worker'] ||= {}
Settings.cron_jobs['bulk_imports_stale_import_worker']['cron'] ||= '0 */4 * * *'
Settings.cron_jobs['bulk_imports_stale_import_worker']['job_class'] = 'BulkImports::StaleImportWorker'
Settings.cron_jobs['import_stuck_project_import_jobs'] ||= {}
Settings.cron_jobs['import_stuck_project_import_jobs']['cron'] ||= '15 * * * *'
Settings.cron_jobs['import_stuck_project_import_jobs']['job_class'] = 'Gitlab::Import::StuckProjectImportJobsWorker'
Settings.cron_jobs['jira_import_stuck_jira_import_jobs'] ||= {}
Settings.cron_jobs['jira_import_stuck_jira_import_jobs']['cron'] ||= '* 0/15 * * *'
Settings.cron_jobs['jira_import_stuck_jira_import_jobs']['job_class'] = 'Gitlab::JiraImport::StuckJiraImportJobsWorker'
Settings.cron_jobs['stuck_export_jobs_worker'] ||= {}
Settings.cron_jobs['stuck_export_jobs_worker']['cron'] ||= '30 * * * *'
Settings.cron_jobs['stuck_export_jobs_worker']['job_class'] = 'StuckExportJobsWorker'
Settings.cron_jobs['gitlab_service_ping_worker'] ||= {}
Settings.cron_jobs['gitlab_service_ping_worker']['cron'] ||= nil # This is dynamically loaded in the sidekiq initializer
Settings.cron_jobs['gitlab_service_ping_worker']['job_class'] = 'GitlabServicePingWorker'
Settings.cron_jobs['stuck_merge_jobs_worker'] ||= {}
Settings.cron_jobs['stuck_merge_jobs_worker']['cron'] ||= '*/15 * * * *'
Settings.cron_jobs['stuck_merge_jobs_worker']['job_class'] = 'StuckMergeJobsWorker'
Settings.cron_jobs['pages_domain_verification_cron_worker'] ||= {}
Settings.cron_jobs['pages_domain_verification_cron_worker']['cron'] ||= '*/15 * * * *'
Settings.cron_jobs['pages_domain_verification_cron_worker']['job_class'] = 'PagesDomainVerificationCronWorker'
Settings.cron_jobs['pages_domain_removal_cron_worker'] ||= {}
Settings.cron_jobs['pages_domain_removal_cron_worker']['cron'] ||= '47 0 * * *'
Settings.cron_jobs['pages_domain_removal_cron_worker']['job_class'] = 'PagesDomainRemovalCronWorker'
Settings.cron_jobs['pages_domain_ssl_renewal_cron_worker'] ||= {}
Settings.cron_jobs['pages_domain_ssl_renewal_cron_worker']['cron'] ||= '*/10 * * * *'
Settings.cron_jobs['pages_domain_ssl_renewal_cron_worker']['job_class'] = 'PagesDomainSslRenewalCronWorker'
Settings.cron_jobs['issue_due_scheduler_worker'] ||= {}
Settings.cron_jobs['issue_due_scheduler_worker']['cron'] ||= '50 00 * * *'
Settings.cron_jobs['issue_due_scheduler_worker']['job_class'] = 'IssueDueSchedulerWorker'
Settings.cron_jobs['schedule_migrate_external_diffs_worker'] ||= {}
Settings.cron_jobs['schedule_migrate_external_diffs_worker']['cron'] ||= '15 * * * *'
Settings.cron_jobs['schedule_migrate_external_diffs_worker']['job_class'] = 'ScheduleMigrateExternalDiffsWorker'
Settings.cron_jobs['namespaces_prune_aggregation_schedules_worker'] ||= {}
Settings.cron_jobs['namespaces_prune_aggregation_schedules_worker']['cron'] ||= '5 1 * * *'
Settings.cron_jobs['namespaces_prune_aggregation_schedules_worker']['job_class'] = 'Namespaces::PruneAggregationSchedulesWorker'
Settings.cron_jobs['container_expiration_policy_worker'] ||= {}
Settings.cron_jobs['container_expiration_policy_worker']['cron'] ||= '50 * * * *'
Settings.cron_jobs['container_expiration_policy_worker']['job_class'] = 'ContainerExpirationPolicyWorker'
Settings.cron_jobs['cleanup_container_registry_worker'] ||= {}
Settings.cron_jobs['cleanup_container_registry_worker']['cron'] ||= '*/5 * * * *'
Settings.cron_jobs['cleanup_container_registry_worker']['job_class'] = 'ContainerRegistry::CleanupWorker'
Settings.cron_jobs['image_ttl_group_policy_worker'] ||= {}
Settings.cron_jobs['image_ttl_group_policy_worker']['cron'] ||= '40 0 * * *'
Settings.cron_jobs['image_ttl_group_policy_worker']['job_class'] = 'DependencyProxy::ImageTtlGroupPolicyWorker'
Settings.cron_jobs['cleanup_dependency_proxy_worker'] ||= {}
Settings.cron_jobs['cleanup_dependency_proxy_worker']['cron'] ||= '20 3,15 * * *'
Settings.cron_jobs['cleanup_dependency_proxy_worker']['job_class'] = 'DependencyProxy::CleanupDependencyProxyWorker'
Settings.cron_jobs['cleanup_package_registry_worker'] ||= {}
Settings.cron_jobs['cleanup_package_registry_worker']['cron'] ||= '20 * * * *'
Settings.cron_jobs['cleanup_package_registry_worker']['job_class'] = 'Packages::CleanupPackageRegistryWorker'
Settings.cron_jobs['x509_issuer_crl_check_worker'] ||= {}
Settings.cron_jobs['x509_issuer_crl_check_worker']['cron'] ||= '30 1 * * *'
Settings.cron_jobs['x509_issuer_crl_check_worker']['job_class'] = 'X509IssuerCrlCheckWorker'
Settings.cron_jobs['users_create_statistics_worker'] ||= {}
Settings.cron_jobs['users_create_statistics_worker']['cron'] ||= '2 15 * * *'
Settings.cron_jobs['users_create_statistics_worker']['job_class'] = 'Users::CreateStatisticsWorker'
Settings.cron_jobs['authorized_project_update_periodic_recalculate_worker'] ||= {}
Settings.cron_jobs['authorized_project_update_periodic_recalculate_worker']['cron'] ||= '45 1 1,15 * *'
Settings.cron_jobs['authorized_project_update_periodic_recalculate_worker']['job_class'] = 'AuthorizedProjectUpdate::PeriodicRecalculateWorker'
Settings.cron_jobs['update_container_registry_info_worker'] ||= {}
Settings.cron_jobs['update_container_registry_info_worker']['cron'] ||= '0 0 * * *'
Settings.cron_jobs['update_container_registry_info_worker']['job_class'] = 'UpdateContainerRegistryInfoWorker'
Settings.cron_jobs['postgres_dynamic_partitions_manager'] ||= {}
Settings.cron_jobs['postgres_dynamic_partitions_manager']['cron'] ||= '21 */6 * * *'
Settings.cron_jobs['postgres_dynamic_partitions_manager']['job_class'] ||= 'Database::PartitionManagementWorker'
Settings.cron_jobs['postgres_dynamic_partitions_dropper'] ||= {}
Settings.cron_jobs['postgres_dynamic_partitions_dropper']['cron'] ||= '45 12 * * *'
Settings.cron_jobs['postgres_dynamic_partitions_dropper']['job_class'] ||= 'Database::DropDetachedPartitionsWorker'
Settings.cron_jobs['analytics_usage_trends_count_job_trigger_worker'] ||= {}
Settings.cron_jobs['analytics_usage_trends_count_job_trigger_worker']['cron'] ||= '50 23 */1 * *'
Settings.cron_jobs['analytics_usage_trends_count_job_trigger_worker']['job_class'] ||= 'Analytics::UsageTrends::CountJobTriggerWorker'
Settings.cron_jobs['member_invitation_reminder_emails_worker'] ||= {}
Settings.cron_jobs['member_invitation_reminder_emails_worker']['cron'] ||= '0 0 * * *'
Settings.cron_jobs['member_invitation_reminder_emails_worker']['job_class'] = 'MemberInvitationReminderEmailsWorker'
Settings.cron_jobs['schedule_merge_request_cleanup_refs_worker'] ||= {}
Settings.cron_jobs['schedule_merge_request_cleanup_refs_worker']['cron'] ||= '* * * * *'
Settings.cron_jobs['schedule_merge_request_cleanup_refs_worker']['job_class'] = 'ScheduleMergeRequestCleanupRefsWorker'
Settings.cron_jobs['manage_evidence_worker'] ||= {}
Settings.cron_jobs['manage_evidence_worker']['cron'] ||= '0 * * * *'
Settings.cron_jobs['manage_evidence_worker']['job_class'] = 'Releases::ManageEvidenceWorker'
Settings.cron_jobs['publish_release_worker'] ||= {}
Settings.cron_jobs['publish_release_worker']['cron'] ||= '20,50 * * * *'
Settings.cron_jobs['publish_release_worker']['job_class'] = 'Releases::PublishEventWorker'
Settings.cron_jobs['user_status_cleanup_batch_worker'] ||= {}
Settings.cron_jobs['user_status_cleanup_batch_worker']['cron'] ||= '* * * * *'
Settings.cron_jobs['user_status_cleanup_batch_worker']['job_class'] = 'UserStatusCleanup::BatchWorker'
Settings.cron_jobs['ssh_keys_expired_notification_worker'] ||= {}
Settings.cron_jobs['ssh_keys_expired_notification_worker']['cron'] ||= '0 2,14 * * *'
Settings.cron_jobs['ssh_keys_expired_notification_worker']['job_class'] = 'SshKeys::ExpiredNotificationWorker'
Settings.cron_jobs['ssh_keys_expiring_soon_notification_worker'] ||= {}
Settings.cron_jobs['ssh_keys_expiring_soon_notification_worker']['cron'] ||= '0 1 * * *'
Settings.cron_jobs['ssh_keys_expiring_soon_notification_worker']['job_class'] = 'SshKeys::ExpiringSoonNotificationWorker'
Settings.cron_jobs['users_deactivate_dormant_users_worker'] ||= {}
Settings.cron_jobs['users_deactivate_dormant_users_worker']['cron'] ||= '21,42 0-4 * * *'
Settings.cron_jobs['users_deactivate_dormant_users_worker']['job_class'] = 'Users::DeactivateDormantUsersWorker'
Settings.cron_jobs['ci_delete_unit_tests_worker'] ||= {}
Settings.cron_jobs['ci_delete_unit_tests_worker']['cron'] ||= '0 0 * * *'
Settings.cron_jobs['ci_delete_unit_tests_worker']['job_class'] = 'Ci::DeleteUnitTestsWorker'
Settings.cron_jobs['batched_background_migrations_worker'] ||= {}
Settings.cron_jobs['batched_background_migrations_worker']['cron'] ||= '* * * * *'
Settings.cron_jobs['batched_background_migrations_worker']['job_class'] = 'Database::BatchedBackgroundMigrationWorker'
Settings.cron_jobs['batched_background_migration_worker_ci_database'] ||= {}
Settings.cron_jobs['batched_background_migration_worker_ci_database']['cron'] ||= '* * * * *'
Settings.cron_jobs['batched_background_migration_worker_ci_database']['job_class'] = 'Database::BatchedBackgroundMigration::CiDatabaseWorker'
Settings.cron_jobs['issues_reschedule_stuck_issue_rebalances'] ||= {}
Settings.cron_jobs['issues_reschedule_stuck_issue_rebalances']['cron'] ||= '*/15 * * * *'
Settings.cron_jobs['issues_reschedule_stuck_issue_rebalances']['job_class'] = 'Issues::RescheduleStuckIssueRebalancesWorker'
Settings.cron_jobs['projects_schedule_refresh_build_artifacts_size_statistics_worker'] ||= {}
Settings.cron_jobs['projects_schedule_refresh_build_artifacts_size_statistics_worker']['cron'] ||= '2/17 * * * *'
Settings.cron_jobs['projects_schedule_refresh_build_artifacts_size_statistics_worker']['job_class'] = 'Projects::ScheduleRefreshBuildArtifactsSizeStatisticsWorker'
Settings.cron_jobs['inactive_projects_deletion_cron_worker'] ||= {}
Settings.cron_jobs['inactive_projects_deletion_cron_worker']['cron'] ||= '*/10 * * * *'
Settings.cron_jobs['inactive_projects_deletion_cron_worker']['job_class'] = 'Projects::InactiveProjectsDeletionCronWorker'
Settings.cron_jobs['loose_foreign_keys_cleanup_worker'] ||= {}
Settings.cron_jobs['loose_foreign_keys_cleanup_worker']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['loose_foreign_keys_cleanup_worker']['job_class'] = 'LooseForeignKeys::CleanupWorker'
Settings.cron_jobs['batched_git_ref_updates_cleanup_scheduler_worker'] ||= {}
Settings.cron_jobs['batched_git_ref_updates_cleanup_scheduler_worker']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['batched_git_ref_updates_cleanup_scheduler_worker']['job_class'] = 'BatchedGitRefUpdates::CleanupSchedulerWorker'
Settings.cron_jobs['ci_runner_versions_reconciliation_worker'] ||= {}
Settings.cron_jobs['ci_runner_versions_reconciliation_worker']['cron'] ||= '@daily'
Settings.cron_jobs['ci_runner_versions_reconciliation_worker']['job_class'] = 'Ci::Runners::ReconcileExistingRunnerVersionsCronWorker'
Settings.cron_jobs['users_migrate_records_to_ghost_user_in_batches_worker'] ||= {}
Settings.cron_jobs['users_migrate_records_to_ghost_user_in_batches_worker']['cron'] ||= '*/2 * * * *'
Settings.cron_jobs['users_migrate_records_to_ghost_user_in_batches_worker']['job_class'] = 'Users::MigrateRecordsToGhostUserInBatchesWorker'
Settings.cron_jobs['ci_runners_stale_machines_cleanup_worker'] ||= {}
Settings.cron_jobs['ci_runners_stale_machines_cleanup_worker']['cron'] ||= '36 * * * *'
Settings.cron_jobs['ci_runners_stale_machines_cleanup_worker']['job_class'] = 'Ci::Runners::StaleMachinesCleanupCronWorker'
Settings.cron_jobs['packages_cleanup_delete_orphaned_dependencies_worker'] ||= {}
Settings.cron_jobs['packages_cleanup_delete_orphaned_dependencies_worker']['cron'] ||= '*/10 * * * *'
Settings.cron_jobs['packages_cleanup_delete_orphaned_dependencies_worker']['job_class'] = 'Packages::Cleanup::DeleteOrphanedDependenciesWorker'
Settings.cron_jobs['cleanup_dangling_debian_package_files_worker'] ||= {}
Settings.cron_jobs['cleanup_dangling_debian_package_files_worker']['cron'] ||= '20 21 * * *'
Settings.cron_jobs['cleanup_dangling_debian_package_files_worker']['job_class'] = 'Packages::Debian::CleanupDanglingPackageFilesWorker'
Settings.cron_jobs['object_storage_delete_stale_direct_uploads_worker'] ||= {}
Settings.cron_jobs['object_storage_delete_stale_direct_uploads_worker']['cron'] ||= '*/6 * * * *'
Settings.cron_jobs['object_storage_delete_stale_direct_uploads_worker']['job_class'] = 'ObjectStorage::DeleteStaleDirectUploadsWorker'
Settings.cron_jobs['service_desk_custom_email_verification_cleanup'] ||= {}
Settings.cron_jobs['service_desk_custom_email_verification_cleanup']['cron'] ||= '*/2 * * * *'
Settings.cron_jobs['service_desk_custom_email_verification_cleanup']['job_class'] = 'ServiceDesk::CustomEmailVerificationCleanupWorker'
Settings.cron_jobs['deactivated_pages_deployments_delete_cron_worker'] ||= {}
Settings.cron_jobs['deactivated_pages_deployments_delete_cron_worker']['cron'] ||= '*/10 * * * *'
Settings.cron_jobs['deactivated_pages_deployments_delete_cron_worker']['job_class'] ||= 'Pages::DeactivatedDeploymentsDeleteCronWorker'
Settings.cron_jobs['ci_schedule_unlock_pipelines_in_queue_worker'] ||= {}
Settings.cron_jobs['ci_schedule_unlock_pipelines_in_queue_worker']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['ci_schedule_unlock_pipelines_in_queue_worker']['job_class'] = 'Ci::ScheduleUnlockPipelinesInQueueCronWorker'
Settings.cron_jobs['ci_catalog_resources_process_sync_events_worker'] ||= {}
Settings.cron_jobs['ci_catalog_resources_process_sync_events_worker']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['ci_catalog_resources_process_sync_events_worker']['job_class'] = 'Ci::Catalog::Resources::ProcessSyncEventsWorker'
Settings.cron_jobs['namespaces_process_outdated_namespace_descendants_cron_worker'] ||= {}
Settings.cron_jobs['namespaces_process_outdated_namespace_descendants_cron_worker']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['namespaces_process_outdated_namespace_descendants_cron_worker']['job_class'] = 'Namespaces::ProcessOutdatedNamespaceDescendantsCronWorker'
Settings.cron_jobs['performance_bar_stats'] ||= {}
Settings.cron_jobs['performance_bar_stats']['cron'] ||= '*/2 * * * *'
Settings.cron_jobs['performance_bar_stats']['job_class'] = 'GitlabPerformanceBarStatsWorker'
Settings.cron_jobs['ci_catalog_resources_aggregate_last30_day_usage_worker'] ||= {}
Settings.cron_jobs['ci_catalog_resources_aggregate_last30_day_usage_worker']['cron'] ||= '*/4 * * * *'
Settings.cron_jobs['ci_catalog_resources_aggregate_last30_day_usage_worker']['job_class'] = 'Ci::Catalog::Resources::AggregateLast30DayUsageWorker'
Settings.cron_jobs['ci_catalog_resources_cleanup_last_usages_worker'] ||= {}
Settings.cron_jobs['ci_catalog_resources_cleanup_last_usages_worker']['cron'] ||= '0 0 * * *'
Settings.cron_jobs['ci_catalog_resources_cleanup_last_usages_worker']['job_class'] = 'Ci::Catalog::Resources::CleanupLastUsagesWorker'
Settings.cron_jobs['ci_click_house_finished_pipelines_sync_worker'] ||= {}
Settings.cron_jobs['ci_click_house_finished_pipelines_sync_worker']['cron'] ||= '*/4 * * * *'
Settings.cron_jobs['ci_click_house_finished_pipelines_sync_worker']['args'] ||= [1]
Settings.cron_jobs['ci_click_house_finished_pipelines_sync_worker']['job_class'] = 'Ci::ClickHouse::FinishedPipelinesSyncCronWorker'
Settings.cron_jobs['deactivate_expired_deployments_cron_worker'] ||= {}
Settings.cron_jobs['deactivate_expired_deployments_cron_worker']['cron'] ||= '*/10 * * * *'
Settings.cron_jobs['deactivate_expired_deployments_cron_worker']['job_class'] ||= 'Pages::DeactivateExpiredDeploymentsCronWorker'
Settings.cron_jobs['database_monitor_locked_tables_cron_worker'] ||= {}
Settings.cron_jobs['database_monitor_locked_tables_cron_worker']['cron'] ||= '30 7 */3 * *'
Settings.cron_jobs['database_monitor_locked_tables_cron_worker']['job_class'] = 'Database::MonitorLockedTablesWorker'
Settings.cron_jobs['merge_requests_process_scheduled_merge'] ||= {}
Settings.cron_jobs['merge_requests_process_scheduled_merge']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['merge_requests_process_scheduled_merge']['job_class'] = 'MergeRequests::ProcessScheduledMergeWorker'
Settings.cron_jobs['ci_schedule_old_pipelines_removal_cron_worker'] ||= {}
Settings.cron_jobs['ci_schedule_old_pipelines_removal_cron_worker']['cron'] ||= '*/11 * * * *'
Settings.cron_jobs['ci_schedule_old_pipelines_removal_cron_worker']['job_class'] = 'Ci::ScheduleOldPipelinesRemovalCronWorker'

Gitlab.ee do
  Settings.cron_jobs['analytics_devops_adoption_create_all_snapshots_worker'] ||= {}
  Settings.cron_jobs['analytics_devops_adoption_create_all_snapshots_worker']['cron'] ||= '0 1 * * *'
  Settings.cron_jobs['analytics_devops_adoption_create_all_snapshots_worker']['job_class'] = 'Analytics::DevopsAdoption::CreateAllSnapshotsWorker'
  Settings.cron_jobs['analytics_cycle_analytics_incremental_worker'] ||= {}
  Settings.cron_jobs['analytics_cycle_analytics_incremental_worker']['cron'] ||= '*/10 * * * *'
  Settings.cron_jobs['analytics_cycle_analytics_incremental_worker']['job_class'] = 'Analytics::CycleAnalytics::IncrementalWorker'
  Settings.cron_jobs['analytics_cycle_analytics_consistency_worker'] ||= {}
  Settings.cron_jobs['analytics_cycle_analytics_consistency_worker']['cron'] ||= '*/30 * * * *'
  Settings.cron_jobs['analytics_cycle_analytics_consistency_worker']['job_class'] = 'Analytics::CycleAnalytics::ConsistencyWorker'
  Settings.cron_jobs['analytics_cycle_analytics_reaggregation_worker'] ||= {}
  Settings.cron_jobs['analytics_cycle_analytics_reaggregation_worker']['cron'] ||= '*/25 * * * *'
  Settings.cron_jobs['analytics_cycle_analytics_reaggregation_worker']['job_class'] = 'Analytics::CycleAnalytics::ReaggregationWorker'
  Settings.cron_jobs['analytics_cycle_analytics_stage_aggregation_worker'] ||= {}
  Settings.cron_jobs['analytics_cycle_analytics_stage_aggregation_worker']['cron'] ||= '*/5 * * * *'
  Settings.cron_jobs['analytics_cycle_analytics_stage_aggregation_worker']['job_class'] = 'Analytics::CycleAnalytics::StageAggregationWorker'
  Settings.cron_jobs['analytics_value_stream_dashboard_count_worker'] ||= {}
  Settings.cron_jobs['analytics_value_stream_dashboard_count_worker']['cron'] ||= '*/7 * * * *'
  Settings.cron_jobs['analytics_value_stream_dashboard_count_worker']['job_class'] = 'Analytics::ValueStreamDashboard::CountWorker'
  Settings.cron_jobs['active_user_count_threshold_worker'] ||= {}
  Settings.cron_jobs['active_user_count_threshold_worker']['cron'] ||= '0 12 * * *'
  Settings.cron_jobs['active_user_count_threshold_worker']['job_class'] = 'ActiveUserCountThresholdWorker'
  Settings.cron_jobs['adjourned_group_deletion_worker'] ||= {}
  Settings.cron_jobs['adjourned_group_deletion_worker']['cron'] ||= '0 2 * * *'
  Settings.cron_jobs['adjourned_group_deletion_worker']['job_class'] = 'AdjournedGroupDeletionWorker'
  Settings.cron_jobs['adjourned_projects_deletion_cron_worker'] ||= {}
  Settings.cron_jobs['adjourned_projects_deletion_cron_worker']['cron'] ||= '0 7 * * *'
  Settings.cron_jobs['adjourned_projects_deletion_cron_worker']['job_class'] = 'AdjournedProjectsDeletionCronWorker'
  Settings.cron_jobs['banned_user_project_deletion_cron_worker'] ||= {}
  Settings.cron_jobs['banned_user_project_deletion_cron_worker']['cron'] ||= '0 19 * * *'
  Settings.cron_jobs['banned_user_project_deletion_cron_worker']['job_class'] = 'AntiAbuse::BannedUserProjectDeletionCronWorker'
  Settings.cron_jobs['geo_verification_cron_worker'] ||= {}
  Settings.cron_jobs['geo_verification_cron_worker']['cron'] ||= '* * * * *'
  Settings.cron_jobs['geo_verification_cron_worker']['job_class'] ||= 'Geo::VerificationCronWorker'
  Settings.cron_jobs['geo_sync_timeout_cron_worker'] ||= {}
  Settings.cron_jobs['geo_sync_timeout_cron_worker']['cron'] ||= '*/10 * * * *'
  Settings.cron_jobs['geo_sync_timeout_cron_worker']['job_class'] ||= 'Geo::SyncTimeoutCronWorker'
  Settings.cron_jobs['geo_secondary_usage_data_cron_worker'] ||= {}
  Settings.cron_jobs['geo_secondary_usage_data_cron_worker']['cron'] ||= '0 0 * * 0'
  Settings.cron_jobs['geo_secondary_usage_data_cron_worker']['job_class'] ||= 'Geo::SecondaryUsageDataCronWorker'
  Settings.cron_jobs['geo_registry_sync_worker'] ||= {}
  Settings.cron_jobs['geo_registry_sync_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['geo_registry_sync_worker']['job_class'] ||= 'Geo::RegistrySyncWorker'
  Settings.cron_jobs['geo_repository_registry_sync_worker'] ||= {}
  Settings.cron_jobs['geo_repository_registry_sync_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['geo_repository_registry_sync_worker']['job_class'] ||= 'Geo::RepositoryRegistrySyncWorker'
  Settings.cron_jobs['geo_metrics_update_worker'] ||= {}
  Settings.cron_jobs['geo_metrics_update_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['geo_metrics_update_worker']['job_class'] ||= 'Geo::MetricsUpdateWorker'
  Settings.cron_jobs['geo_prune_event_log_worker'] ||= {}
  Settings.cron_jobs['geo_prune_event_log_worker']['cron'] ||= '*/5 * * * *'
  Settings.cron_jobs['geo_prune_event_log_worker']['job_class'] ||= 'Geo::PruneEventLogWorker'
  Settings.cron_jobs['geo_secondary_registry_consistency_worker'] ||= {}
  Settings.cron_jobs['geo_secondary_registry_consistency_worker']['cron'] ||= '* * * * *'
  Settings.cron_jobs['geo_secondary_registry_consistency_worker']['job_class'] ||= 'Geo::Secondary::RegistryConsistencyWorker'
  Settings.cron_jobs['historical_data_worker'] ||= {}
  Settings.cron_jobs['historical_data_worker']['cron'] ||= '0 12 * * *'
  Settings.cron_jobs['historical_data_worker']['job_class'] = 'HistoricalDataWorker'
  Settings.cron_jobs['incident_sla_exceeded_check_worker'] ||= {}
  Settings.cron_jobs['incident_sla_exceeded_check_worker']['cron'] ||= '*/2 * * * *'
  Settings.cron_jobs['incident_sla_exceeded_check_worker']['job_class'] = 'IncidentManagement::IncidentSlaExceededCheckWorker'
  Settings.cron_jobs['incident_management_persist_oncall_rotation_worker'] ||= {}
  Settings.cron_jobs['incident_management_persist_oncall_rotation_worker']['cron'] ||= '*/5 * * * *'
  Settings.cron_jobs['incident_management_persist_oncall_rotation_worker']['job_class'] = 'IncidentManagement::OncallRotations::PersistAllRotationsShiftsJob'
  Settings.cron_jobs['incident_management_schedule_escalation_check_worker'] ||= {}
  Settings.cron_jobs['incident_management_schedule_escalation_check_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['incident_management_schedule_escalation_check_worker']['job_class'] = 'IncidentManagement::PendingEscalations::ScheduleCheckCronWorker'
  Settings.cron_jobs['import_software_licenses_worker'] ||= {}
  Settings.cron_jobs['import_software_licenses_worker']['cron'] ||= '0 3 * * 0'
  Settings.cron_jobs['import_software_licenses_worker']['job_class'] = 'ImportSoftwareLicensesWorker'
  Settings.cron_jobs['ldap_group_sync_worker'] ||= {}
  Settings.cron_jobs['ldap_group_sync_worker']['cron'] ||= '0 * * * *'
  Settings.cron_jobs['ldap_group_sync_worker']['job_class'] = 'LdapAllGroupsSyncWorker'
  Settings.cron_jobs['ldap_sync_worker'] ||= {}
  Settings.cron_jobs['ldap_sync_worker']['cron'] ||= '30 1 * * *'
  Settings.cron_jobs['ldap_sync_worker']['job_class'] = 'LdapSyncWorker'
  Settings.cron_jobs['elastic_index_bulk_cron_worker'] ||= {}
  Settings.cron_jobs['elastic_index_bulk_cron_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['elastic_index_bulk_cron_worker']['job_class'] ||= 'ElasticIndexBulkCronWorker'
  Settings.cron_jobs['elastic_index_embedding_bulk_cron_worker'] ||= {}
  Settings.cron_jobs['elastic_index_embedding_bulk_cron_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['elastic_index_embedding_bulk_cron_worker']['job_class'] ||= 'Search::ElasticIndexEmbeddingBulkCronWorker'
  Settings.cron_jobs['elastic_index_initial_bulk_cron_worker'] ||= {}
  Settings.cron_jobs['elastic_index_initial_bulk_cron_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['elastic_index_initial_bulk_cron_worker']['job_class'] ||= 'ElasticIndexInitialBulkCronWorker'
  Settings.cron_jobs['elastic_cluster_reindexing_cron_worker'] ||= {}
  Settings.cron_jobs['elastic_cluster_reindexing_cron_worker']['cron'] ||= '*/5 * * * *'
  Settings.cron_jobs['elastic_cluster_reindexing_cron_worker']['job_class'] ||= 'ElasticClusterReindexingCronWorker'
  Settings.cron_jobs['elastic_remove_expired_namespace_subscriptions_from_index_cron_worker'] ||= {}
  Settings.cron_jobs['elastic_remove_expired_namespace_subscriptions_from_index_cron_worker']['cron'] ||= '10 3 * * *'
  Settings.cron_jobs['elastic_remove_expired_namespace_subscriptions_from_index_cron_worker']['job_class'] ||= 'ElasticRemoveExpiredNamespaceSubscriptionsFromIndexCronWorker'
  Settings.cron_jobs['elastic_migration_worker'] ||= {}
  Settings.cron_jobs['elastic_migration_worker']['cron'] ||= '*/5 * * * *'
  Settings.cron_jobs['elastic_migration_worker']['job_class'] ||= 'Elastic::MigrationWorker'
  Settings.cron_jobs['search_zoekt_scheduling_worker'] ||= {}
  Settings.cron_jobs['search_zoekt_scheduling_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['search_zoekt_scheduling_worker']['job_class'] ||= 'Search::Zoekt::SchedulingWorker'
  Settings.cron_jobs['search_elastic_metrics_update_cron_worker'] ||= {}
  Settings.cron_jobs['search_elastic_metrics_update_cron_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['search_elastic_metrics_update_cron_worker']['job_class'] ||= 'Search::Elastic::MetricsUpdateCronWorker'
  Settings.cron_jobs['search_zoekt_metrics_update_cron_worker'] ||= {}
  Settings.cron_jobs['search_zoekt_metrics_update_cron_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['search_zoekt_metrics_update_cron_worker']['job_class'] ||= 'Search::Zoekt::MetricsUpdateCronWorker'
  Settings.cron_jobs['pause_control_resume_worker'] ||= {}
  Settings.cron_jobs['pause_control_resume_worker']['cron'] ||= '*/5 * * * *'
  Settings.cron_jobs['pause_control_resume_worker']['job_class'] ||= 'PauseControl::ResumeWorker'
  Settings.cron_jobs['concurrency_limit_resume_worker'] ||= {}
  Settings.cron_jobs['concurrency_limit_resume_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['concurrency_limit_resume_worker']['job_class'] ||= 'ConcurrencyLimit::ResumeWorker'
  Settings.cron_jobs['sync_seat_link_worker'] ||= {}
  Settings.cron_jobs['sync_seat_link_worker']['cron'] ||= "#{rand(60)} #{rand(3..4)} * * * UTC"
  Settings.cron_jobs['sync_seat_link_worker']['job_class'] = 'SyncSeatLinkWorker'
  Settings.cron_jobs['sync_service_token_worker'] ||= {}
  Settings.cron_jobs['sync_service_token_worker']['cron'] ||= "#{rand(60)} #{rand(5..6)} * * * UTC"
  Settings.cron_jobs['sync_service_token_worker']['job_class'] = '::CloudConnector::SyncServiceTokenWorker'
  Settings.cron_jobs['users_create_statistics_worker'] ||= {}
  Settings.cron_jobs['users_create_statistics_worker']['cron'] ||= '2 15 * * *'
  Settings.cron_jobs['users_create_statistics_worker']['job_class'] = 'Users::CreateStatisticsWorker'
  Settings.cron_jobs['iterations_update_status_worker'] ||= {}
  Settings.cron_jobs['iterations_update_status_worker']['cron'] ||= '5 0 * * *'
  Settings.cron_jobs['iterations_update_status_worker']['job_class'] = 'IterationsUpdateStatusWorker'
  Settings.cron_jobs['iterations_generator_worker'] ||= {}
  Settings.cron_jobs['iterations_generator_worker']['cron'] ||= '5 0 * * *'
  Settings.cron_jobs['iterations_generator_worker']['job_class'] = 'Iterations::Cadences::ScheduleCreateIterationsWorker'
  Settings.cron_jobs['vulnerability_statistics_schedule_worker'] ||= {}
  Settings.cron_jobs['vulnerability_statistics_schedule_worker']['cron'] ||= '15 1,20 * * *'
  Settings.cron_jobs['vulnerability_statistics_schedule_worker']['job_class'] = 'Vulnerabilities::Statistics::ScheduleWorker'
  Settings.cron_jobs['vulnerability_historical_statistics_deletion_worker'] ||= {}
  Settings.cron_jobs['vulnerability_historical_statistics_deletion_worker']['cron'] ||= '15 3 * * *'
  Settings.cron_jobs['vulnerability_historical_statistics_deletion_worker']['job_class'] = 'Vulnerabilities::HistoricalStatistics::DeletionWorker'
  Settings.cron_jobs['vulnerability_orphaned_remediations_cleanup_worker'] ||= {}
  Settings.cron_jobs['vulnerability_orphaned_remediations_cleanup_worker']['job_class'] = 'Vulnerabilities::OrphanedRemediationsCleanupWorker'
  Settings.cron_jobs['vulnerability_orphaned_remediations_cleanup_worker']['cron'] ||= '15 3 * * */6'
  Settings.cron_jobs['security_create_orchestration_policy_worker'] ||= {}
  Settings.cron_jobs['security_create_orchestration_policy_worker']['cron'] ||= '*/10 * * * *'
  Settings.cron_jobs['security_create_orchestration_policy_worker']['job_class'] = 'Security::CreateOrchestrationPolicyWorker'
  Settings.cron_jobs['security_orchestration_policy_rule_schedule_worker'] ||= {}
  Settings.cron_jobs['security_orchestration_policy_rule_schedule_worker']['cron'] ||= '*/15 * * * *'
  Settings.cron_jobs['security_orchestration_policy_rule_schedule_worker']['job_class'] = 'Security::OrchestrationPolicyRuleScheduleWorker'
  Settings.cron_jobs['security_pipeline_execution_policies_schedule_worker'] ||= {}
  Settings.cron_jobs['security_pipeline_execution_policies_schedule_worker']['cron'] ||= '* * * * *'
  Settings.cron_jobs['security_pipeline_execution_policies_schedule_worker']['job_class'] = 'Security::PipelineExecutionPolicies::ScheduleWorker'
  Settings.cron_jobs['security_scans_purge_worker'] ||= {}
  Settings.cron_jobs['security_scans_purge_worker']['cron'] ||= '0 */4 * * 6,0'
  Settings.cron_jobs['security_scans_purge_worker']['job_class'] = 'Security::Scans::PurgeWorker'
  Settings.cron_jobs['app_sec_dast_profile_schedule_worker'] ||= {}
  Settings.cron_jobs['app_sec_dast_profile_schedule_worker']['cron'] ||= '7-59/15 * * * *'
  Settings.cron_jobs['app_sec_dast_profile_schedule_worker']['job_class'] = 'AppSec::Dast::ProfileScheduleWorker'
  Settings.cron_jobs['ci_namespace_mirrors_consistency_check_worker'] ||= {}
  Settings.cron_jobs['ci_namespace_mirrors_consistency_check_worker']['cron'] ||= '*/4 * * * *'
  Settings.cron_jobs['ci_namespace_mirrors_consistency_check_worker']['job_class'] = 'Database::CiNamespaceMirrorsConsistencyCheckWorker'
  Settings.cron_jobs['ci_project_mirrors_consistency_check_worker'] ||= {}
  Settings.cron_jobs['ci_project_mirrors_consistency_check_worker']['cron'] ||= '2-58/4 * * * *'
  Settings.cron_jobs['ci_project_mirrors_consistency_check_worker']['job_class'] = 'Database::CiProjectMirrorsConsistencyCheckWorker'
  Settings.cron_jobs['arkose_blocked_users_report_worker'] ||= {}
  Settings.cron_jobs['arkose_blocked_users_report_worker']['cron'] ||= '0 6 * * *'
  Settings.cron_jobs['arkose_blocked_users_report_worker']['job_class'] = 'Arkose::BlockedUsersReportWorker'
  Settings.cron_jobs['ci_runners_stale_group_runners_prune_worker_cron'] ||= {}
  Settings.cron_jobs['ci_runners_stale_group_runners_prune_worker_cron']['cron'] ||= '30 * * * *'
  Settings.cron_jobs['ci_runners_stale_group_runners_prune_worker_cron']['job_class'] = 'Ci::Runners::StaleGroupRunnersPruneCronWorker'
  Settings.cron_jobs['licenses_reset_submit_license_usage_data_banner'] ||= {}
  Settings.cron_jobs['licenses_reset_submit_license_usage_data_banner']['cron'] ||= "0 0 * * *"
  Settings.cron_jobs['licenses_reset_submit_license_usage_data_banner']['job_class'] = 'Licenses::ResetSubmitLicenseUsageDataBannerWorker'
  Settings.cron_jobs['package_metadata_licenses_sync_worker'] ||= {}
  Settings.cron_jobs['package_metadata_licenses_sync_worker']['cron'] ||= "*/5 * * * *"
  Settings.cron_jobs['package_metadata_licenses_sync_worker']['job_class'] = 'PackageMetadata::LicensesSyncWorker'
  Settings.cron_jobs['compliance_violations_consistency_worker'] ||= {}
  Settings.cron_jobs['compliance_violations_consistency_worker']['cron'] ||= '0 1 * * *'
  Settings.cron_jobs['compliance_violations_consistency_worker']['job_class'] = 'ComplianceManagement::MergeRequests::ComplianceViolationsConsistencyWorker'
  Settings.cron_jobs['users_delete_unconfirmed_users_worker'] ||= {}
  Settings.cron_jobs['users_delete_unconfirmed_users_worker']['cron'] ||= '0 * * * *'
  Settings.cron_jobs['users_delete_unconfirmed_users_worker']['job_class'] = 'Users::UnconfirmedUsersDeletionCronWorker'
  Settings.cron_jobs['users_unconfirmed_secondary_emails_deletion_cron_worker'] ||= {}
  Settings.cron_jobs['users_unconfirmed_secondary_emails_deletion_cron_worker']['cron'] ||= '0 * * * *'
  Settings.cron_jobs['users_unconfirmed_secondary_emails_deletion_cron_worker']['job_class'] = 'Users::UnconfirmedSecondaryEmailsDeletionCronWorker'
  Settings.cron_jobs['package_metadata_advisories_sync_worker'] ||= {}
  Settings.cron_jobs['package_metadata_advisories_sync_worker']['cron'] ||= "*/5 * * * *"
  Settings.cron_jobs['package_metadata_advisories_sync_worker']['job_class'] = 'PackageMetadata::AdvisoriesSyncWorker'
  Settings.cron_jobs['okr_checkin_reminder_emails'] ||= {}
  Settings.cron_jobs['okr_checkin_reminder_emails']['cron'] ||= "0 1 * * *"
  Settings.cron_jobs['okr_checkin_reminder_emails']['job_class'] = 'Okrs::CheckinReminderEmailsCronWorker'
  Settings.cron_jobs['timeout_pending_status_check_responses_worker'] ||= {}
  Settings.cron_jobs['timeout_pending_status_check_responses_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['timeout_pending_status_check_responses_worker']['job_class'] = 'ComplianceManagement::TimeoutPendingStatusCheckResponsesWorker'
  Settings.cron_jobs['click_house_ci_finished_builds_sync_worker'] ||= {}
  Settings.cron_jobs['click_house_ci_finished_builds_sync_worker']['cron'] ||= '*/3 * * * *'
  Settings.cron_jobs['click_house_ci_finished_builds_sync_worker']['args'] ||= [1]
  Settings.cron_jobs['click_house_ci_finished_builds_sync_worker']['job_class'] = 'ClickHouse::CiFinishedBuildsSyncCronWorker'
  Settings.cron_jobs['click_house_events_sync_worker'] ||= {}
  Settings.cron_jobs['click_house_events_sync_worker']['cron'] ||= "*/3 * * * *"
  Settings.cron_jobs['click_house_events_sync_worker']['job_class'] = 'ClickHouse::EventsSyncWorker'
  Settings.cron_jobs['click_house_user_add_on_assignments_sync_worker'] ||= {}
  Settings.cron_jobs['click_house_user_add_on_assignments_sync_worker']['cron'] = "*/3 * * * *"
  Settings.cron_jobs['click_house_user_add_on_assignments_sync_worker']['job_class'] = 'ClickHouse::UserAddOnAssignmentsSyncWorker'
  Settings.cron_jobs['click_house_event_authors_consistency_cron_worker'] ||= {}
  Settings.cron_jobs['click_house_event_authors_consistency_cron_worker']['cron'] ||= "*/30 * * * *"
  Settings.cron_jobs['click_house_event_authors_consistency_cron_worker']['job_class'] = 'ClickHouse::EventAuthorsConsistencyCronWorker'
  Settings.cron_jobs['click_house_event_namespace_paths_consistency_cron_worker'] ||= {}
  Settings.cron_jobs['click_house_event_namespace_paths_consistency_cron_worker']['cron'] ||= "*/45 * * * *"
  Settings.cron_jobs['click_house_event_namespace_paths_consistency_cron_worker']['job_class'] = 'ClickHouse::EventPathsConsistencyCronWorker'
  Settings.cron_jobs['click_house_rebuild_materialized_view_cron_worker'] ||= {}
  Settings.cron_jobs['click_house_rebuild_materialized_view_cron_worker']['cron'] ||= "*/10 * * * *"
  Settings.cron_jobs['click_house_rebuild_materialized_view_cron_worker']['job_class'] = 'ClickHouse::RebuildMaterializedViewCronWorker'
  Settings.cron_jobs['click_house_dump_all_write_buffers_cron_worker'] ||= {}
  Settings.cron_jobs['click_house_dump_all_write_buffers_cron_worker']['cron'] ||= "*/5 * * * *"
  Settings.cron_jobs['click_house_dump_all_write_buffers_cron_worker']['job_class'] = 'ClickHouse::DumpAllWriteBuffersCronWorker'
  Settings.cron_jobs['gitlab_subscriptions_add_on_purchases_schedule_bulk_refresh_user_assignments_worker'] ||= {}
  Settings.cron_jobs['gitlab_subscriptions_add_on_purchases_schedule_bulk_refresh_user_assignments_worker']['cron'] ||= "0 */4 * * *"
  Settings.cron_jobs['gitlab_subscriptions_add_on_purchases_schedule_bulk_refresh_user_assignments_worker']['job_class'] = 'GitlabSubscriptions::AddOnPurchases::ScheduleBulkRefreshUserAssignmentsWorker'
  Settings.cron_jobs['gitlab_subscriptions_add_on_purchases_cleanup_worker'] ||= {}
  Settings.cron_jobs['gitlab_subscriptions_add_on_purchases_cleanup_worker']['cron'] ||= '0 1 * * *'
  Settings.cron_jobs['gitlab_subscriptions_add_on_purchases_cleanup_worker']['job_class'] = 'GitlabSubscriptions::AddOnPurchases::CleanupWorker'
  Settings.cron_jobs['gitlab_subscriptions_offline_cloud_license_provision_worker'] ||= {}
  Settings.cron_jobs['gitlab_subscriptions_offline_cloud_license_provision_worker']['cron'] ||= '30 0 * * *'
  Settings.cron_jobs['gitlab_subscriptions_offline_cloud_license_provision_worker']['job_class'] = 'GitlabSubscriptions::AddOnPurchases::OfflineCloudLicenseProvisionWorker'
  Settings.cron_jobs['observability_alert_query_worker'] ||= {}
  Settings.cron_jobs['observability_alert_query_worker']['cron'] ||= '* * * * *'
  Settings.cron_jobs['observability_alert_query_worker']['job_class'] = 'Observability::AlertQueryWorker'
  Settings.cron_jobs['report_security_policies_metrics_worker.rb'] ||= {}
  Settings.cron_jobs['report_security_policies_metrics_worker.rb']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['report_security_policies_metrics_worker.rb']['job_class'] = 'Security::Policies::ReportSecurityPoliciesMetricsWorker'
  Settings.cron_jobs['usage_events_dump_write_buffer_cron_worker'] ||= {}
  Settings.cron_jobs['usage_events_dump_write_buffer_cron_worker']['cron'] ||= "*/5 * * * *"
  Settings.cron_jobs['usage_events_dump_write_buffer_cron_worker']['job_class'] = 'UsageEvents::DumpWriteBufferCronWorker'
  Settings.cron_jobs['package_metadata_cve_enrichment_sync_worker'] ||= {}
  Settings.cron_jobs['package_metadata_cve_enrichment_sync_worker']['cron'] ||= "0 */1 * * *"
  Settings.cron_jobs['package_metadata_cve_enrichment_sync_worker']['job_class'] = 'PackageMetadata::CveEnrichmentSyncWorker'
  Settings.cron_jobs['members_schedule_prune_deletions_worker'] ||= {}
  Settings.cron_jobs['members_schedule_prune_deletions_worker']['cron'] ||= "*/5 * * * *"
  Settings.cron_jobs['members_schedule_prune_deletions_worker']['job_class'] = 'Members::SchedulePruneDeletionsWorker'
  Settings.cron_jobs['ai_conversation_cleanup_cron_worker'] ||= {}
  Settings.cron_jobs['ai_conversation_cleanup_cron_worker']['cron'] ||= '30 2 * * *'
  Settings.cron_jobs['ai_conversation_cleanup_cron_worker']['job_class'] = 'Ai::Conversation::CleanupCronWorker'
  Settings.cron_jobs['ai_active_context_bulk_process_worker'] ||= {}
  Settings.cron_jobs['ai_active_context_bulk_process_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['ai_active_context_bulk_process_worker']['job_class'] ||= 'Ai::ActiveContext::BulkProcessWorker'
  Settings.cron_jobs['namespaces_enable_descendants_cache_cron_worker'] ||= {}
  Settings.cron_jobs['namespaces_enable_descendants_cache_cron_worker']['cron'] ||= '*/11 * * * *'
  Settings.cron_jobs['namespaces_enable_descendants_cache_cron_worker']['job_class'] = 'Namespaces::EnableDescendantsCacheCronWorker'
  Settings.cron_jobs['delete_expired_dependency_exports_worker'] ||= {}
  Settings.cron_jobs['delete_expired_dependency_exports_worker']['cron'] ||= '0 4 * * *'
  Settings.cron_jobs['delete_expired_dependency_exports_worker']['job_class'] = 'Sbom::DeleteExpiredExportsWorker'
  Settings.cron_jobs['analytics_dump_ai_user_metrics_database_write_buffer_cron_worker'] ||= {}
  Settings.cron_jobs['analytics_dump_ai_user_metrics_database_write_buffer_cron_worker']['cron'] ||= "*/10 * * * *"
  Settings.cron_jobs['analytics_dump_ai_user_metrics_database_write_buffer_cron_worker']['job_class'] = 'Analytics::DumpAiUserMetricsWriteBufferCronWorker'

  Gitlab.com do
    Settings.cron_jobs['disable_legacy_open_source_license_for_inactive_projects'] ||= {}
    Settings.cron_jobs['disable_legacy_open_source_license_for_inactive_projects']['cron'] ||= "30 5 * * 0"
    Settings.cron_jobs['disable_legacy_open_source_license_for_inactive_projects']['job_class'] = 'Projects::DisableLegacyOpenSourceLicenseForInactiveProjectsWorker'
    Settings.cron_jobs['notify_seats_exceeded_batch_worker'] ||= {}
    Settings.cron_jobs['notify_seats_exceeded_batch_worker']['cron'] ||= '0 3 * * *'
    Settings.cron_jobs['notify_seats_exceeded_batch_worker']['job_class'] ||= 'GitlabSubscriptions::NotifySeatsExceededBatchWorker'
    Settings.cron_jobs['gitlab_subscriptions_schedule_refresh_seats_worker'] ||= {}
    Settings.cron_jobs['gitlab_subscriptions_schedule_refresh_seats_worker']['cron'] ||= "0 */6 * * *"
    Settings.cron_jobs['gitlab_subscriptions_schedule_refresh_seats_worker']['job_class'] = 'GitlabSubscriptions::ScheduleRefreshSeatsWorker'
    Settings.cron_jobs['namespaces_schedule_dormant_member_removal_worker'] ||= {}
    Settings.cron_jobs['namespaces_schedule_dormant_member_removal_worker']['cron'] ||= "0 */6 * * *"
    Settings.cron_jobs['namespaces_schedule_dormant_member_removal_worker']['job_class'] = 'Namespaces::ScheduleDormantMemberRemoval'
    Settings.cron_jobs['gitlab_subscriptions_offline_cloud_license_provision_worker']['status'] = 'disabled'
    Settings.cron_jobs['send_recurring_notifications_worker'] ||= {}
    Settings.cron_jobs['send_recurring_notifications_worker']['cron'] ||= '0 7 * * *'
    Settings.cron_jobs['send_recurring_notifications_worker']['job_class'] =
      'ComplianceManagement::Pipl::SendRecurringNotificationsWorker'

    Settings.cron_jobs['block_pipl_users_worker'] ||= {}
    Settings.cron_jobs['block_pipl_users_worker']['cron'] ||= '0 8 * * *'
    Settings.cron_jobs['block_pipl_users_worker']['job_class'] =
      'ComplianceManagement::Pipl::BlockPiplUsersWorker'

    Settings.cron_jobs['delete_pipl_users_worker'] ||= {}
    Settings.cron_jobs['delete_pipl_users_worker']['cron'] ||= '0 8 * * *'
    Settings.cron_jobs['delete_pipl_users_worker']['job_class'] =
      'ComplianceManagement::Pipl::DeletePiplUsersWorker'
  end

  Gitlab.jh do
    Settings.cron_jobs['gitlab_subscriptions_offline_cloud_license_provision_worker']['status'] = 'disabled'
  end
end

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
# Cells
#
Settings['cell'] ||= {}
Settings.cell['id'] ||= nil
Settings.cell['database'] ||= {}
Settings.cell.database['skip_sequence_alteration'] ||= false
# This ternary operation expression to be removed when we merge https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/4382
Settings.cell['topology_service'] ||= Settings.respond_to?(:topology_service) ? Settings.topology_service || {} : {}
Settings.cell.topology_service['enabled'] ||= false
Settings.cell.topology_service['address'] ||= 'topology-service.gitlab.example.com:443'
Settings.cell.topology_service['ca_file'] ||= '/home/git/gitlab/config/topology-service-ca.pem'
Settings.cell.topology_service['certificate_file'] ||= '/home/git/gitlab/config/topology-service-cert.pem'
Settings.cell.topology_service['private_key_file'] ||= '/home/git/gitlab/config/topology-service-key.pem'

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
# Suggested Reviewers
#
Gitlab.ee do
  Settings['suggested_reviewers'] ||= {}
  Settings.suggested_reviewers['secret_file'] ||= Rails.root.join('.gitlab_suggested_reviewers_secret')
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
  Settings.duo_workflow.reverse_merge!(
    secure: true,
    executor_binary_url: "https://gitlab.com/api/v4/projects/58711783/packages/generic/duo-workflow-executor/#{executor_version}/duo-workflow-executor.tar.gz",
    executor_version: executor_version
  )

  # Default to proxy via Cloud Connector
  unless Settings.duo_workflow['service_url'].present?
    cloud_connector_uri = URI.parse(Settings.cloud_connector.base_url)

    # Cloudflare has been disabled untill
    # gets resolved https://gitlab.com/gitlab-org/gitlab/-/issues/509586
    # Settings.duo_workflow['service_url'] = "#{cloud_connector_uri.host}:#{cloud_connector_uri.port}"

    service_url = "duo-workflow#{cloud_connector_uri.host.include?('staging') ? '.staging' : ''}.runway.gitlab.net:#{cloud_connector_uri.port}"
    Settings.duo_workflow['service_url'] = service_url
    Settings.duo_workflow['secure'] = cloud_connector_uri.scheme == 'https'
  end
end

#
# Zoekt credentials
#
Gitlab.ee do
  Settings['zoekt'] ||= {}
  Settings.zoekt['username_file'] ||= Rails.root.join('.gitlab_zoekt_username')
  Settings.zoekt['password_file'] ||= Rails.root.join('.gitlab_zoekt_password')
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
Settings.bullet['enabled'] ||= Rails.env.development?

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
