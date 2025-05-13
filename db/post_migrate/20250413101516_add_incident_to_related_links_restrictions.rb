# frozen_string_literal: true

class AddIncidentToRelatedLinksRestrictions < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  BASE_TYPES = {
    issue: 0,
    incident: 1,
    task: 4,
    objective: 5,
    key_result: 6,
    epic: 7
  }.freeze

  class WorkItemType < MigrationRecord
    self.table_name = 'work_item_types'
  end

  class RelatedLinkRestriction < MigrationRecord
    self.table_name = 'work_item_related_link_restrictions'
  end

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  def up
    work_item_types = fetch_work_item_types
    missing_types = work_item_types.select { |_key, value| value.nil? }.keys

    return say("Required WorkItemType records are missing: #{missing_types.join(', ')}") unless missing_types.empty?

    incident = work_item_types[:incident]
    epic = work_item_types[:epic]
    issue = work_item_types[:issue]
    task = work_item_types[:task]
    objective = work_item_types[:objective]
    key_result = work_item_types[:key_result]

    restrictions = [
      { source_type_id: epic.id, target_type_id: incident.id, link_type: 0 },
      { source_type_id: issue.id, target_type_id: incident.id, link_type: 0 },
      { source_type_id: task.id, target_type_id: incident.id, link_type: 0 },
      { source_type_id: objective.id, target_type_id: incident.id, link_type: 0 },
      { source_type_id: key_result.id, target_type_id: incident.id, link_type: 0 },
      { source_type_id: incident.id, target_type_id: incident.id, link_type: 0 },

      { source_type_id: epic.id, target_type_id: incident.id, link_type: 1 },
      { source_type_id: issue.id, target_type_id: incident.id, link_type: 1 },
      { source_type_id: task.id, target_type_id: incident.id, link_type: 1 },
      { source_type_id: objective.id, target_type_id: incident.id, link_type: 1 },
      { source_type_id: key_result.id, target_type_id: incident.id, link_type: 1 },
      { source_type_id: incident.id, target_type_id: incident.id, link_type: 1 },
      { source_type_id: incident.id, target_type_id: epic.id, link_type: 1 },
      { source_type_id: incident.id, target_type_id: issue.id, link_type: 1 },
      { source_type_id: incident.id, target_type_id: task.id, link_type: 1 },
      { source_type_id: incident.id, target_type_id: objective.id, link_type: 1 },
      { source_type_id: incident.id, target_type_id: key_result.id, link_type: 1 }
    ]

    RelatedLinkRestriction.upsert_all(
      restrictions,
      unique_by: :index_work_item_link_restrictions_on_source_link_type_target
    )
  end

  def down
    incident = WorkItemType.find_by(base_type: BASE_TYPES[:incident])
    return unless incident

    RelatedLinkRestriction.where(source_type_id: incident.id).delete_all
    RelatedLinkRestriction.where(target_type_id: incident.id).delete_all
  end

  private

  def fetch_work_item_types
    BASE_TYPES.transform_values { |base_type| WorkItemType.find_by(base_type: base_type) }
  end
end
