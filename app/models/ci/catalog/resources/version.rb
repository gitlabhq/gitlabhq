# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This class represents a CI/CD Catalog resource version.
      # Only versions which contain valid CI components are included in this table.
      class Version < ::ApplicationRecord
        include BulkInsertableAssociations
        include SemanticVersionable

        semver_method :version
        validate_semver

        self.table_name = 'catalog_resource_versions'

        belongs_to :release, inverse_of: :catalog_resource_version
        belongs_to :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :versions
        belongs_to :project, inverse_of: :catalog_resource_versions
        has_many :components, class_name: 'Ci::Catalog::Resources::Component', inverse_of: :version

        validates :release, :catalog_resource, :project, presence: true

        scope :for_catalog_resources, ->(catalog_resources) { where(catalog_resource_id: catalog_resources) }
        scope :preloaded, -> { includes(:catalog_resource, project: [:route, { namespace: :route }], release: :author) }
        scope :by_name, ->(name) { joins(:release).merge(Release.where(tag: name)) }

        scope :order_by_created_at_asc, -> { reorder(created_at: :asc) }
        scope :order_by_created_at_desc, -> { reorder(created_at: :desc) }
        scope :order_by_released_at_asc, -> { reorder(released_at: :asc) }
        scope :order_by_released_at_desc, -> { reorder(released_at: :desc) }

        delegate :sha, :author_id, to: :release

        before_create :sync_with_release
        after_destroy :update_catalog_resource
        after_save :update_catalog_resource

        class << self
          def latest
            order_by_released_at_desc.first
          end

          # This query uses LATERAL JOIN to find the latest version for each catalog resource. To avoid
          # joining the `catalog_resources` table, we build an in-memory table using the resource ids.
          # Example:
          # SELECT ...
          # FROM (VALUES (CATALOG_RESOURCE_ID_1),(CATALOG_RESOURCE_ID_2)) catalog_resources (id)
          # INNER JOIN LATERAL (...)
          def latest_for_catalog_resources(catalog_resources)
            return none if catalog_resources.empty?

            catalog_resources_table = Ci::Catalog::Resource.arel_table
            catalog_resources_id_list = catalog_resources.map { |resource| "(#{resource.id})" }.join(',')

            join_query = Ci::Catalog::Resources::Version
              .where(catalog_resources_table[:id].eq(arel_table[:catalog_resource_id]))
              .order_by_released_at_desc
              .limit(1)

            Ci::Catalog::Resources::Version
              .from("(VALUES #{catalog_resources_id_list}) #{catalog_resources_table.name} (id)")
              .joins("INNER JOIN LATERAL (#{join_query.to_sql}) #{table_name} ON TRUE")
          end

          def order_by(order)
            case order.to_s
            when 'created_asc' then order_by_created_at_asc
            when 'created_desc' then order_by_created_at_desc
            when 'released_at_asc' then order_by_released_at_asc
            else
              order_by_released_at_desc
            end
          end
        end

        def name
          release.tag
        end

        def commit
          project.commit_by(oid: sha)
        end

        def path
          Gitlab::Routing.url_helpers.project_tag_path(project, name)
        end

        def readme
          project.repository.tree(sha).readme
        end

        def sync_with_release!
          sync_with_release
          save!
        end

        private

        # This column is denormalized from `releases`. It is first synced when a new version
        # is created. Any updates to the column are synced via Release model callback.
        def sync_with_release
          self.released_at = release.released_at
        end

        def update_catalog_resource
          catalog_resource.update_latest_released_at!
        end
      end
    end
  end
end

Ci::Catalog::Resources::Version.prepend_mod_with('Ci::Catalog::Resources::Version')
