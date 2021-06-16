# frozen_string_literal: true

module Gitlab
  module Checks
    class PushFileCountCheck < BaseSingleChecker
      attr_reader :repository, :newrev, :limit, :logger

      LOG_MESSAGES = {
        diff_content_check: "Validating diff contents being single file..."
      }.freeze

      ERROR_MESSAGES = {
        upper_limit: "The repository can contain at most %{limit} file(s).",
        lower_limit: "The repository must contain at least 1 file."
      }.freeze

      def initialize(change, repository:, limit:, logger:)
        @repository = repository
        @newrev = change[:newrev]
        @limit = limit
        @logger = logger
      end

      def validate!
        file_count = repository.ls_files(newrev).size

        if file_count > limit
          raise ::Gitlab::GitAccess::ForbiddenError, ERROR_MESSAGES[:upper_limit] % { limit: limit }
        end

        if file_count == 0
          raise ::Gitlab::GitAccess::ForbiddenError, ERROR_MESSAGES[:lower_limit]
        end
      end
    end
  end
end
