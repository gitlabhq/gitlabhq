# frozen_string_literal: true

module BulkImports
  module Groups
    module Graphql
      class GetProjectsQuery
        attr_reader :context

        def initialize(context:)
          @context = context
        end

        def to_s
          <<-GRAPHQL
          query($full_path: ID!, $cursor: String, $per_page: Int) {
            group(fullPath: $full_path) {
              projects(includeSubgroups: false, #{not_aimed_for_deletion}first: $per_page, after: $cursor) {
                page_info: pageInfo {
                  next_page: endCursor
                  has_next_page: hasNextPage
                }
                nodes {
                  id
                  name
                  path
                  full_path: fullPath
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
          %w[data group projects]
        end

        def data_path
          base_path << 'nodes'
        end

        def page_info_path
          base_path << 'page_info'
        end

        private

        def source_version
          Gitlab::VersionInfo.parse(context.bulk_import.source_version)
        end

        def not_aimed_for_deletion
          return if source_version < Gitlab::VersionInfo.parse('16.1.0')

          'notAimedForDeletion: true, '
        end
      end
    end
  end
end
