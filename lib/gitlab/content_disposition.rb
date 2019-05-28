# frozen_string_literal: true
# This ports ActionDispatch::Http::ContentDisposition (https://github.com/rails/rails/pull/33829,
# which will be available in Rails 6.
module Gitlab
  class ContentDisposition # :nodoc:
    # Make sure we remove this patch starting with Rails 6.0.
    if Rails.version.start_with?('6.0')
      raise <<~MSG
        Please remove this file and use `ActionDispatch::Http::ContentDisposition` instead.
      MSG
    end

    def self.format(disposition:, filename:)
      new(disposition: disposition, filename: filename).to_s
    end

    attr_reader :disposition, :filename

    def initialize(disposition:, filename:)
      @disposition = disposition
      @filename = filename
    end

    # rubocop:disable Style/VariableInterpolation
    TRADITIONAL_ESCAPED_CHAR = /[^ A-Za-z0-9!#$+.^_`|~-]/.freeze

    def ascii_filename
      'filename="' + percent_escape(::I18n.transliterate(filename), TRADITIONAL_ESCAPED_CHAR) + '"'
    end

    RFC_5987_ESCAPED_CHAR = /[^A-Za-z0-9!#$&+.^_`|~-]/.freeze
    # rubocop:enable Style/VariableInterpolation

    def utf8_filename
      "filename*=UTF-8''" + percent_escape(filename, RFC_5987_ESCAPED_CHAR)
    end

    def to_s
      if filename
        "#{disposition}; #{ascii_filename}; #{utf8_filename}"
      else
        "#{disposition}"
      end
    end

    private

    def percent_escape(string, pattern)
      string.gsub(pattern) do |char|
        char.bytes.map { |byte| "%%%02X" % byte }.join
      end
    end
  end
end
