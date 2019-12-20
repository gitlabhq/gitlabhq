require_relative '../settings'
require_relative '../object_store_settings'
require_relative '../smime_signature_settings'

# Default settings
Settings['ldap'] ||= Settingslogic.new({})
Settings.ldap['enabled'] = false if Settings.ldap['enabled'].nil?
Settings.ldap['prevent_ldap_sign_in'] = false if Settings.ldap['prevent_ldap_sign_in'].blank?

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
    server = Settingslogic.new(server)

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

    if server['ssl_version'] || server['ca_file']
      Rails.logger.warn 'DEPRECATED: LDAP options `ssl_version` and `ca_file` should be nested within `tls_options`' # rubocop:disable Gitlab/RailsLogger
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

Gitlab.ee do
  Settings['smartcard'] ||= Settingslogic.new({})
  Settings.smartcard['enabled'] = false if Settings.smartcard['enabled'].nil?
  Settings.smartcard['client_certificate_required_port'] = 3444 if Settings.smartcard['client_certificate_required_port'].nil?
  Settings.smartcard['required_for_git_access'] = false if Settings.smartcard['required_for_git_access'].nil?
  Settings.smartcard['san_extensions'] = false if Settings.smartcard['san_extensions'].nil?
end

Settings['omniauth'] ||= Settingslogic.new({})
Settings.omniauth['enabled'] = true if Settings.omniauth['enabled'].nil?
Settings.omniauth['auto_sign_in_with_provider'] = false if Settings.omniauth['auto_sign_in_with_provider'].nil?
Settings.omniauth['allow_single_sign_on'] = false if Settings.omniauth['allow_single_sign_on'].nil?
Settings.omniauth['allow_bypass_two_factor'] = false if Settings.omniauth['allow_bypass_two_factor'].nil?
Settings.omniauth['external_providers'] = [] if Settings.omniauth['external_providers'].nil?
Settings.omniauth['block_auto_created_users'] = true if Settings.omniauth['block_auto_created_users'].nil?
Settings.omniauth['auto_link_ldap_user'] = false if Settings.omniauth['auto_link_ldap_user'].nil?
Settings.omniauth['auto_link_saml_user'] = false if Settings.omniauth['auto_link_saml_user'].nil?

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
Settings.omniauth['cas3'] ||= Settingslogic.new({})
Settings.omniauth.cas3['session_duration'] ||= 8.hours
Settings.omniauth['session_tickets'] ||= Settingslogic.new({})
Settings.omniauth.session_tickets['cas3'] = 'ticket'

# Fill out omniauth-gitlab settings. It is needed for easy set up GHE or GH by just specifying url.

github_default_url = "https://github.com"
github_settings = Settings.omniauth['providers'].find { |provider| provider["name"] == "github" }

if github_settings
  # For compatibility with old config files (before 7.8)
  # where people dont have url in github settings
  if github_settings['url'].blank?
    github_settings['url'] = github_default_url
  end

  github_settings["args"] ||= Settingslogic.new({})

  github_settings["args"]["client_options"] =
    if github_settings["url"].include?(github_default_url)
      OmniAuth::Strategies::GitHub.default_options[:client_options]
    else
      {
        "site"          => File.join(github_settings["url"], "api/v3"),
        "authorize_url" => File.join(github_settings["url"], "login/oauth/authorize"),
        "token_url"     => File.join(github_settings["url"], "login/oauth/access_token")
      }
    end
end

# SAML should be enabled for the tests automatically, but only for EE.
saml_provider_enabled = Settings.omniauth.providers.any? do |provider|
  provider['name'] == 'group_saml'
end

if Gitlab.ee? && Rails.env.test? && !saml_provider_enabled
  Settings.omniauth.providers << Settingslogic.new({ 'name' => 'group_saml' })
end

Settings['shared'] ||= Settingslogic.new({})
Settings.shared['path'] = Settings.absolute(Settings.shared['path'] || "shared")

Settings['issues_tracker'] ||= {}

