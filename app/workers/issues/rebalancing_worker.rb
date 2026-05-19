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

      # Resolve to a namespace. The project_id param is retained for backward compatibility with
      # in-flight jobs enqueued before we standardised on namespace_id; new callers always pass
      # root_namespace_id via issue.namespace.work_item_positioning_root.id.
      namespace = rebalance_target(project_id, root_namespace_id)

      # something might have happened with the namespace between scheduling the worker and actually running it,
      # maybe it was removed.
      if namespace.nil?
        Gitlab::ErrorTracking.log_exception(
          ArgumentError.new("Namespace to be rebalanced not found for arguments: project_id #{project_id}, root_namespace_id: #{root_namespace_id}"),
          { project_id: project_id, root_namespace_id: root_namespace_id })

        return
      end

      return if ::Gitlab::Issues::Rebalancing::State.rebalance_recently_finished?(namespace)

      Issues::RelativePositionRebalancingService.new(namespace).execute
    rescue Issues::RelativePositionRebalancingService::TooManyConcurrentRebalances => e
      Gitlab::ErrorTracking.log_exception(e, root_namespace_id: root_namespace_id, project_id: project_id)
    end

    private

    def rebalance_target(project_id, root_namespace_id)
      return Project.find_by_id(project_id)&.project_namespace if project_id

      Namespace.find_by_id(root_namespace_id)
    end
  end
end
