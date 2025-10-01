# frozen_string_literal: true

module Mcp
  module Tools
    class Manager
      CUSTOM_TOOLS = {
        'get_mcp_server_version' => ::Mcp::Tools::GetServerVersionService.new(name: 'get_mcp_server_version')
      }.freeze

      attr_reader :tools

      def initialize
        @tools = build_tools
      end

      private

      def build_tools
        api_tools = {}
        ::API::API.routes.each do |route|
          settings = route.app.route_setting(:mcp)
          next if settings.blank?

          api_tools[settings[:tool_name].to_s] = Mcp::Tools::ApiTool.new(route)
        end

        { **api_tools, **CUSTOM_TOOLS }
      end
    end
  end
end

Mcp::Tools::Manager.prepend_mod
