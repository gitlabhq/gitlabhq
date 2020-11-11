# frozen_string_literal: true

module BulkImports
  module Common
    module Loaders
      class EntityLoader
        def initialize(*args); end

        def load(context, entity)
          context.entity.bulk_import.entities.create!(entity)
        end
      end
    end
  end
end