#
# GitLab
#
Settings['gitlab'] ||= Settingslogic.new({})
Settings.gitlab['default_project_creation'] ||= ::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS
Settings.gitlab['default_project_deletion_protection'] ||= false
Settings.gitlab['default_projects_limit'] ||= 100000
Settings.gitlab['default_branch_protection'] ||= 2
Settings.gitlab['default_can_create_group'] = true if Settings.gitlab['default_can_create_group'].nil?
Settings.gitlab['default_theme'] = Gitlab::Themes::APPLICATION_DEFAULT if Settings.gitlab['default_theme'].nil?
Settings.gitlab['host']       ||= ENV['GITLAB_HOST'] || 'localhost'
Settings.gitlab['ssh_host']   ||= Settings.gitlab.host
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
Settings.gitlab['base_url']   ||= Settings.__send__(:build_base_gitlab_url)
Settings.gitlab['url']        ||= Settings.__send__(:build_gitlab_url)
Settings.gitlab['user']       ||= 'git'
Settings.gitlab['user_home']  ||= begin
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
Settings.gitlab['max_attachment_size'] ||= 10
Settings.gitlab['session_expire_delay'] ||= 10080
Settings.gitlab['unauthenticated_session_expire_delay'] ||= 2.hours.to_i
Settings.gitlab.default_projects_features['issues']             = true if Settings.gitlab.default_projects_features['issues'].nil?
Settings.gitlab.default_projects_features['merge_requests']     = true if Settings.gitlab.default_projects_features['merge_requests'].nil?
Settings.gitlab.default_projects_features['wiki']               = true if Settings.gitlab.default_projects_features['wiki'].nil?
Settings.gitlab.default_projects_features['snippets']           = true if Settings.gitlab.default_projects_features['snippets'].nil?
Settings.gitlab.default_projects_features['builds']             = true if Settings.gitlab.default_projects_features['builds'].nil?
Settings.gitlab.default_projects_features['container_registry'] = true if Settings.gitlab.default_projects_features['container_registry'].nil?
Settings.gitlab.default_projects_features['visibility_level']   = Settings.__send__(:verify_constant, Gitlab::VisibilityLevel, Settings.gitlab.default_projects_features['visibility_level'], Gitlab::VisibilityLevel::PRIVATE)
Settings.gitlab['domain_whitelist'] ||= []
Settings.gitlab['import_sources'] ||= Gitlab::ImportSources.values
Settings.gitlab['trusted_proxies'] ||= []
Settings.gitlab['content_security_policy'] ||= Gitlab::ContentSecurityPolicy::ConfigLoader.default_settings_hash
Settings.gitlab['no_todos_messages'] ||= YAML.load_file(Rails.root.join('config', 'no_todos_messages.yml'))
Settings.gitlab['impersonation_enabled'] ||= true if Settings.gitlab['impersonation_enabled'].nil?
Settings.gitlab['usage_ping_enabled'] = true if Settings.gitlab['usage_ping_enabled'].nil?

Gitlab.ee do
  Settings.gitlab['mirror_max_delay'] ||= 300
  Settings.gitlab['mirror_max_capacity'] ||= 30
  Settings.gitlab['mirror_capacity_threshold'] ||= 15
end

#
# Elasticseacrh
#
Gitlab.ee do
  Settings['elasticsearch'] ||= Settingslogic.new({})
  Settings.elasticsearch['enabled'] = false if Settings.elasticsearch['enabled'].nil?
  Settings.elasticsearch['url'] = ENV['ELASTIC_URL'] || "http://localhost:9200"
  Settings.elasticsearch['indexer_path'] ||= Gitlab::Utils.which('gitlab-elasticsearch-indexer')
end

#
# CI
#
Settings['gitlab_ci'] ||= Settingslogic.new({})
Settings.gitlab_ci['shared_runners_enabled'] = true if Settings.gitlab_ci['shared_runners_enabled'].nil?
Settings.gitlab_ci['all_broken_builds']     = true if Settings.gitlab_ci['all_broken_builds'].nil?
Settings.gitlab_ci['add_pusher']            = false if Settings.gitlab_ci['add_pusher'].nil?
Settings.gitlab_ci['builds_path']           = Settings.absolute(Settings.gitlab_ci['builds_path'] || "builds/")
Settings.gitlab_ci['url']                 ||= Settings.__send__(:build_gitlab_ci_url)

#
# Reply by email
#
Settings['incoming_email'] ||= Settingslogic.new({})
Settings.incoming_email['enabled'] = false if Settings.incoming_email['enabled'].nil?

#
# Build Artifacts
#
Settings['artifacts'] ||= Settingslogic.new({})
Settings.artifacts['enabled']      = true if Settings.artifacts['enabled'].nil?
Settings.artifacts['storage_path'] = Settings.absolute(Settings.artifacts.values_at('path', 'storage_path').compact.first || File.join(Settings.shared['path'], "artifacts"))
# Settings.artifact['path'] is deprecated, use `storage_path` instead
Settings.artifacts['path']         = Settings.artifacts['storage_path']
Settings.artifacts['max_size'] ||= 100 # in megabytes
Settings.artifacts['object_store'] = ObjectStoreSettings.parse(Settings.artifacts['object_store'])

