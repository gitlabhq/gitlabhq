# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass -- General utility
module Gitlab
  class HttpResponseParser < HTTParty::Parser
    def json
      log_oversize_response if oversize_response?
      super
    end

    private

    def oversize_response?
      oversize_threshold > 0 && total_value_count_estimate > oversize_threshold
    end

    def log_oversize_response
      Gitlab::AppJsonLogger.info(
        message: 'Large HTTP JSON response',
        number_of_fields: total_value_count_estimate,
        caller: Gitlab::BacktraceCleaner.clean_backtrace(caller)
      )
    end

    # Estimates the total number of values in the JSON response by counting:
    # : => Number of key-value pairs
    # , => Number of elements in arrays (off by one since [1, 2, 3] has just 2 commas)
    # [ => Number of arrays
    # { => Number of objects
    def total_value_count_estimate
      @total_value_count_estimate ||= body.count('{[,:')
    end

    def oversize_threshold
      @oversize_threshold ||= ENV['GITLAB_JSON_SIZE_THRESHOLD'].to_i
    end
  end
end
# rubocop: enable Gitlab/NamespacedClass -- General utility
