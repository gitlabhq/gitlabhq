# frozen_string_literal: true

module Resolvers
  module Ci
    module Catalog
      class ResourcesResolver < BaseResolver
        include LooksAhead

        type ::Types::Ci::Catalog::ResourceType.connection_type, null: true

        argument :scope, ::Types::Ci::Catalog::ResourceScopeEnum,
          required: false,
          default_value: :all,
          description: 'Scope of the returned catalog resources.'

        argument :search, GraphQL::Types::String,
          required: false,
          description: 'Search term to filter the catalog resources by name or description.'

        argument :sort, ::Types::Ci::Catalog::ResourceSortEnum,
          required: false,
          description: 'Sort catalog resources by given criteria.'

        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/429636
        argument :project_path, GraphQL::Types::ID,
          required: false,
          description: 'Project with the namespace catalog.'

        def resolve_with_lookahead(scope:, project_path: nil, search: nil, sort: nil)
          project = Project.find_by_full_path(project_path)

          apply_lookahead(
            ::Ci::Catalog::Listing
              .new(context[:current_user])
              .resources(namespace: project&.root_namespace, sort: sort, search: search, scope: scope)
          )
        end

        private

        def preloads
          {
            web_path: { project: { namespace: :route } },
            readme_html: { project: :route }
          }
        end
      end
    end
  end
end
