# frozen_string_literal: true

module Gitlab
  module Search
    module SortOptions
      def sort_and_direction(order_by, sort)
        # Due to different uses of sort param in web vs. API requests we prefer
        # order_by when present
        case [order_by, sort]
        when %w[created_at asc], [nil, 'created_asc']
          :created_at_asc
        when %w[created_at desc], [nil, 'created_desc']
          :created_at_desc
        else
          :unknown
        end
      end
      module_function :sort_and_direction # rubocop: disable Style/AccessModifierDeclarations
    end
  end
end
