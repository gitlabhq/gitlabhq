# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class Entity < Grape::Entity
        expose :id
        expose :bulk_import_id
        expose :status_name, as: :status
        expose :source_full_path
        expose :destination_name
        expose :destination_namespace
        expose :parent_id
        expose :namespace_id
        expose :project_id
        expose :created_at
        expose :updated_at
        expose :failures, using: EntityFailure
      end
    end
  end
end
