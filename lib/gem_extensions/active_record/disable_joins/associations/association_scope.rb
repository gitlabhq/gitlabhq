# frozen_string_literal: true

module GemExtensions
  module ActiveRecord
    module DisableJoins
      module Associations
        class AssociationScope < ::ActiveRecord::Associations::AssociationScope # :nodoc:
          def scope(association)
            source_reflection = association.reflection
            owner = association.owner
            unscoped = association.klass.unscoped
            reverse_chain = get_chain(source_reflection, association, unscoped.alias_tracker).reverse

            previous_reflection, last_reflection, last_ordered, last_join_ids = last_scope_chain(reverse_chain, owner)

            add_constraints(last_reflection, last_reflection.join_primary_key, last_join_ids, owner, last_ordered,
              previous_reflection: previous_reflection)
          end

          private

          def last_scope_chain(reverse_chain, owner)
            # Pulled from https://github.com/rails/rails/pull/42448
            # Fixes cases where the foreign key is not id
            first_item = reverse_chain.shift
            first_scope = [nil, first_item, false, [owner._read_attribute(first_item.join_foreign_key)]]

            reverse_chain.inject(first_scope) do |(previous_reflection, reflection, ordered, join_ids), next_reflection|
              key = reflection.join_primary_key
              records = add_constraints(reflection, key, join_ids, owner, ordered, previous_reflection: previous_reflection)
              foreign_key = next_reflection.join_foreign_key
              record_ids = records.pluck(foreign_key) # rubocop:disable CodeReuse/ActiveRecord
              records_ordered = records && records.order_values.any?

              [reflection, next_reflection, records_ordered, record_ids]
            end
          end

          def add_constraints(reflection, key, join_ids, owner, ordered, previous_reflection: nil)
            scope = reflection.build_scope(reflection.aliased_table).where(key => join_ids) # rubocop:disable CodeReuse/ActiveRecord

            # Pulled from https://github.com/rails/rails/pull/42590
            # Fixes cases where used with an STI type
            relation = reflection.klass.scope_for_association
            scope.merge!(
              relation.except(:select, :create_with, :includes, :preload, :eager_load, :joins, :left_outer_joins)
            )

            # Attempt to fix use case where we have a polymorphic relationship
            # Build on an additional scope to filter by the polymorphic type
            if reflection.type
              polymorphic_class = previous_reflection.try(:klass) || owner.class

              polymorphic_type = transform_value(polymorphic_class.polymorphic_name)
              scope = apply_scope(scope, reflection.aliased_table, reflection.type, polymorphic_type)
            end

            scope = reflection.constraints.inject(scope) do |memo, scope_chain_item|
              item = eval_scope(reflection, scope_chain_item, owner)
              scope.unscope!(*item.unscope_values)
              scope.where_clause += item.where_clause
              scope.order_values = item.order_values | scope.order_values
              scope
            end

            if scope.order_values.empty? && ordered
              split_scope = ::GemExtensions::ActiveRecord::DisableJoins::Relation.create(scope.klass, key, join_ids)
              split_scope.where_clause += scope.where_clause
              split_scope
            else
              scope
            end
          end
        end
      end
    end
  end
end
