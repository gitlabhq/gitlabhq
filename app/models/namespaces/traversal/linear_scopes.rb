# frozen_string_literal: true

module Namespaces
  module Traversal
    module LinearScopes
      extend ActiveSupport::Concern

      include AsCte

      class_methods do
        # When filtering namespaces by the traversal_ids column to compile a
        # list of namespace IDs, it can be faster to reference the ID in
        # traversal_ids than the primary key ID column.
        def as_ids
          select(Arel.sql('namespaces.traversal_ids[array_length(namespaces.traversal_ids, 1)]').as('id'))
        end

        def roots
          root_ids = all.select("#{quoted_table_name}.traversal_ids[1]").distinct
          unscoped.where(id: root_ids)
        end

        def self_and_ancestors(include_self: true, upto: nil, hierarchy_order: nil)
          self_and_ancestors_from_inner_join(
            include_self: include_self,
            upto: upto, hierarchy_order:
            hierarchy_order
          )
        end

        def self_and_ancestor_ids(include_self: true)
          self_and_ancestors(include_self: include_self).as_ids
        end

        def self_and_descendants(include_self: true)
          self_and_descendants_with_comparison_operators(include_self: include_self)
        end

        def self_and_descendant_ids(include_self: true)
          self_and_descendants(include_self: include_self).as_ids
        end

        def self_and_hierarchy
          unscoped.from_union([all.self_and_ancestors, all.self_and_descendants(include_self: false)])
        end

        def order_by_depth(hierarchy_order)
          return all unless hierarchy_order

          depth_order = hierarchy_order == :asc ? :desc : :asc

          all
            .select(Namespace.default_select_columns, 'array_length(traversal_ids, 1) as depth')
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

        def self_and_ancestors_from_inner_join(include_self: true, upto: nil, hierarchy_order: nil)
          base_cte = all.reselect('namespaces.traversal_ids').as_cte(:base_ancestors_cte)

          unnest = if include_self
                     base_cte.table[:traversal_ids]
                   else
                     base_cte_traversal_ids = 'base_ancestors_cte.traversal_ids'
                     traversal_ids_range = "1:array_length(#{base_cte_traversal_ids},1)-1"
                     Arel.sql("#{base_cte_traversal_ids}[#{traversal_ids_range}]")
                   end

          ancestor_subselect = "SELECT DISTINCT #{unnest_func(unnest).to_sql} FROM base_ancestors_cte"
          ancestors_join = <<~SQL
            INNER JOIN (#{ancestor_subselect}) AS ancestors(ancestor_id) ON namespaces.id = ancestors.ancestor_id
          SQL

          namespaces = Arel::Table.new(:namespaces)

          records = unscoped
            .with(base_cte.to_arel)
            .from(namespaces)
            .joins(ancestors_join)
            .order_by_depth(hierarchy_order)

          if upto
            upto_ancestor_ids = unscoped.where(id: upto).select(unnest_func(Arel.sql('traversal_ids')))
            records = records.where.not(id: upto_ancestor_ids)
          end

          records
        end

        def self_and_descendants_with_comparison_operators(include_self: true)
          base = all.select(:id, :traversal_ids)
          base_cte = base.as_cte(:descendants_base_cte)

          namespaces = Arel::Table.new(:namespaces)

          superset_cte = self.superset_cte(base_cte.table.name)
          withs = [base_cte.to_arel, superset_cte.to_arel]
          # Order is important. namespace should be last to handle future joins.
          froms = [superset_cte.table, namespaces]

          base_ref = froms.first

          # Bound the search space to ourselves (optional) and descendants.
          #
          # WHERE next_traversal_ids_sibling(base_cte.traversal_ids) > namespaces.traversal_ids
          records = unscoped
            .distinct
            .with(*withs)
            .from(froms)
            .where(next_sibling_func(base_ref[:traversal_ids]).gt(namespaces[:traversal_ids]))

          #   AND base_cte.traversal_ids <= namespaces.traversal_ids
          if include_self
            records.where(base_ref[:traversal_ids].lteq(namespaces[:traversal_ids]))
          else
            records.where(base_ref[:traversal_ids].lt(namespaces[:traversal_ids]))
          end
        end

        def next_sibling_func(*args)
          Arel::Nodes::NamedFunction.new('next_traversal_ids_sibling', args)
        end

        def unnest_func(*args)
          Arel::Nodes::NamedFunction.new('unnest', args)
        end

        def superset_cte(base_name)
          superset_sql = <<~SQL
            SELECT d1.traversal_ids
            FROM #{base_name} d1
            WHERE NOT EXISTS (
              SELECT 1
              FROM #{base_name} d2
              WHERE d2.id = ANY(d1.traversal_ids)
                AND d2.id <> d1.id
            )
          SQL

          Gitlab::SQL::CTE.new(:superset, superset_sql, materialized: false)
        end
      end
    end
  end
end
