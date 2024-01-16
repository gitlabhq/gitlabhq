# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This class represents a CI/CD Catalog resource version.
      # Only versions which contain valid CI components are included in this table.
      class Version < ::ApplicationRecord
        include BulkInsertableAssociations

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
        # After we denormalize the `released_at` column, we won't need to use `joins(:release)` and keyset_order_*
        scope :order_by_released_at_asc, -> { joins(:release).keyset_order_by_released_at_asc }
        scope :order_by_released_at_desc, -> { joins(:release).keyset_order_by_released_at_desc }

        delegate :sha, :released_at, :author_id, to: :release

        after_destroy :update_catalog_resource
        after_save :update_catalog_resource

        class << self
          # In the future, we should support semantic versioning.
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/427286
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

            # We need to use an alias for the `releases` table here so that it does not
            # conflict with `joins(:release)` in the `order_by_released_at_*` scope.
            join_query = Ci::Catalog::Resources::Version
              .where(catalog_resources_table[:id].eq(arel_table[:catalog_resource_id]))
              .joins("INNER JOIN releases AS rel ON rel.id = #{table_name}.release_id")
              .order(Arel.sql('rel.released_at DESC'))
              .limit(1)

            Ci::Catalog::Resources::Version
              .from("(VALUES #{catalog_resources_id_list}) #{catalog_resources_table.name} (id)")
              .joins("INNER JOIN LATERAL (#{join_query.to_sql}) #{table_name} ON TRUE")
          end

          def keyset_order_by_released_at_asc
            keyset_order = Gitlab::Pagination::Keyset::Order.build([
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: :released_at,
                column_expression: Release.arel_table[:released_at],
                order_expression: Release.arel_table[:released_at].asc,
                nullable: :not_nullable,
                distinct: false
              ),
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: :id,
                order_expression: Release.arel_table[:id].asc,
                nullable: :not_nullable,
                distinct: true
              )
            ])

            reorder(keyset_order)
          end

          def keyset_order_by_released_at_desc
            keyset_order = Gitlab::Pagination::Keyset::Order.build([
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: :released_at,
                column_expression: Release.arel_table[:released_at],
                order_expression: Release.arel_table[:released_at].desc,
                nullable: :not_nullable,
                distinct: false
              ),
              Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
                attribute_name: :id,
                order_expression: Release.arel_table[:id].desc,
                nullable: :not_nullable,
                distinct: true
              )
            ])

            reorder(keyset_order)
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

        private

        def update_catalog_resource
          catalog_resource.update_latest_released_at!
        end
      end
    end
  end
end

Ci::Catalog::Resources::Version.prepend_mod_with('Ci::Catalog::Resources::Version')
