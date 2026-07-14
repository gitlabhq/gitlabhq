# frozen_string_literal: true

module API
  module Entities
    class PersonalAccessTokenGranularScope < Grape::Entity
      expose :access, documentation: { type: 'String', example: 'personal_projects' }
      expose :permissions, documentation: { type: 'Array', example: ['read_job'] }

      expose :project_id, documentation: { type: 'Integer', format: 'int64', example: 3 } do |granular_scope, options|
        next unless granular_scope.namespace.is_a?(::Namespaces::ProjectNamespace)

        # All render paths pass a prebuilt namespace_id => project_id map, so project_id is resolved
        # without a per-scope query. The direct load is a defensive fallback for reuse without the map.
        project_ids_by_namespace_id = options[:project_ids_by_namespace_id]
        next project_ids_by_namespace_id[granular_scope.namespace_id] if project_ids_by_namespace_id

        granular_scope.namespace.project&.id
      end

      expose :group_id, documentation: { type: 'Integer', format: 'int64', example: 5 } do |granular_scope|
        granular_scope.namespace_id if granular_scope.namespace.is_a?(::Group)
      end
    end
  end
end
