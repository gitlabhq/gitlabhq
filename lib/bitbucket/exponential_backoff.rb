# frozen_string_literal: true

module Bitbucket
  module ExponentialBackoff
    extend ActiveSupport::Concern

    INITIAL_DELAY = 1.second
    EXPONENTIAL_BASE = 2
    MAX_RETRIES = 3

    RateLimitError = Class.new(StandardError)

    def retry_with_exponential_backoff(&block)
      run_retry_with_exponential_backoff(&block)
    end

    private

    def run_retry_with_exponential_backoff
      retries = 0
      delay = INITIAL_DELAY

      loop do
        return yield
      rescue OAuth2::Error, HTTParty::ResponseError => e
        retries, delay = handle_error(retries, delay, e.message)

        next
      end
    end

    def handle_error(retries, delay, error)
      retries += 1

      raise RateLimitError, "Maximum number of retries (#{MAX_RETRIES}) exceeded. #{error}" if retries >= MAX_RETRIES

      delay *= EXPONENTIAL_BASE * (1 + Random.rand)

      logger.info(message: "Retrying in #{delay} seconds due to #{error}")
      sleep delay

      [retries, delay]
    end
  end
end
