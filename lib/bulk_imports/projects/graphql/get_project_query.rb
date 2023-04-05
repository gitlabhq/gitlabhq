# frozen_string_literal: true

module BulkImports
  module Projects
    module Graphql
      class GetProjectQuery
        include Queryable

        def to_s
          <<-'GRAPHQL'
          query($full_path: ID!) {
            project(fullPath: $full_path) {
              id
              name
              visibility
              created_at: createdAt
            }
          }
          GRAPHQL
        end
      end
    end
  end
end
