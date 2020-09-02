# frozen_string_literal: true

module Gitlab
  module SQL
    # Class for building SQL INTERSECT statements.
    #
    # ORDER BYs are dropped from the relations as the final sort order is not
    # guaranteed any way.
    #
    # Example usage:
    #
    #     hierarchies = [group1.self_and_hierarchy, group2.self_and_hierarchy]
    #     intersect   = Gitlab::SQL::Intersect.new(hierarchies)
    #     sql         = intersect.to_sql
    #
    #     Project.where("id IN (#{sql})")
    class Intersect < SetOperator
      def self.operator_keyword
        'INTERSECT'
      end
    end
  end
end
