# frozen_string_literal: true

module API
  class ErrorTracking::ProjectSettings < ::API::Base
    before { authenticate! }

    feature_category :error_tracking
    urgency :low

    helpers do
      def project_setting
        @project_setting ||= user_project.error_tracking_setting
      end
    end

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize! :admin_operations, user_project

        not_found!('Error Tracking Setting') unless project_setting
      end

      desc 'Get error tracking settings for the project' do
        detail 'This feature was introduced in GitLab 12.7.'
        success Entities::ErrorTracking::ProjectSetting
      end

      get ':id/error_tracking/settings' do
        present project_setting, with: Entities::ErrorTracking::ProjectSetting
      end

      desc 'Enable or disable error tracking settings for the project' do
        detail 'This feature was introduced in GitLab 12.8.'
        success Entities::ErrorTracking::ProjectSetting
      end
      params do
        requires :active, type: Boolean, desc: 'Specifying whether to enable or disable error tracking settings', allow_blank: false
        optional :integrated, type: Boolean, desc: 'Specifying whether to enable or disable integrated error tracking'
      end

      patch ':id/error_tracking/settings/' do
        update_params = {
          error_tracking_setting_attributes: { enabled: params[:active] }
        }

        unless params[:integrated].nil?
          update_params[:error_tracking_setting_attributes][:integrated] = params[:integrated]
        end

        result = ::Projects::Operations::UpdateService.new(user_project, current_user, update_params).execute

        if result[:status] == :success
          present project_setting, with: Entities::ErrorTracking::ProjectSetting
        else
          result
        end
      end
    end
  end
end
