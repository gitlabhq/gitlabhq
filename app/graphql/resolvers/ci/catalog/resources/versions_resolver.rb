# frozen_string_literal: true

module Resolvers
  module Ci
    module Catalog
      module Resources
        class VersionsResolver < BaseResolver
          type Types::Ci::Catalog::Resources::VersionType.connection_type, null: true

          argument :name, GraphQL::Types::String,
            required: false,
            description: 'Name of the version.'

          alias_method :catalog_resource, :object

          def resolve(name: nil)
            if name
              ::Ci::Catalog::Resources::Version.for_catalog_resources(catalog_resource).by_name(name)
            else
              fetch_catalog_resources_versions
            end
          end

          private

          def fetch_catalog_resources_versions
            BatchLoader::GraphQL.for(catalog_resource).batch(default_value: []) do |catalog_resources, loader|
              versions = ::Ci::Catalog::Resources::Version.versions_for_catalog_resources(catalog_resources)

              versions.group_by(&:catalog_resource).each do |catalog_resource, resource_versions|
                loader.call(catalog_resource, resource_versions)
              end
            end
          end
        end
      end
    end
  end
end
