# frozen_string_literal: true

module API
  module Entities
    module BulkImports
      class Entity < Grape::Entity
        expose :id, documentation: { type: 'Integer', example: 1 }
        expose :bulk_import_id, documentation: { type: 'Integer', example: 1 }
        expose :status_name, as: :status, documentation: {
          type: 'String', example: 'created', values: %w[created started finished timeout failed]
        }
        expose :entity_type, documentation: { type: 'String', values: %w[group project] }
        expose :source_full_path, documentation: { type: 'String', example: 'source_group' }
        expose :full_path, as: :destination_full_path, documentation: {
          type: 'String', example: 'some_group/source_project'
        }
        expose :destination_name, documentation: { type: 'String', example: 'destination_slug' } # deprecated
        expose :destination_slug, documentation: { type: 'String', example: 'destination_slug' }
        expose :destination_namespace, documentation: { type: 'String', example: 'destination_path' }
        expose :parent_id, documentation: { type: 'Integer', example: 1 }
        expose :namespace_id, documentation: { type: 'Integer', example: 1 }
        expose :project_id, documentation: { type: 'Integer', example: 1 }
        expose :created_at, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
        expose :updated_at, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
        expose :failures, using: EntityFailure, documentation: { is_array: true }
        expose :migrate_projects, documentation: { type: 'Boolean', example: true }
        expose :migrate_memberships, documentation: { type: 'Boolean', example: true }
        expose :has_failures, documentation: { type: 'Boolean', example: false }
        expose :checksums, as: :stats, documentation: { type: 'object' }
      end
    end
  end
end
