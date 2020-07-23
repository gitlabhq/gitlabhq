# frozen_string_literal: true

module Projects::IncidentsHelper
  def incidents_data(project)
    {
      'project-path' => project.full_path
    }
  end
end
