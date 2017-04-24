module Gitlab
  # Retrieving of parent or child groups based on a base ActiveRecord relation.
  #
  # This class uses recursive CTEs and as a result will only work on PostgreSQL.
  class GroupHierarchy
    attr_reader :base, :model

    # base - An instance of ActiveRecord::Relation for which to get parent or
    #        child groups.
    def initialize(base)
      @base = base
      @model = base.model
    end

    # Returns a relation that includes the base set of groups and all their
    # ancestors (recursively).
    def base_and_ancestors
      base_and_ancestors_cte.apply_to(model.all)
    end

    # Returns a relation that includes the base set of groups and all their
    # descendants (recursively).
    def base_and_descendants
      base_and_descendants_cte.apply_to(model.all)
    end

    # Returns a relation that includes the base groups, their ancestors, and the
    # descendants of the base groups.
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
    def all_groups
      ancestors = base_and_ancestors_cte
      descendants = base_and_descendants_cte

      ancestors_table = ancestors.alias_to(groups_table)
      descendants_table = descendants.alias_to(groups_table)

      union = SQL::Union.new([model.unscoped.from(ancestors_table),
                              model.unscoped.from(descendants_table)])

      model.
        unscoped.
        with.
        recursive(ancestors.to_arel, descendants.to_arel).
        from("(#{union.to_sql}) #{model.table_name}")
    end

    private

    def base_and_ancestors_cte
      cte = SQL::RecursiveCTE.new(:base_and_ancestors)

      cte << base.except(:order)

      # Recursively get all the ancestors of the base set.
      cte << model.
        from([groups_table, cte.table]).
        where(groups_table[:id].eq(cte.table[:parent_id])).
        except(:order)

      cte
    end

    def base_and_descendants_cte
      cte = SQL::RecursiveCTE.new(:base_and_descendants)

      cte << base.except(:order)

      # Recursively get all the descendants of the base set.
      cte << model.
        from([groups_table, cte.table]).
        where(groups_table[:parent_id].eq(cte.table[:id])).
        except(:order)

      cte
    end

    def groups_table
      model.arel_table
    end
  end
end
