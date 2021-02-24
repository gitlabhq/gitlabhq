# frozen_string_literal: true

module CompareHelper
  def create_mr_button?(from: params[:from], to: params[:to], source_project: @project, target_project: @target_project)
    from.present? &&
      to.present? &&
      from != to &&
      can?(current_user, :create_merge_request_from, source_project) &&
      can?(current_user, :create_merge_request_in, target_project) &&
      target_project.repository.branch_exists?(from) &&
      source_project.repository.branch_exists?(to)
  end

  def create_mr_path(from: params[:from], to: params[:to], source_project: @project, target_project: @target_project)
    project_new_merge_request_path(
      target_project,
      merge_request: {
        source_project_id: source_project.id,
        source_branch: to,
        target_project_id: target_project.id,
        target_branch: from
      }
    )
  end

  def target_projects(source_project)
    MergeRequestTargetProjectFinder
      .new(current_user: current_user, source_project: source_project, project_feature: :repository)
      .execute(include_routes: true)
  end

  def project_compare_selector_data(project, merge_request, params)
    {
      project_compare_index_path: project_compare_index_path(project),
      refs_project_path: refs_project_path(project),
      params_from: params[:from],
      params_to: params[:to],
      project_merge_request_path: merge_request.present? ? project_merge_request_path(project, merge_request) : '',
      create_mr_path: create_mr_button? ? create_mr_path : ''
    }.tap do |data|
      if Feature.enabled?(:compare_repo_dropdown, project, default_enabled: :yaml)
        data[:project_to] = { id: project.id, name: project.full_path }.to_json
        data[:projects_from] = target_projects(project).map { |project| { id: project.id, name: project.full_path } }.to_json
      end
    end
  end
end
