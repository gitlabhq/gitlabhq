# frozen_string_literal: true

# We use the Keyset / Stable cursor connection by default for ActiveRecord::Relation.
# However, there are times when that may not be powerful enough (yet), and we
# want to use standard offset pagination.
module Gitlab
  module Graphql
    module Pagination
      class OffsetActiveRecordRelationConnection < GraphQL::Pagination::ActiveRecordRelationConnection
        prepend ::Gitlab::Graphql::ConnectionRedaction
        include ::Gitlab::Graphql::ConnectionCollectionMethods
      end
    end
  end
end
