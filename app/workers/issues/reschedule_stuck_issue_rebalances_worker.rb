# frozen_string_literal: true

module Issues
  class RescheduleStuckIssueRebalancesWorker
    include ApplicationWorker
    include CronjobQueue

    data_consistency :sticky

    idempotent!
    urgency :low
    feature_category :team_planning
    deduplicate :until_executed, including_scheduled: true

    def perform
      namespace_ids, project_ids = ::Gitlab::Issues::Rebalancing::State.fetch_rebalancing_groups_and_projects

      return if namespace_ids.blank? && project_ids.blank?

      namespaces = Namespace.id_in(namespace_ids)
      projects = Project.id_in(project_ids)

      Issues::RebalancingWorker.bulk_perform_async_with_contexts(
        namespaces,
        arguments_proc: ->(namespace) { [nil, nil, namespace.id] },
        context_proc: ->(namespace) { { namespace: namespace } }
      )

      Issues::RebalancingWorker.bulk_perform_async_with_contexts(
        projects,
        arguments_proc: ->(project) { [nil, project.id, nil] },
        context_proc: ->(project) { { project: project } }
      )
    end
  end
end
