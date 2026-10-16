# frozen_string_literal: true

module Security
  # This model represents a shadow table of the main database's projects table.
  # It is used for finding the organization_id for project-related data in SEC database
  class ProjectMirror < SecApplicationRecord
    self.table_name = 'sec_project_mirrors'
    self.primary_key = :project_id

    belongs_to :project

    class << self
      def sync!(event)
        project = event.project

        upsert(
          {
            project_id: event.project_id,
            namespace_id: project.namespace_id,
            organization_id: project.organization_id
          },
          unique_by: :project_id
        )
      end
    end
  end
end
