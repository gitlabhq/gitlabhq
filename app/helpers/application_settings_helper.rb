# frozen_string_literal: true

module ApplicationSettingsHelper
  extend self

  delegate :allow_signup?,
           :gravatar_enabled?,
           :password_authentication_enabled_for_web?,
           :akismet_enabled?,
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
    Gitlab.config.repositories.storages.keys.each_with_object(OpenStruct.new) do |storage, weights|
      weights[storage.to_sym] = @application_setting.repository_storages_weighted[storage] || 0
    end
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

  def enabled_protocol_button(container, protocol)
    case protocol
    when 'ssh'
      ssh_clone_button(container, append_link: false)
    else
      http_clone_button(container, append_link: false)
    end
  end

  # Return a group of checkboxes that use Bootstrap's button plugin for a
  # toggle button effect.
  def restricted_level_checkboxes(help_block_id, checkbox_name, options = {})
    Gitlab::VisibilityLevel.values.map do |level|
      checked = restricted_visibility_levels(true).include?(level)
      css_class = checked ? 'active' : ''
      tag_name = "application_setting_visibility_level_#{level}"

      label_tag(tag_name, class: css_class) do
        check_box_tag(checkbox_name, level, checked,
                      autocomplete: 'off',
                      'aria-describedby' => help_block_id,
                      'class' => options[:class],
                      id: tag_name) + visibility_level_icon(level) + visibility_level_label(level)
      end
    end
  end

  # Return a group of checkboxes that use Bootstrap's button plugin for a
  # toggle button effect.
  def import_sources_checkboxes(help_block_id, options = {})
    Gitlab::ImportSources.options.map do |name, source|
      checked = @application_setting.import_sources.include?(source)
      css_class = checked ? 'active' : ''
      checkbox_name = 'application_setting[import_sources][]'

      label_tag(name, class: css_class) do
        check_box_tag(checkbox_name, source, checked,
                      autocomplete: 'off',
                      'aria-describedby' => help_block_id,
                      'class' => options[:class],
                      id: name.tr(' ', '_')) + name
      end
    end
  end

  def oauth_providers_checkboxes
    button_based_providers.map do |source|
      disabled = @application_setting.disabled_oauth_sign_in_sources.include?(source.to_s)
      name = Gitlab::Auth::OAuth::Provider.label_for(source)
      checkbox_name = 'application_setting[enabled_oauth_sign_in_sources][]'
      checkbox_id = "application_setting_enabled_oauth_sign_in_sources_#{name.parameterize(separator: '_')}"

      content_tag :div, class: 'form-check' do
        check_box_tag(
          checkbox_name,
          source,
          !disabled,
          autocomplete: 'off',
          id: checkbox_id,
          class: 'form-check-input'
        ) +
        label_tag(checkbox_id, name, class: 'form-check-label')
      end
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
    _("If enabled, access to projects will be validated on an external service"\
        " using their classification label.")
  end

  def external_authorization_timeout_help_text
    _("Time in seconds GitLab will wait for a response from the external "\
        "service. When the service does not respond in time, access will be "\
        "denied.")
  end

  def external_authorization_url_help_text
    _("When leaving the URL blank, classification labels can still be "\
        "specified without disabling cross project features or performing "\
        "external authorization checks.")
  end

  def external_authorization_client_certificate_help_text
    _("The X509 Certificate to use when mutual TLS is required to communicate "\
        "with the external authorization service. If left blank, the server "\
        "certificate is still validated when accessing over HTTPS.")
  end

  def external_authorization_client_key_help_text
    _("The private key to use when a client certificate is provided. This value "\
        "is encrypted at rest.")
  end

  def external_authorization_client_pass_help_text
    _("The passphrase required to decrypt the private key. This is optional "\
        "and the value is encrypted at rest.")
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
      :container_expiration_policies_enable_historic_entries,
      :container_registry_token_expire_delay,
      :default_artifacts_expire_in,
      :default_branch_name,
      :default_branch_protection,
      :default_ci_config_path,
      :default_group_visibility,
      :default_project_creation,
      :default_project_visibility,
      :default_projects_limit,
      :default_snippet_visibility,
      :disable_feed_token,
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
      :ed25519_key_restriction,
      :eks_integration_enabled,
      :eks_account_id,
      :eks_access_key_id,
      :eks_secret_access_key,
      :email_author_in_body,
      :enabled_git_access_protocol,
      :enforce_terms,
      :external_pipeline_validation_service_timeout,
      :external_pipeline_validation_service_token,
      :external_pipeline_validation_service_url,
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
      :housekeeping_bitmaps_enabled,
      :housekeeping_enabled,
      :housekeeping_full_repack_period,
      :housekeeping_gc_period,
      :housekeeping_incremental_repack_period,
      :html_emails_enabled,
      :import_sources,
      :in_product_marketing_emails_enabled,
      :invisible_captcha_enabled,
      :max_artifacts_size,
      :max_attachment_size,
      :max_import_size,
      :max_pages_size,
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
      :require_two_factor_authentication,
      :restricted_visibility_levels,
      :rsa_key_restriction,
      :send_user_confirmation_email,
      :session_expire_delay,
      :shared_runners_enabled,
      :shared_runners_text,
      :sign_in_text,
      :signup_enabled,
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
      :throttle_authenticated_web_enabled,
      :throttle_authenticated_web_period_in_seconds,
      :throttle_authenticated_web_requests_per_period,
      :throttle_authenticated_packages_api_enabled,
      :throttle_authenticated_packages_api_period_in_seconds,
      :throttle_authenticated_packages_api_requests_per_period,
      :throttle_unauthenticated_enabled,
      :throttle_unauthenticated_period_in_seconds,
      :throttle_unauthenticated_requests_per_period,
      :throttle_unauthenticated_packages_api_enabled,
      :throttle_unauthenticated_packages_api_period_in_seconds,
      :throttle_unauthenticated_packages_api_requests_per_period,
      :throttle_protected_paths_enabled,
      :throttle_protected_paths_period_in_seconds,
      :throttle_protected_paths_requests_per_period,
      :protected_paths_raw,
      :time_tracking_limit_to_hours,
      :two_factor_grace_period,
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
      :web_ide_clientside_preview_enabled,
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
      :raw_blob_request_limit,
      :project_import_limit,
      :project_export_limit,
      :project_download_export_limit,
      :group_import_limit,
      :group_export_limit,
      :group_download_export_limit,
      :wiki_page_max_content_bytes,
      :container_registry_delete_tags_service_timeout,
      :rate_limiting_response_text,
      :container_registry_expiration_policies_worker_capacity,
      :container_registry_cleanup_tags_service_max_list_size,
      :keep_latest_artifact,
      :whats_new_variant
    ].tap do |settings|
      settings << :deactivate_dormant_users unless Gitlab.com?
    end
  end

  def external_authorization_service_attributes
    [
      :external_auth_client_cert,
      :external_auth_client_key,
      :external_auth_client_key_pass,
      :external_authorization_service_default_label,
      :external_authorization_service_enabled,
      :external_authorization_service_timeout,
      :external_authorization_service_url
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
    can?(current_user, :read_cluster, Clusters::Instance.new)
  end

  def omnibus_protected_paths_throttle?
    Rack::Attack.throttles.key?('protected paths')
  end

  def self_monitoring_project_data
    {
      'create_self_monitoring_project_path' =>
        create_self_monitoring_project_admin_application_settings_path,

      'status_create_self_monitoring_project_path' =>
        status_create_self_monitoring_project_admin_application_settings_path,

      'delete_self_monitoring_project_path' =>
        delete_self_monitoring_project_admin_application_settings_path,

      'status_delete_self_monitoring_project_path' =>
        status_delete_self_monitoring_project_admin_application_settings_path,

      'self_monitoring_project_exists' =>
        Gitlab::CurrentSettings.self_monitoring_project.present?.to_s,

      'self_monitoring_project_full_path' =>
        Gitlab::CurrentSettings.self_monitoring_project&.full_path
    }
  end

  def show_documentation_base_url_field?
    Feature.enabled?(:help_page_documentation_redirect)
  end

  def valid_runner_registrars
    Gitlab::CurrentSettings.valid_runner_registrars
  end

  def signup_enabled?
    !!Gitlab::CurrentSettings.signup_enabled
  end
end

ApplicationSettingsHelper.prepend_mod_with('ApplicationSettingsHelper')

# The methods in `EE::ApplicationSettingsHelper` should be available as both
# instance and class methods.
ApplicationSettingsHelper.extend_mod_with('ApplicationSettingsHelper')
