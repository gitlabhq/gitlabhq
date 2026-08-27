# frozen_string_literal: true

module Ci
  module Catalog
    module BundledResources
      class Version < ::ApplicationRecord
        include CacheMarkdownField
        include SemanticVersionable

        self.table_name = 'catalog_bundled_resource_versions'

        belongs_to :bundled_resource, class_name: 'Ci::Catalog::BundledResource',
          foreign_key: :catalog_bundled_resource_id, inverse_of: :versions, optional: false
        has_many :components, class_name: 'Ci::Catalog::BundledResources::Component',
          foreign_key: :catalog_bundled_version_id, inverse_of: :version

        cache_markdown_field :readme

        validates :semver_prerelease, length: { maximum: 255 }

        scope :for_bundled_resources, ->(bundled_resource_ids) {
          where(catalog_bundled_resource_id: bundled_resource_ids)
        }
        scope :with_semver, -> { where.not(semver_major: nil) }
        scope :without_prerelease, -> { where(semver_prerelease: nil) }

        class << self
          def latest
            with_semver.without_prerelease.order_by_semantic_version_desc.first
          end
        end
      end
    end
  end
end
