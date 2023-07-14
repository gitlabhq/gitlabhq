# frozen_string_literal: true

module ActiveRecord
  module GitlabPatches
    module Partitioning
      module Reflection
        module AssociationReflection
          def check_eager_loadable!
            return if scope && scope.arity == 1 && options.key?(:partition_foreign_key)

            super
          end
        end
      end
    end
  end
end
