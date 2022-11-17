# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    # Sidekiq retry error that won't be reported to Sentry
    # Use it when a job retry is an expected behavior
    RetryError = Class.new(StandardError)
  end
end
