# frozen_string_literal: true

module API
  module Mcp
    module Handlers
      # See: https://modelcontextprotocol.io/specification/2025-06-18/schema#listtoolsrequest
      class ListTools
        include ::Gitlab::InternalEventsTracking

        def initialize(manager)
          @manager = manager
        end

        # allowed_tools: optional array of tool name strings. When present, only
        #   named tools are returned.
        # allowed_toolsets: optional array of toolset name strings. When present,
        #   only tools from those toolsets (plus ALWAYS_ON) are returned. The
        #   pseudo-value "all" includes every toolset. When both allowed_tools
        #   and allowed_toolsets are given, the result is their union.
        # include_named_unlisted: when true, an unlisted tool named in allowed_tools is
        #   returned too.
        def invoke(
          current_user, allowed_tools: nil, allowed_toolsets: nil, tool_name_prefix: nil, include_named_unlisted: false)
          tools_hash = manager.list_tools

          allowed_tools = resolve_aliases(allowed_tools)
          warn_unknown_tools(allowed_tools, tools_hash)
          included = resolve_included(allowed_tools: allowed_tools, allowed_toolsets: allowed_toolsets)

          tools = tools_hash.filter_map do |name, tool|
            next nil if included && included.exclude?(name)
            next nil unless tool.available?(current_user)
            next nil if tool.unlisted? && !(include_named_unlisted && Array(allowed_tools).include?(name))

            build_tool_data(name, tool, tool_name_prefix)
          end

          track_internal_event('list_mcp_tools', user: current_user)
          logger.conditional_info(
            current_user,
            message: 'MCP tools list',
            event_name: 'tools_list',
            ai_component: 'mcp_server',
            tool_count: tools.size
          )

          { tools: tools }
        end

        private

        def resolve_aliases(allowed_tools)
          return allowed_tools if allowed_tools.blank?

          allowed_tools.map { |name| manager.resolve_alias(name) }
        end

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

        def build_tool_data(name, tool, tool_name_prefix)
          tool_data = {
            name: "#{tool_name_prefix}#{name}",
            description: tool.description,
            inputSchema: tool.input_schema
          }

          tool_data[:icons] = [tool.icons.first] if tool.try(:icons).present?

          tool_data[:annotations] = (tool.try(:annotations) || {}).merge(toolset: tool.toolset.to_s)

          tool_data
        end

        def logger
          @logger ||= ::Gitlab::Mcp::Logger.build
        end

        attr_reader :manager
      end
    end
  end
end
