# frozen_string_literal: true

class DropWorkItemDescriptionsTable < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.4'

  # We found that partitioning by root_namespace_id causes problems when syncing the data when a work item gets
  # transferred between namespaces.
  def up
    drop_table :work_item_descriptions if table_exists? :work_item_descriptions
  end

  def down
    # no-op, we don't want to recreate the table with the root_namespace_id partitioning
  end
end
