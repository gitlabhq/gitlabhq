# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This class represents a CI/CD Catalog resource version.
      # Only versions which contain valid CI components are included in this table.
      class Version < ::ApplicationRecord
        self.table_name = 'catalog_resource_versions'

        belongs_to :release, inverse_of: :catalog_resource_version
        belongs_to :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :versions
        belongs_to :project, inverse_of: :catalog_resource_versions
        has_many :components, class_name: 'Ci::Catalog::Resources::Component', inverse_of: :version

        validates :release, :catalog_resource, :project, presence: true
      end
    end
  end
end

Ci::Catalog::Resources::Version.prepend_mod_with('Ci::Catalog::Resources::Version')
