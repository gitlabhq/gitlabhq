# frozen_string_literal: true

class CreateCustomSoftwareLicensesTable < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.0'

  def up
    create_table :custom_software_licenses do |t|
      t.references :project, index: false, foreign_key: { on_delete: :cascade }, null: false
      t.text :name, null: false, limit: 255

      t.index [:project_id, :name], unique: true
    end
  end

  def down
    drop_table :custom_software_licenses
  end
end
