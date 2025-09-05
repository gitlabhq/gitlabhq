# frozen_string_literal: true

class CreateSecurityProjectTrackedContexts < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    create_table :security_project_tracked_contexts do |t|
      t.bigint :project_id, null: false
      t.timestamps_with_timezone null: false
      t.integer :context_type, limit: 1, null: false, default: 1
      t.integer :state, limit: 1, null: false, default: 1
      t.boolean :is_default, null: false, default: false
      t.text :context_name, null: false

      t.index [:project_id, :context_name, :context_type], unique: true,
        name: 'index_security_project_tracked_contexts_on_project_context'
    end

    add_text_limit :security_project_tracked_contexts, :context_name, 1024
  end

  def down
    drop_table :security_project_tracked_contexts
  end
end
