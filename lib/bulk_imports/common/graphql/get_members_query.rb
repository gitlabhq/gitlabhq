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
              members: #{members_type}(relations: [#{relations}], first: $per_page, after: $cursor) {
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
                    username: username
                    name: name
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

        def relations
          if context.entity.group?
            group_relations
          else
            project_relations
          end
        end

        def source_version
          Gitlab::VersionInfo.parse(context.bulk_import.source_version)
        end

        def group_relations
          base_relation = "DIRECT INHERITED"
          base_relation += " SHARED_FROM_GROUPS" if source_version >= Gitlab::VersionInfo.parse("14.7.0")
          base_relation
        end

        def project_relations
          base_relation = "DIRECT INHERITED INVITED_GROUPS"
          base_relation += " SHARED_INTO_ANCESTORS" if source_version >= Gitlab::VersionInfo.parse("16.0.0")
          base_relation
        end
      end
    end
  end
end
