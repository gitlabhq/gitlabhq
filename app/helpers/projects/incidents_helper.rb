# frozen_string_literal: true

module Projects::IncidentsHelper
  def incidents_data(project, params)
    {
      'project-path' => project.full_path,
      'new-issue-path' => new_project_issue_path(project),
      'incident-template-name' => 'incident',
      'incident-type' => 'incident',
      'issue-path' => project_issues_path(project),
      'empty-list-svg-path' => image_path('illustrations/empty-state/empty-scan-alert-md.svg'),
      'text-query': params[:search],
      'author-username-query': params[:author_username],
      'assignee-username-query': params[:assignee_username],
      'can-create-incident': create_issue_type_allowed?(project, :incident).to_s
    }
  end
end

Projects::IncidentsHelper.prepend_mod_with('Projects::IncidentsHelper')
