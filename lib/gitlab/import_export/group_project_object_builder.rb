module Gitlab
  module ImportExport
    # Given a class, it finds or creates a new object
    # (initializes in the case of Label) at group or project level
    # If it does not exist in the group, it creates it at project level
    #
    # For example:
    # `GroupProjectObjectBuilder.build(Label, label_attributes)`
    #  finds or initializes a label with the given attributes.
    #
    # It also adds some logic around Group Labels/Milestones for edge cases.
    class GroupProjectObjectBuilder
      def self.build(*args)
        Project.transaction do
          new(*args).find
        end
      end

      def initialize(klass, attributes)
        @klass = klass < Label ? Label : klass
        @attributes = attributes
        @group = @attributes[:group]
        @project = @attributes[:project]
      end

      def find
        find_or_action do
          label? ? @klass.new(project_attributes) : @klass.create(project_attributes)
        end
      end

      private

      def find_or_action(&block)
        @klass.where(where_clause).first || yield
      end

      def where_clause
        return { project_id: @project.id } unless milestone? || label?

        @attributes.slice('title').map do |key, value|
          if @group
            project_clause(key, value).or(group_clause(key, value))
          else
            project_clause(key, value)
          end
        end.reduce(:or)
      end

      def group_clause(key, value)
        table[key].eq(value).and(table[:group_id].eq(@group.id))
      end

      def project_clause(key, value)
        table[key].eq(value).and(table[:project_id].eq(@project.id))
      end

      def table
        @table ||= @klass.arel_table
      end

      def project_attributes
        @attributes.except(:group).tap do |atts|
          if label?
            atts['type'] = 'ProjectLabel' # Always create project labels
          elsif milestone?
            if atts['group_id'] # Transform new group milestones into project ones
              atts['iid'] = nil
              atts.delete('group_id')
            else
              claim_iid
            end
          end
        end
      end

      def label?
        @klass == Label
      end

      def milestone?
        @klass == Milestone
      end

      # If an existing group milesone used the IID
      # claim the IID back and set the group milestone to use one available
      # This is neccessary to fix situations like the following:
      #  - Importing into a user namespace project with exported group milestones
      #    where the IID of the Group milestone could conflict with a project one.
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
