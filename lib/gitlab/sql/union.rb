module Gitlab
  module SQL
    # Class for building SQL UNION statements.
    #
    # ORDER BYs are dropped from the relations as the final sort order is not
    # guaranteed any way.
    #
    # Example usage:
    #
    #     union = Gitlab::SQL::Union.new(user.personal_projects, user.projects)
    #     sql   = union.to_sql
    #
    #     Project.where("id IN (#{sql})")
    class Union
      def initialize(relations)
        @relations = relations
      end

      def to_sql
        # Some relations may include placeholders for prepared statements, these
        # aren't incremented properly when joining relations together this way.
        # By using "unprepared_statements" we remove the usage of placeholders
        # (thus fixing this problem), at a slight performance cost.
        fragments = ActiveRecord::Base.connection.unprepared_statement do
          @relations.map do |rel|
            rel.reorder(nil).to_sql
          end
        end

        fragments.join("\nUNION\n")
      end
    end
  end
end
