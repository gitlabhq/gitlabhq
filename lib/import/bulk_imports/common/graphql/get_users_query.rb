# frozen_string_literal: true

module Import
  module BulkImports
    module Common
      module Graphql
        class GetUsersQuery
          def to_s
            <<-GRAPHQL
              query($ids: [ID!], $cursor: String) {
                users(ids: $ids, after: $cursor) {
                  pageInfo {
                    next_page: endCursor
                    has_next_page: hasNextPage
                  }
                  nodes {
                    id
                    name
                    username
                  }
                }
              }
            GRAPHQL
          end

          def variables
            {}
          end
        end
      end
    end
  end
end
