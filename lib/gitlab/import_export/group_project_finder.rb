module Gitlab
  module ImportExport
    class GroupProjectFinder
      def self.find(*args)
        new(*args).find
      end

      def initialize(klass, attributes)
        @klass = klass
        @attributes = attributes
        @group_id = @attributes['group_id']
        @project_id = @attributes['project_id']
      end

      def find
        @klass.where(where_clause)
      end

      private

      def where_clause
        @attributes.except('group_id', 'project_id').map do |key, value|
          table[key].eq(value).and(table[:group_id].eq(@group_id))
            .or(table[key].eq(value).and(table[:project_id].eq(@project_id)))
        end.reduce(:or)
      end

      def table
        @table ||= @klass.arel_table
      end
    end
  end
end
