# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      # Given a class, it finds or creates a new object
      # (initializes in the case of Label) at group or project level.
      # If it does not exist in the group, it creates it at project level.
      #
      # Example:
      #   `ObjectBuilder.build(Label, label_attributes)`
      #    finds or initializes a label with the given attributes.
      #
      # It also adds some logic around Group Labels/Milestones for edge cases.
      class ObjectBuilder < Base::ObjectBuilder
        def self.build(*args)
          ::Project.transaction do
            super
          end
        end

        def initialize(klass, attributes)
          super

          @group = @attributes['group']
          @project = @attributes['project']
        end

        def find
          return if epic? && group.nil?
          return find_diff_commit_user if diff_commit_user?

          super
        end

        private

        attr_reader :group, :project

        def where_clauses
          [
            where_clause_base,
            where_clause_for_title,
            where_clause_for_klass
          ].compact
        end

        # Returns Arel clause `"{table_name}"."project_id" = {project.id}` if project is present
        # For example: merge_request has :target_project_id, and we are searching by :iid
        # or, if group is present:
        # `"{table_name}"."project_id" = {project.id} OR "{table_name}"."group_id" = {group.id}`
        def where_clause_base
          [].tap do |clauses|
            clauses << table[:project_id].eq(project.id) if project
            clauses << table[:group_id].in(group.self_and_ancestors_ids) if group
          end.reduce(:or)
        end

        # Returns Arel clause for a particular model or `nil`.
        def where_clause_for_klass
          return attrs_to_arel(attributes.slice('filename')).and(table[:issue_id].eq(nil)) if design?

          attrs_to_arel(attributes.slice('iid')) if merge_request?
        end

        def prepare_attributes
          attributes.dup.tap do |atts|
            atts.delete('group') unless epic?

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

            atts['importing'] = true if klass.ancestors.include?(Importable)
          end
        end

        def find_diff_commit_user
          find_with_cache do
            MergeRequest::DiffCommitUser
              .find_or_create(@attributes['name'], @attributes['email'])
          end
        end

        def label?
          klass == Label
        end

        def milestone?
          klass == Milestone
        end

        def merge_request?
          klass == MergeRequest
        end

        def epic?
          klass == Epic
        end

        def design?
          klass == DesignManagement::Design
        end

        def diff_commit_user?
          klass == MergeRequest::DiffCommitUser
        end

        # If an existing group milestone used the IID
        # claim the IID back and set the group milestone to use one available
        # This is necessary to fix situations like the following:
        #  - Importing into a user namespace project with exported group milestones
        #    where the IID of the Group milestone could conflict with a project one.
        def claim_iid
          # The milestone has to be a group milestone, as it's the only case where
          # we set the IID as the maximum. The rest of them are fixed.
          milestone = project.milestones.find_by(iid: attributes['iid'])

          return unless milestone

          milestone.iid = nil
          milestone.ensure_project_iid!
          milestone.save!
        end
      end
    end
  end
end
