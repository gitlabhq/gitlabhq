module Gitlab
  module ImportExport
    class GroupProjectFinder
      def self.find_or_new(*args)
        new(*args).find_or_new
      end

      def self.find_or_create(*args)
        new(*args).find_or_create
      end

      def initialize(klass, attributes)
        @klass = klass
        @attributes = attributes
        @group_id = @attributes['group_id']
        @project_id = @attributes['project_id']
      end

      def find_or_new
        @klass.where(where_clause).first || @klass.new(project_attributes)
      end

      def find_or_create
        @klass.where(where_clause).first || @klass.create(project_attributes)
      end

      private

      def where_clause
        @attributes.except('group_id', 'project_id').map do |key, value|
          project_clause = table[key].eq(value).and(table[:project_id].eq(@project_id))

          if @group_id
              project_clause.or(table[key].eq(value).and(table[:group_id].eq(@group_id)))
          else
            project_clause
          end
        end.reduce(:or)
      end

      def table
        @table ||= @klass.arel_table
      end

      def project_attributes
        @attributes.except('group_id').tap do |atts|
          atts['type'] = 'ProjectLabel' if label?
        end
      end

      def label?
        @klass == Label || @klass < Label
      end
    end
  end
end
