# frozen_string_literal: true

module BitbucketServer
  module RetryWithDelay
    extend ActiveSupport::Concern

    MAXIMUM_DELAY = 20

    def retry_with_delay(&block)
      run_retry_with_delay(&block)
    end

    private

    def run_retry_with_delay
      response = yield

      if response.code == 429 && response.headers.has_key?('retry-after')
        retry_after = response.headers['retry-after'].to_i

        if retry_after <= MAXIMUM_DELAY
          logger.info(message: "Retrying in #{retry_after} seconds due to 429 Too Many Requests")
          sleep retry_after

          response = yield
        end
      end

      response
    end
  end
end
