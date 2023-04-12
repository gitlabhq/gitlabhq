# frozen_string_literal: true

module Ci
  module Catalog
    # This class represents a CI/CD Catalog resource.
    # A Catalog resource is normally associated to a project.
    # This model connects to the `main` database because of its
    # dependency on the Project model and its need to join with that table
    # in order to generate the CI/CD catalog.
    class Resource < ::ApplicationRecord
      self.table_name = 'catalog_resources'

      belongs_to :project

      scope :for_projects, ->(project_ids) { where(project_id: project_ids) }

      delegate :avatar_path, :description, :name, to: :project

      def versions
        project.releases.order_released_desc
      end

      def latest_version
        versions.first
      end
    end
  end
end
