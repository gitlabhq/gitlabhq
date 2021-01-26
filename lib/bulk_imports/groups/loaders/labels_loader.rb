# frozen_string_literal: true

module BulkImports
  module Groups
    module Loaders
      class LabelsLoader
        def initialize(*); end

        def load(context, data)
          Array.wrap(data['nodes']).each do |entry|
            Labels::CreateService.new(entry)
              .execute(group: context.entity.group)
          end

          context.entity.update_tracker_for(
            relation: :labels,
            has_next_page: data.dig('page_info', 'has_next_page'),
            next_page: data.dig('page_info', 'end_cursor')
          )
        end
      end
    end
  end
end
