# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      module Connections
        def self.use(schema)
          schema.connections.add(
            ::Gitlab::Graphql::Pagination::OffsetPaginatedRelation,
            ::Gitlab::Graphql::Pagination::OffsetActiveRecordRelationConnection)

          schema.connections.add(
            ActiveRecord::Relation,
            Gitlab::Graphql::Pagination::Keyset::Connection)

          schema.connections.add(
            Gitlab::Graphql::Loaders::LazyRelationLoader::RelationProxy,
            Gitlab::Graphql::Pagination::Keyset::Connection)

          schema.connections.add(
            Gitlab::Graphql::ExternallyPaginatedArray,
            Gitlab::Graphql::Pagination::ExternallyPaginatedArrayConnection)

          schema.connections.add(
            Array,
            Gitlab::Graphql::Pagination::ArrayConnection)
        end
      end
    end
  end
end
