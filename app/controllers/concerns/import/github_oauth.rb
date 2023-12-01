# frozen_string_literal: true

module Import
  module GithubOauth
    extend ActiveSupport::Concern

    OAuthConfigMissingError = Class.new(StandardError)

    included do
      rescue_from OAuthConfigMissingError, with: :missing_oauth_config
    end

    private

    def provider_auth
      return if session[access_token_key].present?

      go_to_provider_for_permissions unless ci_cd_only?
    end

    def ci_cd_only?
      %w[1 true].include?(params[:ci_cd_only])
    end

    def go_to_provider_for_permissions
      redirect_to authorize_url
    end

    def oauth_client
      raise OAuthConfigMissingError unless oauth_config

      oauth_client_from_config
    end

    def oauth_client_from_config
      @oauth_client_from_config ||= ::OAuth2::Client.new(
        oauth_config.app_id,
        oauth_config.app_secret,
        oauth_options.merge(ssl: { verify: oauth_config['verify_ssl'] })
      )
    end

    def oauth_config
      @oauth_config ||= Gitlab::Auth::OAuth::Provider.config_for('github')
    end

    def oauth_options
      return unless oauth_config

      oauth_config.dig('args', 'client_options').to_h.deep_symbolize_keys
    end

    def authorize_url
      state = SecureRandom.base64(64)
      session[auth_state_key] = state
      session[:auth_on_failure_path] = "#{new_project_path}#import_project"
      oauth_client.auth_code.authorize_url(
        redirect_uri: callback_import_url,
        # read:org only required for collaborator import, which is optional,
        # but at the time of this OAuth request we do not know which optional
        # configuration the user will select because the options are only shown
        # after authenticating
        scope: 'repo, read:org',
        state: state
      )
    end

    def get_token(code)
      oauth_client.auth_code.get_token(code).token
    end

    def missing_oauth_config
      session[access_token_key] = nil

      message = _('Missing OAuth configuration for GitHub.')

      respond_to do |format|
        format.json do
          render json: { errors: message }, status: :unauthorized
        end

        format.any do
          redirect_to new_import_url,
            alert: message
        end
      end
    end

    def callback_import_url
      public_send("users_import_#{provider_name}_callback_url", extra_import_params.merge({ namespace_id: params[:namespace_id] })) # rubocop:disable GitlabSecurity/PublicSend
    end

    def extra_import_params
      {}
    end
  end
end
