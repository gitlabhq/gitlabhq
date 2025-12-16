# frozen_string_literal: true

module Mcp
  module Tools
    class GraphqlTool
      include Mcp::Tools::Concerns::Versionable

      attr_reader :current_user, :params

      def initialize(current_user:, params:, version: nil)
        @current_user = current_user
        @params = params
        initialize_version(version)
      end

      # Override in subclasses or use version metadata
      def graphql_operation
        raise NotImplementedError unless self.class.version_metadata(version)[:graphql_operation]

        self.class.version_metadata(version)[:graphql_operation]
      end

      def operation_name
        self.class.version_metadata(version)[:operation_name] ||
          raise(NotImplementedError, "operation_name must be defined")
      end

      # Can be overridden with version-specific methods
      def build_variables
        raise NotImplementedError, "build_variables must be implemented"
      end

      def execute
        result = GitlabSchema.execute(
          graphql_operation_for_version,
          variables: build_variables_for_version,
          context: execution_context
        )

        process_result(result)
      end

      private

      def execution_context
        {
          current_user: current_user,
          is_sessionless_user: false
        }
      end

      def process_result(result)
        # Handle GraphQL-level errors (syntax, validation, etc.)
        if result['errors']
          error_messages = extract_error_messages(result['errors'])
          return ::Mcp::Tools::Response.error(error_messages.join(', '))
        end

        operation_data = result.dig('data', operation_name)

        return ::Mcp::Tools::Response.error("Operation returned no data") if operation_data.nil?

        # Check for operation-specific errors
        operation_errors = operation_data['errors']
        if operation_errors&.any?
          error_messages = extract_error_messages(operation_errors)
          return ::Mcp::Tools::Response.error(error_messages.join(', '))
        end

        formatted_content = [{ type: 'text', text: Gitlab::Json.dump(operation_data) }]
        ::Mcp::Tools::Response.success(formatted_content, operation_data)
      end

      def extract_error_messages(errors)
        errors.map do |error|
          if error.is_a?(String)
            error
          elsif error.is_a?(Hash)
            error['message'] || error.to_s
          else
            error.to_s
          end
        end
      end
    end
  end
end
