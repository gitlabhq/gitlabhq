# frozen_string_literal: true

module Issues
  class RebalancingWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    idempotent!
    urgency :low
    feature_category :team_planning
    deduplicate :until_executed, including_scheduled: true

    def perform(ignore = nil, project_id = nil, root_namespace_id = nil)
      # we need to have exactly one of the project_id and root_namespace_id params be non-nil
      raise ArgumentError, "Expected only one of the params project_id: #{project_id} and root_namespace_id: #{root_namespace_id}" if project_id && root_namespace_id
      return if project_id.nil? && root_namespace_id.nil?
      return if ::Gitlab::Issues::Rebalancing::State.rebalance_recently_finished?(project_id, root_namespace_id)

      # pull the projects collection to be rebalanced either the project if namespace is not a group(i.e. user namespace)
      # or the root namespace, this also makes the worker backward compatible with previous version where a project_id was
      # passed as the param
      projects_to_rebalance = projects_collection(project_id, root_namespace_id)

      # something might have happened with the namespace between scheduling the worker and actually running it,
      # maybe it was removed.
      if projects_to_rebalance.blank?
        Gitlab::ErrorTracking.log_exception(
          ArgumentError.new("Projects to be rebalanced not found for arguments: project_id #{project_id}, root_namespace_id: #{root_namespace_id}"),
          { project_id: project_id, root_namespace_id: root_namespace_id })

        return
      end

      Issues::RelativePositionRebalancingService.new(projects_to_rebalance).execute
    rescue Issues::RelativePositionRebalancingService::TooManyConcurrentRebalances => e
      Gitlab::ErrorTracking.log_exception(e, root_namespace_id: root_namespace_id, project_id: project_id)
    end

    private

    def projects_collection(project_id, root_namespace_id)
      # we can have either project_id(older version) or project_id if project is part of a user namespace and not a group
      # or root_namespace_id(newer version) never both.
      return Project.id_in([project_id]) if project_id

      Namespace.find_by_id(root_namespace_id)&.all_projects
    end
  end
end
