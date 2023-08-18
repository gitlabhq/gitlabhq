# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This class represents a CI/CD Catalog resource component.
      # The data will be used as metadata of a component.
      class Component < ::ApplicationRecord
        self.table_name = 'catalog_resource_components'

        belongs_to :project, inverse_of: :ci_components
        belongs_to :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :components
        belongs_to :version, class_name: 'Ci::Catalog::Resources::Version', inverse_of: :components

        enum resource_type: { template: 1 }

        validates :inputs, json_schema: { filename: 'catalog_resource_component_inputs' }
        validates :version, :catalog_resource, :project, :name, presence: true
      end
    end
  end
end

Ci::Catalog::Resources::Component.prepend_mod_with('Ci::Catalog::Resources::Component')
