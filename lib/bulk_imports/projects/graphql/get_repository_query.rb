# frozen_string_literal: true

module BulkImports
  module Projects
    module Graphql
      module GetRepositoryQuery
        extend self

        def to_s
          <<-'GRAPHQL'
          query($full_path: ID!) {
            project(fullPath: $full_path) {
              httpUrlToRepo
            }
          }
          GRAPHQL
        end

        def variables(context)
          { full_path: context.entity.source_full_path }
        end

        def base_path
          %w[data project]
        end

        def data_path
          base_path
        end

        def page_info_path
          base_path << 'page_info'
        end
      end
    end
  end
end
