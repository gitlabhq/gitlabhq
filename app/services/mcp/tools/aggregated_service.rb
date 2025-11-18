# frozen_string_literal: true

# rubocop:disable Mcp/UseApiService -- does not depend directly on REST API
module Mcp
  module Tools
    class AggregatedService < BaseService
      include Mcp::Tools::Concerns::Versionable
      extend Gitlab::Utils::Override

      def self.tool_name
        raise NoMethodError, "#{self.class.name}#tool_name should be implemented in a subclass"
      end

      def initialize(tools:, version: nil)
        super(name: self.class.tool_name)
        initialize_version(version)
        @tools = tools
      end

      override :execute
      def execute(request: nil, params: nil)
        @request = request
        @params = params

        super
      end

      protected

      override :perform_default
      def perform_default(arguments = {})
        params[:arguments] = transform_arguments(arguments)
        tool = select_tool(arguments)

        raise Mcp::Tools::Manager::ToolNotFoundError, self.class.tool_name unless tool

        tool.execute(request:, params:)
      end

      private

      attr_reader :tools, :request, :params

      def select_tool(_args)
        raise NoMethodError, "#{self.class.name}#select_tool should be implemented in a subclass"
      end

      def transform_arguments(_args)
        raise NoMethodError, "#{self.class.name}#transform_arguments should be implemented in a subclass"
      end
    end
  end
end
# rubocop:enable Mcp/UseApiService
