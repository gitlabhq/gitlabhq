# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      class Builder
        class Project
          include Gitlab::Utils::StrongMemoize

          def initialize(project)
            @project = project
          end

          def secret_variables(environment:, protected_ref: false, only: nil)
            variables = @project.variables
            variables = variables.unprotected unless protected_ref
            variables = variables.for_environment(environment)
            variables = variables.by_key(only) if only

            Gitlab::Ci::Variables::Collection.new(variables)
          end
        end
      end
    end
  end
end
