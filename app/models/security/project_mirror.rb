# frozen_string_literal: true

module Security
  # This model represents a shadow table of the main database's projects table.
  # It is used for finding the organization_id for project-related data in SEC database
  class ProjectMirror < SecApplicationRecord
    self.table_name = 'sec_project_mirrors'
    self.primary_key = :project_id

    belongs_to :project
  end
end
