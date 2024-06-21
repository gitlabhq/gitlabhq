# frozen_string_literal: true

class RemoveImportedColumnOnDesignManagementDesigns < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    remove_column :design_management_designs, :imported
  end

  def down
    add_column :design_management_designs, :imported, :integer, default: 0, null: false, limit: 2
  end
end
