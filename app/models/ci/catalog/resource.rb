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
      has_many :components, class_name: 'Ci::Catalog::Resources::Component', inverse_of: :catalog_resource
      has_many :versions, class_name: 'Ci::Catalog::Resources::Version', inverse_of: :catalog_resource

      scope :for_projects, ->(project_ids) { where(project_id: project_ids) }
      scope :order_by_created_at_desc, -> { reorder(created_at: :desc) }
      scope :order_by_name_desc, -> { joins(:project).merge(Project.sorted_by_name_desc) }
      scope :order_by_name_asc, -> { joins(:project).merge(Project.sorted_by_name_asc) }

      delegate :avatar_path, :description, :name, :star_count, :forks_count, to: :project

      enum state: { draft: 0, published: 1 }

      def versions
        project.releases.order_released_desc
      end

      def latest_version
        project.releases.latest
      end
    end
  end
end

Ci::Catalog::Resource.prepend_mod_with('Ci::Catalog::Resource')
