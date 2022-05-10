# frozen_string_literal: true

module Groups
  module ProjectsRequiringAuthorizationsRefresh
    class Base
      def initialize(group)
        @group = group
      end

      private

      def ids_of_projects_in_hierarchy_and_project_shares(group)
        project_ids = Set.new

        ids_of_projects_in_hierarchy = group.all_projects.pluck(:id) # rubocop: disable CodeReuse/ActiveRecord
        ids_of_projects_in_project_shares = ids_of_projects_shared_with_self_and_descendant_groups(group)

        project_ids.merge(ids_of_projects_in_hierarchy)
        project_ids.merge(ids_of_projects_in_project_shares)

        project_ids
      end

      def ids_of_projects_shared_with_self_and_descendant_groups(group, batch_size: 50)
        project_ids = Set.new

        group.self_and_descendants_ids.each_slice(batch_size) do |group_ids|
          project_ids.merge(ProjectGroupLink.in_group(group_ids).pluck(:project_id)) # rubocop: disable CodeReuse/ActiveRecord
        end

        project_ids
      end
    end
  end
end
