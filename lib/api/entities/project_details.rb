# frozen_string_literal: true

module API
  module Entities
    class ProjectDetails < BasicProjectDetails
      expose :forked_from_project, using: Entities::BasicProjectDetails, if: ->(project, options) do
        project.forked? && Ability.allowed?(options[:current_user], :read_project, project.forked_from_project)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def self.preload_relation(projects_relation, _options = {})
        super(projects_relation).preload(
          project_group_links: { group: :route },
          fork_network: :root_project,
          fork_network_member: :forked_from_project,
          forked_from_project: [:route, :topics, :group, :project_feature, { namespace: [:route, :owner] }])
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def self.execute_batch_counting(projects_relation)
        # Call the count methods on every project, so the BatchLoader would load them all at
        # once when the entities are rendered
        projects_relation.filter_map(&:forked_from_project).each(&:forks_count)

        super
      end

      def self.repositories_for_preload(projects_relation)
        super + projects_relation.filter_map(&:forked_from_project).map(&:repository)
      end
    end
  end
end

API::Entities::ProjectDetails.prepend_mod_with('API::Entities::ProjectDetails', with_descendants: true)
