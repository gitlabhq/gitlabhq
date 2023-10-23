# frozen_string_literal: true

module Resolvers
  module Ci
    module Catalog
      class ResourcesResolver < BaseResolver
        include LooksAhead

        type ::Types::Ci::Catalog::ResourceType.connection_type, null: true

        argument :sort, ::Types::Ci::Catalog::ResourceSortEnum,
          required: false,
          description: 'Sort Catalog Resources by given criteria.'

        argument :project_path, GraphQL::Types::ID,
          required: false,
          description: 'Project with the namespace catalog.'

        def resolve_with_lookahead(project_path:, sort: nil)
          project = Project.find_by_full_path(project_path)

          apply_lookahead(
            ::Ci::Catalog::Listing
              .new(context[:current_user])
              .resources(namespace: project.root_namespace, sort: sort)
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
