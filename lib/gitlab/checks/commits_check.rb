# frozen_string_literal: true

module Gitlab
  module Checks
    class CommitsCheck < ::Gitlab::Checks::BaseSingleChecker
      INVALID_AUTHOR_FOR_SIGNED_COMMITS = 'For signed Web commits, the commit must be equal to the author'
      LOG_MESSAGE = 'Checking if commits authors are valid...'

      def validate!
        return if deletion?

        logger.log_timed(LOG_MESSAGE) do
          commits.each do |commit|
            check_signed_commit_authorship!(commit)
          end
        end
      end

      private

      def check_signed_commit_authorship!(commit)
        return unless signed_by_gitlab?(commit)

        return if commit.author == user_access.user

        raise ::Gitlab::GitAccess::ForbiddenError, INVALID_AUTHOR_FOR_SIGNED_COMMITS
      end
    end
  end
end
