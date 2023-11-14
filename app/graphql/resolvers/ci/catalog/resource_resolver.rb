# frozen_string_literal: true

module Resolvers
  module Ci
    module Catalog
      class ResourceResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource

        authorize :read_code

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
          if full_path.present?
            project = Project.find_by_full_path(full_path)
            authorize!(project)

            raise_resource_not_available_error! unless project.catalog_resource

            project.catalog_resource
          else
            catalog_resource = ::Gitlab::Graphql::Lazy.force(GitlabSchema.find_by_gid(id))
            authorize!(catalog_resource&.project)

            catalog_resource
          end
        end
      end
    end
  end
end
