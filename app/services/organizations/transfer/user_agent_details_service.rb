# frozen_string_literal: true

module Organizations
  module Transfer
    class UserAgentDetailsService
      ISSUE_BATCH_SIZE = 1_000
      SNIPPET_BATCH_SIZE = 1_000

      def initialize(group:, old_organization:, new_organization:)
        @group = group
        @old_organization = old_organization
        @new_organization = new_organization
      end

      def execute
        unless group.root?
          Gitlab::AppLogger.warn(
            message: 'Skipping user_agent_details transfer: group is not a root group',
            group_id: group.id
          )
          return
        end

        transfer_issue_details
        transfer_project_snippet_details
      end

      private

      attr_reader :group, :old_organization, :new_organization

      # rubocop:disable CodeReuse/ActiveRecord -- Queries specific to this service
      def transfer_issue_details
        Gitlab::Pagination::Keyset::Iterator
          .new(scope: hierarchy_issues)
          .each_batch(of: ISSUE_BATCH_SIZE) do |issues|
            transfer_details_for('Issue', issues.map(&:id))
          end
      end

      def hierarchy_issues
        Issue
          .within_namespace_hierarchy(group)
          .select(:id, :created_at)
          .order(:created_at, :id)
      end

      def transfer_project_snippet_details
        Namespace.project_namespaces.by_root_id(group.id).each_batch do |namespaces|
          project_ids = Project.where(project_namespace_id: namespaces.select(:id)).ids
          next if project_ids.empty?

          Snippet.where(project_id: project_ids).each_batch(of: SNIPPET_BATCH_SIZE) do |snippets|
            transfer_details_for('Snippet', snippets.select(:id))
          end
        end
      end

      def transfer_details_for(subject_type, subject_ids)
        UserAgentDetail
          .where(organization_id: old_organization.id, subject_type: subject_type,
            subject_id: subject_ids)
          .update_all(organization_id: new_organization.id)
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end
