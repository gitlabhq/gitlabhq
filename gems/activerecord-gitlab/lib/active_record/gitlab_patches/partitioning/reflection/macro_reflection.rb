# frozen_string_literal: true

module ActiveRecord
  module GitlabPatches
    module Partitioning
      module Reflection
        module MacroReflection
          def scope_for(relation, owner = nil)
            if scope.arity == 1 && owner.nil? && options.key?(:partition_foreign_key)
              relation
            else
              super
            end
          end
        end
      end
    end
  end
end
