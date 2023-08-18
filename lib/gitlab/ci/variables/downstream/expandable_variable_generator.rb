# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      module Downstream
        class ExpandableVariableGenerator < Base
          def for(item)
            expanded_var = expanded_var_for(item)
            file_vars = file_var_dependencies_for(item)

            [expanded_var].concat(file_vars)
          end

          private

          def expanded_var_for(item)
            {
              key: item.key,
              value: ::ExpandVariables.expand(
                item.value,
                context.all_bridge_variables,
                expand_file_refs: context.expand_file_refs
              )
            }
          end

          def file_var_dependencies_for(item)
            return [] if context.expand_file_refs
            return [] unless item.depends_on

            item.depends_on.filter_map do |dependency|
              dependency_variable = context.all_bridge_variables[dependency]

              if dependency_variable&.file?
                {
                  key: dependency_variable.key,
                  value: dependency_variable.value,
                  variable_type: :file
                }
              end
            end
          end
        end
      end
    end
  end
end
