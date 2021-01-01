# frozen_string_literal: true

module Gitlab
  module APIAuthentication
    class TokenResolver
      include ActiveModel::Validations

      attr_reader :token_type

      validates :token_type, inclusion: { in: %i[personal_access_token job_token deploy_token] }

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
        end
      end

      private

      def resolve_personal_access_token(raw)
        # Check if the password is a personal access token
        pat = ::PersonalAccessToken.find_by_token(raw.password)
        return unless pat

        # Ensure that the username matches the token. This check is a subtle
        # departure from the existing behavior of #find_personal_access_token_from_http_basic_auth.
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38627#note_435907856
        raise ::Gitlab::Auth::UnauthorizedError unless pat.user.username == raw.username

        pat
      end

      def resolve_job_token(raw)
        # Only look for a job if the username is correct
        return if ::Gitlab::Auth::CI_JOB_USER != raw.username

        job = ::Ci::AuthJobFinder.new(token: raw.password).execute

        # Actively reject credentials with the username `gitlab-ci-token` if
        # the password is not a valid job token. This replicates existing
        # behavior of #find_user_from_job_token.
        raise ::Gitlab::Auth::UnauthorizedError unless job

        job
      end

      def resolve_deploy_token(raw)
        # Check if the password is a deploy token
        token = ::DeployToken.active.find_by_token(raw.password)
        return unless token

        # Ensure that the username matches the token. This check is a subtle
        # departure from the existing behavior of #deploy_token_from_request.
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38627#note_474826205
        raise ::Gitlab::Auth::UnauthorizedError unless token.username == raw.username

        token
      end
    end
  end
end
