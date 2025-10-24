# frozen_string_literal: true

module Mcp
  module Tools
    class GetServerVersionService < CustomService
      extend ::Gitlab::Utils::Override

      # Register version 0.1.0
      register_version '0.1.0', {
        description: 'Get the current version of MCP server.',
        input_schema: {
          type: 'object',
          properties: {},
          required: []
        }
      }

      override :authorize!
      def authorize!(_params)
        true
      end

      protected

      # Version 0.1.0 implementation
      def perform_0_1_0(_arguments = {})
        data = { version: Gitlab::VERSION, revision: Gitlab.revision }
        formatted_content = [{ type: 'text', text: data[:version] }]
        ::Mcp::Tools::Response.success(formatted_content, data)
      end

      # Fallback to 0.1.0 behavior for any unimplemented versions
      override :perform_default
      def perform_default(arguments = {})
        perform_0_1_0(arguments)
      end
    end
  end
end
