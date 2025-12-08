# frozen_string_literal: true

module Gitlab
  module GithubImport
    # Error that will be raised when we're about to reach (or have reached) the
    # GitHub API's rate limit.
    class RateLimitError < StandardError
      attr_reader :reset_in

      def initialize(message = nil, reset_in = nil)
        @reset_in = reset_in
        super(message)
      end
    end
  end
end
