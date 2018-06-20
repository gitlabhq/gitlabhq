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
        return { project_id: @project.id } unless milestone? || label?

        @attributes.slice(:title).map do |key, value|
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
          if label?
            atts['type'] = 'ProjectLabel'
          elsif milestone?
            if atts['group_id']
              atts['iid'] = nil
              atts.delete('group_id')
            else
              claim_iid
            end
          end
        end
      end

      def label?
        @klass == Label || @klass < Label
      end

      def milestone?
        @klass == Milestone
      end

      def claim_iid
        group_milestone = @project.milestones.find_by(iid: @attributes['iid'])

        group_milestone.update!(iid: max_milestone_iid + 1) if group_milestone
      end

      def max_milestone_iid
        [@attributes['iid'], @project.milestones.maximum(:iid)].compact.max
      end
    end
  end
end
