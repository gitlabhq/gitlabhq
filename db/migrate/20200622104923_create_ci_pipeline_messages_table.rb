# frozen_string_literal: true

class CreateCiPipelineMessagesTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  ERROR_SEVERITY = 0
  MAX_CONTENT_LENGTH = 10_000

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :ci_pipeline_messages do |t|
        t.integer :severity, null: false, default: ERROR_SEVERITY, limit: 2
        t.references :pipeline, index: true, null: false, foreign_key: { to_table: :ci_pipelines, on_delete: :cascade }, type: :integer
        t.text :content, null: false
      end
    end

    add_text_limit :ci_pipeline_messages, :content, MAX_CONTENT_LENGTH
  end

  def down
    drop_table :ci_pipeline_messages
  end
end
