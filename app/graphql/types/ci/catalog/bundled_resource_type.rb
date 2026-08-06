# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      # rubocop: disable Graphql/AuthorizeTypes -- cell-wide readable, no per-record authorization
      class BundledResourceType < BaseObject
        graphql_name 'CiCatalogBundledResource'
        description 'A GitLab-maintained bundled CI/CD catalog resource on the current cell.'

        authorize_granular_token permissions: :read_catalog_bundled_resource,
          boundary: :instance,
          boundary_type: :instance

        connection_type_class Types::CountableConnectionType

        field :id, GraphQL::Types::ID, null: false,
          experiment: { milestone: '19.3' },
          description: 'ID of the bundled catalog resource.'

        field :name, GraphQL::Types::String, null: true,
          experiment: { milestone: '19.3' },
          description: 'Name of the bundled catalog resource.'

        field :description, GraphQL::Types::String, null: true,
          experiment: { milestone: '19.3' },
          description: 'Description of the bundled catalog resource.'

        field :full_path, GraphQL::Types::ID, null: true,
          experiment: { milestone: '19.3' },
          description: 'Full path of the bundled catalog resource (for example, `components/sast`).'

        field :server_fqdn, GraphQL::Types::String, null: true,
          experiment: { milestone: '19.3' },
          description: 'FQDN of the GitLab instance that maintains the bundled catalog resource.'

        # rubocop:disable GraphQL/ExtractType -- flat scalar fields mirroring CiCatalogResource, not a sub-entity
        field :latest_released_at, Types::TimeType, null: true,
          experiment: { milestone: '19.3' },
          description: "Release date of the bundled catalog resource's latest version."

        field :latest_version_name, GraphQL::Types::String, null: true,
          experiment: { milestone: '19.3' },
          description: 'Name of the latest version of the bundled catalog resource (for example, `v1.2.3`).'
        # rubocop:enable GraphQL/ExtractType

        def latest_version_name
          BatchLoader::GraphQL.for(object).batch do |resources, loader|
            versions_by_resource_id = ::Ci::Catalog::BundledResources::Version
              .for_bundled_resources(resources.map(&:id))
              .order_by_semantic_version_desc
              .group_by(&:catalog_bundled_resource_id)

            resources.each do |resource|
              loader.call(resource, versions_by_resource_id[resource.id]&.first&.semver&.to_s)
            end
          end
        end
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
