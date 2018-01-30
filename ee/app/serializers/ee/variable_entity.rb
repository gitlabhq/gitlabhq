module EE
  module VariableEntity
    extend ActiveSupport::Concern

    prepended do
      expose :environment_scope, if: ->(variable, options) { variable.project.feature_available?(:variable_environment_scope) }
    end
  end
end
