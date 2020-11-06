# frozen_string_literal: true

module BulkImports
  module Common
    module Loaders
      class EntitiesLoader
        def initialize(*args); end

        def load(context, entities)
          bulk_import = context.entity.bulk_import

          entities.each do |entity|
            bulk_import.entities.create!(entity)
          end
        end
      end
    end
  end
end
