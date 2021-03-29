# frozen_string_literal: true

module Gitlab
  module SQL
    # Class for building SQL UNION statements.
    #
    # By default ORDER BYs are dropped from the relations as the final sort
    # order is not guaranteed any way.
    #
    # Example usage:
    #
    #     union = Gitlab::SQL::Union.new([user.personal_projects, user.projects])
    #     sql   = union.to_sql
    #
    #     Project.where("id IN (#{sql})")
    class Union < SetOperator
      def self.operator_keyword
        'UNION'
      end
    end
  end
end
