# frozen_string_literal: true

module BulkImports
  module Projects
    module Graphql
      module Queryable
        attr_reader :context

        def initialize(context:)
          @context = context
        end

        def variables
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
