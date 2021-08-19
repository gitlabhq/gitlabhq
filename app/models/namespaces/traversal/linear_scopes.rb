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

        def self_and_descendants(include_self: true)
          return super unless use_traversal_ids?

          records = self_and_descendants_with_duplicates(include_self: include_self)

          distinct = records.select('DISTINCT on(namespaces.id) namespaces.*')

          # Produce a query of the form: SELECT * FROM namespaces;
          #
          # When we have queries that break this SELECT * format we can run in to errors.
          # For example `SELECT DISTINCT on(...)` will fail when we chain a `.count` c
          unscoped.without_sti_condition.from(distinct, :namespaces)
        end

        def self_and_descendant_ids(include_self: true)
          return super unless use_traversal_ids?

          self_and_descendants_with_duplicates(include_self: include_self)
            .select('DISTINCT namespaces.id')
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

        def self_and_descendants_with_duplicates(include_self: true)
          base_ids = select(:id)

          records = unscoped
            .without_sti_condition
            .from("namespaces, (#{base_ids.to_sql}) base")
            .where('namespaces.traversal_ids @> ARRAY[base.id]')

          if include_self
            records
          else
            records.where('namespaces.id <> base.id')
          end
        end
      end
    end
  end
end
