# frozen_string_literal: true

module BulkImports
  module Groups
    module Graphql
      module GetLabelsQuery
        extend self

        def to_s
          <<-'GRAPHQL'
          query ($full_path: ID!, $cursor: String, $per_page: Int) {
            group(fullPath: $full_path) {
              labels(first: $per_page, after: $cursor, onlyGroupLabels: true) {
                page_info: pageInfo {
                  next_page: endCursor
                  has_next_page: hasNextPage
                }
                nodes {
                  title
                  description
                  color
                  created_at: createdAt
                  updated_at: updatedAt
                }
              }
            }
          }
          GRAPHQL
        end

        def variables(context)
          {
            full_path: context.entity.source_full_path,
            cursor: context.tracker.next_page,
            per_page: ::BulkImports::Tracker::DEFAULT_PAGE_SIZE
          }
        end

        def base_path
          %w[data group labels]
        end

        def data_path
          base_path << 'nodes'
        end

        def page_info_path
          base_path << 'page_info'
        end
      end
    end
  end
end
