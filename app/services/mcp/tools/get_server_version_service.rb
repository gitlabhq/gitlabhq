# frozen_string_literal: true

# rubocop:disable Mcp/UseApiService -- Tool does not depend on REST API
module Mcp
  module Tools
    class GetServerVersionService < BaseService
      extend ::Gitlab::Utils::Override

      override :description
      def description
        'Get the current version of MCP server.'
      end

      override :input_schema
      def input_schema
        {
          type: 'object',
          properties: {},
          required: []
        }
      end

      protected

      override :perform
      def perform(_access_token, _arguments = {}, _query = {})
        data = { version: Gitlab::VERSION, revision: Gitlab.revision }
        formatted_content = [{ type: 'text', text: data[:version] }]
        ::Mcp::Tools::Response.success(formatted_content, data)
      end
    end
  end
end
# rubocop:enable Mcp/UseApiService
