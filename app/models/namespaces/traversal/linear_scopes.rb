# frozen_string_literal: true

module Namespaces
  module Traversal
    module LinearScopes
      extend ActiveSupport::Concern

      class_methods do
        # When filtering namespaces by the traversal_ids column to compile a
        # list of namespace IDs, it can be faster to reference the ID in
        # traversal_ids than the primary key ID column.
        def as_ids
          return super unless use_traversal_ids?

          select('namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)] AS id')
        end

        def self_and_descendants
          return super unless use_traversal_ids?

          without_dups = self_and_descendants_with_duplicates
            .select('DISTINCT on(namespaces.id) namespaces.*')

          # Wrap the `SELECT DISTINCT on(....)` with a normal query so we
          # retain expected Rails behavior. Otherwise count and other
          # aggregates won't work.
          unscoped.without_sti_condition.from(without_dups, :namespaces)
        end

        def self_and_descendant_ids
          return super unless use_traversal_ids?

          self_and_descendants_with_duplicates.select('DISTINCT namespaces.id')
        end

        # Make sure we drop the STI `type = 'Group'` condition for better performance.
        # Logically equivalent so long as hierarchies remain homogeneous.
        def without_sti_condition
          unscope(where: :type)
        end

        private

        def use_traversal_ids?
          Feature.enabled?(:use_traversal_ids, default_enabled: :yaml)
        end

        def self_and_descendants_with_duplicates
          base_ids = select(:id)

          unscoped
            .without_sti_condition
            .from("namespaces, (#{base_ids.to_sql}) base")
            .where('namespaces.traversal_ids @> ARRAY[base.id]')
        end
      end
    end
  end
end
