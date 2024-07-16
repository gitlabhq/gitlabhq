# frozen_string_literal: true

module Ci
  # This model represents a shadow table of the main database's projects table.
  # It allows us to navigate the project and namespace hierarchy on the ci database.
  class ProjectMirror < ApplicationRecord
    include FromUnion

    belongs_to :project
    belongs_to :namespace_mirror, primary_key: :namespace_id, foreign_key: :namespace_id, inverse_of: :project_mirrors
    has_many :builds, primary_key: :project_id, foreign_key: :project_id, inverse_of: :project_mirror
    has_many :pipelines, primary_key: :project_id, foreign_key: :project_id, inverse_of: :project_mirror

    scope :by_namespace_id, ->(namespace_id) { where(namespace_id: namespace_id) }
    scope :by_project_id, ->(project_id) { where(project_id: project_id) }

    class << self
      def sync!(event)
        upsert({ project_id: event.project_id, namespace_id: event.project.namespace_id }, unique_by: :project_id)
      end
    end
  end
end
