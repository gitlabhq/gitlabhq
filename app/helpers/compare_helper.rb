# frozen_string_literal: true

module CompareHelper
  def create_mr_button?(source_project:, from:, to: nil, target_project: nil)
    target_project ||= source_project.default_merge_request_target
    to ||= target_project.default_branch

    from.present? &&
      to.present? &&
      from != to &&
      can?(current_user, :create_merge_request_from, source_project) &&
      can?(current_user, :create_merge_request_in, target_project) &&
      target_project.repository.branch_exists?(to) &&
      source_project.repository.branch_exists?(from)
  end

  def create_mr_path(from:, source_project:, to: nil, target_project: nil, mr_params: {})
    merge_request_params = {
      source_branch: from
    }

    merge_request_params[:target_project_id] = target_project.id if target_project
    merge_request_params[:target_branch] = to if to

    project_new_merge_request_path(
      source_project,
      merge_request: merge_request_params.merge(mr_params)
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
      source_project: { id: project.id, name: project.full_path }.to_json,
      target_project: { id: @target_project.id, name: @target_project.full_path }.to_json,
      source_project_refs_path: refs_project_path(project),
      target_project_refs_path: refs_project_path(@target_project),
      params_from: params[:from],
      params_to: params[:to],
      straight: params[:straight]
    }.tap do |data|
      data[:projects_from] = target_projects(project).map do |target_project|
        { id: target_project.id, name: target_project.full_path }
      end.to_json

      data[:project_merge_request_path] =
        if merge_request.present?
          project_merge_request_path(project, merge_request)
        else
          ''
        end

      # The `from` and `to` params are inverted in the compare page. The route is `/compare/:from...:to`, but the UI
      # correctly shows `:to` as the "Source" (i.e. the `from` for MR), and `:from` as "Target" (i.e. the `to` for MR).
      data[:create_mr_path] =
        if create_mr_button?(from: params[:to], to: params[:from], source_project: project, target_project: @target_project)
          create_mr_path(from: params[:to], to: params[:from], source_project: project, target_project: @target_project)
        else
          ''
        end
    end
  end
end
