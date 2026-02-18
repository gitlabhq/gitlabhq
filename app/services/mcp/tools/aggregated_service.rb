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

      def enhance_response_with_operation(response, operation:, tool_name:, action_description: nil)
        return response if response[:isError]

        if response[:structuredContent].is_a?(Hash)
          response[:structuredContent][:_meta] = {
            operation: operation.to_s,
            tool: tool_name.to_s,
            aggregator: self.class.tool_name
          }
        end

        if action_description && response.dig(:content, 0, :text)
          original_text = response.dig(:content, 0, :text)

          if json_object_or_array?(original_text)
            response[:content].first[:text] = "#{action_description} #{original_text}"
          end
        end

        response
      end

      def json_object_or_array?(text)
        parsed = Gitlab::Json.safe_parse(text)
        parsed.is_a?(Hash) || parsed.is_a?(Array)
      rescue JSON::ParserError, EncodingError
        false
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
