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

          argument :search, GraphQL::Types::String,
            required: false,
            description: 'Search term to filter versions by name.'

          extras [:lookahead]

          alias_method :catalog_resource, :object

          def resolve(lookahead:, name: nil, search: nil)
            if name
              ::Ci::Catalog::Resources::Version.for_catalog_resources(catalog_resource).by_name(name)
            elsif search
              ::Ci::Catalog::Resources::Version.for_catalog_resources(catalog_resource).search_by_version(search)
            else
              fetch_catalog_resources_versions(per_resource_limit(lookahead))
            end
          end

          private

          def fetch_catalog_resources_versions(limit)
            BatchLoader::GraphQL.for(catalog_resource).batch(key: limit, default_value: []) do |resources, loader|
              versions = ::Ci::Catalog::Resources::Version.versions_for_catalog_resources(resources, limit: limit)
              resources_by_id = resources.index_by(&:id)

              versions.group_by(&:catalog_resource_id).each do |catalog_resource_id, resource_versions|
                loader.call(resources_by_id[catalog_resource_id], resource_versions)
              end
            end
          end

          def per_resource_limit(lookahead)
            arguments = lookahead.arguments
            return unless arguments[:first]
            return if arguments.values_at(:after, :before, :last).any?
            return if lookahead.selects?(:count)

            arguments[:first].clamp(0, context.schema.default_max_page_size) + 1
          end
        end
      end
    end
  end
end
