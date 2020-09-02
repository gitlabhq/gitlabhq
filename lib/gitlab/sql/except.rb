# frozen_string_literal: true

module Gitlab
  module SQL
    # Class for building SQL EXCEPT statements.
    #
    # ORDER BYs are dropped from the relations as the final sort order is not
    # guaranteed any way.
    #
    # Example usage:
    #
    #     except = Gitlab::SQL::Except.new([user.projects, user.personal_projects])
    #     sql    = except.to_sql
    #
    #     Project.where("id IN (#{sql})")
    class Except < SetOperator
      def self.operator_keyword
        'EXCEPT'
      end
    end
  end
end
