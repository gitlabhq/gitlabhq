# frozen_string_literal: true

module API
  class ErrorTracking::ProjectSettings < ::API::Base
    before { authenticate! }

    ERROR_TRACKING_PROJECT_SETTINGS_TAGS = %w[error_tracking_project_settings].freeze

    feature_category :observability
    urgency :low

    helpers do
      def project_setting
        @project_setting ||= user_project.error_tracking_setting
      end
    end

    params do
      requires :id, types: [String, Integer],
        desc: 'The ID or URL-encoded path of the project owned by the authenticated user'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        authorize! :admin_operations, user_project
      end

      desc 'Get Error Tracking settings' do
        detail 'Get error tracking settings for the project. This feature was introduced in GitLab 12.7.'
        success Entities::ErrorTracking::ProjectSetting
        tags ERROR_TRACKING_PROJECT_SETTINGS_TAGS
      end

      get ':id/error_tracking/settings' do
        not_found!('Error Tracking Setting') unless project_setting
        present project_setting, with: Entities::ErrorTracking::ProjectSetting
      end

      desc 'Enable or disable the Error Tracking project settings' do
        detail 'The API allows you to enable or disable the Error Tracking settings for a project.'\
          'Only for users with the Maintainer role for the project.'
        success Entities::ErrorTracking::ProjectSetting
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ERROR_TRACKING_PROJECT_SETTINGS_TAGS
      end
      params do
        requires :active,
          type: Boolean,
          desc: 'Pass true to enable the already configured Error Tracking settings or false to disable it.',
          allow_blank: false
        optional :integrated,
          type: Boolean,
          desc: 'Pass true to enable the integrated Error Tracking backend. Available in GitLab 14.2 and later.'
      end

      patch ':id/error_tracking/settings/' do
        not_found!('Error Tracking Setting') unless project_setting
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

      desc 'Update Error Tracking project settings. Available in GitLab 15.10 and later.' do
        detail 'Update Error Tracking settings for a project. ' \
               'Only for users with Maintainer role for the project.'
        success Entities::ErrorTracking::ProjectSetting
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags ERROR_TRACKING_PROJECT_SETTINGS_TAGS
      end
      params do
        requires :active, type: Boolean,
          desc: 'Pass true to enable the configured Error Tracking settings or false to disable it.',
          allow_blank: false
        requires :integrated,
          type: Boolean,
          desc: 'Pass true to enable the integrated Error Tracking backend.'
      end

      put ':id/error_tracking/settings' do
        not_found! unless Feature.enabled?(:integrated_error_tracking, user_project)
        update_params = {
          error_tracking_setting_attributes: { enabled: params[:active] }
        }

        update_params[:error_tracking_setting_attributes][:integrated] = params[:integrated]

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
