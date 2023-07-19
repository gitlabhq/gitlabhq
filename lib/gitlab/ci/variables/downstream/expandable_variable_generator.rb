# frozen_string_literal: true

module Gitlab
  module Ci
    module Variables
      module Downstream
        class ExpandableVariableGenerator < Base
          def for(item)
            expanded_value = ::ExpandVariables.expand(item.value, context.all_bridge_variables)

            [{ key: item.key, value: expanded_value }]
          end
        end
      end
    end
  end
end
