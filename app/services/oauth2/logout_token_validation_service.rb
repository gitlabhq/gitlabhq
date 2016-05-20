module Oauth2
  class LogoutTokenValidationService < ::BaseService
    attr_reader :status, :current_user

    def initialize(user, params={})
      if params && params[:state] && !params[:state].empty?
        oauth = Gitlab::Geo::OauthSession.new(state: params[:state])
        @access_token_string = oauth.extract_logout_token
      end
      @current_user = user
    end

    def execute
      return error('access token not found') unless access_token
      status = Oauth2::AccessTokenValidationService.validate(access_token)

      if status == Oauth2::AccessTokenValidationService::VALID
        user = User.find(access_token.resource_owner_id)

        if current_user == user
          success
        end
      else
        error(status)
      end
    end

    def access_token
      return unless @access_token_string && @access_token_string.is_utf8?

      @access_token ||= Doorkeeper::AccessToken.by_token(@access_token_string)
    end
  end
end
