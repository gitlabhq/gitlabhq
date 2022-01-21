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

        def roots
          return super unless use_traversal_ids_roots?

          root_ids = all.select("#{quoted_table_name}.traversal_ids[1]").distinct
          unscoped.where(id: root_ids)
        end

        def self_and_ancestors(include_self: true, upto: nil, hierarchy_order: nil)
          return super unless use_traversal_ids_for_ancestor_scopes?

          ancestors_cte, base_cte = ancestor_ctes
          namespaces = Arel::Table.new(:namespaces)

          records = unscoped
            .with(base_cte.to_arel, ancestors_cte.to_arel)
            .distinct
            .from([ancestors_cte.table, namespaces])
            .where(namespaces[:id].eq(ancestors_cte.table[:ancestor_id]))
            .order_by_depth(hierarchy_order)

          unless include_self
            records = records.where(ancestors_cte.table[:base_id].not_eq(ancestors_cte.table[:ancestor_id]))
          end

          if upto
            records = records.where.not(id: unscoped.where(id: upto).select('unnest(traversal_ids)'))
          end

          records
        end

        def self_and_ancestor_ids(include_self: true)
          return super unless use_traversal_ids_for_ancestor_scopes?

          self_and_ancestors(include_self: include_self).as_ids
        end

        def self_and_descendants(include_self: true)
          return super unless use_traversal_ids_for_descendants_scopes?

          if Feature.enabled?(:traversal_ids_btree, default_enabled: :yaml)
            self_and_descendants_with_comparison_operators(include_self: include_self)
          else
            records = self_and_descendants_with_duplicates_with_array_operator(include_self: include_self)
            distinct = records.select('DISTINCT on(namespaces.id) namespaces.*')
            distinct.normal_select
          end
        end

        def self_and_descendant_ids(include_self: true)
          return super unless use_traversal_ids_for_descendants_scopes?

          if Feature.enabled?(:traversal_ids_btree, default_enabled: :yaml)
            self_and_descendants_with_comparison_operators(include_self: include_self).as_ids
          else
            self_and_descendants_with_duplicates_with_array_operator(include_self: include_self)
              .select('DISTINCT namespaces.id')
          end
        end

        def order_by_depth(hierarchy_order)
          return all unless hierarchy_order

          depth_order = hierarchy_order == :asc ? :desc : :asc

          all
            .select(Arel.star, 'array_length(traversal_ids, 1) as depth')
            .order(depth: depth_order, id: :asc)
        end

        # Produce a query of the form: SELECT * FROM namespaces;
        #
        # When we have queries that break this SELECT * format we can run in to errors.
        # For example `SELECT DISTINCT on(...)` will fail when we chain a `.count` c
        def normal_select
          unscoped.from(all, :namespaces)
        end

        private

        def use_traversal_ids?
          Feature.enabled?(:use_traversal_ids, default_enabled: :yaml)
        end

        def use_traversal_ids_roots?
          Feature.enabled?(:use_traversal_ids_roots, default_enabled: :yaml) &&
          use_traversal_ids?
        end

        def use_traversal_ids_for_ancestor_scopes?
          Feature.enabled?(:use_traversal_ids_for_ancestor_scopes, default_enabled: :yaml) &&
          use_traversal_ids?
        end

        def use_traversal_ids_for_descendants_scopes?
          Feature.enabled?(:use_traversal_ids_for_descendants_scopes, default_enabled: :yaml) &&
          use_traversal_ids?
        end

        def self_and_descendants_with_comparison_operators(include_self: true)
          base = all.select(
            :traversal_ids,
            'LEAD (namespaces.traversal_ids, 1) OVER (ORDER BY namespaces.traversal_ids ASC) next_traversal_ids'
          )
          base_cte = Gitlab::SQL::CTE.new(:descendants_base_cte, base)

          namespaces = Arel::Table.new(:namespaces)

          # Bound the search space to ourselves (optional) and descendants.
          #
          # WHERE (base_cte.next_traversal_ids IS NULL OR base_cte.next_traversal_ids > namespaces.traversal_ids)
          #   AND next_traversal_ids_sibling(base_cte.traversal_ids) > namespaces.traversal_ids
          records = unscoped
            .from([base_cte.table, namespaces])
            .where(base_cte.table[:next_traversal_ids].eq(nil).or(base_cte.table[:next_traversal_ids].gt(namespaces[:traversal_ids])))
            .where(next_sibling_func(base_cte.table[:traversal_ids]).gt(namespaces[:traversal_ids]))

          #   AND base_cte.traversal_ids <= namespaces.traversal_ids
          records = if include_self
                      records.where(base_cte.table[:traversal_ids].lteq(namespaces[:traversal_ids]))
                    else
                      records.where(base_cte.table[:traversal_ids].lt(namespaces[:traversal_ids]))
                    end

          records_cte = Gitlab::SQL::CTE.new(:descendants_cte, records)

          unscoped
            .unscope(where: [:type])
            .with(base_cte.to_arel, records_cte.to_arel)
            .from(records_cte.alias_to(namespaces))
        end

        def next_sibling_func(*args)
          Arel::Nodes::NamedFunction.new('next_traversal_ids_sibling', args)
        end

        def self_and_descendants_with_duplicates_with_array_operator(include_self: true)
          base_ids = select(:id)

          records = unscoped
            .from("namespaces, (#{base_ids.to_sql}) base")
            .where('namespaces.traversal_ids @> ARRAY[base.id]')

          if include_self
            records
          else
            records.where('namespaces.id <> base.id')
          end
        end

        def ancestor_ctes
          base_scope = all.select('namespaces.id', 'namespaces.traversal_ids')
          base_cte = Gitlab::SQL::CTE.new(:base_ancestors_cte, base_scope)

          # We have to alias id with 'AS' to avoid ambiguous column references by calling methods.
          ancestors_scope = unscoped
            .unscope(where: [:type])
            .select('id as base_id', 'unnest(traversal_ids) as ancestor_id')
            .from(base_cte.table)
          ancestors_cte = Gitlab::SQL::CTE.new(:ancestors_cte, ancestors_scope)

          [ancestors_cte, base_cte]
        end
      end
    end
  end
end
