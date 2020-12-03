# frozen_string_literal: true

module DependencyProxy
  class AuthTokenService < DependencyProxy::BaseService
    attr_reader :token

    def initialize(token)
      @token = token
    end

    def execute
      JSONWebToken::HMACToken.decode(token, ::Auth::DependencyProxyAuthenticationService.secret).first
    end

    class << self
      def decoded_token_payload(token)
        self.new(token).execute
      end
    end
  end
end
