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

        argument :verification_level, ::Types::Ci::Catalog::Resources::VerificationLevelEnum,
          required: false,
          description: 'Filter catalog resources by verification level.'

        def resolve_with_lookahead(scope:, search: nil, sort: nil, verification_level: nil)
          apply_lookahead(
            ::Ci::Catalog::Listing
              .new(context[:current_user])
              .resources(sort: sort, search: search, scope: scope, verification_level: verification_level)
          )
        end

        private

        def preloads
          {
            full_path: { project: [:route, { namespace: :route }] },
            web_path: { project: { namespace: :route } },
            readme_html: { project: :route }
          }
        end
      end
    end
  end
end