#
# Registry
#
Settings['registry'] ||= Settingslogic.new({})
Settings.registry['enabled']       ||= false
Settings.registry['host']          ||= "example.com"
Settings.registry['port']          ||= nil
Settings.registry['api_url']       ||= "http://localhost:5000/"
Settings.registry['key']           ||= nil
Settings.registry['issuer']        ||= nil
Settings.registry['host_port']     ||= [Settings.registry['host'], Settings.registry['port']].compact.join(':')
Settings.registry['path']            = Settings.absolute(Settings.registry['path'] || File.join(Settings.shared['path'], 'registry'))
Settings.registry['notifications'] ||= []

#
# Error Reporting and Logging with Sentry
#
Settings['sentry'] ||= Settingslogic.new({})
Settings.sentry['enabled'] ||= false
Settings.sentry['dsn'] ||= nil
Settings.sentry['environment'] ||= nil
Settings.sentry['clientside_dsn'] ||= nil

#
# Pages
#
Settings['pages'] ||= Settingslogic.new({})
Settings.pages['enabled']           = false if Settings.pages['enabled'].nil?
Settings.pages['access_control']    = false if Settings.pages['access_control'].nil?
Settings.pages['path']              = Settings.absolute(Settings.pages['path'] || File.join(Settings.shared['path'], "pages"))
Settings.pages['https']             = false if Settings.pages['https'].nil?
Settings.pages['host']              ||= "example.com"
Settings.pages['port']              ||= Settings.pages.https ? 443 : 80
Settings.pages['protocol']          ||= Settings.pages.https ? "https" : "http"
Settings.pages['url']               ||= Settings.__send__(:build_pages_url)
Settings.pages['external_http']     ||= false unless Settings.pages['external_http'].present?
Settings.pages['external_https']    ||= false unless Settings.pages['external_https'].present?
Settings.pages['artifacts_server']  ||= Settings.pages['enabled'] if Settings.pages['artifacts_server'].nil?
Settings.pages['secret_file'] ||= Rails.root.join('.gitlab_pages_secret')

#
# Geo
#
Gitlab.ee do
  Settings['geo'] ||= Settingslogic.new({})
  # For backwards compatibility, default to gitlab_url and if so, ensure it ends with "/"
  Settings.geo['node_name'] = Settings.geo['node_name'].presence || Settings.gitlab['url'].chomp('/').concat('/')

  #
  # Registry replication
  #
  Settings.geo['registry_replication'] ||= Settingslogic.new({})
  Settings.geo.registry_replication['enabled'] ||= false
end

#
# Unleash
#
Settings['feature_flags'] ||= Settingslogic.new({})
Settings.feature_flags['unleash'] ||= Settingslogic.new({})
Settings.feature_flags.unleash['enabled'] = false if Settings.feature_flags.unleash['enabled'].nil?

#
# External merge request diffs
#
Settings['external_diffs'] ||= Settingslogic.new({})
Settings.external_diffs['enabled']      = false if Settings.external_diffs['enabled'].nil?
Settings.external_diffs['when']         = 'always' if Settings.external_diffs['when'].nil?
Settings.external_diffs['storage_path'] = Settings.absolute(Settings.external_diffs['storage_path'] || File.join(Settings.shared['path'], 'external-diffs'))
Settings.external_diffs['object_store'] = ObjectStoreSettings.parse(Settings.external_diffs['object_store'])

#
# Git LFS
#
Settings['lfs'] ||= Settingslogic.new({})
Settings.lfs['enabled']      = true if Settings.lfs['enabled'].nil?
Settings.lfs['storage_path'] = Settings.absolute(Settings.lfs['storage_path'] || File.join(Settings.shared['path'], "lfs-objects"))
Settings.lfs['object_store'] = ObjectStoreSettings.parse(Settings.lfs['object_store'])

#
# Uploads
#
Settings['uploads'] ||= Settingslogic.new({})
Settings.uploads['storage_path'] = Settings.absolute(Settings.uploads['storage_path'] || 'public')
Settings.uploads['base_dir'] = Settings.uploads['base_dir'] || 'uploads/-/system'
Settings.uploads['object_store'] = ObjectStoreSettings.parse(Settings.uploads['object_store'])
Settings.uploads['object_store']['remote_directory'] ||= 'uploads'

