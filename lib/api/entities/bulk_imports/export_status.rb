# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class ExportStatus < Grape::Entity
        expose :relation
        expose :status
        expose :error
        expose :updated_at
      end
    end
  end
end
