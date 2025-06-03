# frozen_string_literal: true

class RemoveTicketWorkItemTypeWrongHierarchyRestrictions < Gitlab::Database::Migration[2.3]
  TICKET_ID = 9
  TASK_ID = 5

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.1'

  def up
    # Only 1 hierarchy restriction record is correct, where ticket (parent) and task (child) are allowed.
    # All others are incorrect as not in sync with
    # lib/gitlab/database_importers/work_items/hierarchy_restrictions_importer.rb
    connection.execute(
      <<~SQL
        DELETE FROM
          work_item_hierarchy_restrictions
        WHERE (parent_type_id = #{TICKET_ID} OR child_type_id = #{TICKET_ID})
          AND child_type_id != #{TASK_ID}
      SQL
    )
  end

  def down
    # no-op
    # This records were introduced by mistake to begin with, so we never want to add them back.
  end
end
