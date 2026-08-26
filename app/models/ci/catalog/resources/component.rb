# frozen_string_literal: true

module Ci
  module Catalog
    module Resources
      # This class represents a CI/CD Catalog resource component.
      # The data will be used as metadata of a component.
      class Component < ::ApplicationRecord
        ignore_column :resource_type, remove_with: '17.8', remove_after: '2024-11-18'

        self.table_name = 'catalog_resource_components'

        belongs_to :project, inverse_of: :ci_components
        belongs_to :catalog_resource, class_name: 'Ci::Catalog::Resource', inverse_of: :components
        belongs_to :version, class_name: 'Ci::Catalog::Resources::Version', inverse_of: :components
        has_many :last_usages, class_name: 'Ci::Catalog::Resources::Components::LastUsage', inverse_of: :component

        # BulkInsertSafe must be included after the `has_many` declaration, otherwise it raises
        # an error about the save callback that is auto generated for this association.
        include BulkInsertSafe

        enum :component_type, { template: 1 }

        validates :spec, json_schema: { filename: 'catalog_resource_component_spec' }
        validates :version, :catalog_resource, :project, :name, presence: true

        def self.names_by_ids(component_ids)
          where(id: component_ids).select(:id, :name)
        end

        def self.versions_by_component_ids(component_ids)
          joins(:version)
            .where(id: component_ids)
            .select('catalog_resource_components.id',
              'catalog_resource_components.version_id',
              "CONCAT_WS('.', catalog_resource_versions.semver_major, " \
                "catalog_resource_versions.semver_minor, " \
                "catalog_resource_versions.semver_patch) AS version_name")
        end

        def include_path
          "$CI_SERVER_FQDN/#{project.full_path}/#{name}@#{version.name}"
        end

        # `spec['inputs']` is stored in a jsonb column, which reorders object keys by length, so the
        # author's order is read from `inputs_order`. That key is absent for versions published before
        # it was introduced, which keep the length order until re-published or backfilled; see
        # https://gitlab.com/gitlab-org/gitlab/-/work_items/619182. It can also drift from `inputs`, so
        # it is a hint: names that no longer exist are dropped, and unlisted inputs are appended.
        def ordered_inputs
          inputs = spec['inputs']
          return {} unless inputs.is_a?(Hash)

          order = spec['inputs_order']
          return inputs unless order.is_a?(Array)

          inputs.slice(*order, *inputs.keys)
        end
      end
    end
  end
end

Ci::Catalog::Resources::Component.prepend_mod_with('Ci::Catalog::Resources::Component')
