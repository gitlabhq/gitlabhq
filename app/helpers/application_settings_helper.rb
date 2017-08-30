module ApplicationSettingsHelper
  prepend EE::ApplicationSettingsHelper
  extend self

  delegate  :gravatar_enabled?,
            :signup_enabled?,
            :password_authentication_enabled?,
            :akismet_enabled?,
            :koding_enabled?,
            to: :current_application_settings

  def user_oauth_applications?
    current_application_settings.user_oauth_applications
  end

  def allowed_protocols_present?
    current_application_settings.enabled_git_access_protocol.present?
  end

  def enabled_protocol
    case current_application_settings.enabled_git_access_protocol
    when 'http'
      gitlab_config.protocol
    when 'ssh'
      'ssh'
    end
  end

  def enabled_project_button(project, protocol)
    case protocol
    when 'ssh'
      ssh_clone_button(project, 'bottom', append_link: false)
    else
      http_clone_button(project, 'bottom', append_link: false)
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
      checked = current_application_settings.import_sources.include?(source)
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
      disabled = current_application_settings.disabled_oauth_sign_in_sources.include?(source.to_s)
      css_class = 'btn'
      css_class << ' active' unless disabled
      checkbox_name = 'application_setting[enabled_oauth_sign_in_sources][]'

      label_tag(checkbox_name, class: css_class) do
        check_box_tag(checkbox_name, source, !disabled,
                      autocomplete: 'off') + Gitlab::OAuth::Provider.label_for(source)
      end
    end
  end

  def repository_storages_options_for_select
    options = Gitlab.config.repositories.storages.map do |name, storage|
      ["#{name} - #{storage['path']}", name]
    end

    options_for_select(options, @application_setting.repository_storages)
  end

  def sidekiq_queue_options_for_select
    options_for_select(Sidekiq::Queue.all.map(&:name), @application_setting.sidekiq_throttling_queues)
  end

  def visible_attributes
    [
      :admin_notification_email,
      :after_sign_out_path,
      :after_sign_up_text,
      :akismet_api_key,
      :akismet_enabled,
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
      :email_author_in_body,
      :enabled_git_access_protocol,
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
      :password_authentication_enabled,
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
      :two_factor_grace_period,
      :unique_ips_limit_enabled,
      :unique_ips_limit_per_user,
      :unique_ips_limit_time_window,
      :usage_ping_enabled,
      :user_default_external,
      :user_oauth_applications,
      :version_check_enabled
    ]
  end
end
