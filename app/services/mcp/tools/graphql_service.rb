# frozen_string_literal: true

# rubocop:disable Mcp/UseApiService -- does not depend directly on REST API
module Mcp
  module Tools
    class GraphqlService < BaseService
      include Mcp::Tools::Concerns::Versionable
      extend Gitlab::Utils::Override

      def initialize(name:, version: nil)
        super(name: name)
        initialize_version(version)
      end

      override :set_cred
      def set_cred(current_user: nil, access_token: nil)
        @current_user = current_user
        _ = access_token # access_token is not used in GraphqlService
      end

      override :execute
      def execute(request: nil, params: nil)
        return Response.error("#{self.class.name}: current_user is not set") unless current_user.present?

        super
      end

      protected

      # Subclasses should override this to return their GraphQL tool class
      def graphql_tool_class
        raise NotImplementedError, "#{self.class.name}#graphql_tool_class must be implemented"
      end

      # Default implementation - can be overridden in subclasses
      def perform_default(_arguments = {})
        raise NoMethodError, "No implementation found for version #{version}"
      end

      private

      def execute_graphql_tool(arguments)
        tool = graphql_tool_class.new(
          current_user: current_user,
          params: arguments,
          version: version
        )

        tool.execute
      end
    end
  end
end
# rubocop:enable Mcp/UseApiService
