module ApplicationSettingsHelper
  extend self

  delegate  :allow_signup?,
            :gravatar_enabled?,
            :password_authentication_enabled_for_web?,
            :akismet_enabled?,
            :koding_enabled?,
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
      gitlab_config.protocol
    when 'ssh'
      'ssh'
    end
  end

  def enabled_project_button(project, protocol)
    case protocol
    when 'ssh'
      ssh_clone_button(project, append_link: false)
    else
      http_clone_button(project, append_link: false)
    end
  end

  # Return a group of checkboxes that use Bootstrap's button plugin for a
  # toggle button effect.
  def restricted_level_checkboxes(help_block_id, checkbox_name)
    Gitlab::VisibilityLevel.values.map do |level|
      checked = restricted_visibility_levels(true).include?(level)
      css_class = checked ? 'active' : ''
      tag_name = "application_setting_visibility_level_#{level}"

      label_tag(tag_name, class: css_class) do
        check_box_tag(checkbox_name, level, checked,
                      autocomplete: 'off',
                      'aria-describedby' => help_block_id,
                      id: tag_name) + visibility_level_icon(level) + visibility_level_label(level)
      end
    end
  end

  # Return a group of checkboxes that use Bootstrap's button plugin for a
  # toggle button effect.
  def import_sources_checkboxes(help_block_id)
    Gitlab::ImportSources.options.map do |name, source|
      checked = Gitlab::CurrentSettings.import_sources.include?(source)
      css_class = checked ? 'active' : ''
      checkbox_name = 'application_setting[import_sources][]'

      label_tag(name, class: css_class) do
        check_box_tag(checkbox_name, source, checked,
                      autocomplete: 'off',
                      'aria-describedby' => help_block_id,
                      id: name.tr(' ', '_')) + name
      end
    end
  end

  def oauth_providers_checkboxes
    button_based_providers.map do |source|
      disabled = Gitlab::CurrentSettings.disabled_oauth_sign_in_sources.include?(source.to_s)
      css_class = 'btn'
      css_class << ' active' unless disabled
      checkbox_name = 'application_setting[enabled_oauth_sign_in_sources][]'

      label_tag(checkbox_name, class: css_class) do
        check_box_tag(checkbox_name, source, !disabled,
                      autocomplete: 'off') + Gitlab::Auth::OAuth::Provider.label_for(source)
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

  def repository_storages_options_for_select(selected)
    options = Gitlab.config.repositories.storages.map do |name, storage|
      ["#{name} - #{storage['path']}", name]
    end

    options_for_select(options, selected)
  end

  def sidekiq_queue_options_for_select
    options_for_select(Sidekiq::Queue.all.map(&:name), @application_setting.sidekiq_throttling_queues)
  end

  def circuitbreaker_failure_count_help_text
    health_link = link_to(s_('AdminHealthPageLink|health page'), admin_health_check_path)
    api_link = link_to(s_('CircuitBreakerApiLink|circuitbreaker api'), help_page_path("api/repository_storage_health"))
    message = _("The number of failures of after which GitLab will completely "\
                "prevent access to the storage. The number of failures can be "\
                "reset in the admin interface: %{link_to_health_page} or using "\
                "the %{api_documentation_link}.")
    message = message % { link_to_health_page: health_link, api_documentation_link: api_link }

    message.html_safe
  end

  def circuitbreaker_access_retries_help_text
    _('The number of attempts GitLab will make to access a storage.')
  end

  def circuitbreaker_failure_reset_time_help_text
    _("The time in seconds GitLab will keep failure information. When no "\
      "failures occur during this time, information about the mount is reset.")
  end

  def circuitbreaker_storage_timeout_help_text
    _("The time in seconds GitLab will try to access storage. After this time a "\
      "timeout error will be raised.")
  end

  def circuitbreaker_check_interval_help_text
    _("The time in seconds between storage checks. When a previous check did "\
      "complete yet, GitLab will skip a check.")
  end

  def visible_attributes
    [
      :admin_notification_email,
      :after_sign_out_path,
      :after_sign_up_text,
      :akismet_api_key,
      :akismet_enabled,
      :authorized_keys_enabled,
      :auto_devops_enabled,
      :auto_devops_domain,
      :circuitbreaker_access_retries,
      :circuitbreaker_check_interval,
      :circuitbreaker_failure_count_threshold,
      :circuitbreaker_failure_reset_time,
      :circuitbreaker_storage_timeout,
      :clientside_sentry_dsn,
      :clientside_sentry_enabled,
      :container_registry_token_expire_delay,
      :default_artifacts_expire_in,
      :default_branch_protection,
      :default_group_visibility,
      :default_project_visibility,
      :default_projects_limit,
      :default_snippet_visibility,
      :disabled_oauth_sign_in_sources,
      :domain_blacklist_enabled,
      :domain_blacklist_raw,
      :domain_whitelist_raw,
      :dsa_key_restriction,
      :ecdsa_key_restriction,
      :ed25519_key_restriction,
      :email_author_in_body,
      :enabled_git_access_protocol,
      :gitaly_timeout_default,
      :gitaly_timeout_medium,
      :gitaly_timeout_fast,
      :gravatar_enabled,
      :hashed_storage_enabled,
      :help_page_hide_commercial_content,
      :help_page_support_url,
      :help_page_text,
      :home_page_url,
      :housekeeping_bitmaps_enabled,
      :housekeeping_enabled,
      :housekeeping_full_repack_period,
      :housekeeping_gc_period,
      :housekeeping_incremental_repack_period,
      :html_emails_enabled,
      :import_sources,
      :koding_enabled,
      :koding_url,
      :max_artifacts_size,
      :max_attachment_size,
      :max_pages_size,
      :metrics_enabled,
      :metrics_host,
      :metrics_method_call_threshold,
      :metrics_packet_size,
      :metrics_pool_size,
      :metrics_port,
      :metrics_sample_interval,
      :metrics_timeout,
      :pages_domain_verification_enabled,
      :password_authentication_enabled_for_web,
      :password_authentication_enabled_for_git,
      :performance_bar_allowed_group_id,
      :performance_bar_enabled,
      :plantuml_enabled,
      :plantuml_url,
      :polling_interval_multiplier,
      :project_export_enabled,
      :prometheus_metrics_enabled,
      :recaptcha_enabled,
      :recaptcha_private_key,
      :recaptcha_site_key,
      :repository_checks_enabled,
      :repository_storages,
      :require_two_factor_authentication,
      :restricted_visibility_levels,
      :rsa_key_restriction,
      :send_user_confirmation_email,
      :sentry_dsn,
      :sentry_enabled,
      :session_expire_delay,
      :shared_runners_enabled,
      :shared_runners_text,
      :sidekiq_throttling_enabled,
      :sidekiq_throttling_factor,
      :sidekiq_throttling_queues,
      :sign_in_text,
      :signup_enabled,
      :terminal_max_session_time,
      :throttle_unauthenticated_enabled,
      :throttle_unauthenticated_requests_per_period,
      :throttle_unauthenticated_period_in_seconds,
      :throttle_authenticated_web_enabled,
      :throttle_authenticated_web_requests_per_period,
      :throttle_authenticated_web_period_in_seconds,
      :throttle_authenticated_api_enabled,
      :throttle_authenticated_api_requests_per_period,
      :throttle_authenticated_api_period_in_seconds,
      :two_factor_grace_period,
      :unique_ips_limit_enabled,
      :unique_ips_limit_per_user,
      :unique_ips_limit_time_window,
      :usage_ping_enabled,
      :user_default_external,
      :user_oauth_applications,
      :version_check_enabled,
      :allow_local_requests_from_hooks_and_services
    ]
  end
end
