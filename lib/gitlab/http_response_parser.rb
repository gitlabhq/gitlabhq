# frozen_string_literal: true

# rubocop: disable Gitlab/NamespacedClass -- General utility
module Gitlab
  class HttpResponseParser < HTTParty::Parser
    # rubocop:disable Gitlab/Json -- Using JSON.parse for compatibility reasons
    def json
      validate_response_size!(:json)

      JSON.parse(body, quirks_mode: true, allow_nan: true, max_nesting: max_json_depth)
    end
    # rubocop:enable Gitlab/Json

    def xml
      validate_response_size!(:xml)

      super
    end

    def csv
      validate_response_size!(:csv)

      super
    end

    private

    def validate_response_size!(type)
      return unless oversize_response?(type)

      log_and_raise_oversize_response!(type)
    end

    def oversize_response?(type)
      max_chars = max_structural_chars_for(type)
      return false if max_chars <= 0

      total_structural_chars_for(type) > max_chars
    end

    def log_and_raise_oversize_response!(type)
      structural_chars = total_structural_chars_for(type)

      Gitlab::AppJsonLogger.error(
        message: "Large HTTP #{type.to_s.upcase} response",
        structural_chars: structural_chars,
        caller: Gitlab::BacktraceCleaner.clean_backtrace(caller)
      )

      raise oversize_response_error_for(type)
    end

    def total_structural_chars_for(type)
      case type
      when :json then estimate_total_json_structural_chars
      when :xml then estimate_total_xml_structural_chars
      when :csv then estimate_total_csv_structural_chars
      else
        raise ArgumentError, "Unsupported type: #{type}"
      end
    end

    def max_structural_chars_for(type)
      case type
      when :json then Gitlab::CurrentSettings.max_http_response_json_structural_chars
      when :xml then Gitlab::CurrentSettings.max_http_response_xml_structural_chars
      when :csv then Gitlab::CurrentSettings.max_http_response_csv_structural_chars
      else
        raise ArgumentError, "Unsupported type: #{type}"
      end
    end

    def oversize_response_error_for(type)
      case type
      when :json then JSON::ParserError.new('JSON response exceeded the maximum number of objects')
      when :xml then MultiXml::ParseError.new('XML response exceeded the maximum number of objects')
      when :csv then CSV::MalformedCSVError.new('CSV response exceeded the maximum number of objects', 1)
      else
        raise ArgumentError, "Unsupported type: #{type}"
      end
    end

    # Estimates the total number of values in the JSON response by counting:
    # : => Number of key-value pairs
    # , => Number of elements in arrays (off by one since [1, 2, 3] has just 2 commas)
    # [ => Number of arrays
    # { => Number of objects
    def estimate_total_json_structural_chars
      @estimate_total_json_structural_chars ||= body.count('{[,:')
    end

    # Estimates the total number of elements in the XML response by counting:
    # < => Number of opening tags (divided by 2 to account for closing tags)
    # = => Number of attributes
    def estimate_total_xml_structural_chars
      @estimate_total_xml_structural_chars ||= (body.count('<') / 2) + body.count('=')
    end

    # Estimates the total number of elements in the CSV response by counting:
    # , => Number of comma separators
    # \t => Number of tab separators
    # ; => Number of semicolon separators
    # \n => Number of row separators
    def estimate_total_csv_structural_chars
      @estimate_total_csv_structural_chars ||= body.count(",\t;\n")
    end

    def max_json_depth
      Gitlab::CurrentSettings.max_http_response_json_depth
    end
  end
end
# rubocop: enable Gitlab/NamespacedClass -- General utility
