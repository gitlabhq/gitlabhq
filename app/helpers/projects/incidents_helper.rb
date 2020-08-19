# frozen_string_literal: true

module Projects::IncidentsHelper
  def incidents_data(project)
    {
      'project-path' => project.full_path,
      'new-issue-path' => new_project_issue_path(project),
      'incident-template-name' => 'incident',
      'incident-type' => 'incident',
      'issue-path' => project_issues_path(project),
      'empty-list-svg-path' => image_path('illustrations/incident-empty-state.svg')
    }
  end
end

Projects::IncidentsHelper.prepend_if_ee('EE::Projects::IncidentsHelper')
