# frozen_string_literal: true

module Gitlab
  # Retrieving of parent or child objects based on a base ActiveRecord relation.
  #
  # This class uses recursive CTEs and as a result will only work on PostgreSQL.
  class ObjectHierarchy
    DEPTH_COLUMN = :depth

    attr_reader :ancestors_base, :descendants_base, :model, :options, :unscoped_model

    # ancestors_base - An instance of ActiveRecord::Relation for which to
    #                  get parent objects.
    # descendants_base - An instance of ActiveRecord::Relation for which to
    #                    get child objects. If omitted, ancestors_base is used.
    def initialize(ancestors_base, descendants_base = ancestors_base, options: {})
      raise ArgumentError, "Model of ancestors_base does not match model of descendants_base" if ancestors_base.model != descendants_base.model

      @ancestors_base = ancestors_base
      @descendants_base = descendants_base
      @model = ancestors_base.model
      @unscoped_model = @model.unscoped
      @options = options
    end

    # Returns the set of descendants of a given relation, but excluding the given
    # relation
    # rubocop: disable CodeReuse/ActiveRecord
    def descendants
      base_and_descendants.where.not(id: descendants_base.select(:id))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Returns the maximum depth starting from the base
    # A base object with no children has a maximum depth of `1`
    def max_descendants_depth
      base_and_descendants(with_depth: true).maximum(DEPTH_COLUMN)
    end

    # Returns the set of ancestors of a given relation, but excluding the given
    # relation
    #
    # Passing an `upto` will stop the recursion once the specified parent_id is
    # reached. So all ancestors *lower* than the specified ancestor will be
    # included.
    # rubocop: disable CodeReuse/ActiveRecord
    def ancestors(upto: nil, hierarchy_order: nil)
      base_and_ancestors(upto: upto, hierarchy_order: hierarchy_order).where.not(id: ancestors_base.select(:id))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Returns a relation that includes the ancestors_base set of objects
    # and all their ancestors (recursively).
    #
    # Passing an `upto` will stop the recursion once the specified parent_id is
    # reached. So all ancestors *lower* than the specified ancestor will be
    # included.
    #
    # Passing a `hierarchy_order` with either `:asc` or `:desc` will cause the
    # recursive query order from most nested object to root or from the root
    # ancestor to most nested object respectively. This uses a `depth` column
    # where `1` is defined as the depth for the base and increment as we go up
    # each parent.
    #
    # Note: By default the order is breadth-first
    # rubocop: disable CodeReuse/ActiveRecord
    def base_and_ancestors(upto: nil, hierarchy_order: nil)
      recursive_query = base_and_ancestors_cte(upto, hierarchy_order).apply_to(unscoped_model.all)
      recursive_query = recursive_query.order(depth: hierarchy_order) if hierarchy_order
      read_only(recursive_query)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Returns a relation that includes the descendants_base set of objects
    # and all their descendants (recursively).
    #
    # When `with_depth` is `true`, a `depth` column is included where it starts with `1` for the base objects
    # and incremented as we go down the descendant tree
    # rubocop: disable CodeReuse/ActiveRecord
    def base_and_descendants(with_depth: false)
      read_only(base_and_descendants_cte(with_depth: with_depth).apply_to(unscoped_model.all))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Returns a relation that includes the base objects, their ancestors,
    # and the descendants of the base objects.
    #
    # The resulting query will roughly look like the following:
    #
    #     WITH RECURSIVE ancestors AS ( ... ),
    #       descendants AS ( ... )
    #     SELECT *
    #     FROM (
    #       SELECT *
    #       FROM ancestors namespaces
    #
    #       UNION
    #
    #       SELECT *
    #       FROM descendants namespaces
    #     ) groups;
    #
    # Using this approach allows us to further add criteria to the relation with
    # Rails thinking it's selecting data the usual way.
    #
    # If nested objects are not supported, ancestors_base is returned.
    # rubocop: disable CodeReuse/ActiveRecord
    def all_objects
      ancestors = base_and_ancestors_cte
      descendants = base_and_descendants_cte

      ancestors_table = ancestors.alias_to(objects_table)
      descendants_table = descendants.alias_to(objects_table)

      ancestors_scope = unscoped_model.from(ancestors_table)
      descendants_scope = unscoped_model.from(descendants_table)

      relation = unscoped_model
        .with
        .recursive(ancestors.to_arel, descendants.to_arel)
        .from_union([
          ancestors_scope,
          descendants_scope
        ])

      read_only(relation)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    # Remove the extra `depth` field using an INNER JOIN to avoid breaking UNION queries
    # and ordering the rows based on the `depth` column to maintain the row order.
    #
    # rubocop: disable CodeReuse/ActiveRecord
    def remove_depth_and_maintain_order(relation, hierarchy_order: :asc)
      joined_relation = model.joins("INNER JOIN (#{relation.select(:id, :depth).to_sql}) namespaces_join_table on namespaces_join_table.id = #{model.table_name}.id").order("namespaces_join_table.depth" => hierarchy_order)

      model.from(Arel::Nodes::As.new(joined_relation.arel, objects_table))
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def base_and_ancestors_cte(stop_id = nil, hierarchy_order = nil)
      cte = SQL::RecursiveCTE.new(:base_and_ancestors)

      base_query = ancestors_base.except(:order)
      base_query = base_query.select("1 as #{DEPTH_COLUMN}", "ARRAY[#{objects_table.name}.id] AS tree_path", "false AS tree_cycle", objects_table[Arel.star]) if hierarchy_order

      cte << base_query

      # Recursively get all the ancestors of the base set.
      parent_query = unscoped_model
        .from(from_tables(cte))
        .where(ancestor_conditions(cte))
        .except(:order)

      if hierarchy_order
        quoted_objects_table_name = model.connection.quote_table_name(objects_table.name)

        parent_query = parent_query.select(
          cte.table[DEPTH_COLUMN] + 1,
          "tree_path || #{quoted_objects_table_name}.id",
          "#{quoted_objects_table_name}.id = ANY(tree_path)",
          objects_table[Arel.star]
        ).where(cte.table[:tree_cycle].eq(false))
      end

      parent_query = parent_query.where(parent_id_column(cte).not_eq(stop_id)) if stop_id

      cte << parent_query
      cte
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def base_and_descendants_cte(with_depth: false)
      cte = SQL::RecursiveCTE.new(:base_and_descendants)

      base_query = descendants_base.except(:order)
      base_query = base_query.select("1 AS #{DEPTH_COLUMN}", "ARRAY[#{objects_table.name}.id] AS tree_path", "false AS tree_cycle", objects_table[Arel.star]) if with_depth

      cte << base_query

      # Recursively get all the descendants of the base set.
      descendants_query = unscoped_model
        .from(from_tables(cte))
        .where(descendant_conditions(cte))
        .except(:order)

      if with_depth
        quoted_objects_table_name = model.connection.quote_table_name(objects_table.name)

        descendants_query = descendants_query.select(
          cte.table[DEPTH_COLUMN] + 1,
          "tree_path || #{quoted_objects_table_name}.id",
          "#{quoted_objects_table_name}.id = ANY(tree_path)",
          objects_table[Arel.star]
        ).where(cte.table[:tree_cycle].eq(false))
      end

      cte << descendants_query
      cte
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def objects_table
      model.arel_table
    end

    def parent_id_column(cte)
      cte.table[:parent_id]
    end

    def from_tables(cte)
      [objects_table, cte.table]
    end

    def ancestor_conditions(cte)
      objects_table[:id].eq(cte.table[:parent_id])
    end

    def descendant_conditions(cte)
      objects_table[:parent_id].eq(cte.table[:id])
    end

    def read_only(relation)
      # relations using a CTE are not safe to use with update_all as it will
      # throw away the CTE, hence we mark them as read-only.
      relation.extend(Gitlab::Database::ReadOnlyRelation)
      relation
    end
  end
end

Gitlab::ObjectHierarchy.prepend_mod_with('Gitlab::ObjectHierarchy')
