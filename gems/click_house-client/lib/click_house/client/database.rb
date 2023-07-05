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
        @variables = variables.merge(database: database).freeze
      end

      def uri
        @uri ||= begin
          parsed = Addressable::URI.parse(@url)
          parsed.query_values = @variables
          parsed
        end
      end

      def headers
        @headers ||= {
          'X-ClickHouse-User' => @username,
          'X-ClickHouse-Key' => @password
        }.freeze
      end
    end
  end
end
