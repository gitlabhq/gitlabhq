# frozen_string_literal: true

module Mcp
  module Tools
    class GetServerVersionService < CustomService
      extend ::Gitlab::Utils::Override

      override :description
      def description
        'Get the current version of MCP server.'
      end

      override :authorize!
      def authorize!(_params)
        true
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
      def perform(_arguments = {})
        data = { version: Gitlab::VERSION, revision: Gitlab.revision }
        formatted_content = [{ type: 'text', text: data[:version] }]
        ::Mcp::Tools::Response.success(formatted_content, data)
      end
    end
  end
end
