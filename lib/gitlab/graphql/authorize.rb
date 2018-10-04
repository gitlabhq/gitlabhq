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
        # If the `#authorize` call is used on multiple classes, we add the
        # permissions specified on a subclass, to the ones that were specified
        # on it's superclass.
        @required_permissions ||= if self.respond_to?(:superclass) && superclass.respond_to?(:required_permissions)
                                    superclass.required_permissions.dup
                                  else
                                    []
                                  end
      end

      def authorize(*permissions)
        required_permissions.concat(permissions)
      end
    end
  end
end
