# frozen_string_literal: true

class CreateHierarchyWorkItemsTable < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS hierarchy_work_items
      (
              traversal_path String,
              id Int64,
              title String DEFAULT '',
              author_id Nullable(Int64),
              created_at DateTime64(6, 'UTC') DEFAULT now(),
              updated_at DateTime64(6, 'UTC') DEFAULT now(),
              milestone_id Nullable(Int64),
              iid Nullable(Int64),
              updated_by_id Nullable(Int64),
              weight Nullable(Int64),
              confidential Bool DEFAULT false,
              due_date Nullable(Date32),
              moved_to_id Nullable(Int64),
              time_estimate Nullable(Int64) DEFAULT 0,
              relative_position Nullable(Int64),
              last_edited_at Nullable(DateTime64(6, 'UTC')),
              last_edited_by_id Nullable(Int64),
              closed_at Nullable(DateTime64(6, 'UTC')),
              closed_by_id Nullable(Int64),
              state_id Int8 DEFAULT 1,
              duplicated_to_id Nullable(Int64),
              promoted_to_epic_id Nullable(Int64),
              health_status Nullable(Int8),
              sprint_id Nullable(Int64),
              blocking_issues_count Int64 DEFAULT 0,
              upvotes_count Int64 DEFAULT 0,
              work_item_type_id Int64,
              namespace_id Int64,
              start_date Nullable(Date32),
              label_ids Array(Int64) DEFAULT [],
              assignee_ids Array(Int64) DEFAULT [],
              custom_status_id Int64,
              system_defined_status_id Int64,
              version DateTime64(6, 'UTC') DEFAULT now(),
              deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY (traversal_path, work_item_type_id, id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS hierarchy_work_items
    SQL
  end
end
