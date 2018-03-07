# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateChatopsTables < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    create_table :ci_pipeline_chat_data, id: :bigserial do |t|
      t.integer :pipeline_id, null: false
      t.references :chat_name, foreign_key: { on_delete: :cascade }, null: false
      t.text :response_url, null: false

      # A pipeline can only contain one row in this table, hence this index is
      # unique.
      t.index :pipeline_id, unique: true
    end

    add_foreign_key :ci_pipeline_chat_data, :ci_pipelines,
      column: :pipeline_id,
      on_delete: :cascade
  end
end
