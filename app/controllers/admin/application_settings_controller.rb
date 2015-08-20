class Admin::ApplicationSettingsController < Admin::ApplicationController
  before_action :set_application_setting

  def show
  end

  def update
    if @application_setting.update_attributes(application_setting_params)
      redirect_to admin_application_settings_path,
        notice: 'Application settings saved successfully'
    else
      render :show
    end
  end

  private

  def set_application_setting
    @application_setting = ApplicationSetting.current
  end

  def application_setting_params
    restricted_levels = params[:application_setting][:restricted_visibility_levels]
    if restricted_levels.nil?
      params[:application_setting][:restricted_visibility_levels] = []
    else
      restricted_levels.map! do |level|
        level.to_i
      end
    end

    import_sources = params[:application_setting][:import_sources]
    if import_sources.nil?
      params[:application_setting][:import_sources] = []
    else
      import_sources.map! do |source|
        source.to_str
      end
    end

    params.require(:application_setting).permit(
      :default_projects_limit,
      :default_branch_protection,
      :signup_enabled,
      :signin_enabled,
      :gravatar_enabled,
      :twitter_sharing_enabled,
      :sign_in_text,
      :home_page_url,
      :after_sign_out_path,
      :max_attachment_size,
      :session_expire_delay,
      :default_project_visibility,
      :default_snippet_visibility,
      :restricted_signup_domains_raw,
      :version_check_enabled,
      :user_oauth_applications,
      restricted_visibility_levels: [],
      import_sources: []
    )
  end
end
