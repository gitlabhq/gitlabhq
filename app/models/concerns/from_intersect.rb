# frozen_string_literal: true

module FromIntersect
  extend ActiveSupport::Concern

  class_methods do
    # Produces a query that uses a FROM to select data using an INTERSECT.
    #
    # Example:
    #     groups = Group.from_intersect([group1.self_and_hierarchy, group2.self_and_hierarchy])
    #
    # This would produce the following SQL query:
    #
    #     SELECT *
    #     FROM (
    #       SELECT "namespaces". *
    #       ...
    #
    #       INTERSECT
    #
    #       SELECT "namespaces". *
    #       ...
    #     ) groups;
    #
    # members - An Array of ActiveRecord::Relation objects to use in the intersect.
    #
    # remove_duplicates - A boolean indicating if duplicate entries should be
    #                     removed. Defaults to true.
    #
    # alias_as - The alias to use for the sub query. Defaults to the name of the
    #            table of the current model.
    extend FromSetOperator
    define_set_operator Gitlab::SQL::Intersect
  end
end
