# frozen_string_literal: true

# Wrapper around a RequestAuthenticator to
# perform authorization of scopes. Access is limited to
# only those methods needed to validate that an API user
# has at least one permitted scope.
module Gitlab
  module Auth
    class ScopeValidator
      def initialize(api_user, request_authenticator)
        @api_user = api_user
        @request_authenticator = request_authenticator
      end

      def valid_for?(permitted)
        return true unless @api_user
        return true if permitted.none?

        scopes = permitted.map { |s| API::Scope.new(s) }
        @request_authenticator.valid_access_token?(scopes: scopes)
      end
    end
  end
end
