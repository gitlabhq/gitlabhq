# frozen_string_literal: true

module API
  class ErrorTracking < Grape::API
    before { authenticate! }

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
    end
  end
end