#
# Packages
#
Gitlab.ee do
  Settings['packages'] ||= Settingslogic.new({})
  Settings.packages['enabled']      = true if Settings.packages['enabled'].nil?
  Settings.packages['storage_path'] = Settings.absolute(Settings.packages['storage_path'] || File.join(Settings.shared['path'], "packages"))
  Settings.packages['object_store'] = ObjectStoreSettings.parse(Settings.packages['object_store'])
end

#
# Dependency Proxy
#
Gitlab.ee do
  Settings['dependency_proxy'] ||= Settingslogic.new({})
  Settings.dependency_proxy['enabled']      = true if Settings.dependency_proxy['enabled'].nil?
  Settings.dependency_proxy['storage_path'] = Settings.absolute(Settings.dependency_proxy['storage_path'] || File.join(Settings.shared['path'], "dependency_proxy"))
  Settings.dependency_proxy['object_store'] = ObjectStoreSettings.parse(Settings.dependency_proxy['object_store'])

  # For first iteration dependency proxy uses Rails server to download blobs.
  # To ensure acceptable performance we only allow feature to be used with
  # multithreaded web-server Puma. This will be removed once download logic is moved
  # to GitLab workhorse
  Settings.dependency_proxy['enabled'] = false unless defined?(::Puma)
end

#
# Mattermost
#
Settings['mattermost'] ||= Settingslogic.new({})
Settings.mattermost['enabled'] = false if Settings.mattermost['enabled'].nil?
Settings.mattermost['host'] = nil unless Settings.mattermost.enabled

#
# Gravatar
#
Settings['gravatar'] ||= Settingslogic.new({})
Settings.gravatar['enabled']      = true if Settings.gravatar['enabled'].nil?
Settings.gravatar['plain_url']  ||= 'https://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon'
Settings.gravatar['ssl_url']    ||= 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon'
Settings.gravatar['host']         = Settings.host_without_www(Settings.gravatar['plain_url'])

#
# Cron Jobs
#
Settings['cron_jobs'] ||= Settingslogic.new({})

if Gitlab.ee? && Settings['ee_cron_jobs']
  Settings.cron_jobs.merge!(Settings.ee_cron_jobs)
end

