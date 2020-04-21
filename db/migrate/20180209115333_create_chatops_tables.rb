# frozen_string_literal: true

class CreateChatopsTables < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_pipeline_chat_data, id: :bigserial do |t|
      t.integer :pipeline_id, null: false
      t.references :chat_name, foreign_key: { on_delete: :cascade }, null: false
      t.text :response_url, null: false # rubocop:disable Migration/AddLimitToTextColumns

      # A pipeline can only contain one row in this table, hence this index is
      # unique.
      t.index :pipeline_id, unique: true

      t.index :chat_name_id
    end

    # rubocop:disable Migration/AddConcurrentForeignKey
    add_foreign_key :ci_pipeline_chat_data, :ci_pipelines,
      column: :pipeline_id,
      on_delete: :cascade
  end
end
