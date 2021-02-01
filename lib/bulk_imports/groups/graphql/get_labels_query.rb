# frozen_string_literal: true

module BulkImports
  module Groups
    module Graphql
      module GetLabelsQuery
        extend self

        def to_s
          <<-'GRAPHQL'
          query ($full_path: ID!, $cursor: String) {
            group(fullPath: $full_path) {
              labels(first: 100, after: $cursor) {
                page_info: pageInfo {
                  end_cursor: endCursor
                  has_next_page: hasNextPage
                }
                nodes {
                  title
                  description
                  color
                }
              }
            }
          }
          GRAPHQL
        end

        def variables(entity)
          {
            full_path: entity.source_full_path,
            cursor: entity.next_page_for(:labels)
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
