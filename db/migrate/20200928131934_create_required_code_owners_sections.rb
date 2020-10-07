# frozen_string_literal: true

class CreateRequiredCodeOwnersSections < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :required_code_owners_sections, if_not_exists: true do |t|
        t.references :protected_branch, null: false, foreign_key: { on_delete: :cascade }
        t.text :name, null: false
      end
    end

    add_text_limit :required_code_owners_sections, :name, 1024
  end

  def down
    with_lock_retries do
      drop_table :required_code_owners_sections, if_exists: true
    end
  end
end
