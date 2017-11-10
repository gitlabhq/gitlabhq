# frozen_string_literal: true

module Gitlab
  module GithubImport
    # Error that will be raised when we're about to reach (or have reached) the
    # GitHub API's rate limit.
    RateLimitError = Class.new(StandardError)
  end
end
