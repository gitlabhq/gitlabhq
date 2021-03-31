# frozen_string_literal: true

# This patches https://github.com/ruby-json-schema/json-schema/blob/765e6d8fdbfdaca1a42fa743f4621e757f9f6a03/lib/json-schema/validator.rb
# to address https://github.com/ruby-json-schema/json-schema/issues/148.
require 'json-schema'

module JSON
  class Validator
    def initialize_data(data)
      if @options[:parse_data]
        if @options[:json]
          data = self.class.parse(data)
        elsif @options[:uri]
          json_uri = Util::URI.normalized_uri(data)
          data = self.class.parse(custom_open(json_uri))
        elsif data.is_a?(String)
          begin
            data = self.class.parse(data)
          rescue JSON::Schema::JsonParseError
            # Silently discard the error - use the data as-is
          end
        end
      end

      JSON::Schema.stringify(data)
    end
  end
end
