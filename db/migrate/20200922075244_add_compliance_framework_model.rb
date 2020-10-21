# frozen_string_literal: true

class AddComplianceFrameworkModel < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless table_exists?(:compliance_management_frameworks)
      with_lock_retries do
        create_table :compliance_management_frameworks do |t|
          t.references :group, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false, index: false
          t.text :name, null: false
          t.text :description, null: false
          t.text :color, null: false
          t.index [:group_id, :name], unique: true
        end
      end
    end

    add_text_limit :compliance_management_frameworks, :name, 255
    add_text_limit :compliance_management_frameworks, :description, 255
    add_text_limit :compliance_management_frameworks, :color, 10
  end

  def down
    with_lock_retries do
      drop_table :compliance_management_frameworks
    end
  end
end
