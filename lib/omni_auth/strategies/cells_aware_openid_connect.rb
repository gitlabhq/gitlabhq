# frozen_string_literal: true

require 'omniauth_openid_connect'

# rubocop:disable Gitlab/BoundedContexts -- OmniAuth is external middleware, not a GitLab bounded context
module OmniAuth
  module Strategies
    # Custom OpenID Connect strategy for GitLab Cells architecture
    class CellsAwareOpenidConnect < OpenIDConnect
      # Override user_info method to handle IAM authentication service limitations
      # This is overridden from https://github.com/omniauth/omniauth_openid_connect/blob/master/lib/omniauth/strategies/openid_connect.rb#L263C6-L273C10
      # We skip the OIDC userinfo endpoint call and directly use the ID token for user information
      # when the userinfo endpoint is not available in the IAM authentication service
      def user_info
        return @user_info if @user_info

        if access_token.id_token
          decoded = decode_id_token(access_token.id_token).raw_attributes

          @user_info = ::OpenIDConnect::ResponseObject::UserInfo.new decoded
        else
          @user_info = access_token.userinfo!
        end
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
