# frozen_string_literal: true

class Admin::ApplicationSettingsController < Admin::ApplicationController
  include InternalRedirect
  include IntegrationsHelper

  # NOTE: Use @application_setting in this controller when you need to access
  # application_settings after it has been modified. This is because the
  # ApplicationSetting model uses Gitlab::ProcessMemoryCache for caching and the
  # cache might be stale immediately after an update.
  # https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/30233
  before_action :set_application_setting, except: :integrations

  before_action :disable_query_limiting, only: [:usage_data]

  feature_category :not_owned, [
                     :general, :reporting, :metrics_and_profiling, :network,
                     :preferences, :update, :reset_health_check_token
                   ]

  feature_category :metrics, [
                     :create_self_monitoring_project,
                     :status_create_self_monitoring_project,
                     :delete_self_monitoring_project,
                     :status_delete_self_monitoring_project
                   ]

  feature_category :source_code_management, [:repository, :clear_repository_check_states]
  feature_category :continuous_integration, [:ci_cd, :reset_registration_token]
  feature_category :service_ping, [:usage_data]
  feature_category :integrations, [:integrations]
  feature_category :pages, [:lets_encrypt_terms_of_service]

  VALID_SETTING_PANELS = %w(general repository
                            ci_cd reporting metrics_and_profiling
                            network preferences).freeze

  # The current size of a sidekiq job's jid is 24 characters. The size of the
  # jid is an internal detail of Sidekiq, and they do not guarantee that it'll
  # stay the same. We chose 50 to give us room in case the size of the jid
  # increases. The jid is alphanumeric, so 50 is very generous. There is a spec
  # that ensures that the constant value is more than the size of an actual jid.
  PARAM_JOB_ID_MAX_SIZE = 50

  VALID_SETTING_PANELS.each do |action|
    define_method(action) { perform_update if submitted? }
  end

  def integrations
    return not_found unless instance_level_integrations?

    @integrations = Integration.find_or_initialize_all_non_project_specific(Integration.for_instance).sort_by(&:title)
  end

  def update
    perform_update
  end

  def usage_data
    respond_to do |format|
      format.html do
        usage_data_json = Gitlab::Json.pretty_generate(Gitlab::UsageData.data)

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
    RepositoryCheck::ClearWorker.perform_async # rubocop:disable CodeReuse/Worker

    redirect_to(
      general_admin_application_settings_path,
      notice: _('Started asynchronous removal of all repository check states.')
    )
  end

  # Getting ToS url requires `directory` api call to Let's Encrypt
  # which could result in 500 error/slow rendering on settings page
  # Because of that we use separate controller action
  def lets_encrypt_terms_of_service
    redirect_to ::Gitlab::LetsEncrypt.terms_of_service_url
  end

  # Specs are in spec/requests/self_monitoring_project_spec.rb
  def create_self_monitoring_project
    job_id = SelfMonitoringProjectCreateWorker.perform_async # rubocop:disable CodeReuse/Worker

    render status: :accepted, json: {
      job_id: job_id,
      monitor_status: status_create_self_monitoring_project_admin_application_settings_path
    }
  end

  # Specs are in spec/requests/self_monitoring_project_spec.rb
  def status_create_self_monitoring_project
    job_id = params[:job_id].to_s

    unless job_id.length <= PARAM_JOB_ID_MAX_SIZE
      return render status: :bad_request, json: {
        message: _('Parameter "job_id" cannot exceed length of %{job_id_max_size}' %
          { job_id_max_size: PARAM_JOB_ID_MAX_SIZE })
      }
    end

    if SelfMonitoringProjectCreateWorker.in_progress?(job_id) # rubocop:disable CodeReuse/Worker
      ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

      return render status: :accepted, json: {
        message: _('Job to create self-monitoring project is in progress')
      }
    end

    if @application_setting.self_monitoring_project_id.present?
      return render status: :ok, json: self_monitoring_data
    end

    render status: :bad_request, json: {
      message: _('Self-monitoring project does not exist. Please check logs ' \
        'for any error messages')
    }
  end

  # Specs are in spec/requests/self_monitoring_project_spec.rb
  def delete_self_monitoring_project
    job_id = SelfMonitoringProjectDeleteWorker.perform_async # rubocop:disable CodeReuse/Worker

    render status: :accepted, json: {
      job_id: job_id,
      monitor_status: status_delete_self_monitoring_project_admin_application_settings_path
    }
  end

  # Specs are in spec/requests/self_monitoring_project_spec.rb
  def status_delete_self_monitoring_project
    job_id = params[:job_id].to_s

    unless job_id.length <= PARAM_JOB_ID_MAX_SIZE
      return render status: :bad_request, json: {
        message: _('Parameter "job_id" cannot exceed length of %{job_id_max_size}' %
          { job_id_max_size: PARAM_JOB_ID_MAX_SIZE })
      }
    end

    if SelfMonitoringProjectDeleteWorker.in_progress?(job_id) # rubocop:disable CodeReuse/Worker
      ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

      return render status: :accepted, json: {
        message: _('Job to delete self-monitoring project is in progress')
      }
    end

    if @application_setting.self_monitoring_project_id.nil?
      return render status: :ok, json: {
        message: _('Self-monitoring project has been successfully deleted')
      }
    end

    render status: :bad_request, json: {
      message: _('Self-monitoring project was not deleted. Please check logs ' \
        'for any error messages')
    }
  end

  private

  def self_monitoring_data
    {
      project_id: @application_setting.self_monitoring_project_id,
      project_full_path: @application_setting.self_monitoring_project&.full_path
    }
  end

  def set_application_setting
    @application_setting = ApplicationSetting.current_without_cache
    @plans = Plan.all
  end

  def disable_query_limiting
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/29418')
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
    params[:application_setting][:valid_runner_registrars]&.delete("")
    params[:application_setting][:restricted_visibility_levels]&.delete("")

    if params[:application_setting].key?(:required_instance_ci_template)
      params[:application_setting][:required_instance_ci_template] = nil if params[:application_setting][:required_instance_ci_template].empty?
    end

    remove_blank_params_for!(:elasticsearch_aws_secret_access_key, :eks_secret_access_key)

    # TODO Remove domain_denylist_raw in APIv5 (See https://gitlab.com/gitlab-org/gitlab-foss/issues/67204)
    params.delete(:domain_denylist_raw) if params[:domain_denylist_file]
    params.delete(:domain_denylist_raw) if params[:domain_denylist]
    params.delete(:domain_allowlist_raw) if params[:domain_allowlist]

    params[:application_setting].permit(visible_application_setting_attributes)
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
      *ApplicationSetting.kroki_formats_attributes.keys.map { |key| "kroki_formats_#{key}".to_sym },
      :lets_encrypt_notification_email,
      :lets_encrypt_terms_of_service_accepted,
      :domain_denylist_file,
      :raw_blob_request_limit,
      :issues_create_limit,
      :notes_create_limit,
      :default_branch_name,
      disabled_oauth_sign_in_sources: [],
      import_sources: [],
      restricted_visibility_levels: [],
      repository_storages_weighted: {},
      valid_runner_registrars: []
    ]
  end

  def submitted?
    request.patch?
  end

  def perform_update
    successful = ::ApplicationSettings::UpdateService
      .new(@application_setting, current_user, application_setting_params)
      .execute

    if recheck_user_consent?
      session[:ask_for_usage_stats_consent] = current_user.requires_usage_stats_consent?
    end

    redirect_path = referer_path(request) || general_admin_application_settings_path

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

    flash[:alert] = _('Application settings update failed')

    render action
  end

  def remove_blank_params_for!(*keys)
    params[:application_setting].delete_if { |setting, value| setting.to_sym.in?(keys) && value.blank? }
  end

  # overridden in EE
  def valid_setting_panels
    VALID_SETTING_PANELS
  end
end

Admin::ApplicationSettingsController.prepend_mod_with('Admin::ApplicationSettingsController')
