# frozen_string_literal: true

module Resolvers
  module Ci
    module Catalog
      class ResourceResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource

        type ::Types::Ci::Catalog::ResourceType, null: true

        argument :id, ::Types::GlobalIDType[::Ci::Catalog::Resource],
          required: false,
          description: 'CI/CD Catalog resource global ID.'

        argument :full_path, GraphQL::Types::ID,
          required: false,
          description: 'CI/CD Catalog resource full path.'

        def ready?(**args)
          unless args[:id].present? ^ args[:full_path].present?
            raise Gitlab::Graphql::Errors::ArgumentError,
              "Exactly one of 'id' or 'full_path' arguments is required."
          end

          super
        end

        def resolve(id: nil, full_path: nil)
          catalog_resource = if full_path.present?
                               ::Ci::Catalog::Listing.new(current_user).find_resource(full_path: full_path)
                             else
                               ::Ci::Catalog::Listing.new(current_user).find_resource(id: id.model_id)
                             end

          raise_resource_not_available_error! unless catalog_resource

          catalog_resource
        end
      end
    end
  end
end
