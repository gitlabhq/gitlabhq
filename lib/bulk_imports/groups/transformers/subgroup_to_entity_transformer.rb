# frozen_string_literal: true

module BulkImports
  module Groups
    module Transformers
      class SubgroupToEntityTransformer
        def transform(context, entry)
          {
            source_type: :group_entity,
            source_full_path: entry['full_path'],
            destination_name: entry['path'],
            destination_namespace: context.entity.group.full_path,
            parent_id: context.entity.id,
            migrate_projects: context.entity.migrate_projects
          }
        end
      end
    end
  end
end
