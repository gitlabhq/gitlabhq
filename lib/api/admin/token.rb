# frozen_string_literal: true

module API
  module Admin
    class Token < ::API::Base
      feature_category :system_access

      helpers do
        def identify_token(token)
          if token.start_with?(Gitlab::CurrentSettings.current_application_settings.personal_access_token_prefix,
            ApplicationSetting.defaults[:personal_access_token_prefix])
            handle_personal_access_token(token)
          elsif token.start_with?(DeployToken::DEPLOY_TOKEN_PREFIX)
            handle_deploy_token(token)
          else
            raise ArgumentError, 'Token type not supported.'
          end
        end

        def handle_personal_access_token(token)
          PersonalAccessToken.find_by_token(token)
        end

        def handle_deploy_token(token)
          DeployToken.find_by_token(token)
        end
      end

      before do
        authenticated_as_admin!

        if Feature.disabled?(:admin_agnostic_token_finder, current_user)
          render_api_error!("'admin_agnostic_token_finder' feature flag is disabled", :not_found)
        end
      end

      rescue_from ArgumentError do |e|
        render_api_error!(e.message, :unprocessable_entity)
      end

      namespace 'admin' do
        desc 'Get information about a token.' do
          detail 'This feature was introduced in GitLab 17.5.
                  This feature is gated by the :admin_agnostic_token_finder feature flag.'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' },
            { code: 422, message: 'Unprocessable' }
          ]
          tags %w[admin]
          hidden true
        end
        params do
          requires :token, type: String, desc: 'The token that information is requested about.'
        end
        post 'token' do
          identified_token = identify_token(params[:token])

          render_api_error!({ error: 'Not found' }, :not_found) if identified_token.nil?

          status :ok

          present identified_token, with: "API::Entities::#{identified_token.class.name}".constantize
        end
      end
    end
  end
end
