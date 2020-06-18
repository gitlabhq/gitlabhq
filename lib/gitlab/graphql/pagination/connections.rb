# frozen_string_literal: true

module Gitlab
  module Graphql
    module Pagination
      module Connections
        def self.use(schema)
          schema.connections.add(
            ActiveRecord::Relation,
            Gitlab::Graphql::Pagination::Keyset::Connection)

          schema.connections.add(
            Gitlab::Graphql::ExternallyPaginatedArray,
            Gitlab::Graphql::Pagination::ExternallyPaginatedArrayConnection)
        end
      end
    end
  end
end
