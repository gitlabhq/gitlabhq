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
        verify_select_values!(relations) if Rails.env.test? || Rails.env.development?
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
        fragments = ApplicationRecord.connection.unprepared_statement do
          relations.filter_map do |rel|
            next if rel.is_a?(ActiveRecord::Relation) && rel.null_relation?

            sql = remove_order ? rel.reorder(nil).to_sql : rel.to_sql
            sql.presence
          end
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

      def verify_select_values!(relations)
        all_select_values = relations.map do |relation|
          if relation.respond_to?(:select_values)
            relation.select_values
          else
            relation.projections # Handle Arel based subqueries
          end
        end

        unless all_select_values.map(&:size).uniq.one?
          relation_select_sizes = all_select_values.map.with_index do |select_values, index|
            if select_values.empty?
              "Relation ##{index}: *, all columns"
            else
              "Relation ##{index}: #{select_values.size} select values"
            end
          end

          exception_text = <<~EOF
          Relations with uneven select values were passed. The UNION query could break when the underlying table changes (add or remove columns).

          #{relation_select_sizes.join("\n")}
          EOF

          raise(exception_text)
        end
      end
    end
  end
end
