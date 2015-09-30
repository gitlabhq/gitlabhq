module Ci
  class Admin::ApplicationSettingsController < Ci::Admin::ApplicationController
    before_action :set_application_setting

    def show
    end

    def update
      if @application_setting.update_attributes(application_setting_params)
        redirect_to ci_admin_application_settings_path,
          notice: 'Application settings saved successfully'
      else
        render :show
      end
    end

    private

    def set_application_setting
      @application_setting = Ci::ApplicationSetting.current
      @application_setting ||= Ci::ApplicationSetting.create_from_defaults
    end

    def application_setting_params
      params.require(:application_setting).permit(
        :all_broken_builds,
        :add_pusher,
      )
    end
  end
end
