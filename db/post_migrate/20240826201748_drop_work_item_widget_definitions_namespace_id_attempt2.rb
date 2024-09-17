# frozen_string_literal: true

class DropWorkItemWidgetDefinitionsNamespaceIdAttempt2 < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    remove_column :work_item_widget_definitions, :namespace_id, if_exists: true
  end

  def down
    add_column :work_item_widget_definitions, :namespace_id, :bigint, if_not_exists: true
  end
end
