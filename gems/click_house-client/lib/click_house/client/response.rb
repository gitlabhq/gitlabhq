# frozen_string_literal: true

module ClickHouse
  module Client
    class Response
      attr_reader :body

      def initialize(body, http_status_code)
        @body = body
        @http_status_code = http_status_code
      end

      def success?
        @http_status_code == 200
      end
    end
  end
end
