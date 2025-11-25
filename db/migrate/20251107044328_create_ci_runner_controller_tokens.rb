# frozen_string_literal: true

class CreateCiRunnerControllerTokens < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  def up
    create_table :ci_runner_controller_tokens do |t|
      t.text :description, limit: 1024
      t.text :token_digest, null: false, limit: 255
      t.references :runner_controller, null: false,
        foreign_key: { to_table: :ci_runner_controllers, on_delete: :cascade },
        index: { name: 'index_ci_rac_tokens_on_rac_id' }

      t.timestamps_with_timezone null: false
    end

    add_index :ci_runner_controller_tokens, :token_digest, unique: true
  end

  def down
    drop_table :ci_runner_controller_tokens
  end
end
