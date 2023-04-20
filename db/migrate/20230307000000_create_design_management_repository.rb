# frozen_string_literal: true

class CreateDesignManagementRepository < Gitlab::Database::Migration[2.1]
  def change
    create_table :design_management_repositories do |t|
      t.references :project, index: { unique: true }, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps_with_timezone null: false
    end
  end
end
