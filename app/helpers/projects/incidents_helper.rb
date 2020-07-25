# frozen_string_literal: true

module Projects::IncidentsHelper
  def incidents_data(project)
    {
      'project-path' => project.full_path,
      'new-issue-path' => new_project_issue_path(project),
      'incident-template-name' => 'incident'
    }
  end
end
