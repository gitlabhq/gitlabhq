# frozen_string_literal: true

module ApplicationSettingsHelper
  extend self

  delegate :allow_signup?,
    :gravatar_enabled?,
    :password_authentication_enabled_for_web?,
    :akismet_enabled?,
    :spam_check_endpoint_enabled?,
    :require_personal_access_token_expiry?,
    to: :'Gitlab::CurrentSettings.current_application_settings'

  def user_oauth_applications?
    Gitlab::CurrentSettings.user_oauth_applications
  end

  def allowed_protocols_present?
    Gitlab::CurrentSettings.enabled_git_access_protocol.present?
  end

  def enabled_protocol
    case Gitlab::CurrentSettings.enabled_git_access_protocol
    when 'http'
      Gitlab.config.gitlab.protocol
    when 'ssh'
      'ssh'
    end
  end

  def kroki_available_formats
    ApplicationSetting.kroki_formats_attributes.map do |key, value|
      {
        name: "kroki_formats_#{key}",
        label: value[:label],
        value: @application_setting.kroki_formats[key] || false
      }
    end
  end

  def storage_weights
    # Instead of using a `Struct` we could wrap this into an object.
    # See https://gitlab.com/gitlab-org/gitlab/-/issues/358419
    storages_weighted = @application_setting.repository_storages_with_default_weight

    weights = Struct.new(*storages_weighted.keys.map(&:to_sym))
    weights.new(*storages_weighted.values)
  end

  def all_protocols_enabled?
    Gitlab::CurrentSettings.enabled_git_access_protocol.blank?
  end

  def ssh_enabled?
    all_protocols_enabled? || enabled_protocol == 'ssh'
  end

  def http_enabled?
    all_protocols_enabled? || Gitlab::CurrentSettings.enabled_git_access_protocol == 'http'
  end

  def anti_spam_service_enabled?
    akismet_enabled? || spam_check_endpoint_enabled?
  end

  def enabled_protocol_button(container, protocol)
    case protocol
    when 'ssh'
      ssh_clone_button(container, append_link: false)
    else
      http_clone_button(container, append_link: false)
    end
  end

  def global_search_settings_checkboxes(form)
    [
      form.gitlab_ui_checkbox_component(
        :global_search_issues_enabled,
        _("Enable issues tab in global search results"),
        checkbox_options: { checked: @application_setting.global_search_issues_enabled, multiple: false }
      ),
      form.gitlab_ui_checkbox_component(
        :global_search_merge_requests_enabled,
        _("Enable merge requests tab in global search results"),
        checkbox_options: { checked: @application_setting.global_search_merge_requests_enabled, multiple: false }
      ),
      form.gitlab_ui_checkbox_component(
        :global_search_snippet_titles_enabled,
        _("Enable snippet tab in global search results"),
        checkbox_options: { checked: @application_setting.global_search_snippet_titles_enabled, multiple: false }
      ),
      form.gitlab_ui_checkbox_component(
        :global_search_users_enabled,
        _("Enable users tab in global search results"),
        checkbox_options: { checked: @application_setting.global_search_users_enabled, multiple: false }
      )
    ]
  end

  def restricted_level_checkboxes(form)
    restricted_visibility_levels_help_text = {
      Gitlab::VisibilityLevel::PUBLIC => s_(
        'AdminSettings|If selected, only administrators are able to create public groups, projects, ' \
          'and snippets. Also, profiles are only visible to authenticated users.'
      ),
      Gitlab::VisibilityLevel::INTERNAL => s_(
        'AdminSettings|If selected, only administrators are able to create internal groups, projects, and ' \
          'snippets.'
      ),
      Gitlab::VisibilityLevel::PRIVATE => s_(
        'AdminSettings|If selected, only administrators are able to create private groups, projects, and ' \
          'snippets.'
      )
    }

    Gitlab::VisibilityLevel.options.map do |label, level|
      checked = restricted_visibility_levels(true).include?(level)

      form.gitlab_ui_checkbox_component(
        :restricted_visibility_levels,
        checkbox_options: { checked: checked, multiple: true, autocomplete: 'off' },
        checked_value: level,
        unchecked_value: nil
      ) do |c|
        c.with_label do
          visibility_level_icon(level) + content_tag(:span, label, { class: 'gl-ml-2' })
        end

        c.with_help_text do
          restricted_visibility_levels_help_text.fetch(level)
        end
      end
    end
  end

  def import_sources_checkboxes(form)
    Gitlab::ImportSources.options.map do |name, source|
      checked = @application_setting.import_sources.include?(source)

      form.gitlab_ui_checkbox_component(
        :import_sources,
        name,
        checkbox_options: { checked: checked, multiple: true, autocomplete: 'off' },
        checked_value: source,
        unchecked_value: nil
      )
    end
  end

  def oauth_providers_checkboxes(form)
    button_based_providers.map do |source|
      checked = @application_setting.disabled_oauth_sign_in_sources.exclude?(source.to_s)
      name = Gitlab::Auth::OAuth::Provider.label_for(source)

      form.gitlab_ui_checkbox_component(
        :enabled_oauth_sign_in_sources,
        name,
        checkbox_options: { checked: checked, multiple: true, autocomplete: 'off' },
        checked_value: source,
        unchecked_value: nil
      )
    end
  end

  def key_restriction_options_for_select(type)
    bit_size_options = Gitlab::SSHPublicKey.supported_sizes(type).map do |bits|
      ["Must be at least #{bits} bits", bits]
    end

    [
      ['Are allowed', 0],
      *bit_size_options,
      ['Are forbidden', ApplicationSetting::FORBIDDEN_KEY_VALUE]
    ]
  end

  def repository_storages_options_json
    options = Gitlab.config.repositories.storages.map do |name, storage|
      {
        label: "#{name} - #{storage['gitaly_address']}",
        value: name
      }
    end

    options.to_json
  end

  def external_authorization_description
    s_("ExternalAuthorization|Access to projects is validated on an external service "\
      "using their classification label.")
  end

  def external_authorization_allow_token_help_text
    s_("ExternalAuthorization|Does not apply if service URL is specified.")
  end

  def external_authorization_timeout_help_text
    s_("ExternalAuthorization|Period GitLab waits for a response from the external "\
      "service. If there is no response, access is denied. Default: 0.5 seconds.")
  end

  def external_authorization_url_help_text
    s_("ExternalAuthorization|URL to which the projects make authorization requests. If the URL is blank, cross-project "\
      "features are available and can still specify classification "\
      "labels for projects.")
  end

  def external_authorization_client_certificate_help_text
    s_("ExternalAuthorization|Certificate used to authenticate with the external authorization service. "\
      "If blank, the server certificate is validated when accessing over HTTPS.")
  end

  def external_authorization_client_key_help_text
    s_("ExternalAuthorization|Private key of client authentication certificate. "\
      "Encrypted when stored.")
  end

  def external_authorization_client_pass_help_text
    s_("ExternalAuthorization|Passphrase required to decrypt the private key. "\
      "Encrypted when stored.")
  end

  def external_authorization_client_url_help_text
    s_("ExternalAuthorization|Classification label to use when requesting authorization if no specific "\
      "label is defined on the project.")
  end

  def sidekiq_job_limiter_mode_help_text
    _("How the job limiter handles jobs exceeding the thresholds specified below. "\
      "The 'track' mode only logs the jobs. The 'compress' mode compresses the jobs and "\
      "raises an exception if the compressed size exceeds the limit.")
  end

  def sidekiq_job_limiter_modes_for_select
    ApplicationSetting.sidekiq_job_limiter_modes.keys.map { |mode| [mode.humanize, mode] }
  end

  def visible_attributes
    [
      :abuse_notification_email,
      :admin_mode,
      :after_sign_out_path,
      :after_sign_up_text,
      :akismet_api_key,
      :akismet_enabled,
      :allow_local_requests_from_hooks_and_services,
      :allow_local_requests_from_web_hooks_and_services,
      :allow_local_requests_from_system_hooks,
      :allow_possible_spam,
      :dns_rebinding_protection_enabled,
      :archive_builds_in_human_readable,
      :asset_proxy_enabled,
      :asset_proxy_secret_key,
      :asset_proxy_url,
      :asset_proxy_allowlist,
      :static_objects_external_storage_auth_token,
      :static_objects_external_storage_url,
      :authorized_keys_enabled,
      :auto_devops_enabled,
      :auto_devops_domain,
      :concurrent_github_import_jobs_limit,
      :concurrent_bitbucket_import_jobs_limit,
      :concurrent_bitbucket_server_import_jobs_limit,
      :container_expiration_policies_enable_historic_entries,
      :container_registry_expiration_policies_caching,
      :container_registry_token_expire_delay,
      :decompress_archive_file_timeout,
      :default_artifacts_expire_in,
      :default_branch_name,
      :default_branch_protection,
      :default_branch_protection_defaults,
      :default_ci_config_path,
      :default_group_visibility,
      :default_preferred_language,
      :default_project_creation,
      :default_project_visibility,
      :default_projects_limit,
      :default_snippet_visibility,
      :default_syntax_highlighting_theme,
      :delete_inactive_projects,
      :deny_all_requests_except_allowed,
      :disable_admin_oauth_scopes,
      :disable_feed_token,
      :disable_password_authentication_for_users_with_sso_identities,
      :root_moved_permanently_redirection,
      :disabled_oauth_sign_in_sources,
      :domain_denylist,
      :domain_denylist_enabled,
      # TODO Remove domain_denylist_raw in APIv5 (See https://gitlab.com/gitlab-org/gitlab-foss/issues/67204)
      :domain_denylist_raw,
      :domain_allowlist,
      # TODO Remove domain_allowlist_raw in APIv5 (See https://gitlab.com/gitlab-org/gitlab-foss/issues/67204)
      :domain_allowlist_raw,
      :outbound_local_requests_allowlist_raw,
      :dsa_key_restriction,
      :ecdsa_key_restriction,
      :ecdsa_sk_key_restriction,
      :ed25519_key_restriction,
      :ed25519_sk_key_restriction,
      :eks_integration_enabled,
      :eks_account_id,
      :eks_access_key_id,
      :eks_secret_access_key,
      :email_author_in_body,
      :email_confirmation_setting,
      :enabled_git_access_protocol,
      :enforce_ci_inbound_job_token_scope_enabled,
      :enforce_terms,
      :error_tracking_enabled,
      :error_tracking_api_url,
      :external_pipeline_validation_service_timeout,
      :external_pipeline_validation_service_token,
      :external_pipeline_validation_service_url,
      :failed_login_attempts_unlock_period_in_minutes,
      :first_day_of_week,
      :floc_enabled,
      :force_pages_access_control,
      :gitaly_timeout_default,
      :gitaly_timeout_medium,
      :gitaly_timeout_fast,
      :gitpod_enabled,
      :gitpod_url,
      :grafana_enabled,
      :grafana_url,
      :gravatar_enabled,
      :hashed_storage_enabled,
      :help_page_hide_commercial_content,
      :help_page_support_url,
      :help_page_documentation_base_url,
      :help_page_text,
      :hide_third_party_offers,
      :home_page_url,
      :housekeeping_enabled,
      :housekeeping_full_repack_period,
      :housekeeping_gc_period,
      :housekeeping_incremental_repack_period,
      :housekeeping_optimize_repository_period,
      :html_emails_enabled,
      :import_sources,
      :inactive_projects_delete_after_months,
      :inactive_projects_min_size_mb,
      :inactive_projects_send_warning_email_after_months,
      :include_optional_metrics_in_service_ping,
      :invisible_captcha_enabled,
      :jira_connect_application_key,
      :jira_connect_public_key_storage_enabled,
      :jira_connect_proxy_url,
      :jira_connect_additional_audience_url,
      :math_rendering_limits_enabled,
      :max_artifacts_content_include_size,
      :max_artifacts_size,
      :max_attachment_size,
      :max_decompressed_archive_size,
      :max_export_size,
      :max_import_size,
      :max_import_remote_file_size,
      :max_login_attempts,
      :max_pages_size,
      :max_pages_custom_domains_per_project,
      :max_terraform_state_size_bytes,
      :max_yaml_size_bytes,
      :max_yaml_depth,
      :metrics_method_call_threshold,
      :minimum_password_length,
      :mirror_available,
      :notify_on_unknown_sign_in,
      :pages_domain_verification_enabled,
      :password_authentication_enabled_for_web,
      :password_authentication_enabled_for_git,
      :performance_bar_allowed_group_path,
      :performance_bar_enabled,
      :personal_access_token_prefix,
      :kroki_enabled,
      :kroki_url,
      :kroki_formats,
      :plantuml_enabled,
      :plantuml_url,
      :diagramsnet_enabled,
      :diagramsnet_url,
      :pages_extra_deployments_default_expiry_seconds,
      :polling_interval_multiplier,
      :project_export_enabled,
      :prometheus_metrics_enabled,
      :recaptcha_enabled,
      :recaptcha_private_key,
      :recaptcha_site_key,
      :login_recaptcha_protection_enabled,
      :receive_max_input_size,
      :repository_checks_enabled,
      :repository_storages_weighted,
      :require_admin_approval_after_user_signup,
      :require_admin_two_factor_authentication,
      :require_two_factor_authentication,
      :remember_me_enabled,
      :restricted_visibility_levels,
      :rsa_key_restriction,
      :session_expire_delay,
      :shared_runners_enabled,
      :shared_runners_text,
      :signup_enabled,
      :silent_mode_enabled,
      :slack_app_enabled,
      :slack_app_id,
      :slack_app_secret,
      :slack_app_signing_secret,
      :slack_app_verification_token,
      :sourcegraph_enabled,
      :sourcegraph_url,
      :sourcegraph_public_only,
      :spam_check_endpoint_enabled,
      :spam_check_endpoint_url,
      :spam_check_api_key,
      :terminal_max_session_time,
      :terms,
      :throttle_authenticated_api_enabled,
      :throttle_authenticated_api_period_in_seconds,
      :throttle_authenticated_api_requests_per_period,
      :throttle_authenticated_git_lfs_enabled,
      :throttle_authenticated_git_lfs_period_in_seconds,
      :throttle_authenticated_git_lfs_requests_per_period,
      :throttle_authenticated_web_enabled,
      :throttle_authenticated_web_period_in_seconds,
      :throttle_authenticated_web_requests_per_period,
      :throttle_authenticated_packages_api_enabled,
      :throttle_authenticated_packages_api_period_in_seconds,
      :throttle_authenticated_packages_api_requests_per_period,
      :throttle_authenticated_files_api_enabled,
      :throttle_authenticated_files_api_period_in_seconds,
      :throttle_authenticated_files_api_requests_per_period,
      :throttle_authenticated_deprecated_api_enabled,
      :throttle_authenticated_deprecated_api_period_in_seconds,
      :throttle_authenticated_deprecated_api_requests_per_period,
      :throttle_unauthenticated_api_enabled,
      :throttle_unauthenticated_api_period_in_seconds,
      :throttle_unauthenticated_api_requests_per_period,
      :throttle_unauthenticated_enabled,
      :throttle_unauthenticated_period_in_seconds,
      :throttle_unauthenticated_requests_per_period,
      :throttle_unauthenticated_packages_api_enabled,
      :throttle_unauthenticated_packages_api_period_in_seconds,
      :throttle_unauthenticated_packages_api_requests_per_period,
      :throttle_unauthenticated_files_api_enabled,
      :throttle_unauthenticated_files_api_period_in_seconds,
      :throttle_unauthenticated_files_api_requests_per_period,
      :throttle_unauthenticated_git_http_enabled,
      :throttle_unauthenticated_git_http_period_in_seconds,
      :throttle_unauthenticated_git_http_requests_per_period,
      :throttle_unauthenticated_deprecated_api_enabled,
      :throttle_unauthenticated_deprecated_api_period_in_seconds,
      :throttle_unauthenticated_deprecated_api_requests_per_period,
      :throttle_protected_paths_enabled,
      :throttle_protected_paths_period_in_seconds,
      :throttle_protected_paths_requests_per_period,
      :protected_paths_raw,
      :protected_paths_for_get_request_raw,
      :time_tracking_limit_to_hours,
      :two_factor_grace_period,
      :update_runner_versions_enabled,
      :unique_ips_limit_enabled,
      :unique_ips_limit_per_user,
      :unique_ips_limit_time_window,
      :usage_ping_enabled,
      :usage_ping_features_enabled,
      :user_default_external,
      :user_show_add_ssh_key_message,
      :user_default_internal_regex,
      :user_oauth_applications,
      :version_check_enabled,
      :diff_max_patch_bytes,
      :diff_max_files,
      :diff_max_lines,
      :commit_email_hostname,
      :protected_ci_variables,
      :local_markdown_version,
      :mailgun_signing_key,
      :mailgun_events_enabled,
      :snowplow_collector_hostname,
      :snowplow_cookie_domain,
      :snowplow_database_collector_hostname,
      :snowplow_enabled,
      :snowplow_app_id,
      :push_event_hooks_limit,
      :push_event_activities_limit,
      :custom_http_clone_url_root,
      :snippet_size_limit,
      :email_restrictions_enabled,
      :email_restrictions,
      :issues_create_limit,
      :notes_create_limit,
      :notes_create_limit_allowlist_raw,
      :members_delete_limit,
      :raw_blob_request_limit,
      :project_import_limit,
      :project_export_limit,
      :project_download_export_limit,
      :group_import_limit,
      :group_export_limit,
      :group_download_export_limit,
      :wiki_page_max_content_bytes,
      :wiki_asciidoc_allow_uri_includes,
      :container_registry_delete_tags_service_timeout,
      :rate_limiting_response_text,
      :package_registry_allow_anyone_to_pull_option,
      :package_registry_cleanup_policies_worker_capacity,
      :container_registry_expiration_policies_worker_capacity,
      :container_registry_cleanup_tags_service_max_list_size,
      :keep_latest_artifact,
      :whats_new_variant,
      :user_deactivation_emails_enabled,
      :resource_access_token_notify_inherited,
      :lock_resource_access_token_notify_inherited,
      :sentry_enabled,
      :sentry_dsn,
      :sentry_clientside_dsn,
      :sentry_environment,
      :sentry_clientside_traces_sample_rate,
      :sidekiq_job_limiter_mode,
      :sidekiq_job_limiter_compression_threshold_bytes,
      :sidekiq_job_limiter_limit_bytes,
      :suggest_pipeline_enabled,
      :enable_artifact_external_redirect_warning_page,
      :search_rate_limit,
      :search_rate_limit_unauthenticated,
      :search_rate_limit_allowlist_raw,
      :users_get_by_id_limit,
      :users_get_by_id_limit_allowlist_raw,
      :runner_token_expiration_interval,
      :group_runner_token_expiration_interval,
      :project_runner_token_expiration_interval,
      :pipeline_limit_per_project_user_sha,
      :invitation_flow_enforcement,
      :can_create_group,
      :can_create_organization,
      :bulk_import_concurrent_pipeline_batch_limit,
      :concurrent_relation_batch_export_limit,
      :bulk_import_enabled,
      :bulk_import_max_download_file_size,
      :silent_admin_exports_enabled,
      :allow_contribution_mapping_to_admins,
      :allow_runner_registration_token,
      :user_defaults_to_private_profile,
      :deactivation_email_additional_text,
      :projects_api_rate_limit_unauthenticated,
      :group_api_limit,
      :group_invited_groups_api_limit,
      :group_shared_groups_api_limit,
      :group_projects_api_limit,
      :groups_api_limit,
      :project_api_limit,
      :project_invited_groups_api_limit,
      :projects_api_limit,
      :create_organization_api_limit,
      :user_contributed_projects_api_limit,
      :user_projects_api_limit,
      :user_starred_projects_api_limit,
      :gitlab_dedicated_instance,
      :gitlab_environment_toolkit_instance,
      :ci_max_includes,
      :allow_account_deletion,
      :gitlab_shell_operation_limit,
      :namespace_aggregation_schedule_lease_duration_in_seconds,
      :ci_max_total_yaml_size_bytes,
      :project_jobs_api_rate_limit,
      :security_txt_content,
      :allow_project_creation_for_guest_and_below,
      :downstream_pipeline_trigger_limit_per_project_user_sha,
      :asciidoc_max_includes,
      :ai_action_api_rate_limit,
      :code_suggestions_api_rate_limit,
      :require_personal_access_token_expiry,
      :observability_backend_ssl_verification_enabled,
      :show_migrate_from_jenkins_banner,
      :ropc_without_client_credentials,
      :global_search_snippet_titles_enabled,
      :global_search_users_enabled,
      :global_search_issues_enabled,
      :global_search_merge_requests_enabled
    ].tap do |settings|
      unless Gitlab.com?
        settings << :resource_usage_limits
        settings << :deactivate_dormant_users
        settings << :deactivate_dormant_users_period
        settings << :nuget_skip_metadata_url_validation
      end
    end
  end

  def runner_token_expiration_interval_attributes
    {
      instance_runner_token_expiration_interval: @application_setting.runner_token_expiration_interval,
      group_runner_token_expiration_interval: @application_setting.group_runner_token_expiration_interval,
      project_runner_token_expiration_interval: @application_setting.project_runner_token_expiration_interval
    }
  end

  def external_authorization_service_attributes
    [
      :external_auth_client_cert,
      :external_auth_client_key,
      :external_auth_client_key_pass,
      :external_authorization_service_default_label,
      :external_authorization_service_enabled,
      :external_authorization_service_timeout,
      :external_authorization_service_url,
      :allow_deploy_tokens_and_keys_with_external_authn
    ]
  end

  # ok to remove in REST API v5
  def deprecated_attributes
    [
      :admin_notification_email,
      :asset_proxy_whitelist
    ]
  end

  def expanded_by_default?
    Rails.env.test?
  end

  def integration_expanded?(substring)
    @application_setting.errors.messages.any? { |k, _| k.to_s.start_with?(substring) }
  end

  def instance_clusters_enabled?
    clusterable = Clusters::Instance.new

    clusterable.certificate_based_clusters_enabled? &&
      can?(current_user, :read_cluster, clusterable)
  end

  def valid_runner_registrars
    Gitlab::CurrentSettings.valid_runner_registrars
  end

  def signup_enabled?
    !!Gitlab::CurrentSettings.signup_enabled
  end

  def pending_user_count
    User.blocked_pending_approval.count
  end

  def registration_features_can_be_prompted?
    !Gitlab::CurrentSettings.usage_ping_enabled?
  end

  def signup_form_data
    {
      host: new_user_registration_url(host: Gitlab.config.gitlab.host),
      settings_path: general_admin_application_settings_path(anchor: 'js-signup-settings'),
      signup_enabled: @application_setting[:signup_enabled].to_s,
      require_admin_approval_after_user_signup: @application_setting[:require_admin_approval_after_user_signup].to_s,
      email_confirmation_setting: @application_setting[:email_confirmation_setting].to_s,
      minimum_password_length: @application_setting[:minimum_password_length],
      minimum_password_length_min: ApplicationSetting::DEFAULT_MINIMUM_PASSWORD_LENGTH,
      minimum_password_length_max: Devise.password_length.max,
      minimum_password_length_help_link:
        'https://about.gitlab.com/handbook/security/#gitlab-password-policy-guidelines',
      domain_allowlist_raw: @application_setting.domain_allowlist_raw,
      new_user_signups_cap: @application_setting[:new_user_signups_cap].to_s,
      domain_denylist_enabled: @application_setting[:domain_denylist_enabled].to_s,
      denylist_type_raw_selected:
        (@application_setting.domain_denylist.present? || @application_setting.domain_denylist.blank?).to_s,
      domain_denylist_raw: @application_setting.domain_denylist_raw,
      email_restrictions_enabled: @application_setting[:email_restrictions_enabled].to_s,
      supported_syntax_link_url: 'https://github.com/google/re2/wiki/Syntax',
      email_restrictions: @application_setting.email_restrictions.to_s,
      after_sign_up_text: @application_setting[:after_sign_up_text].to_s,
      pending_user_count: pending_user_count
    }
  end
end

ApplicationSettingsHelper.prepend_mod_with('ApplicationSettingsHelper')

# The methods in `EE::ApplicationSettingsHelper` should be available as both
# instance and class methods.
ApplicationSettingsHelper.extend_mod_with('ApplicationSettingsHelper')
