# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#listtoolsrequest
      class ListTools
        def initialize(manager)
          @manager = manager
        end

        # allowed_tools: optional array of tool name strings. When present, only
        #   named tools are returned.
        # allowed_toolsets: optional array of toolset name strings. When present,
        #   only tools from those toolsets (plus ALWAYS_ON) are returned. The
        #   pseudo-value "all" includes every toolset. When both allowed_tools
        #   and allowed_toolsets are given, the result is their union.
        def invoke(current_user, allowed_tools: nil, allowed_toolsets: nil, tool_name_prefix: nil)
          tools_hash = manager.list_tools
          toolsets_enabled = ::Feature.enabled?(:mcp_toolsets, current_user)

          warn_unknown_tools(allowed_tools, tools_hash)
          included = resolve_included(allowed_tools: allowed_tools, allowed_toolsets: allowed_toolsets)

          tools = tools_hash.filter_map do |name, tool|
            next nil if included && included.exclude?(name)
            next nil unless tool_available?(tool, current_user)
            next nil if tool.unlisted?

            build_tool_data(name, tool, tool_name_prefix, toolsets_enabled)
          end

          { tools: tools }
        end

        private

        def warn_unknown_tools(allowed_tools, tools_hash)
          return if allowed_tools.blank?

          known_names = tools_hash.keys.map(&:to_s)
          unknown = allowed_tools - known_names
          logger.warn(message: "Unknown MCP tool names in allowed_tools", names: unknown) if unknown.any?
        end

        def resolve_included(allowed_tools:, allowed_toolsets:)
          has_tools_filter = allowed_tools.present?
          has_toolset_filter = allowed_toolsets.present?
          return unless has_tools_filter || has_toolset_filter

          result = Set.new
          result.merge(allowed_tools) if has_tools_filter
          result.merge(manager.tools_in_toolsets(allowed_toolsets)) if has_toolset_filter
          result
        end

        def build_tool_data(name, tool, tool_name_prefix, toolsets_enabled)
          tool_data = {
            name: "#{tool_name_prefix}#{name}",
            description: tool.description,
            inputSchema: tool.input_schema
          }

          tool_data[:icons] = [tool.icons.first] if tool.try(:icons).present?

          tool_annotations = tool.try(:annotations) || {}
          tool_annotations = tool_annotations.merge(toolset: tool.toolset.to_s) if toolsets_enabled
          tool_data[:annotations] = tool_annotations if tool_annotations.present?

          tool_data
        end

        def tool_available?(tool, current_user)
          # tool does not have an availability check if it does not inherit `Mcp::Tools::Base::BaseService`
          return true unless tool.is_a?(::Mcp::Tools::Base::BaseService)

          tool.set_cred(current_user: current_user) if tool.is_a? ::Mcp::Tools::Base::CustomService
          tool.available?
        end

        def logger
          @logger ||= ::Gitlab::Mcp::Logger.build
        end

        attr_reader :manager
      end
    end
  end
end
