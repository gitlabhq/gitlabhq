module Gitlab
  module ImportExport
    class GroupProjectFinder
      def self.find_or_new(*args)
        Project.transaction do
          new(*args).find_or_new
        end
      end

      def self.find_or_create(*args)
        Project.transaction do
          new(*args).find_or_create
        end
      end

      def initialize(klass, attributes)
        @klass = klass
        @attributes = attributes
        @group = @attributes[:group]
        @project = @attributes[:project]
      end

      def find_or_new
        @klass.where(where_clause).first || @klass.new(project_attributes)
      end

      def find_or_create
        @klass.where(where_clause).first || @klass.create(project_attributes)
      end

      private

      def where_clause
        @attributes.except(:group, :project).map do |key, value|
          project_clause = table[key].eq(value).and(table[:project_id].eq(@project.id))

          if @group
            project_clause.or(table[key].eq(value).and(table[:group_id].eq(@group.id)))
          else
            project_clause
          end
        end.reduce(:or)
      end

      def table
        @table ||= @klass.arel_table
      end

      def project_attributes
        @attributes.except(:group).tap do |atts|
          atts['type'] = 'ProjectLabel' if label?
        end
      end

      def label?
        @klass == Label || @klass < Label
      end
    end
  end
end
