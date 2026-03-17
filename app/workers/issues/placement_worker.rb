# frozen_string_literal: true

module Issues
  class PlacementWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    idempotent!
    deduplicate :until_executed, including_scheduled: true
    feature_category :team_planning
    urgency :high
    worker_resource_boundary :cpu
    weight 2

    # Move at most the most recent 100 issues
    QUERY_LIMIT = 100

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(params, project_id = nil)
      # Passing an integer project_id to Issues::PlacementWorker is deprecated.
      # This is here to support existing jobs during upgrades.
      namespace = if params.is_a?(Hash)
                    Namespace.find_by_id(params['namespace_id'])
                  else
                    namespace_from_project_id(project_id)
                  end

      return unless namespace

      issue = find_representative_issue(namespace)
      return unless issue

      # Temporary disable moving null elements because of performance problems
      # For more information check https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4321
      return if issue.blocked_for_repositioning?

      # Move the oldest 100 unpositioned items to the end.
      # This is to deal with out-of-order execution of the worker,
      # while preserving creation order.
      to_place = Issue
                 .relative_positioning_query_base(issue)
                 .with_null_relative_position
                 .order({ created_at: :asc }, { id: :asc })
                 .limit(QUERY_LIMIT + 1)
                 .to_a

      leftover = to_place.pop if to_place.count > QUERY_LIMIT

      Issue.move_nulls_to_end(to_place)
      Issues::BaseService.new(container: nil).rebalance_if_needed(to_place.max_by(&:relative_position))
      Issues::PlacementWorker.perform_async({ 'namespace_id' => namespace.id }) if leftover.present?
    rescue RelativePositioning::NoSpaceLeft => e
      Gitlab::ErrorTracking.log_exception(e, namespace_id: namespace.id)
      Issues::RebalancingWorker.perform_async(nil, *issue.project.self_or_root_group_ids)
    end

    private

    def namespace_from_project_id(project_id)
      project = Project.find_by_id(project_id)
      return unless project

      return project.project_namespace if project.parent.user_namespace?

      project.root_ancestor
    end

    def find_representative_issue(namespace)
      projects = if namespace.project_namespace?
                   [namespace.project]
                 else
                   namespace.all_projects
                 end

      Issue.in_projects(projects).take
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
