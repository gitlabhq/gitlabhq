# frozen_string_literal: true

module Mutations
  module Ci
    module Catalog
      module Resources
        class Unpublish < BaseMutation
          graphql_name 'CatalogResourceUnpublish'

          authorize :add_catalog_resource

          argument :id, ::Types::GlobalIDType[::Ci::Catalog::Resource],
            required: true,
            description: 'Global ID of the catalog resource to unpublish.'

          def resolve(id:)
            catalog_resource = ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(id))
            authorize!(catalog_resource&.project)

            catalog_resource.unpublish!

            {
              errors: []
            }
          end
        end
      end
    end
  end
end
