module Oauth2
  class LogoutTokenValidationService
    attr_reader :status, :current_user

    def initialize(user, access_token_string)
      @access_token_string = access_token_string
      @current_user = user
    end

    def validate
      return false unless access_token

      @status = Oauth2::AccessTokenValidationService.validate(access_token)

      if @status == Oauth2::AccessTokenValidationService::VALID
        user = User.find(access_token.resource_owner_id)

        if current_user == user
          true
        end
      else
        false
      end
    end

    def access_token
      return unless @access_token_string && @access_token_string.is_utf8?

      @access_token ||= Doorkeeper::AccessToken.by_token(@access_token_string)
    end
  end
end
