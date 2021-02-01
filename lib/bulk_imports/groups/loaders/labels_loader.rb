# frozen_string_literal: true

module BulkImports
  module Groups
    module Loaders
      class LabelsLoader
        def initialize(*); end

        def load(context, data)
          Labels::CreateService.new(data).execute(group: context.entity.group)
        end
      end
    end
  end
end
