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
        def initialize(klass, attributes)
          super

          @group = @attributes['group']
          @project = @attributes['project']
        end

        def find
          return if group_relation_without_group?
          return find_diff_commit_user if diff_commit_user?
          return find_diff_commit if diff_commit?
          return find_work_item_type if work_item_type?
          return find_pipeline if pipeline?

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

          attrs_to_arel(attributes.slice('iid', 'target_project_id')) if merge_request?
        end

        def prepare_attributes
          attributes.dup.tap do |atts|
            atts.delete('group') unless group_level_object?

            if label?
              atts['type'] = 'ProjectLabel' # Always create project labels
              atts.delete('group_id')
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
          find_or_create_diff_commit_user(@attributes['name'], @attributes['email'])
        end

        def find_diff_commit
          row = @attributes.dup

          # Diff commits come in two formats:
          #
          # 1. The old format where author/committer details are separate fields
          # 2. The new format where author/committer details are nested objects,
          #    and pre-processed by `find_diff_commit_user`.
          #
          # The code here ensures we support both the old and new format.
          aname = row.delete('author_name')
          amail = row.delete('author_email')
          cname = row.delete('committer_name')
          cmail = row.delete('committer_email')
          author = row.delete('commit_author')
          committer = row.delete('committer')

          row['commit_author'] = author ||
            find_or_create_diff_commit_user(aname, amail)

          row['committer'] = committer ||
            find_or_create_diff_commit_user(cname, cmail)

          MergeRequestDiffCommit.new(row)
        end

        def find_or_create_diff_commit_user(name, email)
          find_with_cache([MergeRequest::DiffCommitUser, name, email]) do
            MergeRequest::DiffCommitUser.find_or_create(name, email)
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
          klass == ::DesignManagement::Design
        end

        def diff_commit_user?
          klass == MergeRequest::DiffCommitUser
        end

        def diff_commit?
          klass == MergeRequestDiffCommit
        end

        def work_item_type?
          klass == ::WorkItems::Type
        end

        def pipeline?
          klass == ::Ci::Pipeline
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

        def group_relation_without_group?
          group_level_object? && group.nil?
        end

        def group_level_object?
          epic?
        end

        def find_work_item_type
          base_type = @attributes['base_type']

          # Using a tmp key to invalidate cache. Should be removed in next release
          # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/497857
          find_with_cache([::WorkItems::Type, base_type, :tmp_correct_id]) do
            if ::WorkItems::Type.base_types.key?(base_type)
              ::WorkItems::Type.default_by_type(base_type)
            else
              ::WorkItems::Type.default_issue_type
            end
          end
        end

        def find_pipeline
          # Here we should referencing only existing pipelines
          # Only the 'iid' and `project` attributes should be present
          ::Ci::Pipeline.find_by(iid: attributes['iid'], project_id: project.id)
        end
      end
    end
  end
end

Gitlab::ImportExport::Project::ObjectBuilder.prepend_mod
