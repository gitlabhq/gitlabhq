# frozen_string_literal: true

module Resolvers
  module Ci
    module Catalog
      module Resources
        class VersionsResolver < BaseResolver
          type Types::Ci::Catalog::Resources::VersionType.connection_type, null: true

          # This allows a maximum of 1 call to the field that uses this resolver. If the
          # field is evaluated on more than one node, it causes performance degradation.
          extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1

          argument :name, GraphQL::Types::String,
            required: false,
            description: 'Name of the version.'

          argument :sort, Types::Ci::Catalog::Resources::VersionSortEnum,
            required: false,
            description: 'Sort versions by given criteria.'

          alias_method :catalog_resource, :object

          def resolve(name: nil, sort: nil)
            ::Ci::Catalog::Resources::VersionsFinder.new(catalog_resource, current_user, name: name, sort: sort).execute
          end
        end
      end
    end
  end
end
