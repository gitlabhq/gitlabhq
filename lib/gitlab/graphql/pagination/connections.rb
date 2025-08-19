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

          schema.connections.add(
            ::ClickHouse::Client::QueryBuilder,
            Gitlab::Graphql::Pagination::ClickHouseConnection
          )
        end
      end
    end
  end
end

Gitlab::Graphql::Pagination::Connections.prepend_mod
