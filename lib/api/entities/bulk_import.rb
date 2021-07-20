# frozen_string_literal: true

module API
  module Entities
    class BulkImport < Grape::Entity
      expose :id
      expose :status_name, as: :status
      expose :source_type
      expose :created_at
      expose :updated_at
    end
  end
end
