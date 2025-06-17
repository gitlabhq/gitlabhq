# frozen_string_literal: true

class CreateWorkspaceTokens < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  # @return [void]
  def change
    create_table :workspace_tokens do |t|
      t.references :workspace, foreign_key: { on_delete: :cascade }, null: false, index: { unique: true }

      t.timestamps_with_timezone null: false
      t.bigint :project_id, null: false, index: true
      t.text :token_encrypted, limit: 512, null: false

      t.check_constraint 'char_length(token_encrypted) <= 512'
    end
  end
end
