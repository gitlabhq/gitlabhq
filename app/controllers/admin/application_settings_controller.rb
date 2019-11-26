# frozen_string_literal: true

class Admin::ApplicationSettingsController < Admin::ApplicationController
  include InternalRedirect

  before_action :set_application_setting
  before_action :whitelist_query_limiting, only: [:usage_data]

  VALID_SETTING_PANELS = %w(general integrations repository
                            ci_cd reporting metrics_and_profiling
                            network preferences).freeze

  VALID_SETTING_PANELS.each do |action|
    define_method(action) { perform_update if submitted? }
  end

  def show
    render :general
  end

  def update
    perform_update
  end

  def usage_data
    respond_to do |format|
      format.html do
        usage_data_json = JSON.pretty_generate(Gitlab::UsageData.data)

        render html: Gitlab::Highlight.highlight('payload.json', usage_data_json, language: 'json')
      end
      format.json { render json: Gitlab::UsageData.to_json }
    end
  end

  def reset_registration_token
    @application_setting.reset_runners_registration_token!

    flash[:notice] = _('New runners registration token has been generated!')
    redirect_to admin_runners_path
  end

  def reset_health_check_token
    @application_setting.reset_health_check_access_token!
    flash[:notice] = _('New health check access token has been generated!')
    redirect_back_or_default
  end

  def clear_repository_check_states
    RepositoryCheck::ClearWorker.perform_async

    redirect_to(
      admin_application_settings_path,
      notice: _('Started asynchronous removal of all repository check states.')
    )
  end

  # Getting ToS url requires `directory` api call to Let's Encrypt
  # which could result in 500 error/slow rendering on settings page
  # Because of that we use separate controller action
  def lets_encrypt_terms_of_service
    redirect_to ::Gitlab::LetsEncrypt.terms_of_service_url
  end

  private

  def set_application_setting
    @application_setting = ApplicationSetting.current_without_cache
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-foss/issues/63107')
  end

  def application_setting_params
    params[:application_setting] ||= {}

    if params[:application_setting].key?(:enabled_oauth_sign_in_sources)
      enabled_oauth_sign_in_sources = params[:application_setting].delete(:enabled_oauth_sign_in_sources)
      enabled_oauth_sign_in_sources&.delete("")

      params[:application_setting][:disabled_oauth_sign_in_sources] =
        AuthHelper.button_based_providers.map(&:to_s) -
        Array(enabled_oauth_sign_in_sources)
    end

    params[:application_setting][:import_sources]&.delete("")
    params[:application_setting][:restricted_visibility_levels]&.delete("")
    params[:application_setting].delete(:elasticsearch_aws_secret_access_key) if params[:application_setting][:elasticsearch_aws_secret_access_key].blank?
    # TODO Remove domain_blacklist_raw in APIv5 (See https://gitlab.com/gitlab-org/gitlab-foss/issues/67204)
    params.delete(:domain_blacklist_raw) if params[:domain_blacklist_file]
    params.delete(:domain_blacklist_raw) if params[:domain_blacklist]
    params.delete(:domain_whitelist_raw) if params[:domain_whitelist]

    params.require(:application_setting).permit(
      visible_application_setting_attributes
    )
  end

  def recheck_user_consent?
    return false unless session[:ask_for_usage_stats_consent]
    return false unless params[:application_setting]

    params[:application_setting].key?(:usage_ping_enabled) || params[:application_setting].key?(:version_check_enabled)
  end

  def visible_application_setting_attributes
    [
      *::ApplicationSettingsHelper.visible_attributes,
      *::ApplicationSettingsHelper.external_authorization_service_attributes,
      :lets_encrypt_notification_email,
      :lets_encrypt_terms_of_service_accepted,
      :domain_blacklist_file,
      :raw_blob_request_limit,
      disabled_oauth_sign_in_sources: [],
      import_sources: [],
      repository_storages: [],
      restricted_visibility_levels: []
    ]
  end

  def submitted?
    request.patch?
  end

  def perform_update
    successful = ApplicationSettings::UpdateService
      .new(@application_setting, current_user, application_setting_params)
      .execute

    if recheck_user_consent?
      session[:ask_for_usage_stats_consent] = current_user.requires_usage_stats_consent?
    end

    redirect_path = referer_path(request) || admin_application_settings_path

    respond_to do |format|
      if successful
        format.json { head :ok }
        format.html { redirect_to redirect_path, notice: _('Application settings saved successfully') }
      else
        format.json { head :bad_request }
        format.html { render_update_error }
      end
    end
  end

  def render_update_error
    action = valid_setting_panels.include?(action_name) ? action_name : :general

    render action
  end

  # overridden in EE
  def valid_setting_panels
    VALID_SETTING_PANELS
  end
end

Admin::ApplicationSettingsController.prepend_if_ee('EE::Admin::ApplicationSettingsController')
