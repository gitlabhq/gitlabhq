# frozen_string_literal: true

module ActiveRecord
  module GitlabPatches
    module Partitioning
      module Reflection
        module MacroReflection
          NO_OWNER = Struct.new(:partition_id).new(1..100_000)

          # We override the method to allow eager loading of partitioned records
          #
          # For eager loading the owner is always nil and we supply a benign
          # object that allows the scope to be evaluated with a query like
          # `where partition_id between 1 and 100000`
          # and transforms it into
          # `where partition_id is not null`
          # to ensure that no partition is left out by the query.
          # This is safe because `partition_id` columns are defined as `not null`
          #
          def scope_for(relation, owner = nil)
            if scope.arity == 1 && owner.nil? && options.key?(:partition_foreign_key)
              relation = relation.instance_exec(NO_OWNER, &scope)
              if relation_includes_partition_id_condition?(relation)
                relation.rewhere(relation.table[:partition_id].not_eq(nil))
              else
                relation
              end
            else
              super
            end
          end

          def relation_includes_partition_id_condition?(relation)
            relation
              .where_clause
              .extract_attributes
              .map(&:name)
              .include?('partition_id')
          end
        end
      end
    end
  end
end
