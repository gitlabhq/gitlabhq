# frozen_string_literal: true

module API
  module Internal
    class ErrorTracking < ::API::Base
      GITLAB_ERROR_TRACKING_TOKEN_HEADER = "Gitlab-Error-Tracking-Token"

      feature_category :observability

      helpers do
        def verify_error_tracking_token!
          input = params['error_tracking_token']

          if headers.key?(GITLAB_ERROR_TRACKING_TOKEN_HEADER)
            input ||= headers[GITLAB_ERROR_TRACKING_TOKEN_HEADER]
          end

          input&.chomp!

          unauthorized! unless Devise.secure_compare(error_tracking_token, input)
        end

        def error_tracking_token
          Gitlab::CurrentSettings.error_tracking_access_token
        end

        def error_tracking_enabled?
          Gitlab::CurrentSettings.error_tracking_enabled
        end
      end

      namespace 'internal' do
        namespace 'error_tracking' do
          before do
            verify_error_tracking_token!
          end

          post '/allowed', urgency: :high do
            public_key = params[:public_key]
            project_id = params[:project_id]

            unprocessable_entity! if public_key.blank? || project_id.blank?

            project = Project.find(project_id)
            enabled = error_tracking_enabled? &&
              Feature.enabled?(:gitlab_error_tracking, project) &&
              ::ErrorTracking::ClientKey.enabled_key_for(project_id, public_key).exists?

            status 200
            { enabled: enabled }
          end
        end
      end
    end
  end
end
