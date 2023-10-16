# frozen_string_literal: true

class AddWorkItemsRelatedLinkRestrictions < Gitlab::Database::Migration[2.1]
  RELATED = 0
  BLOCKS = 1

  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class RelatedLinkRestriction < MigrationRecord
    self.table_name = 'work_item_related_link_restrictions'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  # rubocop:disable Metrics/AbcSize
  def up
    epic = WorkItemType.find_by_name_and_namespace_id('Epic', nil)
    issue = WorkItemType.find_by_name_and_namespace_id('Issue', nil)
    task = WorkItemType.find_by_name_and_namespace_id('Task', nil)
    objective = WorkItemType.find_by_name_and_namespace_id('Objective', nil)
    key_result = WorkItemType.find_by_name_and_namespace_id('Key Result', nil)

    unless epic && issue && task && objective && key_result
      Gitlab::AppLogger.warn('Default WorkItemType records are missing, not adding RelatedLinkRestrictions.')

      return
    end

    restrictions = [
      { source_type_id: epic.id, target_type_id: epic.id, link_type: RELATED },
      { source_type_id: epic.id, target_type_id: issue.id, link_type: RELATED },
      { source_type_id: epic.id, target_type_id: task.id, link_type: RELATED },
      { source_type_id: epic.id, target_type_id: objective.id, link_type: RELATED },
      { source_type_id: epic.id, target_type_id: key_result.id, link_type: RELATED },
      { source_type_id: issue.id, target_type_id: issue.id, link_type: RELATED },
      { source_type_id: issue.id, target_type_id: task.id, link_type: RELATED },
      { source_type_id: issue.id, target_type_id: objective.id, link_type: RELATED },
      { source_type_id: issue.id, target_type_id: key_result.id, link_type: RELATED },
      { source_type_id: task.id, target_type_id: task.id, link_type: RELATED },
      { source_type_id: task.id, target_type_id: objective.id, link_type: RELATED },
      { source_type_id: task.id, target_type_id: key_result.id, link_type: RELATED },
      { source_type_id: objective.id, target_type_id: objective.id, link_type: RELATED },
      { source_type_id: objective.id, target_type_id: key_result.id, link_type: RELATED },
      { source_type_id: key_result.id, target_type_id: key_result.id, link_type: RELATED },
      { source_type_id: epic.id, target_type_id: epic.id, link_type: BLOCKS },
      { source_type_id: epic.id, target_type_id: issue.id, link_type: BLOCKS },
      { source_type_id: epic.id, target_type_id: task.id, link_type: BLOCKS },
      { source_type_id: epic.id, target_type_id: objective.id, link_type: BLOCKS },
      { source_type_id: epic.id, target_type_id: key_result.id, link_type: BLOCKS },
      { source_type_id: issue.id, target_type_id: issue.id, link_type: BLOCKS },
      { source_type_id: issue.id, target_type_id: epic.id, link_type: BLOCKS },
      { source_type_id: issue.id, target_type_id: task.id, link_type: BLOCKS },
      { source_type_id: issue.id, target_type_id: objective.id, link_type: BLOCKS },
      { source_type_id: issue.id, target_type_id: key_result.id, link_type: BLOCKS },
      { source_type_id: task.id, target_type_id: task.id, link_type: BLOCKS },
      { source_type_id: task.id, target_type_id: epic.id, link_type: BLOCKS },
      { source_type_id: task.id, target_type_id: issue.id, link_type: BLOCKS },
      { source_type_id: task.id, target_type_id: objective.id, link_type: BLOCKS },
      { source_type_id: task.id, target_type_id: key_result.id, link_type: BLOCKS },
      { source_type_id: objective.id, target_type_id: objective.id, link_type: BLOCKS },
      { source_type_id: objective.id, target_type_id: key_result.id, link_type: BLOCKS },
      { source_type_id: key_result.id, target_type_id: key_result.id, link_type: BLOCKS },
      { source_type_id: key_result.id, target_type_id: objective.id, link_type: BLOCKS }
    ]

    RelatedLinkRestriction.upsert_all(
      restrictions,
      unique_by: :index_work_item_link_restrictions_on_source_link_type_target
    )
  end
  # rubocop:enable Metrics/AbcSize

  def down
    # Until this point the restrictions table was empty so we can delete all records when migrating down
    RelatedLinkRestriction.delete_all
  end
end
