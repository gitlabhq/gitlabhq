module Gitlab
  module Graphql
    # Allow fields to declare permissions their objects must have. The field
    # will be set to nil unless all required permissions are present.
    module Authorize
      extend ActiveSupport::Concern

      def self.use(schema_definition)
        schema_definition.instrument(:field, Instrumentation.new)
      end

      def required_permissions
        @required_permissions ||= []
      end

      def authorize(*permissions)
        required_permissions.concat(permissions)
      end
    end
  end
end
