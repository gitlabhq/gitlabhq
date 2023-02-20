# frozen_string_literal: true

module Gitlab
  module APIAuthentication
    class TokenResolver
      include ActiveModel::Validations

      attr_reader :token_type

      validates :token_type, inclusion: {
        in: %i[
          personal_access_token_with_username
          job_token_with_username
          deploy_token_with_username
          personal_access_token
          job_token
          deploy_token
          personal_access_token_from_jwt
          deploy_token_from_jwt
          job_token_from_jwt
        ]
      }

      UsernameAndPassword = ::Gitlab::APIAuthentication::TokenLocator::UsernameAndPassword

      def initialize(token_type)
        @token_type = token_type
        validate!
      end

      # Existing behavior is known to be inconsistent across authentication
      # methods with regards to whether to silently ignore present but invalid
      # credentials or to raise an error/respond with 401.
      #
      # If a token can be located from the provided credentials, but the token
      # or credentials are in some way invalid, this implementation opts to
      # raise an error.
      #
      # For example, if the raw credentials include a username and password, and
      # a token is resolved from the password, but the username does not match
      # the token, an error will be raised.
      #
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/246569

      def resolve(raw)
        case @token_type
        when :personal_access_token
          resolve_personal_access_token raw

        when :job_token
          resolve_job_token raw

        when :deploy_token
          resolve_deploy_token raw

        when :personal_access_token_with_username
          resolve_personal_access_token_with_username raw

        when :job_token_with_username
          resolve_job_token_with_username raw

        when :deploy_token_with_username
          resolve_deploy_token_with_username raw

        when :personal_access_token_from_jwt
          resolve_personal_access_token_from_jwt raw

        when :deploy_token_from_jwt
          resolve_deploy_token_from_jwt raw

        when :job_token_from_jwt
          resolve_job_token_from_jwt raw
        end
      end

      private

      def resolve_personal_access_token_with_username(raw)
        raise ::Gitlab::Auth::UnauthorizedError unless raw.username

        with_personal_access_token(raw) do |pat|
          break unless pat

          # Ensure that the username matches the token. This check is a subtle
          # departure from the existing behavior of #find_personal_access_token_from_http_basic_auth.
          # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38627#note_435907856
          raise ::Gitlab::Auth::UnauthorizedError unless pat.user.username == raw.username

          pat
        end
      end

      def resolve_job_token_with_username(raw)
        # Only look for a job if the username is correct
        return if ::Gitlab::Auth::CI_JOB_USER != raw.username

        with_job_token(raw) do |job|
          job
        end
      end

      def resolve_deploy_token_with_username(raw)
        with_deploy_token(raw) do |token|
          break unless token

          # Ensure that the username matches the token. This check is a subtle
          # departure from the existing behavior of #deploy_token_from_request.
          # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38627#note_474826205
          raise ::Gitlab::Auth::UnauthorizedError unless token.username == raw.username

          token
        end
      end

      def resolve_personal_access_token(raw)
        with_personal_access_token(raw) do |pat|
          pat
        end
      end

      def resolve_job_token(raw)
        with_job_token(raw) do |job|
          job
        end
      end

      def resolve_deploy_token(raw)
        with_deploy_token(raw) do |token|
          token
        end
      end

      def resolve_personal_access_token_from_jwt(raw)
        with_jwt_token(raw) do |jwt_token|
          break unless jwt_token['token'].is_a?(Integer)

          pat = ::PersonalAccessToken.find(jwt_token['token'])
          break unless pat

          pat
        end
      end

      def resolve_deploy_token_from_jwt(raw)
        with_jwt_token(raw) do |jwt_token|
          break unless jwt_token['token'].is_a?(String)

          resolve_deploy_token(UsernameAndPassword.new(nil, jwt_token['token']))
        end
      end

      def resolve_job_token_from_jwt(raw)
        with_jwt_token(raw) do |jwt_token|
          break unless jwt_token['token'].is_a?(String)

          resolve_job_token(UsernameAndPassword.new(nil, jwt_token['token']))
        end
      end

      def with_personal_access_token(raw, &block)
        pat = ::PersonalAccessToken.find_by_token(raw.password)
        return unless pat

        yield(pat)
      end

      def with_deploy_token(raw, &block)
        unless Gitlab::ExternalAuthorization.allow_deploy_tokens_and_deploy_keys?
          raise ::Gitlab::Auth::UnauthorizedError
        end

        token = ::DeployToken.active.find_by_token(raw.password)
        return unless token

        yield(token)
      end

      def with_job_token(raw, &block)
        job = ::Ci::AuthJobFinder.new(token: raw.password).execute
        raise ::Gitlab::Auth::UnauthorizedError unless job

        yield(job)
      end

      def with_jwt_token(raw, &block)
        jwt_token = ::Gitlab::JWTToken.decode(raw.password)
        raise ::Gitlab::Auth::UnauthorizedError unless jwt_token

        yield(jwt_token)
      end
    end
  end
end
