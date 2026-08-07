# frozen_string_literal: true

module Ci
  module Catalog
    module BundledResources
      class Component < ::ApplicationRecord
        include FileStoreMounter

        self.table_name = 'catalog_bundled_resource_components'

        NAME_REGEX = /\A#{::Ci::Catalog::ComponentsProject::NAME_PATTERN}\z/

        mount_file_store_uploader Ci::Catalog::BundledResources::ComponentUploader

        belongs_to :bundled_resource, class_name: 'Ci::Catalog::BundledResource',
          foreign_key: :catalog_bundled_resource_id, inverse_of: :components, optional: false
        belongs_to :version, class_name: 'Ci::Catalog::BundledResources::Version',
          foreign_key: :catalog_bundled_version_id, inverse_of: :components, optional: false

        validates :name, presence: true, length: { maximum: 255 },
          format: { with: NAME_REGEX },
          uniqueness: { scope: :catalog_bundled_version_id }
        validates :spec, json_schema: { filename: 'catalog_resource_component_spec', size_limit: 64.kilobytes }
      end
    end
  end
end
