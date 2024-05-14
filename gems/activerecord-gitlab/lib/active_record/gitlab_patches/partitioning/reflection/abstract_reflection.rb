# frozen_string_literal: true

module ActiveRecord
  module GitlabPatches
    module Partitioning
      module Reflection
        module AbstractReflection
          extend ActiveSupport::Concern

          def join_scope(table, foreign_table, foreign_klass)
            klass_scope = super
            return klass_scope unless respond_to?(:options)

            partition_foreign_key = options[:partition_foreign_key]
            klass_scope.where!(table[:partition_id].eq(foreign_table[partition_foreign_key])) if partition_foreign_key

            klass_scope
          end
        end
      end
    end
  end
end
