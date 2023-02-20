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
    def perform(issue_id, project_id = nil)
      issue = find_issue(issue_id, project_id)
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
      Issues::PlacementWorker.perform_async(nil, leftover.project_id) if leftover.present?
    rescue RelativePositioning::NoSpaceLeft => e
      Gitlab::ErrorTracking.log_exception(e, issue_id: issue_id, project_id: project_id)
      Issues::RebalancingWorker.perform_async(nil, *root_namespace_id_to_rebalance(issue, project_id))
    end

    def find_issue(issue_id, project_id)
      return Issue.id_in(issue_id).take if issue_id

      project = Project.id_in(project_id).take
      return unless project

      project.issues.take
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def root_namespace_id_to_rebalance(issue, project_id)
      project_id = project_id.presence || issue.project_id
      Project.find(project_id)&.self_or_root_group_ids
    end
  end
end
