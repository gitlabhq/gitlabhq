# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass -- General utility
module Gitlab
  class HttpResponseParser < HTTParty::Parser
    # rubocop:disable Gitlab/Json -- Using JSON.parse for compatibility reasons
    def json
      log_and_raise_oversize_response! if oversize_response?

      JSON.parse(body, quirks_mode: true, allow_nan: true, max_nesting: max_json_depth)
    end
    # rubocop:enable Gitlab/Json

    def xml
      log_parse_method_called(:xml, (body.count('<') / 2) + body.count('='))

      super
    end

    def csv
      log_parse_method_called(:csv, body.count(",\n"))

      super
    end

    private

    def oversize_response?
      max_json_structural_chars > 0 && total_value_count_estimate > max_json_structural_chars
    end

    def log_and_raise_oversize_response!
      Gitlab::AppJsonLogger.error(
        message: 'Large HTTP JSON response',
        number_of_fields: total_value_count_estimate,
        caller: Gitlab::BacktraceCleaner.clean_backtrace(caller)
      )

      raise JSON::ParserError, 'JSON response exceeded the maximum number of objects'
    end

    def log_parse_method_called(parse_method, structural_element_count)
      Gitlab::AppJsonLogger.info(
        message: 'HttpResponseParser method called',
        parse_method: parse_method,
        structural_element_count: structural_element_count,
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

    def max_json_structural_chars
      Gitlab::CurrentSettings.max_http_response_json_structural_chars
    end

    def max_json_depth
      Gitlab::CurrentSettings.max_http_response_json_depth
    end
  end
end
# rubocop: enable Gitlab/NamespacedClass -- General utility
