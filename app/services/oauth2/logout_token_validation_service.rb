module Oauth2
  class LogoutTokenValidationService < ::BaseService
    attr_reader :status

    def initialize(user, params = {})
      @params = params
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
      @access_token ||= begin
        return unless  params[:state] && !params[:state].empty?

        oauth_session = Gitlab::Geo::OauthSession.new(state: params[:state])

        logout_token = oauth_session.extract_logout_token
        return unless logout_token && logout_token.is_utf8?

        Doorkeeper::AccessToken.by_token(logout_token)
      end

    end
  end
end
