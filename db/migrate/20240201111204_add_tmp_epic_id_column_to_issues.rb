# frozen_string_literal: true

class AddTmpEpicIdColumnToIssues < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!

  def up
    add_column :issues, :tmp_epic_id, :bigint # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
  end

  def down
    remove_column :issues, :tmp_epic_id
  end
end