Settings.cron_jobs['stuck_ci_jobs_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['stuck_ci_jobs_worker']['cron'] ||= '0 * * * *'
Settings.cron_jobs['stuck_ci_jobs_worker']['job_class'] = 'StuckCiJobsWorker'
Settings.cron_jobs['pipeline_schedule_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['pipeline_schedule_worker']['cron'] ||= '19 * * * *'
Settings.cron_jobs['pipeline_schedule_worker']['job_class'] = 'PipelineScheduleWorker'
Settings.cron_jobs['expire_build_artifacts_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['expire_build_artifacts_worker']['cron'] ||= '50 * * * *'
Settings.cron_jobs['expire_build_artifacts_worker']['job_class'] = 'ExpireBuildArtifactsWorker'
Settings.cron_jobs['repository_check_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['repository_check_worker']['cron'] ||= '20 * * * *'
Settings.cron_jobs['repository_check_worker']['job_class'] = 'RepositoryCheck::DispatchWorker'
Settings.cron_jobs['admin_email_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['admin_email_worker']['cron'] ||= '0 0 * * 0'
Settings.cron_jobs['admin_email_worker']['job_class'] = 'AdminEmailWorker'
Settings.cron_jobs['personal_access_tokens_expiring_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['personal_access_tokens_expiring_worker']['cron'] ||= '0 1 * * *'
Settings.cron_jobs['personal_access_tokens_expiring_worker']['job_class'] = 'PersonalAccessTokens::ExpiringWorker'
Settings.cron_jobs['repository_archive_cache_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['repository_archive_cache_worker']['cron'] ||= '0 * * * *'
Settings.cron_jobs['repository_archive_cache_worker']['job_class'] = 'RepositoryArchiveCacheWorker'
Settings.cron_jobs['import_export_project_cleanup_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['import_export_project_cleanup_worker']['cron'] ||= '0 * * * *'
Settings.cron_jobs['import_export_project_cleanup_worker']['job_class'] = 'ImportExportProjectCleanupWorker'
Settings.cron_jobs['ci_archive_traces_cron_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['ci_archive_traces_cron_worker']['cron'] ||= '17 * * * *'
Settings.cron_jobs['ci_archive_traces_cron_worker']['job_class'] = 'Ci::ArchiveTracesCronWorker'
Settings.cron_jobs['requests_profiles_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['requests_profiles_worker']['cron'] ||= '0 0 * * *'
Settings.cron_jobs['requests_profiles_worker']['job_class'] = 'RequestsProfilesWorker'
Settings.cron_jobs['remove_expired_members_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['remove_expired_members_worker']['cron'] ||= '10 0 * * *'
Settings.cron_jobs['remove_expired_members_worker']['job_class'] = 'RemoveExpiredMembersWorker'
Settings.cron_jobs['remove_expired_group_links_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['remove_expired_group_links_worker']['cron'] ||= '10 0 * * *'
Settings.cron_jobs['remove_expired_group_links_worker']['job_class'] = 'RemoveExpiredGroupLinksWorker'
Settings.cron_jobs['prune_old_events_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['prune_old_events_worker']['cron'] ||= '0 */6 * * *'
Settings.cron_jobs['prune_old_events_worker']['job_class'] = 'PruneOldEventsWorker'
Settings.cron_jobs['trending_projects_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['trending_projects_worker']['cron'] = '0 1 * * *'
Settings.cron_jobs['trending_projects_worker']['job_class'] = 'TrendingProjectsWorker'
Settings.cron_jobs['remove_unreferenced_lfs_objects_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['remove_unreferenced_lfs_objects_worker']['cron'] ||= '20 0 * * *'
Settings.cron_jobs['remove_unreferenced_lfs_objects_worker']['job_class'] = 'RemoveUnreferencedLfsObjectsWorker'
Settings.cron_jobs['stuck_import_jobs_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['stuck_import_jobs_worker']['cron'] ||= '15 * * * *'
Settings.cron_jobs['stuck_import_jobs_worker']['job_class'] = 'StuckImportJobsWorker'
Settings.cron_jobs['gitlab_usage_ping_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['gitlab_usage_ping_worker']['cron'] ||= Settings.__send__(:cron_for_usage_ping)
Settings.cron_jobs['gitlab_usage_ping_worker']['job_class'] = 'GitlabUsagePingWorker'
Settings.cron_jobs['stuck_merge_jobs_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['stuck_merge_jobs_worker']['cron'] ||= '0 */2 * * *'
Settings.cron_jobs['stuck_merge_jobs_worker']['job_class'] = 'StuckMergeJobsWorker'
Settings.cron_jobs['pages_domain_verification_cron_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['pages_domain_verification_cron_worker']['cron'] ||= '*/15 * * * *'
Settings.cron_jobs['pages_domain_verification_cron_worker']['job_class'] = 'PagesDomainVerificationCronWorker'
Settings.cron_jobs['pages_domain_removal_cron_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['pages_domain_removal_cron_worker']['cron'] ||= '47 0 * * *'
Settings.cron_jobs['pages_domain_removal_cron_worker']['job_class'] = 'PagesDomainRemovalCronWorker'
Settings.cron_jobs['pages_domain_ssl_renewal_cron_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['pages_domain_ssl_renewal_cron_worker']['cron'] ||= '*/10 * * * *'
Settings.cron_jobs['pages_domain_ssl_renewal_cron_worker']['job_class'] = 'PagesDomainSslRenewalCronWorker'
Settings.cron_jobs['issue_due_scheduler_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['issue_due_scheduler_worker']['cron'] ||= '50 00 * * *'
Settings.cron_jobs['issue_due_scheduler_worker']['job_class'] = 'IssueDueSchedulerWorker'
Settings.cron_jobs['prune_web_hook_logs_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['prune_web_hook_logs_worker']['cron'] ||= '0 */1 * * *'
Settings.cron_jobs['prune_web_hook_logs_worker']['job_class'] = 'PruneWebHookLogsWorker'
Settings.cron_jobs['schedule_migrate_external_diffs_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['schedule_migrate_external_diffs_worker']['cron'] ||= '15 * * * *'
Settings.cron_jobs['schedule_migrate_external_diffs_worker']['job_class'] = 'ScheduleMigrateExternalDiffsWorker'
Settings.cron_jobs['namespaces_prune_aggregation_schedules_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['namespaces_prune_aggregation_schedules_worker']['cron'] ||= '5 1 * * *'
Settings.cron_jobs['namespaces_prune_aggregation_schedules_worker']['job_class'] = 'Namespaces::PruneAggregationSchedulesWorker'

Gitlab.ee do
  Settings.cron_jobs['adjourned_group_deletion_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['adjourned_group_deletion_worker']['cron'] ||= '0 3 * * *'
  Settings.cron_jobs['adjourned_group_deletion_worker']['job_class'] = 'AdjournedGroupDeletionWorker'
  Settings.cron_jobs['clear_shared_runners_minutes_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['clear_shared_runners_minutes_worker']['cron'] ||= '0 0 1 * *'
  Settings.cron_jobs['clear_shared_runners_minutes_worker']['job_class'] = 'ClearSharedRunnersMinutesWorker'
  Settings.cron_jobs['adjourned_projects_deletion_cron_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['adjourned_projects_deletion_cron_worker']['cron'] ||= '0 4 * * *'
  Settings.cron_jobs['adjourned_projects_deletion_cron_worker']['job_class'] = 'AdjournedProjectsDeletionCronWorker'
  Settings.cron_jobs['geo_file_download_dispatch_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['geo_file_download_dispatch_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['geo_file_download_dispatch_worker']['job_class'] ||= 'Geo::FileDownloadDispatchWorker'
  Settings.cron_jobs['geo_metrics_update_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['geo_metrics_update_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['geo_metrics_update_worker']['job_class'] ||= 'Geo::MetricsUpdateWorker'
  Settings.cron_jobs['geo_migrated_local_files_clean_up_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['geo_migrated_local_files_clean_up_worker']['cron'] ||= '15 */6 * * *'
  Settings.cron_jobs['geo_migrated_local_files_clean_up_worker']['job_class'] ||= 'Geo::MigratedLocalFilesCleanUpWorker'
  Settings.cron_jobs['geo_prune_event_log_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['geo_prune_event_log_worker']['cron'] ||= '*/5 * * * *'
  Settings.cron_jobs['geo_prune_event_log_worker']['job_class'] ||= 'Geo::PruneEventLogWorker'
  Settings.cron_jobs['geo_repository_sync_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['geo_repository_sync_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['geo_repository_sync_worker']['job_class'] ||= 'Geo::RepositorySyncWorker'
  Settings.cron_jobs['geo_repository_verification_primary_batch_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['geo_repository_verification_primary_batch_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['geo_repository_verification_primary_batch_worker']['job_class'] ||= 'Geo::RepositoryVerification::Primary::BatchWorker'
  Settings.cron_jobs['geo_repository_verification_secondary_scheduler_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['geo_repository_verification_secondary_scheduler_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['geo_repository_verification_secondary_scheduler_worker']['job_class'] ||= 'Geo::RepositoryVerification::Secondary::SchedulerWorker'
  Settings.cron_jobs['geo_container_repository_sync_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['geo_container_repository_sync_worker']['cron'] ||= '*/1 * * * *'
  Settings.cron_jobs['geo_container_repository_sync_worker']['job_class'] ||= 'Geo::ContainerRepositorySyncDispatchWorker'
  Settings.cron_jobs['historical_data_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['historical_data_worker']['cron'] ||= '0 12 * * *'
  Settings.cron_jobs['historical_data_worker']['job_class'] = 'HistoricalDataWorker'
  Settings.cron_jobs['import_software_licenses_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['import_software_licenses_worker']['cron'] ||= '0 3 * * 0'
  Settings.cron_jobs['import_software_licenses_worker']['job_class'] = 'ImportSoftwareLicensesWorker'
  Settings.cron_jobs['ldap_group_sync_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['ldap_group_sync_worker']['cron'] ||= '0 * * * *'
  Settings.cron_jobs['ldap_group_sync_worker']['job_class'] = 'LdapAllGroupsSyncWorker'
  Settings.cron_jobs['ldap_sync_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['ldap_sync_worker']['cron'] ||= '30 1 * * *'
  Settings.cron_jobs['ldap_sync_worker']['job_class'] = 'LdapSyncWorker'
  Settings.cron_jobs['pseudonymizer_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['pseudonymizer_worker']['cron'] ||= '0 23 * * *'
  Settings.cron_jobs['pseudonymizer_worker']['job_class'] ||= 'PseudonymizerWorker'
  Settings.cron_jobs['update_max_seats_used_for_gitlab_com_subscriptions_worker'] ||= Settingslogic.new({})
  Settings.cron_jobs['update_max_seats_used_for_gitlab_com_subscriptions_worker']['cron'] ||= '0 12 * * *'
  Settings.cron_jobs['update_max_seats_used_for_gitlab_com_subscriptions_worker']['job_class'] = 'UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker'
end

#
# Sidekiq
#
Settings['sidekiq'] ||= Settingslogic.new({})
Settings['sidekiq']['log_format'] ||= 'default'

#
# GitLab Shell
#
Settings['gitlab_shell'] ||= Settingslogic.new({})
Settings.gitlab_shell['path']           = Settings.absolute(Settings.gitlab_shell['path'] || Settings.gitlab['user_home'] + '/gitlab-shell/')
Settings.gitlab_shell['hooks_path']     = :deprecated_use_gitlab_shell_path_instead
Settings.gitlab_shell['authorized_keys_file'] ||= File.join(Dir.home, '.ssh', 'authorized_keys')
Settings.gitlab_shell['secret_file'] ||= Rails.root.join('.gitlab_shell_secret')
Settings.gitlab_shell['receive_pack']   = true if Settings.gitlab_shell['receive_pack'].nil?
Settings.gitlab_shell['upload_pack']    = true if Settings.gitlab_shell['upload_pack'].nil?
Settings.gitlab_shell['ssh_host']     ||= Settings.gitlab.ssh_host
Settings.gitlab_shell['ssh_port']     ||= 22
Settings.gitlab_shell['ssh_user']     ||= Settings.gitlab.user
Settings.gitlab_shell['owner_group']  ||= Settings.gitlab.user
Settings.gitlab_shell['ssh_path_prefix'] ||= Settings.__send__(:build_gitlab_shell_ssh_path_prefix)
Settings.gitlab_shell['git_timeout'] ||= 10800

#
# Workhorse
#
Settings['workhorse'] ||= Settingslogic.new({})
Settings.workhorse['secret_file'] ||= Rails.root.join('.gitlab_workhorse_secret')

#
# Repositories
#
Settings['repositories'] ||= Settingslogic.new({})
Settings.repositories['storages'] ||= {}
unless Settings.repositories.storages['default']
  Settings.repositories.storages['default'] ||= {}
  # We set the path only if the default storage doesn't exist, in case it exists
  # but follows the pre-9.0 configuration structure. `6_validations.rb` initializer
  # will validate all storages and throw a relevant error to the user if necessary.
  Settings.repositories.storages['default']['path'] ||= Settings.gitlab['user_home'] + '/repositories/'
end

Settings.repositories.storages.each do |key, storage|
  Settings.repositories.storages[key] = Gitlab::GitalyClient::StorageSettings.new(storage)
end

#
# The repository_downloads_path is used to remove outdated repository
# archives, if someone has it configured incorrectly, and it points
# to the path where repositories are stored this can cause some
# data-integrity issue. In this case, we sets it to the default
# repository_downloads_path value.
#
repositories_storages          = Settings.repositories.storages.values
repository_downloads_path      = Settings.gitlab['repository_downloads_path'].to_s.gsub(%r{/$}, '')
repository_downloads_full_path = File.expand_path(repository_downloads_path, Settings.gitlab['user_home'])

# Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/1255
Gitlab::GitalyClient::StorageSettings.allow_disk_access do
  if repository_downloads_path.blank? || repositories_storages.any? { |rs| [repository_downloads_path, repository_downloads_full_path].include?(rs.legacy_disk_path.gsub(%r{/$}, '')) }
    Settings.gitlab['repository_downloads_path'] = File.join(Settings.shared['path'], 'cache/archive')
  end
end

#
# Backup
#
Settings['backup'] ||= Settingslogic.new({})
Settings.backup['keep_time']  ||= 0
Settings.backup['pg_schema']    = nil
Settings.backup['path']         = Settings.absolute(Settings.backup['path'] || "tmp/backups/")
Settings.backup['archive_permissions'] ||= 0600
Settings.backup['upload'] ||= Settingslogic.new({ 'remote_directory' => nil, 'connection' => nil })
Settings.backup['upload']['multipart_chunk_size'] ||= 104857600
Settings.backup['upload']['encryption'] ||= nil
Settings.backup['upload']['encryption_key'] ||= ENV['GITLAB_BACKUP_ENCRYPTION_KEY']
Settings.backup['upload']['storage_class'] ||= nil

#
# Pseudonymizer
#
Gitlab.ee do
  Settings['pseudonymizer'] ||= Settingslogic.new({})
  Settings.pseudonymizer['manifest'] = Settings.absolute(Settings.pseudonymizer['manifest'] || Rails.root.join("config/pseudonymizer.yml"))
  Settings.pseudonymizer['upload'] ||= Settingslogic.new({ 'remote_directory' => nil, 'connection' => nil })
  # Settings.pseudonymizer['upload']['multipart_chunk_size'] ||= 104857600
end

#
# Git
#
Settings['git'] ||= Settingslogic.new({})
Settings.git['bin_path'] ||= '/usr/bin/git'

# Important: keep the satellites.path setting until GitLab 9.0 at
# least. This setting is fed to 'rm -rf' in
# db/migrate/20151023144219_remove_satellites.rb
Settings['satellites'] ||= Settingslogic.new({})
Settings.satellites['path'] = Settings.absolute(Settings.satellites['path'] || "tmp/repo_satellites/")

#
# Kerberos
#
Gitlab.ee do
  Settings['kerberos'] ||= Settingslogic.new({})
  Settings.kerberos['enabled'] = false if Settings.kerberos['enabled'].nil?
  Settings.kerberos['keytab'] = nil if Settings.kerberos['keytab'].blank? # nil means use default keytab
  Settings.kerberos['service_principal_name'] = nil if Settings.kerberos['service_principal_name'].blank? # nil means any SPN in keytab
  Settings.kerberos['use_dedicated_port'] = false if Settings.kerberos['use_dedicated_port'].nil?
  Settings.kerberos['https'] = Settings.gitlab.https if Settings.kerberos['https'].nil?
  Settings.kerberos['port'] ||= Settings.kerberos.https ? 8443 : 8088

  if Settings.kerberos['enabled'] && !Settings.omniauth.providers.map(&:name).include?('kerberos_spnego')
    Settings.omniauth.providers << Settingslogic.new({ 'name' => 'kerberos_spnego' })
  end
end

#
# Extra customization
#
Settings['extra'] ||= Settingslogic.new({})

#
# Rack::Attack settings
#
Settings['rack_attack'] ||= Settingslogic.new({})
Settings.rack_attack['git_basic_auth'] ||= Settingslogic.new({})
Settings.rack_attack.git_basic_auth['enabled'] = false if Settings.rack_attack.git_basic_auth['enabled'].nil?
Settings.rack_attack.git_basic_auth['ip_whitelist'] ||= %w{127.0.0.1}
Settings.rack_attack.git_basic_auth['maxretry'] ||= 10
Settings.rack_attack.git_basic_auth['findtime'] ||= 1.minute
Settings.rack_attack.git_basic_auth['bantime'] ||= 1.hour
Settings.rack_attack['admin_area_protected_paths_enabled'] ||= false

#
# Gitaly
#
Settings['gitaly'] ||= Settingslogic.new({})

#
# Webpack settings
#
Settings['webpack'] ||= Settingslogic.new({})
Settings.webpack['dev_server'] ||= Settingslogic.new({})
Settings.webpack.dev_server['enabled'] ||= false
Settings.webpack.dev_server['host']    ||= 'localhost'
Settings.webpack.dev_server['port']    ||= 3808

#
# Monitoring settings
#
Settings['monitoring'] ||= Settingslogic.new({})
Settings.monitoring['ip_whitelist'] ||= ['127.0.0.1/8']
Settings.monitoring['unicorn_sampler_interval'] ||= 10
Settings.monitoring['puma_sampler_interval'] ||= 5
Settings.monitoring['ruby_sampler_interval'] ||= 60
Settings.monitoring['sidekiq_exporter'] ||= Settingslogic.new({})
Settings.monitoring.sidekiq_exporter['enabled'] ||= false
Settings.monitoring.sidekiq_exporter['address'] ||= 'localhost'
Settings.monitoring.sidekiq_exporter['port'] ||= 8082
Settings.monitoring['web_exporter'] ||= Settingslogic.new({})
Settings.monitoring.web_exporter['enabled'] ||= false
Settings.monitoring.web_exporter['address'] ||= 'localhost'
Settings.monitoring.web_exporter['port'] ||= 8083

#
# Shutdown settings
#
Settings['shutdown'] ||= Settingslogic.new({})
Settings.shutdown['blackout_seconds'] ||= 10

#
# Testing settings
#
if Rails.env.test?
  Settings.gitlab['default_projects_limit']   = 42
  Settings.gitlab['default_can_create_group'] = true
  Settings.gitlab['default_can_create_team']  = false
end
