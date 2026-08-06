# frozen_string_literal: true

module Ci
  module Catalog
    class BundledResource < ::ApplicationRecord
      self.table_name = 'catalog_bundled_resources'

      has_many :versions, class_name: 'Ci::Catalog::BundledResources::Version',
        foreign_key: :catalog_bundled_resource_id, inverse_of: :bundled_resource
      has_many :components, class_name: 'Ci::Catalog::BundledResources::Component',
        foreign_key: :catalog_bundled_resource_id, inverse_of: :bundled_resource

      validates :server_fqdn, presence: true, length: { maximum: 255 }
      validates :name, presence: true, length: { maximum: 255 }
      validates :full_path, presence: true, length: { maximum: 1024 },
        uniqueness: { scope: :server_fqdn, case_sensitive: false }
      validates :description, length: { maximum: 1024 }

      scope :ordered_by_id, -> { order(id: :asc) }

      def latest_version
        versions.order_by_semantic_version_desc.first
      end

      def latest_version_name
        latest_version&.semver&.to_s
      end
    end
  end
end
