# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This class represents a CI/CD Catalog resource component.
      # The data will be used as metadata of a component.
      class Component < ::ApplicationRecord
        self.table_name = 'catalog_resource_components'

        include IgnorableColumns
        ignore_column :inputs, remove_with: '17.1', remove_after: '2024-05-16'
        ignore_column :path, remove_with: '17.1', remove_after: '2024-05-20'

        belongs_to :project, inverse_of: :ci_components
        belongs_to :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :components
        belongs_to :version, class_name: 'Ci::Catalog::Resources::Version', inverse_of: :components
        has_many :usages, class_name: 'Ci::Catalog::Resources::Components::Usage', inverse_of: :component

        # BulkInsertSafe must be included after the `has_many` declaration, otherwise it raises
        # an error about the save callback that is auto generated for this association.
        include BulkInsertSafe

        enum resource_type: { template: 1 }

        validates :spec, json_schema: { filename: 'catalog_resource_component_spec' }
        validates :version, :catalog_resource, :project, :name, presence: true

        def include_path
          "#{Gitlab.config.gitlab_ci.server_fqdn}/#{project.full_path}/#{name}@#{version.name}"
        end
      end
    end
  end
end

Ci::Catalog::Resources::Component.prepend_mod_with('Ci::Catalog::Resources::Component')
