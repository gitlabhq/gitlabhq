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
        usage_data_json = JSON.pretty_generate(Gitlab::UsageData.data)

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
    @application_setting = ApplicationSetting.current
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
    params.delete(:domain_blacklist_raw) if params[:domain_blacklist_file]

    params.require(:application_setting).permit(
      visible_application_setting_attributes
    )
  end

  def visible_application_setting_attributes
    ApplicationSettingsHelper.visible_attributes + [
      :domain_blacklist_file,
      disabled_oauth_sign_in_sources: [],
      import_sources: [],
      repository_storages: [],
      restricted_visibility_levels: [],
      sidekiq_throttling_queues: []
    ]
  end
end
