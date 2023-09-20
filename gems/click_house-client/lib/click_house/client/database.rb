# frozen_string_literal: true

module ClickHouse
  module Client
    class Database
      attr_reader :database

      def initialize(database:, url:, username:, password:, variables: {})
        @database = database
        @url = url
        @username = username
        @password = password
        @variables = {
          database: database,
          enable_http_compression: 1 # enable HTTP compression by default
        }.merge(variables).freeze
      end

      def uri
        @uri ||= build_custom_uri
      end

      def build_custom_uri(extra_variables: {})
        parsed = Addressable::URI.parse(@url)
        parsed.query_values = @variables.merge(extra_variables)
        parsed
      end

      def headers
        @headers ||= {
          'X-ClickHouse-User' => @username,
          'X-ClickHouse-Key' => @password,
          'X-ClickHouse-Format' => 'JSON' # always return JSON data
        }.freeze
      end
    end
  end
end
