# frozen_string_literal: true

# Groups::ProjectsRequiringAuthorizationsRefresh::OnTransferFinder
#
# Given a group, this finder can be used to obtain a list of Project IDs of projects
# that requires their `project_authorizations` records to be refreshed in the event where
# the group has been transferred.

module Groups
  module ProjectsRequiringAuthorizationsRefresh
    class OnTransferFinder < Base
      def execute
        ids_of_projects_in_hierarchy_and_project_shares(@group).to_a
      end
    end
  end
end
