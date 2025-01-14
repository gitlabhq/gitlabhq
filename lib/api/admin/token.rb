# frozen_string_literal: true

module API
  module Admin
    class Token < ::API::Base
      feature_category :system_access
      AUDIT_SOURCE = :api_admin_token

      helpers do
        def identify_token(plaintext)
          token = ::Authn::AgnosticTokenIdentifier.token_for(plaintext, AUDIT_SOURCE)
          raise ArgumentError, 'Token type not supported.' if token.blank?

          token
        end
      end

      before do
        authenticated_as_admin!
      end

      rescue_from ArgumentError do |e|
        render_api_error!(e.message, :unprocessable_entity)
      end

      params do
        requires :token, type: String, desc: 'The token that information is requested about.'
      end
      namespace 'admin/token' do
        desc 'Get information about a token.' do
          detail 'This feature was introduced in GitLab 17.5.'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' },
            { code: 422, message: 'Unprocessable' }
          ]
          tags %w[admin]
          hidden true
        end
        post do
          identified_token = identify_token(params[:token])
          render_api_error!({ error: 'Not found' }, :not_found) if identified_token.revocable.nil?

          status :ok

          present identified_token.revocable, with: identified_token.present_with, current_user: current_user
        end

        desc 'Revoke a token.' do
          detail 'This feature was introduced in GitLab 17.7.'
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not Found' },
            { code: 422, message: 'Unprocessable' }
          ]
          tags %w[admin]
          hidden true
        end
        delete do
          if Feature.disabled?(:api_admin_token_revoke, current_user)
            render_api_error!("'api_admin_token_revoke' feature flag is disabled", :not_found)
          end

          identified_token = identify_token(params[:token])

          render_api_error!({ error: 'Not found' }, :not_found) if identified_token.revocable.nil?

          response = identified_token.revoke!(current_user)

          response.success? ? no_content! : render_api_error!({ error: response.message }, :bad_request)
        end
      end
    end
  end
end
