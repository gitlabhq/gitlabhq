# frozen_string_literal: true

module Ci
  module Catalog
    # This class represents a CI/CD Catalog resource.
    # A Catalog resource is normally associated to a project.
    # This model connects to the `main` database because of its
    # dependency on the Project model and its need to join with that table
    # in order to generate the CI/CD catalog.
    class Resource < ::ApplicationRecord
      include Gitlab::SQL::Pattern

      self.table_name = 'catalog_resources'

      belongs_to :project
      has_many :components, class_name: 'Ci::Catalog::Resources::Component', foreign_key: :catalog_resource_id,
        inverse_of: :catalog_resource
      has_many :versions, class_name: 'Ci::Catalog::Resources::Version', inverse_of: :catalog_resource

      scope :for_projects, ->(project_ids) { where(project_id: project_ids) }
      scope :search, ->(query) { fuzzy_search(query, [:name, :description], use_minimum_char_limit: false) }

      scope :order_by_created_at_desc, -> { reorder(created_at: :desc) }
      scope :order_by_created_at_asc, -> { reorder(created_at: :asc) }
      scope :order_by_name_desc, -> { reorder(arel_table[:name].desc.nulls_last) }
      scope :order_by_name_asc, -> { reorder(arel_table[:name].asc.nulls_last) }
      scope :order_by_latest_released_at_desc, -> { reorder(arel_table[:latest_released_at].desc.nulls_last) }
      scope :order_by_latest_released_at_asc, -> { reorder(arel_table[:latest_released_at].asc.nulls_last) }

      delegate :avatar_path, :star_count, :forks_count, to: :project

      enum state: { draft: 0, published: 1 }

      before_create :sync_with_project

      def versions
        project.releases.order_released_desc
      end

      def latest_version
        project.releases.latest
      end

      def unpublish!
        update!(state: :draft)
      end

      def publish!
        update!(state: :published)
      end

      def sync_with_project!
        sync_with_project
        save!
      end

      private

      def sync_with_project
        self.name = project.name
        self.description = project.description
      end
    end
  end
end

Ci::Catalog::Resource.prepend_mod_with('Ci::Catalog::Resource')
