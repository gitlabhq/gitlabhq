class Admin::ApplicationSettingsController < Admin::ApplicationController
  prepend EE::Admin::ApplicationSettingsController

  before_action :set_application_setting

  def show
  end

  def update
    successful = ApplicationSettings::UpdateService
      .new(@application_setting, current_user, application_setting_params)
      .execute

    if successful
      redirect_to admin_application_settings_path,
        notice: 'Application settings saved successfully'
    else
      render :show
    end
  end

  def usage_data
    respond_to do |format|
      format.html do
        usage_data = Gitlab::UsageData.data
        usage_data_json = params[:pretty] ? JSON.pretty_generate(usage_data) : usage_data.to_json

        render html: Gitlab::Highlight.highlight('payload.json', usage_data_json)
      end
      format.json { render json: Gitlab::UsageData.to_json }
    end
  end

  def reset_runners_token
    @application_setting.reset_runners_registration_token!
    flash[:notice] = 'New runners registration token has been generated!'
    redirect_to admin_runners_path
  end

  def reset_health_check_token
    @application_setting.reset_health_check_access_token!
    flash[:notice] = 'New health check access token has been generated!'
    redirect_to :back
  end

  def clear_repository_check_states
    RepositoryCheck::ClearWorker.perform_async

    redirect_to(
      admin_application_settings_path,
      notice: 'Started asynchronous removal of all repository check states.'
    )
  end

  private

  def set_application_setting
    @application_setting = current_application_settings
  end

  def application_setting_params
    import_sources = params[:application_setting][:import_sources]
    if import_sources.nil?
      params[:application_setting][:import_sources] = []
    else
      import_sources.map! do |source|
        source.to_str
      end
    end

    enabled_oauth_sign_in_sources = params[:application_setting].delete(:enabled_oauth_sign_in_sources)

    params[:application_setting][:disabled_oauth_sign_in_sources] =
      AuthHelper.button_based_providers.map(&:to_s) -
      Array(enabled_oauth_sign_in_sources)

    params[:application_setting][:restricted_visibility_levels]&.delete("")
    params.delete(:domain_blacklist_raw) if params[:domain_blacklist_file]

    params.require(:application_setting).permit(
      application_setting_params_attributes
    )
  end

  def application_setting_params_attributes
    [
      :admin_notification_email,
      :after_sign_out_path,
      :after_sign_up_text,
      :akismet_api_key,
      :akismet_enabled,
      :container_registry_token_expire_delay,
      :default_artifacts_expire_in,
      :default_branch_protection,
      :default_group_visibility,
      :default_project_visibility,
      :default_projects_limit,
      :default_snippet_visibility,
      :domain_blacklist_enabled,
      :domain_blacklist_file,
      :domain_blacklist_raw,
      :domain_whitelist_raw,
      :email_author_in_body,
      :enabled_git_access_protocol,
      :gravatar_enabled,
      :help_page_text,
      :help_page_hide_commercial_content,
      :help_page_support_url,
      :home_page_url,
      :housekeeping_bitmaps_enabled,
      :housekeeping_enabled,
      :housekeeping_full_repack_period,
      :housekeeping_gc_period,
      :housekeeping_incremental_repack_period,
      :html_emails_enabled,
      :koding_enabled,
      :koding_url,
      :password_authentication_enabled,
      :plantuml_enabled,
      :plantuml_url,
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
      :performance_bar_allowed_group_id,
      :performance_bar_enabled,
      :recaptcha_enabled,
      :recaptcha_private_key,
      :recaptcha_site_key,
      :repository_checks_enabled,
      :require_two_factor_authentication,
      :session_expire_delay,
      :sign_in_text,
      :signup_enabled,
      :sentry_dsn,
      :sentry_enabled,
      :clientside_sentry_dsn,
      :clientside_sentry_enabled,
      :send_user_confirmation_email,
      :shared_runners_enabled,
      :shared_runners_text,
      :sidekiq_throttling_enabled,
      :sidekiq_throttling_factor,
      :two_factor_grace_period,
      :user_default_external,
      :user_oauth_applications,
      :unique_ips_limit_per_user,
      :unique_ips_limit_time_window,
      :unique_ips_limit_enabled,
      :version_check_enabled,
      :terminal_max_session_time,
      :polling_interval_multiplier,
      :prometheus_metrics_enabled,
      :usage_ping_enabled,

      disabled_oauth_sign_in_sources: [],
      import_sources: [],
      repository_storages: [],
      restricted_visibility_levels: [],
      sidekiq_throttling_queues: []
    ]
  end
end
