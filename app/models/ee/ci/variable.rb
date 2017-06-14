module EE
  module Ci
    module Variable
      extend ActiveSupport::Concern

      module VariableClassMethods
        def key_uniqueness_scope
          %i[project_id scope]
        end
      end

      prepended do
        singleton_class.prepend(VariableClassMethods)

        validates(
          :scope,
          presence: true,
          format: { with: ::Gitlab::Regex.variable_scope_regex,
                    message: ::Gitlab::Regex.variable_scope_regex_message }
        )
      end
    end
  end
end
