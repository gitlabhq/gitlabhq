# frozen_string_literal: true

module BulkImports
  module Projects
    module Graphql
      class GetSnippetRepositoryQuery
        include Queryable

        def to_s
          <<-'GRAPHQL'
          query($full_path: ID!) {
            project(fullPath: $full_path) {
              snippets {
                page_info: pageInfo {
                  next_page: endCursor
                  has_next_page: hasNextPage
                }
                nodes {
                  title
                  createdAt
                  httpUrlToRepo
                }
              }
            }
          }
          GRAPHQL
        end

        def variables
          {
            full_path: context.entity.source_full_path,
            cursor: context.tracker.next_page,
            per_page: ::BulkImports::Tracker::DEFAULT_PAGE_SIZE
          }
        end

        def base_path
          %w[data project snippets]
        end

        def data_path
          base_path << 'nodes'
        end
      end
    end
  end
end
