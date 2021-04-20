# frozen_string_literal: true

module API
  module Helpers
    module Authentication
      extend ActiveSupport::Concern

      class_methods do
        def authenticate_with(&block)
          strategies = ::Gitlab::APIAuthentication::Builder.new.build(&block)
          namespace_inheritable :authentication, strategies
        end
      end

      included do
        helpers ::Gitlab::Utils::StrongMemoize

        helpers do
          def token_from_namespace_inheritable
            strong_memoize(:token_from_namespace_inheritable) do
              strategies = namespace_inheritable(:authentication)
              next unless strategies&.any?

              # Extract credentials from the request
              found = strategies.to_h { |location, _| [location, ::Gitlab::APIAuthentication::TokenLocator.new(location).extract(current_request)] }
              found.filter! { |location, raw| raw }
              next unless found.any?

              # Specifying multiple credentials is an error
              # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38627#note_475984136
              bad_request!('Found more than one set of credentials') if found.size > 1

              location, raw = found.first
              find_token_from_raw_credentials(strategies[location], raw)
            end

          rescue ::Gitlab::Auth::UnauthorizedError
            # TODO: this should be rescued and converted by the exception handling middleware
            # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38627#note_475174516
            unauthorized!
          end

          def access_token_from_namespace_inheritable
            token = token_from_namespace_inheritable
            token if token.is_a? PersonalAccessToken
          end

          def user_from_namespace_inheritable
            token = token_from_namespace_inheritable
            return token if token.is_a? DeployToken

            token&.user
          end

          def ci_build_from_namespace_inheritable
            token = token_from_namespace_inheritable
            token if token.is_a?(::Ci::Build)
          end

          private

          def find_token_from_raw_credentials(token_types, raw)
            token_types.each do |token_type|
              # Resolve a token from the raw credentials
              token = ::Gitlab::APIAuthentication::TokenResolver.new(token_type).resolve(raw)
              return token if token
            end

            # If a request provides credentials via an allowed transport, the
            # credentials must be valid. If we reach this point, the credentials
            # must not be valid credentials of an allowed type.
            raise ::Gitlab::Auth::UnauthorizedError
          end
        end
      end
    end
  end
end
