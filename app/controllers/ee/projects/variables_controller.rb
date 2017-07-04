module EE
  module Projects
    module VariablesController
      extend ActiveSupport::Concern

      def variable_params_attributes
        attrs = super

        attrs.unshift(:environment_scope) if
            project.feature_available?(:variable_environment_scope)

        attrs
      end
    end
  end
end
