# frozen_string_literal: true

module BulkImports
  module Common
    module Graphql
      class GetMembersQuery
        attr_reader :context

        def initialize(context:)
          @context = context
        end

        def to_s
          <<-GRAPHQL
          query($full_path: ID!, $cursor: String, $per_page: Int) {
            portable: #{context.entity.entity_type}(fullPath: $full_path) {
              members: #{members_type}(relations: [DIRECT, INHERITED], first: $per_page, after: $cursor) {
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
                    user_gid: id
                    public_email: publicEmail
                  }
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

        def data_path
          base_path << 'nodes'
        end

        def page_info_path
          base_path << 'page_info'
        end

        private

        def base_path
          %w[data portable members]
        end

        def members_type
          if context.entity.group?
            'groupMembers'
          else
            'projectMembers'
          end
        end
      end
    end
  end
end
