# frozen_string_literal: true

module Mcp
  module Tools
    class Manager
      include VersionHelper

      class ToolNotFoundError < StandardError
        attr_reader :tool_name, :args

        def initialize(tool_name)
          @tool_name = tool_name
          super("Tool '#{tool_name}' not found.")
        end
      end

      class VersionNotFoundError < StandardError
        attr_reader :tool_name, :requested_version, :available_versions

        def initialize(tool_name, requested_version, available_versions)
          @tool_name = tool_name
          @requested_version = requested_version
          @available_versions = available_versions
          super("Tool '#{tool_name}' version '#{requested_version}' not found. " \
            "Available versions: #{available_versions.join(', ')}")
        end
      end

      class InvalidVersionFormatError < StandardError
        attr_reader :version

        def initialize(version)
          @version = version
          super("Invalid semantic version format: #{version}.")
        end
      end

      # Registry of all custom tools mapped to their service classes
      CUSTOM_TOOLS = {
        'get_mcp_server_version' => ::Mcp::Tools::GetServerVersionService
      }.freeze

      attr_reader :tools

      def initialize
        @tools = build_tools
      end

      def list_tools
        tools
      end

      def get_tool(name:, version: nil)
        raise InvalidVersionFormatError, version if version && !validate_semantic_version(version)

        return get_custom_tool(name, version) if CUSTOM_TOOLS.key?(name)

        return get_api_tool(name, version) if discover_api_tools.key?(name)

        return get_aggregated_api_tool(name, version) if discover_aggregated_api_tools.key?(name)

        raise ToolNotFoundError, name
      end

      private

      def get_custom_tool(name, version)
        tool_class = CUSTOM_TOOLS[name]

        unless version.nil? || tool_class.version_exists?(version)
          available_versions = tool_class.available_versions
          raise VersionNotFoundError.new(name, version, available_versions)
        end

        tool_class.new(name: name, version: version)
      end

      def get_api_tool(name, version)
        api_tools = discover_api_tools
        tool = api_tools[name]
        api_tool_version = tool.version

        raise VersionNotFoundError.new(name, version, [api_tool_version]) if version && version != api_tool_version

        tool
      end

      def get_aggregated_api_tool(name, version)
        aggregated_api_tools = discover_aggregated_api_tools
        tool = aggregated_api_tools[name]
        tool_version = tool.version

        raise VersionNotFoundError.new(name, version, [tool_version]) if version && version != tool_version

        tool
      end

      def build_tools
        tools = {}

        # Build custom tools using their latest versions
        CUSTOM_TOOLS.each do |name, tool_class|
          tools[name] = tool_class.new(name: name)
        end

        # Include API tools (discovered from route_setting :mcp)
        api_tools = discover_api_tools
        api_tools.each do |name, tool|
          tools[name] = tool
        end

        # Include aggregated API tools (discovered from route_setting :mcp with aggregators specified)
        aggregated_api_tools = discover_aggregated_api_tools
        aggregated_api_tools.each do |name, tool|
          tools[name] = tool
        end

        tools
      end

      def discover_api_tools
        @api_tools ||= begin
          api_tools = {}

          ::API::API.routes.each do |route|
            settings = route.app.route_setting(:mcp)
            next if settings.blank?
            next if settings[:aggregators].present?

            name = settings[:tool_name].to_s
            tool = Mcp::Tools::ApiTool.new(name: name, route: route)
            api_tools[name] = tool
          end

          api_tools.freeze
        end
      end

      def discover_aggregated_api_tools
        @aggregated_api_tools ||= begin
          aggregated_api_tools = {}

          ::API::API.routes.each do |route|
            settings = route.app.route_setting(:mcp)
            next if settings.blank?

            name = settings[:tool_name].to_s
            aggregators = settings[:aggregators]
            next if aggregators.blank?

            tool = Mcp::Tools::ApiTool.new(name: name, route: route)

            aggregators.each do |aggregator|
              aggregated_api_tools[aggregator] ||= []
              aggregated_api_tools[aggregator] << tool
            end
          end

          aggregated_api_tools.to_h do |klass, tools|
            [klass.tool_name, klass.new(tools: tools)]
          end.freeze
        end
      end
    end
  end
end

Mcp::Tools::Manager.prepend_mod
