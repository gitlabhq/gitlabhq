# frozen_string_literal: true

# Groups::ProjectsRequiringAuthorizationsRefresh::OnDirectMembershipFinder
#
# Given a group, this finder can be used to obtain a list of Project IDs of projects
# that requires their `project_authorizations` records to be refreshed in the event where
# a member has been added/removed/updated in the group.

module Groups
  module ProjectsRequiringAuthorizationsRefresh
    class OnDirectMembershipFinder < Base
      def execute
        project_ids = Set.new

        project_ids.merge(ids_of_projects_in_hierarchy_and_project_shares(@group))
        project_ids.merge(ids_of_projects_in_hierarchy_and_project_shares_of_shared_groups(@group))

        project_ids.to_a
      end

      private

      def ids_of_projects_in_hierarchy_and_project_shares_of_shared_groups(group, batch_size: 10)
        project_ids = Set.new

        group.shared_groups.each_batch(of: batch_size) do |shared_groups_batch|
          shared_groups_batch.each do |shared_group|
            project_ids.merge(ids_of_projects_in_hierarchy_and_project_shares(shared_group))
          end
        end

        project_ids
      end
    end
  end
end
