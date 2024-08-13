# frozen_string_literal: true

module Gitlab
  module DatabaseImporters
    module WorkItems
      module RelatedLinksRestrictionsImporter
        # This importer populates the default link restrictions for the base work item types that support this feature.
        # These rules are documented in https://docs.gitlab.com/ee/development/work_items.html#write-a-database-migration

        # rubocop:disable Metrics/AbcSize
        def self.upsert_restrictions
          epic = find_or_create_type(::WorkItems::Type::TYPE_NAMES[:epic])
          issue = find_or_create_type(::WorkItems::Type::TYPE_NAMES[:issue])
          task = find_or_create_type(::WorkItems::Type::TYPE_NAMES[:task])
          objective = find_or_create_type(::WorkItems::Type::TYPE_NAMES[:objective])
          key_result = find_or_create_type(::WorkItems::Type::TYPE_NAMES[:key_result])

          restrictions = [
            # Source can relate to target and target can relate to source
            { source_type_id: epic.id, target_type_id: epic.id, link_type: 0 },
            { source_type_id: epic.id, target_type_id: issue.id, link_type: 0 },
            { source_type_id: epic.id, target_type_id: task.id, link_type: 0 },
            { source_type_id: epic.id, target_type_id: objective.id, link_type: 0 },
            { source_type_id: epic.id, target_type_id: key_result.id, link_type: 0 },
            { source_type_id: issue.id, target_type_id: issue.id, link_type: 0 },
            { source_type_id: issue.id, target_type_id: task.id, link_type: 0 },
            { source_type_id: issue.id, target_type_id: objective.id, link_type: 0 },
            { source_type_id: issue.id, target_type_id: key_result.id, link_type: 0 },
            { source_type_id: task.id, target_type_id: task.id, link_type: 0 },
            { source_type_id: task.id, target_type_id: objective.id, link_type: 0 },
            { source_type_id: task.id, target_type_id: key_result.id, link_type: 0 },
            { source_type_id: objective.id, target_type_id: objective.id, link_type: 0 },
            { source_type_id: objective.id, target_type_id: key_result.id, link_type: 0 },
            { source_type_id: key_result.id, target_type_id: key_result.id, link_type: 0 },
            # Source can block target and target can be blocked by source
            { source_type_id: epic.id, target_type_id: epic.id, link_type: 1 },
            { source_type_id: epic.id, target_type_id: issue.id, link_type: 1 },
            { source_type_id: epic.id, target_type_id: task.id, link_type: 1 },
            { source_type_id: epic.id, target_type_id: objective.id, link_type: 1 },
            { source_type_id: epic.id, target_type_id: key_result.id, link_type: 1 },
            { source_type_id: issue.id, target_type_id: issue.id, link_type: 1 },
            { source_type_id: issue.id, target_type_id: epic.id, link_type: 1 },
            { source_type_id: issue.id, target_type_id: task.id, link_type: 1 },
            { source_type_id: issue.id, target_type_id: objective.id, link_type: 1 },
            { source_type_id: issue.id, target_type_id: key_result.id, link_type: 1 },
            { source_type_id: task.id, target_type_id: task.id, link_type: 1 },
            { source_type_id: task.id, target_type_id: epic.id, link_type: 1 },
            { source_type_id: task.id, target_type_id: issue.id, link_type: 1 },
            { source_type_id: task.id, target_type_id: objective.id, link_type: 1 },
            { source_type_id: task.id, target_type_id: key_result.id, link_type: 1 },
            { source_type_id: objective.id, target_type_id: objective.id, link_type: 1 },
            { source_type_id: objective.id, target_type_id: key_result.id, link_type: 1 },
            { source_type_id: key_result.id, target_type_id: key_result.id, link_type: 1 },
            { source_type_id: key_result.id, target_type_id: objective.id, link_type: 1 }
          ]

          ::WorkItems::RelatedLinkRestriction.upsert_all(
            restrictions,
            unique_by: :index_work_item_link_restrictions_on_source_link_type_target
          )
        end
        # rubocop:enable Metrics/AbcSize

        def self.find_or_create_type(name)
          type = ::WorkItems::Type.find_by_name(name)
          return type if type

          Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.upsert_types
          ::WorkItems::Type.find_by_name(name)
        end
      end
    end
  end
end
