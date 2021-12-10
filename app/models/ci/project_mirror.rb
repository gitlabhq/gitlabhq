# frozen_string_literal: true

module Ci
  # This model represents a shadow table of the main database's projects table.
  # It allows us to navigate the project and namespace hierarchy on the ci database.
  class ProjectMirror < ApplicationRecord
    belongs_to :project

    class << self
      def sync!(event)
        upsert({ project_id: event.project_id, namespace_id: event.project.namespace_id },
               unique_by: :project_id)
      end
    end
  end
end
