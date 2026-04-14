# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#listtoolsrequest
      class ListTools
        def initialize(manager)
          @manager = manager
        end

        # allowed_tools: optional array of tool name strings to filter the response.
        # When nil or empty, all available tools are returned (default agentic chat behaviour).
        # When provided, only tools whose names are in the list are returned, ensuring the
        # agent's LLM sees exactly the toolset that was configured for it.
        def invoke(current_user, allowed_tools: nil, tool_name_prefix: nil)
          tools_hash = manager.list_tools

          if allowed_tools.present?
            known_names = tools_hash.keys.map(&:to_s)
            unknown = allowed_tools - known_names
            Gitlab::AppLogger.warn(message: "Unknown MCP tool names in allowed_tools", names: unknown) if unknown.any?
          end

          tools = tools_hash.filter_map do |name, tool|
            next nil if allowed_tools.present? && allowed_tools.exclude?(name)
            next nil unless tool_available?(tool, current_user)

            tool_data = {
              name: "#{tool_name_prefix}#{name}",
              description: tool.description,
              inputSchema: tool.input_schema
            }

            tool_data[:icons] = [tool.icons.first] if tool.try(:icons).present?

            annotations = tool.try(:annotations)
            tool_data[:annotations] = annotations if annotations.present?

            tool_data
          end

          { tools: tools }
        end

        private

        def tool_available?(tool, current_user)
          # tool does not have an availability check if it does not inherit `Mcp::Tools::BaseService`
          return true unless tool.is_a?(::Mcp::Tools::BaseService)

          tool.set_cred(current_user: current_user) if tool.is_a? ::Mcp::Tools::CustomService
          tool.available?
        end

        attr_reader :manager
      end
    end
  end
end
