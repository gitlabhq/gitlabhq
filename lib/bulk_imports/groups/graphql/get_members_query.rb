# frozen_string_literal: true

module BulkImports
  module Groups
    module Graphql
      module GetMembersQuery
        extend self
        def to_s
          <<-'GRAPHQL'
          query($full_path: ID!, $cursor: String) {
            group(fullPath: $full_path) {
              group_members: groupMembers(relations: DIRECT, first: 100, after: $cursor) {
                page_info: pageInfo {
                  next_page: endCursor
                  has_next_page: hasNextPage
                }
                nodes {
                  created_at: createdAt
                  updated_at: updatedAt
                  expires_at: expiresAt
                  access_level: accessLevel {
                    integer_value: integerValue
                  }
                  user {
                    public_email: publicEmail
                  }
                }
              }
            }
          }
          GRAPHQL
        end

        def variables(context)
          {
            full_path: context.entity.source_full_path,
            cursor: context.tracker.next_page
          }
        end

        def base_path
          %w[data group group_members]
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
