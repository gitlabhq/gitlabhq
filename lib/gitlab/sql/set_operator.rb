# frozen_string_literal: true

module Gitlab
  module SQL
    # Class for building SQL set operator statements (UNION, INTERSECT, and
    # EXCEPT).
    #
    # ORDER BYs are dropped from the relations as the final sort order is not
    # guaranteed any way.
    #
    # remove_order: false option can be used in special cases where the
    # ORDER BY is necessary for the query.
    #
    # Example usage:
    #
    #     union = Gitlab::SQL::Union.new([user.personal_projects, user.projects])
    #     sql   = union.to_sql
    #
    #     Project.where("id IN (#{sql})")
    class SetOperator
      def initialize(relations, remove_duplicates: true, remove_order: true)
        @relations = relations
        @remove_duplicates = remove_duplicates
        @remove_order = remove_order
      end

      def self.operator_keyword
        raise NotImplementedError
      end

      def to_sql
        # Some relations may include placeholders for prepared statements, these
        # aren't incremented properly when joining relations together this way.
        # By using "unprepared_statements" we remove the usage of placeholders
        # (thus fixing this problem), at a slight performance cost.
        fragments = ActiveRecord::Base.connection.unprepared_statement do
          relations.map do |rel|
            remove_order ? rel.reorder(nil).to_sql : rel.to_sql
          end.reject(&:blank?)
        end

        if fragments.any?
          "(" + fragments.join(")\n#{operator_keyword_fragment}\n(") + ")"
        else
          'NULL'
        end
      end

      # UNION [ALL] | INTERSECT [ALL] | EXCEPT [ALL]
      def operator_keyword_fragment
        remove_duplicates ? self.class.operator_keyword : "#{self.class.operator_keyword} ALL"
      end

      private

      attr_reader :relations, :remove_duplicates, :remove_order
    end
  end
end
