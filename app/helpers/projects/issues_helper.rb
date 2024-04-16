# frozen_string_literal: true

module Projects
  module IssuesHelper
    MAX_FORK_CHAIN_LENGTH = 20

    def create_mr_tracking_data(can_create_mr, can_create_confidential_mr)
      if can_create_confidential_mr
        { event_tracking: 'click_create_confidential_mr_issues_list' }
      elsif can_create_mr
        { event_tracking: 'click_create_mr_issues_list' }
      else
        {}
      end
    end

    def default_target(project)
      target = project.default_merge_request_target
      target = project unless target.present? && can?(current_user, :create_merge_request_in, target)

      target
    end

    def target_projects(project)
      return [] unless project.forked?

      target = default_target(project)

      MergeRequestTargetProjectFinder
        .new(current_user: current_user, source_project: project)
        .execute(include_routes: true)
        .limit(MAX_FORK_CHAIN_LENGTH)
        .filter { |target_project| can?(current_user, :create_merge_request_in, target_project) }
        .sort { |target_project, _| target_project.id == target.id ? 0 : 1 }
    end

    def merge_request_target_projects_options(issue, target, default_create_mr_path)
      default_project = default_target(target)
      target_projects(target).map do |project|
        value = refs_project_path(project, search: '')
        label = project.full_name
        project_create_mr_path = default_create_mr_path
        unless default_project.id == project.id
          project_create_mr_path = create_mr_path(
            from: issue.to_branch_name,
            source_project: target,
            target_project: project,
            to: project.default_branch,
            mr_params: { issue_iid: issue.iid }
          )
        end

        [
          nil,
          value,
          {
            label: label,
            data: { id: project.id, full_path: project.full_path, create_mr_path: project_create_mr_path }
          }
        ]
      end
    end
  end
end
