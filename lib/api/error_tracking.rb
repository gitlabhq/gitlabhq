# frozen_string_literal: true

module API
  class ErrorTracking < ::API::Base
    before { authenticate! }

    feature_category :error_tracking

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get error tracking settings for the project' do
        detail 'This feature was introduced in GitLab 12.7.'
        success Entities::ErrorTracking::ProjectSetting
      end

      get ':id/error_tracking/settings' do
        authorize! :admin_operations, user_project

        setting = user_project.error_tracking_setting

        not_found!('Error Tracking Setting') unless setting

        present setting, with: Entities::ErrorTracking::ProjectSetting
      end

      desc 'Enable or disable error tracking settings for the project' do
        detail 'This feature was introduced in GitLab 12.8.'
        success Entities::ErrorTracking::ProjectSetting
      end
      params do
        requires :active, type: Boolean, desc: 'Specifying whether to enable or disable error tracking settings', allow_blank: false
      end

      patch ':id/error_tracking/settings/' do
        authorize! :admin_operations, user_project

        setting = user_project.error_tracking_setting

        not_found!('Error Tracking Setting') unless setting

        update_params = {
          error_tracking_setting_attributes: { enabled: params[:active] }
        }

        result = ::Projects::Operations::UpdateService.new(user_project, current_user, update_params).execute

        if result[:status] == :success
          present setting, with: Entities::ErrorTracking::ProjectSetting
        else
          result
        end
      end
    end
  end
end
